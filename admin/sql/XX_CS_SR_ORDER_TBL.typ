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
-- | Name  	  :    XX_CS_SR_ORDER_TBL                              |
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

DROP TYPE XX_CS_SR_ORDER_TBL
/

SET TERM ON
PROMPT Creating Record type XX_CS_SR_ORDER_REC_TYPE
SET TERM OFF

CREATE OR REPLACE
TYPE  XX_CS_SR_ORDER_REC_TYPE AS OBJECT
(
order_number              VARCHAR2(100),
order_sub                 varchar2(100),
sku_id                    varchar2(100),
Sku_description           varchar2(1000),
quantity                  number,
Manufacturer_info         varchar2(250),
order_link                varchar2(4000),
attribute1                varchar2(1000),
attribute2                varchar2(1000),
attribute3                varchar2(1000),
attribute4                varchar2(1000),
attribute5               varchar2(1000))

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_SR_ORDER_TBL
SET TERM OFF

CREATE OR REPLACE
TYPE XX_CS_SR_ORDER_TBL AS TABLE OF XX_CS_SR_ORDER_REC_TYPE

/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


