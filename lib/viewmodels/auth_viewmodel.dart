import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Pending registration (OTP verification)
  String? _pendingEmail;
  String? _pendingName;
  String? _pendingPasswordHash;

  bool get awaitingOtp => _pendingEmail != null;

  // Pending account deletion (OTP re-auth)
  String? _pendingDeleteEmail;
  bool get awaitingDeleteOtp => _pendingDeleteEmail != null;
  String? get pendingDeleteEmail => _pendingDeleteEmail;

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

  // ----------------------------
  // Registration (Supabase OTP)
  // ----------------------------
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

      // Already registered locally?
      final existing = usersBox.get(normalizedEmail);
      if (existing is Map) return false;

      final hash = _hashPassword(password);

      // Send OTP via Supabase
      await _supabase.auth.signInWithOtp(email: normalizedEmail);

      _pendingEmail = normalizedEmail;
      _pendingName = fullName.trim();
      _pendingPasswordHash = hash;

      return true;
    } catch (e) {
      debugPrint('startRegistration (Supabase) error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtpAndCreateAccount({
    required String email,
    required String otp,
  }) async {
    if (_pendingEmail == null || _pendingPasswordHash == null || _pendingName == null) {
      return false;
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail != _pendingEmail) return false;

    _setLoading(true);
    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: normalizedEmail,
        token: otp.trim(),
      );

      await DatabaseService.instance.init();
      final usersBox = DatabaseService.instance.userBox;

      final profile = UserModel(
        email: normalizedEmail,
        displayName: _pendingName!,
      );

      await usersBox.put(normalizedEmail, profile.toMap());
      await usersBox.put('profile', profile.toMap());

      final pwdKey = AppConstants.passwordKeyForEmail(normalizedEmail);
      await KeyStorageService.instance.setString(pwdKey, _pendingPasswordHash!);
      await KeyStorageService.instance.setString(AppConstants.kPasswordEverSet, 'true');

      _user = profile;
      _isAuthenticated = true;

      _pendingEmail = null;
      _pendingName = null;
      _pendingPasswordHash = null;

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

  Future<bool> resendOtp({required String email}) async {
    if (_pendingEmail == null) return false;

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail != _pendingEmail) return false;

    _setLoading(true);
    try {
      await _supabase.auth.signInWithOtp(email: normalizedEmail);
      return true;
    } catch (e) {
      debugPrint('resendOtp error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------
  // Local Login (no Supabase session)
  // ----------------------------
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
      final stored = await KeyStorageService.instance.getString(pwdKey);
      if (stored == null) return false;

      final ok = stored == _hashPassword(password);
      if (!ok) return false;

      await usersBox.put('profile', profile.toMap());
      await KeyStorageService.instance.setString(AppConstants.kPasswordEverSet, 'true');

      _user = profile;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------
  // Biometrics (local)
  // ----------------------------
  Future<bool> canUseBiometrics() async {
    await DatabaseService.instance.init();

    final ever = await KeyStorageService.instance.getString(AppConstants.kPasswordEverSet);
    if (ever != 'true') return false;

    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> loginWithBiometrics() async {
    if (_loading) return false;

    _setLoading(true);
    try {
      final allowed = await canUseBiometrics();
      if (!allowed) return false;

      final didAuth = await _localAuth
          .authenticate(
            localizedReason: 'Unlock CipherTask with your fingerprint',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
              useErrorDialogs: true,
              sensitiveTransaction: true,
            ),
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () async {
              try {
                await _localAuth.stopAuthentication();
              } catch (_) {}
              return false;
            },
          );

      if (!didAuth) return false;

      await loadUser();
      if (_user == null) return false;

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on PlatformException {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------
  // Logout (local + supabase signOut best-effort)
  // ----------------------------
  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;

    // best effort
    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    notifyListeners();
  }

  // ----------------------------
  // Profile update (local)
  // ----------------------------
  Future<bool> updateDisplayName(String newName) async {
    try {
      if (_user == null) return false;

      final updated = UserModel(email: _user!.email, displayName: newName.trim());

      await DatabaseService.instance.init();
      final usersBox = DatabaseService.instance.userBox;

      await usersBox.put(updated.email, updated.toMap());
      await usersBox.put('profile', updated.toMap());

      _user = updated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('updateDisplayName error: $e');
      return false;
    }
  }

  // ----------------------------
  // Local delete only
  // ----------------------------
  Future<bool> deleteLocalAccount() async {
    try {
      final email = _user?.email;

      await DatabaseService.instance.init();
      await DatabaseService.instance.clearAll();

      if (email != null && email.isNotEmpty) {
        await KeyStorageService.instance.delete(AppConstants.passwordKeyForEmail(email));
      }

      await KeyStorageService.instance.delete(AppConstants.kPasswordEverSet);
      await KeyStorageService.instance.delete(AppConstants.kDbKey);
      await KeyStorageService.instance.delete(AppConstants.kAesKey);

      await logout();
      return true;
    } catch (e) {
      debugPrint('deleteLocalAccount error: $e');
      return false;
    }
  }

  // ==========================================================
  // OTP RE-AUTH FOR ACCOUNT DELETION (SUPABASE + LOCAL)
  // ==========================================================

  /// Step 1: Send OTP to the currently logged-in local user's email.
  Future<bool> startDeleteAccountOtp() async {
    final email = _user?.email.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;

    _setLoading(true);
    try {
      await _supabase.auth.signInWithOtp(email: email);
      _pendingDeleteEmail = email;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('startDeleteAccountOtp error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Optional: resend OTP for delete flow.
  Future<bool> resendDeleteOtp() async {
    if (_loading) return false;

    final email = _pendingDeleteEmail;
    if (email == null || email.isEmpty) return false;

    _setLoading(true);
    try {
      await _supabase.auth.signInWithOtp(email: email);
      return true;
    } catch (e) {
      debugPrint('resendDeleteOtp error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Step 2: Verify OTP, then invoke Edge Function to delete Auth user, then wipe local.
  Future<bool> verifyDeleteOtpAndDeleteAccount({required String otp}) async {
    final email = _pendingDeleteEmail;
    if (email == null || email.isEmpty) return false;

    _setLoading(true);
    try {
      // (A) Verify OTP -> creates a Supabase session
      final verifyRes = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp.trim(),
      );

      final accessToken =
          verifyRes.session?.accessToken ?? _supabase.auth.currentSession?.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('Delete OTP verified but accessToken is null/empty.');
        return false;
      }

      // // Debug: print first chars to prove we have a JWT
      // debugPrint('Delete accessToken prefix: ${accessToken.substring(0, 20)}');

      // // (B) Validate the JWT against THIS project
      // final check = await _supabase.auth.getUser(accessToken);
      // if (check.user == null) {
      //   debugPrint('JWT validation failed: getUser returned null user');
      //   return false;
      // }
      // debugPrint('JWT valid for userId=${check.user!.id}');

      // (C) Call Edge Function (SDK invoke)
      final fnRes = await _supabase.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (fnRes.status != 200) {
        debugPrint('delete-account failed: ${fnRes.status} ${fnRes.data}');
        return false;
      }

      _pendingDeleteEmail = null;

      // (D) Wipe local + logout (your existing local delete)
      final okLocal = await deleteLocalAccount();
      return okLocal;
    } catch (e) {
      debugPrint('verifyDeleteOtpAndDeleteAccount error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------
  // Password policy + helpers
  // ----------------------------
  bool passwordMeetsPolicy(String password) {
    if (password.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*()_\-+=\[\]{};:"\\|,.<>/?`~]').hasMatch(password);
    return hasUpper && hasSpecial;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}