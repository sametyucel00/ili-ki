import 'package:flutter/material.dart';
import 'package:iliski_kocu_ai/core/constants/app_links.dart';
import 'package:iliski_kocu_ai/core/utils/link_launcher.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Gizlilik Politikası',
      child: SingleChildScrollView(
        child: PrimaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Gizlilik Özeti'),
              const SizedBox(height: 12),
              const Text(
                'Hisle; analiz geçmişi, kredi durumu, satın alma durumu ve cihazla ilişkili temel uygulama ayarlarını hizmeti sunmak için yerel olarak işler.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Mesaj içerikleri bu sürümde cihaz içinde işlenir ve yerel önbellekte tutulur. Kullanıcı isterse uygulama içinden tüm verilerini temizleyebilir.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Satın alma ve reklam ödülü bilgileri cihaz içinde saklanır. Uygulama silinirse bu veriler kaybolabilir.',
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => openExternalLink(AppLinks.privacyUrl),
                child: const Text('Web sürümünü aç'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
