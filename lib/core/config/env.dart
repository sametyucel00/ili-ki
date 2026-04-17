import 'dart:io';

class Env {
  static const functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'europe-west1',
  );

  static const enableAndroidPurchaseSimulation = bool.fromEnvironment(
    'ENABLE_ANDROID_PURCHASE_SIMULATION',
    defaultValue: true,
  );

  static const aiBackendUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: '',
  );

  static const aiBackendTimeoutSeconds = int.fromEnvironment(
    'AI_BACKEND_TIMEOUT_SECONDS',
    defaultValue: 28,
  );

  static const premiumProductIds = <String>[
    'com.hisle.app.premium.monthly',
    'com.hisle.app.premium.yearly',
    'com.hisle.app.credits.10',
    'com.hisle.app.credits.50',
  ];

  static bool get useAndroidPurchaseSimulation =>
      enableAndroidPurchaseSimulation && Platform.isAndroid;
}
