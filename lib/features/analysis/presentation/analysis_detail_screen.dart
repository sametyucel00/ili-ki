import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/core/utils/error_text.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

final analysisDetailProvider =
    FutureProvider.autoDispose.family((ref, String id) {
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
                    const SectionHeader('Orijinal metin'),
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
                    const SectionHeader('Kısa yorum'),
                    const SizedBox(height: 12),
                    Text(item.aiSummary),
                    const SizedBox(height: 14),
                    _InfoLine(label: 'Olası niyet', value: item.aiIntent),
                    _InfoLine(
                        label: 'İlgi seviyesi', value: item.interestLevel),
                    _InfoLine(
                        label: 'Netlik seviyesi', value: item.clarityLevel),
                    if (item.neutralityNote != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.neutralityNote!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Önerilen yaklaşım'),
                    const SizedBox(height: 12),
                    Text(item.aiSuggestedAction),
                  ],
                ),
              ),
              if (item.aiRiskFlags.isNotEmpty) ...[
                const SizedBox(height: 12),
                _BulletedCard(
                    title: 'Dikkat noktaları', items: item.aiRiskFlags),
              ],
              if (item.likelyDynamics.isNotEmpty) ...[
                const SizedBox(height: 12),
                _BulletedCard(
                    title: 'Olası dinamikler', items: item.likelyDynamics),
              ],
              if (item.avoidNow.isNotEmpty) ...[
                const SizedBox(height: 12),
                _BulletedCard(title: 'Şimdilik kaçın', items: item.avoidNow),
              ],
              if (item.nextSteps.isNotEmpty) ...[
                const SizedBox(height: 12),
                _BulletedCard(title: 'Sonraki adımlar', items: item.nextSteps),
              ],
              if (item.aiReplyOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _BulletedCard(
                    title: 'Cevap önerileri', items: item.aiReplyOptions),
              ],
              if ((item.optionalMessage ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                PrimaryCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Kısa mesaj önerisi'),
                      const SizedBox(height: 12),
                      Text(item.optionalMessage!),
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
                      await Clipboard.setData(
                          ClipboardData(text: item.aiSummary));
                      await ref.read(analyticsServiceProvider).logEvent(
                        'result_copied',
                        {'source': 'detail'},
                      );
                    },
                    child: const Text('Yorumu Kopyala'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(analysisRepositoryProvider).toggleFavorite(
                            analysisId,
                            !item.isFavorite,
                          );
                      ref.invalidate(analysisDetailProvider(analysisId));
                    },
                    child:
                        Text(item.isFavorite ? 'Favoriden Çıkar' : 'Favorile'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(analysisRepositoryProvider)
                          .deleteAnalysis(analysisId);
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
}

class _BulletedCard extends StatelessWidget {
  const _BulletedCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $item'),
            ),
          ),
        ],
      ),
    );
  }
}
