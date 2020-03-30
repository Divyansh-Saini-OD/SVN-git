-- +============================================================================================+
-- |                        				Office Depot 		                                |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_CE_STORE_BANK_DEPOSITS_F1.idx                                            |
-- | Rice Id      :                                                                             | 
-- | Description  :                                                                             |  
-- | Purpose      :                                                                             |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |1.0		   30-MAR-2020   AMIT KUMAR    		  Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

CREATE INDEX XFIN.XX_CE_BANK_ACCOUNTS_N11 ON CE.CE_BANK_ACCOUNTS SUBSTR (CBA.AGENCY_LOCATION_CODE, 3);

WHENEVER SQLERROR EXIT 1

EXIT;

