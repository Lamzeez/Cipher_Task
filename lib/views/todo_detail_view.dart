import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../utils/snack_bar.dart';

class TodoDetailView extends StatelessWidget {
  final TodoModel todo;
  const TodoDetailView({super.key, required this.todo});

  String _formatCreatedAt(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();

    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridiem = dt.hour >= 12 ? 'PM' : 'AM';

    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');

    String datePart = '$mm-$dd';
    if (dt.year != now.year) {
      final yy = (dt.year % 100).toString().padLeft(2, '0');
      datePart = '$mm-$dd-$yy';
    }

    return '$hour:$minute$meridiem $datePart';
  }

  InputDecoration _dialogFieldDecoration(String label) {
    final radius = BorderRadius.circular(16);

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFF101B38),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.white24, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.white24, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFF9B7BFF), width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoViewModel>(
      builder: (context, vm, _) {
        final TodoModel current = vm.todos.any((t) => t.id == todo.id)
            ? vm.todos.firstWhere((t) => t.id == todo.id)
            : todo;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'Task Details',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
                onPressed: () async {
                  await _showEditDialog(context, vm, current);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirmed = await _confirmDelete(context);
                  if (confirmed != true) return;

                  await vm.deleteTodo(current.id);

                  if (context.mounted) {
                    showMiniSnackBar(context, 'Task deleted successfully.');
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: FutureBuilder<String>(
            future: vm.decryptNote(current.encryptedNote),
            builder: (context, snap) {
              final note = snap.connectionState == ConnectionState.done
                  ? (snap.data ?? '')
                  : '';

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopTaskCard(
                      title: current.title,
                      isDone: current.isDone,
                      timestampText: _formatCreatedAt(current.createdAt),
                      onToggleDone: () => vm.toggleDone(current),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFFB79CFF),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Sensitive Note',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 220),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101B38),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: snap.connectionState == ConnectionState.done
                                ? SelectableText(
                                    note.trim().isEmpty ? '(empty)' : note,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Decrypting...',
                                        style: TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: current.isDone
                                ? Icons.refresh_rounded
                                : Icons.task_alt_rounded,
                            label: current.isDone
                                ? 'Mark as Pending'
                                : 'Mark as Done',
                            backgroundColor: current.isDone
                                ? const Color(0xFF24304F)
                                : const Color(0xFF8B5CF6),
                            onPressed: () => vm.toggleDone(current),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.edit_rounded,
                            label: 'Edit Task',
                            backgroundColor: const Color(0xFF24304F),
                            onPressed: () async {
                              await _showEditDialog(context, vm, current);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
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
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: _dialogFieldDecoration('Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                minLines: 3,
                maxLines: 5,
                decoration: _dialogFieldDecoration(
                  'Sensitive Note (will be re-encrypted)',
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
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
        showMiniSnackBar(context, 'Title cannot be empty.');
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
      showMiniSnackBar(context, 'Task updated successfully.');
    }

    titleController.dispose();
    noteController.dispose();
  }
}

class _TopTaskCard extends StatelessWidget {
  final String title;
  final bool isDone;
  final String timestampText;
  final VoidCallback onToggleDone;

  const _TopTaskCard({
    required this.title,
    required this.isDone,
    required this.timestampText,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF121E3D),
            Color(0xFF0E1730),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green.withOpacity(0.14)
                      : Colors.orange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isDone ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDone ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timestampText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w800,
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone ? Colors.white70 : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Transform.scale(
                scale: 1.05,
                child: Checkbox(
                  value: isDone,
                  onChanged: (_) => onToggleDone(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: const BorderSide(color: Colors.white54, width: 1.3),
                ),
              ),
              Text(
                isDone ? 'This task is done' : 'This task is still pending',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1730),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}