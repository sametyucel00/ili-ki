import 'package:flutter/material.dart';
import 'package:iliski_kocu_ai/core/constants/app_links.dart';
import 'package:iliski_kocu_ai/core/utils/link_launcher.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Yardım Merkezi',
      child: ListView(
        children: [
          const PrimaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader('Sık sorulanlar'),
                SizedBox(height: 12),
                Text('• Uygulama terapi veya profesyonel danışmanlık yerine geçmez.'),
                Text('• Analizler yorumlayıcıdır; kesinlik iddia etmez.'),
                Text('• Kredi, reklam ödülü ve satın alma hakları hesap durumuna göre değişebilir.'),
                Text('• Hesabını bağlarsan geçmişin ve satın alma geri yükleme hakların korunur.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _HelpLinkTile(
            title: 'Gizlilik Politikası',
            subtitle: 'Veri işleme, saklama ve silme detayları',
            url: AppLinks.privacyUrl,
          ),
          const SizedBox(height: 10),
          _HelpLinkTile(
            title: 'Kullanım Koşulları',
            subtitle: 'Hizmet kapsamı, satın alma ve kullanım kuralları',
            url: AppLinks.termsUrl,
          ),
          const SizedBox(height: 10),
          _HelpLinkTile(
            title: 'Satın alma ve geri yükleme',
            subtitle: 'Abonelikler, kredi paketleri ve geri yükleme',
            url: AppLinks.purchasesUrl,
          ),
          const SizedBox(height: 10),
          _HelpLinkTile(
            title: 'Veri silme ve hesap silme',
            subtitle: 'Hangi veriler silinir, hangi kayıtlar kalabilir',
            url: AppLinks.deletionUrl,
          ),
        ],
      ),
    );
  }
}

class _HelpLinkTile extends StatelessWidget {
  const _HelpLinkTile({
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String title;
  final String subtitle;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new_rounded),
      onTap: () => openExternalLink(url),
    );
  }
}
