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
-- | Name  :    XX_CS_TD_SR_TBL_TYPE                                   |
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

DROP TYPE XX_CS_TDS_SR_TBL_TYPE
/

SET TERM ON
PROMPT Creating Record type XX_CS_TDS_SR_REC_TYPE
SET TERM OFF

CREATE OR REPLACE
TYPE  XX_CS_TDS_SR_REC_TYPE AS OBJECT (
  request_date                          DATE,
    request_id                            NUMBER,
    request_number                        VARCHAR2(25),
    description                           VARCHAR2(240),
    customer_id                           NUMBER,
    customer_sku_id                       VARCHAR2(100),
    user_id                               VARCHAR2(100),
    language                              VARCHAR2(4),
    contact_id                            VARCHAR2(15),
    contact_name                          VARCHAR2(250),
    contact_phone                         VARCHAR2(50),
    contact_email                         VARCHAR2(250),
    contact_fax                           VARCHAR2(50),
    comments                              VARCHAR2(3000),
    order_number                          VARCHAR2(100),
    customer_number                       NUMBER,
    ship_date                             date,
    Ship_to                               varchar2(25),
    employee_id                           varchar2(50),
    Location_id                           number,
    preferred_contact                     varchar2(250),
    dev_ques_ans_id                       number,
    Attribute1                            varchar2(250),
    Attribute2                            varchar2(250),
    Attribute3                            varchar2(250),
    Attribute4                            varchar2(250),
    Attribute5                            varchar2(250),
    Attribute6                            varchar2(250),
    Attribute7                            varchar2(250),
    Attribute8                            varchar2(250),
    Attribute9                            varchar2(250),
    Attribute10                           varchar2(250))

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_TDS_SR_TBL_TYPE
SET TERM OFF


CREATE OR REPLACE
TYPE        XX_CS_TDS_SR_TBL_TYPE AS TABLE OF XX_CS_TDS_SR_REC_TYPE
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


