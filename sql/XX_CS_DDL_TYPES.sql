
REM APPS XX_CS_CHANNEL_TBL

  CREATE OR REPLACE TYPE "APPS"."XX_CS_CHANNEL_TBL" AS TABLE OF VARCHAR2(100)
/

 
REM APPS XX_CS_PROBLECODE_REC_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_PROBLECODE_REC_TYPE" AS OBJECT (
PROBLEM_CODE     VARCHAR2(200),
PROBLEM_DESCR    VARCHAR2(500) );
/

 
REM APPS XX_CS_PROBLEMCODE_TBL_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_PROBLEMCODE_TBL_TYPE" AS TABLE OF XX_CS_PROBLECODE_REC_TYPE;
/

 
REM APPS XX_CS_REQUEST_REC_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_REQUEST_REC_TYPE" AS OBJECT (
REQUEST_ID       NUMBER,
REQUEST_TYPE     VARCHAR2(200) );
/

 
REM APPS XX_CS_REQUEST_TBL_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_REQUEST_TBL_TYPE" AS TABLE OF XX_CS_REQUEST_REC_TYPE;
/

 
REM APPS XX_CS_REQ_PRO_REC_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_REQ_PRO_REC_TYPE" AS OBJECT (
REQUEST_ID       NUMBER,
REQUEST_TYPE     VARCHAR2(200),
PROBLEM_CODE     VARCHAR2(200),
PROBLEM_DESCR    VARCHAR2(500));
/

 
REM APPS XX_CS_REQ_PRO_TBL_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_REQ_PRO_TBL_TYPE" AS TABLE OF XX_CS_REQ_PRO_REC_TYPE;
/

 
REM APPS XX_CS_RESOURCE_REC_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_RESOURCE_REC_TYPE" AS OBJECT (
      SERVICE_REQUEST_ID             NUMBER ,
      PARTY_ID                       NUMBER ,
      COUNTRY                        VARCHAR2(60) ,
      PARTY_SITE_ID                  NUMBER       ,
      CITY                           VARCHAR2(60)  ,
      POSTAL_CODE                    VARCHAR2(60)  ,
      STATE                          VARCHAR2(60)  ,
      AREA_CODE                      VARCHAR2(10)  ,
      COUNTY                         VARCHAR2(60)  ,
      COMP_NAME_RANGE                VARCHAR2(360) ,
      PROVINCE                       VARCHAR2(60)  ,
      NUM_OF_EMPLOYEES               NUMBER        ,
      INCIDENT_TYPE_ID               NUMBER        ,
      INCIDENT_SEVERITY_ID           NUMBER        ,
      INCIDENT_URGENCY_ID            NUMBER        ,
      PROBLEM_CODE                   VARCHAR2(60)  ,
      INCIDENT_STATUS_ID             NUMBER        ,
      PLATFORM_ID                    NUMBER        ,
      SUPPORT_SITE_ID                NUMBER        ,
      CUSTOMER_SITE_ID               NUMBER        ,
      SR_CREATION_CHANNEL            VARCHAR2(150) ,
      INVENTORY_ITEM_ID              NUMBER        ,
      ATTRIBUTE1                     VARCHAR2(150) ,
      ATTRIBUTE2                     VARCHAR2(150) ,
      ATTRIBUTE3                     VARCHAR2(150) ,
      ATTRIBUTE4                     VARCHAR2(150) ,
      ATTRIBUTE5                     VARCHAR2(150) ,
      ATTRIBUTE6                     VARCHAR2(150) ,
      ATTRIBUTE7                     VARCHAR2(150) ,
      ATTRIBUTE8                     VARCHAR2(150) ,
      ATTRIBUTE9                     VARCHAR2(150) ,
      ATTRIBUTE10                    VARCHAR2(150) ,
      ATTRIBUTE11                    VARCHAR2(150) ,
      ATTRIBUTE12                    VARCHAR2(150) ,
      ATTRIBUTE13                    VARCHAR2(150) ,
      ATTRIBUTE14                    VARCHAR2(150) ,
      ATTRIBUTE15                    VARCHAR2(150) ,
      ORGANIZATION_ID                NUMBER        ,
      SR_PL_INV_ITEM_ID              NUMBER        ,
      SR_PL_ORG_ID                   NUMBER        ,
      SR_CAT_ID                      NUMBER        ,
      SR_PROD_INV_ITEM_ID            NUMBER        ,
      SR_PROD_ORG_ID                 NUMBER        ,
      SR_PROD_COMP_ID                NUMBER        ,
      SR_PROD_SUBCOMP_ID             NUMBER        ,
      GRP_OWNER                      NUMBER        ,
      SUP_INV_ITEM_ID                NUMBER        ,
      SUP_ORG_ID                     NUMBER        ,
      VIP_CUST                       VARCHAR2(360) ,
      SR_PRBLM_CODE                  VARCHAR2(360) ,
      CONT_PREF                      VARCHAR2(360) ,
      CONTRACT_COV                   VARCHAR2(360) ,
      SR_LANG                        VARCHAR2(360) ,
      ORD_LINE_TYPE                  VARCHAR2(360) ,
      VENDOR_ID                      NUMBER        ,
      WAREHOUSE_ID                   NUMBER        ,
      CUST_GEO_VS_ID                 NUMBER         );
/

 
REM APPS XX_CS_SR_CREATE_OUT_REC_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_SR_CREATE_OUT_REC_TYPE" AS OBJECT (
  request_id   NUMBER,
  request_number  VARCHAR2(64),
  interaction_id  NUMBER,
  workflow_process_id  NUMBER,
  individual_owner  NUMBER,
  group_owner   NUMBER,
  individual_type  VARCHAR2(30),
  auto_task_gen_status  VARCHAR2(3),
  contract_service_id  NUMBER,
  resolve_by_date  DATE,
  respond_by_date  DATE,
  resolved_on_date  DATE,
  responded_on_date  DATE
  );
/

 
REM APPS XX_CS_SR_NOTES_REC

  CREATE OR REPLACE TYPE "APPS"."XX_CS_SR_NOTES_REC" AS OBJECT (
NOTES         VARCHAR2(1000),
NOTE_DETAILS  VARCHAR2(2000),
CREATION_DATE DATE,
CREATED_BY    VARCHAR2(100));


/

 
REM APPS XX_CS_SR_NOTES_TBL

  CREATE OR REPLACE TYPE "APPS"."XX_CS_SR_NOTES_TBL" AS TABLE OF XX_CS_SR_NOTES_REC
/

 
REM APPS XX_CS_SR_ORDER_REC_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_SR_ORDER_REC_TYPE" AS OBJECT
(
order_number              VARCHAR2(100),
order_sub                 varchar2(100),
sku_id                    varchar2(100),
Sku_description           varchar2(1000),
quantity                  number,
Manufacturer_info         varchar2(250),
order_link                varchar2(4000),
attribute1                varchar2(1000),
attribute2                varchar2(1000),
attribute3                varchar2(1000),
attribute4                varchar2(1000),
attribute5               varchar2(1000)
);
/

 
REM APPS XX_CS_SR_ORDER_TBL

  CREATE OR REPLACE TYPE "APPS"."XX_CS_SR_ORDER_TBL" AS TABLE OF XX_CS_SR_ORDER_REC_TYPE
/

 
REM APPS XX_CS_SR_REC_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_SR_REC_TYPE" AS OBJECT (
  request_date                          DATE,
  request_id                            NUMBER,
  request_number                        NUMBER,
  type_id                               NUMBER,
  type_name                             VARCHAR2(30),
  status_name                           VARCHAR2(30),
  owner_id                              NUMBER,
  owner_group_id                        NUMBER,
  description                           VARCHAR2(240),
  caller_type                           VARCHAR2(30),
  customer_id                           NUMBER,
  customer_sku_id                       VARCHAR2(100),
  user_id                               VARCHAR2(100),
  language                              VARCHAR2(4),
  problem_code                          VARCHAR2(50),
  resolution_code                       VARCHAR2(50),
  exp_resolution_date                   DATE,
  act_resolution_date                   DATE,
  channel                               VARCHAR2(100),
  contact_name                          VARCHAR2(100),
  contact_phone                         VARCHAR2(50),
  contact_email                         VARCHAR2(100),
  contact_fax                           VARCHAR2(50),
  comments                              VARCHAR2(1000),
  order_number                          VARCHAR2(100),
  customer_number                       NUMBER,
  ship_date                             date,
  account_mgr_email                     varchar2(500),
  sales_rep_contact                     varchar2(250),
  sales_rep_contact_phone               varchar2(25),
  sales_rep_contract_email              varchar2(50),
  amazon_po_number                      number,
  warehouse_id                          number,
  global_ticket_flag                    varchar2(1));
/

 
REM APPS XX_CS_SR_STATUS_REC

  CREATE OR REPLACE TYPE "APPS"."XX_CS_SR_STATUS_REC" AS OBJECT ( STATUS VARCHAR2(50), STATUS_ID NUMBER )
/

 
REM APPS XX_CS_SR_STATUS_TBL

  CREATE OR REPLACE TYPE "APPS"."XX_CS_SR_STATUS_TBL" AS TABLE OF XX_CS_SR_STATUS_REC
/

 
REM APPS XX_CS_SR_TBL_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_CS_SR_TBL_TYPE" AS TABLE OF XX_CS_SR_REC_TYPE
/

 
REM APPS XX_GLB_SITEKEY_REC_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_GLB_SITEKEY_REC_TYPE" AS OBJECT (
      locale       VARCHAR2(40)
    , brand        VARCHAR2(40)   -- OD, VIKING, TECH DEPOT
    , site_mode    VARCHAR2(40)   -- BUSINESS, CONSUMER
);
/

 
REM APPS XX_GLB_SITEKEY_TBL_TYPE

  CREATE OR REPLACE TYPE "APPS"."XX_GLB_SITEKEY_TBL_TYPE" AS TABLE OF XX_GLB_SITEKEY_REC_TYPE;
/

 