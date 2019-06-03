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
-- | Name  :    XX_QA_SC_FINDINGS_REC_TYPE                                 |
-- | Description  : This script creates object type 		       	   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                    |
-- |=======   ==========  =============    	=======================    |
-- |DRAFT 1A 23-APR-11  Bala E   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

-- DROP TYPE XX_QA_SC_FINDINGS_REC_TYPE
-- /

SET TERM ON
PROMPT Creating Record type XX_QA_SC_FINDINGS_REC_TYPE
SET TERM OFF

CREATE OR REPLACE
TYPE XX_QA_SC_FINDINGS_REC_TYPE AS OBJECT (
      question_code       VARCHAR2(1000) 
    , section             VARCHAR2(1000)
    , sub_section         VARCHAR2(1000) 
    , question            VARCHAR2(1000) 
    , answer               VARCHAR2(1000)
    , nayn                 VARCHAR2(10)
    , auditor_comments     VARCHAR2(2000) 
    , find_attribute1      VARCHAR2(150)
    , find_attribute2      VARCHAR2(150)
    , find_attribute3      VARCHAR2(150)
    , find_attribute4      VARCHAR2(150)
    , find_attribute5      VARCHAR2(150)
    )

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_QA_SC_FINDINGS_TBL_TYPE
SET TERM OFF


CREATE OR REPLACE
TYPE XX_QA_SC_FINDINGS_TBL_TYPE AS TABLE OF XX_QA_SC_FINDINGS_REC_TYPE
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


