SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- |  Name  	:   XX_CE_MKTPLC_PRE_STG_EXCPN.grt                         |
-- |  RICE ID  	:   I3123                       	  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0     08-AUG-18   Priyam P      	    Initial version               |
-- +==========================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON XX_CE_MKTPLC_PRE_STG_EXCPN TO ERP_SYSTEM_TABLE_SELECT_ROLE;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
