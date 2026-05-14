import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  final String? name;
  final bool isSignup;

  const OTPVerificationScreen({
    Key? key,
    required this.phone,
    this.name,
    required this.isSignup,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_pinController.text.length != 6) {
      _showSnackBar('6 digits درج کریں', false);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.verifyOTP(
      otp: _pinController.text,
      name: widget.name ?? '',
      phone: widget.phone,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        final userData = result['user'];

        if (widget.isSignup) {
          // Signup flow – show success then go to login
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Icon(Icons.check_circle, color: Color(0xFF00478D), size: 60),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'اکاؤنٹ بن گیا!\nAccount Created!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Login flow – save user to SharedPreferences then go to dashboard
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_phone', userData['phone'] ?? widget.phone);
          await prefs.setString('user_name', userData['name'] ?? '');

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  userName: userData['name'] ?? 'User',
                  userPhone: userData['phone'] ?? widget.phone,
                ),
              ),
              (route) => false,
            );
          }
        }
      } else {
        _showSnackBar(result['message'], false);
        _pinController.clear();
      }
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, child) {
        final lang = langProvider.currentLanguage;

        final defaultPinTheme = PinTheme(
          width: 56,
          height: 60,
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2138),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
        );

        final focusedPinTheme = defaultPinTheme.copyWith(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00478D), width: 2),
          ),
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A2138)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00478D).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sms_outlined, size: 50, color: Color(0xFF00478D)),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    Translations.t('verify_otp', lang),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2138)),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    Translations.t('otp_description', lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.phone,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00478D)),
                  ),

                  const SizedBox(height: 40),

                  Pinput(
                    controller: _pinController,
                    focusNode: _focusNode,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: focusedPinTheme,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    onCompleted: (pin) => _verifyOTP(),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00478D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              Translations.t('verify_otp', lang),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () async {
                      final result = await _authService.sendOTP(widget.phone);
                      _showSnackBar(result['message'], result['success']);
                    },
                    child: Text(
                      Translations.t('resend_otp', lang),
                      style: const TextStyle(color: Color(0xFF00478D), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
