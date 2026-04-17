import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class RewardedCreditSheet extends ConsumerStatefulWidget {
  const RewardedCreditSheet({super.key});

  @override
  ConsumerState<RewardedCreditSheet> createState() => _RewardedCreditSheetState();
}

class _RewardedCreditSheetState extends ConsumerState<RewardedCreditSheet> {
  bool loading = false;
  String? status;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    if (user?.isPremium == true) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              'Premium aktif',
              subtitle: 'Premium kullanıcılar için reklam izleme seçeneği kapalıdır.',
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Kredi kazan',
            subtitle: 'İstersen reklam izle ya da premium ve kredi paketlerine geç.',
          ),
          const SizedBox(height: 16),
          const PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1 reklam izle → 1 analiz kazan'),
                SizedBox(height: 8),
                Text('Reklam izlemek tamamen isteğe bağlıdır. Ödül kazanılınca kredi hesabına işlenir.'),
              ],
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 12),
            Text(status!),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
                    setState(() {
                      loading = true;
                      status = null;
                    });
                    await ref.read(rewardedAdServiceProvider).initialize();
                    final success = await ref.read(rewardedAdServiceProvider).showRewardedAd(() async {
                      await ref.read(premiumRepositoryProvider).grantRewardedCredit();
                      await ref.read(authControllerProvider.notifier).refreshProfile();
                    });
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      loading = false;
                      status = success
                          ? '1 analiz hakkın hesabına eklendi.'
                          : 'Reklam şu anda açılamadı. Biraz sonra tekrar deneyebilirsin.';
                    });
                  },
            child: Text(loading ? 'Reklam hazırlanıyor...' : '1 Reklam İzle, 1 Analiz Kazan'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/premium');
            },
            child: const Text('Kredi ve premium seçeneklerini gör'),
          ),
        ],
      ),
    );
  }
}
