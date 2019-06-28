-- +============================================================================================+
-- |                        Office Depot - Project Beacon                                       |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_AP_CLD_SUPP_BNKACT_STG.ctl                                               |
-- | Rice Id      : I                                                                           |
-- | Description  : Vendor Interface  from Cloud                                                |
-- | Purpose      : Load Supplier Banking Details                                               |
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
INTO TABLE XX_AP_CLD_SUPP_BNKACT_STG
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    ( 
SUPPLIER_NUM   CHAR"TRIM(:SUPPLIER_NUM)",
SUPPLIER_NAME  CHAR"TRIM(:SUPPLIER_NAME)",
VENDOR_SITE_CODE   CHAR"TRIM(:VENDOR_SITE_CODE)",
COUNTRY_CODE   CHAR"TRIM(:COUNTRY_CODE)",
BANK_NAME      CHAR"TRIM(:BANK_NAME)",
BRANCH_NAME   CHAR"TRIM(:BRANCH_NAME)",
BANK_ACCOUNT_NAME   CHAR"TRIM(:BANK_ACCOUNT_NAME)",
BANK_ACCOUNT_NUM   CHAR"TRIM(:BANK_ACCOUNT_NUM)",
PRIMARY_FLAG  CHAR"TRIM(:PRIMARY_FLAG)",
START_DATE   CHAR"TRIM(:START_DATE)",
END_DATE    CHAR"TRIM(:END_DATE)",
CURRENCY_CODE   CHAR"TRIM(:CURRENCY_CODE)",
PROCESS_FLAG        CONSTANT "N",
BNKACT_PROCESS_FLAG CONSTANT "1",
   created_by       CONSTANT "-1",
   creation_date    SYSDATE,
   last_update_date SYSDATE,
   last_updated_by  CONSTANT  "-1"
)
