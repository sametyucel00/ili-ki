require('dotenv').config();

const cors = require('cors');
const express = require('express');

const app = express();
const port = Number(process.env.PORT || 3000);
const provider = (process.env.AI_PROVIDER || 'openai').toLowerCase();
const model =
  provider === 'groq'
    ? process.env.GROQ_MODEL || 'llama-3.1-8b-instant'
    : process.env.OPENAI_MODEL || 'gpt-4o-mini';
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '*')
  .split(',')
  .map((item) => item.trim())
  .filter(Boolean);
const rateLimitWindowMs = Number(process.env.RATE_LIMIT_WINDOW_MS || 60_000);
const rateLimitMax = Number(process.env.RATE_LIMIT_MAX || 30);
const rateBuckets = new Map();

app.disable('x-powered-by');
app.use(express.json({ limit: '24kb' }));
app.use(
  cors({
    origin(origin, callback) {
      if (allowedOrigins.includes('*') || !origin || allowedOrigins.includes(origin)) {
        callback(null, true);
        return;
      }
      callback(new Error('origin_not_allowed'));
    },
  }),
);

app.get('/health', (_, res) => {
  res.json({
    ok: true,
    service: 'hisle-ai-server',
    provider,
    model,
  });
});

app.post('/ai', async (req, res) => {
  const providerError = validateProviderConfig();
  if (providerError) {
    res.status(500).json({ error: providerError });
    return;
  }

  if (!allowRequest(req)) {
    res.status(429).json({ error: 'rate_limited' });
    return;
  }

  const type = String(req.body?.type || '');
  if (!['message_analysis', 'reply_generation', 'situation_strategy'].includes(type)) {
    res.status(400).json({ error: 'invalid_type' });
    return;
  }

  const userText = type === 'situation_strategy' ? req.body.situation : req.body.message;
  if (!isUsefulText(userText)) {
    res.status(400).json({ error: 'empty_input' });
    return;
  }

  try {
    const result = await callAiProvider(type, req.body);
    res.json({ result });
  } catch (error) {
    console.error('ai_request_failed', {
      provider,
      type,
      message: error instanceof Error ? error.message : String(error),
    });
    res.status(502).json({ error: 'ai_unavailable' });
  }
});

app.use((_, res) => {
  res.status(404).json({ error: 'not_found' });
});

app.listen(port, () => {
  console.log(`Hisle AI server listening on port ${port} using ${provider}/${model}`);
});

function validateProviderConfig() {
  if (provider === 'groq') {
    return process.env.GROQ_API_KEY ? null : 'groq_key_missing';
  }
  if (provider === 'openai') {
    return process.env.OPENAI_API_KEY ? null : 'openai_key_missing';
  }
  return 'unsupported_ai_provider';
}

function providerConfig() {
  if (provider === 'groq') {
    return {
      url: 'https://api.groq.com/openai/v1/chat/completions',
      apiKey: process.env.GROQ_API_KEY,
      errorPrefix: 'groq_http',
    };
  }

  return {
    url: 'https://api.openai.com/v1/chat/completions',
    apiKey: process.env.OPENAI_API_KEY,
    errorPrefix: 'openai_http',
  };
}

function allowRequest(req) {
  const forwarded = String(req.headers['x-forwarded-for'] || '');
  const ip = forwarded.split(',')[0].trim() || req.socket.remoteAddress || 'unknown';
  const now = Date.now();
  const current = rateBuckets.get(ip);

  if (!current || now - current.startedAt > rateLimitWindowMs) {
    rateBuckets.set(ip, { startedAt: now, count: 1 });
    return true;
  }

  current.count += 1;
  return current.count <= rateLimitMax;
}

function isUsefulText(value) {
  return typeof value === 'string' && value.trim().length >= 2 && value.trim().length <= 6000;
}

async function callAiProvider(type, input) {
  const config = providerConfig();
  const response = await fetch(config.url, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${config.apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model,
      temperature: 0.3,
      max_tokens: input.tier === 'premium' ? 950 : 700,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: systemPrompt(),
        },
        {
          role: 'user',
          content: userPrompt(type, input),
        },
      ],
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`${config.errorPrefix}_${response.status}: ${text.slice(0, 300)}`);
  }

  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('empty_model_output');
  }

  const parsed = JSON.parse(content);
  return normalize(type, parsed, input);
}

function systemPrompt() {
  return [
    'Sen Hisle uygulamasının Türkçe ilişki iletişimi asistanısın.',
    'Çıktıların sakin, doğal, gerçekçi ve mobil ekranda okunabilir olmalı.',
    'Terapi, tanı, profesyonel danışmanlık veya kesin yargı sunma.',
    'Karşı tarafın iç dünyası hakkında kesin konuşma; olasılık dili kullan.',
    'Manipülasyon, baskı, takip, taciz, intikam, kıskandırma veya bağımlılık önerme.',
    'Gereksiz dramatik, yapay veya sosyal medya klişesi gibi yazma.',
    'Reply generation için message alanı her zaman karşı taraftan gelen metindir.',
    'replyOptions her zaman uygulama kullanıcısının göndereceği mesajlar olmalı.',
    'Karşı tarafın cümlesini sahiplenme, aynalamaya çalışma, mesajı tekrar etme.',
    'recommendedAction her zaman kullanıcıya yönelik kısa strateji cümlesi olmalı; mesaj metni gibi görünmemeli.',
    'Sadece geçerli JSON döndür.',
  ].join('\n');
}

function userPrompt(type, input) {
  if (type === 'message_analysis') {
    return JSON.stringify({
      task: 'Gelen mesajı ilişki iletişimi açısından yorumla.',
      rules: [
        'Kesin niyet atfetme.',
        'Kısa, sakin ve somut yaz.',
        'Belirsizlik varsa bunu açıkça belirt.',
        'Üç doğal cevap önerisi ver.',
      ],
      outputShape: {
        summary: 'string',
        intent: 'string',
        interestLevel: 'string',
        clarityLevel: 'string',
        riskFlags: ['string'],
        neutralityNote: 'string',
        recommendedAction: 'string',
        replyOptions: ['string', 'string', 'string'],
      },
      message: clean(input.message),
      context: clean(input.context),
      relationshipType: clean(input.relationshipType),
      tier: clean(input.tier),
    });
  }

  if (type === 'reply_generation') {
    return JSON.stringify({
      task: 'Karşı taraftan gelen mesaja, uygulama kullanıcısının gönderebileceği doğal Türkçe cevaplar üret.',
      rules: [
        'Mesajı tekrarlama.',
        'Karşı tarafın ağzından yazma.',
        'Soru sormayı abartma; özellikle kısa cevapta baskı kurma.',
        'Cevaplar tek başına gönderilebilir, doğal ve günlük Türkçe olsun.',
        'Soğuk, kaba veya pasif agresif tınlayan kısa kalıplardan kaçın.',
      ],
      outputShape: {
        recommendedAction: 'string',
        replyOptions: ['string', 'string', 'string'],
      },
      message: clean(input.message),
      context: clean(input.context),
      tone: clean(input.tone),
      responseLength: clean(input.responseLength),
      emojiPreference: Boolean(input.emojiPreference),
      tier: clean(input.tier),
    });
  }

  return JSON.stringify({
    task: 'Anlatılan ilişki iletişimi durumuna sakin, pratik bir strateji öner.',
    rules: [
      'Belirsizlik varsa açıkça söyle.',
      'Tehlike yoksa kırmızı bayrak abartma.',
      'Üç uygulanabilir sonraki adım ver.',
      'İstenirse kısa bir örnek mesaj öner.',
    ],
    outputShape: {
      summary: 'string',
      likelyDynamics: ['string'],
      riskFlags: ['string'],
      avoidNow: ['string'],
      nextSteps: ['string', 'string', 'string'],
      optionalMessage: 'string',
      recommendedAction: 'string',
    },
    situation: clean(input.situation),
    relationshipType: clean(input.relationshipType),
    tier: clean(input.tier),
  });
}

function clean(value) {
  if (typeof value !== 'string') {
    return '';
  }
  return value.trim().slice(0, 6000);
}

function normalize(type, parsed, input) {
  const signals = detectSignals(type === 'situation_strategy' ? input.situation : input.message, input.context);

  if (type === 'message_analysis') {
    return normalizeMessageAnalysis(parsed, input, signals);
  }

  if (type === 'reply_generation') {
    return normalizeReplyGeneration(parsed, input, signals);
  }

  return normalizeSituationStrategy(parsed, input, signals);
}

function normalizeMessageAnalysis(parsed, input, signals) {
  const replyOptions = ensureReplyOptions(parsed.replyOptions, input, signals);
  const riskFlags = sanitizeList(parsed.riskFlags).filter((item) => !looksOverstatedRisk(item)).slice(0, 3);

  return {
    summary: sanitizeSentence(
      parsed.summary,
      buildSummary(signals, input.relationshipType),
    ),
    intent: sanitizeSentence(parsed.intent, buildIntent(signals)),
    interestLevel: sanitizeLabel(parsed.interestLevel, buildInterestLevel(signals)),
    clarityLevel: sanitizeLabel(parsed.clarityLevel, buildClarityLevel(signals)),
    riskFlags,
    neutralityNote: sanitizeSentence(
      parsed.neutralityNote,
      'Bu yorum kesinlik iddiası taşımaz; yalnızca mesajın tonu ve bağlamına göre olası bir okuma sunar.',
    ),
    recommendedAction: normalizeStrategyText(
      parsed.recommendedAction,
      buildRecommendedAction(signals),
    ),
    replyOptions,
  };
}

function normalizeReplyGeneration(parsed, input, signals) {
  return {
    recommendedAction: normalizeStrategyText(
      parsed.recommendedAction,
      buildReplyAction(signals, input.tone),
    ),
    replyOptions: ensureReplyOptions(parsed.replyOptions, input, signals),
  };
}

function normalizeSituationStrategy(parsed, input, signals) {
  const nextSteps = sanitizeList(parsed.nextSteps).filter(isUsefulStrategyLine).slice(0, 3);
  const avoidNow = sanitizeList(parsed.avoidNow).filter(isUsefulStrategyLine).slice(0, 3);
  const likelyDynamics = sanitizeList(parsed.likelyDynamics).filter(isUsefulStrategyLine).slice(0, 3);

  return {
    summary: sanitizeSentence(
      parsed.summary,
      buildSituationSummary(signals),
    ),
    likelyDynamics: likelyDynamics.length ? likelyDynamics : buildLikelyDynamics(signals),
    riskFlags: sanitizeList(parsed.riskFlags).filter((item) => !looksOverstatedRisk(item)).slice(0, 3),
    avoidNow: avoidNow.length ? avoidNow : buildAvoidNow(signals),
    nextSteps: nextSteps.length ? nextSteps : buildNextSteps(signals),
    optionalMessage: sanitizeOptionalMessage(parsed.optionalMessage, signals),
    recommendedAction: normalizeStrategyText(
      parsed.recommendedAction,
      buildSituationAction(signals),
    ),
  };
}

function stringOr(value, fallback) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function sanitizeSentence(value, fallback) {
  const raw = stringOr(value, fallback)
    .replace(/\s+/g, ' ')
    .replace(/\.\./g, '.')
    .trim();
  return raw || fallback;
}

function sanitizeLabel(value, fallback) {
  const raw = sanitizeSentence(value, fallback);
  if (raw.length > 24) {
    return fallback;
  }
  return raw;
}

function sanitizeList(value) {
  return Array.isArray(value)
    ? value
        .map((item) => String(item).replace(/\s+/g, ' ').trim())
        .filter(Boolean)
    : [];
}

function normalizeStrategyText(value, fallback) {
  const raw = sanitizeSentence(value, fallback);
  const lower = raw.toLocaleLowerCase('tr');
  if (
    looksLikeMessageText(raw) ||
    raw.includes('?') ||
    lower.includes('bana haber ver') ||
    lower.includes('istersen konuşabiliriz') ||
    lower.includes('uygun olduğunda konuşuruz') ||
    lower.includes('müsait hissettiğinde yazarsın')
  ) {
    return fallback;
  }
  return raw;
}

function sanitizeOptionalMessage(value, signals) {
  const raw = stringOr(value, '');
  if (!raw) {
    return buildOptionalSituationMessage(signals);
  }
  const cleaned = raw.replace(/\s+/g, ' ').trim();
  if (!isGoodReplyOption(cleaned, signals)) {
    return buildOptionalSituationMessage(signals);
  }
  return cleaned;
}

function ensureReplyOptions(value, input, signals) {
  const options = sanitizeList(value).filter((item) => isGoodReplyOption(item, signals));
  const fallback = buildReplySet(input, signals);
  const merged = [...options, ...fallback].filter(uniqueByNormalizedText);

  if (options.length < 2) {
    return fallback.slice(0, 3);
  }

  return merged.slice(0, 3);
}

function isGoodReplyOption(text, signals) {
  const trimmed = text.trim();
  if (trimmed.length < 18 || trimmed.length > 220) {
    return false;
  }

  return (
    !looksMirroredOrSelfReferential(trimmed) &&
    !looksLikeMessageText(trimmed) &&
    !looksTooCold(trimmed) &&
    !looksPushy(trimmed, signals) &&
    !trimmed.includes('?')
  );
}

function looksMirroredOrSelfReferential(text) {
  const lower = text.toLocaleLowerCase('tr').replace(/[.!?]/g, ' ');
  return (
    lower.includes('konuşmak istemiyorum') ||
    lower.includes('yalnız kalmak istiyorum') ||
    lower.includes('gerçekten konuşmak istemiyorum') ||
    lower.includes('çok yoruldum') ||
    lower.includes('umarım yarın daha iyi hissederim') ||
    lower.includes('seni düşünüyorum') ||
    lower.includes('müsait olunca ben yazarım') ||
    lower.includes('bugün biraz yoğunum')
  );
}

function looksLikeMessageText(text) {
  const lower = text.toLocaleLowerCase('tr');
  return (
    lower.includes('görüşürüz') ||
    lower.includes('yazarsın') ||
    lower.includes('haber ver') ||
    lower.includes('istersen konuşabiliriz')
  );
}

function looksTooCold(text) {
  const lower = text.toLocaleLowerCase('tr').replace(/\s+/g, ' ').trim();
  return (
    lower === 'anlaşıldı.' ||
    lower === 'anlaşıldı, görüşürüz.' ||
    lower === 'tamam, görüşürüz.' ||
    lower === 'iyi günler.' ||
    lower === 'yarın görüşürüz, iyi günler.'
  );
}

function looksPushy(text, signals) {
  const lower = text.toLocaleLowerCase('tr');
  if (signals?.needsSpace) {
    return (
      lower.includes('ne zaman') ||
      lower.includes('neden') ||
      lower.includes('ama') ||
      lower.includes('hemen')
    );
  }
  return lower.includes('hemen');
}

function looksOverstatedRisk(text) {
  const lower = text.toLocaleLowerCase('tr');
  return (
    lower.includes('kesin') ||
    lower.includes('manipüle') ||
    lower.includes('toksik') ||
    lower.includes('narsist')
  );
}

function isUsefulStrategyLine(text) {
  return text.trim().length >= 10 && text.trim().length <= 180;
}

function detectSignals(message, context) {
  const joined = `${clean(message)} ${clean(context)}`.toLocaleLowerCase('tr');

  return {
    needsSpace:
      includesAny(joined, ['yalnız kal', 'konuşmak istem', 'kafam dolu', 'biraz alan', 'yalnız olmak']) ||
      includesAny(joined, ['yoğunum', 'müsait olunca', 'sonra yazarım']),
    delay: includesAny(joined, ['yoğunum', 'sonra', 'müsait olunca', 'geç dönebilirim']),
    apology: includesAny(joined, ['özür', 'kusura', 'yanlış anlama', 'haklısın']),
    warmth: includesAny(joined, ['merak ettim', 'özledim', 'güzel', 'seviyorum', 'isterim']),
    uncertainty: includesAny(joined, ['bilmiyorum', 'emin değilim', 'kararsız', 'bakarız']),
    distance: includesAny(joined, ['istemiyorum', 'yoruldum', 'boşver', 'görüşmeyelim']),
    conflict: includesAny(joined, ['tartış', 'kavga', 'kırıld', 'sinirlend', 'üzdü']),
    invitation: includesAny(joined, ['görüşelim', 'buluşalım', 'ister misin']),
    closure: includesAny(joined, ['bitirelim', 'devam etmek istemiyorum', 'uzatmak istemiyorum']),
  };
}

function includesAny(text, needles) {
  return needles.some((needle) => text.includes(needle));
}

function buildSummary(signals, relationshipType) {
  if (signals.closure) {
    return 'Mesajda konuşmayı azaltma veya kapatma eğilimi hissediliyor. Kesin bir karar gibi okumadan önce tonu sakin değerlendirmek iyi olur.';
  }
  if (signals.needsSpace) {
    return 'Mesajın ana tonu alan isteme ve yükü azaltma yönünde görünüyor. Bu, kalıcı bir geri çekilme anlamına gelmek zorunda değil.';
  }
  if (signals.conflict) {
    return 'Mesajda savunma veya kırgınlık tonu olabilir. Burada ilk hedef tansiyonu düşürmek olmalı.';
  }
  if (signals.warmth && signals.delay) {
    return 'Mesaj hem bağı koparmıyor hem de şu an için tempo düşürüyor gibi görünüyor. Yani tamamen soğuk değil, ama alan ihtiyacı var.';
  }
  if (signals.uncertainty) {
    return 'Mesajda netlikten çok belirsizlik ve kararsızlık hissi var. Fazla anlam yüklemeden ilerlemek daha güvenli olur.';
  }
  if (relationshipType && relationshipType.toLocaleLowerCase('tr').includes('flört')) {
    return 'Mesajda ilgi tamamen kapanmış görünmüyor, ama tempo ve netlik tarafında bir dalgalanma olabilir.';
  }
  return 'Mesajda net bir olumsuzluk kadar belirsizlik de var. Sakin ve ölçülü bir cevap en güvenli yol olur.';
}

function buildIntent(signals) {
  if (signals.closure) {
    return 'Mesafeyi artırma veya konuşmayı kapatma ihtimali';
  }
  if (signals.needsSpace) {
    return 'Biraz alan isteme veya tempo düşürme';
  }
  if (signals.conflict) {
    return 'Gerginliği azaltma veya savunmaya geçme';
  }
  if (signals.warmth) {
    return 'Bağı koparmadan iletişimi sürdürme';
  }
  return 'Belirsiz ama tamamen kopuk olmayan bir iletişim';
}

function buildInterestLevel(signals) {
  if (signals.closure) {
    return 'Düşük veya geri çekilen';
  }
  if (signals.warmth && !signals.distance) {
    return 'Orta';
  }
  if (signals.delay || signals.uncertainty) {
    return 'Belirsiz';
  }
  return 'Orta-belirsiz';
}

function buildClarityLevel(signals) {
  if (signals.closure || signals.needsSpace) {
    return 'Orta';
  }
  if (signals.uncertainty || signals.delay) {
    return 'Düşük-orta';
  }
  return 'Orta';
}

function buildRecommendedAction(signals) {
  if (signals.closure) {
    return 'Üstelemeden kısa ve saygılı kal; kendi sınırını da koruyan net bir cevap seç.';
  }
  if (signals.needsSpace) {
    return 'Alan tanıyan, baskı kurmayan ve kapıyı tamamen kapatmayan kısa bir cevap seç.';
  }
  if (signals.conflict) {
    return 'Önce tansiyonu düşüren bir ton kullan; netlik ihtiyacını sonra konuşmak daha iyi olur.';
  }
  if (signals.uncertainty) {
    return 'Fazla anlam yüklemeden kısa kal ve karşı tarafın tonuna göre ilerle.';
  }
  return 'Kısa, sakin ve doğal bir cevap ver; konuşmayı gereksiz ağırlık vermeden açık bırak.';
}

function buildReplyAction(signals, tone) {
  const toneLower = clean(tone).toLocaleLowerCase('tr');
  if (toneLower.includes('net')) {
    return 'Sakin ama açık bir ton seç; hem alan tanı hem de kendi duruşunu koru.';
  }
  if (toneLower.includes('mesaf')) {
    return 'Kısa, kontrollü ve saygılı kal; fazla duygusal yük bindirme.';
  }
  if (signals.needsSpace) {
    return 'Alan tanıyan ve karşı tarafı zorlamayan kısa bir cevap seç.';
  }
  if (signals.conflict) {
    return 'Tansiyonu düşüren, yumuşak ama ezilmeyen bir cevap seç.';
  }
  return 'Doğal, sakin ve tek mesajda gönderilebilir bir cevap seç.';
}

function buildSituationSummary(signals) {
  if (signals.conflict) {
    return 'Durumda kırgınlık veya savunma hali baskın olabilir. Burada hızdan çok ton önemli.';
  }
  if (signals.needsSpace) {
    return 'Durumun ana ekseni alan ihtiyacı ile senin netlik ihtiyacın arasında bir denge kurmak gibi görünüyor.';
  }
  if (signals.uncertainty) {
    return 'Durumda karışıklık ve beklenti farkı öne çıkıyor. Kesin hükümden çok gözlemle ilerlemek daha sağlıklı.';
  }
  return 'Durum tamamen kapalı görünmüyor, ama daha net ve sakin bir çerçeveye ihtiyaç var.';
}

function buildLikelyDynamics(signals) {
  if (signals.conflict) {
    return [
      'İki taraf da savunmaya geçmeden konuşmakta zorlanıyor olabilir.',
      'Zamanlama ve ton, içeriğin önüne geçmiş olabilir.',
      'Hızlı açıklama arayışı yeni gerilim yaratabilir.',
    ];
  }
  if (signals.needsSpace) {
    return [
      'Karşı taraf şu an duygusal ya da zihinsel yükünü azaltmak istiyor olabilir.',
      'Senin netlik ihtiyacın ile onun tempo ihtiyacı çakışıyor olabilir.',
      'Kısa süreli alan tanımak iletişimi tamamen bitirmek anlamına gelmeyebilir.',
    ];
  }
  return [
    'İletişim temposu tam eşleşmiyor olabilir.',
    'Belirsizlik, niyetten çok ifade tarzından kaynaklanıyor olabilir.',
    'Daha net ama sakin bir konuşma zemini işe yarayabilir.',
  ];
}

function buildAvoidNow(signals) {
  if (signals.needsSpace) {
    return [
      'Arka arkaya açıklama istemek',
      'Sessizliği hemen kötüye yormak',
      'Karşı tarafın niyetinden kesin eminmiş gibi konuşmak',
    ];
  }
  if (signals.conflict) {
    return [
      'Eski konuları tekrar açmak',
      'İma ve alay içeren cümleler kurmak',
      'Hızlı sonuç almaya çalışmak',
    ];
  }
  return [
    'Tek mesajdan büyük sonuçlar çıkarmak',
    'Baskı kuran bir ton kullanmak',
    'Kendi ihtiyacını tamamen bastırmak',
  ];
}

function buildNextSteps(signals) {
  if (signals.needsSpace) {
    return [
      'Kısa ve sakin bir cevap ver.',
      'Bir süre alan bırak ve mesaj temposunu zorlamadan izle.',
      'İleride netlik gerekiyorsa bunu tek cümleyle, sakin şekilde iste.',
    ];
  }
  if (signals.conflict) {
    return [
      'Önce gerginliği düşüren kısa bir ton seç.',
      'Savunma değil ihtiyaç dili kullan.',
      'Konu uzarsa mola verip sonra dönmeyi tercih et.',
    ];
  }
  return [
    'Tek bir net amaç belirle: yakınlaşmak mı, netlik almak mı, sınır koymak mı?',
    'Kısa ve doğal bir mesajla ilerle.',
    'Karşı tarafın sonraki tonuna göre devam edip etmeye karar ver.',
  ];
}

function buildSituationAction(signals) {
  if (signals.needsSpace) {
    return 'Şu an ilk hedef baskıyı azaltmak; kısa bir mesaj ve biraz alan daha iyi sonuç verebilir.';
  }
  if (signals.conflict) {
    return 'Önce tansiyonu düşür, sonra ihtiyaçlarını daha net bir zeminde konuş.';
  }
  return 'Sakin kal, kendi ihtiyacını netleştir ve tek bir ölçülü adımla ilerle.';
}

function buildOptionalSituationMessage(signals) {
  if (signals.needsSpace) {
    return 'Anladım, biraz alan bırakıyorum. Uygun olduğunda sakin şekilde konuşabiliriz.';
  }
  if (signals.conflict) {
    return 'Bunu büyütmek istemiyorum. Uygun olduğunda daha sakin bir tonda konuşalım.';
  }
  return 'Bunu gereksizce büyütmek istemem. Uygun olduğunda net ve sakin konuşabiliriz.';
}

function buildReplySet(input, signals) {
  const tone = normalizeTone(input?.tone);
  const length = normalizeLength(input?.responseLength);
  const wantsEmoji = Boolean(input?.emojiPreference);

  const toneSets = {
    tatli: {
      short: [
        'Tamam, biraz nefes al. Uygun olduğunda konuşuruz.',
        'Anladım, seni zorlamayayım. Hazır olunca yazarsın.',
        'Sorun değil, biraz alan bırakıyorum. Sonra konuşuruz.',
      ],
      medium: [
        'Tamam, seni zorlamayayım. Biraz nefes al, uygun olduğunda konuşuruz.',
        'Anlıyorum, kendine zaman ayırman iyi gelebilir. Hazır olduğunda yazarsın.',
        'Sorun değil, biraz alan bırakıyorum. İçin rahat ettiğinde konuşuruz.',
      ],
      long: [
        'Tamam, seni zorlamayayım. Biraz nefes alman iyi gelebilir. Hazır olduğunda konuşuruz, ben de bu alanı saygıyla bırakırım.',
        'Anlıyorum, şu an biraz geri çekilmek istiyor olabilirsin. Uygun olduğunda sakin şekilde devam edebiliriz.',
        'Sorun değil, bu konuşmayı büyütmeyeceğim. İçin rahat ettiğinde yeniden konuşabiliriz.',
      ],
    },
    havali: {
      short: [
        'Tamam, uygun olduğunda yazarsın.',
        'Sorun değil, biraz alan bırakalım.',
        'Anladım, sonra haberleşiriz.',
      ],
      medium: [
        'Tamam, alanına saygı duyuyorum. Uygun olduğunda yazarsın.',
        'Sorun değil, biraz akışına bırakalım. Sonra konuşuruz.',
        'Anladım, şimdilik alan bırakıyorum. Rahat hissettiğinde yazarsın.',
      ],
      long: [
        'Tamam, alanına saygı duyuyorum. Şu an üzerine gelmek istemem; rahat hissettiğinde konuşuruz.',
        'Sorun değil, biraz akışına bırakmak daha iyi olabilir. Uygun olduğunda yeniden konuşuruz.',
        'Anladım, şu an seni zorlamayacağım. Ne zaman iyi hissedersen o zaman devam ederiz.',
      ],
    },
    net: {
      short: [
        'Tamam, uygun olduğunda yazabilirsin.',
        'Anladım, şimdilik geri çekiliyorum.',
        'Müsait olduğunda net konuşuruz.',
      ],
      medium: [
        'Tamam, seni zorlamayacağım. Uygun olduğunda yazabilirsin.',
        'Anlıyorum, biraz alan tanıyorum. Hazır olduğunda net konuşuruz.',
        'Mesajını aldım. Şimdilik geri çekiliyorum, sonra konuşabiliriz.',
      ],
      long: [
        'Tamam, seni zorlamayacağım. Ama uygun olduğunda bunu daha net konuşmak isterim.',
        'Anlıyorum, biraz alan tanıyorum. Hazır olduğunda daha açık ve sakin konuşabiliriz.',
        'Mesajını aldım. Şimdilik geri çekiliyorum, ama belirsizlik uzarsa netleşmek isterim.',
      ],
    },
    mesafeli: {
      short: [
        'Tamam, alanına saygı duyuyorum.',
        'Anladım, sonra konuşuruz.',
        'Sorun değil, şimdilik burada kalalım.',
      ],
      medium: [
        'Tamam, alanına saygı duyuyorum. Uygun olduğunda dönüş yaparsın.',
        'Anladım, şimdilik üzerine gelmeyeceğim. Hazır olduğunda konuşuruz.',
        'Sorun değil, biraz mesafe bırakıyorum. Uygun olunca yazarsın.',
      ],
      long: [
        'Tamam, alanına saygı duyuyorum. Şu an üzerine gelmek istemem; uygun olduğunda dönüş yaparsın.',
        'Anladım, şimdilik geri çekiliyorum. Hazır olduğunda konuşabiliriz.',
        'Sorun değil, biraz mesafe bırakıyorum. Sonra konuşmak istersen yazarsın.',
      ],
    },
    flirt: {
      short: [
        'Tamam, biraz alan bırakıyorum. Sonra konuşuruz 🙂',
        'Peki, hazır olduğunda yazarsın 🙂',
        'Anladım, sonra tatlı tatlı devam ederiz 🙂',
      ],
      medium: [
        'Tamam, biraz alan bırakıyorum. Hazır olduğunda tatlı tatlı konuşuruz 🙂',
        'Peki, seni zorlamayayım. Uygun olduğunda yazarsın 🙂',
        'Anladım, şimdilik geri çekileyim. Sonra daha güzel konuşuruz 🙂',
      ],
      long: [
        'Tamam, seni zorlamayayım. Biraz alan bırakıyorum; uygun olduğunda tatlı tatlı devam ederiz 🙂',
        'Peki, şu an üstüne gelmek istemem. Hazır olduğunda yaz, sonra daha güzel konuşuruz 🙂',
        'Anladım, biraz nefes al. Sonra daha rahat bir anda devam ederiz 🙂',
      ],
    },
    kibar: {
      short: [
        'Anlıyorum, uygun olduğunda konuşuruz.',
        'Tamam, müsait hissettiğinde yazarsın.',
        'Sorun değil, hazır olduğunda konuşuruz.',
      ],
      medium: [
        'Anlıyorum, kendine zaman ayırman iyi olabilir. Uygun olduğunda konuşuruz.',
        'Tamam, seni zorlamak istemem. Müsait hissettiğinde yazarsın.',
        'Sorun değil, biraz alan bırakıyorum. Hazır olduğunda konuşabiliriz.',
      ],
      long: [
        'Anlıyorum, kendine zaman ayırman iyi olabilir. Uygun olduğunda sakin şekilde konuşuruz.',
        'Tamam, seni zorlamak istemem. Hazır hissettiğinde yazarsın, sonra devam ederiz.',
        'Sorun değil, biraz alan bırakıyorum. Konuşmak istediğinde sakin şekilde dönebiliriz.',
      ],
    },
    assertive: {
      short: [
        'Anladım, ama ben de netliği önemsiyorum.',
        'Tamam, sonra daha net konuşmak isterim.',
        'Mesajını aldım, uygun olduğunda netleşelim.',
      ],
      medium: [
        'Anladım, ama ben de netliği önemsiyorum. Uygun olduğunda açık konuşalım.',
        'Tamam, seni zorlamam. Yine de sonra daha net konuşmak isterim.',
        'Mesajını aldım. Hazır olduğunda bunu daha açık konuşabiliriz.',
      ],
      long: [
        'Anladım, seni şu an zorlamayacağım. Ama uygun olduğunda daha net konuşmak benim için önemli.',
        'Tamam, biraz alan tanırım. Yine de sonra açık ve sakin bir şekilde netleşmek isterim.',
        'Mesajını aldım. Şimdilik geri çekiliyorum, ama uygun olduğunda bu konuyu daha net konuşmak isterim.',
      ],
    },
    closure: {
      short: [
        'Anladım, ben de burada bırakayım.',
        'Tamam, uzatmayacağım.',
        'Mesajını aldım, burada kapatayım.',
      ],
      medium: [
        'Anladım, ben de burada bırakmanın daha iyi olacağını düşünüyorum.',
        'Tamam, uzatmayacağım. Burada kapatmak benim için daha doğru.',
        'Mesajını aldım. Bu noktada devam etmemek daha iyi görünüyor.',
      ],
      long: [
        'Anladım, ben de burada bırakmanın daha sağlıklı olacağını düşünüyorum. O yüzden uzatmayacağım.',
        'Tamam, bu noktada devam etmemek benim için daha doğru geliyor. Burada kapatayım.',
        'Mesajını aldım. Daha fazla uzatmadan burada bırakmak daha iyi olacak.',
      ],
    },
  };

  const selectedTone = toneSets[tone] || toneSets.kibar;
  let replies = [...selectedTone[length]];

  if (signals.conflict && tone !== 'closure') {
    replies = replies.map((item) => softenConflictReply(item));
  }

  if (signals.closure && tone !== 'closure') {
    replies = [
      'Anladım, seni zorlamayacağım. Kendine iyi bak.',
      'Tamam, ben de burada uzatmayayım.',
      'Mesajını aldım, burada bırakıyorum.',
    ];
  }

  if (wantsEmoji && tone !== 'closure') {
    replies = replies.map((item) => addEmoji(item));
  } else {
    replies = replies.map(removeEmoji);
  }

  return replies.filter((item) => isGoodReplyOption(item, signals)).slice(0, 3);
}

function normalizeTone(value) {
  const tone = clean(value).toLocaleLowerCase('tr');
  if (tone.includes('tatlı')) return 'tatli';
  if (tone.includes('havalı') || tone.includes('cool')) return 'havali';
  if (tone.includes('net')) return 'net';
  if (tone.includes('mesaf')) return 'mesafeli';
  if (tone.includes('flört')) return 'flirt';
  if (tone.includes('kibar')) return 'kibar';
  if (tone.includes('sert')) return 'assertive';
  if (tone.includes('kapanış')) return 'closure';
  return 'kibar';
}

function normalizeLength(value) {
  const length = clean(value).toLocaleLowerCase('tr');
  if (length.includes('uzun')) return 'long';
  if (length.includes('kısa') || length.includes('kisa')) return 'short';
  return 'medium';
}

function softenConflictReply(text) {
  return text
    .replace('Tamam,', 'Anladım,')
    .replace('Mesajını aldım.', 'Ne demek istediğini aldım.')
    .replace('daha net konuşmak isterim', 'daha sakin konuşmak isterim');
}

function addEmoji(text) {
  if (/[🙂😊🌿]$/.test(text)) {
    return text;
  }
  return `${removeEmoji(text)} 🙂`;
}

function removeEmoji(text) {
  return text.replace(/\s*[🙂😊🌿]+$/u, '');
}

function uniqueByNormalizedText(item, index, array) {
  const normalized = normalizeUniqueText(item);
  return index === array.findIndex((candidate) => normalizeUniqueText(candidate) === normalized);
}

function normalizeUniqueText(text) {
  return text
    .toLocaleLowerCase('tr')
    .replace(/[.!?]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}
