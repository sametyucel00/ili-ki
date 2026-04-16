# Release Checklist

## Firebase / Backend

- [ ] `app_config/runtime` dokümanı üretim değerleriyle oluşturuldu
- [ ] `OPENAI_API_KEY` deploy ortamında tanımlı
- [ ] Functions deploy edildi
- [ ] Firestore rules deploy edildi

## Auth / Payments / Ads

- [ ] Anonymous, Google, Apple, Email provider açık
- [ ] Android SHA-1 ve SHA-256 eklendi
- [ ] App Store Connect ürünleri oluşturuldu
- [ ] Google Play ürünleri oluşturuldu
- [ ] AdMob rewarded unit gerçek cihazda test edildi

## GitHub / CI

- [ ] Android signing secrets eklendi
- [ ] iOS signing/TestFlight secrets eklendi
- [ ] Netlify deploy secret eklendi
- [ ] Publish workflow'ları manuel tetiklenerek doğrulandı

## QA

- [ ] Guest-first giriş akışı doğrulandı
- [ ] Account linking sonrası UID korunumu test edildi
- [ ] Rewarded ad sonrası kredi artışı doğrulandı
- [ ] IAP satın alma ve restore doğrulandı
- [ ] Gizlilik, yardım ve koşullar linkleri açılıyor
- [ ] Android release build alındı
- [ ] iOS IPA/TestFlight build alındı
