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
-- | Name  	  :    XX_CS_SR_MAIL_NOTES_REC                         |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 23-DEC-09  Rajeswari Jagarlamudi   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


SET TERM ON
PROMPT Creating Record type XX_CS_SR_MAIL_NOTES_REC
SET TERM OFF

create or replace TYPE  XX_CS_SR_MAIL_NOTES_REC AS OBJECT (
NOTES           VARCHAR2(2000)  ,
NOTE_DETAILS    VARCHAR2(32767) ,
CREATION_DATE   DATE,
CREATED_BY      VARCHAR2(100))

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SHOW ERROR


