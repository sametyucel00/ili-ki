import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

final premiumProductIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  return ref.read(localCacheServiceProvider).getLocalPremiumProductId();
});

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerings = ref.watch(productsProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final activeProductId = ref.watch(premiumProductIdProvider).valueOrNull;
    final isAndroidSimulation = Env.useAndroidPurchaseSimulation;
    final expiry = user?.subscriptionExpiryDate;
    final remainingDays = expiry == null ? null : expiry.difference(DateTime.now()).inDays + 1;

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
                      : 'Premium ile daha derin analiz ve daha yüksek limitler açılır.',
                ),
                if (user?.isPremium == true && activeProductId != null) ...[
                  const SizedBox(height: 8),
                  Text('Aktif paket: ${_planTitle(activeProductId)}'),
                ],
                if (user?.isPremium == true && expiry != null) ...[
                  const SizedBox(height: 8),
                  Text('Bitiş: ${DateFormat('d MMMM yyyy', 'tr_TR').format(expiry)}'),
                  Text(
                    'Kalan süre: ${remainingDays != null && remainingDays > 0 ? '$remainingDays gün' : 'Bugün sona eriyor'}',
                  ),
                ],
                if (user?.isPremium != true) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const RewardedCreditSheet(),
                    ),
                    child: const Text('1 reklam izle → 1 analiz kazan'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Plan karşılaştırması'),
                const SizedBox(height: 12),
                const Text('• Standart kullanım: günlük 3 analiz hakkı'),
                const Text('• Premium: günlük 10 analiz hakkı'),
                const Text('• Kredi paketleri: hızlı şekilde ek analiz hakkı'),
                if (isAndroidSimulation) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Android test modu açık. Bu ekrandaki satın alma butonlarına bastığında işlem doğrudan hesabına uygulanır.',
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
                      'Store ürünleri henüz bulunamadı. Product IDlerini mağazada aynı isimlerle tanımla.',
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
                            onPressed: product.id == activeProductId
                                ? null
                                : () async {
                                    final feedback =
                                        await ref.read(premiumRepositoryProvider).buyProduct(product);
                                    await ref.read(authControllerProvider.notifier).refreshProfile();
                                    ref.invalidate(productsProvider);
                                    ref.invalidate(premiumProductIdProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(feedback.message)),
                                      );
                                    }
                                  },
                            child: Text(_buttonTextForProduct(
                              product: product,
                              activeProductId: activeProductId,
                            )),
                          ),
                        ),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: () async {
                      final feedback = await ref.read(premiumRepositoryProvider).restore();
                      await ref.read(authControllerProvider.notifier).refreshProfile();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(feedback.message)),
                        );
                      }
                    },
                    child: const Text('Satın alımları geri yükle'),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ErrorStateView(
              message: error.toString(),
              onRetry: () => ref.invalidate(productsProvider),
            ),
          ),
        ],
      ),
    );
  }

  String _buttonTextForProduct({
    required ProductDetails product,
    required String? activeProductId,
  }) {
    if (product.id == activeProductId) {
      return 'Aktif';
    }
    final isPremiumPlan = product.id.contains('.premium.');
    if (isPremiumPlan && activeProductId != null && activeProductId.contains('.premium.')) {
      return 'Paketi Değiştir';
    }
    return product.price;
  }

  String _planTitle(String productId) {
    if (productId.endsWith('.yearly')) {
      return 'Premium Yıllık';
    }
    if (productId.endsWith('.monthly')) {
      return 'Premium Aylık';
    }
    return 'Premium';
  }
}
