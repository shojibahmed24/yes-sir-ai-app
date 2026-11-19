-- 020_chemistry_ch11_duplicate_options.sql
--
-- Owner decision 2026-11-20, after the owner read the printed guide
-- (pages 588 and 589, true 300 dpi scans kept outside the repo):
-- the DUPLICATE IS IN THE PRINT, not an OCR defect, so there is no
-- "correct printed form" to restore. The owner's instruction: keep
-- the row, keep the printed key, and put a different (already
-- wrong) option into the duplicated slot — the student reads the
-- printed correct answer either way.
--
--   che-ch11-mcq-bank-309 (p588, question "কোনটি হাইড্রোকার্বনের
--   সাধারণ সংকেত?"): ক and গ were both 'CnH2n+1OH'. Key = খ
--   ('CnH2n'). গ becomes an aldehyde formula — an aldehyde is not a
--   hydrocarbon, so it stays a WRONG option; the key is untouched.
--
--   che-ch11-mcq-bank-315 (p589, question "সম্পৃক্ত হাইড্রোকার্বন
--   যৌগের নাম কোনটি?"): ক = গ = 'মিথেন' and খ = ঘ = 'ইথিন'.
--   Key = গ ('মিথেন'). The two duplicated slots (ক, ঘ) become
--   unsaturated names from the same chapter ('ইথাইন', 'প্রোপিন') —
--   still wrong for "saturated", and the key stays the only correct
--   answer. Option order (ক/খ/গ/ঘ) is preserved: the key letter
--   never moves.
--
-- No row is deleted. options may be stored either as a JSON array
-- (index order = ক/খ/গ/ঘ) or as a JSON object keyed ক/খ/গ/ঘ; both
-- shapes are handled. flag_note is rewritten so the header no longer
-- claims "not emended" after the fix.
--
-- WRITE: apply only with the owner's one-time permission.

UPDATE guide_questions
SET options = CASE jsonb_typeof(options)
        WHEN 'array' THEN jsonb_set(
          options, '{2}', to_jsonb('CnH2n+1CHO'::text), false)
        ELSE jsonb_set(
          options, '{গ}', to_jsonb('CnH2n+1CHO'::text), false)
      END,
    flag_note = 'ছাপায় ক ও গ অপশন একই ছিল (সম্ভাব্য misprint, গাইড পৃষ্ঠা ৫৮৮)। ২০২৬-১১-২০: গ-এর অপশনটি একই অধ্যায়ের ভিন্ন একটি ভুল অপশন দিয়ে প্রতিস্থাপন করা হয়েছে; কী (খ) অপরিবর্তিত।'
WHERE id = 'che-ch11-mcq-bank-309';

UPDATE guide_questions
SET options = CASE jsonb_typeof(options)
        WHEN 'array' THEN jsonb_set(
          jsonb_set(options, '{0}', to_jsonb('ইথাইন'::text), false),
          '{3}', to_jsonb('প্রোপিন'::text), false)
        ELSE jsonb_set(
          jsonb_set(options, '{ক}', to_jsonb('ইথাইন'::text), false),
          '{ঘ}', to_jsonb('প্রোপিন'::text), false)
      END,
    flag_note = 'ছাপায় ক=গ (মিথেন) ও খ=ঘ (ইথিন) ছিল (সম্ভাব্য misprint, গাইড পৃষ্ঠা ৫৮৯)। ২০২৬-১১-২০: ক ও ঘ-এ ভিন্ন ভুল অপশন বসানো হয়েছে; কী (গ) অপরিবর্তিত।'
WHERE id = 'che-ch11-mcq-bank-315';

-- Post-apply check (read-only): four distinct options per row.
SELECT id,
       options,
       answer_key,
       (SELECT count(DISTINCT v) FROM jsonb_array_elements_text(
          CASE jsonb_typeof(options)
            WHEN 'array' THEN options
            ELSE (SELECT jsonb_agg(value ORDER BY key) FROM jsonb_each(options))
          END)) AS distinct_options
FROM guide_questions
WHERE id IN ('che-ch11-mcq-bank-309', 'che-ch11-mcq-bank-315');
