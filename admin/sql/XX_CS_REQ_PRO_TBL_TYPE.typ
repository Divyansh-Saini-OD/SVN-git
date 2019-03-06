SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :    XX_CS_REQ_PRO_TBL_TYPE                                 |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 23-OCT-07  Rajeswari Jagarlamudi   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

DROP TYPE XX_CS_REQ_PRO_TBL_TYPE
/

SET TERM ON
PROMPT Creating Record type XX_CS_REQ_PRO_REC_TYPE
SET TERM OFF

CREATE OR REPLACE
TYPE  XX_CS_REQ_PRO_REC_TYPE AS OBJECT (
REQUEST_ID       NUMBER,
REQUEST_TYPE     VARCHAR2(200),
PROBLEM_CODE     VARCHAR2(200),
PROBLEM_DESCR    VARCHAR2(500))

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_REQ_PRO_TBL_TYPE
SET TERM OFF



CREATE OR REPLACE
TYPE XX_CS_REQ_PRO_TBL_TYPE AS TABLE OF XX_CS_REQ_PRO_REC_TYPE
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR



