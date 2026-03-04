import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import 'profile_view.dart';
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

    // Load todos for the current user after first frame
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

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your encrypted tasks will remain stored locally, but this session will end.',
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
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final todoVm = context.watch<TodoViewModel>();

    final displayName = (auth.user?.displayName ?? '').trim();
    final titleText =
        displayName.isEmpty ? 'CipherTask' : 'Welcome!\n$displayName';

    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CipherTask'),
        centerTitle: true,
        // Logout removed and placed in header area
      ),
      body: Column(
        children: [
          // HEADER AREA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logout button aligned to the right, below title
                Row(
                  children: [
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final confirmed = await _confirmLogout(context);
                        if (confirmed != true) return;

                        await context.read<AuthViewModel>().logout();

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          _miniSnackBar('Logged out successfully.'),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.lock, color: Colors.redAccent),
                            SizedBox(width: 6),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Title + profile button row
                Row(
                  children: [
                    Expanded(
                        child: Text(
                          titleText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 20) - 3,
                              ),
                        ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Profile',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileView()),
                        );
                      },
                      icon: const Icon(Icons.person),
                    ),
                  ],
                ),

                
              ],
            ),
          ),

            // Removed divider between Add Task and list

          // CREATE TODO SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                children: [
                TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(color: Colors.white, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide:
                          const BorderSide(color: Colors.white70, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide:
                          const BorderSide(color: Colors.white, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  decoration: InputDecoration(
                    labelText: 'Sensitive task details',
                    border: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: const BorderSide(color: Colors.white, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide:
                          const BorderSide(color: Colors.white70, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide:
                          const BorderSide(color: Colors.white, width: 1.2),
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_title.text.trim().isEmpty) return;

                    final user = auth.user;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        _miniSnackBar('No authenticated user.'),
                      );
                      return;
                    }

                    await todoVm.addTodo(
                      title: _title.text.trim(),
                      sensitiveNotePlain: _note.text.trim(),
                      ownerEmail: user.email,
                    );

                    _title.clear();
                    _note.clear();

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      _miniSnackBar('Task created successfully.'),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
                  const SizedBox(height: 18), // Add margin below Add Task button
              ],
            ),
          ),

            // Removed divider between Add Task and list

          // LIST
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
        content: Text('Are you sure you want to delete "${todo.title}"?'),
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
            MaterialPageRoute(builder: (_) => TodoDetailView(todo: todo)),
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
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: FutureBuilder<String>(
          future: vm.decryptNote(todo.encryptedNote),
          builder: (context, snap) => Text(
            snap.hasData ? '${snap.data}' : 'Decrypting...',
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

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              _miniSnackBar('Task deleted successfully.'),
            );
          },
        ),
      ),
    );
  }
}