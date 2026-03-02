import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class TodoViewModel extends ChangeNotifier {
  final List<TodoModel> _todos = [];
  List<TodoModel> get todos => List.unmodifiable(_todos);

  bool _loading = false;
  bool get loading => _loading;

  String? _currentOwnerEmail;
  String? get currentOwnerEmail => _currentOwnerEmail;

  /// Load todos belonging only to [ownerEmail]
  Future<void> loadTodosForUser(String ownerEmail) async {
    _setLoading(true);
    try {
      await DatabaseService.instance.init();

      _currentOwnerEmail = ownerEmail;
      _todos.clear();

      final box = DatabaseService.instance.todosBox;

      for (final value in box.values) {
        if (value is! Map) continue;

        final raw = Map<String, dynamic>.from(value as Map);

        // Skip records that don't belong to this user
        final email = raw['ownerEmail'] as String? ?? '';
        if (email != ownerEmail) continue;

        try {
          final todo = TodoModel.fromMap(raw);
          _todos.add(todo);
        } catch (_) {
          // ignore malformed record instead of crashing
        }
      }

      // Newest first
      _todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } finally {
      _setLoading(false);
    }
  }

  /// Create a todo for [ownerEmail]
  Future<void> addTodo({
    required String title,
    required String sensitiveNotePlain,
    required String ownerEmail,
  }) async {
    _setLoading(true);
    try {
      await DatabaseService.instance.init();
      final box = DatabaseService.instance.todosBox;

      final now = DateTime.now().millisecondsSinceEpoch;
      final id = now.toString();

      final encryptedNote =
          await EncryptionService.instance.encryptNote(sensitiveNotePlain);

      final todo = TodoModel(
        id: id,
        title: title,
        encryptedNote: encryptedNote,
        isDone: false,
        createdAt: now,
        ownerEmail: ownerEmail,
      );

      await box.put(id, todo.toMap());
      _todos.insert(0, todo);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleDone(TodoModel todo) async {
    await DatabaseService.instance.init();
    final box = DatabaseService.instance.todosBox;

    final updated = todo.copyWith(isDone: !todo.isDone);
    await box.put(updated.id, updated.toMap());

    final idx = _todos.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _todos[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> updateTodo({
    required String id,
    required String title,
    required String sensitiveNotePlain,
  }) async {
    await DatabaseService.instance.init();
    final box = DatabaseService.instance.todosBox;

    final existing = box.get(id);
    if (existing is! Map) return;

    var todo = TodoModel.fromMap(Map<String, dynamic>.from(existing));

    final encryptedNote =
        await EncryptionService.instance.encryptNote(sensitiveNotePlain);

    todo = todo.copyWith(
      title: title,
      encryptedNote: encryptedNote,
    );

    await box.put(id, todo.toMap());

    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _todos[idx] = todo;
      notifyListeners();
    }
  }

  Future<void> deleteTodo(String id) async {
    await DatabaseService.instance.init();
    await DatabaseService.instance.todosBox.delete(id);
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<String> decryptNote(String cipher) {
    return EncryptionService.instance.decryptNote(cipher);
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}