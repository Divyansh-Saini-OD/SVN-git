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
-- | Name  :    XX_CS_TDS_PARTS_QUOTE_TBL                              |
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

DROP TYPE XX_CS_TDS_PARTS_QUOTE_TBL
/

SET TERM ON
PROMPT Creating Record type XX_CS_TDS_PARTS_QUOTE_REC_TYPE
SET TERM OFF

create or replace
TYPE XX_CS_TDS_PARTS_QUOTE_REC_TYPE
IS object
        (
          Item_number      VARCHAR2(25),
          Item_description VARCHAR2(250),
          RMS_SKU          VARCHAR2(25),
          Quantity         NUMBER,
          Item_category    VARCHAR2(25),
          Purchase_price   NUMBER,
          Selling_price    Number,
          Exchange_price   NUMBER,
          Core_flag        VARCHAR2(1),
          UOM              VARCHAR2(5),
          schedule_date    DATE,
          Attribue1        VARCHAR2(250),
          Attribue2        VARCHAR2(250),
          Attribue3        VARCHAR2(250),
          Attribue4        VARCHAR2(250),
          Attribue5        VARCHAR2(250)
        );

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_TDS_PARTS_QUOTE_TBL
SET TERM OFF


CREATE OR REPLACE TYPE XX_CS_TDS_PARTS_QUOTE_TBL IS TABLE OF XX_CS_TDS_PARTS_QUOTE_REC_TYPE
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


