import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_model.dart';
import '../services/avatar_service.dart';
import '../services/database_service.dart';
import '../services/key_storage_service.dart';
import '../utils/constants.dart';

class PendingMiniSnackBar {
  final String message;
  final bool success;

  const PendingMiniSnackBar({
    required this.message,
    required this.success,
  });
}

class AuthViewModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  UserModel? _user;
  UserModel? get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  /// Current local avatar file.  Null when none has been set.
  File? _avatarFile;
  File? get avatarFile => _avatarFile;

  /// Incremented on every avatar change so Image.file widgets bust their cache.
  int _avatarVersion = 0;
  int get avatarVersion => _avatarVersion;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _pendingEmail;
  String? _pendingName;
  String? _pendingPasswordHash;

  bool get awaitingOtp => _pendingEmail != null;

  String? _pendingDeleteEmail;
  bool get awaitingDeleteOtp => _pendingDeleteEmail != null;
  String? get pendingDeleteEmail => _pendingDeleteEmail;

  // ── avatar ─────────────────────────────────────────────────────────────────

  Future<void> loadAvatar() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      _avatarFile = null;
      return;
    }
    _avatarFile = await AvatarService.instance.loadAvatar(email);
    notifyListeners();
  }


  PendingMiniSnackBar? _pendingMiniSnackBar;

    void setPendingMiniSnackBar({
      required String message,
      required bool success,
    }) {
      _pendingMiniSnackBar = PendingMiniSnackBar(
        message: message,
        success: success,
      );
    }

    PendingMiniSnackBar? takePendingMiniSnackBar() {
      final value = _pendingMiniSnackBar;
      _pendingMiniSnackBar = null;
      return value;
    }

  /// Opens the gallery picker, saves the file, evicts the old image from
  /// Flutter's in-memory ImageCache, then bumps [avatarVersion] so every
  /// Image.file widget rebuilds with fresh bytes.
  Future<bool> updateAvatar() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) return false;

    _setLoading(true);
    try {
      final file = await AvatarService.instance.pickAndSaveAvatar(email);
      if (file == null) return false;

      // Evict ALL cached entries for this file. Flutter stores separate cache
      // entries per (file, cacheWidth, cacheHeight) combination, so we clear
      // the full live+pending cache to guarantee no stale pixels survive.
      imageCache.evict(FileImage(file));
      imageCache.clearLiveImages();

      _avatarFile = file;
      _avatarVersion = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeAvatar() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) return;

    await AvatarService.instance.deleteAvatar(email);
    _avatarFile = null;
    _avatarVersion = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  // ── core auth ──────────────────────────────────────────────────────────────

  Future<void> loadUser() async {
    await DatabaseService.instance.init();

    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser != null) {
      final email = (supabaseUser.email ?? '').trim().toLowerCase();
      final metadata = supabaseUser.userMetadata ?? {};
      final fullName =
          (metadata['full_name'] ??
                  metadata['name'] ??
                  metadata['display_name'] ??
                  email.split('@').first)
              .toString()
              .trim();

      if (email.isNotEmpty) {
        final profile = UserModel(email: email, displayName: fullName);

        final box = DatabaseService.instance.userBox;
        await box.put(email, profile.toMap());
        await box.put('profile', profile.toMap());

        _user = profile;
        _isAuthenticated = true;
        await loadAvatar();
        notifyListeners();
        return;
      }
    }

    final box = DatabaseService.instance.userBox;
    final data = box.get('profile');
    if (data is Map) {
      _user = UserModel.fromMap(Map<String, dynamic>.from(data));
    } else {
      _user = null;
    }

    _isAuthenticated = false;
    await loadAvatar();
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

      final existing = usersBox.get(normalizedEmail);
      if (existing is Map) return false;

      final hash = _hashPassword(password);
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
    if (_pendingEmail == null ||
        _pendingPasswordHash == null ||
        _pendingName == null) {
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
      await KeyStorageService.instance.setString(
        AppConstants.kPasswordEverSet,
        'true',
      );

      _user = profile;
      _isAuthenticated = true;

      _pendingEmail = null;
      _pendingName = null;
      _pendingPasswordHash = null;

      await loadAvatar();
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
      await KeyStorageService.instance.setString(
        AppConstants.kPasswordEverSet,
        'true',
      );

      _user = profile;
      _isAuthenticated = true;
      await loadAvatar();
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> canUseBiometrics() async {
    await DatabaseService.instance.init();

    final ever = await KeyStorageService.instance.getString(
      AppConstants.kPasswordEverSet,
    );
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

  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;
    _avatarFile = null;
    _avatarVersion = DateTime.now().millisecondsSinceEpoch;

    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    notifyListeners();
  }

  Future<bool> updateDisplayName(String newName) async {
    try {
      if (_user == null) return false;

      final updated = UserModel(
        email: _user!.email,
        displayName: newName.trim(),
      );

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

  Future<bool> deleteLocalAccount() async {
    try {
      final email = _user?.email;

      if (email != null && email.isNotEmpty) {
        await AvatarService.instance.deleteAvatar(email);
      }

      await DatabaseService.instance.init();
      await DatabaseService.instance.clearAll();

      if (email != null && email.isNotEmpty) {
        await KeyStorageService.instance.delete(
          AppConstants.passwordKeyForEmail(email),
        );
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

  Future<bool> verifyDeleteOtpAndDeleteAccount({required String otp}) async {
    final email = _pendingDeleteEmail;
    if (email == null || email.isEmpty) return false;

    _setLoading(true);
    try {
      final verifyRes = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp.trim(),
      );

      final accessToken =
          verifyRes.session?.accessToken ??
          _supabase.auth.currentSession?.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('Delete OTP verified but accessToken is null/empty.');
        return false;
      }

      final fnRes = await _supabase.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (fnRes.status != 200) {
        debugPrint('delete-account failed: ${fnRes.status} ${fnRes.data}');
        return false;
      }

      _pendingDeleteEmail = null;

      final okLocal = await deleteLocalAccount();
      return okLocal;
    } catch (e) {
      debugPrint('verifyDeleteOtpAndDeleteAccount error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool passwordMeetsPolicy(String password) {
    if (password.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasSpecial = RegExp(
      r'[!@#$%^&*()_\-+=\[\]{};:"\\|,.<>/?`~]',
    ).hasMatch(password);
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

  Future<bool> signInWithGoogle() async {
    if (_loading) return false;

    _setLoading(true);
    try {
      final didLaunch = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.ciphertask.app://login-callback',
        authScreenLaunchMode:
            kIsWeb
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication,
        scopes: 'email profile openid',
      );
      return didLaunch;
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithFacebook() async {
    if (_loading) return false;

    _setLoading(true);
    try {
      final didLaunch = await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'com.ciphertask.app://login-callback',
        authScreenLaunchMode:
            kIsWeb
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication,
        scopes: 'email,public_profile',
      );
      return didLaunch;
    } catch (e) {
      debugPrint('signInWithFacebook error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncSupabaseUserToLocal() async {
    try {
      await DatabaseService.instance.init();

      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser == null) return;

      final email = (supabaseUser.email ?? '').trim().toLowerCase();
      if (email.isEmpty) return;

      final metadata = supabaseUser.userMetadata ?? {};
      final fullName =
          (metadata['full_name'] ??
                  metadata['name'] ??
                  metadata['display_name'] ??
                  email.split('@').first)
              .toString()
              .trim();

      final profile = UserModel(email: email, displayName: fullName);

      final usersBox = DatabaseService.instance.userBox;
      await usersBox.put(email, profile.toMap());
      await usersBox.put('profile', profile.toMap());

      _user = profile;
      _isAuthenticated = true;
      await loadAvatar();
      notifyListeners();
    } catch (e) {
      debugPrint('syncSupabaseUserToLocal error: $e');
    }
  }
  String? _pendingOAuthSnackBarMessage;

  String? takePendingOAuthSnackBarMessage() {
    final msg = _pendingOAuthSnackBarMessage;
    _pendingOAuthSnackBarMessage = null;
    return msg;
  }

  void setPendingOAuthSnackBarMessage(String message) {
    _pendingOAuthSnackBarMessage = message;
  }
}