SET TIMING ON;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- Step 1
-- QC Defect 13923
-- Disabling Index. It will be enabled again in last step of action plan

ALTER INDEX ar.ar_payment_schedules_n9 
UNUSABLE;


EXIT;

SHO ERR;