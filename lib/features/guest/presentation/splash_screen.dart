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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6DDD3), Color(0xFFC78E84)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(56),
                ),
                padding: const EdgeInsets.all(18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset('assets/branding/app-icon-master.png'),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'İlişki Koçu AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF3A2928),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sakin, dengeli, yorumlayıcı iletişim desteği',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6B5B58),
                    ),
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
      ),
    );
  }
}
