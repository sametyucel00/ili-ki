import 'package:flutter/material.dart';
import 'package:iliski_kocu_ai/shared/widgets/common_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Kullanım Koşulları',
      child: SingleChildScrollView(
        child: PrimaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader('Hizmet kapsamı'),
              SizedBox(height: 12),
              Text('Uygulama, ilişki iletişimi için AI destekli yorum ve cevap önerileri sunar; terapi, tanı veya profesyonel danışmanlık hizmeti değildir.'),
              SizedBox(height: 12),
              Text('Üretilen içerikler yorumlayıcıdır ve kesinlik iddia etmez. Kullanıcı, önerileri kendi sorumluluğunda değerlendirir.'),
              SizedBox(height: 12),
              Text('Premium planlar ve kredi paketleri uygulama içi satın alma ile sunulur. Fiyat, yenileme ve iptal bilgileri satın alma ekranında açıkça gösterilmelidir.'),
              SizedBox(height: 12),
              Text('Taciz, manipülasyon, tehdit, takıntılı takip veya zarar verici kullanım bu hizmetin amaç dışı kullanımıdır.'),
            ],
          ),
        ),
      ),
    );
  }
}
