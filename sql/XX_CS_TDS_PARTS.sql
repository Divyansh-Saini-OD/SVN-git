CREATE TABLE "XXOM"."XX_CS_TDS_PARTS"
  (
    "REQUEST_NUMBER"   VARCHAR2(25 BYTE),
    "STORE_ID"         NUMBER,
    "LINE_NUMBER"      NUMBER,
    "ITEM_NUMBER"      VARCHAR2(25 BYTE),
    "ITEM_DESCRIPTION" VARCHAR2(250 BYTE),
    "RMS_SKU"          VARCHAR2(25 BYTE),
    "QUANTITY"         NUMBER,
    "ITEM_CATEGORY"    VARCHAR2(150 BYTE),
    "PURCHASE_PRICE"   NUMBER,
    "SELLING_PRICE"    NUMBER,
    "EXCHANGE_PRICE"   NUMBER,
    "CORE_FLAG"        VARCHAR2(1 BYTE),
    "UOM"              VARCHAR2(15 BYTE),
    "SCHEDULE_DATE" DATE,
    "CREATION_DATE" DATE,
    "CREATED_BY" VARCHAR2(25 BYTE),
    "LAST_UDATE_DATE" DATE,
    "LAST_UPDATED_BY" VARCHAR2(25 BYTE),
    "ATTRIBUTE1"      VARCHAR2(250 BYTE),
    "ATTRIBUTE2"      VARCHAR2(250 BYTE),
    "ATTRIBUTE3"      VARCHAR2(250 BYTE),
    "ATTRIBUTE4"      VARCHAR2(250 BYTE),
    "ATTRIBUTE5"      VARCHAR2(250 BYTE),
    "SALES_FLAG"      VARCHAR2(1 BYTE),
    "MANUFACTURER"    VARCHAR2(50 BYTE),
    "MODEL"           VARCHAR2(25 BYTE),
    "SERIAL_NUMBER"   VARCHAR2(50 BYTE),
    "PROBLEM_DESCR"   VARCHAR2(250 BYTE),
    "SPECIAL_INSTR"   VARCHAR2(1000 BYTE)
  );
/