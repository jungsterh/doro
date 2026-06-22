/// End-to-end user workflow tests covering the six core scenarios:
/// 1. Creating a new task
/// 2. Starting a session (timer runs)
/// 3. Pausing then stopping a session (record saved)
/// 4. Cancelling a session (record not saved)
/// 5. Dashboard with graphs (swipe left)
/// 6. Dark / light mode toggle
///
/// Run on a connected device or emulator:
///   flutter test integration_test/app_workflow_test.dart
///
/// Setup notes:
/// - Uses in-memory SQLite — no real database is written to.
/// - Provider overrides bypass Supabase auth and IAP.
/// - SharedPreferences mocks skip onboarding and seed theme state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:doro/app.dart';
import 'package:doro/core/constants/app_constants.dart';
import 'package:doro/pages/home/widgets/activity_pie_chart.dart';
import 'package:doro/pages/home/widgets/weekly_bar_chart.dart';
import 'package:doro/pages/timer/timer_page.dart';
import 'package:doro/pages/timer/widgets/flip_clock.dart';
import 'package:doro/providers/auth_provider.dart';
import 'package:doro/providers/session_provider.dart';
import 'package:doro/providers/task_provider.dart';
import 'package:doro/services/database_service.dart';
import 'package:doro/services/session_service.dart';
import 'package:doro/services/task_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      AppConstants.prefIsPremium: false,
      AppConstants.prefDarkMode: true,
    });
    db = await DatabaseService.openInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp() => ProviderScope(
        overrides: [
          taskServiceProvider.overrideWithValue(TaskService(db: db)),
          sessionServiceProvider.overrideWithValue(SessionService(db: db)),
          authProvider.overrideWith((ref) => AuthNotifier.unauthenticated()),
        ],
        child: const DoroApp(),
      );

  // Opens the task dropdown, taps "Add new task", fills in [name], and taps
  // Create. After this the task is selected in the dropdown trigger row.
  Future<void> createAndSelectTask(WidgetTester tester, String name) async {
    await tester.tap(find.text('Select a task...'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add new task'));
    await tester.pumpAndSettle();

    // Only the dialog's name TextField is visible at this point.
    await tester.enterText(find.byType(TextField).first, name);
    await tester.pump();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Create new task
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('1. Create new task — appears selected in dropdown',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await createAndSelectTask(tester, 'Deep Work');

    // Task name shown in the dropdown trigger row.
    expect(find.text('Deep Work'), findsOneWidget);
    // START button is visible (it was always there, now enabled).
    expect(find.text('START'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Start session — timer runs
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('2. Tap START — timer page opens and session is running',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await createAndSelectTask(tester, 'Focus');

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    // Timer page rendered.
    expect(find.byType(TimerPage), findsOneWidget);
    // Task name shown on timer page.
    expect(find.text('Focus'), findsOneWidget);
    // Clock widget present.
    expect(find.byType(FlipClock), findsOneWidget);
    // Control drawer slid in automatically — Pause button confirms session is running.
    expect(find.text('Pause'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Pause then stop — session record is saved
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('3. Pause timer then stop — session saved to database',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await createAndSelectTask(tester, 'Writing');

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    // Pause.
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();

    expect(find.text('PAUSED'), findsOneWidget);

    // Stop — the drawer hides first, then the confirmation dialog appears.
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(find.text('Stop Session?'), findsOneWidget);
    // Tap the 'Stop' action in the dialog (drawer is now hidden).
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    // Timer page replaced by summary page.
    expect(find.byType(TimerPage), findsNothing);
    // Session was written to the in-memory database.
    final sessions = await db.getSessions();
    expect(sessions, hasLength(1));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Cancel timer — session NOT saved
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('4. Cancel timer — session discarded, back on home page',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await createAndSelectTask(tester, 'Exercise');

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    // Cancel via control drawer.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel Session?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    // Returned to home page.
    expect(find.text('START'), findsOneWidget);
    // No session was persisted.
    final sessions = await db.getSessions();
    expect(sessions, isEmpty);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Dashboard — graphs available on swipe left
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('5. Swipe left — dashboard shows bar and pie charts',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Fling left on the PageView to navigate to the dashboard page.
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 2000);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    // Charts are rendered even with empty data.
    expect(find.byType(WeeklyBarChart), findsOneWidget);
    expect(find.byType(ActivityPieChart), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Theme toggle — dark / light mode
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('6. Dark/light mode toggle updates the MaterialApp theme',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Open settings (settings icon is in the top-right of the start page).
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);

    // App starts in dark mode per the SharedPreferences mock — toggle to light.
    final darkModeTile = find.ancestor(
      of: find.text('Dark Mode'),
      matching: find.byType(SwitchListTile),
    );
    await tester.tap(darkModeTile);
    await tester.pumpAndSettle();

    // MaterialApp is now using the light theme.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, equals(ThemeMode.light));
  });
}
