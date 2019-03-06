SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :    XX_CS_REQUEST_TBL_TYPE                                 |
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

DROP TYPE XX_CS_REQUEST_TBL_TYPE;
/

SET TERM ON
PROMPT Creating Record type XX_CS_SR_REC_TYPE
SET TERM OFF

create or replace TYPE        "XX_CS_REQUEST_REC_TYPE" AS OBJECT (
REQUEST_ID       NUMBER,
REQUEST_TYPE     VARCHAR2(200) );

/
SET TERM ON
PROMPT Record type XX_CS_SR_REC_TYPE created
SET TERM OFF

SET TERM ON
PROMPT Creating type XX_CS_REQUEST_TBL_TYPE
SET TERM OFF

create or replace TYPE  XX_CS_REQUEST_TBL_TYPE AS TABLE OF XX_CS_REQUEST_REC_TYPE;
/

SET TERM ON
PROMPT Type XX_CS_REQUEST_TBL_TYPE created
SET TERM OFF

SHOW ERROR;
EXIT;


