# Yes Sir AI — UI Revamp Plan (ডিজাইন-ড্রাইভেন, ফেজ-ভিত্তিক)

> তারিখ: ২০২৬-১১-২০ · Status: **অনুমোদনের অপেক্ষায়** (কিছু বিল্ড হয়নি)
> লক্ষ্য: অ্যাপকে **professional + colorful + eye-catchy + animated + fast** করা।

---

## ১. উদ্দেশ্য (কেন)

অ্যাপের ব্যাকএন্ড/লজিক আগে থেকেই শক্ত (৮৩৪+ টেস্ট)। এখন UI-কে প্রথম শ্রেণির
পণ্য-মানের করতে হবে যাতে ছাত্র/অভিভাবক খোলার সাথে সাথেই “সাজানো, জীবন্ত, দ্রুত”
বোধ করে। মূল উদ্দেশ্য **পারসেপশন ও এনগেজমেন্ট**, কার্যকারিতা পরিবর্তন নয়।

## ২. Goal / Non-goal / Anti-goal

**Goal**
- পুরো অ্যাপে একই নকশা-ভাষা (টোকেন/কালার/মোশন) ধারাবাহিকভাবে ছড়ানো।
- স্ক্রিনগুলো animated ও responsive লাগে, কিন্তু দ্রুত থাকে (কোনো jank নয়)।
- প্রতিটি সাবজেক্টের নিজস্ব রঙের পরিচয় স্পষ্ট (colorful)।
- গুরুত্বপূর্ণ নেভিগেশন/স্টেট এক নজরে বোঝা যায় (eye-catchy hierarchy)।

**Non-goal**
- নতুন ব্যাকএন্ড/ডেটাবেস কাজ, নতুন payment, নতুন AI feature — এগুলো নয়।
- সম্পূর্ণ নতুন রঙ-প্যালেট বা ফ্রেমওয়ার্ক বদল — বিদ্যমান Warm Paper Scholar
  সিস্টেম **পুনর্ব্যবহার ও সম্পূর্ণ প্রয়োগ** করা হবে, নতুন করে বানানো নয়।

**Anti-goal (এটা হলে ব্যর্থ)**
- UI “সুন্দর” করতে গিয়ে ধীর হয়ে যাওয়া (জ্যাঙ্ক, লম্বা অ্যানিমেশন)।
- WCAG/কনট্রাস্ট ভেঙে পড়া, Reduced-motion ইউজারদের জন্য চলতে থাকা মোশন।
- বাংলা/ইংরেজি স্ট্রিং-এর মাঝে হার্ডকোড টেক্সট ঢুকে পড়া।
- ফাইল ২৫০ লাইনের ওপরে যাওয়া, বা টেস্ট ভেঙে যাওয়া।

## ৩. সীমাবদ্ধতা (Constraints)

- প্রতি Dart ফাইল ≤ ২৫০ লাইন (target ১৫০–২০০)।
- সব UI লেখা bilingual (bn/en), page-wise `lib/l10n/pages/*`।
- অ্যানিমেশন duration tokens-এ (micro 150 / standard 250 / entrance 300 /
  celebration 600 ms), `reducedMotion()` হলে মোশন বন্ধ।
- কোনো নতুন dependency নেই (Flutter built-in + বিদ্যমান `go_router`/theme)।
- রঙ শুধু `AppTheme`/`DarkPalette`/`LightPalette` থেকে; ফাইল-লেভেল `Color(0x…)` নয়।
- কোনো secret/DB write/Play publish/ফাইল ডিলিট নেই।

## ৪. বর্তমান অবস্থা (অডিট, ২০২৬-১১-২০)

**ডিজাইন সিস্টেম আছে এবং ভালো:**
- `lib/theme/` — `app_theme.dart` (ব্র্যান্ড + সাবজেক্ট কালার + ৬ গ্রেডিয়েন্ট),
  `app_tokens.dart` (`Sp`/`Rad`/`Elev`/`IconSize`), `motion.dart` (৫ duration),
  `app_theme_builder.dart` (light/dark এক builder)।
- কম্পোনেন্ট আছে: `AnimatedCard`, `StaggeredList`, `ShimmerCard`,
  `AnimatedProgress`, `AppBackground`, `ThemedScaffold`, `AppStateView`,
  `SectionHeader`, `MarksBadge`, `McqOptionCard`, `AppChip`।

**কিন্তু ব্যবহার কম (মাপা হয়েছে):**

| কম্পোনেন্ট/টোকেন | ব্যবহার (রেফারেন্স) |
|---|---|
| `ThemedScaffold` | ৬৫ ✅ |
| `AppStateView` | ১০ |
| `SectionHeader` | ৯ |
| `MarksBadge` | ৭ |
| `ShimmerCard` | ৬ |
| `McqOptionCard` / `AppChip` | ৬ / ৬ |
| `AppBackground` | ৬ |
| `AnimatedCard` | ৪ |
| `StaggeredList` | ৩ |
| `AnimatedProgress` | ২ |

- `Elev.` / `IconSize.` টোকেন ফিচার-ফাইলে প্রায় **০** — স্পেসিং/রেডিয়াস/এলিভেশন
  কোথাও কোথাও loose সংখ্যা।
- হার্ডকোড `Color(0x…)` ফিচার-ফাইলে **মাত্র ৩-৪টি** (ভালো) — এর মানে কালার
  তেমন ছড়ানো হয়নি; সাবজেক্ট-কালার ব্যবহার আরও বাড়ানো যায়।
- অ্যানিমেশন প্রায় **অনুপস্থিত** — হোম গ্রিড/লিস্ট/হাব সব static রেন্ডার।
- টাইপোগ্রাফি: `guide_answer_body.dart`-এ ৯টি `fontSize:` লিটারাল — অ্যাপ টেক্সট
  থিমের বদলে হাতে বসলেছে; আরও ~৪০টি ফাইল একই প্যাটার্নে।
- **রিগ্রেশন (আমারই):** `global_picker_tree.dart` এখন **২৬১ লাইন** (২৫০+), আমি
  English-2nd নোট যোগ করে পেরেছি — আগে ঠিক করতে হবে।

**স্ক্রিন ইনভেন্টরি (~৭০ রুট):**
- Journey 1 (শেখা): Home → Subjects hub → Chapter list → Lesson hub → Search-flow
  → List → Guide answer / MCQ / creative / quiz / model test / board।
- Journey 2 (অনুশীলন): Practice hub → daily/weak quiz → model tests → results।
- Journey 3 (অগ্রগতি): Progress → Achievements → today-lessons / opened-chapters।
- Journey 4 (আকাউন্ট): Profile → Settings / Parent PIN / Parent dashboard /
  Premium paywall / Voice tutor / Saved / Help / About।
- Journey 5 (আগে): Splash → Onboarding (৩) → Login/OTP → Registration (১৩ ধাপ)।

## ৫. Approach (কোন পথে বানাবো)

**বিকল্প বিবেচনা:**
1. **সম্পূর্ণ রিডিজাইন** — নতুন প্যালেট/লেআউট সব বদল। → ব্যয়বহুল, ঝুঁকিপূর্ণ,
   বিদ্যমান সুন্দর সিস্টেম ফেলে দেওয়া। ❌
2. **নতুন dependency (Lottie/Rive/টাচ-রিপল লাইব্রেরি)** — লিভলি কিন্তু বাইনারি
   বড়, slow device-এ জ্যাঙ্ক, dependency ঝুঁকি। ❌ (আপাতত)
3. **ইনক্রিমেন্টাল অ্যাডপশন (নির্বাচিত)** — বিদ্যমান টোকেন/কম্পোনেন্ট/গ্রেডিয়েন্ট
   প্রতিটি স্ক্রিনে ধারাবাহিকভাবে প্রয়োগ + lightweight Flutter built-in motion।
   → দ্রুত, নিরাপদ, “fast” গ্যারান্টেড, টেস্টযোগ্য। ✅

**ডেলিভারি নীতি:** প্রতিটি ফেজ শেষে `flutter analyze` (০ error/warning) +
`flutter test --concurrency=1` (সব সবুজ) রিপোর্ট; ছোট commit + main push।

---

## ৬. ফেজ-ভিত্তিক বাস্তবায়ন (কোথায় কী করব)

> ফেজগুলো ছোট ও নির্ভরশীল-মুক্ত রাখা হয়েছে যাতে মাঝে থামা/রিভিউ করা যায়।

### UI Phase 0 — ভিত্তি + রিগ্রেশন ঠিক (কোনো ভিজুয়াল পরিবর্তন নয়)
- `global_picker_tree.dart` (২৬১→) ভাগ করা: Paper-II সেকশন-লজিক আলাদা হেল্পারে
  নিয়ে ≤২৫০।
- টোকেন-এক্সপোজার: `Elev`/`IconSize`/`Sp`/`Rad` ব্যবহার না করা ফাইলের একটা চেকলিস্ট
  তৈরি (টার্গেট: ফেজগুলোতে adopt)।
- **verify:** analyze ০ error/warning; full suite সবুজ; কোনো রেন্ডার বদলায় না।

### UI Phase 1 — মোশন ফাউন্ডেশন (এন্ট্রান্স + micro-interaction)
- `HomeHeroCard`, `HomeStatsRow`, `HomeSubjectGrid` — `StaggeredList`/`AnimatedCard`
  দিয়ে এন্ট্রান্স; `MotionTokens.tapScale` ট্যাপ-রিপল (HeroCard/buttons)।
- `HomeSubjectGrid`-এ সাবজেক্ট-কালার বর্ডার/ব্যাজ (রঙের পরিচয়)।
- `reducedMotion()` মান্য — চলতে-থাকা মোশন বন্ধ।
- **verify:** `ui_widgets_test`-এ নতুন কেস (reduced-motion + stagger order)।

### UI Phase 2 — সাবজেক্ট কালার ও হায়ারার্কি (colorful)
- Subjects hub (`subjects_screen.dart` + `SubjectCard`) — প্রতিটি কার্ডে সাবজেক্ট
  গ্রেডিয়েন্ট হেডার + কালার অ্যাকসেন্ট; ক্লাস-সিলেক্টর চিপে সিলেক্টেড হাইলাইট।
- Chapter list (`chapters_screen.dart`) — সাবজেক্ট-কালার অগ্রগতি রিং/চেক + আইকন।
- `SectionHeader` যেখানে “action” আছে সেখানে ধারাবাহিক ব্যবহার।
- **verify:** সাবজেক্ট-কালার ম্যাপ টেস্ট; স্ন্যাপশট না-ভাঙা।

### UI Phase 3 — টাইপোগ্রাফি ও ফাইল-হেলথ (professional + consistent)
- **সংশোধন:** answer স্ক্রিনে `fontSize` হলো ইউজারের **ফন্ট-সাইজ কন্ট্রোল**
  (`onFontSmaller`/`onFontLarger`) — তাই ওই লিটারাল সরানো যাবে না; শুধু স্পেসিং
  `Sp`-এ এবং ফ্যামিলি/হাইট থিম থেকেই আসে।
- `guide_answer_body.dart` (২৫৭ → ≤২৫০): প্রশ্ন + MCQ ব্লক আলাদা
  `guide_answer_question_block.dart`-এ।
- `search_screen.dart` (২৫৪ → ≤২৫০): একটা ব্লক আলাদা helper-এ।
- সব কার্ড `AppTheme.softCardDecoration`/`Rad` ব্যবহার; বটম-nav/ডায়ালগ `Elev`।
- **verify:** analyze ০ error/warning; full suite সবুজ; ভিজুয়াল আচরণ অপরিবর্তিত।

### UI Phase 4 — স্ক্রিন-বাই-স্ক্রিন পলিশ (journey 1–4)
প্রতিটি স্ক্রিনে: এন্ট্রান্স মোশন, খালি/এরর/লোডিং স্টেট (`AppStateView`),
সেকশন হেডার, সাবজেক্ট-কালার, `Sp`/`Rad`।
- Home (Hero/Stats/Grid/LowerSections) · Subjects hub · Chapter list ·
  Lesson hub · Search-flow + list · Guide answer/MCQ/creative ·
  Quiz/Model-test screen · Results (celebration) · Progress + Achievements ·
  Profile/Settings/Parent/Premium/Voice।
- Model-test/quiz রেজাল্টে `AnimatedProgress` + celebration (৬০০ms)।

### UI Phase 5 — নতুন স্ক্রিন (প্রস্তাব, **আপনার অনুমোদন লাগবে**)
প্রস্তাবিত (বিস্তারিত §৮-এ), সব read-only + স্টোরেজ-নির্ভর, কোনো ব্যাকএন্ড ছাড়া:
1. **Study plan / Today dashboard** — আজকের টার্গেট, স্ট্রিক, “শুরু করুন” কার্ড।
2. **Subject detail** — একটি সাবজেক্টের চ্যাপ্টার/লেসন/সেটের এক-পেজ ওভারভিউ।
3. **Achievements enhance** — ব্যাজ গ্রিড + আনলক স্টেট (ইতিমধ্যে আছে, পলিশ)।
4. **Empty-state illustration** — রঙিন আইকন-ভিত্তিক (ভারী অ্যাসেট নয়)।
5. **Onboarding/Splash polish** — ব্র্যান্ড গ্রেডিয়েন্ট + এক-লাইন value।

### UI Phase 6 — পারফরম্যান্স (fast গ্যারান্টি)
- লিস্টগুলো lazy (`ListView.builder`) নিশ্চিত; `const` ব্যবহার; অপ্রয়োজনীয়
  `setState`/rebuild কমানো; shadow/গ্রেডিয়েন্ট খরচ পরীক্ষা।
- prefetch যেখানে আছে সেখানে রাখা; কোনো ব্লকিং I/O মূল থ্রেডে না।
- **verify:** `flutter run --profile`-এ jank নোট (user-এর device-এ চূড়ান্ত)।

### তারপর — Phase 7 (প্রোফাইল/প্যারেন্ট/প্রিমিয়াম পলিশ)
- এই পুরো UI-revamp শেষ হলে **আগের Phase 7** চালু: profile/settings/parent
  dashboard/premium paywall/voice tutor-এর পলিশ। (প্রিমিয়াম “কেনা” আপাতত বন্ধ —
  Play Console + server verification দরকার, এটা এই পরিসরের বাইরে।)

---

## ৭. ফাইল-ম্যাপ (কোথায় কোথায় স্পর্শ হবে)

| ফেজ | ফাইল/এলাকা |
|---|---|
| 0 | `lib/features/learn/global_picker_tree.dart` (+ নতুন helper) |
| 1 | `lib/theme/motion.dart`, `lib/theme/widgets/*` (AnimatedCard/StaggeredList), `lib/features/home/widgets/*` |
| 2 | `lib/features/home/subjects_screen.dart`, `widgets/subject_card.dart`, `widgets/class_selector.dart`, `lib/features/learn/chapters_screen.dart` |
| 3 | `lib/theme/app_text_theme.dart`, `lib/features/learn/widgets/*` (answer/solution), `lib/theme/app_theme.dart` |
| 4 | `lib/features/{home,learn,practice,progress,profile,parent,premium}/*` (স্ক্রিন-ভিত্তিক) |
| 5 | নতুন `lib/features/{today,subject_detail,…}` + `lib/l10n/pages/*_strings.dart` |
| 6 | বিদ্যমান লিস্ট/স্ক্রিনে `const`/builder/অপ্টিমাইজ |

---

## ৮. “কোন স্ক্রিন যোগ করব?” — প্রস্তাব ও সুপারিশ

**সুপারিশ (আগে করুন):**
- **Subject detail screen** — এখন সাবজেক্ট ট্যাপ সরাসরি চ্যাপ্টারে যায়; মাঝের
  “ওভারভিউ” নেই। একটি রঙিন ওভারভিউ (চ্যাপ্টার সংখ্যা, লেসন, সেট, board প্রশ্ন)
  নেভিগেশন স্পষ্ট করবে। ✅
- **Today / Study plan** — হোমে “আজকের গোল” আছে, কিন্তু আলাদা plan view নেই;
  streak + goal + আজকের সাজেশন এক জায়গায়। ✅
- **Achievements পলিশ** — ব্যাজ/মাইলস্টোন গ্রিড (ইতিমধ্যে আছে, শুধু ভিজুয়াল)।
- **Empty-state illustration** — সব খালি স্ক্রিনে রঙিন, ধারাবাহিক আইকন+টেক্সট।

**পরে / চাইলে:**
- Onboarding value-prop আপগ্রেড, Splash brand-motion, dark-mode tune।

**করবো না (এখন):** leaderboard, social, download/offline ব্যাংক — ব্যাকএন্ড
নির্ভর বা স্কোপ-বাইরে।

---

## ৯. আপনার সিদ্ধান্ত দরকার

1. **ভিজুয়াল তীব্রতা:** (ক) বিদ্যমান **Warm Paper** প্যালেট + সাবজেক্ট-কালার
   গ্রেডিয়েন্টে হালকা colorful (সুপারিশ) — ধারাবাহিক, WCAG-safe; নাকি (খ) আরও
   বোল্ড/উজ্জ্বল গ্রেডিয়েন্ট বেশি?
2. **নতুন স্ক্রিন:** §৮-এর কোনগুলো যোগ করব? (Subject detail + Today plan
   সুপারিশ; Achievements পলিশ + empty-state illustration হ্যাঁ/না)
3. **মোশন লেভেল:** হালকা-মাঝারি এন্ট্রান্স + micro-tap (সুপারিশ) — নাকি বেশি
   বাউন্সি? (Reduced-motion সবসময় মানা হবে।)
4. **শুরুর ক্রম:** UI Phase 0–6 ধারাবাহিকভাবে, প্রতি ফেজে analyze+test — রাজি?

আপনি ১–৪ উত্তর দিলেই আমি প্ল্যান চূড়ান্ত করে Phase 0 থেকে বাস্তবায়ন শুরু করব।
