SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT CREATING GRANT XX_C2T_CC_TOKEN_STG_EXCPTNS
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : XX_C2T_CC_TOKEN_STG_EXCPTNS_GRT                                     |
-- | Description : Create grants for the table XX_C2T_CC_TOKEN_STG_EXCPTNS             |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date         Author               Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | V1.0     24-MAR-2016  Avinash Baddam       Initial version                        |
-- |                                                                                   |
-- +===================================================================================+

PROMPT GRANT SELECT TO ERP_SYSTEM_TABLE_SELECT_ROLE.....
GRANT SELECT ON XXFIN.XX_C2T_CC_TOKEN_STG_EXCPTNS TO ERP_SYSTEM_TABLE_SELECT_ROLE;

/
SHOW ERROR
