SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- |  Name  	:   XX_CE_EBAY_TABLES.grt                         |
-- |  RICE ID  	:   Custom Tables Grants                           	  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0      28-06-2018   M K Pramod Kumar     Initial version               |
-- +==========================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON xx_ce_mpl_Settlement_hdr TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON xx_ce_mpl_Settlement_dtl TO ERP_SYSTEM_TABLE_SELECT_ROLE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
