import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/session.dart';
import '../../../models/task.dart';
import '../../../providers/date_range_provider.dart';

enum _ChartScale { oneMin, fiveMin, thirtyMin, oneHour }

extension _ScaleProps on _ChartScale {
  double get secondsPerUnit {
    switch (this) {
      case _ChartScale.oneMin:
        return 60;
      case _ChartScale.fiveMin:
        return 300;
      case _ChartScale.thirtyMin:
        return 1800;
      case _ChartScale.oneHour:
        return 3600;
    }
  }

  double get interval => 1;

  String formatLabel(double value) {
    if (value == 0) return '';
    switch (this) {
      case _ChartScale.oneMin:
        return '${value.toInt()}m';
      case _ChartScale.fiveMin:
        return '${(value * 5).toInt()}m';
      case _ChartScale.thirtyMin:
        final totalMin = (value * 30).toInt();
        if (totalMin < 60) return '${totalMin}m';
        final h = totalMin ~/ 60;
        final m = totalMin % 60;
        return m == 0 ? '${h}h' : '${h}h${m}m';
      case _ChartScale.oneHour:
        return '${value.toInt()}h';
    }
  }

  String get label {
    switch (this) {
      case _ChartScale.oneMin:
        return '1m';
      case _ChartScale.fiveMin:
        return '5m';
      case _ChartScale.thirtyMin:
        return '30m';
      case _ChartScale.oneHour:
        return '1h';
    }
  }
}

// ─── Bucket (one bar on the chart) ───────────────────────────────────────────

class _Bucket {
  final DateTime start;
  final DateTime end;
  final String label;

  const _Bucket({
    required this.start,
    required this.end,
    required this.label,
  });
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class WeeklyBarChart extends StatefulWidget {
  final List<Session> sessions;
  final List<Task> tasks;
  final DateRangeState rangeState;

  const WeeklyBarChart({
    super.key,
    required this.sessions,
    required this.tasks,
    required this.rangeState,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  _ChartScale _scale = _ChartScale.oneHour;
  int _offset = 0;

  static const _scales = _ChartScale.values;

  @override
  void didUpdateWidget(WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rangeState.range != widget.rangeState.range) {
      _offset = 0;
    }
  }

  void _zoomIn() {
    final idx = _scales.indexOf(_scale);
    if (idx > 0) setState(() => _scale = _scales[idx - 1]);
  }

  void _zoomOut() {
    final idx = _scales.indexOf(_scale);
    if (idx < _scales.length - 1) setState(() => _scale = _scales[idx + 1]);
  }

  bool get _canGoForward => _offset > 0;
  bool get _supportsOffset => widget.rangeState.range != DateRange.custom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final buckets = _computeBuckets();
    final data = _buildChartData(buckets);
    final title = _chartTitle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_supportsOffset)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavChevron(
                    icon: Icons.chevron_left,
                    enabled: true,
                    color: textColor,
                    onTap: () => setState(() => _offset++),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 96),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _NavChevron(
                    icon: Icons.chevron_right,
                    enabled: _canGoForward,
                    color: textColor,
                    onTap: _canGoForward ? () => setState(() => _offset--) : null,
                  ),
                ],
              )
            else
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                _ZoomButton(
                  icon: Icons.remove,
                  onTap: _zoomOut,
                  enabled: _scales.indexOf(_scale) < _scales.length - 1,
                  textColor: textColor,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    _scale.label,
                    style: TextStyle(color: textColor, fontSize: 11),
                  ),
                ),
                _ZoomButton(
                  icon: Icons.add,
                  onTap: _zoomIn,
                  enabled: _scales.indexOf(_scale) > 0,
                  textColor: textColor,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _maxUnits(data, buckets.length),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final totalSeconds = rod.toY * _scale.secondsPerUnit;
                    final label = _formatDuration(totalSeconds.round());
                    final bucketLabel = groupIndex < buckets.length
                        ? buckets[groupIndex].label
                        : '';
                    return BarTooltipItem(
                      '$bucketLabel\n$label',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= buckets.length) {
                        return const SizedBox.shrink();
                      }
                      final bucket = buckets[idx];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          bucket.label,
                          style: TextStyle(color: textColor, fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _scale.interval,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      if (value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        _scale.formatLabel(value),
                        style: TextStyle(color: textColor, fontSize: 10),
                      );
                    },
                    reservedSize: 36,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: _scale.interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              barGroups: _buildBarGroups(data, buckets.length),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Bucket computation ───────────────────────────────────────────────────

  List<_Bucket> _computeBuckets() {
    final range = widget.rangeState.range;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (range) {
      case DateRange.week:
        // 7-day window shifted by _offset weeks back
        final endDay = today.subtract(Duration(days: _offset * 7));
        return List.generate(7, (i) {
          final d = endDay.subtract(Duration(days: 6 - i));
          return _Bucket(
            start: d,
            end: d.add(const Duration(days: 1)),
            label: DateFormat('E').format(d),
          );
        });

      case DateRange.month:
        // Calendar month shifted by _offset months back
        final targetMonth =
            DateTime(now.year, now.month - _offset, 1);
        final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 1);
        final effectiveEnd =
            monthEnd.isAfter(today) ? today : monthEnd.subtract(const Duration(days: 1));
        return _weeklyBuckets(targetMonth, effectiveEnd);

      case DateRange.ytd:
        // Full year shifted by _offset years back
        final targetYear = now.year - _offset;
        final monthCount = targetYear == now.year ? now.month : 12;
        return List.generate(monthCount, (i) {
          final monthStart = DateTime(targetYear, i + 1, 1);
          final monthEnd = DateTime(targetYear, i + 2, 1);
          return _Bucket(
            start: monthStart,
            end: monthEnd,
            label: DateFormat('MMM').format(monthStart),
          );
        });

      case DateRange.custom:
        final (from, to) = widget.rangeState.bounds;
        final start = DateTime(from.year, from.month, from.day);
        final end = DateTime(to.year, to.month, to.day);
        final spanDays = end.difference(start).inDays + 1;

        if (spanDays <= 14) {
          return _dailyBuckets(start, end);
        } else if (spanDays <= 90) {
          return _weeklyBuckets(start, end);
        } else {
          return _monthlyBuckets(start, end);
        }
    }
  }

  List<_Bucket> _dailyBuckets(DateTime from, DateTime to) {
    final buckets = <_Bucket>[];
    var d = from;
    while (!d.isAfter(to)) {
      buckets.add(_Bucket(
        start: d,
        end: d.add(const Duration(days: 1)),
        label: DateFormat('d').format(d),
      ));
      d = d.add(const Duration(days: 1));
    }
    return buckets;
  }

  List<_Bucket> _weeklyBuckets(DateTime from, DateTime to) {
    // Align to Monday
    var weekStart = from.subtract(Duration(days: (from.weekday - 1) % 7));
    final buckets = <_Bucket>[];
    while (!weekStart.isAfter(to)) {
      final weekEnd = weekStart.add(const Duration(days: 7));
      buckets.add(_Bucket(
        start: weekStart,
        end: weekEnd,
        label: DateFormat('M/d').format(weekStart),
      ));
      weekStart = weekEnd;
    }
    return buckets;
  }

  List<_Bucket> _monthlyBuckets(DateTime from, DateTime to) {
    final buckets = <_Bucket>[];
    var m = DateTime(from.year, from.month, 1);
    while (!m.isAfter(to)) {
      final next = DateTime(m.year, m.month + 1, 1);
      buckets.add(_Bucket(
        start: m,
        end: next,
        label: DateFormat('MMM').format(m),
      ));
      m = next;
    }
    return buckets;
  }

  // ─── Chart title ──────────────────────────────────────────────────────────

  String _chartTitle() {
    final now = DateTime.now();
    switch (widget.rangeState.range) {
      case DateRange.week:
        if (_offset == 0) return 'This Week';
        if (_offset == 1) return 'Last Week';
        return '$_offset Weeks Ago';
      case DateRange.month:
        if (_offset == 0) return 'This Month';
        return DateFormat('MMMM yyyy')
            .format(DateTime(now.year, now.month - _offset, 1));
      case DateRange.ytd:
        if (_offset == 0) return 'This Year';
        return '${now.year - _offset}';
      case DateRange.custom:
        final (from, to) = widget.rangeState.bounds;
        return '${DateFormat('MMM d').format(from)} – ${DateFormat('MMM d').format(to)}';
    }
  }

  // ─── Data aggregation ─────────────────────────────────────────────────────

  Map<int, Map<String, double>> _buildChartData(List<_Bucket> buckets) {
    final data = <int, Map<String, double>>{
      for (int i = 0; i < buckets.length; i++) i: {},
    };

    for (final session in widget.sessions) {
      if (!session.isCompleted) continue;
      final sessionDay = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      for (int i = 0; i < buckets.length; i++) {
        if (!sessionDay.isBefore(buckets[i].start) &&
            sessionDay.isBefore(buckets[i].end)) {
          final units = session.durationSeconds / _scale.secondsPerUnit;
          data[i]![session.taskId] = (data[i]![session.taskId] ?? 0) + units;
          break;
        }
      }
    }

    return data;
  }

  double _maxUnits(Map<int, Map<String, double>> data, int bucketCount) {
    double max = 1;
    for (int i = 0; i < bucketCount; i++) {
      final total = (data[i] ?? {}).values.fold(0.0, (a, b) => a + b);
      if (total > max) max = total;
    }
    return (max * 1.2).ceilToDouble();
  }

  List<BarChartGroupData> _buildBarGroups(
      Map<int, Map<String, double>> data, int bucketCount) {
    final barWidth = bucketCount <= 7 ? 16.0 : bucketCount <= 12 ? 14.0 : 10.0;

    return List.generate(bucketCount, (i) {
      final dayData = data[i] ?? {};
      double startY = 0;

      if (dayData.isEmpty) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: Colors.transparent,
              width: barWidth,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }

      final taskMap = {for (final t in widget.tasks) t.id: t};
      final rodStacks = <BarChartRodStackItem>[];
      for (final entry in dayData.entries) {
        final task = taskMap[entry.key];
        final color = task?.color ?? AppColors.darkAccent;
        rodStacks.add(BarChartRodStackItem(startY, startY + entry.value, color));
        startY += entry.value;
      }

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: startY,
            rodStackItems: rodStacks,
            width: barWidth,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }
}

// ─── Zoom button ──────────────────────────────────────────────────────────────

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color textColor;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        size: 16,
        color: enabled ? textColor : textColor.withValues(alpha: 0.3),
      ),
    );
  }
}

// ─── Period nav chevron ───────────────────────────────────────────────────────

class _NavChevron extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  const _NavChevron({
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
