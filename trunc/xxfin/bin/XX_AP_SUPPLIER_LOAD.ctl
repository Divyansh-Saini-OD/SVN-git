-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_AP_SUPPLIER_LOAD.ctl                                                     |
-- | Rice Id      : Defect 32542                                                                |
-- | Description  : I2170_One time vendor conversion for customer rebate checks                 |
-- | Purpose      : Insret into Custom Table XX_AP_SUPPLIER_STG                                 |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   06-JAN-2015   Amarnath Modium      Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+
OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE XXFIN.XX_AP_SUPPLIER_STG
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    (   SUPPLIER_NAME                     CHAR"TRIM(:SUPPLIER_NAME)"
       ,TAX_REG_NUM                       CHAR"TRIM(:TAX_REG_NUM)"
       ,TAX_PAYER_ID                      CHAR"TRIM(:TAX_PAYER_ID)"
       ,SUPPLIER_TYPE                     CHAR"TRIM(:SUPPLIER_TYPE)"
       ,CUSTOMER_NUM                      CHAR"TRIM(:CUSTOMER_NUM)"
       ,ONE_TIME_FLAG                     CHAR"TRIM(:ONE_TIME_FLAG)"
       ,FEDERAL_REPORTABLE_FLAG           CHAR"TRIM(:FEDERAL_REPORTABLE_FLAG)"
       ,STATE_REPORTABLE_FLAG             CHAR"TRIM(:STATE_REPORTABLE_FLAG)"
       ,INCOME_TAX_TYPE                   CHAR"TRIM(:INCOME_TAX_TYPE)"
       ,MBE                               CHAR"TRIM(:MBE)"
       ,NMSDC                             CHAR"TRIM(:NMSDC)"
       ,WBE                               CHAR"TRIM(:WBE)"
       ,WBENC                             CHAR"TRIM(:WBENC)"
       ,VOB                               CHAR"TRIM(:VOB)"
       ,DOD_OR_VA                         CHAR"TRIM(:DOD_OR_VA)"
       ,DOE                               CHAR"TRIM(:DOE)"
       ,USBLN                             CHAR"TRIM(:USBLN)"
       ,LGBT                              CHAR"TRIM(:LGBT)"
       ,NGLCC                             CHAR"TRIM(:NGLCC)"
       ,NIB_NISH_ABILITY_ONE              CHAR"TRIM(:NIB_NISH_ABILITY_ONE)"
       ,FOREIGN_OWNED                     CHAR"TRIM(:FOREIGN_OWNED)"
       ,SB                                CHAR"TRIM(:SB)"
       ,SAM                               CHAR"TRIM(:SAM)"
       ,SBA                               CHAR"TRIM(:SBA)"
       ,SBC                               CHAR"TRIM(:SBC)"
       ,SDBE                              CHAR"TRIM(:SDBE)"
       ,SBA8_A                            CHAR"TRIM(:SBA8_A)"
       ,HUBZ                              CHAR"TRIM(:HUBZ)"
       ,WOSB                              CHAR"TRIM(:WOSB)"
       ,WSBE                              CHAR"TRIM(:WSBE)"
       ,EDWOSB                            CHAR"TRIM(:EDWOSB)"
       ,VOSB                              CHAR"TRIM(:VOSB)"
       ,SDVOSB                            CHAR"TRIM(:SDVOSB)"
       ,HBCU_MI                           CHAR"TRIM(:HBCU_MI)"
       ,AND_A                             CHAR"TRIM(:AND_A)"
       ,IND                               CHAR"TRIM(:IND)"
       ,OWNERSHIP_CLASSIFICATION          CHAR"TRIM(:OWNERSHIP_CLASSIFICATION)"
       ,BUSS_CLASS_PROCESS_FLAG           CONSTANT "N"
       ,SUPP_PROCESS_FLAG                 CONSTANT "1"
       ,SUPP_ERROR_FLAG                   CONSTANT "N" 
       ,CREATED_BY                        "FND_GLOBAL.USER_ID"
       ,CREATION_DATE                     SYSDATE
       ,LAST_UPDATED_BY                   "FND_GLOBAL.USER_ID"
       ,LAST_UPDATE_DATE                  SYSDATE
)

-- +=====================================
-- | END OF SCRIPT
-- +=====================================
