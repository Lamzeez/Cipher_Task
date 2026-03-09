import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import 'profile_view.dart';
import 'todo_detail_view.dart';
import '../utils/snack_bar.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _search = TextEditingController();

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final auth = context.read<AuthViewModel>();
      final email = auth.user?.email;
      if (email != null && email.isNotEmpty) {
        context.read<TodoViewModel>().loadTodosForUser(email);
      }
    });

    _search.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text(
          'Your encrypted tasks will remain stored locally, but your session will end.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F73D9),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteSelected(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete selected tasks?'),
        content: Text(
          count == 1
              ? 'Are you sure you want to delete the selected task?'
              : 'Are you sure you want to delete $count selected tasks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }

      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelectAll(List<TodoModel> todos) {
    final ids = todos.map((t) => t.id).toSet();

    setState(() {
      _selectionMode = true;
      if (_selectedIds.length == ids.length && ids.isNotEmpty) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

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

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF8A8A8A),
        fontSize: 15,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: const Color(0xFF7B7B7B)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFE3E3E3),
          width: 1.4,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF2F73D9),
          width: 1.6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final todoVm = context.watch<TodoViewModel>();
    final visibleTodos = todoVm.getFilteredTodos(_search.text);

    final displayName = (auth.user?.displayName ?? '').trim();
    final userName = displayName.isEmpty ? 'User' : displayName;

    final allVisibleSelected =
        visibleTodos.isNotEmpty &&
        _selectedIds.length == visibleTodos.length &&
        visibleTodos.every((t) => _selectedIds.contains(t.id));

    final totalCount = todoVm.todos.length;
    final doneCount = todoVm.todos.where((e) => e.isDone).length;
    final pendingCount = totalCount - doneCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: todoVm.loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopWelcomeCard(
                            userName: userName,
                            onProfileTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileView(),
                                ),
                              );
                            },
                            onLogoutTap: () async {
                              final confirmed = await _confirmLogout(context);
                              if (confirmed != true) return;

                              await context.read<AuthViewModel>().logout();

                              if (!mounted) return;
                              showMiniSnackBar(
                                context,
                                'Logged out successfully.',
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatsCard(
                                  icon: Icons.pending_actions_rounded,
                                  title: 'Pending',
                                  value: '$pendingCount',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatsCard(
                                  icon: Icons.task_alt_rounded,
                                  title: 'Done',
                                  value: '$doneCount',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _WhiteSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.add_task_rounded,
                                      color: Color(0xFF2F73D9),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Create New Task',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _title,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                  decoration: _fieldDecoration(
                                    hint: 'Task Title',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _note,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                  minLines: 3,
                                  maxLines: 4,
                                  decoration: _fieldDecoration(
                                    hint: 'Sensitive task details',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4A8AF4),
                                          Color(0xFF1F67C8),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF2F73D9,
                                          ).withOpacity(0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final title = _title.text.trim();
                                        final note = _note.text.trim();

                                        if (title.isEmpty || note.isEmpty) {
                                          showMiniSnackBar(
                                            context,
                                            'Please enter both Task Title and Sensitive task details.',
                                          );
                                          return;
                                        }

                                        final user = auth.user;
                                        if (user == null) {
                                          showMiniSnackBar(
                                            context,
                                            'No authenticated user.',
                                          );
                                          return;
                                        }

                                        await todoVm.addTodo(
                                          title: title,
                                          sensitiveNotePlain: note,
                                          ownerEmail: user.email,
                                        );

                                        _title.clear();
                                        _note.clear();

                                        if (!mounted) return;
                                        showMiniSnackBar(
                                          context,
                                          'Task created successfully.',
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Add Task',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _WhiteSectionCard(
                            child: TextField(
                              controller: _search,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: _fieldDecoration(
                                hint: 'Search task title or sensitive detail',
                                prefixIcon: Icons.search_rounded,
                                suffixIcon: _search.text.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _search.clear();
                                          setState(() {});
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFF7B7B7B),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectionMode)
                            _SelectionBar(
                              selectedCount: _selectedIds.length,
                              allVisibleSelected: allVisibleSelected,
                              hasItems: visibleTodos.isNotEmpty,
                              onSelectAll: () => _toggleSelectAll(visibleTodos),
                              onDelete: _selectedIds.isEmpty
                                  ? null
                                  : () async {
                                      final confirmed =
                                          await _confirmDeleteSelected(
                                        context,
                                        _selectedIds.length,
                                      );
                                      if (confirmed != true) return;

                                      final ids = _selectedIds.toList();
                                      await todoVm.deleteMultipleTodos(ids);

                                      if (!mounted) return;
                                      _clearSelection();
                                      showMiniSnackBar(
                                        context,
                                        ids.length == 1
                                            ? 'Task deleted successfully.'
                                            : '${ids.length} tasks deleted successfully.',
                                      );
                                    },
                              onCancel: _clearSelection,
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 10),
                            child: Row(
                              children: [
                                Text(
                                  _search.text.trim().isEmpty
                                      ? 'Your Tasks'
                                      : 'Search Results',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFE3E3E3),
                                    ),
                                  ),
                                  child: Text(
                                    '${visibleTodos.length} item${visibleTodos.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  visibleTodos.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 86,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _search.text.trim().isEmpty
                                          ? Icons.note_alt_outlined
                                          : Icons.search_off_rounded,
                                      size: 42,
                                      color: const Color(0xFF8AA8D8),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _search.text.trim().isEmpty
                                        ? 'No tasks yet.'
                                        : 'No matching tasks found.',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Create a task to get started.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF7A7A7A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final todo = visibleTodos[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TodoTile(
                                    todo: todo,
                                    decryptedNote:
                                        todoVm.decryptedNoteFor(todo.id),
                                    timestampText:
                                        _formatCreatedAt(todo.createdAt),
                                    selectionMode: _selectionMode,
                                    selected: _selectedIds.contains(todo.id),
                                    onToggleSelection: () =>
                                        _toggleSelection(todo.id),
                                    onEnterSelectionMode: () =>
                                        _enterSelectionMode(todo.id),
                                  ),
                                );
                              },
                              childCount: visibleTodos.length,
                            ),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}

class _TopWelcomeCard extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const _TopWelcomeCard({
    required this.userName,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Material(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onLogoutTap,
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatsCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2F73D9)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhiteSectionCard extends StatelessWidget {
  final Widget child;

  const _WhiteSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: child,
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int selectedCount;
  final bool allVisibleSelected;
  final bool hasItems;
  final VoidCallback onSelectAll;
  final VoidCallback? onDelete;
  final VoidCallback onCancel;

  const _SelectionBar({
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.hasItems,
    required this.onSelectAll,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E6FA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$selectedCount selected',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: hasItems ? onSelectAll : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2F73D9),
                  side: const BorderSide(color: Color(0xFFBFD4F7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  allVisibleSelected
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                ),
                label: Text(
                  allVisibleSelected ? 'Clear all' : 'Select all',
                ),
              ),
              ElevatedButton.icon(
                onPressed: onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Delete selected'),
              ),
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final TodoModel todo;
  final String decryptedNote;
  final String timestampText;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelection;
  final VoidCallback onEnterSelectionMode;

  const _TodoTile({
    required this.todo,
    required this.decryptedNote,
    required this.timestampText,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelection,
    required this.onEnterSelectionMode,
  });

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete task?'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TodoViewModel>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (selectionMode) {
            onToggleSelection();
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TodoDetailView(todo: todo)),
          );
        },
        onLongPress: () {
          if (!selectionMode) {
            onEnterSelectionMode();
          } else {
            onToggleSelection();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: selected
                ? const Color(0xFFEAF1FB)
                : Colors.white,
            border: Border.all(
              color: selected
                  ? const Color(0xFF2F73D9)
                  : const Color(0xFFEAEAEA),
              width: selected ? 1.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SelectionLeading(
                selectionMode: selectionMode,
                selected: selected,
                isDone: todo.isDone,
                onSelectionTap: onToggleSelection,
                onDoneChanged: (_) => vm.toggleDone(todo),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        decoration:
                            todo.isDone ? TextDecoration.lineThrough : null,
                        color: todo.isDone
                            ? const Color(0xFF8A8A8A)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      decryptedNote.isEmpty ? '(empty)' : decryptedNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: todo.isDone
                            ? const Color(0xFF9C9C9C)
                            : const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            color: const Color(0xFFF4F6F8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Color(0xFF7A7A7A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                timestampText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: todo.isDone
                                ? const Color(0xFFE9F8EE)
                                : const Color(0xFFFFF4E7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            todo.isDone ? 'Completed' : 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: todo.isDone
                                  ? const Color(0xFF1F9D55)
                                  : const Color(0xFFE98A15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              selectionMode
                  ? Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected
                          ? const Color(0xFF2F73D9)
                          : const Color(0xFFB7B7B7),
                      size: 26,
                    )
                  : IconButton(
                      tooltip: 'Delete',
                      onPressed: () async {
                        final confirmed = await _confirmDelete(context);
                        if (confirmed != true) return;

                        await vm.deleteTodo(todo.id);

                        if (!context.mounted) return;
                        showMiniSnackBar(
                          context,
                          'Task deleted successfully.',
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFF7A7A7A),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionLeading extends StatelessWidget {
  final bool selectionMode;
  final bool selected;
  final bool isDone;
  final ValueChanged<bool?> onDoneChanged;
  final VoidCallback onSelectionTap;

  const _SelectionLeading({
    required this.selectionMode,
    required this.selected,
    required this.isDone,
    required this.onDoneChanged,
    required this.onSelectionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (selectionMode) {
      return InkWell(
        onTap: onSelectionTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? const Color(0xFF2F73D9)
                  : const Color(0xFFBDBDBD),
              width: 1.5,
            ),
            color: selected
                ? const Color(0xFF2F73D9).withOpacity(0.12)
                : Colors.transparent,
          ),
          child: selected
              ? const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Color(0xFF2F73D9),
                )
              : null,
        ),
      );
    }

    return Transform.scale(
      scale: 1.05,
      child: Checkbox(
        value: isDone,
        onChanged: onDoneChanged,
        activeColor: const Color(0xFF2F73D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: const BorderSide(color: Color(0xFF9A9A9A), width: 1.3),
      ),
    );
  }
}