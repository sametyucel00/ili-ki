import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iliski_kocu_ai/core/services/analytics_service.dart';

class RewardedAdService {
  RewardedAdService(this._analytics);

  final AnalyticsService _analytics;

  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7422131853794926/8791858882';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-7422131853794926/5389789590';
    }
    return '';
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  Future<bool> showRewardedAd(Future<void> Function() onRewardEarned) async {
    if (_adUnitId.isEmpty) {
      return false;
    }

    final completer = Completer<bool>();
    await _analytics.logEvent('rewarded_ad_requested');

    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) async {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );

          await ad.show(
            onUserEarnedReward: (_, __) async {
              await _analytics.logEvent('rewarded_ad_completed');
              await onRewardEarned();
              if (!completer.isCompleted) {
                completer.complete(true);
              }
            },
          );
        },
        onAdFailedToLoad: (error) async {
          await _analytics.logEvent('rewarded_ad_failed', {'code': error.code});
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future;
  }
}
