SET TIMING ON;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- Step 5
-- QC Defect 13923
-- Running GIS for indexes created in Step 2 and 3



EXECUTE dbms_stats.unlock_table_stats ('AR', 'AR_CASH_RECEIPTS_ALL');

EXECUTE dbms_stats.unlock_table_stats ('AR', 'AR_PAYMENT_SCHEDULES_ALL');

EXECUTE fnd_stats.gather_index_stats ('XXFIN', 'XX_AR_CASH_RECEIPTS_N14');

EXECUTE fnd_stats.gather_index_stats ('XXFIN', 'XX_AR_PAYMENT_SCHEDULES_ALL_N3');

EXECUTE dbms_stats.lock_table_stats('AR', 'AR_CASH_RECEIPTS_ALL');

EXECUTE dbms_stats.lock_table_stats('AR', 'AR_PAYMENT_SCHEDULES_ALL');


EXIT;

SHO ERR;