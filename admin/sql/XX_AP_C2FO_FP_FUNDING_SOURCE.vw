SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - C2FO Funding Program Buyer Toggle                                 |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Script to create the Editioned View for table  XX_AP_C2FO_FP_FUNDING_SOURCE  |
-- |                                                                                  |
-- |RICE_ID:                                                                          |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   ===============      =====================================|
-- | 1.0     16-May-19     Arun D'Souza 	    Initial version                   |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating Edition View for XX_AP_C2FO_FP_FUNDING_SOURCE.....
PROMPT **Edition View creates as XX_AP_C2FO_FP_FUNDING_SOURCE# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_C2FO_FP_FUNDING_SOURCE in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_C2FO_FP_FUNDING_SOURCE');

SHOW ERRORS;
EXIT;