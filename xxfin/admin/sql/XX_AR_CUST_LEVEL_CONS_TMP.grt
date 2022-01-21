SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT CREATING GRANT XX_AR_CUST_LEVEL_CONS_TMP
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : XX_AR_CUST_LEVEL_CONS_TMP                                           |
-- | Description : Create grants for the table XX_AR_CUST_LEVEL_CONS_TMP               |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date         Author               Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | V1.0     07-OCT-2010  Navin Agarwal        Initial version                        |
-- |                                                                                   |
-- +===================================================================================+

GRANT ALL ON XXFIN.XX_AR_CUST_LEVEL_CONS_TMP TO APPS;

/
SHOW ERROR

