import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';
import 'otp_verify_view.dart';
import '../utils/snack_bar.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  bool _showPasswordStatus = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _pass.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.removeListener(_onPasswordChanged);
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    return regex.hasMatch(email);
  }

  String _generateRandomUsername() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final suffix = List.generate(
      10,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return 'user_$suffix';
  }

  _PasswordStrength _getPasswordStrength(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasSpecial =
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];+=~`]').hasMatch(password);

    if (hasMinLength && hasUppercase && hasSpecial) {
      return _PasswordStrength.strong;
    }

    if (hasMinLength) {
      return _PasswordStrength.medium;
    }

    return _PasswordStrength.weak;
  }

  Widget _buildPasswordStatus() {
    final strength = _getPasswordStrength(_pass.text);

    String text;
    Color color;

    switch (strength) {
      case _PasswordStrength.weak:
        text = 'Password strength: Weak';
        color = Colors.red;
        break;
      case _PasswordStrength.medium:
        text = 'Password strength: Medium';
        color = Colors.orange;
        break;
      case _PasswordStrength.strong:
        text = 'Password strength: Strong';
        color = Colors.green;
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 1.3,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4A8AF4),
                            Color(0xFF1F67C8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2F73D9).withOpacity(0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create your account using your email\nand password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF707070),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _buildInputField(
                      controller: _email,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Focus(
                      onFocusChange: (hasFocus) {
                        if (!mounted) return;
                        setState(() => _showPasswordStatus = hasFocus);
                      },
                      child: _buildPasswordField(
                        controller: _pass,
                        hintText: 'Password',
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_showPasswordStatus) _buildPasswordStatus(),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: _confirm,
                      hintText: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4A8AF4),
                              Color(0xFF1F67C8),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2F73D9).withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: auth.loading
                              ? null
                              : () async {
                                  final email = _email.text.trim();
                                  final password = _pass.text.trim();
                                  final confirm = _confirm.text.trim();
                                  final generatedUsername =
                                      _generateRandomUsername();

                                  if (email.isEmpty) {
                                    showMiniSnackBar(
                                      context,
                                      'Please enter your email.',
                                    );
                                    return;
                                  }

                                  if (!_isValidEmail(email)) {
                                    showMiniSnackBar(
                                      context,
                                      'Please enter a valid email address.',
                                    );
                                    return;
                                  }

                                  if (password.isEmpty) {
                                    showMiniSnackBar(
                                      context,
                                      'Please enter your password.',
                                    );
                                    return;
                                  }

                                  if (confirm.isEmpty) {
                                    showMiniSnackBar(
                                      context,
                                      'Please confirm your password.',
                                    );
                                    return;
                                  }

                                  if (!auth.passwordMeetsPolicy(password)) {
                                    showMiniSnackBar(
                                      context,
                                      'Password must be 8+ chars, 1 uppercase, 1 special char.',
                                    );
                                    return;
                                  }

                                  if (password != confirm) {
                                    showMiniSnackBar(
                                      context,
                                      'Passwords do not match.',
                                    );
                                    return;
                                  }

                                  final ok = await auth.startRegistration(
                                    fullName: generatedUsername,
                                    email: email,
                                    password: password,
                                  );

                                  if (!ok) {
                                    if (!context.mounted) return;
                                    showMiniSnackBar(
                                      context,
                                      'That email is already registered.',
                                    );
                                    return;
                                  }

                                  if (!context.mounted) return;
                                  showMiniSnackBar(
                                    context,
                                    'OTP sent to $email. Please check your email.',
                                  );

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OtpVerifyView(email: email),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: auth.loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE2E2E2),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Color(0xFF7A7A7A),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE2E2E2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginView(),
                              ),
                            );
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: Color(0xFF2F73D9),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 66,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 16,
          ),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFFE3E3E3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFF2F73D9),
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return SizedBox(
      height: 66,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 16,
          ),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFFE3E3E3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFF2F73D9),
              width: 1.6,
            ),
          ),
          suffixIcon: IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF7B7B7B),
            ),
          ),
        ),
      ),
    );
  }
}

enum _PasswordStrength {
  weak,
  medium,
  strong,
}