SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project C2FO Buyer Toggle                      |
-- +================================================================================+
-- | Name :INSERT_XX_AP_C2FO_FUND_SOURCE                                            |
-- | Description :   SQL Script to insert C2FO Funding Partner Bank Record          | 
-- | custom table    XX_AP_C2FO_FP_FUNDING_SOURCE 	                            |
-- | Rice ID     :                                                                  |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     17-May-2019  Arun DSouza	    	Initial version                     |
-- | V2.1     20-Jun-2019  Arun DSouza	    	Prodn version                       |
-- +================================================================================+

SET DEFINE OFF

 insert into  XX_AP_C2FO_FP_FUNDING_SOURCE 
   (FUND_TYPE, FUND_OPERATING_UNIT, FUND_SUPPLIER_NAME, FUND_SUPPLIER_SITE, FUND_BANK_ACCOUNT_NAME
   )
VALUES
     ('C2FO_FUNDING_PARTNER','OU_US','C2FO BUYER TOGGLE','E1374027','C2FO BUYER TOGGLE-1374027');


COMMIT;
/

SHOW ERROR