class AppLinks {
  static const legalHubBaseUrl = String.fromEnvironment(
    'LEGAL_HUB_BASE_URL',
    defaultValue: 'https://iliski-kocu-ai.netlify.app',
  );

  static String get privacyUrl => '$legalHubBaseUrl/#privacy';
  static String get termsUrl => '$legalHubBaseUrl/#terms';
  static String get helpUrl => '$legalHubBaseUrl/#help';
  static String get purchasesUrl => '$legalHubBaseUrl/#iap';
  static String get deletionUrl => '$legalHubBaseUrl/#data-deletion';
}
