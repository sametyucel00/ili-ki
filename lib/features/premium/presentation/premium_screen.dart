import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/config/env.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';
import 'package:iliski_kocu_ai/shared/widgets/rewarded_credit_sheet.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

final productsProvider = FutureProvider.autoDispose<List<ProductDetails>>((ref) async {
  ref.read(premiumRepositoryProvider).attachPurchaseListener();
  return ref.read(premiumRepositoryProvider).loadProducts();
});

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerings = ref.watch(productsProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isAndroidSimulation = Env.useAndroidPurchaseSimulation;

    return AppScaffold(
      title: 'Premium ve Krediler',
      child: ListView(
        children: [
          PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut kredi: ${user?.creditBalance ?? 0}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  user?.isPremium == true
                      ? 'Premium aktif'
                      : 'Premium ile daha derin analiz ve yuksek limit acilir',
                ),
                if (user?.isGuest == true) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push('/link-account'),
                    child: Text(
                      isAndroidSimulation
                          ? 'Hesabini baglamak istersen sonra da yapabilirsin'
                          : 'Satin alma oncesi hesabini bagla',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const RewardedCreditSheet(),
                  ),
                  child: const Text('1 reklam izle -> 1 analiz kazan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Plan karsilastirmasi'),
                const SizedBox(height: 12),
                const Text('- Misafir: sinirli kredi, lokal gecmis'),
                const Text('- Bagli kullanici: senkron, geri yukleme, bonus kredi'),
                const Text('- Premium: daha yuksek limit, derin analiz, uzun gecmis'),
                if (isAndroidSimulation) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Android test modu acik. Bu ekrandaki satin alma butonlarina bastiginda islem dogrudan hesabina uygulanir.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          offerings.when(
            data: (data) => PrimaryCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('Paketler'),
                  const SizedBox(height: 12),
                  if (data.isEmpty)
                    const Text(
                      'Store urunleri henuz bulunamadi. Product IDlerini magazada ayni isimlerle tanimla.',
                    )
                  else
                    ...data.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(product.title),
                          subtitle: Text(product.description),
                          trailing: FilledButton(
                            onPressed: () async {
                              if (user?.isGuest == true && !isAndroidSimulation) {
                                await ref.read(analyticsServiceProvider).logEvent(
                                  'account_link_prompt_shown',
                                  {'source': 'purchase_attempt'},
                                );
                                if (context.mounted) {
                                  context.push('/link-account');
                                }
                                return;
                              }
                              await ref.read(premiumRepositoryProvider).buyProduct(product);
                              await ref.read(authControllerProvider.notifier).refreshProfile();
                            },
                            child: Text(product.price),
                          ),
                        ),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(premiumRepositoryProvider).restore();
                      await ref.read(authControllerProvider.notifier).refreshProfile();
                    },
                    child: const Text('Satin alimlari geri yukle'),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 220, child: LoadingList()),
            error: (error, _) => ErrorStateView(
              message: error.toString(),
              onRetry: () => ref.invalidate(productsProvider),
            ),
          ),
        ],
      ),
    );
  }
}
