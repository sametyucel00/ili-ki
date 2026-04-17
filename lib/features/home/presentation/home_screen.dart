import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final config = ref.watch(appConfigProvider);
    final connectivity = ref.watch(connectivityServiceProvider).watchConnection();

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
          physics: const AlwaysScrollableScrollPhysics(),
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
              data: (user) => PrimaryCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugün hazır',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${user?.creditBalance ?? 0} kredi kaldı',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.isPremium == true
                          ? 'Premium aktif. Daha yüksek limitler ve gelişmiş akışlar kullanılabilir.'
                          : 'Kredi ekleyebilir, premium özellikleri inceleyebilir veya reklam izleyerek analiz hakkı kazanabilirsin.',
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
                        OutlinedButton(
                          onPressed: () => context.push('/history'),
                          child: const Text('Geçmişe Git'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(
                height: 156,
                child: PrimaryCard(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => ErrorStateView(
                message: error.toString(),
                onRetry: () => ref.read(authControllerProvider.notifier).refreshProfile(),
              ),
            ),
            const SizedBox(height: 18),
            config.when(
              data: (value) => _DailyLimitCard(config: value),
              loading: () => const SizedBox(
                height: 220,
                child: PrimaryCard(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const PrimaryCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bugünkü limitler'),
                    SizedBox(height: 8),
                    Text('Limit bilgileri şu anda alınamadı. Varsayılan kullanım akışı devam eder.'),
                  ],
                ),
              ),
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
                subtitle: 'Ton, netlik ve olası anlam katmanlarını yorumla',
                icon: Icons.mark_chat_read_outlined,
                onTap: () => context.push('/analysis'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Cevap Yazdır',
                subtitle: 'Doğal ve kullanıma hazır yanıt seçenekleri üret',
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
                subtitle: 'Uzun bir süreci özetleyip yol haritası al',
                icon: Icons.insights_outlined,
                onTap: () => context.push('/strategy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Geçmiş',
                subtitle: 'Önceki analizlerini ve favorilerini aç',
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
        height: 158,
        child: PrimaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.surfaceContainerHighest.withValues(alpha: 0.94),
            tone.secondaryContainer.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bugünkü limitler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Kullanım sınırlarını, günlük haklarını ve kredi maliyetlerini buradan görebilirsin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Günlük kullanım',
                  value: '${config.guestDailyLimit} kez',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Başlangıç kredisi',
                  value: '${config.starterCredits} kredi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Mesaj Analizi',
                  value: '${config.messageAnalysisCost} kredi',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Cevap Yazdır',
                  value: '${config.replyGenerationCost} kredi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Durumu Anlat',
                  value: '${config.situationStrategyCost} kredi',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Günlük ücretsiz kredi',
                  value: '${config.freeDailyCredits} kredi',
                ),
              ),
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
        color: Colors.white.withValues(alpha: 0.72),
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
