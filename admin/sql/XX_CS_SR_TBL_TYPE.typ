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
-- | Name  :    XX_CS_SR_TBL_TYPE                                      |
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

DROP TYPE XX_CS_SR_TBL_TYPE
/

SET TERM ON
PROMPT Creating Record type XX_CS_SR_REC_TYPE
SET TERM OFF

CREATE OR REPLACE
TYPE  XX_CS_SR_REC_TYPE AS OBJECT (
  request_date                          DATE,
  request_id                            NUMBER,
  request_number                        NUMBER,
  type_id                               NUMBER,
  type_name                             VARCHAR2(30),
  status_name                           VARCHAR2(30),
  owner_id                              NUMBER,
  owner_group_id                        NUMBER,
  description                           VARCHAR2(240),
  caller_type                           VARCHAR2(30),
  customer_id                           NUMBER,
  customer_sku_id                       VARCHAR2(100),
  user_id                               VARCHAR2(100),
  language                              VARCHAR2(4),
  problem_code                          VARCHAR2(50),
  resolution_code                       VARCHAR2(50),
  exp_resolution_date                   DATE,
  act_resolution_date                   DATE,
  channel                               VARCHAR2(100),
  contact_name                          VARCHAR2(100),
  contact_phone                         VARCHAR2(50),
  contact_email                         VARCHAR2(100),
  contact_fax                           VARCHAR2(50),
  comments                              VARCHAR2(1000),
  order_number                          VARCHAR2(100),
  customer_number                       NUMBER,
  ship_date                             date,
  account_mgr_email                     varchar2(500),
  sales_rep_contact                     varchar2(250),
  sales_rep_contact_phone               varchar2(25),
  sales_rep_contact_email              varchar2(50),
  sales_rep_contact_name                varchar2(100),
  sales_rep_contact_ext                 varchar2(25),
  warehouse_id                          number,
  global_ticket_flag                    varchar2(1),
  global_ticket_number                  number,
  preferred_contact                     varchar2(100),
  Ship_to                               varchar2(25),
  zz_flag                               varchar2(25))

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_SR_TBL_TYPE
SET TERM OFF


CREATE OR REPLACE
TYPE        XX_CS_SR_TBL_TYPE AS TABLE OF XX_CS_SR_REC_TYPE
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


