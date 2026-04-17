import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'İsimsiz kullanıcı';
    final expiry = user?.subscriptionExpiryDate;

    return AppScaffold(
      title: 'Profil ve Ayarlar',
      child: ListView(
        children: [
          PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  user?.isPremium == true
                      ? 'Premium aktif. Bu cihazda satın alımlar ve analiz geçmişi kullanılabilir.'
                      : 'Hisle doğrudan kullanım odaklı çalışır. Kullanım verileri bu cihazda tutulur.',
                ),
                if (user?.isPremium == true && expiry != null) ...[
                  const SizedBox(height: 8),
                  Text(
                      'Premium bitişi: ${DateFormat('d MMMM yyyy', 'tr_TR').format(expiry)}'),
                ],
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () =>
                      _showRenameDialog(context, ref, user?.displayName),
                  child: const Text('İsmi değiştir'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await _showConfirmDialog(
                context,
                title: 'Tüm verileri sil',
                description:
                    'Analiz geçmişin, favorilerin, günlük kullanım sayaçların ve yerel ayarların silinecek. Bu işlem geri alınamaz.',
                confirmText: 'Sil',
              );
              if (confirmed != true) {
                return;
              }
              await ref.read(authControllerProvider.notifier).deleteData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veriler temizlendi.')),
                );
              }
            },
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Tüm verileri sil'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await _showConfirmDialog(
                context,
                title: 'Hesabı sil',
                description:
                    'Bu cihazdaki yerel profil kapatılacak ve yerine yeni bir profil oluşturulacak. İsim, premium durumu, geçmiş ve kredi bilgileri sıfırlanır.',
                confirmText: 'Devam et',
              );
              if (confirmed != true) {
                return;
              }
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Yeni bir yerel profil oluşturuldu.')),
                );
              }
            },
            icon: const Icon(Icons.person_remove_outlined),
            label: const Text('Hesabı sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref, String? currentName) async {
    final controller = TextEditingController(text: currentName ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Görünen ismi değiştir'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Örn. Melis',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () async {
              final nextName = controller.text.trim();
              if (nextName.isEmpty) {
                return;
              }
              await ref
                  .read(authControllerProvider.notifier)
                  .updateDisplayName(nextName);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
