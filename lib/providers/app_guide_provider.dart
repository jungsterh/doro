import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// `null`  = loading (pref not yet read — overlay stays hidden)
/// `false` = guide not yet seen — overlay visible
/// `true`  = guide dismissed — overlay hidden
class AppGuideNotifier extends StateNotifier<bool?> {
  AppGuideNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(AppConstants.prefAppGuideDone) ?? false;
    } catch (e) {
      debugPrint('AppGuideNotifier load error: $e');
      state = false; // Default to showing the guide on error
    }
  }

  Future<void> markDone() async {
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefAppGuideDone, true);
    } catch (e) {
      debugPrint('AppGuideNotifier markDone error: $e');
    }
  }

  /// For testing / debug reset
  Future<void> reset() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefAppGuideDone, false);
  }
}

final appGuideProvider =
    StateNotifierProvider<AppGuideNotifier, bool?>((ref) => AppGuideNotifier());
