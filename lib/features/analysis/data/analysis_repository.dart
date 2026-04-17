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
    try {
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
    } catch (_) {
      return _buildLocalMessageAnalysis(
        message: message,
        context: context,
        relationshipType: relationshipType,
      );
    }
  }

  Future<AnalysisRecord> createReplyGeneration({
    required String message,
    String? context,
    required String tone,
    required String responseLength,
    required bool emojiPreference,
  }) async {
    try {
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
    } catch (_) {
      return _buildLocalReplyGeneration(
        message: message,
        context: context,
        tone: tone,
        responseLength: responseLength,
        emojiPreference: emojiPreference,
      );
    }
  }

  Future<AnalysisRecord> createSituationStrategy({
    required String situation,
    String? relationshipType,
  }) async {
    try {
      final result = await _functions.httpsCallable('createSituationStrategy').call({
        'inputText': situation,
        'relationshipType': relationshipType,
      });
      final record = AnalysisRecord.fromMap(Map<String, dynamic>.from(result.data as Map));
      await _persistCache(record);
      final count = await _cache.incrementCompletedAnalysisCount();
      await _analytics.logEvent('strategy_generated', {'completed_count': count});
      return record;
    } catch (_) {
      return _buildLocalSituationStrategy(
        situation: situation,
        relationshipType: relationshipType,
      );
    }
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
          (snapshot) => snapshot.docs.map((doc) => AnalysisRecord.fromMap(doc.data())).toList(),
        );
  }

  Future<List<AnalysisRecord>> loadCachedHistory() async {
    final items = await _cache.readCachedAnalyses();
    return items.map(AnalysisRecord.fromMap).toList();
  }

  Future<AnalysisRecord?> getAnalysisById(String id) async {
    try {
      final snapshot = await _firestore.collection('analyses').doc(id).get();
      if (snapshot.exists && snapshot.data() != null) {
        return AnalysisRecord.fromMap(snapshot.data()!);
      }
    } catch (_) {
      // Fall back to cached records below.
    }
    final cached = await loadCachedHistory();
    return cached.where((item) => item.id == id).firstOrNull;
  }

  Future<void> toggleFavorite(String id, bool value) async {
    try {
      await _firestore.collection('analyses').doc(id).update({'isFavorite': value});
    } catch (_) {
      final cached = await _cache.readCachedAnalyses();
      final updated = cached
          .map((item) => item['id'] == id ? {...item, 'isFavorite': value} : item)
          .toList();
      await _cache.writeCachedAnalyses(updated);
    }
    await _analytics.logEvent('result_favorited', {'value': value});
  }

  Future<void> deleteAnalysis(String id) async {
    try {
      await _firestore.collection('analyses').doc(id).delete();
    } catch (_) {
      final cached = await _cache.readCachedAnalyses();
      await _cache.writeCachedAnalyses(cached.where((item) => item['id'] != id).toList());
    }
  }

  Future<int> getCompletedAnalysisCount() => _cache.getCompletedAnalysisCount();

  Future<AnalysisRecord> _buildLocalMessageAnalysis({
    required String message,
    String? context,
    String? relationshipType,
  }) async {
    await _consumeLocalCredits(1);
    final now = DateTime.now();
    final summary = message.length > 90
        ? '${message.substring(0, 90)}...'
        : message;
    final record = AnalysisRecord(
      id: 'local_${now.microsecondsSinceEpoch}',
      uid: _uid,
      type: AnalysisType.messageAnalysis,
      inputText: message,
      contextText: context,
      relationshipType: relationshipType,
      tone: null,
      responseLength: null,
      emojiPreference: null,
      aiSummary: 'Mesaj genel olarak temkinli ve yoruma açık görünüyor. Öne çıkan bölüm: $summary',
      aiIntent: 'Belirsiz',
      aiRiskFlags: const [],
      aiSuggestedAction: 'Kısa, net ve sakin bir cevap vermek şu aşamada daha güvenli olabilir.',
      aiReplyOptions: const [
        'Tamam, müsait olduğunda konuşabiliriz.',
        'Anladım, uygun olduğunda yazarsın.',
        'Sorun değil, sonra devam ederiz.',
      ],
      rawModelOutput: const {},
      creditsUsed: 1,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
      neutralityNote: 'Bu sonuç cihaz içi yedek üretim modundan geldiği için yorum daha genel tutuldu.',
      clarityLevel: 'Orta',
      interestLevel: 'Belirsiz',
      avoidNow: const [],
      nextSteps: const [],
      likelyDynamics: const [],
      optionalMessage: null,
    );
    await _persistCache(record);
    final count = await _cache.incrementCompletedAnalysisCount();
    await _analytics.logEvent('analysis_completed', {
      'type': 'message_analysis',
      'completed_count': count,
      'mode': 'local_fallback',
    });
    return record;
  }

  Future<AnalysisRecord> _buildLocalReplyGeneration({
    required String message,
    String? context,
    required String tone,
    required String responseLength,
    required bool emojiPreference,
  }) async {
    await _consumeLocalCredits(1);
    final suffix = emojiPreference ? ' 🙂' : '';
    final options = <String>[
      'Anladım, müsait olduğunda devam ederiz$suffix',
      'Tamam, haberleşiriz$suffix',
      'Olur, sonra konuşalım$suffix',
    ];
    final now = DateTime.now();
    final record = AnalysisRecord(
      id: 'local_${now.microsecondsSinceEpoch}',
      uid: _uid,
      type: AnalysisType.replyGeneration,
      inputText: message,
      contextText: context,
      relationshipType: null,
      tone: tone,
      responseLength: responseLength,
      emojiPreference: emojiPreference,
      aiSummary: 'Cevap seçenekleri hazırlandı.',
      aiIntent: null,
      aiRiskFlags: const [],
      aiSuggestedAction: 'Ton seçimine göre en doğal gelen cevabı seçebilirsin.',
      aiReplyOptions: options,
      rawModelOutput: const {},
      creditsUsed: 1,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
      neutralityNote: null,
      clarityLevel: null,
      interestLevel: null,
      avoidNow: const [],
      nextSteps: const [],
      likelyDynamics: const [],
      optionalMessage: null,
    );
    await _persistCache(record);
    final count = await _cache.incrementCompletedAnalysisCount();
    await _analytics.logEvent('reply_generated', {
      'completed_count': count,
      'mode': 'local_fallback',
    });
    return record;
  }

  Future<AnalysisRecord> _buildLocalSituationStrategy({
    required String situation,
    String? relationshipType,
  }) async {
    await _consumeLocalCredits(2);
    final now = DateTime.now();
    final record = AnalysisRecord(
      id: 'local_${now.microsecondsSinceEpoch}',
      uid: _uid,
      type: AnalysisType.situationStrategy,
      inputText: situation,
      contextText: null,
      relationshipType: relationshipType,
      tone: null,
      responseLength: null,
      emojiPreference: null,
      aiSummary: 'Durumda tempo ve beklenti farkı olabilir.',
      aiIntent: null,
      aiRiskFlags: const [],
      aiSuggestedAction: 'Tek bir net mesaj ve biraz alan tanımak daha sağlıklı olabilir.',
      aiReplyOptions: const [],
      rawModelOutput: const {},
      creditsUsed: 2,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
      neutralityNote: null,
      clarityLevel: null,
      interestLevel: null,
      avoidNow: const ['Arka arkaya baskı kuran mesajlar atmak'],
      nextSteps: const ['Biraz alan tanı', 'Tek bir net mesaj seç', 'Gelen cevaba göre devam et'],
      likelyDynamics: const ['İletişim temposu şu an eşleşmiyor olabilir'],
      optionalMessage: 'Müsait olduğunda konuşabiliriz, acele etmiyorum.',
    );
    await _persistCache(record);
    final count = await _cache.incrementCompletedAnalysisCount();
    await _analytics.logEvent('strategy_generated', {
      'completed_count': count,
      'mode': 'local_fallback',
    });
    return record;
  }

  Future<void> _consumeLocalCredits(int amount) async {
    final current = await _cache.getLocalCreditBalance() ?? 1;
    if (current < amount) {
      throw const AppException('Insufficient credits.', code: 'insufficient_credits');
    }
    await _cache.consumeLocalCredit(fallbackBalance: current, amount: amount);
  }
}
