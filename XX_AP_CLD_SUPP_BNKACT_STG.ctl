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
-- |DRAFT 1A   24-JUN-2019   Arun DSouza          Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

LOAD DATA
APPEND
INTO TABLE APPS.XX_AP_CLD_SUPP_BNKACT_STG
WHEN (SUPPLIER_NAME <> 'SUPPLIER_NAME')
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
    ( 
SUPPLIER_NUM,
SUPPLIER_NAME,
VENDOR_SITE_CODE,
COUNTRY_CODE,
BANK_NAME,
BRANCH_NAME,
BANK_ACCOUNT_NAME,
BANK_ACCOUNT_NUM,
PRIMARY_FLAG,
START_DATE,
END_DATE,
CURRENCY_CODE,
PROCESS_FLAG        CONSTANT "N",
BNKACT_PROCESS_FLAG CONSTANT "1",
   created_by       CONSTANT "-1",
   creation_date    SYSDATE,
   last_update_date SYSDATE,
   last_updated_by  CONSTANT  "-1"
)
