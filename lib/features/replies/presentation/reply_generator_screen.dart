import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/core/utils/error_text.dart';
import 'package:iliski_kocu_ai/features/analysis/presentation/analysis_controller.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';
import 'package:iliski_kocu_ai/shared/widgets/rewarded_credit_sheet.dart';

class ReplyGeneratorScreen extends ConsumerStatefulWidget {
  const ReplyGeneratorScreen({super.key});

  @override
  ConsumerState<ReplyGeneratorScreen> createState() => _ReplyGeneratorScreenState();
}

class _ReplyGeneratorScreenState extends ConsumerState<ReplyGeneratorScreen> {
  final messageController = TextEditingController();
  final contextController = TextEditingController();
  String tone = 'Tatlı';
  String responseLength = 'Kısa';
  bool emojiPreference = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisActionProvider);
    final result = state.valueOrNull;
    final replyResult = result?.type == AnalysisType.replyGeneration ? result : null;

    return AppScaffold(
      title: 'Cevap Yazdır',
      child: ListView(
        children: [
          const SectionHeader(
            'Doğal cevap üret',
            subtitle: 'Türkçe, kullanıma hazır ve role uygun üç seçenek oluştur.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: messageController,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Karşı taraftan gelen mesaj'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contextController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Opsiyonel bağlam'),
          ),
          const SizedBox(height: 8),
          Text(
            'Opsiyonel bağlam; konuşmanın nerede takıldığını veya bu mesajın hangi durumda geldiğini anlatan kısa nottur.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SelectionChipGroup(
            label: 'Ton',
            value: tone,
            options: const ['Tatlı', 'Cool', 'Net', 'Mesafeli', 'Flörtöz', 'Kibar', 'Sert ama saygılı', 'Kapanış odaklı'],
            onChanged: (value) => setState(() => tone = value),
          ),
          const SizedBox(height: 16),
          SelectionChipGroup(
            label: 'Uzunluk',
            value: responseLength,
            options: const ['Kısa', 'Orta', 'Uzun'],
            onChanged: (value) => setState(() => responseLength = value),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: emojiPreference,
            onChanged: (value) => setState(() => emojiPreference = value),
            title: const Text('Emoji tercihi'),
          ),
          ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () => ref.read(analysisActionProvider.notifier).generateReplies(
                      inputText: messageController.text.trim(),
                      context: contextController.text.trim().isEmpty ? null : contextController.text.trim(),
                      tone: tone,
                      responseLength: responseLength,
                      emojiPreference: emojiPreference,
                    ),
            child: Text(state.isLoading ? 'Üretiliyor...' : 'Cevapları Üret'),
          ),
          const SizedBox(height: 18),
          if (state.isLoading) const SizedBox(height: 280, child: LoadingList()),
          if (state.hasError)
            isInsufficientCreditsError(state.error!)
                ? EmptyStateView(
                    title: 'Kredi yetersiz',
                    description: 'Reklam izleyerek kredi kazanabilir ya da premium seçeneklerine geçebilirsin.',
                    buttonText: 'Seçenekleri Aç',
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const RewardedCreditSheet(),
                    ),
                  )
                : ErrorStateView(
                    message: toUserFacingError(state.error!),
                    onRetry: () => ref.read(analysisActionProvider.notifier).generateReplies(
                          inputText: messageController.text.trim(),
                          context: contextController.text.trim().isEmpty ? null : contextController.text.trim(),
                          tone: tone,
                          responseLength: responseLength,
                          emojiPreference: emojiPreference,
                        ),
                  ),
          if (replyResult != null) ...[
            ...replyResult.aiReplyOptions.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PrimaryCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reply),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: reply));
                              await ref.read(analyticsServiceProvider).logEvent('result_copied', {'source': 'reply_generator'});
                            },
                            child: const Text('Kopyala'),
                          ),
                          OutlinedButton(
                            onPressed: () => context.push('/detail/${replyResult.id}'),
                            child: const Text('Detay'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
