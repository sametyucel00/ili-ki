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

  Future<void> _deleteSingle(String id) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kaydı sil'),
            content: const Text(
              'Bu analiz geçmişten silinecek. Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await ref.read(historyRepositoryProvider).deleteHistoryItem(id);
    ref.invalidate(historyProvider(favoritesOnly));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçmiş kaydı silindi.')),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tüm geçmişi sil'),
            content: const Text(
              'Tüm analiz geçmişi silinecek. Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Tümünü sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await ref.read(historyRepositoryProvider).clearAllHistory();
    ref.invalidate(historyProvider(favoritesOnly));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm analiz geçmişi silindi.')),
      );
    }
  }

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
          tooltip: 'Tümünü sil',
          onPressed: () => _clearAll(),
          icon: const Icon(Icons.delete_sweep_rounded),
        ),
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
            itemBuilder: (context, index) => AnalysisListTile(
              item: items[index],
              onDelete: () => _deleteSingle(items[index].id),
            ),
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
