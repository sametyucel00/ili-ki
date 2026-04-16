import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/features/account_linking/presentation/account_linking_screen.dart';
import 'package:iliski_kocu_ai/features/analysis/presentation/analysis_detail_screen.dart';
import 'package:iliski_kocu_ai/features/analysis/presentation/message_analysis_screen.dart';
import 'package:iliski_kocu_ai/features/guest/presentation/splash_screen.dart';
import 'package:iliski_kocu_ai/features/history/presentation/history_screen.dart';
import 'package:iliski_kocu_ai/features/home/presentation/home_screen.dart';
import 'package:iliski_kocu_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:iliski_kocu_ai/features/premium/presentation/premium_screen.dart';
import 'package:iliski_kocu_ai/features/profile/presentation/privacy_policy_screen.dart';
import 'package:iliski_kocu_ai/features/profile/presentation/profile_screen.dart';
import 'package:iliski_kocu_ai/features/profile/presentation/terms_screen.dart';
import 'package:iliski_kocu_ai/features/replies/presentation/reply_generator_screen.dart';
import 'package:iliski_kocu_ai/features/strategy/presentation/strategy_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/analysis', builder: (_, __) => const MessageAnalysisScreen()),
      GoRoute(path: '/replies', builder: (_, __) => const ReplyGeneratorScreen()),
      GoRoute(path: '/strategy', builder: (_, __) => const StrategyScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(
        path: '/detail/:id',
        builder: (_, state) => AnalysisDetailScreen(analysisId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/link-account', builder: (_, __) => const AccountLinkingScreen()),
      GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
    ],
  );
});
