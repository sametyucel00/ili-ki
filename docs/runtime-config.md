# Firestore `app_config/runtime`

Firestore Console'da su yolu ac:

- `app_config`
- document id: `runtime`

Alanlari su degerlerle olustur:

```json
{
  "starterCredits": 3,
  "freeDailyCredits": 2,
  "linkBonusCredits": 3,
  "replyGenerationCost": 1,
  "messageAnalysisCost": 1,
  "situationStrategyCost": 2,
  "guestDailyLimit": 3,
  "linkedDailyLimit": 10,
  "aiCooldownSeconds": 20,
  "latestPromptVersion": "v1",
  "softPaywallThreshold": 2,
  "rewardedAdCredits": 1,
  "rewardedAdDailyLimit": 3,
  "androidPurchaseSimulationEnabled": true
}
```

Oneri mantigi:

- `starterCredits: 3`
  Ilk deneyimde urunu hissettirmek icin yeterli.
- `freeDailyCredits: 2`
  Tamamen kilitli hissettirmez ama monetization'i da oldurmez.
- `linkBonusCredits: 3`
  Hesap baglama icin net ama abartisiz odul.
- `messageAnalysisCost: 1`
- `replyGenerationCost: 1`
- `situationStrategyCost: 2`
  Daha agir analiz oldugu icin strateji daha pahali.
- `guestDailyLimit: 3`
  Guest-first deneyimi korur ama abuse'u sinirlar.
- `linkedDailyLimit: 10`
  Hesap baglamayi anlamli sekilde odullendirir.
- `aiCooldownSeconds: 20`
  Spam ve maliyet patlamasini azaltir.
- `softPaywallThreshold: 2`
  Kullanici deger gordukten sonra paywall gosterilir.
- `rewardedAdCredits: 1`
  1 reklam = 1 analiz akisiyla uyumludur.
- `rewardedAdDailyLimit: 3`
  Reklam suistimalini sinirlar ama kullaniciyi da bogmaz.
- `androidPurchaseSimulationEnabled: true`
  Android'de satin alma butonlarini gecici olarak test satin almasi gibi calistirir.
