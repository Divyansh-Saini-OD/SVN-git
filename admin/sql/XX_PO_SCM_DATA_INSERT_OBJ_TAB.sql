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
--|                1. XX_PO_SCM_HDR_OBJ                                                         |--
--|                2. XX_PO_SCM_HDR_TAB                                                         |--
--|                3. XX_PO_SCM_LINES_OBJ                                                       |--
--|                4. XX_PO_SCM_LINES_TAB                                                       |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              19-JUN-2018       Phuoc Nguyen            Original                         |--
--| 2.0              10-SEP-2020       Shalu George       Adding column item_description        |--
--+=============================================================================================+--
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF 
WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Dropping TYPE XX_PO_SCM_HDR_OBJ  
PROMPT Dropping TYPE XX_PO_SCM_HDR_TAB  
PROMPT Dropping TYPE XX_PO_SCM_LINES_OBJ
PROMPT Dropping TYPE XX_PO_SCM_LINES_TAB
PROMPT

DROP TYPE XX_PO_SCM_HDR_OBJ;
DROP TYPE XX_PO_SCM_HDR_TAB;
DROP TYPE XX_PO_SCM_LINES_OBJ;
DROP TYPE XX_PO_SCM_LINES_TAB;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Creating RECORD TYPE XX_PO_SCM_HDR_OBJ
PROMPT

CREATE OR REPLACE TYPE XX_PO_SCM_HDR_OBJ AS OBJECT (
    record_id            NUMBER,
    process_code         VARCHAR2(2 BYTE),
    po_number            VARCHAR2(30 BYTE),
    currency_code        VARCHAR2(15 BYTE),
    vendor_site_code     VARCHAR2(25 BYTE),
    loc_id               NUMBER,
    fob_code             VARCHAR2(25 BYTE),
    freight_code         VARCHAR2(25 BYTE),
    note_to_vendor       VARCHAR2(480 BYTE),
    note_to_receiver     VARCHAR2(480 BYTE),
    status_code          VARCHAR2(25 BYTE),
    import_manual_po     VARCHAR2(250 BYTE),
    date_entered         DATE,
    date_changed         DATE,
    rate_type            VARCHAR2(30 BYTE),
    distribution_code    VARCHAR2(30 BYTE),
    po_type              VARCHAR2(30 BYTE),
    num_lines            NUMBER,
    cost                 NUMBER,
    units_ord_rec_shpd   NUMBER,
    lbs                  NUMBER,
    net_po_total_cost    NUMBER,
    drop_ship_flag       VARCHAR2(30 BYTE),
    ship_via             VARCHAR2(200 BYTE),
    back_orders          VARCHAR2(10 BYTE),
    order_dt             DATE,
    ship_dt              DATE,
    arrival_dt           DATE,
    cancel_dt            DATE,
    release_date         DATE,
    revision_flag        VARCHAR2(30 BYTE),
    last_ship_dt         DATE,
    last_receipt_dt      DATE,
    disc_pct             NUMBER,
    disc_days            NUMBER,
    net_days             NUMBER,
    allowance_basis      VARCHAR2(10 BYTE),
    allowance_dollars    NUMBER,
    allowance_percent    NUMBER,
    pom_created_by       VARCHAR2(100 BYTE),
    time_entered         VARCHAR2(50 BYTE),
    program_entered_by   VARCHAR2(100 BYTE),
    pom_changed_by       VARCHAR2(100 BYTE),
    changed_time         VARCHAR2(50 BYTE),
    program_changed_by   VARCHAR2(100 BYTE),
    cust_id              NUMBER,
    cust_order_nbr       NUMBER,
    vendor_doc_num       VARCHAR2(30 BYTE),
    cust_order_sub_nbr   VARCHAR2(30 BYTE),
    batch_id             NUMBER,
    record_status        VARCHAR2(30 BYTE),
    error_description    VARCHAR2(2000 BYTE),
    request_id           NUMBER,
    attribute1           VARCHAR2(150 BYTE),
    attribute2           VARCHAR2(150 BYTE),
    attribute3           VARCHAR2(150 BYTE),
    attribute4           VARCHAR2(150 BYTE),
    attribute5           VARCHAR2(150 BYTE),
    attribute_category   VARCHAR2(150 BYTE),
    created_by           NUMBER,
    creation_date        DATE,
    last_updated_by      NUMBER,
    last_update_date     DATE,
    last_update_login    NUMBER,
    error_column         VARCHAR2(100 BYTE),
    error_value          VARCHAR2(200 BYTE))
/
WHENEVER SQLERROR CONTINUE;
PROMPT
PROMPT Creating TABLE TYPE XX_PO_SCM_HDR_TAB
PROMPT

CREATE OR REPLACE TYPE XX_PO_SCM_HDR_TAB IS TABLE OF XX_PO_SCM_HDR_OBJ;
/
WHENEVER SQLERROR CONTINUE;
PROMPT
PROMPT Creating RECORD TYPE XX_PO_SCM_LINES_OBJ
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
PROMPT Providing Grant on all objects for XX_PO_SCM_HDR to Apps
PROMPT

GRANT ALL ON XX_PO_SCM_HDR_OBJ TO APPS;
GRANT ALL ON XX_PO_SCM_HDR_TAB TO APPS;
--GRANT SELECT ON XX_OE_ORDER_HEADERS_SCM TO ERP_SYSTEM_TABLE_SELECT_ROLE;

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