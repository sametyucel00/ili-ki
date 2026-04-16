import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';
import 'package:iliski_kocu_ai/shared/widgets/rewarded_credit_sheet.dart';

final completedAnalysisCountProvider = FutureProvider<int>((ref) {
  return ref.read(analysisRepositoryProvider).getCompletedAnalysisCount();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(notificationServiceProvider).initialize();
      await ref.read(analyticsServiceProvider).logEvent('home_opened');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final config = ref.watch(appConfigProvider);
    final connectivity = ref.watch(connectivityServiceProvider).watchConnection();
    final completedCount = ref.watch(completedAnalysisCountProvider);

    return AppScaffold(
      title: AppStrings.appName,
      actions: [
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => ref.read(authControllerProvider.notifier).refreshProfile(),
        child: ListView(
          children: [
            StreamBuilder<bool>(
              stream: connectivity,
              initialData: true,
              builder: (context, snapshot) {
                if (snapshot.data ?? true) {
                  return const SizedBox.shrink();
                }
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: InfoBanner(
                    icon: Icons.wifi_off_rounded,
                    message: 'İnternet bağlantısı yok. Kayıtlı içerikler gösterilir, yeni analiz için bağlantı gerekir.',
                  ),
                );
              },
            ),
            auth.when(
              data: (user) => config.when(
                data: (appConfig) => completedCount.when(
                  data: (count) => Column(
                    children: [
                      PrimaryCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.isGuest == true ? 'Misafir modundasın' : 'Hesabın bağlı',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${user?.creditBalance ?? 0} kredi kaldı. Analizlerin sakin, dengeli ve Türkçe hazırlanır.',
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton(
                                  onPressed: () async {
                                    await ref.read(analyticsServiceProvider).logEvent('paywall_viewed', {'source': 'home'});
                                    if (context.mounted) {
                                      context.push('/premium');
                                    }
                                  },
                                  child: const Text('Premium Gör'),
                                ),
                                if (ref.read(paywallServiceProvider).shouldPromptForLink(
                                  user: user,
                                  completedAnalyses: count,
                                  enteringHistory: false,
                                  attemptingPurchase: false,
                                ))
                                  OutlinedButton(
                                    onPressed: () async {
                                      await ref.read(analyticsServiceProvider).logEvent('account_link_prompt_shown', {'source': 'home_card'});
                                      if (context.mounted) {
                                        context.push('/link-account');
                                      }
                                    },
                                    child: const Text('Hesabını Bağla'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (ref.read(paywallServiceProvider).shouldShowSoftPaywall(
                        user: user,
                        config: appConfig,
                        completedAnalyses: count,
                      )) ...[
                        const SizedBox(height: 12),
                        InfoBanner(
                          icon: Icons.ondemand_video_rounded,
                          message: 'Kredin bittiğinde istersen 1 reklam izle → 1 analiz kazan seçeneğini kullanabilirsin.',
                          actionLabel: 'Seçenekleri Aç',
                          onAction: () async {
                            await ref.read(analyticsServiceProvider).logEvent('paywall_viewed', {'source': 'soft_banner'});
                            if (context.mounted) {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const RewardedCreditSheet(),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  loading: () => const SizedBox(height: 140, child: PrimaryCard(child: Center(child: CircularProgressIndicator()))),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                loading: () => const SizedBox(height: 140, child: PrimaryCard(child: Center(child: CircularProgressIndicator()))),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox(height: 140, child: PrimaryCard(child: Center(child: CircularProgressIndicator()))),
              error: (error, _) => ErrorStateView(
                message: error.toString(),
                onRetry: () => ref.read(authControllerProvider.notifier).refreshProfile(),
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeader('Hızlı başlat', subtitle: 'İhtiyacın olan akışı tek dokunuşla aç.'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _QuickActionCard(
                  title: 'Mesaj Analizi',
                  icon: Icons.mark_chat_read_outlined,
                  onTap: () => context.push('/analysis'),
                ),
                _QuickActionCard(
                  title: 'Cevap Yazdır',
                  icon: Icons.auto_fix_high_outlined,
                  onTap: () => context.push('/replies'),
                ),
                _QuickActionCard(
                  title: 'Durumu Anlat',
                  icon: Icons.insights_outlined,
                  onTap: () => context.push('/strategy'),
                ),
                _QuickActionCard(
                  title: 'Geçmiş',
                  icon: Icons.history_rounded,
                  onTap: () => context.push('/history'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            config.when(
              data: (value) => PrimaryCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Bugünkü limitler'),
                    const SizedBox(height: 12),
                    Text('Misafir günlük limit: ${value.guestDailyLimit} kullanım'),
                    Text('Bağlı hesap günlük limit: ${value.linkedDailyLimit} kullanım'),
                    Text('Mesaj analizi: ${value.messageAnalysisCost} kredi'),
                    Text('Cevap üretimi: ${value.replyGenerationCost} kredi'),
                    Text('Durum stratejisi: ${value.situationStrategyCost} kredi'),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 18),
            const SectionHeader('Örnek kullanımlar'),
            const SizedBox(height: 12),
            const _ExampleCard(text: '“Bugün biraz yoğundum, sonra konuşalım.”'),
            const SizedBox(height: 10),
            const _ExampleCard(text: '“Sence fazla mı yazdım, yoksa geri mi çekileyim?”'),
            const SizedBox(height: 18),
            const Text(AppStrings.disclaimer, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: PrimaryCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(child: Text(text));
  }
}
