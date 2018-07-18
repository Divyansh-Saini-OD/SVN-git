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
-- | Name  :    XX_CS_TDS_PARTS_HDR_REC                                |
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

DROP TYPE XX_CS_TDS_PARTS_HDR_REC
/

SET TERM ON
PROMPT Creating Record type XX_CS_TDS_PARTS_HDR_REC
SET TERM OFF

CREATE OR REPLACE TYPE XX_CS_TDS_PARTS_HDR_REC IS OBJECT (
      order_number         VARCHAR2 (64),
      order_status         VARCHAR2 (30),
      location_id          VARCHAR2 (150),
      reforderno           VARCHAR2 (150),
      refordersub          VARCHAR2 (3),
      creation_date        DATE,
      modified_date        DATE,
      order_type           VARCHAR2 (20),
      contact_name         VARCHAR2 (150),
      contact_email        VARCHAR2 (150),
      contact_phone        VARCHAR2 (150),
      customer_po_number   VARCHAR2 (150),
      location_name        VARCHAR2 (240),
      tendertyp            VARCHAR2 (30),
      cccid                VARCHAR2 (80),
      tndacctnbr           VARCHAR2 (80),
      exp_date             DATE,
      avscode              VARCHAR2 (80),
      bill_to              VARCHAR2(150),  
      status_code          VARCHAR2(1),
      number_of_lines      NUMBER,
      subtotal             NUMBER,
      order_source_code    VARCHAR2(1),
      order_total          NUMBER,
      bill_address_seq     VARCHAR2(8),
      billing_name         VARCHAR2(30),
      contact_seq_id       VARCHAR2(5),
      special_instructions VARCHAR2(2000),
      associate_id         NUMBER,
      order_category       VARCHAR2(1),
      contact_id           NUMBER,
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

SHOW ERROR


