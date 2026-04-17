import 'package:iliski_kocu_ai/core/services/analytics_service.dart';
import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/shared/models/app_user.dart';
import 'package:uuid/uuid.dart';

class AuthRepository {
  AuthRepository({
    required AnalyticsService analytics,
    required LocalCacheService cache,
  })  : _analytics = analytics,
        _cache = cache;

  final AnalyticsService _analytics;
  final LocalCacheService _cache;
  final Uuid _uuid = const Uuid();

  Future<AppUser> bootstrapSession() async {
    final existing = await _cache.readUserProfile();
    final now = DateTime.now();

    if (existing != null) {
      final user = AppUser.fromMap(existing).copyWith(lastLoginAt: now);
      final merged = await _mergeLocalState(user);
      await _cache.writeUserProfile(merged.toMap());
      return merged;
    }

    final newUser = AppUser(
      uid: _uuid.v4(),
      displayName: _generateNickname(),
      email: null,
      photoUrl: null,
      provider: 'local',
      authType: 'local',
      isGuest: false,
      isLinked: false,
      createdAt: now,
      lastLoginAt: now,
      linkedAt: null,
      language: 'tr',
      planType: 'free',
      creditBalance: 1,
      isOnboarded: false,
      subscriptionStatus: 'inactive',
      subscriptionPlatform: null,
      subscriptionExpiryDate: null,
      notificationEnabled: false,
      deletedAt: null,
    );

    await _cache.writeUserProfile(newUser.toMap());
    await _cache.setLocalCreditBalance(1);
    await _analytics.logEvent('local_session_created');
    return newUser;
  }

  Future<void> markOnboardingCompleted() async {
    await _cache.markOnboardingSeen();
    final user = await getCurrentProfile();
    final updated = user.copyWith(isOnboarded: true, lastLoginAt: DateTime.now());
    await _cache.writeUserProfile(updated.toMap());
    await _analytics.logEvent('onboarding_completed');
  }

  Future<bool> isOnboardingSeen() => _cache.isOnboardingSeen();

  Future<AppUser> getCurrentProfile() async {
    final existing = await _cache.readUserProfile();
    if (existing == null) {
      return bootstrapSession();
    }
    return _mergeLocalState(AppUser.fromMap(existing));
  }

  Future<void> linkWithGoogle() async {}

  Future<void> linkWithApple() async {}

  Future<void> linkWithEmail(String email, String password) async {}

  Future<void> deleteAllData() async {
    await _cache.clearAll();
    await bootstrapSession();
  }

  Future<void> deleteAccount() async {
    await _cache.clearAll();
  }

  Future<void> signOutGuestAware() async {
    await _cache.clearAll();
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = await getCurrentProfile();
    final updated = user.copyWith(
      displayName: displayName.trim(),
      lastLoginAt: DateTime.now(),
    );
    await _cache.writeUserProfile(updated.toMap());
  }

  Future<AppUser> _mergeLocalState(AppUser user) async {
    final localCredits = await _cache.getLocalCreditBalance();
    final localPlanType = await _cache.getLocalPlanType();
    final localSubscriptionStatus = await _cache.getLocalSubscriptionStatus();
    final localPremiumExpiry = await _cache.getLocalPremiumExpiry();
    final localPremiumProductId = await _cache.getLocalPremiumProductId();

    final hasIncompletePremiumState =
        (localPlanType == 'premium' || localSubscriptionStatus == 'active') &&
        (localPremiumExpiry == null || localPremiumProductId == null);
    if (hasIncompletePremiumState ||
        (localPremiumExpiry != null && localPremiumExpiry.isBefore(DateTime.now()))) {
      await _cache.clearLocalPremiumState();
      final fallback = user.copyWith(
        planType: 'free',
        subscriptionStatus: 'inactive',
        subscriptionExpiryDate: null,
      );
      await _cache.writeUserProfile(fallback.toMap());
      return fallback.copyWith(
        creditBalance: localCredits ?? fallback.creditBalance,
      );
    }

    final merged = user.copyWith(
      planType: localPlanType ?? user.planType,
      creditBalance: localCredits ?? user.creditBalance,
      subscriptionStatus: localSubscriptionStatus ?? user.subscriptionStatus,
      subscriptionExpiryDate: localPremiumExpiry ?? user.subscriptionExpiryDate,
    );
    await _cache.writeUserProfile(merged.toMap());
    return merged;
  }

  String _generateNickname() {
    final adjectives = ['Sakin', 'Nazik', 'Dingin', 'Yumuşak', 'Işıl', 'Derin'];
    final nouns = ['Rüzgar', 'Yıldız', 'Deniz', 'Kalp', 'Ayışığı', 'Yol'];
    final now = DateTime.now().millisecondsSinceEpoch;
    final adjective = adjectives[now % adjectives.length];
    final noun = nouns[(now ~/ 7) % nouns.length];
    return '$adjective $noun';
  }
}
