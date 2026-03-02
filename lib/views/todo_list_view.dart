import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../models/todo_model.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  final _title = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TodoViewModel>().loadTodos());
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final todoVm = context.watch<TodoViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('CipherTask - ${auth.user?.displayName ?? ''}'),
        actions: [
          IconButton(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.lock),
            tooltip: 'Lock',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'Sensitive Note (AES-256 encrypted)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_title.text.trim().isEmpty) return;
                    await todoVm.addTodo(
                      title: _title.text.trim(),
                      sensitiveNotePlain: _note.text.trim(),
                    );
                    _title.clear();
                    _note.clear();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Encrypted Task'),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: todoVm.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: todoVm.todos.length,
                    itemBuilder: (_, i) => _TodoTile(todo: todoVm.todos[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final TodoModel todo;
  const _TodoTile({required this.todo});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TodoViewModel>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(todo.title),
        subtitle: FutureBuilder<String>(
          future: vm.decryptNote(todo.encryptedNote),
          builder: (context, snap) => Text(
            snap.hasData ? 'Note: ${snap.data}' : 'Decrypting...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: Checkbox(
          value: todo.isDone,
          onChanged: (_) => vm.toggleDone(todo),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => vm.deleteTodo(todo.id),
        ),
      ),
    );
  }
}