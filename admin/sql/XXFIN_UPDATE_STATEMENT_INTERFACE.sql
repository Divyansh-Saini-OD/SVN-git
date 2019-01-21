-- This script is to update the errored out records in statement interface for reporcessing
-- This should update 2 records
UPDATE ce_statement_headers_int_all 
SET org_id = 403,
RECORD_STATUS_FLAG = 'N'
WHERE bank_account_num = '000247696000000359114';
COMMIT;
/