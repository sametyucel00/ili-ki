import 'package:flutter/material.dart';
import 'package:iliski_kocu_ai/core/constants/app_links.dart';
import 'package:iliski_kocu_ai/core/utils/link_launcher.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Kullanım Koşulları',
      child: SingleChildScrollView(
        child: PrimaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Hizmet Kapsamı'),
              const SizedBox(height: 12),
              const Text(
                'Hisle, ilişki iletişimi için AI destekli yorum ve cevap önerileri sunar; terapi, tanı, hukuki değerlendirme veya profesyonel danışmanlık hizmeti değildir.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Üretilen içerikler yorumlayıcıdır ve kesinlik iddia etmez. Kullanıcı, önerileri kendi koşulları içinde değerlendirmekten sorumludur.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Abonelikler ve kredi paketleri yalnızca uygulama içi satın alma yoluyla sunulur. Yenileme, fiyat, iptal ve geri yükleme kuralları ilgili mağaza politikalarına tabidir.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Taciz, manipülasyon, tehdit, intikam veya zorlayıcı iletişim biçimlerini destekleyen kullanım bu hizmetin amacı dışındadır.',
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => openExternalLink(AppLinks.termsUrl),
                child: const Text('Web sürümünü aç'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
