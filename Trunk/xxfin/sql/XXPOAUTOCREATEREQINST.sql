-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | SQL Script to create the following objects                               |
-- |             Table       : XX_PO_REQUISITIONS_STG                         |
-- |             Sequence    : XX_PO_REQ_BATCH_STG_S                          |
-- |             Synonyms    : XX_PO_REQUISITIONS_STG, XX_PO_REQ_BATCH_STG_S  |
-- |                                                                          |
-- |                        for the Extension E0980, Auto Requisition Import  |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     21-MAR-2007  Gowri Shankar        Initial version               |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

DROP SYNONYM xx_po_req_batch_stg_s;

DROP SYNONYM xx_po_requisitions_stg;

DROP SEQUENCE xxfin.xx_po_req_batch_stg_s;

DROP TABLE xxfin.xx_po_requisitions_stg;

CREATE TABLE xxfin.xx_po_requisitions_stg
(
    file_name                       VARCHAR2(240)
    ,batch_id                       NUMBER
    ,req_id                         VARCHAR2(240)
    ,requisition_type               VARCHAR2(240)
    ,preparer_name                  VARCHAR2(240)
    ,interface_source_code          VARCHAR2(240)
    ,source_type_disp               VARCHAR2(240)
    ,deliver_to_requestor_name      VARCHAR2(240)
    ,destination_type_code          VARCHAR2(240)
    ,req_description                VARCHAR2(240)
    ,req_line_number                VARCHAR2(240)
    ,line_type                      VARCHAR2(240)
    ,item                           VARCHAR2(240)
    ,category                       VARCHAR2(240)
    ,item_description               VARCHAR2(240)
    ,unit_of_measure                VARCHAR2(240)
    ,quantity                       VARCHAR2(240)
    ,price                          VARCHAR2(240)
    ,need_by_date                   DATE
    ,buyer                          VARCHAR2(240)
    ,organization                   VARCHAR2(240)
    ,location                       VARCHAR2(240)
    ,supplier_name                  VARCHAR2(240)
    ,supplier_site                  VARCHAR2(240)
    ,req_line_number_dist           VARCHAR2(240)
    ,distribution_quantity          VARCHAR2(240)
    ,charge_account                 VARCHAR2(240)
    ,project                        VARCHAR2(240)
    ,task                           VARCHAR2(240)
    ,expenditure_type               VARCHAR2(240)
    ,expenditure_org                VARCHAR2(240)
    ,expenditure_item_date          DATE
    ,request_id                     NUMBER
    ,source_type_code               VARCHAR2(240)
    ,attribute1                     VARCHAR2(240)
    ,attribute2                     VARCHAR2(240)
    ,attribute3                     VARCHAR2(240)
    ,attribute4                     VARCHAR2(240)
    ,attribute5                     VARCHAR2(240)
    ,attribute6                     VARCHAR2(240)
    ,status                         VARCHAR2(20)
);

CREATE SEQUENCE xxfin.xx_po_req_batch_stg_s START WITH 1 INCREMENT BY 1;

CREATE SYNONYM xx_po_requisitions_stg FOR xxfin.xx_po_requisitions_stg;

CREATE SYNONYM xx_po_req_batch_stg_s FOR xxfin.xx_po_req_batch_stg_s;

SHOW ERROR