-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization                        |
-- +============================================================================================+
-- | Name         : XX_OM_GLOBALNOTIFY.grt                                                      |
-- | Rice Id      : E0270_GlobalNotification                                                    | 
-- | Description  : Global Notification creating grants on Temporary table                      |  
-- | Purpose      : Providing grant on custom table.                                            |
-- |                1. XX_OM_GLOBALNOTIFY (Holding Deferred order details )                     |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author           Remarks                                           | 
-- |=======    ==========    =============    ==================================================+
-- |DRAFT 1A   17-July-2007  Pankaj Kapse     Initial Version                                   |
-- |                                                                                            |
-- +============================================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Providing Grant on Custom Tables to Apps......
PROMPT

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Providing Grant on the Table XX_OM_GLOBALNOTIFY to Apps .....
PROMPT


GRANT ALL ON XX_OM_GLOBALNOTIFY TO APPS;


WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;