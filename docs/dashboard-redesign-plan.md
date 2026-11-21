# হোম ড্যাশবোর্ড — প্রফেশনাল রিডিজাইন প্ল্যান (2026-11-22)

> লক্ষ্য: অ্যাপ খুললেই মনে হবে “পূর্ণাঙ্গ পড়ার অ্যাপ” — শুধু সাবজেক্টের তালিকা নয়; অগ্রগতি, লক্ষ্য, স্ট্রিক, দৈনিক পরিকল্পনা, দুর্বল জায়গা, পরীক্ষার প্রস্তুতি এক নজরে।
>现状 অডিট + প্রস্তাবিত সেকশন + ফেজ প্ল্যান।

---

## ১. এখন ড্যাশবোর্ডে যা আছে

| সেকশন | বর্তমান | সমস্যা/সীমা |
|---|---|---|
| টপ বার | অ্যাভাটার, অভিবাদন, ক্লাস চিপ, নোটিফিকেশন/সেটিংস আইকন, ভাষা চিপ | স্ট্রিক/XP নেই; ভাষা চিপ হেডার দখল করে; নোটিফিকেশন ব্যাজ নেই |
| Today goal | এক লাইনের টেক্সট + chevron | সংখ্যা/রিং নেই; “লক্ষ্য” আসলে দেখায় না |
| সার্চ | টেক্সট → search flow | ভালো; কুইক-অ্যাকশন নেই |
| Continue hero | শেষ lesson (subject/chapter/page) | chapter-level resume; বড় কার্ডে অগ্রগতি নেই |
| Stats row | আজকের lesson, খোলা অধ্যায়, saved | স্ট্রিক/গোল/সাপ্তাহিক সক্রিয়তা নেই |
| Subject grid | ২ কলাম, নাম + সংখ্যা | progress %, ব্যাজ, দ্রুত অ্যাকশন নেই |
| নিচের সেকশন | “শেষ যেখানে পড়েছ”, recent books | আসল weak topics নেই; recommended ডুপ্লিকেট সরানো হয়েছে |
| Demo banner | অবস্থা | ঠিক আছে |

**ডেটা আছে কিন্তু দেখানো হয় না:** `ProgressSummary.weakChapters`, `goalMinutes/goalProgress`, `streakDays`, সাপ্তাহিক activity dates, quiz/model results, notification unread, profile class/school.

---

## ২. প্রফেশনাল অ্যাপে সাধারণত যা থাকে (বেঞ্চমার্ক)

1. **Greeting + streak + XP/level** (Duolingo/Khan)
2. **Daily goal ring** (“আজ ১৫/২০ মিনিট”)
3. **Continue learning** (বড় কার্ড, সরাসরি resume)
4. **Quick actions** (Search, Practice, Model Test, Saved, Ask AI)
5. **Today’s plan** (৩–৫টি টাস্ক, 체크)
6. **Weekly activity** (৭ দিনের বার/হিটম্যাপ)
7. **Weak topics / revision** (আসল ডেটা)
8. **Upcoming test / countdown**
9. **Achievements preview** (ব্যাজ/মাইলস্টোন)
10. **Subjects with progress** (%, ব্যাজ, কাউন্ট)
11. **Recent questions** (সাম্প্রতিক দেখা প্রশ্ন)
12. **Notification unread badge**

---

## ৩. প্রস্তাবিত নতুন ড্যাশবোর্ড (উপর থেকে নিচে)

```
[Avatar] শুভ সন্ধ্যা, রাফি        🔥 ৭ দিন   ⭐ ২৪০ XP   🔔(2)
ক্লাস ৯ · বিজ্ঞান                [সেটিংস]

┌ আজকের লক্ষ্য ──────────────┐
│   ◯ ১২/২০ মিনিট   (৬০%)     │   ← progress ring
│  ৩টি লেসন · ১টি কুইজ বাকি     │
└────────────────────────────┘

🔎 [কী শিখতে চাও? পৃষ্ঠা/প্রশ্ন/বিষয়…]

┌ ▶ চালিয়ে যাও ──────────────┐
│ রসায়ন · অধ্যায় ৩ · প্রশ্ন ৫ │
│ [চালিয়ে যাও]   অগ্রগতি ৪০%  │
└────────────────────────────┘

[Search] [Practice] [Model Test] [Saved] [Ask AI]   ← quick actions

আজকের পরিকল্পনা
 ☐ রসায়ন ৩.১ লেসন (১০ মি)
 ☑ গণিত MCQ ১০টি
 ☐ স্ট্রিক কুইজ

এই সপ্তাহ  ▁▃▅▂▇▅▁  ৩/৭ দিন সক্রিয়

দুর্বল অধ্যায় (আসল)  →  রিভিশন শুরু

আসন্ন  [মডেল টেস্ট — পদার্থ · ৩ দিন বাকি]

আমার বিষয়সমূহ  (progress %, ব্যাজ)
 [গণিত ৪৫%] [রসায়ন ২০%] …

সাম্প্রতিক প্রশ্ন  →  (৩টি row)

সাফল্য  🏅 ৩/১২ ব্যাজ  →
```

---

## ৪. নতুন ফিচার তালিকা (প্রায়োরিটি)

### P0 — ড্যাশবোর্ড “প্রাণ” পাবে
1. **Streak + XP হেডার** — `streakDays` (real) + XP ফর্মুলা (lesson 10, quiz correct 2, model test 1/প্রশ্ন, cap) → `progressService`-এ।
2. **Daily goal ring** — `goalMinutes`/`goalProgress` (Settings-এর গোল), না থাকলে “গোল সেট করো” CTA।
3. **Quick actions row** — Search / Practice / Model Test / Saved / Ask AI।
4. **Chapter-level resume** — hero card সরাসরি `/search-flow?...&chapter=N` (আগে শুধু subject)।
5. **Notification unread badge** — in-app unread গোনা।

### P1 — শেখার চালিকা
6. **Today’s plan** — ৩টি ডাইনামিক টাস্ক: streak quiz, weak chapter revision, model test (real state থেকে)।
7. **Weekly activity** — `ProgressSummary.activityDates` → ৭ দিনের বার।
8. **আসল weak topics** — `weakChapters` থেকে ২টি + “রিভিশন শুরু” (আগে ভুয়া “শেষ পড়া”)।
9. **Upcoming test card** — পরবর্তী সাপ্তাহিক মডেল টেস্ট (শনিবার) countdown।

### P2 — পলিশ
10. **Subject progress %** — opened/total per subject; ব্যাজ (বই/গাইড)।
11. **Recent questions** (সাম্প্রতিক দেখা ৩টি গাইড প্রশ্ন)।
12. **Achievements preview** — earned/total + লিংক।
13. **Loading skeletons** (bare “Loading subjects…” বদলে)।
14. **Offline chip** — connectivity_plus আছে; “অফলাইন — সেভ করা ডেটা”।

---

## ৫. ফেজ প্ল্যান

| ফেজ | কাজ | নির্ভরতা | Acceptance |
|---|---|---|---|
| **D1** | হেডার: streak + XP + নোটিফিকেশন ব্যাজ; ভাষা চিপ সরানো (Settings-এ) | XP ফর্মুলা | হেডারে ৩টি রিয়েল সংখ্যা; analyze ০ |
| **D2** | Daily goal ring + Today’s plan | goalMinutes | রিং সত্যি %, প্ল্যান টাস্ক রিয়েল |
| **D3** | Quick actions + chapter-level resume | — | ৫টি অ্যাকশন কাজ করে; hero অধ্যায়ে ফেরে |
| **D4** | Weekly activity + weak topics + upcoming test | activityDates, weakChapters | ৭-দিন চার্ট; weak>0 হলে রিভিশন |
| **D5** | Subject progress %, recent questions, achievements preview | subject counts | প্রতিটি কার্ডে % |
| **D6** | Skeletons, offline chip, spacing/typography pass | connectivity | লোডিং/অফলাইন সৎ |

প্রতি ফেজ: নতুন widget আলাদা ফাইলে (≤২৫০ লাইন), bn/en স্ট্রিং, ১টি টেস্ট, analyze ০।

---

## ৬. ডেটা/ব্যাকএন্ড

- **XP:** কোথাও নেই → `ProgressSummary`-এ `xp` যোগ; ফর্মুলা ক্লায়েন্টে (attempts থেকে), পরে সার্ভারে।
- **activityDates:** আছে (৭ দিনের অ্যাকটিভিটি)।
- **goalProgress/goalMinutes:** আছে (Settings)।
- **weakChapters:** আছে।
- **notification unread:** in-app read-set (আছে) → ব্যাজ।
- **subject %:** `chaptersOpenedFor` + chapterCount (আছে)।

নতুন DB/ডিপ্লয় লাগবে না (XP বাদে, ক্লায়েন্ট হিসাব)।

---

## ৭. সিদ্ধান্ত দরকার

1. **XP দেখাবেন?** (গেমিফিকেশন) — সুপারিশ: হ্যাঁ, ছোট স্কেলে।
2. ভাষা চিপ হেডার থেকে সরিয়ে **Settings-এ** রাখা ঠিক?
3. Quick actions-এ **Ask AI** থাকবে? (এখন lesson/guide-এ AI আছে)
4. Today’s plan কে ঠিক করবে — রিয়েল state (সুপারিশ) নাকি ইউজার নিজে টাস্ক যোগ করবে?

সুপারিশ: D1 → D2 → D3 ক্রমে শুরু; প্রতিটির পরে ফোনে যাচাই।
