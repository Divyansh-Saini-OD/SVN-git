SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF
-- +===================================================================+
-- |                        Office Depot                               |
-- |                                                                   |
-- +===================================================================+
-- | Script Name  :  XX_COM_OID_ERROR_LOG.grt                          |
-- | Description  :  Grants on custom table XX_COM_OID_ERROR_LOG       | 
-- |                                                                   |
-- | Rice Id      :                                                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       22-MAY-2015  Manikant Kasu      Initial draft version    |
-- +===================================================================+
WHENEVER SQLERROR CONTINUE;
SET TERM ON

PROMPT
PROMPT 'Granting the Table XXCOMN.XX_COM_OID_ERROR_LOG'
PROMPT

PROMPT 'Granting XX_COM_OID_ERROR_LOG'
GRANT SELECT ON XXCOMN.XX_COM_OID_ERROR_LOG TO ERP_SYSTEM_TABLE_SELECT_ROLE
/

PROMPT 'Granting XX_COM_OID_ERROR_LOG to APPS'
GRANT ALL ON XXCOMN.XX_COM_OID_ERROR_LOG TO APPS
/
    
PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SHOW ERRORS;
EXIT;