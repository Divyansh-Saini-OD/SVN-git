CREATE OR REPLACE VIEW XXOD_AR_DEFAULT_FIRST_PMT_V
-- +==============================================================================+
-- |                  Office Depot - Project Simplify                             |
-- |                      Wipro/Office Depot                                      |
-- +==============================================================================+
-- | Name  : XXOD_AR_DEFAULT_FIRST_PMT_V                                          |
-- | Description: R0450_Default first payment report provides on a                |
-- |              daily basis all accounts who have no prior                      |
-- |              purchasing history with Office Depot                            |
-- |               and have a invoice which is past due.                          |
-- |                                                                              |
-- |                                                                              |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version   Date         Author            Remarks                              |
-- |=======   ==========   =============     =====================================|
-- |1.0       30-JUL-2007  Antony            Initial version                      |
-- |1.1       24-JUN-2008  Ganesan JV        Modified for the defect#8028         |
-- |1.2       16-Feb-2009  Ganesan JV        Modified for the defect#13339        |
-- +==============================================================================+
("CUSTOMER_NUMBER"
, "CUSTOMER_NAME"
, "AMOUNT_PAST_DUE"
, "DAYS_PAST_DUE"
, "CREDIT_LIMIT"
, "CITY"
, "STATE"
, "TRANSACTION_NUMBER"
, "TRANSACTION_TYPE"
, "COLLECTOR_NUMBER"
, "COLLECTOR_NAME"
, "TRX_DATE") 
AS 
  SELECT HCA.account_number
        ,HP.party_name
        ,APS.amount_due_remaining
        ,TRUNC(SYSDATE) - TRUNC(APS.due_date)             -- Commented the MIN Function by Ganesan for defect 13339
        ,HCPA.overall_credit_limit
        ,HL.city
        ,HL.state
        ,APS.trx_number trx_number
        ,RCTT.name Trx_type
        ,AC.name Collector_number
        ,AC.description Collector_name
        ,RCT.trx_date   TRX_DATE                         --Added by Ranjith for defect 13339
FROM    ar_payment_schedules   APS
        ,hz_cust_accounts            HCA
        ,hz_parties                        HP
        ,hz_cust_profile_amts     HCPA
        ,hz_locations                     HL
        ,hz_party_sites                 HPS
        ,ra_customer_trx             RCT
        ,gl_sets_of_books            GSOB
        ,hz_customer_profiles        HCP          -- Added by Ganesan for defect 8028
        ,ar_collectors               AC           -- Added by Ganesan for defect 8028
        ,ra_cust_trx_types           RCTT         -- Added by Ganesan for defect 8028
WHERE APS.status             = 'OP'
AND GSOB.set_of_books_id     = fnd_profile.value('GL_SET_OF_BKS_ID')
AND GSOB.currency_code       = HCPA.currency_code
AND HCPA.cust_account_id     = APS.customer_id
AND APS.customer_id          = HCA.cust_account_id
--AND APS.customer_id          = RCT.paying_customer_id    Commented by Ganesan for defect 8028
--AND APS.customer_id          = RCT.bill_to_customer_id     --Added by Ganesan for defect 8028  -- Commented by Ranjith for defect 13339
AND APS.customer_trx_id      =rct.customer_trx_id            --Added by Ranjith for defect 13339
AND HCA.party_id             = HP.party_id
AND HPS.party_id             = HP.party_id
AND HPS.location_id          = HL.location_id
AND HCP.cust_account_id      = HCA.cust_account_id        -- Added by Ganesan for defect 8028
AND HCP.site_use_id IS NULL                               -- Added by Ganesan for defect 8028
AND AC.collector_id          = HCP.collector_id           -- Added by Ganesan for defect 8028
AND AC.name                  = 'Default Collector'
AND RCTT.cust_trx_type_id    = APS.cust_trx_type_id       -- Added by Ganesan for defect 8028
AND HPS.identifying_address_flag  = 'Y'
AND APS.amount_due_remaining  != 0
--AND TRUNC(RCT.term_due_date) <= TRUNC(SYSDATE)          Commented by Ganesan for defect 8028
AND TRUNC(APS.due_date)      <= TRUNC(SYSDATE)
AND HCPA.site_use_id IS NULL
AND NOT EXISTS (SELECT /*+ INDEX(ACR AR_CASH_RECEIPTS_N2) */ 1                                 -- Added by Ganesan for defect 8028
              FROM ar_cash_receipts ACR,
              ar_receivable_applications ARP
              WHERE ACR.cash_receipt_id = ARP.cash_receipt_id
              AND   ACR.pay_from_customer = HCA.cust_account_id
              AND   ARP.applied_customer_trx_id IS NOT NULL
              AND   ARP.status          = 'APP'
              AND   ACR.status          = 'APP'
              AND   ACR.type            = 'CASH')
/*AND EXISTS (                                         Commented by Ganesan for defect 8028
              SELECT RCTX.paying_customer_id
              FROM ra_customer_trx   RCTX
                   ,ra_cust_trx_types RCTT
              WHERE RCTX.paying_customer_id = RCT.paying_customer_id
              AND   RCTX.cust_trx_type_id   = RCTT.cust_trx_type_id
              AND   RCTT.type               ='INV'
              GROUP BY RCTX.paying_customer_id
              HAVING COUNT(RCTX.paying_customer_id) = 1
           )*/
/*GROUP BY HCA.account_number                         Commented by Ganesan for defect 13339
                 ,HP.party_name
                 ,APS.amount_due_remaining
                 ,HCPA.overall_credit_limit
                 ,HL.city
                 ,HL.state
                 ,APS.trx_number           -- Added by Ganesan for defect 8028
                 ,AC.name                  -- Added by Ganesan for defect 8028
                 ,AC.description           -- Added by Ganesan for defect 8028
                 ,RCTT.name               -- Added by Ganesan for defect 8028
                 ,RCT.trx_date           --Added by Ranjith for defect 13339
*/
;
 