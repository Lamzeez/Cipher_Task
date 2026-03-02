import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/key_storage_service.dart';
import '../utils/constants.dart';
import 'package:flutter/services.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  UserModel? _user;
  UserModel? get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> loadUser() async {
    await DatabaseService.instance.init();

    final box = DatabaseService.instance.userBox;
    final data = box.get('profile');
    if (data is Map) {
      _user = UserModel.fromMap(Map<String, dynamic>.from(data));
    } else {
      _user = null;
    }
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    await DatabaseService.instance.init();

    final hash = _hashPassword(password);
    await KeyStorageService.instance.setString(AppConstants.kPasswordHash, hash);
    await KeyStorageService.instance.setString(AppConstants.kPasswordEverSet, 'true');

    // Save profile in encrypted Hive box
    final profile = UserModel(email: email, displayName: fullName);
    await DatabaseService.instance.userBox.put('profile', profile.toMap());
    _user = profile;

    _isAuthenticated = true;
    _setLoading(false);
    notifyListeners();
  }

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

      await loadUser();
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> canUseBiometrics() async {
    final flag = await KeyStorageService.instance.getString(AppConstants.kPasswordEverSet);
    if (flag != 'true') return false;

    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> loginWithPassword(String password) async {
    if (_loading) return false;

    _setLoading(true);
    try {
      await DatabaseService.instance.init();

      final stored = await KeyStorageService.instance.getString(AppConstants.kPasswordHash);
      if (stored == null) return false;

      final ok = stored == _hashPassword(password);
      if (!ok) return false;

      await KeyStorageService.instance.setString(AppConstants.kPasswordEverSet, 'true');
      await loadUser();
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;        // optional but cleaner for security
    notifyListeners();
  }

  bool passwordMeetsPolicy(String password) {
    // min 8, 1 uppercase, 1 special
    if (password.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*()_\-+=\[\]{};:"\\|,.<>/?`~]').hasMatch(password);
    return hasUpper && hasSpecial;
  }

  String _hashPassword(String password) {
    // Stored hash only (never store raw password)
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}