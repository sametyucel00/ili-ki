import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class AccountLinkingScreen extends StatelessWidget {
  const AccountLinkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Devam Et',
      child: ListView(
        children: [
          const PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader('Bu sürümde giriş gerekmiyor'),
                SizedBox(height: 12),
                Text(
                  'Hisle şu anda doğrudan devam mantığıyla çalışıyor. Premium ve kredi satın alma akışları yine kullanılabilir.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }
}
