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
-- | Name  	  :    XX_CS_SR_STATUS_TBL                             |
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

DROP TYPE XX_CS_SR_STATUS_TBL
/

SET TERM ON
PROMPT Creating Record type XX_CS_SR_STATUS_REC
SET TERM OFF

CREATE OR REPLACE
TYPE XX_CS_SR_STATUS_REC AS OBJECT ( STATUS VARCHAR2(50), STATUS_ID NUMBER )
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_SR_STATUS_TBL
SET TERM OFF

CREATE OR REPLACE
TYPE XX_CS_SR_STATUS_TBL AS TABLE OF XX_CS_SR_STATUS_REC
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR
