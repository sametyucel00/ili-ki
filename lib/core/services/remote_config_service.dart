import 'package:iliski_kocu_ai/shared/models/app_config_model.dart';

class RemoteConfigService {
  const RemoteConfigService();

  Future<AppConfigModel> initialize() async {
    return const AppConfigModel(
      starterCredits: 5,
      freeDailyCredits: 2,
      linkBonusCredits: 0,
      replyGenerationCost: 1,
      messageAnalysisCost: 1,
      situationStrategyCost: 2,
      guestDailyLimit: 10,
      linkedDailyLimit: 20,
      aiCooldownSeconds: 20,
      latestPromptVersion: 'local-v1',
      maintenanceMode: false,
      premiumFeatures: ['deep_analysis', 'extended_history'],
      softPaywallThreshold: 2,
    );
  }
}
