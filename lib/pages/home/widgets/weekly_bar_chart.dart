import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/session.dart';
import '../../../models/task.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<Session> sessions;
  final List<Task> tasks;

  const WeeklyBarChart({
    super.key,
    required this.sessions,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final data = _buildChartData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _maxHours(data),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toStringAsFixed(1)}h',
                      TextStyle(color: Colors.white, fontSize: 12),
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
                      final days = _last7Days();
                      final idx = value.toInt();
                      if (idx < 0 || idx >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        DateFormat('E').format(days[idx]),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                        ),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        '${value.toInt()}h',
                        style: TextStyle(color: textColor, fontSize: 10),
                      );
                    },
                    reservedSize: 28,
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
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder)
                        .withValues(alpha: 0.5),
                    strokeWidth: 1,
                  );
                },
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              barGroups: _buildBarGroups(data),
            ),
          ),
        ),
      ],
    );
  }

  List<DateTime> _last7Days() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  Map<int, Map<String, double>> _buildChartData() {
    final days = _last7Days();
    final data = <int, Map<String, double>>{};

    for (int i = 0; i < 7; i++) {
      data[i] = {};
    }

    for (final session in sessions) {
      if (!session.isCompleted) continue;
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      for (int i = 0; i < days.length; i++) {
        if (sessionDate == days[i]) {
          final hours = session.durationSeconds / 3600.0;
          data[i]![session.taskId] =
              (data[i]![session.taskId] ?? 0) + hours;
          break;
        }
      }
    }

    return data;
  }

  double _maxHours(Map<int, Map<String, double>> data) {
    double max = 1;
    for (final dayData in data.values) {
      final total = dayData.values.fold(0.0, (a, b) => a + b);
      if (total > max) max = total;
    }
    return (max * 1.2).ceilToDouble();
  }

  List<BarChartGroupData> _buildBarGroups(
      Map<int, Map<String, double>> data) {
    return List.generate(7, (i) {
      final dayData = data[i] ?? {};
      double startY = 0;

      // Simple: stack all task hours
      if (dayData.isEmpty) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: Colors.transparent,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }

      // Use color from task
      final taskMap = {for (final t in tasks) t.id: t};

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
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}
