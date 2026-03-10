import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/snack_bar.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _pendingSnackShown = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _biometricReady = false;
  bool _checkingBiometric = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final authVm = context.read<AuthViewModel>();
      final ready = await authVm.canUseBiometrics();
      if (!mounted) return;
      setState(() {
        _biometricReady = ready;
        _checkingBiometric = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricReady = false;
        _checkingBiometric = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<AuthViewModel>();
    final ok = await authVm.loginWithPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!ok) {
      showMiniSnackBar(
        context,
        'Invalid email or password.',
        success: false,
      );
    } else {
      showMiniSnackBar(
        context,
        'Login successful.',
        success: true,
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();

    final authVm = context.read<AuthViewModel>();
    final ok = await authVm.signInWithGoogle();

    if (!mounted) return;

    if (!ok) {
      showMiniSnackBar(
        context,
        'Google sign-in could not be started.',
        success: false,
      );
    }
  }

  Future<void> _loginWithFacebook() async {
    FocusScope.of(context).unfocus();

    final authVm = context.read<AuthViewModel>();
    final ok = await authVm.signInWithFacebook();

    if (!mounted) return;

    if (!ok) {
      showMiniSnackBar(
        context,
        'Facebook sign-in could not be started.',
        success: false,
      );
    }
  }

  Future<void> _loginWithBiometrics() async {
    FocusScope.of(context).unfocus();

    final authVm = context.read<AuthViewModel>();
    final ok = await authVm.loginWithBiometrics();

    if (!mounted) return;

    if (!ok) {
      showMiniSnackBar(
        context,
        'Biometric login failed.',
        success: false,
      );
    } else {
      showMiniSnackBar(
        context,
        'Biometric login successful.',
        success: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final isLoading = authVm.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Logo ──────────────────────────────────────────────
                      Container(
                        height: 118,
                        width: 118,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4D97FF), Color(0xFF2168D8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x223B82F6),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter your email and password to\nlog in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6E6E6E),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 34),
                      // ── Email field ───────────────────────────────────────
                      _buildInputField(
                        controller: _emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) return 'Please enter your email.';
                          final emailOk = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(text);
                          if (!emailOk) return 'Please enter a valid email.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      // ── Password field ────────────────────────────────────
                      _buildInputField(
                        controller: _passwordController,
                        hintText: 'Password',
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Please enter your password.';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF8A8A8A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ── Log In button ─────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4D97FF), Color(0xFF2168D8)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x223B82F6),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _loginWithPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      // ── Divider ───────────────────────────────────────────
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(
                              color: Color(0xFFD7D7D7),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'Or login with',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF6E6E6E),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Color(0xFFD7D7D7),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // ── Social / biometric buttons ────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton(
                            onTap: isLoading ? null : _loginWithGoogle,
                            child: Image.asset(
                              'assets/icons/google_logo.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 32,
                                color: Color(0xFFDB4437),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _SocialButton(
                            onTap: isLoading ? null : _loginWithFacebook,
                            child: Image.asset(
                              'assets/icons/facebook_logo.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.facebook_rounded,
                                size: 32,
                                color: Color(0xFF1877F2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _SocialButton(
                            onTap: (_checkingBiometric ||
                                    !_biometricReady ||
                                    isLoading)
                                ? null
                                : _loginWithBiometrics,
                            backgroundColor: const Color(0xFFF3F7FF),
                            child: Icon(
                              Icons.fingerprint_rounded,
                              size: 30,
                              color: (_checkingBiometric || !_biometricReady)
                                  ? const Color(0xFFBFC9DE)
                                  : const Color(0xFF7D8CFF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // ── Sign up link ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterView(),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2F73D9),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction:
          hintText == 'Email' ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (hintText == 'Password') {
          _loginWithPassword();
        }
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF969696),
          fontSize: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFFDFDFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 22,
        ),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFF2F73D9),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.4,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.6,
          ),
        ),
      ),
    );
  }

  void _showPendingMiniSnackBarIfAny() {
    if (_pendingSnackShown) return;
    _pendingSnackShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final pending = context.read<AuthViewModel>().takePendingMiniSnackBar();
      if (pending == null) return;

      showMiniSnackBar(
        context,
        pending.message,
        success: pending.success,
      );
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showPendingMiniSnackBarIfAny();
  }
}

// ── Social button ─────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color backgroundColor;

  const _SocialButton({
    required this.onTap,
    required this.child,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 72,
        width: 72,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF7F7F7) : backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE3E3E3),
            width: 1.2,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}