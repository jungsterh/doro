import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doro/core/constants/app_constants.dart';
import 'package:doro/providers/premium_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<PremiumNotifier> makeNotifier() async {
    final notifier = PremiumNotifier();
    await Future.delayed(Duration.zero); // allow async _load() to complete
    return notifier;
  }

  group('PremiumNotifier', () {
    group('initial state', () {
      test('defaults to false when no persisted value', () async {
        final notifier = await makeNotifier();
        expect(notifier.state, isFalse);
      });

      test('loads true from SharedPreferences on construction', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.prefIsPremium: true,
        });
        final notifier = await makeNotifier();
        expect(notifier.state, isTrue);
      });

      test('loads false from SharedPreferences on construction', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.prefIsPremium: false,
        });
        final notifier = await makeNotifier();
        expect(notifier.state, isFalse);
      });
    });

    group('setPremium()', () {
      test('updates state to true', () async {
        final notifier = await makeNotifier();
        await notifier.setPremium(true);
        expect(notifier.state, isTrue);
      });

      test('updates state to false', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.prefIsPremium: true,
        });
        final notifier = await makeNotifier();
        await notifier.setPremium(false);
        expect(notifier.state, isFalse);
      });

      test('persists true to SharedPreferences', () async {
        final notifier = await makeNotifier();
        await notifier.setPremium(true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(AppConstants.prefIsPremium), isTrue);
      });

      test('persists false to SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.prefIsPremium: true,
        });
        final notifier = await makeNotifier();
        await notifier.setPremium(false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(AppConstants.prefIsPremium), isFalse);
      });
    });

    group('ProviderContainer reads premium state from SharedPreferences', () {
      // Demonstrates the pattern used in widget/provider integration tests:
      // seed SharedPreferences, then read premiumProvider from a container.
      test('container reads true when SharedPreferences has true', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.prefIsPremium: true,
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(premiumProvider); // trigger notifier creation + _load()
        await Future.delayed(Duration.zero); // allow async _load() to complete
        expect(container.read(premiumProvider), isTrue);
      });

      test('container reads false when SharedPreferences has false', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.prefIsPremium: false,
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(premiumProvider); // trigger notifier creation + _load()
        await Future.delayed(Duration.zero); // allow async _load() to complete
        expect(container.read(premiumProvider), isFalse);
      });
    });
  });
}
