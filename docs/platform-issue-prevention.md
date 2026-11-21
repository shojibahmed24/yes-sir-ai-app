# প্ল্যাটফর্ম-ব্যাপী সমস্যা ও প্রতিরোধ-প্ল্যান (U1–U11)

> উৎস: ইউজার-রিপোর্ট (ক্লাস ৯ ইসলাম, ৯ পদার্থ) + লাইভ প্রোব + কোড-অডিট।
> **মূল কথা:** সমস্যাগুলো এক বিষয়/এক ক্লাসের নয় — কাঠামোগত (count model, lesson scope, part order, auth, scope)। তাই ফিক্সও হবে কেন্দ্রীয়, তারপর সব ক্লাস/বিষয়ে যাচাই।
> লগ: `docs/user-issue-log-2026-11-22.md` · অডিট টুল: `tools/audit_guide_consistency.mjs`

---

## ১. রিপোর্টের তালিকা (১১টি) ও প্রমাণ

| # | সমস্যা | প্রমাণ | মূল কারণ |
|---|---|---|---|
| U1 | চাবি আছে, তবু “গাইডে ছাপা সমাধান নেই” | row: `answer_key='জ্ঞান'`, `guide_solution` খালি | কপি **চাবি** ও **লিখিত সমাধান** গুলিয়ে ফেলে |
| U2 | সব AI ব্যাখ্যা ফেল | live: `generate` → **401 sign-in-required** | অ্যাপ Edge-এ **anon key** পাঠায়, session token নয় |
| U3 | প্রতি বিষয়ে ডুপ্লিকেট “গাইড প্রশ্ন” কার্ড | SubjectsGrid | একই গন্তব্যে দুই এন্ট্রি |
| U4 | “সারাংশসহ / শুধু ধাপ” — ক্লিকে কিছু হয় না | guide_answer_screen flags only | `_requestExplanation()` ডাকা হয় না |
| U5 | বোর্ড প্রশ্ন প্রতি অধ্যায়ে | board tile always rendered | subject-wide জিনিস chapter scope-এ |
| U6 | সৃজনশীল অংশের ক্রম/মার্ক ভুল | rows: ga=3, gha=4, ka=1, kha=2; `marksParts={"ক":1,...}` | id অ্যালফাবেটিক sort + Map |
| U7 | হেডার ৮১০ vs টাইপ ৬৪৮ | ch1: total=810, mcq=336, short=72, creative=240 rows | ৮১০ সব রো; creative রো≠গ্রুপ |
| U8 | এক অধ্যায়ে সংখ্যা আছে, একটায় নেই | ch2 tile count missing | `chapterTotals` আংশিক/ক্যাশ |
| U9 | পদার্থ ২য় অধ্যায়ে সৃজনশীল সংখ্যা নেই | lesson rows partial | lazy lesson counts partial |
| U10 | “সৃজনশীল ৩” খুললে ০ প্রশ্ন | `guideLessons 1.5=175`; `list ch2 lesson=1.5` = **0** | lesson counts subject-wide, list chapter-scoped; static lesson map ভুল অধ্যায়ে |
| U11 | কিছু মডেল সেট খোলা, কিছু লক | keyed MCQ 0 হলে lock | lock-এর কারণ UI-তে স্পষ্ট নয় |

**ছয়টি মূল কারণ:** (A) session token নেই · (B) একাধিক count model · (C) creative part order/map · (D) scope ভুল (subject-wide → chapter) · (E) ডুপ্লিকেট affordance · (F) কপি অর্থ অস্পষ্ট।

---

## ২. এক-সিস্টেম নিয়ম (Canonical rules)

### ২.১ কাউন্ট (U7/U8/U9)
- **এক সোর্স:** অধ্যায়ের সংখ্যা = অফার্ড সেকশনগুলোর যোগফল; সৃজনশীল = **গ্রুপ** (stimulus), রো নয়।
- হেডারে দুটো ভাগ: `মোট প্রশ্ন` (সব রো) ও `পড়ার প্রশ্ন` (= mcq+short+creative groups)। UI-তে দুটোই লেবেলসহ, নাহলে শুধু দ্বিতীয়টি।
- কোনো সংখ্যা অজানা হলে **পুরো লাইন** বাদ (আংশিক নয়) — সব অধ্যায়ে একই আচরণ।
- সার্ভার চুক্তি: `guideChapters` → `{chapter, mcqCount, shortCount, creativeGroupCount, otherCount}` (নতুন); পুরোনো `totalCount` থাকবে compat-এ।

### ২.২ লেসন (U9/U10)
- guide mode-এ **সার্ভার** lesson list (chapter-scoped): `guideLessons?chapter=N` — স্ট্যাটিক ম্যাপ নয়।
- count ও list একই filter (chapter + lesson) ব্যবহার করবে; না মিললে সংখ্যা দেখাবে না।

### ২.৩ সৃজনশীল (U6)
- ক্রম: `ka → kha → ga → gha` (অ্যালফাবেটিক নয়), অজানা হলে id-natural।
- মার্ক: `marks_parts` Map/List → ক=1, খ=2, গ=3, ঘ=4 (লকড নিয়ম); পেল না হলে সেই অংশে মার্ক দেখাবে না।
- stim group-এ ৪টি অংশ না মিললে গ্রুপ আঁকবে না (আংশিক গ্রুপ নয়)।

### ২.৪ স্কোপ (U5/U11)
- subject-wide জিনিস (বোর্ড, মডেল সেট) শুধু root-এ একবার।
- মডেল সেট lock = keyed MCQ 0 → কার্ডে **কারণ লেখা** + “শুরু” বাটন লুকাও (disabled নয়)।

### ২.৫ Auth (U2)
- সব ব্যক্তিগত/কোটা-বদ্ধ Edge কলে `edgeAuthToken()` (session access token); anon শুধু পাবলিক লিস্টে।

### ২.৬ ডুপ্লিকেট (U3/U4)
- এক গন্তব্য = এক এন্ট্রি; ব্যাখ্যার দুই বাটন = একই generation, শুধু display mode।

---

## ৩. অডিট পদ্ধতি (সব ক্লাস/বিষয়)

`tools/audit_guide_consistency.mjs` চালান:
```
node tools/audit_guide_consistency.mjs 6 7 8 9 10
```
আউটপুট: `docs/guide-consistency-audit.json` — প্রতি class+subject+chapter:
- `chapterTotal`, `mcq`, `short`, `creative`, `offeredSum`, `mismatch`
- lessons: `countByLesson` vs `listNoChapter`
- creative sample: `marksParts` type + ordering

**CI গার্ড (পরবর্তী):** mismatch>0 হলে ফেল; নতুন কনটেন্ট ইমপোর্টের পর বাধ্যতামূলক।

---

## ৪. ফেজ প্ল্যান

| ফেজ | কাজ | ফাইল | Acceptance |
|---|---|---|---|
| **F1** | Auth token সব Edge কলে | `edge_post.dart`, `openrouter_client.dart` | সাইন-ইনে AI 200; anon-এ সৎ 401 |
| **F2** | সৃজনশীল ক্রম/মার্ক | `creative_part_marks.dart`, model | সব অংশ ka→gha; ক=1…ঘ=4 |
| **F3** | Dup/scope/copy | `subjects_grid.dart`, `search_flow_picker_section.dart`, `guide_answer_screen.dart`, strings | এক এন্ট্রি; বোর্ড root-only; দুই বাটন কাজ করে; কপি সৎ |
| **F4** | Count model (server+client) | `guide-bank` guideChapters + client | হেডার=অফার্ড যোগফল; creative=group; অজানা=লাইন বাদ |
| **F5** | Chapter-scoped lessons | `guide-bank` guideLessons + extras/picker | lesson count = list count |
| **F6** | মডেল সেট lock UI | `guide_model_test_list_screen.dart` | lock-এ কারণ, শুরু বাটন নেই |

প্রতিটি ফেজ: analyze ০ + ইউনিট টেস্ট + `audit` mismatch ০ (নমুনা ক্লাসে)।

---

## ৫. এই সেশনে ইতিমধ্যে কোডে করা

- ✅ U2: `edgeAuthToken()` — `edge_post.dart` + `openrouter_client.dart`
- ✅ U3: ডুপ্লিকেট গাইড কার্ড বাদ
- ✅ U4: দুই বাটন এখন generation ডাকে (`style` সহ)
- ✅ U5: বোর্ড টাইল শুধু root-এ
- ✅ U6: part order ka→kha→ga→gha + Map পার্স টেস্ট
- ✅ U10-এর কারণ প্রমাণিত (lesson subject-wide vs chapter list=0)
- ⏳ U1/U7/U8/U9/U11 — নিয়ম ও ধাপ নির্ধারিত, F4/F5/F6-এ বাস্তবায়ন

---

## ৬. যাচাই চেকলিস্ট (প্রতি রিলিজে)

- [ ] `node tools/audit_guide_consistency.mjs 6 7 8 9 10` → `mismatch=0`
- [ ] সৃজনশীল: চারটি অংশের মার্ক ১/২/৩/৪
- [ ] lesson counts == list totals
- [ ] বোর্ড একবার, root-এ
- [ ] AI ব্যাখ্যা সাইন-ইনে ২০০
- [ ] analyze ০ error/warning; ফুল স্যুট পাস
- [ ] ফোনে নমুনা: ৬ ইসলাম, ৯ ইসলাম, ৯ পদার্থ, ১০ (শেয়ার্ড)
