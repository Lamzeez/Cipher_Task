import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class TodoViewModel extends ChangeNotifier {
  final List<TodoModel> _todos = [];
  List<TodoModel> get todos => List.unmodifiable(_todos);

  final Map<String, String> _decryptedNotes = {};
  String decryptedNoteFor(String id) => _decryptedNotes[id] ?? '';

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
      _decryptedNotes.clear();

      final box = DatabaseService.instance.todosBox;

      for (final value in box.values) {
        if (value is! Map) continue;

        final raw = Map<String, dynamic>.from(value as Map);

        final email = raw['ownerEmail'] as String? ?? '';
        if (email != ownerEmail) continue;

        try {
          final todo = TodoModel.fromMap(raw);
          _todos.add(todo);
        } catch (_) {
          // ignore malformed record instead of crashing
        }
      }

      _todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      await _primeDecryptedNotes();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _primeDecryptedNotes() async {
    for (final todo in _todos) {
      try {
        _decryptedNotes[todo.id] =
            await EncryptionService.instance.decryptNote(todo.encryptedNote);
      } catch (_) {
        _decryptedNotes[todo.id] = '';
      }
    }
    notifyListeners();
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

      debugPrint('TODO TITLE (plain): $title');
      debugPrint('TODO DETAIL (plain): $sensitiveNotePlain');
      debugPrint('TODO DETAIL (encrypted): $encryptedNote');

      final todo = TodoModel(
        id: id,
        title: title,
        encryptedNote: encryptedNote,
        isDone: false,
        createdAt: now,
        ownerEmail: ownerEmail,
      );

      debugPrint('Saving todo to Hive...');
      debugPrint('ownerEmail: $ownerEmail');
      debugPrint('encryptedNote to save: $encryptedNote');

      await box.put(id, todo.toMap());
      _todos.insert(0, todo);
      _decryptedNotes[id] = sensitiveNotePlain;
      notifyListeners();
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
      _decryptedNotes[id] = sensitiveNotePlain;
      notifyListeners();
    }
  }

  Future<void> deleteTodo(String id) async {
    await DatabaseService.instance.init();
    await DatabaseService.instance.todosBox.delete(id);
    _todos.removeWhere((t) => t.id == id);
    _decryptedNotes.remove(id);
    notifyListeners();
  }

  Future<void> deleteMultipleTodos(List<String> ids) async {
    if (ids.isEmpty) return;

    await DatabaseService.instance.init();
    final box = DatabaseService.instance.todosBox;

    await box.deleteAll(ids);

    _todos.removeWhere((t) => ids.contains(t.id));
    for (final id in ids) {
      _decryptedNotes.remove(id);
    }

    notifyListeners();
  }

  List<TodoModel> getFilteredTodos(String query) {
    final trimmed = query.trim().toLowerCase();

    final base = <TodoModel>[
      ..._todos.where((t) => !t.isDone),
      ..._todos.where((t) => t.isDone),
    ];

    if (trimmed.isEmpty) return base;

    return base.where((todo) {
      final titleMatch = todo.title.toLowerCase().contains(trimmed);
      final noteMatch =
          (_decryptedNotes[todo.id] ?? '').toLowerCase().contains(trimmed);
      return titleMatch || noteMatch;
    }).toList();
  }

  Future<String> decryptNote(String cipher) {
    return EncryptionService.instance.decryptNote(cipher);
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}