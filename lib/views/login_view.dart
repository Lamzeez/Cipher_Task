import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';
import 'widgets/secure_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  late Future<bool> _canBio;

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

    return Scaffold(
      appBar: AppBar(title: const Text('CipherTask Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            SecureTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            SecureTextField(
              controller: _pass,
              label: 'Password',
              obscure: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      final email = _email.text.trim();
                      final password = _pass.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        _show('Please enter both email and password.');
                        return;
                      }

                      final ok =
                          await auth.loginWithPassword(email, password);
                      if (!ok && context.mounted) {
                        _show(
                          'Invalid email or password, or account not registered yet.',
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
                            _show(
                              'Biometric unlock failed or cancelled.',
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
            const Spacer(),
            TextButton(
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
          ],
        ),
      ),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}