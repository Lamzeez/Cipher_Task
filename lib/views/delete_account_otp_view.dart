import 'dart:async';

import 'package:cipher_task/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class DeleteAccountOtpView extends StatefulWidget {
  const DeleteAccountOtpView({super.key});

  @override
  State<DeleteAccountOtpView> createState() => _DeleteAccountOtpViewState();
}

class _DeleteAccountOtpViewState extends State<DeleteAccountOtpView> {
  final TextEditingController _otp = TextEditingController();

  bool _canResend = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(60);
  }

  @override
  void dispose() {
    _otp.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() {
      _canResend = false;
      _secondsRemaining = seconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        t.cancel();
        setState(() {
          _canResend = true;
          _secondsRemaining = 0;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final email = auth.pendingDeleteEmail ?? auth.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Delete')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'We sent a 6-digit code to:\n$email\n\n'
                'Enter code to permanently delete your account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otp,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '6-digit OTP',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        final ok = await context
                            .read<AuthViewModel>()
                            .verifyDeleteOtpAndDeleteAccount(
                              otp: _otp.text.trim(),
                            );

                        if (!ok && context.mounted) {
                          showMiniSnackBar(context, 'Invalid/expired OTP or delete failed.');
                          return;
                        }

                        if (!context.mounted) return;
                        showMiniSnackBar(context, 'Account deleted successfully.');

                        // Back to Login/root
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('Verify & Delete'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: (!_canResend || auth.loading)
                    ? null
                    : () async {
                        final ok = await context.read<AuthViewModel>().resendDeleteOtp();
                        if (!mounted) return;

                        if (ok) {
                          showMiniSnackBar(context, 'New code sent.');
                          _startCountdown(60);
                        } else {
                          showMiniSnackBar(context, 'Please wait before resending.');
                        }
                      },
                child: _canResend
                    ? const Text('Resend code')
                    : Text('Resend in $_secondsRemaining s'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}