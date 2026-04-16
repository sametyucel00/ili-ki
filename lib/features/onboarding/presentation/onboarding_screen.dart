import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iliski_kocu_ai/core/constants/app_strings.dart';
import 'package:iliski_kocu_ai/features/auth/presentation/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  final items = const [
    _OnboardingItem(
      step: '01',
      title: 'Mesajları daha net gör',
      description:
          'Gelen mesajın tonu, açıklığı ve olası anlamı daha düzenli bir çerçevede önüne gelir. Uygulama kesin hüküm vermez, sana daha sakin düşünme alanı açar.',
    ),
    _OnboardingItem(
      step: '02',
      title: 'Cevap seçeneklerini hızlıca hazırla',
      description:
          'Tatlı, net, mesafeli ya da daha yumuşak bir ton seçip kullanıma hazır Türkçe cevaplar alabilirsin.',
    ),
    _OnboardingItem(
      step: '03',
      title: 'Durumu tek yerden toparla',
      description:
          'Uzun uzun düşünmek yerine yaşanan iletişimi özetleyip bir sonraki adım için daha dengeli öneriler görebilirsin.',
    ),
    _OnboardingItem(
      step: '04',
      title: 'Önce dene, hesabını sonra bağla',
      description:
          'İlk açılışta giriş zorunlu değildir. Uygulamayı deneyebilir, istersen daha sonra hesabını bağlayıp geçmişini koruyabilirsin.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: items.length,
                  onPageChanged: (value) => setState(() => page = value),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFF8F3), Color(0xFFF3E6DF)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.step,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: const Color(0xFFBA786D),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: 1.1),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
                          ),
                          const Spacer(),
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
                    duration: const Duration(milliseconds: 220),
                    width: page == index ? 28 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: page == index ? const Color(0xFFB56A63) : const Color(0xFFD6C2BB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                'Hesabını daha sonra bağlayabilirsin.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;
}
