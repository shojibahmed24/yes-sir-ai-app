# Device-test issue log & fix plan (2026-11-21)

> উৎস: মালিকের ফোনে zip-build APK (picture 7–12 + আগের 3–6)।
> নিয়ম: প্রতিটি ফিক্সের পর analyze + targeted test, তারপর নতুন zip।

## চিহ্নিত সমস্যা (root cause সহ)

| # | লক্ষণ | Root cause (যাচাইকৃত) | Severity |
|---|---|---|---|
| I1 | “আমার সম্পর্কে” ফাঁকা গ্রে পেজ | বাংলা l10n ম্যাপে `privacy` key ছিল না → `s['privacy']!` null crash | **FIXED** (key যোগ) |
| I2 | প্রোফাইলে ছবি আছে, হোম (ড্যাশবোর্ড) avatar-এ নেই | `HomeTopBar` শুধু নাম থেকে initial আঁকে; সেভ করা ছবি পড়ে না | HIGH |
| I3 | ছবি ডেটাবেজে সেভ হয় না | Supabase Storage bucket + RLS policy নেই → upload ব্যর্থ, শুধু লোকাল ফাইল | HIGH |
| I4 | হোমে “বিষয় লোড হচ্ছে…” শেষ হয় না, স্ট্যাট 0 | `loadHomeData` future memo + subject/guide-flag কলে ব্যর্থতা; ব্যর্থতা হোমে সঠিকভাবে দেখানো/retry নেই | HIGH |
| I5 | Subjects স্ক্রিনে সব লক, “০টি অধ্যায়”, “বই এখনো দেওয়া হয়নি” | Class 9-এ `books_public.supplied` সব false (guide-only বই); locked লজিক guide availability দেখে না (আর guide-flags Edge কলও slow/fail) | **CRITICAL (product)** |
| I6 | Science পিকেର: “লোড হচ্ছে…” তারপর “কোনো আইটেম পাওয়া যায়নি” | `edge_post` টাইমআউট ৩০s → **১২s** কমানো; ভারী guide call (chapters/lessons/flags) মোবাইল নেটে টাইমআউট → null → “unavailable/empty” | **CRITICAL (regression)** |
| I7 | MCQ তালিকা: “সার্ভার পাওয়া যায়নি — আবার চেষ্টা করুন” | একই টাইমআউট/ব্যর্থতা; guideline: ব্যর্থতা আর সত্যিকারের ০ রো আলাদা করা হয়নি | HIGH |
| I8 | English পিকার কাজ করে, বাকিরা না | English path হালকা (static sections + sets cache); বাকিরা per-type/lesson count + flags = বেশি ভারী call → টাইমআউটে আগে পড়ে | MEDIUM |

**লাইভ যাচাই (আজ):** guide-bank `list/guideChapters/guideLessons/sets` সার্ভারে 200; Class 9 `books_public` ১৬ রো, supplied=true **০** → I5 নিশ্চিত ডেটা-লজিক, শুধু নেটওয়ার্ক নয়।

## Fix plan (phase to phase)

### P1 — লোডিং/নেটওয়ার্ক রিগ্রেশন (সবার আগে)
- [ ] `edge_post` টাইমআউট ফেরানো: open 30s, body 45s (আগের আচরণ), অথবা per-call override।
- [ ] ব্যর্থ হলে স্ক্রিনে স্পষ্ট “সার্ভারে পৌঁছায়নি + Retry” (empty থেকে আলাদা)।
- [ ] Sub-instrument: response status + duration log (debug-only)।
- [ ] যাচাই: ফোনে সাবজেক্ট/সায়েন্স/মডেল টেস্ট খোলা।

### P2 — Subject availability (guide-only unlock)
- [ ] Locked শুধু তখন, যখন **বই নেই এবং গাইডও নেই**; গাইড থাকলে আনলক (Guide-only ফ্লো)।
- [ ] `০টি অধ্যায়` এর বদলে “গাইড প্রশ্ন” সংখ্যা দেখানো।
- [ ] হোম গ্রিডের loading → একবার fetch + retry state।
- [ ] টেস্ট: class 9 subject → unlocked (guide), class 6 supplied → unlocked, কোনো বই/গাইড নেই → locked।

### P3 — Profile ছবি end-to-end
- [ ] Storage bucket `avatars` (private) + owner-only RLS (মাইগ্রেশন)।
- [ ] Upload → signed/public URL → `profiles.avatar_url`-এ সেভ; ব্যর্থ হলে সৎ নোট।
- [ ] হোম avatar-এ ছবি (initial fallback), profile hero-র সাথে একই সোর্স।
- [ ] টেস্ট: local-only → DB URL, URL থাকলে home-এ ছবি।

### P4 — পিকার একরকম
- [ ] English-2nd/English-1st আর সাধারণ guide পিকার: একই count/loading/empty প্যাটার্ন।
- [ ] skeleton শুধু pending-এ; ব্যর্থ হলে error + retry।

### P5 — Empty vs failure
- [ ] সব guide/lesson লিস্টে: `found:true,total:0` = “কিছু নেই”, request fail = “সার্ভারে পৌঁছায়নি”।
- [ ] মডেল টেস্ট সেট লিস্টেও একই।

### P6 — রিগ্রেশন গার্ড
- [ ] l10n প্যারিটি টেস্ট (bn/en key set সমান) — About-এর মতো ক্র্যাশ ঠেকাতে।
- [ ] টাইমআউট/অ্যাভেইলেবিলিটি ইউনিট টেস্ট।
- [ ] প্রতিটি ফেজ শেষে analyze + full suite + নতুন zip।

> মালিকের আরও ইস্যু এলে এই টেবিলে যোগ হবে; P1 তারপর শুরু।
