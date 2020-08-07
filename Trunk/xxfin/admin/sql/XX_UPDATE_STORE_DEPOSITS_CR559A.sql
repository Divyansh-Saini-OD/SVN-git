--This script is for testing the CR559A
--This should update 3161 records
Update xx_ce_store_bank_deposits 
set serial_num = NULL
where trunc(creation_date) = trunc(sysdate-1) 
and deposit_type = 'CHK';
COMMIT;
/