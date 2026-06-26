import 'dart:ui';
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
  bool _isCountDown = false;
  int _countDownMinutes = 25;

  static const double _dropdownClosedHeight = 52.0;
  static const double _dropdownGap = 12.0;
  static const double _toggleHeight = 36.0;
  static const double _toggleGap = 8.0;
  static const double _pillHeight = 36.0;
  static const double _pillGap = 8.0;

  double get _buttonTop {
    double top = _dropdownClosedHeight + _dropdownGap + _toggleHeight + _toggleGap;
    if (_isCountDown) top += _pillHeight + _pillGap;
    return top;
  }

  @override
  Widget build(BuildContext context) {
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
    final bottomPad = isLandscape ? 0.0 : 40.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Mode toggle row
        Positioned(
          top: _dropdownClosedHeight + _dropdownGap,
          left: 0,
          right: 0,
          height: _toggleHeight,
          child: _buildModeToggle(isDark),
        ),

        // Duration pill (count-down only)
        if (_isCountDown)
          Positioned(
            top: _dropdownClosedHeight + _dropdownGap + _toggleHeight + _toggleGap,
            left: 0,
            right: 0,
            height: _pillHeight,
            child: _buildDurationPill(isDark),
          ),

        // Start button + lock toggle
        Positioned(
          top: _buttonTop,
          left: 0,
          right: 0,
          bottom: bottomPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildStartButton(isDark, isLandscape)),
              if (isPremium) _buildLockToggle(isDark, lockEnabled),
            ],
          ),
        ),

        // Dropdown always on top so it overlays when open
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

  // ─── Mode toggle ──────────────────────────────────────────────────────────

  Widget _buildModeToggle(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            label: 'Open Session',
            icon: Icons.arrow_upward_rounded,
            selected: !_isCountDown,
            isDark: isDark,
            onTap: () => setState(() => _isCountDown = false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeButton(
            label: 'Time Block',
            icon: Icons.arrow_downward_rounded,
            selected: _isCountDown,
            isDark: isDark,
            onTap: () => setState(() => _isCountDown = true),
          ),
        ),
      ],
    );
  }

  // ─── Duration pill ────────────────────────────────────────────────────────

  Widget _buildDurationPill(bool isDark) {
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final border = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return GestureDetector(
      onTap: () => _showMinutePicker(isDark),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 15, color: accent),
            const SizedBox(width: 7),
            Text(
              _formatMinutes(_countDownMinutes),
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: accent),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // ─── Minute picker modal ──────────────────────────────────────────────────

  Future<void> _showMinutePicker(bool isDark) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MinutePickerSheet(
        initialMinutes: _countDownMinutes,
        isDark: isDark,
        onConfirm: (minutes) {
          setState(() => _countDownMinutes = minutes);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ─── Start button ─────────────────────────────────────────────────────────

  Widget _buildStartButton(bool isDark, bool isLandscape) {
    final enabled = _selectedTask != null;

    // Dark mode: frosted-black glass. Light mode: frosted-white glass.
    final bgColor = enabled
        ? (isDark
            ? Colors.black.withValues(alpha: 0.65)
            : AppColors.glassLight.withValues(alpha: 0.85))
        : (isDark
            ? Colors.black.withValues(alpha: 0.35)
            : AppColors.glassLight.withValues(alpha: 0.55));

    final borderColor = enabled
        ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
        : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);

    final contentColor = enabled
        ? (isDark ? AppColors.darkText : AppColors.lightText)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return GestureDetector(
      onTap: enabled ? _startSession : null,
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: isLandscape ? 44 : 72,
                      color: contentColor,
                    ),
                    SizedBox(height: isLandscape ? 4 : 8),
                    Text(
                      'START',
                      style: TextStyle(
                        fontSize: isLandscape ? 18 : 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: contentColor,
                      ),
                    ),
                    if (!enabled) ...[
                      SizedBox(height: isLandscape ? 3 : 6),
                      Text(
                        'Select a task above',
                        style: TextStyle(
                          fontSize: isLandscape ? 11 : 12,
                          color: contentColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Lock toggle ──────────────────────────────────────────────────────────

  Widget _buildLockToggle(bool isDark, bool lockEnabled) {
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.do_not_disturb_on_outlined,
            size: 15,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 7),
          Text(
            'Focus Lock',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 7),
          Switch(
            value: lockEnabled,
            onChanged: (value) =>
                ref.read(lockModeProvider.notifier).setEnabled(value),
            activeThumbColor: accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // ─── Add task dialog ──────────────────────────────────────────────────────

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

  // ─── Session start ────────────────────────────────────────────────────────

  void _startSession() {
    if (_selectedTask == null) return;
    final target =
        _isCountDown ? Duration(minutes: _countDownMinutes) : null;
    ref.read(activeSessionProvider.notifier).startSession(
          _selectedTask!,
          targetDuration: target,
        );
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

// ─── Mode toggle button ───────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border =
        isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    final bg = selected ? accent.withValues(alpha: 0.1) : cardBg;
    final borderColor = selected ? accent : border;
    final fg = selected ? accent : secondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Minute picker bottom sheet ───────────────────────────────────────────

class _MinutePickerSheet extends StatefulWidget {
  final int initialMinutes;
  final bool isDark;
  final ValueChanged<int> onConfirm;

  const _MinutePickerSheet({
    required this.initialMinutes,
    required this.isDark,
    required this.onConfirm,
  });

  @override
  State<_MinutePickerSheet> createState() => _MinutePickerSheetState();
}

class _MinutePickerSheetState extends State<_MinutePickerSheet> {
  late int _selected;
  late FixedExtentScrollController _scrollController;

  // Continuous 1-minute steps up to 120, then coarser steps to 180.
  static final List<int> _values = [
    ...List.generate(30, (i) => i + 1),   // 1–30  (every 1 min)
    35, 40, 45, 50, 55,
    60, 75, 90, 105, 120, 150, 180,
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMinutes;
    final idx = _values.indexOf(_selected);
    _scrollController = FixedExtentScrollController(
      initialItem: idx >= 0 ? idx : 0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _label(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Confirm button: dark mode = white filled, light mode = white filled + dark border
    final btnBg = isDark ? Colors.white : Colors.white;
    final btnFg = Colors.black;
    final btnBorder = isDark
        ? BorderSide.none
        : BorderSide(color: AppColors.lightBorder, width: 1.5);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: secondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Duration',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: text,
              ),
            ),
            const SizedBox(height: 20),

            // Scroll wheel
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Selection highlight band
                  IgnorePointer(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 50,
                    perspective: 0.003,
                    diameterRatio: 2.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) =>
                        setState(() => _selected = _values[i]),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _values.length,
                      builder: (_, i) {
                        final val = _values[i];
                        final isSelected = val == _selected;
                        return Center(
                          child: Text(
                            _label(val),
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 18,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected ? text : secondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onConfirm(_selected),
                style: FilledButton.styleFrom(
                  backgroundColor: btnBg,
                  foregroundColor: btnFg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: isDark ? 0 : 1,
                  side: btnBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Set  ${_label(_selected)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
