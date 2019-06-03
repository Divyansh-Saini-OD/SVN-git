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
-- | Name  :    XX_QA_SC_VIOLATION_REC_TYPE                                 |
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

-- DROP TYPE XX_QA_SC_VENDOR_REC_TYPE
-- /

SET TERM ON
PROMPT Creating Record type XX_QA_SC_VENDOR_REC_TYPE
SET TERM OFF

CREATE OR REPLACE   
TYPE XX_QA_SC_VENDOR_REC_TYPE AS OBJECT (
      od_vendor_no            VARCHAR2(150) 
    , vendor                  VARCHAR2(1000)
    , vendor_address          XX_QA_SC_CONTACT_ADD_REC_TYPE    
    , vendor_contact          XX_QA_SC_VENDOR_CONT_REC_TYPE 
    , entity_id               VARCHAR2(150)
    , od_factory_no           VARCHAR2(150)
    , base_address            VARCHAR2(1000)
    , city                    VARCHAR2(150)
    , state                   VARCHAR2(150)
    , country                 VARCHAR2(150)
    , factory_contacts        XX_QA_SC_VENDOR_CONT_REC_TYPE   
    , factory_status          VARCHAR2(150)
    , invoice_no              VARCHAR2(150)
    , invoice_date            DATE 
    , invoice_amount          VARCHAR2(150)
    , payment_method          VARCHAR2(150)
    , payment_date            DATE
    , payment_amount          VARCHAR2(150)
    , grade                   VARCHAR2(150)
    , region                  VARCHAR2(150)
    , sub_region              VARCHAR2(150)
    , vendor_attribute1       VARCHAR2(150)
    , vendor_attribute2       VARCHAR2(150)
    , vendor_attribute3       VARCHAR2(150)
    , vendor_attribute4       VARCHAR2(150)
    , vendor_attribute5       VARCHAR2(150)
    )

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_QA_SC_VENDOR_REC_TYPE
SET TERM OFF


CREATE OR REPLACE
TYPE XX_QA_SC_VENDOR_TBL_TYPE AS TABLE OF XX_QA_SC_VENDOR_REC_TYPE
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


