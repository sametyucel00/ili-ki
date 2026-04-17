import 'package:iliski_kocu_ai/shared/models/app_config_model.dart';
import 'package:iliski_kocu_ai/shared/models/app_user.dart';

class PaywallService {
  const PaywallService();

  bool shouldPromptForLink({
    required AppUser? user,
    required int completedAnalyses,
    required bool enteringHistory,
    required bool attemptingPurchase,
  }) {
    if (user == null || !user.isGuest) {
      return false;
    }
    return completedAnalyses >= 1 || enteringHistory || attemptingPurchase;
  }

  bool shouldShowSoftPaywall({
    required AppUser? user,
    required AppConfigModel config,
    required int completedAnalyses,
  }) {
    if (user?.isPremium == true) {
      return false;
    }
    return completedAnalyses >= config.softPaywallThreshold ||
        (user?.creditBalance ?? 0) <= 0;
  }
}
