import 'dart:math';

import 'package:iliski_kocu_ai/core/errors/app_exception.dart';
import 'package:iliski_kocu_ai/core/services/ai_backend_service.dart';
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
    required AiBackendService aiBackend,
  })  : _cache = cache,
        _analytics = analytics,
        _config = config,
        _aiBackend = aiBackend;

  final LocalCacheService _cache;
  final AnalyticsService _analytics;
  final RemoteConfigService _config;
  final AiBackendService _aiBackend;
  final Uuid _uuid = const Uuid();

  Future<AnalysisRecord> createMessageAnalysis({
    required String message,
    String? context,
    String? relationshipType,
  }) async {
    _requireText(message);
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
    _requireText(message);
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
    _requireText(situation);
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
    final records = <AnalysisRecord>[];
    for (final item in items) {
      try {
        records.add(AnalysisRecord.fromMap(item));
      } catch (_) {
        // Skip malformed old cache entries.
      }
    }
    return records;
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
    await _cache
        .writeCachedAnalyses(cached.where((item) => item['id'] != id).toList());
  }

  Future<void> clearAllAnalyses() async {
    await _cache.writeCachedAnalyses(const []);
  }

  Future<int> getCompletedAnalysisCount() => _cache.getCompletedAnalysisCount();

  Future<AnalysisRecord> _buildLocalMessageAnalysis({
    required String message,
    String? context,
    String? relationshipType,
  }) async {
    await _checkDailyLimit();
    await _consumeLocalCredits(1);

    final isPremium = await _isPremiumActive();
    final remote = await _aiBackend.createMessageAnalysis(
      message: message,
      context: context,
      relationshipType: relationshipType,
      isPremium: isPremium,
    );
    if (remote != null) {
      final now = DateTime.now();
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
        aiSummary: _stringValue(remote['summary'],
            fallback: 'Mesaj dengeli şekilde yorumlandı.'),
        aiIntent: _nullableString(remote['intent']),
        aiRiskFlags: _stringList(remote['riskFlags']),
        aiSuggestedAction: _stringValue(
          remote['recommendedAction'],
          fallback:
              'Kısa, net ve sakin bir cevap vermek daha güvenli olabilir.',
        ),
        aiReplyOptions: _stringList(remote['replyOptions']).take(3).toList(),
        rawModelOutput: remote,
        creditsUsed: 1,
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        neutralityNote: _nullableString(remote['neutralityNote']) ??
            'Bu yorum kesinlik iddiası taşımaz; olası bir okuma sunar.',
        clarityLevel: _nullableString(remote['clarityLevel']),
        interestLevel: _nullableString(remote['interestLevel']),
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
        'mode': 'remote',
      });
      return record;
    }

    final profile = _messageProfile(message, context);
    final now = DateTime.now();
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
      aiSummary: profile.summary,
      aiIntent: profile.intent,
      aiRiskFlags: profile.riskFlags,
      aiSuggestedAction: profile.recommendedAction,
      aiReplyOptions: profile.replyOptions,
      rawModelOutput: const {},
      creditsUsed: 1,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
      neutralityNote:
          'Bu yorum kesinlik iddiası taşımaz; yalnızca mesajın tonu, netliği ve bağlamına göre olası bir okuma sunar.',
      clarityLevel: profile.clarityLevel,
      interestLevel: profile.interestLevel,
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

    final isPremium = await _isPremiumActive();
    final remote = await _aiBackend.createReplyGeneration(
      message: message,
      context: context,
      tone: tone,
      responseLength: responseLength,
      emojiPreference: emojiPreference,
      isPremium: isPremium,
    );
    if (remote != null) {
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
        aiSummary:
            '$tone tonda $responseLength uzunlukta cevap seçenekleri hazırlandı.',
        aiIntent: null,
        aiRiskFlags: const [],
        aiSuggestedAction: _stringValue(
          remote['recommendedAction'],
          fallback:
              'En doğal gelen cevabı seçip kendi konuşma tarzına göre küçükçe düzenleyebilirsin.',
        ),
        aiReplyOptions: _stringList(remote['replyOptions']).take(3).toList(),
        rawModelOutput: remote,
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
        'mode': 'remote',
      });
      return record;
    }

    final options =
        _replyOptions(message, tone, responseLength, emojiPreference);
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
      aiSummary:
          '$tone tonda $responseLength uzunlukta 3 cevap seçeneği hazırlandı.',
      aiIntent: null,
      aiRiskFlags: const [],
      aiSuggestedAction:
          'En doğal gelen cevabı seçip gerekirse kendi konuşma tarzına göre küçükçe yumuşatabilirsin.',
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

    final isPremium = await _isPremiumActive();
    final remote = await _aiBackend.createSituationStrategy(
      situation: situation,
      relationshipType: relationshipType,
      isPremium: isPremium,
    );
    if (remote != null) {
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
        aiSummary: _stringValue(remote['summary'],
            fallback: 'Durum dengeli şekilde özetlendi.'),
        aiIntent: null,
        aiRiskFlags: _stringList(remote['riskFlags']),
        aiSuggestedAction: _stringValue(
          remote['recommendedAction'],
          fallback: 'Önce tek bir net hedef belirleyip sakin bir adım seç.',
        ),
        aiReplyOptions: const [],
        rawModelOutput: remote,
        creditsUsed: 2,
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        neutralityNote: null,
        clarityLevel: null,
        interestLevel: null,
        avoidNow: _stringList(remote['avoidNow']),
        nextSteps: _stringList(remote['nextSteps']),
        likelyDynamics: _stringList(remote['likelyDynamics']),
        optionalMessage: _nullableString(remote['optionalMessage']),
      );
      await _persistCache(record);
      final count = await _cache.incrementCompletedAnalysisCount();
      await _analytics.logEvent('strategy_generated', {
        'completed_count': count,
        'mode': 'remote',
      });
      return record;
    }

    final lower = situation.toLowerCase();
    final isCold = lower.contains('soğuk') ||
        lower.contains('geç') ||
        lower.contains('cevap verm');
    final isConflict = lower.contains('tartış') ||
        lower.contains('kavga') ||
        lower.contains('kırıld');
    final summary = isConflict
        ? 'Durumda kırgınlık veya savunmaya geçme ihtimali öne çıkıyor.'
        : isCold
            ? 'Durumda iletişim temposu ve beklenti farkı belirgin görünüyor.'
            : 'Durumda netlik ihtiyacı var; acele karar yerine sakin bir çerçeve daha iyi olabilir.';
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
      aiSummary: summary,
      aiIntent: null,
      aiRiskFlags: isConflict
          ? const ['Duygusal yoğunluk yüksekse mesajı büyütme riski olabilir.']
          : const [],
      aiSuggestedAction:
          'Önce tek bir net hedef belirle: açıklık mı istiyorsun, sakinleşmek mi, yoksa konuşmayı kapatmak mı?',
      aiReplyOptions: const [],
      rawModelOutput: const {},
      creditsUsed: 2,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
      neutralityNote: null,
      clarityLevel: null,
      interestLevel: null,
      avoidNow: const [
        'Arka arkaya baskı kuran mesajlar atmak',
        'Karşı tarafın niyetinden kesin eminmiş gibi davranmak',
      ],
      nextSteps: const [
        'Duygunu kısa ve suçlamadan ifade et',
        'Yanıt için makul bir alan bırak',
        'Gelen tepkiye göre konuşmayı sürdür veya sınır koy',
      ],
      likelyDynamics: isCold
          ? const [
              'İletişim temposu şu an eşleşmiyor olabilir',
              'Karşı taraf net olmayan bir alanda kalıyor olabilir'
            ]
          : const ['Beklenti ve ifade biçimi farklılaşmış olabilir'],
      optionalMessage:
          'Bunu büyütmek istemiyorum ama netleşmek iyi gelir. Uygun olduğunda sakin sakin konuşalım.',
    );
    await _persistCache(record);
    final count = await _cache.incrementCompletedAnalysisCount();
    await _analytics.logEvent('strategy_generated', {
      'completed_count': count,
      'mode': 'local',
    });
    return record;
  }

  _MessageProfile _messageProfile(String message, String? context) {
    final lower = '$message ${context ?? ''}'.toLowerCase();
    final short = message.trim().length < 18;
    final hasDelay = lower.contains('sonra') ||
        lower.contains('müsait') ||
        lower.contains('yoğun');
    final hasWarmth = lower.contains('özled') ||
        lower.contains('merak') ||
        lower.contains('görüş') ||
        lower.contains('❤️');
    final hasDistance = lower.contains('bilmiyorum') ||
        lower.contains('kararsız') ||
        lower.contains('istemiyorum');
    final hasApology = lower.contains('kusura') ||
        lower.contains('özür') ||
        lower.contains('haklısın');

    if (hasWarmth) {
      return const _MessageProfile(
        summary:
            'Mesajda sıcaklık ve iletişimi sürdürme isteği öne çıkıyor. Yine de tek mesajdan kesin niyet çıkarmamak daha sağlıklı.',
        intent: 'Yakınlaşma veya konuşmayı sürdürme',
        interestLevel: 'Orta-yüksek',
        clarityLevel: 'Orta',
        riskFlags: [],
        recommendedAction:
            'Cevabı sıcak ama abartısız tut. Karşı tarafa alan bırakan doğal bir devam cümlesi iyi çalışır.',
        replyOptions: [
          'Ben de konuşmayı isterim, uygun olduğunda haberleşelim.',
          'Güzel söyledin, ben de bunu sakin sakin konuşmak isterim.',
          'Olur, uygun bir zamanda devam edelim.',
        ],
      );
    }

    if (hasDistance) {
      return const _MessageProfile(
        summary:
            'Mesajda mesafe veya kararsızlık sinyali var. Bu kesin bir kopuş anlamına gelmeyebilir ama baskı kurmamak önemli.',
        intent: 'Alan isteme veya netleşememe',
        interestLevel: 'Belirsiz',
        clarityLevel: 'Orta',
        riskFlags: ['Üstelemek konuşmayı gerebilir.'],
        recommendedAction:
            'Kısa, saygılı ve alan tanıyan bir cevap ver. Netlik istiyorsan bunu tek cümleyle sor.',
        replyOptions: [
          'Anlıyorum, düşünmek istersen alan bırakırım.',
          'Netleşmek istersen sakin şekilde konuşabiliriz.',
          'Tamam, seni zorlamak istemem. Uygun olduğunda konuşuruz.',
        ],
      );
    }

    if (hasApology) {
      return const _MessageProfile(
        summary:
            'Mesajda yumuşama veya sorumluluk alma tonu var. Bu, konuşmayı daha sakin bir zemine çekmek için iyi bir fırsat olabilir.',
        intent: 'Onarma veya gerginliği azaltma',
        interestLevel: 'Orta',
        clarityLevel: 'Yüksek',
        riskFlags: [],
        recommendedAction:
            'Cevabında hem sınırını hem de konuşmaya açık olduğunu dengeli şekilde göster.',
        replyOptions: [
          'Bunu söylemen iyi geldi. Ben de sakin konuşmak isterim.',
          'Anladım, ben de konuyu büyütmeden netleşmek isterim.',
          'Teşekkür ederim, uygun olduğunda konuşalım.',
        ],
      );
    }

    if (hasDelay || short) {
      return const _MessageProfile(
        summary:
            'Mesaj kısa ve yoruma açık. Net bir olumsuzluk görünmüyor ama ilgi seviyesi de tek başına kesinleşmiyor.',
        intent: 'Belirsiz veya nötr iletişim',
        interestLevel: 'Belirsiz',
        clarityLevel: 'Düşük-orta',
        riskFlags: [],
        recommendedAction:
            'Acele anlam yükleme. Kısa, sakin ve konuşmayı açık bırakan bir cevap en güvenli seçenek.',
        replyOptions: [
          'Tamam, müsait olduğunda konuşuruz.',
          'Anladım, uygun olunca haberleşiriz.',
          'Sorun değil, sonra devam ederiz.',
        ],
      );
    }

    return const _MessageProfile(
      summary:
          'Mesajda belirgin bir yön var ama niyet tamamen net değil. Sakin ve açık bir cevap belirsizliği azaltabilir.',
      intent: 'Konuşmayı sürdürme veya netleşme',
      interestLevel: 'Orta',
      clarityLevel: 'Orta',
      riskFlags: [],
      recommendedAction:
          'Tek bir konuya odaklanan, kısa ve dengeli bir cevap ver. Fazla açıklama yapmak yerine netlik iste.',
      replyOptions: [
        'Anladım, bunu sakin şekilde konuşabiliriz.',
        'Benim için netleşmesi iyi olur. Uygun olduğunda konuşalım.',
        'Tamam, ne demek istediğini daha net duymak isterim.',
      ],
    );
  }

  List<String> _replyOptions(String message, String tone, String responseLength,
      bool emojiPreference) {
    final emoji = emojiPreference ? ' 🙂' : '';
    final isLong = responseLength == 'Uzun';
    final isShort = responseLength == 'Kısa';
    final seed = message.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final variants = <String, List<String>>{
      'Tatlı': [
        'Anladım, bunu güzelce konuşabiliriz$emoji',
        'Tamam, uygun olduğunda sakin sakin devam edelim$emoji',
        'Ben buradayım, acele etmeden konuşuruz$emoji',
      ],
      'Havalı': [
        'Tamamdır, uygun olduğunda haberleşiriz$emoji',
        'Sorun yok, akışına bırakalım$emoji',
        'Olur, müsait olduğunda devam ederiz$emoji',
      ],
      'Net': [
        'Anladım. Benim için netleşmesi iyi olur, uygun olduğunda konuşalım.',
        'Tamam, bunu uzatmadan açıkça konuşmak isterim.',
        'Ben netlikten yanayım. Uygun olduğunda bunu konuşalım.',
      ],
      'Mesafeli': [
        'Anladım, şu an biraz alan bırakmak daha iyi.',
        'Tamam, uygun olunca konuşuruz.',
        'Sorun değil, ben de biraz sakin kalmayı tercih ederim.',
      ],
      'Flörtöz': [
        'Tamam, ama bu konuşmanın devamını merak ettim$emoji',
        'Olur, uygun olduğunda devam edelim; bence güzel bir yere gidebilir$emoji',
        'Peki, bunu sonra biraz daha tatlı konuşalım$emoji',
      ],
      'Kibar': [
        'Anladım, teşekkür ederim. Uygun olduğunda konuşabiliriz.',
        'Tamam, bunu sakin bir zamanda konuşmak iyi olur.',
        'Anlıyorum. Senin için de uygunsa sonra devam edelim.',
      ],
      'Sert ama saygılı': [
        'Anladım ama bu konuda daha net olmamız gerekiyor.',
        'Tamam, fakat belirsizlik uzarsa benim için sağlıklı olmaz.',
        'Bunu saygıyla söylüyorum: netlik benim için önemli.',
      ],
      'Kapanış odaklı': [
        'Anladım. Bu konuşmayı burada sakin şekilde kapatmak benim için daha iyi.',
        'Tamam, ben bu noktada uzatmamayı tercih ediyorum.',
        'Teşekkür ederim, ben artık bu konuyu kapatmak istiyorum.',
      ],
    };
    final selected = [...(variants[tone] ?? variants['Kibar']!)];
    selected.shuffle(Random(seed));
    if (isLong) {
      return selected
          .take(3)
          .map((item) =>
              '$item Benim niyetim konuyu büyütmek değil; sadece daha sakin ve net ilerlemek.')
          .toList();
    }
    if (isShort) {
      return selected
          .take(3)
          .map((item) => item.split('.').first.trim())
          .toList();
    }
    return selected.take(3).toList();
  }

  Future<void> _consumeLocalCredits(int amount) async {
    final current = await _cache.getLocalCreditBalance() ?? 5;
    if (current < amount) {
      throw const AppException('Insufficient credits.',
          code: 'insufficient_credits');
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
    return (planType == 'premium' || status == 'active') && expiry != null;
  }

  String _stringValue(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  String? _nullableString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Object>()
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _requireText(String value) {
    if (value.trim().isEmpty) {
      throw const AppException('Lütfen önce metin gir.', code: 'empty_input');
    }
  }
}

class _MessageProfile {
  const _MessageProfile({
    required this.summary,
    required this.intent,
    required this.interestLevel,
    required this.clarityLevel,
    required this.riskFlags,
    required this.recommendedAction,
    required this.replyOptions,
  });

  final String summary;
  final String intent;
  final String interestLevel;
  final String clarityLevel;
  final List<String> riskFlags;
  final String recommendedAction;
  final List<String> replyOptions;
}
