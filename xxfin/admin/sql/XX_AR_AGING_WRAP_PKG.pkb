SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT CREATING PACKAGE BODY XX_AR_AGING_WRAP_PKG

PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE BODY XX_AR_AGING_WRAP_PKG
AS
 -- +======================================================================+
 -- |                  Office Depot - Project Simplify                     |
 -- |                       WIPRO Technologies                             |
 -- +======================================================================+
 -- | Name :    XX_AR_AGING_WRAP_PKG                                       |
 -- | RICE :    R0426                                                      |
 -- | Description : This package submits 'OD: AR Aging Buckets Wrapper'    |
 -- |               which inturn submits the OD: AR Aging Buckets - Child  |
 -- |Change Record:                                                        |
 -- |===============                                                       |
 -- |Version   Date          Author              Remarks                   |
 -- |=======   ==========   =============        =====================     |
 -- |1.0       15-SEP-10    Ganga Devi R         Initial version           |
 -- |1.1       07-OCT-10    Navin Agarwal        Changed the initial       |
 -- |                                            version for Naming        |
 -- |                                            convention and threading  |
 -- |                                            logic                     |
 -- |1.2       01-Nov-10    Mohammed Appas A     Updated the version       |
 -- |                                            for the following:        |
 -- |                                            a) Removed the hard-coded |
 -- |                                               Currency value in      |
 -- |                                               Line # 145             |
 -- |                                            b) Removed the unused     |
 -- |                                               variables in           |
 -- |                                               declarartion section   |
 -- |                                                                      |
 -- |1.3       08-Nov-10    Ganga Devi R         Included the operating    |
 -- |                                            unit for defect#7792      |
 -- |1.4       18-Nov-10    Ganga Devi	R        Modified label in the pgm |
 -- |                                            output as per defect#7792 |
 -- |                                                                      |   
 -- |1.5       01-Feb-11    Vishwajeet           Modified the code to copy |
 -- |                                            the output file to the app|
 -- |                                            ropriate directory. Defect|
 -- |                                            #9715.                    |
 -- |1.6       10-JUN-13    Bapuji Nanapaneni    Modifed for 12i UPGRADE   |
 -- |1.7       03-NOV-15    Ray Strauss          R12.2 Compliance          |
 -- +======================================================================+

   PROCEDURE AR_AGING_BUCKETS    ( x_errbuf                  OUT NOCOPY   VARCHAR2
                                  ,x_retcode                 OUT NOCOPY   NUMBER
                                  ,p_thread_count            IN           NUMBER
                                  ,p_run_at_customer_level   IN           VARCHAR2
                                  ,p_batch_size              IN           NUMBER
                                  ,p_run_interim_pgm         IN           VARCHAR2
                                 )
   IS

      --Local Variables
      ln_payment_schedule_id_low     NUMBER        := 0;
      ln_payment_schedule_id_high    NUMBER        := 0;
      ln_tot_elg_customers           NUMBER        := 0;
      ln_batch_size                  NUMBER        := 0;
      ln_start_id                    NUMBER        := 0;
      ln_upper_range                 NUMBER        := 0;
      ln_request_id                  NUMBER        := 0;
      ln_this_request_id             NUMBER        := FND_GLOBAL.CONC_REQUEST_ID ;
      ln_total_outstanding_amt       NUMBER        := 0;
      ln_sum_tot_amt_0               NUMBER        := 0;
      ln_sum_tot_amt_1               NUMBER        := 0;
      ln_sum_tot_amt_2               NUMBER        := 0;
      ln_sum_tot_amt_3               NUMBER        := 0;
      ln_sum_tot_amt_4               NUMBER        := 0;
      ln_sum_tot_amt_5               NUMBER        := 0;
      ln_sum_tot_amt_6               NUMBER        := 0;
      ln_sum_tot_31pd                NUMBER        := 0;
      ln_sum_tot_61pd                NUMBER        := 0;
      ln_sum_tot_181pd               NUMBER        := 0;
      lc_error_loc                   VARCHAR2(4000):= NULL;
      lc_request_data                VARCHAR2(4000):= NULL;
      lc_currency_code               VARCHAR2(4000):= NULL;  --Added for prod defect#7792
      lc_operating_unit              VARCHAR2(4000):= NULL;  --Added for prod defect#7792
      lc_setup_exception             EXCEPTION;
      ln_err_cnt                     NUMBER        := 0;
      ln_wrn_cnt                     NUMBER        := 0;
      ln_nrm_cnt                     NUMBER        := 0;
      ln_org_id                      NUMBER        :=FND_PROFILE.VALUE('ORG_ID'); --Added for prod defect#7792
      ln_user_id                     NUMBER        :=FND_PROFILE.VALUE('USER_ID');
 ----------Vishwajeet---Defect#9715------------------------
      ln_style                       VARCHAR2(100);
      ln_set_print_options           BOOLEAN;
      ln_printer                     VARCHAR2(200);
      ln_no_of_copies                NUMBER  :=0;

      -- pl/sql table to hold all batch Id's created.
      TYPE rec_batch_id IS RECORD (
                                  request_id   NUMBER
                                 ,status       VARCHAR2(100)
                                  );
      lrec_batch_id                 rec_batch_id;
      TYPE tab_batch_id IS TABLE OF lrec_batch_id%TYPE
      INDEX BY BINARY_INTEGER;
      gtab_batch_id                 tab_batch_id;

   BEGIN

      lc_request_data := FND_CONC_GLOBAL.REQUEST_DATA;

      lc_error_loc := 'Selecting the set of books id';

      SELECT GSOB.currency_code 
      INTO   lc_currency_code
      --FROM   gl_sets_of_books GSOB
      FROM   gl_ledgers GSOB	--ADDED BY NB FOR 12i UPGRADE  
      WHERE  GSOB.ledger_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');

    --Added below select to get the operating unit for prod defect#7792
      lc_error_loc := 'Selecting the Operating Unit';

      SELECT name 
      INTO   lc_operating_unit
      FROM   hr_operating_units HOU
      WHERE  HOU.organization_id=ln_org_id;

      IF (NVL(lc_request_data,'FIRST') = 'FIRST') AND (p_run_interim_pgm='Y') THEN

         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting OD: AR Open Transactions – Repopulate Interim Table ');
         lc_error_loc := 'Submitting OD: AR Open Transactions – Repopulate Interim Table ';

         ln_request_id:=FND_REQUEST.SUBMIT_REQUEST ( 'XXFIN'
                                                    ,'XXAROCREPI'
                                                    ,''
                                                    ,SYSDATE
                                                    ,TRUE
                                                   );
         COMMIT;

         IF (ln_request_id = 0) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to submit OD: AR Open Transactions – Repopulate Interim Table. '||SQLERRM);
            RAISE lc_setup_exception;
         END IF;

         FND_CONC_GLOBAL.set_req_globals(conc_status   => 'PAUSED', request_data  => 'SECOND' );

      ELSIF (lc_request_data = 'SECOND') OR ((NVL(lc_request_data,'FIRST') = 'FIRST') AND (p_run_interim_pgm = 'N'))  THEN

         lc_error_loc := 'Selecting the range of payment schedule id';

         SELECT MIN(payment_schedule_id)
               ,MAX(payment_schedule_id)
         INTO   ln_payment_schedule_id_low
               ,ln_payment_schedule_id_high
         FROM   xx_ar_open_trans_itm APS
       --WHERE  APS.invoice_currency_code = 'USD' --Commented for prod defect#7792
         WHERE  APS.invoice_currency_code = lc_currency_code --Added for prod defect#7792
         AND    APS.org_id                = ln_org_id --Added for prod defect#7792
         AND    APS.gl_date              <= SYSDATE
         AND    APS.gl_date_closed        > SYSDATE;

         ln_tot_elg_customers := (ln_payment_schedule_id_high - ln_payment_schedule_id_low)+1;
         lc_error_loc         := 'Deriving batch size';
         ln_batch_size        := CEIL(ln_tot_elg_customers/NVL(p_thread_count,10));
         ln_start_id          := ln_payment_schedule_id_low;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Wrapper Request ID:   '||ln_this_request_id);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

         lc_error_loc := 'Deleting existing records from temp table XX_AR_CUST_PAYMENT_TEMP ';
         DELETE  
         FROM   XX_AR_CUST_PAYMENT_TEMP
         WHERE  org_id = ln_org_id;
         COMMIT;

         lc_error_loc := 'Deleting existing records from temp table XX_AR_CUST_LEVEL_TMP ';
         DELETE
         FROM  XX_AR_CUST_LEVEL_TMP
         WHERE org_id = ln_org_id;
         COMMIT;

         lc_error_loc := 'Deleting existing records from temp table XX_AR_CUST_LEVEL_CONS_TMP ';
         DELETE
         FROM  XX_AR_CUST_LEVEL_CONS_TMP
         WHERE org_id = ln_org_id;
         COMMIT;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Number of Records need to be processed: '||ln_tot_elg_customers);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch Size for child program: '||ln_batch_size);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

         ----------------To Get Printer value  Added by Vishwajeet for Defect #9715----------------
             BEGIN
            	SELECT number_of_copies,
                       	 printer
                	 INTO ln_no_of_copies,
                    	  ln_printer 
              	 FROM FND_CONCURRENT_REQUESTS
           	      WHERE request_id=ln_this_request_id;
         	     EXCEPTION
                      WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Printer Not Found  ');
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID: '||ln_this_request_id);
                         x_retcode :=2;
            END;
         ---------------------------------------------------------------------------------------------

         lc_error_loc := 'Opening loop for Child Programs ';

         FOR i IN 1 .. p_thread_count
         LOOP

            ln_upper_range := LEAST(ln_start_id + ln_batch_size - 1,ln_payment_schedule_id_high);

            lc_error_loc := 'Submitting OD: AR Aging Buckets - Child Program  '||i;

         ----------Added by Vishwajeet --for Defect #9715-------------
                      ----Set the printer value for the child program---------------

		FOR c IN (SELECT fpv.printer_name, fpsv.printer_style_name 
            	      FROM fnd_printer_styles_vl fpsv, 
                  	     fnd_printer_information fpi, 
                             fnd_printer_types fpt, fnd_printer_vl fpv 
               	     WHERE fpv.printer_name = ln_printer 
                         AND fpv.printer_type = fpt.printer_type 
                         AND fpt.printer_type = fpi.printer_type 
                         AND fpi.printer_style = fpsv.printer_style_name) 
            LOOP 
                ln_style := c.printer_style_name; 
            EXIT; 
            END LOOP; 

                ln_set_print_options := fnd_request.set_print_options (printer        => ln_printer, 
                                                                            style          => ln_style, 
                                                                            copies         => ln_no_of_copies, 
                                                                            save_output    => TRUE, 
                                                                            print_together => 'N'); 

         IF ln_set_print_options THEN 

            ln_request_id:=FND_REQUEST.SUBMIT_REQUEST ( 'XXFIN'
                                                       ,'XXARAGINGCHILD'
                                                       ,''
                                                       ,SYSDATE
                                                       ,TRUE
                                                       ,ln_start_id
                                                       ,ln_upper_range
                                                       ,p_run_at_customer_level
                                                       ,p_batch_size
                                                      );

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Submited OD: AR Aging Buckets - Child Program  '||i);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID: '||ln_request_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Schedule Id Low : '||ln_start_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Schedule Id High : '||ln_upper_range);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'+---------------------------------------------------------------------------+');

            COMMIT;

            IF (ln_request_id = 0) THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to submit OD: AR Aging Buckets - Child Program '||i||' : '||SQLERRM);
               RAISE lc_setup_exception;
            ELSE
               gtab_batch_id (i).request_id := ln_request_id;
            END IF;

            ln_start_id := ln_start_id + ln_batch_size ;

         END IF;--- ln_set_print_options Defect #9715
         END LOOP;

         IF (gtab_batch_id.COUNT > 0 )THEN
            FND_CONC_GLOBAL.set_req_globals(conc_status   => 'PAUSED', request_data  => 'OVER' );
            RETURN;
         END IF;

      ELSE

         IF (p_run_at_customer_level = 'N') THEN

            lc_error_loc := 'Selecting total bucket amount from XX_AR_CUST_PAYMENT_TEMP';

            SELECT SUM(total_outstanding_amt)
                  ,SUM(sum_tot_amt_0)
                  ,SUM(sum_tot_amt_1)
                  ,SUM(sum_tot_amt_2)
                  ,SUM(sum_tot_amt_3)
                  ,SUM(sum_tot_amt_4)
                  ,SUM(sum_tot_amt_5)
                  ,SUM(sum_tot_amt_6)
                  ,SUM(sum_tot_amt_2+sum_tot_amt_3+sum_tot_amt_4+sum_tot_amt_5+sum_tot_amt_6)
                  ,SUM(sum_tot_amt_3+sum_tot_amt_4+sum_tot_amt_5+sum_tot_amt_6)
                  ,SUM(sum_tot_amt_5+sum_tot_amt_6)
             INTO  ln_total_outstanding_amt
                  ,ln_sum_tot_amt_0
                  ,ln_sum_tot_amt_1
                  ,ln_sum_tot_amt_2
                  ,ln_sum_tot_amt_3
                  ,ln_sum_tot_amt_4
                  ,ln_sum_tot_amt_5
                  ,ln_sum_tot_amt_6
                  ,ln_sum_tot_31pd
                  ,ln_sum_tot_61pd
                  ,ln_sum_tot_181pd
             FROM  XX_AR_CUST_PAYMENT_TEMP XACPT
             WHERE XACPT.org_id = ln_org_id;

         ELSIF (p_run_at_customer_level = 'Y') THEN

            lc_error_loc := 'Inserting record into XX_AR_CUST_LEVEL_CONS_TMP at customer level ';

            INSERT INTO XX_AR_CUST_LEVEL_CONS_TMP
               (SELECT customer_id
                     ,SUM(total_outstanding_amt)
                     ,SUM(sum_tot_amt_0)
                     ,SUM(sum_tot_amt_1)
                     ,SUM(sum_tot_amt_2)
                     ,SUM(sum_tot_amt_3)
                     ,SUM(sum_tot_amt_4)
                     ,SUM(sum_tot_amt_5)
                     ,SUM(sum_tot_amt_6)
                     ,ln_org_id
                     ,SYSDATE
                     ,ln_user_id
                     ,SYSDATE
                     ,ln_user_id
                FROM  XX_AR_CUST_LEVEL_TMP XACLT
                WHERE XACLT.org_id = ln_org_id
                GROUP BY customer_id
               );

            lc_error_loc := 'Selecting total bucket amount from XX_AR_CUST_LEVEL_CONS_TMP and displaying to outfile';

            SELECT SUM(total_outstanding_amt)
                  ,SUM(sum_tot_amt_0)
                  ,SUM(sum_tot_amt_1)
                  ,SUM(sum_tot_amt_2)
                  ,SUM(sum_tot_amt_3)
                  ,SUM(sum_tot_amt_4)
                  ,SUM(sum_tot_amt_5)
                  ,SUM(sum_tot_amt_6)
                  ,SUM(sum_tot_amt_2+sum_tot_amt_3+sum_tot_amt_4+sum_tot_amt_5+sum_tot_amt_6)
                  ,SUM(sum_tot_amt_3+sum_tot_amt_4+sum_tot_amt_5+sum_tot_amt_6)
                  ,SUM(sum_tot_amt_5+sum_tot_amt_6)
             INTO  ln_total_outstanding_amt
                  ,ln_sum_tot_amt_0
                  ,ln_sum_tot_amt_1
                  ,ln_sum_tot_amt_2
                  ,ln_sum_tot_amt_3
                  ,ln_sum_tot_amt_4
                  ,ln_sum_tot_amt_5
                  ,ln_sum_tot_amt_6
                  ,ln_sum_tot_31pd
                  ,ln_sum_tot_61pd
                  ,ln_sum_tot_181pd
             FROM  XX_AR_CUST_LEVEL_CONS_TMP XACLCT
             WHERE XACLCT.org_id = ln_org_id;

         END IF;

         lc_error_loc := 'Printing output';
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Operating Unit              : '||lc_operating_unit);    --Added for prod defect# 7792
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'+---------------------------------------------------------------------------+');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'TOTAL OUTSTANDING AMOUNT    : $'||TRIM(TO_CHAR(ln_total_outstanding_amt,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'+---------------------------------------------------------------------------+');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Amount Due          : $'||TRIM(TO_CHAR(ln_sum_tot_amt_0,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'1 - 30 Days Past Due        : $'||TRIM(TO_CHAR(ln_sum_tot_amt_1,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'31 - 60 Days Past Due       : $'||TRIM(TO_CHAR(ln_sum_tot_amt_2,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'61 - 90 Days Past Due       : $'||TRIM(TO_CHAR(ln_sum_tot_amt_3,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'91 - 180 Days Past Due      : $'||TRIM(TO_CHAR(ln_sum_tot_amt_4,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'181 - 365 Days Past Due     : $'||TRIM(TO_CHAR(ln_sum_tot_amt_5,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'366 + Days Past Due         : $'||TRIM(TO_CHAR(ln_sum_tot_amt_6,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'+---------------------------------------------------------------------------+');
               --Modified below label from 30+,60+,180+ to 31+,61+,181+ as per defect 7792 on 18-Nov-2010 V1.4
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'31 + Days Past Due          : $'||TRIM(TO_CHAR(ln_sum_tot_31pd,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'61 + Days Past Due          : $'||TRIM(TO_CHAR(ln_sum_tot_61pd,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'181 + Days Past Due         : $'||TRIM(TO_CHAR(ln_sum_tot_181pd,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'366 + Days Past Due         : $'||TRIM(TO_CHAR(ln_sum_tot_amt_6,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'+---------------------------------------------------------------------------+');


         FND_FILE.PUT_LINE(FND_FILE.LOG,'Operating Unit              : '||lc_operating_unit);  --Added for prod defect# 7792
         FND_FILE.PUT_LINE(FND_FILE.LOG,'+---------------------------------------------------------------------------+');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'TOTAL OUTSTANDING AMOUNT    : $'||TRIM(TO_CHAR(ln_total_outstanding_amt,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'+---------------------------------------------------------------------------+');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Current Amount Due          : $'||TRIM(TO_CHAR(ln_sum_tot_amt_0,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'1 - 30 Days Past Due        : $'||TRIM(TO_CHAR(ln_sum_tot_amt_1,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'31 - 60 Days Past Due       : $'||TRIM(TO_CHAR(ln_sum_tot_amt_2,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'61 - 90 Days Past Due       : $'||TRIM(TO_CHAR(ln_sum_tot_amt_3,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'91 - 180 Days Past Due      : $'||TRIM(TO_CHAR(ln_sum_tot_amt_4,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'181 - 365 Days Past Due     : $'||TRIM(TO_CHAR(ln_sum_tot_amt_5,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'366 + Days Past Due         : $'||TRIM(TO_CHAR(ln_sum_tot_amt_6,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'+---------------------------------------------------------------------------+');
               --Modified below label from 30+,60+,180+ to 31+,61+,181+ as per defect 7792 on 18-Nov-2010 V1.4
         FND_FILE.PUT_LINE(FND_FILE.LOG,'31 + Days Past Due          : $'||TRIM(TO_CHAR(ln_sum_tot_31pd,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'61 + Days Past Due          : $'||TRIM(TO_CHAR(ln_sum_tot_61pd,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'181 + Days Past Due         : $'||TRIM(TO_CHAR(ln_sum_tot_181pd,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'366 + Days Past Due         : $'||TRIM(TO_CHAR(ln_sum_tot_amt_6,'999,999,999,999,999,999.99')));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'+---------------------------------------------------------------------------+');

         lc_error_loc := 'Setting the status of the Master Program';

         SELECT SUM(CASE WHEN status_code = 'E'
                         THEN 1 ELSE 0 END)
               ,SUM(CASE WHEN status_code = 'G'
                         THEN 1 ELSE 0 END)
               ,SUM(CASE WHEN status_code = 'C'
                         THEN 1 ELSE 0 END)
         INTO   ln_err_cnt
               ,ln_wrn_cnt
               ,ln_nrm_cnt
         FROM   FND_CONCURRENT_REQUESTS
         WHERE  parent_request_id = ln_this_request_id;

         IF (ln_err_cnt > 0 AND ln_wrn_cnt > 0) THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: AR Aging Buckets - Child ended in Error/Warning');
             x_retcode     := 2;
         ELSIF (ln_wrn_cnt >0 AND ln_err_cnt = 0) THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: AR Aging Buckets - Child ended in Warning');
             x_retcode     := 1;
         ELSIF (ln_err_cnt >0 AND ln_wrn_cnt = 0) THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: AR Aging Buckets - Child ended in Error');
             x_retcode     := 2;
         END IF;
      END IF;

   EXCEPTION

      WHEN lc_setup_exception THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_loc);
         x_retcode := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'--'||SQLERRM);

   END AR_AGING_BUCKETS;

END XX_AR_AGING_WRAP_PKG;
/
SHOW ERR
