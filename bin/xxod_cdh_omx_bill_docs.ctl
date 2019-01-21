-- +=======================================================================+
-- |                            Office Depot                               |
-- +=======================================================================+
-- | Name            : XXOD_CDH_OMX_EBILL_DOCS.ctl                         |
-- | Rice ID         : 700                                                 |
-- | Description     : Control File to load the XX_CDH_OMX_EBILL_DOCS_STG  |
-- |                   table and XX_CDH_OMX_RECONCILE_COUNT_STG            |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      11-FEB-2015 Havish Kasina      Initial Draft version          |
-- |2.0      20-MAR-2015 Havish Kasina      Review Changes                 |
-- +=======================================================================+
LOAD DATA
APPEND
INTO TABLE XX_CDH_OMX_BILL_DOCS_STG
WHEN (1) = 'D'  
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( junk1 filler,
  BATCH_ID,
  ORACLE_CUSTOMER_NUMBER,
  AOPS_CUSTOMER_NUMBER,
  OMX_CUSTOMER_NUMBER,
  ACTIVE_CONSIGNEE             "TRIM(:ACTIVE_CONSIGNEE)",
  PRINT_DAILY_FLAG             "TRIM(:PRINT_DAILY_FLAG)",
  SUMMARY_BILL_FLAG            "TRIM(:SUMMARY_BILL_FLAG)",
  SUMMARY_BILL_CYCLE           "TRIM(:SUMMARY_BILL_CYCLE)",
  PRINT_EXP_REP_FLAG           "TRIM(:PRINT_EXP_REP_FLAG)",
  PRINT_INV_DETAIL_FLAG        "TRIM(:PRINT_INV_DETAIL_FLAG)",
  PRINT_REMITTANCE_PAGE        "TRIM(:PRINT_REMITTANCE_PAGE)",
  PAYMENT_TERM                 "TRIM(:PAYMENT_TERM)",
  SORT_BY_CONSIGNEE_EXP_RPT    "TRIM(:SORT_BY_CONSIGNEE_EXP_RPT)",
  SORT_BY_PO_EXP_RPT           "TRIM(:SORT_BY_PO_EXP_RPT)",
  SORT_BY_COSTCENTER_EXP_RPT   "TRIM(:SORT_BY_COSTCENTER_EXP_RPT)",
  CREATED_BY                   "FND_GLOBAL.USER_ID",                    
  CREATION_DATE                "SYSDATE",       
  LAST_UPDATED_BY              "FND_GLOBAL.USER_ID",   
  LAST_UPDATE_DATE             "SYSDATE",      
  LAST_UPDATE_LOGIN            "FND_GLOBAL.LOGIN_ID",
  REQUEST_ID                   "FND_GLOBAL.CONC_REQUEST_ID",
  EXTRACT_DATE                 "SYSDATE",
  RECORD_ID                    "XX_CDH_OMX_REC_ID_S.NEXTVAL",
  STATUS           CONSTANT    'N'  
)
INTO TABLE XX_CDH_OMX_RECONCILE_COUNT_STG
Append
WHEN Record_type = 'T' 
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( Record_type POSITION(1),
  BATCH_ID,
  NO_OF_OMX_EBILL_DOCS,
  CREATED_BY                   "FND_GLOBAL.USER_ID",                    
  CREATION_DATE                "SYSDATE",       
  LAST_UPDATED_BY              "FND_GLOBAL.USER_ID",   
  LAST_UPDATE_DATE             "SYSDATE",      
  LAST_UPDATE_LOGIN            "FND_GLOBAL.LOGIN_ID",
  REQUEST_ID                   "FND_GLOBAL.CONC_REQUEST_ID",
  RECORD_ID                    "XX_CDH_OMX_REC_ID_S.NEXTVAL",
  STATUS            CONSTANT   'N'
)
