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
      temperature: 0.35,
      max_tokens: input.tier === 'premium' ? 900 : 650,
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
    'Terapi, tanı veya profesyonel danışmanlık iddiasında bulunma.',
    'Başka bir kişinin iç düşünceleri hakkında kesinlik iddia etme; olasılık ve belirsizlik dili kullan.',
    'Manipülasyon, takip, taciz, baskı, intikam, kıskandırma, bağımlılık oluşturma veya zorlama önerme.',
    'Sakin, doğal, pratik, kısa ve mobil ekranda okunabilir yaz.',
    'Reply üretirken message alanı daima karşı tarafın gönderdiği metindir.',
    'replyOptions daima uygulama kullanıcısının karşı tarafa göndereceği cevaplar olmalıdır.',
    'Karşı tarafın mesajındaki birinci tekil ifadeleri kullanıcıya aitmiş gibi sahiplenme.',
    'Gelen mesajı tekrar etme; ona cevap ver.',
    'recommendedAction bir mesaj değil, kullanıcıya kısa strateji önerisi olmalıdır.',
    'Sadece geçerli JSON döndür. Markdown kullanma.',
  ].join('\n');
}

function userPrompt(type, input) {
  if (type === 'message_analysis') {
    return JSON.stringify({
      task: 'Gelen mesajı ilişki iletişimi açısından yorumla.',
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
      task: 'Karşı taraftan gelen mesaja, uygulama kullanıcısının gönderebileceği doğal Türkçe cevap seçenekleri üret.',
      perspectiveRules: [
        'message karşı tarafın gönderdiği metindir.',
        'replyOptions kullanıcının karşı tarafa göndereceği cevaplardır.',
        'recommendedAction kullanıcıya strateji önerisidir; mesaj metni gibi yazılmamalıdır.',
        'Gelen mesajdaki "ben" ifadelerini kullanıcıya aitmiş gibi kullanma.',
        'Gelen mesajı tekrar etme; ona cevap ver.',
        'Çok soğuk, keskin veya kapanış gibi duran "Anlaşıldı, görüşürüz" tarzı cevaplardan kaçın.',
        'Cevaplar sakin, saygılı, alan tanıyan ve tek başına gönderilebilir doğal mesajlar olsun.',
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
    task: 'Anlatılan ilişki iletişimi durumuna sakin bir strateji öner.',
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
  if (type === 'message_analysis') {
    return {
      summary: stringOr(parsed.summary, 'Mesaj sakin şekilde yorumlandı.'),
      intent: stringOr(parsed.intent, 'Belirsiz'),
      interestLevel: stringOr(parsed.interestLevel, 'Belirsiz'),
      clarityLevel: stringOr(parsed.clarityLevel, 'Orta'),
      riskFlags: listOfStrings(parsed.riskFlags).slice(0, 4),
      neutralityNote: stringOr(
        parsed.neutralityNote,
        'Bu yorum kesinlik iddiası taşımaz; yalnızca olası bir okuma sunar.',
      ),
      recommendedAction: stringOr(parsed.recommendedAction, 'Kısa, net ve sakin ilerle.'),
      replyOptions: listOfStrings(parsed.replyOptions).slice(0, 3),
    };
  }

  if (type === 'reply_generation') {
    return {
      recommendedAction: normalizeReplyAction(parsed.recommendedAction),
      replyOptions: ensureReplyOptions(parsed.replyOptions, input).slice(0, 3),
    };
  }

  return {
    summary: stringOr(parsed.summary, 'Durum sakin şekilde özetlendi.'),
    likelyDynamics: listOfStrings(parsed.likelyDynamics).slice(0, 4),
    riskFlags: listOfStrings(parsed.riskFlags).slice(0, 4),
    avoidNow: listOfStrings(parsed.avoidNow).slice(0, 4),
    nextSteps: listOfStrings(parsed.nextSteps).slice(0, 3),
    optionalMessage: stringOr(parsed.optionalMessage, ''),
    recommendedAction: stringOr(parsed.recommendedAction, 'Sakin ve net bir sonraki adım seç.'),
  };
}

function stringOr(value, fallback) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function listOfStrings(value) {
  return Array.isArray(value)
    ? value.map((item) => String(item).trim()).filter(Boolean)
    : [];
}

function normalizeReplyAction(value) {
  const action = stringOr(value, 'Sakin ve alan tanıyan bir cevap seç.');
  if (
    looksLikeReplyText(action) ||
    looksTooCold(action) ||
    looksMirroredOrSelfReferential(action) ||
    action.trim().endsWith('?') ||
    action.toLocaleLowerCase('tr').includes('bana haber ver') ||
    action.toLocaleLowerCase('tr').includes('istersen konuşabiliriz')
  ) {
    return 'Karşı tarafın alan ihtiyacını kabul eden, sakin ve kapıyı açık bırakan kısa bir cevap seç.';
  }
  return action;
}

function ensureReplyOptions(value, input) {
  const options = listOfStrings(value)
    .map((item) => item.replace(/\s+/g, ' ').trim())
    .filter((item) => isGoodReplyOption(item));
  const fallback = buildReplyFallbacks(input);

  if (options.length < 2) {
    return fallback.slice(0, 3);
  }

  return [...options, ...fallback].filter(unique).slice(0, 3);
}

function isGoodReplyOption(text) {
  const trimmed = text.trim();
  if (trimmed.length < 28) {
    return false;
  }
  return (
    !looksLikeMirroredIncomingMessage(trimmed) &&
    !looksMirroredOrSelfReferential(trimmed) &&
    !looksTooCold(trimmed) &&
    !looksPushy(trimmed) &&
    !trimmed.includes('?')
  );
}

function looksLikeMirroredIncomingMessage(text) {
  const lower = text.toLocaleLowerCase('tr');
  return (
    lower.includes('bugün konuşmak istemiyorum') ||
    lower.includes('ben konuşmak istemiyorum') ||
    lower.includes('yarın daha iyi hissederim') ||
    lower.includes('bugün çok yoruldum') ||
    (lower.includes('görüşmek üzere') && lower.includes('bugün')) ||
    (lower.includes('seni seviyorum') && lower.includes('konuşmak istemiyorum'))
  );
}

function looksTooCold(text) {
  const lower = text.toLocaleLowerCase('tr').replace(/\s+/g, ' ').trim();
  return (
    lower === 'anlaşıldı, görüşürüz.' ||
    lower === 'anlaşıldı, görüşürüz' ||
    lower === 'yarın görüşürüz, iyi günler.' ||
    lower === 'yarın görüşürüz, iyi günler' ||
    lower === 'iyi günler, konuşmak istemiyorum anlaşıldı. yarın görüşürüz.'
  );
}

function looksLikeReplyText(text) {
  const lower = text.toLocaleLowerCase('tr');
  return (
    lower.includes('görüşürüz') ||
    lower.includes('yazarım') ||
    lower.includes('konuşuruz') ||
    lower.includes('iyi günler')
  );
}

function looksMirroredOrSelfReferential(text) {
  const lower = text.toLocaleLowerCase('tr').replace(/[.!?]/g, ' ');
  return (
    lower.includes('konuşmak istemiyorum') ||
    lower.includes('yalnız kalmak istiyorum') ||
    lower.includes('gerçekten konuşmak istemiyorum') ||
    lower.includes('başka bir zaman ne zaman uygun olur') ||
    lower.includes('seni düşünüyorum') ||
    lower.includes('umarım yarın daha iyi hissederim') ||
    lower.includes('çok yoruldum')
  );
}

function looksPushy(text) {
  const lower = text.toLocaleLowerCase('tr');
  return (
    lower.includes('ne zaman uygun olur') ||
    lower.includes('ne zaman konuşabiliriz') ||
    lower.includes('neden') ||
    lower.includes('ama neden') ||
    lower.includes('hemen')
  );
}

function buildReplyFallbacks(input) {
  const tone = clean(input?.tone).toLocaleLowerCase('tr');
  const responseLength = clean(input?.responseLength).toLocaleLowerCase('tr');
  const wantsEmoji = Boolean(input?.emojiPreference);

  const baseSets = {
    havali: [
      'Tamam, alanına saygı duyuyorum. Rahat hissettiğinde yazarsın.',
      'Sorun değil, biraz alan bırakayım. Uygun olduğunda konuşuruz.',
      'Anladım, kendine vakit ayır. Sonra haberleşiriz.',
    ],
    net: [
      'Tamam, seni zorlamayacağım. Uygun olduğunda yazabilirsin.',
      'Anlıyorum, biraz alan tanıyorum. Hazır olduğunda konuşuruz.',
      'Mesajını aldım, şimdilik geri çekiliyorum. Uygun olunca yazarsın.',
    ],
    mesafeli: [
      'Tamam, alanına saygı duyuyorum. Uygun olduğunda dönüş yaparsın.',
      'Anladım, şimdilik üzerine gelmeyeceğim. Hazır olduğunda konuşuruz.',
      'Sorun değil, biraz mesafe bırakıyorum. Uygun olunca yazarsın.',
    ],
    tatli: [
      'Tamam, seni zorlamayayım. Biraz nefes al, istersen sonra konuşuruz.',
      'Anlıyorum, kendine zaman ayırman iyi gelebilir. Hazır olduğunda buradayım.',
      'Sorun değil, biraz alan bırakıyorum. İçin rahat edince konuşuruz.',
    ],
    kibar: [
      'Anlıyorum, kendine zaman ayırman iyi olabilir. Uygun olduğunda konuşuruz.',
      'Tamam, seni zorlamak istemem. Müsait hissettiğinde yazarsın.',
      'Sorun değil, biraz alan bırakıyorum. Hazır olduğunda konuşabiliriz.',
    ],
    default: [
      'Anlıyorum, kendine zaman ayırman iyi olabilir. Uygun olduğunda konuşuruz.',
      'Tamam, seni zorlamak istemem. Müsait hissettiğinde yazarsın.',
      'Sorun değil, biraz alan bırakıyorum. Hazır olduğunda konuşabiliriz.',
    ],
  };

  const selected =
    baseSets[tone] ||
    (tone.includes('haval') ? baseSets.havali : null) ||
    (tone.includes('tatl') ? baseSets.tatli : null) ||
    (tone.includes('mesaf') ? baseSets.mesafeli : null) ||
    (tone.includes('net') ? baseSets.net : null) ||
    (tone.includes('kibar') ? baseSets.kibar : null) ||
    baseSets.default;

  return selected.map((item) => adjustReplyLengthAndEmoji(item, responseLength, wantsEmoji));
}

function adjustReplyLengthAndEmoji(text, responseLength, wantsEmoji) {
  let result = text;

  if (responseLength.includes('kısa') || responseLength.includes('kisa')) {
    if (result.includes('kendine zaman ayırman iyi olabilir')) {
      result = 'Anlıyorum, uygun olduğunda konuşuruz.';
    } else if (result.includes('seni zorlamak istemem')) {
      result = 'Tamam, müsait hissettiğinde yazarsın.';
    } else if (result.includes('biraz alan bırakıyorum')) {
      result = 'Sorun değil, hazır olduğunda konuşuruz.';
    } else if (result.includes('alanına saygı duyuyorum')) {
      result = 'Tamam, uygun olduğunda yazarsın.';
    } else {
      result = result.replace(/\s+/g, ' ').trim();
    }
  }

  if (wantsEmoji && !/[🙂😊🌿]/.test(result)) {
    result = `${result} 🙂`;
  }

  return result;
}

function unique(item, index, array) {
  return array.indexOf(item) === index;
}
