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
-- |DRAFT 1A   24-JUN-2019   Arun DSouza          Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

LOAD DATA
APPEND
INTO TABLE XX_AP_CLD_SITE_DFF_STG
WHEN (SUPPLIER_NAME <> 'SUPPLIER_NAME')
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
    (
SUPPLIER_NUMBER,
SUPPLIER_NAME,
VENDOR_SITE_CODE,
EDI_DISTRIBUTION_CODE,
SUP_TRAIT,
BACK_ORDER_FLAG,
OD_DATE_SIGNED,
EFT_SETTLE_DAYS,
SUPPLIER_SHIP_TO,
DEDUCT_FROM_INVOICE_FLAG,
RTV_FREIGHT_PAYMENT_METHOD,
PAYMENT_FREQUENCY,
RTV_INSTRUCTIONS,
ADDL_RTV_INSTRUCTIONS,
REMOVE_PRICE_STICKER_FLAG,
CONTACT_SUPPLIER_FOR_RGA_FLAG,
DESTROY_FLAG,
SERIAL_NUM_REQUIRED_FLAG,
PERMANENT_RGA,
LEAD_TIME,
VENDOR_MIN_AMOUNT,
MASTER_VENDOR_ID,
RTV_OPTION,
DESTROY_ALLOW_AMOUNT,
MIN_RETURN_QTY,
MIN_RETURN_AMOUNT,
DAMAGE_DESTROY_LIMIT,
RTV_RELATED_SITE,
PROCESS_FLAG     CONSTANT "N",
DFF_PROCESS_FLAG CONSTANT "1"
)
