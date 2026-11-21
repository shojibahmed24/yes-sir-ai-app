# Yes Sir AI — পূর্ণ UI/UX ও ফিচার অডিট (2026-11-21)

> **স্কোপ:** লগইন থেকে শুরু করে প্রতিটি স্ক্রিন (১০০+ রুট), AI চ্যাট, AI ব্যাখ্যা, সৃজনশীল/উদ্দীপক পেজ, নোটিফিকেশন, প্রিমিয়াম, বই, মডেল টেস্ট — সব।
> **পদ্ধতি:** ৩টি স্বতন্ত্র কোড-অডিট (auth/profile · learn/AI · home/practice) + নিজের লাইভ DB প্রোব ও স্ক্যান। সব রেফারেন্স `file:line` — লাইন নম্বর পরের এডিটে সরে যেতে পারে, ফাইল নাম স্থির।
> **নিয়ম:** এখানে কোনো ফিচার "ভুয়া" বলে চিহ্নিত মানে ইউজার যা দেখে তার সাথে বাস্তবতা মেলে না — ডেমো/প্লেসহোল্ডার/হার্ডকোড।

---

## ০. এক নজরে

| স্তর | সংখ্যা | অর্থ |
|---|---|---|
| **Critical** | ১৫ | ফিচার ভুয়া/ভুল তথ্য/ক্র্যাশ-ঝুঁকি — Play-এর আগে অবশ্যই ঠিক |
| **High** | ৩৬ | বিভ্রান্তিকর UI, ডেড CTA, ভুল নেভিগেশন |
| **Medium/Low** | ~৫০ | স্টেট, ডিজিট, a11y, কনট্রাস্ট, ডেড কোড, i18n |
| **অসম্পূর্ণ ফিচার** | ১১টি ক্ষেত্র | নোটিফিকেশন, প্রিমিয়াম, ভয়েস, বই-রিডার, মডেল টেস্ট, SMS OTP, সাপোর্ট, XP, Today, Practice কভারেজ, Lesson-step |

**শীর্ষ ১০ ব্লকার (এই 순서ে ঠিক করা উচিত)**
1. Guide-answer timeout → **খালি পেজ + ভুল “চাবি নেই”** (C1)
2. Search-flow-এ **ক্লাস পিকার শুধু ৬/৭/বর্তমান** — ক্লাস ১–৫, ৮–১০ বাছাই করা যায় না (C2)
3. Premium পেজে **$5 দাম দেখায়, কিনতে কিছুই নেই** (C5)
4. **Voice Tutor কল নয়** — শুধু টাইমার (C4)
5. **নোটিফিকেশন শেল** + ভুল “৩টি নতুন” কাউন্ট (C6)
6. **OTP: যেকোনো ৪ সংখ্যা** গ্রহণ — ফোন ভেরিফিকেশন নেই (C7)
7. **বই-রিডারে বই নেই** — শুধু প্লেসহোল্ডার (C8)
8. **বই লাইব্রেরি সবাইকে ক্লাস ৬** দেখায় + ভুল `bookId` (C9)
9. **মডেল টেস্ট = ৩টি হার্ডকোড ডেমো টেস্ট** (C10), Quiz retake = ডেমো ব্যাংক (C11)
10. **Home “weak chapters” আসলে শেষ খোলা অধ্যায়** (C12)

### অবস্থা আপডেট — ২০২৬-১১-২২ রাতের ইমপ্লিমেন্টেশন

| আইটেম | অবস্থা | নোট |
|---|---|---|
| C1 guide-answer failure | ✅ | error + retry; ভুল “no key” বন্ধ |
| C2 class picker 1–10 | ✅ | `class_choices.dart`, ৩ জায়গায় |
| C3 chapter opened | ✅ | class-stamped |
| C5 price honesty | ✅ | “লঞ্চে ফ্রি”, $৫ বাদ |
| C6 notification count | ✅ (আংশিক) | ভুল কাউন্ট/ডেড বাটন বাদ; pipeline এখনো বাকি |
| C9 book library class | ✅ | প্রোফাইল ক্লাস + আসল book id |
| C11 quiz retake | ✅ | একই প্রশ্ন সেট |
| C12 weak-chapters lie | ✅ | লেবেল “শেষ যেখানে পড়েছ” (আসল weak data পরে) |
| C14 chapter tap | ✅ | search-flow + chapter param |
| C15 read again | ✅ | লাইব্রেরি (ভুল পেজ নয়) |
| H1 detailed/steps | ✅ | লেবেল বাস্তব: সারাংশসহ / শুধু ধাপ |
| H2/H3/H4 back context | ✅ | returnTo/class/source honored |
| H6 chat autoscroll | ✅ (আংশিক) | রিট্রাই/কপি বাকি |
| H8 subject names | ✅ | ৯–১০-এর সব বিষয় যোগ |
| H9/H10 book lookup | ✅ | ডেড ট্যাপ/ইনফিনিট লোডিং বন্ধ |
| H11/H12 | ✅ | রিফ্রেশ ক্লাস + বটম-নেভ ট্যাব |
| H14 XP lie | ✅ | XP না থাকলে লেভেল লুকায় |
| H15 CTA label | ✅ | “কুইজ শুরু করো” |
| H16 subject detail | ✅ | আসল নাম + সাবজেক্টসহ practice |
| H17 advice | ✅ | আসল কাউন্ট |
| H22/H23 saved | ✅ | লেবেল/ব্যাক ঠিক |
| H25 stale contact | ✅ | লগইন থেকে এলে ক্লিয়ার |
| H26/H27 profile claims | ✅ | ভুয়া ক্লাস/প্রিমিয়াম বাদ |
| H29/H30 OTP | ✅ | লাইভ কুলডাউন; WhatsApp কপি বাদ |
| H31 step 9 copy | ✅ | “পাঠানো হয়েছে” মিথ্যা বাদ |
| H32 password rules | ✅ | লাইভ, ৩ নিয়ম প্রয়োগযোগ্য |
| H33 busy states | ✅ | লগইন/OTP স্পিনার |
| H35 settings saved | ✅ | লোকাল-only হলে আলাদা মেসেজ |
| H36 textScaler | ✅ | সিস্টেম ফন্ট মানে |
| C4/C7/C8/C10 + notifications pipeline + voice | ⏸ | সিদ্ধান্ত/ব্যাকএন্ড/ডিভাইস লাগে — §৬ দেখুন |

---

## ১. Critical — ফিচার ভুল/ভুয়া (P0)

### C1 · Guide answer: timeout-এ খালি পেজ, MCQ-তে ভুল “চাবি নেই”
`lib/features/learn/guide_answer_screen.dart:108-114` — `catch` শুধু `_loading=false` করে; `_unavailable` সেট হয় না, stage-1 ফিল্ডও খালি। ফলে `widgets/guide_answer_body.dart:161-163` MCQ-কে “কী নেই” নোটে ফেলে দেয় — **ভুল দাবি, কোনো এরর/রিট্রাই নেই**।
**সমাধান:** failure → `AppStateKind.error` + Retry; `unavailable` শুধু server-verified `found:false`-তে; টাইমআউট আলাদা মেসেজ।

### C2 · Search-flow-এ ক্লাস পিকার অসম্পূর্ণ
`lib/features/learn/widgets/search_flow_identity_fields.dart:30` — `{6, 7, controller.schoolClass}`; একই প্যাটার্ন `search_screen.dart:120`, `widgets/chapter_questions_parts.dart:53`।
**সমাধান:** `classes 1..10` (Subjects স্ক্রিনের `ClassSelector`-এর মতো), খালি ক্লাসে সৎ নোট।

### C3 · অধ্যায়ের “খোলা হয়েছে” স্ট্যাটাস কখনো মেলে না — **আজ ফিক্সড**
`lib/features/learn/chapters_screen.dart:180,212` পুরোনো `'subject|n'` কী খুঁজত, কিন্তু লেসন এখন `'class|subject|chapter'` লিখে। `LearnStore.chapterOpened()` যোগ করে ঠিক করা হয়েছে (টেস্ট: `test/learn_class_progress_test.dart`)।

### C4 · Voice Tutor আসলে কল নয়
`lib/features/premium/voice_tutor_screen.dart:77-107` — মাইক ক্যাপচার নেই, অডিও নেই, ট্রান্সপোর্ট নেই; শুধু লোকাল টাইমার চলে। Gemini Live transport এখনো হয়নি।
**সমাধান:** হয় আসল transport, নাহলে স্ক্রিনে স্পষ্ট “শীঘ্রই আসছে” + বাটন disable (ভুয়া কল নয়)।

### C5 · Paywall: দাম আছে, কেনা নেই
`lib/features/premium/premium_paywall_screen.dart:70-73,199-207` — বাটন চিরকাল “Coming soon”, অথচ $5/মাস দেখানো হয়।
**সমাধান:** Play Billing না হওয়া পর্যন্ত দাম লুকিয়ে “লঞ্চে ফ্রি” / “শীঘ্রই”; অথবা Play Billing + server verification (P7)।

### C6 · নোটিফিকেশন শেল
`lib/features/profile/notifications_screen.dart:70,100` — `_items()` সবসময় `const []`; `notifications_strings.dart:5`-এ “৩টি নতুন” হার্ডকোড। mark-all/clear ডেড কন্ট্রোল। (`:103-106` back সবসময় `/home`)।

### C7 · রেজিস্ট্রেশন OTP: যেকোনো ৪ সংখ্যা
`lib/features/registration/steps/step09_otp.dart:69-83`, `step12_review.dart:176-180` — SMS যাচাই ছাড়াই ফোন সেভ হয়।
**সমাধান:** Supabase Phone Auth চালু; না হলে ধাপটি বাদ দিয়ে শুধু ইমেইল ভেরিফিকেশন, আর UI-তে ভুয়া “কোড পাঠানো হয়েছে” নয়।

### C8 · Book Reader-এ বই নেই
`lib/features/books/book_page_viewer_screen.dart:152-154` — শুধু “পৃষ্ঠার লেখা এখনো আসেনি”; Prev/Next শুধু নম্বর বদলায়। **সিদ্ধান্ত দরকার:** টেক্সট/PDF পাইপলাইন হবে কি? (লাইসেন্স+স্টোরেজ)

### C9 · বই লাইব্রেরি ক্লাস-ব্লাইন্ড
`lib/features/books/book_library_screen.dart:46,63` — `classBooksAsync(6)` ও `class6Meta`; `:106` (ও `home_screen.dart:200`) `'class6-${subject}-bn'` বানানো id।
**সমাধান:** প্রোফাইল ক্লাস, `books_public.id` সরাসরি।

### C10 · মডেল টেস্ট ডেমো
`lib/core/services/model_test_service.dart:30-35` — ৩টি হার্ডকোড টেস্ট (১০/৮/০ প্রশ্ন), UI বলে “Board-standard full model test”। লাইভ গাইড-সেট ভিত্তিক টেস্টে যেতে হবে।

### C11 · Quiz retake ভুল সোর্স
`lib/features/practice/quiz_results_screen.dart:157-161` — “Try Again” → `practiceService.quizFor()` (৫ প্রশ্নের লোকাল ডেমো ব্যাংক), আগের গাইড সেট নয়।

### C12 · Home “Weak chapters” মিথ্যা
`lib/features/home/home_lower_sections.dart:47-69` — আসলে শেষ খোলা অধ্যায়; আসল weak data `ProgressSummary.weakChapters`-এ আছে, ব্যবহার হয় না।

### C13 · Saved-এ বুক-আইডি মিশে যায়
`lib/features/books/book_page_viewer_screen.dart:71` + `lib/features/progress/saved_questions_screen.dart:163-167` — `book:math|45` টাইপ id “saved questions” হিসেবে হোমে গোনা হয়, ট্যাপ করলে কিছু হয় না।

### C14 · Chapter কার্ড ট্যাপ → ডেমো লেসন
`lib/features/learn/widgets/chapter_card.dart:56-65` — `page:45, problem:5` হার্ডকোড, লিগ্যাসি `/search`-এ যায়।

### C15 · Results → “আবার পড়ো” ভুল পেজ
`model_test_results_screen.dart:163`, `quiz_results_screen.dart:133` — `/books/viewer` সিলেকশন ছাড়াই, ফলে ম্যাথ পৃষ্ঠা ৪৫ দেখায়।

---

## ২. High — বিভ্রান্তিকর UI / ডেড CTA

### Learn ও AI
- **H1 · “বিস্তারিত” ও “ধাপে ধাপে” একই ফল** — `guide_answer_screen.dart:232-239,158` সবসময় `style:'steps'`; `widgets/guide_explanation_section.dart:120` শুধু সারাংশ লুকায়।
- **H2 · লিস্ট থেকে Back ক্লাস/সোর্স হারায়** — `search_flow_list_screen.dart:190,196-198` হার্ডকোড `/search-flow?subject=`; রাউটার `returnTo` মানে (`router/learn_routes.dart:141`)।
- **H3 · Lesson-hub back ভিন্ন আচরণ** — `lesson_hub_screen.dart:44-55`; system back বনাম অ্যাপ-ব্যাক দুই পথ।
- **H4 · /lesson back → লিগ্যাসি /search** — `lesson_screen.dart:147`, যদিও `LessonSelection.returnTo` আছে।
- **H5 · দুটি সমান্তরাল পিকার-পথ** — `lesson_hub_nodes.dart:17-51` লেসনে ট্যাপ করলে আলাদা হাবে নিয়ে যায়, অথচ একই স্ক্রিনে টাইপ ড্রপডাউনও (`widgets/search_flow_picker_section.dart:119-139`)। **একটি বেছে নিতে হবে।**
- **H6 · চ্যাট: অটো-স্ক্রল নেই, রিট্রাই/কপি নেই** — `chat_screen.dart:181-204`; “Tip” শুধু `math|3|45|5` (`:172`)।
- **H7 · Answer-এ prev/next নেই; লিস্টে ফিরলে পেজিং রিসেট** — `guide_answer_body.dart:132-228`, `search_flow_answer_nav.dart:6-8`।
- **H8 · সাবজেক্ট নাম অসম্পূর্ণ** — `widgets/mock_data.dart:82-109` ২০টি id জানে, লাইভ ৫৭; `chemistry`, `accounting` কাঁচা id দেখায় (`search_flow_summary.dart:29`, `lesson_screen.dart:171`)।
- **H9 · Book lookup: ডেড ট্যাপ + ক্লাস ৬ হার্ডকোড** — `book_lookup_screen.dart:70-73,50-54,216`।
- **H10 · Book lookup AI infinite loading** — `widgets/book_lookup_detail.dart:29-41` `.then()` বিনা `onError`, রিট্রাই নেই।

### Home / Subjects / Books
- **H11** · Refresh ভুল ক্লাসে — `subjects_screen.dart:101-104` (`_schoolClass ?? 6`), সিলেক্টরের পিক উপেক্ষা।
- **H12** · বটম-নেভ ভুল ট্যাব/অনুপস্থিত — `subjects_screen.dart:202`, `chapters_screen.dart:239` (tab 0 হাইলাইট); Practice/Progress/Profile-এ নেভ নেই (`practice_screen.dart:200`, `progress_screen.dart:54`, `achievements_screen.dart:34`)।
- **H13** · “Practice by subject” শুধু ম্যাথ+সায়েন্স — `practice/widgets/practice_home_view.dart:91-117`।
- **H14** · Progress-এ Level 1 · 0 XP — `core/services/progress_service.dart:86-87`, `progress_screen.dart:126-130`।
- **H15** · Achievements সার্ভার স্ট্রিক গোনে না (`achievements_screen.dart:46-62`); CTA-র লেবেল “Quiz Champion” কিন্তু `/quiz` খোলে (`:151-154`)।
- **H16** · Subject detail-এর AppBar “বিষয়”ই থাকে (`subject_detail_screen.dart:66`); “Start practice” subject হারায় (`subject_detail_body.dart:152-157`)।
- **H17** · সব ক্লাসে একই “আজকের পরামর্শ: গণিত ৩য় অধ্যায়” — `subjects_screen.dart:183-196`, `subjects_strings.dart:27`।
- **H18** · “চালিয়ে যান” অধ্যায়ে ফেরে না — `home_continue_route.dart:7-25`।
- **H19** · “Today goal” স্ট্যাটিক স্লোগান — `home_screen.dart:108-125`।
- **H20** · “Recommended” হিরো-র কপি — `home_lower_sections.dart:71-88`।
- **H21** · হোম গ্রিডে pull-to-refresh নেই — `home_subject_grid.dart:132-163`।
- **H22** · Saved-এর “Practice” র্যান্ডম ব্যাংক — `saved_questions_screen.dart:229-231`।
- **H23** · Saved back → /profile — `saved_questions_screen.dart:56,68,99`, `router/practice_routes.dart:29`।

### Auth / Profile / Settings
- **H24** · Notifications হেডারে ভুল কাউন্ট + back `/home` — `notifications_screen.dart:119-122,103-106`।
- **H25** · OTP-তে পুরোনো `ys_reset_contact` আটকে থাকে — `otp_screen.dart:44-46,171-188`, `core/services/auth_service.dart:94-102`।
- **H26** · প্রোফাইল ভুয়া “Class 10 • Science” — `profile_screen.dart:123-125`, `profile_strings.dart:13`।
- **H27** · সবাই “Premium member (Pro)” — `profile_screen.dart:208-213`।
- **H28** · 🤖 ইমোজি লোগো/অ্যাভাটার — `step01_welcome.dart:30-35`, `about_screen.dart:67-70`।
- **H29** · OTP-তে “৩০ সেকেন্ড” কুলডাউন নেই, আনলিমিটেড রিসেন্ড — `otp_strings.dart:9`, `otp_screen.dart:76-97`।
- **H30** · “SMS বা WhatsApp” — WhatsApp চ্যানেল নেই (`otp_strings.dart:11`)।
- **H31** · Step 9-এ “৪ সংখ্যার কোড পাঠানো হয়েছে” বনাম “SMS চালু নেই” — `reg_step09_strings.dart:4`, `step09_otp.dart:97-101`।
- **H32** · Reset password: তিনটি নিয়ম শুরুতেই সবুজ ✓, ২–৩ নিয়ম প্রয়োগই হয় না — `reset_password_screen.dart:102-104,121-126,181-192`।
- **H33** · Login/OTP/Review-তে busy state নেই — `login_screen.dart:68-101`, `otp_screen.dart:118-121`, `step12_review.dart:51,209-216`।
- **H34** · Help/FAQ-তে সাপোর্ট ইমেইল/URL নেই — `help_faq_screen.dart:3-6,52-67`।
- **H35** · Settings সবসময় “Saved” বলে, upsert ব্যর্থ হলেও — `settings_screen.dart:118-125`।
- **H36** · `textScaler` সিস্টেম ফন্ট সাইজ ওভাররাইড করে — `app.dart:29-33`।

---

## ৩. Medium / Low — থিম অনুযায়ী

**স্টেট ও লোডিং**
- Future বিল্ডে তৈরি → প্রতি rebuild-এ রিফেচ: `practice_screen.dart:208`, `progress_screen.dart:62`, `achievements_screen.dart:42`, `quiz_results_screen.dart:50`।
- `snap.data ?? empty` → লোডিং/ব্যর্থতা/শূন্য একই দেখায় (একই ফাইলগুলো)।
- English reader `_load()`-এ try/catch নেই → অনন্ত স্পিনার (`english_reader_screen.dart:88-104`)।
- Board tile FutureBuilder-এ error branch নেই (`search_flow_board_tile.dart:30-37`)।
- Picker empty state-এ “Loading…” + “No items” একসাথে (`widgets/global_picker.dart:132-136`)।
- Chapter load ব্যর্থ হলে guide-এ `[]` (error = empty), textbook-এ unlabelled static fallback (`search_flow_controller.dart:201-211`)।
- Creative part load ব্যর্থতা গিলে ফেলে (`guide_creative_answer_view.dart:112-118`)।

**পেজিং/নেভিগেশন**
- `_loadMoreGuide`-এ try/catch ও in-flight guard নেই (`search_flow_list_screen.dart:157-181`) → ডুপ্লিকেট পেজ/আনহ্যান্ডলড এরর।
- List unavailable-এ রিট্রাই নেই (`search_flow_list_screen.dart:203-208`)।
- Chapter questions unavailable-এ রিট্রাই নেই (`chapter_questions_screen.dart:139-143`)।
- English reader back সেকশন/লেসন হারায় (`english_reader_screen.dart:165-166`)।

**ডিজিট/ফরম্যাট**
- Bangla মোডে ল্যাটিন সংখ্যা: `quiz_results_screen.dart:91-116`, `achievement_badges.dart:32-75`, `model_test_list_screen.dart:67-71`, `guide_question_header.dart:57,62,73`, `subject_card.dart:135`।
- Internal id টাইটেলে: `english_search_flow_list_screen.dart:155-158`; guide header-এ `setId` (`guide_question_header.dart:73`)।

**ক্র্যাশ-ঝুঁকি**
- `'কখগঘ'[i]` — ৫ অপশনের আইটেমে RangeError (`quiz_question_screen.dart:213`, `model_test_exam_screen.dart:203`)।
- `Attempt.chapter`-এ subject id ঢুকে ডেটা নষ্ট (`quiz_question_screen.dart:86`, `model_test_exam_screen.dart:113`)।
- Step 4 গ্রিড `childAspectRatio: 2.2` বড় ফন্টে ক্লিপ (`step04_class.dart:53-57`)।
- Appearance SegmentedButton বড় লেবেলে ওভারফ্লো (`settings_appearance_section.dart:112-124`).

**A11y / কনট্রাস্ট**
- `textScaler` ওভাররাইড (H36); একমাত্র Semantics নোড `search_flow_field_states.dart:78`।
- Icon-only send/back/report/bookmark-এ লেবেল নেই; PIN keypad/ভাষা-চিপ `GestureDetector` (`parent_pin_screen.dart:211-228`, `auth_scaffold.dart:112`)।
- কম কনট্রাস্ট: `profile_hero.dart:54-64`, `voice_hero.dart:40-71`, `parent_stat_card.dart:35-40`, `parent_pin_screen.dart:202-207`।

**লজিক/কনটেন্ট**
- Register step 6 “Skip” সেভ করে, step 11 “Skip” বাতিল করে (`step06_school.dart:49-51`)।
- Parent PIN “Forgot PIN?” ডেড-এন্ড (`parent_pin_screen.dart:139-151`)।
- Non-premium-এও “0 / 30 voice minutes” (`parent_dashboard_screen.dart:34,179-184`)।
- Delete account: পাসওয়ার্ড/বায়োমেট্রিক re-auth নেই (`delete_account_tile.dart:19-47`)।
- Splash `_route()`-এ try/catch নেই, লোগো `errorBuilder` নেই (`splash_screen.dart:53-82,109-113`)।
- Model test exam back-এ কনফার্মেশন নেই; item missing হলে `.first` (`model_test_exam_screen.dart:181-186,52-54`)।
- Quiz-এ ৬টি অ্যাকশন বাটন একসাথে (`quiz_question_screen.dart:232-245`)।
- No-match screen-এ দুই বাটন একই কাজ (`no_match_screen.dart:110-122`)।
- English reader-এ সঠিক অপশন আগেই হাইলাইট (`english_reader_question_options.dart:60-78`), guide-এর নীতির বিপরীত।
- Book lookup AI-তে চিপ/সোর্স নেই (`english_reader_question_card.dart:204-217`)।

**i18n ও ডেড কোড**
- `lib/features/today/today_strings.dart` — l10n-এর বাইরে (৩৫ লাইন)।
- `widgets/mock_data.dart`-এ ২০ সাবজেক্ট নাম (H8)।
- ডেড মক স্ট্রিং: `subjects_strings.dart:4,7,34,36`, `book_library_strings.dart:6-9`, `book_page_viewer_strings.dart:4-7`, `settings_strings.dart:7,77` (“Roll: 12 • ID #YS-88214”)।
- অব্যবহৃত: `registration_wizard.dart:22`, `auth/widgets/robot_avatar.dart`; ডুপ্লিকেট `/practice-tab` (`router/practice_routes.dart:19`)।
- `solution_renderer.dart:214-216`-এ হার্ডকোড `'AI: unknown'`।

---

## ৪. অসম্পূর্ণ ফিচার ম্যাট্রিক্স

| ফিচার | বর্তমান অবস্থা | যা দরকার |
|---|---|---|
| নোটিফিকেশন | শেল; list `[]`, ডেড mark/clear, ভুল কাউন্ট | `flutter_local_notifications` + রিমাইন্ডার শিডিউল + প্রেফারেন্স + ডিপলিংক |
| প্রিমিয়াম | “Coming soon”; দাম দেখায় | Play Billing + server verify, নাহলে দাম লুকাও |
| Voice Tutor | লোকাল টাইমার, অডিও নেই | Gemini Live transport + quota + এরর স্টেট |
| Book Reader | প্লেসহোল্ডার | পৃষ্ঠা টেক্সট/PDF পাইপলাইন (লাইসেন্স সিদ্ধান্ত) |
| Books Library | ক্লাস ৬ হার্ডকোড, ভুল id | প্রোফাইল ক্লাস + `books_public.id` |
| Model Tests | ৩টি ডেমো টেস্ট | guide সেট → টেস্ট বিল্ডার |
| Practice/Retake | ৫ প্রশ্নের ডেমো ব্যাংক | গাইড/অধ্যায়ভিত্তিক সেট |
| SMS OTP | যেকোনো ৪ সংখ্যা | Phone Auth অথবা ধাপ বাদ + ইমেইল ভেরিফাই |
| সাপোর্ট | ইমেইল/URL নেই | সাপোর্ট ইমেইল (ইউজারের সিদ্ধান্ত) + Play listing |
| XP/Level | সবসময় 0/1 | স্ট্রিক+attempt থেকে XP বা কার্ড বাদ |
| Today | স্ট্যাটিক স্লোগান | আসল ডেইলি গোল + স্ট্রিক |
| Practice কভারেজ | ম্যাথ+সায়েন্স | সব সাবজেক্ট (guide-ভিত্তিক) |
| Lesson-step | কিছু বিষয়ে হার্ডকোড ম্যাপ | সব guide বিষয়ে `guideLessons` (bulk, cached) |
| Achievements | লোকাল attempt-only | সার্ভার স্ট্রিক/অধ্যায় অন্তর্ভুক্ত |

**ডেটা/কনটেন্ট ফাঁক (কোড নয়, কনটেন্ট সিদ্ধান্ত)**
- ক্লাস ১–৫: বই/গাইড কিছুই নেই।
- ক্লাস ৯ Chemistry: অধ্যায় ১–২ নেই (৩,৪,৫,৬,৭,১১ আছে)।
- ক্লাস ১০ = ক্লাস ৯-এর শেয়ার্ড বই (ইচ্ছাকৃত, UI-তে ব্যাজ আছে)।
- ক্লাস ৯ Bangla/English chapterless (লেসনভিত্তিক), English-2nd সেটভিত্তিক — UI ঠিক আছে, ডকুমেন্ট করা দরকার।
- Chemistry-তে ২২টি অচিহ্নিত dropped chunk (আগের রিপোর্ট)।

---

## ৫. ফেজভিত্তিক প্ল্যান (কাজ শুরুর ক্রম)

> প্রতি ফেজ শেষে: `flutter analyze` (০ error/warning) + সংশ্লিষ্ট টেস্ট + `flutter test` ফুল স্যুট। কোড ≤২৫০ লাইন/ফাইল, নতুন টেক্সট bn+en দুটোই।

### P0 — Correctness ব্লকার (আনুমানিক ২–৩ দিন)
1. C1 গাইড-আনসার failure state + রিট্রাই + ভুল “no key” বন্ধ।
2. C2 ক্লাস পিকার ১–১০ (তিন জায়গায় একই কম্পোনেন্ট)।
3. C14 chapter tap → আসল search-flow (ডেমো page/problem বাদ)।
4. H1 detailed/steps আলাদা করা অথবা একটি বাটন।
5. H2/H3/H4 back/returnTo ঠিক করা (class+source সহ)।
6. H9/H10 book lookup ডেড ট্যাপ + AI infinite loading।
7. H11 refresh ক্লাস, H34 সাপোর্ট ইমেইল (ইউজার দিলে), H35 “Saved” মিথ্যা বন্ধ।
8. C13 saved list আলাদা করা (`saved_questions` বনাম bookmarks)।

**Acceptance:** guide answer network fail-এ error+retry; ক্লাস ১–১০ সব পিকারে; back সব পথে context ধরে; analyze ০।

### P1 — Auth ও অ্যাকাউন্ট সততা (২ দিন)
C7, H25, H29, H30, H31, H32, H33, H26, H27, C5-এর দাম-সততা, H36।

**Acceptance:** OTP ছাড়া ফোন সেভ হয় না বা ধাপ নেই; কুলডাউন কাজ করে; প্রোফাইল শুধু সত্য তথ্য; সিস্টেম ফন্ট সাইজ মানে।

### P2 — Home/Subjects প্রফেশনাল (২–৩ দিন)
H12 (নেভিগেশন স্থাপত্য), H13, H14, H15, H16, H17 (ডাইনামিক পরামর্শ), H18 (chapter resume), H19, H20 (একটি বাদ), H21, H22, H23, C12।

**Acceptance:** সব ট্যাবে বটম-নেভ সঠিক হাইলাইট; নতুন ইউজার ভুয়া ডেটা দেখে না; continue আসল অধ্যায়ে ফেরে।

### P3 — Learn/AI UX (৩ দিন)
H5 (এক পিকার-পথ), H6 (অটো-স্ক্রল+রিট্রাই+কপি+সাজেশন), H7 (prev/next), H8 (নাম DB থেকে), AI ব্যাখ্যায় সোর্স/ডিসক্লেইমার/রিট্রাই, creative stimulus empty-vs-error, reader bugs, paging guard, chips কমানো।

**Acceptance:** উত্তর স্ক্রল নিজে নামে; AI ব্যর্থতায় রিট্রাই; সৃজনশীল অংশ লোড-ফেল আলাদা; প্রতি উত্তরে সোর্স লেবেল।

### P4 — Practice/Results (২–৩ দিন)
C10 (আসল মডেল টেস্ট), C11, C15, RangeError, `Attempt.chapter` ফিক্স, exit confirmation, ডিজিট, রেজাল্ট লেআউট।

**Acceptance:** টেস্ট/রিটেক আসল সেট থেকে; ৫ অপশনেও ক্র্যাশ নেই; রেজাল্টে সঠিক অধ্যায়।

### P5 — Notifications ও রিমাইন্ডার (২ দিন)
লোকাল নোটিফিকেশন পাইপলাইন, ইভেন্ট (ডেইলি স্ট্রিক, নতুন গাইড), প্রেফারেন্স ওয়্যারিং, টাইম পিকার, ভুল কাউন্ট বাদ, back context।

### P6 — Books (৩–৫ দিন, কনটেন্ট সিদ্ধান্ত সাপেক্ষ)
আসল রিডার (টেক্সট/PDF), ক্লাস-সচেতন লাইব্রেরি, সঠিক `bookId`, প্রগ্রেস, bookmark আলাদা।

### P7 — Premium ও Voice (৩–৫ দিন, Play অ্যাকাউন্ট সাপেক্ষ)
Play Billing + server verification, entitlement UI, Gemini Live transport, quota/এরর/রিফান্ড নীতি।

### P8 — Consistency, a11y, i18n (২–৩ দিন, সমান্তরালে চলে)
`today_strings` → l10n, dead mock strings পরিষ্কার, ডেড ফাইল/রুট, digits পাস, Semantics, কনট্রাস্ট টোকেন, `textScaler` (P1-এর অংশ), l10n parity টেস্টে today + features কভার।

---

## ৬. ইউজারের সিদ্ধান্ত দরকার

1. **সাপোর্ট ইমেইল/URL** (Play listing-এর জন্য বাধ্যতামূলক)।
2. **প্রিমিয়াম লঞ্চ:** ফ্রি-অনলি (দাম লুকানো) নাকি Play Billing এখনই?
3. **Book Reader:** আসল টেক্সট/PDF আনবেন কি? (লাইসেন্স + স্টোরেজ খরচ)
4. **লিগ্যাসি `/search`, `/practice-tab`, `/chapter-questions`** রুট রাখা হবে না বাদ?
5. **নোটিফিকেশন ইভেন্ট:** কোন কোন রিমাইন্ডার চান (স্ট্রিক/দৈনিক/নতুন প্রশ্ন)?
6. **ক্লাস ১–৫ ডেটা** কখন আসবে?
7. **H5:** লেসনে ট্যাপ → হাব-পেজ, নাকি পিকারের ভেতরেই টাইপ-রো? (একটি বেছে নিতে হবে)
8. **C7:** SMS OTP আনবেন (খরচ) নাকি রেজিস্ট্রেশন থেকে ফোন-ভেরিফিকেশন বাদ?

---

## ৭. ইতিমধ্যে সম্পন্ন (এই সপ্তাহে)

- guideFlags bulk endpoint (guide-bank v33, লাইভ ~০.৮s/class), ক্লায়েন্ট fallback সহ।
- সাবজেক্ট হাব: ব্যাজ (বই/গাইড/বই+গাইড), গ্রুপিং, সার্চ, ক্লাস-১০ শেয়ার্ড-বই নোট, খালি-ক্লাস নোট।
- পিকারে অধ্যায়-প্রশ্ন সংখ্যা (একই কলে, ক্যাশড), সারাংশ লাইন, `#নম্বর` চিপ।
- Class-stamped chapter progress + C3 ফিক্স + “শুরু করুন” CTA + `source=guide` ডিপলিংক।
- l10n parity গার্ড (`???`/mojibake/key-সমতা), guide bulk-flags টেস্ট।
- Avatars bucket (migration 022), হোম অ্যাভাটার।
- স্যুট: **৯০৮/৯০৮** (শেষ রান), analyze ০ error/warning।

---

## ৮. যাচাই চেকলিস্ট (প্রতি ফেজে)

- [ ] `flutter analyze` → ০ error, ০ warning (আগের ১৭ info বাদে)
- [ ] `flutter test` → ফুল স্যুট পাস (ডিটাচড রানে, `-j 3` বা কম)
- [ ] প্রতিটি নতুন স্ক্রিনে loading / empty / error / retry চারটি স্টেট
- [ ] bn+en দুটোতেই টেক্সট, সংখ্যা `numStr`
- [ ] ফাইল ≤২৫০ লাইন
- [ ] ফোনে স্মোক: লগইন→হোম→সাবজেক্ট→গাইড→উত্তর→AI→চ্যাট→প্র্যাকটিস→রেজাল্ট→প্রোফাইল
- [ ] টেস্ট = ডেস্কটপ প্রমাণ; ফোন আচরণ আলাদা করে ইউজার যাচাই করবেন
