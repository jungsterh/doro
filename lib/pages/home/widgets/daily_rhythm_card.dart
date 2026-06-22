import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/session.dart';
import '../../../widgets/glass_card.dart';

class DailyRhythmCard extends StatefulWidget {
  final List<Session> sessions;
  const DailyRhythmCard({super.key, required this.sessions});

  @override
  State<DailyRhythmCard> createState() => _DailyRhythmCardState();
}

class _DailyRhythmCardState extends State<DailyRhythmCard> {
  int _daysBack = 0;

  DateTime get _selectedDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: _daysBack));
  }

  String get _dayLabel {
    if (_daysBack == 0) return 'Today';
    if (_daysBack == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(_selectedDay);
  }

  List<int> _buildHourlyActivity() {
    final counts = List.filled(24, 0);
    final day = _selectedDay;
    final dayEnd = day.add(const Duration(days: 1));
    for (final session in widget.sessions) {
      if (!session.isCompleted) continue;
      final st = session.startTime;
      if (!st.isBefore(day) && st.isBefore(dayEnd)) {
        counts[st.hour]++;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final hourlyActivity = _buildHourlyActivity();
    final canGoForward = _daysBack > 0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v > 300) {
            setState(() => _daysBack++);
          } else if (v < -300 && canGoForward) {
            setState(() => _daysBack--);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Rhythm',
                    style: Theme.of(context).textTheme.titleMedium),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChevronButton(
                      icon: Icons.chevron_left,
                      enabled: true,
                      color: textColor,
                      onTap: () => setState(() => _daysBack++),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        _dayLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                    ),
                    _ChevronButton(
                      icon: Icons.chevron_right,
                      enabled: canGoForward,
                      color: textColor,
                      onTap: canGoForward
                          ? () => setState(() => _daysBack--)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RhythmHeatmap(
              hourlyActivity: hourlyActivity,
              accentColor: accentColor,
              textColor: textColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  const _ChevronButton({
    required this.icon,
    required this.enabled,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? color : color.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _RhythmHeatmap extends StatelessWidget {
  final List<int> hourlyActivity;
  final Color accentColor;
  final Color textColor;

  const _RhythmHeatmap({
    required this.hourlyActivity,
    required this.accentColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount =
        hourlyActivity.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(24, (hour) {
            final count = hourlyActivity[hour].toDouble();
            final intensity = maxCount > 0 ? count / maxCount : 0.0;
            return Expanded(
              child: Container(
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: intensity == 0 ? 0.08 : 0.15 + intensity * 0.75,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _label('12a'),
            const Spacer(),
            _label('6a'),
            const Spacer(),
            _label('12p'),
            const Spacer(),
            _label('6p'),
            const Spacer(),
            _label('12a'),
          ],
        ),
      ],
    );
  }

  Widget _label(String t) =>
      Text(t, style: TextStyle(color: textColor, fontSize: 9));
}
