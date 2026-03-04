import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'otp_verify_view.dart';
import 'widgets/secure_text_field.dart';

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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  SnackBar _miniSnackBar(String msg) {
    return SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
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

              // Password Field
              SecureTextField(
                controller: _pass,
                label: 'Password',
                obscure: true,
              ),

              // ✅ Regex guide
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password must have at least 8 characters, 1 uppercase letter, and 1 special character',
                  style: const TextStyle(fontSize: 12, height: 1.3),
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

                        if (fullName.isEmpty || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            _miniSnackBar('Please enter your username and email.'),
                          );
                          return;
                        }

                        if (password != confirm) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            _miniSnackBar('Passwords do not match.'),
                          );
                          return;
                        }

                        if (!auth.passwordMeetsPolicy(password)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            _miniSnackBar(
                              'Password must be 8+ chars, 1 uppercase, 1 special char.',
                            ),
                          );
                          return;
                        }

                        final ok = await auth.startRegistration(
                          fullName: fullName,
                          email: email,
                          password: password,
                        );

                        if (!ok) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            _miniSnackBar('That email is already registered.'),
                          );
                          return;
                        }

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          _miniSnackBar('OTP sent to $email. Please check your email.'),
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