 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package body XXOD_AR_CREDIT_LMT_AUDIT_PKG
 PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

 CREATE OR REPLACE
 PACKAGE BODY XXOD_AR_CREDIT_LMT_AUDIT_PKG
 AS

 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name        : R0429-Credit Limit Change Audit Report              |
 -- |                                                                   |
 -- | Description : This report displays the customer details and the   |
 -- |               credit limit changes of that customer which has     |
 -- |               happened yesterday.                                 |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author              Remarks                |
 -- |=======   ==========   =============        =======================|
 -- |1.0       10-MAR-2007  Sailaja              Initial version        |
 -- |                       Wipro Technologies   Added for Defect 4429  |
 -- |1.1       12-MAR-2009  Prakash Sankaran     Defect 13539           |
 -- |                                          CREDIT LIMIT_CHANGE <> 0 |
 -- |1.2       10-AUG-2013 Aradhna Sharma       R0429- Updated for R12  |
 -- |                                           retrofit.               |
 -- +===================================================================+
 -- +===================================================================+
 -- | Name        : XXOD_AR_CREDIT_LMT_AUDIT_PKG                        |
 -- | Description : This procedure calculates the oustanding amount     |
 -- |               ,60 + past due, credit limit change and displays the|
 -- |               customer details, credit limit prior, credit limit  |
 -- |               current, credit date changed.                       |
 -- |                                                                   |
 -- +===================================================================+

 PROCEDURE CREDIT_LIMIT_CHANGE(p_date DATE)
 AS

 ln_outstanding_amount   xxod_ar_credit_limit_temp.outstanding_amount%TYPE;
 ln_past_due_60              xxod_ar_credit_limit_temp.past_due_60_amount%TYPE;
 ln_credit_limit_percent     xxod_ar_credit_limit_temp.credit_limit_percent%TYPE;

 CURSOR c_customers
 IS
 SELECT HP.party_name                 CUSTOMER_NAME
       ,HCA.account_number            CUSTOMER_NUMBER
       ,HCA.cust_account_id           CUSTOMER_ID
       ,ARC.Collector_id              COLLECTOR_ID
       ,ARC.Name                      COLLECTOR
       ,TO_CHAR(SYSDATE,'MM/DD/YY')   AUDIT_DATE
       ,HCP.overall_credit_limit      OVERALL_CREDIT_LIMIT
 FROM   hz_parties                    HP
       ,hz_cust_accounts              HCA
       ,hz_cust_profile_amts          HCP
    ------   ,ar_customer_profiles          ACP  ---------commented by Aradhna Sharma for R12 retrofit on 10-Aug-2013
       ,hz_customer_profiles          ACP  --------Added by Aradhna Sharma for R12 retrofit on 10-Aug-2013
       ,ar_collectors                 ARC
     -----  ,gl_sets_of_books              GL       ---------commented by Aradhna Sharma for R12 retrofit on 10-Aug-2013
       ,gl_ledgers                     GL            --------Added by Aradhna Sharma for R12 retrofit on 10-Aug-2013
 WHERE  HCA.cust_account_id         = HCP.Cust_Account_id
------ AND    HCP.Cust_account_profile_id = ACP.customer_profile_id  ---------commented by Aradhna Sharma for R12 retrofit on 10-Aug-2013
  AND    HCP.Cust_account_profile_id = ACP.Cust_account_profile_id    --------Added by Aradhna Sharma for R12 retrofit on 10-Aug-2013
 AND    ACP.Collector_id            = ARC.Collector_id
--- AND    HCA.cust_account_id         = ACP.Customer_id  ---------commented by Aradhna Sharma for R12 retrofit on 10-Aug-2013
  AND    HCA.cust_account_id         = ACP.cust_account_id    --------Added by Aradhna Sharma for R12 retrofit on 10-Aug-2013
--- AND    HCP.Cust_account_id         = ACP.Customer_id    --------commented by Aradhna Sharma for R12 retrofit on 10-Aug-2013
  AND    HCP.Cust_account_id         = ACP.Cust_account_id    --------Added by Aradhna Sharma for R12 retrofit on 10-Aug-2013
 AND    HP.party_id                 = HCA.party_id 
 AND    HCP.site_use_id IS NULL
------ AND    GL.set_of_books_id          = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')   ---------commented by Aradhna Sharma for R12 retrofit on 10-Aug-2013
  AND    GL.ledger_id          = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')   --------Added by Aradhna Sharma for R12 retrofit on 10-Aug-2013
 AND    HCP.currency_code           = GL.currency_code
 AND    TRUNC(HCP.last_update_date) = p_date;

 CURSOR c_credit_info(p_ovr_all_lmt NUMBER,p_customer_id NUMBER)
 IS
 SELECT PRIOR_CREDIT_LIMIT
       ,CURRENT_CREDIT_LIMIT
       ,CREDIT_LIMIT_CHANGE
       ,CREDIT_CHANGED_BY
       ,CREDIT_CHANGED_DATE
       ,CREDIT_INFO_UPDATE_DATE
 FROM (
       SELECT ACH.credit_limit   PRIOR_CREDIT_LIMIT
             ,NVL(LEAD(ACH.credit_limit) OVER (ORDER BY ACH.credit_info_update_date),p_ovr_all_lmt) CURRENT_CREDIT_LIMIT
             ,NVL(LEAD(ACH.credit_limit) OVER (ORDER BY ACH.credit_info_update_date),p_ovr_all_lmt) - ACH.credit_limit CREDIT_LIMIT_CHANGE
             ,FUU.user_name                                                 CREDIT_CHANGED_BY
             ,TO_CHAR(ACH.credit_info_update_date,'DD-MON-YYYY HH24:MI:SS') CREDIT_CHANGED_DATE
             ,ACH.credit_info_update_date
       FROM   ar_credit_histories           ACH
             ,fnd_user                      FUU
             -----,gl_sets_of_books              GL     ---------commented by Aradhna Sharma for R12 retrofit on 10-Aug-2013
	     ,gl_ledgers              GL         --------Added by Aradhna Sharma for R12 retrofit on 10-Aug-2013
       WHERE  ACH.customer_id             = p_customer_id
       AND    ACH.credit_info_updated_by  = FUU.user_id
       AND    ACH.currency_code           = GL.currency_code
       AND    ACH.site_use_id               IS NULL
      ----- AND    GL.set_of_books_id          = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')     ---------commented by Aradhna Sharma for R12 retrofit on 10-Aug-2013
       AND    GL.ledger_id          = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')       --------Added by Aradhna Sharma for R12 retrofit on 10-Aug-2013
       AND    TRUNC(ACH.credit_info_update_date) = p_date
      )
 WHERE    CREDIT_LIMIT_CHANGE <> 0              -- Defect 13539 - Prakash Sankaran 3/12/2009
 ORDER BY credit_info_update_date;

   BEGIN

      FOR lcu_customers IN c_customers
      LOOP

         -- Calculating outstanding_amount and 61+ Past Due
            BEGIN
               SELECT NVL(SUM( DECODE( APS.class, 'PMT', -APP.acctd_amount_applied_from, APS.acctd_amount_due_remaining )),0)
                      ,NVL(SUM((DECODE( GREATEST(61,CEIL(TRUNC(SYSDATE)-APS.due_date)),
                           LEAST(9999999,CEIL(TRUNC(SYSDATE)-APS.due_date)),1,0) 
                           * DECODE(NVL(APS.amount_in_dispute,0), 0, 1,1 )
                           * DECODE(NVL(APS.amount_adjusted_pending,0), 0, 1,1)) 
                           * DECODE(APS.class, 'PMT', -APP.acctd_amount_applied_from, APS.acctd_amount_due_remaining)),0)
               INTO   ln_outstanding_amount
                      ,ln_past_due_60
               FROM   ar_payment_schedules  APS,
                      ra_cust_trx_line_gl_dist RCTLGD,
                      ar_receivable_applications APP
               WHERE  APS.customer_trx_id = RCTLGD.customer_trx_id(+)
               AND    NVL(RCTLGD.account_class,'REC') = 'REC'
               AND    NVL(RCTLGD.latest_rec_flag,'Y') = 'Y'
               AND    APS.customer_id = lcu_customers.customer_id
               AND    APS.status = 'OP'
               AND    APS.acctd_amount_due_remaining <> 0
               AND    APS.cash_receipt_id = APP.cash_receipt_id(+)
               AND    NVL(APP.status, 'UNAPP') IN ( 'UNAPP', 'UNID', 'ACC','OTHER ACC' )
               AND    APS.gl_date <= SYSDATE
               AND    APS.gl_date_closed > SYSDATE;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'No outstanding amount / 61+ Past Due for the customer. '
                                               || SQLERRM);
               WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while calculating the outstanding amount / 61+ Past Due. '
                                               || SQLERRM);
            END;
            ---Calculating the Credit Histories Information
            FOR lcu_credit_info IN c_credit_info(lcu_customers.overall_credit_limit,lcu_customers.customer_id)
            LOOP     
               --Percentage Calculation
               SELECT ROUND(((lcu_credit_info.CREDIT_LIMIT_CHANGE)/
                        (DECODE(NVL(lcu_credit_info.CURRENT_CREDIT_LIMIT,1),0,1,
                         NVL(lcu_credit_info.CURRENT_CREDIT_LIMIT,1)))*100),2)
               INTO   ln_credit_limit_percent
               FROM   dual;

            -- Inserting into global temporary table

                INSERT INTO XXOD_AR_CREDIT_LIMIT_TEMP
                       ( customer_number
                        ,customer_name
                        ,collector
                        ,credit_limit_prior
                        ,credit_limit_current
                        ,credit_limit_change
                        ,credit_limit_percent
                        ,credit_changed_by
                        ,credit_changed_date
                        ,outstanding_amount
                        ,past_due_60_amount
                        ,audit_date
                       )
                 VALUES     
                       ( 
                        lcu_customers.CUSTOMER_NUMBER
                        ,lcu_customers.CUSTOMER_NAME
                        ,lcu_customers.COLLECTOR
                        ,lcu_credit_info.PRIOR_CREDIT_LIMIT
                        ,lcu_credit_info.CURRENT_CREDIT_LIMIT
                        ,lcu_credit_info.CREDIT_LIMIT_CHANGE
                        ,ln_credit_limit_percent
                        ,lcu_credit_info.CREDIT_CHANGED_BY
                        ,lcu_credit_info.CREDIT_CHANGED_DATE
                        ,ln_outstanding_amount
                        ,ln_past_due_60
                        ,lcu_customers.AUDIT_DATE
                       );
            END LOOP;
      END LOOP;

   END;
 END XXOD_AR_CREDIT_LMT_AUDIT_PKG;
/
SHOW ERROR
