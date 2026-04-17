import 'package:iliski_kocu_ai/core/services/analytics_service.dart';

class NotificationService {
  NotificationService(this._analytics);

  final AnalyticsService _analytics;

  Future<void> initialize() async {
    await _analytics.logEvent('notification_service_initialized');
  }
}
