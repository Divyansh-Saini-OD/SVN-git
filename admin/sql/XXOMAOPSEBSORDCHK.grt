-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXOMAOPSEBSORDCHK.grt                                                       |
-- | Rice Id      :                                                                             | 
-- | Description  : Grants Creation                                                             |  
-- | Purpose      : Create Grant on table XX_OM_AOPS_EBS_ORD_CHK.                                |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   08-SEP-2008   Bala E               Initial Version                               |
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
PROMPT Providing Grant on object XX_OM_AOPS_EBS_ORD_CHK.tbl to Apps .....
PROMPT

GRANT ALL ON  XX_OM_AOPS_EBS_ORD_CHK TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;