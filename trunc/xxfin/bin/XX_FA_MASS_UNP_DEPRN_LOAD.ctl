                                                  -- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_FA_MASS_UNP_DEPRN_LOAD.ctl                                               |
-- | Rice Id      : E3122 (Defect 32542)                                                        |
-- | Description  : E3122 - Load FA Mass Unplanned Depreciation using API                       |
-- | Purpose      : Insret into Custom Table XX_FA_UNP_DEPRN_STG                                |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- | 1.0      16-JUL-2015    Madhu Bolli           Initial Version                              |
-- | 1.1      28-SEP-2015    Madhu Bolli           Hardcode Request_id and few other columns    |
-- |                                                                                            |
-- +============================================================================================+
LOAD DATA
APPEND
INTO TABLE XXFIN.XX_FA_UNP_DEPRN_STG
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    (  BOOK_TYPE_CODE                        CHAR"TRIM(:BOOK_TYPE_CODE)"
      ,ASSET_ID                              CHAR"TRIM(:ASSET_ID)"
      ,UNP_DEPR_CC                           CHAR"TRIM(:UNP_DEPR_CC)"
      ,UNP_AMOUNT                            CHAR"TRIM(:UNP_AMOUNT)"
      ,UNP_TYPE		                         CHAR"TRIM(replace(:UNP_TYPE, chr(13), ''))"
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
