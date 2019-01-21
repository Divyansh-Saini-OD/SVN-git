SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : AlTER_HZ_CUSTOMER_PROFILES_NAIT-61952_NAIT_66520.tbl                                            |
-- | Description : MOD4B Release2                                                               |
-- | Rice Id     : E2059                                                                        |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        22-Nov-2018     Reddy Sekhar K       Added for req NAIT-61952 and NAIT-66520     |                                   
-- +============================================================================================+

PROMPT
PROMPT Altering the Table HZ_CUSTOMER_PROFILES .....
PROMPT

UPDATE HZ_CUSTOMER_PROFILES SET ATTRIBUTE6='null' WHERE CUST_ACCOUNT_ID='7520' ;
UPDATE HZ_CUSTOMER_PROFILES SET ATTRIBUTE6='null' WHERE CUST_ACCOUNT_ID='7571' ;
UPDATE HZ_CUSTOMER_PROFILES SET ATTRIBUTE6='null' WHERE CUST_ACCOUNT_ID='32178';
UPDATE HZ_CUSTOMER_PROFILES SET ATTRIBUTE6='null' WHERE CUST_ACCOUNT_ID='7304' ;
COMMIT;
UPDATE HZ_CUSTOMER_PROFILES SET ATTRIBUTE6='Y' WHERE CUST_ACCOUNT_ID='7520' AND SITE_USE_ID IS NULL;
UPDATE HZ_CUSTOMER_PROFILES SET ATTRIBUTE6='B' WHERE CUST_ACCOUNT_ID='7571' AND SITE_USE_ID IS NULL;
UPDATE HZ_CUSTOMER_PROFILES SET ATTRIBUTE6='P' WHERE CUST_ACCOUNT_ID='32178' AND SITE_USE_ID IS NULL;
UPDATE HZ_CUSTOMER_PROFILES SET ATTRIBUTE6='N' WHERE CUST_ACCOUNT_ID='7304' AND SITE_USE_ID IS NULL;
COMMIT;

PROMPT
PROMPT Altering the Table HZ_CUSTOMER_PROFILES is done.
PROMPT

SHOW ERRORS;
EXIT;

