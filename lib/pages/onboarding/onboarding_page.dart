import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_button.dart';
import '../../providers/onboarding_provider.dart';
import '../auth/login_page.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final cardBg = isDark ? AppColors.darkCard : const Color(0xFFF5F5F5);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top section: Logo and title
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBg,
                        border: Border.all(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      'Welcome to Doro',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      'Track your focus, sync across devices',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              // Bottom section: CTA buttons
              Column(
                children: [
                  // Google Sign-In button
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(provider: 'google'),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline, color: textColor),
                          const SizedBox(width: 8),
                          Text('Sign up with Google',
                              style: TextStyle(color: textColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Apple Sign-In button (iOS only)
                  if (Platform.isIOS)
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(provider: 'apple'),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, color: textColor),
                            const SizedBox(width: 8),
                            Text('Continue with Apple',
                                style: TextStyle(color: textColor)),
                          ],
                        ),
                      ),
                    ),
                  if (Platform.isIOS) const SizedBox(height: 24),
                  // Skip option
                  GestureDetector(
                    onTap: () async {
                      // Mark onboarding as done
                      await ref.read(onboardingProvider.notifier).markOnboardingDone();
                    },
                    child: Text(
                      Platform.isIOS ? 'Skip for now' : 'Continue without signing up',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
