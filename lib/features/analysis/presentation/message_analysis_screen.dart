import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/utils/error_text.dart';
import 'package:iliski_kocu_ai/features/analysis/presentation/analysis_controller.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';
import 'package:iliski_kocu_ai/shared/widgets/rewarded_credit_sheet.dart';

class MessageAnalysisScreen extends ConsumerStatefulWidget {
  const MessageAnalysisScreen({super.key});

  @override
  ConsumerState<MessageAnalysisScreen> createState() => _MessageAnalysisScreenState();
}

class _MessageAnalysisScreenState extends ConsumerState<MessageAnalysisScreen> {
  final messageController = TextEditingController();
  final contextController = TextEditingController();
  String relationshipType = 'Belirsiz';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisActionProvider);
    ref.listen(analysisActionProvider, (_, next) {
      next.whenData((value) {
        if (value != null && value.type == AnalysisType.messageAnalysis) {
          context.push('/detail/${value.id}');
        }
      });
    });

    return AppScaffold(
      title: 'Mesaj Analizi',
      child: ListView(
        children: [
          const SectionHeader(
            'Mesajı yükle',
            subtitle: 'Mesajı daha sakin ve daha net değerlendirmek için buraya ekle.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: messageController,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'Gelen mesajı buraya yapıştır'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: contextController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Opsiyonel bağlam'),
          ),
          const SizedBox(height: 8),
          Text(
            'Opsiyonel bağlam; bu mesajdan hemen önce ne konuşulduğu, aranızdaki durum veya son gelişme gibi ek bilgidir.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          PremiumDropdownField(
            label: 'İlişki türü',
            helperText: 'Bu seçim yorumun tonunu ve öneri dilini şekillendirir.',
            value: relationshipType,
            items: const ['Belirsiz', 'Flört', 'İlişki', 'Eski partner', 'Arkadaşlık'],
            onChanged: (value) => setState(() => relationshipType = value),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () => ref.read(analysisActionProvider.notifier).analyzeMessage(
                      inputText: messageController.text.trim(),
                      context: contextController.text.trim().isEmpty ? null : contextController.text.trim(),
                      relationshipType: relationshipType,
                    ),
            child: Text(state.isLoading ? 'Analiz ediliyor...' : 'Analiz Et'),
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
                    onRetry: () => ref.read(analysisActionProvider.notifier).analyzeMessage(
                          inputText: messageController.text.trim(),
                          context: contextController.text.trim(),
                          relationshipType: relationshipType,
                        ),
                  ),
        ],
      ),
    );
  }
}
