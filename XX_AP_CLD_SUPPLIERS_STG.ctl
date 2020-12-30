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
-- |1.0        27-JUN-2019   Priyam Parmar          Initial Version                             |
-- |1.1        22-DEC-2020   Komal Mishra           w.r.t. JIRA NAIT-166023                     |
-- |                                                                                            |
-- +============================================================================================+

OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE XX_AP_CLD_SUPPLIERS_STG
WHEN SEGMENT1 <> ''
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    ( 
SUPPLIER_NAME   CHAR"TRIM(:SUPPLIER_NAME)",
SEGMENT1        CHAR"TRIM(:SEGMENT1)",
VENDOR_TYPE_LOOKUP_CODE   CHAR"UPPER(TRIM(:VENDOR_TYPE_LOOKUP_CODE))",
ORGANIZATION_TYPE  		  CHAR"UPPER(TRIM(:ORGANIZATION_TYPE))",
END_DATE_ACTIVE           CHAR"TRIM(:END_DATE_ACTIVE)",
ONE_TIME_FLAG             CHAR"TRIM(:ONE_TIME_FLAG)",
MIN_ORDER_AMOUNT          CHAR"TRIM(:MIN_ORDER_AMOUNT)",
CUSTOMER_NUM              CHAR"TRIM(:CUSTOMER_NUM)",
STANDARD_INDUSTRY_CLASS   CHAR"TRIM(:STANDARD_INDUSTRY_CLASS)",
NUM_1099                  CHAR"TRIM(:NUM_1099)",
FEDERAL_REPORTABLE_FLAG   CHAR"TRIM(:FEDERAL_REPORTABLE_FLAG)",
TYPE_1099                 CHAR"TRIM(:TYPE_1099)",
STATE_REPORTABLE_FLAG     CHAR"TRIM(:STATE_REPORTABLE_FLAG)",
TAX_REPORTING_NAME        CHAR"TRIM(:TAX_REPORTING_NAME)",
NAME_CONTROL              CHAR"TRIM(:NAME_CONTROL)",
TAX_VERIFICATION_DATE     CHAR"TRIM(:TAX_VERIFICATION_DATE)",
ALLOW_AWT_FLAG            CHAR"TRIM(:ALLOW_AWT_FLAG)",
VAT_CODE                  CHAR"TRIM(:VAT_CODE)",
VAT_REGISTRATION_NUM      CHAR"TRIM(:VAT_REGISTRATION_NUM)",
AUTO_TAX_CALC_OVERRIDE    CHAR"TRIM(:AUTO_TAX_CALC_OVERRIDE)",
ATTRIBUTE_CATEGORY        CHAR"TRIM(:ATTRIBUTE_CATEGORY)",
ATTRIBUTE3   CHAR"TRIM(:ATTRIBUTE3)",
ATTRIBUTE2   CHAR"TRIM(:ATTRIBUTE2)",
ATTRIBUTE4   CHAR"TRIM(:ATTRIBUTE4)",
ATTRIBUTE5   CHAR"TRIM(:ATTRIBUTE5)",
ATTRIBUTE6   CHAR"TRIM(:ATTRIBUTE6)",
ATTRIBUTE7   CHAR"TRIM(:ATTRIBUTE7)",
ATTRIBUTE8   CHAR"TRIM(:ATTRIBUTE8)",
ATTRIBUTE9   CHAR"TRIM(:ATTRIBUTE9)",
ATTRIBUTE10   CHAR"TRIM(:ATTRIBUTE10)",
ATTRIBUTE11   CHAR"TRIM(:ATTRIBUTE11)",
ATTRIBUTE12   CHAR"TRIM(:ATTRIBUTE12)",
ATTRIBUTE13   CHAR"TRIM(:ATTRIBUTE13)",
ATTRIBUTE14   CHAR"TRIM(:ATTRIBUTE14)",
ATTRIBUTE15   CHAR"TRIM(:ATTRIBUTE15)",
SUPP_PROCESS_FLAG CONSTANT "1",
PROCESS_FLAG          CONSTANT "N",
     created_by       CONSTANT "-1",
     creation_date    SYSDATE,
     last_update_date SYSDATE,
     last_updated_by  CONSTANT  "-1"
    )
