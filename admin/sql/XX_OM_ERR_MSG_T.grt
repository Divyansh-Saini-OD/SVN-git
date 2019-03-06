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
-- | Name  :    XX_OM_ERR_MSG_T                                        |
-- | Description      : This scipt grants privileges on XX_OM_ERR_MSG_T|
-- |                    to B2B_COMMON                                  |
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
PROMPT Granting Privileges XX_OM_ERR_MSG_T to B2B_COMMON
SET TERM OFF

GRANT AQ_USER_ROLE TO B2B_COMMON
/
GRANT EXECUTE ON BPEL_AQADM.XX_OM_ERR_MSG_T TO B2B_COMMON
/

SET TERM ON
PROMPT Privileges Granted
SET TERM OFF


SHOW ERROR



