SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==========================================================================+
-- |                  Office Depot SMB Internal Market Place                  |
-- +==========================================================================+
-- |  Name  	: XX_AP_SMB_INT_MKT_STG.grt                                   |
-- |  RICE ID :                                                            	  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0     18-Oct-18     Arun D' souza 	    Initial version               |
-- +==========================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON XX_AP_SMB_INT_MKT_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
