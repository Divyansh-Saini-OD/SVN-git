UPDATE XXCRM.HZ_CUSTOMER_PROFILES SET ATTRIBUTE6 = 'B' WHERE cust_account_id IN (33595139,33059690,233948) AND SITE_USE_ID IS NULL;

COMMIT;   

SHOW ERRORS;

EXIT;