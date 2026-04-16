import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iliski_kocu_ai/core/config/app_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/core/theme/app_theme.dart';

class IliskiKocuAiApp extends ConsumerWidget {
  const IliskiKocuAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
