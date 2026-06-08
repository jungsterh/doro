import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doro/core/constants/app_constants.dart';
import 'package:doro/providers/recent_tasks_provider.dart';

void main() {
  // Reset SharedPreferences mock before each test so tests are isolated.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Helper: create notifier and wait for async _load() to finish.
  Future<RecentTasksNotifier> makeNotifier() async {
    final notifier = RecentTasksNotifier();
    // Yield to the event loop so the async _load() completes.
    await Future.delayed(Duration.zero);
    return notifier;
  }

  // ---------------------------------------------------------------------------
  group('initial state', () {
    test('starts empty when no saved data', () async {
      final notifier = await makeNotifier();
      expect(notifier.state, isEmpty);
    });

    test('loads persisted ids on construction', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefRecentTaskIds: ['task-x', 'task-y'],
      });
      final notifier = await makeNotifier();
      expect(notifier.state, ['task-x', 'task-y']);
    });
  });

  // ---------------------------------------------------------------------------
  group('recordUsed', () {
    test('adds new id to front of empty list', () async {
      final notifier = await makeNotifier();
      await notifier.recordUsed('task-1');
      expect(notifier.state, ['task-1']);
    });

    test('adds newer id in front of older one', () async {
      final notifier = await makeNotifier();
      await notifier.recordUsed('task-1');
      await notifier.recordUsed('task-2');
      expect(notifier.state.first, 'task-2');
      expect(notifier.state[1], 'task-1');
    });

    test('re-using an existing id moves it to front', () async {
      final notifier = await makeNotifier();
      await notifier.recordUsed('task-1');
      await notifier.recordUsed('task-2');
      await notifier.recordUsed('task-3');
      await notifier.recordUsed('task-1'); // re-use
      expect(notifier.state, ['task-1', 'task-3', 'task-2']);
    });

    test('re-using front id keeps list the same', () async {
      final notifier = await makeNotifier();
      await notifier.recordUsed('task-1');
      await notifier.recordUsed('task-2');
      await notifier.recordUsed('task-2'); // re-use front
      expect(notifier.state, ['task-2', 'task-1']);
    });

    test('no duplicate ids after re-use', () async {
      final notifier = await makeNotifier();
      await notifier.recordUsed('task-A');
      await notifier.recordUsed('task-B');
      await notifier.recordUsed('task-A');
      expect(notifier.state.where((id) => id == 'task-A').length, 1);
    });

    test('respects recentTasksLimit — never exceeds it', () async {
      final notifier = await makeNotifier();
      for (var i = 0; i < AppConstants.recentTasksLimit + 5; i++) {
        await notifier.recordUsed('task-$i');
      }
      expect(notifier.state.length, AppConstants.recentTasksLimit);
    });

    test('most recent id is always at index 0 after limit overflow', () async {
      final notifier = await makeNotifier();
      for (var i = 0; i < AppConstants.recentTasksLimit + 3; i++) {
        await notifier.recordUsed('task-$i');
      }
      // Last added should be at front
      expect(
          notifier.state.first,
          'task-${AppConstants.recentTasksLimit + 2}');
    });

    test('persists ids to SharedPreferences', () async {
      final notifier = await makeNotifier();
      await notifier.recordUsed('task-abc');

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(AppConstants.prefRecentTaskIds);
      expect(saved, isNotNull);
      expect(saved, contains('task-abc'));
    });

    test('persisted order matches state order', () async {
      final notifier = await makeNotifier();
      await notifier.recordUsed('task-1');
      await notifier.recordUsed('task-2');
      await notifier.recordUsed('task-3');

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(AppConstants.prefRecentTaskIds)!;
      expect(saved, notifier.state);
    });
  });

  // ---------------------------------------------------------------------------
  group('state integrity across multiple calls', () {
    test('5 unique tasks → list length is 5', () async {
      final notifier = await makeNotifier();
      for (var i = 1; i <= 5; i++) {
        await notifier.recordUsed('task-$i');
      }
      expect(notifier.state.length, 5);
    });

    test('order is most-recent-first', () async {
      final notifier = await makeNotifier();
      await notifier.recordUsed('first');
      await notifier.recordUsed('second');
      await notifier.recordUsed('third');
      expect(notifier.state, ['third', 'second', 'first']);
    });
  });
}
