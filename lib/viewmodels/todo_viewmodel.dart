import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class TodoViewModel extends ChangeNotifier {
  final List<TodoModel> _todos = [];
  List<TodoModel> get todos => List.unmodifiable(_todos);

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadTodos() async {
    _setLoading(true);
    await DatabaseService.instance.init();

    _todos.clear();
    final box = DatabaseService.instance.todosBox;

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        _todos.add(TodoModel.fromMap(Map<String, dynamic>.from(raw)));
      }
    }

    _todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setLoading(false);
  }

  Future<void> addTodo({
    required String title,
    required String sensitiveNotePlain,
  }) async {
    await DatabaseService.instance.init();

    final encryptedNote = await EncryptionService.instance.encryptNote(sensitiveNotePlain);

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final todo = TodoModel(
      id: id,
      title: title,
      encryptedNote: encryptedNote,
      isDone: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await DatabaseService.instance.todosBox.put(id, todo.toMap());
    _todos.insert(0, todo);
    notifyListeners();
  }

  Future<void> toggleDone(TodoModel todo) async {
    final updated = todo.copyWith(isDone: !todo.isDone);
    await DatabaseService.instance.todosBox.put(todo.id, updated.toMap());

    final idx = _todos.indexWhere((t) => t.id == todo.id);
    if (idx != -1) _todos[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteTodo(String id) async {
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