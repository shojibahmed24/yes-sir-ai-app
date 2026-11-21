# APK রাউন্ড — রুট-কজ ও ফিক্স প্ল্যান (2026-11-23)

> প্রতিটি সমস্যার প্রকৃত কারণ (কোড/ডেটা প্রমাণ) এবং ফিক্সের ক্রম। ✅ = বাস্তবায়িত।

| আইডি | সমস্যা | প্রকৃত কারণ | ফিক্স | অবস্থা |
|---|---|---|---|---|
| A1 | Settings-এ ধূসর ব্লক | `settings_account_section`-এ `s['reminderTime']!` — কী মুছে গিয়েছিল → build exception → release ErrorWidget (ধূসর) | কী ফেরানো | ✅ `4091b05` |
| A2 | লম্বা UUID আইডি | raw uid দেখানো | `@name-xxxx` | ✅ `4091b05` |
| A10 | Subjects/সব লিস্ট সার্ভার থেকে আসে না | পুরোনো APK **expired session token** guide-bank-এ পাঠাত → 401 → সব LOCK/খালি | পাবলিক রিডে 401 হলে anon retry; flags খালি=unknown; 3s timeout | ✅ `bc51525` |
| A13 | প্রশ্ন তালিকা ধীর | প্রতি খোলায় network; ক্যাশ miss; বড় payload | cache-first + slim + prefetch | ⏳ |
| A3 | দৈনিক কুইজ লম্বা স্পিনার | guide daily fetch ধীর/ব্যর্থ; ফলব্যাক দেরিতে | ২.৫s পর ব্যাংক সেট ডায়ালগ; স্পিনার টেক্সট | ⏳ |
| A4 | প্র্যাকটিসে শুধু গণিত+বিজ্ঞান | `practice_home_view`-এ হার্ডকোড | সব সাবজেক্টের টাইল | ⏳ |
| A5 | মডেল টেস্ট শুধু গণিত | `PracticeSession.selectedSubject` | স্ক্রিনে সাবজেক্ট পিকার | ⏳ |
| A6 | “সার্ভারে পৌঁছানো যায়নি” রিট্রাই নেই | কোল্ড/অফলাইন, খালি ক্যাশ | Retry CTA + ক্যাশ | ⏳ |
| A7 | Quiz Prev বাটন বড় খালি বক্স | OutlinedButton min-width 88×56, শুধু আইকন | ৪৪×৪৪ tonal icon | ⏳ |
| A8 | প্ল্যান প্রতিদিন একই | ফিক্সড ৩ টাস্ক | তারিখ+state রোটেশন, done persist | ⏳ |
| A9 | সপ্তাহে শুধু আজকের বার | activityDates ফরম্যাট মিসম্যাচ | নরমালাইজ + ৭-দিন ম্যাপ | ⏳ |
| A11 | “শেষ যেখানে পড়েছ”-এ ভুল কপি | `noWeakYet` স্ট্রিং | `noLastStudied` | ⏳ |
| A12 | হোমের নিচের সেকশন অপরিণত | ভিন্ন কার্ড/চার্ট স্টাইল | এক SectionHeader/কার্ড, ৭-বার চার্ট, muted done | ⏳ |
| A14 | Google লগইনে supabase.co দেখায় | Supabase browser OAuth redirect | নেটিভ `google_sign_in` + `signInWithIdToken` (Web client ID দরকার) | ⏳ |

## ক্রম (এক ব্যাচে এক কাজ)
1. **খোলার গতি:** A13 (cache-first + prefetch), A3 (fast fallback), A6 (retry)
2. **কভারেজ:** A4 (সব বিষয়), A5 (মডেল সাবজেক্ট)
3. **পলিশ:** A7, A11, A12, A8, A9
4. **Google:** A14 (Web client ID পেলে)

## নোট
- ✅ চিহ্নিতগুলো নতুন APK-তে আছে; বাকিগুলো পুরোনো APK-তে দেখা যাবে না ধরে নেবেন না।
- প্রতিটি ধাপে analyze ০ + সংশ্লিষ্ট টেস্ট, শেষে নতুন zip।
