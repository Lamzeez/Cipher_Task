import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'delete_account_otp_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  SnackBar _miniSnackBar(String msg) {
    return SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    final current = auth.user?.displayName ?? '';
    final controller = TextEditingController(text: current);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final newName = controller.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(_miniSnackBar('Username cannot be empty.'));
      return;
    }

    final success = await auth.updateDisplayName(newName);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      _miniSnackBar(success ? 'Username updated.' : 'Failed to update username.'),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your Supabase Auth account and wipe encrypted local data.\n\n'
          'We will send an OTP to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('No user loaded.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.displayName.isEmpty ? '(No username set)' : user.displayName),
                    subtitle: Text(user.email),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: auth.loading ? null : () => _editName(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit username'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: auth.loading
                          ? null
                          : () async {
                              final confirmed = await _confirmDelete(context);
                              if (confirmed != true) return;

                              final ok = await context.read<AuthViewModel>().startDeleteAccountOtp();
                              if (!context.mounted) return;

                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  _miniSnackBar('Failed to send OTP. Try again.'),
                                );
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                _miniSnackBar('OTP sent. Please check your email.'),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DeleteAccountOtpView(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      label: const Text(
                        'Delete account',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (auth.loading) const CircularProgressIndicator(),
                ],
              ),
            ),
    );
  }
}