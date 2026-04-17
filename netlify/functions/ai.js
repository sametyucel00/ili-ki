const headers = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-allow-headers': 'content-type',
  'content-type': 'application/json; charset=utf-8',
};

const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers };
  }

  if (event.httpMethod !== 'POST') {
    return json(405, { error: 'method_not_allowed' });
  }

  if (!process.env.OPENAI_API_KEY) {
    return json(500, { error: 'openai_key_missing' });
  }

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch (_) {
    return json(400, { error: 'invalid_json' });
  }

  const type = String(body.type || '');
  if (!['message_analysis', 'reply_generation', 'situation_strategy'].includes(type)) {
    return json(400, { error: 'invalid_type' });
  }

  const userText = type === 'situation_strategy' ? body.situation : body.message;
  if (!isUsefulText(userText)) {
    return json(400, { error: 'empty_input' });
  }

  try {
    const result = await callOpenAI(type, body);
    return json(200, { result });
  } catch (error) {
    console.error('ai_function_failed', {
      type,
      message: error instanceof Error ? error.message : String(error),
    });
    return json(502, { error: 'ai_unavailable' });
  }
};

function json(statusCode, payload) {
  return {
    statusCode,
    headers,
    body: JSON.stringify(payload),
  };
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
