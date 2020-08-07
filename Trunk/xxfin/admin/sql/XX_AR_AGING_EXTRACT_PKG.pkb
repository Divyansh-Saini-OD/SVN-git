CREATE OR REPLACE
PACKAGE BODY XX_AR_AGING_EXTRACT_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  XX_AR_AGING_EXTRACT_PKG                       |
-- | Description      :  This Package is used by to Extract Cusromer   |
-- |                     aging Information                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 06-Mar-2009  Ganesan JV       Initial draft version       |
-- |                                        developed from the AR AGING|
-- |                                        Report                     |
-- |1.1       31-Mar-2009  Ganesan JV       Changed the code for       |
-- |                                        tuning the performance     |
-- |                                        for defect 13502           |
-- |1.2       24-Sep-09    Harini G         Modified code to remove    |
-- |                                        collection strategy parameter|
-- |                                        for defect 2322            |
-- +===================================================================+
gc_file_path VARCHAR2(500)  := 'XXFIN_OUTBOUND';

PROCEDURE write_log(p_debug_flag VARCHAR2,
                                        p_msg VARCHAR2)
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  IT Convergence/Wirpo?Office Depot                |
-- +===================================================================+
-- | Name             :  write_log                                                        |
-- | Description      :  This procedure is used to write in to log file|
-- |                     based on the debug flag                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date              Author                  Remarks                   |
-- |=======   ==========        =============    ======================     |
-- |DRAFT 1.0 06-Mar-2009  Ganesan JV       Initial draft version       |
-- |                                        developed from the AR AGING|
-- |                                        Report                     |
-- |1.1       31-Mar-2009  Ganesan JV       Changed the code for       |
-- |                                        tuning the performance     |
-- |                                        for defect 13502           |
-- |1.2       24-Sep-09    Harini G         Modified code to remove    |
-- |                                        collection strategy parameter|
-- |                                        for defect 2322            |
-- +===================================================================+
AS
BEGIN
        IF(p_debug_flag = 'Y') Then
                fnd_file.put_line(FND_FILE.LOG,p_msg);
        END IF;
END;

PROCEDURE ar_aging_extract(p_ret_code            OUT   NUMBER
                           ,p_err_msg            OUT   VARCHAR2
                           ,p_reporting_level          VARCHAR2
                           ,p_reporting_entity_id      VARCHAR2
                                                      ,p_dynamic_group            VARCHAR2
                                                      ,p_181_past_days_low        NUMBER
                                                      ,p_181_past_days_high       NUMBER
                                                      ,p_61_past_days_low         NUMBER
                                                      ,p_61_past_days_high        NUMBER
                                                      ,p_31_past_days_low         NUMBER
                                                      ,p_31_past_days_high        NUMBER
                                                      ,p_outstanding_amt_low      NUMBER
                                                      ,p_outstanding_amt_high     NUMBER
                                                      ,p_collector_low            VARCHAR2
                                                      ,p_collector_high           VARCHAR2
                                                      ,p_customer_class           VARCHAR2
                                                     -- ,p_collection_strategy      VARCHAR2  Commented for defect 2322
                                                      ,p_last_payment_date_low    VARCHAR2
                                                      ,p_last_payment_date_high   VARCHAR2
                                                      ,p_invoice_date_low         VARCHAR2
                                                      ,p_invoice_date_high        VARCHAR2
                                                      ,p_as_of_date               VARCHAR2
                                                      ,p_customer_num_low         VARCHAR2
                                                      ,p_customer_num_high        VARCHAR2
                                                      ,p_salesrep_low             VARCHAR2
                                                      ,p_salesrep_high            VARCHAR2
                                                      ,p_debug_flag               VARCHAR2)
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  IT Convergence/Wirpo?Office Depot                |
-- +===================================================================+
-- | Name             :  ar_aging_extract                                 |
-- | Description      :  This Procedure is to get the customer aging   |
-- |                     information                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date              Author                  Remarks                   |
-- |=======   ==========        =============    ======================     |
-- |DRAFT 1.0 06-Mar-2009  Ganesan JV       Initial draft version       |
-- |                                        developed from the AR AGING|
-- |                                        Report                     |
-- |1.1       31-Mar-2009  Ganesan JV       Changed the code for       |
-- |                                        tuning the performance     |
-- |                                        for defect 13502           |
-- |1.2       24-Sep-09    Harini G         Modified code to remove    |
-- |                                        collection strategy parameter|
-- |                                        for defect 2322            |
-- +===================================================================+
AS
-------------------------------------------------------------------------
-- The Cursor Selects the Aging Information for the passed information --
-------------------------------------------------------------------------

CURSOR lcu_main(P_CURRENCY_CODE VARCHAR2
                ,p_collection_level VARCHAR2
                                         ,p_as_of_date       DATE
                                         ,p_last_payment_date_low  DATE
                                         ,p_last_payment_date_high DATE
                                         ,p_invoice_date_low       DATE
                                         ,p_invoice_date_high      DATE)
IS
/*SELECT CUST_NO_1                         -- Commented by Ganesan for Improving the performance
                 ,CUST_ID
                 ,PARTY_ID1
                 ,SHORT_CUST_NAME_1
                 ,CUST_SORT_1
                 --,SITE_USE_ID
                 ,COLLECTOR_NAME_1
                 ,CREDIT_LIMIT_1
                 ,CUSTOMER_CLASS1_1
       ,SUM(TOTAL_CUST_AMT_1) TOTAL_CUST_AMT_1
                 ,SUM(TOTAL_CUST_B0_1)  TOTAL_CUST_B0_1
                 ,SUM(TOTAL_CUST_B1_1)  TOTAL_CUST_B1_1
                 ,SUM(TOTAL_CUST_B2_1)  TOTAL_CUST_B2_1
                 ,SUM(TOTAL_CUST_B3_1)  TOTAL_CUST_B3_1
                 ,SUM(TOTAL_CUST_B4_1)  TOTAL_CUST_B4_1
                 ,SUM(TOTAL_CUST_B5_1)  TOTAL_CUST_B5_1
                 ,SUM(TOTAL_CUST_B6_1)  TOTAL_CUST_B6_1
                 ,SUM(TOTAL_CUST_B7_1)  TOTAL_CUST_B7_1
                 ,SUM(TOTAL_CUST_B8_1)  TOTAL_CUST_B8_1
                 ,SUM(TOTAL_CUST_B9_1)  TOTAL_CUST_B9_1
                 ,CUSTOMER_CATEGORY
       ,RISK_CODE
FROM
        (*/
                SELECT HCA.account_number                                          CUST_NO_1
                                ,HCA.cust_account_id                                         CUST_ID
                                ,HP.party_id                                                 PARTY_ID1
                                ,HP.party_name                                               SHORT_CUST_NAME_1
                                ,DECODE(HP.party_name,NULL,2,1)                              CUST_SORT_1
                                ,APS.customer_site_use_id                                    SITE_USE_ID
                                ,AC.name                                                     COLLECTOR_NAME_1
                                ,HCPA.overall_credit_limit                                   CREDIT_LIMIT_1
                                ,AL.meaning                                                  CUSTOMER_CLASS1_1
                                ,RCT.customer_trx_id                                         customer_trx_id
                                ,RCT.trx_number                                              TRX_NUMBER
                                ,(CEIL(TRUNC(p_as_of_date) - APS.due_date))                 DAYS_PAST_DUE
                                ,XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,p_as_of_date) TOTAL_CUST_AMT_1
                                /*,(DECODE(GREATEST(-9999,CEIL(TRUNC(p_as_of_date)-APS.due_date)),LEAST(0,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B0_1
                                ,(DECODE(GREATEST(1,CEIL(TRUNC(p_as_of_date)  -APS.due_date)),LEAST(30,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B1_1
                                ,(DECODE(GREATEST(31,CEIL(TRUNC(p_as_of_date) -APS.due_date)),LEAST(60,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B2_1
                                ,(DECODE(GREATEST(61,CEIL(TRUNC(p_as_of_date) -APS.due_date)),LEAST(90,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B3_1
                                ,(DECODE(GREATEST(91,CEIL(TRUNC(p_as_of_date) -APS.due_date)),LEAST(180,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B4_1
                                ,(DECODE(GREATEST(181,CEIL(TRUNC(p_as_of_date)-APS.due_date)),LEAST(365,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B5_1
                                ,(DECODE(GREATEST(366,CEIL(TRUNC(p_as_of_date)-APS.due_date)),LEAST(9999999,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B6_1
                                ,(DECODE(GREATEST(31,CEIL(TRUNC(p_as_of_date) -APS.due_date)),LEAST(9999999,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B7_1
                                ,(DECODE(GREATEST(61,CEIL(TRUNC(p_as_of_date) -APS.due_date)),LEAST(9999999,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B8_1
                                ,(DECODE(GREATEST(181,CEIL(TRUNC(p_as_of_date)-APS.due_date)),LEAST(9999999,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B9_1*/
                                ,AL_CAT.meaning                                              CUSTOMER_CATEGORY
                                ,HCP.risk_code                                               RISK_CODE
                FROM   ra_customer_trx        RCT
                                ,ar_payment_schedules   APS
                                ,hz_cust_accounts       HCA
                                ,hz_customer_profiles   HCP
                                ,hz_cust_profile_amts   HCPA
                                ,hz_parties             HP
                                ,ar_collectors          AC
                                ,ar_lookups             AL
                                ,ar_trx_bal_summary     ATBS
                                 ,hz_party_sites  HPS
                                 ,ar_lookups      AL_CAT
                WHERE  RCT.customer_trx_id             = APS.customer_trx_id
                  AND  APS.customer_id                 = HCA.cust_account_id
                  AND  HCA.cust_account_id             = HCP.cust_account_id
                  AND  HCA.customer_class_code         = AL.lookup_code(+)
                  AND  NVL(AL.lookup_type,'CUSTOMER CLASS')                  = 'CUSTOMER CLASS'
                  AND  HP.category_code                = AL_CAT.lookup_code(+)
                  AND  NVL(AL_CAT.lookup_type,'CUSTOMER_CATEGORY')              = 'CUSTOMER_CATEGORY'
                  AND  HCP.collector_id                = AC.collector_id
                  AND  HCP.cust_account_profile_id     = HCPA.cust_account_profile_id(+)
                  AND  HCA.party_id                    = HP.party_id
                  AND  ATBS.cust_account_id(+)            = APS.customer_id
                  AND  ATBS.site_use_id(+)                = APS.customer_site_use_id
                  AND  APS.class                       <> 'PMT'
                  AND  HCP.site_use_id IS NULL
                  AND  ATBS.currency(+)                   = P_CURRENCY_CODE
                  AND  HCPA.currency_code(+)              = P_CURRENCY_CODE
                  AND  ATBS.org_id(+)                     = P_REPORTING_ENTITY_ID
                  AND  APS.gl_date                    <= P_AS_OF_DATE
                  AND  APS.gl_date_closed              > P_AS_OF_DATE
                  AND  HP.party_id  = HPS.party_id(+)
                  AND  HPS.status(+)                      = 'A'
                  AND  HPS.identifying_address_flag(+)    = 'Y'
                  AND  NVL(HCA.account_number,'X') BETWEEN NVL(p_customer_num_low,NVL(HCA.account_number,'X')) AND NVL(p_customer_num_high,NVL(HCA.account_number,'X'))
                  AND  NVL(ATBS.last_payment_date,sysdate) BETWEEN NVL(p_last_payment_date_low,NVL(ATBS.last_payment_date,sysdate))
                                                                                                             AND NVL(p_last_payment_date_high,NVL(ATBS.last_payment_date,sysdate))
                  AND  NVL(AC.name,'X') BETWEEN NVL(p_collector_low,NVL(AC.name,'X')) AND  NVL(p_collector_high,NVL(AC.name,'X'))
                  AND  NVL(AL.lookup_code,'X') = NVL(p_customer_class,NVL(AL.lookup_code,'X'))
                  AND  NVL(RCT.trx_date,sysdate) BETWEEN NVL(p_invoice_date_low, NVL(RCT.trx_date,sysdate))
                                                                               AND NVL(p_invoice_date_high, NVL(RCT.trx_date,sysdate))
                  AND  NVL(XXOD_AR_SFA_HIERARCHY_PKG.GET_SALESREP_NAME(HPS.party_site_id),'X') BETWEEN NVL(p_salesrep_low,NVL(XXOD_AR_SFA_HIERARCHY_PKG.GET_SALESREP_NAME(HPS.party_site_id),'X'))
                                                                                                                                                                                                          AND NVL(p_salesrep_high,NVL(XXOD_AR_SFA_HIERARCHY_PKG.GET_SALESREP_NAME(HPS.party_site_id),'X'))
                UNION ALL
                SELECT HCA.account_number                                          CUST_NO_1
                                ,HCA.cust_account_id                                         CUST_ID
                                ,HP.party_id                                                 PARTY_ID1
                                ,DECODE(HP.party_name
                                                 ,NULL
                                                 ,'Unidentified Payment'
                                                 ,HP.party_name
                                                 )                                                     SHORT_CUST_NAME_1
                                ,DECODE(HP.party_name,NULL,2,1)                              CUST_SORT_1
                                ,APS.customer_site_use_id                                    SITE_USE_ID
                                ,AC.name                                                     COLLECTOR_NAME_1
                                ,HCPA.overall_credit_limit                                   CREDIT_LIMIT_1
                          ,AL.meaning                                                  CUSTOMER_CLASS1_1
                                ,APS.customer_trx_id                                        customer_trx_id
                                ,null                                                       TRX_NUMBER
                                ,(CEIL(TRUNC(p_as_of_date) - APS.due_date))                 DAYS_PAST_DUE
                                ,XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,p_as_of_date) TOTAL_CUST_AMT_1
                                /*,(DECODE(GREATEST(-9999,CEIL(TRUNC(p_as_of_date)-APS.due_date)),least(0,ceil(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B0_1
                                ,(DECODE(GREATEST(1,CEIL(TRUNC(p_as_of_date)  -APS.due_date)),least(30,ceil(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B1_1
                                ,(DECODE(GREATEST(31,CEIL(TRUNC(p_as_of_date) -APS.due_date)),least(60,ceil(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B2_1
                                ,(DECODE(GREATEST(61,CEIL(TRUNC(p_as_of_date) -APS.due_date)),least(90,ceil(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B3_1
                                ,(DECODE(GREATEST(91,CEIL(TRUNC(p_as_of_date) -APS.due_date)),least(180,ceil(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B4_1
                                ,(DECODE(GREATEST(181,CEIL(TRUNC(p_as_of_date)-APS.due_date)),least(365,ceil(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B5_1
                                ,(DECODE(GREATEST(366,CEIL(TRUNC(p_as_of_date)-APS.due_date)),least(9999999,ceil(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B6_1
                                ,(DECODE(GREATEST(31,CEIL(TRUNC(p_as_of_date) -APS.due_date)),least(9999999,ceil(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B7_1
                                ,(DECODE(GREATEST(61,CEIL(TRUNC(p_as_of_date) -APS.due_date)),least(9999999,ceil(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B8_1
                                ,(DECODE(GREATEST(181,CEIL(TRUNC(p_as_of_date)-APS.due_date)),LEAST(9999999,CEIL(TRUNC(p_as_of_date)-APS.due_date)),1,0)*XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.payment_schedule_id,APS.class,P_AS_OF_DATE)) TOTAL_CUST_B9_1*/
                                ,AL_CAT.meaning                                              CUSTOMER_CATEGORY
                                ,HCP.risk_code                                               RISK_CODE
                FROM   ar_payment_schedules      APS
                                ,hz_cust_accounts          HCA
                                ,hz_customer_profiles      HCP
                                ,hz_cust_profile_amts      HCPA
                                ,hz_parties                HP
                                ,ar_collectors             AC
                                ,ar_lookups                AL
                                ,ar_trx_bal_summary        ATBS
                                 ,hz_party_sites  HPS
                                 ,ar_lookups      AL_CAT
                WHERE APS.customer_id             = HCA.cust_account_id (+)
                  AND   HCA.cust_account_id         = HCP.cust_account_id (+)
                  AND   HCP.collector_id            = AC.collector_id (+)
                  AND    HCA.customer_class_code         = AL.lookup_code(+)
                  AND    NVL(AL.lookup_type,'CUSTOMER CLASS')                  = 'CUSTOMER CLASS'-- Added by Ganesan fo handling setup problems with Customers.
                  AND    HP.category_code                = AL_CAT.lookup_code(+)
                  AND    NVL(AL_CAT.lookup_type,'CUSTOMER_CATEGORY')              = 'CUSTOMER_CATEGORY'
                  ------AND   HCA.customer_class_code     = AL.lookup_code (+)
                  ------AND   AL.lookup_type (+)          = 'CUSTOMER CLASS'
                  AND   HCP.cust_account_profile_id = HCPA.cust_account_profile_id (+)
                  AND   HCA.party_id                = HP.party_id (+)
                  AND   ATBS.cust_account_id (+)    = APS.customer_id
                  AND   ATBS.site_use_id (+)        = APS.customer_site_use_id
                  AND   APS.class                   = 'PMT'
                  AND   HCP.site_use_id IS NULL
                  AND   ATBS.currency (+)           = P_CURRENCY_CODE
                  AND   HCPA.currency_code (+)      = P_CURRENCY_CODE
                  AND   ATBS.org_id (+)             = P_REPORTING_ENTITY_ID
                  AND   APS.gl_date                <= P_AS_OF_DATE
                  AND   APS.gl_date_closed          > P_AS_OF_DATE
                  AND   HP.party_id  = HPS.party_id(+)
                  AND   HPS.status(+)                      = 'A'
                  AND   HPS.identifying_address_flag(+)    = 'Y'
                  AND   NVL(HCA.account_number,'X') BETWEEN NVL(p_customer_num_low,NVL(HCA.account_number,'X')) AND NVL(p_customer_num_high,NVL(HCA.account_number,'X'))
                  AND  NVL(ATBS.last_payment_date,sysdate) BETWEEN NVL(p_last_payment_date_low,NVL(ATBS.last_payment_date,sysdate))
                                                                                                             AND NVL(p_last_payment_date_high,NVL(ATBS.last_payment_date,sysdate))
                  AND  NVL(AC.name,'X') BETWEEN NVL(p_collector_low,NVL(AC.name,'X')) AND  NVL(p_collector_high,NVL(AC.name,'X'))
                  AND  NVL(AL.lookup_code,'X') = NVL(p_customer_class,NVL(AL.lookup_code,'X'))
                  AND  NVL(XXOD_AR_SFA_HIERARCHY_PKG.GET_SALESREP_NAME(HPS.party_site_id),'X') BETWEEN NVL(p_salesrep_low,NVL(XXOD_AR_SFA_HIERARCHY_PKG.GET_SALESREP_NAME(HPS.party_site_id),'X'))
                                                                                                                                                                                                          AND NVL(p_salesrep_high,NVL(XXOD_AR_SFA_HIERARCHY_PKG.GET_SALESREP_NAME(HPS.party_site_id),'X'))
        /*)
WHERE NVL(GET_COLLECTION_STRATEGY(p_collection_level,site_use_id,cust_id,party_id1),'X') = NVL(P_COLLECTION_STRATEGY,NVL(GET_COLLECTION_STRATEGY(p_collection_level,site_use_id,cust_id,party_id1),'X'))
  AND total_cust_b9_1 BETWEEN NVL(p_181_past_days_low,total_cust_b9_1) AND NVL(p_181_past_days_high,total_cust_b9_1)
  AND total_cust_b8_1 BETWEEN NVL(p_61_past_days_low,total_cust_b8_1) AND NVL(p_61_past_days_high,total_cust_b8_1)
  AND total_cust_b7_1 BETWEEN NVL(p_31_past_days_low,total_cust_b7_1) AND NVL(p_31_past_days_high,total_cust_b7_1)
GROUP BY CUST_NO_1                     -- Commented by Ganesan for improving the performance.
       ,CUST_NO_1
                 ,CUST_ID
                 ,PARTY_ID1
                 ,SHORT_CUST_NAME_1
                 ,CUST_SORT_1
                -- ,SITE_USE_ID
                 ,COLLECTOR_NAME_1
                 ,CREDIT_LIMIT_1
                 ,CUSTOMER_CLASS1_1
                 ,CUSTOMER_CATEGORY
       ,RISK_CODE*/
ORDER BY  CUST_NO_1
          ,CUST_SORT_1;

---------------------------------
--   VARIABLE DECLARATION      --
---------------------------------

ln_outstanding_amount    NUMBER := 0;
ln_total_cust_amt_1      NUMBER := 0;
ln_total_cust_b0_1       NUMBER := 0;
ln_total_cust_b1_1       NUMBER := 0;
ln_total_cust_b2_1       NUMBER := 0;
ln_total_cust_b3_1       NUMBER := 0;
ln_total_cust_b4_1       NUMBER := 0;
ln_total_cust_b5_1       NUMBER := 0;
ln_total_cust_b6_1       NUMBER := 0;
ln_total_cust_b7_1       NUMBER := 0;
ln_total_cust_b8_1       NUMBER := 0;
ln_total_cust_b9_1       NUMBER := 0;
ln_outstanding_amt_tot   NUMBER := 0;
ln_total_b0_1            NUMBER := 0;
ln_total_b1_1            NUMBER := 0;
ln_total_b2_1            NUMBER := 0;
ln_total_b3_1            NUMBER := 0;
ln_total_b4_1            NUMBER := 0;
ln_total_b5_1            NUMBER := 0;
ln_total_b6_1            NUMBER := 0;
ln_total_b7_1            NUMBER := 0;
ln_total_b8_1            NUMBER := 0;
ln_total_b9_1            NUMBER := 0;
lc_customer_number       hz_cust_accounts.account_number%TYPE;
lc_prev_customer         hz_cust_accounts.account_number%TYPE;
ln_count_customers       NUMBER := 0;
lc_print                 VARCHAR2(32000);
lc_print_tot             VARCHAR2(32000);
lc_print_title           VARCHAR2(32000);
lc_code                  VARCHAR2(32000);
lc_collection_level      iex_app_preferences_vl.preference_value%TYPE;
ln_set_of_books_id       ar_system_parameters.set_of_books_id%TYPE;
lc_set_of_books_name     gl_sets_of_books.name%TYPE;
lc_currency_code         gl_sets_of_books.currency_code%TYPE;
ln_buffer                BINARY_INTEGER  := 32767;
lt_file                  utl_file.file_type;
lc_filename              VARCHAR2(4000);
ln_req_id                NUMBER := 0;
lc_source_dir_path       VARCHAR2(4000);
ld_as_of_date              DATE;
ld_last_payment_date_low   DATE;
ld_last_payment_date_high       DATE;
ld_invoice_date_low             DATE;
ld_invoice_date_high            DATE;
lc_final_customer               hz_cust_accounts.account_number%TYPE;          
lc_final_short_cust_name        hz_parties.party_name%TYPE;
lc_final_collector_name_1       ar_collectors.name%TYPE;
lc_final_credit_limit_1         hz_cust_profile_amts.overall_credit_limit%TYPE;
lc_final_customer_category      ar_lookups.meaning%TYPE;
lc_final_risk_code              hz_customer_profiles.risk_code%TYPE;
--lc_collection_strategy          iex_strategy_templates_vl.strategy_name%TYPE DEFAULT NULL; -- Added for checking the collection strategy if parameter is passed.
                                                                                             -- Commented for defect 2322



                                                 -- FND_CONC_DATE.string_to_date();

BEGIN
   DBMS_OUTPUT.PUT_LINE('Entered into extract');
   write_log(p_debug_flag,'Entered into extract');
   ld_as_of_date := FND_DATE.CANONICAL_TO_DATE(p_as_of_date);
   ld_last_payment_date_low :=  FND_DATE.CANONICAL_TO_DATE(p_last_payment_date_low );
   ld_last_payment_date_high := FND_DATE.CANONICAL_TO_DATE(p_last_payment_date_high);
   ld_invoice_date_low       := FND_DATE.CANONICAL_TO_DATE(p_invoice_date_low      );
   ld_invoice_date_high      := FND_DATE.CANONICAL_TO_DATE(p_invoice_date_high     );

   -------------------------------------------------------
   --   Initialising the file name and opening the file --
   -------------------------------------------------------

   ln_req_id:= fnd_profile.value('CONC_REQUEST_ID');
   lc_filename:='OD_AR_Aging_Extract_by_Customer_'||ln_req_id;
   lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);

   -------------------------------------------------------
   --   Initialising the file name and opening the file --
   -------------------------------------------------------
   lc_code := ' Getting the file name';
   BEGIN                     --added by ranjith
     SELECT directory_path
     INTO lc_source_dir_path
     FROM   dba_directories
     WHERE  directory_name = gc_file_path;
   EXCEPTION
   WHEN OTHERS THEN
      write_log(p_debug_flag,'Exception raised while getting directory path '|| SQLERRM);
   END;
   -------------------------------------------------------
        -- Finding the collection strategy Level             --
        -------------------------------------------------------

   lc_code := lc_code || ' Finding Collection Strategy Level';
   BEGIN
      SELECT preference_value
      INTO   lc_collection_level
      FROM   iex_app_preferences_vl
      WHERE  preference_name = 'COLLECTIONS STRATEGY LEVEL';
   EXCEPTION
   WHEN OTHERS THEN
      lc_collection_level := 'BILL_TO';
   END;
   write_log(p_debug_flag,'Collection Strategy Level: ' || lc_collection_level);

   -------------------------------------------------------
   --     Getting the Set of Books Name, Currency       --
   -------------------------------------------------------
   lc_code := lc_code ||  ' Getting Set of Books Name,Currency';
   BEGIN
      SELECT set_of_books_id
      INTO   ln_set_of_books_id
      FROM   ar_system_parameters;
   EXCEPTION
   WHEN OTHERS THEN
     ln_set_of_books_id := 0;
   END;

   BEGIN
      SELECT name, currency_code
      INTO   lc_set_of_books_name, lc_currency_code
      FROM   gl_sets_of_books
      WHERE  set_of_books_id = ln_set_of_books_id;
   EXCEPTION
   WHEN OTHERS THEN
     lc_set_of_books_name := NULL;
     lc_currency_code := NULL;
   END;
   write_log(p_debug_flag,'Set Of Books ID: ' || ln_set_of_books_id);
   write_log(p_debug_flag,'Printing aging information');
   -------------------------------------------------------
   --    Printing the Aging Information in the file     --
   -------------------------------------------------------

   --XLA_MO_REPORTING_API.Initialize(p_reporting_level, p_reporting_entity_id, 'AUTO');
   lc_print_title := 'Customer Number' || '|' || 'Customer Name' || '|' || 'Collector Name' || '|' || 'Credit Limit' || '|' || 'Outstanding Amount' || '|' || 'Current' || '|' || '1-30 PD' || '|' || '31-60 PD' || '|' || '61-90 PD' || '|' || '91-180 PD' || '|' || '181-365 PD' || '|' || '366+ PD' || '|' || '31+ PD' || '|' || '61+ PD' || '|' || '181+ PD';
        DBMS_OUTPUT.PUT_LINE(lc_print_title);
   UTL_FILE.PUT_LINE(lt_file,lc_print_title);
   lc_prev_customer := 0;
   FOR lr_main_rec IN lcu_main(lc_currency_code
                               ,lc_collection_level
                               ,ld_as_of_date
                               ,ld_last_payment_date_low
                               ,ld_last_payment_date_high
                               ,ld_invoice_date_low
                               ,ld_invoice_date_high)
   LOOP

      ----------------------------------------------------------------------------------  
      --Commenting the code that gets the Collection Strategy for defect 2322 - START
      ----------------------------------------------------------------------------------
      /*
      ------------------------------------------------------
      --      Getting the collection strategy             --
      ------------------------------------------------------
      lc_code := 'Getting the collection strategy for ' || lr_main_rec.CUST_NO_1;
      IF p_collection_strategy IS NOT NULL THEN
              lc_collection_strategy     := GET_COLLECTION_STRATEGY(lc_collection_level,lr_main_rec.site_use_id,lr_main_rec.cust_id,lr_main_rec.party_id1);
      END IF;
      */
      
       ----------------------------------------------------------------------------------  
      --Commenting the code that gets the Collection Strategy for defect 2322 - END
      ----------------------------------------------------------------------------------

      ------------------------------------------------------
      --      Getting the information at Customer Level   --
      ------------------------------------------------------
      IF lc_prev_customer <> NVL(lr_main_rec.CUST_NO_1,'NULL') THEN
         lc_code := 'lc_print ' || lc_final_customer;
         --dbms_output.put_line('Customer No: ' || lr_main_rec.CUST_NO_1);
         lc_print:=   lc_final_customer         
                      || '|' || lc_final_short_cust_name  
                      || '|' || lc_final_collector_name_1 
                      || '|' || lc_final_credit_limit_1   
                      || '|' || ln_total_cust_amt_1 
                      || '|' || ln_total_cust_b0_1 || '|' || ln_total_cust_b1_1 || '|' || ln_total_cust_b2_1 || '|' || ln_total_cust_b3_1 
                      || '|' || ln_total_cust_b4_1 || '|' || ln_total_cust_b5_1 || '|' || ln_total_cust_b6_1 || '|' || ln_total_cust_b7_1 
                      || '|' || ln_total_cust_b8_1 || '|' || ln_total_cust_b9_1
                      || '|' || lc_final_customer_category
                      || '|' || lc_final_risk_code        
                      || '|' || chr(13);
       
       
      ----------------------------------------------------------------------------
      --      Parameter Checking for 181 PD,61 PD,31 PD and Collection Strategy --
      ----------------------------------------------------------------------------
          lc_code := 'Parameter checking ' || lc_final_customer;
          IF lc_prev_customer <> '0' 
            --AND (lc_collection_strategy IS NULL OR lc_collection_strategy = p_collection_strategy) Commented for defect 2322
            AND ln_total_cust_b9_1 BETWEEN NVL(p_181_past_days_low,ln_total_cust_b9_1) AND NVL(p_181_past_days_high,ln_total_cust_b9_1) 
            AND ln_total_cust_b8_1 BETWEEN NVL(p_61_past_days_low,ln_total_cust_b8_1) AND NVL(p_61_past_days_high,ln_total_cust_b8_1)
            AND ln_total_cust_b7_1 BETWEEN NVL(p_31_past_days_low,ln_total_cust_b7_1) AND NVL(p_31_past_days_high,ln_total_cust_b7_1) 
          THEN
            -- Needs to be removed
           --  dbms_output.put_line('lc_print for ' || lc_final_customer|| ' '  || lc_print);
          ------------------------------------------------------
          ---   Assigning the Total Amounts at customer level --
          ------------------------------------------------------
             lc_code := 'Assiging Total Outstanding amount';
             ln_outstanding_amt_tot := ln_outstanding_amt_tot + ln_total_cust_amt_1;
             ln_total_b0_1                     := ln_total_b0_1 + ln_total_cust_b0_1;
             ln_total_b1_1                     := ln_total_b1_1 +    ln_total_cust_b1_1;
             ln_total_b2_1                     := ln_total_b2_1 +    ln_total_cust_b2_1;
             ln_total_b3_1                     := ln_total_b3_1 + ln_total_cust_b3_1;
             ln_total_b4_1                     := ln_total_b4_1 +    ln_total_cust_b4_1;
             ln_total_b5_1                     := ln_total_b5_1 + ln_total_cust_b5_1;
             ln_total_b6_1                     := ln_total_b6_1 +    ln_total_cust_b6_1;
             ln_total_b7_1                     := ln_total_b7_1 +    ln_total_cust_b7_1;
             ln_total_b8_1                     := ln_total_b8_1 +    ln_total_cust_b8_1;
             ln_total_b9_1                     := ln_total_b9_1 +    ln_total_cust_b9_1;
           -- dbms_output.put_line('lc_print: ' ||lc_print);
            UTL_FILE.PUT_LINE(lt_file,lc_print);
          END IF;
          lc_code := 'Assing Prev Customer with ' || lr_main_rec.CUST_NO_1;
          lc_prev_customer := lr_main_rec.CUST_NO_1;
          ln_count_customers := ln_count_customers + 1;

         --------------------------------------------------------
         --     Reintializing the amounts for every customer   --
         --------------------------------------------------------
         lc_code := 'Reintialise all amounts with 0 ';
         ln_total_cust_amt_1   := 0;
         ln_total_cust_b0_1    := 0;
         ln_total_cust_b1_1    := 0;
         ln_total_cust_b2_1    := 0;
         ln_total_cust_b3_1    := 0;
         ln_total_cust_b4_1    := 0;
         ln_total_cust_b5_1    := 0;
         ln_total_cust_b6_1    := 0;
         ln_total_cust_b7_1    := 0;
         ln_total_cust_b8_1    := 0;
         ln_total_cust_b9_1    := 0;

      END IF;
       ---------------------------------------------------------
       --      Assiging the total outstanding amounts.        --
       ---------------------------------------------------------
       lc_code := 'Assigning total outstanding amounts';
       --IF (p_collection_strategy IS NULL OR lc_collection_strategy = p_collection_strategy) THEN Commented for defect 2322
          ln_total_cust_amt_1   := ln_total_cust_amt_1   + lr_main_rec.total_cust_amt_1;
          IF lr_main_rec.days_past_due <= 0 THEN
                  ln_total_cust_b0_1    := ln_total_cust_b0_1    + lr_main_rec.total_cust_amt_1 ;
          ELSIF lr_main_rec.days_past_due >= 1 AND lr_main_rec.days_past_due <= 30 THEN
                  ln_total_cust_b1_1    := ln_total_cust_b1_1    + lr_main_rec.total_cust_amt_1 ;
          ELSIF lr_main_rec.days_past_due >= 31 AND lr_main_rec.days_past_due <= 60 THEN
                  ln_total_cust_b2_1    := ln_total_cust_b2_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b7_1    := ln_total_cust_b7_1    + lr_main_rec.total_cust_amt_1 ;
          ELSIF lr_main_rec.days_past_due >= 61 AND lr_main_rec.days_past_due <= 90 THEN
                  ln_total_cust_b3_1    := ln_total_cust_b3_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b7_1    := ln_total_cust_b7_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b8_1    := ln_total_cust_b8_1    + lr_main_rec.total_cust_amt_1 ;

          ELSIF lr_main_rec.days_past_due >= 91 AND lr_main_rec.days_past_due <= 180 THEN
                  ln_total_cust_b4_1    := ln_total_cust_b4_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b7_1    := ln_total_cust_b7_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b8_1    := ln_total_cust_b8_1    + lr_main_rec.total_cust_amt_1 ;
                  
          ELSIF lr_main_rec.days_past_due >= 181 AND lr_main_rec.days_past_due  <= 365 THEN
                  ln_total_cust_b5_1    := ln_total_cust_b5_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b7_1    := ln_total_cust_b7_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b8_1    := ln_total_cust_b8_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b9_1    := ln_total_cust_b9_1    + lr_main_rec.total_cust_amt_1 ;
          ELSIF lr_main_rec.days_past_due >= 366 THEN 
                  ln_total_cust_b6_1    := ln_total_cust_b6_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b7_1    := ln_total_cust_b7_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b8_1    := ln_total_cust_b8_1    + lr_main_rec.total_cust_amt_1 ;
                  ln_total_cust_b9_1    := ln_total_cust_b9_1    + lr_main_rec.total_cust_amt_1 ;
          END IF;

          ------------------------------------------------------
          -- Assiging the Customer information                --
          ------------------------------------------------------
          lc_code := 'Assigning customer Information';
          lc_prev_customer           := lr_main_rec.CUST_NO_1;
          lc_final_customer          := lr_main_rec.CUST_NO_1;
          lc_final_short_cust_name   := lr_main_rec.short_cust_name_1;
          lc_final_collector_name_1  := lr_main_rec.collector_name_1;
          lc_final_credit_limit_1    := lr_main_rec.credit_limit_1;
          lc_final_customer_category := lr_main_rec.customer_category;
          lc_final_risk_code         := lr_main_rec.risk_code;

       --END IF; Commented for defect 2322

       /*  lc_print := lr_main_rec.CUST_NO_1                               -- Commented by Ganesan for improving the performance
                                               || '|' || lr_main_rec.short_cust_name_1
                                               || '|' || lr_main_rec.collector_name_1
                                               || '|' || lr_main_rec.credit_limit_1
                                               || '|' || lr_main_rec.total_cust_amt_1
                                               || '|' || lr_main_rec.total_cust_b0_1
                                               || '|' || lr_main_rec.total_cust_b1_1
                                               || '|' || lr_main_rec.total_cust_b2_1
                                               || '|' || lr_main_rec.total_cust_b3_1
                                               || '|' || lr_main_rec.total_cust_b4_1
                                               || '|' || lr_main_rec.total_cust_b5_1
                                               || '|' || lr_main_rec.total_cust_b6_1
                                               || '|' || lr_main_rec.total_cust_b7_1
                                               || '|' || lr_main_rec.total_cust_b8_1
                                               || '|' || lr_main_rec.total_cust_b9_1
                                               || '|' || lr_main_rec.customer_category
                                               || '|' || lr_main_rec.risk_code
                                               || '|' || chr(13);*/
               -------------------------------------------------------
               --    Calculating the Grand Total                    --
               -------------------------------------------------------

       /*      ln_outstanding_amt_tot := ln_outstanding_amt_tot + lr_main_rec.total_cust_amt_1;
               ln_total_b0_1                     := ln_total_b0_1 + lr_main_rec.total_cust_b0_1;
               ln_total_b1_1                     := ln_total_b1_1 +    lr_main_rec.total_cust_b1_1;
               ln_total_b2_1                     := ln_total_b2_1 +    lr_main_rec.total_cust_b2_1;
               ln_total_b3_1                     := ln_total_b3_1 + lr_main_rec.total_cust_b3_1;
               ln_total_b4_1                     := ln_total_b4_1 +    lr_main_rec.total_cust_b4_1;
               ln_total_b5_1                     := ln_total_b5_1 + lr_main_rec.total_cust_b5_1;
               ln_total_b6_1                     := ln_total_b6_1 +    lr_main_rec.total_cust_b6_1;
               ln_total_b7_1                     := ln_total_b7_1 +    lr_main_rec.total_cust_b7_1;
               ln_total_b8_1                     := ln_total_b8_1 +    lr_main_rec.total_cust_b8_1;
               ln_total_b9_1                     := ln_total_b9_1 +    lr_main_rec.total_cust_b9_1;*/

                        --DBMS_OUTPUT.PUT_LINE( lc_print);
                        --UTL_FILE.PUT_LINE(lt_file,lc_print);

        END LOOP;
--      DBMS_OUTPUT.PUT_LINE('Collection Strategy' || lc_collection_strategy || ' | ' || p_collection_strategy);
        ----------------------------------------------------------------------------------
        --        Assigning the Outstanding amounts for the last fetched customer       --
        ----------------------------------------------------------------------------------
        IF ( --(lc_collection_strategy IS NULL OR lc_collection_strategy = p_collection_strategy)AND Commented for defect 2322
	          ln_total_cust_b9_1 BETWEEN NVL(p_181_past_days_low,ln_total_cust_b9_1) AND NVL(p_181_past_days_high,ln_total_cust_b9_1) 
              AND ln_total_cust_b8_1 BETWEEN NVL(p_61_past_days_low,ln_total_cust_b8_1) AND NVL(p_61_past_days_high,ln_total_cust_b8_1)
              AND ln_total_cust_b7_1 BETWEEN NVL(p_31_past_days_low,ln_total_cust_b7_1) AND NVL(p_31_past_days_high,ln_total_cust_b7_1)) THEN 
            --------------------------------------------------------
            --- Calculating the Total Amounts for last customer   --
            --------------------------------------------------------
            ln_outstanding_amt_tot := ln_outstanding_amt_tot + ln_total_cust_amt_1;
            ln_total_b0_1          := ln_total_b0_1 + ln_total_cust_b0_1;
            ln_total_b1_1          := ln_total_b1_1 +    ln_total_cust_b1_1;
            ln_total_b2_1          := ln_total_b2_1 +    ln_total_cust_b2_1;
            ln_total_b3_1          := ln_total_b3_1 + ln_total_cust_b3_1;
            ln_total_b4_1          := ln_total_b4_1 +    ln_total_cust_b4_1;
            ln_total_b5_1          := ln_total_b5_1 + ln_total_cust_b5_1;
            ln_total_b6_1          := ln_total_b6_1 +    ln_total_cust_b6_1;
            ln_total_b7_1          := ln_total_b7_1 +    ln_total_cust_b7_1;
            ln_total_b8_1          := ln_total_b8_1 +    ln_total_cust_b8_1;
            ln_total_b9_1          := ln_total_b9_1 +    ln_total_cust_b9_1;
            lc_print:= lc_final_customer
                    || '|' || lc_final_short_cust_name
                    || '|' || lc_final_collector_name_1
                    || '|' || lc_final_credit_limit_1
                    || '|' || ln_total_cust_amt_1 
                    || '|' || ln_total_cust_b0_1 || '|' || ln_total_cust_b1_1 || '|' || ln_total_cust_b2_1 || '|' || ln_total_cust_b3_1 
                    || '|' || ln_total_cust_b4_1 || '|' || ln_total_cust_b5_1 || '|' || ln_total_cust_b6_1 || '|' || ln_total_cust_b7_1 
                    || '|' || ln_total_cust_b8_1 || '|' || ln_total_cust_b9_1
                    || '|' || lc_final_customer_category
                    || '|' || lc_final_risk_code
                                   || '|' || chr(13);
        END IF;
        -----------------------------------------------
        --     Printing Total Outstanding Info       --
        -----------------------------------------------
        lc_print_tot :=LN_OUTSTANDING_AMT_TOT
                       || '|' || LN_TOTAL_B0_1
                       || '|' || LN_TOTAL_B1_1
                       || '|' || LN_TOTAL_B2_1
                       || '|' || LN_TOTAL_B3_1
                       || '|' || LN_TOTAL_B4_1
                       || '|' || LN_TOTAL_B5_1
                       || '|' || LN_TOTAL_B6_1
                       || '|' || LN_TOTAL_B7_1
                       || '|' || LN_TOTAL_B8_1
                       || '|' || LN_TOTAL_B9_1;
        UTL_FILE.PUT_LINE(lt_file,lc_print);
--      dbms_output.put_line(lc_print);
        dbms_output.put_line('Count Of Customers: ' || ln_count_customers);
        DBMS_OUTPUT.PUT_LINE(lc_print_tot);
        UTL_FILE.PUT_LINE(lt_file,lc_print_tot);
        DBMS_OUTPUT.PUT_LINE('Exited');
        UTL_FILE.PUT_LINE(lt_file,'Exited');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Output is written to : ' || lc_source_dir_path || '/' || lc_filename || chr(13));
        DBMS_OUTPUT.PUT_LINE('The Output is written to : ' || lc_source_dir_path || '/' || lc_filename || chr(13));
        write_log(p_debug_flag,'Program Completed');
   UTL_FILE.fclose(lt_file);
EXCEPTION
WHEN OTHERS THEN
   write_log(p_debug_flag,'The Program exited because of the following error message:' || SQLERRM);
   write_log(p_debug_flag,'The Program while executing ' || lc_code);
   DBMS_OUTPUT.PUT_LINE('The Program exited because of the following error message:' || SQLERRM);
   DBMS_OUTPUT.PUT_LINE('The Program while executing ' || lc_code);
END AR_AGING_EXTRACT;

   --------------------------------------------------------------------------------------------  
    --Commenting the below function that gets the Collection Strategy for defect 2322 - START
   --------------------------------------------------------------------------------------------
   /*
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                          Wipro-Office Depot                                |
-- +============================================================================+
-- | Name             :  get_collection_strategy                                |
-- | Description      :  This Function is to get Collection Strategy Information|
-- |                     at the passed level                                    |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date              Author                  Remarks                            |
-- |=======   ==========        =============    ===============================     |
-- |DRAFT 1.0 06-Mar-2009  Ganesan JV       Initial draft version                |
-- |                                        developed from the AR AGING         |
-- |                                        Report                              |
-- |1.1       31-Mar-2009  Ganesan JV       Changed the code for                |
-- |                                        tuning the performance              |
-- |                                        for defect 13502                    |
-- +============================================================================+
FUNCTION get_collection_strategy(p_collection_level VARCHAR2
                                 ,p_site_use_id NUMBER
                                 ,p_cust_id NUMBER
                                 ,p_party_id NUMBER)
RETURN VARCHAR2 IS
---------------------------------
--   VARIABLE DECLARATION      --
---------------------------------
lc_collection_strategy VARCHAR2(240);
ln_party_id            NUMBER(15);
lc_code                VARCHAR2(400);
BEGIN

  -------------------------------------------------------
  --    Get collection Strategy - BILL_TO Level        --
  -------------------------------------------------------

  IF p_collection_level = 'BILL_TO' then
    SELECT strategy_name
    INTO lc_collection_strategy
    FROM iex_strategies STR,
         iex_strategy_templates_vl TEMP
    WHERE TEMP.strategy_temp_id = STR.strategy_template_id
      AND STR.object_id = p_site_use_id
      AND object_type = 'BILL_TO'
      AND STR.status_code in ('OPEN', 'ONHOLD')
      AND TEMP.enabled_flag = 'Y'
      AND TEMP.valid_from_dt <= TRUNC(sysdate)
      AND (TEMP.valid_to_dt >= TRUNC(sysdate) or TEMP.valid_to_dt is null);
  -------------------------------------------------------
  --    Get collection Strategy - ACCOUNT Level        --
  -------------------------------------------------------

  ELSIF p_collection_level = 'ACCOUNT' then
    SELECT strategy_name
    INTO lc_collection_strategy
    FROM iex_strategies STR,
         iex_strategy_templates_vl TEMP
    WHERE TEMP.strategy_temp_id = STR.strategy_template_id
      AND STR.object_id = p_cust_id
      AND object_type = 'ACCOUNT'
      AND STR.status_code in ('OPEN', 'ONHOLD')
      AND TEMP.enabled_flag = 'Y'
      AND TEMP.valid_from_dt <= TRUNC(sysdate)
      AND (TEMP.valid_to_dt >= TRUNC(sysdate) or TEMP.valid_to_dt is null);
  -------------------------------------------------------
  --    Get collection Strategy - CUSTOMER Level        --
  -------------------------------------------------------

  ELSE --p_strategy_level is 'CUSTOMER'

    SELECT strategy_name
    INTO lc_collection_strategy
    FROM iex_strategies STR,
         iex_strategy_templates_vl TEMP
    WHERE TEMP.strategy_temp_id = STR.strategy_template_id
      AND STR.object_id = p_party_id
      AND object_type = 'PARTY'
      AND STR.status_code in ('OPEN', 'ONHOLD')
      AND TEMP.enabled_flag = 'Y'
      AND TEMP.valid_from_dt <= TRUNC(sysdate)
      AND (TEMP.valid_to_dt >= TRUNC(sysdate) or TEMP.valid_to_dt is null);
  END IF;

  RETURN(lc_collection_strategy);
--end if;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN '';
  WHEN TOO_MANY_ROWS THEN -- Added Exception for handling multiple strategies
    RETURN '';
  WHEN OTHERS THEN        -- Added Exception for handling multiple strategies
    RETURN '';
END;
*/

   --------------------------------------------------------------------------------------------  
    --Commenting the below function that gets the Collection Strategy for defect 2322 - END
   --------------------------------------------------------------------------------------------

END XX_AR_AGING_EXTRACT_PKG;
/
SHO ERR