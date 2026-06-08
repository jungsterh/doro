import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../models/task.dart';
import '../providers/recent_tasks_provider.dart';
import '../providers/task_provider.dart';
import 'glass_card.dart';

class TaskDropdown extends ConsumerStatefulWidget {
  final Task? selectedTask;
  final ValueChanged<Task?> onTaskSelected;
  final VoidCallback? onAddNew;

  const TaskDropdown({
    super.key,
    this.selectedTask,
    required this.onTaskSelected,
    this.onAddNew,
  });

  @override
  ConsumerState<TaskDropdown> createState() => _TaskDropdownState();
}

class _TaskDropdownState extends ConsumerState<TaskDropdown> {
  bool _isOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open() {
    setState(() {
      _isOpen = true;
      _query = '';
      _searchController.clear();
    });
  }

  void _close() => setState(() => _isOpen = false);

  void _select(Task task) {
    widget.onTaskSelected(task);
    ref.read(recentTasksProvider.notifier).recordUsed(task.id);
    _close();
  }

  List<Task> _sortedTasks(List<Task> all, List<String> recentIds) {
    if (_query.isEmpty) {
      final recentSet = recentIds.toSet();
      final recent = recentIds
          .map((id) => all.where((t) => t.id == id).firstOrNull)
          .whereType<Task>()
          .toList();
      final rest = all.where((t) => !recentSet.contains(t.id)).toList();
      return [...recent, ...rest];
    }
    final q = _query.toLowerCase();
    return all.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final recentIds = ref.watch(recentTasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary.withValues(alpha: 0.9)
        : AppColors.lightTextSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Trigger row
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: _isOpen ? _close : _open,
          child: Row(
            children: [
              if (widget.selectedTask != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.selectedTask!.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.selectedTask?.name ?? 'Select a task...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.selectedTask != null
                            ? textColor
                            : secondaryColor,
                      ),
                ),
              ),
              Icon(
                _isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: secondaryColor,
                size: 20,
              ),
            ],
          ),
        ),

        if (_isOpen)
          GlassCard(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.only(top: 4),
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.92),
            child: tasksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
              data: (tasks) {
                final filtered = _sortedTasks(tasks, recentIds);
                final noMatch = _query.isNotEmpty && filtered.isEmpty;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          hintStyle: TextStyle(
                              color: secondaryColor, fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              size: 18, color: secondaryColor),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),

                    // "Recent" label
                    if (_query.isEmpty && recentIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                        child: Row(
                          children: [
                            Icon(Icons.history,
                                size: 12, color: secondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'RECENT',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Task list
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          ...filtered.map((task) => ListTile(
                                dense: true,
                                leading: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: task.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(
                                  task.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: textColor,
                                        fontWeight:
                                            widget.selectedTask?.id == task.id
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                      ),
                                ),
                                trailing: widget.selectedTask?.id == task.id
                                    ? Icon(Icons.check,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)
                                    : null,
                                onTap: () => _select(task),
                              )),

                          // Add new task option
                          if (noMatch || _query.isEmpty) ...[
                            if (filtered.isNotEmpty)
                              const Divider(height: 1),
                            ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.add,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                _query.isNotEmpty
                                    ? 'Add "$_query"'
                                    : 'Add new task',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () {
                                _close();
                                widget.onAddNew?.call();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
