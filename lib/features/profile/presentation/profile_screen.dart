import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_links.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/core/utils/link_launcher.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    return AppScaffold(
      title: 'Profil ve Ayarlar',
      child: ListView(
        children: [
          PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? 'İsimsiz kullanıcı', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(user?.email ?? 'Misafir oturumu'),
                const SizedBox(height: 8),
                Text('Dil: ${user?.language ?? 'tr'}'),
                Text('Bildirimler: ${user?.notificationEnabled == true ? 'Açık' : 'Kapalı'}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Gizlilik Politikası'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/privacy'),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Yardım Merkezi'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/help'),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Kullanım Koşulları'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/terms'),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Hesabını bağla'),
            subtitle: const Text('Geçmişini koru ve satın alımları geri yükle'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/link-account'),
          ),
          const SizedBox(height: 10),
          const PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader('Yasal ve gizlilik'),
                SizedBox(height: 12),
                Text(AppStrings.disclaimer),
                SizedBox(height: 8),
                Text('Gizlilik, kullanım koşulları, satın alma ve veri silme detayları uygulama içindeki ekranlardan ve web hukuk merkezinden erişilebilir.'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => openExternalLink(AppLinks.helpUrl),
            child: const Text('Web yardım merkezini aç'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              await ref.read(analyticsServiceProvider).logEvent('account_deletion_started', {'scope': 'data'});
              await ref.read(authControllerProvider.notifier).deleteData();
              await ref.read(analyticsServiceProvider).logEvent('account_deletion_completed', {'scope': 'data'});
            },
            child: const Text('Tüm verileri sil'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              await ref.read(analyticsServiceProvider).logEvent('account_deletion_started', {'scope': 'account'});
              await ref.read(authControllerProvider.notifier).deleteAccount();
              await ref.read(analyticsServiceProvider).logEvent('account_deletion_completed', {'scope': 'account'});
            },
            child: const Text('Hesabı sil'),
          ),
        ],
      ),
    );
  }
}
