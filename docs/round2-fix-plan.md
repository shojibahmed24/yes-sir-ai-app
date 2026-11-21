# রাউন্ড ২ — বাস্তবায়ন প্ল্যান (B1–B15)

> নিয়ম: এক ব্যাচ = এক কমিট = analyze 0 error + সংশ্লিষ্ট টেস্ট পাস। শেষে full suite + নতুন zip।
> deploy: এই রাউন্ডে Edge/DB পরিবর্তন **নেই** (সব ক্লায়েন্ট-সাইড) → কোনো deploy লাগবে না।

## ব্যাচ ১ — সত্যবাদী নেটওয়ার্ক (B7 · B15 · B6 · B13)
মূল কথা: ব্যর্থতা কখনো “০ প্রশ্ন/০ বিষয়” নয়; আর ক্যাশ থাকলে কখনো skeleton নয়।

1. `guides_flow_list_service._fetchPageInner`: ব্যর্থ/টাইমআউট → `mode: unavailable` (খালি-ok কখনো নয়), client-scan ফলব্যাক শুধু সত্যিকারের পুরোনো সার্ভারে।
2. `booksService`: `subjectsAsync` ব্যর্থ হলে **খালি লিস্ট নয়** — নতুন `SubjectsResult` (list / failed) ফেরত; পুরোনো API রাখা হবে wrapper হিসেবে।
3. `HomeSubjectGrid`: ৩ অবস্থা — ডিস্ক ক্যাশ/লোডেড → দেখাও; ব্যর্থ → “সার্ভারে পৌঁছানো যায়নি” + **Retry**; সত্যিই ০ → empty।
4. `GuideListDiskCache` (নতুন): প্রথম পাতা raw JSON + total + time, LRU 40, TTL 24h → stale-while-revalidate; স্ক্রিনে ক্যাশ থাকলে skeleton নেই।
5. লিস্ট স্ক্রিন: `unavailable`-এ Retry বাটন; ক্যাশ থাকলে পুরোনো তালিকা রাখে।

## ব্যাচ ২ — الأولى-ফ্রেম ঠিক (B8 · B10)
1. `SchoolClassCache`: অ্যাপ স্টার্টে একবার হাইড্রেট; `resolveSchoolClass` ও `SearchFlowController` সিঙ্ক্রোনাসভাবে সেভ ক্লাস পায় → ৬-এর ফ্ল্যাশ শেষ।
2. পিকারের ধাপ-ব্যাক (`PopScope` + অ্যাপ-বার): লেসন → অধ্যায় → রুট; URL-এ `subject/source/class/chapter/lesson` রাখা, `init()` প্যারাম মানবে।

## ব্যাচ ৩ — তালিকা ও সাজানো (B2 · B3 · B4 · B11 · B12 · B9)
1. B2: `pageSize` 20→10; `ListView.builder` + scroll-trigger (৬০০px আগে) + background prefetch + ফুটার spinner/retry।
2. B3/B4: ক্রিয়েটিভ গ্রুপের `groupParts` লেবেল কার্ডের ভেতরে; `GuideQuestionRow.marksOverride` → “১০ নম্বর · ৩টি অংশ”; সব part-এ marks না থাকলে মোট নয়।
3. B11: লেসন তালিকা = curated ম্যাপ ∩ সার্ভার; সংখ্যাভিত্তিক ক্রম; compilation → ভাঁজ করা “অতিরিক্ত সেট”; ডুপ্লিকেট কোড পাশাপাশি।
4. B12: লেসন হাব ডেটা-চালিত — ০ কাউন্ট → কার্ড লুকাও, অজানা → থাক; পুরো ০ → empty + “সব লেসন”।
5. B9: লেসনের টাইপ-সংখ্যা ট্যাপযোগ্য চিপ → সরাসরি তালিকা; আলাদা “প্রশ্নের ধরন” ড্রপডাউন শুধু কাউন্ট অজানা হলে।

## ব্যাচ ৪ — রেজাল্ট ও AI লেবেল (B1 · B5)
1. `ReviewFilterCards` + নতুন `test_review_screen.dart` + রুট `/test-review?kind&filter`; `model_test_results_screen.dart` body আলাদা করে ২৫০-এর নিচে।
2. `AiAttributionLabel`: release-এ কোনো মডেল/প্রোভাইডার নাম নয় (debug-এ থাকবে); কুইজ/সমাধান রেন্ডারারও একই।

## ব্যাচ ৫ — হোম রিকেন্ট (B14)
1. `LearnStore.recordLastStudied` + `addRecentSubjectChapter` — গাইড প্রশ্ন/গ্রুপ/লেসন খোলার সময়।
2. হোমের “শেষ যেখানে পড়েছ” + “সম্প্রতি খোলা বই” ওই ডেটা থেকে; ট্যাপে সঠিক লেসন/হাব।

## ঝুঁকি / নিয়ম
- সব পরিবর্তনে ভার্বাটিম/নম্বর নিয়ম অটুট: কোনো নম্বর বা প্রশ্ন অনুমান করা হবে না — অজানা হলে কিছু দেখানো হবে না।
- ক্যাশ কখনো ভুল ক্লাসের ডেটা দেখাবে না (কি-তে class+subject+chapter+type)।
- প্রতিটি ব্যাচের পর নতুন zip।
