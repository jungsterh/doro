import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/session.dart';
import '../../../models/task.dart';

class ActivityPieChart extends StatefulWidget {
  final List<Session> sessions;
  final List<Task> tasks;

  const ActivityPieChart({
    super.key,
    required this.sessions,
    required this.tasks,
  });

  @override
  State<ActivityPieChart> createState() => _ActivityPieChartState();
}

class _ActivityPieChartState extends State<ActivityPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final taskData = _buildTaskData();

    if (taskData.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No activity yet')),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Breakdown',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;
              final chartSize = isWide ? 160.0 : 120.0;
              final gap = isWide ? 48.0 : 28.0;
              return Row(
                children: [
                  SizedBox(
                    height: chartSize,
                    width: chartSize,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex =
                                  response.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: _buildSections(taskData),
                        centerSpaceRadius: isWide ? 40 : 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: taskData.entries.map((entry) {
                        final task = widget.tasks.firstWhere(
                          (t) => t.id == entry.key,
                          orElse: () => Task(
                            id: entry.key,
                            name: 'Unknown',
                            colorHex: '#888888',
                            createdAt: DateTime.now(),
                          ),
                        );
                        final totalSeconds =
                            taskData.values.fold(0.0, (a, b) => a + b);
                        final pct = totalSeconds > 0
                            ? (entry.value / totalSeconds * 100).round()
                            : 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: task.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.name,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$pct%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, double> _buildTaskData() {
    final data = <String, double>{};
    for (final session in widget.sessions) {
      if (!session.isCompleted) continue;
      data[session.taskId] =
          (data[session.taskId] ?? 0) + session.durationSeconds;
    }
    return data;
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data) {
    final taskMap = {for (final t in widget.tasks) t.id: t};
    int i = 0;
    return data.entries.map((entry) {
      final task = taskMap[entry.key];
      final color = task?.color ?? AppColors.darkAccent;
      final isTouched = i == _touchedIndex;
      i++;
      return PieChartSectionData(
        value: entry.value,
        color: color,
        radius: isTouched ? 50 : 40,
        showTitle: false,
      );
    }).toList();
  }
}
