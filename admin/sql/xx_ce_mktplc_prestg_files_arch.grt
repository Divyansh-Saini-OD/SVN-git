SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- |  Name  	:   xx_ce_mktplc_prestg_files_arch.grt                         |
-- |  RICE ID  	:   I3123                       	  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0      27-MAR-19   Priyam P      	    Initial version               |
-- +==========================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON xx_ce_mktplc_prestg_files_arch TO ERP_SYSTEM_TABLE_SELECT_ROLE;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
