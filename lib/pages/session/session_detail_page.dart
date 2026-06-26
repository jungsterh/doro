import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/duration_formatter.dart';
import '../../models/session.dart';
import '../../models/task.dart';
import '../../providers/session_provider.dart';
import '../../widgets/glass_card.dart';

class SessionDetailPage extends ConsumerStatefulWidget {
  final Session session;
  final Task? task;

  const SessionDetailPage({
    super.key,
    required this.session,
    this.task,
  });

  @override
  ConsumerState<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends ConsumerState<SessionDetailPage> {
  late Session _session = widget.session;
  late final TextEditingController _noteController =
      TextEditingController(text: _session.comment ?? '');
  bool _editing = false;
  bool _saving = false;

  Task? get task => widget.task;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _saving = true);
    final updated = await ref
        .read(activeSessionProvider.notifier)
        .updateSessionComment(_session, _noteController.text);
    ref.invalidate(sessionsProvider);
    ref.invalidate(sessionsByTaskProvider(_session.taskId));
    if (!mounted) return;
    setState(() {
      _session = updated;
      _noteController.text = updated.comment ?? '';
      _editing = false;
      _saving = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _noteController.text = _session.comment ?? '';
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dateFmt = DateFormat('EEEE, MMMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');

    final startTime = _session.startTime;
    final endTime = _session.endTime;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Session Detail'),
              actions: [
                if (!_editing)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit note',
                    onPressed: () => setState(() => _editing = true),
                  ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header: task + duration
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        if (task != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: task!.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                task!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          DurationFormatter.fromSeconds(_session.durationSeconds),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Date & time info
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: dateFmt.format(startTime),
                          isDark: isDark,
                          secondaryColor: secondaryColor,
                        ),
                        _Divider(isDark: isDark),
                        _InfoRow(
                          icon: Icons.play_circle_outline,
                          label: 'Started',
                          value: timeFmt.format(startTime),
                          isDark: isDark,
                          secondaryColor: secondaryColor,
                        ),
                        if (endTime != null) ...[
                          _Divider(isDark: isDark),
                          _InfoRow(
                            icon: Icons.stop_circle_outlined,
                            label: 'Ended',
                            value: timeFmt.format(endTime),
                            isDark: isDark,
                            secondaryColor: secondaryColor,
                          ),
                        ],
                        _Divider(isDark: isDark),
                        _InfoRow(
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value: DurationFormatter.formatHuman(_session.duration),
                          isDark: isDark,
                          secondaryColor: secondaryColor,
                          valueColor: accent,
                        ),
                      ],
                    ),
                  ),

                  // Notes
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes_outlined,
                                size: 16, color: secondaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Notes',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: secondaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_editing) ...[
                          TextField(
                            controller: _noteController,
                            maxLines: 4,
                            autofocus: true,
                            enabled: !_saving,
                            decoration: InputDecoration(
                              hintText: 'Add a note about this session...',
                              border: const OutlineInputBorder(),
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: secondaryColor),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _saving ? null : _cancelEdit,
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _saving ? null : _saveNote,
                                child: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Save'),
                              ),
                            ],
                          ),
                        ] else
                          Text(
                            _session.comment?.trim().isNotEmpty == true
                                ? _session.comment!
                                : 'No notes for this session.',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _session.comment?.trim().isNotEmpty ==
                                              true
                                          ? null
                                          : secondaryColor,
                                      height: 1.5,
                                    ),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color secondaryColor;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.secondaryColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: secondaryColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: secondaryColor),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark
          ? AppColors.glassBorderDark
          : AppColors.glassBorderLight,
    );
  }
}
