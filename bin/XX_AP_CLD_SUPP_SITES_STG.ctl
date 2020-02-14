-- +============================================================================================+
-- |                        Office Depot - Project Beacon                                       |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_AP_CLD_SUPP_SITES_STG.ctl                                                |
-- | Rice Id      : I                                                                           |
-- | Description  : Vendor Interface from Cloud                                                 |
-- | Purpose      : Load Supplier Sites.                                                        |
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
INTO TABLE XX_AP_CLD_SUPP_SITES_STG
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    ( 
SUPPLIER_NUMBER ,
SUPPLIER_NAME        CHAR"TRIM(:SUPPLIER_NAME)",
VENDOR_SITE_CODE     CHAR"TRIM(:VENDOR_SITE_CODE)",
VENDOR_SITE_CODE_ALT  CHAR"TRIM(:VENDOR_SITE_CODE_ALT)",
RFQ_ONLY_SITE_FLAG   CHAR"TRIM(:RFQ_ONLY_SITE_FLAG)",
PURCHASING_SITE_FLAG   CHAR"TRIM(:PURCHASING_SITE_FLAG)",
PCARD_SITE_FLAG        CHAR"TRIM(:PCARD_SITE_FLAG)",
PAY_SITE_FLAG          CHAR"TRIM(:PAY_SITE_FLAG)",
PRIMARY_PAY_SITE_FLAG  CHAR"TRIM(:PRIMARY_PAY_SITE_FLAG)",
FAX_AREA_CODE          CHAR"TRIM(:FAX_AREA_CODE)",
FAX                    CHAR"TRIM(:FAX)",
INACTIVE_DATE          CHAR"TRIM(:INACTIVE_DATE)",
CUSTOMER_NUM           CHAR"TRIM(:CUSTOMER_NUM)",
SHIP_VIA_LOOKUP_CODE   CHAR"TRIM(:SHIP_VIA_LOOKUP_CODE)",
FREIGHT_TERMS_LOOKUP_CODE   CHAR"TRIM(:FREIGHT_TERMS_LOOKUP_CODE)",
FOB_LOOKUP_CODE        CHAR"TRIM(:FOB_LOOKUP_CODE)",
TERMS_DATE_BASIS       CHAR"TRIM(:TERMS_DATE_BASIS)",
PAY_GROUP_LOOKUP_CODE  CHAR"TRIM(:PAY_GROUP_LOOKUP_CODE)",
PAYMENT_PRIORITY      CHAR"TRIM(:PAYMENT_PRIORITY)",
TERMS_NAME            CHAR"TRIM(:TERMS_NAME)",
INVOICE_AMOUNT_LIMIT   CHAR"TRIM(:INVOICE_AMOUNT_LIMIT)",
PAY_DATE_BASIS_LOOKUP_CODE   CHAR"TRIM(:PAY_DATE_BASIS_LOOKUP_CODE)",
ALWAYS_TAKE_DISC_FLAG   CHAR"TRIM(:ALWAYS_TAKE_DISC_FLAG)",
INVOICE_CURRENCY_CODE   CHAR"TRIM(:INVOICE_CURRENCY_CODE)",
PAYMENT_CURRENCY_CODE   CHAR"TRIM(:PAYMENT_CURRENCY_CODE)",
HOLD_ALL_PAYMENTS_FLAG   CHAR"TRIM(:HOLD_ALL_PAYMENTS_FLAG)",
HOLD_FUTURE_PAYMENTS_FLAG   CHAR"TRIM(:HOLD_FUTURE_PAYMENTS_FLAG)",
HOLD_UNMATCHED_INVOICES_FLAG   CHAR"TRIM(:HOLD_UNMATCHED_INVOICES_FLAG)",
HOLD_REASON   CHAR"TRIM(:HOLD_REASON)",
HOLD_BY       CHAR"TRIM(:HOLD_BY)",
HOLD_DATE     CHAR"TRIM(:HOLD_DATE)",
HOLD_FLAG     CHAR"TRIM(:HOLD_FLAG)",
PURCHASING_HOLD_REASON         CHAR"TRIM(:PURCHASING_HOLD_REASON)",
AUTO_CALCULATE_INTEREST_FLAG   CHAR"TRIM(:AUTO_CALCULATE_INTEREST_FLAG)",
TAX_REPORTING_SITE_FLAG        CHAR"TRIM(:TAX_REPORTING_SITE_FLAG)",
EXCLUDE_FREIGHT_FROM_DISCOUNT  CHAR"TRIM(:EXCLUDE_FREIGHT_FROM_DISCOUNT)",
PAY_ON_CODE                    CHAR"TRIM(:PAY_ON_CODE)",
DEFAULT_PAY_SITE_CODE          CHAR"TRIM(:DEFAULT_PAY_SITE_CODE)",
PAY_ON_RECEIPT_SUMMARY_CODE   CHAR"TRIM(:PAY_ON_RECEIPT_SUMMARY_CODE)",
MATCH_OPTION                  CHAR"TRIM(:MATCH_OPTION)",
COUNTRY_OF_ORIGIN_CODE        CHAR"TRIM(:COUNTRY_OF_ORIGIN_CODE)",
CONSUMPTION_ADVICE_FREQUENCY  CHAR"TRIM(:CONSUMPTION_ADVICE_FREQUENCY)",
CONSUMPTION_ADVICE_SUMMARY   CHAR"TRIM(:CONSUMPTION_ADVICE_SUMMARY)",
CREATE_DEBIT_MEMO_FLAG       CHAR"TRIM(:CREATE_DEBIT_MEMO_FLAG)",
SUPPLIER_NOTIF_METHOD        CHAR"TRIM(:SUPPLIER_NOTIF_METHOD)",
EMAIL_ADDRESS                CHAR"TRIM(:EMAIL_ADDRESS)",
TOLERANCE_NAME               CHAR"TRIM(:TOLERANCE_NAME)",
GAPLESS_INV_NUM_FLAG         CHAR"TRIM(:GAPLESS_INV_NUM_FLAG)",
SELLING_COMPANY_IDENTIFIER   CHAR"TRIM(:SELLING_COMPANY_IDENTIFIER)",
BANK_CHARGE_BEARER           CHAR"TRIM(:BANK_CHARGE_BEARER)",
BANK_INSTRUCTION1_CODE       CHAR"TRIM(:BANK_INSTRUCTION1_CODE)",
BANK_INSTRUCTION2_CODE       CHAR"TRIM(:BANK_INSTRUCTION2_CODE)",
BANK_INSTRUCTION_DETAILS   CHAR"TRIM(:BANK_INSTRUCTION_DETAILS)",
PAYMENT_REASON_CODE        CHAR"TRIM(:PAYMENT_REASON_CODE)",
PAYMENT_REASON_COMMENTS   CHAR"TRIM(:PAYMENT_REASON_COMMENTS)",
DELIVERY_CHANNEL_CODE   CHAR"TRIM(:DELIVERY_CHANNEL_CODE)",
SETTLEMENT_PRIORITY   CHAR"TRIM(:SETTLEMENT_PRIORITY)",
PAYMENT_TEXT_MESSAGE1   CHAR"TRIM(:PAYMENT_TEXT_MESSAGE1)",
PAYMENT_TEXT_MESSAGE2   CHAR"TRIM(:PAYMENT_TEXT_MESSAGE2)",
PAYMENT_TEXT_MESSAGE3   CHAR"TRIM(:PAYMENT_TEXT_MESSAGE3)",
PAYMENT_METHOD_LOOKUP_CODE   CHAR"TRIM(:PAYMENT_METHOD_LOOKUP_CODE)",
ALLOW_SUBSTITUTE_RECEIPTS_FLAG   CHAR"TRIM(:ALLOW_SUBSTITUTE_RECEIPTS_FLAG)",
ALLOW_UNORDERED_RECEIPTS_FLAG   CHAR"TRIM(:ALLOW_UNORDERED_RECEIPTS_FLAG)",
ENFORCE_SHIP_TO_LOCATION_CODE   CHAR"TRIM(:ENFORCE_SHIP_TO_LOCATION_CODE)",
QTY_RCV_EXCEPTION_CODE          CHAR"TRIM(:QTY_RCV_EXCEPTION_CODE)",
RECEIPT_DAYS_EXCEPTION_CODE     CHAR"TRIM(:RECEIPT_DAYS_EXCEPTION_CODE)",
DAYS_EARLY_RECEIPT_ALLOWED      CHAR"TRIM(:DAYS_EARLY_RECEIPT_ALLOWED)",
DAYS_LATE_RECEIPT_ALLOWED       CHAR"TRIM(:DAYS_LATE_RECEIPT_ALLOWED)",
RECEIVING_ROUTING_ID            CHAR"TRIM(:RECEIVING_ROUTING_ID)",
VAT_CODE                        CHAR"TRIM(:VAT_CODE)",
VAT_REGISTRATION_NUM   CHAR"TRIM(:VAT_REGISTRATION_NUM)",
REMIT_ADVICE_DELIVERY_METHOD   CHAR"TRIM(:REMIT_ADVICE_DELIVERY_METHOD)",
REMITTANCE_EMAIL   CHAR"TRIM(:REMITTANCE_EMAIL)",
ATTRIBUTE_CATEGORY   CHAR"TRIM(:ATTRIBUTE_CATEGORY)",
ATTRIBUTE1   CHAR"TRIM(:ATTRIBUTE1)",
ATTRIBUTE2   CHAR"TRIM(:ATTRIBUTE2)",
ATTRIBUTE3   CHAR"TRIM(:ATTRIBUTE3)",
ATTRIBUTE4   CHAR"TRIM(:ATTRIBUTE4)",
ATTRIBUTE5   CHAR"TRIM(:ATTRIBUTE5)",
ATTRIBUTE6   CHAR"TRIM(:ATTRIBUTE6)",
ATTRIBUTE8   CHAR"TRIM(:ATTRIBUTE8)",
ATTRIBUTE9   CHAR"TRIM(:ATTRIBUTE9)",
ATTRIBUTE10   CHAR"TRIM(:ATTRIBUTE10)",
ATTRIBUTE11   CHAR"TRIM(:ATTRIBUTE11)",
ATTRIBUTE12   CHAR"TRIM(:ATTRIBUTE12)",
ATTRIBUTE14   CHAR"TRIM(:ATTRIBUTE14)",
ATTRIBUTE15   CHAR"TRIM(:ATTRIBUTE15)",
BANK_CHARGE_DEDUCTION_TYPE   CHAR"TRIM(:BANK_CHARGE_DEDUCTION_TYPE)",
ACCTS_PAY_CONCAT_GL_SEGMENTS   CHAR"TRIM(:ACCTS_PAY_CONCAT_GL_SEGMENTS)",
PREPAY_CODE_GL_SEGMENTS   CHAR"TRIM(:PREPAY_CODE_GL_SEGMENTS)",
FUTURE_DATED_GL_SEGMENTS   CHAR"TRIM(:FUTURE_DATED_GL_SEGMENTS)",
PHONE_AREA_CODE            CHAR"TRIM(:PHONE_AREA_CODE)",
PHONE_NUMBER   CHAR"TRIM(:PHONE_NUMBER)",
POSTAL_CODE   CHAR"TRIM(:POSTAL_CODE)",
PROVINCE       CHAR"TRIM(:PROVINCE)",
STATE          CHAR"TRIM(:STATE)",
CITY           CHAR"TRIM(:CITY)",
ADDRESS_LINE1   CHAR"TRIM(:ADDRESS_LINE1)",
ADDRESS_LINE2   CHAR"TRIM(:ADDRESS_LINE2)",
COUNTRY   CHAR"TRIM(:COUNTRY)",
SHIP_TO_LOCATION   CHAR"TRIM(:SHIP_TO_LOCATION)",
BILL_TO_LOCATION   CHAR"TRIM(:BILL_TO_LOCATION)",
ORG_ID   CHAR"TRIM(:ORG_ID)",
ATTRIBUTE7   CHAR"TRIM(:ATTRIBUTE7)",
ATTRIBUTE13   CHAR"TRIM(:ATTRIBUTE13)",
SERVICE_TOLERANCE   CHAR"TRIM(:SERVICE_TOLERANCE)",
QTY_RCV_TOLERANCE        CHAR"TRIM(:QTY_RCV_TOLERANCE)",    
INSPECTION_REQUIRED_FLAG CHAR"TRIM(:INSPECTION_REQUIRED_FLAG)",
RECEIPT_REQUIRED_FLAG    CHAR"TRIM(:RECEIPT_REQUIRED_FLAG)", 
ADDRESS_LINE3   CHAR"TRIM(:ADDRESS_LINE3)",
ADDRESS_LINE4   CHAR"TRIM(:ADDRESS_LINE4)", 
ATTRIBUTE23   CHAR"TRIM(:ATTRIBUTE23)",
COUNTY           CHAR"TRIM(:COUNTY)",
PAY_ALONE_FLAG  CHAR"TRIM(:PAY_ALONE_FLAG)",  
SITE_PROCESS_FLAG CONSTANT "1",
PROCESS_FLAG      CONSTANT "N",
 created_by       CONSTANT "-1",
 creation_date    SYSDATE,
 last_update_date SYSDATE,
 last_updated_by  CONSTANT  "-1"
)

