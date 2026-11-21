# APK রাউন্ড — রুট-কজ ও ফিক্স প্ল্যান (2026-11-23)

> প্রতিটি সমস্যার প্রকৃত কারণ (কোড/ডেটা প্রমাণ) এবং ফিক্সের ক্রম। ✅ = বাস্তবায়িত।

| আইডি | সমস্যা | প্রকৃত কারণ | ফিক্স | অবস্থা |
|---|---|---|---|---|
| A1 | Settings-এ ধূসর ব্লক | `settings_account_section`-এ `s['reminderTime']!` — কী মুছে গিয়েছিল → build exception → release ErrorWidget (ধূসর) | কী ফেরানো | ✅ `4091b05` |
| A2 | লম্বা UUID আইডি | raw uid দেখানো | `@name-xxxx` | ✅ `4091b05` |
| A10 | Subjects/সব লিস্ট সার্ভার থেকে আসে না | পুরোনো APK **expired session token** guide-bank-এ পাঠাত → 401 → সব LOCK/খালি | পাবলিক রিডে 401 হলে anon retry; flags খালি=unknown; 3s timeout | ✅ `bc51525` |
| A13 | প্রশ্ন তালিকা ধীর | প্রতি খোলায় network; ক্যাশ miss | প্রথম পাতা ৩ মিনিট ক্যাশ (প্রোডাকশন) | ✅ `d1f1184` |
| A3 | দৈনিক কুইজ লম্বা স্পিনার | book probe ১০s আগে, guide fetch ৪০s → ৬s বাজেটে গাইড আসত না | book probe ১s + guide ৫s | ✅ `39c08d4` |
| A4 | প্র্যাকটিসে শুধু গণিত+বিজ্ঞান | `practice_home_view`-এ হার্ডকোড | ক্লাসের সব সাবজেক্ট | ✅ `0e9b4e2` |
| A5 | মডেল টেস্ট শুধু গণিত | `PracticeSession.selectedSubject` | স্ক্রিনে সাবজেক্ট চিপ | ✅ `fd0cca6` |
| A6 | “সার্ভারে পৌঁছানো যায়নি” রিট্রাই নেই | কোল্ড/অফলাইন, খালি ক্যাশ | Retry CTA | ✅ `dfcff8d` |
| A7 | Quiz Prev বাটন বড় খালি বক্স | OutlinedButton min-width 88×56, শুধু আইকন | ৪৪×৪৪ গোল icon | ✅ `ccedeb7` |
| A8 | প্ল্যান প্রতিদিন একই | ফিক্সড ৩ টাস্ক | দিনভিত্তিক রোটেশন, একই টাস্ক দুইবার নয় | ✅ `322a99e` |
| A9 | সপ্তাহে শুধু আজকের বার | আসলে ডেটা কম; ফরম্যাট ইতিমধ্যেই নরমালাইজড | কিছু করার নেই (৭ দিন ব্যবহার করলেই ভরবে) | ✅ n/a |
| A11 | “শেষ যেখানে পড়েছ”-এ ভুল কপি | `noWeakYet` স্ট্রিং | `noLastStudied` | ✅ `ccedeb7` |
| A12 | হোমের নিচের সেকশন অপরিণত | ভিন্ন কার্ড/চার্ট স্টাইল | ৭-বার চার্ট + এক কম্প্যাক্ট কার্ড-রো empty state | ✅ `6f41849`,`ac099fa` |
| A14 | Google লগইনে supabase.co দেখায় | Supabase browser OAuth redirect | নেটিভ `google_sign_in` + `signInWithIdToken`, ব্যর্থলে browser fallback | ✅ `google_native_sign_in.dart` |

## নোট
- সব এন্ট্রি সমাধান হয়েছে; কোনো আইটেম বাকি নেই।
- প্রতিটি ধাপে analyze ০ + সংশ্লিষ্ট টেস্ট চালানো হয়েছে।
- **A14-এর জন্য Google Cloud সেটআপ (একবার):**
  1. Credentials → OAuth client → **Android**: package `com.yessirai.app` + release SHA-1।
  2. Credentials → OAuth client → **Web application**: ওই Client ID-টাই `GOOGLE_OAUTH_CLIENT_ID`
     (dart_defines.json-এ আছে) — native flow-এ `serverClientId` হিসেবে লাগে।
  3. OAuth consent screen-এ অ্যাপ নাম **Yes Sir AI**, লোগো, privacy/terms URL।
  - উপরের যেকোনোটি না থাকলে অ্যাপ নিজেই browser OAuth-এ ফিরে যায় (লগইন আটকায় না),
    কিন্তু তখন আবার Google স্ক্রিনে `supabase.co` লেখা দেখা যাবে।
