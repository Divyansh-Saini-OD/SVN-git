-- +=========================================================================+
-- |                            Office Depot                                 |
-- +=========================================================================+
-- | Name            : XXOD_CDH_OMX_EBILL_CONTACTS.ctl                       |
-- | Rice ID         : 700                                                   |
-- | Description     : Control File to load the XX_CDH_OMX_EBILL_CONTACTS_STG|
-- |                   table and XX_CDH_OMX_RECONCILE_COUNT_STG              |
-- |                                                                         |
-- |Change History:                                                          |
-- |---------------                                                          |
-- |                                                                         |
-- |Version  Date        Author             Remarks                          |
-- |-------  ----------- -----------------  ---------------------------------|
-- |1.0      11-FEB-2015 Havish Kasina      Initial Draft version            |
-- |2.0      20-MAR-2015 Havish Kasina      Review Changes                   |
-- +=========================================================================+
LOAD DATA
APPEND
INTO TABLE XX_CDH_OMX_EBILL_CONTACTS_STG
WHEN (1) = 'D'  
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( junk1 filler,
  BATCH_ID,
  ORACLE_CUSTOMER_NUMBER,
  AOPS_CUSTOMER_NUMBER,
  OMX_CUSTOMER_NUMBER,
  BILL_TO_CONSIGNEE            "TRIM(:BILL_TO_CONSIGNEE)",
  CONTACT_FIRST_NAME           "TRIM(:CONTACT_FIRST_NAME)",
  CONTACT_LAST_NAME            "TRIM(:CONTACT_LAST_NAME)",
  EMAIL_ADDRESS                "TRIM(:EMAIL_ADDRESS)",
  CREATED_BY                   "FND_GLOBAL.USER_ID",                    
  CREATION_DATE                "SYSDATE",       
  LAST_UPDATED_BY              "FND_GLOBAL.USER_ID",   
  LAST_UPDATE_DATE             "SYSDATE",      
  LAST_UPDATE_LOGIN            "FND_GLOBAL.LOGIN_ID",
  REQUEST_ID                   "FND_GLOBAL.CONC_REQUEST_ID",
  EXTRACT_DATE                 "SYSDATE",
  RECORD_ID                    "XX_CDH_OMX_REC_ID_S.NEXTVAL",
  STATUS            CONSTANT   'N'  
)
INTO TABLE XX_CDH_OMX_RECONCILE_COUNT_STG
Append
WHEN Record_type = 'T' 
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( Record_type POSITION(1),
  BATCH_ID,
  NO_OF_OMX_EBILL_CONTACTS,
  CREATED_BY                   "FND_GLOBAL.USER_ID",                    
  CREATION_DATE                "SYSDATE",       
  LAST_UPDATED_BY              "FND_GLOBAL.USER_ID",   
  LAST_UPDATE_DATE             "SYSDATE",      
  LAST_UPDATE_LOGIN            "FND_GLOBAL.LOGIN_ID",
  REQUEST_ID                   "FND_GLOBAL.CONC_REQUEST_ID",
  RECORD_ID                    "XX_CDH_OMX_REC_ID_S.NEXTVAL",
  STATUS            CONSTANT   'N'
)


