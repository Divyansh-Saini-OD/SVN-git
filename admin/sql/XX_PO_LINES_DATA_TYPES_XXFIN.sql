SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE

--+=============================================================================================+--
--|                        Office Depot - SCM Modernization                                     |--
--|                                                                                             |--
--+=============================================================================================+--
--+=============================================================================================+--
--|                                                                                             |--
--| Program Name   : XX_PO_SCM_DATA_INSERT                                                      |--
--|                                                                                             |--
--| Purpose        : Create Custom OBJECTS and TABLES                                           |--
--|                  The Objects created are:                                                   |--
--|                                                                                             |--
--|                                                                                             |--
--|                1. XX_PO_SCM_LINES_OBJ                                                       |--
--|                2. XX_PO_SCM_LINES_TAB                                                       |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              19-JUN-2018       Shalu George          Original                           |--
--|                                                                                             |--
--+=============================================================================================+--
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF 
WHENEVER SQLERROR CONTINUE;

PROMPT 
PROMPT Dropping TYPE XX_PO_SCM_LINES_OBJ
PROMPT Dropping TYPE XX_PO_SCM_LINES_TAB
PROMPT

DROP TYPE XX_PO_SCM_LINES_TAB;
DROP TYPE XX_PO_SCM_LINES_OBJ;


WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Creating RECORD TYPE XX_PO_SCM_HDR_OBJ
PROMPT

CREATE OR REPLACE TYPE  XX_PO_SCM_LINES_OBJ AS OBJECT (
    record_line_id         NUMBER,
    record_id              NUMBER,
    process_code           VARCHAR2(2 BYTE),
    po_number              VARCHAR2(30 BYTE),
    line_num               NUMBER,
    item                   NUMBER,
    quantity               NUMBER,
    ship_to_location       NUMBER,
    need_by_date           DATE,
    promised_date          DATE,
    line_reference_num     NUMBER,
    uom_code               VARCHAR2(30 BYTE),
    unit_price             NUMBER,
    shipmentnumber         NUMBER,
    dept                   NUMBER,
    class                  NUMBER,
    vendor_product_code    VARCHAR2(30 BYTE),
    extended_cost          NUMBER,
    qty_shipped            NUMBER,
    qty_received           NUMBER,
    seasonal_large_order   VARCHAR2(30 BYTE),
    batch_id               NUMBER,
    record_status          VARCHAR2(30 BYTE),
    error_description      VARCHAR2(2000 BYTE),
    request_id             NUMBER,
    attribute1             VARCHAR2(150 BYTE),
    attribute2             VARCHAR2(150 BYTE),
    attribute3             VARCHAR2(150 BYTE),
    attribute4             VARCHAR2(150 BYTE),
    attribute5             VARCHAR2(150 BYTE),
    attribute_category     VARCHAR2(150 BYTE),
    created_by             NUMBER,
    creation_date          DATE,
    last_updated_by        NUMBER,
    last_update_date       DATE,
    last_update_login      NUMBER,
    error_column           VARCHAR2(100 BYTE),
    error_value            VARCHAR2(200 BYTE),
	item_description       VARCHAR2(240 BYTE)								--Added for Elynxx
)
/
WHENEVER SQLERROR CONTINUE;
PROMPT
PROMPT Creating TABLE TYPE XX_PO_SCM_LINES_TAB
PROMPT

CREATE OR REPLACE TYPE XX_PO_SCM_LINES_TAB IS TABLE OF XX_PO_SCM_LINES_OBJ;

/
WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Providing Grant on all objects XX_PO_SCM_LINES to Apps
PROMPT

GRANT ALL ON XX_PO_SCM_LINES_OBJ TO APPS;
GRANT ALL ON XX_PO_SCM_LINES_TAB TO APPS;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT
SET FEEDBACK ON
EXIT;