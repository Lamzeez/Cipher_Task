import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'CipherTask';

  // Hive boxes (encrypted DB file)
  static const String boxTodos = 'todos_box';
  static const String boxUser = 'user_box';

  // Secure Storage keys
  static const String kDbKey = 'db_encryption_key_b64';
  static const String kAesKey = 'aes_256_key_b64';
  static const String kPasswordHash = 'user_password_hash';
  static const String kPasswordEverSet =
      'password_ever_set'; // "true"/"false"
  static String passwordKeyForEmail(String email) =>
      'pwd_hash_${email.toLowerCase()}';

  // Session
  static const int sessionTimeoutSeconds = 120; // 2 minutes
  static const int sessionWarningBeforeSeconds = 30; // warn 30s before timeout
}


/// Cyberpunk / neon color palette (purple / blue)
class AppColors {
  static const Color background = Color(0xFF050816); // deep space
  static const Color surface = Color(0xFF0B1120); // dark panel
  static const Color surfaceAlt = Color(0xFF111827); // card-ish

  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color neonBlue = Color(0xFF38BDF8);
  static const Color neonPink = Color(0xFFEC4899);

  static const Color textPrimary = Colors.white;
  static const Color textMuted = Color(0xFF9CA3AF);
}

/// Global Cyberpunk theme
ThemeData buildCyberpunkTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.neonPurple,
      secondary: AppColors.neonBlue,
      background: AppColors.background,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceAlt.withOpacity(0.97),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceAlt.withOpacity(0.93),
      elevation: 10,
      shadowColor: AppColors.neonPurple.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: AppColors.neonPurple,
          width: 0.5,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        backgroundColor: AppColors.neonPurple,
        foregroundColor: Colors.white,
        elevation: 6,
        shadowColor: AppColors.neonBlue.withOpacity(0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        side: const BorderSide(color: AppColors.neonBlue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        foregroundColor: AppColors.neonBlue,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface.withOpacity(0.95),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.neonBlue,
          width: 2,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.neonPink,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
  );
}
