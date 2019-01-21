-- +=============================================================================+
-- |                            Office Depot                                     |
-- +=============================================================================+
-- | Name            : xx_cdh_omx_dunning_stg.ctl                                |
-- | Rice ID         : 701                                                       |
-- | Description     : ContRol File to load the xx_cdh_omx_dunning_stg           |
-- |                   table and XX_CDH_OMX_RECONCILE_COUNT_STG                  |
-- |                                                                             |
-- |Change History:                                                              |
-- |---------------                                                              |
-- |                                                                             |
-- |Version  Date        Author             Remarks                              |
-- |-------  ----------- -----------------  -------------------------------------|
-- |DRAFT 1.0  19-Feb-2015  Abhi konda       Initial draft version     			 |
-- |DRAFT 1.1  24-MAR-2015  Abhi konda       Code Review Changes	             |
-- +=============================================================================| 
LOAD DATA
APPEND
INTO TABLE xx_cdh_omx_dunning_stg
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
  BILL_CONSIGNEE_REF     "TRIM(:BILL_CONSIGNEE_REF)",
  DUNNING_FLAG           "TRIM(:DUNNING_FLAG)",
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
  NO_OF_OMX_DUNNING,
  Record_id "XX_CDH_OMX_REC_ID_S.NEXTVAL",
  CREATED_BY                   "FND_GLOBAL.USER_ID",                    
  CREATION_DATE                "SYSDATE",       
  LAST_UPDATED_BY              "FND_GLOBAL.USER_ID",   
  LAST_UPDATE_DATE             "SYSDATE",      
  LAST_UPDATE_LOGIN            "FND_GLOBAL.LOGIN_ID",
  REQUEST_ID                   "FND_GLOBAL.CONC_REQUEST_ID",
  STATUS          CONSTANT     'N'
)
