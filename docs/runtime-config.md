# Firestore `app_config/runtime`

Firestore Console'da şu yolu aç:

- `app_config`
- document id: `runtime`

Alanları şu değerlerle oluştur:

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
  "rewardedAdDailyLimit": 3
}
```

Öneri mantığı:

- `starterCredits: 3`
  İlk deneyimde ürünü hissettirmek için yeterli.
- `freeDailyCredits: 2`
  Tamamen kilitli hissettirmez ama monetization'ı da öldürmez.
- `linkBonusCredits: 3`
  Hesap bağlama için net ama abartısız ödül.
- `messageAnalysisCost: 1`
- `replyGenerationCost: 1`
- `situationStrategyCost: 2`
  Daha ağır analiz olduğu için strateji daha pahalı.
- `guestDailyLimit: 3`
  Guest-first deneyimi korur ama abuse'u sınırlar.
- `linkedDailyLimit: 10`
  Hesap bağlamayı anlamlı şekilde ödüllendirir.
- `aiCooldownSeconds: 20`
  Spam ve maliyet patlamasını azaltır.
- `softPaywallThreshold: 2`
  Kullanıcı değer gördükten sonra paywall gösterilir.
- `rewardedAdCredits: 1`
  Senin istediğin akışla birebir uyumlu.
- `rewardedAdDailyLimit: 3`
  Reklam suistimalini sınırlar ama kullanıcıyı da boğmaz.
