-- +============================================================================================+
-- |                        Office Depot - Project Beacon                                       |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_AP_CLD_SITE_DFF_STG.ctl                                                  |
-- | Rice Id      :                                                                             |
-- | Description  : Vendor Interface from Cloud                                                 |
-- | Purpose      : DFF Load                                                                    |
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
INTO TABLE XX_AP_CLD_SITE_DFF_STG
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    (
SUPPLIER_NUMBER   ,
SUPPLIER_NAME      CHAR"TRIM(:SUPPLIER_NAME)",
VENDOR_SITE_CODE   CHAR"TRIM(:VENDOR_SITE_CODE)",
EDI_DISTRIBUTION_CODE   CHAR"TRIM(:EDI_DISTRIBUTION_CODE)",
SUP_TRAIT         CHAR"TRIM(:SUP_TRAIT)",
BACK_ORDER_FLAG   CHAR"TRIM(:BACK_ORDER_FLAG)",
OD_DATE_SIGNED     CHAR"TRIM(:OD_DATE_SIGNED)",
VENDOR_DATE_SIGNED     CHAR"TRIM(:VENDOR_DATE_SIGNED)",
EFT_SETTLE_DAYS   CHAR"TRIM(:EFT_SETTLE_DAYS)",
MIN_PREPAID_CODE  CHAR"TRIM(:MIN_PREPAID_CODE)",
SUPPLIER_SHIP_TO   CHAR"TRIM(:SUPPLIER_SHIP_TO)",
DEDUCT_FROM_INVOICE_FLAG   CHAR"TRIM(:DEDUCT_FROM_INVOICE_FLAG)",
RTV_FREIGHT_PAYMENT_METHOD   CHAR"TRIM(:RTV_FREIGHT_PAYMENT_METHOD)",
PAYMENT_FREQUENCY   CHAR"TRIM(:PAYMENT_FREQUENCY)",
RTV_INSTRUCTIONS    CHAR"TRIM(:RTV_INSTRUCTIONS)",
ADDL_RTV_INSTRUCTIONS   CHAR"TRIM(:ADDL_RTV_INSTRUCTIONS)",
RGA_MARKED_FLAG   CHAR"TRIM(:RGA_MARKED_FLAG)",
REMOVE_PRICE_STICKER_FLAG   CHAR"TRIM(:REMOVE_PRICE_STICKER_FLAG)",
CONTACT_SUPPLIER_FOR_RGA_FLAG   CHAR"TRIM(:CONTACT_SUPPLIER_FOR_RGA_FLAG)",
DESTROY_FLAG            CHAR"TRIM(:DESTROY_FLAG)",
SERIAL_NUM_REQUIRED_FLAG   CHAR"TRIM(:SERIAL_NUM_REQUIRED_FLAG)",
PERMANENT_RGA           CHAR"TRIM(:PERMANENT_RGA)",
LEAD_TIME               CHAR"TRIM(:LEAD_TIME)",
VENDOR_MIN_AMOUNT       CHAR"TRIM(:VENDOR_MIN_AMOUNT)",
MASTER_VENDOR_ID        CHAR"TRIM(:MASTER_VENDOR_ID)",
RTV_OPTION              CHAR"TRIM(:RTV_OPTION)",
DESTROY_ALLOW_AMOUNT    CHAR"TRIM(:DESTROY_ALLOW_AMOUNT)",
MIN_RETURN_QTY          CHAR"TRIM(:MIN_RETURN_QTY)",
MIN_RETURN_AMOUNT       CHAR"TRIM(:MIN_RETURN_AMOUNT)",
DAMAGE_DESTROY_LIMIT     CHAR"TRIM(:DAMAGE_DESTROY_LIMIT)",
RTV_RELATED_SITE        CHAR"TRIM(:RTV_RELATED_SITE)",
DELIVERY_POLICY		    CHAR"TRIM(:DELIVERY_POLICY)",
FAVOURABLE_PRICE_PCT    CHAR"TRIM(:FAVOURABLE_PRICE_PCT)", 
MAX_PRICE_AMT           CHAR"TRIM(:MAX_PRICE_AMT)",  
MIN_CHARGEBACK_AMT      CHAR"TRIM(:MIN_CHARGEBACK_AMT)",  
MAX_FREIGHT_AMT         CHAR"TRIM(:MAX_FREIGHT_AMT)",  
DIST_VAR_NEG_AMT        CHAR"TRIM(:DIST_VAR_NEG_AMT)",   
DIST_VAR_POS_AMT        CHAR"TRIM(:DIST_VAR_POS_AMT)",  
SITE_EMAIL_ADDRESS      CHAR"TRIM(:SITE_EMAIL_ADDRESS)",   
PROCESS_FLAG     CONSTANT "N",
DFF_PROCESS_FLAG CONSTANT "1",
created_by       CONSTANT "-1",
creation_date    SYSDATE,
last_update_date SYSDATE,
last_updated_by  CONSTANT  "-1"
)
