CREATE OR REPLACE PACKAGE BODY xx_ar_aging_bucket_summary 
-- +===================================================================+
-- | Name  : xx_ar_aging_bucket_summary                                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author          Remarks                    |
-- |=======   ==========   =============   ============================|
-- |1.0       08-APR-2014  Veronica M      Initial version for defect  |
-- |                                       29220 to provide AR Aging   |
-- |                                       bucket summary.             |
-- |1.1       21-APR-2014  Veronica M      Modified for defect 29220   |
-- |1.2       02-JUN-2014  Veronica M      Modified for defect 29559 to|   
-- |                                       change the number format to |
-- |                                       include commas separation   |
-- +===================================================================+
AS

PROCEDURE xx_aging_bal_proc ( x_err_buff            OUT VARCHAR2
                             ,x_ret_code            OUT NUMBER
                             ,p_as_of_date          IN  VARCHAR2)
IS

CURSOR l_aging_cur(CP_CURRENCY_CODE VARCHAR2
                  ,P_REPORTING_ENTITY_ID NUMBER
                  ,P_AS_OF_DATE DATE) IS
SELECT /*+ INDEX(APS XXAR_PAYMENT_SCHEDULES_ALL_N1) LEADING(APS RCT) */
       (XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.PAYMENT_SCHEDULE_ID, APS.class
                                         ,P_AS_OF_DATE) )   P_B_AMOUNT
FROM   ra_customer_trx        RCT
      ,ar_payment_schedules   APS
      ,ar_trx_bal_summary     ATBS
WHERE  RCT.customer_trx_id             = APS.customer_trx_id
AND    ATBS.cust_account_id(+)         = APS.customer_id
AND    ATBS.site_use_id(+)             = APS.customer_site_use_id
AND    APS.class                       <> 'PMT'
AND    ATBS.currency(+)                = CP_CURRENCY_CODE
AND    ATBS.org_id(+)                  = P_REPORTING_ENTITY_ID
AND    APS.gl_date                    <= P_AS_OF_DATE
AND    APS.gl_date_closed              > P_AS_OF_DATE
UNION ALL
SELECT /*+ INDEX(APS XXAR_PAYMENT_SCHEDULES_ALL_N1)*/
(XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(APS.PAYMENT_SCHEDULE_ID,APS.class
                                         ,P_AS_OF_DATE)    )   P_B_AMOUNT
FROM   ar_payment_schedules      APS
      ,ar_trx_bal_summary        ATBS
WHERE ATBS.cust_account_id (+)    = APS.customer_id
AND   ATBS.site_use_id (+)        = APS.customer_site_use_id
AND   APS.class                   = 'PMT'
AND   ATBS.currency (+)           = CP_CURRENCY_CODE
AND   ATBS.org_id (+)             = P_REPORTING_ENTITY_ID
AND   APS.gl_date                <= P_AS_OF_DATE
AND   APS.gl_date_closed          > P_AS_OF_DATE;

ln_outstanding_bal NUMBER := 0;
lc_currency_code   VARCHAR2(10) DEFAULT NULL;
lc_oustanding_bal_fmt  VARCHAR2(50);    --Added for defect 29559

ln_reporting_entity_id NUMBER := FND_PROFILE.VALUE('ORG_ID');
ld_as_of_date          DATE := FND_DATE.CANONICAL_TO_DATE (P_AS_OF_DATE);

BEGIN

mo_global.Set_Policy_Context('S', FND_PROFILE.VALUE('ORG_ID'));

FOR i IN l_aging_cur(lc_currency_code ,ln_reporting_entity_id ,ld_as_of_date)
LOOP
    ln_outstanding_bal := ln_outstanding_bal + i.p_b_amount;
END LOOP;

lc_oustanding_bal_fmt := TO_CHAR(ln_outstanding_bal,'999,999,999.99');

FND_FILE.PUT_LINE (FND_FILE.LOG, 'For Org id : '|| ln_reporting_entity_id);  --Added for defect 29559

FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '-------------------------');
FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Org id : '|| ln_reporting_entity_id);
FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '-------------------------');
FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'As of date: '|| ld_as_of_date);
FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '-------------------------');
--FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Outstanding Balance = '|| ln_outstanding_bal);
FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Outstanding Balance = '|| lc_oustanding_bal_fmt);  --Commented/Added for defect 29559

END xx_aging_bal_proc;

END xx_ar_aging_bucket_summary;
/