import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/constants.dart';
import 'key_storage_service.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  bool _initialized = false;

  Future<void> init() async {
    // 1) Make sure Hive itself is initialized ONCE
    if (!_initialized) {
      await Hive.initFlutter();
      _initialized = true;
    }

    // 2) Get / create the encryption key for the DB file
    final dbKeyBytes =
        await KeyStorageService.instance.getOrCreateDbKeyBytes();
    final cipher = HiveAesCipher(dbKeyBytes);

    // 3) Ensure both boxes are open (re-open them if they were deleted)
    if (!Hive.isBoxOpen(AppConstants.boxTodos)) {
      await Hive.openBox(
        AppConstants.boxTodos,
        encryptionCipher: cipher,
      );
    }

    if (!Hive.isBoxOpen(AppConstants.boxUser)) {
      await Hive.openBox(
        AppConstants.boxUser,
        encryptionCipher: cipher,
      );
    }
  }

  Box get todosBox => Hive.box(AppConstants.boxTodos);
  Box get userBox => Hive.box(AppConstants.boxUser);

  /// Logically “delete everything” but keep boxes & encryption intact.
  Future<void> clearAll() async {
    await todosBox.clear();
    await userBox.clear();
  }
}