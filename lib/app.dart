import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'pages/home/home_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/onboarding/subscription_benefit_page.dart';
import 'providers/theme_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/auth_provider.dart';

class DoroApp extends ConsumerWidget {
  const DoroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final onboardingDone = ref.watch(onboardingProvider);
    final authState = ref.watch(authProvider);

    // Router logic:
    // 1. If onboarding not done → show OnboardingPage
    // 2. If just signed in (authenticated but no onboarding flag yet) → show SubscriptionBenefitPage
    // 3. Otherwise → show HomePage
    Widget home;
    if (!onboardingDone) {
      home = const OnboardingPage();
    } else if (authState.isAuthenticated && authState.user?.isTrialActive == true) {
      // Show subscription benefits page if user just signed up with active trial
      home = const SubscriptionBenefitPage();
    } else {
      home = const HomePage();
    }

    return MaterialApp(
      title: 'Doro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: home,
      routes: {
        '/subscription-benefits': (context) => const SubscriptionBenefitPage(),
      },
    );
  }
}
