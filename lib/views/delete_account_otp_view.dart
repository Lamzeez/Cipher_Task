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
                      'Confirm Delete',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We sent a 6-digit code to\n$email\n\nEnter the code to permanently delete your account.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF707070),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFFFD6D6),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This action is permanent and cannot be undone.',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                                    .verifyDeleteOtpAndDeleteAccount(
                                      otp: otp,
                                    );

                                if (!ok && context.mounted) {
                                  showMiniSnackBar(
                                    context,
                                    'Invalid or expired OTP, or delete failed.',
                                  );
                                  return;
                                }

                                if (!context.mounted) return;

                                showMiniSnackBar(
                                  context,
                                  'Account deleted successfully.',
                                );

                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          disabledBackgroundColor: Colors.redAccent.withOpacity(
                            0.5,
                          ),
                          elevation: 0,
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
                                'Verify & Delete',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
                                  .resendDeleteOtp();

                              if (!mounted) return;

                              if (ok) {
                                showMiniSnackBar(context, 'New code sent.');
                                _startCountdown(60);
                              } else {
                                showMiniSnackBar(
                                  context,
                                  'Please wait before resending.',
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