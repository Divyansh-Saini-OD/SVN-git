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
-- | Name  :    XX_CS_ORDER_LINES_TBL                              |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 23-SEP-12  Rajeswari Jagarlamudi   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+



SET TERM ON
PROMPT Creating Record type XX_CS_ORDER_LINES_REC 
SET TERM OFF

create or replace
TYPE XX_CS_ORDER_LINES_REC IS OBJECT (
      line_number          NUMBER,
      vendor_part_number   VARCHAR2 (25),
      item_description     VARCHAR2 (250),
      sku                  VARCHAR2 (25),
      order_qty            NUMBER,
      selling_price        NUMBER,
      uom                  VARCHAR2 (15),
      comments             VARCHAR2 (2000),
      line_type            VARCHAR2 (1),
      po_number            VARCHAR2 (50),
      release              VARCHAR2 (50),
      serial_number        VARCHAR2 (50),
      cost_center          VARCHAR2 (50),
      desktop_location     VARCHAR2 (50),
      attribute1           VARCHAR2 (150),
      attribute2           VARCHAR2 (150),
      attribute3           VARCHAR2 (150),
      attribute4           VARCHAR2 (150),
      attribute5           VARCHAR2 (150),
      attribute6           VARCHAR2 (150),
      attribute7           VARCHAR2 (150),
      attribute8           VARCHAR2 (150),
      attribute9           VARCHAR2 (150),
      attribute10          VARCHAR2 (150),
      attribute11          VARCHAR2 (150),
      attribute12          VARCHAR2 (150),
      attribute13          VARCHAR2 (150),
      attribute14          VARCHAR2 (150),
      attribute15          VARCHAR2 (150)
   );

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_ORDER_LINES_TBL
SET TERM OFF


create or replace
TYPE XX_CS_ORDER_LINES_TBL IS TABLE OF XX_CS_ORDER_LINES_REC;
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


