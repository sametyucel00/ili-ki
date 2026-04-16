import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:iliski_kocu_ai/shared/models/app_config_model.dart';

class RemoteConfigService {
  const RemoteConfigService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  Future<AppConfigModel> initialize() async {
    await _remoteConfig.setDefaults(const {
      'starter_credits': 3,
      'free_daily_credits': 2,
      'link_bonus_credits': 3,
      'reply_generation_cost': 1,
      'message_analysis_cost': 1,
      'situation_strategy_cost': 2,
      'guest_daily_limit': 3,
      'linked_daily_limit': 10,
      'ai_cooldown_seconds': 20,
      'soft_paywall_threshold': 2,
      'latest_prompt_version': 'v1',
      'maintenance_mode': false,
    });
    await _remoteConfig.fetchAndActivate();
    return AppConfigModel(
      starterCredits: _remoteConfig.getInt('starter_credits'),
      freeDailyCredits: _remoteConfig.getInt('free_daily_credits'),
      linkBonusCredits: _remoteConfig.getInt('link_bonus_credits'),
      replyGenerationCost: _remoteConfig.getInt('reply_generation_cost'),
      messageAnalysisCost: _remoteConfig.getInt('message_analysis_cost'),
      situationStrategyCost: _remoteConfig.getInt('situation_strategy_cost'),
      guestDailyLimit: _remoteConfig.getInt('guest_daily_limit'),
      linkedDailyLimit: _remoteConfig.getInt('linked_daily_limit'),
      aiCooldownSeconds: _remoteConfig.getInt('ai_cooldown_seconds'),
      latestPromptVersion: _remoteConfig.getString('latest_prompt_version'),
      maintenanceMode: _remoteConfig.getBool('maintenance_mode'),
      premiumFeatures: const ['deep_analysis', 'restore_purchases', 'history_sync'],
      softPaywallThreshold: _remoteConfig.getInt('soft_paywall_threshold'),
    );
  }
}
