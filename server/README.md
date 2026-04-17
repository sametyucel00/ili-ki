# Hisle AI Node.js Server

Bu klasör, Hisle mobil uygulamasının AI isteklerini güvenli şekilde sunucu üzerinden çalıştırması için hazırlanmış bağımsız Node.js API uygulamasıdır.

Mobil uygulama doğrudan AI provider key kullanmaz. Uygulama sadece bu endpoint'e istek atar:

```text
POST https://api.senindomainin.com/ai
```

## Provider Seçimi

Sunucu iki provider destekler:

```text
AI_PROVIDER=groq
```

veya:

```text
AI_PROVIDER=openai
```

MVP/test için önerilen ücretsiz/limitli seçenek:

```text
AI_PROVIDER=groq
GROQ_API_KEY=gsk_...
GROQ_MODEL=llama-3.1-8b-instant
```

OpenAI kullanmak istersen:

```text
AI_PROVIDER=openai
OPENAI_API_KEY=sk-proj-...
OPENAI_MODEL=gpt-4o-mini
```

## Kurulum

Sunucuda Node.js 20 veya üzeri olmalı.

```bash
cd server
npm install
cp .env.example .env
nano .env
npm start
```

`.env` örneği:

```text
AI_PROVIDER=groq
GROQ_API_KEY=gsk_your-groq-key-here
GROQ_MODEL=llama-3.1-8b-instant
OPENAI_API_KEY=sk-proj-your-openai-key-here
OPENAI_MODEL=gpt-4o-mini
PORT=3000
ALLOWED_ORIGINS=*
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=30
```

Sadece Groq kullanacaksan `OPENAI_API_KEY` boş kalabilir. Sadece OpenAI kullanacaksan `GROQ_API_KEY` boş kalabilir.

## Endpointler

Health check:

```text
GET /health
```

Örnek cevap:

```json
{
  "ok": true,
  "service": "hisle-ai-server",
  "provider": "groq",
  "model": "llama-3.1-8b-instant"
}
```

AI endpoint:

```text
POST /ai
```

Örnek body:

```json
{
  "type": "reply_generation",
  "message": "Bugün konuşmak istemiyorum dedi",
  "tone": "Kibar",
  "responseLength": "Kısa",
  "emojiPreference": false,
  "tier": "standard"
}
```

Örnek başarılı cevap:

```json
{
  "result": {
    "recommendedAction": "Kısa ve sakin cevap ver.",
    "replyOptions": [
      "Anlıyorum, uygun olduğunda konuşabiliriz.",
      "Tamam, seni zorlamak istemem.",
      "Sorun değil, sonra konuşuruz."
    ]
  }
}
```

## Domain Bağlama

DNS tarafında örnek:

```text
Type: A
Name: api
Value: SUNUCU_IP_ADRESIN
```

Nginx reverse proxy örneği:

```nginx
server {
  server_name api.senindomainin.com;

  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

SSL için:

```bash
sudo certbot --nginx -d api.senindomainin.com
```

## Flutter Build Ayarı

GitHub Actions secret olarak şunu ekle:

```text
AI_BACKEND_URL=https://api.senindomainin.com/ai
```

Lokal test run için:

```bash
flutter run --dart-define=AI_BACKEND_URL=https://api.senindomainin.com/ai
```
