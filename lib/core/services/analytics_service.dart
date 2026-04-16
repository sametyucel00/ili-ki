import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  const AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logEvent(String name, [Map<String, Object?> params = const {}]) {
    final safe = <String, Object>{};
    for (final entry in params.entries) {
      final value = entry.value;
      if (value != null &&
          (value is String || value is int || value is double || value is bool)) {
        safe[entry.key] = value;
      }
    }
    return _analytics.logEvent(name: name, parameters: safe);
  }
}
