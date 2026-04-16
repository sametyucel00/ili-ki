import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

final completedAnalysisCountProvider = FutureProvider<int>((ref) {
  return ref.read(analysisRepositoryProvider).getCompletedAnalysisCount();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    message:
                        'İnternet bağlantısı yok. Kayıtlı içerikler gösterilir, yeni analiz için bağlantı gerekir.',
                  ),
                );
              },
            ),
            const SectionHeader(
              'Hızlı başlat',
              subtitle: 'İhtiyacın olan akışı tek dokunuşla aç.',
            ),
            const SizedBox(height: 12),
            const _QuickActionRows(),
            const SizedBox(height: 18),
            auth.when(
              data: (user) => completedCount.when(
                data: (count) => PrimaryCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.isGuest == true ? 'Misafir modundasın' : 'Hesabın hazır',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${user?.creditBalance ?? 0} kredi kaldı',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.isGuest == true
                            ? 'İstersen önce uygulamayı kullan, sonra hesabını bağlayıp geçmişini koru.'
                            : 'Geçmişin ve kullanım durumun hesabında tutulur.',
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton(
                            onPressed: () => context.push('/premium'),
                            child: const Text('Premium ve Krediler'),
                          ),
                          if (ref.read(paywallServiceProvider).shouldPromptForLink(
                            user: user,
                            completedAnalyses: count,
                            enteringHistory: false,
                            attemptingPurchase: false,
                          ))
                            OutlinedButton(
                              onPressed: () => context.push('/link-account'),
                              child: const Text('Hesabını Bağla'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(
                  height: 140,
                  child: PrimaryCard(child: Center(child: CircularProgressIndicator())),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox(
                height: 140,
                child: PrimaryCard(child: Center(child: CircularProgressIndicator())),
              ),
              error: (error, _) => ErrorStateView(
                message: error.toString(),
                onRetry: () => ref.read(authControllerProvider.notifier).refreshProfile(),
              ),
            ),
            const SizedBox(height: 18),
            config.when(
              data: (value) => _DailyLimitCard(config: value),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionRows extends StatelessWidget {
  const _QuickActionRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Mesaj Analizi',
                subtitle: 'Mesajın tonunu ve netliğini yorumla',
                icon: Icons.mark_chat_read_outlined,
                onTap: () => context.push('/analysis'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Cevap Yazdır',
                subtitle: 'Hazır cevap seçenekleri oluştur',
                icon: Icons.auto_fix_high_outlined,
                onTap: () => context.push('/replies'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Durumu Anlat',
                subtitle: 'Uzun durumu özetleyip yön bul',
                icon: Icons.insights_outlined,
                onTap: () => context.push('/strategy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Geçmiş',
                subtitle: 'Önceki analizlerine geri dön',
                icon: Icons.history_rounded,
                onTap: () => context.push('/history'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 150,
        child: PrimaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyLimitCard extends StatelessWidget {
  const _DailyLimitCard({required this.config});

  final dynamic config;

  @override
  Widget build(BuildContext context) {
    final tone = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tone.surfaceContainerHighest.withValues(alpha: 0.95),
            tone.secondaryContainer.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bugünkü limitler', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Kullanım sınırlarını ve kredi maliyetlerini buradan görebilirsin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _MetricTile(label: 'Misafir', value: '${config.guestDailyLimit} kullanım')),
              const SizedBox(width: 12),
              Expanded(child: _MetricTile(label: 'Bağlı hesap', value: '${config.linkedDailyLimit} kullanım')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MetricTile(label: 'Mesaj Analizi', value: '${config.messageAnalysisCost} kredi')),
              const SizedBox(width: 12),
              Expanded(child: _MetricTile(label: 'Cevap Yazdır', value: '${config.replyGenerationCost} kredi')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MetricTile(label: 'Durumu Anlat', value: '${config.situationStrategyCost} kredi')),
              const SizedBox(width: 12),
              Expanded(child: _MetricTile(label: 'Reklam ödülü', value: '${config.rewardedAdCredits} kredi')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
