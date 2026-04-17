import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      next.whenData((user) {
        if (user == null) {
          return;
        }
        final elapsed = DateTime.now().difference(_startedAt);
        final remaining = const Duration(milliseconds: 1200) - elapsed;
        final target = user.isOnboarded ? '/home' : '/onboarding';
        Timer(remaining.isNegative ? Duration.zero : remaining, () {
          if (mounted) {
            context.go(target);
          }
        });
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A1516),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2022),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF4D363B)),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 36,
                color: Color(0xFFF0B3AA),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFFF6E8E2),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'İletişimi daha net gör',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFD8BBB4),
                  ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: Color(0xFFF0B3AA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
