import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import OpenAI from 'openai';
import { z } from 'zod';
import { promptLibrary, PromptKey } from './prompts';

admin.initializeApp();

const db = admin.firestore();
const aiApiKey = defineSecret('OPENAI_API_KEY');

function resolveAiApiKey() {
  return process.env.OPENAI_API_KEY || aiApiKey.value();
}

const analysisSchema = z.object({
  summary: z.string().min(1),
  interestLevel: z.string().optional().default('Belirsiz'),
  clarityLevel: z.string().optional().default('Orta'),
  riskFlags: z.array(z.string()).max(5).default([]),
  neutralityNote: z.string().optional().default('Bağlam sınırlı olduğu için yorum ihtimale dayanır.'),
  recommendedAction: z.string().min(1),
  replyOptions: z.array(z.string()).min(3).max(3),
});

const replySchema = z.object({
  replyOptions: z.array(z.string()).min(3).max(3),
});

const strategySchema = z.object({
  summary: z.string().min(1),
  likelyDynamics: z.array(z.string()).default([]),
  riskFlags: z.array(z.string()).default([]),
  avoidNow: z.array(z.string()).default([]),
  nextSteps: z.array(z.string()).min(3).max(3),
  optionalMessage: z.string().optional(),
});

type Config = {
  starterCredits: number;
  freeDailyCredits: number;
  linkBonusCredits: number;
  replyGenerationCost: number;
  messageAnalysisCost: number;
  situationStrategyCost: number;
  guestDailyLimit: number;
  linkedDailyLimit: number;
  aiCooldownSeconds: number;
  latestPromptVersion: string;
  softPaywallThreshold: number;
};

async function getConfig(): Promise<Config> {
  const snapshot = await db.collection('app_config').doc('runtime').get();
  const data = snapshot.data() ?? {};
  return {
    starterCredits: Number(data.starterCredits ?? 3),
    freeDailyCredits: Number(data.freeDailyCredits ?? 2),
    linkBonusCredits: Number(data.linkBonusCredits ?? 3),
    replyGenerationCost: Number(data.replyGenerationCost ?? 1),
    messageAnalysisCost: Number(data.messageAnalysisCost ?? 1),
    situationStrategyCost: Number(data.situationStrategyCost ?? 2),
    guestDailyLimit: Number(data.guestDailyLimit ?? 3),
    linkedDailyLimit: Number(data.linkedDailyLimit ?? 10),
    aiCooldownSeconds: Number(data.aiCooldownSeconds ?? 20),
    latestPromptVersion: String(data.latestPromptVersion ?? 'v1'),
    softPaywallThreshold: Number(data.softPaywallThreshold ?? 2),
  };
}

function assertAuth(uid?: string): string {
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  return uid;
}

async function getUser(uid: string) {
  const snapshot = await db.collection('users').doc(uid).get();
  if (!snapshot.exists) {
    throw new HttpsError('not-found', 'User document missing.');
  }
  return snapshot;
}

async function logCredit(uid: string, type: string, amount: number, balanceAfter: number, note: string) {
  const ref = db.collection('credit_transactions').doc();
  await ref.set({
    id: ref.id,
    uid,
    type,
    amount,
    balanceAfter,
    note,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function checkCooldown(uid: string, seconds: number) {
  const recent = await db
    .collection('analyses')
    .where('uid', '==', uid)
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();
  const last = recent.docs[0]?.data()?.createdAt?.toDate?.();
  if (!last) {
    return;
  }
  const diff = Date.now() - last.getTime();
  if (diff < seconds * 1000) {
    throw new HttpsError('resource-exhausted', 'Please wait before trying again.');
  }
}

async function enforceDailyLimit(uid: string, isGuest: boolean, config: Config) {
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const snapshot = await db
    .collection('analyses')
    .where('uid', '==', uid)
    .where('createdAt', '>=', start)
    .get();
  const limit = isGuest ? config.guestDailyLimit : config.linkedDailyLimit;
  if (snapshot.size >= limit) {
    throw new HttpsError('resource-exhausted', 'Daily limit reached.');
  }
}

async function spendCredits(uid: string, amount: number, reason: string) {
  await db.runTransaction(async (tx) => {
    const userRef = db.collection('users').doc(uid);
    const userSnap = await tx.get(userRef);
    const balance = Number(userSnap.data()?.creditBalance ?? 0);
    if (balance < amount) {
      throw new HttpsError('failed-precondition', 'Insufficient credits.');
    }
    const next = balance - amount;
    tx.update(userRef, { creditBalance: next });
    const logRef = db.collection('credit_transactions').doc();
    tx.set(logRef, {
      id: logRef.id,
      uid,
      type: 'deduction',
      amount: -amount,
      balanceAfter: next,
      note: reason,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function awardCredits(uid: string, amount: number, reason: string) {
  const userRef = db.collection('users').doc(uid);
  const snap = await userRef.get();
  const next = Number(snap.data()?.creditBalance ?? 0) + amount;
  await userRef.update({ creditBalance: next });
  await logCredit(uid, 'grant', amount, next, reason);
}

async function callModel(
  promptKey: PromptKey,
  payload: Record<string, unknown>,
  schema: z.ZodSchema,
): Promise<Record<string, unknown>> {
  const resolvedKey = resolveAiApiKey();
  if (!resolvedKey) {
    throw new Error('OPENAI_API_KEY is missing');
  }
  const client = new OpenAI({ apiKey: resolvedKey });
  const prompt = await loadPromptBundle(promptKey);
  const completion = await client.chat.completions.create({
    model: 'gpt-4.1-mini',
    temperature: 0.5,
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: prompt.systemPrompt },
      { role: 'developer', content: prompt.developerPrompt },
      { role: 'user', content: JSON.stringify(payload) },
    ],
  });

  const content = completion.choices[0]?.message?.content;
  if (!content) {
    throw new Error('Empty model output');
  }
  const parsed = JSON.parse(content);
  return schema.parse(parsed) as Record<string, unknown>;
}

async function loadPromptBundle(promptKey: PromptKey) {
  const snapshot = await db
    .collection('prompts')
    .where('promptKey', '==', promptKey)
    .where('isActive', '==', true)
    .limit(1)
    .get();
  if (snapshot.empty) {
    return promptLibrary[promptKey];
  }
  const data = snapshot.docs[0].data();
  return {
    systemPrompt: String(data.systemPrompt ?? promptLibrary[promptKey].systemPrompt),
    developerPrompt: String(data.developerPrompt ?? promptLibrary[promptKey].developerPrompt),
  };
}

async function safeModelCall(
  promptKey: PromptKey,
  payload: Record<string, unknown>,
  schema: z.ZodSchema,
  fallback: Record<string, unknown>,
) {
  try {
    return await callModel(promptKey, payload, schema);
  } catch {
    try {
      return await callModel(promptKey, payload, schema);
    } catch {
      return fallback;
    }
  }
}

async function createAndStoreAnalysis(args: {
  uid: string;
  type: 'messageAnalysis' | 'replyGeneration' | 'situationStrategy';
  inputText: string;
  contextText?: string;
  relationshipType?: string;
  tone?: string;
  responseLength?: string;
  emojiPreference?: boolean;
  modelOutput: Record<string, unknown>;
  creditsUsed: number;
}) {
  const ref = db.collection('analyses').doc();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const data = {
    id: ref.id,
    uid: args.uid,
    type: args.type,
    inputText: args.inputText,
    contextText: args.contextText ?? null,
    relationshipType: args.relationshipType ?? null,
    tone: args.tone ?? null,
    responseLength: args.responseLength ?? null,
    emojiPreference: args.emojiPreference ?? null,
    aiSummary: String(args.modelOutput.summary ?? ''),
    aiIntent: String(args.modelOutput.interestLevel ?? ''),
    aiRiskFlags: Array.isArray(args.modelOutput.riskFlags) ? args.modelOutput.riskFlags : [],
    aiSuggestedAction: String(
      args.modelOutput.recommendedAction ?? args.modelOutput.summary ?? 'Sakin ve net ilerlemek daha güvenli olabilir.',
    ),
    aiReplyOptions: Array.isArray(args.modelOutput.replyOptions) ? args.modelOutput.replyOptions : [],
    rawModelOutput: args.modelOutput,
    creditsUsed: args.creditsUsed,
    isFavorite: false,
    createdAt: now,
    updatedAt: now,
    neutralityNote: args.modelOutput.neutralityNote ?? null,
    clarityLevel: args.modelOutput.clarityLevel ?? null,
    interestLevel: args.modelOutput.interestLevel ?? null,
    avoidNow: Array.isArray(args.modelOutput.avoidNow) ? args.modelOutput.avoidNow : [],
    nextSteps: Array.isArray(args.modelOutput.nextSteps) ? args.modelOutput.nextSteps : [],
    likelyDynamics: Array.isArray(args.modelOutput.likelyDynamics) ? args.modelOutput.likelyDynamics : [],
    optionalMessage: args.modelOutput.optionalMessage ?? null,
  };
  await ref.set(data);
  const saved = await ref.get();
  return {
    ...saved.data(),
    createdAt: saved.data()?.createdAt?.toDate?.()?.toISOString(),
    updatedAt: saved.data()?.updatedAt?.toDate?.()?.toISOString(),
  };
}

export const grantStarterCredits = onCall(async (request) => {
  const uid = assertAuth(request.auth?.uid);
  const user = await getUser(uid);
  if (Number(user.data()?.creditBalance ?? 0) > 0) {
    return { granted: false };
  }
  const config = await getConfig();
  await awardCredits(uid, config.starterCredits, 'starter_credits');
  return { granted: true, amount: config.starterCredits };
});

export const grantLinkReward = onCall(async (request) => {
  const uid = assertAuth(request.auth?.uid);
  const userRef = db.collection('users').doc(uid);
  const snap = await userRef.get();
  if (snap.data()?.isLinked === true) {
    return { granted: false };
  }
  const config = await getConfig();
  await userRef.update({
    isGuest: false,
    isLinked: true,
    authType: request.auth?.token.firebase?.sign_in_provider ?? 'linked',
    provider: request.auth?.token.firebase?.sign_in_provider ?? 'linked',
    linkedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await awardCredits(uid, config.linkBonusCredits, 'link_bonus');
  return { granted: true };
});

export const createAnalysis = onCall({ secrets: [aiApiKey] }, async (request) => {
  const uid = assertAuth(request.auth?.uid);
  const config = await getConfig();
  const isGuest = request.auth?.token.firebase?.sign_in_provider === 'anonymous';
  await enforceDailyLimit(uid, isGuest, config);
  await checkCooldown(uid, config.aiCooldownSeconds);
  await spendCredits(uid, config.messageAnalysisCost, 'message_analysis');

  const payload = {
    message: String(request.data?.inputText ?? ''),
    context: String(request.data?.contextText ?? ''),
    relationshipType: String(request.data?.relationshipType ?? ''),
    tier: isGuest ? 'guest' : 'linked',
  };
  const output = await safeModelCall('message_analysis', payload, analysisSchema, {
    summary: 'Mesaj kısa ve belirsiz görünüyor. Ek bağlam olmadan kesin yorum yapmak sağlıklı olmaz.',
    interestLevel: 'Belirsiz',
    clarityLevel: 'Düşük',
    riskFlags: [],
    neutralityNote: 'Bu yorum sınırlı bağlama dayanır.',
    recommendedAction: 'Sakin, kısa ve açık bir cevap vermek daha güvenli olabilir.',
    replyOptions: ['Tamam, müsait olunca konuşalım.', 'Anladım, uygun olduğunda yazarsın.', 'Sorun değil, sonra devam ederiz.'],
  });

  return createAndStoreAnalysis({
    uid,
    type: 'messageAnalysis',
    inputText: payload.message,
    contextText: payload.context,
    relationshipType: payload.relationshipType,
    modelOutput: output,
    creditsUsed: config.messageAnalysisCost,
  });
});

export const generateReplies = onCall({ secrets: [aiApiKey] }, async (request) => {
  const uid = assertAuth(request.auth?.uid);
  const config = await getConfig();
  const isGuest = request.auth?.token.firebase?.sign_in_provider === 'anonymous';
  await enforceDailyLimit(uid, isGuest, config);
  await checkCooldown(uid, config.aiCooldownSeconds);
  await spendCredits(uid, config.replyGenerationCost, 'reply_generation');

  const payload = {
    message: String(request.data?.inputText ?? ''),
    context: String(request.data?.contextText ?? ''),
    tone: String(request.data?.tone ?? 'Kibar'),
    responseLength: String(request.data?.responseLength ?? 'Kısa'),
    emojiPreference: Boolean(request.data?.emojiPreference ?? false),
  };
  const output = await safeModelCall('reply_generation', payload, replySchema, {
    replyOptions: [
      'Tamam, haberleşiriz.',
      'Anladım, uygun olunca yazarsın.',
      'Sorun değil, sonra konuşuruz.',
    ],
  });

  return createAndStoreAnalysis({
    uid,
    type: 'replyGeneration',
    inputText: payload.message,
    contextText: payload.context,
    tone: payload.tone,
    responseLength: payload.responseLength,
    emojiPreference: payload.emojiPreference,
    modelOutput: output,
    creditsUsed: config.replyGenerationCost,
  });
});

export const createSituationStrategy = onCall({ secrets: [aiApiKey] }, async (request) => {
  const uid = assertAuth(request.auth?.uid);
  const config = await getConfig();
  const isGuest = request.auth?.token.firebase?.sign_in_provider === 'anonymous';
  await enforceDailyLimit(uid, isGuest, config);
  await checkCooldown(uid, config.aiCooldownSeconds);
  await spendCredits(uid, config.situationStrategyCost, 'situation_strategy');

  const payload = {
    situation: String(request.data?.inputText ?? ''),
    relationshipType: String(request.data?.relationshipType ?? ''),
  };
  const output = await safeModelCall('situation_strategy', payload, strategySchema, {
    summary: 'Durumda belirsizlik ve tempo uyumsuzluğu olabilir.',
    likelyDynamics: ['İletişim ritmi eşleşmiyor olabilir'],
    riskFlags: [],
    avoidNow: ['Arka arkaya baskılı mesaj atmak'],
    nextSteps: ['Biraz alan tanı', 'Tek bir net mesaj seç', 'Cevaba göre tempoyu ayarla'],
    optionalMessage: 'Müsait olduğunda konuşalım, ben buradayım.',
  });

  return createAndStoreAnalysis({
    uid,
    type: 'situationStrategy',
    inputText: payload.situation,
    relationshipType: payload.relationshipType,
    modelOutput: output,
    creditsUsed: config.situationStrategyCost,
  });
});

export const grantDailyCredits = onCall(async (request) => {
  const uid = assertAuth(request.auth?.uid);
  const config = await getConfig();
  await awardCredits(uid, config.freeDailyCredits, 'daily_credits');
  return { granted: true };
});

export const deductCredits = onCall(async (request) => {
  const uid = assertAuth(request.auth?.uid);
  await spendCredits(uid, Number(request.data?.amount ?? 0), String(request.data?.reason ?? 'manual'));
  return { ok: true };
});

export const verifySubscription = onCall(async (request) => {
  const uid = assertAuth(request.auth?.uid);
  await db.collection('subscriptions').doc(uid).set(
    {
      id: uid,
      uid,
      platform: request.data?.platform ?? 'unknown',
      productId: request.data?.productId ?? 'unknown',
      status: 'active',
      startDate: admin.firestore.FieldValue.serverTimestamp(),
      expiryDate: request.data?.expiryDate ?? null,
      autoRenew: true,
      lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await db.collection('users').doc(uid).update({
    planType: 'premium',
    subscriptionStatus: 'active',
    subscriptionPlatform: request.data?.platform ?? 'unknown',
    subscriptionExpiryDate: request.data?.expiryDate ?? null,
  });
  return { ok: true };
});

export const restoreEntitlementsIfNeeded = onCall(async (request) => {
  const uid = assertAuth(request.auth?.uid);
  await db.collection('users').doc(uid).set({ lastLoginAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  return { restored: true };
});

export const checkGuestUsagePolicy = onCall(async (request) => {
  const uid = assertAuth(request.auth?.uid);
  const config = await getConfig();
  const user = await getUser(uid);
  return {
    isGuest: Boolean(user.data()?.isGuest ?? true),
    softPaywallThreshold: config.softPaywallThreshold,
  };
});

export const deleteUserData = onCall(async (request) => {
  const uid = assertAuth(request.auth?.uid);
  const batch = db.batch();
  const collections = ['analyses', 'credit_transactions', 'feedback', 'subscriptions'];
  for (const collection of collections) {
    const snapshot = await db.collection(collection).where('uid', '==', uid).get();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  }
  batch.set(
    db.collection('users').doc(uid),
    { deletedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true },
  );
  await batch.commit();
  return { deleted: true };
});

export const purchaseWebhookHandler = onRequest(async (req, res) => {
  res.status(200).json({ received: true, bodyPresent: Boolean(req.body) });
});
