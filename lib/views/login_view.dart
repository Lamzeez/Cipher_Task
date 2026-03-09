import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';
import '../utils/snack_bar.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  late Future<bool> _canBio;

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _canBio = context.read<AuthViewModel>().canUseBiometrics();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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

                    // App Icon
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
                      'Login',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Enter your email and password to\nlog in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF707070),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 34),

                    _buildInputField(
                      controller: _email,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    _buildPasswordField(),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Transform.scale(
                          scale: 1.1,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            side: const BorderSide(
                              color: Color(0xFF333333),
                              width: 1.6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            activeColor: const Color(0xFF2F73D9),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            showMiniSnackBar(
                              context,
                              'Forgot password will be added later.',
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF2F73D9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

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
                                  final email = _email.text.trim();
                                  final password = _pass.text.trim();

                                  if (email.isEmpty || password.isEmpty) {
                                    showMiniSnackBar(
                                      context,
                                      'Please enter both email and password.',
                                    );
                                    return;
                                  }

                                  final ok = await auth.loginWithPassword(
                                    email,
                                    password,
                                  );

                                  if (!ok && context.mounted) {
                                    showMiniSnackBar(
                                      context,
                                      'Invalid email or password, or account not registered yet.',
                                    );
                                    return;
                                  }

                                  if (context.mounted) {
                                    showMiniSnackBar(
                                      context,
                                      'Logged in successfully.',
                                    );
                                  }
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
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE2E2E2),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'Or login with',
                            style: TextStyle(
                              color: Color(0xFF7A7A7A),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE2E2E2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(
                          onTap: () {
                            showMiniSnackBar(
                              context,
                              'Google sign in will be added later.',
                            );
                          },
                          child: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildSocialButton(
                          onTap: () {
                            showMiniSnackBar(
                              context,
                              'Facebook sign in will be added later.',
                            );
                          },
                          child: const Text(
                            'f',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1877F2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FutureBuilder<bool>(
                          future: _canBio,
                          builder: (context, snap) {
                            final canUseBiometrics = snap.data == true;

                            return _buildSocialButton(
                              backgroundColor: const Color(0xFFEAF1FB),
                              onTap: (!canUseBiometrics || auth.loading)
                                  ? null
                                  : () async {
                                      final ok =
                                          await auth.loginWithBiometrics();

                                      if (!ok && context.mounted) {
                                        showMiniSnackBar(
                                          context,
                                          'Biometric unlock failed or cancelled.',
                                        );
                                        return;
                                      }

                                      if (context.mounted) {
                                        showMiniSnackBar(
                                          context,
                                          'Logged in with biometrics.',
                                        );
                                      }
                                    },
                              child: Icon(
                                Icons.fingerprint,
                                size: 32,
                                color: canUseBiometrics
                                    ? const Color(0xFF6A8DFF)
                                    : Colors.grey.shade400,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterView(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF2F73D9),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 66,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 16,
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
    );
  }

  Widget _buildPasswordField() {
    return SizedBox(
      height: 66,
      child: TextField(
        controller: _pass,
        obscureText: _obscurePassword,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 16,
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
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF7B7B7B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget child,
    VoidCallback? onTap,
    Color backgroundColor = Colors.white,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E2E2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}