-- +===========================================================================+
-- |                  Office Depot - TZ Subcriptions Project                   |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : XX_AR_CONTRACTS_CTL.ctl                                     |
-- | Description :                                                             |
-- | Control File to load data into Table for XX_AR_CONTRACTS_GTT              |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      07-MAR-2018 JAI_CG        Initial draft version                   |
-- |2.0      21-APR-2018 JAI_CG        Updated to load pipe delimited files    |
-- +===========================================================================+

OPTIONS (SKIP=1)

LOAD DATA

INFILE *

APPEND

INTO TABLE XX_AR_CONTRACTS_GTT

FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '""'

TRAILING NULLCOLS 

  (CONTRACT_ID                "LTRIM(RTRIM(:CONTRACT_ID, CHR(34)), CHR(34))",
   CONTRACT_NUMBER            "LTRIM(RTRIM(:CONTRACT_NUMBER, CHR(34)), CHR(34))",
   CONTRACT_NAME              "LTRIM(RTRIM(:CONTRACT_NAME, CHR(34)), CHR(34))",
   CONTRACT_STATUS            "LTRIM(RTRIM(:CONTRACT_STATUS, CHR(34)), CHR(34))",
   CONTRACT_MAJOR_VERSION     "LTRIM(RTRIM(:CONTRACT_MAJOR_VERSION, CHR(34)), CHR(34))",
   CONTRACT_START_DATE        "TO_DATE(LTRIM(RTRIM(:CONTRACT_START_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD')",
   CONTRACT_END_DATE          "TO_DATE(LTRIM(RTRIM(:CONTRACT_END_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD')",
   CONTRACT_BILLING_FREQ      "LTRIM(RTRIM(:CONTRACT_BILLING_FREQ, CHR(34)), CHR(34))",
   BILL_CUST_ACCOUNT_NUMBER   "LTRIM(RTRIM(:BILL_CUST_ACCOUNT_NUMBER, CHR(34)), CHR(34))",
   BILL_TO_OSR                "LTRIM(RTRIM(:BILL_TO_OSR, CHR(34)), CHR(34))",
   BILL_CUST_NAME             "LTRIM(RTRIM(:BILL_CUST_NAME, CHR(34)), CHR(34))",
   BILL_TO_SITE_OSR           "LTRIM(RTRIM(:BILL_TO_SITE_OSR, CHR(34)), CHR(34))",
   SHIP_CUST_ACCOUNT_NUMBER   "LTRIM(RTRIM(:SHIP_CUST_ACCOUNT_NUMBER, CHR(34)), CHR(34))",
   SHIP_TO_OSR                "LTRIM(RTRIM(:SHIP_TO_OSR, CHR(34)), CHR(34))",
   SHIP_CUST_NAME             "LTRIM(RTRIM(:SHIP_CUST_NAME, CHR(34)), CHR(34))",
   SHIP_TO_SITE_OSR           "LTRIM(RTRIM(:SHIP_TO_SITE_OSR, CHR(34)), CHR(34))",
   INITIAL_ORDER_NUMBER       "LTRIM(RTRIM(:INITIAL_ORDER_NUMBER, CHR(34)), CHR(34))",
   STORE_NUMBER               "LTRIM(RTRIM(:STORE_NUMBER, CHR(34)), CHR(34))",
   PAYMENT_TYPE               "LTRIM(RTRIM(:PAYMENT_TYPE, CHR(34)), CHR(34))",
   PAYMENT_IDENTIFIER         "LTRIM(RTRIM(:PAYMENT_IDENTIFIER, CHR(34)), CHR(34))",
   CARD_TYPE                  "DECODE(LTRIM(RTRIM(:CARD_TYPE, CHR(34)), CHR(34)), 'American Express', 'AMEX', LTRIM(RTRIM(:CARD_TYPE, CHR(34)), CHR(34)))",
   CARD_TOKEN                 "LTRIM(RTRIM(:CARD_TOKEN, CHR(34)), CHR(34))",
   CARD_EXPIRATION_DATE       "TO_DATE(LTRIM(RTRIM(:CARD_EXPIRATION_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD')",
   CARD_ENCRYPTION_LABEL      "REPLACE(LTRIM(RTRIM(:CARD_ENCRYPTION_LABEL, CHR(34)), CHR(34)),CHR(13),'')",
   REF_ASSOCIATE_NUMBER       "LTRIM(RTRIM(:REF_ASSOCIATE_NUMBER, CHR(34)), CHR(34))",
   SALES_REPRESENTATIVE       "LTRIM(RTRIM(:SALES_REPRESENTATIVE, CHR(34)), CHR(34))",
   CARD_HOLDER_NAME           "LTRIM(RTRIM(:CARD_HOLDER_NAME, CHR(34)), CHR(34))",
   CARD_TOKENIZED_FLAG        "LTRIM(RTRIM(:CARD_TOKENIZED_FLAG, CHR(34)), CHR(34))",   
   CARD_ENCRYPTION_HASH       "LTRIM(RTRIM(:CARD_ENCRYPTION_HASH, CHR(34)), CHR(34))",
   LOYALTY_MEMBER_NUMBER      "LTRIM(RTRIM(:LOYALTY_MEMBER_NUMBER, CHR(34)), CHR(34))",
   TOTAL_AMOUNT               "LTRIM(RTRIM(NVL(TRIM(:TOTAL_AMOUNT), 0), CHR(34)), CHR(34))",
   CONTRACT_LINE_NUMBER       "LTRIM(RTRIM(:CONTRACT_LINE_NUMBER, CHR(34)), CHR(34))",
   ITEM_NAME                  "LTRIM(RTRIM(:ITEM_NAME, CHR(34)), CHR(34))",
   ITEM_DESCRIPTION           "LTRIM(RTRIM(:ITEM_DESCRIPTION, CHR(34)), CHR(34))",
   QUANTITY                   "LTRIM(RTRIM(:QUANTITY, CHR(34)), CHR(34))",
   UOM_CODE                   "LTRIM(RTRIM(:UOM_CODE, CHR(34)), CHR(34))",
   INITIAL_ORDER_LINE         "LTRIM(RTRIM(:INITIAL_ORDER_LINE, CHR(34)), CHR(34))",
   PAYMENT_TERM               "LTRIM(RTRIM(:PAYMENT_TERM, CHR(34)), CHR(34))",
   CONTRACT_LINE_START_DATE   "TO_DATE(LTRIM(RTRIM(:CONTRACT_LINE_START_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD')",
   CONTRACT_LINE_END_DATE     "TO_DATE(LTRIM(RTRIM(:CONTRACT_LINE_END_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD')",
   CONTRACT_LINE_BILLING_FREQ "LTRIM(RTRIM(:CONTRACT_LINE_BILLING_FREQ, CHR(34)), CHR(34))",
   CUSTOMER_EMAIL             "LTRIM(RTRIM(:CUSTOMER_EMAIL, CHR(34)), CHR(34))",
   CANCELLATION_DATE          "DECODE(LTRIM(RTRIM(:CANCELLATION_DATE, CHR(34)), CHR(34)), '', '',TO_DATE(LTRIM(RTRIM(:CANCELLATION_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD'))",
   PROGRAM                    "LTRIM(RTRIM(:PROGRAM, CHR(34)), CHR(34))",
   LINE_TYPE                  "LTRIM(RTRIM(:LINE_TYPE, CHR(34)), CHR(34))",
   PAYMENT_LAST_UPDATE_DATE   "DECODE(LTRIM(RTRIM(:PAYMENT_LAST_UPDATE_DATE, CHR(34)), CHR(34)), '', '',TO_DATE(LTRIM(RTRIM(:PAYMENT_LAST_UPDATE_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD'))",
   INITIAL_BILLING_SEQUENCE   "LTRIM(RTRIM(:INITIAL_BILLING_SEQUENCE, CHR(34)), CHR(34))",
   VENDOR_NUMBER              "REPLACE(LTRIM(RTRIM(:VENDOR_NUMBER, CHR(34)), CHR(34)),CHR(13),'')",
   PURCHASE_ORDER             "LTRIM(RTRIM(:PURCHASE_ORDER, CHR(34)), CHR(34))",
   DESKTOP                    "LTRIM(RTRIM(:DESKTOP, CHR(34)), CHR(34))",
   COST_CENTER                "LTRIM(RTRIM(:COST_CENTER, CHR(34)), CHR(34))",
   RELEASE_NUM                "LTRIM(RTRIM(:RELEASE_NUM, CHR(34)), CHR(34))",
   CONTRACT_USER_STATUS       "LTRIM(RTRIM(:CONTRACT_USER_STATUS, CHR(34)), CHR(34))",
   EXTERNAL_SOURCE            "REPLACE(LTRIM(RTRIM(:EXTERNAL_SOURCE, CHR(34)), CHR(34)),CHR(13),'')",
   CONTRACT_NUMBER_MODIFIER   "REPLACE(LTRIM(RTRIM(:CONTRACT_NUMBER_MODIFIER, CHR(34)), CHR(34)),CHR(13),'')")