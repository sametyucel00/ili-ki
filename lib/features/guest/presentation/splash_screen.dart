import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        final route = user.isOnboarded ? '/home' : '/onboarding';
        context.go(route);
      });
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFB56A63), Color(0xFFE2B3AA)],
                ),
              ),
              child: const Icon(Icons.favorite_outline_rounded, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text('İlişki Koçu AI', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
