import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/session.dart';
import '../../providers/session_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/glass_card.dart';
import 'widgets/acknowledge_button.dart';
import 'widgets/comment_input.dart';
import 'widgets/session_header.dart';
import 'widgets/session_trend_chart.dart';

class SummaryPage extends ConsumerStatefulWidget {
  final Session session;

  const SummaryPage({super.key, required this.session});

  @override
  ConsumerState<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends ConsumerState<SummaryPage> {
  late final TextEditingController _commentController =
      TextEditingController(text: widget.session.comment ?? '');

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(tasksProvider);
    final sessionsAsync = ref.watch(sessionsByTaskProvider(widget.session.taskId));

    final taskList = taskAsync.valueOrNull ?? [];
    final taskMatches =
        taskList.where((t) => t.id == widget.session.taskId);
    final task = taskMatches.isEmpty ? null : taskMatches.first;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _done,
              ),
              title: const Text('Session Summary'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: SessionHeader(
                      session: widget.session,
                      task: task,
                    ),
                  ),

                  // Trend chart
                  sessionsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (sessions) => sessions.length > 1
                        ? GlassCard(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: SessionTrendChart(
                              sessions: sessions,
                              task: task,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Comment input
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Session Note',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: CommentInput(
                            controller: _commentController,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Done button
                  AcknowledgeButton(
                    onPressed: _done,
                    label: 'Done',
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _done() async {
    // The session was saved with no note when the timer stopped, so persist
    // whatever the user typed here before leaving.
    final text = _commentController.text;
    if (text.trim() != (widget.session.comment ?? '')) {
      await ref
          .read(activeSessionProvider.notifier)
          .updateSessionComment(widget.session, text);
    }
    // Refresh sessions on home
    ref.invalidate(sessionsProvider);
    ref.invalidate(sessionsByTaskProvider(widget.session.taskId));
    if (mounted) {
      Navigator.of(context)
          .popUntil((route) => route.isFirst);
    }
  }
}
