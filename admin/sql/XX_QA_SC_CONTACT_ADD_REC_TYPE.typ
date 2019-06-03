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
-- | Name  :    XX_QA_SC_CONTACT_ADD_REC_TYPE                                 |
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

-- DROP TYPE XX_QA_SC_CONTACT_ADD_REC_TYPE
-- /

SET TERM ON
PROMPT Creating Record type XX_QA_SC_CONTACT_ADD_REC_TYPE
SET TERM OFF

  
CREATE OR REPLACE  
TYPE XX_QA_SC_CONTACT_ADD_REC_TYPE AS OBJECT(
      address_1             VARCHAR2(500)
    , address_2             VARCHAR2(500)
    , address_3             VARCHAR2(500)
    , address_4             VARCHAR2(500)
    , address_city          VARCHAR2(500)
    , address_state         VARCHAR2(500)
    , address_country       VARCHAR2(500)
    )
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF




SHOW ERROR
