# İlişki Koçu AI

Flutter + Firebase tabanlı, guest-first ilişki iletişimi yardımcı uygulaması.

## Hazır olanlar

- Anonim oturum bootstrap
- Guest-first onboarding ve routing
- Mesaj analizi, cevap üretimi, durum stratejisi ekranları
- Geçmiş, detay, hesap bağlama, premium ve profil akışları
- Remote Config, Analytics, Crashlytics, Firestore, Functions iskeleti
- Server-side kredi mantığı ve AI çağrıları
- Privacy / Terms ekranları

## Geliştirme

```bash
flutter pub get
flutter analyze lib
cd functions
npm install
npm run build
```

## Kullanıcı tarafından sonra doldurulacaklar

- Mağaza ürünlerinin App Store Connect ve Google Play tarafında oluşturulması
- GitHub signing / deploy secret'larının eklenmesi
- `OPENAI_API_KEY` deploy ortamı secret'ı
- Netlify alan adı veya canlı hukuk merkezi bağlantısı
