-- This should update 638 rows.
-- Defect # 14421
UPDATE ap_bank_accounts_all
SET AGENCY_LOCATION_CODE = NULL
WHERE INACTIVE_DATE < SYSDATE
AND ACCOUNT_TYPE = 'INTERNAL';
COMMIT;
/