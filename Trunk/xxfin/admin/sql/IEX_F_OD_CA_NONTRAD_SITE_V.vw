SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  IEX_F_OD_CA_NONTRAD_SITE_V.vw                       |
-- | Description :                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |                                                                   | 
-- +===================================================================+
CREATE OR REPLACE FORCE VIEW IEX_F_OD_CA_NONTRAD_SITE_V (CUSTOMER_SITE_USE_ID)
AS
  SELECT DEL.customer_site_use_id
  FROM iex_f_accounts_V DEL
  WHERE EXISTS
    (SELECT cust_account_id
    FROM hz_cust_accounts HCA ,
      hz_parties HZP
    WHERE HCA.cust_account_id = DEL.cust_account_id
    AND HCA.party_id          = HZP.party_id
    AND HZP.category_code    IN
      (SELECT FFV.FLEX_VALUE
      FROM FND_FLEX_VALUE_SETS FFVS ,
        FND_FLEX_VALUES FFV
      WHERE FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
      AND FFVS.flex_value_set_name = 'XX_AR_CUST_NONTRAD'
      )
    ) ;
/
SHOW ERRORS;
EXIT;



