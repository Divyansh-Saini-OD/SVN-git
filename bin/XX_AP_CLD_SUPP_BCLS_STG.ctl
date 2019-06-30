-- +============================================================================================+
-- |                        Office Depot - Project BEACON                                       |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_AP_CLD_SUPP_BCLS_STG.ctl                                                 |
-- | Rice Id      :                                                                             |
-- | Description  : Vendor interface from Cloud                                                 |
-- | Purpose      : Load Business Classifications                                               |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   27-JUN-2019   Priyam Parmar          Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE XX_AP_CLD_SUPP_BCLS_STG
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    ( 
SUPPLIER_NAME     CHAR"TRIM(:SUPPLIER_NAME)",
SUPPLIER_NUMBER   CHAR"TRIM(:SUPPLIER_NUMBER)",
CLASSIFICATION    CHAR"TRIM(:CLASSIFICATION)",
SUBCLASSIFICATION   CHAR"TRIM(:SUBCLASSIFICATION)",
START_DATE        CHAR"TRIM(:START_DATE)",
CONFIRMED_ON      CHAR"TRIM(:CONFIRMED_ON)",
PROCESS_FLAG     CONSTANT "N",
BCLS_PROCESS_FLAG CONSTANT "1",
created_by       CONSTANT "-1",
creation_date    SYSDATE,
last_update_date SYSDATE,
last_updated_by  CONSTANT  "-1"
)

