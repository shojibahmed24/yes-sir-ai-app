-- Step 1: every lecture-sheet row leaves the app lists.
begin;
update public.guide_questions set section = 'lecture-quarantine'
     where guide_source in ('ict-lecture-satt','career-shikkha-lecture-satt')
       and section in ('mcq_bank','short','model-mcq','creative');
commit;
