import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../models/todo_model.dart';
import 'todo_detail_view.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _note = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load todos for the current user after the first frame
    Future.microtask(() {
      final auth = context.read<AuthViewModel>();
      final email = auth.user?.email;
      if (email != null && email.isNotEmpty) {
        context.read<TodoViewModel>().loadTodosForUser(email);
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  SnackBar _miniSnackBar(String msg) {
    return SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final todoVm = context.watch<TodoViewModel>();

    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(
        title: Text('CipherTask - ${auth.user?.displayName ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: 'Lock',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text(
                    'Your encrypted tasks will remain stored locally, '
                    'but this session will end.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await auth.logout();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  _miniSnackBar('Logged out successfully.'),
                );
              }
            },
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
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(
                        color: Colors.white70,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  decoration: InputDecoration(
                    labelText: 'Sensitive Note (AES-256 encrypted)',
                    border: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(
                        color: Colors.white70,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.2,
                      ),
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_title.text.trim().isEmpty) return;

                    if (auth.user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        _miniSnackBar('No authenticated user.'),
                      );
                      return;
                    }

                    await todoVm.addTodo(
                      title: _title.text.trim(),
                      sensitiveNotePlain: _note.text.trim(),
                      ownerEmail: auth.user!.email,
                    );

                    _title.clear();
                    _note.clear();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        _miniSnackBar('Task created successfully.'),
                      );
                    }
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

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'Are you sure you want to delete "${todo.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  SnackBar _miniSnackBar(String msg) {
    return SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TodoViewModel>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TodoDetailView(todo: todo),
            ),
          );
        },
        leading: Checkbox(
          value: todo.isDone,
          onChanged: (_) => vm.toggleDone(todo),
        ),
        title: Text(
          todo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            decoration: todo.isDone
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: FutureBuilder<String>(
          future: vm.decryptNote(todo.encryptedNote),
          builder: (context, snap) => Text(
            snap.hasData ? 'Note: ${snap.data}' : 'Decrypting...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            final confirmed = await _confirmDelete(context);
            if (confirmed != true) return;

            await vm.deleteTodo(todo.id);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _miniSnackBar('Task deleted successfully.'),
              );
            }
          },
        ),
      ),
    );
  }
}