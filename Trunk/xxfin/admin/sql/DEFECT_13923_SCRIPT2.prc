SET TIMING ON;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- Step 4
-- QC Defect 13923
-- Enabling index which we disabled in Step 1

ALTER INDEX ar.ar_payment_schedules_n9 
REBUILD PARALLEL;

ALTER INDEX ar.ar_payment_schedules_n9  
NOPARALLEL;


EXIT;

SHO ERR;