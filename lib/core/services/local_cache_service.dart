import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const _historyKey = 'cached_analyses';
  static const _onboardingKey = 'onboarding_seen';
  static const _completedCountKey = 'completed_analysis_count';

  Future<List<Map<String, dynamic>>> readCachedAnalyses() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_historyKey) ?? <String>[];
    return values.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  Future<void> writeCachedAnalyses(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, items.map(jsonEncode).toList());
  }

  Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<int> getCompletedAnalysisCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_completedCountKey) ?? 0;
  }

  Future<int> incrementCompletedAnalysisCount() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_completedCountKey) ?? 0) + 1;
    await prefs.setInt(_completedCountKey, next);
    return next;
  }
}
