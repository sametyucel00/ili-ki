import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseFunctionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: 'europe-west1'),
);
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) => FirebaseAnalytics.instance);
final remoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) => FirebaseRemoteConfig.instance);
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final localCacheServiceProvider = Provider<LocalCacheService>((ref) => LocalCacheService());
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(firebaseAnalyticsProvider)),
);
final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => RemoteConfigService(ref.watch(remoteConfigProvider)),
);
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(ref.watch(connectivityProvider)),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(
    ref.watch(firebaseMessagingProvider),
    ref.watch(analyticsServiceProvider),
  ),
);
final paywallServiceProvider = Provider<PaywallService>((ref) => const PaywallService());
final purchasesServiceProvider = Provider<PurchasesService>(
  (ref) => PurchasesService(ref.watch(analyticsServiceProvider)),
);
final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => RewardedAdService(ref.watch(analyticsServiceProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    functions: ref.watch(firebaseFunctionsProvider),
    analytics: ref.watch(analyticsServiceProvider),
    cache: ref.watch(localCacheServiceProvider),
  ),
);

final analysisRepositoryProvider = Provider<AnalysisRepository>(
  (ref) => AnalysisRepository(
    firestore: ref.watch(firestoreProvider),
    functions: ref.watch(firebaseFunctionsProvider),
    cache: ref.watch(localCacheServiceProvider),
    analytics: ref.watch(analyticsServiceProvider),
  ),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(
    firestore: ref.watch(firestoreProvider),
    cache: ref.watch(localCacheServiceProvider),
  ),
);

final premiumRepositoryProvider = Provider<PremiumRepository>(
  (ref) => PremiumRepository(
    firestore: ref.watch(firestoreProvider),
    functions: ref.watch(firebaseFunctionsProvider),
    purchases: ref.watch(purchasesServiceProvider),
    analytics: ref.watch(analyticsServiceProvider),
  ),
);

final appConfigProvider = FutureProvider<AppConfigModel>((ref) async {
  return ref.watch(remoteConfigServiceProvider).initialize();
});
