import 'package:flutter/material.dart';
import 'package:iliski_kocu_ai/core/config/env.dart';
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
                'Hisle; analiz geçmişi, kredi durumu, satın alma kayıtları, reklam ödülü durumu ve yerel uygulama ayarlarını hizmeti sunmak için cihaz üzerinde saklar.',
              ),
              const SizedBox(height: 12),
              Text(
                'AI analizi açıksa mesaj metni, opsiyonel bağlam, ilişki türü, ton ve uzunluk gibi seçili alanlar ${Env.aiProviderName} ile çalışan üçüncü taraf AI servisine güvenli backend üzerinden gönderilebilir.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu veri yalnızca analiz, cevap önerisi ve durum stratejisi üretmek için kullanılır. Kullanıcı isterse AI veri paylaşım iznini kapatabilir; bu durumda uygulama yerel yorum modunda çalışmaya devam eder.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Uygulama, hassas içerikleri gereksiz düz metin loglarında tutmamaya çalışır. Kullanıcı uygulama içinden tüm verileri silebilir veya yerel profili sıfırlayabilir.',
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
