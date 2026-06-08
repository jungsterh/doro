import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

enum DisplayMode { digital, flip }

class DisplayModeNotifier extends StateNotifier<DisplayMode> {
  DisplayModeNotifier() : super(DisplayMode.digital) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(AppConstants.prefDisplayMode) ?? 'digital';
    state = val == 'flip' ? DisplayMode.flip : DisplayMode.digital;
  }

  Future<void> setMode(DisplayMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefDisplayMode,
        mode == DisplayMode.flip ? 'flip' : 'digital');
  }
}

final displayModeProvider =
    StateNotifierProvider<DisplayModeNotifier, DisplayMode>(
  (ref) => DisplayModeNotifier(),
);
