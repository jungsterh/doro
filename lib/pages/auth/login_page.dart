import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String provider; // 'google' or 'apple'

  const LoginPage({super.key, required this.provider});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger the OAuth sign-in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSignIn();
    });
  }

  Future<void> _performSignIn() async {
    try {
      if (widget.provider == 'google') {
        await ref.read(authProvider.notifier).signInWithGoogle();
      } else if (widget.provider == 'apple') {
        await ref.read(authProvider.notifier).signInWithApple();
      }

      // After successful sign-in, mark onboarding as done
      if (mounted && ref.read(authProvider).isAuthenticated) {
        await ref.read(onboardingProvider.notifier).markOnboardingDone();
        // Navigation will be handled automatically by app.dart routing
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        // Go back to onboarding
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authState.isLoading)
              Column(
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Signing you in...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white : AppColors.lightText,
                        ),
                  ),
                ],
              )
            else if (authState.error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign-in failed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white : AppColors.lightText,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      authState.error ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
