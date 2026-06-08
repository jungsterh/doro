import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/date_range_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/glass_card.dart';
import '../premium/premium_page.dart';
import '../settings/settings_page.dart';
import 'widgets/activity_pie_chart.dart';
import 'widgets/recent_sessions_list.dart';
import 'widgets/start_task_panel.dart';
import 'widgets/weekly_bar_chart.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _StartPage(isDark: isDark),
              _DashboardPage(isDark: isDark),
            ],
          ),

          // Page indicator dots
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? (isDark
                            ? AppColors.darkAccent
                            : AppColors.lightAccent)
                        : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary)
                            .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _StartPage extends ConsumerWidget {
  final bool isDark;
  const _StartPage({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isLandscape ? 12 : 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (!isLandscape)
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 8 : 24),
            const Expanded(child: StartTaskPanel()),
          ],
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _DashboardPage extends ConsumerWidget {
  final bool isDark;
  const _DashboardPage({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final sessionsAsync =
        isPremium ? ref.watch(filteredSessionsProvider) : ref.watch(sessionsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header row
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dashboard',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _ExportButton(
                          tasksAsync: tasksAsync, sessionsAsync: sessionsAsync),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsPage()),
                        ),
                      ),
                    ],
                  ),
                ),

                // Date range filter (premium only)
                if (isPremium)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _DateRangeFilter(isDark: isDark),
                  ),

                tasksAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (tasks) => sessionsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (sessions) => GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: WeeklyBarChart(sessions: sessions, tasks: tasks),
                    ),
                  ),
                ),

                tasksAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (tasks) => sessionsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (sessions) => GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child:
                          ActivityPieChart(sessions: sessions, tasks: tasks),
                    ),
                  ),
                ),

                tasksAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (tasks) => sessionsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (sessions) => GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: RecentSessionsList(
                          sessions: sessions, tasks: tasks),
                    ),
                  ),
                ),

                if (!isPremium) _PremiumHistoryBanner(isDark: isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeFilter extends ConsumerWidget {
  final bool isDark;
  const _DateRangeFilter({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rangeState = ref.watch(dateRangeProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...DateRange.values
              .where((r) => r != DateRange.custom)
              .map((range) {
            final selected = rangeState.range == range;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () =>
                    ref.read(dateRangeProvider.notifier).setRange(range),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.15)
                        : (isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? accent
                          : (isDark
                              ? AppColors.glassBorderDark
                              : AppColors.glassBorderLight),
                    ),
                  ),
                  child: Text(
                    range.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected
                          ? accent
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            );
          }),
          // Custom range picker
          GestureDetector(
            onTap: () => _pickCustomRange(context, ref),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: rangeState.range == DateRange.custom
                    ? accent.withValues(alpha: 0.15)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: rangeState.range == DateRange.custom
                      ? accent
                      : (isDark
                          ? AppColors.glassBorderDark
                          : AppColors.glassBorderLight),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range,
                      size: 14,
                      color: rangeState.range == DateRange.custom
                          ? accent
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                  const SizedBox(width: 6),
                  Text(
                    rangeState.range == DateRange.custom &&
                            rangeState.customStart != null
                        ? '${DateFormat('MMM d').format(rangeState.customStart!)} – ${DateFormat('MMM d').format(rangeState.customEnd!)}'
                        : 'Custom',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: rangeState.range == DateRange.custom
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: rangeState.range == DateRange.custom
                          ? accent
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );
    if (picked != null) {
      ref.read(dateRangeProvider.notifier).setCustomRange(
            picked.start,
            picked.end.copyWith(hour: 23, minute: 59, second: 59),
          );
    }
  }
}

class _PremiumHistoryBanner extends StatelessWidget {
  final bool isDark;
  const _PremiumHistoryBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      backgroundColor: accent.withValues(alpha: 0.07),
      borderColor: accent.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_clock, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly & yearly history',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upgrade to Premium to look back months and years',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumPage()),
            ),
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final AsyncValue tasksAsync;
  final AsyncValue sessionsAsync;

  const _ExportButton({required this.tasksAsync, required this.sessionsAsync});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return PopupMenuButton<String>(
      icon: Icon(Icons.ios_share_outlined, color: accent),
      tooltip: 'Export',
      onSelected: (value) async {
        final tasks = (tasksAsync.valueOrNull ?? []) as List;
        final sessions = (sessionsAsync.valueOrNull ?? []) as List;
        if (sessions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No sessions to export yet')),
          );
          return;
        }
        final svc = ExportService();
        try {
          if (value == 'pdf') {
            await svc.exportPdf(sessions.cast(), tasks.cast());
          } else {
            await svc.exportCsv(sessions.cast(), tasks.cast());
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Export failed: $e')),
            );
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'pdf',
          child: Row(children: [
            Icon(Icons.picture_as_pdf_outlined, size: 18),
            SizedBox(width: 10),
            Text('Export as PDF'),
          ]),
        ),
        PopupMenuItem(
          value: 'csv',
          child: Row(children: [
            Icon(Icons.table_chart_outlined, size: 18),
            SizedBox(width: 10),
            Text('Export as CSV / Excel'),
          ]),
        ),
      ],
    );
  }
}
