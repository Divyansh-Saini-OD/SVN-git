CREATE OR REPLACE PACKAGE BODY XX_CN_FAN_EXTRACT_PKG AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_CN_FAN_EXTRACT_PKG                                             |
-- |                                                                                |
-- | Rice ID    : E1004D_CustomCollections_(Fanatic_Extract)                        |
-- | Description: Package body to extract the fanatic data from staging             |
-- |              table and insert it into XX_CN_NOT_TRX and XX_CN_FAN_TRX tables   |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  12-OCT-2007  Hema Chikkanna         Initial draft version             |
-- |1.0       19-OCT-2007  Hema Chikkanna         Updated After Testing             |
-- |1.1       02-NOV-2007  Hema Chikkanna         Incorporated code for Error       |
-- |                                              Reporting,Party site ID Derivation|
-- |                                              and log error procedure           |
-- |1.2       12-NOV-2007  Hema Chikkanna         Incorporated error reporting      |
-- |                                              changes.                          |
-- +================================================================================+


-- Global variables decalration

-- Global Constant
G_EVENT_ID              CONSTANT PLS_INTEGER        :=  9999;
G_SRC_DOC_TYPE          CONSTANT VARCHAR2(4)        := 'FAN';
G_COLLECTION_SRC        CONSTANT VARCHAR2(10)       := 'Fanatic';
G_CHILD_PROG            CONSTANT VARCHAR2(100)      := 'OD: CN Custom Collections (Fanatic Extract) Child Program';
G_PROG_TYPE             CONSTANT VARCHAR2(100)      := 'E1004D_CustomCollections_(Fanatic_Extract)';   


-- Global Variables
gn_batch_size           PLS_INTEGER      := FND_PROFILE.VALUE('XX_CN_FAN_BATCH_SIZE');
gn_client_org_id        NUMBER           := FND_GLOBAL.ORG_ID;


-- +=============================================================+
-- | Name        : fanatic_col_notify                            |
-- | Description : Procedure to extract the fanatic              |
-- |               order data and insert it into                 |
-- |               xx_cn_not_trx table                           |
-- |                                                             |
-- | Parameters  : x_err_msg                OUT   VARCHAR2       |
-- |               x_ret_code               OUT   PLS_INTEGER    |
-- |               p_parent_proc_audit_id   IN    PLS_INTEGER    |
-- |               p_start_date             IN    DATE           |
-- |               p_end_date               IN    DATE           |
-- |                                                             |
-- +=============================================================+

PROCEDURE  fanatic_col_notify ( p_start_date           IN  DATE
                               ,p_end_date             IN  DATE
                               ,p_parent_proc_audit_id IN  PLS_INTEGER
                               ,x_err_msg              OUT NOCOPY VARCHAR2
                               ,x_ret_code             OUT NOCOPY PLS_INTEGER
                               ) IS



ln_trx_count            NUMBER;
lc_error_message        VARCHAR2(4000);

-- Standard who columns
ln_created_by           NUMBER         := FND_GLOBAL.user_id;
ld_creation_date        DATE           := SYSDATE;
ln_last_updated_by      NUMBER         := FND_GLOBAL.user_id;
ld_last_update_date     DATE           := SYSDATE;
ln_last_update_login    NUMBER         := FND_GLOBAL.login_id;
ln_request_id           NUMBER         := FND_GLOBAL.conc_request_id;
ln_prog_appl_id         NUMBER         := FND_GLOBAL.prog_appl_id;

lc_process_type         VARCHAR2(40);
ln_process_audit_id     NUMBER;
lc_descritpion          VARCHAR2(4000);




BEGIN


   lc_process_type      := 'FANATIC_NOTIFY';

   ln_process_audit_id  := NULL;  -- Will get value in the call below

   lc_descritpion       := 'Fanatic Notification Process';


   xx_cn_util_pkg.begin_batch(
                                  p_parent_proc_audit_id  => p_parent_proc_audit_id
                                 ,x_process_audit_id      => ln_process_audit_id
                                 ,p_request_id            => fnd_global.conc_request_id
                                 ,p_process_type          => lc_process_type
                                 ,p_description           => lc_descritpion
                                );


   -------------------------------------------
   -- Insert records into xx_cn_not_trx table
   -------------------------------------------
   INSERT INTO xx_cn_not_trx (
               not_trx_id
              ,row_id
              ,org_id
              ,notified_date
              ,process_audit_id
              ,batch_id
              ,last_extracted_date
              ,extracted_flag
              ,event_id
              ,source_doc_type
              ,source_trx_id
              ,source_trx_line_id
              ,source_trx_number
              ,processed_date
              ,request_id
              ,program_application_id
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              )
         SELECT
              xx_cn_not_trx_s.NEXTVAL
             ,XCFS.ROWID
             ,XCFS.org_id
             ,SYSDATE
             ,ln_process_audit_id
             ,FLOOR(xx_cn_not_trx_s.CURRVAL/gn_batch_size)
             ,SYSDATE
             ,'N'
             ,G_EVENT_ID
             ,G_SRC_DOC_TYPE
             ,NULL
             ,XCFS.line_number
             ,XCFS.order_number
             ,XCFS.rollup_date
             ,ln_request_id
             ,ln_prog_appl_id
             ,ln_created_by
             ,ld_creation_date
             ,ln_last_updated_by
             ,ld_last_update_date
             ,ln_last_update_login
         FROM
              xx_cn_fan_stg     XCFS
         WHERE  XCFS.rollup_date    BETWEEN p_start_date AND p_end_date
         AND    XCFS.org_id         = gn_client_org_id
         AND NOT EXISTS
                      (SELECT 1
                       FROM   xx_cn_not_trx XCNT
                       WHERE  XCNT.source_trx_number  = XCFS.order_number
                       AND    XCNT.source_trx_line_id = XCFS.line_number
                       AND    XCNT.event_id           = G_EVENT_ID
                       AND    XCNT.source_doc_type    = G_SRC_DOC_TYPE);


   ln_trx_count := SQL%ROWCOUNT;

   xx_cn_util_pkg.display_out ( 'Number of Records Notified from Fanatic Source  : ' || ln_trx_count);

   -- Update the batch with number of transaction records extracted

   lc_error_message := 'Finished notification run: Notified ' || ln_trx_count || ' orders.';

   xx_cn_util_pkg.update_batch(
                                p_process_audit_id      => ln_process_audit_id
                               ,p_execution_code        => 0
                               ,p_error_message         => lc_error_message
                              );


   xx_cn_util_pkg.end_batch (ln_process_audit_id);

   COMMIT;

   x_ret_code := 0;

   EXCEPTION

         WHEN OTHERS THEN

             ROLLBACK;

             xx_cn_util_pkg.update_batch(
                                                p_process_audit_id      => ln_process_audit_id
                                               ,p_execution_code        => SQLCODE
                                               ,p_error_message         => SQLERRM
                                           );


             xx_cn_util_pkg.end_batch (ln_process_audit_id);

             x_err_msg := 'Unexpeted error while notifying the Orders: '||SQLERRM;

             x_ret_code := 2;


    END fanatic_col_notify;


-- +=============================================================+
-- | Name        : fanatic_extrcat_main                          |
-- | Description : MAIN Procedure to extract the fanatic         |
-- |               data and insert it into xx_cn_not_trx table   |
-- |                                                             |
-- |                                                             |
-- | Parameters  : x_errbuf         OUT   VARCHAR2               |
-- |               x_retcode        OUT   NUMBER                 |
-- |               p_mode           IN    VARCHAR2               |
-- |               p_start_date     IN    VARCAHR2               |
-- |               p_end_date       IN    VARCAHR2               |
-- |                                                             |
-- +=============================================================+


PROCEDURE fanatic_extract_main ( x_errbuf      OUT NOCOPY VARCHAR2
                                ,x_retcode     OUT NOCOPY NUMBER
                                ,p_mode        IN  VARCHAR2
                                ,p_start_date  IN  VARCHAR2
                                ,p_end_date    IN  VARCHAR2
                               ) IS


ld_start_date                 DATE;
ld_end_date                   DATE;
ln_ext_audit_id               PLS_INTEGER;
lc_err_msg                    VARCHAR2(4000);
ln_ret_code                   PLS_INTEGER;
ln_batch_id                   NUMBER;
lc_error_message              VARCHAR2(4000);
lc_sd_exist                   VARCHAR2(1);
lc_ed_exist                   VARCHAR2(1);
ln_extract_count              PLS_INTEGER;

lc_process_type               VARCHAR2(40);
ln_proc_ext_audit_id          NUMBER;
lc_descritpion                VARCHAR2(4000);

ln_code                       NUMBER;
lc_message                    VARCHAR2(4000);
ln_count                      PLS_INTEGER;
ln_request_id                 NUMBER      := FND_GLOBAL.conc_request_id;



-- Conc request variables
ln_conc_request_id            NUMBER;
lb_wait_req                   BOOLEAN;
lc_phase                      VARCHAR2(25);
lc_status                     VARCHAR2(25);
lc_dev_phase                  VARCHAR2(25);
lc_dev_status                 VARCHAR2(25);
lc_con_message                VARCHAR2(2000);
ln_conc_req_idx               NUMBER := 0;

-- Exception Variable
EX_RUN_CONV_PROG_FIRST        EXCEPTION;
EX_UNEXP_ERR_NOTIFY_ORD       EXCEPTION;
EX_INVALID_CN_PERIOD_DATE     EXCEPTION;
EX_INVALID_FAN_BATCH_SIZE     EXCEPTION;


CURSOR lcu_batch_id IS
   SELECT DISTINCT xcnt.batch_id
   FROM   xx_cn_not_trx xcnt
   WHERE  xcnt.extracted_flag  = 'N'
   AND    xcnt.source_doc_type = G_SRC_DOC_TYPE
   AND    xcnt.event_id        = G_EVENT_ID;



BEGIN

    xx_cn_util_pkg.display_out ('******************** Custom Collections (Fanatic Extract) ********************');
    xx_cn_util_pkg.display_out (' ');
    xx_cn_util_pkg.display_out ('********************************* BEGIN *********************************');
    xx_cn_util_pkg.display_out (' ');

    xx_cn_util_pkg.display_log ('******************** Custom Collections (Fanatic Extract) ********************');
    xx_cn_util_pkg.display_log (' ');
    xx_cn_util_pkg.display_log ('********************************* BEGIN *********************************');
    xx_cn_util_pkg.display_log (' ');

    xx_cn_util_pkg.display_out ( 'Mode of Run: ' || p_mode);
    xx_cn_util_pkg.display_out (' ');
    xx_cn_util_pkg.display_log ( 'Mode of Run: ' || p_mode);
    xx_cn_util_pkg.display_log (' ');

    IF p_mode = 'INTERFACE' THEN

      BEGIN
          
          -------------------------------------------------------
          -- Commented as per change in logic for interface mode 
          -- Modified on 29/Oct/2007 
          -------------------------------------------------------
       /* SELECT MAX(XCNT.last_extracted_date)
          INTO   ld_start_date
          FROM   xx_cn_not_trx         XCNT
          WHERE  XCNT.source_doc_type  = G_SRC_DOC_TYPE
          AND    XCNT.event_id         = G_EVENT_ID;

          IF ld_start_date IS NULL THEN

             -- Raise Exception and Terminate the program
             RAISE EX_RUN_CONV_PROG_FIRST;


          END IF; */
          
          ----------------------------------------------------------------
          -- Included as per change in logic for interface mode 
          -- Modified on 29/Oct/2007 
          ----------------------------------------------------------------
          
          SELECT COUNT (1)
          INTO ln_count
          FROM DUAL
          WHERE EXISTS (
                         SELECT XCNT.not_trx_id
                         FROM   xx_cn_not_trx XCNT
                         WHERE  XCNT.source_doc_type = G_SRC_DOC_TYPE
                         AND    XCNT.event_id        = G_EVENT_ID
                       );
                         
                         
                     
          SELECT MIN (CAPSV.start_date)
          INTO ld_start_date
          FROM cn_acc_period_statuses_v CAPSV
          WHERE (CAPSV.quarter_num, CAPSV.period_year) =
                      (SELECT CAPS.quarter_num
                             ,CAPS.period_year
                       FROM cn_acc_period_statuses_v CAPS
                       WHERE SYSDATE BETWEEN CAPS.start_date AND CAPS.end_date);
          
          
          
          IF (ln_count = 0) 
          THEN
          
               RAISE EX_RUN_CONV_PROG_FIRST;
               
          END IF;
          ---------------------------------          
          -- End of changes on 29/Oct/2007 
          ---------------------------------
          

          ld_end_date := SYSDATE;

       EXCEPTION

          WHEN OTHERS THEN

             RAISE;

       END;

    ELSIF p_mode ='CONVERSION' THEN

       ld_start_date := fnd_date.canonical_to_date(p_start_date);
       ld_end_date   := fnd_date.canonical_to_date(p_end_date);

       xx_cn_util_pkg.display_out ( 'Start Date: ' || ld_start_date);
       xx_cn_util_pkg.display_out ( 'End Date: '   || ld_end_date);

       xx_cn_util_pkg.display_log ( 'Start Date: ' || ld_start_date);
       xx_cn_util_pkg.display_log ( 'End Date: '   || ld_end_date);

    END IF; -- End of Mode branch

    ------------------------------------------------------
    -- Check if input dates belong to Open/Future periods
    ------------------------------------------------------

    xx_cn_util_pkg.display_log('Extract: Checking if start and end dates belong to Open/Future periods');
    xx_cn_util_pkg.display_log ('');
    
    -- Initialize the lc_exist flag
    
    lc_sd_exist := 'N';
    lc_ed_exist := 'N';

    BEGIN

         SELECT 'Y'
         INTO   lc_sd_exist
         FROM   cn_acc_period_statuses_v CAPSV
         WHERE  ld_start_date BETWEEN CAPSV.start_date AND CAPSV.end_date;

         IF (lc_sd_exist = 'N')
         THEN
             -- Raise exception and terminate the program
             RAISE EX_INVALID_CN_PERIOD_DATE;
         END IF;

         SELECT 'Y'
         INTO   lc_ed_exist
         FROM   cn_acc_period_statuses_v CAPSV
         WHERE  ld_end_date BETWEEN CAPSV.start_date AND CAPSV.end_date;

         IF (lc_ed_exist = 'N')
         THEN
             -- Raise exception and terminate the program
             RAISE EX_INVALID_CN_PERIOD_DATE;

         END IF;

    EXCEPTION
         WHEN NO_DATA_FOUND THEN

            RAISE EX_INVALID_CN_PERIOD_DATE;

         WHEN OTHERS THEN

            lc_sd_exist := 'N';
            lc_ed_exist := 'N';

            RAISE;
    END;

    xx_cn_util_pkg.display_log('Extract: End of check for start and end dates belonging to Open/Future periods');
    xx_cn_util_pkg.display_log ('');

    -------------------------------
    -- Check for valid batch size
    -------------------------------
    xx_cn_util_pkg.display_log('Extract: Checking if Batch Size from OD: CN Fanatic Process Batch Size is valid');
    xx_cn_util_pkg.display_log ('');

    IF (gn_batch_size IS NULL OR gn_batch_size <= 0)
    THEN
        -- raise exception and terminate the program
        RAISE EX_INVALID_FAN_BATCH_SIZE;

    END IF;

    xx_cn_util_pkg.display_log('Extract: End of check for valid Batch Size from OD: CN Fanatic Process Batch Size');
    xx_cn_util_pkg.display_log ('');

    ---------------------------
    -- Main extraction process
    ---------------------------

    lc_process_type      := 'FANATIC_MAIN';

    ln_proc_ext_audit_id := NULL;   -- Will get a value in the call below

    lc_descritpion       := 'Fanatic: begin of the main extract process';

    xx_cn_util_pkg.begin_batch(
                                p_parent_proc_audit_id  => NULL
                               ,x_process_audit_id      => ln_proc_ext_audit_id
                               ,p_request_id            => fnd_global.conc_request_id
                               ,p_process_type          => lc_process_type
                               ,p_description           => lc_descritpion
                              );

    ln_ext_audit_id := ln_proc_ext_audit_id;

    xx_cn_util_pkg.DEBUG('Custom Collections>>');

    xx_cn_util_pkg.DEBUG('Extract: Call notify process begin.');

    lc_err_msg      := NULL;
    ln_ret_code     := NULL;

    xx_cn_util_pkg.DEBUG('Extract: entering notify.');
    
    xx_cn_util_pkg.flush; -- Flush the messages to the stack

    ---------------------------------------------------
    -- Call the FANATIC_COL_NOTIFY procedure to extract
    -- the eligible Fanatic data
    ---------------------------------------------------

    fanatic_col_notify ( p_start_date           => ld_start_date
                        ,p_end_date             => ld_end_date
                        ,p_parent_proc_audit_id => ln_proc_ext_audit_id
                        ,x_err_msg              => lc_err_msg
                        ,x_ret_code             => ln_ret_code
                       );
     
    xx_cn_util_pkg.g_process_audit_id := ln_proc_ext_audit_id;

    IF ln_ret_code = 2 THEN

       -- Raise exception and terminate the program

       xx_cn_util_pkg.display_log (lc_err_msg);
       xx_cn_util_pkg.display_log ('');

       RAISE EX_UNEXP_ERR_NOTIFY_ORD;

    END IF;

    xx_cn_util_pkg.DEBUG('Extract: exit from notify and start collection run.');

    --------------------------------------------------------
    -- Insert records into xx_cn_fan_trx table in batches
    --------------------------------------------------------

    xx_cn_util_pkg.DEBUG('Extract: start extraction process.');
    xx_cn_util_pkg.DEBUG('Extract: entering cursor Batches loop.');

    -- Delete the records from concurrent request pl/sql table type
    lt_conc_req_tbl.DELETE;

    FOR lr_batch_id IN lcu_batch_id
    LOOP

        ln_batch_id := lr_batch_id.batch_id;

        ---------------------------------------
        -- Submit the child concurrent program
        ---------------------------------------
        xx_cn_util_pkg.DEBUG('Extract: Submitting the child program for each batch.');
        
        xx_cn_util_pkg.flush;
        
        ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST ( application => 'xxcrm'
                                                          ,program     => 'XXCNFANCHILD'
                                                          ,sub_request => FALSE
                                                          ,argument1   => ln_batch_id
                                                          ,argument2   => ln_proc_ext_audit_id
                                                         );
                                                         
        xx_cn_util_pkg.g_process_audit_id := ln_proc_ext_audit_id;                                                 
                                                         
        COMMIT;

        lc_message  := NULL;
        ln_code     := NULL;

        IF ln_conc_request_id = 0 THEN

            ROLLBACK;

            ln_code := -1;

            FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
            FND_MESSAGE.set_token ('PRG_NAME','XXCNFANCHILD');
            FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);

            lc_message := FND_MESSAGE.get;

            xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                       ,p_prog_type      => G_PROG_TYPE  
                                       ,p_prog_id        => ln_request_id
                                       ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                       ,p_message        => lc_message
                                       ,p_code           => ln_code
                                       ,p_err_code       => 'XX_OIC_0012_CONC_PRG_FAILED'
                                     );


             xx_cn_util_pkg.DEBUG (lc_message);

             xx_cn_util_pkg.display_log (lc_message);
             xx_cn_util_pkg.display_log ('');

             x_retcode := 1;

             x_errbuf := 'Procedure: FANATIC_EXTRACT_MAIN: ' || lc_message;

        ELSE

             lt_conc_req_tbl (ln_conc_req_idx) := ln_conc_request_id;

             xx_cn_util_pkg.DEBUG ('Submitted: '|| G_CHILD_PROG);
             xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);

             xx_cn_util_pkg.DEBUG ('Concurrent Request ID: '|| ln_conc_request_id);
             xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
             xx_cn_util_pkg.display_log ('');

        END IF;

        -- Increment the index number
        ln_conc_req_idx := ln_conc_req_idx + 1;

    END LOOP; -- End of loop on batches

    -------------------------------------------------
    -- Wait for all the child program to complete
    -- before the main program
    -------------------------------------------------
    IF (ln_conc_req_idx > 0) THEN

       FOR i IN 0 .. (ln_conc_req_idx - 1)
       LOOP

           ln_conc_request_id := lt_conc_req_tbl (i);

           lb_wait_req  :=   FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                              request_id => ln_conc_request_id,
                                                              INTERVAL   => 5,
                                                              phase      => lc_phase,
                                                              status     => lc_status,
                                                              dev_phase  => lc_dev_phase,
                                                              dev_status => lc_dev_status,
                                                              message    => lc_con_message
                                                            );

            IF (    lc_dev_status = 'ERROR'
                 OR lc_dev_status = 'TERMINATED'
                 OR lc_dev_status = 'CANCELLED')
            THEN
                    xx_cn_util_pkg.DEBUG (lc_con_message);

                    xx_cn_util_pkg.display_log (lc_con_message);

                    x_retcode := 1;

                    x_errbuf := 'Procedure: FANATIC_EXTRACT_MAIN: ' || lc_con_message;

            END IF; -- End of branch on dev status check

        END LOOP;

    END IF; -- End of branch on concurrent request index check

    COMMIT;

    ln_proc_ext_audit_id := ln_ext_audit_id;

    -- To get the total count of records extracted into xx_cn_fan_trx
    BEGIN

      ln_extract_count := 0;

      SELECT COUNT(*)
      INTO   ln_extract_count
      FROM   xx_cn_fan_trx
      WHERE  process_audit_id = ln_proc_ext_audit_id;

    EXCEPTION
      WHEN OTHERS THEN
             RAISE;
    END;

    xx_cn_util_pkg.display_out ('Total number of records extracted from Fanatic Source: '||ln_extract_count);

    xx_cn_util_pkg.DEBUG ('Total number of records extracted from Fanatic Source: '||ln_extract_count);

    xx_cn_util_pkg.DEBUG('Custom Collections<<');

    xx_cn_util_pkg.end_batch (ln_proc_ext_audit_id);


    xx_cn_util_pkg.display_out ('********************************** End of Process **********************************');


    xx_cn_util_pkg.display_log ('********************************** End of Process **********************************');


    x_retcode := 0;


EXCEPTION

      WHEN EX_RUN_CONV_PROG_FIRST THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0013_RUN_CONV_FIRST');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                    ,p_prog_type      => G_PROG_TYPE
                                    ,p_prog_id        => ln_request_id         
                                    ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                    ,p_message        => lc_message
                                    ,p_code           => ln_code
                                    ,p_err_code       => 'XX_OIC_0013_RUN_CONV_FIRST'
                                   );

         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** End of process ******************************');

         xx_cn_util_pkg.display_out ('*************************** End of process ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: FANATIC_EXTRACT_MAIN: ' || lc_message;

      WHEN EX_INVALID_CN_PERIOD_DATE THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0014_INVALID_CN_DATE');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                   ,p_prog_type      => G_PROG_TYPE
                                   ,p_prog_id        => ln_request_id         
                                   ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                   ,p_message        => lc_message
                                   ,p_code           => ln_code
                                   ,p_err_code       => 'XX_OIC_0014_INVALID_CN_DATE'
                                  );

         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** End of process ******************************');

         xx_cn_util_pkg.display_out ('*************************** End of process ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: FANATIC_EXTRACT_MAIN: ' || lc_message;

      WHEN EX_INVALID_FAN_BATCH_SIZE THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0029_INVALID_FAN_SIZE');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                    ,p_prog_type      => G_PROG_TYPE
                                    ,p_prog_id        => ln_request_id
                                    ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                    ,p_message        => lc_message
                                    ,p_code           => ln_code
                                    ,p_err_code       => 'XX_OIC_0029_INVALID_FAN_SIZE'
                                  );


         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** End of process ******************************');

         xx_cn_util_pkg.display_out ('*************************** End of process ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: FANATIC_EXTRACT_MAIN: ' || lc_message;


      WHEN EX_UNEXP_ERR_NOTIFY_ORD THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0019_NOTIFY_ERROR');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                    ,p_prog_type      => G_PROG_TYPE
                                    ,p_prog_id        => ln_request_id
                                    ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                    ,p_message        => lc_message
                                    ,p_code           => ln_code
                                    ,p_err_code       => 'XX_OIC_0019_NOTIFY_ERROR'
                                  );

         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.update_batch(
                                      p_process_audit_id      => ln_proc_ext_audit_id
                                     ,p_execution_code        => SQLCODE
                                     ,p_error_message         => SQLERRM
                                    );


         xx_cn_util_pkg.end_batch (ln_proc_ext_audit_id);


         xx_cn_util_pkg.display_log ('*************************** End of process ******************************');

         xx_cn_util_pkg.display_out ('*************************** End of process ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: FANATIC_EXTRACT_MAIN: ' || lc_message;

     WHEN OTHERS THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
         FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);

         lc_message := fnd_message.get;

         xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                   ,p_prog_type      => G_PROG_TYPE
                                   ,p_prog_id        => ln_request_id
                                   ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_MAIN'
                                   ,p_message        => lc_message
                                   ,p_code           => ln_code
                                   ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                 );


         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.update_batch(
                                      p_process_audit_id      => ln_proc_ext_audit_id
                                     ,p_execution_code        => SQLCODE
                                     ,p_error_message         => lc_message
                                    );


         xx_cn_util_pkg.end_batch (ln_proc_ext_audit_id);

         xx_cn_util_pkg.display_log ('*************************** End of process ******************************');

         xx_cn_util_pkg.display_out ('*************************** End of process ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: FANATIC_EXTRACT_MAIN: ' || lc_message;

END fanatic_extract_main; -- End of Main Extract Program



-- +=============================================================+
-- | Name        : fanatic_extract_child                         |
-- | Description : Procedure to extract the uncollected data from|
-- |               xx_cn_not_trx table and insert it into        |
-- |               xx_cn_fan_trx table batch wise                |
-- |                                                             |
-- | Parameters  : x_errbuf             OUT   VARCHAR2           |
-- |               x_retcode            OUT   NUMBER             |
-- |               p_batch_id           IN    VARCHAR2           |
-- |               p_process_audit_id   IN    VARCAHR2           |
-- |                                                             |
-- +=============================================================+


PROCEDURE fanatic_extract_child ( x_errbuf            OUT NOCOPY VARCHAR2
                                 ,x_retcode           OUT NOCOPY NUMBER
                                 ,p_batch_id          IN  NUMBER
                                 ,p_process_audit_id  IN  NUMBER
                                ) IS

ln_fan_trx_count         PLS_INTEGER := 0;
L_LIMIT_SIZE             CONSTANT PLS_INTEGER    := 10000;

-- Standard who columns
ln_created_by           NUMBER      := FND_GLOBAL.user_id;
ld_creation_date        DATE        := SYSDATE;
ln_last_updated_by      NUMBER      := FND_GLOBAL.user_id;
ld_last_update_date     DATE        := SYSDATE;
ln_last_update_login    NUMBER      := FND_GLOBAL.login_id;
ln_request_id           NUMBER      := FND_GLOBAL.conc_request_id;
ln_prog_appl_id         NUMBER      := FND_GLOBAL.prog_appl_id;

lc_err_msg              VARCHAR2(4000);
ln_ret_code             PLS_INTEGER;

ln_code                 NUMBER;
lc_message              VARCHAR2(4000);

ln_proc_col_audit_id    NUMBER;
lc_error_message        VARCHAR2(4000);
lc_process_type         VARCHAR2(40);
lc_descritpion          VARCHAR2(4000);
lb_val_rec              BOOLEAN;

ln_null_rev_class       PLS_INTEGER;
ln_null_drop_ship       PLS_INTEGER;
ln_null_po_cost         PLS_INTEGER;      
ln_null_rollup_date     PLS_INTEGER;
ln_null_party_site      PLS_INTEGER;



CURSOR lcu_fan_trx IS
     SELECT   xx_cn_fan_trx_s.NEXTVAL           -- fan_trx_id
             ,NULL                              -- Booked Date
             ,XCFS.ordered_date                 -- Ordered Date
             ,XCFS.salesrep_id                  -- Salesrep ID
             ,HCA.cust_account_id               -- Customer ID
             ,NULL                              -- Inventory Item ID
             ,XCFS.ordered_date                 -- processed_date
             ,cn_api.get_acc_period_id(XCFS.ordered_date)                             -- Processed Period Id
             ,XCFS.org_id                       -- Org Id
             ,G_EVENT_ID                        -- Event ID
             ,'NON-REVENUE'                     -- Revenue Type
             ,cn_api.get_site_address_id(HCAS.party_site_id)                          -- Ship to Address Id
             ,HCAS.party_site_id                                                      -- Party Site ID
             ,DECODE(XCFS.return_flag,'Y',XCFS.original_order_date,XCFS.rollup_date)  -- Rollup Date
             ,G_SRC_DOC_TYPE                    -- Source Doc Type 'FAN'
             ,NULL                              -- Source Trx ID
             ,XCFS.line_number                  -- Source Trx Line ID
             ,XCFS.order_number                 -- Source Trx Number
             ,NVL(XCFS.quantity, 0)             -- Qunatity
             ,NVL(XCFS.transaction_amount,0)    -- Transaction Amount
             ,XCFS.transaction_currency_code    -- Transactional Currency Code
             ,XCFS.trx_type                     -- Trx Type
             ,NULL                              -- Class code
             ,NULL                              -- Department code
             ,XCFS.private_brand                -- Private Brand flag
             ,XCFS.cost                         -- PO Cost
             ,XCRC.division                     -- Division
             ,XCRC.revenue_class_id             -- Revenue_class_id
             ,XCFS.drop_ship_flag               -- Drop Ship Flag
             ,XCFS.margin                       -- Margin Amount
             ,0                                 -- Discount Percentage
             ,NULL                              -- Exchange Rate
             ,XCFS.return_reason_code           -- Return Reason Code
             ,NULL                              -- Order Source name
             ,'N'                               -- Summarized Flag
             ,'N'                               -- Salesrep Assign Flag
             ,p_batch_id                        -- Batch ID
             ,NULL                              -- Transfer Batch ID
             ,NULL                              -- Summ Batch ID
             ,p_process_audit_id                -- Process Audit ID
             ,ln_request_id                     -- Conc req ID
             ,ln_prog_appl_id                   -- Program Application ID
             ,ln_created_by                     -- Standard WHO Column
             ,ld_creation_date                  -- Standard WHO Column
             ,ln_last_updated_by                -- Standard WHO Column
             ,ld_last_update_date               -- Standard WHO Column
             ,ln_last_update_login              -- Standard WHO Column
     FROM     xx_cn_not_trx                 XCNT
             ,xx_cn_fan_stg                 XCFS
             ,hz_cust_accounts              HCA
             ,hz_cust_acct_sites            HCAS
             ,xx_cn_rev_class               XCRC
     WHERE    XCFS.order_number           = XCNT.source_trx_number
     AND      XCFS.line_number            = XCNT.source_trx_line_id
     AND      XCFS.customer_seq_num       = HCA.orig_system_reference
     AND      XCFS.shipto_seq             = HCAS.orig_system_reference
     AND      HCA.cust_account_id         = HCAS.cust_account_id
     AND      XCNT.org_id                 = gn_client_org_id
     AND      XCFS.org_id                 = XCNT.org_id
     AND      XCRC.collection_source      = G_COLLECTION_SRC
     AND      XCNT.event_id               = G_EVENT_ID
     AND      XCNT.extracted_flag         = 'N'
     AND      XCNT.batch_id               = p_batch_id;


BEGIN

   xx_cn_util_pkg.display_out (' Office DEPOT');
   xx_cn_util_pkg.display_out (' ');
   xx_cn_util_pkg.display_out (RPAD (' ', 100, '_'));
   xx_cn_util_pkg.display_out ('');
      
   xx_cn_util_pkg.display_out (' Fanatic Child Extract for Batch ID:  '||p_batch_id );
   xx_cn_util_pkg.display_out (' ');


   ------------------------------------
   -- Begin a new batch for Extraction
   ------------------------------------
   ln_proc_col_audit_id := NULL;   -- Will get a value in the call below

   lc_process_type      := 'FANATIC_EXTRACT';

   lc_descritpion       := 'Extraction run for batch ' || p_batch_id;


   xx_cn_util_pkg.begin_batch(
                               p_parent_proc_audit_id  => p_process_audit_id
                              ,x_process_audit_id      => ln_proc_col_audit_id
                              ,p_request_id            => fnd_global.conc_request_id
                              ,p_process_type          => lc_process_type
                              ,p_description           => lc_descritpion
                             );
                             
   xx_cn_util_pkg.DEBUG('Extract: Inside the Child Program to insert records into XX_CN_FAN_TRX table .');
   
   xx_cn_util_pkg.DEBUG('Extract: Running Child Program for Batch ID : ' ||p_batch_id);
   
   
   ln_null_rev_class   := 0;     
   ln_null_drop_ship   := 0;     
   ln_null_po_cost     := 0;      
   ln_null_rollup_date := 0;
   ln_null_party_site  := 0;
   

   OPEN lcu_fan_trx;

   LOOP

      lt_fantrx.DELETE;
      lt_fantrx_suc.DELETE;
      lt_fantrx_fal.DELETE;

      ln_code    := NULL;
      lc_message := NULL;

      FETCH lcu_fan_trx BULK COLLECT INTO lt_fantrx LIMIT L_LIMIT_SIZE;
      
      IF (lt_fantrx.COUNT > 0 )
      THEN

         FOR idx IN lt_fantrx.FIRST .. lt_fantrx.LAST
         LOOP

             lb_val_rec := TRUE;
             
             --------------------------------
             -- Calculation of Margin Amount
             --------------------------------
             IF lt_fantrx(idx).cost IS NOT NULL 
             THEN
             
                   IF lt_fantrx(idx).drop_ship_flag IS NOT NULL
                   THEN
                   
                        IF lt_fantrx(idx).drop_ship_flag = 'N' THEN

                            lt_fantrx(idx).margin := lt_fantrx(idx).transaction_amount - (lt_fantrx(idx).quantity * lt_fantrx(idx).cost);

                        ELSE

                            lt_fantrx(idx).margin := (lt_fantrx(idx).transaction_amount * 1.1) - (lt_fantrx(idx).quantity * lt_fantrx(idx).cost);

                        END IF;
                    
                   ELSE
                       
                       ln_code    := NULL;
                                    
                       lc_message := NULL;
                       
                       lb_val_rec := FALSE;
                       
                       ln_null_drop_ship := ln_null_drop_ship +1;
                       
                       ln_code := -1;
                       
                       FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0055_NO_DROP_SHIP');
                       FND_MESSAGE.set_token ('ORDER_NO',lt_fantrx(idx).source_trx_number);
                       FND_MESSAGE.set_token ('LINE_NO', lt_fantrx(idx).source_trx_line_id);
                       
                       
                       lc_message := FND_MESSAGE.get;
                       
                       xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                                  ,p_prog_type      => G_PROG_TYPE
                                                  ,p_prog_id        => ln_request_id 
                                                  ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                                  ,p_message        => lc_message
                                                  ,p_code           => ln_code
                                                  ,p_err_code       => 'XX_OIC_0055_NO_DROP_SHIP'
                                                );
                       
                       
                       xx_cn_util_pkg.DEBUG (lc_message);
                                         
                    
                   END IF; -- end of drop ship flag check
                  
             ELSE
             
                 ln_code    := NULL;
             
                 lc_message := NULL;
             
                 lb_val_rec := FALSE;
             
                 ln_null_po_cost := ln_null_po_cost +1;
             
                 ln_code := -1;
             
                 FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0024_NO_PO_COST');
                 FND_MESSAGE.set_token ('ORDER_NO',lt_fantrx(idx).source_trx_number);
                 FND_MESSAGE.set_token ('LINE_NO', lt_fantrx(idx).source_trx_line_id);
             
             
                 lc_message := FND_MESSAGE.get;
             
                 xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                            ,p_prog_type      => G_PROG_TYPE
                                            ,p_prog_id        => ln_request_id 
                                            ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                            ,p_message        => lc_message
                                            ,p_code           => ln_code
                                            ,p_err_code       => 'XX_OIC_0024_NO_PO_COST'
                                          );
             
             
                  xx_cn_util_pkg.DEBUG (lc_message);
             
              END IF; -- End of po cost check
             
             --------------------------
             -- Check for Rollup Date
             --------------------------
             IF lt_fantrx(idx).rollup_date IS NULL THEN


                 ln_code    := NULL;

                 lc_message := NULL;

                 lb_val_rec := FALSE;
                 
                 ln_null_rollup_date  := ln_null_rollup_date + 1;

                 ln_code := -1;

                 FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0030_NO_ROLLUP_DATE');
                 FND_MESSAGE.set_token ('ORDER_NO',lt_fantrx(idx).source_trx_number);
                 FND_MESSAGE.set_token ('LINE_NO', lt_fantrx(idx).source_trx_line_id);


                 lc_message := FND_MESSAGE.get;

                 xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                            ,p_prog_type      => G_PROG_TYPE
                                            ,p_prog_id        => ln_request_id 
                                            ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                            ,p_message        => lc_message
                                            ,p_code           => ln_code
                                            ,p_err_code       => 'XX_OIC_0030_NO_ROLLUP_DATE'
                                          );


                 xx_cn_util_pkg.DEBUG (lc_message);

                 xx_cn_util_pkg.display_log (lc_message);


             END IF; -- end of roll up date check
             
             ---------------------------
             -- Check for Party Site ID
             ---------------------------

             IF lt_fantrx(idx).party_site_id IS NULL 
             THEN

                 ln_code    := NULL;

                 lc_message := NULL;

                 lb_val_rec := FALSE;

                 ln_null_party_site := ln_null_party_site + 1;

                 ln_code := -1;

                 FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0031_NO_PARTY_SITE_ID');
                 FND_MESSAGE.set_token ('ORDER_NO',lt_fantrx(idx).source_trx_number);
                 FND_MESSAGE.set_token ('LINE_NO', lt_fantrx(idx).source_trx_line_id);


                 lc_message := FND_MESSAGE.get;

                 xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                            ,p_prog_type      => G_PROG_TYPE
                                            ,p_prog_id        => ln_request_id 
                                            ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                            ,p_message        => lc_message
                                            ,p_code           => ln_code
                                            ,p_err_code       => 'XX_OIC_0031_NO_PARTY_SITE_ID'
                                          );


                 xx_cn_util_pkg.DEBUG (lc_message);

                 xx_cn_util_pkg.display_log (lc_message);

             END IF;   -- end of party site id validation


             -------------------------------
             -- Check for Revenue Class
             -------------------------------

             lc_err_msg  := NULL;
             ln_ret_code := NULL;


             IF lt_fantrx(idx).revenue_class_id IS NULL THEN


                    ln_code    := NULL;

                    lc_message := NULL;

                    lb_val_rec := FALSE;
                    
                    ln_null_rev_class := ln_null_rev_class + 1;

                    ln_code := -1;

                    FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0032_NO_REV_CLASS_ID');
                    FND_MESSAGE.set_token ('ORDER_NO',lt_fantrx(idx).source_trx_number);
                    FND_MESSAGE.set_token ('LINE_NO', lt_fantrx(idx).source_trx_line_id);



                    lc_message := FND_MESSAGE.get;

                    xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                               ,p_prog_type      => G_PROG_TYPE
                                               ,p_prog_id        => ln_request_id 
                                               ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                               ,p_message        => lc_message
                                               ,p_code           => ln_code
                                               ,p_err_code       => 'XX_OIC_0032_NO_REV_CLASS_ID'
                                             );


                    xx_cn_util_pkg.DEBUG (lc_message);

                    xx_cn_util_pkg.display_log (lc_message);



             END IF; -- end of revenue class id validation




             -- Assigning value to lt_fantrx_suc pl/sql table type

             IF lb_val_rec = TRUE THEN

                lt_fantrx_suc(lt_fantrx_suc.COUNT+1) := lt_fantrx(idx);
                
             ELSIF lb_val_rec = FALSE THEN      
                 
                lt_fantrx_fal(lt_fantrx_fal.COUNT+1) := lt_fantrx(idx); 

             END IF;
              
      END LOOP; -- End of lt_omtrx loop
      
      END IF; -- End of main cursor count branch


      -- Bulk insert into XX_CN_FAN_TRX table
      
      xx_cn_util_pkg.DEBUG('Extract: Inserting into XX_CN_FAN_TRX.');

      FORALL i IN lt_fantrx_suc.FIRST .. lt_fantrx_suc.LAST

        INSERT INTO xx_cn_fan_trx VALUES lt_fantrx_suc(i);


      ln_fan_trx_count := ln_fan_trx_count + lt_fantrx_suc.COUNT;
      
      ----------------------------------------------------------------------------
      --Report all errored records to the End User
      ----------------------------------------------------------------------------
      IF(lt_fantrx_fal.COUNT > 0) THEN
      
            xx_cn_util_pkg.display_log        (RPAD (' ', 230, '_'));
            xx_cn_util_pkg.display_log        ('');
      
            xx_cn_util_pkg.display_log        (' Records having NULL Revenue Class                 :              '||LPAD(ln_null_rev_class,15));
            xx_cn_util_pkg.display_log        ('');
            
            xx_cn_util_pkg.display_log        (' Records having NULL PO Cost                       :              '||LPAD(ln_null_po_cost,15));
            xx_cn_util_pkg.display_log        ('');
            
            xx_cn_util_pkg.display_log        (' Records having NULL Drop Ship Flag                :              '||LPAD(ln_null_drop_ship,15));
            xx_cn_util_pkg.display_log        ('');
            
            xx_cn_util_pkg.display_log        (' Records having NULL Rollup Date                   :              '||LPAD(ln_null_rollup_date,15));
            xx_cn_util_pkg.display_log        ('');
            
            xx_cn_util_pkg.display_log        (' Records having NULL Party Site ID                 :              '||LPAD(ln_null_party_site,15));
            xx_cn_util_pkg.display_log        ('');
            
            xx_cn_util_pkg.display_out        (' Number of Errored Fanatic Order Records           :              '||LPAD(lt_fantrx_fal.COUNT,15));
            xx_cn_util_pkg.display_out        ('');
            
            xx_cn_util_pkg.display_log        (' Number of Errored Fanatic Order Records           :              '||LPAD(lt_fantrx_fal.COUNT,15));
            xx_cn_util_pkg.display_log        ('');
            
            xx_cn_util_pkg.display_log        (' (The Errored Records have a NULL or INVALID value in Revenue Class ID,PO Cost, Drop Ship Flag, Party Site ID or Rollup Date.)');
            xx_cn_util_pkg.display_log        ('');
            
            xx_cn_util_pkg.display_log        (RPAD (' ', 230, '_'));
            xx_cn_util_pkg.display_log 
                                              (     RPAD (' CUSTOMER_ID', 15)
                                                 || CHR(9)
                                                 || RPAD (' ORDER_NUMBER', 20)
                                                 || CHR(9)
                                                 || RPAD (' ORDER_DATE', 15)
                                                 || CHR(9)
                                                 || RPAD (' LINE_NUMBER', 15)
                                                 || CHR(9)
                                                 || RPAD (' ROLLUP_DATE', 15)
                                                 || CHR(9)
                                                 || LPAD (' COST', 10)
                                                 || RPAD (' ', 5)
                                                 || CHR(9)
                                                 || RPAD ('PRIVATE_BRAND', 15)
                                                 || CHR(9)
                                                 || RPAD ('DIVISION', 15)
                                                 || CHR(9)
                                                 || RPAD ('REVENUE_CLASS', 15)
                                                 || CHR(9)
                                               );
            xx_cn_util_pkg.display_log        (RPAD (' ', 230, '_'));
            
            
            FOR i IN lt_fantrx_fal.FIRST .. lt_fantrx_fal.LAST
            LOOP
                 xx_cn_util_pkg.display_log 
                                              (     RPAD (' '||NVL(TO_CHAR(lt_fantrx_fal(i).customer_id),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_fantrx_fal(i).source_trx_number),' '), 20)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_fantrx_fal(i).order_date),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_fantrx_fal(i).source_trx_line_id),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_fantrx_fal(i).rollup_date),' '), 15)
                                                 || CHR(9)
                                                 || LPAD (NVL(TRIM(TO_CHAR(ROUND(lt_fantrx_fal(i).cost,2),'9,999,999,999,999,999,999,999,999,999,999,999,999.99')),' '), 10)
                                                 || RPAD (' ', 5)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_fantrx_fal(i).private_brand),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_fantrx_fal(i).division),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_fantrx_fal(i).revenue_class_id),' '), 15)
                                                 || CHR(9)
                                              );
            END LOOP;
      
            xx_cn_util_pkg.display_log        (RPAD (' ', 230, '_'));
            xx_cn_util_pkg.display_log        ('');
      
            x_retcode                         := 1;
      
            x_errbuf                          := 'Procedure: FANATIC_EXTRCAT_CHILD: This Batch has some errored Records';
            
      END IF; -- End of error reporting

      -------------------------------------------------------------
      -- Update the xx_cn_not_trx table with extracted flag to Y
      -------------------------------------------------------------
      
      xx_cn_util_pkg.DEBUG('Extract: Updating extracted_flag in XX_CN_NOT_TRX .');

      UPDATE xx_cn_not_trx XCNT
      SET    XCNT.extracted_flag    = 'Y'
            ,XCNT.last_updated_by   = ln_last_updated_by
            ,XCNT.last_update_date  = ld_last_update_date
            ,XCNT.last_update_login = ln_last_update_login
      WHERE (XCNT.batch_id,XCNT.source_trx_number,XCNT.source_trx_line_id)
                                    = (SELECT XCFT.batch_id
                                             ,XCFT.source_trx_number
                                             ,XCFT.source_trx_line_id
                                       FROM   xx_cn_fan_trx XCFT
                                       WHERE  XCFT.source_trx_number  = XCNT.source_trx_number
                                       AND    XCFT.source_trx_line_id = XCNT.source_trx_line_id
                                       AND    XCFT.event_id           = G_EVENT_ID);


      xx_cn_util_pkg.DEBUG('Extract: Updated extracted_flag in XX_CN_NOT_TRX.');

      COMMIT;

      EXIT WHEN lcu_fan_trx%NOTFOUND;

   END LOOP;

   CLOSE lcu_fan_trx;

   xx_cn_util_pkg.DEBUG('Extract: Number of records inserted into XX_CN_FAN_TRX table: '||ln_fan_trx_count || '    for batch:  '||p_batch_id );

   xx_cn_util_pkg.display_out(' Extract: Number of records inserted into XX_CN_FAN_TRX table: '||ln_fan_trx_count || '   for batch:  '||p_batch_id );
   
   xx_cn_util_pkg.display_out  (RPAD (' ', 100, '_'));


   lc_error_message := 'Finished Inserting records into XX_CN_FAN_TRX table for batch: '||p_batch_id;

   xx_cn_util_pkg.update_batch(
                                p_process_audit_id      => ln_proc_col_audit_id
                               ,p_execution_code        => 0
                               ,p_error_message         => lc_error_message
                              );


   xx_cn_util_pkg.end_batch (ln_proc_col_audit_id);

  
   
   IF lt_fantrx_fal.COUNT > 0
   THEN

        x_retcode := 1;
        
   ELSE

        x_retcode := 0;
        

   END IF;



 EXCEPTION

   WHEN OTHERS THEN

         ROLLBACK;

         CLOSE lcu_fan_trx;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
         FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                   ,p_prog_type      => G_PROG_TYPE
                                   ,p_prog_id        => ln_request_id 
                                   ,p_exception      => 'XX_CN_FAN_EXTRACT_PKG.FANATIC_EXTRACT_CHILD'
                                   ,p_message        => lc_message
                                   ,p_code           => ln_code
                                   ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                  );


         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.update_batch(
                                         p_process_audit_id      => ln_proc_col_audit_id
                                        ,p_execution_code        => SQLCODE
                                        ,p_error_message         => lc_message
                                    );


         xx_cn_util_pkg.end_batch (ln_proc_col_audit_id);

         x_retcode := 2;

         x_errbuf  := lc_message;

 END fanatic_extract_child;

 END  XX_CN_FAN_EXTRACT_PKG;
/

SHOW ERRORS

EXIT;