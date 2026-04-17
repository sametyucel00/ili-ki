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
        final remaining = const Duration(milliseconds: 2800) - elapsed;
        final target = user.isOnboarded ? '/home' : '/onboarding';
        Timer(remaining.isNegative ? Duration.zero : remaining, () {
          if (mounted) {
            context.go(target);
          }
        });
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8ECE7),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F5),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8C4BA)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8D4C45).withValues(alpha: 0.13),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 36,
                color: Color(0xFF9E4F49),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF2F2324),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'İletişimi daha net gör',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF7E5D5A),
                  ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: Color(0xFFB8615B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
