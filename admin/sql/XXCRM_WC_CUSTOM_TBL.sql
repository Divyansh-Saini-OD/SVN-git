SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE TABLE xxcrm.xxcrm_custmast_head_int ( 
Customer_Number VARCHAR2(30)
,Organization_Number VARCHAR2(30)
,Customer_Number_AOPS VARCHAR2(200)
,Customer_Name VARCHAR2(20)
,Status VARCHAR2(2)
,Customer_Type VARCHAR2(30)
,Customer_Class_Code VARCHAR2(30)
,Sales_Channel_Code VARCHAR2(30)
,SIC_Code VARCHAR2(20)
,cust_Category_Code VARCHAR2(20)
,DUNS_Number NUMBER
,SIC_Code_Type VARCHAR2(30)
,Collector_ID NUMBER
,Collector_Name VARCHAR2(30)
,Credit_Checking VARCHAR2(20)
,Credit_Rating VARCHAR2(20)
,Account_Established_Date DATE
,Account_Credit_Limit_USD VARCHAR2(20)
,Account_Credit_Limit_CAD  VARCHAR2(20)
,Order_credit_Limit_USD NUMBER
,Order_credit_Limit_CAD NUMBER
,Credit_Classification VARCHAR2(20)
,Exposure_Analysis_Segment VARCHAR2(20)
,Risk_Code VARCHAR2(20)
,Source_of_Creation_for_Credit VARCHAR2(60)
,po_value varchar2(60)
,po varchar2(60)
,release_value varchar2(60)
,release varchar2(60)
,cost_center_value varchar2(60)
,cost_center varchar2(60)
,desktop_value varchar2(60)
,desktop varchar2(60)
,LAST_UPDATED_BY             NUMBER(15) NOT NULL
,CREATION_DATE               DATE       NOT NULL
,LAST_UPDATE_LOGIN           NUMBER(15) 
,REQUEST_ID                  NUMBER(15)     
,PROGRAM_APPLICATION_ID      NUMBER(15)     
,CREATED_BY                  NUMBER(15) NOT NULL
,LAST_UPDATE_DATE            DATE   NOT NULL
,PROGRAM_ID                  NUMBER(15)
 );

CREATE TABLE xxcrm.xx_cdhar_int_log
(program_name varchar2(240)
,module_name  varchar2(240)
,Program_run_date date
,filename varchar2(100)
,Total_records NUMBER
,status varchar2(10)
,message VARCHAR2(20) );

create table xxcrm.xxcrm_wcelg_cust (
PARTY_ID                        NUMBER(15)   ,
CUST_ACCOUNT_ID                 NUMBER(15)   NOT NULL,
ACCOUNT_NUMBER                  VARCHAR2(30) ,
SITE_USE_ID                     NUMBER(15)   ,
INT_SOURCE                      VARCHAR2(15) ,
ORIG_EXTRACTION_DATE            DATE         ,
LAST_EXTRACTION_DATE            DATE         ,
MASTER_DATA_EXTRACTED           VARCHAR2(1)  ,
TRANS_DATA_EXTRACTED            VARCHAR2(1)  ,
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE         );


create table xxcrm.xxar_adjustment_delta 
(adjustment_id  number(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_contpoint_delta 
(contact_point_id  number(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_cust_acct_sites_delta 
(cust_acct_site_id  number(15),
cust_account_id    number(15),
party_site_id      number(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_cust_profile_amts_delta (
cust_acct_profile_amt_id   number(15),
cust_account_profile_id    number(15),
currency_code               varchar2(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_cust_site_uses_delta (
site_use_id   number(15),
cust_acct_site_id    number(15),
site_use_code               varchar2(15),
orig_system_reference       varchar2(60),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_CUSTOMER_PROFILES_delta (
cust_account_profile_id    number(15),
cust_account_id number(15),
party_id        number(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );


create table xxcrm.xxcrm_org_contacts_delta (
org_contact_id    number(15),
party_relationship_id number(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_party_sites_delta ( 
party_site_id   number(15),
party_id        number(15),
location_id     number(15),
party_site_number varchar2(60),
orig_system_reference varchar2(60),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_rs_group_members_delta ( 
group_member_id  number(15),
group_id        number(15),
resource_id     number(15),
person_id      number(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_rs_resource_extns (
resource_id number(15),
person_party_id number(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_TM_NAM_DTLS_delta ( 
named_acct_terr_entity_id  number(15),
named_acct_terr_id        number(15),
entity_type      varchar2(60),
entity_id      number(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

create table xxcrm.xxcrm_party_delta 
(party_id                       number(15),
LAST_UPDATE_DATE                DATE         NOT NULL,
LAST_UPDATED_BY                 NUMBER(15)   NOT NULL,
CREATION_DATE                   DATE         NOT NULL,
CREATED_BY                      NUMBER(15)   NOT NULL,
LAST_UPDATE_LOGIN               NUMBER(15)   ,
REQUEST_ID                      NUMBER(15)   ,
PROGRAM_APPLICATION_ID          NUMBER(15)   ,
PROGRAM_ID                      NUMBER(15)   ,
PROGRAM_UPDATE_DATE             DATE          );

CREATE TABLE xxcrm.xxcrm_cust_accounts_delta
  (
    party_id        NUMBER(15),
    cust_account_id NUMBER(15),
    LAST_UPDATE_DATE DATE NOT NULL,
    LAST_UPDATED_BY NUMBER(15) NOT NULL,
    CREATION_DATE DATE NOT NULL,
    CREATED_BY             NUMBER(15) NOT NULL,
    LAST_UPDATE_LOGIN      NUMBER(15) ,
    REQUEST_ID             NUMBER(15) ,
    PROGRAM_APPLICATION_ID NUMBER(15) ,
    PROGRAM_ID             NUMBER(15) ,
    PROGRAM_UPDATE_DATE DATE
  );

grant all on   xxcrm.xxcrm_custmast_head_int  TO APPS WITH grant option;
grant all on   xxcrm.xx_cdhar_int_log  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_wcelg_cust  TO APPS WITH grant option;
grant all on   xxcrm.xxar_adjustment_delta  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_contpoint_delta  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_cust_acct_sites_delta  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_cust_profile_amts_delta  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_cust_site_uses_delta  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_CUSTOMER_PROFILES_delta  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_org_contacts_delta   TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_party_sites_delta  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_rs_group_members_delta  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_rs_resource_extns  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_TM_NAM_DTLS_delta  TO APPS WITH grant option;
grant all on   xxcrm.xxcrm_party_delta  TO APPS WITH grant option;
GRANT ALL ON xxcrm.xxcrm_cust_accounts_delta TO APPS WITH GRANT OPTION;
