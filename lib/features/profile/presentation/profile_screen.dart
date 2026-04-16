import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                Text(
                  user?.displayName?.trim().isNotEmpty == true ? user!.displayName! : 'İsimsiz kullanıcı',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(user?.email ?? 'Misafir oturumu'),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => _showRenameDialog(context, ref, user?.displayName),
                  child: const Text('İsmi değiştir'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Hesabını bağla'),
            subtitle: const Text('Geçmişini koru ve satın alımları geri yükle'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/link-account'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).deleteData();
            },
            child: const Text('Tüm verileri sil'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).deleteAccount();
            },
            child: const Text('Hesabı sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, String? currentName) async {
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
              await ref.read(authControllerProvider.notifier).updateDisplayName(nextName);
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
}
