import 'dart:io';

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
      labelStyle: const TextStyle(color: Color(0xFF6F6F6F), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFE3E3E3), width: 1.3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFE3E3E3), width: 1.3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFF2F73D9), width: 1.5),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        title: const Text(
          'Edit username',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black87),
          cursorColor: const Color(0xFF2F73D9),
          decoration: _dialogFieldDecoration('Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2F73D9),
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

  Future<void> _changeAvatar(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    final hasAvatar = auth.avatarFile != null;

    if (hasAvatar) {
      final choice = await showDialog<_AvatarAction>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: Colors.white,
          title: const Text(
            'Profile picture',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          content: const Text(
            'What would you like to do?',
            style: TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_AvatarAction.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_AvatarAction.remove),
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2F73D9)),
              onPressed: () => Navigator.of(ctx).pop(_AvatarAction.change),
              child: const Text('Change'),
            ),
          ],
        ),
      );

      if (!context.mounted) return;

      if (choice == _AvatarAction.remove) {
        await auth.removeAvatar();
        if (context.mounted) {
          showMiniSnackBar(context, 'Profile picture removed.');
        }
        return;
      }

      if (choice != _AvatarAction.change) return;
    }

    final success = await auth.updateAvatar();

    if (!context.mounted) return;
    if (success) {
      showMiniSnackBar(context, 'Profile picture updated.');
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        title: const Text(
          'Delete account?',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        content: const Text(
          'This will permanently delete your Supabase Auth account and wipe encrypted local data.\n\nWe will send an OTP to confirm.',
          style: TextStyle(color: Colors.black87, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
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
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style:
              TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text('No user loaded.',
                  style: TextStyle(color: Colors.black87)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Column(
                children: [
                  _ProfileHeaderCard(
                    username: user.displayName.isEmpty
                        ? '(No username set)'
                        : user.displayName,
                    email: user.email,
                    avatarFile: auth.avatarFile,
                    // Key changes whenever avatar is updated/removed, forcing
                    // Image.file to discard its cache and re-read the file.
                    avatarVersion: auth.avatarVersion,
                    onTapAvatar: auth.loading
                        ? null
                        : () => _changeAvatar(context),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.manage_accounts_rounded,
                                color: Color(0xFF2F73D9)),
                            SizedBox(width: 10),
                            Text(
                              'Account Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A8AF4), Color(0xFF1F67C8)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF2F73D9).withOpacity(0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: auth.loading
                                  ? null
                                  : () => _editName(context),
                              icon: const Icon(Icons.edit_rounded,
                                  color: Colors.white),
                              label: const Text(
                                'Edit username',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side:
                                  const BorderSide(color: Colors.redAccent),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
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
                                      showMiniSnackBar(context,
                                          'Failed to send OTP. Try again.');
                                      return;
                                    }

                                    showMiniSnackBar(context,
                                        'OTP sent. Please check your email.');

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const DeleteAccountOtpView(),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.delete_forever_rounded,
                                color: Colors.redAccent),
                            label: const Text(
                              'Delete account',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700),
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

// ── Avatar action enum ────────────────────────────────────────────────────────

enum _AvatarAction { change, remove, cancel }

// ── Profile header card ───────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final String username;
  final String email;
  final File? avatarFile;
  final int avatarVersion;
  final VoidCallback? onTapAvatar;

  const _ProfileHeaderCard({
    required this.username,
    required this.email,
    required this.avatarFile,
    required this.avatarVersion,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A8AF4), Color(0xFF1F67C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F73D9).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapAvatar,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.28),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    // ValueKey on the whole ClipOval forces Flutter to rebuild
                    // the subtree (and flush the image cache) whenever the
                    // avatar changes or is removed.
                    key: ValueKey(avatarVersion),
                    child: avatarFile != null
                        ? Image.file(
                            avatarFile!,
                            fit: BoxFit.cover,
                            width: 82,
                            height: 82,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
                // Camera badge
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2F73D9).withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Color(0xFF2F73D9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}