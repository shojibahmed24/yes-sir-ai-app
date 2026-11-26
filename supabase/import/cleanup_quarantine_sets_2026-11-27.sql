-- Round 7 cleanup: quarantined lecture rows must not appear as
-- model-test sets. set_id is cleared (rows stay for the repaired
-- re-import by id); section is already 'lecture-quarantine'.
begin;
update public.guide_questions
   set set_id = null
 where section = 'lecture-quarantine';
commit;
