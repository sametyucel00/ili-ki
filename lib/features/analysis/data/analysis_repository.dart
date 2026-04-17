import 'package:iliski_kocu_ai/core/errors/app_exception.dart';
import 'package:iliski_kocu_ai/core/services/analytics_service.dart';
import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/core/services/remote_config_service.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';
import 'package:uuid/uuid.dart';

class AnalysisRepository {
  AnalysisRepository({
    required LocalCacheService cache,
    required AnalyticsService analytics,
    required RemoteConfigService config,
  })  : _cache = cache,
        _analytics = analytics,
        _config = config;

  final LocalCacheService _cache;
  final AnalyticsService _analytics;
  final RemoteConfigService _config;
  final Uuid _uuid = const Uuid();

  Future<AnalysisRecord> createMessageAnalysis({
    required String message,
    String? context,
    String? relationshipType,
  }) async {
    await _analytics.logEvent('analysis_started', {'type': 'message_analysis'});
    return _buildLocalMessageAnalysis(
      message: message,
      context: context,
      relationshipType: relationshipType,
    );
  }

  Future<AnalysisRecord> createReplyGeneration({
    required String message,
    String? context,
    required String tone,
    required String responseLength,
    required bool emojiPreference,
  }) async {
    return _buildLocalReplyGeneration(
      message: message,
      context: context,
      tone: tone,
      responseLength: responseLength,
      emojiPreference: emojiPreference,
    );
  }

  Future<AnalysisRecord> createSituationStrategy({
    required String situation,
    String? relationshipType,
  }) async {
    return _buildLocalSituationStrategy(
      situation: situation,
      relationshipType: relationshipType,
    );
  }

  Future<void> _persistCache(AnalysisRecord record) async {
    final items = await _cache.readCachedAnalyses();
    final next = [record.toMap(), ...items].take(50).toList();
    await _cache.writeCachedAnalyses(next);
  }

  Future<List<AnalysisRecord>> loadCachedHistory() async {
    final items = await _cache.readCachedAnalyses();
    return items.map(AnalysisRecord.fromMap).toList();
  }

  Future<AnalysisRecord?> getAnalysisById(String id) async {
    final cached = await loadCachedHistory();
    try {
      return cached.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleFavorite(String id, bool value) async {
    final cached = await _cache.readCachedAnalyses();
    final updated = cached
        .map((item) => item['id'] == id ? {...item, 'isFavorite': value} : item)
        .toList();
    await _cache.writeCachedAnalyses(updated);
    await _analytics.logEvent('result_favorited', {'value': value});
  }

  Future<void> deleteAnalysis(String id) async {
    final cached = await _cache.readCachedAnalyses();
    await _cache.writeCachedAnalyses(cached.where((item) => item['id'] != id).toList());
  }

  Future<int> getCompletedAnalysisCount() => _cache.getCompletedAnalysisCount();

  Future<AnalysisRecord> _buildLocalMessageAnalysis({
    required String message,
    String? context,
    String? relationshipType,
  }) async {
    await _checkDailyLimit();
    await _consumeLocalCredits(1);

    final now = DateTime.now();
    final summary = message.length > 90 ? '${message.substring(0, 90)}...' : message;
    final record = AnalysisRecord(
      id: _uuid.v4(),
      uid: 'local_user',
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
      neutralityNote: 'Bu sonuç cihaz içi üretim modundan geldiği için yorum daha genel tutuldu.',
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
      'mode': 'local',
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
    await _checkDailyLimit();
    await _consumeLocalCredits(1);

    final suffix = emojiPreference ? ' 🙂' : '';
    final options = <String>[
      'Anladım, müsait olduğunda devam ederiz$suffix',
      'Tamam, haberleşiriz$suffix',
      'Olur, sonra konuşalım$suffix',
    ];
    final now = DateTime.now();
    final record = AnalysisRecord(
      id: _uuid.v4(),
      uid: 'local_user',
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
      'mode': 'local',
    });
    return record;
  }

  Future<AnalysisRecord> _buildLocalSituationStrategy({
    required String situation,
    String? relationshipType,
  }) async {
    await _checkDailyLimit();
    await _consumeLocalCredits(2);

    final now = DateTime.now();
    final record = AnalysisRecord(
      id: _uuid.v4(),
      uid: 'local_user',
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
      'mode': 'local',
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

  Future<void> _checkDailyLimit() async {
    final config = await _config.initialize();
    final isPremium = await _isPremiumActive();
    final limit = isPremium ? config.linkedDailyLimit : config.guestDailyLimit;
    final currentUsage = await _cache.getTodayUsageCount();
    if (currentUsage >= limit) {
      throw const AppException('Daily limit reached.', code: 'daily_limit');
    }
    await _cache.incrementTodayUsageCount();
  }

  Future<bool> _isPremiumActive() async {
    final expiry = await _cache.getLocalPremiumExpiry();
    if (expiry != null && expiry.isBefore(DateTime.now())) {
      await _cache.clearLocalPremiumState();
      return false;
    }
    final planType = await _cache.getLocalPlanType();
    final status = await _cache.getLocalSubscriptionStatus();
    return planType == 'premium' || status == 'active';
  }
}
