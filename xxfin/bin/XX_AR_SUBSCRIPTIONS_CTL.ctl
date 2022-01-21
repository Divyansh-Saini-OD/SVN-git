-- +===========================================================================+
-- |                  Office Depot - TZ Subcriptions Project                   |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : XX_AR_SUBSCRIPTIONS_CTL.ctl                                 |
-- | Description :                                                             |
-- | Control File to load data into Table for XX_AR_SUBSCRIPTIONS_GTT          |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      07-MAR-2018 JAI_CG        Initial draft version                   |
-- |2.0      20-APR-2018 JAI_CG        Updated to load pipe delimited files    |
-- +===========================================================================+

OPTIONS (SKIP=1)

LOAD DATA

INFILE *

APPEND

INTO TABLE XX_AR_SUBSCRIPTIONS_GTT

FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '""'

TRAILING NULLCOLS 

  (CONTRACT_ID                "LTRIM(RTRIM(:CONTRACT_ID, CHR(34)), CHR(34))", 
   CONTRACT_NUMBER            "LTRIM(RTRIM(:CONTRACT_NUMBER, CHR(34)), CHR(34))",
   CONTRACT_NAME              "LTRIM(RTRIM(:CONTRACT_NAME, CHR(34)), CHR(34))",
   CONTRACT_LINE_NUMBER       "LTRIM(RTRIM(:CONTRACT_LINE_NUMBER, CHR(34)), CHR(34))",
   BILLING_DATE               "TO_DATE(LTRIM(RTRIM(:BILLING_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD')",
   CONTRACT_LINE_AMOUNT       "LTRIM(RTRIM(:CONTRACT_LINE_AMOUNT, CHR(34)), CHR(34))",
   BILLING_SEQUENCE_NUMBER    "LTRIM(RTRIM(:BILLING_SEQUENCE_NUMBER, CHR(34)), CHR(34))",
   PAYMENT_TERMS              "LTRIM(RTRIM(:PAYMENT_TERMS, CHR(34)), CHR(34))",
   UOM_CODE                   "LTRIM(RTRIM(:UOM_CODE, CHR(34)), CHR(34))",
   SERVICE_PERIOD_START_DATE  "TO_DATE(LTRIM(RTRIM(:SERVICE_PERIOD_START_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD')",
   SERVICE_PERIOD_END_DATE    "TO_DATE(LTRIM(RTRIM(:SERVICE_PERIOD_END_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD')",
   NEXT_BILLING_DATE          "DECODE(LTRIM(RTRIM(:NEXT_BILLING_DATE, CHR(34)), CHR(34)), '', '',TO_DATE(LTRIM(RTRIM(:NEXT_BILLING_DATE, CHR(34)), CHR(34)), 'RRRR-MM-DD'))",
   INVOICE_INTERFACED_FLAG    CONSTANT 'N')