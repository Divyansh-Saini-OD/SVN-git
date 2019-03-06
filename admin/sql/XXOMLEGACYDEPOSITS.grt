-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXOMLEGACYDEPOSITS.grt                                                      |
-- | Rice Id      : I1272                                                                       | 
-- | Description  : INT-I1272_SalesOrderFrom LegacySystems(HVOP) Grants Creation                |  
-- | Purpose      : Create Grant on table XX_OM_LEGACY_DEPOSITS.                                |
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
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

COLUMN XXOM_login   NEW_VALUE XXOM_LOGIN   NOPRINT
COLUMN XXOM_user    NEW_VALUE XXOM_USER    NOPRINT


SET TERM ON

SELECT '&&1' XXOM_LOGIN
      ,'&&2' XXOM_USER
FROM  SYS.dual
WHERE ROWNUM = 1;

WHENEVER SQLERROR EXIT 1

Prompt Connecting TO Custom SCHEMA &&XXOM_USER

CONNECT &&XXOM_LOGIN;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Providing Grant on Custom Tables,object and Sequence to Apps......
PROMPT

PROMPT
PROMPT Providing Grant on object XX_OM_LEGACY_DEPOSITS.tbl to Apps .....
PROMPT

GRANT ALL ON  XX_OM_LEGACY_DEPOSITS TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

