-- +=============================================================================+
-- |                            Office Depot                                     |
-- +=============================================================================+
-- | Name            : xx_cdh_omx_cust_info_stg.ctl                                  |
-- | Rice ID         : 702                                                       |
-- | Description     : ContRol File to load the xx_cdh_omx_cust_info_stg            |
-- |                   table and XX_CDH_OMX_RECONCILE_COUNT_STG                  |
-- |                                                                             |
-- |Change History:                                                              |
-- |---------------                                                              |
-- |                                                                             |
-- |Version  Date        Author             Remarks                              |
-- |-------  ----------- -----------------  -------------------------------------|
-- |1.0      16-MAR-2015 Abhi K     		Initial Draft version                |
-- +=============================================================================+
LOAD DATA
APPEND
INTO TABLE xx_cdh_omx_cust_info_stg
WHEN (1) = 'D' 
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( 
 junk1 filler,
  BATCH_ID,
  CUSTOMER_NUMBER,
  AOPS_CUSTOMER_NUMBER,
  OMX_ACCOUNT_NUMBER,
  CREDIT_LIMIT     "TRIM(:CREDIT_LIMIT)",
  DB_RATING        "TRIM(:DB_RATING)",
  DB_RATING_DATE "to_date(:DB_RATING_DATE, 'YYYYMMDD')",
  STATEMENT_CYCLE  "TRIM(:STATEMENT_CYCLE)",
  STATEMENT_TYPE   "TRIM(:STATEMENT_TYPE)",
  STATUS CONSTANT    'N',
  PROCESS_FLAG CONSTANT    'N',
  RECORD_ID "XX_CDH_OMX_REC_ID_S.NEXTVAL",
  REQUEST_ID "FND_GLOBAL.CONC_REQUEST_ID",
  CREATION_DATE  SYSDATE, 
  created_by     "fnd_global.user_id",
  lAST_UPDATE_DATE SYSDATE,
  last_updated_by       "fnd_global.user_id",
  last_update_login     "fnd_global.login_id"
)
INTO TABLE XX_CDH_OMX_RECONCILE_COUNT_STG
Append
WHEN Record_type = 'T' 
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( Record_type POSITION(1),
  Batch_id,
  NO_OF_OMX_CREDITS,
  Record_id "XX_CDH_OMX_REC_ID_S.NEXTVAL",
  CREATED_BY                   "FND_GLOBAL.USER_ID",                    
  CREATION_DATE                "SYSDATE",       
  LAST_UPDATED_BY              "FND_GLOBAL.USER_ID",   
  LAST_UPDATE_DATE             "SYSDATE",      
  LAST_UPDATE_LOGIN            "FND_GLOBAL.LOGIN_ID",
  REQUEST_ID                   "FND_GLOBAL.CONC_REQUEST_ID",
  STATUS           CONSTANT    'N'
)
