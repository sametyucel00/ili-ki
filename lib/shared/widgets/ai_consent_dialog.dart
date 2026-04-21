import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iliski_kocu_ai/core/config/env.dart';
import 'package:iliski_kocu_ai/core/constants/app_links.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/core/utils/link_launcher.dart';

Future<bool> ensureAiDataConsent(BuildContext context, WidgetRef ref) async {
  final backendConfigured = ref.read(aiBackendServiceProvider).isConfigured;
  if (!backendConfigured) {
    return true;
  }

  final hasPrompted =
      await ref.read(localCacheServiceProvider).hasAiDataConsentPrompted();
  final hasConsent =
      await ref.read(localCacheServiceProvider).hasAiDataConsent();
  if (hasConsent || hasPrompted) {
    return true;
  }

  if (!context.mounted) {
    return false;
  }

  final approved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('AI veri paylaşım izni'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mesaj metni, yazdığın bağlam, seçtiğin ton ve ilişki seçenekleri daha iyi analiz üretmek için ${Env.aiProviderName} ile çalışan üçüncü taraf AI servisine güvenli backend üzerinden gönderilebilir.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bu veri yalnızca analiz, cevap önerisi ve durum stratejisi üretmek için kullanılır. İzin vermezsen uygulama dış AI yerine yerel yorum modunda devam eder.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => openExternalLink(AppLinks.privacyUrl),
                      child: const Text('Gizlilik Politikası'),
                    ),
                    OutlinedButton(
                      onPressed: () => openExternalLink(AppLinks.termsUrl),
                      child: const Text('Kullanım Koşulları'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Şimdilik verme'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('İzin ver ve devam et'),
            ),
          ],
        ),
      ) ??
      false;

  await ref.read(localCacheServiceProvider).setAiDataConsent(approved);
  ref.invalidate(aiDataConsentProvider);
  await ref.read(analyticsServiceProvider).logEvent(
    approved ? 'ai_data_consent_granted' : 'ai_data_consent_declined',
  );
  return approved;
}
