import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/session.dart';
import '../../../models/task.dart';

class SessionTrendChart extends StatelessWidget {
  final List<Session> sessions;
  final Task? task;

  const SessionTrendChart({
    super.key,
    required this.sessions,
    this.task,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = task?.color ?? Theme.of(context).colorScheme.primary;

    final completed = sessions.where((s) => s.isCompleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (completed.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = completed.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.durationSeconds / 60.0, // minutes
      );
    }).toList();

    // Calculate proper Y-axis range
    final maxDuration =
        spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxY = (maxDuration * 1.2).ceil().toDouble(); // 20% padding, minimum 5
    final actualMaxY = maxY < 5 ? 5.0 : maxY;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Trend',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: actualMaxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder)
                      .withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= completed.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        DateFormat('M/d')
                            .format(completed[idx].startTime),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 22,
                    interval: completed.length > 5
                        ? (completed.length / 5).ceilToDouble()
                        : 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        '${value.toInt()}m',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: accent,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: accent,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: accent.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
