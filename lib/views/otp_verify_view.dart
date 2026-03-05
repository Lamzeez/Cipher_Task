import 'dart:async';

import 'package:cipher_task/utils/snack_bar.dart';
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

  bool _canResend = false;
  int _secondsRemaining = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
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


  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: SingleChildScrollView(
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
                          showMiniSnackBar(context,'Invalid or expired OTP.');
                          return;
                        }

                        if (!context.mounted) return;

                        // ensure we do NOT end up in home automatically
                        context.read<AuthViewModel>().logout();

                        showMiniSnackBar(context, 'Registration complete! Please log in.');

                        // Back to login (first route)
                        Navigator.popUntil(context, (route) => route.isFirst);
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
                          showMiniSnackBar(context,'A new code has been sent to ${widget.email}.');
                          _startResendCountdown(seconds: 60);
                        } else {
                          showMiniSnackBar(context, 'Unable to resend code. Please wait and try again.');
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