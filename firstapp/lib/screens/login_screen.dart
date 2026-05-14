import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  final _voiceService = VoiceService();

  bool _isLoading = false;
  bool _isListeningPhone = false;

  Timer? _micTimer;
  int _micSecondsLeft = 4;

  late AnimationController _phoneMicController;

  @override
  void initState() {
    super.initState();
    _phoneMicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _phoneMicController.dispose();
    _phoneController.dispose();
    _micTimer?.cancel();
    super.dispose();
  }

  Future<void> _handlePhoneMic() async {
    if (_isListeningPhone) {
      _stopPhoneMic();
      return;
    }

    setState(() {
      _isListeningPhone = true;
      _micSecondsLeft = 4;
    });
    _phoneMicController.repeat(reverse: true);

    final started = await _voiceService.startRecording();
    if (started == null) {
      _stopPhoneMic();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Microphone permission denied or Error starting recorder.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _micTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_micSecondsLeft > 1) {
        if (mounted) setState(() => _micSecondsLeft--);
      } else {
        if (mounted && _isListeningPhone) {
          _processPhoneResult();
        }
      }
    });
  }

  Future<void> _processPhoneResult() async {
    _stopPhoneMic();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Processing your voice...'),
            ],
          ),
          backgroundColor: Color(0xFF00478D),
        ),
      );
    }

    final result = await _voiceService.stopAndProcess('phone');

    if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (!mounted) return;

    if (result != null && result != 'Unknown' && result.trim().isNotEmpty) {
      final digits = result.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 11) {
        setState(() => _phoneController.text = digits);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Heard "$result" but could not find a valid 11-digit number.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _stopPhoneMic() {
    _micTimer?.cancel();
    _phoneMicController.stop();
    _phoneMicController.reset();
    if (mounted) setState(() => _isListeningPhone = false);
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await _authService.loginUser(_phoneController.text.trim());
      setState(() => _isLoading = false);

      if (mounted) {
        if (result['success']) {
          final user = result['user'] as Map<String, dynamic>? ?? {};
          final userName = (user['name'] ?? 'User').toString();
          final userPhone = (user['phone'] ?? _phoneController.text.trim()).toString();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_phone', userPhone);
          await prefs.setString('user_name', userName);

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => DashboardScreen(userName: userName, userPhone: userPhone)),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, child) {
        final lang = langProvider.currentLanguage;

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
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => langProvider.toggleLanguage(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: const Color(0xFF00478D), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(lang == 'ur' ? 'اردو' : 'English', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF00478D), Color(0xFF005EB8)]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medical_services_rounded, size: 50, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      Translations.t('Login', lang), // Corrected to Translations.t
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A2138)),
                    ),
                    const SizedBox(height: 32),
                    AnimatedBuilder(
                      animation: _phoneMicController,
                      builder: (context, child) {
                        return TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 11,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: _isListeningPhone ? 'Listening... $_micSecondsLeft' : Translations.t('Phone Number', lang),
                            hintText: '03001234567',
                            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF00478D)),
                            suffixIcon: IconButton(
                              icon: Icon(_isListeningPhone ? Icons.mic : Icons.mic_none, color: _isListeningPhone ? Colors.red : const Color(0xFF00478D)),
                              onPressed: _handlePhoneMic,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return Translations.t('Enter phone number', lang); // Corrected
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00478D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(Translations.t('Login', lang), style: const TextStyle(color: Colors.white)), // Corrected
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(Translations.t('Don\'t have an account?', lang)), // Corrected
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                          child: Text(Translations.t('Sign Up', lang), style: const TextStyle(fontWeight: FontWeight.bold)), // Corrected
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
