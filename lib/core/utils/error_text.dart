String toUserFacingError(Object error) {
  final text = error.toString();
  if (text.contains('resource-exhausted') ||
      text.contains('Daily limit reached')) {
    return 'Günlük kullanım limitine ulaştın. Biraz sonra tekrar deneyebilir veya premium seçeneklerine bakabilirsin.';
  }
  if (text.contains('Insufficient credits')) {
    return 'Yeterli kredin yok. Devam etmek için kredi alabilir veya premiuma geçebilirsin.';
  }
  if (text.contains('network') ||
      text.contains('socket') ||
      text.contains('internet')) {
    return 'İnternet bağlantısı gerekir. Bağlantını kontrol edip tekrar dene.';
  }
  if (text.contains('timeout')) {
    return 'İstek zaman aşımına uğradı. Kısa süre sonra tekrar deneyebilirsin.';
  }
  return 'İşlem şu anda tamamlanamadı. Lütfen tekrar dene.';
}

bool isInsufficientCreditsError(Object error) {
  final text = error.toString();
  return text.contains('Insufficient credits') ||
      text.contains('Yeterli kredin yok');
}
