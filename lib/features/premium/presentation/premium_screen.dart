import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iliski_kocu_ai/core/constants/app_links.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/core/utils/link_launcher.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/features/premium/data/premium_repository.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';
import 'package:iliski_kocu_ai/shared/widgets/rewarded_credit_sheet.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

final productsProvider =
    FutureProvider.autoDispose<List<ProductDetails>>((ref) async {
  return ref.read(premiumRepositoryProvider).loadProducts();
});

final premiumProductIdProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  return ref.read(localCacheServiceProvider).getLocalPremiumProductId();
});

final purchaseHistoryProvider =
    FutureProvider.autoDispose<List<PurchaseHistoryItem>>((ref) {
  return ref.read(premiumRepositoryProvider).loadPurchaseHistory();
});

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(premiumRepositoryProvider).attachPurchaseListener(
        onApplied: (feedback) async {
          await ref.read(authControllerProvider.notifier).refreshProfile();
          ref.invalidate(premiumProductIdProvider);
          ref.invalidate(purchaseHistoryProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(feedback.message)),
            );
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final offerings = ref.watch(productsProvider);
    final history = ref.watch(purchaseHistoryProvider);
    final config = ref.watch(appConfigProvider).valueOrNull;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final activeProductId = ref.watch(premiumProductIdProvider).valueOrNull;
    final expiry = user?.subscriptionExpiryDate;
    final remainingDays =
        expiry == null ? null : expiry.difference(DateTime.now()).inDays + 1;

    return AppScaffold(
      title: 'Premium ve Krediler',
      child: ListView(
        children: [
          PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      user?.isPremium == true
                          ? Icons.workspace_premium_rounded
                          : Icons.lock_open_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user?.isPremium == true
                            ? 'Premium aktif'
                            : 'Standart kullanım',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Mevcut kredi: ${user?.creditBalance ?? 0}'),
                const SizedBox(height: 8),
                Text(
                  user?.isPremium == true
                      ? 'Günlük premium limitlerin açık.'
                      : 'Premium ile daha yüksek günlük limit ve gelişmiş kullanım açılır.',
                ),
                if (user?.isPremium == true && activeProductId != null) ...[
                  const SizedBox(height: 8),
                  Text('Aktif paket: ${_planTitle(activeProductId)}'),
                ],
                if (user?.isPremium == true && expiry != null) ...[
                  const SizedBox(height: 8),
                  Text(
                      'Bitiş: ${DateFormat('d MMMM yyyy', 'tr_TR').format(expiry)}'),
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
                Text(
                  '• Standart kullanım: günlük ${config?.guestDailyLimit ?? 10} analiz hakkı',
                ),
                Text(
                  '• Premium: günlük ${config?.linkedDailyLimit ?? 20} analiz hakkı',
                ),
                const Text('• Kredi paketleri: hızlı şekilde ek analiz hakkı'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Abonelik bilgileri'),
                const SizedBox(height: 12),
                const Text(
                  'Premium Aylık ve Premium Yıllık planları otomatik yenilenen aboneliktir. Güncel fiyatlar satın al butonlarında mağaza fiyatı olarak gösterilir.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik yenilenir. Yönetim ve iptal işlemleri App Store veya Google Play abonelik ayarlarından yapılır.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => openExternalLink(AppLinks.termsUrl),
                      child: const Text('Kullanım Koşulları (EULA)'),
                    ),
                    OutlinedButton(
                      onPressed: () => openExternalLink(AppLinks.privacyUrl),
                      child: const Text('Gizlilik Politikası'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          offerings.when(
            data: (data) => _PackagesCard(
              products: data,
              activeProductId: activeProductId,
            ),
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ErrorStateView(
              message: 'Paketler şu anda yüklenemedi. Tekrar deneyebilirsin.',
              onRetry: () => ref.invalidate(productsProvider),
            ),
          ),
          const SizedBox(height: 16),
          history.when(
            data: (items) => _PurchaseHistoryCard(items: items),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
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

class _PackagesCard extends ConsumerWidget {
  const _PackagesCard({
    required this.products,
    required this.activeProductId,
  });

  final List<ProductDetails> products;
  final String? activeProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Paketler'),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Text(
                'Paketler şu anda bulunamadı. Mağaza ürünleri tanımlandıktan sonra burada görünür.')
          else
            ...products.map(
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
                            final feedback = await ref
                                .read(premiumRepositoryProvider)
                                .buyProduct(product);
                            if (feedback.didChangeEntitlement) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .refreshProfile();
                              ref.invalidate(productsProvider);
                              ref.invalidate(premiumProductIdProvider);
                              ref.invalidate(purchaseHistoryProvider);
                            }
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
              final feedback =
                  await ref.read(premiumRepositoryProvider).restore();
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
    if (isPremiumPlan &&
        activeProductId != null &&
        activeProductId.contains('.premium.')) {
      return 'Paketi Değiştir';
    }
    return product.price;
  }
}

class _PurchaseHistoryCard extends StatelessWidget {
  const _PurchaseHistoryCard({required this.items});

  final List<PurchaseHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Satın alma ve kredi geçmişi'),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('Henüz satın alma veya kredi işlemi yok.')
          else
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(item.note),
                trailing:
                    Text(DateFormat('d MMM', 'tr_TR').format(item.createdAt)),
              ),
            ),
        ],
      ),
    );
  }
}
