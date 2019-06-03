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
-- | Name  :    XX_QA_SC_AUDIT_REC_TYPE                                 |
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

-- DROP TYPE XX_QA_SC_AUDIT_REC_TYPE
-- /

SET TERM ON
PROMPT Creating Record type XX_QA_SC_AUDIT_REC_TYPE
SET TERM OFF

CREATE OR REPLACE
TYPE XX_QA_SC_AUDIT_REC_TYPE IS OBJECT (
      transmission_status         VARCHAR2(150) 
    , client                      VARCHAR2(150) 
    , inspection_no               VARCHAR2(150) 
    , inspection_id               VARCHAR2(250) 
    , inspection_type             VARCHAR2(150) 
    , service_type                VARCHAR2(150) 
    , qa_profile                  VARCHAR2(150) 
    , status                      VARCHAR2(150) 
    , complete_by_start_date      DATE 
    , complete_by_end_date        DATE 
    , audit_schduled_date         DATE 
    , inspection_date             DATE 
    , inspection_time_in          VARCHAR2(150) 
    , inspection_time_out         VARCHAR2(150) 
    , inspection_schduled_date    DATE 
    , initial_inspection_date     DATE 
    , relationships               VARCHAR2(150) 
    , inspectors_schduled         VARCHAR2(10) --DATE 
    , inspection_month            VARCHAR2(10) 
    , inspection_year             VARCHAR2(10) 
    , insert_line_id              NUMBER
    , attribute1                  VARCHAR2(150)
    , attribute2                  VARCHAR2(150)
    , attribute3                  VARCHAR2(150)
    , attribute4                  VARCHAR2(150)
    , attribute5                  VARCHAR2(150)
    )
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF



SHOW ERROR
