require('dotenv').config();

const cors = require('cors');
const express = require('express');

const app = express();
const port = Number(process.env.PORT || 3000);
const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';
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
    model,
  });
});

app.post('/ai', async (req, res) => {
  if (!process.env.OPENAI_API_KEY) {
    res.status(500).json({ error: 'openai_key_missing' });
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
    const result = await callOpenAI(type, req.body);
    res.json({ result });
  } catch (error) {
    console.error('ai_request_failed', {
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
  console.log(`Hisle AI server listening on port ${port}`);
});

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

async function callOpenAI(type, input) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model,
      temperature: 0.45,
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
    throw new Error(`openai_http_${response.status}: ${text.slice(0, 300)}`);
  }

  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('empty_model_output');
  }

  const parsed = JSON.parse(content);
  return normalize(type, parsed);
}

function systemPrompt() {
  return [
    'Sen Hisle uygulamasının Türkçe ilişki iletişimi asistanısın.',
    'Terapi, tanı veya profesyonel danışmanlık iddiasında bulunma.',
    'Başka bir kişinin iç düşünceleri hakkında kesinlik iddia etme; olasılık ve belirsizlik dili kullan.',
    'Manipülasyon, takip, taciz, baskı, intikam, kıskandırma, bağımlılık oluşturma veya zorlama önerme.',
    'Sakin, doğal, pratik, kısa ve mobil ekranda okunabilir yaz.',
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
      task: 'Gelen mesaja doğal Türkçe cevap seçenekleri üret.',
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

function normalize(type, parsed) {
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
      recommendedAction: stringOr(parsed.recommendedAction, 'En doğal gelen cevabı seç.'),
      replyOptions: listOfStrings(parsed.replyOptions).slice(0, 3),
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
