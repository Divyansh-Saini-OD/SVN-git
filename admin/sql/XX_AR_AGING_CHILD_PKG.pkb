SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_AR_AGING_CHILD_PKG

PROMPT Program exits if the creation is not successful

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_AR_AGING_CHILD_PKG
AS
 -- +======================================================================+
 -- |                  Office Depot - Project Simplify                     |
 -- |                       WIPRO Technologies                             |
 -- +======================================================================+
 -- | Name :    XX_AR_AGING_CHILD_PKG                                      |
 -- | RICE :    R0426                                                      |
 -- | Description : This package will insert the bucket amount total into  |
 -- |               the temp table XX_AR_CUST_PAYMENT_TEMP                 |
 -- |Change Record:                                                        |
 -- |===============                                                       |
 -- |Version   Date          Author              Remarks                   |
 -- |=======   ==========   =============        =====================     |
 -- |1.0       15-SEP-10    Ganga Devi R         Initial version           |
 -- |1.1       07-OCT-10    Navin Agarwal        Changed the initial       |
 -- |                                            version for Naming        |
 -- |                                            convention and added      |
 -- |                                            threading logic           |
 -- |1.2       01-Nov-10    Mohammed Appas A     Changed the initial       |
 -- |                                            version to include  Org Id|
 -- |                                            in queries (Line# 82 and  |
 -- |                                            137)                      |
 -- |1.3       03-Nov-15    Ray Strauss          R12.2 compliance          |
 -- |                                                                      |
 -- +======================================================================+

   PROCEDURE INSERT_INTO_TEMP    ( x_errbuf                       OUT NOCOPY   VARCHAR2
                                  ,x_retcode                      OUT NOCOPY   NUMBER
                                  ,p_payment_schedule_id_low      IN           NUMBER
                                  ,p_payment_schedule_id_high     IN           NUMBER
                                  ,p_run_at_customer_level        IN           VARCHAR2
                                  ,p_batch_size                   IN           NUMBER
                                 )
   IS

      --Local Variables
      lc_error_loc                   VARCHAR2(4000):= NULL;
      ln_total_ids                   NUMBER        :=0;
      ln_org_id                      NUMBER        :=FND_PROFILE.VALUE('ORG_ID');
      ln_user_id                     NUMBER        :=FND_PROFILE.VALUE('USER_ID');
      TYPE lt_payment_id_cust        IS TABLE OF XX_AR_CUST_LEVEL_TMP%ROWTYPE;
      lt_payment_cust                lt_payment_id_cust;

      CURSOR open_cust
      IS
         SELECT customer_id
               ,SUM(amount_due)                                    total_outstanding_amt
               ,SUM(CASE WHEN days_due >=-999 and days_due<=0
                     THEN amount_due ELSE 0 END)                   sum_tot_amt_0
               ,SUM(CASE WHEN days_due >=1 and days_due<=30
                         THEN amount_due ELSE 0 END)               sum_tot_amt_1
               ,SUM(CASE WHEN days_due >=31 and days_due<=60
                         THEN amount_due ELSE 0 END)               sum_tot_amt_2
               ,SUM(CASE WHEN days_due > =61 and days_due<=90
                         THEN amount_due ELSE 0 END)               sum_tot_amt_3
               ,SUM(CASE WHEN days_due >=91 and days_due<=180
                         THEN amount_due ELSE 0 END)               sum_tot_amt_4
               ,SUM(CASE WHEN days_due >=181 and days_due <=365
                         THEN amount_due ELSE 0 END)               sum_tot_amt_5
               ,SUM(CASE WHEN days_due >=366 and days_due <=9999
                         THEN amount_due ELSE 0 END)               sum_tot_amt_6
               ,ln_org_id
               ,SYSDATE
               ,ln_user_id
               ,SYSDATE
               ,ln_user_id
         FROM  (SELECT  customer_id
                       ,NVL(XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(payment_schedule_id,class,SYSDATE),0) amount_due
                       ,TRUNC(SYSDATE)- due_date days_due
                 FROM  XX_AR_OPEN_TRANS_ITM   APS
                 WHERE APS.payment_schedule_id BETWEEN p_payment_schedule_id_low AND p_payment_schedule_id_high
                 AND   APS.org_id = ln_org_id
                )
         GROUP BY customer_id;

   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Schedule Id Low  : '||p_payment_schedule_id_low);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Schedule Id High : '||p_payment_schedule_id_high);

      IF(p_run_at_customer_level='Y')THEN

         lc_error_loc := 'Opening open_cust cursor';
         OPEN open_cust;
         LOOP
         FETCH open_cust BULK COLLECT INTO lt_payment_cust LIMIT p_batch_size;

            lc_error_loc := 'Inserting record into XX_AR_CUST_LEVEL_TMP at customer level';
            FORALL i IN 1..lt_payment_cust.COUNT
               INSERT INTO XX_AR_CUST_LEVEL_TMP
               VALUES      lt_payment_cust(i);
            ln_total_ids := ln_total_ids + lt_payment_cust.COUNT;

         EXIT WHEN open_cust%NOTFOUND;
         END LOOP;
         CLOSE open_cust;

         FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Closing Cursor open_cust...');
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Payment ids inserted at customer_level: '||ln_total_ids);

      ELSIF(p_run_at_customer_level='N')THEN

         FND_FILE.PUT_LINE (FND_FILE.LOG,'Inserting record into XX_AR_CUST_PAYMENT_TEMP at report level');
         lc_error_loc := 'Inserting record into XX_AR_CUST_PAYMENT_TEMP at report level';

         INSERT INTO XX_AR_CUST_PAYMENT_TEMP
            SELECT SUM(amount_due)                                    total_outstanding_amt
                  ,SUM(CASE WHEN days_due >=-999 and days_due<=0
                            THEN amount_due ELSE 0 END)               sum_tot_amt_0
                  ,SUM(CASE WHEN days_due >=1 and days_due<=30
                            THEN amount_due ELSE 0 END)               sum_tot_amt_1
                  ,SUM(CASE WHEN days_due >=31 and days_due<=60
                            THEN amount_due ELSE 0 END)               sum_tot_amt_2
                  ,SUM(CASE WHEN days_due > =61 and days_due<=90
                            THEN amount_due ELSE 0 END)               sum_tot_amt_3
                  ,SUM(CASE WHEN days_due >=91 and days_due<=180
                            THEN amount_due ELSE 0 END)               sum_tot_amt_4
                  ,SUM(CASE WHEN days_due >=181 and days_due <=365
                            THEN amount_due ELSE 0 END)               sum_tot_amt_5
                  ,SUM(CASE WHEN days_due >=366 and days_due <=9999
                            THEN amount_due ELSE 0 END)               sum_tot_amt_6
                  ,ln_org_id
                  ,SYSDATE
                  ,ln_user_id
                  ,SYSDATE
                  ,ln_user_id
            FROM  (SELECT  NVL(XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(payment_schedule_id,class,SYSDATE),0) amount_due
                          ,TRUNC(SYSDATE)- due_date days_due
                   FROM   XX_AR_OPEN_TRANS_ITM   APS
                   WHERE  APS.payment_schedule_id BETWEEN p_payment_schedule_id_low AND p_payment_schedule_id_high
                   AND   APS.org_id = ln_org_id
                  );
      END IF;

   EXCEPTION

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while '||lc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'--'||SQLERRM);

   END INSERT_INTO_TEMP;

END XX_AR_AGING_CHILD_PKG;
/
SHOW ERR
