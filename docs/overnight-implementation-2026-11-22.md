# রাতের ইমপ্লিমেন্টেশন রিপোর্ট — ২০২৬-১১-২২

> **কী:** `docs/full-ui-audit-2026-11-21.md`-এর অডিট থেকে যেসব সমস্যা ইউজারের সিদ্ধান্ত/ব্যাকএন্ড/ডিভাইস ছাড়াই ঠিক করা যায় — সেগুলো ধাপে ধাপে ইমপ্লিমেন্ট করা হয়েছে।
> **শাখা:** `main` (প্রতিটি ব্যাচ আলাদা কমিট, তারপর ff-merge — আগের রীতি অনুযায়ী)।
> **নিয়ম:** কোনো ফাইল ডিলিট নয়, কোনো DB লেখা/ডিপ্লয় নয়, কোনো সিক্রেট নেই, প্রতিটি ফাইল ≤২৫০ লাইন।

---

## ১. কমিট তালিকা

| কমিট | কী |
|---|---|
| `773d774` | **P0:** guide-answer failure state, classes 1–10, real chapter nav, back context, book lookup, bookmark separation |
| `5495853` | **P1:** auth/profile honesty — OTP cooldown + stale contact, password rules, busy states, system font size, price/profile claims, notifications header |
| `0a2ad37` | **P2:** subjects refresh/nav, honest advice + last-studied, subject title + practice, saved back/labels, duplicate recommendation removed |
| `3e0ee03` | **P3:** chat auto-scroll, real subject names, paging guard, honest picker empty state + explanation labels |
| `9771d23` | **P4:** crash-safe option letters, honest attempt chapter, retake the same questions |
| `28f8d48` | **P5:** class-aware book library, real book ids in recents, books count |
| (শেষ) | **P6:** honest XP/level, results “read again” → library, quiz CTA label + audit status update |

---

## ২. ঠিক করা সমস্যা — বিস্তারিত

### ২.১ Learn / Guide / AI
- **C1 · Guide-answer timeout ছিল নীরব বিপর্যয়** — `catch` শুধু লোডিং বন্ধ করত, ফলে খালি পেজ এবং MCQ-তে ভুল “চাবি নেই”। এখন `_failed` স্টেট + স্পষ্ট এরর + **Retry**; `answerLoadFailed` নতুন bn/en স্ট্রিং।
- **C2 · ক্লাস পিকার** — `search-flow`, পুরোনো `/search` ও chapter-questions পিকারে শুধু `{6,7,current}` ছিল। নতুন `lib/features/learn/class_choices.dart` → **১–১০ সব ক্লাস**, defensive extra class সহ।
- **C14 · Chapter কার্ড** — `page:45, problem:5` ডেমো স্ট্যাম্প + লিগ্যাসি `/search` বাদ; এখন সঠিক ক্লাসসহ `/search-flow?...&chapter=N`। `SearchFlowScreen/Controller`-এ `initialChapter` সাপোর্ট যোগ হয়েছে (continue/resume-এর ভিত্তি)।
- **H1 · “বিস্তারিত” বনাম “ধাপে ধাপে”** — দুটোই একই আউটপুট দিত। লেবেল এখন বাস্তব কাজ বলে: **“সারাংশসহ দেখাও” / “শুধু ধাপ দেখাও”** (সারাংশ দেখানো/লুকানো)।
- **H2/H3/H4 · Back context** — লিস্টের back এখন `returnTo` + class/source/chapter ধরে; lesson-hub → list `backTo` সম্মান করে; `/lesson` back `_sel.returnTo`-তে ফেরে (লিগ্যাসি `/search` নয়)।
- **H6 · চ্যাট** — ScrollController + auto-scroll: পাঠানোর পর ও উত্তর এলে শেষে নামে (উত্তর আর অফ-স্ক্রিনে হারায় না)।
- **H8 · সাবজেক্ট নাম** — `subjectNameFor` ম্যাপে ক্লাস ৯–১০-এর ১০টি বিষয় যোগ (chemistry, physics, biology, higher-math, accounting, economics, civics, business-entrepreneurship, english-2nd, class-8 variants) — কাঁচা id আর দেখাবে না।
- **Paging** — “আরও লোড” এখন in-flight guard + try/catch: ডাবল ট্যাপে ডুপ্লিকেট পেজ বা আনহ্যান্ডলড এরর নেই।
- **Picker empty** — “Loading.” লেবেলের নিচে “No items found” contradiction বাদ; ফিল্ড লেবেল এখন অধ্যায়।
- **H9/H10 · Book lookup** — পেজ খালি/ভুল হলে বাটন disable; ক্লাস প্রোফাইল থেকে; AI ব্যাখ্যায় `.then()` বদলে await+try/catch → **অনন্ত “loading explanation” বন্ধ**।
- **C13 · Saved বনাম bookmark** — পেজ-বুকমার্ক এখন আলাদা স্টোর (`ys_book_bookmarks`); Saved-এ `book:` আইডি ফিল্টার হয় — ডেড রো ও ভুল কাউন্ট বন্ধ।

### ২.২ Auth / Profile / Settings
- **H29 · OTP কুলডাউন** — লেবেল “(0:30)” বলে কিছুই ছিল না। এখন সত্যিকারের ৩০s টাইমার (`Timer.periodic`), শেষে “আবার পাঠাও”; রিসেন্ডে কুলডাউন রিসেট; ডেমোতেও।
- **H25 · Stale reset contact** — লগইন থেকে OTP-তে এলে পুরোনো ইমেইল মুছে যায় (`clearResetContact`) — ফোন ফিল্ড আর লুকায় না, ভুয়া “code sent to…” নেই।
- **H30/H31 · কপি** — “SMS বা WhatsApp” বাদ (WhatsApp চ্যানেল নেই); Step 9-এ “৪ সংখ্যার কোড পাঠানো হয়েছে” মিথ্যা বাদ।
- **H32 · Reset password rules** — তিনটি টিক আগে থেকেই সবুজ ছিল। এখন লাইভ: ৮+ অক্ষর, সংখ্যা+স্পেশাল, upper/lower — টাইপের সাথে টিক ওঠে।
- **H33 · Busy states** — `AuthPrimaryButton`-এ `busy` + স্পিনার + “সাইন-ইন হচ্ছে…” / OTP-তে busy — দ্রুত ডাবল ট্যাপও আটকায়।
- **H36 · Font size** — অ্যাপ আর সিস্টেম ফন্ট সাইজ জোর করে ১.০ করে না; ইউজার Settings-এ ফন্ট বাছলে তখনই override (`fontScaleChosen`)।
- **H26/H27 · Profile সত্য** — ক্লাস সেট না থাকলে “Class 10 • Science” নয়, “ক্লাস সেট করা হয়নি…”; “Premium member (Pro)” নয়, শুধু “প্রিমিয়াম” (এনটাইটেলমেন্ট দাবি নেই)।
- **H35 · Settings save** — cloud upsert ব্যর্থ হলে “Saved” নয়, “এই ডিভাইসে সংরক্ষিত — সার্ভারে যায়নি”।
- **C5 · Premium দাম** — paywall-এ “$৫/মাস” বাদ → **“লঞ্চে ফ্রি”** (Play Billing এখনো নেই; ভয়েস মিনিটের লাইনে আলাদা `perPeriod`)।
- **H24 · Notifications** — হেডারের ভুল “৩টি নতুন” বাদ; খালি তালিকায় mark-all/clear ডেড বাটন লুকানো; back `pop` (Profile/Home যেখান থেকে এসেছে)।

### ২.৩ Home / Subjects
- **H11** — Subjects refresh এখন **দেখানো ক্লাস** invalidate করে (`_selectedClass ?? _schoolClass`), হার্ডকোড ৬ নয়।
- **H12** — Subjects/Chapters-এ বটম-নেভ এখন **ট্যাব ১** হাইলাইট (আগে Home)।
- **H17** — “আজকের পরামর্শ: গণিত ৩য় অধ্যায়” সব ক্লাসে দেখানো বন্ধ; কার্ডে আসল কাউন্ট (supplied books · subjects)।
- **C12** — “দুর্বল অধ্যায়” আসলে শেষ খোলা অধ্যায় ছিল; শিরোনাম এখন সৎ: **“শেষ যেখানে পড়েছ”**। (আসল weak-data কার্ড পরের ফেজে।)
- **H20** — হিরো-র নকল “Recommended for you” কার্ড বাদ।
- **H16** — Subject detail-এর AppBar-এ **আসল বিষয়ের নাম** (আগে “বিষয়”); “অনুশীলন শুরু” এখন `PracticeSession.selectedSubject` সেট করে — বিষয় হারায় না।
- **H22/H23** — Saved-এর “Practice” এখন **“এই বিষয়ে প্র্যাকটিস”** (সৎ লেবেল); back `pop` (আগে সবসময় /profile)।
- **H14** — Progress-এ XP ডেটা না থাকলে “Level 1 · 0 XP” নয়, **“তোমার পড়ার অগ্রগতি”**।
- **H15** — Achievements-এর CTA “Quiz Champion” (ব্যাজের নাম) → **“কুইজ শুরু করো”**।

### ২.৪ Books
- **C9** — Book Library আর ক্লাস ৬ হার্ডকোড নয়; **প্রোফাইল ক্লাস**, ধারণক্ষমতা `books_public` থেকে; হেডারে “ক্লাস N · M বই”।
- **C9 (id)** — Home-এর recent book entry-তে এখন **আসল `books_public.id`** (৪র্থ অংশ); id না থাকলে লাইব্রেরি খোলে, ভুয়া `class6-…` id নয়।

### ২.৫ Practice
- **Crash** — `'কখগঘ'[i]` ৫+ অপশনে RangeError দিত। নতুন `optionLetter()` — বাংলা অক্ষর, তারপর সংখ্যা; quiz ও model exam দুটোতেই।
- **Data** — `Attempt.chapter`-এ subject id লেখা হতো (রেকর্ড নষ্ট); এখন `''` (অজানা)।
- **C11** — “Try Again” ডেমো ৫-প্রশ্ন ব্যাংক নিত; এখন **একই প্রশ্নগুলোই** (`attempt.answers` → `findQuestion`), না মিললে ব্যাংক fallback।
- **C15** — Results-এর “আবার পড়ো” সিলেকশন ছাড়া ভুল পেজ (ম্যাথ ৪৫) খুলত; এখন **বই লাইব্রেরি**।

### ২.৬ Admin/ডক
- `docs/full-ui-audit-2026-11-21.md`-এ **অবস্থা আপডেট** টেবিল যোগ (কোনটা ✅, কোনটা ⏸)।
- `test/audit_fixes_test.dart` (৪ টেস্ট): classChoices ১–১০, bookmark separation, legacy saved filter, saved toggle।
- `test/learn_class_progress_test.dart`-এ `chapterOpened` কেস।

---

## ৩. যাচাই

- `flutter analyze`: **০ error, ০ warning** (১৭টি আগের `deprecated_member_use` info অপরিবর্তিত)।
- **ফুল টেস্ট: ৯১৩/৯১৩ পাস** (১২টি চাঙ্কে, প্রতিটি fresh compiler cache; শেষ দুই চাঙ্ক প্রথম রানে দুটি পুরোনো source-guard টেস্টে ফেল করেছিল — টেস্টগুলো নতুন আচরণে আপডেট করা হয়েছে, এখন সব পাস)।
- আক্রান্ত প্রতিটি ফাইল/ফিচারের টেস্ট আলাদা রানেও পাস।
- **টেস্ট ডেস্কটপে চলে; ফোনের আচরণ প্রমাণ করে না** — নিচের চেকলিস্ট ফোনে দেখতে হবে।

---

## ৪. যা ইচ্ছাকৃতভাবে করা হয়নি (সিদ্ধান্ত/ব্যাকএন্ড/ডিভাইস দরকার)

| আইটেম | কেন থামানো হলো | দরকার |
|---|---|---|
| **C4 Voice Tutor আসল কল** | Gemini Live transport + key + audio pipeline | Play/keys decision; এখনো ডেমো টাইমার |
| **C7 SMS OTP** | Supabase Phone Auth + SMS খরচ | ইউজার সিদ্ধান্ত (খরচ) — এখন শুধু সৎ কপি |
| **C8 Book Reader** | আসল পৃষ্ঠা টেক্সট/PDF পাইপলাইন + লাইসেন্স | কনটেন্ট সিদ্ধান্ত |
| **C10 Model Tests** | “বোর্ড-স্ট্যান্ডার্ড টেস্ট” কীভাবে তৈরি হবে (গাইড সেট থেকে?) | প্রোডাক্ট সিদ্ধান্ত |
| **Notifications pipeline** | push/local notification প্লাগইন + ইভেন্ট নীতি | কোন ইভেন্টে রিমাইন্ডার (সিদ্ধান্ত) — এখন শেল সৎ |
| **Support email (H34)** | Play listing-এ আসল ইমেইল দরকার | ইউজার ইমেইল |
| **Legacy রুট বাদ দেওয়া** | ফাইল ডিলিট নিষিদ্ধ / রাউট সিদ্ধান্ত | ইউজার সিদ্ধান্ত |
| **আসল weak-chapters হোম কার্ড** | ProgressSummary plumbing | পরের ফেজ (P2-বাকি) |
| **Practice-by-subject সব বিষয়** | subject list plumbing in PracticeScreen | পরের ফেজ |
| **আনসারে prev/next** | পেজিং state মডেল বদলাতে হবে | পরের ফেজ |

---

## ৫. বাকি কাজের ক্রম (সকালে শুরু করার জন্য)

1. **ফোনে স্মোক** (নতুন বিল্ড): লগইন → OTP (কুলডাউন) → হোম → সাবজেক্ট (গ্রুপিং/ব্যাজ/সার্চ) → গাইড পিকার (ক্লাস ১–১০, অধ্যায়-সংখ্যা) → উত্তর (AI ব্যাখ্যা লেবেল) → চ্যাট (অটো-স্ক্রল) → বই লাইব্রেরি (ক্লাস) → প্র্যাকটিস/রেজাল্ট (retake একই প্রশ্ন)।
2. **C10/C11-এর বাকি:** আসল মডেল টেস্ট = গাইড সেট থেকে generator (server/edge)।
3. **Notifications:** `flutter_local_notifications` + ইভেন্ট নীতি (আপনার সিদ্ধান্ত).
4. **Practice subjects:** সব সাবজেক্টের কার্ড।
5. **Home pull-to-refresh + weak chapters আসল ডেটা।**
6. **Support email** সেট হলে Help/FAQ + Play Data Safety।

---

## ৬. ঝুঁকি ও রোলব্যাক

- সব পরিবর্তন **স্থানীয় UI/লজিক**; কোনো DB স্কিমা/এজ ফাংশন বদলানো হয়নি, কিছু ডিপ্লয়ও হয়নি।
- কোনো স্ক্রিন অপ্রত্যাশিত লাগলে: `git revert <hash>` (প্রতি ব্যাচ আলাদা কমিট)।
- ফন্ট/লেবেল বদলেছে বলে কিছু পুরোনো স্ক্রিনশট-টেস্ট থাকলে নাম মিলবে না — বাস্তব টেস্টগুলো পাস করেছে।

---

## ৭. নোট: এই ওয়ার্কস্পেসে টেস্ট রান

`flutter test` একবারে পুরো স্যুট চালালে মাঝে মাঝে একটি ফাইল “loading” অবস্থায় আটকে যায় (Windows + OneDrive `build/test_cache` লক)। সমাধান: `C:\Users\rajsh\AppData\Local\Temp\opencode\ysa-db\run-chunks.ps1` — ১২ ফাইল করে fresh cache-এ চালায়। CI-তে (F1) `--concurrency` সীমিত রাখা বা Linux রানার ব্যবহার করা ভালো।

---

## ৯. রাতের দ্বিতীয় অংশ (P8–P11) — সাপোর্ট, OTP, Reader, নোটিফিকেশন

### ৯.১ সাপোর্ট ও Play URL (commit `1c199a1`)
- `rajshahi.jibon@gmail.com` — Help/FAQ ক্লিকেবল + About-এ
- নতুন **`docs/account-deletion.html`** (bn+en, ইন-অ্যাপ + ইমেইল পথ) — Play-এর বাধ্যতামূলক URL
- About-এ Privacy / Terms / **Account deletion** তিনটি লিংক; “ডেমো টার্মস” লেবেল বাদ
- `lib/core/services/contact_info.dart` — এক জায়গায় ইমেইল + তিনটি URL

### ৯.২ আসল ফোন OTP — httpSMS (commit `15e458b`)
- **`supabase/migrations/023_phone_otps.sql`** — server-only টেবিল (hash, expiry, attempts); লাইভে প্রয়োগ হয়েছে (Management API SQL)
- **`supabase/functions/phone-otp`** (v3, `verify_jwt=false`):
  - ৬-ডিজিট কোড, SHA-256 হ্যাশ (pepper secret), ৫ মিনিট expiry
  - ৬০s cooldown, দিনে ৫টি, ৫ ভুলে কোড বাতিল
  - httpSMS: `POST https://api.httpsms.com/v1/messages/send` (`x-api-key`, `from`, `to` string)
- **লাইভ টেস্ট:** `send` → 200 `{ok:true}` (SMS গেছে), ভুল কোড → `wrong` + attemptsLeft
- **সিক্রেট:** `HTTPSMS_API_KEY`, `HTTPSMS_FROM_NUMBER (+8801721013902)`, `OTP_PEPPER` — শুধু function secrets-এ, কোডে নেই
- অ্যাপে: `auth_phone_service` Edge-এ যায়; **Step 9 ahora ৬ ডিজিট + আসল যাচাই**; লগইনের “OTP” লিংক বাদ (সেশন বানায় না, তাই ভুয়া লগইন হতো)

### ৯.৩ Book Reader — আসল পৃষ্ঠার লেখা (commit `15e458b`)
- `guide-bank` **v35**-এ নতুন `action:'pageText'` — `book_chunks` (migration 007) থেকে **প্রিন্টেড পৃষ্ঠার OCR টেক্সট**; কোনো নতুন OCR/স্টোরেজ নেই
- লাইভ যাচাই: `class6-math-bn` p10 → ৫৫৮৩ অক্ষর, pages 8–11
- Reader এখন আসল লেখা দেখায় + **OCR সতর্কতা** (“উত্তরের চাবি নয়”); না পেলে সৎ “লোড করা যায়নি”
- ⚠️ কিছু বই (যেমন class9 chemistry)-এ ওই পৃষ্ঠার chunk নেই → সৎ empty

### ৯.৪ লোকাল নোটিফিকেশন (commit পরবর্তী)
- `flutter_local_notifications` + `timezone` + desugaring + manifest receivers/permission
- ৭টি শিডিউল: দৈনিক পড়া (৭টা), স্ট্রিক (৯:৩০), দৈনিক গোল (৮টা), সাপ্তাহিক মডেল টেস্ট (শনি ১০টা), সাপ্তাহিক রিপোর্ট (রবি ৬টা), সেভ-প্রশ্ন রিভিশন (৮টা), + new-content (অ্যাপ খোলার সময় ভার্সন বদলালে একবার)
- Settings-এর ৩টি সুইচ এখন **আসল** — সেভ করলেই reschedule
- সব inexact alarm (ব্যাটারি/অনুমতি ঝামেলা নেই)

### ৯.৫ অন্যান্য (commit `1a7f3b3`)
- চ্যাট: AI টেক্সট **selectable (long-press copy)** + ফেল হলে **Retry** বার
- ক্লাস ১–৫: “শীঘ্রই আসছে” কার্ড (ভুয়া লেসন নেই)
- `/search` → `/search-flow`, `/practice-tab` → `/practice` redirect
- SEO/সিক্রেট স্ক্যান: কোনো key/token কোডে বা ডকে নেই

---

## ১০. নতুন বিল্ড (সকালের জন্য)

- **zip:** `C:\Users\rajsh\Downloads\yes-sir-ai-app-2026-11-22.zip` (৮৬৮ এন্ট্রি, ২.৬ MB)
- আছে: সব নতুন কোড + `supabase/functions` + keystore + `key.properties` + `dart_defines.json` + দুই ডক
- নেই: `.git`, `build`, `.dart_tool`
- বিল্ড: `flutter build apk --release --dart-define-from-file=dart_defines.json`
- ⚠️ zip-এ keystore + পাসওয়ার্ড আছে — শেয়ার করবেন না।
- **সার্ভার:** guide-bank v33 আগেই ডিপ্লয় করা (এই রাতের UI পরিবর্তনে নতুন ডিপ্লয় লাগে না)। Access token revoke করে দিয়েছেন ধরে নিচ্ছি।

