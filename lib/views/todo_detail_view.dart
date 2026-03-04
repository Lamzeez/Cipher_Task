import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../viewmodels/todo_viewmodel.dart';

class TodoDetailView extends StatelessWidget {
  final TodoModel todo;
  const TodoDetailView({super.key, required this.todo});

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
    return Consumer<TodoViewModel>(
      builder: (context, vm, _) {
        // Get latest todo from VM (so UI reflects updates immediately)
        final TodoModel current = vm.todos.any((t) => t.id == todo.id)
            ? vm.todos.firstWhere((t) => t.id == todo.id)
            : todo;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () async {
                  await _showEditDialog(context, vm, current);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirmed = await _confirmDelete(context);
                  if (confirmed != true) return;

                  await vm.deleteTodo(current.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      _miniSnackBar('Task deleted successfully.'),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<String>(
              future: vm.decryptNote(current.encryptedNote),
              builder: (context, snap) {
                final note = (snap.connectionState == ConnectionState.done)
                    ? (snap.data ?? '')
                    : '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: current.isDone,
                          onChanged: (_) => vm.toggleDone(current),
                        ),
                        Text(
                          current.isDone ? 'Done' : 'Pending',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => vm.toggleDone(current),
                          child: Text(
                            current.isDone
                                ? 'Mark as Pending'
                                : 'Mark as Done',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Sensitive Note',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            snap.connectionState == ConnectionState.done
                                ? (note.trim().isEmpty ? '(empty)' : note)
                                : 'Decrypting...',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    TodoViewModel vm,
    TodoModel current,
  ) async {
    final titleController = TextEditingController(text: current.title);

    // We need the decrypted note as initial value
    final decrypted = await vm.decryptNote(current.encryptedNote);
    final noteController = TextEditingController(text: decrypted);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Sensitive Note (will be re-encrypted)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) {
      titleController.dispose();
      noteController.dispose();
      return;
    }

    final newTitle = titleController.text.trim();
    final newNote = noteController.text.trim();

    if (newTitle.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _miniSnackBar('Title cannot be empty.'),
        );
      }
      titleController.dispose();
      noteController.dispose();
      return;
    }

    await vm.updateTodo(
      id: current.id,
      title: newTitle,
      sensitiveNotePlain: newNote,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        _miniSnackBar('Task updated successfully.'),
      );
    }

    // Controllers auto-dispose when dialog closes, but safe:
    titleController.dispose();
    noteController.dispose();
  }
}