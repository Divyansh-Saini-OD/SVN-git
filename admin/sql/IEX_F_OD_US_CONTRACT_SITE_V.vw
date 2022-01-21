SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  IEX_F_OD_US_CONTRACT_SITE_V.vw                     |
-- | Description :                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |                                                                   | 
-- +===================================================================+
CREATE OR REPLACE FORCE VIEW IEX_F_OD_US_CONTRACT_SITE_V (CUSTOMER_SITE_USE_ID)
AS
  SELECT DEL.customer_site_use_id
  FROM iex_f_accounts_V DEL
  WHERE EXISTS
    (SELECT cust_account_id
    FROM hz_cust_accounts HCA
    WHERE HCA.cust_account_id = DEL.cust_account_id
    AND HCA.attribute18       = 'CONTRACT'
    ) ;
/
SHOW ERRORS;
EXIT;



