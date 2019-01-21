BEGIN

------------------------------------------------------------------------------------

create or replace
TYPE XX_ORDER_DET_OBJ AS OBJECT
(
  OrderNumber                   NUMBER,
  OrderTotal                    VARCHAR2(100),
  ShipToRef                     VARCHAR2(100),
  SalesRepId                    NUMBER,
  OrderedDate                   VARCHAR2(100)
);


create or replace TYPE XX_ORDER_DET_OBJ_TBL AS TABLE OF XX_ORDER_DET_OBJ;


-------------------------------------------------------------------------------------

create or replace TYPE XX_CASE_DET_OBJ AS OBJECT
(
 IncidentNumber  VARCHAR2(100),
  PartyName       VARCHAR2(300),
  Description     VARCHAR2(2000),
  IncidentDate    VARCHAR2(100),
  CloseDate       VARCHAR2(100),
  ResolvedDate    VARCHAR2(100),
  Status          VARCHAR2(100),
  CSR             VARCHAR2(100),
  Sumary          VARCHAR2(1500),
  Creator         VARCHAR2(100),
  DataSource      VARCHAR2(100),
  FetchTime       VARCHAR2(100)
);


create or replace
TYPE XX_CASE_DET_OBJ_TBL AS TABLE OF XX_CASE_DET_OBJ;

-------------------------------------------------------------------------------------

create or replace TYPE XX_PRICE_DET_OBJ AS OBJECT
(
  ProductCode           VARCHAR2(100),
  ProductName           VARCHAR2(300),
  SkuPrice              VARCHAR2(100),
  ContractId            VARCHAR2(100),
  AddressSeq            VARCHAR2(100),
  DataSource            VARCHAR2(100),
  fetchTime             VARCHAR2(100)
);

create or replace
TYPE XX_PRICE_DET_OBJ_TBL AS TABLE OF XX_PRICE_DET_OBJ;

--------------------------------------------------------------------------------------

create or replace TYPE XX_LOY_DET_OBJ AS OBJECT
(
  wlrorderdt       VARCHAR2(100),
  wlrorderid       VARCHAR2(100),
  wlrpuramt        VARCHAR2(100),
  wlrcatrwd        VARCHAR2(100)
);

create or replace
TYPE XX_LOY_DET_OBJ_TBL AS TABLE OF XX_LOY_DET_OBJ;

--------------------------------------------------------------------------------------

create or replace TYPE XX_FIN_PARENT_OBJ AS OBJECT
(
  CustAccountId                 VARCHAR2(100),
  AccountName                   VARCHAR2(500),
  Status                        VARCHAR2(100)
);

create or replace TYPE XX_FIN_PARENT_OBJ_TBL AS TABLE OF XX_FIN_PARENT_OBJ;


---------------------------------------------------------------------------------------


create or replace TYPE XX_FIN_CHILD_OBJ AS OBJECT
(
  CustAccountId                 VARCHAR2(100),
  AccountName                   VARCHAR2(500),
  Status                        VARCHAR2(100)
);

create or replace TYPE XX_FIN_CHILD_OBJ_TBL AS TABLE OF XX_FIN_CHILD_OBJ;

----------------------------------------------------------------------------------------

create or replace TYPE XX_EMAIL_CAMP_OBJ AS OBJECT
(
  OrgPartyNum                   VARCHAR2(100),
  CustTypeCode                  VARCHAR2(50),
  OrgName                       VARCHAR2(300),
  PersonPartyNum                VARCHAR2(100),
  FirstName                     VARCHAR2(100),
  LastName                      VARCHAR2(100),
  EmailAdd                      VARCHAR2(100),
  EmailCampDt                   VARCHAR2(100),
  EmailCampSegCode              VARCHAR2(50),
  EmailCampZoneCode             VARCHAR2(50),
  TelCountryCd                  VARCHAR2(50),
  TelAreaCd                     VARCHAR2(50),
  TelNum                        VARCHAR2(50),
  Msg                           VARCHAR2(200)
);


create or replace TYPE XX_EMAIL_CAMP_OBJ_TBL AS TABLE OF XX_EMAIL_CAMP_OBJ;

----------------------------------------------------------------------------------------

create or replace TYPE XX_BACK_ORDER_OBJ AS OBJECT
(
  OrderId                   VARCHAR2(100),
  TotalOrderAmt             VARCHAR2(50),
  BackOrderQty              VARCHAR2(300),
  ItemId                    VARCHAR2(100),
  UnitListPriceAmt          VARCHAR2(100),
  UnitOriginalPriceAmt      VARCHAR2(100),
  UnitPoCostAmt             VARCHAR2(100),
  UnitSellingPriceAmt       VARCHAR2(100)
);


create or replace TYPE XX_BACK_ORDER_OBJ_TBL AS TABLE OF XX_BACK_ORDER_OBJ;

----------------------------------------------------------------------------------------

create or replace TYPE XX_BILLING_INFO_OBJ AS OBJECT
(
  REPORTING_LOC                 VARCHAR2(100),
  SALESPERSON_ID                VARCHAR2(50),
  AR_FLAG                       VARCHAR2(300),
  BILL_TO_LIMIT                 VARCHAR2(100),
  BILL_TO_DOLLARS               VARCHAR2(100),
  BILL_TO_DOLLAR_EXPIRE         VARCHAR2(100),
  ORDER_LIMIT                   VARCHAR2(100),
  LINE_LIMIT                    VARCHAR2(100),
  ORDER_REST_IND                VARCHAR2(50),
  ADDR_ORDER_REST_IND           VARCHAR2(50),
  BACKORDER_ALLOW_FLAG          VARCHAR2(50),
  FREIGHT_CHG_REQ_FLAG          VARCHAR2(50),
  CONTRACT_CODE                 VARCHAR2(50),
  ADDR_CONTRACT_CODE            VARCHAR2(200),
  PRODUCT_XREF_NBR              VARCHAR2(100),
  PRICE_PLAN                    VARCHAR2(100),
  PRICE_PLAN_SEQ                VARCHAR2(100),
  FILLER                        VARCHAR2(100)
);

create or replace TYPE XX_BILLING_INFO_OBJ_TBL AS TABLE OF XX_BILLING_INFO_OBJ;

------------------------------------------------------------------------------------------

create or replace TYPE XX_PAST_DUE_OBJ AS OBJECT
(
  DueDate                     VARCHAR2(50),
  AmountDueOriginal           VARCHAR2(20),
  AmountDueRemaining          VARCHAR2(20),
  AcctdAmoundDueRemaining     VARCHAR2(100),
  AmountApplied               VARCHAR2(40),
  AmountAdjusted              VARCHAR2(300),
  AmountInDispute             VARCHAR2(20),
  AmountCredited              VARCHAR2(40),
  InCollection                VARCHAR2(40),
  ActiveClaimFlag             VARCHAR2(20),
  DiscountOriginal            VARCHAR2(30),
  DiscountRemaining           VARCHAR2(30),
  DiscountTakenEarned         VARCHAR2(30)
  );

create or replace TYPE XX_PAST_DUE_OBJ_TBL AS TABLE OF XX_PAST_DUE_OBJ;

---------------------------------------------------------------------------------------------

create or replace TYPE XX_TAX_EXEMPT_OBJ AS OBJECT
(
  ADDRESS_SEQ            VARCHAR2(50),
  ADDRESS_STATE          VARCHAR2(20),
  COUNTRY_CODE           VARCHAR2(20),
  TAX_CERTIF_NBR         VARCHAR2(100),
  EXP_DATE               VARCHAR2(40),
  GST_EXEMPT_COMMENT     VARCHAR2(300),
  TAX_STATUS             VARCHAR2(20),
  ADDR_SEQ_DENLET        VARCHAR2(40),
  DENIAL_SEND_DATE       VARCHAR2(40),
  LETTER_NOTIF           VARCHAR2(100),
  FEDERAL_EXEMPT         VARCHAR2(100)
);

create or replace TYPE XX_TAX_EXEMPT_OBJ_TBL AS TABLE OF XX_TAX_EXEMPT_OBJ;

----------------------------------------------------------------------------------------------

create or replace TYPE XX_CUST_FROM_LOY_OBJ AS OBJECT
(
  MemberId           VARCHAR2(50),
  FirstName          VARCHAR2(200),
  LastName           VARCHAR2(200),
  Company            VARCHAR2(300),
  Address1           VARCHAR2(100),
  Address2           VARCHAR2(100),
  City               VARCHAR2(40),
  State              VARCHAR2(20),
  ZipCode            VARCHAR2(20),
  Country            VARCHAR2(200),
  Phone              VARCHAR2(60),
  Email              VARCHAR2(100),
  AddedDate          VARCHAR2(50),
  ActivatedDate      VARCHAR2(50)
  );
  
  
create or replace TYPE XX_CUST_FROM_LOY_OBJ_TBL AS TABLE OF XX_CUST_FROM_LOY_OBJ;

----------------------------------------------------------------------------------------------

create or replace TYPE XX_CUST_FROM_AOPS_OBJ AS OBJECT
(
  CustomerId         VARCHAR2(50),
  BusinessName       VARCHAR2(300),
  StreetAddress1     VARCHAR2(100),
  StreetAddress2     VARCHAR2(100),
  City               VARCHAR2(40),
  State              VARCHAR2(20),
  Province           VARCHAR2(20),
  ZipCode            VARCHAR2(20),
  Country            VARCHAR2(20)
  );

create or replace
TYPE XX_CUST_FROM_AOPS_OBJ_TBL AS TABLE OF XX_CUST_FROM_AOPS_OBJ;

----------------------------------------------------------------------------------------------

create or replace TYPE XX_CUST_FROM_CDH_OBJ AS OBJECT
(
  CustomerId         VARCHAR2(50),
  BusinessName       VARCHAR2(300),
  StreetAddress1     VARCHAR2(100),
  StreetAddress2     VARCHAR2(100),
  City               VARCHAR2(40),
  State              VARCHAR2(20),
  Province           VARCHAR2(20),
  ZipCode            VARCHAR2(20),
  Country            VARCHAR2(20)
  );

create or replace
TYPE XX_CUST_FROM_CDH_OBJ_TBL AS TABLE OF XX_CUST_FROM_CDH_OBJ;

---------------------------------------------------------------------------------------------

create or replace TYPE XX_CUST_BY_PHONE_OBJ AS OBJECT
(
  CustomerId         VARCHAR2(50),
  BusinessName       VARCHAR2(300),
  StreetAddress1     VARCHAR2(100),
  StreetAddress2     VARCHAR2(100),
  City               VARCHAR2(40),
  State              VARCHAR2(20),
  Province           VARCHAR2(20),
  ZipCode            VARCHAR2(20),
  Country            VARCHAR2(20)
  );

create or replace
TYPE XX_CUST_BY_PHONE_OBJ_TBL AS TABLE OF XX_CUST_BY_PHONE_OBJ;


------------------------------------------------------------------------------------------------

create or replace TYPE XX_CUST_INFO_META_OBJ AS OBJECT
(
  AopsCustInfoDataSource              VARCHAR2(100),
  AopsCustInfoFetchTime               VARCHAR2(100),
  AopsCustOrderInfoDataSource         VARCHAR2(100),
  AopsCustOrderInfoFetchTime          VARCHAR2(100),
  AopsCustBillingInfoDataSource       VARCHAR2(100),
  AopsCustBillingInfoFetchTime        VARCHAR2(100),
  GetBillingFreqDataSource            VARCHAR2(100),
  GetBillingFreqFetchTime             VARCHAR2(100),
  GetCustFinInfoDataSource            VARCHAR2(100),
  GetCustFinInfoFetchTime             VARCHAR2(100),
  GetCustPastDueInfoDataSource        VARCHAR2(100),
  GetCustPastDueInfoFetchTime         VARCHAR2(100),
  GetFinHierChildrenDataSource        VARCHAR2(100),
  GetFinHierChildrenFetchTime         VARCHAR2(100),
  GetParentAcctFinInfoDataSource      VARCHAR2(100),
  GetParentAcctFinInfoFetchTime       VARCHAR2(100),
  GetRepAssignmentsDataSource         VARCHAR2(100),
  GetRepAssignmentsFetchTime          VARCHAR2(100),
  GetTaxExemptInfoDataSource          VARCHAR2(100),
  GetTaxExemptInfoFetchTime           VARCHAR2(100),
  GetTeraDataCustInfoDataSource       VARCHAR2(100),
  GetTeraDataCustInfoFetchTime        VARCHAR2(100),
  LoyaltyMbrEnrollDataSource          VARCHAR2(100),
  LoyaltyMbrEnrollFetchTime           VARCHAR2(100),
  LoyaltyMbrPurchaseDataSource        VARCHAR2(100),
  LoyaltyMbrPurchaseFetchTime            VARCHAR2(100), 
  GetAOPS_ContractDataSource            VARCHAR2(100),
  GetAOPS_ContractFetchTime              VARCHAR2(100), 
  GetCDH_CustOrderInfoDataSource         VARCHAR2(100), 
  GetCDH_CustOrderInfoFetchTime          VARCHAR2(100), 
  GetOpenCasesDataSource                 VARCHAR2(100), 
  GetOpenCasesFetchTime                  VARCHAR2(100)
);

create or replace TYPE XX_CUST_INFO_META_OBJ_TBL AS TABLE OF XX_CUST_INFO_META_OBJ;



END;
/