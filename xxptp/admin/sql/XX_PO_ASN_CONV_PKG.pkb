 SET VERIFY OFF
 WHENEVER SQLERROR CONTINUE
 WHENEVER OSERROR EXIT FAILURE ROLLBACK

 PROMPT
 PROMPT Creating XX_PO_ASN_CONV_PKG package body
 PROMPT
 CREATE OR REPLACE PACKAGE BODY XX_PO_ASN_CONV_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_ASN_CONV_PKG                                                   |
-- | Description      : This package is used to                                              |
-- |                   1) Validate all ASNs to be interfaced from the                        |
-- |                      Staging Table.                                                     |
-- |                   2) Insert the Validated ASNs in the Oracle                            |
-- |                      Interface tables.                                                  |
-- |                   3) Run Receiving Transaction Processor to insert ASNs into Oracle     |
-- |                      base tables.                                                       |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version       Date           Author            Remarks                                   |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   25-May-2007      Gowri Nagarajan   Initial draft version                      |
-- |DRAFT 1B   15-Jun-2007      Gowri Nagarajan   Incorporated Peer Review Comments          |
-- |                                              a)Changed the procedure names              |
-- |                                              b) Added p_batch_size and p_max_threads    |
-- |                                                 in the master_main                      |
-- |DRAFT 1C   28-Jun-2007      Gowri Nagarajan   Incorporated Changes as per the conversion |
-- |                                              Strategy                                   |
-- |DRAFT 1D   09-Jul-2007      Gowri Nagarajan   Added cursor to include po_interface_errors|
-- |                                              errors                                     |
-- |DRAFT 1E   10-Jul-2007      Gowri Nagarajan   Included queries                           |
-- |DRAFT 1F   17-Jul-2007      Gowri Nagarajan   Added p_debug_flag parameter in            |
-- |                                              master_main and child_main                 |
-- |1.0        19-Jul-2007      Gowri Nagarajan   Baselined                                  |
-- |1.1        24-Sep-2007      Ritu Shukla       Initialized G_SLEEP, G_MAX_WAIT_TIME to 0  |
-- +=========================================================================================+

AS

   -- ----------------------------
   -- Global Constants Declaration
   -- ----------------------------
   G_SLEEP                         CONSTANT PLS_INTEGER  :=  0;
   G_MAX_WAIT_TIME                 CONSTANT PLS_INTEGER  :=  0;
   G_COMN_APPLICATION              CONSTANT VARCHAR2(30) := 'XXCOMN';
   G_SUMRY_REPORT_PRGM             CONSTANT VARCHAR2(30) := 'XXCOMCONVSUMMREP';
   G_EXCEP_REPORT_PRGM             CONSTANT VARCHAR2(30) := 'XXCOMCONVEXPREP';
   G_CONVERSION_CODE               CONSTANT VARCHAR2(30) := 'C0303_ASN';
   G_CHLD_PROG_APPLICATION         CONSTANT VARCHAR2(30) := 'PO';
   G_CHLD_PROG_EXECUTABLE          CONSTANT VARCHAR2(30) := 'XXPOASNCHILD';
   G_PACKAGE_NAME                  CONSTANT VARCHAR2(30) := 'XX_PO_ASN_CONV_PKG';
   G_STAGING_TABLE_NAME            CONSTANT VARCHAR2(30) := 'XX_PO_ASN_HDR_CONV_STG';
   G_LIMIT_SIZE                    CONSTANT PLS_INTEGER  :=  10000;
   G_USER_ID                       CONSTANT rcv_headers_interface.created_by%TYPE := FND_GLOBAL.user_id;
     

   -- ----------------------------
   -- Global Variables Declaration
   -- ----------------------------
   gn_receipt_source_code    rcv_headers_interface.receipt_source_code%TYPE;
   gn_master_request_id      PLS_INTEGER;
   gn_conversion_id          PLS_INTEGER;
   gn_max_child_req          PLS_INTEGER ;
   gn_batch_count            PLS_INTEGER := 0;
   gn_record_count           PLS_INTEGER := 0;
   gn_req_id                 PLS_INTEGER := 0;
   gn_child_request_id       PLS_INTEGER ;
   gc_debug_flag             VARCHAR2(1);

   -- -------------------------------
   -- Type declaration for request_id
   -- -------------------------------

   TYPE req_id_tbl_type IS TABLE OF FND_CONCURRENT_REQUESTS.request_id%TYPE
   INDEX BY BINARY_INTEGER;

   -- ----------------------------------------
   -- Variable declaration for the table types
   -- ----------------------------------------

   gt_req_id               req_id_tbl_type;
   
   ----------------------------------------------------
   --Declaring record variables for logging bulk errors
   ----------------------------------------------------
   gr_asn_err_rec         xx_com_exceptions_log_conv%ROWTYPE;
   gr_asn_err_empty_rec   xx_com_exceptions_log_conv%ROWTYPE;

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

       -- Display messages only when debug_flag is 'Y'
       
       IF nvl(gc_debug_flag,'N') ='Y' THEN

         FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
       END IF;

   END display_log;

   -- +====================================================================+
   -- | Name        :  display_out                                         |
   -- | Description :  This procedure is invoked to print in the Output    |
   -- |                file                                                |
   -- |                                                                    |
   -- | Parameters  :  Message                                             |
   -- +====================================================================+

   PROCEDURE display_out(
                         p_message IN VARCHAR2
                        )
   IS

   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

   END display_out;

   -- +====================================================================+
   -- | Name        :  get_conversion_id                                   |
   -- | Description :  This procedure is invoked to get the conversion_id  |
   -- |                                                                    |
   -- | Returns     :  Conversion_Id                                       |
   -- |                                                                    |
   -- |                                                                    |
   -- +====================================================================+

   PROCEDURE get_conversion_id(
                                x_conversion_id  OUT  NUMBER
                               ,x_return_status  OUT  VARCHAR2
                              )
   IS

   BEGIN
   display_log('Get Conversion Id');
        SELECT XCCC.conversion_id
        INTO   x_conversion_id
        FROM   xx_com_conversions_conv XCCC
        WHERE  XCCC.conversion_code = G_CONVERSION_CODE;

        x_return_status := 'S';

   EXCEPTION

     WHEN NO_DATA_FOUND THEN

        x_return_status := 'E';
        display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code C0303_ASN');

     WHEN OTHERS THEN
        x_return_status := 'N';
        display_log('Unexpected Error ocurred while deriving conversion_id.Error:'||SUBSTR(SQLERRM,1,200));

   END get_conversion_id;

   -- +====================================================================+
   -- | Name        :  log_procedure                                       |
   -- |                                                                    |
   -- | Description :  This procedure is invoked to log the exceptions in  |
   -- |                the common exception log table                      |
   -- |                                                                    |
   -- |                                                                    |
   -- | Parameters  :  p_control_id                                        |
   -- |                p_source_system_code                                |
   -- |                p_procedure_name                                    |
   -- |                p_staging_table_name                                |
   -- |                p_staging_column_name                               |
   -- |                p_staging_column_value                              |
   -- |                p_source_system_ref                                 |
   -- |                p_batch_id                                          |
   -- |                p_exception_log                                     |
   -- |                p_oracle_error_code                                 |
   -- |                p_oracle_error_msg                                  |
   -- +====================================================================+

   PROCEDURE log_procedure(
                           p_control_id           IN NUMBER,
                           p_source_system_code   IN VARCHAR2,
                           p_procedure_name       IN VARCHAR2,
                           p_staging_table_name   IN VARCHAR2,
                           p_staging_column_name  IN VARCHAR2,
                           p_staging_column_value IN VARCHAR2,
                           p_source_system_ref    IN VARCHAR2,
                           p_batch_id             IN NUMBER,
                           p_exception_log        IN VARCHAR2,
                           p_oracle_error_code    IN VARCHAR2,
                           p_oracle_error_msg     IN VARCHAR2
                          )

   IS

   BEGIN
   
       ------------------------------------
       --Initializing the error record type
       ------------------------------------
       gr_asn_err_rec                     :=  gr_asn_err_empty_rec;
    
      -- -----------------------------------------------------------------
      -- Call the common package to log exceptions
      -- -----------------------------------------------------------------

      gr_asn_err_rec.oracle_error_msg    :=  p_oracle_error_msg;
      gr_asn_err_rec.oracle_error_code   :=  p_oracle_error_code;
      gr_asn_err_rec.record_control_id   :=  p_control_id;
      gr_asn_err_rec.request_id          :=  gn_child_request_id;
      gr_asn_err_rec.converion_id        :=  gn_conversion_id;
      gr_asn_err_rec.package_name        :=  G_PACKAGE_NAME;
      gr_asn_err_rec.procedure_name      :=  p_procedure_name;
      gr_asn_err_rec.staging_table_name  :=  p_staging_table_name;
      gr_asn_err_rec.staging_column_name :=  p_staging_column_name;
      gr_asn_err_rec.staging_column_value:=  p_staging_column_value;
      gr_asn_err_rec.exception_log       :=  p_exception_log ;
      gr_asn_err_rec.source_system_ref   :=  p_source_system_ref;
      gr_asn_err_rec.batch_id            :=  p_batch_id;
  
    display_log('gr_asn_err_rec.request_id :'||gr_asn_err_rec.request_id);
  /*
  XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc(
                                                  p_conversion_id         => gn_conversion_id,
                                                  p_record_control_id     => p_control_id,
                                                  p_source_system_code    => p_source_system_code,
                                                  p_package_name          => G_PACKAGE_NAME,
                                                  p_procedure_name        => p_procedure_name,
                                                  p_staging_table_name    => p_staging_table_name,
                                                  p_staging_column_name   => p_staging_column_name,
                                                  p_staging_column_value  => p_staging_column_value,
                                                  p_source_system_ref     => p_source_system_ref,
                                                  p_batch_id              => p_batch_id,
                                                  p_exception_log         => p_exception_log,
                                                  p_oracle_error_code     => p_oracle_error_code,
                                                  p_oracle_error_msg      => p_oracle_error_msg
                                                 );
  
  */
  
  XX_COM_CONV_ELEMENTS_PKG.bulk_add_message(gr_asn_err_rec);
  
  EXCEPTION

     WHEN OTHERS THEN
         display_log('Unexpected Error ocurred in logging exception messages in log_procedure of child_main procedure.Error :'||SUBSTR(SQLERRM,1,200));
         display_log(SQLERRM);

   END log_procedure;

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
                                    p_conversion_id      IN   NUMBER
                                   ,p_batch_id           IN   NUMBER
                                   ,x_master_request_id  OUT  NUMBER
                                   ,x_return_status      OUT  VARCHAR2
                                  )
   IS

   BEGIN
   
        display_log('get_master_request_id for batch '||p_batch_id|| 'and conversion_id:'||p_conversion_id);

        SELECT XCCIC.master_request_id
        INTO   x_master_request_id
        FROM   xx_com_control_info_conv XCCIC
        WHERE  XCCIC.conversion_id = p_conversion_id
        AND    XCCIC.batch_id      = p_batch_id;

        x_return_status := 'S';

   EXCEPTION

      WHEN NO_DATA_FOUND THEN
         x_return_status := 'E';
         x_master_request_id := NULL;
         display_log('Master_request_id is null for this batch -'||SUBSTR(SQLERRM,1,200));
         log_procedure(
                       p_control_id           => NULL,
                       p_source_system_code   => NULL,
                       p_procedure_name       => 'GET_MASTER_REQUEST_ID',
                       p_staging_table_name   => NULL,
                       p_staging_column_name  => NULL,
                       p_staging_column_value => NULL,
                       p_source_system_ref    => NULL,
                       p_batch_id             => p_batch_id,
                       p_exception_log        => 'Master_request_id is null for this batch',
                       p_oracle_error_code    => NULL,
                       p_oracle_error_msg     => NULL
                      );
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

      WHEN OTHERS THEN

         x_return_status := 'N';

         display_log('Error while deriving master_request_id - '||SUBSTR(SQLERRM,1,200));

         log_procedure(
                       p_control_id           => NULL,
                       p_source_system_code   => NULL,
                       p_procedure_name       => 'GET_MASTER_REQUEST_ID',
                       p_staging_table_name   => NULL,
                       p_staging_column_name  => NULL,
                       p_staging_column_value => NULL,
                       p_source_system_ref    => NULL,
                       p_batch_id             => p_batch_id,
                       p_exception_log        => NULL,
                       p_oracle_error_code    => SQLCODE,
                       p_oracle_error_msg     => SUBSTR(SQLERRM,1,200)
                       );

       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

   END get_master_request_id;

   -- +====================================================================+
   -- | Name        :  launch_summary_report                               |
   -- | Description :  This procedure is invoked to Launch Conversion      |
   -- |                Processing Summary Report for that run              |
   -- |                                                                    |
   -- +====================================================================+

   PROCEDURE launch_summary_report(
                                   x_errbuf   OUT  VARCHAR2
                                  ,x_retcode  OUT  VARCHAR2
                                  )
   IS

   -- --------------------------
   -- Local Variable Declaration
   -- --------------------------

   EX_REP_SUMM                EXCEPTION;
   lt_conc_summ_request_id    PLS_INTEGER;
   lc_status                  VARCHAR2(03);

   BEGIN
         FOR i IN gt_req_id.FIRST .. gt_req_id.LAST
         LOOP
             LOOP
                 SELECT FCR.phase_code
                 INTO   lc_status
                 FROM   fnd_concurrent_requests FCR
                 WHERE  FCR.request_id = gt_req_id(i);

                 IF  lc_status = 'C' THEN
                     EXIT;
                 ELSE
                     DBMS_LOCK.SLEEP(G_SLEEP);
                 END IF;
             END LOOP;
         END LOOP;

         lt_conc_summ_request_id := FND_REQUEST.submit_request(
                                                                application  => G_COMN_APPLICATION
                                                              , program      => G_SUMRY_REPORT_PRGM
                                                              , sub_request  => FALSE
                                                              , argument1    => G_CONVERSION_CODE
                                                              , argument2    => gn_master_request_id
                                                              , argument3    => NULL
                                                              , argument4    => NULL
                                                              );

          COMMIT;
         
         IF  lt_conc_summ_request_id = 0 THEN

            display_log('Unable to submit the processing summary report concurrent program');
            x_errbuf  := FND_MESSAGE.GET;
            RAISE EX_REP_SUMM;

         ELSE
            display_log('Submitted the processing summary report concurrent program');
         END IF;

   EXCEPTION

      WHEN EX_REP_SUMM THEN

         x_retcode := 2;
         x_errbuf  := 'Processing Summary Report for the batch could not be submitted.Error:'|| SUBSTR(SQLERRM,1,200);

      WHEN OTHERS THEN

         x_retcode := 2;
         x_errbuf  := 'Processing Summary Report for the batch could not be submitted due to unexpected error.Error : '|| SUBSTR(SQLERRM,1,200);

   END launch_summary_report;

   -- +====================================================================+
   -- | Name        :  launch_exception_report                             |
   -- | Description :  This procedure is invoked to Launch Exception       |
   -- |                Report for that batch                               |
   -- |                                                                    |
   -- | Parameters  :  p_batch_id                                          |
   -- +====================================================================+

   PROCEDURE launch_exception_report(
                                     p_batch_id       IN   NUMBER
                                    ,p_conc_req_id    IN   NUMBER
                                    ,p_master_req_id  IN   NUMBER 
                                    ,x_errbuf         OUT  VARCHAR2
                                    ,x_retcode        OUT  NUMBER
                                    )
   IS


   EX_REP_EXC                  EXCEPTION;
   lt_conc_excep_request_id    PLS_INTEGER;

   BEGIN

      lt_conc_excep_request_id := FND_REQUEST.submit_request(
                                                               application =>  G_COMN_APPLICATION
                                                              ,program     =>  G_EXCEP_REPORT_PRGM
                                                              ,sub_request =>  FALSE             -- TRUE means is a sub request
                                                              ,argument1   =>  G_CONVERSION_CODE -- conversion_code
                                                              ,argument2   =>  p_master_req_id   -- MASTER REQUEST ID
                                                              ,argument3   =>  p_conc_req_id     -- REQUEST ID
                                                              ,argument4   =>  p_batch_id        -- BATCH ID
                                                            );

       COMMIT;
      
      IF lt_conc_excep_request_id = 0 THEN
          x_errbuf  := FND_MESSAGE.GET;
          RAISE EX_REP_EXC;
      ELSE
          display_log('Submitted the Exception Log Report concurrent program');
      END IF;

   EXCEPTION

      WHEN EX_REP_EXC THEN

        x_retcode := 2;
        x_errbuf  := 'Exception Summary Report for the batch '||p_batch_id||' could not be submitted.Error :' || SUBSTR(SQLERRM,1,200);

   END launch_exception_report;

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
   -- |                p_batch_size                                          |
   -- |                p_max_threads                                         |
   -- |                                                                      |
   -- | Returns     :  x_time                                                |
   -- |                                                                      |
   -- +======================================================================+

   PROCEDURE bat_child(
                        p_request_id          IN    NUMBER
                       ,p_validate_only_flag  IN    VARCHAR2
                       ,p_reset_status_flag   IN    VARCHAR2
                       ,p_batch_size          IN    NUMBER
                       ,p_max_threads         IN    NUMBER
                       ,x_time                OUT   DATE
                       ,x_errbuf              OUT   VARCHAR2
                       ,x_retcode             OUT   VARCHAR2
                      )
   IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      EX_SUBMIT_CHILD       EXCEPTION;
      ln_batch_size_count   PLS_INTEGER;
      ln_seq                PLS_INTEGER;
      ln_req_count          PLS_INTEGER;
      ln_conc_request_id    PLS_INTEGER;


   BEGIN

      x_retcode  := 0;
      -- ----------------------------------
      -- Get the batch_id from the sequence
      -- ----------------------------------

      SELECT XX_PO_ASN_HDR_CONV_STG_BAT_S.NEXTVAL
      INTO   ln_seq
      FROM   SYS.DUAL;

      -- -------------------------------------
      -- Assign batches to the Header records
      -- -------------------------------------

      display_log('Assign batches to the Header records with batch_id: '||ln_seq);
      UPDATE xx_po_asn_hdr_conv_stg XPAHCS
      SET    XPAHCS.batch_id     = ln_seq
            ,XPAHCS.process_flag = 2
      WHERE XPAHCS.batch_id IS NULL
      AND   XPAHCS.process_flag = 1
      AND   ROWNUM <= p_batch_size ;
      ----------------------------------------------------------
      --Fetching Count of Eligible Records in the Staging Table
      ----------------------------------------------------------
      ln_batch_size_count := SQL%ROWCOUNT;

      COMMIT;
      ------------------------------------------------------------------------------ 
      --Initializing the record count variables and taking next value of sequence
      ------------------------------------------------------------------------------

      gn_record_count     := gn_record_count + ln_batch_size_count;

      -- ------------------------------------
      -- Assign batches to the detail records
      -- ------------------------------------

      display_log('Assign batches to the detail records for batch '||ln_seq);
      UPDATE xx_po_asn_dtl_conv_stg XPADCS
      SET    XPADCS.batch_id     = ln_seq
            ,XPADCS.process_flag = 2
      WHERE  XPADCS.batch_id IS NULL
      AND    XPADCS.process_flag = 1
      AND    XPADCS.parent_record_id IN (SELECT XPAHCS.record_id
                                         FROM   xx_po_asn_hdr_conv_stg XPAHCS
                                         WHERE  XPAHCS.batch_id=ln_seq);

      COMMIT;

      -----------------------------------------
      -- Submitting Child Program for each batch
      -----------------------------------------

      LOOP
         -- --------------------------------------------
         -- Get the count of running concurrent requests
         -- --------------------------------------------

         SELECT COUNT(1)
         INTO   ln_req_count
         FROM   FND_CONCURRENT_REQUESTS FCR
         WHERE  FCR.parent_request_id  = gn_master_request_id
         AND    FCR.phase_code IN ('P','R');

         IF ln_req_count < p_max_threads THEN

            ln_conc_request_id := FND_REQUEST.submit_request(
                                                              application => G_CHLD_PROG_APPLICATION
                                                             ,program     => G_CHLD_PROG_EXECUTABLE
                                                             ,sub_request => FALSE
                                                             ,argument1   => p_validate_only_flag
                                                             ,argument2   => p_reset_status_flag
                                                             ,argument3   => ln_seq
                                                             ,argument4   => gc_debug_flag
                                                           );

             IF ln_conc_request_id = 0 THEN
                display_log('Unable to submit the chil conc program ::;ln_seq ='||ln_seq);
                x_errbuf  := FND_MESSAGE.GET;
                RAISE EX_SUBMIT_CHILD;

             ELSE

                display_log('submitted the chil conc program ::;ln_seq ='||ln_seq);
                COMMIT;
                gn_req_id := gn_req_id + 1;
                gt_req_id(gn_req_id) := ln_conc_request_id;
                gn_batch_count       := gn_batch_count + 1;
                x_time := SYSDATE;

                ---------------------------------------------------
                -- Procedure to Log Conversion Control Informations.
                ---------------------------------------------------
                XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                                                               p_conversion_id          => gn_conversion_id
                                                              ,p_batch_id               => ln_seq
                                                              ,p_num_bus_objs_processed => ln_batch_size_count
                                                               );
              EXIT;

             END IF;

         ELSE
             DBMS_LOCK.SLEEP(G_SLEEP);

         END IF;
      END LOOP;

   EXCEPTION

     WHEN EX_SUBMIT_CHILD THEN

        x_retcode := 2;
        x_errbuf  := 'Error in submitting child requests.Error :' || SUBSTR(SQLERRM,1,200);
        display_log(x_errbuf);

     WHEN OTHERS THEN

        x_retcode := 2;
        x_errbuf  := 'Unexpected error ocurred while submitting child requests.Error : ' ||SUBSTR(SQLERRM,1,200);
        display_log(x_errbuf);

   END bat_child;

   -- +====================================================================+
   -- | Name        :  update_batch_id                                     |
   -- |                                                                    |
   -- | Description :  This procedure is invoked to reset Batch Id to Null |
   -- |                for Previously Errored Out Records                  |
   -- +====================================================================+

   PROCEDURE update_batch_id(
                              x_errbuf        OUT VARCHAR2,
                              x_retcode       OUT VARCHAR2
                            )

   IS

   BEGIN

         display_log(' Inside update batch id ');
         
         UPDATE xx_po_asn_hdr_conv_stg XPAHCS
         SET    XPAHCS.batch_id     = NULL
               ,XPAHCS.process_flag = 1
         WHERE  XPAHCS.process_flag NOT IN (0,7);

         UPDATE xx_po_asn_dtl_conv_stg XPADCS
         SET    XPADCS.batch_id     = NULL
               ,XPADCS.process_flag = 1
         WHERE  XPADCS.process_flag NOT IN (0,7);

         COMMIT;

         x_retcode  := 0;

   EXCEPTION

      WHEN OTHERS THEN

           x_errbuf   := 'Unexpected error while updating the batch_id.Error :'||SUBSTR(SQLERRM,1,200);
           x_retcode  := 2;

   END update_batch_id;

   -- +=======================================================================+
   -- | Name        :  update_child_batch_id                               |
   -- | Description :  This procedure is invoked to reset Batch Id to Null |
   -- |                for Previously Errored Out Records                  |
   -- |                                                                    |
   -- | Parameters  :  p_batch_id                                          |
   -- +====================================================================+

   PROCEDURE update_child_batch_id(p_batch_id      IN  NUMBER,
                                   x_errbuf        OUT VARCHAR2,
                                   x_retcode       OUT VARCHAR2
                                  )

   IS

   BEGIN
   
         display_log('Inside update_child_batch_id '||p_batch_id);

         UPDATE xx_po_asn_hdr_conv_stg XPAHCS
         SET    XPAHCS.process_flag = 2
         WHERE  XPAHCS.batch_id     = p_batch_id
         AND    XPAHCS.process_flag NOT IN (0,7);

         UPDATE xx_po_asn_dtl_conv_stg XPADCS
         SET    XPADCS.process_flag = 2
         WHERE  XPADCS.batch_id     = p_batch_id
         AND    XPADCS.process_flag NOT IN (0,7);

         x_retcode  := 0;

   EXCEPTION

       WHEN OTHERS THEN

          x_errbuf    := 'Unexpected error while updating the batch_id.Error:'||SUBSTR(SQLERRM,1,200);
          x_retcode   := 2;

          log_procedure(
                       p_control_id           => NULL,
                       p_source_system_code   => NULL,
                       p_procedure_name       => 'UPDATE_CHILD_BATCH_ID',
                       p_staging_table_name   => NULL,
                       p_staging_column_name  => NULL,
                       p_staging_column_value => NULL,
                       p_source_system_ref    => NULL,
                       p_batch_id             => p_batch_id,
                       p_exception_log        => NULL,
                       p_oracle_error_code    => SQLCODE,
                       p_oracle_error_msg     => SUBSTR(SQLERRM,1,200)
                       );

       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

   END update_child_batch_id;

   -- +===================================================================+
   -- | Name        :  submit_sub_requests                                |
   -- | Description :  This procedure is invoked from the master_main     |
   -- |                procedure. This would submit child requests based  |
   -- |                on batch_size.                                     |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters  :  p_validate_omly_flag                               |
   -- |                p_reset_status_flag                                |
   -- |                p_batch_size                                       |
   -- |                p_max_threads                                      |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE submit_sub_requests(
                                 p_validate_only_flag  IN   VARCHAR2
                                ,p_reset_status_flag   IN   VARCHAR2
                                ,p_batch_size          IN   NUMBER
                                ,p_max_threads         IN   NUMBER
                                ,x_errbuf              OUT  VARCHAR2
                                ,x_retcode             OUT  VARCHAR2
                                )

   IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      EX_NO_DATA          EXCEPTION;
      EX_NO_ENTRY         EXCEPTION;
      ld_check_time       DATE;
      ld_current_time     DATE;
      ln_rem_time         NUMBER;
      ln_current_count    PLS_INTEGER;
      ln_last_count       PLS_INTEGER;
      lc_return_status    VARCHAR2(03);
      lc_launch           VARCHAR2(02) := 'N';

   BEGIN
   
        display_log('Inside submit_sub_requests');
        x_retcode := 0;

        get_conversion_id(
                          x_conversion_id => gn_conversion_id
                         ,x_return_status => lc_return_status
                         );

        IF lc_return_status = 'S' THEN

           IF NVL(p_reset_status_flag,'N') = 'Y' THEN

              -- --------------------------------------------------------
              -- Call update_batch_id to change status of errored records
              -- --------------------------------------------------------

              update_batch_id(x_errbuf
                             ,x_retcode
                             );

           END IF;

           ld_check_time := SYSDATE;

           ln_current_count := 0;

           LOOP

              ln_last_count := ln_current_count;

              -- -----------------------------------------
              -- Get the current count of eligible records
              -- -----------------------------------------

              SELECT COUNT(1)
              INTO   ln_current_count
              FROM   xx_po_asn_hdr_conv_stg  XPAHCS
              WHERE  XPAHCS.batch_id IS NULL
              AND    XPAHCS.process_flag = 1;

              IF (ln_current_count >= p_batch_size) THEN

                 -- -------------------------------------------
                 -- Call bat_child to launch the child requests
                 -- -------------------------------------------

                 bat_child(
                            p_request_id         => gn_master_request_id
                           ,p_validate_only_flag => p_validate_only_flag
                           ,p_reset_status_flag  => p_reset_status_flag
                           ,p_batch_size         => p_batch_size
                           ,p_max_threads        => p_max_threads
                           ,x_time               => ld_check_time
                           ,x_errbuf             => x_errbuf
                           ,x_retcode            => x_retcode
                           );

                 lc_launch := 'Y';

              ELSE

                 IF ln_last_count = ln_current_count THEN

                    ld_current_time := SYSDATE;

                    ln_rem_time := (ld_current_time - ld_check_time)*86400;

                    IF  ln_rem_time > G_MAX_WAIT_TIME THEN
                        EXIT;
                    ELSE
                        DBMS_LOCK.SLEEP(G_SLEEP);
                    END IF;

                 ELSE

                    DBMS_LOCK.SLEEP(G_SLEEP);

                 END IF;

              END IF;

           END LOOP;

           IF ln_current_count <> 0 THEN

              bat_child(
                         p_request_id         => gn_master_request_id
                        ,p_validate_only_flag => p_validate_only_flag
                        ,p_reset_status_flag  => p_reset_status_flag
                        ,p_batch_size         => p_batch_size
                        ,p_max_threads        => p_max_threads
                        ,x_time               => ld_check_time
                        ,x_errbuf             => x_errbuf
                        ,x_retcode            => x_retcode
                        );

              lc_launch := 'Y';

           END IF;

           IF  lc_launch = 'N' THEN

              RAISE EX_NO_DATA;

           ELSE

              launch_summary_report(
                                     x_errbuf
                                    ,x_retcode
                                   );

             -------------------------
             --Launch Exception Report
             -------------------------
             display_log('Submitted the launch exception report concurrent program for the parent:'||gn_master_request_id);
             launch_exception_report(
                                     NULL                       -- p_batch_id
                                    ,NULL                       -- Child request id
                                    ,gn_master_request_id       -- Master Request id
                                    ,x_errbuf
                                    ,x_retcode
                                  );                       

           END IF;

           display_out(RPAD('=',38,'='));
           display_out(RPAD('Batch Size                 : ',29,' ')||RPAD(p_batch_size,9,' '));
           display_out(RPAD('Number of Batches Launched : ',29,' ')||RPAD(gn_batch_count,9,' '));
           display_out(RPAD('Number of Records          : ',29,' ')||RPAD(gn_record_count,9,' '));
           display_out(RPAD('=',38,'='));

        ELSE

            RAISE EX_NO_ENTRY;

        END IF;

   EXCEPTION

      WHEN EX_NO_DATA THEN

         x_retcode := 1;
         x_errbuf  := 'No Data Found in the Staging Table XX_PO_ASN_HDR_CONV_STG';

      WHEN EX_NO_ENTRY THEN

         x_retcode := 2;

      WHEN OTHERS THEN

         x_retcode := 2;
         x_errbuf  := 'Unexpected Error ocurred while submitting sub requests.Error :'||SUBSTR(SQLERRM,1,200);

   END submit_sub_requests;

   -- +====================================================================+
   -- | Name        :  master_main                                         |
   -- | Description :  This procedure is invoked from the OD:PO ASN        |
   -- |                Conversion Master Concurrent Request.This would     |
   -- |                submit child programs based on batch_size           |
   -- |                                                                    |
   -- |                                                                    |
   -- | Parameters  :  p_validate_omly_flag                                |
   -- |                p_reset_status_flag                                 |
   -- |                p_batch_size                                        |
   -- |                p_max_threads                                       |
   -- | Returns     :                                                      |
   -- |                                                                    |
   -- +====================================================================+

   PROCEDURE master_main(
                         x_errbuf             OUT VARCHAR2
                        ,x_retcode            OUT VARCHAR2
                        ,p_validate_only_flag IN  VARCHAR2
                        ,p_reset_status_flag  IN  VARCHAR2
                        ,p_batch_size         IN  NUMBER
                        ,p_max_threads        IN  NUMBER
                        ,p_debug_flag         IN  VARCHAR2
                        )
   IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      EX_SUB_REQ              EXCEPTION;
      EX_SUB_REQ_NO_DATA      EXCEPTION;
      ln_retcode              NUMBER;
      lc_errbuf               VARCHAR2(4000);

   BEGIN

     display_log('Begining of the processing');
     display_log('___________________________');
     
      gc_debug_flag        := p_debug_flag;
      gn_master_request_id := FND_GLOBAL.CONC_REQUEST_ID;

      submit_sub_requests(
                           p_validate_only_flag
                          ,p_reset_status_flag
                          ,p_batch_size
                          ,p_max_threads
                          ,lc_errbuf
                          ,ln_retcode
                         );

      IF ln_retcode = 1 THEN

         x_errbuf := lc_errbuf;
         RAISE EX_SUB_REQ_NO_DATA;

      ELSIF ln_retcode = 2 THEN
         x_errbuf := lc_errbuf;
         RAISE EX_SUB_REQ;

      END IF;
   
      COMMIT;

     EXCEPTION

        WHEN EX_SUB_REQ_NO_DATA THEN

             x_retcode := 1;

        WHEN EX_SUB_REQ THEN

             x_retcode := 2;

        WHEN OTHERS THEN

             x_retcode := 2;
             x_errbuf  := 'Unexpected error occured in master_main procedure.Error :'||SUBSTR(SQLERRM,1,200);

   END master_main;

   -- +===================================================================+
   -- | Name        :  insert_into_interface                              |
   -- | Description :  This procedure is invoked from the main procedure. |
   -- |                This would insert records into interface tables    |
   -- |                                                                   |
   -- | Parameters  :  p_batch_id                                         |
   -- |                                                                   |
   -- |                                                                   |
   -- | Returns     :                                                     |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE insert_into_interface (
                                    p_batch_id       IN   NUMBER,
                                    x_errbuf         OUT  VARCHAR2,
                                    x_retcode        OUT  VARCHAR2
                                   )
   IS


   BEGIN
   display_log('Procedure insert_into_interface for batch: '||p_batch_id);

      BEGIN

         -- -----------------------------------------------------------------
         -- Insert all the validated records into RCV Headers interface table
         -- -----------------------------------------------------------------

         INSERT INTO RCV_HEADERS_INTERFACE(
                     HEADER_INTERFACE_ID
              ,      GROUP_ID
              ,      EDI_CONTROL_NUM
              ,      PROCESSING_STATUS_CODE
              ,      RECEIPT_SOURCE_CODE
              ,      ASN_TYPE
              ,      TRANSACTION_TYPE
              ,      AUTO_TRANSACT_CODE
              ,      TEST_FLAG
              ,      LAST_UPDATE_DATE
              ,      LAST_UPDATED_BY
              ,      LAST_UPDATE_LOGIN
              ,      CREATION_DATE
              ,      CREATED_BY
              ,      NOTICE_CREATION_DATE
              ,      SHIPMENT_NUM
              ,      RECEIPT_NUM
              ,      RECEIPT_HEADER_ID
              ,      VENDOR_NAME
              ,      VENDOR_ID
              ,      VENDOR_SITE_CODE
              ,      VENDOR_SITE_ID
              ,      FROM_ORGANIZATION_CODE
              ,      FROM_ORGANIZATION_ID
              ,      SHIP_TO_ORGANIZATION_CODE
              ,      SHIP_TO_ORGANIZATION_ID
              ,      LOCATION_CODE
              ,      LOCATION_ID
              ,      BILL_OF_LADING
              ,      PACKING_SLIP
              ,      SHIPPED_DATE
              ,      FREIGHT_CARRIER_CODE
              ,      EXPECTED_RECEIPT_DATE
              ,      RECEIVER_ID
              ,      NUM_OF_CONTAINERS
              ,      WAYBILL_AIRBILL_NUM
              ,      COMMENTS
              ,      GROSS_WEIGHT
              ,      GROSS_WEIGHT_UOM_CODE
              ,      NET_WEIGHT
              ,      NET_WEIGHT_UOM_CODE
              ,      TAR_WEIGHT
              ,      TAR_WEIGHT_UOM_CODE
              ,      PACKAGING_CODE
              ,      CARRIER_METHOD
              ,      CARRIER_EQUIPMENT
              ,      SPECIAL_HANDLING_CODE
              ,      HAZARD_CODE
              ,      HAZARD_CLASS
              ,      HAZARD_DESCRIPTION
              ,      FREIGHT_TERMS
              ,      FREIGHT_BILL_NUMBER
              ,      INVOICE_NUM
              ,      INVOICE_DATE
              ,      TOTAL_INVOICE_AMOUNT
              ,      TAX_NAME
              ,      TAX_AMOUNT
              ,      FREIGHT_AMOUNT
              ,      CURRENCY_CODE
              ,      CONVERSION_RATE_TYPE
              ,      CONVERSION_RATE
              ,      CONVERSION_RATE_DATE
              ,      PAYMENT_TERMS_NAME
              ,      PAYMENT_TERMS_ID
              ,      ATTRIBUTE_CATEGORY
              ,      ATTRIBUTE1
              ,      ATTRIBUTE2
              ,      ATTRIBUTE3
              ,      ATTRIBUTE4
              ,      ATTRIBUTE5
              ,      ATTRIBUTE6
              ,      ATTRIBUTE7
              ,      ATTRIBUTE8
              ,      ATTRIBUTE9
              ,      ATTRIBUTE10
              ,      ATTRIBUTE11
              ,      ATTRIBUTE12
              ,      ATTRIBUTE13
              ,      ATTRIBUTE14
              ,      ATTRIBUTE15
              ,      USGGL_TRANSACTION_CODE
              ,      EMPLOYEE_NAME
              ,      EMPLOYEE_ID
              ,      INVOICE_STATUS_CODE
              ,      VALIDATION_FLAG
              ,      PROCESSING_REQUEST_ID
              ,      CUSTOMER_ACCOUNT_NUMBER
              ,      CUSTOMER_ID
              ,      CUSTOMER_SITE_ID
              ,      CUSTOMER_PARTY_NAME
              ,      REMIT_TO_SITE_ID
              )
              SELECT
                     HEADER_INTERFACE_ID
              ,      p_batch_id
              ,      EDI_CONTROL_NUM
              ,      PROCESSING_STATUS_CODE
              ,      RECEIPT_SOURCE_CODE
              ,      ASN_TYPE
              ,      TRANSACTION_TYPE
              ,      AUTO_TRANSACT_CODE
              ,      TEST_FLAG
              ,      SYSDATE --LAST_UPDATE_DATE
              ,      G_USER_ID --LAST_UPDATED_BY
              ,      G_USER_ID --LAST_UPDATE_LOGIN
              ,      SYSDATE   --CREATION_DATE
              ,      G_USER_ID --CREATED_BY
              ,      NOTICE_CREATION_DATE
              ,      SHIPMENT_NUM
              ,      RECEIPT_NUM
              ,      RECEIPT_HEADER_ID
              ,      VENDOR_NAME
              ,      VENDOR_ID
              ,      VENDOR_SITE_CODE
              ,      VENDOR_SITE_ID
              ,      FROM_ORGANIZATION_CODE
              ,      FROM_ORGANIZATION_ID
              ,      SHIP_TO_ORGANIZATION_CODE
              ,      SHIP_TO_ORGANIZATION_ID
              ,      LOCATION_CODE
              ,      LOCATION_ID
              ,      BILL_OF_LADING
              ,      PACKING_SLIP
              ,      SHIPPED_DATE
              ,      FREIGHT_CARRIER_CODE
              ,      EXPECTED_RECEIPT_DATE
              ,      RECEIVER_ID
              ,      NUM_OF_CONTAINERS
              ,      WAYBILL_AIRBILL_NUM
              ,      COMMENTS
              ,      GROSS_WEIGHT
              ,      GROSS_WEIGHT_UOM_CODE
              ,      NET_WEIGHT
              ,      NET_WEIGHT_UOM_CODE
              ,      TAR_WEIGHT
              ,      TAR_WEIGHT_UOM_CODE
              ,      PACKAGING_CODE
              ,      CARRIER_METHOD
              ,      CARRIER_EQUIPMENT
              ,      SPECIAL_HANDLING_CODE
              ,      HAZARD_CODE
              ,      HAZARD_CLASS
              ,      HAZARD_DESCRIPTION
              ,      FREIGHT_TERMS
              ,      FREIGHT_BILL_NUMBER
              ,      INVOICE_NUM
              ,      INVOICE_DATE
              ,      TOTAL_INVOICE_AMOUNT
              ,      TAX_NAME
              ,      TAX_AMOUNT
              ,      FREIGHT_AMOUNT
              ,      CURRENCY_CODE
              ,      CONVERSION_RATE_TYPE
              ,      CONVERSION_RATE
              ,      CONVERSION_RATE_DATE
              ,      PAYMENT_TERMS_NAME
              ,      PAYMENT_TERMS_ID
              ,      ATTRIBUTE_CATEGORY
              ,      ATTRIBUTE1
              ,      ATTRIBUTE2
              ,      ATTRIBUTE3
              ,      ATTRIBUTE4
              ,      ATTRIBUTE5
              ,      ATTRIBUTE6
              ,      ATTRIBUTE7
              ,      ATTRIBUTE8
              ,      ATTRIBUTE9
              ,      ATTRIBUTE10
              ,      ATTRIBUTE11
              ,      ATTRIBUTE12
              ,      ATTRIBUTE13
              ,      ATTRIBUTE14
              ,      ATTRIBUTE15
              ,      USGGL_TRANSACTION_CODE
              ,      EMPLOYEE_NAME
              ,      EMPLOYEE_ID
              ,      INVOICE_STATUS_CODE
              ,      'Y'  --VALIDATION_FLAG as'Y'
              ,      PROCESSING_REQUEST_ID
              ,      CUSTOMER_ACCOUNT_NUMBER
              ,      CUSTOMER_ID
              ,      CUSTOMER_SITE_ID
              ,      CUSTOMER_PARTY_NAME
              ,      REMIT_TO_SITE_ID
              FROM   XX_PO_ASN_HDR_CONV_STG XAHIS
              WHERE  XAHIS.process_flag = 5
              AND    XAHIS.batch_id = p_batch_id;

              x_retcode := 0;

              display_log('Sucessfully inserted validated records into the Header interface table');

      EXCEPTION

         WHEN NO_DATA_FOUND THEN

            x_retcode := 1;
            x_errbuf  := 'No Data Found Exception Raised while inserting data into the RCV_HEADERS_INTERFACE table.'||SUBSTR(SQLERRM,1,200);

            log_procedure(
                          p_control_id           => NULL,
                          p_source_system_code   => NULL,
                          p_procedure_name       => 'INSERT_INTO_INTERFACE',
                          p_staging_table_name   => NULL,
                          p_staging_column_name  => NULL,
                          p_staging_column_value => NULL,
                          p_source_system_ref    => NULL,
                          p_batch_id             => p_batch_id,
                          p_exception_log        => x_errbuf,
                          p_oracle_error_code    => NULL,
                          p_oracle_error_msg     => NULL
                         );

       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

       WHEN OTHERS THEN

            x_errbuf := 'Unexpedted error occurred while inserting data into RCV Headers interface table.Error:'||SUBSTR(SQLERRM,1,200);
            display_log(x_errbuf);

            log_procedure(
                    p_control_id           => NULL,
                    p_source_system_code   => NULL,
                    p_procedure_name       => 'INSERT_INTO_INTERFACE',
                    p_staging_table_name   => NULL,
                    p_staging_column_name  => NULL,
                    p_staging_column_value => NULL,
                    p_source_system_ref    => NULL,
                    p_batch_id             => p_batch_id,
                    p_exception_log        => NULL,
                    p_oracle_error_code    => SQLCODE,
                    p_oracle_error_msg     => SUBSTR(SQLERRM,1,200)
                    );

       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

            x_retcode := 2;
      END;

      -- ----------------------------------------------------------------------
      -- Insert all the validated records into RCV Transactions interface table
      -- ----------------------------------------------------------------------

      BEGIN

         INSERT INTO RCV_TRANSACTIONS_INTERFACE(
                     INTERFACE_TRANSACTION_ID
              ,      GROUP_ID
              ,      LAST_UPDATE_DATE
              ,      LAST_UPDATED_BY
              ,      CREATION_DATE
              ,      CREATED_BY
              ,      LAST_UPDATE_LOGIN
              ,      REQUEST_ID
              ,      PROGRAM_APPLICATION_ID
              ,      PROGRAM_ID
              ,      PROGRAM_UPDATE_DATE
              ,      TRANSACTION_TYPE
              ,      TRANSACTION_DATE
              ,      PROCESSING_STATUS_CODE
              ,      PROCESSING_MODE_CODE
              ,      PROCESSING_REQUEST_ID
              ,      TRANSACTION_STATUS_CODE
              ,      CATEGORY_ID
              ,      QUANTITY
              ,      UNIT_OF_MEASURE
              ,      INTERFACE_SOURCE_CODE
              ,      INTERFACE_SOURCE_LINE_ID
              ,      INV_TRANSACTION_ID
              ,      ITEM_ID
              ,      ITEM_DESCRIPTION
              ,      ITEM_REVISION
              ,      UOM_CODE
              ,      EMPLOYEE_ID
              ,      AUTO_TRANSACT_CODE
              ,      SHIPMENT_HEADER_ID
              ,      SHIPMENT_LINE_ID
              ,      SHIP_TO_LOCATION_ID
              ,      PRIMARY_QUANTITY
              ,      PRIMARY_UNIT_OF_MEASURE
              ,      RECEIPT_SOURCE_CODE
              ,      VENDOR_ID
              ,      VENDOR_SITE_ID
              ,      FROM_ORGANIZATION_ID
              ,      FROM_SUBINVENTORY
              ,      TO_ORGANIZATION_ID
              ,      INTRANSIT_OWNING_ORG_ID
              ,      ROUTING_HEADER_ID
              ,      ROUTING_STEP_ID
              ,      SOURCE_DOCUMENT_CODE
              ,      PARENT_TRANSACTION_ID
              ,      PO_HEADER_ID
              ,      PO_REVISION_NUM
              ,      PO_RELEASE_ID
              ,      PO_LINE_ID
              ,      PO_LINE_LOCATION_ID
              ,      PO_UNIT_PRICE
              ,      CURRENCY_CODE
              ,      CURRENCY_CONVERSION_TYPE
              ,      CURRENCY_CONVERSION_RATE
              ,      CURRENCY_CONVERSION_DATE
              ,      PO_DISTRIBUTION_ID
              ,      REQUISITION_LINE_ID
              ,      REQ_DISTRIBUTION_ID
              ,      CHARGE_ACCOUNT_ID
              ,      SUBSTITUTE_UNORDERED_CODE
              ,      RECEIPT_EXCEPTION_FLAG
              ,      ACCRUAL_STATUS_CODE
              ,      INSPECTION_STATUS_CODE
              ,      INSPECTION_QUALITY_CODE
              ,      DESTINATION_TYPE_CODE
              ,      DELIVER_TO_PERSON_ID
              ,      LOCATION_ID
              ,      DELIVER_TO_LOCATION_ID
              ,      SUBINVENTORY
              ,      LOCATOR_ID
              ,      WIP_ENTITY_ID
              ,      WIP_LINE_ID
              ,      DEPARTMENT_CODE
              ,      WIP_REPETITIVE_SCHEDULE_ID
              ,      WIP_OPERATION_SEQ_NUM
              ,      WIP_RESOURCE_SEQ_NUM
              ,      BOM_RESOURCE_ID
              ,      SHIPMENT_NUM
              ,      FREIGHT_CARRIER_CODE
              ,      BILL_OF_LADING
              ,      PACKING_SLIP
              ,      SHIPPED_DATE
              ,      EXPECTED_RECEIPT_DATE
              ,      ACTUAL_COST
              ,      TRANSFER_COST
              ,      TRANSPORTATION_COST
              ,      TRANSPORTATION_ACCOUNT_ID
              ,      NUM_OF_CONTAINERS
              ,      WAYBILL_AIRBILL_NUM
              ,      VENDOR_ITEM_NUM
              ,      VENDOR_LOT_NUM
              ,      RMA_REFERENCE
              ,      COMMENTS
              ,      ATTRIBUTE_CATEGORY
              ,      ATTRIBUTE1
              ,      ATTRIBUTE2
              ,      ATTRIBUTE3
              ,      ATTRIBUTE4
              ,      ATTRIBUTE5
              ,      ATTRIBUTE6
              ,      ATTRIBUTE7
              ,      ATTRIBUTE8
              ,      ATTRIBUTE9
              ,      ATTRIBUTE10
              ,      ATTRIBUTE11
              ,      ATTRIBUTE12
              ,      ATTRIBUTE13
              ,      ATTRIBUTE14
              ,      ATTRIBUTE15
              ,      SHIP_HEAD_ATTRIBUTE_CATEGORY
              ,      SHIP_HEAD_ATTRIBUTE1
              ,      SHIP_HEAD_ATTRIBUTE2
              ,      SHIP_HEAD_ATTRIBUTE3
              ,      SHIP_HEAD_ATTRIBUTE4
              ,      SHIP_HEAD_ATTRIBUTE5
              ,      SHIP_HEAD_ATTRIBUTE6
              ,      SHIP_HEAD_ATTRIBUTE7
              ,      SHIP_HEAD_ATTRIBUTE8
              ,      SHIP_HEAD_ATTRIBUTE9
              ,      SHIP_HEAD_ATTRIBUTE10
              ,      SHIP_HEAD_ATTRIBUTE11
              ,      SHIP_HEAD_ATTRIBUTE12
              ,      SHIP_HEAD_ATTRIBUTE13
              ,      SHIP_HEAD_ATTRIBUTE14
              ,      SHIP_HEAD_ATTRIBUTE15
              ,      SHIP_LINE_ATTRIBUTE_CATEGORY
              ,      SHIP_LINE_ATTRIBUTE1
              ,      SHIP_LINE_ATTRIBUTE2
              ,      SHIP_LINE_ATTRIBUTE3
              ,      SHIP_LINE_ATTRIBUTE4
              ,      SHIP_LINE_ATTRIBUTE5
              ,      SHIP_LINE_ATTRIBUTE6
              ,      SHIP_LINE_ATTRIBUTE7
              ,      SHIP_LINE_ATTRIBUTE8
              ,      SHIP_LINE_ATTRIBUTE9
              ,      SHIP_LINE_ATTRIBUTE10
              ,      SHIP_LINE_ATTRIBUTE11
              ,      SHIP_LINE_ATTRIBUTE12
              ,      SHIP_LINE_ATTRIBUTE13
              ,      SHIP_LINE_ATTRIBUTE14
              ,      SHIP_LINE_ATTRIBUTE15
              ,      USSGL_TRANSACTION_CODE
              ,      GOVERNMENT_CONTEXT
              ,      REASON_ID
              ,      DESTINATION_CONTEXT
              ,      SOURCE_DOC_QUANTITY
              ,      SOURCE_DOC_UNIT_OF_MEASURE
              ,      MOVEMENT_ID
              ,      HEADER_INTERFACE_ID
              ,      VENDOR_CUM_SHIPPED_QTY
              ,      ITEM_NUM
              ,      DOCUMENT_NUM
              ,      DOCUMENT_LINE_NUM
              ,      TRUCK_NUM
              ,      SHIP_TO_LOCATION_CODE
              ,      CONTAINER_NUM
              ,      SUBSTITUTE_ITEM_NUM
              ,      NOTICE_UNIT_PRICE
              ,      ITEM_CATEGORY
              ,      LOCATION_CODE
              ,      VENDOR_NAME
              ,      VENDOR_SITE_CODE
              ,      FROM_ORGANIZATION_CODE
              ,      TO_ORGANIZATION_CODE
              ,      INTRANSIT_OWNING_ORG_CODE
              ,      ROUTING_CODE
              ,      ROUTING_STEP
              ,      RELEASE_NUM
              ,      DOCUMENT_SHIPMENT_LINE_NUM
              ,      DOCUMENT_DISTRIBUTION_NUM
              ,      DELIVER_TO_PERSON_NAME
              ,      DELIVER_TO_LOCATION_CODE
              ,      USE_MTL_LOT
              ,      USE_MTL_SERIAL
              ,      LOCATOR
              ,      REASON_NAME
              ,      VALIDATION_FLAG
              ,      SUBSTITUTE_ITEM_ID
              ,      QUANTITY_SHIPPED
              ,      QUANTITY_INVOICED
              ,      TAX_NAME
              ,      TAX_AMOUNT
              ,      REQ_NUM
              ,      REQ_LINE_NUM
              ,      REQ_DISTRIBUTION_NUM
              ,      WIP_ENTITY_NAME
              ,      WIP_LINE_CODE
              ,      RESOURCE_CODE
              ,      SHIPMENT_LINE_STATUS_CODE
              ,      BARCODE_LABEL
              ,      TRANSFER_PERCENTAGE
              ,      QA_COLLECTION_ID
              ,      COUNTRY_OF_ORIGIN_CODE
              ,      OE_ORDER_HEADER_ID
              ,      OE_ORDER_LINE_ID
              ,      CUSTOMER_ID
              ,      CUSTOMER_SITE_ID
              ,      CUSTOMER_ITEM_NUM
              ,      CREATE_DEBIT_MEMO_FLAG
              ,      PUT_AWAY_RULE_ID
              ,      PUT_AWAY_STRATEGY_ID
              ,      LPN_ID
              ,      TRANSFER_LPN_ID
              ,      COST_GROUP_ID
              ,      MOBILE_TXN
              ,      MMTT_TEMP_ID
              ,      TRANSFER_COST_GROUP_ID
              ,      SECONDARY_QUANTITY
              ,      SECONDARY_UNIT_OF_MEASURE
              ,      SECONDARY_UOM_CODE
              ,      QC_GRADE
              ,      FROM_LOCATOR
              ,      FROM_LOCATOR_ID
              ,      PARENT_SOURCE_TRANSACTION_NUM
              ,      INTERFACE_AVAILABLE_QTY
              ,      INTERFACE_TRANSACTION_QTY
              ,      INTERFACE_AVAILABLE_AMT
              ,      INTERFACE_TRANSACTION_AMT
              ,      LICENSE_PLATE_NUMBER
              ,      SOURCE_TRANSACTION_NUM
              ,      TRANSFER_LICENSE_PLATE_NUMBER
              ,      LPN_GROUP_ID
              ,      ORDER_TRANSACTION_ID
              ,      CUSTOMER_ACCOUNT_NUMBER
              ,      CUSTOMER_PARTY_NAME
              ,      OE_ORDER_LINE_NUM
              ,      OE_ORDER_NUM
              ,      PARENT_INTERFACE_TXN_ID
              ,      CUSTOMER_ITEM_ID
              ,      AMOUNT
              ,      JOB_ID
              ,      TIMECARD_ID
              ,      TIMECARD_OVN
              ,      ERECORD_ID
              ,      PROJECT_ID
              ,      TASK_ID
              ,      ASN_ATTACH_ID
              )
              SELECT
                     INTERFACE_TRANSACTION_ID
              ,      p_batch_id
              ,      SYSDATE --LAST_UPDATE_DATE
              ,      G_USER_ID--LAST_UPDATED_BY
              ,      SYSDATE --CREATION_DATE
              ,      G_USER_ID--CREATED_BY
              ,      G_USER_ID --LAST_UPDATE_LOGIN
              ,      REQUEST_ID
              ,      PROGRAM_APPLICATION_ID
              ,      PROGRAM_ID
              ,      PROGRAM_UPDATE_DATE
              ,      TRANSACTION_TYPE
              ,      SYSDATE--TRANSACTION_DATE
              ,      PROCESSING_STATUS_CODE
              ,      PROCESSING_MODE_CODE
              ,      PROCESSING_REQUEST_ID
              ,      'PENDING'--TRANSACTION_STATUS_CODE
              ,      CATEGORY_ID
              ,      QUANTITY
              ,      UNIT_OF_MEASURE
              ,      INTERFACE_SOURCE_CODE
              ,      INTERFACE_SOURCE_LINE_ID
              ,      INV_TRANSACTION_ID
              ,      ITEM_ID
              ,      ITEM_DESCRIPTION
              ,      ITEM_REVISION
              ,      UOM_CODE
              ,      EMPLOYEE_ID
              ,      AUTO_TRANSACT_CODE
              ,      SHIPMENT_HEADER_ID
              ,      SHIPMENT_LINE_ID
              ,      SHIP_TO_LOCATION_ID
              ,      PRIMARY_QUANTITY
              ,      PRIMARY_UNIT_OF_MEASURE
              ,      RECEIPT_SOURCE_CODE
              ,      VENDOR_ID
              ,      VENDOR_SITE_ID
              ,      FROM_ORGANIZATION_ID
              ,      FROM_SUBINVENTORY
              ,      TO_ORGANIZATION_ID
              ,      INTRANSIT_OWNING_ORG_ID
              ,      ROUTING_HEADER_ID
              ,      ROUTING_STEP_ID
              ,      SOURCE_DOCUMENT_CODE
              ,      PARENT_TRANSACTION_ID
              ,      PO_HEADER_ID
              ,      PO_REVISION_NUM
              ,      PO_RELEASE_ID
              ,      PO_LINE_ID
              ,      PO_LINE_LOCATION_ID
              ,      PO_UNIT_PRICE
              ,      CURRENCY_CODE
              ,      CURRENCY_CONVERSION_TYPE
              ,      CURRENCY_CONVERSION_RATE
              ,      CURRENCY_CONVERSION_DATE
              ,      PO_DISTRIBUTION_ID
              ,      REQUISITION_LINE_ID
              ,      REQ_DISTRIBUTION_ID
              ,      CHARGE_ACCOUNT_ID
              ,      SUBSTITUTE_UNORDERED_CODE
              ,      RECEIPT_EXCEPTION_FLAG
              ,      ACCRUAL_STATUS_CODE
              ,      INSPECTION_STATUS_CODE
              ,      INSPECTION_QUALITY_CODE
              ,      DESTINATION_TYPE_CODE
              ,      DELIVER_TO_PERSON_ID
              ,      LOCATION_ID
              ,      DELIVER_TO_LOCATION_ID
              ,      SUBINVENTORY
              ,      LOCATOR_ID
              ,      WIP_ENTITY_ID
              ,      WIP_LINE_ID
              ,      DEPARTMENT_CODE
              ,      WIP_REPETITIVE_SCHEDULE_ID
              ,      WIP_OPERATION_SEQ_NUM
              ,      WIP_RESOURCE_SEQ_NUM
              ,      BOM_RESOURCE_ID
              ,      SHIPMENT_NUM
              ,      FREIGHT_CARRIER_CODE
              ,      BILL_OF_LADING
              ,      PACKING_SLIP
              ,      SHIPPED_DATE
              ,      EXPECTED_RECEIPT_DATE
              ,      ACTUAL_COST
              ,      TRANSFER_COST
              ,      TRANSPORTATION_COST
              ,      TRANSPORTATION_ACCOUNT_ID
              ,      NUM_OF_CONTAINERS
              ,      WAYBILL_AIRBILL_NUM
              ,      VENDOR_ITEM_NUM
              ,      VENDOR_LOT_NUM
              ,      RMA_REFERENCE
              ,      COMMENTS
              ,      ATTRIBUTE_CATEGORY
              ,      ATTRIBUTE1
              ,      ATTRIBUTE2
              ,      ATTRIBUTE3
              ,      ATTRIBUTE4
              ,      ATTRIBUTE5
              ,      ATTRIBUTE6
              ,      ATTRIBUTE7
              ,      ATTRIBUTE8
              ,      ATTRIBUTE9
              ,      ATTRIBUTE10
              ,      ATTRIBUTE11
              ,      ATTRIBUTE12
              ,      ATTRIBUTE13
              ,      ATTRIBUTE14
              ,      ATTRIBUTE15
              ,      SHIP_HEAD_ATTRIBUTE_CATEGORY
              ,      SHIP_HEAD_ATTRIBUTE1
              ,      SHIP_HEAD_ATTRIBUTE2
              ,      SHIP_HEAD_ATTRIBUTE3
              ,      SHIP_HEAD_ATTRIBUTE4
              ,      SHIP_HEAD_ATTRIBUTE5
              ,      SHIP_HEAD_ATTRIBUTE6
              ,      SHIP_HEAD_ATTRIBUTE7
              ,      SHIP_HEAD_ATTRIBUTE8
              ,      SHIP_HEAD_ATTRIBUTE9
              ,      SHIP_HEAD_ATTRIBUTE10
              ,      SHIP_HEAD_ATTRIBUTE11
              ,      SHIP_HEAD_ATTRIBUTE12
              ,      SHIP_HEAD_ATTRIBUTE13
              ,      SHIP_HEAD_ATTRIBUTE14
              ,      SHIP_HEAD_ATTRIBUTE15
              ,      SHIP_LINE_ATTRIBUTE_CATEGORY
              ,      SHIP_LINE_ATTRIBUTE1
              ,      SHIP_LINE_ATTRIBUTE2
              ,      SHIP_LINE_ATTRIBUTE3
              ,      SHIP_LINE_ATTRIBUTE4
              ,      SHIP_LINE_ATTRIBUTE5
              ,      SHIP_LINE_ATTRIBUTE6
              ,      SHIP_LINE_ATTRIBUTE7
              ,      SHIP_LINE_ATTRIBUTE8
              ,      SHIP_LINE_ATTRIBUTE9
              ,      SHIP_LINE_ATTRIBUTE10
              ,      SHIP_LINE_ATTRIBUTE11
              ,      SHIP_LINE_ATTRIBUTE12
              ,      SHIP_LINE_ATTRIBUTE13
              ,      SHIP_LINE_ATTRIBUTE14
              ,      SHIP_LINE_ATTRIBUTE15
              ,      USSGL_TRANSACTION_CODE
              ,      GOVERNMENT_CONTEXT
              ,      REASON_ID
              ,      DESTINATION_CONTEXT
              ,      SOURCE_DOC_QUANTITY
              ,      SOURCE_DOC_UNIT_OF_MEASURE
              ,      MOVEMENT_ID
              ,      HEADER_INTERFACE_ID
              ,      VENDOR_CUM_SHIPPED_QTY
              ,      ITEM_NUM
              ,      LEGACY_PO_NBR
              ,      DOCUMENT_LINE_NUM
              ,      TRUCK_NUM
              ,      SHIP_TO_LOCATION_CODE
              ,      CONTAINER_NUM
              ,      SUBSTITUTE_ITEM_NUM
              ,      NOTICE_UNIT_PRICE
              ,      ITEM_CATEGORY
              ,      LOCATION_CODE
              ,      VENDOR_NAME
              ,      VENDOR_SITE_CODE
              ,      FROM_ORGANIZATION_CODE
              ,      TO_ORGANIZATION_CODE
              ,      INTRANSIT_OWNING_ORG_CODE
              ,      ROUTING_CODE
              ,      ROUTING_STEP
              ,      RELEASE_NUM
              ,      DOCUMENT_SHIPMENT_LINE_NUM
              ,      DOCUMENT_DISTRIBUTION_NUM
              ,      DELIVER_TO_PERSON_NAME
              ,      DELIVER_TO_LOCATION_CODE
              ,      USE_MTL_LOT
              ,      USE_MTL_SERIAL
              ,      LOCATOR
              ,      REASON_NAME
              ,      'Y' --VALIDATION_FLAG
              ,      SUBSTITUTE_ITEM_ID
              ,      QUANTITY_SHIPPED
              ,      QUANTITY_INVOICED
              ,      TAX_NAME
              ,      TAX_AMOUNT
              ,      REQ_NUM
              ,      REQ_LINE_NUM
              ,      REQ_DISTRIBUTION_NUM
              ,      WIP_ENTITY_NAME
              ,      WIP_LINE_CODE
              ,      RESOURCE_CODE
              ,      SHIPMENT_LINE_STATUS_CODE
              ,      BARCODE_LABEL
              ,      TRANSFER_PERCENTAGE
              ,      QA_COLLECTION_ID
              ,      COUNTRY_OF_ORIGIN_CODE
              ,      OE_ORDER_HEADER_ID
              ,      OE_ORDER_LINE_ID
              ,      CUSTOMER_ID
              ,      CUSTOMER_SITE_ID
              ,      CUSTOMER_ITEM_NUM
              ,      CREATE_DEBIT_MEMO_FLAG
              ,      PUT_AWAY_RULE_ID
              ,      PUT_AWAY_STRATEGY_ID
              ,      LPN_ID
              ,      TRANSFER_LPN_ID
              ,      COST_GROUP_ID
              ,      MOBILE_TXN
              ,      MMTT_TEMP_ID
              ,      TRANSFER_COST_GROUP_ID
              ,      SECONDARY_QUANTITY
              ,      SECONDARY_UNIT_OF_MEASURE
              ,      SECONDARY_UOM_CODE
              ,      QC_GRADE
              ,      FROM_LOCATOR
              ,      FROM_LOCATOR_ID
              ,      PARENT_SOURCE_TRANSACTION_NUM
              ,      INTERFACE_AVAILABLE_QTY
              ,      INTERFACE_TRANSACTION_QTY
              ,      INTERFACE_AVAILABLE_AMT
              ,      INTERFACE_TRANSACTION_AMT
              ,      LICENSE_PLATE_NUMBER
              ,      SOURCE_TRANSACTION_NUM
              ,      TRANSFER_LICENSE_PLATE_NUMBER
              ,      LPN_GROUP_ID
              ,      ORDER_TRANSACTION_ID
              ,      CUSTOMER_ACCOUNT_NUMBER
              ,      CUSTOMER_PARTY_NAME
              ,      OE_ORDER_LINE_NUM
              ,      OE_ORDER_NUM
              ,      PARENT_INTERFACE_TXN_ID
              ,      CUSTOMER_ITEM_ID
              ,      AMOUNT
              ,      JOB_ID
              ,      TIMECARD_ID
              ,      TIMECARD_OVN
              ,      ERECORD_ID
              ,      PROJECT_ID
              ,      TASK_ID
              ,      ASN_ATTACH_ID
              FROM   XX_PO_ASN_DTL_CONV_STG XATIS
              WHERE  XATIS.process_flag = 5
              AND    XATIS.batch_id = p_batch_id;

              x_retcode := 0;

              COMMIT;

              display_log('Sucessfully inserted validated records into the Transactions interface table : '||p_batch_id);

      EXCEPTION

           WHEN NO_DATA_FOUND THEN

              x_retcode := 1;
              x_errbuf  := 'No Data Found Exception Raised while inserting data into the RCV_TRANSACTIONS_INTERFACE table.'||SUBSTR(SQLERRM,1,200);

              log_procedure(
                            p_control_id           => NULL,
                            p_source_system_code   => NULL,
                            p_procedure_name       => 'INSERT_INTO_INTERFACE',
                            p_staging_table_name   => NULL,
                            p_staging_column_name  => NULL,
                            p_staging_column_value => NULL,
                            p_source_system_ref    => NULL,
                            p_batch_id             => p_batch_id,
                            p_exception_log        => x_errbuf,
                            p_oracle_error_code    => NULL,
                            p_oracle_error_msg     => NULL
                           );

           XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

           WHEN OTHERS THEN

              x_errbuf := 'Unexpedted error occurred while inserting data into RCV Transactions interface table.Error:'||SUBSTR(SQLERRM,1,200);
              display_log(x_errbuf);

              log_procedure(
                      p_control_id           => NULL,
                      p_source_system_code   => NULL,
                      p_procedure_name       => 'INSERT_INTO_INTERFACE',
                      p_staging_table_name   => NULL,
                      p_staging_column_name  => NULL,
                      p_staging_column_value => NULL,
                      p_source_system_ref    => NULL,
                      p_batch_id             => p_batch_id,
                      p_exception_log        => NULL,
                      p_oracle_error_code    => SQLCODE,
                      p_oracle_error_msg     => SUBSTR(SQLERRM,1,200)
                          );
              x_retcode := 2;
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

      END;

   END insert_into_interface;

   -- +=========================================================================+
   -- | Name        :  process_asn                                              |
   -- | Description :  This procedure is invoked from the main procedure.       |
   -- |                This procedure will submit the Receiving Transaction     |
   -- |                Processor program to populate the EBS base tables.       |
   -- |                                                                         |
   -- | Parameters  :  p_group_id                                               |
   -- |                                                                         |
   -- +=========================================================================+

   PROCEDURE  process_asn(
                           x_errbuf          OUT  VARCHAR2
                         , x_retcode         OUT  NUMBER
                         , x_pro_hdr_succ    OUT  NUMBER
                         , x_pro_hdr_failed  OUT  NUMBER
                         , x_pro_dtl_succ    OUT  NUMBER
                         , x_pro_dtl_failed  OUT  NUMBER
                         , p_group_id        IN   NUMBER
                         )
   IS

      --  --------------------------
      --  Local Variable Declaration
      --  --------------------------

      EX_SUBMIT_IMPORT         EXCEPTION;
      ln_conc_request_id       FND_CONCURRENT_REQUESTS.request_id%TYPE;
      lc_phase                 fnd_concurrent_requests.phase_code%type;
      ln_import_req_index      PLS_INTEGER:= 0;
      lc_staging_table_name    VARCHAR2(200);
      lc_hdr_error_message     VARCHAR2(2000);
      lc_line_error_message    VARCHAR2(2000);

      -- ----------------------
      -- Table Type Declaration
      -- ----------------------

      TYPE error_message_tbl_typ IS TABLE OF po_interface_errors.error_message%type
      INDEX BY BINARY_INTEGER;
      lt_error_message       error_message_tbl_typ;
      lt_hdr_error_message   error_message_tbl_typ;
      lt_line_error_message  error_message_tbl_typ;

      TYPE error_control_id_tbl_typ IS TABLE OF XX_PO_ASN_HDR_CONV_STG.control_id%type
      INDEX BY BINARY_INTEGER;
      lt_error_control_id    error_control_id_tbl_typ;

      TYPE table_name_tbl_typ IS TABLE OF po_interface_errors.table_name%type
      INDEX BY BINARY_INTEGER;
      lt_table_name          table_name_tbl_typ;

      TYPE success_rowid_tbl_typ IS TABLE OF ROWID
      INDEX BY BINARY_INTEGER;
      lt_success_rowid       success_rowid_tbl_typ;

      TYPE conc_request_id_tbl_typ IS TABLE OF fnd_concurrent_requests.request_id%type
      INDEX BY BINARY_INTEGER;
      lt_conc_request_id     conc_request_id_tbl_typ;

      TYPE int_header_id_tbl_typ IS TABLE OF rcv_headers_interface.header_interface_id%type
      INDEX BY BINARY_INTEGER;
      lt_int_header_id int_header_id_tbl_typ;

      TYPE int_line_id_tbl_typ IS TABLE OF rcv_transactions_interface.interface_transaction_id%type
      INDEX BY BINARY_INTEGER;
      lt_int_line_id int_line_id_tbl_typ;

      ---------------------------------------
      --Cursor to fetch all sucessful records
      ---------------------------------------
      CURSOR lcu_success_records
      IS
      SELECT XPAHCS.ROWID
      FROM   rcv_headers_interface RHI,
             xx_po_asn_hdr_conv_stg XPAHCS
      WHERE  RHI.header_interface_id        = XPAHCS.header_interface_id
      AND    RHI.processing_status_code     = 'SUCCESS'
      AND    RHI.group_id                   = p_group_id;

      -------------------------------------
      --Cursor to fetch all errored records
      -------------------------------------
      CURSOR lcu_errored_records
      IS
      SELECT XPAHCS.control_id,
             PIE.error_message,
             PIE.table_name
      FROM   rcv_headers_interface RHI
            ,po_interface_errors PIE
            ,xx_po_asn_hdr_conv_stg XPAHCS
      WHERE  RHI.processing_status_code   = 'ERROR'
      AND    PIE.interface_header_id      = RHI.header_interface_id
      AND    RHI.header_interface_id      = XPAHCS.header_interface_id
      AND    RHI.group_id                 = p_group_id;

      --------------------------------------------
      --Cursor to select errored interface headers
      -- and concatenate them into one error
      --------------------------------------------
      CURSOR lcu_error_update_header
      IS
      SELECT XPAHCS.header_interface_id
      FROM   xx_po_asn_hdr_conv_stg XPAHCS
      WHERE  XPAHCS.batch_id   = p_group_id
      AND    XPAHCS.header_interface_id IN (SELECT RHI.header_interface_id
                                            FROM   rcv_headers_interface RHI
                                                  ,po_interface_errors PIE
                                            WHERE  RHI.processing_status_code = 'ERROR'
                                            AND    PIE.interface_header_id    = RHI.header_interface_id
                                           );

      TYPE error_update_header_tbl_typ IS TABLE OF  lcu_error_update_header%rowtype
      INDEX BY BINARY_INTEGER;
      lt_error_update_header error_update_header_tbl_typ;

      ------------------------------------------
      --Cursor to select errored interface lines
      ------------------------------------------
      CURSOR lcu_error_update_line
      IS
      SELECT     XPADCS.interface_transaction_id
          FROM   rcv_headers_interface RHI
                ,po_interface_errors PIE
                ,xx_po_asn_dtl_conv_stg XPADCS
          WHERE  RHI.processing_status_code      = 'ERROR'
          AND    RHI.group_id                    = p_group_id
          AND    PIE.interface_header_id         = RHI.header_interface_id
          AND    XPADCS.interface_transaction_id = PIE.interface_line_id
          AND    PIE.interface_transaction_id IS NOT NULL;

      TYPE error_update_line_tbl_typ IS TABLE OF lcu_error_update_line%rowtype
      INDEX BY BINARY_INTEGER;
      lt_error_update_line error_update_line_tbl_typ;

      ------------------------------------------------------
      --Cursor to select all the error messages for a header
      ------------------------------------------------------
      CURSOR lcu_hdr(p_header_interface_id IN NUMBER)
      IS
      SELECT PIE.interface_header_id,PIE.error_message
      FROM po_interface_errors PIE
      WHERE interface_header_id = p_header_interface_id
      AND interface_line_id IS NULL;

      --------------------------------------------------
      --Cursor to select all the error messages for line
      --------------------------------------------------
      CURSOR lcu_line(p_interface_line_id IN NUMBER)
      IS
      SELECT PIE.interface_header_id,PIE.interface_transaction_id,PIE.error_message
      FROM po_interface_errors PIE
      WHERE interface_line_id   = p_interface_line_id ;
      
      --------------------------------------------------------------------
      --Cursor to fetch the distinct Operating Unit from the staging table
      --------------------------------------------------------------------
      CURSOR lcu_operating_unit
      IS
      SELECT FRT.responsibility_id,FRT.application_id,FRT.responsibility_name
      FROM   hr_operating_units HOU
            ,fnd_responsibility_tl FRT
      --WHERE  FRT.responsibility_name like 'OD '||SUBSTR(HOU.name,4,2)||' Purchasing Super User' --Commented on 04-Sep-07,Gowri
      WHERE  FRT.responsibility_name like 'OD ('||SUBSTR(HOU.name,4,2)||') PO Superuser' --Added on 04-Sep-07,Gowri
      AND    HOU.organization_id IN 
        (SELECT DISTINCT org_id 
         FROM po_vendor_sites_all PV
             ,xx_po_asn_hdr_conv_stg XPAHC
         WHERE PV.vendor_site_id = XPAHC.vendor_site_id
         AND  XPAHC.batch_id = p_group_id
         );           

   BEGIN
        
         x_pro_hdr_succ     := 0 ;
         x_pro_hdr_failed   := 0 ;
         x_pro_dtl_succ     := 0 ;
         x_pro_dtl_failed   := 0 ;
           
         -- **************************************************************************
         -- To create ASN's belonging to other OU's, reset the APPS initialize profile
         -- to process such ASN.
         -- **************************************************************************
         
         FOR lcu_operating_unit_rec IN lcu_operating_unit         
         LOOP
             
               FND_GLOBAL.APPS_INITIALIZE(user_id        => G_USER_ID
                                         ,resp_id          => lcu_operating_unit_rec.responsibility_id
                                         ,resp_appl_id     => lcu_operating_unit_rec.application_id);                                        
            
             ln_conc_request_id := FND_REQUEST.submit_request(
                                                              application  => G_CHLD_PROG_APPLICATION
                                                            , program      => 'RVCTP'
                                                            , sub_request  => FALSE
                                                            , argument1    => 'BATCH'
                                                            , argument2    => p_group_id
                                                             );
         END LOOP;           

         IF ln_conc_request_id = 0 THEN
            x_errbuf  := FND_MESSAGE.GET;
            display_log('Standard Receiving Transaction Processor program failed to submit: ' || x_errbuf);
            RAISE EX_SUBMIT_IMPORT;
         ELSE 
            ln_import_req_index:=ln_import_req_index+1;
            lt_conc_request_id(ln_import_req_index):=ln_conc_request_id;

            COMMIT;
            x_retcode := 0;
            display_log('Submitted Receiving Transaction Processor program Successfully : '|| TO_CHAR( ln_conc_request_id ));
         END IF;

       ----------------------------------------------------------------
       --Wait till the standard import program completes for this Batch
       ----------------------------------------------------------------
       IF lt_conc_request_id.COUNT<>0 THEN
       FOR i IN lt_conc_request_id.FIRST..lt_conc_request_id.LAST
           LOOP
               IF lt_conc_request_id(i)<>0 THEN
                   LOOP
                       SELECT FCR.phase_code
                       INTO   lc_phase
                       FROM   FND_CONCURRENT_REQUESTS FCR
                       WHERE  FCR.request_id = ln_conc_request_id;
                       IF  lc_phase = 'C' THEN
                           EXIT;
                       ELSE
                           DBMS_LOCK.SLEEP(G_SLEEP);
                      END IF;
                  END LOOP;
              END IF;
           END LOOP;
       END IF;

       display_log('Updating Process Flags of Header and detail with processed results');
       ------------------------------------------------------
       --Updating Process Flags for Successful Header Records
       ------------------------------------------------------
       OPEN lcu_success_records;
       FETCH lcu_success_records BULK COLLECT INTO lt_success_rowid;
       CLOSE lcu_success_records;

       display_log('lt_success_rowid.count:'||lt_success_rowid.count);
       IF lt_success_rowid.count<>0 THEN
          FORALL i IN lt_success_rowid.FIRST..lt_success_rowid.LAST
          UPDATE xx_po_asn_hdr_conv_stg XPAHCS
          SET    XPAHCS.process_flag = 7
          WHERE  XPAHCS. ROWID       = lt_success_rowid(i);
          
          x_pro_hdr_succ  := x_pro_hdr_succ +SQL%ROWCOUNT;

       END IF;

       ----------------------------------------------------
       --Updating Process Flags for Successful Line Records
       ----------------------------------------------------
       UPDATE xx_po_asn_dtl_conv_stg XPADCS1
       SET    XPADCS1.process_flag=7
       WHERE  XPADCS1.ROWID IN (SELECT XPADCS.ROWID
                                FROM   xx_po_asn_hdr_conv_stg XPAHCS
                                      ,xx_po_asn_dtl_conv_stg XPADCS
                                WHERE  XPADCS.parent_record_id = XPAHCS.record_id
                                AND    XPAHCS.batch_id         = p_group_id
                                AND    XPAHCS.process_flag     = 7);

       x_pro_dtl_succ   := x_pro_dtl_succ + SQL%ROWCOUNT;

       ----------------------------------------
       --Logging Errors for Errored PO Records
       ----------------------------------------
       OPEN lcu_errored_records;
       FETCH lcu_errored_records BULK COLLECT INTO lt_error_control_id,lt_error_message,lt_table_name;

          IF lt_error_control_id.count<>0 THEN
             FOR i IN lt_error_control_id.FIRST..lt_error_control_id.LAST
             LOOP
                 -------------------------------------------------
                 -- Table name is being converted to identify the
                 -- base table from where the data originated
                 -------------------------------------------------
       
                SELECT DECODE(lt_table_name(i),'RCV_HEADERS_INTERFACE','XX_PO_ASN_HDR_CONV_STG'
                                              ,'RCV_TRANSACTIONS_INTERFACE','XX_PO_ASN_DTL_CONV_STG'
                             )
                INTO   lc_staging_table_name
                FROM dual;

             ----------------------------------------------------------------------------
             -- Call XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
             -- to log the exceptions while records are in validation in processing state
             ------------------------------------ ----------------------------------------

             log_procedure(
                          p_control_id           => NULL,
                          p_source_system_code   => NULL,
                          p_procedure_name       => 'CHILD_MAIN',
                          p_staging_table_name   => lc_staging_table_name,
                          p_staging_column_name  => NULL,
                          p_staging_column_value => NULL,
                          p_source_system_ref    => NULL,
                          p_batch_id             => p_group_id,
                          p_exception_log        => NULL,
                          p_oracle_error_code    => NULL,
                          p_oracle_error_msg     => lt_error_message(i)
                          );

             END LOOP;
          END IF;

       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

       CLOSE lcu_errored_records;

       ------------------------------------------------------
       --Updating Process Flags for Errored PO Header Records
       ------------------------------------------------------
       UPDATE xx_po_asn_hdr_conv_stg XPAHCS
       SET    XPAHCS.process_flag = 6
       WHERE  XPAHCS.batch_id     = p_group_id
       AND    XPAHCS.process_flag = 5;

       x_pro_hdr_failed := x_pro_hdr_failed + SQL%ROWCOUNT;

       ----------------------------------------------------
       --Updating Process Flags for Errored PO Line Records
       ----------------------------------------------------
       UPDATE xx_po_asn_dtl_conv_stg XPADCS
       SET    process_flag         = 6
       WHERE  XPADCS.batch_id      = p_group_id
       AND    XPADCS.process_flag  = 5;

       x_pro_dtl_failed := x_pro_dtl_failed + SQL%ROWCOUNT;

       -------------------------------
       --Updating header Error message
       -------------------------------
       OPEN  lcu_error_update_header;
       FETCH lcu_error_update_header BULK COLLECT INTO lt_error_update_header;
       CLOSE lcu_error_update_header;

       IF lt_error_update_header.COUNT<>0
       THEN
           FOR i IN lt_error_update_header.FIRST..lt_error_update_header.LAST
           LOOP
               lt_int_header_id(i):= lt_error_update_header(i).header_interface_id;
               lc_hdr_error_message:=NULL;
               FOR lcu_hdr_rec IN lcu_hdr(lt_error_update_header(i).header_interface_id)
               LOOP
                   lc_hdr_error_message:=SUBSTR(lc_hdr_error_message||lcu_hdr_rec.error_message,1,500);
               END LOOP;
               lt_hdr_error_message(i):=lc_hdr_error_message;
           END LOOP;
       END IF;

       FORALL i IN lt_error_update_header.FIRST..lt_error_update_header.LAST
       UPDATE xx_po_asn_hdr_conv_stg XPAHCS
       SET error_message= lt_hdr_error_message(i)
       WHERE header_interface_id =lt_int_header_id(i);

       -----------------------------
       --Updating line Error message
       -----------------------------
       OPEN  lcu_error_update_line;
       FETCH lcu_error_update_line BULK COLLECT INTO lt_error_update_line;
       CLOSE lcu_error_update_line;

       IF lt_error_update_line.COUNT <>0
       THEN
           FOR i IN lt_error_update_line.FIRST..lt_error_update_line.LAST
           LOOP
               lt_int_line_id(i)  := lt_error_update_line(i).interface_transaction_id;
               lc_line_error_message:=NULL ;
               FOR lcu_line_rec IN lcu_line(lt_error_update_line(i).interface_transaction_id)
               LOOP
                   lc_line_error_message:=SUBSTR(lc_line_error_message||lcu_line_rec.error_message,1,500);
               END LOOP;
               lt_line_error_message(i):=lc_line_error_message;
           END LOOP;
       END IF;

       FORALL i IN lt_error_update_line.FIRST..lt_error_update_line.LAST
       UPDATE xx_po_asn_dtl_conv_stg XPADCS
       SET error_message= lt_line_error_message(i)
       WHERE interface_transaction_id=lt_int_line_id(i);

   EXCEPTION

      WHEN EX_SUBMIT_IMPORT THEN

         x_retcode := 2;
         log_procedure(
                      p_control_id           => NULL,
                      p_source_system_code   => NULL,
                      p_procedure_name       => 'PROCESS_ASN',
                      p_staging_table_name   => NULL,
                      p_staging_column_name  => NULL,
                      p_staging_column_value => NULL,
                      p_source_system_ref    => NULL,
                      p_batch_id             => p_group_id,
                      p_exception_log        => x_errbuf,
                      p_oracle_error_code    => SQLCODE,
                      p_oracle_error_msg     => SUBSTR(SQLERRM,1,200)
                      );

       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

      WHEN OTHERS THEN

         x_errbuf  := 'Unexpected Exception is raised in Procedure PROCESS_ASN '|| SUBSTR(SQLERRM,1,200);
         x_retcode := 2;

         log_procedure(
                      p_control_id           => NULL,
                      p_source_system_code   => NULL,
                      p_procedure_name       => 'PROCESS_ASN',
                      p_staging_table_name   => NULL,
                      p_staging_column_name  => NULL,
                      p_staging_column_value => NULL,
                      p_source_system_ref    => NULL,
                      p_batch_id             => p_group_id,
                      p_exception_log        => x_errbuf,
                      p_oracle_error_code    => SQLCODE,
                      p_oracle_error_msg     => SUBSTR(SQLERRM,1,200)
                      );

       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

   END process_asn;

   -- +===================================================================+
   -- | Name        :  child_main                                         |
   -- | Description :  This procedure is invoked from the OD: PO ASN      |
   -- |                Conversion Child Program Request.This would        |
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
                        x_errbuf             OUT  VARCHAR2
                      , x_retcode            OUT  VARCHAR2
                      , p_validate_only_flag IN   VARCHAR2
                      , p_reset_status_flag  IN   VARCHAR2
                      , p_batch_id           IN   NUMBER
                      , p_debug_flag         IN   VARCHAR2
                       )
   IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      EX_EXCEPTION_SMRY_REPRT        EXCEPTION;
      EX_NO_DATA_FOUND_STG           EXCEPTION;
      EX_VALIDATE_ONLY               EXCEPTION;
      EX_NO_DATA                     EXCEPTION;
      EX_ENTRY_EXCEP                 EXCEPTION;

      ln_hdr_record_count            PLS_INTEGER;
      ln_dtl_record_count            PLS_INTEGER;
      ln_record_count                PLS_INTEGER;

      ln_excpn_request_id            PLS_INTEGER;
      ln_master_request_id           PLS_INTEGER;

      ln_vendor_id                   PLS_INTEGER;
      ln_vendor_site_id              PLS_INTEGER;
      ln_location_id                 PLS_INTEGER;
      ln_line_id                     PLS_INTEGER;
      ln_line_locn_id                PLS_INTEGER;
      ln_distribution_id             PLS_INTEGER;
      ln_to_org_id                   PLS_INTEGER;
      ln_item_id                     PLS_INTEGER;
      ln_promised_date               DATE;
      ln_header_id                   PLS_INTEGER;
      ln_ship_to_location_id         PLS_INTEGER;
      ln_organization_id             PLS_INTEGER;

      ln_hdr_val_success             PLS_INTEGER := 0;
      ln_hdr_val_failed              PLS_INTEGER := 0;
      ln_dtl_val_success             PLS_INTEGER := 0;
      ln_dtl_val_failed              PLS_INTEGER := 0;
      ln_hdr_proc_failed             PLS_INTEGER := 0;
      ln_hdr_proc_success            PLS_INTEGER := 0;
      ln_dtl_proc_failed             PLS_INTEGER := 0;
      ln_dtl_proc_success            PLS_INTEGER := 0;
      ln_header_total                PLS_INTEGER := 0;
      ln_line_total                  PLS_INTEGER := 0;

      ln_validated_succ              PLS_INTEGER := 0;
      ln_validated_err               PLS_INTEGER := 0;
      ln_header_interface_id         PLS_INTEGER ;
      ln_record_id                   PLS_INTEGER ;
      ln_dtl_prss_flag               PLS_INTEGER ;
      ln_hdr_flag                    PLS_INTEGER;
      ln_cntr                        PLS_INTEGER := 0;

      lc_errbuf                      VARCHAR2(1000);
      lc_return_status               VARCHAR2(10);
      lc_uom_code                    VARCHAR2(10);
      lc_dtl_exists_flag             VARCHAR2(1) := NULL;
      lx_errbuf                      VARCHAR2(2000);
      lx_retcode                     VARCHAR2(20);
      lc_vendor_flag                 VARCHAR2(1) ;
      lc_header_flag                 VARCHAR2(1) ;
      lc_line_flag                   VARCHAR2(1) ;
      lc_item_flag                   VARCHAR2(1) ;
      lc_dest_flag                   VARCHAR2(1) ;
      lc_proc_flag                   VARCHAR2(1) := 'N';
      lc_header_message              VARCHAR2(4000);
      lc_line_message                VARCHAR2(4000);
      lc_vendor_name                 PO_VENDORS.VENDOR_NAME%TYPE;
      lc_dest_type_code              po_distributions_all.destination_type_code%TYPE;
      lc_description                 mtl_system_items_b.description%TYPE;

      -- -----------------------
      -- Table Type declarations
      -- -----------------------

      TYPE hdr_ctrl_id_tbl_type IS TABLE OF XX_PO_ASN_HDR_CONV_STG.control_id%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE  row_id_tbl_type IS TABLE OF ROWID
      INDEX BY BINARY_INTEGER;

      TYPE dtl_ctrl_id_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.control_id%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE hdr_prss_flg_tbl_type IS TABLE OF XX_PO_ASN_HDR_CONV_STG.process_flag%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE dtl_prss_flg_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.process_flag%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE hdr_err_msg_tbl_type IS TABLE OF XX_PO_ASN_HDR_CONV_STG.error_message%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE dtl_err_msg_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.error_message%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE vend_id_tbl_type IS TABLE OF XX_PO_ASN_HDR_CONV_STG.vendor_id%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE vend_site_id_tbl_type IS TABLE OF XX_PO_ASN_HDR_CONV_STG.vendor_site_id%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE locn_id_tbl_type IS TABLE OF XX_PO_ASN_HDR_CONV_STG.location_id%TYPE
      INDEX BY BINARY_INTEGER;
      
      TYPE shp_to_org_id_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.to_organization_id%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE hdr_exp_date_tbl_type IS TABLE OF XX_PO_ASN_HDR_CONV_STG.expected_receipt_date%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE vendor_name_tbl_type IS TABLE OF XX_PO_ASN_HDR_CONV_STG.vendor_name%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE item_id_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.item_id%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE item_desc_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.item_description%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE po_line_id_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.po_line_id%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE po_line_locn_id_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.po_line_location_id%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE po_distr_id_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.po_distribution_id%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE po_dest_type_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.destination_type_code%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE uom_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.unit_of_measure%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE dtl_exp_date_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.expected_receipt_date%TYPE
      INDEX BY BINARY_INTEGER;

      TYPE po_header_id_tbl_type IS TABLE OF XX_PO_ASN_DTL_CONV_STG.po_header_id%TYPE
      INDEX BY BINARY_INTEGER;

      -- ----------------------------------------
      -- Variable Declaration for the table types
      -- ----------------------------------------

      lt_vend_id             vend_id_tbl_type ;
      lt_vend_site_id        vend_site_id_tbl_type ;
      lt_locn_hdr_id         locn_id_tbl_type ;
      lt_locn_dtl_id         locn_id_tbl_type ;
      lt_shp_to_org_hdr_id   shp_to_org_id_tbl_type ;
      lt_shp_to_org_dtl_id   shp_to_org_id_tbl_type ;
      lt_hdr_exp_date        hdr_exp_date_tbl_type ;
      lt_vndr_name           vendor_name_tbl_type ;
      lt_item_id             item_id_tbl_type ;
      lt_item_desc           item_desc_tbl_type;
      lt_po_line_id          po_line_id_tbl_type;
      lt_po_line_locn_id     po_line_locn_id_tbl_type;
      lt_po_distri_id        po_distr_id_tbl_type ;
      lt_po_dest_type_code   po_dest_type_tbl_type ;
      lt_uom                 uom_tbl_type;
      lt_dtl_exp_date        dtl_exp_date_tbl_type;
      lt_po_header_id        po_header_id_tbl_type;
      lt_hdr_ctrl_id         hdr_ctrl_id_tbl_type;
      lt_dtl_ctrl_id         dtl_ctrl_id_tbl_type;
      lt_hdr_row_id          row_id_tbl_type;
      lt_dtl_row_id          row_id_tbl_type;
      lt_hdr_prss_flag       hdr_prss_flg_tbl_type;
      lt_dtl_prss_flag       dtl_prss_flg_tbl_type;
      lt_hdr_err_msg         hdr_err_msg_tbl_type;
      lt_dtl_err_msg         dtl_err_msg_tbl_type;

      -- ---------------------------------------------------------------------------------------------------
      -- Cursor to fetch the validation in progress records for a particular batch from header staging table
      -- ---------------------------------------------------------------------------------------------------

      CURSOR lcu_asn_hdr
      IS
      SELECT XPAHCS.*,
             XPAHCS.ROWID
      FROM   xx_po_asn_hdr_conv_stg  XPAHCS
      WHERE  XPAHCS.process_flag  = 2
      AND    XPAHCS.batch_id      = p_batch_id ;

      -- ----------------------------------------------------------------------------------------------------
      -- Cursor to fetch the validation in progress records for a particular batch from details staging table
      -- ----------------------------------------------------------------------------------------------------

      CURSOR lcu_asn_trx (ln_record_id IN  NUMBER)
      IS
      SELECT XPADCS.*,
             XPADCS.ROWID
      FROM   xx_po_asn_dtl_conv_stg   XPADCS
            ,xx_po_asn_hdr_conv_stg   XPAHCS
      WHERE  XPADCS.process_flag        = 2
      AND    XPADCS.batch_id            = p_batch_id
      AND    XPADCS.parent_record_id    = XPAHCS.record_id
      AND    XPADCS.parent_record_id    = ln_record_id ;

      -- --------------------------------
      -- Type declarations of cursor type
      -- --------------------------------

      TYPE hdr_stg_rec_tbl_type IS TABLE OF lcu_asn_hdr%ROWTYPE
      INDEX BY BINARY_INTEGER;
      lt_hdr_stg_record  hdr_stg_rec_tbl_type;

      TYPE dtl_stg_rec_tbl_type IS TABLE OF lcu_asn_trx%ROWTYPE
      INDEX BY BINARY_INTEGER;
      lt_dtl_stg_record  dtl_stg_rec_tbl_type;

      -- ---------------------------------------------------
      -- Cursor to update the process_flag of header table
      -- ---------------------------------------------------

      CURSOR lcu_update_table
      IS
      SELECT XPAHCS.*
      FROM   XX_PO_ASN_HDR_CONV_STG XPAHCS
      WHERE  XPAHCS.batch_id     = p_batch_id
      AND    XPAHCS.process_flag = 5;

      -- --------------------------------
      -- Cursor to get the vendor details
      -- --------------------------------
      CURSOR lcu_get_vendor_dtls(p_ven_num VARCHAR2)
      IS
      SELECT   PVSA.vendor_id,
               PVSA.vendor_site_id,
               PV.vendor_name
      FROM     po_vendor_sites_all  PVSA
              ,po_vendors PV
      WHERE    PVSA.attribute9           = p_ven_num
      AND      PVSA.vendor_id            = PV.vendor_id
      AND      PVSA.purchasing_site_flag = 'Y';

      -- --------------------------------
      -- Cursor to get the header details
      -- --------------------------------

      CURSOR lcu_get_header_dtls(p_po_num      VARCHAR2 ,
                                 p_ven_id      NUMBER ,
                                 p_ven_site_id NUMBER )
      IS
      SELECT  POH.po_header_id
             ,POH.ship_to_location_id
      FROM    po_headers_all POH
      WHERE   POH.segment1                =  p_po_num
      AND     POH.type_lookup_code        = 'STANDARD'
      AND     NVL(POH.closed_code,'OPEN') = 'OPEN'
      AND     POH.vendor_id               =  p_ven_id
      AND     POH.vendor_site_id          =  p_ven_site_id;

      -- ------------------------------
      -- Cursor to get the item details
      -- ------------------------------

      CURSOR  lcu_get_item_dtls(p_item_num VARCHAR2 )
      IS
      SELECT  MSIB.inventory_item_id,
              MSIB.description
      FROM    mtl_system_items_b MSIB
             ,mtl_parameters     MP
      WHERE   MSIB.segment1        = p_item_num
      AND     MSIB.organization_id = MP.organization_id
      AND     ROWNUM               = 1;

      -- -------------------------------
      -- Cursor to get the line details
      -- -------------------------------

      CURSOR lcu_get_line_dtls(p_header_id NUMBER ,
                               p_item_id   NUMBER
                              )
      IS
      SELECT  POL.po_line_id
             ,PLL.line_location_id
             ,POL.unit_meas_lookup_code
             ,PLL.promised_date
             ,PLL.ship_to_organization_id
      FROM    mtl_system_items_b     MSIB
             ,po_lines_all           POL
             ,po_line_locations_all  PLL
      WHERE   MSIB.organization_id   = PLL.ship_to_organization_id
      AND     POL.po_line_id         = PLL.po_line_id
      AND     POL.po_header_id       = p_header_id
      AND     MSIB.inventory_item_id = POL.item_id
      AND     MSIB.inventory_item_id = p_item_id;

      -- ---------------------------------------------
      -- Cursor to get the  destination type code
      -- There would be only one distribution against
      -- each PO line
      -- ---------------------------------------------

      CURSOR  lcu_get_distri_dtls(p_header_id NUMBER)
      IS
      SELECT  PDA.po_distribution_id
             ,PDA.destination_type_code
      FROM    po_distributions_all PDA
      WHERE   PDA.po_header_id  = p_header_id;

     BEGIN     

        -- -------------------------
        -- Clear the table type data
        -- -------------------------
        lt_hdr_prss_flag.DELETE;
        lt_hdr_err_msg.DELETE;
        lt_vend_id.DELETE;
        lt_vend_site_id.DELETE;
        lt_locn_hdr_id.DELETE;
        lt_shp_to_org_hdr_id.DELETE;
        lt_hdr_exp_date.DELETE;
        lt_vndr_name.DELETE;
        lt_hdr_row_id.DELETE;

        gc_debug_flag:= p_debug_flag;
        gn_child_request_id := FND_GLOBAL.CONC_REQUEST_ID ;

        display_log('Child Program launched with the batch_id :'||p_batch_id );        
        display_log('Child Program launched with the Request id :'||gn_child_request_id);

        -- ---------------------
        -- Reprocess the records
        -- ---------------------
        IF NVL(p_reset_status_flag,'N') <>'N' THEN

           display_log('Records are in reprocessing state: ' ||p_batch_id);

           update_child_batch_id(p_batch_id
                                ,x_errbuf
                                ,x_retcode
                                 );
        END IF;

        -- ----------------------
        -- Get the conversion_id
        -- ----------------------
        get_conversion_id
                        (
                        x_conversion_id  => gn_conversion_id
                       ,x_return_status  => lc_return_status
                        );

        IF lc_return_status = 'S' THEN

           -- -----------------
           -- ASN Header level
           -- -----------------
           OPEN  lcu_asn_hdr ;
           FETCH lcu_asn_hdr BULK COLLECT INTO lt_hdr_stg_record;
           CLOSE lcu_asn_hdr;           

           display_log(' Total header records to be processed '||lt_hdr_stg_record.COUNT);
           IF lt_hdr_stg_record.count = 0 THEN
              RAISE EX_NO_DATA_FOUND_STG;
           ELSE              
              lc_dtl_exists_flag := 'N';
              FOR hdr_loop IN lt_hdr_stg_record.FIRST .. lt_hdr_stg_record.LAST /* Start of ASN Header level LOOP*/
              LOOP 
                 display_log('Start of ASN Header level validations '|| hdr_loop);
                 lt_hdr_ctrl_id(hdr_loop)    := lt_hdr_stg_record(hdr_loop).control_id;
                 lt_hdr_row_id(hdr_loop)     := lt_hdr_stg_record(hdr_loop).ROWID;
                 lc_header_message           :=  NULL;

                 lt_dtl_prss_flag.DELETE;
                 lt_dtl_err_msg.DELETE;
                 lt_item_id.DELETE;
                 lt_item_desc.DELETE;
                 lt_po_line_id.DELETE;
                 lt_po_line_locn_id.DELETE;
                 lt_po_distri_id.DELETE;
                 lt_po_dest_type_code.DELETE;
                 lt_shp_to_org_dtl_id.DELETE;
                 lt_uom.DELETE;
                 lt_dtl_exp_date.DELETE;
                 lt_po_header_id.DELETE;
                 lt_locn_dtl_id.DELETE;
                 lt_dtl_row_id.DELETE;

                 -- -----------------------------------------------
                 -- Derive the vendor_id,vendor_site_id,vendor_name
                 -- -----------------------------------------------
                 
                 OPEN lcu_get_vendor_dtls(lt_hdr_stg_record(hdr_loop).vendor_num);
                 FETCH lcu_get_vendor_dtls INTO  ln_vendor_id
                                                ,ln_vendor_site_id
                                                ,lc_vendor_name;
                     IF lcu_get_vendor_dtls%NOTFOUND
                     OR ln_vendor_site_id IS NULL

                     THEN
                     
                         lc_vendor_flag              :='N' ;
                         lt_vend_id(hdr_loop)        := 0  ;
                         lt_vend_site_id(hdr_loop)   := 0  ;
                         lt_vndr_name(hdr_loop)      := NULL  ;
                         fnd_message.set_name('XXPTP','XX_PO_60003_SUPPLIER_INVALID');
                         x_errbuf := fnd_message.get;
                         lc_header_message := SUBSTR(lc_header_message||x_errbuf,1,4000);
                         -- ----------------------------
                         --Adding error message to stack
                         -- ----------------------------                         
                        log_procedure(
                                  p_control_id           => lt_hdr_ctrl_id(hdr_loop),
                                  p_source_system_code   => NULL,
                                  p_procedure_name       => 'CHILD_MAIN',
                                  p_staging_table_name   => 'XX_PO_ASN_HDR_CONV_STG',
                                  p_staging_column_name  => 'VENDOR_NUM',
                                  p_staging_column_value => lt_hdr_stg_record(hdr_loop).vendor_num,
                                  p_source_system_ref    => NULL,
                                  p_batch_id             => p_batch_id,
                                  p_exception_log        => NULL,
                                  p_oracle_error_code    => NULL,
                                  p_oracle_error_msg     => x_errbuf
                                 );
                     ELSE                     
                         lt_vend_id(hdr_loop)        := ln_vendor_id      ;
                         lt_vend_site_id(hdr_loop)   := ln_vendor_site_id ;
                         lt_vndr_name(hdr_loop)      := lc_vendor_name    ;
                         lc_vendor_flag              :='Y' ;

                     END IF;
                 CLOSE lcu_get_vendor_dtls;

                 -- ----------------------------------------
                 -- Derive the header_id,ship_to_location_id
                 -- ----------------------------------------                 
                 OPEN lcu_get_header_dtls(lt_hdr_stg_record(hdr_loop).legacy_po_nbr
                                         ,ln_vendor_id
                                         ,ln_vendor_site_id
                                         );
                 FETCH lcu_get_header_dtls INTO ln_header_id,ln_ship_to_location_id;
                 
                 IF lcu_get_header_dtls%NOTFOUND OR ln_header_id IS NULL
                 THEN                     
                         lc_header_flag            :='N';
                         lt_locn_hdr_id(hdr_loop)  := 0 ;
                         fnd_message.set_name('XXPTP','XX_PO_60001_NO_PO');
                         fnd_message.set_token('SKU',to_char(NVL(ln_item_id,NULL)));
                         fnd_message.set_token('SUPPLIER',to_char(NVL(ln_vendor_id,NULL)));
                         fnd_message.set_token('SITE'    ,to_char(NVL(ln_vendor_site_id,NULL)));
                         x_errbuf := fnd_message.get;
                         lc_header_message:= SUBSTR(lc_header_message||x_errbuf,1,4000);
                         lc_line_message  := SUBSTR(lc_line_message||x_errbuf,1,4000);
                         -- -----------------------------
                         -- Adding error message to stack
                         -- -----------------------------
                         log_procedure(
                                   p_control_id           => lt_hdr_ctrl_id(hdr_loop),
                                   p_source_system_code   => NULL,
                                   p_procedure_name       => 'CHILD_MAIN',
                                   p_staging_table_name   => 'XX_PO_ASN_HDR_CONV_STG',
                                   p_staging_column_name  => 'LEGACY_PO_NBR',
                                   p_staging_column_value => lt_hdr_stg_record(hdr_loop).legacy_po_nbr,
                                   p_source_system_ref    => NULL,
                                   p_batch_id             => p_batch_id,
                                   p_exception_log        => NULL,
                                   p_oracle_error_code    => NULL,
                                   p_oracle_error_msg     => x_errbuf
                                  );
                     ELSE
                     
                         lt_locn_hdr_id(hdr_loop)  := ln_ship_to_location_id;
                         lc_header_flag            :='Y';
                     END IF;
                 CLOSE lcu_get_header_dtls;                 

                 -- -------------------------
                 -- ASN Trx level derivations
                 -- -------------------------

                 lc_line_flag  := 'Y';
                 lc_item_flag  := 'Y';
                 lc_dest_flag  := 'Y';                
                 
                 ln_cntr:= 0;

                 OPEN  lcu_asn_trx (lt_hdr_stg_record(hdr_loop).record_id);
                 FETCH lcu_asn_trx BULK COLLECT INTO lt_dtl_stg_record LIMIT G_LIMIT_SIZE;
                 CLOSE lcu_asn_trx;

                 IF lt_dtl_stg_record.count > 0 THEN

                    

                    FOR dtl_loop IN lt_dtl_stg_record.FIRST .. lt_dtl_stg_record.LAST /* Start of ASN trx level LOOP*/
                    LOOP                       
                    
                       lt_dtl_ctrl_id(dtl_loop)       := lt_dtl_stg_record(dtl_loop).control_id;
                       lt_dtl_row_id(dtl_loop)        := lt_dtl_stg_record(dtl_loop).ROWID;
                       lc_line_message                := '';

                       IF ln_header_id IS NOT NULL AND ln_ship_to_location_id IS NOT NULL THEN
                          lt_po_header_id(dtl_loop)      := ln_header_id;
                          lt_locn_dtl_id(dtl_loop)       := ln_ship_to_location_id;
                       ELSE
                          lt_po_header_id(dtl_loop)      := 0 ;
                          lt_locn_dtl_id(dtl_loop)       := 0 ;
                       END IF;

                       lc_dtl_exists_flag := 'Y' ;

                       display_log('Records are in Validation state ');

                       -- ---------------------------------------------
                       -- Derive the inventory_item_id,item_description
                       -- ---------------------------------------------   
                       display_log('Item under validation is: '||lt_dtl_stg_record(dtl_loop).item_num);
                       OPEN lcu_get_item_dtls(lt_dtl_stg_record(dtl_loop).item_num);
                       FETCH lcu_get_item_dtls INTO ln_item_id,
                                                    lc_description;                                                    

                           IF lcu_get_item_dtls%NOTFOUND
                           OR ln_item_id IS NULL
                           THEN                          
                               lc_item_flag:='N';
                               lt_item_id(dtl_loop)  :=0;
                               lt_item_desc(dtl_loop):=NULL;

                               fnd_message.set_name('XXPTP','XX_PO_60002_SKU_INVALID');
                               fnd_message.set_token('SKU',lt_dtl_stg_record(dtl_loop).item_NUM);
                               x_errbuf := fnd_message.get  ;
                               lc_line_message:=lc_line_message||x_errbuf;

                               -- -----------------------------
                               -- Adding error message to stack
                               -- -----------------------------
                              log_procedure(
                                        p_control_id           => lt_dtl_ctrl_id(dtl_loop),
                                        p_source_system_code   => NULL,
                                        p_procedure_name       => 'CHILD_MAIN',
                                        p_staging_table_name   => 'XX_PO_ASN_DTL_CONV_STG',
                                        p_staging_column_name  => 'ITEM_NUM',
                                        p_staging_column_value => lt_dtl_stg_record(dtl_loop).item_num,
                                        p_source_system_ref    => NULL,
                                        p_batch_id             => p_batch_id,
                                        p_exception_log        => NULL,
                                        p_oracle_error_code    => NULL,
                                        p_oracle_error_msg     => x_errbuf
                                       );
                           ELSE
                               lt_item_id(dtl_loop)  :=ln_item_id;
                               lt_item_desc(dtl_loop):=lc_description;

                           END IF;
                       CLOSE lcu_get_item_dtls;

                       -- --------------------------------------------------------------------------
                       -- Derive the line_id,line_location_id,uom_code,promised_date,organization_id
                       -- --------------------------------------------------------------------------                        
                       display_log('PO Header id under process is : '|| ln_header_id);
                       OPEN lcu_get_line_dtls(ln_header_id,
                                              ln_item_id);

                       FETCH lcu_get_line_dtls INTO  ln_line_id
                                                    ,ln_line_locn_id
                                                    ,lc_uom_code
                                                    ,ln_promised_date
                                                    ,ln_organization_id;

                           IF lcu_get_line_dtls%NOTFOUND
                           OR ln_line_id IS NULL
                           THEN

                               lc_line_flag :='N';
                               lt_po_line_id(dtl_loop)          := 0;
                               lt_po_line_locn_id(dtl_loop)     := 0;
                               lt_uom(dtl_loop)                 := 0;
                               lt_hdr_exp_date(hdr_loop)        := NULL;
                               lt_dtl_exp_date(dtl_loop)        := NULL;
                               lt_shp_to_org_hdr_id(hdr_loop)   := 0;
                               lt_shp_to_org_dtl_id(dtl_loop)   := 0;
                               fnd_message.set_name('XXPTP','XX_PO_60001_NO_PO');
                               fnd_message.set_token('SKU',ln_item_id);
                               fnd_message.set_token('SUPPLIER',to_char(NVL(ln_vendor_id,NULL)));
                               fnd_message.set_token('SITE'    ,to_char(NVL(ln_vendor_site_id,NULL)));
                                                        
                               x_errbuf := fnd_message.get;
                               lc_header_message := SUBSTR(lc_header_message||x_errbuf,1,4000);
                               lc_line_message   := SUBSTR(lc_line_message||x_errbuf,1,4000);

                               -- -----------------------------
                               -- Adding error message to stack
                               -- -----------------------------
                               log_procedure(
                                             p_control_id           => lt_dtl_ctrl_id(dtl_loop),
                                             p_source_system_code   => NULL,
                                             p_procedure_name       => 'CHILD_MAIN',
                                             p_staging_table_name   => 'XX_PO_ASN_DTL_CONV_STG',
                                             p_staging_column_name  => 'LEGACY_PO_NBR',
                                             p_staging_column_value => lt_hdr_stg_record(hdr_loop).legacy_po_nbr||'-'||lt_dtl_stg_record(dtl_loop).item_num,
                                             p_source_system_ref    => NULL,
                                             p_batch_id             => p_batch_id,
                                             p_exception_log        => NULL,
                                             p_oracle_error_code    => NULL,
                                             p_oracle_error_msg     => x_errbuf
                                            );
                           ELSE

                               lt_po_line_id(dtl_loop)         := ln_line_id;
                               lt_po_line_locn_id(dtl_loop)    := ln_line_locn_id;
                               lt_uom(dtl_loop)                := lc_uom_code;
                               lt_hdr_exp_date(hdr_loop)       := ln_promised_date;
                               lt_dtl_exp_date(dtl_loop)       := ln_promised_date;
                               lt_shp_to_org_hdr_id(hdr_loop)  := ln_organization_id;
                               lt_shp_to_org_dtl_id(dtl_loop)  := ln_organization_id;

                           END IF;
                       CLOSE lcu_get_line_dtls;

                       -- ------------------------------------------------
                       -- Derive the distribution_id,destination_type_code
                       -- ------------------------------------------------ 
                       display_log('Validate distribution ');
                       OPEN lcu_get_distri_dtls(ln_header_id);
                       FETCH lcu_get_distri_dtls INTO  ln_distribution_id
                                                      ,lc_dest_type_code;
                           IF lcu_get_distri_dtls%NOTFOUND
                           OR lc_dest_type_code IS NULL
                           THEN
                               lc_dest_flag:='N';
                               lt_po_distri_id(dtl_loop)     :=0;
                               lt_po_dest_type_code(dtl_loop):=0;
                               fnd_message.set_name('XXPTP','XX_PO_60004_DEST_INVALID');
                               x_errbuf := fnd_message.get  ;
                               lc_line_message := SUBSTR(lc_line_message||x_errbuf,1,4000);
                               -- -----------------------------
                               -- Adding error message to stack
                               -- -----------------------------                               
                               log_procedure(
                                         p_control_id           => lt_dtl_ctrl_id(dtl_loop),
                                         p_source_system_code   => NULL,
                                         p_procedure_name       => 'CHILD_MAIN',
                                         p_staging_table_name   => 'XX_PO_ASN_DTL_CONV_STG',
                                         p_staging_column_name  => 'LEGACY_PO_NBR',
                                         p_staging_column_value => lt_hdr_stg_record(hdr_loop).legacy_po_nbr,
                                         p_source_system_ref    => NULL,
                                         p_batch_id             => p_batch_id,
                                         p_exception_log        => NULL,
                                         p_oracle_error_code    => NULL,
                                         p_oracle_error_msg     => x_errbuf
                                        );
                           ELSE
                               lt_po_distri_id(dtl_loop)     :=ln_distribution_id;
                               lt_po_dest_type_code(dtl_loop):=lc_dest_type_code;

                           END IF;
                       CLOSE lcu_get_distri_dtls;
                       
                       ln_cntr:= ln_cntr +1;                       

                      lt_dtl_err_msg(dtl_loop) := lc_line_message ;
                       -- -----------------------------
                       -- Re Initializing the variables
                       -- -----------------------------

                       ln_item_id             := NULL;
                       ln_line_id             := NULL;
                       ln_organization_id     := NULL;                       

                    END LOOP;/* End of ASN trx level LOOP*/
                    
                    
                    ln_header_id           := NULL;
                    ln_vendor_id           := NULL;
                    ln_vendor_site_id      := NULL;
                    ln_ship_to_location_id := NULL;

                    -- ------------------
                    -- Validation Success
                    -- ------------------

                    IF      lc_vendor_flag = 'Y'
                        AND lc_header_flag = 'Y'
                        AND lc_line_flag   = 'Y'
                        AND lc_item_flag   = 'Y'
                        AND lc_dest_flag   = 'Y'
                    THEN
                    display_log('All Success ');
                        lt_hdr_prss_flag(hdr_loop)   := 4;
                        ln_dtl_prss_flag             := 4;
                        lt_hdr_err_msg(hdr_loop)     := NULL;
                    -- ------------------
                    -- Validation Failure
                    -- ------------------

                    ELSE
                        display_log('Some records failed for - '||lc_header_message );

                        lt_hdr_prss_flag(hdr_loop)   := 3;
                        ln_dtl_prss_flag             := 3;
                        lt_hdr_err_msg(hdr_loop)     := lc_header_message ;

                    END IF;
                    -- ---------------------------
                    -- Header staging table update
                    -- ---------------------------

                    IF lc_dtl_exists_flag = 'Y' THEN

                      display_log('Updating Detail staging table with validated results');

                      FORALL dtl_loop IN lt_dtl_stg_record.FIRST..lt_dtl_stg_record.LAST
                       UPDATE XX_PO_ASN_DTL_CONV_STG XPADCS
                       SET    XPADCS.process_flag          = ln_dtl_prss_flag,
                              error_message                = lt_dtl_err_msg(dtl_loop),
                              XPADCS.item_id               = lt_item_id(dtl_loop),
                              XPADCS.item_description      = lt_item_desc(dtl_loop) ,
                              XPADCS.po_line_id            = lt_po_line_id(dtl_loop),
                              XPADCS.po_line_location_id   = lt_po_line_locn_id(dtl_loop),
                              XPADCS.po_distribution_id    = lt_po_distri_id(dtl_loop),
                              XPADCS.destination_type_code = lt_po_dest_type_code(dtl_loop),
                              XPADCS.to_organization_id    = lt_shp_to_org_dtl_id(dtl_loop),
                              XPADCS.unit_of_measure       = lt_uom(dtl_loop),
                              XPADCS.expected_receipt_date = lt_dtl_exp_date(dtl_loop),
                              XPADCS.po_header_id          = lt_po_header_id(dtl_loop),
                              XPADCS.location_id           = lt_locn_dtl_id(dtl_loop)
                       WHERE  XPADCS.rowid                 = lt_dtl_row_id(dtl_loop);

                    END IF;                   

                    IF lt_hdr_prss_flag(hdr_loop)    = 4 THEN
                       ln_hdr_val_success           := ln_hdr_val_success + 1 ;
                       ln_dtl_val_success           := ln_dtl_val_success +ln_cntr ;
                    ELSIF lt_hdr_prss_flag(hdr_loop) = 3 THEN
                       ln_hdr_val_failed            := ln_hdr_val_failed + 1 ;
                       ln_dtl_val_failed            := ln_dtl_val_failed +ln_cntr;
                    END IF;

                 END IF;
                 display_log('The header loop counter is '|| hdr_loop);
              END LOOP; /* End of ASN Header level LOOP*/

            ------------------------------------------------------------------------
            --Invoke Common Conversion API to Bulk Insert the Trnsaction Data Errors
            -------------------------------------------------------------------------
              
              display_log('Logging error Vikas ');            
--              XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

              -- ---------------------------
              -- Header staging table update
              -- ---------------------------

              IF lc_dtl_exists_flag = 'Y' THEN

                 display_log('Updating Header staging table with validated results: '||lt_hdr_stg_record.COUNT);

                 FORALL ln_hdr_loop1 IN lt_hdr_stg_record.FIRST..lt_hdr_stg_record.LAST
                 UPDATE XX_PO_ASN_HDR_CONV_STG XPAHCS
                 SET    XPAHCS.process_flag            = lt_hdr_prss_flag(ln_hdr_loop1),
                        XPAHCS.error_message           = lt_hdr_err_msg(ln_hdr_loop1),
                        XPAHCS.vendor_id               = lt_vend_id(ln_hdr_loop1),
                        XPAHCS.vendor_site_id          = lt_vend_site_id(ln_hdr_loop1),
                        XPAHCS.location_id             = lt_locn_hdr_id(ln_hdr_loop1),
                        XPAHCS.ship_to_organization_id = lt_shp_to_org_hdr_id(ln_hdr_loop1),
                        XPAHCS.expected_receipt_date   = lt_hdr_exp_date(ln_hdr_loop1),
                        XPAHCS.vendor_name             = lt_vndr_name(ln_hdr_loop1)
                 WHERE  XPAHCS.ROWID                   = lt_hdr_row_id(ln_hdr_loop1);  
                 
              display_log('validate '|| p_validate_only_flag);
              display_log('Success count : '||ln_hdr_val_success);

              IF ln_hdr_val_success > 0 THEN

                 -- ---------------------------------------------
                 -- If the validated records need to be processed
                 -- Set the Id value with seeded sequence so as 
                 -- to create a link between stage and RCV tables.
                 -- ---------------------------------------------

                 IF p_validate_only_flag ='N' THEN
                                     
                    UPDATE  XX_PO_ASN_HDR_CONV_STG
                    SET     process_flag        = 5
                           ,header_interface_id = RCV_HEADERS_INTERFACE_S.NEXTVAL
                    WHERE   process_flag        = 4
                    AND     batch_id            = p_batch_id;
                    
                    lc_proc_flag  := 'Y';

                    FOR cur_var IN lcu_update_table
                    LOOP

                       UPDATE  XX_PO_ASN_DTL_CONV_STG
                       SET     process_flag             = 5
                              ,header_interface_id      = cur_var.header_interface_id
                              ,interface_transaction_id = RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL
                       WHERE   parent_record_id         = cur_var.record_id;
                       
                       lc_proc_flag  := 'Y';

                    END LOOP;                      
                                          
                    IF lc_proc_flag = 'Y' THEN

                       -- ---------------------------------------
                       -- Calling insert_into_interface procedure
                       -- ---------------------------------------
                       display_log('Insert into Interface table for batch '||p_batch_id); 

                       insert_into_interface(
                                             p_batch_id      => p_batch_id
                                            ,x_errbuf        => lx_errbuf
                                            ,x_retcode       => lx_retcode
                                            );

                       IF lx_retcode <> 0 THEN
                         x_retcode := lx_retcode;
                         CASE WHEN x_errbuf IS NULL
                         THEN x_errbuf  := lx_errbuf;
                         ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
                         END CASE;
                       END IF;

                       -- -----------------------------
                       -- Calling process_asn procedure
                       -- -----------------------------
                       
                       display_log('Process_asn to call RVCTP for batch '||p_batch_id);
                       process_asn
                                 (
                                   x_errbuf           => lx_errbuf
                                 , x_retcode          => lx_retcode
                                 , x_pro_hdr_succ     => ln_hdr_proc_success
                                 , x_pro_hdr_failed   => ln_hdr_proc_failed
                                 , x_pro_dtl_succ     => ln_dtl_proc_success
                                 , x_pro_dtl_failed   => ln_dtl_proc_failed
                                 , p_group_id         => p_batch_id
                                 );
                       display_log('Post Processing');
                        IF lx_retcode <> 0 THEN
                           x_retcode := lx_retcode;
                           CASE WHEN x_errbuf IS NULL
                           THEN x_errbuf  := lx_errbuf;
                            ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
                           END CASE;
                        END IF;

                 END IF;

              END IF;

           END IF;

         END IF;

      END IF;

      -- ------------------------------------------------------------------------------------------------
      -- Gets the master request Id which needs to be passed while updating Control Information Log Table
      -- ------------------------------------------------------------------------------------------------

      display_log('get_master_request_id ');
      get_master_request_id(
                            p_conversion_id      => gn_conversion_id
                           ,p_batch_id           => p_batch_id
                           ,x_master_request_id  => ln_master_request_id
                           ,x_return_status      => lc_return_status
                           );

      IF lc_return_status = 'S' THEN

         ---------------------------------------------------------------------------------------------
         -- XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc is called over
         -- to log the exception of the record while processing
         ---------------------------------------------------------------------------------------------

         XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                                                        p_conc_mst_req_id             => ln_master_request_id,
                                                        p_batch_id                    => p_batch_id,
                                                        p_conversion_id               => gn_conversion_id,
                                                        p_num_bus_objs_failed_valid   => ln_hdr_val_failed,
                                                        p_num_bus_objs_failed_process => ln_hdr_proc_failed,
                                                        p_num_bus_objs_succ_process   => ln_hdr_proc_success
                                                       );

         ------------------------------------------------------
         --Displaying the PO Header Information in the Out file
         ------------------------------------------------------
         ln_header_total := ln_hdr_proc_success + ln_hdr_proc_failed + ln_hdr_val_failed;
         display_out(RPAD('=',58,'='));
         display_out(RPAD('Total No. Of ASN Header Records      : ',49,' ')||RPAD(ln_header_total,9,' '));
         display_out(RPAD('No. Of ASN Header Records Processed  : ',49,' ')||RPAD(ln_hdr_proc_success,9,' '));
         display_out(RPAD('No. Of ASN Header Records Errored    : ',49,' ')||RPAD(ln_hdr_proc_failed+ln_hdr_val_failed,9,' '));
         display_out(RPAD('=',58,'='));

         ---------------------------------------------------
         --Displaying the PO Line Information in the Out file
         ----------------------------------------------------
         ln_line_total := ln_dtl_proc_success + ln_dtl_proc_failed + ln_dtl_val_failed;         

         display_out(RPAD('=',58,'='));
         display_out(RPAD('Total No. Of ASN Line Records      : ',49,' ')||RPAD(ln_line_total,9,' '));
         display_out(RPAD('No. Of ASN Line Records Processed  : ',49,' ')||RPAD(ln_dtl_proc_success,9,' '));
         display_out(RPAD('No. Of ASN Line Records Errored    : ',49,' ')||RPAD(ln_dtl_proc_failed+ln_dtl_val_failed,9,' '));
         display_out(RPAD('=',58,'='));

      ELSIF lc_return_status = 'E' THEN

            log_procedure(
                          p_control_id            => NULL,
                          p_source_system_code    => NULL,
                          p_procedure_name        => 'GET_MASTER_REQUEST_ID',
                          p_staging_table_name    => NULL,
                          p_staging_column_name   => NULL,
                          p_staging_column_value  => NULL,
                          p_source_system_ref     => NULL,
                          p_batch_id              => p_batch_id,
                          p_exception_log         => 'Master request id is null for this batch',
                          p_oracle_error_code     => NULL,
                          p_oracle_error_msg      => NULL
                         );
      ELSIF lc_return_status = 'N' THEN

            log_procedure(
                          p_control_id            => NULL,
                          p_source_system_code    => NULL,
                          p_procedure_name        => 'GET_MASTER_REQUEST_ID',
                          p_staging_table_name    => NULL,
                          p_staging_column_name   => NULL,
                          p_staging_column_value  => NULL,
                          p_source_system_ref     => NULL,
                          p_batch_id              => p_batch_id,
                          p_exception_log         => NULL,
                          p_oracle_error_code     => NULL,
                          p_oracle_error_msg      => SUBSTR(SQLERRM,1,200)
                         );

      END IF;

      ELSIF lc_return_status = 'E' THEN

            log_procedure(
                          p_control_id            => NULL,
                          p_source_system_code    => NULL,
                          p_procedure_name        => 'GET_CONVERSION_ID',
                          p_staging_table_name    => NULL,
                          p_staging_column_name   => NULL,
                          p_staging_column_value  => NULL,
                          p_source_system_ref     => NULL,
                          p_batch_id              => p_batch_id,
                          p_exception_log         => 'There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code C0273_MerchHierarchy',
                          p_oracle_error_code     => NULL,
                          p_oracle_error_msg      => NULL
                         );

       ELSIF lc_return_status = 'N' THEN

              log_procedure(
                            p_control_id            => NULL,
                            p_source_system_code    => NULL,
                            p_procedure_name        => 'GET_CONVERSION_ID',
                            p_staging_table_name    => NULL,
                            p_staging_column_name   => NULL,
                            p_staging_column_value  => NULL,
                            p_source_system_ref     => NULL,
                            p_batch_id              => p_batch_id,
                            p_exception_log         => NULL,
                            p_oracle_error_code     => NULL,
                            p_oracle_error_msg      => SUBSTR(SQLERRM,1,200)
                           );


       END IF;

       -------------------------------------------------
       -- Launch the Exception Log Report for this batch
       -------------------------------------------------
       display_log('Launch exception report for child request '||gn_child_request_id);
       launch_exception_report(
                               p_batch_id         =>p_batch_id                    -- Batch id
                              ,p_conc_req_id      =>gn_child_request_id           -- Child Request id
                              ,p_master_req_id    =>NULL                          -- Master Request id
                              ,x_errbuf           =>lx_errbuf
                              ,x_retcode          =>lx_retcode
                              );

       IF lx_retcode <> 0 THEN
           x_retcode := lx_retcode;
           CASE WHEN x_errbuf IS NULL
                THEN x_errbuf  := lx_errbuf;
           ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
           END CASE;
       END IF;

       IF lc_return_status <> 'S' THEN
         x_retcode := 2;
       END IF;
       
       display_log('Logging error Vikas ');            
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

       COMMIT;

   -- --------------------------
   -- Handling Exceptions
   -- --------------------------
   EXCEPTION

      WHEN EX_EXCEPTION_SMRY_REPRT THEN

         x_retcode := 1;
         x_errbuf  :='Error in Submitting Processing Summary Report';

          log_procedure(
                               p_control_id           => NULL,
                               p_source_system_code   => NULL,
                               p_procedure_name       => 'CHILD_MAIN',
                               p_staging_table_name   => NULL,
                               p_staging_column_name  => NULL,
                               p_staging_column_value => NULL,
                               p_source_system_ref    => NULL,
                               p_batch_id             => p_batch_id,
                               p_exception_log        => NULL,
                               p_oracle_error_code    => SQLCODE,
                               p_oracle_error_msg     => SUBSTR(SQLERRM,1,200)
                       );
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

      WHEN EX_NO_DATA_FOUND_STG THEN

         x_retcode:=1;
         x_errbuf  :='No data found in the staging table  XX_PO_ASN_HDR_CONV_STG';

          log_procedure(
                               p_control_id           => NULL,
                               p_source_system_code   => NULL,
                               p_procedure_name       => 'CHILD_MAIN',
                               p_staging_table_name   => NULL,
                               p_staging_column_name  => NULL,
                               p_staging_column_value => NULL,
                               p_source_system_ref    => NULL,
                               p_batch_id             => p_batch_id,
                               p_exception_log        => x_errbuf,
                               p_oracle_error_code    => NULL,
                               p_oracle_error_msg     => NULL
                       );

      XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

      WHEN NO_DATA_FOUND THEN

         x_retcode := 1;
         x_errbuf  := 'No Data Found Exception Raised'||SUBSTR(SQLERRM,1,200);

          log_procedure(
                               p_control_id           => NULL,
                               p_source_system_code   => NULL,
                               p_procedure_name       => 'CHILD_MAIN',
                               p_staging_table_name   => NULL,
                               p_staging_column_name  => NULL,
                               p_staging_column_value => NULL,
                               p_source_system_ref    => NULL,
                               p_batch_id             => p_batch_id,
                               p_exception_log        => x_errbuf,
                               p_oracle_error_code    => NULL,
                               p_oracle_error_msg     => NULL
                       );

      XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

      WHEN OTHERS THEN

         x_errbuf  := 'Unexpected Exception is raised in Procedure child_main '||SUBSTR(SQLERRM,1,200);
         x_retcode := 2;

          log_procedure(
                               p_control_id           => NULL,
                               p_source_system_code   => NULL,
                               p_procedure_name       => 'CHILD_MAIN',
                               p_staging_table_name   => NULL,
                               p_staging_column_name  => NULL,
                               p_staging_column_value => NULL,
                               p_source_system_ref    => NULL,
                               p_batch_id             => p_batch_id,
                               p_exception_log        => x_errbuf,
                               p_oracle_error_code    => SQLCODE,
                               p_oracle_error_msg     => SUBSTR(SQLERRM,1,200)
                       );

     XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
   END child_main;

END XX_PO_ASN_CONV_PKG;
/

SHOW ERRORS

EXIT


REM============================================================================================
REM                                   End Of Script
REM============================================================================================
