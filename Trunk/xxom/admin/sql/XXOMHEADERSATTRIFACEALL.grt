-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXOMHEADERSATTRIFACEALL.grt                                                 |
-- | Rice Id      : I1272                                                                       | 
-- | Description  : INT-I1272_SalesOrderFrom LegacySystems(HVOP) Grants Creation                |  
-- | Purpose      : Create Grant on table XX_OM_HEADERS_ATTR_IFACE_ALL.                         |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   03-May-2007   Bapuji Nanapaneni    Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


PROMPT
PROMPT Providing Grant on Custom Tables,object and Sequence to Apps......
PROMPT

PROMPT
PROMPT Providing Grant on object XX_OM_HEADERS_ATTR_IFACE_ALL.tbl to Apps .....
PROMPT

GRANT ALL ON  XX_OM_HEADERS_ATTR_IFACE_ALL.tbl TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
EXIT;
