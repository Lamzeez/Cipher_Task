import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';
import 'widgets/secure_text_field.dart';
import '../utils/snack_bar.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  late Future<bool> _canBio;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _canBio = context.read<AuthViewModel>().canUseBiometrics();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(title: const Text('CipherTask Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Welcome back, operator.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Decrypt your tasks with secure login.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 24),
              SecureTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        final email = _email.text.trim();
                        final password = _pass.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          showMiniSnackBar(
                            context,
                            'Please enter both email and password.',
                          );
                          return;
                        }

                        final ok =
                            await auth.loginWithPassword(email, password);
                        if (!ok && context.mounted) {
                          showMiniSnackBar(
                            context,
                            'Invalid email or password, or account not registered yet.',
                          );
                          return;
                        }

                        if (context.mounted) {
                          showMiniSnackBar(
                            context,
                            'Logged in successfully.',
                          );
                        }
                      },
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('Unlock'),
              ),
              const SizedBox(height: 12),
              FutureBuilder<bool>(
                future: _canBio,
                builder: (context, snap) {
                  final can = snap.data == true;
                  return OutlinedButton.icon(
                    onPressed: (!can || auth.loading)
                        ? null
                        : () async {
                            final ok = await auth.loginWithBiometrics();
                            if (!ok && context.mounted) {
                              showMiniSnackBar(
                                context,
                                'Biometric unlock failed or cancelled.',
                              );
                              return;
                            }

                            if (context.mounted) {
                              showMiniSnackBar(
                                context,
                                'Logged in with biometrics.',
                              );
                            }
                          },
                    icon: const Icon(Icons.fingerprint),
                    label: const Text(
                      'Unlock with Fingerprint (last user)',
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterView(),
                      ),
                    );
                  },
                  child: const Text('No account? Register'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}