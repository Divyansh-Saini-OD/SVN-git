SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_DPS_ERR_MSG_AQTBL                                |
-- | Description      : This script grants privileges on               |
-- |                    XX_OM_DPS_ERR_MSG_AQTBL to B2B_COMMON          |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 12-JUN-2007  Rizwan  A        Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


SET TERM ON
PROMPT Granting Privileges XX_OM_DPS_ERR_MSG_AQTBL to B2B_COMMON
SET TERM OFF

GRANT SELECT, INSERT, UPDATE, DELETE
   ON BPEL_AQADM.XX_OM_DPS_ERR_MSG_AQTBL TO B2B_COMMON
/

SET TERM ON
PROMPT Privileges Granted
SET TERM OFF


SHOW ERROR





