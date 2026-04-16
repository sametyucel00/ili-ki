import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class AccountLinkingScreen extends ConsumerStatefulWidget {
  const AccountLinkingScreen({super.key});

  @override
  ConsumerState<AccountLinkingScreen> createState() => _AccountLinkingScreenState();
}

class _AccountLinkingScreenState extends ConsumerState<AccountLinkingScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(analyticsServiceProvider).logEvent('account_link_prompt_shown', {'source': 'link_screen'}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return AppScaffold(
      title: 'Hesabını Bağla',
      child: ListView(
        children: [
          const PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader('Neden bağlamalısın?'),
                SizedBox(height: 12),
                Text('• Geçmişin güvende kalır'),
                Text('• Cihazlar arasında senkron açılır'),
                Text('• Satın alımları geri yükleyebilirsin'),
                Text('• Bonus kredi kazanırsın'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    await ref.read(authControllerProvider.notifier).linkGoogle();
                    if (context.mounted && !ref.read(authControllerProvider).hasError) {
                      context.pop();
                    }
                  },
            child: const Text('Google ile Devam Et'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    await ref.read(authControllerProvider.notifier).linkApple();
                    if (context.mounted && !ref.read(authControllerProvider).hasError) {
                      context.pop();
                    }
                  },
            child: const Text('Apple ile Devam Et'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: 'E-posta'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Şifre'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .linkEmail(emailController.text.trim(), passwordController.text.trim());
                    if (context.mounted && !ref.read(authControllerProvider).hasError) {
                      context.pop();
                    }
                  },
            child: const Text('E-posta ile Devam Et'),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Şimdilik daha sonra'),
          ),
          if (state.hasError) ...[
            const SizedBox(height: 12),
            Text(state.error.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
