SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==========================================================================+
-- |                  Office Depot C2FO                                       |
-- +==========================================================================+
-- |  Name  	: XX_AP_C2FO_FP_FUNDING_SOURCE.grt                            |
-- |  RICE ID :                                                               |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0     16-MAY-19     Arun DSouza  	    Initial version           |
-- +==========================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON XX_AP_C2FO_FP_FUNDING_SOURCE TO ERP_SYSTEM_TABLE_SELECT_ROLE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
