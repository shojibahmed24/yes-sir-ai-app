// Registration Step 9 - phone OTP strings (bn + en, written together).
// The code is SIX digits and really sent through the phone-otp Edge
// function; DEMO mode keeps the labelled local check only.
const Map<String, String> regStep09Bn = {
  'title': 'কোড যাচাই করো',
  'subtitle': 'তোমার মোবাইলে ৬ সংখ্যার কোড পাঠানো হচ্ছে।',
  'next': 'যাচাই করো  →',
  'resend': 'কোড আসেনি? আবার পাঠাও',
  'demoNote':
      'ডেমো মোড: আসল SMS পাঠানো হয়নি — যেকোনো ৬ সংখ্যার কোড দিয়ে ডেমো যাচাই চলবে।',
  'demoResend': 'ডেমো মোড: আসল SMS পাঠানো হয়নি।',
  'codeSent': 'কোড পাঠানো হয়েছে — ৫ মিনিটের মধ্যে লেখো।',
  'sending': 'কোড পাঠানো হচ্ছে…',
  'resendWait': 'আবার পাঠাতে {n} সেকেন্ড অপেক্ষা করো',
  'phoneNotConfigured': 'আসল SMS OTP এখনো চালু হয়নি।',
  'phoneMissing':
      'আগের ধাপে সঠিক মোবাইল নম্বর লেখা হয়নি — ৭ নম্বর ধাপে ফিরে ঠিক করো।',
  'error': '৬ সংখ্যার কোড লেখো',
  'errWrong': 'কোডটি মেলেনি — আবার লেখো',
  'errExpired': 'কোডের সময় শেষ — আবার পাঠাও',
  'errTooMany': 'অনেকবার ভুল হয়েছে — আবার নতুন কোড নাও',
  'errCooldown': 'একটু অপেক্ষা করো, তারপর আবার পাঠাও',
  'errDaily': 'আজকের সীমা শেষ — কাল আবার চেষ্টা করো',
  'errSms': 'SMS পাঠানো যায়নি — একটু পরে আবার চেষ্টা করো',
  'errNetwork': 'ইন্টারনেট সংযোগ পাওয়া যায়নি — আবার চেষ্টা করো',
};
const Map<String, String> regStep09En = {
  'title': 'Verify the code',
  'subtitle': 'A 6-digit code is being sent to your mobile.',
  'next': 'Verify  →',
  'resend': 'No code yet? Send again',
  'demoNote':
      'DEMO mode: no real SMS was sent — any 6-digit code completes the DEMO check.',
  'demoResend': 'DEMO mode: no real SMS was sent.',
  'codeSent': 'Code sent — enter it within 5 minutes.',
  'sending': 'Sending the code…',
  'resendWait': 'Wait {n} seconds before sending again',
  'phoneNotConfigured': 'Real SMS OTP is not enabled yet.',
  'phoneMissing':
      'No valid mobile number from the earlier step — go back to step 7 and fix it.',
  'error': 'Please write the 6-digit code',
  'errWrong': 'The code did not match — try again',
  'errExpired': 'The code expired — send a new one',
  'errTooMany': 'Too many wrong tries — request a new code',
  'errCooldown': 'Please wait a moment, then resend',
  'errDaily': 'Today\'s limit is used up — try again tomorrow',
  'errSms': 'The SMS could not be sent — try again shortly',
  'errNetwork': 'No internet connection — try again',
};
