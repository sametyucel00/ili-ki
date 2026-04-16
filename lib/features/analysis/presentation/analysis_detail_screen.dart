import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/core/utils/error_text.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

final analysisDetailProvider = FutureProvider.autoDispose.family((ref, String id) {
  return ref.read(analysisRepositoryProvider).getAnalysisById(id);
});

class AnalysisDetailScreen extends ConsumerWidget {
  const AnalysisDetailScreen({required this.analysisId, super.key});

  final String analysisId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(analysisDetailProvider(analysisId));
    return AppScaffold(
      title: 'Analiz Detayı',
      child: detail.when(
        data: (item) {
          if (item == null) {
            return const EmptyStateView(
              title: 'Detay bulunamadı',
              description: 'Bu kayıt silinmiş olabilir.',
            );
          }
          return ListView(
            children: [
              PrimaryCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Orijinal giriş'),
                    const SizedBox(height: 12),
                    Text(item.inputText),
                    if ((item.contextText ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Bağlam: ${item.contextText}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Özet'),
                    const SizedBox(height: 12),
                    Text(item.aiSummary),
                    if (item.interestLevel != null) Text('İlgi seviyesi: ${item.interestLevel}'),
                    if (item.clarityLevel != null) Text('Netlik seviyesi: ${item.clarityLevel}'),
                    if (item.neutralityNote != null) Text('Belirsizlik notu: ${item.neutralityNote}'),
                    const SizedBox(height: 12),
                    Text('Öneri: ${item.aiSuggestedAction}'),
                  ],
                ),
              ),
              if (item.aiRiskFlags.isNotEmpty) ...[
                const SizedBox(height: 12),
                PrimaryCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Dikkat noktaları'),
                      const SizedBox(height: 12),
                      ...item.aiRiskFlags.map((flag) => Text('• $flag')),
                    ],
                  ),
                ),
              ],
              if (item.aiReplyOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                PrimaryCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Cevap önerileri'),
                      const SizedBox(height: 12),
                      ...item.aiReplyOptions.map(
                        (reply) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• $reply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (item.nextSteps.isNotEmpty) ...[
                const SizedBox(height: 12),
                PrimaryCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Sonraki adımlar'),
                      const SizedBox(height: 12),
                      ...item.nextSteps.map((step) => Text('• $step')),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: item.aiSummary));
                      await ref.read(analyticsServiceProvider).logEvent('result_copied', {'source': 'detail'});
                    },
                    child: const Text('Özeti Kopyala'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(analysisRepositoryProvider).toggleFavorite(analysisId, !item.isFavorite);
                      ref.invalidate(analysisDetailProvider(analysisId));
                    },
                    child: Text(item.isFavorite ? 'Favoriden Çıkar' : 'Favorile'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(analysisRepositoryProvider).deleteAnalysis(analysisId);
                      if (context.mounted) {
                        context.pop();
                      }
                    },
                    child: const Text('Sil'),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const LoadingList(),
        error: (error, _) => ErrorStateView(
          message: toUserFacingError(error),
          onRetry: () => ref.invalidate(analysisDetailProvider(analysisId)),
        ),
      ),
    );
  }
}
