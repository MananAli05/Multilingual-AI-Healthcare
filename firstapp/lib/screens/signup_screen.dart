import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import 'otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final _authService = AuthService();
  final _voiceService = VoiceService();

  bool _isLoading = false;
  String? _activeListeningField;
  
  Timer? _micTimer;
  int _micSecondsLeft = 4;

  late AnimationController _nameMicController;
  late AnimationController _phoneMicController;

  @override
  void initState() {
    super.initState();
    _nameMicController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _phoneMicController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _voiceService.speak("Assalam o alaikum! Apna account bananaye k liye neechay diye gaye mic button ko dabayein aur apna naam bolain.");
    });
  }

  @override
  void dispose() {
    _nameMicController.dispose();
    _phoneMicController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _micTimer?.cancel();
    _voiceService.stopSpeaking();
    super.dispose();
  }

  Future<void> _handleFieldMic(String field) async {
    if (_activeListeningField == field) {
      _stopFieldMic(field);
      return;
    }
    if (_activeListeningField != null) _stopFieldMic(_activeListeningField!);

    setState(() {
      _activeListeningField = field;
      _micSecondsLeft = 4;
    });

    if (field == "name") _nameMicController.repeat(reverse: true);
    else _phoneMicController.repeat(reverse: true);

    final started = await _voiceService.startRecording();
    if (started == null) {
      _stopFieldMic(field);
      return;
    }

    _micTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_micSecondsLeft > 1) {
        if (mounted) setState(() => _micSecondsLeft--);
      } else {
        if (mounted && _activeListeningField == field) {
          _processFieldResult(field);
        }
      }
    });
  }

  Future<void> _processFieldResult(String field) async {
    _stopFieldMic(field);
    final result = await _voiceService.stopAndProcess(field);
    if (result != null && result != 'Unknown' && result.trim().isNotEmpty) {
      setState(() {
        if (field == 'name') _nameController.text = result;
        else {
          final digits = result.replaceAll(RegExp(r'\D'), '');
          if (digits.length == 11) _phoneController.text = digits;
        }
      });
    }
  }

  void _stopFieldMic(String field) {
    _micTimer?.cancel();
    if (field == "name") { _nameMicController.stop(); _nameMicController.reset(); }
    else { _phoneMicController.stop(); _phoneMicController.reset(); }
    if (mounted) setState(() => _activeListeningField = null);
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await _authService.sendOTP(_phoneController.text.trim());
      setState(() => _isLoading = false);
      if (mounted && result['success']) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => OTPVerificationScreen(phone: _phoneController.text.trim(), name: _nameController.text.trim(), isSignup: true)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A2138)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF00478D), Color(0xFF005EB8)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(
                        Translations.t('Create Account', lang),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A2138)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Translations.t('Start your health journey', lang),
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildVoiceField(Translations.t('Full Name', lang), _nameController, _nameFocus, Icons.person_outline, "name", _nameMicController),
                const SizedBox(height: 16),
                _buildVoiceField(Translations.t('Phone Number', lang), _phoneController, _phoneFocus, Icons.phone_outlined, "phone", _phoneMicController, isPhone: true),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _handleSignup, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00478D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(Translations.t('Sign Up', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(Translations.t('Already have an account?', lang)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(Translations.t('Login', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceField(String label, TextEditingController ctrl, FocusNode focus, IconData icon, String key, AnimationController anim, {bool isPhone = false}) {
    final isListening = _activeListeningField == key;
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        return TextFormField(
          controller: ctrl,
          focusNode: focus,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return lang == 'ur' ? 'یہ فیلڈ درکار ہے' : 'This field is required';
            }
            if (isPhone && value.replaceAll(RegExp(r'\D'), '').length != 11) {
              return lang == 'ur' ? 'براہ کرم 11 ہندسوں کا درست نمبر درج کریں' : 'Please enter a valid 11-digit number';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: isListening ? 'Listening... $_micSecondsLeft' : label,
            prefixIcon: Icon(icon),
            suffixIcon: IconButton(icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: isListening ? Colors.red : Colors.blue), onPressed: () => _handleFieldMic(key)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
}
