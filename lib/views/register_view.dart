import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SecureTextField(controller: _name, label: 'Full Name'),
            const SizedBox(height: 12),
            SecureTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            SecureTextField(controller: _pass, label: 'Password', obscure: true),
            const SizedBox(height: 12),
            SecureTextField(controller: _confirm, label: 'Confirm Password', obscure: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      final password = _pass.text.trim();
                      if (password != _confirm.text.trim()) {
                        _show('Passwords do not match');
                        return;
                      }
                      if (!auth.passwordMeetsPolicy(password)) {
                        _show('Password must be 8+ chars, 1 uppercase, 1 special char.');
                        return;
                      }
                      await auth.register(
                        fullName: _name.text.trim(),
                        email: _email.text.trim(),
                        password: password,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: auth.loading ? const CircularProgressIndicator() : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}