class Env {
  static const functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'europe-west1',
  );

  static const premiumProductIds = <String>[
    'premium_monthly',
    'premium_yearly',
    'credits_10',
    'credits_50',
  ];
}
