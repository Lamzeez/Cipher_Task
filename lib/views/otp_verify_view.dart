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
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4A8AF4),
                            Color(0xFF1F67C8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2F73D9).withOpacity(0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Verify Email',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Enter the 6-digit code sent to\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF707070),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 34),

                    SizedBox(
                      height: 66,
                      child: TextField(
                        controller: _otp,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '000000',
                          counterText: '',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 8,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 20,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFFE3E3E3),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF2F73D9),
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4A8AF4),
                              Color(0xFF1F67C8),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2F73D9).withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: auth.loading
                              ? null
                              : () async {
                                  final otp = _otp.text.trim();

                                  if (otp.isEmpty) {
                                    showMiniSnackBar(
                                      context,
                                      'Please enter the 6-digit OTP.',
                                    );
                                    return;
                                  }

                                  if (otp.length != 6) {
                                    showMiniSnackBar(
                                      context,
                                      'OTP must be exactly 6 digits.',
                                    );
                                    return;
                                  }

                                  final ok = await context
                                      .read<AuthViewModel>()
                                      .verifyOtpAndCreateAccount(
                                        email: widget.email.trim(),
                                        otp: otp,
                                      );

                                  if (!ok && context.mounted) {
                                    showMiniSnackBar(
                                      context,
                                      'Invalid or expired OTP.',
                                    );
                                    return;
                                  }

                                  if (!context.mounted) return;

                                  context.read<AuthViewModel>().logout();

                                  showMiniSnackBar(
                                    context,
                                    'Registration complete! Please log in.',
                                  );

                                  Navigator.popUntil(
                                    context,
                                    (route) => route.isFirst,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: auth.loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Verify & Create Account',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextButton(
                      onPressed: (!_canResend || auth.loading)
                          ? null
                          : () async {
                              final ok = await context
                                  .read<AuthViewModel>()
                                  .resendOtp(email: widget.email.trim());

                              if (!mounted) return;

                              if (ok) {
                                showMiniSnackBar(
                                  context,
                                  'A new code has been sent to ${widget.email}.',
                                );
                                _startResendCountdown(seconds: 60);
                              } else {
                                showMiniSnackBar(
                                  context,
                                  'Unable to resend code. Please wait and try again.',
                                );
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        _canResend
                            ? 'Resend code'
                            : 'Resend in $_secondsRemaining s',
                        style: TextStyle(
                          color: _canResend
                              ? const Color(0xFF2F73D9)
                              : const Color(0xFF8A8A8A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Check your inbox and spam folder.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}