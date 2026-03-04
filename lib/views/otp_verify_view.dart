import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class OtpVerifyView extends StatefulWidget {
  final String email;
  const OtpVerifyView({super.key, required this.email});

  @override
  State<OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView> {
  final TextEditingController _otp = TextEditingController();

  bool _canResend = false;          // <- start as false
  int _secondsRemaining = 60;       // <- 60-second cooldown
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    // As soon as we land on this screen, start the 60s cooldown.
    _startResendCountdown(seconds: 60);
  }

  @override
  void dispose() {
    _otp.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown({int seconds = 60}) {
    _resendTimer?.cancel();
    setState(() {
      _canResend = false;
      _secondsRemaining = seconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _canResend = true;
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
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
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Enter the 6-digit code sent to\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
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
                          .verifyOtpAndCreateAccount(
                            email: widget.email.trim(),
                            otp: _otp.text.trim(),
                          );

                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _miniSnackBar('Invalid or expired OTP.'),
                        );
                        return;
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _miniSnackBar(
                            'Registration complete! You can now log in.',
                          ),
                        );
                        // Back to first route (typically LoginView)
                        Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        );
                      }
                    },
              child: auth.loading
                  ? const CircularProgressIndicator()
                  : const Text('Verify & Create Account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: (!_canResend || auth.loading)
                  ? null
                  : () async {
                      final ok = await context
                          .read<AuthViewModel>()
                          .resendOtp(email: widget.email.trim());

                      if (!mounted) return;

                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _miniSnackBar(
                            'A new code has been sent to ${widget.email}.',
                          ),
                        );
                        // Start another 60s cooldown after a successful resend.
                        _startResendCountdown(seconds: 60);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _miniSnackBar(
                            'Unable to resend code. Please try again shortly.',
                          ),
                        );
                      }
                    },
              child: _canResend
                  ? const Text('Resend code')
                  : Text('Resend in $_secondsRemaining s'),
            ),
            const SizedBox(height: 12),

            // For debugging during development, you can uncomment this:
            // if (auth.debugLastOtp != null)
            //   Text('DEBUG OTP: ${auth.debugLastOtp!}'),
          ],
        ),
      ),
    );
  }
}