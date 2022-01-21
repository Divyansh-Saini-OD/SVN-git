SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Index Script to create the table:  XX_GL_BEACON_MAPPING               |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       26-APR-2019   Priyam Parmar       Initial DRAFT version                      |
-- |                                                                                  |
-- +==================================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON


GRANT SELECT ON XX_FA_CTU_ERRORS TO ERP_SYSTEM_TABLE_SELECT_ROLE;


--GRANT INSERT,UPDATE,DELETE ON XX_FA_CTU_ERRORS TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT INSERT,UPDATE,DELETE ON XX_FA_CTU_ERRORS TO U887040;
GRANT INSERT,UPDATE,DELETE ON XX_FA_CTU_ERRORS TO U510093;

