import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../models/session.dart';
import '../../../models/task.dart';
import '../../../providers/session_provider.dart';
import '../../../widgets/glass_card.dart';
import '../../session/session_detail_page.dart';

class RecentSessionsList extends ConsumerWidget {
  final List<Session> sessions;
  final List<Task> tasks;
  final int maxItems;

  const RecentSessionsList({
    super.key,
    required this.sessions,
    required this.tasks,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = sessions.where((s) => s.isCompleted).take(maxItems).toList();
    final taskMap = {for (final t in tasks) t.id: t};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (completed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No sessions yet. Start tracking!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Sessions',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...completed.map((session) {
          final task = taskMap[session.taskId];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: ValueKey(session.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 22),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Session?'),
                    content: const Text('This session will be permanently removed.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Delete',
                            style: TextStyle(
                                color: Theme.of(ctx).colorScheme.error)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) async {
                await ref.read(sessionServiceProvider).deleteSession(session.id);
                ref.invalidate(sessionsProvider);
              },
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionDetailPage(
                      session: session,
                      task: task,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: task?.color ?? AppColors.darkAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task?.name ?? 'Unknown Task',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, h:mm a')
                                .format(session.startTime),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DurationFormatter.fromSeconds(session.durationSeconds),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
