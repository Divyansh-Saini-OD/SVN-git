-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXOMGLOBALEXCEPTIONSOUT.grt                                                 |
-- | Rice Id      :                                                                             | 
-- | Description  : OD Exceptions Handling Grants Creation                                      |  
-- | Purpose      : Create Grant for Table XX_OM_GLOBAL_EXCEPTIONS_OUT.                         |
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
PROMPT Providing Grant on object xx_om_global_exceptions_out to Apps .....
PROMPT

GRANT ALL ON  xx_om_global_exceptions_out TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

