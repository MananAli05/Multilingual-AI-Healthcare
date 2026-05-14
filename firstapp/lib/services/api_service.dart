import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static String? _verificationId;

  // Consistency is key: always normalize to +92XXXXXXXXXX
  String _normalizePhone(String phone) {
    String trimmed = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (trimmed.startsWith('+92')) return trimmed;
    if (trimmed.startsWith('92')) return '+$trimmed';
    if (trimmed.startsWith('0')) return trimmed.replaceFirst('0', '+92');
    if (trimmed.length == 10) return '+92$trimmed';
    return trimmed;
  }

  String _firebaseErrorMessage(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try later.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait.';
      default:
        return e.message ?? 'Verification failed (${e.code}).';
    }
  }

  Map<String, dynamic> _mapUserFromProfile(Map<String, dynamic> profile) {
    return {
      'id': profile['id'],
      'firebase_uid': profile['firebase_uid'],
      'name': (profile['name'] ?? '').toString().trim().isEmpty ? 'User' : profile['name'],
      'phone': profile['phone'],
      'language': profile['language_preference'] ?? 'english',
    };
  }

  Future<Map<String, dynamic>> sendOTP(String phone) async {
    try {
      _verificationId = null;
      final completer = Completer<Map<String, dynamic>>();
      final formattedPhone = _normalizePhone(phone);

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (auth.PhoneAuthCredential credential) async {
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (auth.FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.complete({'success': false, 'message': _firebaseErrorMessage(e)});
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'OTP sent to $formattedPhone',
              'phone': formattedPhone,
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) => _verificationId = verificationId,
        timeout: const Duration(seconds: 60),
      );

      return await completer.future.timeout(const Duration(seconds: 65));
    } catch (e) {
      return {'success': false, 'message': 'Failed: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String otp,
    required String name,
    required String phone,
  }) async {
    try {
      if (_verificationId == null) return {'success': false, 'message': 'Request OTP first'};

      auth.PhoneAuthCredential credential = auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      auth.UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final firebaseUid = userCredential.user!.uid;
        final normalizedPhone = _normalizePhone(phone); // Normalize before saving!

        // 1. Sync with Supabase
        final existingUser = await _supabase.from('profiles').select().eq('firebase_uid', firebaseUid).maybeSingle();

        if (existingUser == null) {
          await _supabase.from('profiles').insert({
            'firebase_uid': firebaseUid,
            'phone': normalizedPhone, // SAVE NORMALIZED
            'name': name,
            'language_preference': 'english',
            'created_at': DateTime.now().toIso8601String(),
            'last_login': DateTime.now().toIso8601String(),
          });
        } else {
          await _supabase.from('profiles').update({
            'last_login': DateTime.now().toIso8601String(),
            'phone': normalizedPhone // Keep phone updated/normalized
          }).eq('firebase_uid', firebaseUid);
        }

        final profile = await _supabase.from('profiles').select().eq('firebase_uid', firebaseUid).single();
        final userData = _mapUserFromProfile(profile);

        // 2. Save to SQLite
        await _dbHelper.saveUser(userData);

        return {'success': true, 'message': 'Verification successful', 'user': userData};
      }
      return {'success': false, 'message': 'Verification failed'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> loginUser(String phone) async {
    try {
      final formattedPhone = _normalizePhone(phone);

      // 1. CHECK LOCAL
      final localUser = await _dbHelper.getUserByPhone(formattedPhone);
      if (localUser != null) {
        return {'success': true, 'message': 'Login successful (Offline)', 'user': localUser};
      }

      // 2. CHECK SUPABASE
      final profile = await _supabase.from('profiles').select().eq('phone', formattedPhone).maybeSingle();

      if (profile == null) {
        return {'success': false, 'message': 'User not found. Please sign up first.'};
      }

      final userData = _mapUserFromProfile(profile);
      await _dbHelper.saveUser(userData);

      return {'success': true, 'message': 'Login successful (Online)', 'user': userData};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _dbHelper.clearDatabase();
  }
}
