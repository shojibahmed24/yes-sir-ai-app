# Yes Sir AI — Production Release Audit & Fix Plan

> তারিখ: ২০২৬-১১-২০ · অবস্থা: **অডিট সম্পন্ন (৩টি স্বাধীন read-only অডিট), প্ল্যান অনুমোদনের অপেক্ষায়**
> সোর্স: security audit, quick-load audit, production-readiness audit — সব ফাইন্ডিং file:line প্রমাণসহ (বিস্তারিত এজেন্ট-রিপোর্টে)।
> নিয়ম: কোনো ফেজে কাজ শুরু হবে শুধু মালিকের অনুমোদনের পর; DB write/deploy-এ এক-বারের ক্রেডেনশিয়াল লাগবে।

## ১. শীর্ষ ব্লকার (production যেতে গেলে)

**ক্রিটিক্যাল (নিরাপত্তা/রেভিনিউ)**
1. **GEN mode = ফ্রি আনলিমিটেড AI proxy** — `explain-question` ক্লায়েন্ট-পাঠানো যেকোনো prompt মালিকের OpenRouter/Gemini key-তে ফরওয়ার্ড করে; প্রিমিয়াম চেক/রেট-লিমিট/কোটা নেই।
2. **Mode G-তে key-gate নেই** — উত্তর/key সবার কাছে; README দাবি করা গেট কোডে নেই; আপাতত free-open অর্ডারে মাস্ক করা।
3. **Play purchase verification server নেই** — ক্লায়েন্ট-সাইড completePurchase; কেউ কখনো প্রিমিয়াম হতে পারে না।
4. **Voice ক্যাপ ক্লায়েন্ট-গণিত** — ডেটা ক্লিয়ার করলেই আনলিমিটেড; ভয়েস ট্রান্সপোর্টও unwired (কখনো ready হয় না)।

**রিলিজ-ব্লকার (অ্যান্ড্রয়েড/প্লে)**
5. **`INTERNET` permission release manifest-এ নেই** → release build-এ নেটওয়ার্কই চলবে না।
6. **Debug key-তে সাইন করা** → Play Store প্রত্যাখ্যান করবে।
7. **Privacy policy/terms নেই** (Play listing + Data Safety ব্লকার)।
8. **Account deletion নেই** (Play User Data policy)।
9. **হোম/লগিনে সবার জন্য “partial live” ব্যানার** — অসমাপ্ত পণ্যের বিজ্ঞাপন।
10. **Migration 018/019 live নয়** — anon রিড ভাঙতে পারে।

**Quick-load (প্রতিবার খোলায়)**
11. স্প্ল্যাশে **স্থির ২.৫ সেকেন্ড delay**।
12. স্প্ল্যাশে **প্রতি লঞ্চে নেটওয়ার্ক `refreshSession()`** (টাইমআউটহীন)।
13. `runApp`-এর আগে Supabase init ব্লক; হোমের future build-এ নতুন হয় → লোকেল/ট্যাব বদলে রিফেচ।
14. মডেল টেস্ট শুরুতে **N/5 সিরিয়াল Edge কল**; প্রতি অনুরোধে নতুন HttpClient (৩০ সেকেন্ড টাইমআউট)।
15. Release-এ minify/R8 নেই; app নাম `yes_sir_ai`; `/design-system` ডেভ রাউট shipped; About টেক্সট stale (ক্লাস ৬); version hardcoded; notifications = “Demo list”; reminder টগল মৃত; OTP থিয়েটার; ক্র্যাশ-রিপোর্টিং/সাপোর্ট চ্যানেল নেই; CI নেই।

**ভালো আছে (ছোঁয়া নয়):** prefetch (WiFi-only, one-page-ahead), in-flight dedupe, cache-once grid, ২০-রো paging, saved-questions lazy builder, RLS scoped, কোনো কোড-সিক্রেট নেই, demo premium টগল প্রোডাকশনে inert।

---

## ২. ফেজ-ভিত্তিক ফিক্স প্ল্যান

### Phase A — অ্যান্ড্রয়েড রিলিজ আনব্লক (কোড-অনলি, কোনো কী লাগে না)
- [ ] A1 `INTERNET` permission `android/app/src/main/AndroidManifest.xml`-এ (B1)।
- [ ] A2 app label `yes_sir_ai` → `Yes Sir AI` (H1)।
- [ ] A3 release signingConfig: `key.properties` (gitignored) + upload keystore (কী তৈরি: আপনার সিদ্ধান্ত — Phase-অনুমোদনে) (B2)।
- [ ] A4 release buildType: `isMinifyEnabled` + `isShrinkResources` + ProGuard rules (B1-perf)।
- [ ] A5 `/design-system` রুট `kDebugMode`-এ গেট (M4)।
- [ ] A6 স্প্ল্যাশ: ২.৫ সেকেন্ড delay সরানো (নূন্যতম ৩০০ms ওভারল্যাপ); `refreshSession()` → লোকাল `expiresAt` চেক + ৮ সেকেন্ড `.timeout`; প্রেফস রিড `Future.wait`-এ (S2/S3/S4)।
- [ ] A7 `Supabase.initialize` splash-ফ্রেমের পেছনে (S1)।
- [ ] A8 হোম/প্র্যাকটিস/সাবজেক্ট-কার্ডের `FutureBuilder(future: x())` → memoized (H1/H3/H4)।
- [ ] A9 শেয়ারড `HttpClient` + ৮–১২ সেকেন্ড টাইমআউট `edge_post.dart`-এ (N1)।
- [ ] A10 মৃত ফাইল `search_flow_number_input.dart` `git rm` (L1); `mock_data`-এর নাম-fallback সরানো (L3); build.gradle TODO পরিষ্কার (L2)।
- [ ] A11 About টেক্সট ঠিক (ক্লাস ১–১০ স্কোপ) + `package_info_plus` দিয়ে আসল version (M2/M3)।
- **verify:** analyze ০ error/warning + full suite + `flutter build appbundle --split-debug-info` সফল।

### Phase B — রেন্ডার/নেটওয়ার্ক জ্যাংক (কোড-অনলি)
- [ ] B1 `bangla_second_set_rows_screen` → `ListView.builder` (R1)।
- [ ] B2 `SolutionBlocks.parseBlocks` + math spans memoize (R2)।
- [ ] B3 English reader স্ক্যান ডিস্কে SWR-persist (N3)।
- [ ] B4 চ্যাপ্টার-ফিল্টার memoize (R4); হোম গ্রিড `IntrinsicHeight` → পরিমাপ-ভিত্তিক (R3)।
- [ ] B5 বড় jsonDecode → `compute()` (bulk/ক্যাশ paths) (B3-perf)।
- [ ] B6 lesson screen-এর auto-AI-generate → on-demand (N5) + grounding ডিস্ক-ক্যাশ।
- **verify:** analyze + full suite; ১.৩x টেক্সট-স্কেল টেস্ট বাড়ানো।

### Phase C — ব্যাকএন্ড/এজ (Supabase deploy + এক-বারের মালিক ক্রেডেনশিয়াল লাগবে)
- [ ] C1 **GEN gate:** সার্ভার-সাইড prompt-ক্যাপ + per-user দৈনিক কোটা + প্রিমিয়াম/রেট-লিমিট (`explain-question`) — ক্রিটিক্যাল #1।
- [ ] C2 **Mode G gate:** key/entitlement গেট সার্ভারে — ক্রিটিক্যাল #2।
- [ ] C3 **Play verification Edge function** (Play Developer API, service role) + entitlement write path — ক্রিটিক্যাল #3 (আপনার Play Console service-account setup লাগবে)।
- [ ] C4 **Voice budget সার্ভার-সাইড** + Gemini Live ephemeral-token endpoint (আপনার Gemini key) — ক্রিটিক্যাল #4।
- [ ] C5 কোড-লেভেল JWT ভ্যালিডেশন + CORS origin সীমিত + বেসিক রেট-লিমিট (M2/M3/L1)।
- [ ] C6 **Bulk key-resolution endpoint** (মডেল টেস্ট N/5 → ১ কল) + **all-subjects guide-flags endpoint** (H2/N2)।
- [ ] C7 Migration **018/019 apply + live-যাচাই** (এক-বারের DB password)।
- [ ] C8 অ্যাকাউন্ট-ডিলিশন Edge function (service role) + অ্যাপে “Delete account” ফ্লো (B4)।
- **verify:** লাইভ প্রোব (guide-bank/explain-question), quota-টেস্ট, full suite।

### Phase D — প্রোডাক্ট-সিদ্ধান্ত (আপনার ৩টি উত্তর ছাড়া শেষ হবে না)
- [ ] D1 **প্রিমিয়াম ভঙ্গি:** (ক) সম্পূর্ণ প্রিমিয়াম বানানো (C3+C4-এর ওপর) নাকি (খ) ফ্রি-অনলি লঞ্চ (পেওয়াল/ভয়েস UI সরানো)। → B5/B6/B8-এর সমাধান এখানেই।
- [ ] D2 **Privacy policy + Terms:** আমি বাংলা+ইংরেজি খসড়া লিখে দেব; হোস্টিং URL আপনার (Play Console-এ বসাতে হবে) + অ্যাপে লিংক।
- [ ] D3 **Notifications:** (ক) সত্যিকারের লোকাল রিমাইন্ডার (`flutter_local_notifications`) নাকি (খ) ডেমো লিস্ট/টগল সরানো।
- [ ] D4 **সাপোর্ট ইমেইল/URL** (Play listing + in-app)।
- [ ] D5 **ক্র্যাশ-রিপোর্টিং:** Sentry DSN দিলে Sentry; না দিলে অন্তত `runZonedGuarded` + `FlutterError.onError` হুক।
- **verify:** নির্বাচিত পথে আচরণ + ডক আপডেট।

### Phase E — সিকিউরিটি হার্ডেনিং (কিছুতে আপনার ইনফ্রা লাগবে)
- [ ] E1 Auth টোকেন → `flutter_secure_storage` (H2)।
- [ ] E2 `.gitignore`-এ `dart_defines.json` + `.env*`; `dart_defines.example.json` placeholder (M5)।
- [ ] E3 Avatar → private bucket + signed URL (L2)।
- [ ] E4 Deep link → App Links (আপনার ডোমেইন + assetlinks.json) নতুবা URI-শেপ যাচাই (M1)।
- [ ] E5 Parent PIN → সার্ভার-ভেরিফায়েড (M4)।
- [ ] E6 `ys_reset_contact` → secure storage (L4); AuthException → জেনেরিক bilingual ম্যাপ (L6)।

### Phase F — QA/CI + চূড়ান্ত
- [ ] F1 GitHub Actions: `flutter analyze` + `flutter test` + `flutter build appbundle` (M8/M9)।
- [ ] F2 AGENTS.md “Current state” রিফ্রেশ (H8) + owner-decision লিস্ট আপডেট।
- [ ] F3 Play Console চেকলিস্ট: listing, Data Safety form, সাবস্ক্রিপশন প্রোডাক্ট (যদি D1=ক), টেস্টার গ্রুপ।
- [ ] F4 স্মোক-চেকলিস্ট: লগইন→হোম→সাবজেক্ট→লেসন→কুইজ→মডেল টেস্ট→ভয়েস (যদি থাকে)→পারচেজ-রিস্টোর।

---

## ৩. আপনার সিদ্ধান্ত দরকার (এখন)

1. **Phase A+B** (কোড-অনলি, কোনো কী লাগে না) — শুরু করব? (সুপারিশ: হ্যাঁ)
2. **D1 প্রিমিয়াম ভঙ্গি:** (ক) ফুল প্রিমিয়াম (Play service-account + Gemini key লাগবে) নাকি (খ) ফ্রি-অনলি লঞ্চ?
3. **D2:** আমি privacy/terms-এর খসড়া লিখে দেব কি? হোস্ট কোথায় করবেন?
4. **D5:** Sentry ব্যবহার করবেন (DSN দেবেন) নাকি শুধু বিল্ট-ইন error hook?
5. **A3 keystore:** আমি লোকাল upload-keystore জেনারেট করে দেব (পাসওয়ার্ড gitignored `key.properties`-এ), নাকি আপনি নিজে Play App Signing-এর ফ্লো চালাবেন?
6. **Phase C-এর জন্য:** যখন সেখানে পৌঁছাব, তখন এক-বারের Supabase access token (deploy) + DB password দেবেন তো?
