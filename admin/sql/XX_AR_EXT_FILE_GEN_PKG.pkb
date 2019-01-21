CREATE OR REPLACE PACKAGE BODY XX_AR_EXT_FILE_GEN_PKG
AS
   PROCEDURE MAIN (
      p_errbuf    OUT      VARCHAR2
     ,p_retcode   OUT      NUMBER
     ,p_debug     IN       VARCHAR2
   )
   IS
      ln_conc_id              fnd_concurrent_requests.request_id%TYPE   := -1;
      lb_get_request_status   BOOLEAN;
      lc_phase                VARCHAR2 (100);
      lc_status               VARCHAR2 (100);
      lc_dev_phase            VARCHAR2 (100);
      lc_dev_status           VARCHAR2 (100);
      lc_message              VARCHAR2 (2000);
      ln_batch                NUMBER;
      ln_user_id              NUMBER                                    := FND_PROFILE.VALUE ('user_id');
      ln_appl_id              NUMBER                                    := FND_PROFILE.VALUE ('RESP_APPL_ID');
      ln_resp_id              NUMBER                                    := FND_PROFILE.VALUE ('RESP_ID');
      ln_conc_req_id1         NUMBER;
      ln_conc_req_id2         NUMBER;
      ln_conc_req_id3         NUMBER;
      ln_conc_req_id4         NUMBER;
      ln_conc_req_id5         NUMBER;
      lc_path                 VARCHAR2 (100);
      lc_filename             VARCHAR2 (100);
      lc_debug_flag           VARCHAR2 (1)                              := 'N';
      ln_idx                  NUMBER                                    := 1;
      ln_req_id               req_id;
      gc_error_debug          VARCHAR2 (1000);
      gc_error_loc            NUMBER;
   BEGIN
      FND_GLOBAL.APPS_INITIALIZE (ln_user_id
                                 ,ln_resp_id
                                 ,ln_appl_id
                                 );
--------------------------------------------------------------------------------------
--Submit the Program for the AR Transaction Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the File Generation Program for Transactions');
      ln_conc_req_id1 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARTXNEXTWC'
                                                    ,description      => ''
                                                    ,START_TIME       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id1 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Transaction File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id1;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Transactions');
--------------------------------------------------------------------------------------
--Submit the Program for the Cash Receipt Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the File Generation Program for Cash Receipt');
      ln_conc_req_id2 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARCREXTWC'
                                                    ,description      => ''
                                                    ,start_time       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id2 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Cash Receipt File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id2;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Cash Receipt');
--------------------------------------------------------------------------------------
--Submit the Program for the Adjustments  Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the File Generation Program for Adjustments');
      ln_conc_req_id3 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARADJEXTWC'
                                                    ,description      => ''
                                                    ,start_time       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id3 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Adjustments File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id3;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Adjustments');
--------------------------------------------------------------------------------------
--Submit the Program for the Payment Schedules Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the File Generation Program for Payment Schedules');
      ln_conc_req_id4 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARPSEXTWC'
                                                    ,description      => ''
                                                    ,start_time       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id4 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Payment Schedule File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id4;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Payment Schedule ');
--------------------------------------------------------------------------------------
--Submit the Program for the Receivable Application  Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the Extract Program for Receivable Applications');
      ln_conc_req_id5 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARRAEXTWC'
                                                    ,description      => ''
                                                    ,start_time       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id5 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Receivable Application File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id5;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Receivable Applications');

--------------------------------------------------------------------------------------
--Error While Submit the Program
--------------------------------------------------------------------------------------
      FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
      LOOP
         IF apps.fnd_concurrent.wait_for_request (ln_req_id (i)
                                                 ,30
                                                 ,0
                                                 ,lc_phase
                                                 ,lc_status
                                                 ,lc_dev_phase
                                                 ,lc_dev_status
                                                 ,lc_message
                                                 ) THEN
            IF UPPER (lc_status) = 'ERROR' THEN
               fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with error');
            ELSIF UPPER (lc_status) = 'WARNING' THEN
               fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with warning');
            ELSE
               fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed normal');
            END IF;
         END IF;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         gc_error_debug := 'No data found :' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS THEN
         gc_error_debug := 'Others exception is raised in the Extract File Generation :' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   END MAIN;
END XX_AR_EXT_FILE_GEN_PKG;

CREATE OR REPLACE PACKAGE BODY XX_AR_EXT_FILE_GEN_PKG
AS
   PROCEDURE MAIN (
      p_errbuf    OUT      VARCHAR2
     ,p_retcode   OUT      NUMBER
     ,p_debug     IN       VARCHAR2
   )
   IS
      ln_conc_id              fnd_concurrent_requests.request_id%TYPE   := -1;
      lb_get_request_status   BOOLEAN;
      lc_phase                VARCHAR2 (100);
      lc_status               VARCHAR2 (100);
      lc_dev_phase            VARCHAR2 (100);
      lc_dev_status           VARCHAR2 (100);
      lc_message              VARCHAR2 (2000);
      ln_batch                NUMBER;
      ln_user_id              NUMBER                                    := FND_PROFILE.VALUE ('user_id');
      ln_appl_id              NUMBER                                    := FND_PROFILE.VALUE ('RESP_APPL_ID');
      ln_resp_id              NUMBER                                    := FND_PROFILE.VALUE ('RESP_ID');
      ln_conc_req_id1         NUMBER;
      ln_conc_req_id2         NUMBER;
      ln_conc_req_id3         NUMBER;
      ln_conc_req_id4         NUMBER;
      ln_conc_req_id5         NUMBER;
      lc_path                 VARCHAR2 (100);
      lc_filename             VARCHAR2 (100);
      lc_debug_flag           VARCHAR2 (1)                              := 'N';
      ln_idx                  NUMBER                                    := 1;
      ln_req_id               req_id;
      gc_error_debug          VARCHAR2 (1000);
      gc_error_loc            NUMBER;
   BEGIN
      FND_GLOBAL.APPS_INITIALIZE (ln_user_id
                                 ,ln_resp_id
                                 ,ln_appl_id
                                 );
--------------------------------------------------------------------------------------
--Submit the Program for the AR Transaction Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the File Generation Program for Transactions');
      ln_conc_req_id1 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARTXNEXTWC'
                                                    ,description      => ''
                                                    ,START_TIME       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id1 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Transaction File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id1;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Transactions');
--------------------------------------------------------------------------------------
--Submit the Program for the Cash Receipt Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the File Generation Program for Cash Receipt');
      ln_conc_req_id2 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARCREXTWC'
                                                    ,description      => ''
                                                    ,start_time       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id2 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Cash Receipt File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id2;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Cash Receipt');
--------------------------------------------------------------------------------------
--Submit the Program for the Adjustments  Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the File Generation Program for Adjustments');
      ln_conc_req_id3 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARADJEXTWC'
                                                    ,description      => ''
                                                    ,start_time       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id3 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Adjustments File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id3;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Adjustments');
--------------------------------------------------------------------------------------
--Submit the Program for the Payment Schedules Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the File Generation Program for Payment Schedules');
      ln_conc_req_id4 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARPSEXTWC'
                                                    ,description      => ''
                                                    ,start_time       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id4 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Payment Schedule File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id4;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Payment Schedule ');
--------------------------------------------------------------------------------------
--Submit the Program for the Receivable Application  Full
--------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, 'Submiting the Extract Program for Receivable Applications');
      ln_conc_req_id5 := FND_REQUEST.SUBMIT_REQUEST (application      => 'XXFIN'
                                                    ,program          => 'XXARRAEXTWC'
                                                    ,description      => ''
                                                    ,start_time       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_debug
                                                    );

      IF ln_conc_req_id5 = 0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Receivable Application File Generation Program is not submitted');
      ELSE
         ln_req_id (ln_idx) := ln_conc_req_id5;
         ln_idx := ln_idx + 1;
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, ' File Generation is completed for Receivable Applications');

--------------------------------------------------------------------------------------
--Error While Submit the Program
--------------------------------------------------------------------------------------
      FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
      LOOP
         IF apps.fnd_concurrent.wait_for_request (ln_req_id (i)
                                                 ,30
                                                 ,0
                                                 ,lc_phase
                                                 ,lc_status
                                                 ,lc_dev_phase
                                                 ,lc_dev_status
                                                 ,lc_message
                                                 ) THEN
            IF UPPER (lc_status) = 'ERROR' THEN
               fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with error');
            ELSIF UPPER (lc_status) = 'WARNING' THEN
               fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with warning');
            ELSE
               fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed normal');
            END IF;
         END IF;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         gc_error_debug := 'No data found :' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS THEN
         gc_error_debug := 'Others exception is raised in the Extract File Generation :' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   END MAIN;
END XX_AR_EXT_FILE_GEN_PKG;
/

SHOW errors;