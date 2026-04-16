class Env {
  static const functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'europe-west1',
  );

  static const premiumProductIds = <String>[
    'com.hisle.app.premium.monthly',
    'com.hisle.app.premium.yearly',
    'com.hisle.app.credits.10',
    'com.hisle.app.credits.50',
  ];
}
