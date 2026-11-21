# স্ক্রিন-প্রফেশনালাইজেশন প্ল্যান (ড্যাশবোর্ড-মান)

> ড্যাশবোর্ড এখন hero + hero-stats + goal ring + quick actions + plan + chart + weak topics + %, সব কার্ড-ভিত্তিক।
> বাকি স্ক্রিনগুলোর বড় অংশ এখনো “ফাংশনাল ফর্ম” — কার্ড/হেডার/খালি-অবস্থা/মোশন একরকম নয়। এই ডক সেই ফাঁকটাই তালিকা করে।

---

## ১. স্ট্যান্ডার্ড (যা প্রতিটি স্ক্রিনে থাকবে)

1. **হেডার:** টাইটেল + সাবটাইটেল + ১টি প্রাইমারি অ্যাকশন (স্ক্রল করলেও বোঝা যায় কোথায় আছি)
2. **কার্ড-ভিত্তিক গ্রুপিং:** এক কার্ড-স্টাইল (`AnimatedCard`), সেকশন হেডার + কাউন্ট
3. **আইকন-টাইল:** tinted rounded square + subject colour (SaaS-স্টাইল)
4. **স্টেট:** loading **skeleton**, empty (ইলাস্ট্রেশন/আইকন + পরের ধাপ), error + retry
5. **মোশন:** প্রথম ৬টি আইটেমে stagger, ট্যাপ-স্কেল
6. **বটম-অ্যাকশন বার:** প্রাইমারি CTA সবসময় নিচে sticky (quiz/registration)
7. **টাইপোগ্রাফি/স্পেসিং টোকেন:** `Sp`, `Rad` — র্যান্ডম ১২/১৬ নয়
8. **bn/en** সব টেক্সট; সংখ্যা `numStr`

---

## ২. স্ক্রিন তালিকা — অগ্রাধিকার অনুযায়ী

### Tier A — সবচেয়ে বেশি “plain” (আগে করব)

| স্ক্রিন | এখন | দরকার |
|---|---|---|
| **Login** (`auth/login_screen.dart`, ০ কার্ড) | প্লেইন ফিল্ড + বাটন, ভাষা টগল | ব্র্যান্ড হেডার/ইলাস্ট্রেশন, কার্ডে ফর্ম, “or” ডিভাইডার, social বাটন স্টাইল, error inline, busy state |
| **Onboarding (৩ ধাপ)** | টেক্সট + নেক্সট | প্রতি ধাপে ইলাস্ট্রেশন/আইকন, progress dots, স্কিপ, অ্যানিমেশন |
| **Registration (১৩ ধাপ)** | দুই রকম scaffold | একই `RegScaffold`: ধাপ-প্রগ্রেস বার, সেকশন কার্ড, বটম sticky CTA, ইনলাইন ভ্যালিডেশন |
| **Profile** | hero + টাইল | অ্যাভাটার রিং, স্ট্যাট গ্রিড (স্ট্রিক/XP/মেডেল), অ্যাকশন গ্রিড, প্রিমিয়াম স্ট্যাটাস চিপ |
| **Settings** | এক কার্ড + কয়েক সেকশন | গ্রুপ-কার্ড (Account / Appearance / Notifications / AI / Danger), সেভ-বার sticky, সেভ-স্ট্যাটাস |
| **Progress** | hero + ৩ কার্ড | période সিলেক্টর (৭/৩০ দিন), চার্ট, subject-wise breakdown, achievements strip |
| **Achievements** | ব্যাজ কার্ড | গ্রিড + লক/আনলক ভিজ্যুয়াল, ফিল্টার, শেয়ার |
| **Quiz / Model exam** | ৬ বাটন একসাথে | প্রশ্ন-কার্ড ফোকাস, অপশন টাইল প্রমinence, টাইমার চিপ, নেভিগেশন গ্রিড, exit confirm, submit bar |
| **Results** | কার্ড + বাটন | স্কোর রিং, সেকশন-ভিত্তিক স্কোর, weak list, retry/শেয়ার CTA |
| **Premium / Voice** | hero + তালিকা | প্লান-কার্ড, ফিচার গ্রিড, entitlement ব্যাজ, voice hero + মিনিট রিং |
| **Notifications** | খালি | ইভেন্ট কার্ড, unread ব্যাজ, গ্রুপিং, প্রেফারেন্স লিংক |
| **Books library/viewer** | কার্ড | ক্লাস-হেডার, প্রগ্রেস, কভার-থাম্ব, পেজ-টেক্সট টাইপোগ্রাফি |

### Tier B — ভালো, কিন্তু ড্যাশবোর্ড-মান না

| স্ক্রিন | দরকার |
|---|---|
| **Subjects hub** | হেডার + ক্লাস চিপ + স্ট্যাট সারি; গ্রুপ হেডারে কাউন্ট ব্যাজ |
| **Search flow (picker)** | স্টেপ-ইন্ডিকেটর (ক্লাস→বিষয়→অধ্যায়→টাইপ), সিলেক্টেড-সামারি চিপ, skeleton |
| **Guide answer** | হেডার কার্ড (প্রশ্ন/মার্কস/টাইপ), সেকশন টগল, sticky “ব্যাখ্যা/চ্যাট” বার |
| **Creative group** | অংশ-নেভিগেশন (ক→ঘ) sticky, অংশ-প্রগ্রেস |
| **Lesson / Chat** | chat হেডার কমপ্যাক্ট, suggested prompts, copy/retry (আছে), font control মেনুতে |
| **Chapter questions** | ফিল্টার বার sticky, কাউন্ট চিপ |
| **Model test list** | সেট কার্ডে ব্যাজ (keyed/unkeyed), লক-কারণ (আছে), সর্ট/ফিল্টার |
| **Parent dashboard** | চাইল্ড-সিলেক্টর, période, রিপোর্ট কার্ড, PIN সেটিংস লিংক |

### Tier C — ছোট পলিশ

Help/FAQ (অ্যাকর্ডিয়ন কার্ড), About (লোগো হেডার), Saved (খালি অবস্থা), Today (কার্ড), Opened chapters (গ্রুপ কার্ড), Book lookup, No-match।

---

## ৩. শেয়ার্ড কম্পোনেন্ট (আগে বানাব)

- `StatCard(icon, value, label, accent)` — ড্যাশবোর্ড/প্রোফাইল/প্রগ্রেস
- `SectionShell(title, action, child)` — সব লিস্ট স্ক্রিন
- `EmptyState(icon, title, body, action)` — এক রকম খালি অবস্থা
- `SkeletonCard(lines)` — লোডিং
- `StickyActionBar(child)` — quiz/registration/settings save
- `StepIndicator(current, total)` — onboarding/registration/search
- `ScoreRing(value)` — results/progress
- `InfoBanner(kind)` — demo/offline/warning এক জায়গায়

---

## ৪. ফেজ

| ফেজ | স্ক্রিন | Acceptance |
|---|---|---|
| **S1** | Login, Onboarding, Registration | এক scaffold, স্টেপ বার, sticky CTA, busy/error |
| **S2** | Profile, Settings | গ্রুপ-কার্ড, hero স্ট্যাট, sticky save, সেভ-স্ট্যাটাস |
| **S3** | Progress, Achievements, Results | চার্ট + ring + période, subject breakdown |
| **S4** | Quiz, Model exam, Model list | এক প্রশ্ন-ফোকাস, exit confirm, submit bar, lock ব্যাজ |
| **S5** | Premium, Voice, Notifications | প্লান কার্ড, মিনিট ring, ইভেন্ট কার্ড |
| **S6** | Books + Tier B পলিশ | কভার/থাম্ব, step indicator, sticky bars |

প্রতি ফেজ: analyze ০, টেস্ট, ফোনে নমুনা; ড্যাশবোর্ডের টোকেন/কার্ড রিইউজ।

---

## ৫. সুপারিশ

1. **S1 দিয়ে শুরু** — লগইন/রেজিস্ট্রেশন প্রথম ইমপ্রেশন, এখন সবচেয়ে দুর্বল।
2. তারপর **S2 → S3** (প্রোফাইল/প্রগ্রেস)।
3. S4 (পরীক্ষা) সবচেয়ে বেশি সময় লাগবে — আলাদা ডিজাইন।
4. শেয়ার্ড কম্পোনেন্ট আগে বানালে বাকি সব ফেজ দ্রুত হবে।
