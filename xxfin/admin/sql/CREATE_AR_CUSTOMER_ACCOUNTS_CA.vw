-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Providge Consulting                                |
-- +==========================================================================+
-- | Name  : CREATE_AR_CUSTOMER_ACCOUNTS_CA.vw                                |
-- | RICE# : Standard view                                                    |                                          
-- | Description : Recreate standard view using workaround identifed in MOS   |
-- |               819775.1 for 11g database upgrade issue                    |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     16-FEB-2012  R.Aldridge           Initial version Defect 16884  |
-- |                                                                          |
-- +==========================================================================+

CREATE OR REPLACE FORCE VIEW APPS.AR_CUSTOMER_ACCOUNTS_CA (
CUSTOMER_OR_LOCATION, ACCTD_OR_ENTERED, CUSTOMER_ID, CUSTOMER_NAME,
CUSTOMER_NUMBER, CUSTOMER_STATUS, ACCOUNT_STATUS, PROFILE_CLASS,
RISK_CODE, COLLECTOR_NAME, DSO, CUSTOMER_SITE_USE_ID, LOCATION,
CURRENCY_CODE, OVERALL_CREDIT_LIMIT, ORDER_CREDIT_LIMIT,
CREDIT_AVAILABLE, PASTDUE_INVOICES, BALANCE, ACCTD_BALANCE,
PASTDUE_BALANCE, ACCTD_PASTDUE_BALANCE, OPEN_CREDIT,
ACCTD_OPEN_CREDIT)
AS
SELECT 'C' ,
'A' ,
CUST_ACCT.CUST_ACCOUNT_ID ,
UPPER(SUBSTRB ( PARTY.PARTY_NAME, 1, 50 )),
CUST_ACCT.ACCOUNT_NUMBER ,
CUST_ACCT.STATUS ,
CP.ACCOUNT_STATUS ,
CPC.NAME ,
CP.RISK_CODE ,
COL.NAME ,
ROUND ( ( ( SUM ( DECODE ( PS.CLASS, 'INV', 1, 'DM', 1, 'CB', 1, 'DEP', 1
, 'BR', 1, 0 ) * PS.ACCTD_AMOUNT_DUE_REMAINING ) * MAX ( SP.CER_DSO_DAYS
) ) / DECODE ( SUM ( DECODE ( PS.CLASS, 'INV', 1, 'DM', 1,
'CB', 1, 'DEP', 1, 'BR', 1, 0 ) * DECODE ( SIGN ( TRUNC ( SYSDATE ) -
PS.TRX_DATE - SP.CER_DSO_DAYS ), - 1, (
PS.AMOUNT_DUE_ORIGINAL + NVL ( PS.AMOUNT_ADJUSTED, 0 ) ) * NVL (
PS.EXCHANGE_RATE, 1 ), 0 ) ), 0, 1, SUM ( DECODE ( PS.CLASS, 'INV', 1,
'DM', 1, 'CB', 1, 'DEP', 1, 'BR', 1, 0 ) * DECODE ( SIGN ( TRUNC (
SYSDATE ) - PS.TRX_DATE - SP.CER_DSO_DAYS
), - 1, ( PS.AMOUNT_DUE_ORIGINAL +
NVL ( PS.AMOUNT_ADJUSTED, 0 ) ) * NVL ( PS.EXCHANGE_RATE, 1 ), 0
) ) ) ), 0 ),
- 10 ,
NULL ,
NULL ,
0 ,
0 ,
0 ,
SUM ( DECODE ( PS.STATUS, 'OP', DECODE ( SIGN ( TRUNC ( SYSDATE ) - TRUNC
( NVL ( PS.DUE_DATE, SYSDATE ) ) ), 1, 1, 0 ), 0 ) ),
0 ,
SUM ( NVL ( ps.acctd_amount_due_remaining, 0 ) ) ,
0 ,
SUM ( DECODE ( SIGN ( TRUNC ( SYSDATE ) - TRUNC ( NVL ( PS.DUE_DATE,
SYSDATE ) ) ), 1, PS.ACCTD_AMOUNT_DUE_REMAINING, 0 ) ),
0 ,
SUM ( DECODE ( SIGN ( PS.ACCTD_AMOUNT_DUE_REMAINING ), - 1, (
PS.ACCTD_AMOUNT_DUE_REMAINING * - 1 ), DECODE (
PS.CLASS, 'PMT', PS.ACCTD_AMOUNT_DUE_REMAINING, 0 ) ) )
FROM ar_system_parameters sp,
hz_cust_profile_classes cpc ,
hz_customer_profiles cp ,
ar_collectors col ,
hz_cust_acct_sites a ,
hz_cust_site_uses su ,
hz_cust_accounts cust_acct ,
hz_parties party ,
ar_payment_schedules ps
WHERE cust_acct.cust_account_id = a.cust_account_id
AND cust_acct.party_id = party.party_id
AND a.cust_acct_site_id = su.cust_acct_site_id
AND su.site_use_id = ps.customer_site_use_id ( + )
AND cp.cust_account_id = cust_acct.cust_account_id
AND cp.site_use_id IS NULL
AND col.collector_id = cp.collector_id
AND cpc.profile_class_id ( + ) = cp.profile_class_id
AND NVL ( ps.receipt_confirmed_flag ( + ), 'Y') = 'Y'
GROUP BY CUST_ACCT.CUST_ACCOUNT_ID,
PARTY.PARTY_NAME ,
CUST_ACCT.ACCOUNT_NUMBER ,
CUST_ACCT.STATUS ,
CP.ACCOUNT_STATUS ,
CPC.NAME ,
CP.RISK_CODE ,
COL.NAME ;
COMMENT ON TABLE APPS.AR_CUSTOMER_ACCOUNTS_CA
IS
'(Release 11.5 Only) - 11g workaround MOS 819775.1';

 
show error
