# GitHub Secrets

Bu repo için GitHub Actions tarafında eklemen gereken secret'lar:

## Android release build

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## iOS signed IPA / TestFlight

- `IOS_CERTIFICATE_P12_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_KEYCHAIN_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `IOS_PROFILE_NAME`
- `IOS_BUNDLE_ID`
- `APPLE_TEAM_ID`

## TestFlight upload

- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

## Backend / deploy related

- `OPENAI_API_KEY`

Notlar:

- Android keystore dosyasını base64'e çevirip `ANDROID_KEYSTORE_BASE64` olarak eklemelisin.
- iOS için `.p12` sertifika ve `.mobileprovision` profil base64 olarak eklenmeli.
- `APP_STORE_CONNECT_PRIVATE_KEY` secret'ı `.p8` dosyasının düz metin içeriği olmalı.
