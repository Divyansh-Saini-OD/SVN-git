-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_FA_MM_ADJUST_LOAD.ctl                                                    |
-- | Rice Id      : E3121 - Defect 35046                                                                |
-- | Description  : E3121_ MidMonth FA Mass Adjustments using API                               |
-- | Purpose      : Insert into Custom Table XX_FA_ADJUST_STG                                   |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- | 1.0      10-JUL-2015    Madhu Bolli           Initial Version                              |
-- | 1.1      18-SEP-2015    Madhu Bolli           Hardcoded Request_id, Created_by             |
-- |                                                                                            |
-- +============================================================================================+
LOAD DATA
APPEND
INTO TABLE XXFIN.XX_FA_ADJUST_STG
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    (  BOOK_TYPE_CODE                        CHAR"TRIM(:BOOK_TYPE_CODE)"
      ,ASSET_ID                              CHAR"TRIM(:ASSET_ID)"
      ,DPIS                                  DATE "DD-MM-YY"
      ,COST                                  CHAR"TRIM(:COST)"
      ,YTD_DEPRN                             CHAR"TRIM(:YTD_DEPRN)"
      ,DEPRN_RSV		                         CHAR"TRIM(:DEPRN_RSV)"
      ,DEPRN_METHOD_CODE                     CHAR"TRIM(:DEPRN_METHOD_CODE)"
      ,LIFE_IN_MONTHS                        CHAR"TRIM(:LIFE_IN_MONTHS)"
      ,SALVAGE_VALUE                         CHAR"TRIM(:SALVAGE_VALUE)"
      ,PRORATE_CONV_CODE                     CHAR"TRIM(:PRORATE_CONV_CODE)"
      ,DEPRECIATE_FLAG                       CHAR"TRIM(replace(:DEPRECIATE_FLAG,chr(13),''))"
      ,TRANSACTION_SUB_TYPE                  CHAR"TRIM(:TRANSACTION_SUB_TYPE)"
      ,AMORT_START_DATE                      DATE "DD-MM-YY"
      ,TRANSACTION_NAME                      CHAR"TRIM(:TRANSACTION_NAME)"      
      ,ATTRIBUTE6                            CHAR"TRIM(:ATTRIBUTE6)"
      ,ATTRIBUTE7                            CHAR"TRIM(:ATTRIBUTE7)"
      ,ATTRIBUTE8                            CHAR"TRIM(:ATTRIBUTE8)"
      ,ATTRIBUTE9                            CHAR"TRIM(:ATTRIBUTE9)"
      ,ATTRIBUTE10                           CHAR"TRIM(:ATTRIBUTE10)"
      ,ATTRIBUTE11                           CHAR"TRIM(:ATTRIBUTE11)"
      ,ATTRIBUTE12                           CHAR"TRIM(:ATTRIBUTE12)"      
      ,ATTRIBUTE14                           CHAR"TRIM(:ATTRIBUTE14)"
      ,ATTRIBUTE15                           CHAR"TRIM(:ATTRIBUTE15)"
      ,REQUEST_ID                            CONSTANT "-1" 
      ,PROCESS_FLAG                          CONSTANT "1"
      ,ERROR_FLAG                            CONSTANT "N"
      ,ERROR_MESSAGE                         CHAR"TRIM(:ERROR_MESSAGE)"
      ,CREATED_BY                            CONSTANT "-1"
      ,CREATION_DATE                         SYSDATE          
      ,LAST_UPDATED_BY                       CONSTANT "-1" 
      ,LAST_UPDATE_DATE                      SYSDATE          
      ,LAST_UPDATE_LOGIN                     CONSTANT "-1"      
)

-- +=====================================
-- | END OF SCRIPT
-- +=====================================
