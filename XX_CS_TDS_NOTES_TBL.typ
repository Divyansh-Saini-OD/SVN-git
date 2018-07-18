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
-- | Name  :    XX_CS_TDS_NOTES_TBL                                    |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 23-APR-10  Rajeswari Jagarlamudi   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

--DROP TYPE XX_CS_TDS_NOTES_TBL
--/

SET TERM ON
PROMPT Creating Record type XX_CS_TDS_NOTES_REC 
SET TERM OFF

create or replace TYPE  XX_CS_TDS_NOTES_REC AS OBJECT (
NOTE_TYPE     VARCHAR2(100),
NOTES         VARCHAR2(1000),
NOTE_DETAILS  VARCHAR2(2000),
CREATION_DATE DATE,
CREATED_BY    VARCHAR2(100));

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_TDS_NOTES_TBL
SET TERM OFF

create or replace TYPE XX_CS_TDS_NOTES_TBL AS TABLE OF XX_CS_TDS_NOTES_REC;

/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


