import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

final dailyUsageProvider = FutureProvider<int>((ref) async {
  return ref.read(localCacheServiceProvider).getTodayUsageCount();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final config = ref.watch(appConfigProvider);
    final usage = ref.watch(dailyUsageProvider);
    final connectivity =
        ref.watch(connectivityServiceProvider).watchConnection();

    return AppScaffold(
      title: AppStrings.appName,
      actions: [
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyUsageProvider);
          await ref.read(authControllerProvider.notifier).refreshProfile();
        },
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
                        'İnternet bağlantısı yok. Kayıtlı içerikler gösterilir.',
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      user?.isPremium == true ? 'Premium aktif' : 'Bugün hazır',
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
                          ? 'Daha yüksek günlük limit ve premium kullanım açık.'
                          : 'Kredi ekleyebilir, premium özellikleri inceleyebilir veya reklam izleyerek analiz hakkı kazanabilirsin.',
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => context.push('/premium'),
                      child: const Text('Premium ve Krediler'),
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
                onRetry: () =>
                    ref.read(authControllerProvider.notifier).refreshProfile(),
              ),
            ),
            const SizedBox(height: 18),
            config.when(
              data: (value) => usage.when(
                data: (usedToday) => _DailyLimitCard(
                  config: value,
                  usedToday: usedToday,
                  isPremium: auth.valueOrNull?.isPremium == true,
                ),
                loading: () => const SizedBox(
                  height: 220,
                  child: PrimaryCard(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => _DailyLimitCard(
                  config: value,
                  usedToday: 0,
                  isPremium: auth.valueOrNull?.isPremium == true,
                ),
              ),
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
                    Text(
                        'Limit bilgileri şu anda alınamadı. Varsayılan kullanım akışı devam eder.'),
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
                title: 'Analiz Geçmişi',
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
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyLimitCard extends StatelessWidget {
  const _DailyLimitCard({
    required this.config,
    required this.usedToday,
    required this.isPremium,
  });

  final dynamic config;
  final int usedToday;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final tone = Theme.of(context).colorScheme;
    final dailyLimit =
        isPremium ? config.linkedDailyLimit : config.guestDailyLimit;
    final remaining = (dailyLimit - usedToday).clamp(0, dailyLimit);

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
            isPremium
                ? 'Premium kullanıcı olarak günlük daha yüksek analiz hakkın var. Sayaç her yeni günde sıfırlanır.'
                : 'Standart kullanım limitlerin burada görünür. Sayaç her yeni günde sıfırlanır.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _MetricGrid(
            metrics: [
              _MetricData('Bugün kalan hak', '$remaining / $dailyLimit'),
              _MetricData(
                  'Başlangıç kredisi', '${config.starterCredits} kredi'),
              _MetricData(
                  'Mesaj Analizi', '${config.messageAnalysisCost} kredi'),
              _MetricData(
                  'Cevap Yazdır', '${config.replyGenerationCost} kredi'),
              _MetricData(
                  'Durumu Anlat', '${config.situationStrategyCost} kredi'),
              _MetricData(
                  'Premium günlük hak', '${config.linkedDailyLimit} kez'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (item) => SizedBox(
                  width: width,
                  height: 92,
                  child: _MetricTile(label: item.label, value: item.value),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value);

  final String label;
  final String value;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
