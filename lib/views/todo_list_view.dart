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

    return '$hour:$minute$meridiem $datePart';
  }

  InputDecoration _fieldDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final radius = BorderRadius.circular(18);

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 15,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF101B38),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
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
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'CipherTask',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: todoVm.loading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeaderSection(
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
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _InfoCard(
                                        icon: Icons.pending_actions_rounded,
                                        title: 'Pending',
                                        value: '$pendingCount',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _InfoCard(
                                        icon: Icons.task_alt_rounded,
                                        title: 'Done',
                                        value: '$doneCount',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _SectionCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Create New Task',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      TextField(
                                        controller: _title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        cursorColor: Colors.white,
                                        decoration: _fieldDecoration(
                                          label: 'Task Title',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _note,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        cursorColor: Colors.white,
                                        minLines: 3,
                                        maxLines: 4,
                                        decoration: _fieldDecoration(
                                          label: 'Sensitive task details',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            backgroundColor:
                                                const Color(0xFF8B5CF6),
                                            foregroundColor: Colors.white,
                                            elevation: 6,
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
                                          icon: const Icon(Icons.add_rounded),
                                          label: const Text(
                                            'Add Task',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  child: TextField(
                                    controller: _search,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    cursorColor: Colors.white,
                                    decoration: _fieldDecoration(
                                      label:
                                          'Search task title or sensitive detail',
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
                                                color: Colors.white70,
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
                                    onSelectAll: () =>
                                        _toggleSelectAll(visibleTodos),
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
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _search.text.trim().isEmpty
                                            ? 'Your Tasks'
                                            : 'Search Results',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF121E3D),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: Colors.white12,
                                          ),
                                        ),
                                        child: Text(
                                          '${visibleTodos.length} item${visibleTodos.length == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            color: Colors.white70,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _search.text.trim().isEmpty
                                              ? Icons.note_alt_outlined
                                              : Icons.search_off_rounded,
                                          size: 52,
                                          color: Colors.white38,
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          _search.text.trim().isEmpty
                                              ? 'No tasks yet.'
                                              : 'No matching tasks found.',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 0, 18, 20),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, i) {
                                      final todo = visibleTodos[i];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: _TodoTile(
                                          todo: todo,
                                          decryptedNote:
                                              todoVm.decryptedNoteFor(todo.id),
                                          timestampText:
                                              _formatCreatedAt(todo.createdAt),
                                          selectionMode: _selectionMode,
                                          selected:
                                              _selectedIds.contains(todo.id),
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
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const _HeaderSection({
    required this.userName,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF8B5CF6).withOpacity(0.18),
            ),
            child: const Icon(
              Icons.shield_moon_rounded,
              color: Color(0xFFB79CFF),
              size: 28,
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
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onProfileTap,
                icon: const Icon(Icons.person_rounded),
                tooltip: 'Profile',
              ),
              TextButton.icon(
                onPressed: onLogoutTap,
                icon: const Icon(
                  Icons.lock_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121E3D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFB79CFF)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
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
        color: const Color(0xFF181B33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$selectedCount selected',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: hasItems ? onSelectAll : null,
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
                ? const Color(0xFF1A2145)
                : todo.isDone
                    ? const Color(0xFF10182E)
                    : const Color(0xFF121E3D),
            border: Border.all(
              color: selected
                  ? const Color(0xFF9B7BFF)
                  : todo.isDone
                      ? Colors.white10
                      : const Color(0xFF8B5CF6).withOpacity(0.30),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 10,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        decoration:
                            todo.isDone ? TextDecoration.lineThrough : null,
                        color: todo.isDone ? Colors.white60 : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      decryptedNote.isEmpty ? '(empty)' : decryptedNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: todo.isDone ? Colors.white54 : Colors.white70,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: todo.isDone
                                ? Colors.green.withOpacity(0.14)
                                : Colors.orange.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            todo.isDone ? 'Completed' : 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: todo.isDone
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
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
                          ? const Color(0xFF9B7BFF)
                          : Colors.white38,
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
                        color: Colors.white70,
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
                  ? const Color(0xFF9B7BFF)
                  : Colors.white38,
              width: 1.5,
            ),
            color: selected
                ? const Color(0xFF9B7BFF).withOpacity(0.16)
                : Colors.transparent,
          ),
          child: selected
              ? const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Color(0xFFCDB9FF),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: const BorderSide(color: Colors.white54, width: 1.3),
      ),
    );
  }
}