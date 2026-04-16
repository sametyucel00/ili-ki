import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iliski_kocu_ai/core/services/analytics_service.dart';

class NotificationService {
  NotificationService(this._messaging, this._analytics);

  final FirebaseMessaging _messaging;
  final AnalyticsService _analytics;

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token != null) {
      await _analytics.logEvent('notification_token_received');
    }
  }
}
