import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class RecentTasksNotifier extends StateNotifier<List<String>> {
  RecentTasksNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(AppConstants.prefRecentTaskIds) ?? [];
  }

  Future<void> recordUsed(String taskId) async {
    final updated = [
      taskId,
      ...state.where((id) => id != taskId),
    ].take(AppConstants.recentTasksLimit).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.prefRecentTaskIds, updated);
  }
}

final recentTasksProvider =
    StateNotifierProvider<RecentTasksNotifier, List<String>>(
  (ref) => RecentTasksNotifier(),
);
