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
-- | Name  :    XX_CS_TDS_PARTS_HDR_TBL                                |
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

DROP TYPE XX_CS_TDS_PARTS_HDR_TBL
/

SET TERM ON
PROMPT Creating Record type XX_CS_TDS_PARTS_GET_ORDER_REC
SET TERM OFF

CREATE OR REPLACE TYPE XX_CS_TDS_PARTS_GET_ORDER_REC IS OBJECT (
      user_name            VARCHAR2 (100),
      order_number         VARCHAR2 (64),
      order_date           DATE,
      modify_flag          VARCHAR2(1),
      status_code          VARCHAR2 (30),
      contact_name         VARCHAR2 (150),
      location_id          VARCHAR2 (150),
      order_type           VARCHAR2 (1),
      order_source         VARCHAR2 (150),
      vendor_code          VARCHAR2 (150),
      total                NUMBER,
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
PROMPT Creating tbl type XX_CS_TDS_PARTS_HDR_TBL
SET TERM OFF


CREATE OR REPLACE TYPE XX_CS_TDS_PARTS_HDR_TBL  IS TABLE OF XX_CS_TDS_PARTS_GET_ORDER_REC;
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


