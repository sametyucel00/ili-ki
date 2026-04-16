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
              const Text('İlişki Koçu AI; analiz geçmişi, kredi durumu, hesap bağlantısı, satın alma ve cihazla ilişkili teknik olay kayıtlarını hizmeti sunmak için işler.'),
              const SizedBox(height: 12),
              const Text('Mesaj içerikleri AI işlemesi için backend tarafına gönderilir; mümkün olduğunda içerik minimizasyonu uygulanır ve hata kayıtlarında düz mesaj içeriği tutulmamalıdır.'),
              const SizedBox(height: 12),
              const Text('Misafir kullanımda sınırlı yerel önbellek bulunur. Hesap bağlandığında geçmiş, krediler ve satın alma ilişkili durum bulut senkronu için Firebase üzerinde saklanabilir.'),
              const SizedBox(height: 12),
              const Text('Kullanıcı uygulama içinden verilerini silebilir, hesabını silebilir ve satın alma geri yükleme talebinde bulunabilir. Yasal yükümlülükler nedeniyle bazı işlem kayıtları sınırlı süre tutulabilir.'),
              const SizedBox(height: 12),
              const Text('Bildirimler yalnızca kullanıcı izniyle etkinleştirilir. Reklam izleme ödülü kullanılırsa reklam tedarikçisi cihaz düzeyinde teknik sinyaller işleyebilir.'),
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
