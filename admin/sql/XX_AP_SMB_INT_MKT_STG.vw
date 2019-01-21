SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - C2FO                                                              |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_AP_SMB_INT_MKT_STG                           |
-- |                                                                                  |
-- |RICE_ID:                                                                          |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   ===============      =====================================|
-- | 1.0     18-Oct-18     Arun D' souza 	    Initial version                       |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating Edition View for XX_AP_SMB_INT_MKT_STG .....
PROMPT **Edition View creates as XX_AP_SMB_INT_MKT_STG# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_SMB_INT_MKT_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_SMB_INT_MKT_STG');

SHOW ERRORS;
EXIT;