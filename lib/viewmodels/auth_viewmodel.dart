import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/key_storage_service.dart';
import '../utils/constants.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  UserModel? _user;
  UserModel? get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Pending registration (for OTP verification)
  String? _pendingEmail;
  String? _pendingName;
  String? _pendingPasswordHash;
  String? _pendingOtp; // 6-digit code

  bool get awaitingOtp => _pendingEmail != null;
  String? get debugLastOtp => _pendingOtp;

  /// Load the last logged-in profile (if any) from encrypted Hive.
  /// This does NOT automatically authenticate the user.
  Future<void> loadUser() async {
    await DatabaseService.instance.init();

    final box = DatabaseService.instance.userBox;
    final data = box.get('profile'); // last logged-in user
    if (data is Map) {
      _user = UserModel.fromMap(Map<String, dynamic>.from(data));
    } else {
      _user = null;
    }
    notifyListeners();
  }

  Future<bool> startRegistration({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await DatabaseService.instance.init();

      final normalizedEmail = email.trim().toLowerCase();
      final usersBox = DatabaseService.instance.userBox;

      // Check if email is already registered locally
      final existing = usersBox.get(normalizedEmail);
      if (existing is Map) {
        return false; // email already exists locally
      }

      // Hash the password locally (we still keep local password auth)
      final hash = _hashPassword(password);

      // 1) Ask Supabase to send an OTP email
      // This uses the "passwordless email" OTP flow.
      await _supabase.auth.signInWithOtp(
        email: normalizedEmail,
        // If you don't want Supabase to auto-create an auth user, set options:
        // options: const EmailOtpSignInOptions(shouldCreateUser: true),
      );

      // 2) Remember pending registration data locally.
      _pendingEmail = normalizedEmail;
      _pendingName = fullName.trim();
      _pendingPasswordHash = hash;

      // We don't store the OTP itself; Supabase will verify it.
      _pendingOtp = null;

      return true;
    } catch (e) {
      debugPrint('startRegistration (Supabase) error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify the OTP and, if correct, create the account and log the user in.
  Future<bool> verifyOtpAndCreateAccount({
    required String email,
    required String otp,
  }) async {
    if (_pendingEmail == null ||
        _pendingPasswordHash == null ||
        _pendingName == null) {
      return false; // no pending registration
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail != _pendingEmail) {
      return false; // mismatch
    }

    _setLoading(true);
    try {
      // 1) Ask Supabase to verify the OTP
      // For email OTP, type must be OtpType.email
      // Docs: supabase.auth.verifyOtp({ email, token, type: 'email' }) :contentReference[oaicite:3]{index=3}
      await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: normalizedEmail,
        token: otp.trim(),
      );

      // If we get here without throwing an AuthException, the OTP is valid.

      // 2) Create the local encrypted account like before
      await DatabaseService.instance.init();
      final usersBox = DatabaseService.instance.userBox;

      final profile = UserModel(
        email: normalizedEmail,
        displayName: _pendingName!,
      );

      // store this user under its email AND as 'profile' (last logged-in user)
      await usersBox.put(normalizedEmail, profile.toMap());
      await usersBox.put('profile', profile.toMap());

      // store the password hash in secure storage, keyed by email
      final pwdKey = AppConstants.passwordKeyForEmail(normalizedEmail);
      await KeyStorageService.instance.setString(
        pwdKey,
        _pendingPasswordHash!,
      );
      await KeyStorageService.instance
          .setString(AppConstants.kPasswordEverSet, 'true');

      _user = profile;
      _isAuthenticated = true;

      // clear pending
      _pendingEmail = null;
      _pendingName = null;
      _pendingPasswordHash = null;
      _pendingOtp = null;

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('verifyOtp AuthException: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('verifyOtpAndCreateAccount error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with email + password against the hashed password in secure storage.
  Future<bool> loginWithPassword(String email, String password) async {
    if (_loading) return false;

    _setLoading(true);
    try {
      await DatabaseService.instance.init();

      final normalizedEmail = email.trim().toLowerCase();
      final usersBox = DatabaseService.instance.userBox;

      final data = usersBox.get(normalizedEmail);
      if (data is! Map) return false;

      final profile = UserModel.fromMap(Map<String, dynamic>.from(data));

      final pwdKey = AppConstants.passwordKeyForEmail(normalizedEmail);
      final stored =
          await KeyStorageService.instance.getString(pwdKey);
      if (stored == null) return false;

      final ok = stored == _hashPassword(password);
      if (!ok) return false;

      // Password is correct → mark as authenticated and remember as last profile
      await usersBox.put('profile', profile.toMap());
      await KeyStorageService.instance
          .setString(AppConstants.kPasswordEverSet, 'true');

      _user = profile;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  /// Biometric login: unlocks the last logged-in profile ('profile' in userBox).
  Future<bool> loginWithBiometrics() async {
    if (_loading) return false;

    _setLoading(true);
    try {
      final allowed = await canUseBiometrics();
      if (!allowed) return false;

      // Start biometric auth
      final authFuture = _localAuth.authenticate(
        localizedReason: 'Unlock CipherTask with your fingerprint',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      // HARD STOP: prevent infinite loading if platform hangs
      final didAuth = await authFuture.timeout(
        const Duration(seconds: 12),
        onTimeout: () async {
          try {
            await _localAuth.stopAuthentication(); // cancels prompt if stuck
          } catch (_) {}
          return false;
        },
      );

      if (!didAuth) return false;

      // If device auth succeeded, load last profile and mark as authenticated
      await loadUser();
      if (_user == null) return false;

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on PlatformException catch (_) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Only allow biometrics if the device supports it and a password
  /// has been set at least once (kPasswordEverSet == 'true').
  Future<bool> canUseBiometrics() async {
    await DatabaseService.instance.init();
    final ever = await KeyStorageService.instance
        .getString(AppConstants.kPasswordEverSet);
    if (ever != 'true') return false;

    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  bool passwordMeetsPolicy(String password) {
    // min 8, 1 uppercase, 1 special
    if (password.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasSpecial = RegExp(
            r'[!@#$%^&*()_\-+=\[\]{};:"\\|,.<>/?`~]')
        .hasMatch(password);
    return hasUpper && hasSpecial;
  }

  String _hashPassword(String password) {
    // Stored hash only (never store raw password)
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Simple 6-digit OTP generator (for demo purposes).
  String _generateOtp() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final six = now % 1000000; // 0..999999
    return six.toString().padLeft(6, '0');
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  /// Re-send OTP for the currently pending registration email.
  Future<bool> resendOtp({required String email}) async {
    if (_pendingEmail == null) return false;

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail != _pendingEmail) return false;

    _setLoading(true);
    try {
      await _supabase.auth.signInWithOtp(
        email: normalizedEmail,
      );
      return true;
    } catch (e) {
      debugPrint('resendOtp error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}