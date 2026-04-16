import 'package:flutter/material.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Gizlilik Politikası',
      child: SingleChildScrollView(
        child: PrimaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader('Veri kullanımı'),
              SizedBox(height: 12),
              Text('İlişki Koçu AI; analiz geçmişi, kredi durumu ve hesap bilgilerini hizmeti sunmak için işler.'),
              SizedBox(height: 12),
              Text('Mesaj içerikleri mümkün olduğunca minimize edilerek backend tarafında işlenir. Hassas içerikler loglara düz metin olarak yazılmamalıdır.'),
              SizedBox(height: 12),
              Text('Bağlı hesaplarda geçmiş bulut senkronu için Firebase üzerinde saklanır. Misafir kullanımda yerel önbellek sınırlı tutulur.'),
              SizedBox(height: 12),
              Text('Kullanıcı, uygulama içinden verilerini ve hesabını silebilir. Satın alma ve abonelik kayıtları yasal ve operasyonel gereklilikler kapsamında sınırlı süre tutulabilir.'),
            ],
          ),
        ),
      ),
    );
  }
}
