SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT CREATING GRANT XX_C2T_CC_TOKEN_CRYPTO_EXT
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : XX_C2T_CC_TOKEN_CRYPTO_EXT_GRT                                        |
-- | Description : Create grants for the table XX_C2T_CC_TOKEN_CRYPTO_EXT                |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date         Author               Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | V1.0     13-OCT-2015  Harvinder Rakhra     Initial version                        |
-- |                                                                                   |
-- +===================================================================================+

PROMPT GRANT SELECT TO ERP_SYSTEM_TABLE_SELECT_ROLE.....
GRANT SELECT ON XXFIN.XX_C2T_CC_TOKEN_CRYPTO_EXT TO ERP_SYSTEM_TABLE_SELECT_ROLE;

/
SHOW ERROR
