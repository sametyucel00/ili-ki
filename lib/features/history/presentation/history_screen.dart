import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/core/utils/error_text.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

final historyProvider =
    FutureProvider.autoDispose.family((ref, bool favoritesOnly) {
  return ref
      .read(historyRepositoryProvider)
      .getHistory(favoritesOnly: favoritesOnly);
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(analyticsServiceProvider).logEvent('history_opened'));
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider(favoritesOnly));

    return AppScaffold(
      title: 'Geçmiş',
      actions: [
        IconButton(
          onPressed: () => setState(() => favoritesOnly = !favoritesOnly),
          icon: Icon(favoritesOnly ? Icons.favorite : Icons.favorite_border),
        ),
      ],
      child: history.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateView(
              title: 'Henüz kayıt yok',
              description: 'İlk analizi yaptığında burada göreceksin.',
              buttonText: 'Analize Git',
              onPressed: () => context.push('/analysis'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                AnalysisListTile(item: items[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          title: 'Geçmiş yüklenemedi',
          message: toUserFacingError(error),
          onRetry: () => ref.invalidate(historyProvider(favoritesOnly)),
        ),
      ),
    );
  }
}
