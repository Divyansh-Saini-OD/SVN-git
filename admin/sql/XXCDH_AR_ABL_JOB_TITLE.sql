-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XXCDH_AR_ABL_JOB_TITLE.sql                          |
-- | Description : XXCDH_AR_ABL_JOB_TITLE Object Type                  |
-- |               Creation Script.                                    |
-- |               Type :                                              |
-- |                         VARCHAR2(4000)                            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |Draft 1a  01-JAN-10    Nabarun Ghosh    Initial Version            |
-- +===================================================================+

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT Creating OBJECT TYPE XXCDH_AR_ABL_JOB_TITLE
PROMPT

CREATE OR REPLACE TYPE XXCDH_AR_ABL_JOB_TITLE AS TABLE OF VARCHAR2(4000);
/

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
