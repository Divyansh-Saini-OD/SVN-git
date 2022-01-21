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
-- | SQL Script to create Grants for the table:  XX_AP_CLD_SUPP_CONTACT_STG              |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       18-JUN-2019   Priyam/Visu         Initial DRAFT version                 |
-- |                                                                                  |
-- +==================================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON XX_AP_CLD_SUPP_CONTACT_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
