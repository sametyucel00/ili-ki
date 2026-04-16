class AppConfigModel {
  const AppConfigModel({
    required this.starterCredits,
    required this.freeDailyCredits,
    required this.linkBonusCredits,
    required this.replyGenerationCost,
    required this.messageAnalysisCost,
    required this.situationStrategyCost,
    required this.guestDailyLimit,
    required this.linkedDailyLimit,
    required this.aiCooldownSeconds,
    required this.latestPromptVersion,
    required this.maintenanceMode,
    required this.premiumFeatures,
    required this.softPaywallThreshold,
  });

  final int starterCredits;
  final int freeDailyCredits;
  final int linkBonusCredits;
  final int replyGenerationCost;
  final int messageAnalysisCost;
  final int situationStrategyCost;
  final int guestDailyLimit;
  final int linkedDailyLimit;
  final int aiCooldownSeconds;
  final String latestPromptVersion;
  final bool maintenanceMode;
  final List<String> premiumFeatures;
  final int softPaywallThreshold;
}
