SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_ITEMXREF_CONV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_INV_ITEMXREF_CONV_PKG.pkb                       |
-- | Description :  INV Item Cross Reference Master Package Spec       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author          Remarks                      |
-- |========  =========== =============== =============================|
-- |DRAFT 1a  05-Apr-2007 Abhradip Ghosh  Initial draft version        |
-- |DRAFT 1b  10-Apr-2007 Abhradip Ghosh  Incorporated the Master      |
-- |                                       Conversion Program Logic    |
-- |DRAFT 1c  14-Jun-2007 Abhradip Ghosh  Incorporated OnSite Comments |
-- |DRAFT 1d  14-Jun-2007 Parvez Siddiqui TL Review                    |
-- |DRAFT 1e  21-Jun-2007 Abhradip Ghosh  Incorporated the validation  |
-- |                                      procedure from the Interface |
-- |DRAFT 1f  21-Jun-2007 Parvez Siddiqui TL Review                    |
-- |DRAFT 1g  26-Jun-2007 Abhradip Ghosh  Added master_request_id      |
-- |                                      parameter to summary report  |
-- |DRAFT 1h  26-Jun-2007 Parvez Siddiqui TL Review                    |
-- |1.0       21-Aug-2007 Paddy Sanjeevi  Baseline                     |
-- +===================================================================+
AS

-- ----------------------------
-- Declaring Global Constants
-- ----------------------------
G_SLEEP                    CONSTANT PLS_INTEGER  := 60;
G_MAX_WAIT_TIME            CONSTANT PLS_INTEGER  := 300;
G_COMN_APPLICATION         CONSTANT VARCHAR2(30) := 'XXCOMN';
G_SUMRY_REPORT_PRGM        CONSTANT VARCHAR2(30) := 'XXCOMCONVSUMMREP';
G_EXCEP_REPORT_PRGM        CONSTANT VARCHAR2(30) := 'XXCOMCONVEXPREP';
G_CONVERSION_CODE          CONSTANT VARCHAR2(30) := 'C0272_ItemXref';
G_CHLD_PROG_APPLICATION    CONSTANT VARCHAR2(30) := 'INV';
G_CHLD_PROG_EXECUTABLE     CONSTANT VARCHAR2(30) := 'XX_INV_ITEMXREF_CNV_PG_CH_MAIN';
G_PACKAGE_NAME             CONSTANT VARCHAR2(30) := 'XX_INV_ITEMXREF_CONV_PKG';
G_STAGING_TABLE_NAME       CONSTANT VARCHAR2(30) := 'XX_INV_ITEMXREF_STG';
G_ACTION                   CONSTANT VARCHAR2(01) := 'C';

-- ---------------------------
-- Global Variable Declaration
-- ---------------------------
gn_index_req_id      PLS_INTEGER := 0;
gn_batch_size        PLS_INTEGER;
gn_conversion_id     PLS_INTEGER;
gn_max_child_req     PLS_INTEGER;
gn_master_request_id PLS_INTEGER;
gn_batch_count       PLS_INTEGER := 0;
gn_record_count      PLS_INTEGER := 0;

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE req_id_tbl_type IS TABLE OF fnd_concurrent_requests.request_id%TYPE
INDEX BY BINARY_INTEGER;
gt_req_id req_id_tbl_type;


-- +====================================================================+
-- | Name        :  display_log                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+

PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+

PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END;

-- +======================================================================+
-- | Name        :  bat_child                                             |
-- | Description :  This procedure is invoked from the submit_sub_requests|
-- |                procedure. This would submit child requests based     |
-- |                on batch_size.                                        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_request_id                                          |
-- |                p_validate_only_flag                                  |
-- |                p_reset_status_flag                                   |
-- |                                                                      |
-- | Returns     :  x_time                                                |
-- |                                                                      |
-- +======================================================================+

PROCEDURE bat_child(
                    p_request_id          IN  NUMBER
                    ,p_validate_only_flag IN  VARCHAR2
                    ,p_reset_status_flag  IN  VARCHAR2
                    ,x_time               OUT NOCOPY DATE
                    ,x_errbuf             OUT NOCOPY VARCHAR2
                    ,x_retcode            OUT NOCOPY VARCHAR2
                   )

IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_SUBMIT_CHILD     EXCEPTION;
ln_batch_size_count PLS_INTEGER;
ln_seq              PLS_INTEGER;
ln_req_count        PLS_INTEGER;
ln_request_id       PLS_INTEGER;

BEGIN
   -- ----------------------------------
   -- Get the batch_id from the sequence
   -- ----------------------------------
   SELECT xx_inv_itemxref_stg_bat_s.NEXTVAL
   INTO   ln_seq
   FROM   DUAL;

   -- -----------------------------
   -- Assign batches to the records
   -- -----------------------------
   UPDATE xx_inv_itemxref_stg XIIS
   SET    XIIS.load_batch_id = ln_seq
          ,XIIS.process_flag = 2
   WHERE  XIIS.load_batch_id IS NULL
   AND    XIIS.process_flag = 1
   AND    rownum <= gn_batch_size ;

   ln_batch_size_count := SQL%ROWCOUNT;

   COMMIT;

   gn_record_count := gn_record_count + ln_batch_size_count;

   LOOP
      -- --------------------------------------------
      -- Get the count of running concurrent requests
      -- --------------------------------------------
      SELECT COUNT(1)
      INTO   ln_req_count
      FROM   fnd_concurrent_requests FCR
      WHERE  FCR.parent_request_id  = gn_master_request_id
      AND    FCR.phase_code IN ('P','R');
      
      IF  ln_req_count < gn_max_child_req THEN
          -- ---------------------------------------------------------
          -- Call the custom concurrent program for parallel execution
          -- ---------------------------------------------------------
          ln_request_id := FND_REQUEST.submit_request(
                                                      application  => G_CHLD_PROG_APPLICATION
                                                      ,program     => G_CHLD_PROG_EXECUTABLE
                                                      ,sub_request => FALSE
                                                      ,argument1   => p_validate_only_flag
                                                      ,argument2   => p_reset_status_flag
                                                      ,argument3   => ln_seq
                                                     );

          IF ln_request_id = 0 THEN
             
             x_errbuf  := FND_MESSAGE.get;
             RAISE EX_SUBMIT_CHILD;

          ELSE

              COMMIT;
              gn_index_req_id            := gn_index_req_id + 1;
              gt_req_id(gn_index_req_id) := ln_request_id;
              gn_batch_count             := gn_batch_count + 1;
              x_time                     := sysdate;

              ----------------------------------------------------
              -- Procedure to Log Conversion Control Informations.
              ----------------------------------------------------
              XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                                                             p_conversion_id           => gn_conversion_id
                                                             ,p_batch_id               => ln_seq
                                                             ,p_num_bus_objs_processed => ln_batch_size_count
                                                             );
              EXIT;

          END IF;

      ELSE

          DBMS_LOCK.sleep(G_SLEEP);
                    

      END IF;
   END LOOP;

EXCEPTION
  WHEN EX_SUBMIT_CHILD THEN
       x_retcode := 2;
       x_errbuf  := 'Error in submitting child requests: ' || x_errbuf;
  WHEN OTHERS THEN
      x_retcode := 2;
      x_errbuf  := 'Unexpected error in bat_child : ' || x_errbuf;
END bat_child;

-- +====================================================================+
-- | Name        :  get_conversion_id                                   |
-- | Description :  This procedure is invoked to get the conversion_id  |
-- |                ,batch_size and max_threads                         |
-- |                                                                    |
-- | Parameters  :                                                      |
-- |                                                                    |
-- | Returns     :  Conversion_ID                                       |
-- |                Batch_Size                                          |
-- |                                                                    |
-- +====================================================================+

PROCEDURE get_conversion_id(
                            x_conversion_id   OUT NOCOPY NUMBER
                            ,x_batch_size     OUT NOCOPY NUMBER
                            ,x_max_threads    OUT NOCOPY NUMBER
                            ,x_return_status  OUT NOCOPY VARCHAR2
                           )
IS

BEGIN

   SELECT XCCC.conversion_id,
          XCCC.batch_size,
          XCCC.max_threads
   INTO   x_conversion_id,
          x_batch_size,
          x_max_threads
   FROM   xx_com_conversions_conv XCCC
   WHERE  XCCC.conversion_code = G_CONVERSION_CODE;

   x_return_status := 'S';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_return_status := 'E';
   WHEN OTHERS THEN
       x_return_status := 'E';
       display_log('Error while deriving conversion_id - '||SQLERRM);
END get_conversion_id;

-- +====================================================================+
-- | Name        :  update_batch_id                                     |
-- | Description :  This procedure is invoked to reset Batch Id to Null |
-- |                for Previously Errored Out Records                  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+

PROCEDURE update_batch_id(
                          x_errbuf    OUT NOCOPY VARCHAR2
                          ,x_retcode  OUT NOCOPY VARCHAR2
                         )
IS
BEGIN

   -- ------------------------------
   -- To update the errored records
   -- ------------------------------
   UPDATE xx_inv_itemxref_stg XIIS
   SET    XIIS.load_batch_id = NULL
          ,XIIS.process_flag = 1
   WHERE  XIIS.process_flag NOT IN (0,7);

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected error in update_batch_id - '||SQLERRM;
       display_log(x_errbuf);
END update_batch_id;

-- +====================================================================+
-- | Name        :  launch_summary_report                               |
-- | Description :  This procedure is invoked to Launch Conversion      |
-- |                Processing Summary Report for that run              |
-- |                                                                    |
-- | Parameters  :                                                      |
-- +====================================================================+

PROCEDURE launch_summary_report(
                                x_errbuf   OUT NOCOPY VARCHAR2
                                ,x_retcode OUT NOCOPY VARCHAR2
                               )

IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_REP_SUMM             EXCEPTION;
lc_phase                VARCHAR2(03);
ln_summ_request_id      PLS_INTEGER;

BEGIN

   -- --------------------------------------------------
   -- To check whether the child requests have finished
   -- If not then wait
   -- --------------------------------------------------
   FOR i IN gt_req_id.FIRST .. gt_req_id.LAST
   LOOP
       LOOP
           SELECT FCR.phase_code
           INTO   lc_phase
           FROM   fnd_concurrent_requests FCR
           WHERE  FCR.request_id = gt_req_id(i);

           IF  lc_phase = 'C' THEN
               EXIT;
           ELSE
               DBMS_LOCK.SLEEP(G_SLEEP);
           END IF;
       END LOOP;
   END LOOP;
   
   -- ----------------------------
   -- Launch the exception report 
   -- ----------------------------

   ln_summ_request_id := FND_REQUEST.submit_request(
                                                    application  => G_COMN_APPLICATION
                                                    ,program     => G_SUMRY_REPORT_PRGM
                                                    ,sub_request => FALSE                 -- TRUE means is a sub request
                                                    ,argument1   => G_CONVERSION_CODE     -- conversion_code
                                                    ,argument2   => gn_master_request_id  -- MASTER REQUEST ID
                                                    ,argument3   => NULL                  -- REQUEST ID
                                                    ,argument4   => NULL                  -- BATCH ID
                                                   );

   IF  ln_summ_request_id = 0 THEN
       x_errbuf  := FND_MESSAGE.GET;
       RAISE EX_REP_SUMM;
   ELSE
       COMMIT;
   END IF;

EXCEPTION
   WHEN EX_REP_SUMM THEN
       x_retcode := 2;
       x_errbuf  := 'Processing Summary Report for the batch could not be submitted: '|| x_errbuf;
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected Error in launch_summary_report : '||SQLERRM;
END launch_summary_report;

-- +===================================================================+
-- | Name        :  submit_sub_requests                                |
-- | Description :  This procedure is invoked from the conv_master_main|
-- |                procedure. This would submit child requests based  |
-- |                on batch_size.                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE submit_sub_requests(
                              p_validate_only_flag  IN  VARCHAR2
                              ,p_reset_status_flag  IN  VARCHAR2
                              ,x_errbuf             OUT NOCOPY VARCHAR2
                              ,x_retcode            OUT NOCOPY VARCHAR2
                             )

IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_NO_ENTRY       EXCEPTION;
EX_NO_DATA        EXCEPTION;
ld_check_time     DATE;
ld_current_time   DATE;
ln_rem_time       NUMBER;
ln_current_count  PLS_INTEGER;
ln_last_count     PLS_INTEGER;
lc_return_status  VARCHAR2(03);
lc_launch         VARCHAR2(02) := 'N';

BEGIN

   -----------------------------
   -- Getting the Conversion id
   -----------------------------

   get_conversion_id(
                     x_conversion_id  => gn_conversion_id
                     ,x_batch_size    => gn_batch_size
                     ,x_max_threads   => gn_max_child_req
                     ,x_return_status => lc_return_status
                    );

   IF lc_return_status = 'S' THEN
     ----------------------------------------------
     -- Update Batch Id if p_reset_status_flag='Y'
     ----------------------------------------------
     IF NVL(p_reset_status_flag,'N') = 'Y' THEN
        update_batch_id(
                        x_errbuf   => x_errbuf
                        ,x_retcode => x_retcode
                       );

     END IF;

     ld_check_time := sysdate;

     ln_current_count := 0;

     LOOP

         ln_last_count := ln_current_count;
         
         -------------------------------------------------------------------------------------
         -- Getting the Count of Eligible records and call batch child if count >= batch size, 
         -- else wait for the wait time specified and recheck for eligible records
         -------------------------------------------------------------------------------------

         SELECT COUNT(1)
         INTO   ln_current_count
         FROM   xx_inv_itemxref_stg XIIS
         WHERE  XIIS.load_batch_id IS NULL
         AND    XIIS.process_flag = 1;

         IF (ln_current_count >= gn_batch_size) THEN

            bat_child(
                      p_request_id          => gn_master_request_id
                      ,p_validate_only_flag => p_validate_only_flag
                      ,p_reset_status_flag  => p_reset_status_flag
                      ,x_time               => ld_check_time
                      ,x_errbuf             => x_errbuf
                      ,x_retcode            => x_retcode
                      );
            lc_launch := 'Y';

         ELSE

             IF ln_last_count = ln_current_count THEN

                ld_current_time := sysdate;

                ln_rem_time := (ld_current_time - ld_check_time)*86400;

                IF  ln_rem_time > G_MAX_WAIT_TIME THEN
                    EXIT;
                ELSE
                    DBMS_LOCK.sleep(G_SLEEP);
                END IF; -- ln_rem_time > G_MAX_WAIT_TIME

             ELSE

                 DBMS_LOCK.sleep(G_SLEEP);

             END IF; -- ln_last_count = ln_current_count

         END IF; --  ln_current_count >= gn_batch_size

      END LOOP;

     IF ln_current_count <> 0 THEN

        bat_child(
                  p_request_id          => gn_master_request_id
                  ,p_validate_only_flag => p_validate_only_flag
                  ,p_reset_status_flag  => p_reset_status_flag
                  ,x_time               => ld_check_time
                  ,x_errbuf             => x_errbuf
                  ,x_retcode            => x_retcode
                 );
        lc_launch := 'Y';

     END IF;

     IF  lc_launch = 'N' THEN
         
         RAISE EX_NO_DATA;
     
     ELSE
     
          -- --------------------------
          -- Lauunch the summary report
          -- --------------------------
          launch_summary_report(
                                x_errbuf  => x_errbuf
                                ,x_retcode => x_retcode
                               );
     
     END IF;
     
     
     ----------------------------------------------------------------------------------
     -- Displaying the Batch and Item Information in the output file of Master Program
     ----------------------------------------------------------------------------------

     display_out(RPAD('=',38,'='));
     display_out(RPAD('Batch Size                 : ',29,' ')||RPAD(gn_batch_size,9,' '));
     display_out(RPAD('Number of Batches Launched : ',29,' ')||RPAD(gn_batch_count,9,' '));
     display_out(RPAD('Number of Records          : ',29,' ')||RPAD(gn_record_count,9,' '));
     display_out(RPAD('=',38,'='));
     
   
   ELSE

      RAISE EX_NO_ENTRY;

   END IF; -- lc_return_status

EXCEPTION
   WHEN EX_NO_DATA THEN
       x_errbuf := 'No Data Found in the Table '||G_STAGING_TABLE_NAME;
       display_log(x_errbuf);
       x_retcode := 1;
   WHEN EX_NO_ENTRY THEN
       x_retcode := 2;
       display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE);
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected error in submit_sub_requests '||SQLERRM;
       display_log(x_errbuf);
END submit_sub_requests;


-- +====================================================================+
-- | Name        :  launch_exception_report                             |
-- | Description :  This procedure is invoked to Launch Exception       |
-- |                Report for that batch                               |
-- |                                                                    |
-- | Parameters  :                                                      |
-- +====================================================================+

PROCEDURE launch_exception_report(
                                  p_batch_id  IN  NUMBER
                                  ,x_errbuf   OUT NOCOPY VARCHAR2
                                  ,x_retcode  OUT NOCOPY VARCHAR2
                                 )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_REP_EXC           EXCEPTION;
ln_excep_request_id  PLS_INTEGER;
ln_child_request_id  PLS_INTEGER := FND_GLOBAL.CONC_REQUEST_ID;

BEGIN
   -------------------------------------------------
   -- Submitting the Exception Report for each batch
   -------------------------------------------------

   ln_excep_request_id := FND_REQUEST.submit_request(
                                                     application  => G_COMN_APPLICATION
                                                     ,program     => G_EXCEP_REPORT_PRGM
                                                     ,sub_request => FALSE                -- TRUE means is a sub request
                                                     ,argument1   => G_CONVERSION_CODE    -- conversion_code
                                                     ,argument2   => NULL                 -- MASTER REQUEST ID
                                                     ,argument3   => ln_child_request_id  -- REQUEST ID
                                                     ,argument4   => p_batch_id           -- BATCH ID
                                                    );

   IF ln_excep_request_id = 0 THEN
      x_errbuf  := FND_MESSAGE.get;
      RAISE EX_REP_EXC;
   ELSE
      COMMIT;
   END IF;

EXCEPTION
   WHEN EX_REP_EXC THEN
       x_retcode := 2;
       x_errbuf  := 'Exception Summary Report for the batch '||p_batch_id||' could not be submitted: ' || x_errbuf;
       display_log(x_errbuf);
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected Error in launch_exception_report : '||SQLERRM;
       display_log(x_errbuf);
END launch_exception_report;

-- +====================================================================+
-- | Name        :  get_master_request_id                               |
-- | Description :  This procedure is invoked to get the                |
-- |                master_request_Id                                   |
-- |                                                                    |
-- | Parameters  :  p_conversion_id                                     |
-- |                p_batch_id                                          |
-- |                                                                    |
-- | Returns     :  Master_Request_Id                                   |
-- |                                                                    |
-- +====================================================================+

PROCEDURE get_master_request_id(
                                p_conversion_id      IN  NUMBER
                                ,p_batch_id          IN  NUMBER
                                ,x_master_request_id OUT NOCOPY NUMBER
                               )
IS

BEGIN
   ---------------------------------
   -- Getting the master Request Id
   ---------------------------------
   SELECT XCCIC.master_request_id
   INTO   x_master_request_id
   FROM   xx_com_control_info_conv XCCIC
   WHERE  XCCIC.conversion_id = p_conversion_id
   AND    XCCIC.batch_id      = p_batch_id;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_master_request_id := NULL;
   WHEN OTHERS THEN
       display_log('Error while deriving master_request_id - '||SQLERRM);
END get_master_request_id;

-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: INV ItemXref |
-- |                Conversion Master Concurrent Request.This would     |
-- |                submit child programs based on batch_size           |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_validate_only_flag                                |
-- |                p_reset_status_flag                                 |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag IN  VARCHAR2
                      ,p_reset_status_flag  IN  VARCHAR2
                     )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_SUB_REQ       EXCEPTION;
lc_request_data  VARCHAR2(1000);
lc_error_message VARCHAR2(4000);
ln_return_status NUMBER;

BEGIN

   gn_master_request_id := FND_GLOBAL.CONC_REQUEST_ID;

   submit_sub_requests(
                       p_validate_only_flag  => p_validate_only_flag
                       ,p_reset_status_flag  => p_reset_status_flag
                       ,x_errbuf             => lc_error_message
                       ,x_retcode            => ln_return_status
                      );
   
   CASE ln_return_status 
      WHEN 2 THEN
          x_errbuf := lc_error_message;
          RAISE EX_SUB_REQ;
      WHEN 1 THEN
          x_errbuf  := lc_error_message;
          x_retcode := 1;
      ELSE
          NULL;
   END CASE;

EXCEPTION
   WHEN EX_SUB_REQ THEN
       x_retcode := 2;
   WHEN NO_DATA_FOUND THEN
       x_retcode := 2;
       display_log('No Data Found');
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected error in main procedure - '||SQLERRM;
END master_main;

-- +====================================================================+
-- | Name        :  log_procedure                                       |
-- |                                                                    |
-- | Description :  This procedure is invoked to log the exceptions in  |
-- |                the common exception log table                      |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_control_id                                        |
-- |                p_source_system_code                                |
-- |                p_staging_column_name                               |
-- |                p_staging_column_value                              |
-- |                p_source_system_ref                                 |
-- |                p_batch_id                                          |
-- |                p_oracle_error_msg                                  |
-- +====================================================================+

PROCEDURE log_procedure(
                        p_control_id            IN NUMBER
                        ,p_source_system_code   IN VARCHAR2
                        ,p_procedure_name       IN VARCHAR2
                        ,p_staging_table_name   IN VARCHAR2
                        ,p_staging_column_name  IN VARCHAR2
                        ,p_staging_column_value IN VARCHAR2
                        ,p_source_system_ref    IN VARCHAR2
                        ,p_batch_id             IN NUMBER
                        ,p_exception_log        IN VARCHAR2
                        ,p_oracle_error_code    IN VARCHAR2
                        ,p_oracle_error_msg     IN VARCHAR2
                       )

IS

BEGIN
     -- -----------------------------------------------------------------
     -- Call the common package to log exceptions
     -- -----------------------------------------------------------------
     XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc(
                                                  p_conversion_id         => gn_conversion_id
                                                  ,p_record_control_id     => p_control_id
                                                  ,p_source_system_code    => p_source_system_code
                                                  ,p_package_name          => G_PACKAGE_NAME
                                                  ,p_procedure_name        => p_procedure_name
                                                  ,p_staging_table_name    => p_staging_table_name
                                                  ,p_staging_column_name   => p_staging_column_name
                                                  ,p_staging_column_value  => p_staging_column_value
                                                  ,p_source_system_ref     => p_source_system_ref
                                                  ,p_batch_id              => p_batch_id
                                                  ,p_exception_log         => p_exception_log
                                                  ,p_oracle_error_code     => p_oracle_error_code
                                                  ,p_oracle_error_msg      => p_oracle_error_msg
                                                 );
EXCEPTION

  WHEN OTHERS THEN
      display_log('Error in logging exception messages in log_procedure of child_main procedure');
      display_log(SQLERRM);
END log_procedure;

-- +====================================================================+
-- | Name        :  process_item_xref                                   |
-- |                                                                    |
-- | Description :  This procedure is invoked to validate the records   |
-- |                and process them into the EBS table.                |
-- |                This procedure will always be invoked with the      |
-- |                parameter p_action = 'C'.                           |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_xref_object                                       |
-- |                p_item                                              |
-- |                p_action                                            |
-- |                p_xref_item                                         |
-- |                p_xref_type                                         | 
-- |                p_prodmultiplier                                    |
-- |                p_prodmultdivcd                                     |
-- |                p_prdxrefdesc                                       |
-- |                p_whslrsupplier                                     |
-- |                p_whslrmultiplier                                   |
-- |                p_whslrmultdivcd                                    |
-- |                p_whslrretailprice                                  |
-- |                p_whslruomcd                                        |
-- |                p_whslrprodcategory                                 |
-- |                p_whslrgencatpgnbr                                  |
-- |                p_whslrfurcatpgnbr                                  |
-- |                p_whslrnnpgnbr                                      |
-- |                p_whslrprgeligflg                                   |
-- |                p_whslrbranchflg                                    | 
-- |                                                                    |
-- | Returns     :  Message Code                                        |
-- |                Message Data                                        |
-- +====================================================================+


PROCEDURE process_item_xref(
                            p_xref_object        IN  VARCHAR2
                            ,p_item              IN  VARCHAR2
                            ,p_action            IN  VARCHAR2
                            ,p_xref_item         IN  VARCHAR2
                            ,p_xref_type         IN  VARCHAR2
                            ,p_prodmultiplier    IN  NUMBER
                            ,p_prodmultdivcd     IN  VARCHAR2
                            ,p_prdxrefdesc       IN  VARCHAR2
                            ,p_whslrsupplier     IN  NUMBER
                            ,p_whslrmultiplier   IN  NUMBER
                            ,p_whslrmultdivcd    IN  VARCHAR2
                            ,p_whslrretailprice  IN  NUMBER
                            ,p_whslruomcd        IN  VARCHAR2
                            ,p_whslrprodcategory IN  VARCHAR2
                            ,p_whslrgencatpgnbr  IN  NUMBER
                            ,p_whslrfurcatpgnbr  IN  NUMBER
                            ,p_whslrnnpgnbr      IN  NUMBER
                            ,p_whslrprgeligflg   IN  VARCHAR2
                            ,p_whslrbranchflg    IN  VARCHAR2
                            ,x_message_code      OUT NOCOPY NUMBER
                            ,x_message_data      OUT NOCOPY VARCHAR2
                           )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
ln_exists_item            NUMBER := 0;
ln_vendor_exists          NUMBER := 0;
ln_xrefobj_exists         NUMBER := 0;
ln_xref_type_exists       NUMBER := 0;
ln_inventory_item_id      NUMBER := NULL;
ln_inventory_item_mcr     NUMBER := NULL;
lc_rowid                  ROWID;
lc_lookup_code            fnd_lookup_values.lookup_code%TYPE            := NULL;
lc_description            mtl_system_items_b.description%TYPE           := NULL;
lc_attribute_category     mtl_cross_references.attribute_category%TYPE  := NULL;
lc_attribute1             mtl_cross_references.attribute1%TYPE          := NULL;
lc_attribute2             mtl_cross_references.attribute2%TYPE          := NULL;
lc_attribute3             mtl_cross_references.attribute3%TYPE          := NULL;
lc_attribute4             mtl_cross_references.attribute4%TYPE          := NULL;
lc_attribute5             mtl_cross_references.attribute5%TYPE          := NULL;
lc_attribute6             mtl_cross_references.attribute6%TYPE          := NULL;
lc_attribute7             mtl_cross_references.attribute7%TYPE          := NULL;
lc_attribute8             mtl_cross_references.attribute8%TYPE          := NULL;
lc_attribute9             mtl_cross_references.attribute9%TYPE          := NULL;
lc_attribute10            mtl_cross_references.attribute10%TYPE         := NULL;
lc_attribute11            mtl_cross_references.attribute11%TYPE         := NULL;
lc_attribute12            mtl_cross_references.attribute12%TYPE         := NULL;
lc_attribute13            mtl_cross_references.attribute13%TYPE         := NULL;
   
BEGIN
   
   -----------------------
   -- Action Add or Update
   -----------------------
   IF p_xref_object IS NULL OR
      p_item        IS NULL OR
      p_xref_item   IS NULL OR
      p_xref_type   IS NULL OR
      p_action      IS NULL    THEN
      
      x_message_code  := -1;
      fnd_message.set_name('XXPTP','XX_INV_MANDATORY_PARAMETERS');
      x_message_data := fnd_message.get;
      RETURN;
      
   END IF;
   
   IF p_action = 'C' OR p_action = 'D' THEN
   
      ---------------------------------------------------------------------------------------
      -- Validate XREF_OBJECT, XREF_TYPE for existence and get respective lookup_code value
      ---------------------------------------------------------------------------------------
      BEGIN
         
         SELECT lookup_code
         INTO   lc_lookup_code
         FROM   fnd_lookup_values
         WHERE  lookup_type = 'RMS_EBS_CROSS_REFERENCE_TYPES'
         AND    tag           = p_xref_object
         AND    meaning       = p_xref_type
         AND    enabled_flag  = 'Y';
      
      EXCEPTION
         
         WHEN NO_DATA_FOUND THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_CROSS_REFERENCE_CODE');
            x_message_data := fnd_message.get;
            RETURN;
         
         WHEN OTHERS THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
            fnd_message.set_token('SQLERR',SQLERRM); 
            x_message_data := fnd_message.get;
            RETURN;
      END;         
   
      ----------------------------------------------------------------
      -- Check cross_reference_type in mtl_cross_reference_types table
      ----------------------------------------------------------------
      BEGIN
         
         SELECT count(1)
         INTO   ln_xref_type_exists
         FROM   mtl_cross_reference_types
         WHERE  cross_reference_type = lc_lookup_code;
           
         IF ln_xref_type_exists = 0 THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_CROSS_REFERENCE_TYPE');
            x_message_data := fnd_message.get;
            RETURN;
         END IF;
      
      EXCEPTION
      
         WHEN OTHERS THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
            fnd_message.set_token('SQLERR',SQLERRM); 
            x_message_data := fnd_message.get;
            RETURN;
      END;         
      
      --------------------------------------------
      -- validate item in mtl_system_items_b table
      --------------------------------------------
      BEGIN
         
         SELECT inventory_item_id
         INTO   ln_inventory_item_id
         FROM   mtl_system_items_b
         WHERE  organization_id=(SELECT master_organization_id
				   FROM mtl_parameters
				  WHERE ROWNUM<2)
         AND  segment1 = p_item;
           
      EXCEPTION
         
         WHEN NO_DATA_FOUND THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_INVALID_ITEM');
            x_message_data := fnd_message.get;
            RETURN;
   
         WHEN OTHERS THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
            fnd_message.set_token('SQLERR',SQLERRM); 
            x_message_data := fnd_message.get;
            RETURN;
      END;
   
      ---------------------------------------------------------
      -- Action 'C' - Create or update Cross references record
      ---------------------------------------------------------
      IF p_action = 'C' THEN
       
         -------------------------------------------------------------------------------------------
         -- Validate xref_item and select description from mtl_system_items_b table in case of 'XREF'
         -------------------------------------------------------------------------------------------
         IF p_xref_object = 'XREF' THEN
         
            BEGIN
            
               SELECT description
               INTO   lc_description
               FROM   mtl_system_items_b
	         WHERE  organization_id=(SELECT master_organization_id	
				   FROM mtl_parameters
				  WHERE ROWNUM<2)
               AND  segment1 = p_xref_item;
           
            EXCEPTION
            
               WHEN NO_DATA_FOUND THEN
         
                     x_message_code  := -1;
                     fnd_message.set_name('XXPTP','XX_INV_CROSS_REFERENCE_ITEM');
                     x_message_data := fnd_message.get;
                     RETURN;
            
            WHEN OTHERS THEN
               
               x_message_code  := -1;
               fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
               fnd_message.set_token('SQLERR',SQLERRM); 
               x_message_data := fnd_message.get;
               RETURN;
            END;      
         
         --------------------------------------------------------------------------------
         -- Populate Product Cross References for Office Depot to Non Office Depot Items.
         --------------------------------------------------------------------------------
         ELSIF p_xref_object = 'PRDS' THEN
            
            lc_description          := p_prdxrefdesc;
            lc_attribute_category   := 'PRDS';
            lc_attribute1           := p_xref_type;
            lc_attribute2           := p_prodmultiplier;
            lc_attribute3           := p_prodmultdivcd;
            
         --------------------------------------------------------------------------------
         -- Populate Wholesaler  Cross References for Office Depot to Wholesaler's Items.
         --------------------------------------------------------------------------------
         ELSIF p_xref_Object = 'WHLS' THEN
         
              lc_attribute_category   := 'WHLS';
              lc_description          := p_prdxrefdesc;         
              lc_attribute1           := p_xref_type;
              lc_attribute2           := Null;
              lc_attribute3           := p_whslrsupplier;
              lc_attribute4           := p_whslrmultiplier;
              lc_attribute5           := p_whslrmultdivcd;
              lc_attribute6           := p_whslrprodcategory;
              lc_attribute7           := p_whslrretailprice;
              lc_attribute8           := p_whslruomcd;
              lc_attribute9           := p_whslrgencatpgnbr;
              lc_attribute10          := p_whslrfurcatpgnbr;
              lc_attribute11          := p_whslrnnpgnbr;
              lc_attribute12          := p_whslrprgeligflg;
              lc_attribute13          := p_whslrbranchflg;
            
         END IF;
          
         ------------------------------------------------------------------------------------------------------
         -- Cross check data in MTL_CROSS_REFERENCES table if exists update it else populate data in base table
         ------------------------------------------------------------------------------------------------------
         BEGIN
            
            SELECT rowid,inventory_item_id
            INTO   lc_rowid,
                   ln_inventory_item_mcr
            FROM   mtl_cross_references
            WHERE  inventory_item_id = ln_inventory_item_id
            AND    cross_reference = p_xref_item
            AND    cross_reference_type = lc_lookup_code;
         
         EXCEPTION
            
            WHEN NO_DATA_FOUND THEN
                ln_inventory_item_mcr:= NULL;
            
            WHEN OTHERS THEN
               x_message_code  := -1;
               fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
               fnd_message.set_token('SQLERR',SQLERRM); 
               x_message_data := fnd_message.get;
               RETURN;
         END;
   
         -------------------------------------------------
         -- populating data in mtl_cross_references table
         -------------------------------------------------
         IF ln_inventory_item_mcr IS NULL THEN
            BEGIN
               
               INSERT INTO mtl_cross_references mcr(
                                                    mcr.inventory_item_id
                                                    ,mcr.organization_id
                                                    ,mcr.cross_reference_type
                                                    ,mcr.cross_reference
                                                    ,mcr.last_update_date
                                                    ,mcr.last_updated_by
                                                    ,mcr.creation_date
                                                    ,mcr.created_by
                                                    ,mcr.description
                                                    ,mcr.org_independent_flag
                                                    ,mcr.attribute1
                                                    ,mcr.attribute2
                                                    ,mcr.attribute3
                                                    ,mcr.attribute4
                                                    ,mcr.attribute5
                                                    ,mcr.attribute6
                                                    ,mcr.attribute7
                                                    ,mcr.attribute8
                                                    ,mcr.attribute9
                                                    ,mcr.attribute10
                                                    ,mcr.attribute11
                                                    ,mcr.attribute12
                                                    ,mcr.attribute13
                                                    ,mcr.attribute_category
                                                  )
                                            VALUES( 
                                                   ln_inventory_item_id
                                                   ,NULL
                                                   ,lc_lookup_code
                                                   ,p_xref_item
                                                   ,SYSDATE
                                                   ,fnd_global.user_id
                                                   ,SYSDATE
                                                   ,fnd_global.user_id
                                                   ,lc_description
                                                   ,'Y'
                                                   ,lc_attribute1
                                                   ,lc_attribute2
                                                   ,lc_attribute3
                                                   ,lc_attribute4
                                                   ,lc_attribute5
                                                   ,lc_attribute6
                                                   ,lc_attribute7
                                                   ,lc_attribute8
                                                   ,lc_attribute9
                                                   ,lc_attribute10
                                                   ,lc_attribute11
                                                   ,lc_attribute12
                                                   ,lc_attribute13
                                                   ,lc_attribute_category
                                                  );                
                  
            EXCEPTION
               
               WHEN OTHERS THEN
                  x_message_code  := -1;
                  fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
                  fnd_message.set_token('SQLERR',SQLERRM); 
                  x_message_data := fnd_message.get;
                  RETURN;
            END;
            
            COMMIT;
            x_message_code := 0;
            fnd_message.set_name('XXPTP','XX_INV_SUCCESSFUL_INSERTION');
            x_message_data := fnd_message.get;
         
         ELSE
         
            BEGIN
               ------------------------------
               -- Updating data in base table
               ------------------------------
               UPDATE mtl_cross_references mcr
               SET    mcr.cross_reference_type = lc_lookup_code,
                      mcr.cross_reference      = p_xref_item,
                      mcr.last_update_date     = SYSDATE,
                      mcr.last_updated_by      = fnd_global.user_id,
                      mcr.org_independent_flag = 'Y',
                      mcr.description          = lc_description,
                      mcr.attribute_category   = lc_attribute_category,
                      mcr.attribute1           = lc_attribute1,
                      mcr.attribute2           = lc_attribute2,
                      mcr.attribute3           = lc_attribute3,
                      mcr.attribute4           = lc_attribute4,
                      mcr.attribute5           = lc_attribute5,
                      mcr.attribute6           = lc_attribute6,
                      mcr.attribute7           = lc_attribute7,
                      mcr.attribute8           = lc_attribute8,
                      mcr.attribute9           = lc_attribute9,
                      mcr.attribute10          = lc_attribute10,
                      mcr.attribute11          = lc_attribute11,
                      mcr.attribute12          = lc_attribute12,
                      mcr.attribute13          = lc_attribute13
               WHERE  mcr.rowid                = lc_rowid;
               
            EXCEPTION
               WHEN OTHERS THEN
                  x_message_code  := -1;
                  fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
                  fnd_message.set_token('SQLERR',SQLERRM); 
                  x_message_data := fnd_message.get;
                  RETURN;
   
            END;
            
            COMMIT;
            x_message_code := 0;
            fnd_message.set_name('XXPTP','XX_INV_SUCCESSFUL_UPDATION');
            x_message_data := fnd_message.get;
            
         END IF;
      END IF;-- Action 'C'
      
      ----------------------------------------------
      -- Action 'D' - Delete Cross references record
      ----------------------------------------------
      IF p_action = 'D' THEN
      
         BEGIN
         
            ---------------------------------------------------
            -- Delete cross reference value from the base table
            ---------------------------------------------------
         
            DELETE
            FROM  mtl_cross_references
            WHERE cross_reference_type = lc_lookup_code
            AND   inventory_item_id    = ln_inventory_item_id
            AND   cross_reference      = p_xref_item;
               
         
            IF SQL%ROWCOUNT > 0 THEN
            
               COMMIT;
               x_message_code := 0;
               fnd_message.set_name('XXPTP','XX_INV_SUCCESSFUL_DELETION');
               x_message_data := fnd_message.get;
            
            ELSE
   
              x_message_code := -1;
              fnd_message.set_name('XXPTP','XX_INV_UNSUCCESSFUL_DELETION');
              x_message_data := fnd_message.get;
   
            END IF;
   
         EXCEPTION
   
            WHEN OTHERS THEN
               x_message_code  := -1;
               fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
               fnd_message.set_token('SQLERR',SQLERRM); 
               x_message_data := fnd_message.get;
               RETURN;
               
         END;
      END IF;-- Action 'D' 
   
   ELSE
      
      x_message_code  := -1;
      fnd_message.set_name('XXPTP','XX_INV_INVALID_ACTION');
      fnd_message.set_token('ACTION',p_action); 
      x_message_data := fnd_message.get;
      RETURN;
 
   END IF;
EXCEPTION

   WHEN OTHERS THEN
      x_message_code  := -1;
      fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
      fnd_message.set_token('SQLERR',SQLERRM); 
      x_message_data := fnd_message.get;
      RETURN;

END process_item_xref;

-- +===================================================================+
-- | Name        :  child_main                                         |
-- | Description :  This procedure is invoked from the OD: INV ItemXref|
-- |                Conversion Child  Concurrent Request.This would    |
-- |                submit conversion programs based on input    .     |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                p_batch_id                                         |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE child_main(
                     x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag IN  VARCHAR2
                     ,p_reset_status_flag  IN  VARCHAR2
                     ,p_batch_id           IN  NUMBER
                    )
IS
---------------------------
--Declaring local variables
---------------------------
EX_NO_DATA               EXCEPTION;
EX_ENTRY_EXCEP           EXCEPTION;
lc_return_status         VARCHAR2(03);
lc_return_status_call    PLS_INTEGER;
ln_succ_count            PLS_INTEGER := 0;
ln_err_count             PLS_INTEGER := 0;
ln_master_request_id     PLS_INTEGER;
ln_total                 PLS_INTEGER := 0;
lx_retcode               VARCHAR2(10);

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE row_id_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_row_id row_id_tbl_type;

TYPE process_flag_tbl_type IS TABLE OF xx_inv_itemxref_stg.process_flag%type
INDEX BY BINARY_INTEGER;
lt_process_flag process_flag_tbl_type;

TYPE error_msg_tbl_type IS TABLE OF xx_inv_itemxref_stg.error_message%type
INDEX BY BINARY_INTEGER;
lt_error_msg error_msg_tbl_type ;

-- ------------------------------------------------------------------
-- Declare cursor to fetch the records in vaidation in progress state
-- ------------------------------------------------------------------
CURSOR lcu_item_details
IS
SELECT XIIS.rowid,XIIS.*
FROM   xx_inv_itemxref_stg XIIS
WHERE  XIIS.load_batch_id = p_batch_id
AND    XIIS.process_flag NOT IN (0,7);

----------------------------------
--Declaring Cursor Type Variables
----------------------------------
TYPE itemxref_tbl_type IS TABLE OF lcu_item_details%rowtype
INDEX BY BINARY_INTEGER;
lt_itemxref itemxref_tbl_type;

BEGIN
  
   -- ----------------------------------------------
   -- Procedure to get the conversion_id
   -- ----------------------------------------------
   get_conversion_id(
                     x_conversion_id  => gn_conversion_id
                     ,x_batch_size    => gn_batch_size
                     ,x_max_threads   => gn_max_child_req
                     ,x_return_status => lc_return_status
                    );

   IF lc_return_status = 'S' THEN

      BEGIN
          -- -------------------------------------------------------
          -- Collect the data into the table type
          -- Limit is not used because we are batching at the Master
          -- -------------------------------------------------------
          
          OPEN  lcu_item_details;
          FETCH lcu_item_details BULK COLLECT INTO lt_itemxref;
          CLOSE lcu_item_details;

          IF lt_itemxref.count = 0 THEN

             RAISE EX_NO_DATA;

          ELSE

               FOR i in 1 .. lt_itemxref.LAST
               LOOP

                   lt_row_id(i)   := lt_itemxref(i).rowid;
                   -----------------------------------------------------------------
                   -- XX_INV_ITEM_XREF_PKG.Process_Item_Xref will get called over
                   -- here to process the records to MTL_CROSS_REFERENCES
                   -----------------------------------------------------------------

                   process_item_xref(
                                     p_xref_object        => lt_itemxref(i).xref_object
                                     ,p_item              => lt_itemxref(i).item
                                     ,p_action            => G_ACTION
                                     ,p_xref_item         => lt_itemxref(i).xref_item
                                     ,p_xref_type         => lt_itemxref(i).xref_type
                                     ,p_prodmultiplier    => lt_itemxref(i).prod_multiplier
                                     ,p_prodmultdivcd     => lt_itemxref(i).prod_mult_div_cd
                                     ,p_prdxrefdesc       => lt_itemxref(i).prd_xref_desc
                                     ,p_whslrsupplier     => lt_itemxref(i).whslr_supplier
                                     ,p_whslrmultiplier   => lt_itemxref(i).whslr_multiplier
                                     ,p_whslrmultdivcd    => lt_itemxref(i).whslr_mult_div_cd
                                     ,p_whslrretailprice  => lt_itemxref(i).whslr_retail_price
                                     ,p_whslruomcd        => lt_itemxref(i).whslr_uom_cd
                                     ,p_whslrprodcategory => lt_itemxref(i).whslr_prod_category
                                     ,p_whslrgencatpgnbr  => lt_itemxref(i).whslr_gen_cat_pgnbr
                                     ,p_whslrfurcatpgnbr  => lt_itemxref(i).whslr_fur_cat_pgnbr
                                     ,p_whslrnnpgnbr      => lt_itemxref(i).whslr_nn_pgnbr
                                     ,p_whslrprgeligflg   => lt_itemxref(i).whslr_prg_elig_flg
                                     ,p_whslrbranchflg    => lt_itemxref(i).whslr_branch_flg
                                     ,x_message_data      => lt_itemxref(i).error_message
                                     ,x_message_code      => lc_return_status_call
                                    );

                   -----------------------------------------------------------------------------
                   -- Check for the status returned by the API.
                   -- IF the above call is successful THEN
                   --    Update the process_flag to 7
                   -- ELSE
                   --     Update the process_flag to 6 and also update the appropriate error
                   --     Message.
                   -------------------------------------------------------------------------------

                   IF lc_return_status_call = 0 THEN

                      lt_process_flag(i) := 7;

                      ln_succ_count := ln_succ_count + 1; -- to count the number of successfully processed records

                   ELSE

                       ln_err_count   := ln_err_count + 1; -- to count the number of errored records

                       lt_process_flag(i) := 6;

                       -------------------------------------------------------
                       -- to log the exception of the record while processing
                       -------------------------------------------------------

                       log_procedure(
                                     p_control_id            => lt_itemxref(i).control_id
                                     ,p_source_system_code   => lt_itemxref(i).source_system_code
                                     ,p_procedure_name       => G_PACKAGE_NAME
                                     ,p_staging_table_name   => G_STAGING_TABLE_NAME
                                     ,p_staging_column_name  => NULL
                                     ,p_staging_column_value => NULL
                                     ,p_source_system_ref    => NULL
                                     ,p_batch_id             => p_batch_id
                                     ,p_exception_log        => lt_itemxref(i).error_message
                                     ,p_oracle_error_code    => NULL
                                     ,p_oracle_error_msg     => NULL
                                    );

                       

                   END IF; -- lc_return_status_call

                   lt_error_msg(i)    := lt_itemxref(i).error_message;

               END LOOP;

               FORALL i in 1 .. lt_row_id.LAST
               UPDATE xx_inv_itemxref_stg XIIS
               SET    XIIS.process_flag = lt_process_flag(i)
                      ,XIIS.error_message = lt_error_msg(i)
               WHERE  XIIS.rowid = lt_row_id(i);

               ---------------------------------------------------------------------------------------------
               -- XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc is called over
               -- to log the number of records that were processed and errored
               ---------------------------------------------------------------------------------------------

               get_master_request_id(
                                     p_conversion_id      => gn_conversion_id
                                     ,p_batch_id          => p_batch_id
                                     ,x_master_request_id => ln_master_request_id
                                    );

               IF ln_master_request_id IS NOT NULL THEN

                  XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                                                                 p_conc_mst_req_id              => ln_master_request_id --APPS.FND_GLOBAL.CONC_REQUEST_ID
                                                                 ,p_batch_id                    => p_batch_id
                                                                 ,p_conversion_id               => gn_conversion_id
                                                                 ,p_num_bus_objs_failed_valid   => 0
                                                                 ,p_num_bus_objs_failed_process => ln_err_count
                                                                 ,p_num_bus_objs_succ_process   => ln_succ_count
                                                                 );
               END IF;
               
               -- ------------------------------------------------------
               -- to display the result in the output file
               -- -----------------------------------------------
               
               ln_total := ln_err_count + ln_succ_count;
               
               display_out(RPAD('=',58,'='));
               display_out(RPAD('Total No. Of Item Cross Reference Records      : ',49,' ')||RPAD(ln_total,9,' '));
               display_out(RPAD('No. Of Item Cross Reference Records Processed  : ',49,' ')||RPAD(ln_succ_count,9,' '));
               display_out(RPAD('No. Of Item Cross Reference Records Errored    : ',49,' ')||RPAD(ln_err_count,9,' '));
               display_out(RPAD('=',58,'='));

          END IF;

      EXCEPTION
         WHEN EX_NO_DATA THEN
             x_retcode := 1;
             x_errbuf  := 'No data found in the staging table with batch_id : '||p_batch_id;
             display_log(x_errbuf);
             log_procedure(
                           p_control_id            => NULL
                           ,p_source_system_code   => NULL
                           ,p_procedure_name       => NULL
                           ,p_staging_table_name   => G_STAGING_TABLE_NAME
                           ,p_staging_column_name  => NULL
                           ,p_staging_column_value => NULL
                           ,p_source_system_ref    => NULL
                           ,p_batch_id             => p_batch_id
                           ,p_exception_log        => x_errbuf
                           ,p_oracle_error_code    => NULL
                           ,p_oracle_error_msg     => NULL
                          );
         WHEN OTHERS THEN
             x_retcode := 2;
             log_procedure(
                           p_control_id            => NULL
                           ,p_source_system_code   => NULL
                           ,p_procedure_name       => 'CHILD_MAIN'
                           ,p_staging_table_name   => NULL
                           ,p_staging_column_name  => NULL
                           ,p_staging_column_value => NULL
                           ,p_source_system_ref    => NULL
                           ,p_batch_id             => p_batch_id
                           ,p_exception_log        => NULL
                           ,p_oracle_error_code    => SQLCODE
                           ,p_oracle_error_msg     => SQLERRM
                          );
      
      END;

      --------------------------------------------------------------------------------------------
      -- To launch the Exception Log Report for this batch
      --------------------------------------------------------------------------------------------
      lx_retcode := NULL;
      launch_exception_report(
                              p_batch_id => p_batch_id
                              ,x_errbuf  => x_errbuf
                              ,x_retcode => lx_retcode
                             );
      
      IF lx_retcode IS NOT NULL THEN
         x_retcode := lx_retcode;
      END IF;

      

   ELSE

      RAISE EX_ENTRY_EXCEP;

   END IF;

EXCEPTION
  WHEN EX_ENTRY_EXCEP THEN
       x_retcode := 2;
       display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE);
  WHEN NO_DATA_FOUND THEN
       x_retcode := 2;
       x_errbuf  := 'No Data Found error in main - '||SQLERRM;
  WHEN OTHERS THEN
       x_errbuf  := 'Unexpected error in main - '||SQLERRM;
       x_retcode := 2;
END child_main;

END XX_INV_ITEMXREF_CONV_PKG;
/
SHOW ERRORS
EXIT;


