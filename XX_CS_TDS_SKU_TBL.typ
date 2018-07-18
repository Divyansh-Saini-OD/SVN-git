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
-- | Name  :    XX_CS_TDS_SKU_TBL                                      |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 23-APR-10  Rajeswari Jagarlamudi   Initial draft version  |
-- |         16-Nov-10	Rajeswari Jagarlamudi	Attribute2 change      |
-- |                                                                   |
-- +===================================================================+

DROP TYPE XX_CS_TDS_SKU_TBL
/

SET TERM ON
PROMPT Creating Record type XX_CS_TDS_SKU_REC_TYPE
SET TERM OFF

create or replace TYPE  XX_CS_TDS_SKU_REC_TYPE AS OBJECT
(
sku_id                    varchar2(100),
Sku_category              varchar2(250),
parent_sku                varchar2(100),
sku_relations             varchar2(250),
attribute1                varchar2(1000),
attribute2                varchar2(4000));

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_TDS_SKU_TBL
SET TERM OFF


create or replace TYPE XX_CS_TDS_SKU_TBL AS TABLE OF XX_CS_TDS_SKU_REC_TYPE;

/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


