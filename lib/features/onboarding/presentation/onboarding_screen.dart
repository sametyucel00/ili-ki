import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  final items = const [
    ('Mesajları çözümle', 'Gelen mesajların olası anlamını sakin ve dengeli şekilde yorumla.'),
    ('Doğal cevap yazdır', 'Türkçe, kısa ve doğal cevap alternatifleri üret.'),
    ('Durumu stratejik gör', 'İletişim dinamiğini, kaçınılması gerekenleri ve sonraki adımları gör.'),
    ('Önce dene, sonra bağla', 'Hesap açma zorunlu değil. İstersen daha sonra hesabını bağlarsın.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                height: 360,
                child: PageView.builder(
                  controller: controller,
                  itemCount: items.length,
                  onPageChanged: (value) => setState(() => page = value),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return PrimaryCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.favorite_rounded, size: 34),
                          ),
                          const SizedBox(height: 24),
                          Text(item.$1, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 12),
                          Text(item.$2, style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: page == index ? 26 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: page == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).completeOnboarding();
                  if (context.mounted) {
                    context.go('/home');
                  }
                },
                child: const Text('Hemen Dene'),
              ),
              const SizedBox(height: 12),
              const Text(
                '${AppStrings.disclaimer}\nHesabını daha sonra bağlayabilirsin.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
