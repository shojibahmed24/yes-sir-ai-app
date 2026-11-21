# Quiz স্ক্রিন — প্রফেশনাল রিডিজাইন (S4-1)

> রিসার্চ: Sato/Quizlet/Khan-ধাঁচের পরীক্ষা-ইউআই। লক্ষ্য: এক প্রশ্নে ফোকাস, স্পষ্ট অগ্রগতি, ভুল করে বের হওয়া বন্ধ, দ্রুত নেভিগেশন।

## এখন কী আছে
- এক প্রশ্ন/স্ক্রিন, প্রগ্রেস বার, টাইমার, অপশন টাইল
- হেডারে ব্যাক (সরাসরি বেরিয়ে যায়), নিচে ৬টি অ্যাকশন (Prev/Submit/Skip/Save/View saved/Finish)
- ব্যাখ্যা on-demand

## রিসার্চ থেকে নিয়ম
1. **প্রাইমারি অ্যাকশন একটি** — Next/Submit; বাকিগুলো সেকেন্ডারি আইকন
2. **প্রশ্ন প্যালেট** (১..N গ্রিড) — যেকোনো প্রশ্নে জাম্প, flagged আলাদা রঙ
3. **Exit confirmation** — mid-attempt বেরোলে উত্তর হারায়
4. **অপশন**: বড় টাইল, A/B/C/D লেটার, selected স্পষ্ট, ভুল/সঠিক রঙ শুধু submit-এর পর
5. **টাইমার চিপ** + এমসিকিউ নম্বর `৩/১০`
6. **Submit-এর আগে সারাংশ** (কত উত্তর বাকি)
7. **ব্যাখ্যা**: উত্তর দেওয়ার পর on-demand, স্ক্রল ছাড়া নিচে

## ফেজ
| ধাপ | কাজ | Acceptance |
|---|---|---|
| Q1 | Exit confirmation + timer cancel | ব্যাক চাপলে ডায়ালগ; থাকো/বের হও |
| Q2 | Bottom action bar একীকরণ (Next primary; Prev/Skip icon) | ৬ বাটন → ৩ |
| Q3 | প্রশ্ন প্যালেট (grid sheet) + flagged | যেকোনো প্রশ্নে জাম্প |
| Q4 | Submit সারাংশ (unanswered count) | নিশ্চিত করার আগে সতর্ক |
| Q5 | অপশন ভিজ্যুয়াল পলিশ + ব্যাখ্যা সেকশন | selected/correct/wrong স্পষ্ট |

## অবস্থা

- ✅ Q1 exit confirmation
- ✅ Q2 এক প্রাইমারি অ্যাকশন (prev আইকন + ৩ কম্প্যাক্ট আইকন)
- ✅ Q3 প্রশ্ন প্যালেট (answered/unanswered/current, জাম্প)
- ✅ Q4 submit সারাংশ (unanswered count)
- ✅ Q5 রিভিউ: `OptionTile`-এ আগেই selected/correct/wrong animation (pop/shake, Reduced-Motion সম্মান) + `QuizCheckedCard` ব্যাখ্যা — নতুন ঝুঁকি না নিয়ে যাচাই করে “আছে” নিশ্চিত করা হয়েছে

## এই কমিটে (Q1)
- ব্যাক বাটনে **exit confirmation** (bn/en), টাইমার বাতিল
- স্ট্রিং: leaveTitle/leaveBody/stay/leave
