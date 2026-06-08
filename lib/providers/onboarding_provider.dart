import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingDoneKey = 'onboarding_done';

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDone = prefs.getBool(_onboardingDoneKey) ?? false;
      state = isDone;
    } catch (e) {
      debugPrintStack(label: 'Error loading onboarding state: $e');
    }
  }

  Future<void> markOnboardingDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingDoneKey, true);
      state = true;
    } catch (e) {
      debugPrintStack(label: 'Error saving onboarding state: $e');
      rethrow;
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingDoneKey, false);
      state = false;
    } catch (e) {
      debugPrintStack(label: 'Error resetting onboarding: $e');
      rethrow;
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});
