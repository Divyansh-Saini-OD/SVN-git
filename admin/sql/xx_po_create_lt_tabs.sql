-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name         : xx_po_create_lt_tabs.sql                           |
-- | Rice Id      : E1042-Lead Time-Order Cycle                        |
-- | Description  : Create tables for lead time and order cycle        |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0                   Antonio Morales  Initial version             |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

CREATE TABLE XXMER.XX_PO_LEAD_TIME_ORDER_CYCLE
(
  SOURCE_ID             NUMBER(10)              NOT NULL,
  SOURCE_TYPE           VARCHAR2(2 BYTE)        NOT NULL,
  DESTINATION_ID        NUMBER(10)              NOT NULL,
  DESTINATION_TYPE      VARCHAR2(2 BYTE)        NOT NULL,
  ITEM_ID               NUMBER(10),
  OVERALL_LT            NUMBER(10),
  SHIP_LT               NUMBER(10),
  RECEIPT_LT            NUMBER(10),
  ORDER_CYCLE_DAYS      VARCHAR2(60 BYTE),
  ORDERCYCLE_FREQUENCY  NUMBER(2),
  LAST_UPDATE_DATE      DATE                    NOT NULL,
  LAST_UPDATED_BY       NUMBER                  NOT NULL,
  CREATION_DATE         DATE                    NOT NULL,
  CREATED_BY            NUMBER                  NOT NULL,
  LAST_UPDATE_LOGIN     NUMBER
)
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

CREATE SYNONYM XX_PO_LEAD_TIME_ORDER_CYCLE FOR XXMER.XX_PO_LEAD_TIME_ORDER_CYCLE;

COMMENT ON COLUMN XXMER.XX_PO_LEAD_TIME_ORDER_CYCLE.SOURCE_TYPE IS 'V=Vendor, S=Store, W=Warehouse';

COMMENT ON COLUMN XXMER.XX_PO_LEAD_TIME_ORDER_CYCLE.DESTINATION_TYPE IS 'S=Store, W=Warehouse';


CREATE UNIQUE INDEX XXMER.LEAD_TIME_ORDER_CYCLE_PK ON XXMER.XX_PO_LEAD_TIME_ORDER_CYCLE
(SOURCE_ID, SOURCE_TYPE, DESTINATION_ID, DESTINATION_TYPE, ITEM_ID)
LOGGING
NOPARALLEL;

ALTER TABLE XXMER.XX_PO_LEAD_TIME_ORDER_CYCLE ADD (
  CHECK (destination_type in ('S','W')),
  CHECK (source_type in ('V','S','W')),
  CONSTRAINT LEAD_TIME_ORDER_CYCLE_PK
 PRIMARY KEY
 (SOURCE_ID, SOURCE_TYPE, DESTINATION_ID, DESTINATION_TYPE, ITEM_ID));


CREATE TABLE XXMER.XX_PO_LEAD_TIME_ORDER_CYC_STG
(
  SOURCE_ID             NUMBER(10)              NOT NULL,
  SOURCE_TYPE           VARCHAR2(2 BYTE),
  DESTINATION_ID        NUMBER(10)              NOT NULL,
  DESTINATION_TYPE      VARCHAR2(2 BYTE),
  ITEM_ID               NUMBER(10),
  OVERALL_LT            NUMBER(10),
  SHIP_LT               NUMBER(10),
  RECEIPT_LT            NUMBER(10),
  ORDER_CYCLE_DAYS      VARCHAR2(60 BYTE),
  ORDERCYCLE_FREQUENCY  NUMBER(2),
  ORIGIN                VARCHAR2(3 BYTE)
)
NOLOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

CREATE SYNONYM XX_PO_LEAD_TIME_ORDER_CYC_STG FOR XXMER.XX_PO_LEAD_TIME_ORDER_CYC_STG;

