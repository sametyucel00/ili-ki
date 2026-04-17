import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iliski_kocu_ai/core/services/ai_backend_service.dart';
import 'package:iliski_kocu_ai/core/services/analytics_service.dart';
import 'package:iliski_kocu_ai/core/services/connectivity_service.dart';
import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/core/services/notification_service.dart';
import 'package:iliski_kocu_ai/core/services/paywall_service.dart';
import 'package:iliski_kocu_ai/core/services/purchases_service.dart';
import 'package:iliski_kocu_ai/core/services/rewarded_ad_service.dart';
import 'package:iliski_kocu_ai/core/services/remote_config_service.dart';
import 'package:iliski_kocu_ai/features/analysis/data/analysis_repository.dart';
import 'package:iliski_kocu_ai/features/auth/data/auth_repository.dart';
import 'package:iliski_kocu_ai/features/history/data/history_repository.dart';
import 'package:iliski_kocu_ai/features/premium/data/premium_repository.dart';
import 'package:iliski_kocu_ai/shared/models/app_config_model.dart';

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final localCacheServiceProvider =
    Provider<LocalCacheService>((ref) => LocalCacheService());
final analyticsServiceProvider =
    Provider<AnalyticsService>((ref) => const AnalyticsService());
final aiBackendServiceProvider =
    Provider<AiBackendService>((ref) => AiBackendService());
final remoteConfigServiceProvider =
    Provider<RemoteConfigService>((ref) => const RemoteConfigService());
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(ref.watch(connectivityProvider)),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.watch(analyticsServiceProvider)),
);
final paywallServiceProvider =
    Provider<PaywallService>((ref) => const PaywallService());
final purchasesServiceProvider = Provider<PurchasesService>(
  (ref) => PurchasesService(ref.watch(analyticsServiceProvider)),
);
final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => RewardedAdService(ref.watch(analyticsServiceProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    analytics: ref.watch(analyticsServiceProvider),
    cache: ref.watch(localCacheServiceProvider),
  ),
);

final analysisRepositoryProvider = Provider<AnalysisRepository>(
  (ref) => AnalysisRepository(
    cache: ref.watch(localCacheServiceProvider),
    analytics: ref.watch(analyticsServiceProvider),
    config: ref.watch(remoteConfigServiceProvider),
    aiBackend: ref.watch(aiBackendServiceProvider),
  ),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(
    cache: ref.watch(localCacheServiceProvider),
  ),
);

final premiumRepositoryProvider = Provider<PremiumRepository>(
  (ref) => PremiumRepository(
    cache: ref.watch(localCacheServiceProvider),
    purchases: ref.watch(purchasesServiceProvider),
    analytics: ref.watch(analyticsServiceProvider),
  ),
);

final appConfigProvider = FutureProvider<AppConfigModel>((ref) async {
  return ref.watch(remoteConfigServiceProvider).initialize();
});
