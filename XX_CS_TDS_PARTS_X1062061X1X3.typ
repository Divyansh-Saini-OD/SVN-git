SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Oracle GSD   - Hyderabad, India                  |
-- +===================================================================+
-- | Name  :    XX_CS_TDS_PARTS_STATUS_TBL                             |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |1.0      01-AUG-11  Sreenivasa Tirumala     Initial draft version  |
-- |                                                                   |
-- +===================================================================+

DROP TYPE XX_CS_TDS_PARTS_X1062061X1X3
/

SET TERM ON
PROMPT Creating Record type XX_CS_TDS_PARTS_X1062061X1X3
SET TERM OFF

create or replace TYPE XX_CS_TDS_PARTS_X1062061X1X3 AS OBJECT (
RMS_SKU VARCHAR2(25),
ITEM_DESCRIPTION VARCHAR2(250),
QUANTITY NUMBER,
PURCHASE_PRICE NUMBER,
SELLING_PRICE NUMBER,
UOM VARCHAR2(5)
);
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_TDS_PARTS_X1062061X1X3
SET TERM OFF


create or replace TYPE XX_CS_TDS_PARTS_X1062061X1X2 AS TABLE OF APPS.XX_CS_TDS_PARTS_X1062061X1X3;
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


