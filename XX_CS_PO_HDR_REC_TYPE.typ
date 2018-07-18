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
-- | Name  :    XX_CS_PO_HDR_REC
-- |
-- | Description  : This script creates object type for PO rec type    |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author               Remarks                 |
-- |=======   ==========  =============        ======================= |
-- |1.0       24-SEP-13   Arun Gannarapu   Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+



SET TERM ON
PROMPT Creating Record type XX_CS_PO_HDR_REC
SET TERM OFF

create or replace
TYPE XX_CS_PO_HDR_REC IS OBJECT (
      Request_number       VARCHAR2 (25),
      party_id             NUMBER,
      order_type           VARCHAR2 (25),
      currency_code        VARCHAR2(15),
      cost_center          VARCHAR2(25),
      org_id               NUMBER,
      status_code          VARCHAR2(1),
      order_source_code    VARCHAR2(25),
      order_category       VARCHAR2(25),
      bill_to              VARCHAR2(150),
      ship_to              VARCHAR2(150),
      Comments             VARCHAR2(2000),
      attribute1           VARCHAR2 (150),
      attribute2           VARCHAR2 (150),
      attribute3           VARCHAR2 (150),
      attribute4           VARCHAR2 (150),
      attribute5           VARCHAR2 (150)
   );
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

