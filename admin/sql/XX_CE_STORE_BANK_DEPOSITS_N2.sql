-- +============================================================================================+
-- |                        				Office Depot 		                                |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_CE_STORE_BANK_DEPOSITS_N2.idx                                            |
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

CREATE INDEX XX_CE_STORE_BANK_DEPOSITS_N2 ON XXFIN.XX_CE_STORE_BANK_DEPOSITS ( STATUS_CD );

EXIT;
