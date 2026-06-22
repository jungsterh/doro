import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingDoneKey = 'onboarding_done';
const _trialBenefitSeenKey = 'trial_benefit_seen';

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

// Tracks whether the trial-benefit page has been shown this install.
class TrialBenefitSeenNotifier extends StateNotifier<bool> {
  TrialBenefitSeenNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_trialBenefitSeenKey) ?? false;
    } catch (e) {
      debugPrint('Error loading trial benefit seen: $e');
    }
  }

  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_trialBenefitSeenKey, true);
      state = true;
    } catch (e) {
      debugPrint('Error saving trial benefit seen: $e');
    }
  }
}

final trialBenefitSeenProvider =
    StateNotifierProvider<TrialBenefitSeenNotifier, bool>(
  (ref) => TrialBenefitSeenNotifier(),
);
