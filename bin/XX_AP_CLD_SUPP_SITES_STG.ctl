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
-- |DRAFT 1A   24-JUN-2019   Arun DSouza          Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

LOAD DATA
APPEND
INTO TABLE XX_AP_CLD_SUPP_SITES_STG
WHEN (SUPPLIER_NAME <> 'SUPPLIER_NAME')
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
    ( 
SUPPLIER_NUMBER,
SUPPLIER_NAME,
VENDOR_SITE_CODE,
VENDOR_SITE_CODE_ALT,
RFQ_ONLY_SITE_FLAG,
PURCHASING_SITE_FLAG,
PCARD_SITE_FLAG,
PAY_SITE_FLAG,
PRIMARY_PAY_SITE_FLAG,
FAX_AREA_CODE,
FAX,
INACTIVE_DATE,
CUSTOMER_NUM,
SHIP_VIA_LOOKUP_CODE,
FREIGHT_TERMS_LOOKUP_CODE,
FOB_LOOKUP_CODE,
TERMS_DATE_BASIS,
PAY_GROUP_LOOKUP_CODE,
PAYMENT_PRIORITY,
TERMS_NAME,
INVOICE_AMOUNT_LIMIT,
PAY_DATE_BASIS_LOOKUP_CODE,
ALWAYS_TAKE_DISC_FLAG,
INVOICE_CURRENCY_CODE,
PAYMENT_CURRENCY_CODE,
HOLD_ALL_PAYMENTS_FLAG,
HOLD_FUTURE_PAYMENTS_FLAG,
HOLD_UNMATCHED_INVOICES_FLAG,
HOLD_REASON,
HOLD_BY,
HOLD_DATE,
HOLD_FLAG,
PURCHASING_HOLD_REASON,
AUTO_CALCULATE_INTEREST_FLAG,
TAX_REPORTING_SITE_FLAG,
EXCLUDE_FREIGHT_FROM_DISCOUNT,
PAY_ON_CODE,
DEFAULT_PAY_SITE_CODE,
PAY_ON_RECEIPT_SUMMARY_CODE,
MATCH_OPTION,
COUNTRY_OF_ORIGIN_CODE,
CONSUMPTION_ADVICE_FREQUENCY,
CONSUMPTION_ADVICE_SUMMARY,
CREATE_DEBIT_MEMO_FLAG,
SUPPLIER_NOTIF_METHOD,
EMAIL_ADDRESS,
TOLERANCE_NAME,
GAPLESS_INV_NUM_FLAG,
SELLING_COMPANY_IDENTIFIER,
BANK_CHARGE_BEARER,
BANK_INSTRUCTION1_CODE,
BANK_INSTRUCTION2_CODE,
BANK_INSTRUCTION_DETAILS,
PAYMENT_REASON_CODE,
PAYMENT_REASON_COMMENTS,
DELIVERY_CHANNEL_CODE,
SETTLEMENT_PRIORITY,
PAYMENT_TEXT_MESSAGE1,
PAYMENT_TEXT_MESSAGE2,
PAYMENT_TEXT_MESSAGE3,
PAYMENT_METHOD_LOOKUP_CODE,
ALLOW_SUBSTITUTE_RECEIPTS_FLAG,
ALLOW_UNORDERED_RECEIPTS_FLAG,
ENFORCE_SHIP_TO_LOCATION_CODE,
QTY_RCV_EXCEPTION_CODE,
RECEIPT_DAYS_EXCEPTION_CODE,
DAYS_EARLY_RECEIPT_ALLOWED,
DAYS_LATE_RECEIPT_ALLOWED,
RECEIVING_ROUTING_ID,
VAT_CODE,
VAT_REGISTRATION_NUM,
REMIT_ADVICE_DELIVERY_METHOD,
REMITTANCE_EMAIL,
ATTRIBUTE_CATEGORY,
ATTRIBUTE1,
ATTRIBUTE2,
ATTRIBUTE3,
ATTRIBUTE4,
ATTRIBUTE5,
ATTRIBUTE6,
ATTRIBUTE8,
ATTRIBUTE9,
ATTRIBUTE10,
ATTRIBUTE11,
ATTRIBUTE12,
ATTRIBUTE14,
ATTRIBUTE15,
BANK_CHARGE_DEDUCTION_TYPE,
ACCTS_PAY_CONCAT_GL_SEGMENTS,
PREPAY_CODE_GL_SEGMENTS,
FUTURE_DATED_GL_SEGMENTS,
PHONE_AREA_CODE,
PHONE_NUMBER,
POSTAL_CODE,
PROVINCE,
STATE,
CITY,
ADDRESS_LINE2,
ADDRESS_LINE1,
COUNTRY,
SHIP_TO_LOCATION,
BILL_TO_LOCATION,
ORG_ID,
SITE_PROCESS_FLAG CONSTANT "1",
PROCESS_FLAG      CONSTANT "N",
 created_by       CONSTANT "-1",
 creation_date    SYSDATE,
 last_update_date SYSDATE,
 last_updated_by  CONSTANT  "-1"
)

