-- +=============================================================================+
-- |                            Office Depot                                     |
-- +=============================================================================+
-- | Name            : XXOD_CDH_MOD4_SFDC_CUST.ctl                               |
-- | Rice ID         : 700                                                       |
-- | Description     : Control File to load the XX_CDH_SFDC_MOD4_CUST_STG table  |
-- |                                                                             |
-- |                                                                             |
-- |Change History:                                                              |
-- |---------------                                                              |
-- |                                                                             |
-- |Version  Date        Author             Remarks                              |
-- |-------  ----------- -----------------  -------------------------------------|
-- |1.0      19-FEB-2015 Havish Kasina      Initial Draft version                |
-- |2.0      20-MAR-2015 Havish Kasina      Review Changes                       |
-- |3.0      20-MAR-2015 Havish Kasina      Added BILL_TO_CONSIGNEE              |
-- |4.0      08-SEP-2015 Havish Kasina      Added LPAD Function for AOPS Customer|
-- +=============================================================================+
OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE XX_CDH_MOD4_SFDC_CUST_STG
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( 
  PARTY_ID,
  AOPS_CUSTOMER_NUMBER         "LPAD(:AOPS_CUSTOMER_NUMBER, 8, 0)",
  OMX_CUSTOMER_NUMBER,
  BILLING_TYPE,
  CUSTOMER_AGREEMENT,
  SPLIT_CUSTOMER,
  BILL_TO_CONSIGNEE            "TRIM(:BILL_TO_CONSIGNEE)",
  CREATED_BY                   "FND_GLOBAL.USER_ID",                    
  CREATION_DATE                "SYSDATE",       
  LAST_UPDATED_BY              "FND_GLOBAL.USER_ID",   
  LAST_UPDATE_DATE             "SYSDATE",      
  LAST_UPDATE_LOGIN            "FND_GLOBAL.LOGIN_ID",
  REQUEST_ID                   "FND_GLOBAL.CONC_REQUEST_ID",
  STATUS           CONSTANT    'N',
  RECORD_ID                    "XX_CDH_OMX_REC_ID_S.NEXTVAL"
)