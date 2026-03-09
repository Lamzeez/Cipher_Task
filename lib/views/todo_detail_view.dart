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

    return '$hour:$minute $meridiem • $datePart';
  }

  InputDecoration _dialogFieldDecoration(String label) {
    final radius = BorderRadius.circular(16);

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF6F6F6F),
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFE3E3E3), width: 1.3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFE3E3E3), width: 1.3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFF2F73D9), width: 1.5),
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
          backgroundColor: const Color(0xFFF5F6F8),
          body: FutureBuilder<String>(
            future: vm.decryptNote(current.encryptedNote),
            builder: (context, snap) {
              final note = snap.connectionState == ConnectionState.done
                  ? (snap.data ?? '')
                  : '';

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: const Color(0xFFF5F6F8),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    pinned: true,
                    centerTitle: true,
                    title: const Text(
                      'Task Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
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
                            showMiniSnackBar(
                              context,
                              'Task deleted successfully.',
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
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
                                      color: Color(0xFF2F73D9),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Sensitive Note',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  constraints:
                                      const BoxConstraints(minHeight: 220),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE3E3E3),
                                    ),
                                  ),
                                  child: snap.connectionState ==
                                          ConnectionState.done
                                      ? SelectableText(
                                          note.trim().isEmpty ? '(empty)' : note,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: Colors.black87,
                                          ),
                                        )
                                      : const Row(
                                          children: [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Decrypting...',
                                              style: TextStyle(
                                                color: Color(0xFF6F6F6F),
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
                                      ? 'Mark Pending'
                                      : 'Mark Done',
                                  backgroundColor: current.isDone
                                      ? const Color(0xFFEAF1FB)
                                      : const Color(0xFF2F73D9),
                                  foregroundColor: current.isDone
                                      ? const Color(0xFF2F73D9)
                                      : Colors.white,
                                  onPressed: () => vm.toggleDone(current),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.edit_rounded,
                                  label: 'Edit Task',
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF2F73D9),
                                  borderColor: const Color(0xFFD6E4FA),
                                  onPressed: () async {
                                    await _showEditDialog(context, vm, current);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        title: const Text(
          'Edit task',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.black87),
                cursorColor: const Color(0xFF2F73D9),
                decoration: _dialogFieldDecoration('Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: const TextStyle(color: Colors.black87),
                cursorColor: const Color(0xFF2F73D9),
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
              backgroundColor: const Color(0xFF2F73D9),
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
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4A8AF4),
            Color(0xFF1F67C8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F73D9).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                      ? Colors.white.withOpacity(0.20)
                      : Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isDone ? 'Completed' : 'Pending',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timestampText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
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
              color: Colors.white,
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
                  activeColor: Colors.white,
                  checkColor: const Color(0xFF2F73D9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: const BorderSide(color: Colors.white, width: 1.3),
                ),
              ),
              Text(
                isDone ? 'This task is done' : 'This task is still pending',
                style: const TextStyle(
                  color: Colors.white,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
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
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: backgroundColor == Colors.white ? 0 : 4,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
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