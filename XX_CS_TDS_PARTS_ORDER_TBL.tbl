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
-- | Name  :    XX_CS_TDS_PARTS_ORDER_TBL                              |
-- | Description  : This script creates object type       	       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |1.0      02-AUG-11    Gaurav Agarwal      Initial draft version  |
-- |                                                                   |
-- +===================================================================+

DROP TYPE XX_CS_TDS_PARTS_ORDER_TBL
/

SET TERM ON
PROMPT Creating Record type xx_cs_tds_order_items_rec
SET TERM OFF

create or replace TYPE xx_cs_tds_order_items_rec IS OBJECT (
      rms_sku            VARCHAR2 (25),
      item_description   VARCHAR2 (250),
      quantity           NUMBER,
      purchase_price     NUMBER,
      selling_price      NUMBER,
      uom                VARCHAR2 (5)
   );
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_TDS_PARTS_ORDER_TBL
SET TERM OFF


CREATE OR REPLACE TYPE XX_CS_TDS_PARTS_ORDER_TBL IS TABLE OF xx_cs_tds_order_items_rec
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


