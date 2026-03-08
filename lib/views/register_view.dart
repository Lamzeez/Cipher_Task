import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'otp_verify_view.dart';
import 'widgets/secure_text_field.dart';
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
    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SecureTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              Focus(
                onFocusChange: (hasFocus) {
                  if (!mounted) return;
                  setState(() => _showPasswordStatus = hasFocus);
                },
                child: TextField(
                  controller: _pass,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(
                        color: Colors.white70,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (_showPasswordStatus) _buildPasswordStatus(),
              const SizedBox(height: 12),
              TextField(
                controller: _confirm,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: const BorderSide(
                      color: Colors.white70,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        final email = _email.text.trim();
                        final password = _pass.text.trim();
                        final confirm = _confirm.text.trim();
                        final generatedUsername = _generateRandomUsername();

                        if (email.isEmpty) {
                          showMiniSnackBar(context, 'Please enter your email.');
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
                          showMiniSnackBar(context, 'Please enter your password.');
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
                          showMiniSnackBar(context, 'Passwords do not match.');
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
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('Send OTP'),
              ),
            ],
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