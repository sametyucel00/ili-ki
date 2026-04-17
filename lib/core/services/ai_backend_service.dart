import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iliski_kocu_ai/core/config/env.dart';

class AiBackendService {
  AiBackendService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  bool get isConfigured => Env.aiBackendUrl.trim().isNotEmpty;

  Future<Map<String, dynamic>?> createMessageAnalysis({
    required String message,
    String? context,
    String? relationshipType,
    required bool isPremium,
  }) {
    return _post(
      type: 'message_analysis',
      payload: {
        'message': message,
        'context': context,
        'relationshipType': relationshipType,
        'tier': isPremium ? 'premium' : 'standard',
      },
    );
  }

  Future<Map<String, dynamic>?> createReplyGeneration({
    required String message,
    String? context,
    required String tone,
    required String responseLength,
    required bool emojiPreference,
    required bool isPremium,
  }) {
    return _post(
      type: 'reply_generation',
      payload: {
        'message': message,
        'context': context,
        'tone': tone,
        'responseLength': responseLength,
        'emojiPreference': emojiPreference,
        'tier': isPremium ? 'premium' : 'standard',
      },
    );
  }

  Future<Map<String, dynamic>?> createSituationStrategy({
    required String situation,
    String? relationshipType,
    required bool isPremium,
  }) {
    return _post(
      type: 'situation_strategy',
      payload: {
        'situation': situation,
        'relationshipType': relationshipType,
        'tier': isPremium ? 'premium' : 'standard',
      },
    );
  }

  Future<Map<String, dynamic>?> _post({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final endpoint = Env.aiBackendUrl.trim();
    if (endpoint.isEmpty) {
      return null;
    }

    try {
      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: const {
              'content-type': 'application/json',
              'accept': 'application/json',
            },
            body: jsonEncode({
              'type': type,
              ...payload,
            }),
          )
          .timeout(const Duration(seconds: Env.aiBackendTimeoutSeconds));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return null;
      }
      final result = decoded['result'];
      if (result is Map) {
        return result.cast<String, dynamic>();
      }
      return decoded.cast<String, dynamic>();
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
