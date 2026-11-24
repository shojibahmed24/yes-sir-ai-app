-- Quarantine first: no lecture row reaches a list until re-inserted.
begin;
update public.guide_questions set section = 'lecture-quarantine'
     where guide_source in ('ict-lecture-satt','career-shikkha-lecture-satt')
       and section in ('mcq_bank','short','model-mcq','creative');
commit;
