import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iliski_kocu_ai/core/errors/app_exception.dart';
import 'package:iliski_kocu_ai/core/services/analytics_service.dart';
import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';

class AnalysisRepository {
  AnalysisRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required LocalCacheService cache,
    required AnalyticsService analytics,
  })  : _firestore = firestore,
        _functions = functions,
        _cache = cache,
        _analytics = analytics;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final LocalCacheService _cache;
  final AnalyticsService _analytics;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw const AppException('Aktif kullanıcı bulunamadı.', code: 'missing_user');
    }
    return uid;
  }

  Future<AnalysisRecord> createMessageAnalysis({
    required String message,
    String? context,
    String? relationshipType,
  }) async {
    await _analytics.logEvent('analysis_started', {'type': 'message_analysis'});
    final result = await _functions.httpsCallable('createAnalysis').call({
      'inputText': message,
      'contextText': context,
      'relationshipType': relationshipType,
    });
    final record = AnalysisRecord.fromMap(Map<String, dynamic>.from(result.data as Map));
    await _persistCache(record);
    final count = await _cache.incrementCompletedAnalysisCount();
    await _analytics.logEvent('analysis_completed', {
      'type': 'message_analysis',
      'completed_count': count,
    });
    return record;
  }

  Future<AnalysisRecord> createReplyGeneration({
    required String message,
    String? context,
    required String tone,
    required String responseLength,
    required bool emojiPreference,
  }) async {
    final result = await _functions.httpsCallable('generateReplies').call({
      'inputText': message,
      'contextText': context,
      'tone': tone,
      'responseLength': responseLength,
      'emojiPreference': emojiPreference,
    });
    final record = AnalysisRecord.fromMap(Map<String, dynamic>.from(result.data as Map));
    await _persistCache(record);
    final count = await _cache.incrementCompletedAnalysisCount();
    await _analytics.logEvent('reply_generated', {'completed_count': count});
    return record;
  }

  Future<AnalysisRecord> createSituationStrategy({
    required String situation,
    String? relationshipType,
  }) async {
    final result = await _functions.httpsCallable('createSituationStrategy').call({
      'inputText': situation,
      'relationshipType': relationshipType,
    });
    final record = AnalysisRecord.fromMap(Map<String, dynamic>.from(result.data as Map));
    await _persistCache(record);
    final count = await _cache.incrementCompletedAnalysisCount();
    await _analytics.logEvent('strategy_generated', {'completed_count': count});
    return record;
  }

  Future<void> _persistCache(AnalysisRecord record) async {
    final items = await _cache.readCachedAnalyses();
    final next = [record.toMap(), ...items].take(25).toList();
    await _cache.writeCachedAnalyses(next);
  }

  Stream<List<AnalysisRecord>> watchRecentAnalyses() {
    return _firestore
        .collection('analyses')
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AnalysisRecord.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<List<AnalysisRecord>> loadCachedHistory() async {
    final items = await _cache.readCachedAnalyses();
    return items.map(AnalysisRecord.fromMap).toList();
  }

  Future<AnalysisRecord?> getAnalysisById(String id) async {
    final snapshot = await _firestore.collection('analyses').doc(id).get();
    if (snapshot.exists && snapshot.data() != null) {
      return AnalysisRecord.fromMap(snapshot.data()!);
    }
    final cached = await loadCachedHistory();
    return cached.where((item) => item.id == id).firstOrNull;
  }

  Future<void> toggleFavorite(String id, bool value) async {
    await _firestore.collection('analyses').doc(id).update({'isFavorite': value});
    await _analytics.logEvent('result_favorited', {'value': value});
  }

  Future<void> deleteAnalysis(String id) async {
    await _firestore.collection('analyses').doc(id).delete();
  }

  Future<int> getCompletedAnalysisCount() => _cache.getCompletedAnalysisCount();
}
