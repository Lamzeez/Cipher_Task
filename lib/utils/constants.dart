class AppConstants {
  static const String appName = 'CipherTask';

  // Hive boxes (encrypted DB file)
  static const String boxTodos = 'todos_box';
  static const String boxUser = 'user_box';

  // Secure Storage keys
  static const String kDbKey = 'db_encryption_key_b64';
  static const String kAesKey = 'aes_256_key_b64';
  static const String kPasswordHash = 'user_password_hash';
  static const String kPasswordEverSet = 'password_ever_set'; // "true"/"false"
  static String passwordKeyForEmail(String email) => 'pwd_hash_${email.toLowerCase()}';

  // Session
  static const int sessionTimeoutSeconds = 120; // 2 minutes
}