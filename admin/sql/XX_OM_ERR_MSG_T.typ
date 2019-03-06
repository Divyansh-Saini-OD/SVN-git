SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_ERR_MSG_T.typ                                    |
-- | Description      : This script creates object type XX_OM_ERR_MSG_T|
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 13-JUN-2007  Rizwan A         Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

DROP TYPE BPEL_AQADM.XX_OM_ERR_MSG_T
/

SET TERM ON
PROMPT Creating object type XX_OM_ERR_MSG_T
SET TERM OFF

CREATE OR REPLACE TYPE BPEL_AQADM.XX_OM_ERR_MSG_T AS OBJECT(ERR_MSG_T XMLTYPE)
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF


SHOW ERROR

