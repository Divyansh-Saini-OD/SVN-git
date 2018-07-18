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
-- | Name  :    XX_CS_TDS_SKU_REC_TYPE                                 |
-- | Description  : This script creates object type 		       	   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                    |
-- |=======   ==========  =============    	=======================    |
-- |DRAFT 1A 23-APR-10  Rajeswari Jagarlamudi   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

DROP TYPE XX_CS_TDS_SKU_REC_TYPE
/

SET TERM ON
PROMPT Creating Record type XX_CS_TDS_SKU_REC_TYPE
SET TERM OFF

create or replace
TYPE  XX_CS_TDS_SKU_REC_TYPE AS OBJECT
(
sku_id                    varchar2(100),
status                    varchar2(250),
comments                  varchar2(4000),
attribute1                varchar2(1000),
attribute2                varchar2(1000),
attribute3                varchar2(1000),
attribute4                varchar2(1000),
attribute5                varchar2(1000))

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_TDS_SKU_TBL
SET TERM OFF


CREATE OR REPLACE
TYPE XX_CS_TDS_SKU_TBL AS TABLE OF XX_CS_TDS_SKU_REC_TYPE
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


