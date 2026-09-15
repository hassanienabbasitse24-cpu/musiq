# إصلاح مشكلة 404 على Vercel لسيرفر Express.js

## تشخيص المشكلة

بعد فحص المشروع بالكامل، وجدت أن لديك **نسختين** من السيرفر في أماكن مختلفة، وهذا هو جذر المشكلة:

| الملف | الصيغة | الحالة |
|---|---|---|
| [`api/index.js`](file:///c:/Users/jhonx/Desktop/New%20folder/api/index.js) | CommonJS (`require/module.exports`) — **نسخة كاملة مستقلة** | ✅ هذا هو الملف الذي يقرأه Vercel |
| [`server/server.js`](file:///c:/Users/jhonx/Desktop/New%20folder/server/server.js) | ES Modules (`import/export default`) — **يعتمد على ملفات خارجية** | ❌ Vercel لا يستخدمه |
| [`vercel.json`](file:///c:/Users/jhonx/Desktop/New%20folder/vercel.json) (الجذر) | يوجه كل الطلبات إلى `/api/index.js` | ✅ موجود |

### السبب الفعلي للـ 404:

> [!IMPORTANT]
> المشكلة أن إعداد **Root Directory = `server`** في لوحة Vercel يجعل Vercel يبحث عن الملفات داخل مجلد `server/` فقط. لكن ملف `vercel.json` الرئيسي و مجلد `api/` موجودان في **الجذر** وليس داخل `server/`. لذلك Vercel لا يراهم أصلاً ← **404**.

بالإضافة لذلك، حتى لو أزلت إعداد Root Directory، فإن ملف [`api/index.js`](file:///c:/Users/jhonx/Desktop/New%20folder/api/index.js) يستخدم `require` (CommonJS) بينما [`package.json`](file:///c:/Users/jhonx/Desktop/New%20folder/package.json) في الجذر **لا يحتوي** على `dotenv` كـ dependency، ولكن الملف لا يحتاجه لأنه hardcoded للـ Jamendo API key ويقرأ `YOUTUBE_API_KEY` من `process.env` مباشرة.

---

## الحل المقترح

هناك طريقتان. أنصح بالطريقة الأولى لأنها الأبسط والأنظف:

### الطريقة ١ (الموصى بها): استخدام `api/index.js` في الجذر — بدون Root Directory

هذه هي الطريقة القياسية لـ Vercel. ملف `api/index.js` موجود بالفعل ويعمل كـ Serverless Function تلقائياً.

**الخطوات:**

1. **إزالة إعداد Root Directory** من لوحة Vercel (يجب أن يكون فارغاً).
2. **تحديث [`vercel.json`](file:///c:/Users/jhonx/Desktop/New%20folder/vercel.json)** في الجذر — الملف الحالي صحيح تقريباً، لكن سنضيف `"version": 2`.
3. **تحديث [`package.json`](file:///c:/Users/jhonx/Desktop/New%20folder/package.json)** في الجذر لإضافة `dotenv` (لو احتجته مستقبلاً) والتأكد من أن كل dependencies موجودة.
4. **تحديث [`api/index.js`](file:///c:/Users/jhonx/Desktop/New%20folder/api/index.js)** لإضافة `YOUTUBE_API_KEY` check وتحسينات طفيفة.

> [!WARNING]
> هذا الحل يتجاهل مجلد `server/` بالكامل على Vercel. مجلد `server/` يبقى للتطوير المحلي فقط. ملف `api/index.js` هو النسخة المخصصة لـ Vercel.

---

## التغييرات المطلوبة

### Vercel Dashboard

> [!CAUTION]
> **يجب عليك يدوياً** الدخول إلى Vercel Dashboard → Settings → General → Root Directory وجعله **فارغاً** (أو حذف القيمة `server`). هذه الخطوة لا يمكن تنفيذها من الكود.

---

### ملفات الكود

#### [MODIFY] [`vercel.json`](file:///c:/Users/jhonx/Desktop/New%20folder/vercel.json)

إضافة `version: 2` والتأكد من أن الـ rewrites صحيحة:

```diff
 {
+  "version": 2,
   "rewrites": [
     { "source": "/(.*)", "destination": "/api/index.js" }
   ]
 }
```

#### [MODIFY] [`package.json`](file:///c:/Users/jhonx/Desktop/New%20folder/package.json) (الجذر)

التأكد من أن كل الـ dependencies موجودة بما فيها `dotenv`:

```diff
 {
   "name": "musiq-backend",
   "version": "1.0.0",
   "dependencies": {
     "cors": "^2.8.5",
+    "dotenv": "^16.4.7",
     "express": "^4.21.2",
     "express-rate-limit": "^7.5.0"
   }
 }
```

#### لا تغيير على [`api/index.js`](file:///c:/Users/jhonx/Desktop/New%20folder/api/index.js)

الملف الحالي يعمل بشكل صحيح. يستخدم CommonJS (`module.exports = app`) وهو متوافق مع Vercel Serverless Functions.

---

## خطوات ما بعد التطبيق

1. إزالة Root Directory من Vercel Dashboard (**يدوياً**).
2. تطبيق تغييرات الكود.
3. عمل `git push` لإعادة الـ deployment.
4. اختبار `https://musiqapp.vercel.app/health` — يجب أن يرجع:
   ```json
   {"status":"ok","service":"musiq-backend","sources":["jamendo","youtube"]}
   ```

## Open Questions

> [!IMPORTANT]
> 1. **هل تريد الاحتفاظ بمجلد `server/` للتطوير المحلي فقط، أم تريد توحيد الكود في مكان واحد؟** حالياً يوجد نسختين (واحدة ES Modules في `server/` وواحدة CommonJS في `api/`). الأفضل توحيدهم لاحقاً لتجنب أن تنسى تحديث إحداهما.
> 2. **هل تمت إضافة `YOUTUBE_API_KEY` كـ Environment Variable في Vercel Dashboard لبيئة Production؟**
