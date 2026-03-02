import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import 'key_storage_service.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    final dbKey = await KeyStorageService.instance.getOrCreateDbKeyBytes();
    // Open encrypted boxes (database file is encrypted)
    await Hive.openBox(AppConstants.boxTodos, encryptionCipher: HiveAesCipher(dbKey));
    await Hive.openBox(AppConstants.boxUser, encryptionCipher: HiveAesCipher(dbKey));

    _initialized = true;
  }

  Box get todosBox => Hive.box(AppConstants.boxTodos);
  Box get userBox => Hive.box(AppConstants.boxUser);

  Future<void> clearAll() async {
    await todosBox.clear();
    await userBox.clear();
  }
}