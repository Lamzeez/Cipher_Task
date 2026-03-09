import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'CipherTask';

  // Hive boxes
  static const String boxTodos = 'todos_box';
  static const String boxUser = 'user_box';

  // Secure Storage keys
  static const String kDbKey = 'db_encryption_key_b64';
  static const String kAesKey = 'aes_256_key_b64';
  static const String kPasswordHash = 'user_password_hash';
  static const String kPasswordEverSet = 'password_ever_set';

  static String passwordKeyForEmail(String email) =>
      'pwd_hash_${email.toLowerCase()}';

  // Session
  static const int sessionTimeoutSeconds = 120;
  static const int sessionWarningBeforeSeconds = 30;
}

class AppColors {
  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF9F9F9);
  static const Color surfaceAlt = Color(0xFFEAF1FB);

  static const Color primary = Color(0xFF2F73D9);
  static const Color primaryLight = Color(0xFF4A8AF4);
  static const Color primaryDark = Color(0xFF1F67C8);

  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textMuted = Color(0xFF8A8A8A);

  static const Color border = Color(0xFFE3E3E3);
  static const Color borderSoft = Color(0xFFECECEC);

  static const Color success = Color(0xFF1F9D55);
  static const Color warning = Color(0xFFE98A15);
  static const Color danger = Colors.redAccent;
}

ThemeData buildAppTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      elevation: 0,
      contentTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.borderSoft),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSoft,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      side: const BorderSide(color: Color(0xFF9A9A9A), width: 1.3),
    ),
  );
}