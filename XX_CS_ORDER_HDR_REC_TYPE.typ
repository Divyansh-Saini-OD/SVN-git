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
-- | Name  :    XX_CS_ORDER_HDR_REC 
|
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
PROMPT Creating Record type XX_CS_ORDER_HDR_REC 
SET TERM OFF

create or replace
TYPE XX_CS_ORDER_HDR_REC IS OBJECT (
      Request_number       VARCHAR2 (64),
      Party_id             VARCHAR2 (30),
      creation_date        DATE,
      modified_date        DATE,
      order_number	   varchar2(25),
      order_sub		   varchar2(25),
      order_type           VARCHAR2 (20),
      status_code          VARCHAR2(1),
      number_of_lines      NUMBER,
      order_total          NUMBER,
      subtotal             NUMBER,
      order_source_code    VARCHAR2(1),
      order_category       VARCHAR2(5),
      customer_po_number   VARCHAR2 (50),
      serial_no            VARCHAR2 (25),
      po_number            VARCHAR2 (50),
      release              VARCHAR2 (50),
      cost_center          VARCHAR2 (50),
      desk_top             VARCHAR2 (100),
      printer_location     VARCHAR2 (250),
      location_name        VARCHAR2 (240),
      tendertyp            VARCHAR2 (30),
      cccid                VARCHAR2 (80),
      tndacctnbr           VARCHAR2 (80),
      exp_date             DATE,
      avscode              VARCHAR2 (80),
      bill_to              VARCHAR2(150),
      ship_to              VARCHAR2(150),
      contact_id           NUMBER,
      contact_name         VARCHAR2 (150),
      contact_email        VARCHAR2 (150),
      contact_phone        VARCHAR2 (150),
      special_instructions VARCHAR2(2000),
      sales_person         VARCHAR2 (50),
      associate_id         NUMBER,
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


