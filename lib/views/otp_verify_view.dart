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
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
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
              'Enter the 6-digit code sent to ${widget.email}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
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
                          const SnackBar(
                            content: Text('Invalid or expired OTP.'),
                          ),
                        );
                        return;
                      }

                      if (context.mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    },
              child: auth.loading
                  ? const CircularProgressIndicator()
                  : const Text('Verify & Create Account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      final ok = await context
                          .read<AuthViewModel>()
                          .resendOtp(email: widget.email.trim());

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'A new code has been sent to ${widget.email}.'
                                  : 'Unable to resend code. Please try again.',
                            ),
                          ),
                        );
                      }
                    },
              child: const Text('Resend code'),
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