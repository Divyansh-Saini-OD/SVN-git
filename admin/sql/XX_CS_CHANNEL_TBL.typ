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
-- | Name         :    XX_CS_CHANNEL_TBL                               |
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

DROP TYPE X_CS_CHANNEL_TBL
/

SET TERM ON
PROMPT Creating type XX_CS_SR_REC_TYPE
SET TERM OFF

CREATE OR REPLACE  TYPE XX_CS_CHANNEL_TBL AS TABLE OF VARCHAR2(100)

/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR
