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
-- | SQL Index Script to create the table:  xx_fa_status               |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       15-MAR-2019   Priyam Parmar       Initial DRAFT version                      |
-- |                                                                                  |
-- +==================================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON xx_fa_status TO ERP_SYSTEM_TABLE_SELECT_ROLE;

GRANT INSERT,UPDATE,DELETE ON xx_fa_status TO U887040;
GRANT INSERT,UPDATE,DELETE ON xx_fa_status TO U510093;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
