-- +============================================================================================+
-- |                        Office Depot - Project Beacon                                       |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_AP_CLD_SUPPLIERS_STG.CTL                                                 |
-- | Rice Id      :                                                                             |
-- | Description  : Supplier Interface from Cloud                                               |
-- | Purpose      : Load Suppliers                                                              |
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
INTO TABLE APPS.XX_AP_CLD_SUPPLIERS_STG
WHEN (SUPPLIER_NAME <> 'SUPPLIER_NAME')
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
    ( 
SUPPLIER_NAME,
SEGMENT1,
VENDOR_TYPE_LOOKUP_CODE,
END_DATE_ACTIVE,
ONE_TIME_FLAG,
MIN_ORDER_AMOUNT,
CUSTOMER_NUM,
STANDARD_INDUSTRY_CLASS,
NUM_1099,
FEDERAL_REPORTABLE_FLAG,
TYPE_1099,
STATE_REPORTABLE_FLAG,
TAX_REPORTING_NAME,
NAME_CONTROL,
TAX_VERIFICATION_DATE,
ALLOW_AWT_FLAG,
VAT_CODE,
VAT_REGISTRATION_NUM,
AUTO_TAX_CALC_OVERRIDE,
ATTRIBUTE_CATEGORY,
ATTRIBUTE3,
ATTRIBUTE2,
ATTRIBUTE4,
ATTRIBUTE5,
ATTRIBUTE6,
ATTRIBUTE7,
ATTRIBUTE8,
ATTRIBUTE9,
ATTRIBUTE10,
ATTRIBUTE11,
ATTRIBUTE12,
ATTRIBUTE13,
ATTRIBUTE14,
ATTRIBUTE15,
SUPP_PROCESS_FLAG CONSTANT "1",
PROCESS_FLAG          CONSTANT "N",
     created_by       CONSTANT "-1",
     creation_date    SYSDATE,
     last_update_date SYSDATE,
     last_updated_by  CONSTANT  "-1"
    )
