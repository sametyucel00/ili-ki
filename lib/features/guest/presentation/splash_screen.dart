import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (_, next) {
      next.whenData((user) {
        if (user == null) {
          return;
        }
        context.go(user.isOnboarded ? '/home' : '/onboarding');
      });
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.8),
            ),
          ],
        ),
      ),
    );
  }
}
