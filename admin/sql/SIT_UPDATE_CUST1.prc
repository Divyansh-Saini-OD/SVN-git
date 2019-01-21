UPDATE AR.HZ_CUSTOMER_PROFILES SET ATTRIBUTE6='P' where cust_account_id = 33595139 and site_use_id is null;

COMMIT;   

SHOW ERRORS;

EXIT;