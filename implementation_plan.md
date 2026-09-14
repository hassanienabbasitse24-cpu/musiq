# خطة حل مشكلة الأغاني 30 ثانية — تشغيل أغاني كاملة عبر YouTube

## المشكلة

- Spotify API و iTunes API يعطون فقط `previewUrl` = **30 ثانية**
- `YouTubeService` في الفرونت اند يستخدم Invidious instances عامة غير مستقرة
- النتيجة: أغلب الأغاني تشتغل 30 ثانية فقط

## الحل

نضيف **YouTube audio extraction في الباك ايند** باستخدام مكتبة `@distube/ytdl-core` (مجانية، بدون API key).

### تدفق التشغيل الجديد:

```
المستخدم يضغط أغنية
        │
        ▼
   1. هل محمّلة offline؟ ──── نعم ──▶ شغّل من الملف المحلي ✅
        │ لا
        ▼
   2. اطلب من الباك ايند ──── GET /search/audio?title=X&artist=Y
        │                              │
        │                   الباك ايند يبحث YouTube
        │                   يستخرج رابط الصوت الكامل
        │                   يرجع streamUrl (proxy) 
        │                              │
        ◀──────────────────────────────┘
        │ نجح
        ▼
   3. شغّل الأغنية كاملة عبر الـ proxy stream ✅
        │
        │ فشل
        ▼
   4. Fallback: شغّل iTunes preview (30 ثانية) — أحسن من لا شي
```

---

## التغييرات المطلوبة

### 📦 Backend (Node.js) — 4 ملفات

---

#### 1. [NEW] `server/services/youtubeService.js`

خدمة جديدة تسوي شغلين:
- **بحث YouTube**: عن طريق Invidious API (من السيرفر أكثر استقرار من الهاتف)
- **استخراج رابط الصوت**: عن طريق `@distube/ytdl-core` — يرجع أعلى جودة صوت

```javascript
// الدوال الرئيسية:
searchYouTube(query)        // يبحث بعدة Invidious instances
getAudioUrl(videoId)        // يستخرج رابط الصوت من ytdl-core
getFullAudioUrl(title, artist, baseUrl)  // يجمع البحث + الاستخراج
```

---

#### 2. [NEW] `server/routes/stream.js`

Proxy streaming endpoint — يسحب الصوت من YouTube ويمرره للتطبيق:
- `GET /stream/:videoId` — يبث الصوت مباشرة
- يحل مشكلة IP restrictions (YouTube أحياناً يحظر IPs غير السيرفر)
- يدعم Content-Type headers الصحيحة لـ `just_audio`

---

#### 3. [MODIFY] `server/routes/search.js`

إضافة endpoint جديد بجانب البحث الموجود:
- `GET /search/audio?title=X&artist=Y` — يرجع:
  ```json
  {
    "audioUrl": "https://...(direct YouTube URL)",
    "streamUrl": "https://musiq-backend.onrender.com/stream/VIDEO_ID",
    "duration": 245000,
    "videoId": "abc123"
  }
  ```

> [!NOTE]
> البحث القديم `GET /search?q=...` يبقى كما هو بدون أي تغيير.

---

#### 4. [MODIFY] `server/server.js`

- إضافة `import streamRouter` و تسجيل route `/stream`

---

#### 5. [MODIFY] `server/package.json`

- إضافة dependency: `"@distube/ytdl-core": "^4.16.10"`

---

### 📱 Flutter App — 3 ملفات

---

#### 6. [MODIFY] `lib/core/api/api_client.dart`

إضافة endpoints جديدة:
```dart
static String get audioUrl => '$baseUrl/search/audio';
static String streamUrl(String videoId) => '$baseUrl/stream/$videoId';
```

---

#### 7. [MODIFY] `lib/core/api/api_repository.dart`

إضافة method جديدة:
```dart
static Future<String?> getFullAudioUrl({
  required String title,
  required String artist,
}) async {
  // تتصل بالباك ايند /search/audio
  // ترجع streamUrl (الأكثر استقرار) أو audioUrl 
}
```

---

#### 8. [MODIFY] `lib/core/providers/playback_provider.dart`

تغيير بسيط فقط في دالة `playSong()` — سطور 190-200:

**قبل** (Invidious من الهاتف — غير مستقر):
```dart
final ytUrl = await YouTubeService.getFullAudioUrl(...);
```

**بعد** (الباك ايند — مستقر):
```dart
final ytUrl = await ApiRepository.getFullAudioUrl(...);
```

> [!NOTE]
> ملف `youtube_service.dart` **ما نحذفه** — نخليه كـ fallback إضافي إذا الباك ايند نايم.

---

## ملخص الملفات

| # | الملف | العملية | الوصف |
|:-:|-------|:-------:|-------|
| 1 | `server/services/youtubeService.js` | 🆕 جديد | YouTube بحث + استخراج صوت |
| 2 | `server/routes/stream.js` | 🆕 جديد | Proxy streaming endpoint |
| 3 | `server/routes/search.js` | ✏️ تعديل | إضافة `/audio` endpoint |
| 4 | `server/server.js` | ✏️ تعديل | تسجيل stream route |
| 5 | `server/package.json` | ✏️ تعديل | إضافة ytdl-core |
| 6 | `lib/core/api/api_client.dart` | ✏️ تعديل | إضافة 2 endpoints |
| 7 | `lib/core/api/api_repository.dart` | ✏️ تعديل | إضافة method واحدة |
| 8 | `lib/core/providers/playback_provider.dart` | ✏️ تعديل | تغيير سطر واحد |

---

## بعد التنفيذ — خطوات النشر

1. ✅ `npm install` في فولدر `server/`
2. ✅ اختبار محلي: `node server.js` ← `/search/audio?title=Tamally Maak&artist=Amr Diab`
3. ✅ رفع الباك ايند على Render.com (أو `git push` إذا مربوط)
4. ✅ `flutter run` على الهاتف ← الأغاني تشتغل كاملة

---

## خطة التحقق

- تشغيل الباك ايند محلياً واختبار `/search/audio` و `/stream/:videoId`
- التأكد إن الأغنية تشتغل **أكثر من 30 ثانية** على الهاتف
- التأكد إن الـ fallback يشتغل لو الباك ايند مو متوفر
