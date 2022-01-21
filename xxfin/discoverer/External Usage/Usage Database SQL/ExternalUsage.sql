CREATE TABLE DW_PROGRAM_LOG
(
  LOG_ID           NUMBER,
  LOG_DATE         DATE,
  LOG_MESSAGE      VARCHAR2(1000 BYTE),
  LOG_TYPE         VARCHAR2(100 BYTE),
  PROGRAM_NAME     VARCHAR2(100 BYTE),
  SUBPROGRAM_NAME  VARCHAR2(100 BYTE),
  PARAM1           VARCHAR2(30 BYTE),
  VALUE1           VARCHAR2(30 BYTE),
  PARAM2           VARCHAR2(30 BYTE),
  VALUE2           VARCHAR2(30 BYTE),
  PARAM3           VARCHAR2(30 BYTE),
  VALUE3           VARCHAR2(30 BYTE),
  PARAM4           VARCHAR2(30 BYTE),
  VALUE4           VARCHAR2(30 BYTE),
  PARAM5           VARCHAR2(30 BYTE),
  VALUE5           VARCHAR2(30 BYTE),
  PARAM6           VARCHAR2(30 BYTE),
  VALUE6           VARCHAR2(30 BYTE),
  PARAM7           VARCHAR2(30 BYTE),
  VALUE7           VARCHAR2(30 BYTE),
  PARAM8           VARCHAR2(30 BYTE),
  VALUE8           VARCHAR2(30 BYTE),
  PARAM9           VARCHAR2(30 BYTE),
  VALUE9           VARCHAR2(30 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;




CREATE TABLE OD_EXT_USAGE_ERR
(
  USAGE_SEQ_ID               VARCHAR2(750 BYTE),
  ORDER_HEADER_ID            VARCHAR2(750 BYTE),
  ORDER_ID                   VARCHAR2(750 BYTE),
  ORDER_LINE_NUMBER          VARCHAR2(750 BYTE),
  FULLFILLMENT_ID            VARCHAR2(750 BYTE),
  ORDER_LINE_ID              VARCHAR2(750 BYTE),
  CUSTOMER_ID                VARCHAR2(750 BYTE),
  ACCOUNT_NUMBER             VARCHAR2(750 BYTE),
  BILL_NUMBER                VARCHAR2(750 BYTE),
  CUSTOMER_NAME              VARCHAR2(750 BYTE),
  CUSTOMER_DEPT              VARCHAR2(750 BYTE),
  CUSTOMER_DEPT_DESC         VARCHAR2(750 BYTE),
  PARENT_NAME                VARCHAR2(750 BYTE),
  PARENT_ID                  VARCHAR2(750 BYTE),
  PRODUCT_CODE               VARCHAR2(750 BYTE),
  RETAIL_PRICE               VARCHAR2(750 BYTE),
  PRODUCT_DESC               VARCHAR2(750 BYTE),
  WHOLESALE_PRODUCT_CODE     VARCHAR2(750 BYTE),
  CUSTOMER_PRODUCT_CODE      VARCHAR2(750 BYTE),
  EDI_SELL_CODE              VARCHAR2(750 BYTE),
  QUANTITY_SHIPPED           VARCHAR2(750 BYTE),
  QUANTITY                   VARCHAR2(750 BYTE),
  CUSTOMER_CURRENCY          VARCHAR2(750 BYTE),
  EXTENDED_PRICE             VARCHAR2(750 BYTE),
  RECONCILED_DATE            VARCHAR2(750 BYTE),
  SHIP_TO_CONTACT_NAME       VARCHAR2(750 BYTE),
  SHIP_TO_CUSTOMER_ID        VARCHAR2(750 BYTE),
  SHIP_TO_CUSTOMER_NAME      VARCHAR2(750 BYTE),
  SHIP_TO_ADDRESS_LINE1      VARCHAR2(750 BYTE),
  SHIP_TO_ADDRESS_LINE2      VARCHAR2(750 BYTE),
  SHIP_TO_CITY               VARCHAR2(750 BYTE),
  SHIP_TO_STATE              VARCHAR2(750 BYTE),
  SHIP_TO_ZIP                VARCHAR2(750 BYTE),
  COUNTRY_CODE               VARCHAR2(750 BYTE),
  BILL_TO_CUSTOMER_ID        VARCHAR2(750 BYTE),
  BILL_TO_CUSTOMER_NAME      VARCHAR2(750 BYTE),
  BILL_TO_ADDRESS_LINE1      VARCHAR2(750 BYTE),
  BILL_TO_ADDRESS_LINE2      VARCHAR2(750 BYTE),
  BILL_TO_CITY               VARCHAR2(750 BYTE),
  BILL_TO_STATE              VARCHAR2(750 BYTE),
  BILL_TO_ZIP                VARCHAR2(750 BYTE),
  ORDER_CREATE_DATE          VARCHAR2(750 BYTE),
  DELIVERY_DATE              VARCHAR2(750 BYTE),
  ORDER_COMPLETED_DATE       VARCHAR2(750 BYTE),
  UNIT_OF_MEASURE            VARCHAR2(750 BYTE),
  CUST_PO_NUMBER             VARCHAR2(750 BYTE),
  ITEM_DEPT_NUM              VARCHAR2(750 BYTE),
  ITEM_DEPT_DESC             VARCHAR2(750 BYTE),
  ORDER_NUMBER               VARCHAR2(750 BYTE),
  SUB_ORDER                  VARCHAR2(750 BYTE),
  ORDER_NUMBER_FULLFILLMENT  VARCHAR2(750 BYTE),
  SHIP_TO_ID                 VARCHAR2(750 BYTE),
  SHIP_TO_KEY                VARCHAR2(750 BYTE),
  OD_SKU                     VARCHAR2(750 BYTE),
  SOURCE_SYSTEM_NAME         VARCHAR2(750 BYTE),
  SQL_CODE                   VARCHAR2(750 BYTE),
  SQL_ERR_MSG                VARCHAR2(2000 BYTE),
  CUST_RELEASE_NUMBER        VARCHAR2(60 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


GRANT SELECT ON  OD_EXT_USAGE_ERR TO EUL01_SELECT;



CREATE TABLE OD_EXT_USAGE_RPT
(
  ORDER_HEADER_ID            NUMBER,
  ORDER_ID                   NUMBER,
  ORDER_LINE_NUMBER          NUMBER,
  FULLFILLMENT_ID            NUMBER,
  ORDER_LINE_ID              NUMBER,
  CUSTOMER_ID                VARCHAR2(75 BYTE),
  ACCOUNT_NUMBER             VARCHAR2(150 BYTE),
  BILL_NUMBER                NUMBER,
  CUSTOMER_NAME              VARCHAR2(368 BYTE),
  CUSTOMER_DEPT              VARCHAR2(260 BYTE),
  CUSTOMER_DEPT_DESC         VARCHAR2(260 BYTE),
  PARENT_NAME                VARCHAR2(50 BYTE),
  PARENT_ID                  NUMBER,
  PRODUCT_CODE               VARCHAR2(75 BYTE),
  RETAIL_PRICE               NUMBER,
  PRODUCT_DESC               VARCHAR2(240 BYTE),
  WHOLESALE_PRODUCT_CODE     VARCHAR2(60 BYTE),
  CUSTOMER_PRODUCT_CODE      VARCHAR2(60 BYTE),
  EDI_SELL_CODE              VARCHAR2(10 BYTE),
  QUANTITY_SHIPPED           NUMBER,
  QUANTITY                   NUMBER,
  CUSTOMER_CURRENCY          VARCHAR2(3 BYTE),
  EXTENDED_PRICE             NUMBER,
  RECONCILED_DATE            DATE,
  SHIP_TO_CONTACT_NAME       VARCHAR2(360 BYTE),
  SHIP_TO_CUSTOMER_ID        VARCHAR2(30 BYTE),
  SHIP_TO_CUSTOMER_NAME      VARCHAR2(360 BYTE),
  SHIP_TO_ADDRESS_LINE1      VARCHAR2(30 BYTE),
  SHIP_TO_ADDRESS_LINE2      VARCHAR2(30 BYTE),
  SHIP_TO_CITY               VARCHAR2(30 BYTE),
  SHIP_TO_STATE              VARCHAR2(2 BYTE),
  SHIP_TO_ZIP                VARCHAR2(11 BYTE),
  COUNTRY_CODE               VARCHAR2(10 BYTE),
  BILL_TO_CUSTOMER_ID        VARCHAR2(30 BYTE),
  BILL_TO_CUSTOMER_NAME      VARCHAR2(360 BYTE),
  BILL_TO_ADDRESS_LINE1      VARCHAR2(30 BYTE),
  BILL_TO_ADDRESS_LINE2      VARCHAR2(30 BYTE),
  BILL_TO_CITY               VARCHAR2(30 BYTE),
  BILL_TO_STATE              VARCHAR2(2 BYTE),
  BILL_TO_ZIP                VARCHAR2(11 BYTE),
  ORDER_CREATE_DATE          DATE,
  DELIVERY_DATE              DATE,
  ORDER_COMPLETED_DATE       DATE,
  UNIT_OF_MEASURE            VARCHAR2(20 BYTE),
  CUST_PO_NUMBER             VARCHAR2(30 BYTE),
  ITEM_DEPT_NUM              VARCHAR2(30 BYTE),
  ITEM_DEPT_DESC             VARCHAR2(250 BYTE),
  ORDER_NUMBER               NUMBER,
  SUB_ORDER                  NUMBER,
  ORDER_NUMBER_FULLFILLMENT  VARCHAR2(60 BYTE),
  SOURCE_SYSTEM_NAME         VARCHAR2(3 BYTE),
  SHIP_TO_ID                 VARCHAR2(50 BYTE),
  SHIP_TO_KEY                VARCHAR2(200 BYTE),
  OD_SKU                     VARCHAR2(10 BYTE),
  CUST_RELEASE_NUMBER        VARCHAR2(60 BYTE),
  DESKTOP_LOCATOR            VARCHAR2(50 BYTE),
  CUST_RELEASE_NUMBER_DESC   VARCHAR2(150 BYTE),
  DESKTOP_LOCATOR_DESC       VARCHAR2(150 BYTE),
  CUST_PO_NUMBER_DESC        VARCHAR2(150 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
ENABLE ROW MOVEMENT;


CREATE UNIQUE INDEX PK_EXT_USAGE ON OD_EXT_USAGE_RPT
(ORDER_ID, ORDER_LINE_NUMBER, FULLFILLMENT_ID)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE INDEX CUSTOMER_ID ON OD_EXT_USAGE_RPT
(CUSTOMER_ID, ORDER_ID)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE INDEX BILLTOCUSTOMERID ON OD_EXT_USAGE_RPT
(BILL_TO_CUSTOMER_ID)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE INDEX RECONCILED_DATE ON OD_EXT_USAGE_RPT
(RECONCILED_DATE)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE INDEX USG_BILL_TO_CUST_ID_REC_DT ON OD_EXT_USAGE_RPT
(BILL_TO_CUSTOMER_ID, RECONCILED_DATE)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


ALTER TABLE OD_EXT_USAGE_RPT ADD (
  CONSTRAINT PK_EXT_USAGE
 PRIMARY KEY
 (ORDER_ID, ORDER_LINE_NUMBER, FULLFILLMENT_ID)
    USING INDEX 
    TABLESPACE DISCOVERER
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ));


GRANT SELECT ON  OD_EXT_USAGE_RPT TO EUL01_SELECT;



CREATE TABLE OD_EXT_USAGE_UPDATES
(
  ORDER_HEADER_ID            NUMBER,
  ORDER_ID                   NUMBER,
  ORDER_LINE_NUMBER          NUMBER,
  FULLFILLMENT_ID            NUMBER,
  ORDER_LINE_ID              NUMBER,
  CUSTOMER_ID                VARCHAR2(75 BYTE),
  ACCOUNT_NUMBER             VARCHAR2(150 BYTE),
  BILL_NUMBER                NUMBER,
  CUSTOMER_NAME              VARCHAR2(368 BYTE),
  CUSTOMER_DEPT              VARCHAR2(260 BYTE),
  CUSTOMER_DEPT_DESC         VARCHAR2(260 BYTE),
  PARENT_NAME                VARCHAR2(50 BYTE),
  PARENT_ID                  NUMBER,
  PRODUCT_CODE               VARCHAR2(75 BYTE),
  RETAIL_PRICE               NUMBER,
  PRODUCT_DESC               VARCHAR2(240 BYTE),
  WHOLESALE_PRODUCT_CODE     VARCHAR2(60 BYTE),
  CUSTOMER_PRODUCT_CODE      VARCHAR2(60 BYTE),
  EDI_SELL_CODE              VARCHAR2(10 BYTE),
  QUANTITY_SHIPPED           NUMBER,
  QUANTITY                   NUMBER,
  CUSTOMER_CURRENCY          VARCHAR2(3 BYTE),
  EXTENDED_PRICE             NUMBER,
  RECONCILED_DATE            DATE,
  SHIP_TO_CONTACT_NAME       VARCHAR2(360 BYTE),
  SHIP_TO_CUSTOMER_ID        VARCHAR2(30 BYTE),
  SHIP_TO_CUSTOMER_NAME      VARCHAR2(360 BYTE),
  SHIP_TO_ADDRESS_LINE1      VARCHAR2(30 BYTE),
  SHIP_TO_ADDRESS_LINE2      VARCHAR2(30 BYTE),
  SHIP_TO_CITY               VARCHAR2(30 BYTE),
  SHIP_TO_STATE              VARCHAR2(2 BYTE),
  SHIP_TO_ZIP                VARCHAR2(11 BYTE),
  COUNTRY_CODE               VARCHAR2(10 BYTE),
  BILL_TO_CUSTOMER_ID        VARCHAR2(30 BYTE),
  BILL_TO_CUSTOMER_NAME      VARCHAR2(360 BYTE),
  BILL_TO_ADDRESS_LINE1      VARCHAR2(30 BYTE),
  BILL_TO_ADDRESS_LINE2      VARCHAR2(30 BYTE),
  BILL_TO_CITY               VARCHAR2(30 BYTE),
  BILL_TO_STATE              VARCHAR2(2 BYTE),
  BILL_TO_ZIP                VARCHAR2(11 BYTE),
  ORDER_CREATE_DATE          DATE,
  DELIVERY_DATE              DATE,
  ORDER_COMPLETED_DATE       DATE,
  UNIT_OF_MEASURE            VARCHAR2(20 BYTE),
  CUST_PO_NUMBER             VARCHAR2(30 BYTE),
  ITEM_DEPT_NUM              VARCHAR2(30 BYTE),
  ITEM_DEPT_DESC             VARCHAR2(250 BYTE),
  ORDER_NUMBER               NUMBER,
  SUB_ORDER                  NUMBER,
  ORDER_NUMBER_FULLFILLMENT  VARCHAR2(60 BYTE),
  SOURCE_SYSTEM_NAME         VARCHAR2(3 BYTE),
  SHIP_TO_ID                 VARCHAR2(50 BYTE),
  SHIP_TO_KEY                VARCHAR2(200 BYTE),
  OD_SKU                     VARCHAR2(10 BYTE),
  CUST_RELEASE_NUMBER        VARCHAR2(12 BYTE),
  DESKTOP_LOCATOR            VARCHAR2(50 BYTE),
  CUST_RELEASE_NUMBER_DESC   VARCHAR2(150 BYTE),
  DESKTOP_LOCATOR_DESC       VARCHAR2(150 BYTE),
  CUST_PO_NUMBER_DESC        VARCHAR2(150 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;




CREATE TABLE OD_USAGE_STATS
(
  PROGRAM_NAME  VARCHAR2(30 BYTE),
  RUN_DATE      DATE,
  SYS_MESSAGE   VARCHAR2(350 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;




CREATE TABLE USAGE_LABELS
(
  CUSTOMER_ID             NUMBER,
  CUST_PO_NBR_LABEL       VARCHAR2(150 BYTE),
  CUST_RELEASE_NBR_LABEL  VARCHAR2(150 BYTE),
  DESKTOP_LOC_LABEL       VARCHAR2(150 BYTE),
  CUST_DEPT_LABEL         VARCHAR2(150 BYTE),
  CREATION_DATE           DATE,
  UPDATE_DATE             DATE,
  SOURCE_SYSTEM           VARCHAR2(3 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE UNIQUE INDEX USAGE_LABEL_KEY ON USAGE_LABELS
(CUSTOMER_ID)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


ALTER TABLE USAGE_LABELS ADD (
  CONSTRAINT USAGE_LABEL_KEY
 PRIMARY KEY
 (CUSTOMER_ID)
    USING INDEX 
    TABLESPACE DISCOVERER
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ));


GRANT SELECT ON  USAGE_LABELS TO EUL01_SELECT;



CREATE TABLE USAGE_LABELS_STAGE
(
  CUSTOMER_ID             NUMBER,
  CUST_PO_NBR_LABEL       VARCHAR2(150 BYTE),
  CUST_RELEASE_NBR_LABEL  VARCHAR2(150 BYTE),
  DESKTOP_LOC_LABEL       VARCHAR2(150 BYTE),
  CUST_DEPT_LABEL         VARCHAR2(150 BYTE),
  CREATION_DATE           DATE,
  UPDATE_DATE             DATE,
  SOURCE_SYSTEM           VARCHAR2(3 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


GRANT SELECT ON  USAGE_LABELS_STAGE TO EUL01_SELECT;



CREATE TABLE USAGE_LOV
(
  ACCOUNT_NUMBER   VARCHAR2(150 BYTE)           NOT NULL,
  LOV_TYPE         VARCHAR2(10 BYTE)            NOT NULL,
  LOV_DESCRIPTION  VARCHAR2(60 BYTE),
  SHORT_NAME       VARCHAR2(50 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE INDEX USAGE_LOV_IDX1 ON USAGE_LOV
(ACCOUNT_NUMBER)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE INDEX INDEX_USAGE_LOC_CUST_TYPE ON USAGE_LOV
(ACCOUNT_NUMBER, LOV_TYPE)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;




CREATE TABLE USAGE_PROFILE_DETAIL
(
  TYPE                     VARCHAR2(2 BYTE)     NOT NULL,
  VALUE                    VARCHAR2(4000 BYTE)  NOT NULL,
  USAGE_PROFILE_HEADER_ID  INTEGER              NOT NULL,
  USAGE_PROFILE_DETAIL_ID  INTEGER              NOT NULL
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE UNIQUE INDEX USAGE_PROFILE_DETAIL_PK ON USAGE_PROFILE_DETAIL
(USAGE_PROFILE_DETAIL_ID)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


ALTER TABLE USAGE_PROFILE_DETAIL ADD (
  CONSTRAINT USAGE_PROFILE_DETAIL_PK
 PRIMARY KEY
 (USAGE_PROFILE_DETAIL_ID)
    USING INDEX 
    TABLESPACE DISCOVERER
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ));


ALTER TABLE USAGE_PROFILE_DETAIL ADD (
  CONSTRAINT USAGE_PROFILE_DETAIL_USAG_FK1 
 FOREIGN KEY (USAGE_PROFILE_HEADER_ID) 
 REFERENCES USAGE_PROFILE_HEADER (USAGE_PROFILE_HEADER_ID)
    ON DELETE CASCADE);


GRANT SELECT ON  USAGE_PROFILE_DETAIL TO EUL01_SELECT;



CREATE TABLE USAGE_PROFILE_HEADER
(
  LOGINID                  VARCHAR2(4000 BYTE)  NOT NULL,
  EMAIL                    VARCHAR2(164 BYTE),
  FIRST_NAME               VARCHAR2(50 BYTE),
  LAST_NAME                VARCHAR2(100 BYTE),
  DOMAINID                 VARCHAR2(50 BYTE),
  BILLTO                   VARCHAR2(50 BYTE),
  USERTYPE                 VARCHAR2(5 BYTE),
  USERPERM                 VARCHAR2(5 BYTE),
  USAGE_PROFILE_HEADER_ID  NUMBER               NOT NULL
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE UNIQUE INDEX USAGE_PROFILE_HEADER_PK ON USAGE_PROFILE_HEADER
(USAGE_PROFILE_HEADER_ID)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE UNIQUE INDEX USAGE_PROFILE_HEADER_INDEX1 ON USAGE_PROFILE_HEADER
(LOGINID)
LOGGING
TABLESPACE DISCOVERER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


ALTER TABLE USAGE_PROFILE_HEADER ADD (
  CONSTRAINT USAGE_PROFILE_HEADER_PK
 PRIMARY KEY
 (USAGE_PROFILE_HEADER_ID)
    USING INDEX 
    TABLESPACE DISCOVERER
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ));


GRANT SELECT ON  USAGE_PROFILE_HEADER TO EUL01_SELECT;



CREATE TABLE USAGE_STAGE
(
  CUSTOMER_NAME                   VARCHAR2(30 BYTE),
  PARENT_NAME                     VARCHAR2(30 BYTE),
  CUSTOMER_SHIP_TO_CONTACT_NAME   VARCHAR2(60 BYTE),
  CUSTOMER_SHIP_TO_ID             VARCHAR2(30 BYTE),
  CUST_ADDR_LINE_1                VARCHAR2(30 BYTE),
  CUST_ADDR_LINE_2                VARCHAR2(30 BYTE),
  CUST_CITY                       VARCHAR2(25 BYTE),
  CUST_STATE                      VARCHAR2(2 BYTE),
  CUST_COUNTRY_CD                 VARCHAR2(3 BYTE),
  CUST_DEPT_KEY                   VARCHAR2(20 BYTE),
  SHIP_TO_CUSTOMER_NAME           VARCHAR2(30 BYTE),
  CUST_PRODUCT_CD                 VARCHAR2(20 BYTE),
  SHIP_TO_ZIP                     VARCHAR2(11 BYTE),
  CUSTOMER_CURRENCY               VARCHAR2(5 BYTE),
  CUSTOMER_DEPT_DESC              VARCHAR2(250 BYTE),
  ACCOUNT_NUMBER_AOPS             VARCHAR2(30 BYTE),
  PARENT_ID                       VARCHAR2(15 BYTE),
  ITEM_DEPT_DESC                  VARCHAR2(30 BYTE),
  PRODUCT_DESC_SKU                VARCHAR2(250 BYTE),
  EDI_SELL_CODE                   VARCHAR2(30 BYTE),
  ORDER_COMPLETED_DATE            VARCHAR2(30 BYTE),
  ORDER_LINE_NUMBER               VARCHAR2(30 BYTE),
  CUSTOMER_PO_NUMBER              VARCHAR2(30 BYTE),
  ORDER_NUMBER                    VARCHAR2(30 BYTE),
  SUB_ORDER                       VARCHAR2(10 BYTE),
  ORDER_CREATE_DATE               VARCHAR2(30 BYTE),
  DELIVERY_DATE                   VARCHAR2(30 BYTE),
  PRODUCT_CODE_SKU                VARCHAR2(20 BYTE),
  RECONCILED_DATE                 VARCHAR2(30 BYTE),
  WHOLESALE_PRODUCT_CD            VARCHAR2(20 BYTE),
  EXTENDED_PRICE                  VARCHAR2(20 BYTE),
  SKU_RETAIL_PRICE                VARCHAR2(20 BYTE),
  QUANTITY_ORDERED                VARCHAR2(10 BYTE),
  QUANTITY_SHIPPED                VARCHAR2(10 BYTE),
  CUSTOMER_ID                     VARCHAR2(20 BYTE),
  BILL_TO_SEQUENCE_NBR_AOPS       VARCHAR2(10 BYTE),
  CUSTOMER_BILL_TO_BUSINESS_NAME  VARCHAR2(30 BYTE),
  BILL_TO_ADDRESS_LINE_1          VARCHAR2(30 BYTE),
  BILL_TO_ADDRESS_LINE_2          VARCHAR2(30 BYTE),
  BILL_TO_CITY                    VARCHAR2(30 BYTE),
  BILL_TO_STATE                   VARCHAR2(2 BYTE),
  BILL_TO_ZIP                     VARCHAR2(11 BYTE),
  ORDER_ID                        VARCHAR2(30 BYTE),
  FULLFILLMENT_ID                 VARCHAR2(18 BYTE),
  AOPS_SEQUENCE_ID                VARCHAR2(5 BYTE),
  OD_SKU                          VARCHAR2(10 BYTE),
  CUST_RELEASE_NBR                VARCHAR2(12 BYTE),
  DESKTOP_LOC                     VARCHAR2(20 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


GRANT SELECT ON  USAGE_STAGE TO EUL01_SELECT;



CREATE TABLE USAGE_STAGE_USAGEDB
(
  CUSTOMER_NAME                   VARCHAR2(105 BYTE),
  PARENT_NAME                     VARCHAR2(90 BYTE),
  CUSTOMER_SHIP_TO_CONTACT_NAME   VARCHAR2(180 BYTE),
  CUSTOMER_SHIP_TO_ID             VARCHAR2(90 BYTE),
  CUST_ADDR_LINE_1                VARCHAR2(90 BYTE),
  CUST_ADDR_LINE_2                VARCHAR2(90 BYTE),
  CUST_CITY                       VARCHAR2(90 BYTE),
  CUST_STATE                      VARCHAR2(90 BYTE),
  CUST_COUNTRY_CD                 VARCHAR2(90 BYTE),
  CUST_DEPT_KEY                   VARCHAR2(90 BYTE),
  SHIP_TO_CUSTOMER_NAME           VARCHAR2(90 BYTE),
  CUST_PRODUCT_CD                 VARCHAR2(90 BYTE),
  SHIP_TO_ZIP                     VARCHAR2(90 BYTE),
  CUSTOMER_CURRENCY               VARCHAR2(750 BYTE),
  CUSTOMER_DEPT_DESC              VARCHAR2(750 BYTE),
  ACCOUNT_NUMBER_AOPS             VARCHAR2(750 BYTE),
  PARENT_ID                       VARCHAR2(90 BYTE),
  ITEM_DEPT_DESC                  VARCHAR2(750 BYTE),
  PRODUCT_DESC_SKU                VARCHAR2(750 BYTE),
  EDI_SELL_CODE                   VARCHAR2(750 BYTE),
  ORDER_COMPLETED_DATE            VARCHAR2(90 BYTE),
  ORDER_LINE_NUMBER               VARCHAR2(90 BYTE),
  CUSTOMER_PO_NUMBER              VARCHAR2(90 BYTE),
  ORDER_NUMBER                    VARCHAR2(90 BYTE),
  SUB_ORDER                       VARCHAR2(30 BYTE),
  ORDER_CREATE_DATE               VARCHAR2(90 BYTE),
  DELIVERY_DATE                   VARCHAR2(90 BYTE),
  PRODUCT_CODE_SKU                VARCHAR2(90 BYTE),
  RECONCILED_DATE                 VARCHAR2(90 BYTE),
  WHOLESALE_PRODUCT_CD            VARCHAR2(90 BYTE),
  EXTENDED_PRICE                  VARCHAR2(90 BYTE),
  SKU_RETAIL_PRICE                VARCHAR2(90 BYTE),
  QUANTITY_ORDERED                VARCHAR2(90 BYTE),
  QUANTITY_SHIPPED                VARCHAR2(90 BYTE),
  CUSTOMER_ID                     VARCHAR2(90 BYTE),
  BILL_TO_SEQUENCE_NBR_AOPS       VARCHAR2(90 BYTE),
  CUSTOMER_BILL_TO_BUSINESS_NAME  VARCHAR2(90 BYTE),
  BILL_TO_ADDRESS_LINE_1          VARCHAR2(90 BYTE),
  BILL_TO_ADDRESS_LINE_2          VARCHAR2(90 BYTE),
  BILL_TO_CITY                    VARCHAR2(90 BYTE),
  BILL_TO_STATE                   VARCHAR2(90 BYTE),
  BILL_TO_ZIP                     VARCHAR2(90 BYTE),
  ORDER_ID                        VARCHAR2(90 BYTE),
  FULLFILLMENT_ID                 VARCHAR2(90 BYTE),
  AOPS_SEQUENCE_ID                VARCHAR2(90 BYTE),
  OD_SKU                          VARCHAR2(90 BYTE),
  CUST_RELEASE_NBR                VARCHAR2(90 BYTE),
  DESKTOP_LOC                     VARCHAR2(90 BYTE)
)
TABLESPACE DISCOVERER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;



CREATE OR REPLACE VIEW XXOD_USAGE_CC_LOV
(COLUMN_VALUE)
AS 
Select "COLUMN_VALUE" from TABLE(XXOD_Usage_Lov_Values.Usage_CC_Lov)
/


CREATE OR REPLACE VIEW XXOD_USAGE_PO_LOV
(COLUMN_VALUE)
AS 
Select "COLUMN_VALUE" from TABLE(XXOD_Usage_Lov_Values.Usage_PO_Lov)
/


CREATE OR REPLACE VIEW XXOD_USAGE_SHIPTO_LOV
(COLUMN_VALUE)
AS 
Select "COLUMN_VALUE" from TABLE(XXOD_Usage_Lov_Values.Usage_Ship_To_Lov)
/


CREATE OR REPLACE FUNCTION EUL01."INSERTUSERINFO" (userInfo VARCHAR2, userID VARCHAR2) return VARCHAR2 
is 
--TYPE ProfileVal IS TABLE OF VARCHAR2(200);
XMLLoginID varchar2(50) := 'NONE';
XMLBillTo  VARCHAR2(20) := '';
lists varchar2(5000) := 'ALL';
seq_value NUMBER;
seq_value_detail NUMBER;
profileLoc XMLManager.ProfileVal;
begin 
   
  XMLMANAGER.PopulateXML(userInfo);
  
  IF ((not (userID is null)) AND (LENGTH(userID) > 0)) THEN
      XMLLoginID := userID;--UPPER('001' || userID); 
		
  ELSE 
    XMLLoginID := UPPER(XMLMANAGER.getCell('XML_PROFILE/HEADER/LOGINID')); 
    --XMLLoginID := UPPER(XMLMANAGER.getCell('XML_PROFILE/HEADER/LOGINID')); 

  
  END IF;
  
  XMLBillTo := XMLMANAGER.getCell('XML_PROFILE/HEADER/BILLTO');
  
  
  /*XMLLoginID := SYS_CONTEXT('USERENV','CLIENT_IDENTIFIER');
  */
  IF (not (XMLLoginID is null)) AND (not (XMLBillTo is null)) THEN 
   
      
  DELETE FROM usage_profile_header WHERE  
     usage_profile_header.loginid = XMLLoginID;
  
  SELECT usage_profile.NEXTVAL INTO seq_value FROM DUAL;
  
  INSERT INTO usage_profile_header VALUES(XMLLoginID,
    XMLMANAGER.getCell('XML_PROFILE/HEADER/EMAIL'),
    XMLMANAGER.getCell('XML_PROFILE/HEADER/NAME/FIRST'),
    XMLMANAGER.getCell('XML_PROFILE/HEADER/NAME/LAST'),
    XMLMANAGER.getCell('XML_PROFILE/HEADER/DOMAINID'),
    XMLMANAGER.getCell('XML_PROFILE/HEADER/BILLTO'),
    XMLMANAGER.getCell('XML_PROFILE/HEADER/USERTYPE'),
    XMLMANAGER.getCell('XML_PROFILE/HEADER/USERPERM'),seq_value);

SELECT usage_profile_detail_id.NEXTVAL INTO seq_value_detail FROM DUAL;




-- ******* COST CENTER DETAIL INFO *******
profileLoc := XMLManager.returnList('COSTCENTERS');
IF NOT (profileLoc is NULL) THEN
  FOR i IN profileLoc.FIRST .. profileLoc.LAST
  LOOP
    SELECT usage_profile_detail_id.NEXTVAL INTO seq_value_detail FROM DUAL;
    INSERT INTO usage_profile_detail VALUES('CC',profileLoc(i),seq_value,seq_value_detail);
  END LOOP;
END IF;

profileLoc := XMLManager.returnList('SHIPTOS');
IF NOT (profileLoc IS NULL) THEN
  FOR i IN profileLoc.FIRST .. profileLoc.LAST
  LOOP
    SELECT usage_profile_detail_id.NEXTVAL INTO seq_value_detail FROM DUAL;
    INSERT INTO usage_profile_detail VALUES('ST',profileLoc(i),seq_value,seq_value_detail);
  END LOOP;
END IF;

profileLoc := XMLManager.returnList('PONOS');
IF NOT (profileLoc IS NULL) THEN
  FOR i IN profileLoc.FIRST .. profileLoc.LAST
  LOOP
    SELECT usage_profile_detail_id.NEXTVAL INTO seq_value_detail FROM DUAL;
    INSERT INTO usage_profile_detail VALUES('PO',profileLoc(i),seq_value,seq_value_detail);
  END LOOP;
END IF;




return  XMLLoginID || 'COMPLETE'; 

ELSE
   RETURN XMLLoginID || 'ERROR - NULL Value for Login ID' || XMLMANAGER.getCell('XML_PROFILE/HEADER/BILLTO') || XMLMANAGER.getCell('XML_PROFILE/HEADER/LOGINID');
END IF;	

commit;

end;
/


CREATE OR REPLACE FUNCTION EUL01."DISCO_TABLE_SELECT" ( eul01 IN VARCHAR2
                                     ,PROFILE_USAGE_HEADER    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate     VARCHAR2(4000) := '1 = 2'; -- Default to select no rows
        BEGIN
            lc_predicate     := 'BILLTO= ' || NVL(SYS_CONTEXT('OD-DISCOVERER', 'SSO_USER_ID'),'HAS-NOT-BEEN-SET');
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN '1 = 2'; -- Return so that no rows are visible for secuity reason
        END disco_table_select;
/


CREATE OR REPLACE FUNCTION EUL01."EUL_TRIGGER$POST_LOGIN" 
RETURN number AS

ssouser varchar2(100);

BEGIN

ssouser := SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER');


insert into EUL01.TRIG_TAB values(sysdate, ssouser);
commit;

RETURN 0;
END;
/


CREATE OR REPLACE PROCEDURE EUL01.USAGE_LABELS_LOAD(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) AS

/*---------------------------------------------------------------------------
-- Procedure Usage_Labels_Load
-- Created First Draft January, 2008
-- This procedure reads data from a staging table that resides in the
-- EBS database and pushes data to the usage database, which is seperate from EBS,
-- This is done via  database link.
--
--
------------------------------------------------------------------------------
*/

BEGIN

DECLARE

v_count      NUMBER := 0;
data_exception EXCEPTION;
v_error_message VARCHAR2(2000);
v_sqlcode    VARCHAR2(20);

CURSOR cur1 IS
SELECT * FROM xxcomn.xx_bi_usage_labels_stage@GSIDEV02
ORDER BY customer_id;



BEGIN

--Cursor Check of Exception Messaging
--Cursor Main Insert of New Records

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LABELS_LOAD',SYSDATE,' Labels Load Started ');
COMMIT;

V_COUNT := 0;
v_error_message := NULL;

FOR main_cur IN cur1 LOOP

BEGIN

v_count := v_count + 1;

IF V_COUNT = 10000 THEN
INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LABELS_LOAD',SYSDATE,' Labels Records Loaded 10000');

commit;
v_count := 0;
END IF;

INSERT INTO usage_labels(
  CUSTOMER_ID,
  CUST_PO_NBR_LABEL,
  CUST_RELEASE_NBR_LABEL,
  DESKTOP_LOC_LABEL,
  CUST_DEPT_LABEL,
  CREATION_DATE,
  UPDATE_DATE,
  SOURCE_SYSTEM)
  VALUES(
  LTRIM(RTRIM(main_cur.customer_id)),
  LTRIM(RTRIM(main_cur.cust_po_nbr_label)),
  LTRIM(RTRIM(main_cur.cust_release_nbr_label)),
  LTRIM(RTRIM(main_cur.desktop_loc_label)),
  LTRIM(RTRIM(main_cur.cust_dept_label)),
  SYSDATE,
  SYSDATE,
  'TRD');

--Do Update of Transactions Table

EXCEPTION

WHEN DUP_VAL_ON_INDEX THEN

UPDATE usage_labels SET

  CUSTOMER_ID = TO_NUMBER(main_cur.customer_id),
  CUST_PO_NBR_LABEL = LTRIM(RTRIM(main_cur.cust_po_nbr_label)),
  CUST_RELEASE_NBR_LABEL = LTRIM(RTRIM(main_cur.cust_release_nbr_label)),
  DESKTOP_LOC_LABEL = LTRIM(RTRIM(main_cur.desktop_loc_label)),
  CUST_DEPT_LABEL = LTRIM(RTRIM(main_cur.cust_dept_label)),
  UPDATE_DATE = SYSDATE,
  SOURCE_SYSTEM = 'UPD'
WHERE CUSTOMER_ID = TO_NUMBER(main_cur.customer_id);



WHEN OTHERS THEN

v_error_message := SQLERRM;

dbms_output.put_line(SQLCODE||', '||SQLERRM);

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LABELS_LOAD',SYSDATE,' Labels Error '||v_error_message);
commit;


v_sqlcode := SQLCODE;
v_error_message := SQLERRM;

p_retcode := SQLCODE;
P_errbuf := v_error_message;

END;
END LOOP;

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LABELS_LOAD',SYSDATE,' Labels Load Ended ');
COMMIT;

EXCEPTION

WHEN OTHERS THEN
dbms_output.put_line(SQLCODE||', '||SQLERRM);

v_sqlcode := SQLCODE;
v_error_message := SQLERRM;


END;
END usage_labels_load;
/


CREATE OR REPLACE PROCEDURE EUL01.USAGE_LOAD_USAGEDB(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) AS
/*---------------------------------------------------------------------------
-- Procedure Usage_Load
-- Created First Draft January, 2008
-- This procedure reads data from a staging table that resides in the
-- EBS database and pushes data to the usage database, which is seperate from EBS,
-- This is done via  database link.
--
--
------------------------------------------------------------------------------
*/
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

DECLARE

v_count      NUMBER := 0;
V_TOTAL_COUNT  NUMBER := 0;
v_cust_po_nbr_desc   VARCHAR2(150);
v_cust_release_nbr_desc  VARCHAR2(150);
v_cust_dept_desc      VARCHAR2(150);
v_desktop_loc_desc    VARCHAR2(150);
v_order_number NUMBER;
v_lov_num NUMBER := 0;
v_sysdate VARCHAR2(20);
v_end_time VARCHAR2(20);


data_exception EXCEPTION;
v_error_message VARCHAR2(2000);
v_sqlcode    VARCHAR2(20);



CURSOR cur1 IS
SELECT A.* ,B.CUST_PO_NBR_LABEL, B.cust_release_nbr_label,B.desktop_loc_label,B.cust_dept_label
FROM usage_stage_usagedb a, usage_labels b
WHERE a.customer_id = b.customer_id;

CURSOR cur2 IS
SELECT * FROM od_ext_usage_updates;

CURSOR cur_lov_po IS
SELECT DISTINCT a.customer_id, 'PO', a.customer_po_number,''
FROM USAGE_STAGE_USAGEDB a
WHERE NOT EXISTS (SELECT 'x' FROM USAGE_LOV b WHERE
   b.account_number = a.customer_id AND
   b.LOV_TYPE = 'PO' AND
   b.LOV_DESCRIPTION = a.Customer_PO_number)
AND a.customer_id IS NOT NULL;

TYPE USAGE_LOV_TABLE1
      IS TABLE OF USAGE_LOV%ROWTYPE
      INDEX BY PLS_INTEGER;
   USAGE_TABLE_RECS1 USAGE_LOV_TABLE1;

CURSOR cur_lov_cc IS
SELECT DISTINCT a.customer_id, 'CC', a.cust_dept_key,''
FROM USAGE_STAGE_USAGEDB a
WHERE NOT EXISTS (SELECT 'x' FROM USAGE_LOV b WHERE
   b.account_number = a.customer_id AND
   b.LOV_TYPE = 'CC' AND
   b.LOV_DESCRIPTION = a.Cust_Dept_Key)
AND a.customer_id IS NOT NULL;

TYPE USAGE_LOV_TABLE2
      IS TABLE OF USAGE_LOV%ROWTYPE
      INDEX BY PLS_INTEGER;
   USAGE_TABLE_RECS2 USAGE_LOV_TABLE2;

CURSOR cur_lov_st IS
SELECT DISTINCT a.customer_id, 'ST', a.aops_sequence_id, LTRIM(RTRIM(a.customer_ship_to_id))
FROM USAGE_STAGE_USAGEDB a
WHERE NOT EXISTS (SELECT 'x' FROM USAGE_LOV b WHERE
   b.account_number = a.customer_id AND
   b.LOV_TYPE = 'ST' AND
   b.LOV_DESCRIPTION = a.aops_sequence_id)
AND a.customer_id IS NOT NULL;

TYPE USAGE_LOV_TABLE3
      IS TABLE OF USAGE_LOV%ROWTYPE
      INDEX BY PLS_INTEGER;
   USAGE_TABLE_RECS3 USAGE_LOV_TABLE3;

BEGIN

--Cursor Check of Exception Messaging
--Cursor Main Insert of New Records

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' Starting Program USAGE_LOAD_USAGEDB');
COMMIT;


delete from od_ext_usage_updates;
commit;

FOR main_cur IN cur1 LOOP

v_error_message := NULL;
BEGIN

--Check for critical missing data
IF main_cur.aops_sequence_id IS NULL THEN
v_error_message := 'Missing Customer Ship To ID';
RAISE data_exception;
ELSIF main_cur.aops_sequence_id = '00000' THEN
v_error_message := 'Invalid Customer Ship To ID';
RAISE data_exception;
END IF;

V_TOTAL_COUNT := V_TOTAL_COUNT + 1;
v_count := v_count + 1;
IF v_count = 10000 THEN
commit;
--dbms_output.put_line(' Committing 10,000 trans '||V_TOTAL_COUNT);

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' Committing 10000 Transactions '||V_TOTAL_COUNT);

v_count := 0;
END IF;


v_order_number := 0;
--v_order_number := to_number(ltrim(rtrim(main_cur.order_number)));

BEGIN
--dbms_output.put_line(' Before the Insert Statement ');
INSERT INTO od_ext_usage_rpt(
 ORDER_ID,
  ORDER_LINE_NUMBER,
  FULLFILLMENT_ID,
  CUSTOMER_ID,
  ACCOUNT_NUMBER,
  CUSTOMER_NAME,
  CUSTOMER_DEPT,
  CUSTOMER_DEPT_DESC,
  PARENT_NAME,
  PARENT_ID,
  PRODUCT_CODE,
  RETAIL_PRICE,
  PRODUCT_DESC,
  WHOLESALE_PRODUCT_CODE,
  CUSTOMER_PRODUCT_CODE,
  EDI_SELL_CODE,
  QUANTITY_SHIPPED,
  QUANTITY,
  CUSTOMER_CURRENCY,
  EXTENDED_PRICE,
  RECONCILED_DATE,
  SHIP_TO_CONTACT_NAME,
  SHIP_TO_CUSTOMER_ID,
  SHIP_TO_CUSTOMER_NAME,
  SHIP_TO_ADDRESS_LINE1,
  SHIP_TO_ADDRESS_LINE2,
  SHIP_TO_CITY,
  SHIP_TO_STATE,
  SHIP_TO_ZIP,
  COUNTRY_CODE,
  BILL_TO_CUSTOMER_ID,
  BILL_TO_CUSTOMER_NAME,
  BILL_TO_ADDRESS_LINE1,
  BILL_TO_ADDRESS_LINE2,
  BILL_TO_CITY,
  BILL_TO_STATE,
  BILL_TO_ZIP,
  ORDER_CREATE_DATE,
  DELIVERY_DATE,
  ORDER_COMPLETED_DATE,
  UNIT_OF_MEASURE,
  CUST_PO_NUMBER,
  ITEM_DEPT_DESC,
  ORDER_NUMBER,
  SUB_ORDER,
  ORDER_NUMBER_FULLFILLMENT,
  SHIP_TO_ID,
  SHIP_TO_KEY,
  OD_SKU,
  CUST_RELEASE_NUMBER,
  DESKTOP_LOCATOR,
  CUST_RELEASE_NUMBER_DESC,
  DESKTOP_LOCATOR_DESC,
  CUST_PO_NUMBER_DESC,
  SOURCE_SYSTEM_NAME)
  VALUES(
  to_number(ltrim(rtrim(main_cur.order_id))),
  to_number(ltrim(rtrim(main_cur.order_line_number))),
  to_number(ltrim(rtrim(main_cur.fullfillment_id))),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.account_number_aops)),
  ltrim(rtrim(main_cur.customer_name)),
  ltrim(rtrim(main_cur.cust_dept_key)),
  ltrim(rtrim(main_cur.cust_dept_label)),
  ltrim(rtrim(main_cur.parent_name)),
  to_number(ltrim(rtrim(main_cur.parent_id))),
  ltrim(rtrim(main_cur.product_code_sku)),
  to_number(ltrim(rtrim(main_cur.sku_retail_price))),
  ltrim(rtrim(main_cur.product_desc_sku)),
  ltrim(rtrim(main_cur.wholesale_product_cd)),
  ltrim(rtrim(main_cur.cust_product_cd)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  to_number(ltrim(rtrim(main_cur.quantity_shipped))),
  to_number(ltrim(rtrim(main_cur.quantity_ordered))),
  ltrim(rtrim(main_cur.customer_currency)),
  to_number(ltrim(rtrim(main_cur.extended_price))),
  to_date(main_cur.reconciled_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.customer_ship_to_contact_name)),
  ltrim(rtrim(main_cur.aops_sequence_id)),
  ltrim(rtrim(main_cur.ship_to_customer_name)),
  ltrim(rtrim(main_cur.cust_addr_line_1)),
  ltrim(rtrim(main_cur.cust_addr_line_2)),
  ltrim(rtrim(main_cur.cust_city)),
  ltrim(rtrim(main_cur.cust_state)),
  ltrim(rtrim(main_cur.ship_to_zip)),
  ltrim(rtrim(main_cur.cust_country_cd)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.customer_bill_to_business_name)),
  ltrim(rtrim(main_cur.bill_to_address_line_1)),
  ltrim(rtrim(main_cur.bill_to_address_line_2)),
  ltrim(rtrim(main_cur.bill_to_city)),
  ltrim(rtrim(main_cur.bill_to_state)),
  ltrim(rtrim(main_cur.bill_to_zip)),
  to_date(main_cur.order_create_date,'MMDDYYYY'),
  to_date(main_cur.delivery_date,'MMDDYYYY'),
  to_date(main_cur.order_completed_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.customer_po_number)),
  ltrim(rtrim(main_cur.item_dept_desc)),
  to_number(ltrim(rtrim(main_cur.order_number))),
  to_number(ltrim(rtrim(main_cur.sub_order))),
  to_number(ltrim(rtrim(main_cur.order_number)))||'-00'||to_number(ltrim(rtrim(main_cur.fullfillment_id))),
  ltrim(rtrim(main_cur.customer_ship_to_id)),
  ltrim(rtrim(main_cur.aops_sequence_id))||'-'||ltrim(rtrim(main_cur.customer_ship_to_id)),
  ltrim(rtrim(main_cur.od_sku)),
  ltrim(rtrim(main_cur.cust_release_nbr)),
  ltrim(rtrim(main_cur.desktop_loc)),
  main_cur.cust_release_nbr_label,
  main_cur.desktop_loc_label,
  main_cur.cust_po_nbr_label,
  'TRD');


--Check for other exceptions
IF main_cur.cust_addr_line_1 IS NULL THEN
v_error_message := 'Missing Customer Address Line 1';
RAISE data_exception;
END IF;

IF main_cur.cust_city IS NULL THEN
v_error_message := 'Missing Customer Ship To City';
RAISE data_exception;
END IF;

IF main_cur.cust_state IS NULL THEN
v_error_message := 'Missing Customer Ship To State';
RAISE data_exception;
END IF;

IF main_cur.ship_to_zip IS NULL THEN
v_error_message := 'Missing Customer Ship To Zip';
RAISE data_exception;
END IF;

IF main_cur.order_number IS NULL THEN
v_error_message := 'Missing Customer Order Number';
RAISE data_exception;
END IF;

IF main_cur.bill_to_address_line_1 IS NULL THEN
v_error_message := 'Missing Bill To Address Line 1';
RAISE data_exception;
END IF;

--END IF;

EXCEPTION

WHEN data_exception THEN

--v_sqlcode := '99999';

INSERT INTO od_ext_usage_err(
  ORDER_ID,
  ORDER_LINE_NUMBER,
  FULLFILLMENT_ID,
  CUSTOMER_ID,
  ACCOUNT_NUMBER,
  CUSTOMER_NAME,
  CUSTOMER_DEPT,
  CUSTOMER_DEPT_DESC,
  PARENT_NAME,
  PARENT_ID,
  PRODUCT_CODE,
  RETAIL_PRICE,
  PRODUCT_DESC,
  WHOLESALE_PRODUCT_CODE,
  CUSTOMER_PRODUCT_CODE,
  EDI_SELL_CODE,
  QUANTITY_SHIPPED,
  QUANTITY,
  CUSTOMER_CURRENCY,
  EXTENDED_PRICE,
  RECONCILED_DATE,
  SHIP_TO_CONTACT_NAME,
  SHIP_TO_CUSTOMER_ID,
  SHIP_TO_CUSTOMER_NAME,
  SHIP_TO_ADDRESS_LINE1,
  SHIP_TO_ADDRESS_LINE2,
  SHIP_TO_CITY,
  SHIP_TO_STATE,
  SHIP_TO_ZIP,
  COUNTRY_CODE,
  BILL_TO_CUSTOMER_ID,
  BILL_TO_CUSTOMER_NAME,
  BILL_TO_ADDRESS_LINE1,
  BILL_TO_ADDRESS_LINE2,
  BILL_TO_CITY,
  BILL_TO_STATE,
  BILL_TO_ZIP,
  ORDER_CREATE_DATE,
  DELIVERY_DATE,
  ORDER_COMPLETED_DATE,
  UNIT_OF_MEASURE,
  CUST_PO_NUMBER,
  ITEM_DEPT_DESC,
  ORDER_NUMBER,
  SUB_ORDER,
  ORDER_NUMBER_FULLFILLMENT,
  SHIP_TO_ID,
  SHIP_TO_KEY,
  cust_release_number,
  OD_SKU,
  SOURCE_SYSTEM_NAME,
  SQL_CODE,
  SQL_ERR_MSG)
  VALUES(
  ltrim(rtrim(main_cur.order_id)),
  ltrim(rtrim(main_cur.order_line_number)),
  ltrim(rtrim(main_cur.fullfillment_id)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.account_number_aops)),
  ltrim(rtrim(main_cur.customer_name)),
  ltrim(rtrim(main_cur.cust_dept_key)),
  ltrim(rtrim(main_cur.customer_dept_desc)),
  ltrim(rtrim(main_cur.parent_name)),
  ltrim(rtrim(main_cur.parent_id)),
  ltrim(rtrim(main_cur.product_code_sku)),
  ltrim(rtrim(main_cur.sku_retail_price)),
  ltrim(rtrim(main_cur.product_desc_sku)),
  ltrim(rtrim(main_cur.wholesale_product_cd)),
  ltrim(rtrim(main_cur.cust_product_cd)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.quantity_shipped)),
  ltrim(rtrim(main_cur.quantity_ordered)),
  ltrim(rtrim(main_cur.customer_currency)),
  ltrim(rtrim(main_cur.extended_price)),
  ltrim(rtrim(main_cur.reconciled_date)),
  ltrim(rtrim(main_cur.customer_ship_to_contact_name)),
  ltrim(rtrim(main_cur.aops_sequence_id)),
  ltrim(rtrim(main_cur.ship_to_customer_name)),
  ltrim(rtrim(main_cur.cust_addr_line_1)),
  ltrim(rtrim(main_cur.cust_addr_line_2)),
  ltrim(rtrim(main_cur.cust_city)),
  ltrim(rtrim(main_cur.cust_state)),
  ltrim(rtrim(main_cur.ship_to_zip)),
  ltrim(rtrim(main_cur.cust_country_cd)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.customer_bill_to_business_name)),
  ltrim(rtrim(main_cur.bill_to_address_line_1)),
  ltrim(rtrim(main_cur.bill_to_address_line_2)),
  ltrim(rtrim(main_cur.bill_to_city)),
  ltrim(rtrim(main_cur.bill_to_state)),
  ltrim(rtrim(main_cur.bill_to_zip)),
  ltrim(rtrim(main_cur.order_create_date)),
  ltrim(rtrim(main_cur.delivery_date)),
  ltrim(rtrim(main_cur.order_completed_date)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.customer_po_number)),
  ltrim(rtrim(main_cur.item_dept_desc)),
  ltrim(rtrim(main_cur.order_number)),
  ltrim(rtrim(main_cur.sub_order)),
  ltrim(rtrim(main_cur.order_number))||'-00'||ltrim(rtrim(main_cur.fullfillment_id)),
  ltrim(rtrim(main_cur.customer_ship_to_id)),
  main_cur.aops_sequence_id||'-'||ltrim(rtrim(main_cur.customer_ship_to_id)),
  ltrim(rtrim(main_cur.cust_Release_nbr)),
  main_cur.od_sku,
  'ERR',
  v_sqlcode,
  v_error_message);


WHEN DUP_VAL_ON_INDEX THEN
--dbms_output.put_line(' In the Update Section ');

INSERT INTO od_ext_usage_updates(
  ORDER_ID,
  ORDER_LINE_NUMBER,
  FULLFILLMENT_ID,
  CUSTOMER_ID,
  ACCOUNT_NUMBER,
  CUSTOMER_NAME,
  CUSTOMER_DEPT,
  CUSTOMER_DEPT_DESC,
  PARENT_NAME,
  PARENT_ID,
  PRODUCT_CODE,
  RETAIL_PRICE,
  PRODUCT_DESC,
  WHOLESALE_PRODUCT_CODE,
  CUSTOMER_PRODUCT_CODE,
  EDI_SELL_CODE,
  QUANTITY_SHIPPED,
  QUANTITY,
  CUSTOMER_CURRENCY,
  EXTENDED_PRICE,
  RECONCILED_DATE,
  SHIP_TO_CONTACT_NAME,
  SHIP_TO_CUSTOMER_ID,
  SHIP_TO_CUSTOMER_NAME,
  SHIP_TO_ADDRESS_LINE1,
  SHIP_TO_ADDRESS_LINE2,
  SHIP_TO_CITY,
  SHIP_TO_STATE,
  SHIP_TO_ZIP,
  COUNTRY_CODE,
  BILL_TO_CUSTOMER_ID,
  BILL_TO_CUSTOMER_NAME,
  BILL_TO_ADDRESS_LINE1,
  BILL_TO_ADDRESS_LINE2,
  BILL_TO_CITY,
  BILL_TO_STATE,
  BILL_TO_ZIP,
  ORDER_CREATE_DATE,
  DELIVERY_DATE,
  ORDER_COMPLETED_DATE,
  UNIT_OF_MEASURE,
  CUST_PO_NUMBER,
  ITEM_DEPT_DESC,
  ORDER_NUMBER,
  SUB_ORDER,
  ORDER_NUMBER_FULLFILLMENT,
  SHIP_TO_ID,
  SHIP_TO_KEY,
  OD_SKU,
  CUST_RELEASE_NUMBER,
  DESKTOP_LOCATOR,
  CUST_RELEASE_NUMBER_DESC,
  DESKTOP_LOCATOR_DESC,
  CUST_PO_NUMBER_DESC,
  SOURCE_SYSTEM_NAME)
VALUES(
  to_number(ltrim(rtrim(main_cur.order_id))),
  to_number(ltrim(rtrim(main_cur.order_line_number))),
  to_number(ltrim(rtrim(main_cur.fullfillment_id))),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.account_number_aops)),
  ltrim(rtrim(main_cur.customer_name)),
  ltrim(rtrim(main_cur.cust_dept_key)),
  ltrim(rtrim(main_cur.cust_dept_label)),
  ltrim(rtrim(main_cur.parent_name)),
  to_number(ltrim(rtrim(main_cur.parent_id))),
  ltrim(rtrim(main_cur.product_code_sku)),
  to_number(ltrim(rtrim(main_cur.sku_retail_price))),
  ltrim(rtrim(main_cur.product_desc_sku)),
  ltrim(rtrim(main_cur.wholesale_product_cd)),
  ltrim(rtrim(main_cur.cust_product_cd)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  to_number(ltrim(rtrim(main_cur.quantity_shipped))),
  to_number(ltrim(rtrim(main_cur.quantity_ordered))),
  ltrim(rtrim(main_cur.customer_currency)),
  to_number(ltrim(rtrim(main_cur.extended_price))),
  to_date(main_cur.reconciled_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.customer_ship_to_contact_name)),
  ltrim(rtrim(main_cur.aops_sequence_id)),
  ltrim(rtrim(main_cur.ship_to_customer_name)),
  ltrim(rtrim(main_cur.cust_addr_line_1)),
  ltrim(rtrim(main_cur.cust_addr_line_2)),
  ltrim(rtrim(main_cur.cust_city)),
  ltrim(rtrim(main_cur.cust_state)),
  ltrim(rtrim(main_cur.ship_to_zip)),
  ltrim(rtrim(main_cur.cust_country_cd)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.customer_bill_to_business_name)),
  ltrim(rtrim(main_cur.bill_to_address_line_1)),
  ltrim(rtrim(main_cur.bill_to_address_line_2)),
  ltrim(rtrim(main_cur.bill_to_city)),
  ltrim(rtrim(main_cur.bill_to_state)),
  ltrim(rtrim(main_cur.bill_to_zip)),
  to_date(main_cur.order_create_date,'MMDDYYYY'),
  to_date(main_cur.delivery_date,'MMDDYYYY'),
  to_date(main_cur.order_completed_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.customer_po_number)),
  ltrim(rtrim(main_cur.item_dept_desc)),
  to_number(ltrim(rtrim(main_cur.order_number))),
  to_number(ltrim(rtrim(main_cur.sub_order))),
  to_number(ltrim(rtrim(main_cur.order_number)))||'-00'||to_number(ltrim(rtrim(main_cur.fullfillment_id))),
  ltrim(rtrim(main_cur.customer_ship_to_id)),
  ltrim(rtrim(main_cur.aops_sequence_id))||'-'||ltrim(rtrim(main_cur.customer_ship_to_id)),
  ltrim(rtrim(main_cur.od_sku)),
  ltrim(rtrim(main_cur.cust_release_nbr)),
  ltrim(rtrim(main_cur.desktop_loc)),
  main_cur.cust_release_nbr_label,
  main_cur.desktop_loc_label,
  main_cur.cust_po_nbr_label,
  'UPD');



END;
--***********************************************************************************
EXCEPTION

WHEN OTHERS THEN
--dbms_output.put_line(' In the when others of the loop section ');



v_sqlcode := SQLCODE;
v_error_message := SQLERRM;

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' Error Record - Inserting to Error Table ');

INSERT INTO od_ext_usage_err(
  ORDER_ID,
  ORDER_LINE_NUMBER,
  FULLFILLMENT_ID,
  CUSTOMER_ID,
  ACCOUNT_NUMBER,
  CUSTOMER_NAME,
  CUSTOMER_DEPT,
  CUSTOMER_DEPT_DESC,
  PARENT_NAME,
  PARENT_ID,
  PRODUCT_CODE,
  RETAIL_PRICE,
  PRODUCT_DESC,
  WHOLESALE_PRODUCT_CODE,
  CUSTOMER_PRODUCT_CODE,
  EDI_SELL_CODE,
  QUANTITY_SHIPPED,
  QUANTITY,
  CUSTOMER_CURRENCY,
  EXTENDED_PRICE,
  RECONCILED_DATE,
  SHIP_TO_CONTACT_NAME,
  SHIP_TO_CUSTOMER_ID,
  SHIP_TO_CUSTOMER_NAME,
  SHIP_TO_ADDRESS_LINE1,
  SHIP_TO_ADDRESS_LINE2,
  SHIP_TO_CITY,
  SHIP_TO_STATE,
  SHIP_TO_ZIP,
  COUNTRY_CODE,
  BILL_TO_CUSTOMER_ID,
  BILL_TO_CUSTOMER_NAME,
  BILL_TO_ADDRESS_LINE1,
  BILL_TO_ADDRESS_LINE2,
  BILL_TO_CITY,
  BILL_TO_STATE,
  BILL_TO_ZIP,
  ORDER_CREATE_DATE,
  DELIVERY_DATE,
  ORDER_COMPLETED_DATE,
  UNIT_OF_MEASURE,
  CUST_PO_NUMBER,
  ITEM_DEPT_DESC,
  ORDER_NUMBER,
  SUB_ORDER,
  ORDER_NUMBER_FULLFILLMENT,
  SHIP_TO_ID,
  SHIP_TO_KEY,
  cust_release_number,
  OD_SKU,
  SOURCE_SYSTEM_NAME,
  SQL_CODE,
  SQL_ERR_MSG)
  VALUES(
  ltrim(rtrim(main_cur.order_id)),
  ltrim(rtrim(main_cur.order_line_number)),
  ltrim(rtrim(main_cur.fullfillment_id)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.account_number_aops)),
  ltrim(rtrim(main_cur.customer_name)),
  ltrim(rtrim(main_cur.cust_dept_key)),
  ltrim(rtrim(main_cur.customer_dept_desc)),
  ltrim(rtrim(main_cur.parent_name)),
  ltrim(rtrim(main_cur.parent_id)),
  ltrim(rtrim(main_cur.product_code_sku)),
  ltrim(rtrim(main_cur.sku_retail_price)),
  ltrim(rtrim(main_cur.product_desc_sku)),
  ltrim(rtrim(main_cur.wholesale_product_cd)),
  ltrim(rtrim(main_cur.cust_product_cd)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.quantity_shipped)),
  ltrim(rtrim(main_cur.quantity_ordered)),
  ltrim(rtrim(main_cur.customer_currency)),
  ltrim(rtrim(main_cur.extended_price)),
  ltrim(rtrim(main_cur.reconciled_date)),
  ltrim(rtrim(main_cur.customer_ship_to_contact_name)),
  ltrim(rtrim(main_cur.aops_sequence_id)),
  ltrim(rtrim(main_cur.ship_to_customer_name)),
  ltrim(rtrim(main_cur.cust_addr_line_1)),
  ltrim(rtrim(main_cur.cust_addr_line_2)),
  ltrim(rtrim(main_cur.cust_city)),
  ltrim(rtrim(main_cur.cust_state)),
  ltrim(rtrim(main_cur.ship_to_zip)),
  ltrim(rtrim(main_cur.cust_country_cd)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.customer_bill_to_business_name)),
  ltrim(rtrim(main_cur.bill_to_address_line_1)),
  ltrim(rtrim(main_cur.bill_to_address_line_2)),
  ltrim(rtrim(main_cur.bill_to_city)),
  ltrim(rtrim(main_cur.bill_to_state)),
  ltrim(rtrim(main_cur.bill_to_zip)),
  ltrim(rtrim(main_cur.order_create_date)),
  ltrim(rtrim(main_cur.delivery_date)),
  ltrim(rtrim(main_cur.order_completed_date)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.customer_po_number)),
  ltrim(rtrim(main_cur.item_dept_desc)),
  ltrim(rtrim(main_cur.order_number)),
  ltrim(rtrim(main_cur.sub_order)),
  ltrim(rtrim(main_cur.order_number))||'-00'||ltrim(rtrim(main_cur.fullfillment_id)),
  ltrim(rtrim(main_cur.customer_ship_to_id)),
  ltrim(rtrim(main_cur.aops_sequence_id))||'-'||ltrim(rtrim(main_cur.customer_ship_to_id)),
  ltrim(rtrim(main_cur.cust_Release_nbr)),
  ltrim(rtrim(main_cur.od_sku)),
  'ERR',
  v_SQLCODE,
  v_error_message);

END;

END LOOP;

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' PROGRAM FINISHED FROM LOOP 1 ');
COMMIT;

--********************************* Ending First Loop

V_TOTAL_COUNT := 0;
V_COUNT := 0;

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' Starting Updates ');
commit;

BEGIN
FOR main_cur2 IN cur2 LOOP


V_TOTAL_COUNT := V_TOTAL_COUNT + 1;
v_count := v_count + 1;

IF v_count = 10000 THEN

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' Committing 10000 Update Trans '||V_TOTAL_COUNT);
commit;
v_count := 0;
END IF;

--INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
--'USG_LOAD_USAGEDB',SYSDATE,' record '||v_count);

BEGIN
UPDATE od_ext_usage_rpt SET
  CUSTOMER_ID = main_cur2.customer_id,
  ACCOUNT_NUMBER = main_cur2.account_number,
  CUSTOMER_NAME = main_cur2.customer_name,
  CUSTOMER_DEPT = main_cur2.customer_dept,
  CUSTOMER_DEPT_DESC = main_cur2.customer_dept_desc,
  PARENT_NAME = main_cur2.parent_name,
  PARENT_ID = main_cur2.parent_id,
  PRODUCT_CODE = main_cur2.product_code,
  RETAIL_PRICE = main_cur2.retail_price,
  PRODUCT_DESC = main_cur2.product_desc,
  WHOLESALE_PRODUCT_CODE = main_cur2.wholesale_product_code,
  CUSTOMER_PRODUCT_CODE = main_cur2.customer_product_code,
  EDI_SELL_CODE = main_cur2.edi_sell_code,
  QUANTITY_SHIPPED = main_cur2.quantity_shipped,
  QUANTITY = main_cur2.quantity,
  CUSTOMER_CURRENCY = main_cur2.customer_currency,
  EXTENDED_PRICE = main_cur2.extended_price,
  RECONCILED_DATE = main_cur2.reconciled_date,
  SHIP_TO_CONTACT_NAME = main_cur2.ship_to_contact_name,
  SHIP_TO_CUSTOMER_ID = main_cur2.ship_to_customer_id,
  SHIP_TO_CUSTOMER_NAME = main_cur2.ship_to_customer_name,
  SHIP_TO_ADDRESS_LINE1 = main_cur2.ship_to_address_line1,
  SHIP_TO_ADDRESS_LINE2 = main_cur2.ship_to_address_line2,
  SHIP_TO_CITY = main_cur2.ship_to_city,
  SHIP_TO_STATE = main_cur2.ship_to_state,
  SHIP_TO_ZIP = main_cur2.ship_to_zip,
  COUNTRY_CODE = main_cur2.country_code,
  BILL_TO_CUSTOMER_ID = main_cur2.bill_to_customer_id,
  BILL_TO_CUSTOMER_NAME = main_cur2.bill_to_customer_name,
  BILL_TO_ADDRESS_LINE1 = main_cur2.bill_to_address_line1,
  BILL_TO_ADDRESS_LINE2 = main_cur2.bill_to_address_line2,
  BILL_TO_CITY = main_cur2.bill_to_city,
  BILL_TO_STATE = main_cur2.bill_to_state,
  BILL_TO_ZIP =  main_cur2.bill_to_zip,
  ORDER_CREATE_DATE = main_cur2.order_create_date,
  DELIVERY_DATE = main_cur2.delivery_date,
  ORDER_COMPLETED_DATE = main_cur2.order_completed_date,
  UNIT_OF_MEASURE = main_cur2.unit_of_measure,
  CUST_PO_NUMBER = main_cur2.cust_po_number,
  ITEM_DEPT_DESC = main_cur2.item_dept_desc,
  ORDER_NUMBER = main_cur2.order_number,
  SUB_ORDER = main_cur2.sub_order,
  ORDER_NUMBER_FULLFILLMENT = main_cur2.order_number_fullfillment,
  SHIP_TO_ID = main_cur2.ship_to_id,
  SHIP_TO_KEY = main_cur2.ship_to_key,
  CUST_RELEASE_NUMBER = main_cur2.cust_release_number,
  DESKTOP_LOCATOR = main_cur2.desktop_locator,
  SOURCE_SYSTEM_NAME = 'UPD'
where ORDER_ID = main_cur2.order_id
AND ORDER_LINE_NUMBER = main_cur2.order_line_number
AND FULLFILLMENT_ID = main_cur2.fullfillment_id;


EXCEPTION
WHEN OTHERS THEN

v_sqlcode := SQLCODE;
v_error_message := SQLERRM;

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' Error Record in Update - Inserting to Error Table ');
commit;

INSERT INTO od_ext_usage_err(
  ORDER_LINE_NUMBER,
  FULLFILLMENT_ID,
  CUSTOMER_ID,
  ACCOUNT_NUMBER,
  CUSTOMER_NAME,
  ORDER_NUMBER,
  SOURCE_SYSTEM_NAME,
  SQL_CODE,
  SQL_ERR_MSG)
  VALUES(
  ltrim(rtrim(main_cur2.order_line_number)),
  ltrim(rtrim(main_cur2.fullfillment_id)),
  ltrim(rtrim(main_cur2.customer_id)),
  ltrim(rtrim(main_cur2.account_number)),
  ltrim(rtrim(main_cur2.customer_name)),
  ltrim(rtrim(main_cur2.order_number)),
  'EUP',
  v_SQLCODE,
  v_error_message);
END;

END LOOP;
END;


INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' PROGRAM FINISHED FROM LOOP 2 ');

commit;


--***********************************************************************************************

BEGIN

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' STARTING LOV LOADS ');
COMMIT;


OPEN cur_lov_po;
dbms_output.put_line(' In the usage lov PO section ');

LOOP
--dbms_output.put_line(' 20,000 records ');
--FND_FILE.PUT_LINE(FND_FILE.LOG,' 20,000 records');

      FETCH cur_lov_po BULK COLLECT INTO USAGE_TABLE_RECS1 LIMIT 20000;

       FOR i IN 1..usage_table_recs1.COUNT LOOP

  BEGIN

     INSERT INTO USAGE_LOV
      VALUES USAGE_TABLE_RECS1(i);

EXIT WHEN SQL%NOTFOUND;

EXCEPTION
WHEN NO_DATA_FOUND THEN
INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' NO PO LOV DATA FOUND ');
COMMIT;

WHEN OTHERS THEN
dbms_output.put_line('Error'||SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
--FND_FILE.PUT_LINE(FND_FILE.LOG,'Error'||SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);


END;
END LOOP;

EXIT WHEN cur_lov_po%NOTFOUND;
END LOOP;

COMMIT;
END;

CLOSE cur_lov_po;

-- LOV CC

BEGIN
dbms_output.put_line(' In the CC Lov Section ');

OPEN cur_lov_cc;

LOOP
--dbms_output.put_line(' 20,000 records ');
--FND_FILE.PUT_LINE(FND_FILE.LOG,' 20,000 records');

      FETCH cur_lov_cc BULK COLLECT INTO USAGE_TABLE_RECS2 LIMIT 20000;

       FOR i IN 1..usage_table_recs2.COUNT LOOP

  BEGIN

     INSERT INTO USAGE_LOV
      VALUES USAGE_TABLE_RECS2(i);

EXIT WHEN SQL%NOTFOUND;

EXCEPTION

WHEN NO_DATA_FOUND THEN
INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' NO CC LOV DATA FOUND ');
COMMIT;

WHEN OTHERS THEN
dbms_output.put_line('Error'||SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
--FND_FILE.PUT_LINE(FND_FILE.LOG,'Error'||SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);


END;
END LOOP;

EXIT WHEN cur_lov_cc%NOTFOUND;
END LOOP;

COMMIT;
END;


CLOSE cur_lov_cc;

-- LOV ST

BEGIN
dbms_output.put_line(' In the ST Lov section ');

OPEN cur_lov_st;

LOOP
--dbms_output.put_line(' 20,000 records ');
--FND_FILE.PUT_LINE(FND_FILE.LOG,' 20,000 records');

      FETCH cur_lov_st BULK COLLECT INTO USAGE_TABLE_RECS3 LIMIT 20000;

       FOR i IN 1..usage_table_recs3.COUNT LOOP

  BEGIN

     INSERT INTO USAGE_LOV
      VALUES USAGE_TABLE_RECS3(i);

EXIT WHEN SQL%NOTFOUND;

EXCEPTION
WHEN NO_DATA_FOUND THEN
INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' NO ST LOV DATA FOUND ');
COMMIT;

WHEN OTHERS THEN
dbms_output.put_line('Error'||SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
--FND_FILE.PUT_LINE(FND_FILE.LOG,'Error'||SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);


END;
END LOOP;

EXIT WHEN cur_lov_st%NOTFOUND;
END LOOP;

COMMIT;
END;


CLOSE cur_lov_st;




--************************************************************************************************

IF v_sqlcode IS NOT NULL THEN

p_retcode := 1;
p_errbuf := v_error_message;

ELSE
p_retcode := 0;
p_errbuf := 'Program Finished Successfully';
END IF;


INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' PROGRAM FINISHED ');
commit;


EXCEPTION

WHEN OTHERS THEN
dbms_output.put_line(' In the outer when others exception ');


COMMIT;

dbms_output.put_line(SQLCODE||', '||SQLERRM);
--FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Program Processing - Please check the od_ext_usage_err table');
--FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||', '||SQLERRM);

v_sqlcode := SQLCODE;
v_error_message := SQLERRM;

p_retcode := 1;
p_errbuf := v_error_message;

INSERT INTO OD_USAGE_STATS(program_name,run_date, sys_message)VALUES(
'USG_LOAD_USAGEDB',SYSDATE,' WHEN OTHERS EXCEPTION '||v_error_message);
COMMIT;


INSERT INTO od_ext_usage_err(
  SQL_CODE,
  SQL_ERR_MSG,
  ORDER_CREATE_DATE)
  VALUES(
  v_sqlcode,
  v_error_message,
  sysdate);

Commit;

END;
END usage_load_USAGEDB;
/


CREATE OR REPLACE PACKAGE EUL01.dw_util IS
/*******************************************************************************
Author: Rahul Kundavaram
Creation Date: 15-July-2008

Description: This package common utility programs. Programs in this package
             should be generic purpose.

Modification History
====================
DATE         WHO                   WHAT
-----------  -------------         ---------------------
15-July-2008  Rahul Kundavaram     Package created

*******************************************************************************/
-- public variables
  -- NEWLINE is used to separate text line in the message body
  newline    CONSTANT STRING(2) := chr(13) || chr(10);

  -- RECIPIENT_LIST array is used to pass the list of attachments.
  -- External use syntax is:
  -- dw_util..recipient_list('person1@officedepot.com', 'person2@yahoo.com')
  TYPE recipient_list IS TABLE OF VARCHAR2 (4000);


-- public functions
  FUNCTION get_number (i_value IN VARCHAR2) RETURN NUMBER;

  FUNCTION get_date (i_value IN VARCHAR2) RETURN DATE;

  FUNCTION sendmail (i_to IN RECIPIENT_LIST, i_subject IN VARCHAR2,
                    i_message IN VARCHAR2, i_from IN VARCHAR2 DEFAULT NULL)
    RETURN BOOLEAN;

  PROCEDURE log_message (
    log_message IN VARCHAR2, program_name IN VARCHAR2,
    log_type IN VARCHAR2, subprogram_name IN VARCHAR2 DEFAULT NULL,
    param1 IN VARCHAR2 DEFAULT NULL, value1 IN VARCHAR2 DEFAULT NULL,
    param2 IN VARCHAR2 DEFAULT NULL, value2 IN VARCHAR2 DEFAULT NULL,
    param3 IN VARCHAR2 DEFAULT NULL, value3 IN VARCHAR2 DEFAULT NULL,
    param4 IN VARCHAR2 DEFAULT NULL, value4 IN VARCHAR2 DEFAULT NULL,
    param5 IN VARCHAR2 DEFAULT NULL, value5 IN VARCHAR2 DEFAULT NULL,
    param6 IN VARCHAR2 DEFAULT NULL, value6 IN VARCHAR2 DEFAULT NULL,
    param7 IN VARCHAR2 DEFAULT NULL, value7 IN VARCHAR2 DEFAULT NULL,
    param8 IN VARCHAR2 DEFAULT NULL, value8 IN VARCHAR2 DEFAULT NULL,
    param9 IN VARCHAR2 DEFAULT NULL, value9 IN VARCHAR2 DEFAULT NULL
  );

  PROCEDURE purge_log_messages (i_days_old IN NUMBER);

/******************************************************************************/
END dw_util;
/


CREATE OR REPLACE PACKAGE BODY EUL01.dw_util IS
/*******************************************************************************
Author: Rahul Kundavaram
Creation Date: 15-July-2008

Description: This package common utility programs. Programs in this package
             should be generic purpose.

Modification History
====================
DATE         WHO                   WHAT
-----------  -------------         ---------------------
15-July-2008  Rahul Kundavaram     Package created

*******************************************************************************/
-- global constants
  g_program_name   CONSTANT VARCHAR2(20) := 'DW_UTIL';

/******************************************************************************/
FUNCTION get_number (i_value IN VARCHAR2) RETURN NUMBER IS
  v_numeric_value  NUMBER;

BEGIN
  v_numeric_value := to_number(i_value);
  RETURN v_numeric_value;

EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;

END get_number;
/******************************************************************************/
FUNCTION get_date (i_value IN VARCHAR2) RETURN DATE IS
  v_date_value  DATE;

BEGIN
  v_date_value := to_date(i_value);
  RETURN v_date_value;

EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;

END get_date;
/******************************************************************************/
FUNCTION sendmail (i_to IN RECIPIENT_LIST, i_subject IN VARCHAR2,
                   i_message IN VARCHAR2, i_from IN VARCHAR2 DEFAULT NULL)
RETURN BOOLEAN IS

  v_conn          utl_smtp.connection;
  v_host          VARCHAR2(30) := 'smtp02.imagistics.com';
  v_from_addr     VARCHAR2(30) := 'no_reply@imagistics.com';
  v_from_name     VARCHAR2(30) := user;
  v_headers       VARCHAR2(32767);
  v_to            VARCHAR2(100);
  v_footer        VARCHAR2(250) := '<p><hr>This is an automated email sent ' ||
                    'from DWHP Oracle database (' || user || ') on ' ||
                    to_char(SYSDATE, 'DD-MON-YYYY HH:MI AM');

  PROCEDURE send_header(i_name IN VARCHAR2, i_header IN VARCHAR2) AS
  BEGIN
    utl_smtp.write_data(v_conn, i_name || ': ' || i_header || utl_tcp.crlf);
  END;

BEGIN
  IF i_from IS NOT NULL THEN
    v_from_addr := i_from;
    v_from_name := i_from;
  END IF;

  IF (i_to IS NOT NULL) AND (i_to.COUNT > 0) THEN
    FOR i IN i_to.FIRST .. i_to.LAST LOOP
      v_to := i_to(i);

      IF instr(v_to, '@') = 0 THEN
        v_to := v_to || '@Officedepot.com';
      END IF;

      v_conn := utl_smtp.open_connection(v_host);
      utl_smtp.helo(v_conn, v_host);
      utl_smtp.mail(v_conn, v_from_addr);
      utl_smtp.rcpt(v_conn, v_to);
      utl_smtp.open_data(v_conn);
      send_header('MIME-Version', '1.0');
      send_header('Content-type', 'text/html');
      send_header('From', '"' || v_from_name || '" <' || v_from_addr || '>');
      send_header('Subject', i_subject);
      utl_smtp.write_data(v_conn, utl_tcp.crlf || i_message || v_footer);
      utl_smtp.close_data(v_conn);
      utl_smtp.quit(v_conn);
    END LOOP;

    RETURN TRUE;

  ELSE
    dbms_output.put_line('No recipient list is provided');
    RETURN FALSE;

  END IF; -- i_to.COUNT > 0

EXCEPTION
  WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
    BEGIN
      utl_smtp.quit(v_conn);
    EXCEPTION
      WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
        NULL; -- When the SMTP server is down or unavailable, we don't
              -- have a connection to the server. The quit call will raise an
              -- exception that we can ignore.
    END;

    dbms_output.put_line('Sendmail: Email failed due to transient error. ' ||
      sqlerrm(sqlcode));
    RETURN FALSE;

  WHEN OTHERS THEN
    dbms_output.put_line('Sendmail: Email failed. ' || sqlerrm(sqlcode));
    RETURN FALSE;

END sendmail;
/******************************************************************************/
PROCEDURE log_message (
  log_message IN VARCHAR2, program_name IN VARCHAR2,
  log_type IN VARCHAR2, subprogram_name IN VARCHAR2 DEFAULT NULL,
  param1 IN VARCHAR2 DEFAULT NULL, value1 IN VARCHAR2 DEFAULT NULL,
  param2 IN VARCHAR2 DEFAULT NULL, value2 IN VARCHAR2 DEFAULT NULL,
  param3 IN VARCHAR2 DEFAULT NULL, value3 IN VARCHAR2 DEFAULT NULL,
  param4 IN VARCHAR2 DEFAULT NULL, value4 IN VARCHAR2 DEFAULT NULL,
  param5 IN VARCHAR2 DEFAULT NULL, value5 IN VARCHAR2 DEFAULT NULL,
  param6 IN VARCHAR2 DEFAULT NULL, value6 IN VARCHAR2 DEFAULT NULL,
  param7 IN VARCHAR2 DEFAULT NULL, value7 IN VARCHAR2 DEFAULT NULL,
  param8 IN VARCHAR2 DEFAULT NULL, value8 IN VARCHAR2 DEFAULT NULL,
  param9 IN VARCHAR2 DEFAULT NULL, value9 IN VARCHAR2 DEFAULT NULL
) IS

  PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

INSERT INTO dw_program_log (log_id, log_date, log_message, log_type,
  program_name, subprogram_name, param1, value1, param2, value2, param3,
  value3, param4, value4, param5, value5, param6, value6, param7, value7,
  param8, value8, param9, value9)
VALUES (dw_program_log_s.NEXTVAL, SYSDATE, log_message, upper(log_type),
  upper(program_name), upper(subprogram_name), upper(param1), value1,
  upper(param2), value2, upper(param3), value3, upper(param4), value4,
  upper(param5), value5, upper(param6), value6, upper(param7), value7,
  upper(param8), value8, upper(param9), value9);

COMMIT;

END log_message;
/******************************************************************************/
PROCEDURE purge_log_messages (i_days_old IN NUMBER) IS
  v_subprogram_name  VARCHAR2(20) := 'PURGE_LOG_MESSAGES';

BEGIN
  dw_util.log_message (log_message => 'Purging old records...',
    log_type => 'D', program_name => g_program_name,
    subprogram_name => v_subprogram_name, param1 => 'Days Old',
    value1 => i_days_old);

  DELETE dw_program_log
  WHERE  log_date < SYSDATE - i_days_old;

  dw_util.log_message (log_message => 'Purged ' || SQL%ROWCOUNT ||
    ' old records', log_type => 'D', program_name => g_program_name,
    subprogram_name => v_subprogram_name, param1 => 'Days Old',
    value1 => i_days_old);

  COMMIT;

EXCEPTION
WHEN OTHERS THEN
  dw_util.log_message (log_message => sqlerrm(sqlcode), log_type => 'E',
    program_name => g_program_name, subprogram_name => v_subprogram_name,
    param1 => 'Days Old', value1 => i_days_old);
  RAISE;

END purge_log_messages;
/******************************************************************************/
END dw_util;
/


CREATE OR REPLACE PACKAGE EUL01."OE_CTX" AS
   PROCEDURE set_usage_profile ;
END;
/


CREATE OR REPLACE PACKAGE BODY EUL01."OE_CTX" AS
   PROCEDURE set_usage_profile IS
     usageprofile varchar2(25);
   BEGIN
         SELECT sys_context('USERENV', 'session_user') INTO usageprofile FROM dual;
        
         DBMS_SESSION.SET_CONTEXT('USERENV', 'session_user', usageprofile);
         DBMS_SESSION.SET_CONTEXT('USERENV', 'session_user', usageprofile);
   END set_usage_profile;

 END;
/


CREATE OR REPLACE PACKAGE EUL01."SETPARAM" 

AS

From_Date Date;

To_Date Date;

FUNCTION Set_From_Date(p1 IN VARCHAR2) RETURN Date;

FUNCTION Set_To_Date(p2 IN VARCHAR2) RETURN Date;

FUNCTION Get_From_Date RETURN Date;

FUNCTION Get_To_Date RETURN Date;

END;
/


CREATE OR REPLACE PACKAGE BODY EUL01."SETPARAM" AS



FUNCTION Set_From_Date(p1 IN VARCHAR2) RETURN Date IS


BEGIN

From_Date := P1;

RETURN From_Date;

END;

FUNCTION Set_To_Date(p2 IN VARCHAR2) RETURN Date IS

BEGIN

To_Date := P2;

RETURN To_Date;

END;

FUNCTION Get_From_Date RETURN Date IS

BEGIN

RETURN From_Date;

END;

FUNCTION Get_To_Date RETURN Date IS

BEGIN

RETURN To_Date;

END;

END;
/


CREATE OR REPLACE PACKAGE EUL01.Usage_Load_Pkg IS

/*******************************************************************************
Author: Rahul Kundavaram,
Created: 15-JUl-2008

Description: This package is used to load Usage Stage from Ebis

Modification History
====================
Date         Name                 Description
-----------  ---------------      -------------------------------------------------
 15-JUl-2008 Rahul Kundavaram    Initail Createting of the Packeage to move from EBS=>Usage.



/*******************************************************************************/

  PROCEDURE load_Usage_Stage;

END Usage_Load_Pkg ;
/


CREATE OR REPLACE PACKAGE BODY EUL01.Usage_Load_Pkg IS

/*******************************************************************************
Author: Rahul Kundavaram,
Created: 15-JUl-2008

Description: This package is used to load Usage Stage from Ebis

Modification History
====================
Date         Name                 Description
-----------  ---------------      -------------------------------------------------
 15-JUl-2008 Rahul Kundavaram    Initail Creating of the Package to move from EBS=>Usage.

/*******************************************************************************/

-- private procedures and functions

PROCEDURE Initial_Load;
PROCEDURE clean_stage_data;
PROCEDURE unload_usagestg;

/******************************************************************************/


-- global constants and variables


  g_program_name     CONSTANT VARCHAR2(30) := 'LOAD_USAGE_STAGE_PKG';
  g_load_date        CONSTANT DATE := SYSDATE;

/******************************************************************************/

-- Writes a debug message to the log table


PROCEDURE DEBUG (i_subprogram_name IN VARCHAR2, i_message IN VARCHAR2) IS
BEGIN
  Dw_Util.log_message(log_message => i_message, program_name => g_program_name,
    subprogram_name => i_subprogram_name, log_type => 'D',param1 => 'NULL', value1 => NULL);


END DEBUG;
/******************************************************************************/
-- Writes an error message to the log table and sends an email reporting error

PROCEDURE error (i_subprogram_name IN VARCHAR2, i_message IN VARCHAR2) IS
  v_mail_status    BOOLEAN := FALSE;

BEGIN
  -- log the error message
  Dw_Util.log_message(log_message => i_message, program_name => g_program_name,
    subprogram_name => i_subprogram_name, log_type => 'E');

END error;
/******************************************************************************/
PROCEDURE unload_usagestg  IS
  v_subprogram_name    CONSTANT VARCHAR2(20) := 'UNLOAD_USAGE_STAGE';

BEGIN


  DEBUG(v_subprogram_name, 'Truncating Usage Stage...');

  Execute Immediate 'Truncate Table USAGE_STAGE_USAGEDB';

  DEBUG(v_subprogram_name, 'Usage Stage Table Truncated...');
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  error(v_subprogram_name, SQLERRM(SQLCODE));
  RAISE;

END unload_usagestg;
/*******************************************************************************/
PROCEDURE clean_stage_data IS 
  
  v_subprogram_name    CONSTANT VARCHAR2(20) := 'CLEAN_STAGE_DATA';
  val   NUMBER := 0;
  CURSOR cur1 IS
    SELECT A.* 
    FROM usage_stage_usagedb a for update;

  BEGIN
     DEBUG(v_subprogram_name, 'Usage Clean Stage Data Begining');
  FOR main_cur IN cur1 LOOP
    BEGIN
	
	val := main_cur.customer_Id;
	--EXIT WHEN SQL%NOTFOUND;

   EXCEPTION

WHEN OTHERS THEN
INSERT INTO od_ext_usage_err(
  ORDER_ID,
  ORDER_LINE_NUMBER,
  FULLFILLMENT_ID,
  CUSTOMER_ID,
  ACCOUNT_NUMBER,
  CUSTOMER_NAME,
  CUSTOMER_DEPT,
  CUSTOMER_DEPT_DESC,
  PARENT_NAME,
  PARENT_ID,
  PRODUCT_CODE,
  RETAIL_PRICE,
  PRODUCT_DESC,
  WHOLESALE_PRODUCT_CODE,
  CUSTOMER_PRODUCT_CODE,
  EDI_SELL_CODE,
  QUANTITY_SHIPPED,
  QUANTITY,
  CUSTOMER_CURRENCY,
  EXTENDED_PRICE,
  RECONCILED_DATE,
  SHIP_TO_CONTACT_NAME,
  SHIP_TO_CUSTOMER_ID,
  SHIP_TO_CUSTOMER_NAME,
  SHIP_TO_ADDRESS_LINE1,
  SHIP_TO_ADDRESS_LINE2,
  SHIP_TO_CITY,
  SHIP_TO_STATE,
  SHIP_TO_ZIP,
  COUNTRY_CODE,
  BILL_TO_CUSTOMER_ID,
  BILL_TO_CUSTOMER_NAME,
  BILL_TO_ADDRESS_LINE1,
  BILL_TO_ADDRESS_LINE2,
  BILL_TO_CITY,
  BILL_TO_STATE,
  BILL_TO_ZIP,
  ORDER_CREATE_DATE,
  DELIVERY_DATE,
  ORDER_COMPLETED_DATE,
  UNIT_OF_MEASURE,
  CUST_PO_NUMBER,
  ITEM_DEPT_DESC,
  ORDER_NUMBER,
  SUB_ORDER,
  ORDER_NUMBER_FULLFILLMENT,
  SHIP_TO_ID,
  SHIP_TO_KEY,
  OD_SKU,
  SOURCE_SYSTEM_NAME,
  SQL_CODE,
  SQL_ERR_MSG)
  VALUES(
  ltrim(rtrim(main_cur.order_id)),
  ltrim(rtrim(main_cur.order_line_number)),
  ltrim(rtrim(main_cur.fullfillment_id)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.account_number_aops)),
  ltrim(rtrim(main_cur.customer_name)),
  ltrim(rtrim(main_cur.cust_dept_key)),
  ltrim(rtrim(main_cur.customer_dept_desc)),
  ltrim(rtrim(main_cur.parent_name)),
  ltrim(rtrim(main_cur.parent_id)),
  ltrim(rtrim(main_cur.product_code_sku)),
  ltrim(rtrim(main_cur.sku_retail_price)),
  ltrim(rtrim(main_cur.product_desc_sku)),
  ltrim(rtrim(main_cur.wholesale_product_cd)),
  ltrim(rtrim(main_cur.cust_product_cd)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.quantity_shipped)),
  ltrim(rtrim(main_cur.quantity_ordered)),
  ltrim(rtrim(main_cur.customer_currency)),
  ltrim(rtrim(main_cur.extended_price)),
  ltrim(rtrim(main_cur.reconciled_date)),
  ltrim(rtrim(main_cur.customer_ship_to_contact_name)),
  ltrim(rtrim(main_cur.aops_sequence_id)),
  ltrim(rtrim(main_cur.ship_to_customer_name)),
  ltrim(rtrim(main_cur.cust_addr_line_1)),
  ltrim(rtrim(main_cur.cust_addr_line_2)),
  ltrim(rtrim(main_cur.cust_city)),
  ltrim(rtrim(main_cur.cust_state)),
  ltrim(rtrim(main_cur.ship_to_zip)),
  ltrim(rtrim(main_cur.cust_country_cd)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.customer_bill_to_business_name)),
  ltrim(rtrim(main_cur.bill_to_address_line_1)),
  ltrim(rtrim(main_cur.bill_to_address_line_2)),
  ltrim(rtrim(main_cur.bill_to_city)),
  ltrim(rtrim(main_cur.bill_to_state)),
  ltrim(rtrim(main_cur.bill_to_zip)),
  ltrim(rtrim(main_cur.order_create_date)),
  ltrim(rtrim(main_cur.delivery_date)),
  ltrim(rtrim(main_cur.order_completed_date)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.customer_po_number)),
  ltrim(rtrim(main_cur.item_dept_desc)),
  ltrim(rtrim(main_cur.order_number)),
  ltrim(rtrim(main_cur.sub_order)),
  ltrim(rtrim(main_cur.order_number))||'-00'||ltrim(rtrim(main_cur.fullfillment_id)),
  ltrim(rtrim(main_cur.customer_ship_to_id)),
  main_cur.aops_sequence_id||'-'||ltrim(rtrim(main_cur.customer_ship_to_id)),
  main_cur.od_sku,
  'ERR',
  'Filter Validator',
  'Customer ID is non numeric field');
  
  DELETE FROM USAGE_STAGE_USAGEDB WHERE CURRENT OF cur1;

END;
END LOOP;

  
  
  
  
  
  

END clean_stage_data;

/******************************************************************************/
PROCEDURE load_Usage_Stage  IS

  v_subprogram_name   CONSTANT VARCHAR2(30) := 'LOAD_USAGE_STAGE';
  v_mail_status       BOOLEAN := FALSE;

BEGIN


  DEBUG(v_subprogram_name, 'Loading Usage Stage...');

--Truncate the Table

   unload_usagestg;


  -- load the key fields initially
  Initial_Load;

   -- log a success message
  DEBUG(v_subprogram_name, 'Usage Stage Load Completed');

  
  clean_stage_data;
  -- a sucess message
  DEBUG(v_subprogram_name, 'Usage Clean Stage Data Completed');

EXCEPTION
WHEN OTHERS THEN
  error(v_subprogram_name, SQLERRM(SQLCODE));
  RAISE;

END load_Usage_Stage;
/******************************************************************************/
PROCEDURE Initial_Load IS

  v_subprogram_name  CONSTANT VARCHAR2(30) := 'INITIAL_LOAD';

  v_counter          NUMBER := 0;

  BEGIN

  DEBUG(v_subprogram_name, 'Performing Initial Load...');

 INSERT INTO USAGE_STAGE_USAGEDB(customer_name
    ,parent_name
    ,customer_ship_to_contact_name
    ,customer_ship_to_id
    ,cust_addr_line_1
    ,cust_addr_line_2
    ,cust_city
    ,cust_state
    ,cust_country_cd
    ,cust_dept_key
    ,ship_to_customer_name
    ,cust_product_cd
    ,ship_to_zip
    ,customer_currency
    ,customer_dept_desc
    ,account_number_aops
    ,parent_id
    ,item_dept_desc
    ,product_desc_sku
    ,edi_sell_code
    ,order_completed_date
    ,order_line_number
    ,customer_po_number
    ,order_number
    ,sub_order
    ,order_create_date
    ,delivery_date
    ,product_code_sku
    ,reconciled_date
    ,wholesale_product_cd
    ,extended_price
    ,sku_retail_price
    ,quantity_ordered
    ,quantity_shipped
    ,customer_id
    ,bill_to_sequence_nbr_aops
    ,customer_bill_to_business_name
    ,bill_to_address_line_1
    ,bill_to_address_line_2
    ,bill_to_city
    ,bill_to_state
    ,bill_to_zip
    ,order_id
    ,fullfillment_id
    ,aops_sequence_id
    ,od_sku
    ,cust_release_nbr
    ,desktop_loc) Select * From XXCOMN.XX_BI_USAGE_STAGE@GSIDEV02;


  DEBUG (v_subprogram_name, 'Initial Load Completed - ' || SQL%ROWCOUNT ||' Records Inserted.');

  COMMIT;

EXCEPTION
WHEN OTHERS THEN
  error(v_subprogram_name, SQLERRM(SQLCODE));
  RAISE;

END Initial_Load;

/******************************************************************************/

END Usage_Load_Pkg;
/


CREATE OR REPLACE PACKAGE EUL01."USAGE_SECURITY" AS

 FUNCTION Usage_Profile (p_obj_schema  IN VARCHAR2
                        ,p_obj_name    IN VARCHAR2) RETURN VARCHAR2;

END;
/


CREATE OR REPLACE PACKAGE BODY EUL01."USAGE_SECURITY" AS


FUNCTION Usage_Profile ( p_obj_schema  IN VARCHAR2
                        ,p_obj_name    IN VARCHAR2) RETURN VARCHAR2
IS
    D_predicate VARCHAR2 (2000);

    BEGIN


 --       D_predicate := 'LOGINID = NVL(SYS_CONTEXT(''USERENV'', ''CLIENT_IDENTIFIER''),0)';

D_predicate := 'LOGINID = NVL(SYS_CONTEXT(''USERENV'', ''CLIENT_IDENTIFIER''),0)';
--D_predicate := 'LOGINID = NVL(''423721'',0)';
     RETURN D_predicate;


        EXCEPTION
            WHEN OTHERS THEN
                RETURN '1 = 2'; -- Return so that no rows are visible for secuity reason

    END Usage_Profile;

END usage_security;
/


CREATE OR REPLACE PACKAGE EUL01."USAGE_SECURITY_CONTEXT" AS
  FUNCTION EUL_TRIGGER$POST_LOGIN
   RETURN number;
END;
/


CREATE OR REPLACE PACKAGE BODY EUL01."USAGE_SECURITY_CONTEXT" AS
   FUNCTION EUL_TRIGGER$POST_LOGIN
   RETURN number AS
--   Usage_Login_ID Number;

 Usage_Login_ID Varchar2(30);


   BEGIN

      SELECT loginID INTO Usage_login_ID
      FROM eul01.Usage_Profile_Header
      WHERE loginId = SYS_CONTEXT('USERENV','CLIENT_IDENTIFIER');

	  --Usage_login_ID := '423721';
	  

      DBMS_SESSION.SET_CONTEXT('USERENV', 'CLIENT_IDENTIFIER', Usage_Login_ID);
      

      insert into EUL01.TRIG_TAB values(sysdate, usage_login_Id);


Commit;

    END EUL_TRIGGER$POST_LOGIN;
 END;
/


CREATE OR REPLACE PACKAGE EUL01."XMLMANAGER" AUTHID CURRENT_USER
AS
   TYPE profileval IS TABLE OF VARCHAR2 (200);

   FUNCTION getcell (tag VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION returnlist (tag VARCHAR2)
      RETURN profileval;

   PROCEDURE populatexml (xmlstr VARCHAR2);

   xml         XMLTYPE;
   xmldomvar   xmldom.domdocument;
END xmlmanager;
/


CREATE OR REPLACE PACKAGE BODY EUL01."XMLMANAGER" 
AS
  -- xml XMLType;
 
    FUNCTION getCell(tag VARCHAR2) RETURN VARCHAR2  
    IS
      localVal VARCHAR2 (5000);
    BEGIN
    
      IF xml IS NOT NULL THEN 
        IF xml.existsNode('XML_PROFILE/HEADER/LOGINID') > 0 THEN
          localVal := xml.EXTRACT((tag || '/text()')).getStringVal;
          IF localVal IS NOT NULL THEN 
            RETURN localVal;
          END IF;
        END IF;  
      END IF;
      RETURN '';  
    END getCell;
    
    
    FUNCTION returnList(tag VARCHAR2) RETURN ProfileVal
    IS
      localVal VARCHAR2(7) := 'empty';
	  attribute_name VarChar2(30) := 'none';
      tempVal ProfileVal; 
      nl xmldom.DOMNodeList;
      nl2 xmldom.DOMNodeList;
      n xmldom.DOMNode;
      nc xmldom.DOMNode;
	  att xmldom.DOMNamedNodeMap;
	  node xmldom.DOMNode;
	  num_attributes NUMBER;
      counter NUMBER;
     
	  BEGIN  
        nl  := xmldom.getElementsByTagName(xmlDomVar,tag);
        nc  := dbms_xmldom.item(nl,0); 
	    att := xmldom.getAttributes(nc);
		IF (xmldom.isNull(att) = FALSE) THEN
          num_attributes := xmldom.getLength(att);
          FOR i IN 0..num_attributes-1 LOOP
            node := xmldom.item(att, i);
            attribute_name := xmldom.getNodeName(node);
			IF attribute_name = 'type' THEN
			  attribute_name := xmldom.getNodeValue(node);
			  IF attribute_name = 'all' THEN
				RETURN ProfileVal('*ALL*ALL*');
			  END IF;
			END IF;
          END LOOP;
		END IF;
	  
        nl2 := xmldom.getchildNodes(nc);
        FOR i IN 1..dbms_xmldom.getlength(nl2) LOOP
          nc := dbms_xmldom.item(nl2,i-1);
          nl := xmldom.getchildNodes(nc); 
          n  := dbms_xmldom.item(nl,0);
          IF localVal = 'empty' THEN
		    tempVal := ProfileVal(XMLDOM.getNodeValue(n));
            localVal := 'full';
          ELSE
            tempVal.EXTEND;
            tempVal(tempVal.LAST) := XMLDOM.getNodeValue(n);
          END IF;  
        END LOOP;
        RETURN tempVal;
      END returnList;
    
    
    PROCEDURE PopulateXML(xmlStr VARCHAR2)  
    IS
    
    BEGIN
      IF xmlStr IS NOT NULL THEN
         xml := XMLTYPE.CreateXML(xmlStr);
         xmlDomVar := XMLDOM.NEWDOMDOCUMENT(xmlStr);
      END IF;
    END PopulateXML;
   
    
    
    
    
    
END XMLMANAGER;
/


CREATE OR REPLACE PACKAGE EUL01."XXOD_USAGE_LOV" AS
  TYPE numset_t IS TABLE OF varchar2(100);
  FUNCTION Usage_Ship_To_Lov RETURN numset_t PIPELINED;
  FUNCTION Usage_PO_Lov RETURN numset_t PIPELINED;
  FUNCTION Usage_CC_Lov RETURN numset_t PIPELINED;
END XXOD_Usage_Lov;
/


CREATE OR REPLACE PACKAGE BODY EUL01."XXOD_USAGE_LOV" AS

/**************************************************************************************************/


-- FUNCTION Usage_Ship_To_Lov returns a collection of Ship To's for the customer


FUNCTION Usage_Ship_To_Lov RETURN numset_t PIPELINED IS

Cursor Cur_profile_Shipto is
  Select value
  From     Usage_profile_Header h
    ,      Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And    h.usage_profile_header_id = 5521
  And   d.type = 'ST';

Cursor Cur_profile_LOV is
  SelecT lov_description
  From   USAGE_LOV lov
    ,  Usage_profile_Header h
  Where h.billto = lov.account_number
--  And   h.usage_profile_header_id = 5521
  And   lov.lov_type = 'ST';



p_value VARCHAR2(100);


  BEGIN

  Select value Into p_value
  From   Usage_profile_Header h
    ,    Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 5521
  And   d.type = 'ST'
  And   rownum < 2;

If p_Value = '*ALL*ALL*' Then

  For I in Cur_profile_lov Loop

      PIPE row(I.lov_description);
      END LooP;
Else

  For I in Cur_profile_shipto Loop


      PIPE row(I.value);
      END LooP;

END IF;
RETURN;
  END;


/**************************************************************************************************/
-- FUNCTION Usage_PO_Lov returns a collection of PO's for the customer

FUNCTION Usage_PO_Lov RETURN numset_t PIPELINED IS

Cursor Cur_profile_PO is
  Select value
  From   Usage_profile_Header h
    ,      Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
 -- And   h.usage_profile_header_id = 3401
  And   d.type = 'PO';

Cursor Cur_profile_LOV is
  SelecT lov_description
  From   USAGE_LOV lov
    ,  Usage_profile_Header h
  Where h.billto = lov.account_number
 -- And   h.usage_profile_header_id = 3401
  And   lov.lov_type = 'PO';

p_value VARCHAR2(100);


  BEGIN

  Select value Into p_value
  From   Usage_profile_Header h
    ,      Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 3401
  And   d.type = 'PO'
  And   rownum < 2;

If p_Value = '*ALL*ALL*' Then

  For I in Cur_profile_LOV Loop

      PIPE row(I.lov_description);
      END LooP;
Else

  For I in Cur_profile_PO Loop


      PIPE row(I.value);
      END LooP;

END IF;
RETURN;
  END;
/**************************************************************************************************/

-- FUNCTION Usage_CC_Lov returns a collection of CC's for the customer

FUNCTION Usage_CC_Lov RETURN numset_t PIPELINED IS

Cursor Cur_Profile_CC is
  Select value
  From   Usage_profile_Header h
    ,      Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 3401
  And   d.type = 'CC';

Cursor Cur_profile_LOV is
  SelecT lov_description
  From   USAGE_LOV lov
    ,  Usage_profile_Header h
  Where h.billto = lov.account_number
 -- And   h.usage_profile_header_id = 3401
  And   lov.lov_type = 'CC';

p_value VARCHAR2(100);


  BEGIN

  Select value Into p_value
  From   Usage_profile_Header h
    ,      Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 3401
  And   d.type = 'CC'
  And   rownum < 2;

If p_Value = '*ALL*ALL*' Then

  For I in Cur_profile_LOV Loop

      PIPE row(I.lov_description);
      END LooP;
Else

  For I in Cur_profile_cc Loop

      PIPE row(I.value);
      END LooP;

END IF;
RETURN;
  END;
/**************************************************************************************************/


END XXOD_Usage_Lov;
/


CREATE OR REPLACE PACKAGE EUL01.XXOD_Usage_Lov_Values AS

/*******************************************************************************
Author: Rahul Kundavaram,
Created: 15-JUl-2008

Description: This package is used to load Usage Stage from Ebis

Modification History
====================
Date             Version       Name                      Description
-----------      -------       ---------------           -------------------------------------------------
15-JUl-2008       1            Rahul Kundavaram          Initail Creating of the Package For Populating Lov Values

/*******************************************************************************/

  TYPE numset_t IS TABLE OF varchar2(100);


  FUNCTION Usage_Ship_To_Lov RETURN numset_t PIPELINED;


  FUNCTION Usage_PO_Lov RETURN numset_t PIPELINED;


  FUNCTION Usage_CC_Lov RETURN numset_t PIPELINED;


END XXOD_Usage_Lov_Values;

/************************************************************************************************/
/


CREATE OR REPLACE PACKAGE BODY EUL01.XXOD_Usage_Lov_Values AS


/*******************************************************************************
Author: Rahul Kundavaram,
Created: 15-JUl-2008

Description: This package is used to Retrieve the LOV's for the User Logged in, we retrieve the LOV's either from the
             Profile Details table if the user is supposed to see only a subet of PO'S,SHIP-TO's or Cost Centers or from the
             Lov table if the user is autorized to see all of them.

Modification History
====================
Date             Version       Name                      Description
-----------      -------       ---------------           -------------------------------------------------
15-JUl-2008       1            Rahul Kundavaram          Initail Creating of the Package For Populating Lov Values.
06-Aug-2008       2            Rahul Kundavaram          Changes to PO and CC lov functions to get soft label information.

/*******************************************************************************/


-- FUNCTION Usage_Ship_To_Lov returns a collection of Ship To's for the customer


FUNCTION Usage_Ship_To_Lov RETURN numset_t PIPELINED IS

Cursor Cur_profile_Shipto is
  Select Distinct Short_Name
  From     Usage_profile_Header h
    ,      Usage_Profile_Detail d
    ,      Usage_Lov lov
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 12082
  And   h.billto = lov.account_number
  And   d.type = 'ST';

Cursor Cur_profile_LOV is
  SelecT Distinct Short_Name
  From   USAGE_LOV lov
    ,  Usage_profile_Header h
  Where h.billto = lov.account_number
--  And   h.usage_profile_header_id = 12082
  And   lov.lov_type = 'ST';



p_value VARCHAR2(100):= Null;


BEGIN

  Select value Into p_value
  From   Usage_profile_Header h
    ,    Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 12082
  And   d.type = 'ST'
  And   rownum < 2;

If p_Value = '*ALL*ALL*' Then

  For I in Cur_profile_lov Loop

      PIPE row(I.short_name);
      END LooP;
Else

  For I in Cur_profile_shipto Loop


      PIPE row(I.short_name);
      END LooP;

END IF;
RETURN;
  END;


/**************************************************************************************************/
-- FUNCTION Usage_PO_Lov returns a collection of PO's for the customer

FUNCTION Usage_PO_Lov RETURN numset_t PIPELINED IS

Cursor Cur_profile_PO is
  Select Distinct value
  From   Usage_profile_Header h
    ,      Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 12082
  And   d.type = 'PO';

Cursor Cur_profile_LOV is
  SelecT Distinct lov_description
  From   USAGE_LOV lov
    ,  Usage_profile_Header h
  Where h.billto = lov.account_number
--  And   h.usage_profile_header_id = 12082
  And   lov.lov_type = 'PO';

p_value VARCHAR2(100):= Null;
p_lov_value VARCHAR2(100):= Null;


  BEGIN

  Select value Into p_value
  From   Usage_profile_Header h
    ,      Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 12082
  And   d.type = 'PO'
  And   rownum < 2;

  Select Nvl(cust_po_nbr_label,'PO Number') INTO p_lov_value
  From Usage_labels l
  ,    Usage_profile_Header h
  Where l.customer_id = h.billto;
--  And   h.usage_profile_header_id = 12082;

If p_Value = '*ALL*ALL*' Then

  For I in Cur_profile_LOV Loop

      PIPE row(p_lov_value ||' - '|| I.lov_description);
      END LooP;
Else

  For I in Cur_profile_PO Loop


      PIPE row(p_lov_value ||' - '|| I.value);
      END LooP;

END IF;
RETURN;
  END;
/**************************************************************************************************/

-- FUNCTION Usage_CC_Lov returns a collection of CC's for the customer

FUNCTION Usage_CC_Lov RETURN numset_t PIPELINED IS

Cursor Cur_Profile_CC is
  Select Distinct value
  From   Usage_profile_Header h
    ,      Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 12082
  And   d.type = 'CC';

Cursor Cur_profile_LOV is
  SelecT Distinct lov_description
  From   USAGE_LOV lov
    ,  Usage_profile_Header h
  Where h.billto = lov.account_number
--  And   h.usage_profile_header_id = 12082
  And   lov.lov_type = 'CC';

p_value VARCHAR2(100):=Null;
p_lov_value VARCHAR2(100):= Null;


  BEGIN

  Select value Into p_value
  From   Usage_profile_Header h
    ,      Usage_Profile_Detail d
  Where h.usage_profile_header_id = d.usage_profile_header_id
--  And   h.usage_profile_header_id = 12082
  And   d.type = 'CC'
  And   rownum < 2;

  Select Nvl(cust_dept_label,'Cost Center') INTO p_lov_value
  From Usage_labels l
  ,    Usage_profile_Header h
  Where l.customer_id = h.billto;
--  And   h.usage_profile_header_id = 12082;

If p_Value = '*ALL*ALL*' Then

  For I in Cur_profile_LOV Loop

      PIPE row(p_lov_value ||' - '|| I.lov_description);
      END LooP;
Else

  For I in Cur_profile_cc Loop

      PIPE row(p_lov_value ||' - '|| I.value);
      END LooP;

END IF;
RETURN;
  END;
/**************************************************************************************************/


END XXOD_Usage_Lov_Values;
/


CREATE OR REPLACE PACKAGE EUL01."XX_USAGE_DATA_LOAD" AS
--***************************************************************************************
-- Package: xx_usage_data_load.pks
--
-- Created: 10/3/2007
-- Author: Van Neel, Office Depot
-- Notes:
-- Revisions:
--
-- Purpose:  This package is designed to take data devliered in the form of a flat file
-- on an interim basis (per day, TBD) and load it into the Usage Database (Oracle)
-- for Office Depot to display usage data via the Oracle Discovery Toolset.
--
--****************************************************************************************
--
Procedure initial_data_load (retcode OUT NUMBER, errbuf OUT VARCHAR2);
--
Procedure incremental_data_load (retcode OUT NUMBER, errbuf OUT VARCHAR2);
--
--- Third procedure to clean up table?
--
END xx_usage_data_load;
/


DROP SEQUENCE EUL01.DW_PROGRAM_LOG_S;

CREATE SEQUENCE EUL01.DW_PROGRAM_LOG_S
  START WITH 341
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;



DROP SEQUENCE EUL01.USAGE_PROFILE;

CREATE SEQUENCE EUL01.USAGE_PROFILE
  START WITH 23741
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;


GRANT SELECT ON  EUL01.USAGE_PROFILE TO EUL01_SELECT;


DROP SEQUENCE EUL01.USAGE_PROFILE_DETAIL_ID;

CREATE SEQUENCE EUL01.USAGE_PROFILE_DETAIL_ID
  START WITH 61941
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;


GRANT SELECT ON  EUL01.USAGE_PROFILE_DETAIL_ID TO EUL01_SELECT;


DROP SEQUENCE EUL01.XX_USAGE_SEQ;

CREATE SEQUENCE EUL01.XX_USAGE_SEQ
  START WITH 83959
  MAXVALUE 999999999999999999999999999
  MINVALUE 0
  NOCYCLE
  NOCACHE
  NOORDER;


GRANT SELECT ON  EUL01.XX_USAGE_SEQ TO EUL01_SELECT;


