-- CRM Team has requested these DFFs be incremented by one day 
-- so their testing process will recognize the data as refreshed.

UPDATE apps.per_all_assignments_f 
   SET ass_attribute9=to_char(to_date(ass_attribute9)+1)
 WHERE ass_attribute9 IS NOT NULL;

UPDATE apps.per_all_assignments_f 
   SET ass_attribute10=to_char(to_date(ass_attribute10)+1)
 WHERE ass_attribute10 IS NOT NULL;

COMMIT;
