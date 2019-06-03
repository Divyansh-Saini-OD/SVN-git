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
-- | Name  :    XX_QA_SC_CONT_PHONE_REC_TYPE                                 |
-- | Description  : This script creates object type 		       	   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 23-APR-11  Bala E			Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

-- DROP TYPE XX_QA_SC_CONT_PHONE_REC_TYPE
-- /

SET TERM ON
PROMPT Creating Record type XX_QA_SC_CONT_PHONE_REC_TYPE
SET TERM OFF

  
CREATE OR REPLACE
TYPE XX_QA_SC_CONT_PHONE_REC_TYPE IS OBJECT (
      contact_type       VARCHAR2(1000)
    , contact_no         VARCHAR2(150)
    )
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF




SHOW ERROR
