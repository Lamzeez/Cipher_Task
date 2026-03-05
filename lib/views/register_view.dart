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
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  bool _showPasswordHint = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    // Simple, practical email validation (covers most real-world emails)
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SecureTextField(controller: _name, label: 'Username'),
              const SizedBox(height: 12),

              SecureTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              // Password Field (hint appears only when focused)
              Focus(
                onFocusChange: (hasFocus) {
                  if (!mounted) return;
                  setState(() => _showPasswordHint = hasFocus);
                },
                child: SecureTextField(
                  controller: _pass,
                  label: 'Password',
                  obscure: true,
                ),
              ),

              const SizedBox(height: 6),
              if (_showPasswordHint)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password must have at least 8 characters, 1 uppercase letter, and 1 special character',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),

              const SizedBox(height: 12),

              SecureTextField(
                controller: _confirm,
                label: 'Confirm Password',
                obscure: true,
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        final fullName = _name.text.trim();
                        final email = _email.text.trim();
                        final password = _pass.text.trim();
                        final confirm = _confirm.text.trim();

                        // ✅ Proper validation order
                        if (fullName.isEmpty) {
                          showMiniSnackBar(context, 'Please enter your username.');
                          return;
                        }

                        if (email.isEmpty) {
                          showMiniSnackBar(context, 'Please enter your email.');
                          return;
                        }

                        // ✅ Email verification (valid format)
                        if (!_isValidEmail(email)) {
                          showMiniSnackBar(context, 'Please enter a valid email address.');
                          return;
                        }

                        if (password.isEmpty) {
                          showMiniSnackBar(context, 'Please enter your password.');
                          return;
                        }

                        if (confirm.isEmpty) {
                          showMiniSnackBar(context, 'Please confirm your password.');
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
                          fullName: fullName,
                          email: email,
                          password: password,
                        );

                        if (!ok) {
                          if (!context.mounted) return;
                          showMiniSnackBar(context, 'That email is already registered.');
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