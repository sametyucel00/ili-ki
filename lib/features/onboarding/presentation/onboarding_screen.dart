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
      title: 'Mesajları çözümle',
      description: 'Gelen mesajların olası anlamını kesinlik iddia etmeden, sakin ve dengeli şekilde yorumla.',
      eyebrow: 'Mesaj Analizi',
      metric: '3 yapılandırılmış cevap önerisi',
    ),
    _OnboardingItem(
      title: 'Doğal cevap yazdır',
      description: 'Tatlı, cool, net ya da mesafeli tonda; kullanıma hazır Türkçe cevaplar üret.',
      eyebrow: 'Cevap Yazdır',
      metric: 'Tona göre uyarlanmış 3 alternatif',
    ),
    _OnboardingItem(
      title: 'Durumu stratejik gör',
      description: 'İletişim dinamiğini, kaçınılması gerekenleri ve bir sonraki mantıklı adımı birlikte netleştir.',
      eyebrow: 'Durum Stratejisi',
      metric: 'Özet + risk notu + 3 sonraki adım',
    ),
    _OnboardingItem(
      title: 'Önce dene, sonra bağla',
      description: 'İlk açılışta giriş gerekmez. Analizlerini yaşa, sonra istersen hesabını bağla.',
      eyebrow: 'Guest-First',
      metric: 'Anonim başlangıç + sonradan bağlama',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F3), Color(0xFFF2E4DC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'İlişki Koçu AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF6B5B58),
                        ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    itemCount: items.length,
                    onPageChanged: (value) => setState(() => page = value),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Column(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(36),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFF6DDD3), Color(0xFFC78E84)],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1A6F4A45),
                                    blurRadius: 30,
                                    offset: Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -30,
                                    top: 28,
                                    child: Container(
                                      width: 170,
                                      height: 170,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.14),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: -18,
                                    bottom: -18,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(28),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            item.eyebrow,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: const Color(0xFF4B3432),
                                                ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Center(
                                          child: Container(
                                            width: 220,
                                            height: 220,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(52),
                                            ),
                                            padding: const EdgeInsets.all(20),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(34),
                                              child: Image.asset('assets/branding/app-icon-master.png'),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          item.metric,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: const Color(0xFF5B4441),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            flex: 4,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.84),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontSize: 30,
                                          color: const Color(0xFF352624),
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.description,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: const Color(0xFF6B5B58),
                                        ),
                                  ),
                                  const Spacer(),
                                  const Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _InfoChip(label: 'Belirsizliği azaltır'),
                                      _InfoChip(label: 'Sakin ton'),
                                      _InfoChip(label: 'Zorunlu giriş yok'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
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
                        color: page == index
                            ? const Color(0xFFB56A63)
                            : const Color(0xFFD6C2BB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
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
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.eyebrow,
    required this.metric,
  });

  final String title;
  final String description;
  final String eyebrow;
  final String metric;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECE6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B5B58),
            ),
      ),
    );
  }
}
