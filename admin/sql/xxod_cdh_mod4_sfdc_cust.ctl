-- +============================================================================+
-- |                            Office Depot                                    |
-- +============================================================================+
-- | Name            : XXOD_CDH_MOD4_SFDC_CUST.ctl                              |
-- | Rice ID         : C0700                                                      |
-- | Description     : Control File to load the XX_CDH_SFDC_MOD4_CUST_STG table |
-- |                                                                            |
-- |Change History:                                                             |
-- |---------------                                                             |
-- |                                                                            |
-- |Version  Date        Author             Remarks                             |
-- |-------  ----------- -----------------  ------------------------------------|
-- |1.0      11-FEB-2015 Abhi     Initial Draft version               |
-- +============================================================================+

LOAD DATA
APPEND 
INTO TABLE XX_CDH_MOD4_SFDC_CUST_STG
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( PARTY_ID,
  AOPS_CUSTOMER_NUMBER,
  OMX_CUSTOMER_NUMBER,
  BILLING_TYPE,
  CUSTOMER_AGREEMENT,
  SPLIT_CUSTOMER,
  CREATED_BY                   "FND_GLOBAL.USER_ID",                    
  CREATION_DATE                "SYSDATE",       
  LAST_UPDATED_BY              "FND_GLOBAL.USER_ID",   
  LAST_UPDATE_DATE             "SYSDATE",      
  LAST_UPDATE_LOGIN            "FND_GLOBAL.LOGIN_ID",
  REQUEST_ID                   "FND_GLOBAL.CONC_REQUEST_ID",
  STATUS           CONSTANT    'N'
)

