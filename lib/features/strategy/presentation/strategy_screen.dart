import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/utils/error_text.dart';
import 'package:iliski_kocu_ai/features/analysis/presentation/analysis_controller.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';
import 'package:iliski_kocu_ai/shared/widgets/rewarded_credit_sheet.dart';

class StrategyScreen extends ConsumerStatefulWidget {
  const StrategyScreen({super.key});

  @override
  ConsumerState<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends ConsumerState<StrategyScreen> {
  final situationController = TextEditingController();
  String relationshipType = 'Belirsiz';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisActionProvider);
    ref.listen(analysisActionProvider, (_, next) {
      next.whenData((value) {
        if (value != null && value.type == AnalysisType.situationStrategy) {
          context.push('/detail/${value.id}');
        }
      });
    });

    return AppScaffold(
      title: 'Durumu Anlat',
      child: ListView(
        children: [
          const SectionHeader(
            'İletişim dinamiğini toparla',
            subtitle: 'Uzun anlatımı özetleyen ve bir sonraki adıma odaklanan yorumlar al.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: situationController,
            maxLines: 9,
            decoration: const InputDecoration(hintText: 'Durumu detaylı anlat'),
          ),
          const SizedBox(height: 16),
          PremiumDropdownField(
            label: 'İlişki türü',
            helperText: 'Öneriler, seçtiğin ilişki çerçevesine göre dengelenir.',
            value: relationshipType,
            items: const ['Belirsiz', 'Flört', 'İlişki', 'Eski partner', 'Arkadaşlık'],
            onChanged: (value) => setState(() => relationshipType = value),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () => ref.read(analysisActionProvider.notifier).createStrategy(
                      inputText: situationController.text.trim(),
                      relationshipType: relationshipType,
                    ),
            child: Text(state.isLoading ? 'Yorumlanıyor...' : 'Analiz Et'),
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
                    onRetry: () => ref.read(analysisActionProvider.notifier).createStrategy(
                          inputText: situationController.text.trim(),
                          relationshipType: relationshipType,
                        ),
                  ),
        ],
      ),
    );
  }
}
