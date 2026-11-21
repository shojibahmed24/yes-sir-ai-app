# থিম ও কালার ওভারহল — প্ল্যান (2026-11-23)

> লক্ষ্য: লগইন থেকে প্রতিটি স্ক্রিন — **এক ব্র্যান্ড পরিবার, গ্রেডিয়েন্ট, স্পষ্ট হায়ারার্কি, WCAG AA কনট্রাস্ট**। এখনকার উষ্ণ কাগজ + কুল নীল/ভায়োলেট মিশ্রণ এবং একাধিক গ্রেডিয়েন্ট পরিবারকে এক করা।
>
> **নোট:** এটি শুধু “কালার বদল” নয় — সম্পূর্ণ ভিজ্যুয়াল সিস্টেম (কালার, টাইপোগ্রাফি, স্পেসিং, শেপ/রেডিয়াস, এলিভেশন, মোশন, আইকন, কার্ড ও কম্পোনেন্ট, dark mode)। নিচের রিসার্চ ও ৭টি লেয়ার তার ভিত্তি।

## ০. রিসার্চ ও বেঞ্চমার্ক

**প্রফেশনাল লার্নিং অ্যাপগুলো কী করে:**
- **Duolingo:** একটাই ব্র্যান্ড সবুজ; কার্ড সাদা, বড় রেডিয়াস; সব স্টেট (সঠিক/ভুল) একই রঙ-পরিবারে; typography মাত্র ৩ স্তর।
- **Khan Academy:** নিউট্রাল ক্যানভাস + একটাই অ্যাকসেন্ট; বিষয় রঙ শুধু আইকনে; কার্ডে বর্ডার, ভারী শ্যাডো নয়।
- **10 Minute School:** ব্র্যান্ড গ্রেডিয়েন্ট হিরোতে, বাকি সব সাদা কার্ড; gold শুধু প্রিমিয়াম; স্পষ্ট সেকশন হেডার।
- **Notion/Linear (SaaS মান):** ৮pt স্পেসিং গ্রিড, ৩-স্তরের টেক্সট (primary/secondary/muted), হেয়ারলাইন বর্ডার, soft elevation, সীমিত মোশন।
- **সাধারণ নিয়ম:** ১ ব্র্যান্ড + ১ নিউট্রাল পরিবার + সেমান্টিক ৩টি (success/warning/error) + বিষয়-রঙ শুধু accent; কার্ড সারফেস কখনো বিষয়-রঙে ভরা নয়।

**আমাদের এখনকার বিচ্যুতি:** ৩ গ্রেডিয়েন্ট পরিবার, উষ্ণ ক্যানভাস + কুল ব্র্যান্ড, কার্ড/ক্যানভাস পার্থক্য কম, ২-৩ ধরনের কার্ড স্টাইল, muted টেক্সটে কনট্রাস্ট ঘাটতি, স্ক্রিনে হার্ডকোড রঙ।

## ০.১ ভিজ্যুয়াল সিস্টেমের ৭ লেয়ার (যা বদলাবে)

1. **Color tokens** — brand/neutral/semantic/subject + dark সেট
2. **Gradient** — এক ব্র্যান্ড পরিবার; premium গোল্ড আলাদা; সাবজেক্ট গ্রেডিয়েন্ট শুধু হিরো-থাম্বে
3. **Typography** — display/headline/title/body/label/muted; একই ফন্ট-স্কেল, সর্বোচ্চ ৩ ওজন
4. **Spacing** — ৮pt গ্রিড (`Sp`), স্ক্রিন প্যাডিং/সেকশন গ্যাপ/কার্ড প্যাডিং এক
5. **Shape/elevation** — এক রেডিয়াস স্কেল (`Rad`), কার্ড = border + soft shadow (dark-এ শ্যাডো বাদ)
6. **Components** — Card, Button (primary/secondary/danger), Input, Chip/Badge, SectionHeader, EmptyState, Skeleton, Hero
7. **Motion & icons** — stagger শুধু প্রথম ৬, 150–250ms, reduce-motion সম্মান; এক আইকন পরিবার

## ১. এখনকার অডিট (কোড থেকে)

| টোকেন | বর্তমান | সমস্যা |
|---|---|---|
| Canvas | `#FBF6EC` (উষ্ণ ক্রিম) | নীল/ভায়োলেট ব্র্যান্ডের সাথে ঠান্ডা-গরম সংঘর্ষ |
| Card | `#FFFDF8` | কার্ড/ক্যানভাস পার্থক্য কম → ফ্ল্যাট দেখায় |
| Ink | `#26231F`, `#5E5850`, `#9C9388` | muted টেক্সট ৪.৫:১-এর নিচে কোথাও |
| Brand | `#2F6FED` / `#1E4FBF` | ভালো, কিন্তু সেকেন্ডারি ভায়োলেটের সাথে দিক হারায় |
| Gradients | hero blue→violet, premium amber→violet, subject ৩টি | **৩ পরিবার** — একসাথে দেখলে অপরিকল্পিত |
| Subject | ৬টি রঙ | কিছু রঙ ব্র্যান্ডের সাথে লড়ে; guide/board/accent আলাদা |
| Dark | আলাদা সেট | ইনভার্সনে কার্ড বর্ডার/শ্যাডো অসঙ্গত |

**সিদ্ধান্ত:** “উষ্ণ কাগজ” ছেড়ে **নিউট্রাল ক্যানভাস + ব্র্যান্ড গ্রেডিয়েন্ট**; সাবজেক্ট রঙ শুধু আইকন/অ্যাকসেন্ট, বড় সারফেসে নয়।

## ২. নতুন টোকেন (এক সোর্স: `app_theme.dart` + `app_tokens.dart`)

**ব্র্যান্ড (Indigo → Teal নয়; Deep Indigo → Violet, একটাই পরিবার)**
- `brand600 #4F46E5`, `brand700 #4338CA`, `brand800 #3730A3`
- `brandGradient` = `#4338CA → #6D28D9` (135°)
- `brandSoft #EEF2FF` (চিপ/ব্যাজ)
- `accent #0EA5E9` (লিংক/হাইলাইট), `gold #F59E0B` (premium)

**নিউট্রাল (কুল-নিউট্রাল, উষ্ণ নয়)**
- Canvas `#F7F8FC` · Surface `#FFFFFF` · SurfaceAlt `#EEF1F8`
- Border `#E3E7F0` · Ink `#111827` · Ink2 `#4B5563` · Ink3 `#6B7280`
- Dark: Canvas `#0B1020` · Surface `#121933` · SurfaceAlt `#1A2342` · Border `#26304D` · Ink `#F3F4F6`

**সেমান্টিক:** success `#16A34A`, amber `#D97706`, error `#DC2626`, premium gold gradient `#B45309 → #7C3AED`

**সাবজেক্ট (শুধু accent):** indigo, emerald, orange, violet, teal, cyan, amber — একই saturation/lightness ব্যান্ডে।

## ৩. গঠন (কম্পোনেন্ট)

1. **Card:** surface + 1px border + soft shadow (dark-এ shadow বাদ, border রাখা) — সব স্ক্রিনে এক
2. **Hero:** একটাই ব্র্যান্ড গ্রেডিয়েন্ট + হোয়াইট টেক্সট; সাবজেক্ট গ্রেডিয়েন্ট শুধু সাবজেক্ট ডিটেইল হিরোতে
3. **Badge/Chip:** brandSoft ব্যাকগ্রাউন্ড + brand700 টেক্সট; success/amber আলাদা
4. **Button:** প্রাইমারি = brandGradient; সেকেন্ডারি = surface+border; ডেঞ্জার = error
5. **Input:** surface, border, focus = brand600 (২px), error = error
6. **Section header:** Ink + ছোট Ink3 subtitle
7. **Empty/Info:** SurfaceAlt + Ink2; কোনো লাল নয়

## ৪. স্ক্রিন ম্যাপিং

- **Auth/Onboarding/Registration:** brandGradient hero/লোগো রিং, সাদা কার্ড ফর্ম, brand soft chips
- **Home/Dashboard:** hero gradient, সাদা কার্ড, gold শুধু XP/premium
- **Subjects/Chapters:** সাবজেক্ট accent আইকন-টাইল; কার্ড সাদা
- **Search/Guide:** একই কার্ড/চিপ; sticky bar = surface+border
- **Practice/Quiz:** প্রাইমারি brand; correct=success, wrong=error; timer = amber chip
- **Progress/Achievements:** brand ring, gold ব্যাজ, সাদা গ্রিড কার্ড
- **Profile/Settings:** hero gradient, গ্রুপ কার্ড SurfaceAlt
- **Premium/Voice:** gold→violet শুধু premium হিরো; বাকি সব brand
- **Books:** কভার থাম্ব = সাবজেক্ট gradient; কার্ড সাদা

## ৫. ফেজ

| ফেজ | কাজ | Acceptance |
|---|---|---|
| T1 | টোকেন রিপ্লেস (canvas/surface/border/ink/brand + dark) | সব স্ক্রিন নতুন রঙ পায়; analyze ০ |
| T2 | এক গ্রেডিয়েন্ট পরিবার; premium আলাদা; সাবজেক্ট palette harmonize | কোনো স্ক্রিনে পুরোনো নীল/অ্যাম্বার গ্রেডিয়েন্ট নেই |
| T3 | Card/Button/Input/Chip এক কম্পোনেন্ট সেটে + typography/spacing/radius audit | ডুপ্লিকেট স্টাইল শূন্য; ৮pt গ্রিড |
| T4 | Auth → Home → Subjects → Search → Practice স্ক্রিন-বাই-স্ক্রিন পাস | স্ক্রিনশট তুলনা |
| T5 | Profile/Settings/Progress/Achievements/Premium/Voice/Books | একই ভাষা |
| T6 | dark mode + contrast + a11y + motion যাচাই | ৪.৫:১; সিস্টেম ফন্টে ভাঙে না |

## ৬. ঝুঁকি

- `AppTheme`-এর নাম ধরে অনেক টেস্ট/স্ক্রিন — **নাম অপরিবর্তিত** রেখে শুধু মান বদলাব (সবচেয়ে নিরাপদ)।
- সাবজেক্ট রঙ শুধু accent-এ সীমিত রাখলে কার্ডে রঙের বাহুল্য কমবে, ব্র্যান্ড এক থাকবে।
- পুরোনো হার্ডকোড `Color(0x...)` স্ক্রিনে আছে — T3-এ `AppTheme`-এ সরাব।

**সুপারিশ:** T1+T2 একসাথে (এক কমিট), তারপর স্ক্রিন-বাই-স্ক্রিন T4/T5। এতে পুরো অ্যাপ এক ধাপেই নতুন দেখাবে, ঝুঁকি কম।
