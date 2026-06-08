import 'package:flutter/material.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../models/session.dart';
import '../../../models/task.dart';

class SessionHeader extends StatelessWidget {
  final Session session;
  final Task? task;

  const SessionHeader({
    super.key,
    required this.session,
    this.task,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (task != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: task!.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                task!.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Text(
          DurationFormatter.fromSeconds(session.durationSeconds),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Great session!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color,
              ),
        ),
      ],
    );
  }
}
