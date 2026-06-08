import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/task.dart';
import '../../../providers/lock_mode_provider.dart';
import '../../../providers/premium_provider.dart';
import '../../../providers/recent_tasks_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../widgets/task_dropdown.dart';
import '../../timer/timer_page.dart';

class StartTaskPanel extends ConsumerStatefulWidget {
  const StartTaskPanel({super.key});

  @override
  ConsumerState<StartTaskPanel> createState() => _StartTaskPanelState();
}

class _StartTaskPanelState extends ConsumerState<StartTaskPanel> {
  Task? _selectedTask;
  bool _autoSelected = false;

  // Approximate closed height of TaskDropdown (GlassCard padding 14*2 + text ~20)
  static const double _dropdownClosedHeight = 52.0;
  static const double _dropdownGap = 16.0;

  @override
  Widget build(BuildContext context) {
    // Auto-select the most recent task once on first load
    if (!_autoSelected) {
      final recentIds = ref.watch(recentTasksProvider);
      final tasksAsync = ref.watch(tasksProvider);
      tasksAsync.whenData((tasks) {
        if (tasks.isNotEmpty && _selectedTask == null) {
          Task? candidate;
          for (final id in recentIds) {
            candidate = tasks.where((t) => t.id == id).firstOrNull;
            if (candidate != null) break;
          }
          candidate ??= tasks.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedTask == null) {
              setState(() {
                _selectedTask = candidate;
                _autoSelected = true;
              });
            }
          });
        }
      });
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = ref.watch(premiumProvider);
    final lockEnabled = ref.watch(lockModeProvider).enabled;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = isLandscape ? 20.0 : 40.0;
    final buttonTop = _dropdownClosedHeight + _dropdownGap;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Button + optional lock toggle below dropdown area
        Positioned(
          top: buttonTop,
          left: 0,
          right: 0,
          height: isLandscape ? null : screenHeight * 0.5,
          bottom: isLandscape ? bottomPad : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildStartButton(isDark)),
              if (isPremium) _buildLockToggle(isDark, lockEnabled),
            ],
          ),
        ),

        // Dropdown always rendered on top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TaskDropdown(
            selectedTask: _selectedTask,
            onTaskSelected: (task) => setState(() => _selectedTask = task),
            onAddNew: _showAddTaskDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(bool isDark) {
    final enabled = _selectedTask != null;

    return GestureDetector(
      onTap: enabled ? _startSession : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: enabled
              ? (isDark
                  ? AppColors.darkAccent.withValues(alpha: 0.85)
                  : AppColors.lightAccent.withValues(alpha: 0.9))
              : (isDark
                  ? AppColors.darkCard.withValues(alpha: 0.5)
                  : AppColors.lightCard.withValues(alpha: 0.5)),
          border: Border.all(
            color: enabled
                ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                : (isDark
                    ? AppColors.glassBorderDark
                    : AppColors.glassBorderLight),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              size: 80,
              color: enabled
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'START',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
                color: enabled
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
            if (!enabled) ...[
              const SizedBox(height: 8),
              Text(
                'Select a task above',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLockToggle(bool isDark, bool lockEnabled) {
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.do_not_disturb_on_outlined,
            size: 16,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Focus Lock',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: lockEnabled,
            onChanged: (value) =>
                ref.read(lockModeProvider.notifier).setEnabled(value),
            activeColor: accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    final nameController = TextEditingController();
    String selectedColor = AppConstants.defaultColors.first;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Task name',
                    hintText: 'e.g. Deep Work, Exercise...',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Pick a color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.defaultColors.map((hex) {
                    final color = Color(
                        int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = hex),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == hex
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final task = await ref
                    .read(tasksProvider.notifier)
                    .createTask(name, selectedColor);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (mounted) setState(() => _selectedTask = task);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession() {
    if (_selectedTask == null) return;
    ref.read(activeSessionProvider.notifier).startSession(_selectedTask!);
    ref.read(recentTasksProvider.notifier).recordUsed(_selectedTask!.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TimerPage(),
        fullscreenDialog: true,
      ),
    );
  }
}
