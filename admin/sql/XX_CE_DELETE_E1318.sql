-- This should delete 508 records
-- Defece # 410
DELETE FROM XXFIN.XX_CE_STORE_BANK_DEPOSITS where DEPOSIT_TYPE ='MIS' AND LOG_NUM IS NULL AND BAG_NUM IS NULL;
COMMIT;
/
