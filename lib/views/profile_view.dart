import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'delete_account_otp_view.dart';
import '../utils/snack_bar.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  InputDecoration _dialogFieldDecoration(String label) {
    final radius = BorderRadius.circular(16);

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFF101B38),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.white24, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.white24, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFF9B7BFF), width: 1.3),
      ),
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
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: _dialogFieldDecoration('Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final newName = controller.text.trim();
    if (newName.isEmpty) {
      showMiniSnackBar(context, 'Username cannot be empty.');
      return;
    }

    final success = await auth.updateDisplayName(newName);

    if (!context.mounted) return;
    showMiniSnackBar(
      context,
      success ? 'Username updated.' : 'Failed to update username.',
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your Supabase Auth account and wipe encrypted local data.\n\nWe will send an OTP to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
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
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: user == null
          ? const Center(child: Text('No user loaded.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                children: [
                  _ProfileHeaderCard(
                    username: user.displayName.isEmpty
                        ? '(No username set)'
                        : user.displayName,
                    email: user.email,
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Actions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed:
                                auth.loading ? null : () => _editName(context),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text(
                              'Edit username',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(
                                color: Colors.redAccent,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: auth.loading
                                ? null
                                : () async {
                                    final confirmed =
                                        await _confirmDelete(context);
                                    if (confirmed != true) return;

                                    final ok = await context
                                        .read<AuthViewModel>()
                                        .startDeleteAccountOtp();

                                    if (!context.mounted) return;

                                    if (!ok) {
                                      showMiniSnackBar(
                                        context,
                                        'Failed to send OTP. Try again.',
                                      );
                                      return;
                                    }

                                    showMiniSnackBar(
                                      context,
                                      'OTP sent. Please check your email.',
                                    );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const DeleteAccountOtpView(),
                                      ),
                                    );
                                  },
                            icon: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Delete account',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (auth.loading) const CircularProgressIndicator(),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String username;
  final String email;

  const _ProfileHeaderCard({
    required this.username,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF121E3D),
            Color(0xFF0E1730),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B5CF6).withOpacity(0.18),
              border: Border.all(
                color: const Color(0xFFB79CFF).withOpacity(0.35),
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD7C8FF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1730),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}