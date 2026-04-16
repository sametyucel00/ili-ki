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

- Firebase platform config dosyaları
- `lib/firebase_options.dart` gerçek değerleri
- RevenueCat anahtarları ve ürün kimlikleri
- `OPENAI_API_KEY` Functions secret
- Store metinleri ve nihai hukuk içerikleri
