SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY XX_QP_MODIFIERS_IMPORT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_QP_MODIFIERS_IMPORT_PKG.pkb                     |
-- | Description :  QP Modifiers  Package Body                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  14-May-2007 Abhradip Ghosh     Initial draft version     |
-- |DRAFT 1b  12-Jun-2007 Abhradip Ghosh     Onsite Review Incorporated|
-- |DRAFT 1c  12-Jun-2007 Parvez Siddiqui    TL Review                 |
-- |DRAFT 1d  13-Jun-2007 Abhradip Ghosh     Conid. Onsite Review Incrp|
-- |DRAFT 1e  13-Jun-2007 Parvez Siddiqui    TL Review                 |
-- |DRAFT 1f  13-Jun-2007 Abhradip Ghosh     Onsite Review Incrp       |
-- +===================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------
G_PACKAGE_NAME              CONSTANT VARCHAR2(50)                                  :=  'XX_QP_MODIFIERS_IMPORT_PKG';
G_HEADER_CONTEXT            CONSTANT qp_list_headers_b.context%TYPE                :=  'Promotional Attributes';
G_LIST_TYPE_CODE            CONSTANT qp_list_headers_b.list_type_code%TYPE         :=  'PRO';
G_PTE_CODE                  CONSTANT qp_list_headers_b.pte_code%TYPE               :=  'ORDFUL';
G_LINE_CONTEXT              CONSTANT qp_list_lines.context%TYPE                    :=  'CouponWiz';
G_BENEFIT_PRICE_LIST        CONSTANT qp_list_headers_tl.name%TYPE                  :=  'ZONE_74';
G_OPERAND_PRICE_LIST        CONSTANT qp_list_headers_tl.name%TYPE                  :=  'ZONE_71';
G_CONVERSION_CODE           CONSTANT xx_com_conversions_conv.conversion_code%TYPE  :=  'C0225_Modifiers';
G_APPLICATION               CONSTANT VARCHAR2(10)                                  :=  'QP';
G_CHILD_PROGRAM             CONSTANT VARCHAR2(50)                                  :=  'XX_QP_MODIFIERS_CNV_MAIN';
G_COMM_APPLICATION          CONSTANT VARCHAR2(10)                                  :=  'XXCOMN';
G_SUMM_PROGRAM              CONSTANT VARCHAR2(50)                                  :=  'XXCOMCONVSUMMREP';
G_EXCEP_PROGRAM             CONSTANT VARCHAR2(50)                                  :=  'XXCOMCONVEXPREP';
G_SLEEP                     CONSTANT PLS_INTEGER                                   := 1;
G_MAX_WAIT_TIME             CONSTANT PLS_INTEGER                                   := 2;
G_LOOKUP_LIST_TYPE_CODE     CONSTANT VARCHAR2(30)                                  := 'LIST_TYPE_CODE';
G_SOURCE_SYSTEM_CODE        CONSTANT VARCHAR2(10)                                  := 'QP';
G_ZONE_71                   CONSTANT VARCHAR2(30)                                  := 'ZONE_71';
G_ZONE_74                   CONSTANT VARCHAR2(30)                                  := 'ZONE_74';
G_COMPARISON_OPERATOR_CODE  CONSTANT VARCHAR2(30)                                  := 'COMPARISON_OPERATOR_CODE';
G_ARITHMETIC_OPERATOR       CONSTANT VARCHAR2(30)                                  := 'ARITHMETIC_OPERATOR';
G_MODIFIER_LEVEL_CODE       CONSTANT VARCHAR2(30)                                  := 'MODIFIER_LEVEL_CODE';
G_LIST_LINE_TYPE_CODE       CONSTANT VARCHAR2(30)                                  := 'LIST_LINE_TYPE_CODE';
G_LIMIT_SIZE                CONSTANT PLS_INTEGER                                   := 10000;

----------------------------
--Declaring Global Variables
----------------------------
gn_master_request_id PLS_INTEGER;
gn_batch_size        PLS_INTEGER;
gn_conversion_id     PLS_INTEGER;
gn_max_child_req     PLS_INTEGER ;
gn_batch_count       PLS_INTEGER := 0;
gn_record_count      PLS_INTEGER := 0;
gn_index_request_id  PLS_INTEGER := 0;
gc_reset_status_flag VARCHAR2(03):= 'Y';
gc_pro_flag          VARCHAR2(03):= 'S';

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE req_id_tbl_type IS TABLE OF FND_CONCURRENT_REQUESTS.request_id%TYPE
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

-- +====================================================================+
-- | Name        :  get_conversion_id                                   |
-- | Description :  This procedure is invoked to get the conversion_id, |
-- |                batch_size and max_threads from the common          |
-- |                conversions table                                   |
-- |                                                                    |
-- | Parameters  :                                                      |
-- |                                                                    |
-- | Returns     :  Conversion_ID                                       |
-- |                Batch_Size                                          |
-- |                                                                    |
-- +====================================================================+

PROCEDURE get_conversion_id(
                            x_conversion_id  OUT NOCOPY NUMBER
                            ,x_batch_size    OUT NOCOPY NUMBER
                            ,x_max_threads   OUT NOCOPY NUMBER
                            ,x_return_status OUT NOCOPY VARCHAR2
                            ,x_errbuf        OUT NOCOPY VARCHAR2
                           )
IS
BEGIN
   SELECT XCCC.conversion_id
          ,XCCC.batch_size
          ,XCCC.max_threads
   INTO   x_conversion_id
          ,x_batch_size
          ,x_max_threads
   FROM   xx_com_conversions_conv XCCC
   WHERE  XCCC.conversion_code = G_CONVERSION_CODE;

   x_return_status := 'S';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_return_status := 'E';
       x_errbuf        := SQLERRM;
       display_log(x_errbuf);
   WHEN OTHERS THEN
       x_return_status := SQLERRM;
       x_errbuf        := 'Error while deriving conversion_id - '||SQLERRM;
       display_log(x_errbuf);
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
                                                ,p_record_control_id    => p_control_id
                                                ,p_source_system_code   => p_source_system_code
                                                ,p_package_name         => 'XX_QP_MODIFIERS_IMPORT_PKG'
                                                ,p_procedure_name       => p_procedure_name
                                                ,p_staging_table_name   => p_staging_table_name
                                                ,p_staging_column_name  => p_staging_column_name
                                                ,p_staging_column_value => p_staging_column_value
                                                ,p_source_system_ref    => p_source_system_ref
                                                ,p_batch_id             => p_batch_id
                                                ,p_exception_log        => p_exception_log
                                                ,p_oracle_error_code    => p_oracle_error_code
                                                ,p_oracle_error_msg     => p_oracle_error_msg
                                              );
EXCEPTION
   WHEN OTHERS THEN
       display_log('Error in log_procedure of child_main procedure');
       display_log(SQLERRM);
END log_procedure;

-- +====================================================================+
-- | Name        :  launch_summary_report                               |
-- | Description :  This procedure is invoked to Launch Conversion      |
-- |                Processing Summary Report for that run              |
-- |                                                                    |
-- | Returns  :     x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+

PROCEDURE launch_summary_report(
                                x_errbuf   OUT NOCOPY VARCHAR2
                                ,x_retcode OUT NOCOPY VARCHAR2
                               )
IS
-- ------------------------------------------
-- Local Exception and Variables Declaration
-- ------------------------------------------
EX_REP_SUMM             EXCEPTION;
lc_phase                VARCHAR2(03);
ln_summ_request_id      PLS_INTEGER;

BEGIN

   FOR i IN gt_req_id.FIRST .. gt_req_id.LAST
   LOOP
       LOOP
           -- ----------------------------------------
           -- Get the status of the concurrent request
           -- ----------------------------------------
           SELECT FCR.phase_code
           INTO   lc_phase
           FROM   fnd_concurrent_requests FCR
           WHERE  FCR.request_id = gt_req_id(i);

            --- ------------------------------------------------
            --  If the concurrent requests completed sucessfully
            -- -------------------------------------------------
            IF lc_phase = 'C' THEN
              EXIT;
           ELSE
               DBMS_LOCK.SLEEP(G_SLEEP);
           END IF;
       END LOOP;
   END LOOP;

    -- -----------------------------------------------------------------------------
    -- Call the Conversion Summary Report program after completion of child programs
    -- -----------------------------------------------------------------------------
   ln_summ_request_id := FND_REQUEST.submit_request(
                                                    application   => G_COMM_APPLICATION
                                                    ,program     => G_SUMM_PROGRAM
                                                    ,sub_request => FALSE                -- TRUE means is a sub request
                                                    ,argument1   => G_CONVERSION_CODE    -- conversion_code
                                                    ,argument2   => gn_master_request_id -- MASTER REQUEST ID
                                                    ,argument3   => NULL                 -- REQUEST ID
                                                    ,argument4   => NULL                 -- BATCH ID
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
       display_log(x_errbuf);
END launch_summary_report;

-- +====================================================================+
-- | Name        :  update_master_batch_id                              |
-- |                                                                    |
-- | Description :  This procedure is invoked to reset Batch Id to Null |
-- |                and process_flag to 1 for Previously Errored Out    |
-- |                Records form the master concurrent request          |
-- |                                                                    |
-- | Parameters  :                                                      |
-- +====================================================================+

PROCEDURE update_master_batch_id(
                                 x_errbuf OUT NOCOPY VARCHAR2
                                )
IS

BEGIN

   -- ---------------------------------------------------------------------
   -- Update the records of the header staging table with process_flag = 1
   -- and load_batch_id = NULL
   -- ---------------------------------------------------------------------
   UPDATE xx_qp_list_headers_stg XQPL
   SET    XQPL.process_flag = 1
          ,XQPL.load_batch_id = NULL
   WHERE  XQPL.process_flag NOT IN (0,7);

   -- -------------------------------------------------------------------
   -- Update the records of the line staging table with process_flag = 1
   -- and load_batch_id = NULL
   -- -------------------------------------------------------------------
   UPDATE xx_qp_list_lines_stg XQLL
   SET    XQLL.load_batch_id  = NULL
          ,XQLL.process_flag   = 1
   WHERE  XQLL.process_flag NOT IN (0,7);

   -- ---------------------------------------------------------------------------------
   -- Update the records of the pricing attributes staging table with process_flag = 1
   -- and load_batch_id = NULL
   -- ---------------------------------------------------------------------------------
   UPDATE xx_qp_pricing_attributes_stg XQPA
   SET    XQPA.process_flag  = 1
          ,XQPA.load_batch_id = NULL
   WHERE  XQPA.process_flag NOT IN (0,7);

   -- ------------------------------------------------------------------------
   -- Update the records of the qualifier staging table with process_flag = 1
   -- and load_batch_id = NULL
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_qualifiers_stg XQQS
   SET    XQQS.process_flag = 1
          ,XQQS.load_batch_id = NULL
   WHERE  XQQS.process_flag NOT IN (0,7);

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
       x_errbuf := 'Error in update_master_batch_id : '||SQLERRM;
       display_log(x_errbuf);
END update_master_batch_id;

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
                    p_request_id          IN         NUMBER
                    ,p_validate_only_flag IN         VARCHAR2
                    ,p_reset_status_flag  IN         VARCHAR2
                    ,x_time               OUT NOCOPY DATE
                    ,x_errbuf             OUT NOCOPY VARCHAR2
                    ,x_retcode            OUT NOCOPY VARCHAR2
                   )

IS
-- ----------------------------------------
-- Local Exception and Variable Declaration
-- ----------------------------------------
EX_SUBMIT_CHILD     EXCEPTION;
ln_batch_size_count PLS_INTEGER;
ln_seq              PLS_INTEGER;
ln_req_count        PLS_INTEGER;
ln_conc_request_id  PLS_INTEGER;

BEGIN
   -- ------------------------------------
   -- Get the batch_id from the sequence
   -- ------------------------------------
   SELECT xx_qp_modifiers_batchid_s.NEXTVAL
   INTO   ln_seq
   FROM   DUAL;

   -- ------------------------------------------------------------------------
   -- Update the records of the header staging table with process_flag = 2
   -- and load_batch_id equal to the value of the sequence
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_list_headers_stg XQPL
   SET    XQPL.process_flag = 2
          ,XQPL.load_batch_id = ln_seq
   WHERE  XQPL.load_batch_id IS NULL
   AND    XQPL.process_flag = 1
   AND    ROWNUM <= gn_batch_size;

   ln_batch_size_count := SQL%ROWCOUNT;

   COMMIT;

   -- ------------------------------------------------------------------------
   -- Update the records of the line staging table with process_flag = 2
   -- and load_batch_id equal to the value of the sequence
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_list_lines_stg XQLL
   SET    XQLL.process_flag = 2
          ,XQLL.load_batch_id = ln_seq
   WHERE  XQLL.load_batch_id IS NULL
   AND    XQLL.process_flag = 1
   AND    XQLL.orig_sys_header_ref IN (
                                       SELECT XQPL.orig_sys_header_ref
                                       FROM   xx_qp_list_headers_stg XQPL
                                       WHERE  XQPL.load_batch_id = ln_seq
                                       AND    XQPL.process_flag = 2
                                      );

   COMMIT;

   -- ---------------------------------------------------------------------------------
   -- Update the records of the pricing attributes staging table with process_flag = 2
   -- and load_batch_id equal to the value of the sequence
   -- ----------------------------------------------------------------------------------
   UPDATE xx_qp_pricing_attributes_stg XQPA
   SET    XQPA.process_flag = 2
          ,XQPA.load_batch_id = ln_seq
   WHERE  XQPA.load_batch_id IS NULL
   AND    XQPA.process_flag = 1
   AND    XQPA.orig_sys_header_ref IN (
                                       SELECT XQPL.orig_sys_header_ref
                                       FROM   xx_qp_list_headers_stg XQPL
                                       WHERE  XQPL.load_batch_id = ln_seq
                                       AND    XQPL.process_flag = 2
                                      )
   AND    XQPA.orig_sys_line_ref IN (
                                     SELECT XQLL.orig_sys_line_ref
                                     FROM   xx_qp_list_lines_stg XQLL
                                     WHERE  XQLL.load_batch_id = ln_seq
                                     AND    XQLL.process_flag = 2
                                    );

   COMMIT;

   -- ------------------------------------------------------------------------
   -- Update the records of the qualifier staging table with process_flag = 2
   -- and load_batch_id equal to the value of the sequence
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_qualifiers_stg XQQS
   SET    XQQS.process_flag = 2
          ,XQQS.load_batch_id = ln_seq
   WHERE  XQQS.load_batch_id IS NULL
   AND    XQQS.process_flag = 1
   AND    XQQS.orig_sys_header_ref IN (
                                       SELECT XQPL.orig_sys_header_ref
                                       FROM   xx_qp_list_headers_stg XQPL
                                       WHERE  XQPL.load_batch_id = ln_seq
                                       AND    XQPL.process_flag = 2
                                      );
   COMMIT;

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
         -- -----------------------------------------------------------
         -- Call the custom concurrent program for parallel execution
         -- -----------------------------------------------------------
          ln_conc_request_id := FND_REQUEST.submit_request(
                                                           application  => G_APPLICATION
                                                           ,program     => G_CHILD_PROGRAM
                                                           ,sub_request => FALSE
                                                           ,argument1   => p_validate_only_flag
                                                           ,argument2   => p_reset_status_flag
                                                           ,argument3   => ln_seq
                                                          );

          IF ln_conc_request_id = 0 THEN

             x_errbuf  := FND_MESSAGE.GET;
             RAISE EX_SUBMIT_CHILD;

          ELSE

              COMMIT;
              gn_index_request_id := gn_index_request_id + 1;
              gt_req_id(gn_index_request_id) := ln_conc_request_id;
              gn_batch_count  := gn_batch_count + 1;
              x_time := sysdate;

              ------------------------------------------------------------------------------
              /*Procedure to Log Conversion Control Informations.*/
              ------------------------------------------------------------------------------
              XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                                                             p_conversion_id           => gn_conversion_id
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
       x_errbuf  := 'Error in submitting child requests: ' || x_errbuf;
       display_log(x_errbuf);
       RAISE;
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf := 'Error in bat_child - '||SQLERRM;
       display_log(x_errbuf);
       RAISE;
END bat_child;

-- +===================================================================+
-- | Name        :  submit_sub_requests                                |
-- | Description :  This procedure is invoked from the master_main     |
-- |                procedure. This would submit child requests based  |
-- |                on batch_size.                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE submit_sub_requests(
                              p_validate_only_flag   IN         VARCHAR2
                              ,p_reset_status_flag   IN         VARCHAR2
                              ,x_errbuf              OUT NOCOPY VARCHAR2
                              ,x_retcode             OUT NOCOPY VARCHAR2
                             )

IS
-- -----------------------------------------
-- Local Exception and Variables declaration
-- -----------------------------------------
EX_NO_ENTRY       EXCEPTION;
EX_NO_DATA        EXCEPTION;
ld_check_time     DATE;
ld_current_time   DATE;
ln_rem_time       NUMBER;
ln_current_count  PLS_INTEGER;
ln_last_count     PLS_INTEGER;
lc_return_status  VARCHAR2(03);
lc_launch         VARCHAR2(02) := 'N';
lc_errbuf         VARCHAR2(2000);
lc_retcode        VARCHAR2(10);

BEGIN

   -- ----------------------------------------------------------
   -- To derive the conversion_id, batch_size and max_threads
   -- ----------------------------------------------------------

   get_conversion_id(
                     x_conversion_id  => gn_conversion_id
                     ,x_batch_size    => gn_batch_size
                     ,x_max_threads   => gn_max_child_req
                     ,x_return_status => lc_return_status
                     ,x_errbuf        => lc_errbuf
                    );

   IF lc_return_status = 'S' THEN

      -- -----------------------------------------------------------------
      -- Call to update the process_flag for previously errored records
      -- -----------------------------------------------------------------

      IF NVL(p_reset_status_flag,'N') = 'Y' THEN

         update_master_batch_id(
                                x_errbuf  => lc_errbuf
                               );

      END IF;

      ld_check_time := sysdate;

      ln_current_count := 0;

      LOOP

         ln_last_count := ln_current_count;

         -- -----------------------------------------
         -- Get the current count of eligible records
         -- -----------------------------------------

         SELECT COUNT(1)
         INTO   ln_current_count
         FROM   xx_qp_list_headers_stg XQPL
         WHERE  XQPL.load_batch_id IS NULL
         AND    XQPL.process_flag = 1;

         IF (ln_current_count >= gn_batch_size) THEN

            -- -------------------------------------------
            -- Call bat_child to launch the child requests
            -- -------------------------------------------

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
                    DBMS_LOCK.SLEEP(G_SLEEP);
                END IF; -- ln_rem_time > G_MAX_WAIT_TIME

             ELSE

                 DBMS_LOCK.SLEEP(G_SLEEP);

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
                               x_errbuf   => x_errbuf
                               ,x_retcode => x_retcode
                              );

      END IF;

      display_out(RPAD('=',41,'='));
      display_out(RPAD('Batch Size                     : ',32,' ')||RPAD(gn_batch_size,9,' '));
      display_out(RPAD('Total Number Of Header Records : ',32,' ')||RPAD(gn_record_count,9,' '));
      display_out(RPAD('Number of Batches Launched     : ',32,' ')||RPAD(gn_batch_count,9,' '));
      display_out(RPAD('=',41,'='));

   ELSE

      RAISE EX_NO_ENTRY;

   END IF; -- lc_return_status

EXCEPTION
   WHEN EX_NO_DATA THEN
       x_retcode := 1;
       x_errbuf  := 'There is no data in the table XX_QP_LIST_HEADERS_STG';
       display_out(x_errbuf);
   WHEN EX_NO_ENTRY THEN
       x_retcode := 2;
       x_errbuf  := 'There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE;
       display_out(x_errbuf);
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Error in submit_sub_requests : '||SQLERRM;
       display_out(x_errbuf);
       RAISE;
END submit_sub_requests;

-- +=================================================================================+
-- | Name        :  get_list_type_code                                               |
-- |                                                                                 |
-- | Description :  This procedure is used to validate Default List Type Code        |
-- |                                                                                 |
-- | Parameters  :                                                                   |
-- |                                                                                 |
-- | Returns     :                                                                   |
-- |                                                                                 |
-- +=================================================================================+

PROCEDURE get_list_type_code(
                             x_return_status OUT NOCOPY VARCHAR2
                             ,p_batch_id     IN  NUMBER
                            )
IS

BEGIN

   SELECT 'Y'
   INTO   x_return_status
   FROM   fnd_lookup_values FLV
   WHERE  FLV.lookup_type = G_LOOKUP_LIST_TYPE_CODE
   AND    FLV.lookup_code = G_LIST_TYPE_CODE
   AND    FLV.enabled_flag='Y'
   AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1);

   x_return_status := 'S';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       log_procedure(
                     p_control_id            => NULL
                     ,p_source_system_code   => NULL
                     ,p_procedure_name       => 'GET_LIST_TYPE_CODE'
                     ,p_staging_table_name   => NULL
                     ,p_staging_column_name  => NULL
                     ,p_staging_column_value => NULL
                     ,p_source_system_ref    => NULL
                     ,p_batch_id             => p_batch_id
                     ,p_exception_log        => 'LOOKUP_CODE = '||G_LIST_TYPE_CODE||' not set up.'
                     ,p_oracle_error_code    => NULL
                     ,p_oracle_error_msg     => NULL
                    );
       x_return_status := 'N';
   WHEN OTHERS THEN
       x_return_status := 'N';
       log_procedure(
                     p_control_id            => NULL
                     ,p_source_system_code   => NULL
                     ,p_procedure_name       => 'GET_LIST_TYPE_CODE'
                     ,p_staging_table_name   => NULL
                     ,p_staging_column_name  => NULL
                     ,p_staging_column_value => NULL
                     ,p_source_system_ref    => NULL
                     ,p_batch_id             => p_batch_id
                     ,p_exception_log        => NULL
                     ,p_oracle_error_code    => NULL
                     ,p_oracle_error_msg     => SQLERRM
                    );

END get_list_type_code;

-- +====================================================================+
-- | Name        :  validate_currency_code                              |
-- |                                                                    |
-- | Description :  This procedure is invoked to validate the currency  |
-- |                code                                                |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_currency_code                                     |
-- |                                                                    |
-- +====================================================================+


PROCEDURE validate_currency_code(
                                 p_currency_code IN  VARCHAR2
                                 ,x_err_curr_msg OUT NOCOPY VARCHAR2
                                )
IS

BEGIN

   SELECT 'Y'
   INTO   x_err_curr_msg
   FROM   fnd_currencies FC
   WHERE  FC.currency_code=p_currency_code
   AND    FC.enabled_flag='Y'
   AND    SYSDATE BETWEEN NVL(FC.start_date_active,SYSDATE) AND NVL(FC.end_date_active,SYSDATE+1);

   x_err_curr_msg := 'NE';
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_err_curr_msg := 'E';
   WHEN OTHERS THEN
      x_err_curr_msg := SQLERRM;

END validate_currency_code;


-- +====================================================================+
-- | Name        :  validate_operating_unit                             |
-- |                                                                    |
-- | Description :  This procedure is invoked to validate the operating |
-- |                unit                                                |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_name                                              |
-- |                                                                    |
-- +====================================================================+


PROCEDURE validate_operating_unit(
                                  p_name    IN  VARCHAR2
                                  ,x_org_id OUT NOCOPY NUMBER
                                  ,x_status OUT NOCOPY VARCHAR2
                                 )
IS

BEGIN

   SELECT HOU.organization_id
   INTO   x_org_id
   FROM   hr_operating_units HOU
   WHERE  HOU.name=p_name;

   x_status := 'NE';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      x_status := 'E';
   WHEN OTHERS THEN
      x_status := SQLERRM;
END validate_operating_unit;

-- +====================================================================+
-- | Name        :  validate_line_type_code                             |
-- |                                                                    |
-- | Description :  This procedure is invoked to validate the line type |
-- |                code                                                |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_line_type_code                                    |
-- |                                                                    |
-- +====================================================================+

PROCEDURE validate_line_type_code(
                                  p_line_type_code IN  VARCHAR2
                                  ,x_err_line_code OUT NOCOPY VARCHAR2
                                 )
IS

BEGIN

   SELECT 'Y'
   INTO   x_err_line_code
   FROM   fnd_lookup_values FLV
   WHERE  FLV.lookup_type=G_LIST_LINE_TYPE_CODE
   AND    FLV.lookup_code=p_line_type_code
   AND    FLV.enabled_flag='Y'
   AND SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1);

   x_err_line_code := 'NE';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_err_line_code := 'E';
   WHEN OTHERS THEN
       x_err_line_code := SQLERRM;

END validate_line_type_code;

-- +====================================================================+
-- | Name        :  validate_modifier_level_code                        |
-- |                                                                    |
-- | Description :  This procedure is invoked to validate the modifier  |
-- |                level code                                          |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_line_type_code                                    |
-- |                                                                    |
-- +====================================================================+

PROCEDURE validate_modifier_level_code(
                                       p_modifier_level_code IN  VARCHAR2
                                       ,x_err_mod_code       OUT NOCOPY VARCHAR2
                                      )
IS

BEGIN

   SELECT 'Y'
   INTO   x_err_mod_code
   FROM   fnd_lookup_values FLV
   WHERE  FLV.lookup_type=G_MODIFIER_LEVEL_CODE
   AND    FLV.lookup_code= p_modifier_level_code
   AND    FLV.enabled_flag='Y'
   AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1);

   x_err_mod_code := 'NE';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_err_mod_code := 'E';
   WHEN OTHERS THEN
       x_err_mod_code := SQLERRM;

END validate_modifier_level_code;

-- +=====================================================================+
-- | Name        :  validate_arithmetic_operator                         |
-- |                                                                     |
-- | Description :  This procedure is invoked to validate the arithmetic |
-- |                operator                                             |
-- |                                                                     |
-- |                                                                     |
-- | Parameters  :  p_arithmetic_operator                                |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE validate_arithmetic_operator(
                                       p_arithmetic_operator      IN  VARCHAR2
                                       ,x_err_arithmetic_operator OUT NOCOPY VARCHAR2
                                       ,x_status                  OUT NOCOPY VARCHAR2
                                      )
IS

BEGIN

   SELECT 'Y'
   INTO   x_err_arithmetic_operator
   FROM   fnd_lookup_values FLV
   WHERE  FLV.lookup_type=G_ARITHMETIC_OPERATOR
   AND    FLV.lookup_code= p_arithmetic_operator
   AND    FLV.enabled_flag='Y'
   AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1);

   x_status := 'NE';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_status := 'E';
   WHEN OTHERS THEN
       x_status := SQLERRM;

END validate_arithmetic_operator;

-- +====================================================================+
-- | Name        :  validate_inventory_item_id                          |
-- |                                                                    |
-- | Description :  This procedure is invoked to derive the inventory   |
-- |                item id                                             |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_name                                              |
-- |                                                                    |
-- +====================================================================+

PROCEDURE validate_inventory_item_id(
                                     p_inventory_item IN  VARCHAR2
                                     ,p_uom_code      IN  VARCHAR2
                                     ,x_inv_item      OUT NOCOPY NUMBER
                                     ,x_status        OUT NOCOPY VARCHAR2
                                    )
IS

BEGIN

   SELECT MSI.inventory_item_id
   INTO   x_inv_item
   FROM   mtl_system_items_b MSI,
          mtl_parameters MP
   WHERE  MP.organization_id=MP.master_organization_id
   AND    MP.master_organization_id=MSI.organization_id
   AND    MSI.primary_uom_code=UPPER(p_uom_code)
   AND    MSI.segment1 = p_inventory_item
   AND    rownum=1;

   x_status := 'NE';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_status := 'E';
   WHEN OTHERS THEN
       x_status   := SQLERRM;

END validate_inventory_item_id;

-- +====================================================================+
-- | Name        :  validate_comparision_operator                       |
-- |                                                                    |
-- | Description :  This procedure is invoked to validate the           |
-- |                comparision operator                                |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_comparision_operator_code                         |
-- |                                                                    |
-- +====================================================================+

PROCEDURE validate_comparision_operator(
                                        p_comparision_operator_code IN VARCHAR2
                                        ,x_err_operator_code        OUT NOCOPY VARCHAR2
                                        ,x_status                   OUT NOCOPY VARCHAR2
                                       )
IS

BEGIN

   SELECT 'Y'
   INTO   x_err_operator_code
   FROM   fnd_lookup_values FLV
   WHERE  FLV.lookup_type=G_COMPARISON_OPERATOR_CODE
   AND    FLV.lookup_code= p_comparision_operator_code
   AND    FLV.enabled_flag='Y'
   AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1);

   x_status := 'NE';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_status := 'E';
   WHEN OTHERS THEN
       x_status := SQLERRM;

END validate_comparision_operator;
/*
-- +====================================================================+
-- | Name        :  validate_comments_attrib12                          |
-- |                                                                    |
-- | Description :  This procedure is invoked to validate attribute12   |
-- |                along with comments                                 |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_name                                              |
-- |                                                                    |
-- +====================================================================+


PROCEDURE validate_comments_attrib12(
                                     p_attribute12            IN  VARCHAR2
                                     ,p_comments              IN  VARCHAR2
                                     ,x_err_comments_attrib12 OUT NOCOPY VARCHAR2
                                    )
IS

BEGIN
   CASE
      WHEN p_attribute12 NOT IN ('1A','1B','2A','2B','3','4','7') THEN
           x_err_comments_attrib12 := 'N';
      ELSE
          CASE
              WHEN ((p_attribute12 = '1A') AND (UPPER(p_comments) <> UPPER('Buy one or more items, get one or more free'))) THEN
                    x_err_comments_attrib12 := 'N';
              WHEN ((p_attribute12 = '1B') AND (UPPER(p_comments) <> UPPER('Spend minimum amount, get one or more for free'))) THEN
                    x_err_comments_attrib12 := 'N';
              WHEN ((p_attribute12 = '2A') AND (UPPER(p_comments) <> UPPER('Buy 1 or more, get $ off'))) THEN
                    x_err_comments_attrib12 := 'N';
              WHEN ((p_attribute12 = '2B') AND (UPPER(p_comments) <> UPPER('Buy 1 or more, get % off'))) THEN
                    x_err_comments_attrib12 := 'N';
              WHEN ((p_attribute12 = '3') AND (UPPER(p_comments) <> UPPER('Spend minimum amount, get $ off'))) THEN
                    x_err_comments_attrib12 := 'N';
              WHEN ((p_attribute12 = '4') AND (UPPER(p_comments) <> UPPER('Spend minimum amount, get % off'))) THEN
                    x_err_comments_attrib12 := 'N';
              WHEN ((p_attribute12 = '7') AND (UPPER(p_comments) <> UPPER('Buy an item for specific amount (OD only)'))) THEN
                    x_err_comments_attrib12 := 'N';
              ELSE
                  x_err_comments_attrib12 := 'Y';
          END CASE;
   END CASE;


EXCEPTION
   WHEN OTHERS THEN
       x_err_comments_attrib12 := SQLERRM;

END validate_comments_attrib12;
*/
-- +====================================================================+
-- | Name        :  derive_phase_id                                     |
-- |                                                                    |
-- | Description :  This procedure is invoked to derive the phase_id    |
-- |                from the modifier level code                        |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_modifier_level_code                               |
-- |                                                                    |
-- +====================================================================+

PROCEDURE derive_phase_id(
                          p_modifier_level_code IN  VARCHAR2
                          ,x_phase_id           OUT NOCOPY NUMBER
                          ,x_status             OUT NOCOPY VARCHAR2
                         )
IS

BEGIN

   CASE
      WHEN p_modifier_level_code = 'LINEGROUP' THEN

          BEGIN
               SELECT QPP.pricing_phase_id
               INTO   x_phase_id
               FROM   qp_pricing_phases QPP
               WHERE  QPP.modifier_level_code = 'LINEGROUP'
               AND    QPP.incompat_resolve_code='BEST_PRICE'
               AND    UPPER(QPP.name)=UPPER('All Lines Adjustment');

               x_status := 'NE';

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                 x_status := 'E';
             WHEN OTHERS THEN
                 x_status := SQLERRM;
          END;

      WHEN p_modifier_level_code = 'LINE' THEN

          BEGIN
               SELECT QPP.pricing_phase_id
               INTO   x_phase_id
               FROM   qp_pricing_phases QPP
               WHERE  QPP.modifier_level_code = 'LINE'
               AND    QPP.incompat_resolve_code='BEST_PRICE'
               AND    UPPER(QPP.name)=UPPER('List Line Adjustment');

               x_status := 'NE';

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                 x_status := 'E';
             WHEN OTHERS THEN
                 x_status := SQLERRM;
          END;
      ELSE

          BEGIN
               SELECT QPP.pricing_phase_id
               INTO   x_phase_id
               FROM   qp_pricing_phases QPP
               WHERE  QPP.modifier_level_code = 'ORDER'
               AND    QPP.incompat_resolve_code='BEST_PRICE'
               AND    UPPER(QPP.name)=UPPER('Header Level Adjustments');

               x_status := 'NE';

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                 x_status := 'E';
             WHEN OTHERS THEN
                 x_status := SQLERRM;
          END;
   END CASE;

EXCEPTION
   WHEN OTHERS THEN
     x_status := SQLERRM;

END derive_phase_id;
/*
-- +====================================================================+
-- | Name        :  derive_benefit_list_line_id                         |
-- |                                                                    |
-- | Description :  This procedure is invoked to derive the benefit list|
-- |                line id from inventory item id                      |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_inv_item_id                                       |
-- |                                                                    |
-- +====================================================================+

PROCEDURE derive_benefit_list_line_id(
                                      p_inv_item_id   IN NUMBER
                                      ,x_list_line_id OUT NOCOPY NUMBER
                                      ,x_status       OUT NOCOPY VARCHAR2
                                     )
IS

BEGIN

   SELECT QLL.list_line_id
   INTO   x_list_line_id
   FROM   qp_list_headers_tl QLHT,
          qp_list_headers_b QLH,
          qp_list_lines QLL,
          qp_pricing_attributes QPA
   WHERE  QLHT.list_header_id    = QLH.list_header_id
   AND    QLH.list_header_id     = QLL.list_header_id
   AND    QLL.list_line_id       = QPA.list_line_id
   AND    UPPER(QLHT.name)       = UPPER(G_ZONE_74)
   AND    QPA.product_attr_value = TO_CHAR(p_inv_item_id);

   x_status := 'NE';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
     x_status := 'E';
   WHEN OTHERS THEN
     x_status := SQLERRM;

END derive_benefit_list_line_id;*/

-- +====================================================================+
-- | Name        :  get_operand                                         |
-- |                                                                    |
-- | Description :  This procedure is invoked to derive the operand for |
-- |                a particular inventory item id                      |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_orig_sys_header_ref                              |
-- |                p_batch_id                                          |
-- +====================================================================+

PROCEDURE get_operand(
                      p_orig_sys_header_ref IN  VARCHAR2
                      ,p_batch_id           IN  NUMBER
                      ,x_operand            OUT NOCOPY NUMBER
                      ,x_status             OUT NOCOPY VARCHAR2
                     )
IS

-- -----------------------------------------------------------------
-- Local Variables Declaration
-- -----------------------------------------------------------------
ln_line_no            NUMBER;
ln_num_of_get         NUMBER;
lc_exists             VARCHAR2(03) := 'N';
ln_num_q              NUMBER;
ln_get_operand        NUMBER;
ln_value              NUMBER := 0;
ln_q_operand          NUMBER;
ln_inv_item           NUMBER;
lc_product_attr_value VARCHAR2(90);
lc_product_uom_code   VARCHAR2(90);
lc_status             VARCHAR2(2000);
lc_err_flag           VARCHAR2(01) := 'S';

-- -------------------------------------------------
-- Table Type for holding line staging table data
-- -------------------------------------------------
TYPE op_line_tbl_type IS TABLE OF xx_qp_list_lines_stg%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_op_line op_line_tbl_type;

-- ----------------------------------------------------------------
-- Cursor to fetch the records from the line staging table with
-- attribute9 = 'Q'
-- ----------------------------------------------------------------
CURSOR lcu_operand(
                   p_orig_sys_header_ref IN VARCHAR2
                   ,p_batch_id           IN NUMBER
                  )
IS
SELECT XQLL.*
FROM   xx_qp_list_lines_stg XQLL
WHERE  XQLL.orig_sys_header_ref = p_orig_sys_header_ref
AND    XQLL.load_batch_id = p_batch_id
AND    UPPER(XQLL.attribute9) = UPPER('Buy');

BEGIN

   -- ----------------------------------------------------------------
   -- Count the number of lines for that header
   -- ----------------------------------------------------------------

   SELECT COUNT(1)
   INTO   ln_line_no
   FROM   xx_qp_list_lines_stg XQLL
   WHERE  XQLL.orig_sys_header_ref = p_orig_sys_header_ref
   AND    XQLL.load_batch_id = p_batch_id;

   IF ln_line_no <> 0 THEN

     -- ----------------------------------------------------------------
     -- Count the number of lines with attribute9 = 'R' for that header
     -- ----------------------------------------------------------------
     SELECT COUNT(1)
     INTO   ln_num_of_get
     FROM   xx_qp_list_lines_stg XQLL
     WHERE  XQLL.orig_sys_header_ref = p_orig_sys_header_ref
     AND    XQLL.load_batch_id = p_batch_id
     AND    UPPER(XQLL.attribute9)    = UPPER('Get');

     IF ln_num_of_get = 1 THEN

        -- --------------------------------------------------------------------
        -- Get the operand for that line with attribute9 = 'R' for that header
        -- ---------------------------------------------------------------------

        SELECT operand
        INTO   ln_get_operand
        FROM   xx_qp_list_lines_stg XQLL
        WHERE  XQLL.orig_sys_header_ref = p_orig_sys_header_ref
        AND    XQLL.load_batch_id = p_batch_id
        AND    UPPER(XQLL.attribute9)    = UPPER('Get');

        IF  ln_r_operand <= 0 THEN
            x_status  := 'E';

        ELSE
            lc_exists := 'Y';
        END IF; -- ln_r_operand <= 0

     ELSE
         x_status  := 'E';

     END IF; -- ln_num_of_get = 1

     IF lc_exists = 'Y' THEN

          -- ------------------------------------------------------------------
          -- Get the records from the line staging table into the table type
          -- ------------------------------------------------------------------

        OPEN lcu_operand(
                         p_orig_sys_header_ref
                         ,p_batch_id
                        );
        FETCH lcu_operand BULK COLLECT INTO lt_op_line;
        CLOSE lcu_operand;

        IF lt_op_line.COUNT <> 0 THEN

           FOR i IN  1 ..lt_op_line.COUNT
           LOOP
               IF lt_op_line(i).operand = 0 THEN

                  -- ------------------------------------------------------------------
                  -- Get the product_attr_value and product_uom_code
                  -- from the pricing attributes staging table for that line
                  -- ------------------------------------------------------------------

                  SELECT product_attr_value,
                         product_uom_code
                  INTO   lc_product_attr_value,
                         lc_product_uom_code
                  FROM   xx_qp_pricing_attributes_stg XQPA
                  WHERE  XQPA.orig_sys_header_ref = p_orig_sys_header_ref
                  AND    XQPA.orig_sys_line_ref = lt_op_line(i).orig_sys_line_ref
                  AND    load_batch_id = p_batch_id;

                  -- ---------------------------------
                  -- Validate whether the item exists
                  -- ---------------------------------
                  validate_inventory_item_id(
                                             p_inventory_item  => lc_product_attr_value
                                             ,p_uom_code       => lc_product_uom_code
                                             ,x_inv_item       => ln_inv_item
                                             ,x_status         => lc_status
                                            );

                    IF lc_status <> 'NE' THEN
                      x_status    := 'E';
                      lc_err_flag := 'E';
                      EXIT;

                    ELSE

                         -- --------------------------------------------------------------
                         -- Derive the operand for that item from the price_list ZONE_71
                         -- --------------------------------------------------------------
                         SELECT QLL.operand
                         INTO   ln_q_operand
                         FROM   qp_list_headers_tl QLHT,
                                qp_list_headers_b QLH,
                                qp_list_lines QLL,
                                qp_pricing_attributes QPA
                         WHERE  QLHT.list_header_id    = QLH.list_header_id
                         AND    QLH.list_header_id     = QLL.list_header_id
                         AND    QLL.list_line_id       = QPA.list_line_id
                         AND    UPPER(QLHT.name)       = UPPER(G_ZONE_71)
                         AND    QPA.product_attr_value = TO_CHAR(ln_inv_item);

                         ln_value := ln_value + ln_q_operand;
                    END IF; -- lc_status <> 'NE'

               ELSE
                   x_status  := 'E';
                   lc_err_flag := 'E';
                   EXIT;
               END IF;  -- lt_op_line(i).operand = 0
           END LOOP;

           IF lc_err_flag = 'S' THEN
              x_operand := ln_r_operand/(ln_value/100);
              x_status  := 'NE';
           END IF;

        ELSE
             x_status  := 'E';

        END IF; -- lt_op_line.COUNT <> 0
     END IF; -- lc_exists = 'Y'

   ELSE
      x_status  := 'E';

   END IF; -- ln_line_no <> 0 

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_status := 'E';
   WHEN OTHERS THEN
       x_status := SQLERRM;
END get_operand;

-- +====================================================================+
-- | Name        :  validate_records                                    |
-- |                                                                    |
-- | Description :  This procedure is invoked to validate the records   |
-- |                with process flag = 2 for a particular batch        |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- |                                                                    |
-- +====================================================================+

PROCEDURE validate_records(
                           p_batch_id IN  NUMBER
                           ,x_retcode OUT NOCOPY VARCHAR2
                           ,x_errbuf  OUT NOCOPY VARCHAR2
                          )
IS

-- -----------------------------------------------------
-- Local Variables Declaration
-- -----------------------------------------------------
EX_NO_VALID_DATA           EXCEPTION;
lc_err_hdr_msg             VARCHAR2(2000);
lc_err_line_msg            VARCHAR2(03);
lc_err_pric_attrib         VARCHAR2(03);
lc_err_qualifiers          VARCHAR2(03);
lc_err_msg                 VARCHAR2(2000);
ln_org_id                  PLS_INTEGER;
lc_err_arithmetic_operator VARCHAR2(03);
lc_err_operator_code       VARCHAR2(03);
ln_hdr_index               PLS_INTEGER := 0;
ln_line_index              PLS_INTEGER := 0;
ln_pric_attrib_index       PLS_INTEGER := 0;
ln_qual_index              PLS_INTEGER := 0;
ln_phase_id                PLS_INTEGER;
ln_inv_item                PLS_INTEGER;
ln_list_line_id            PLS_INTEGER;
ln_operand                 PLS_INTEGER;
lc_staging_column_value    VARCHAR2(100);
lc_exception_log           VARCHAR2(100);
lc_err_int_msg             VARCHAR2(2000);

-- ----------------------------------------------------------------
-- Cursor to fetch the records from the header staging table with
-- process_flag IN 1 or 2 or 3 of a batch
-- ----------------------------------------------------------------
CURSOR lcu_header
IS
SELECT XQPL.rowid, XQPL.*
FROM   xx_qp_list_headers_stg XQPL
WHERE  XQPL.process_flag IN (1,2,3)
AND    XQPL.load_batch_id = p_batch_id
ORDER BY XQPL.control_id;

-- -------------------------------------------------
-- Table Type for holding header staging table data
-- -------------------------------------------------
TYPE header_tbl_type IS TABLE OF lcu_header%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_header header_tbl_type;

-- ----------------------------------------------------------
-- Table Type for holding rowid of header staging table
-- ----------------------------------------------------------
TYPE hdr_row_id_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_hdr_row_id hdr_row_id_tbl_type;

-- ----------------------------------------------------------
-- Table Type for holding process_flag of header staging table
-- ----------------------------------------------------------
TYPE hdr_process_flag_tbl_type IS TABLE OF xx_qp_list_headers_stg.process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_hdr_process_flag hdr_process_flag_tbl_type;

-- ----------------------------------------------------------------
-- Cursor to fetch the records from the line staging table with
-- process_flag IN 1 or 2 or 3 for a particular header of a batch
-- ----------------------------------------------------------------
CURSOR lcu_line(
                p_header_orig IN VARCHAR2
                ,p_batch_id   IN NUMBER
               )
IS
SELECT XQLL.rowid,XQLL.*
FROM   xx_qp_list_lines_stg XQLL
WHERE  XQLL.process_flag IN (1,2,3)
AND    XQLL.orig_sys_header_ref = p_header_orig
AND    XQLL.load_batch_id = p_batch_id
ORDER BY XQLL.control_id;

-- -----------------------------------------------
-- Table Type for holding line staging table data
-- -----------------------------------------------
TYPE line_tbl_type IS TABLE OF lcu_line%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_line line_tbl_type;

-- --------------------------------------------------------
-- Table Type for holding rowid of line staging table
-- --------------------------------------------------------
TYPE line_row_id_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_line_row_id line_row_id_tbl_type;

-- --------------------------------------------------------
-- Table Type for holding process_flag of line staging table
-- --------------------------------------------------------

TYPE line_process_flag_tbl_type IS TABLE OF xx_qp_list_lines_stg.process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_line_process_flag line_process_flag_tbl_type;

-- ---------------------------------------------------------------------------
-- Cursor to fetch the records from the pricing attributes staging table with
-- process_flag IN 1 or 2 or 3 for a particular header and a line of a batch
-- ---------------------------------------------------------------------------
CURSOR lcu_pric_attrib(
                       p_header_orig IN VARCHAR2
                       ,p_line_ref   IN VARCHAR2
                       ,p_batch_id   IN NUMBER
                      )
IS
SELECT XQPA.rowid,XQPA.*
FROM   xx_qp_pricing_attributes_stg XQPA
WHERE  XQPA.process_flag IN (1,2,3)
AND    XQPA.orig_sys_header_ref = p_header_orig
AND    XQPA.orig_sys_line_ref   = p_line_ref
AND    XQPA.load_batch_id = p_batch_id
ORDER BY XQPA.control_id;

-- -------------------------------------------------------------
-- Table Type for holding pricing attributes staging table data
-- -------------------------------------------------------------
TYPE pric_attrib_tbl_type IS TABLE OF lcu_pric_attrib%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_pric_attrib pric_attrib_tbl_type;

-- ----------------------------------------------------------------------
-- Table Type for holding rowid of pricing attributes staging table
-- ----------------------------------------------------------------------
TYPE pric_row_id_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_pric_row_id pric_row_id_tbl_type;

-- ----------------------------------------------------------------------
-- Table Type for holding process_flag of pricing attributes staging table
-- ----------------------------------------------------------------------

TYPE pric_process_flag_tbl_type IS TABLE OF xx_qp_pricing_attributes_stg.process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_pric_process_flag pric_process_flag_tbl_type;


-- ---------------------------------------------------------------------------
-- Cursor to fetch the records from the qualifiers staging table with
-- process_flag IN 1 or 2 or 3 for a particular header and a line of a batch
-- ---------------------------------------------------------------------------
CURSOR lcu_qualifiers(
                      p_header_orig IN VARCHAR2
                      ,p_batch_id   IN NUMBER
                     )
IS
SELECT XQQS.rowid, XQQS.*
FROM   xx_qp_qualifiers_stg XQQS
WHERE  XQQS.process_flag IN (1,2,3)
AND    XQQS.orig_sys_header_ref = p_header_orig
AND    XQQS.load_batch_id = p_batch_id
ORDER BY XQQS.control_id;

-- -----------------------------------------------------
-- Table Type for holding qualifiers staging table data
-- -----------------------------------------------------
TYPE qualifiers_tbl_type IS TABLE OF lcu_qualifiers%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_qualifiers qualifiers_tbl_type;


-- -------------------------------------------------------------
-- Table Type for holding rowid of qualfiers staging table
-- -------------------------------------------------------------
TYPE qualifiers_row_id_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_qualifiers_row_id qualifiers_row_id_tbl_type;

-- -------------------------------------------------------------
-- Table Type for holding process_flag of qualfiers staging table
-- -------------------------------------------------------------
TYPE qualifiers_flag_tbl_type IS TABLE OF xx_qp_qualifiers_stg.process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_qualifiers_flag qualifiers_flag_tbl_type;

BEGIN

   -- -------------------------------
   -- Validate list_type_code = 'PRO'
   -- -------------------------------
   get_list_type_code(
                      x_return_status  => gc_pro_flag
                      ,p_batch_id      => p_batch_id
                     );

   -- ------------------------------------------------------------------
   -- Get the records from the header staging table into the table type
   -- ------------------------------------------------------------------
   OPEN  lcu_header;
   FETCH lcu_header BULK COLLECT INTO lt_header;
   CLOSE lcu_header;

   IF lt_header.count <> 0 THEN

      FOR i IN 1 .. lt_header.COUNT
      LOOP
          BEGIN

             ln_hdr_index := ln_hdr_index + 1;
             lt_hdr_row_id(ln_hdr_index) :=   lt_header(i).rowid;
             lc_err_hdr_msg := 'S';

             -- ---------------------------------------
             -- Validate the name of a header
             -- ---------------------------------------
             IF lt_header(i).name IS NULL THEN
                log_procedure(
                              p_control_id            => lt_header(i).control_id
                              ,p_source_system_code   => lt_header(i).source_system_code
                              ,p_procedure_name       => 'VALIDATE_RECORDS'
                              ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                              ,p_staging_column_name  => 'NAME'
                              ,p_staging_column_value => 'NULL'
                              ,p_source_system_ref    => lt_header(i).source_system_ref
                              ,p_batch_id             => p_batch_id
                              ,p_exception_log        => 'Name cannot be null'
                              ,p_oracle_error_code    => NULL
                              ,p_oracle_error_msg     => NULL
                             );
                lc_err_hdr_msg := 'E';
             END IF;

             -- ---------------------------------------
             -- Validate the description of a header
             -- ---------------------------------------
             IF lt_header(i).description IS NULL THEN
                log_procedure(
                              p_control_id            => lt_header(i).control_id
                              ,p_source_system_code   => lt_header(i).source_system_code
                              ,p_procedure_name       => 'VALIDATE_RECORDS'
                              ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                              ,p_staging_column_name  => 'DESCRIPTION'
                              ,p_staging_column_value => 'NULL'
                              ,p_source_system_ref    => lt_header(i).source_system_ref
                              ,p_batch_id             => p_batch_id
                              ,p_exception_log        => 'Description cannot be null'
                              ,p_oracle_error_code    => NULL
                              ,p_oracle_error_msg     => NULL
                             );
                lc_err_hdr_msg := 'E';
             END IF;

             -- ---------------------------------------
             -- Validate the currency code of a header
             -- ---------------------------------------
             IF lt_header(i).currency_code IS NOT NULL THEN
                validate_currency_code(
                                       p_currency_code     => lt_header(i).currency_code
                                       ,x_err_curr_msg     => lc_err_msg
                                      );
                CASE lc_err_msg
                    WHEN 'E' THEN
                         log_procedure(
                                       p_control_id            => lt_header(i).control_id
                                       ,p_source_system_code   => lt_header(i).source_system_code
                                       ,p_procedure_name       => 'VALIDATE_CURRENCY_CODE'
                                       ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                                       ,p_staging_column_name  => 'CURRENCY_CODE'
                                       ,p_staging_column_value => lt_header(i).currency_code
                                       ,p_source_system_ref    => lt_header(i).source_system_ref
                                       ,p_batch_id             => p_batch_id
                                       ,p_exception_log        => 'Not a valid Currency Code'
                                       ,p_oracle_error_code    => NULL
                                       ,p_oracle_error_msg     => NULL
                                      );
                         lc_err_hdr_msg := 'E';
                    WHEN 'NE' THEN
                         NULL;
                    ELSE
                        log_procedure(
                                      p_control_id            => lt_header(i).control_id
                                      ,p_source_system_code   => lt_header(i).source_system_code
                                      ,p_procedure_name       => 'VALIDATE_CURRENCY_CODE'
                                      ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                                      ,p_staging_column_name  => 'CURRENCY_CODE'
                                      ,p_staging_column_value => lt_header(i).currency_code
                                      ,p_source_system_ref    => lt_header(i).source_system_ref
                                      ,p_batch_id             => p_batch_id
                                      ,p_exception_log        => NULL
                                      ,p_oracle_error_code    => NULL
                                      ,p_oracle_error_msg     => lc_err_msg
                                     );
                        lc_err_hdr_msg := 'E';
                END CASE;
             END IF;

             -- ---------------------------------------
             -- Validate the org_code of a header
             -- ---------------------------------------
             IF lt_header(i).org_code IS NOT NULL THEN
               validate_operating_unit(
                                       p_name        => lt_header(i).org_code
                                       ,x_org_id     => ln_org_id
                                       ,x_status     => lc_err_msg
                                      );
                CASE lc_err_msg
                    WHEN 'E' THEN
                         log_procedure(
                                       p_control_id            => lt_header(i).control_id
                                       ,p_source_system_code   => lt_header(i).source_system_code
                                       ,p_procedure_name       => 'VALIDATE_OPERATING_UNIT'
                                       ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                                       ,p_staging_column_name  => 'ORG_CODE'
                                       ,p_staging_column_value => lt_header(i).org_code
                                       ,p_source_system_ref    => lt_header(i).source_system_ref
                                       ,p_batch_id             => p_batch_id
                                       ,p_exception_log        => 'Not a valid Operating Unit'
                                       ,p_oracle_error_code    => NULL
                                       ,p_oracle_error_msg     => NULL
                                      );
                         lc_err_hdr_msg := 'E';
                    WHEN 'NE' THEN
                         NULL;
                    ELSE
                        log_procedure(
                                      p_control_id            => lt_header(i).control_id
                                      ,p_source_system_code   => lt_header(i).source_system_code
                                      ,p_procedure_name       => 'VALIDATE_OPERATING_UNIT'
                                      ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                                      ,p_staging_column_name  => 'ORG_CODE'
                                      ,p_staging_column_value => lt_header(i).org_code
                                      ,p_source_system_ref    => lt_header(i).source_system_ref
                                      ,p_batch_id             => p_batch_id
                                      ,p_exception_log        => NULL
                                      ,p_oracle_error_code    => NULL
                                      ,p_oracle_error_msg     => lc_err_msg
                                     );
                        lc_err_hdr_msg := 'E';
                END CASE;
             END IF;

             -- ----------------------------------------------------------------------------------------
             -- Validate the operand if attribute12 is in '2A'/'2B' and attribute10 is greater than 1
             --  of a header
             -- ----------------------------------------------------------------------------------------
             IF ((lt_header(i).attribute12 ='2A') AND (lt_header(i).attribute10 > 1)) THEN
               get_operand(
                           p_orig_sys_header_ref   => lt_header(i).orig_sys_header_ref
                           ,p_batch_id             => p_batch_id
                           ,x_operand              => ln_operand
                           ,x_status               => lc_err_int_msg
                          );
               CASE lc_err_int_msg
                   WHEN 'N' THEN
                       log_procedure(
                                     p_control_id            => lt_header(i).control_id
                                     ,p_source_system_code   => lt_header(i).source_system_code
                                     ,p_procedure_name       => 'GET_OPERAND'
                                     ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                                     ,p_staging_column_name  => 'ATTRIBUTE12'
                                     ,p_staging_column_value => lt_header(i).attribute12
                                     ,p_source_system_ref    => lt_header(i).source_system_ref
                                     ,p_batch_id             => p_batch_id
                                     ,p_exception_log        => 'Error in operand derivation'
                                     ,p_oracle_error_code    => NULL
                                     ,p_oracle_error_msg     => NULL
                                    );
                       lc_err_hdr_msg := 'E';
                   WHEN 'NE' THEN
                       NULL;
                   ELSE
                       log_procedure(
                                     p_control_id           => lt_header(i).control_id
                                     ,p_source_system_code   => lt_header(i).source_system_code
                                     ,p_procedure_name       => 'GET_OPERAND'
                                     ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                                     ,p_staging_column_name  => 'ATTRIBUTE12'
                                     ,p_staging_column_value => lt_header(i).attribute12
                                     ,p_source_system_ref    => lt_header(i).source_system_ref
                                     ,p_batch_id             => p_batch_id
                                     ,p_exception_log        => NULL
                                     ,p_oracle_error_code    => NULL
                                     ,p_oracle_error_msg     => lc_err_msg
                                    );
                       lc_err_hdr_msg := 'E';
               END CASE;
             END IF;
              

             -- --------------------------------------
             -- Check if the validation has failed
             -- ---------------------------------------
             IF  lc_err_hdr_msg = 'S' THEN
                 -- ---------------------------------------
                 -- Assign the process_flag of the header
                 -- ---------------------------------------
                 lt_hdr_process_flag(ln_hdr_index) := 4;
             ELSE
                 -- ---------------------------------------
                 -- Assign the process_flag of the header
                 -- ---------------------------------------
                 lt_hdr_process_flag(ln_hdr_index) := 3;
             END IF;

             -- ----------------------------------------------------------------------
             -- Get the records from the qualifiers staging table into the table type
             -- ----------------------------------------------------------------------
             OPEN lcu_qualifiers(
                                 p_header_orig  => lt_header(i).orig_sys_header_ref
                                 ,p_batch_id    => p_batch_id
                                );
             LOOP
                 BEGIN
                      FETCH lcu_qualifiers BULK COLLECT INTO lt_qualifiers LIMIT G_LIMIT_SIZE;

                      IF lt_qualifiers.COUNT <> 0 THEN
                        FOR l IN 1 .. lt_qualifiers.COUNT
                        LOOP
                            BEGIN
                                 ln_qual_index := ln_qual_index + 1;
                                 lt_qualifiers_row_id(ln_qual_index) := lt_qualifiers(l).rowid;
                                 lc_err_qualifiers := 'S';

                                 -- ----------------------------------------------------------------------
                                 -- Validate the comparison_operator_code of a qualifier
                                 -- ----------------------------------------------------------------------
                                 IF lt_qualifiers(l).comparison_operator_code IS NOT NULL THEN
                                   validate_comparision_operator(
                                                                 p_comparision_operator_code  => lt_qualifiers(l).comparison_operator_code
                                                                 ,x_err_operator_code         => lc_err_operator_code
                                                                 ,x_status                    => lc_err_msg
                                                                );
                                   CASE lc_err_msg
                                       WHEN 'E' THEN
                                           log_procedure(
                                                         p_control_id            => lt_qualifiers(l).control_id
                                                         ,p_source_system_code   => lt_qualifiers(l).source_system_code
                                                         ,p_procedure_name       => 'VALIDATE_COMPARISION_OPERATOR'
                                                         ,p_staging_table_name   => 'XX_QP_QUALIFIERS_STG'
                                                         ,p_staging_column_name  => 'COMPARISON_OPERATOR_CODE'
                                                         ,p_staging_column_value => lt_qualifiers(l).comparison_operator_code
                                                         ,p_source_system_ref    => lt_qualifiers(l).source_system_ref
                                                         ,p_batch_id             => p_batch_id
                                                         ,p_exception_log        => 'Not a valid Comparision Operator'
                                                         ,p_oracle_error_code    => NULL
                                                         ,p_oracle_error_msg     => NULL
                                                        );
                                           lc_err_qualifiers := 'E';
                                       WHEN 'NE' THEN
                                           NULL;
                                       ELSE
                                           log_procedure(
                                                         p_control_id           => lt_qualifiers(l).control_id
                                                         ,p_source_system_code   => lt_qualifiers(l).source_system_code
                                                         ,p_procedure_name       => 'VALIDATE_COMPARISION_OPERATOR'
                                                         ,p_staging_table_name   => 'XX_QP_QUALIFIERS_STG'
                                                         ,p_staging_column_name  => 'COMPARISON_OPERATOR_CODE'
                                                         ,p_staging_column_value => lt_qualifiers(l).comparison_operator_code
                                                         ,p_source_system_ref    => lt_qualifiers(l).source_system_ref
                                                         ,p_batch_id             => p_batch_id
                                                         ,p_exception_log        => NULL
                                                         ,p_oracle_error_code    => NULL
                                                         ,p_oracle_error_msg     => lc_err_msg
                                                        );
                                           lc_err_qualifiers := 'E';
                                   END CASE;
                                 END IF;

                                 IF lc_err_qualifiers = 'S' THEN
                                   -- -----------------------------------------------------
                                   -- Assign the process_flag of qualifiers
                                   -- -----------------------------------------------------
                                   lt_qualifiers_flag(ln_qual_index) := 4;
                                 ELSE
                                     -- ----------------------------------------------------
                                     -- Assign the process_flag of qualifiers
                                     -- -----------------------------------------------------
                                     lt_qualifiers_flag(ln_qual_index)   := 3;
                                     -- ----------------------------------------------------
                                     -- Assign the process_flag of header
                                     -- -----------------------------------------------------
                                     lt_hdr_process_flag(ln_hdr_index)   := 3;
                                 END IF;

                            EXCEPTION
                               WHEN OTHERS THEN
                                   x_errbuf := 'Error in validate_records inside qualifiers loop : '||SQLERRM;
                                   display_log(x_errbuf);
                                   x_retcode := 2;
                                   log_procedure(
                                                 p_control_id           => NULL
                                                 ,p_source_system_code   => NULL
                                                 ,p_procedure_name       => NULL
                                                 ,p_staging_table_name   => 'XX_QP_QUALIFIERS_STG'
                                                 ,p_staging_column_name  => NULL
                                                 ,p_staging_column_value => NULL
                                                 ,p_source_system_ref    => NULL
                                                 ,p_batch_id             => p_batch_id
                                                 ,p_exception_log        => NULL
                                                 ,p_oracle_error_code    => SQLCODE
                                                 ,p_oracle_error_msg     => SQLERRM
                                                );
                            END;

                        END LOOP; -- lt_qualifiers

                        FORALL ln_qual_index IN lt_qualifiers_row_id.FIRST .. lt_qualifiers_row_id.LAST
                        UPDATE xx_qp_qualifiers_stg XQQS
                        SET    XQQS.process_flag = lt_qualifiers_flag(ln_qual_index)
                        WHERE  XQQS.rowid = lt_qualifiers_row_id(ln_qual_index);

                      END IF; -- lt_qualifiers.COUNT


                 EXCEPTION
                    WHEN OTHERS THEN
                        IF lcu_qualifiers%ISOPEN THEN
                          CLOSE lcu_qualifiers;
                        END IF;
                        x_errbuf := 'Error in validate_records inside qualifiers loop : '||SQLERRM;
                        x_retcode := 2;
                        display_log(x_errbuf);
                        log_procedure(
                                      p_control_id            => NULL
                                      ,p_source_system_code   => NULL
                                      ,p_procedure_name       => NULL
                                      ,p_staging_table_name   => 'XX_QP_QUALIFIERS_STG'
                                      ,p_staging_column_name  => NULL
                                      ,p_staging_column_value => NULL
                                      ,p_source_system_ref    => NULL
                                      ,p_batch_id             => p_batch_id
                                      ,p_exception_log        => NULL
                                      ,p_oracle_error_code    => SQLCODE
                                      ,p_oracle_error_msg     => SQLERRM
                                     );
                 END;

             EXIT WHEN lcu_qualifiers%NOTFOUND;
             END LOOP;
             CLOSE lcu_qualifiers;

             -- ------------------------------------------------------------------
             -- Get the records from the line staging table into the table type
             -- ------------------------------------------------------------------
             OPEN  lcu_line(
                            p_header_orig  => lt_header(i).orig_sys_header_ref
                            ,p_batch_id    => p_batch_id
                           );
             LOOP
                 BEGIN

                     FETCH lcu_line BULK COLLECT INTO lt_line LIMIT G_LIMIT_SIZE;
                     IF lt_line.COUNT <> 0 THEN

                        FOR j IN 1 .. lt_line.COUNT
                        LOOP
                            BEGIN

                                 ln_line_index := ln_line_index + 1;
                                 lt_line_row_id(ln_line_index) := lt_line(j).rowid;
                                 lc_err_line_msg := 'S';

                                 -- --------------------------------------------------
                                 -- Validate the  list_line_type_code of a line
                                 -- --------------------------------------------------
                                 IF lt_line(j).list_line_type_code IS NOT NULL THEN

                                   validate_line_type_code(
                                                           p_line_type_code => lt_line(j).list_line_type_code
                                                           ,x_err_line_code  => lc_err_msg
                                                          );

                                   CASE lc_err_msg
                                       WHEN 'E' THEN
                                           log_procedure(
                                                         p_control_id            => lt_line(j).control_id
                                                         ,p_source_system_code   => lt_line(j).source_system_code
                                                         ,p_procedure_name       => 'VALIDATE_LINE_TYPE_CODE'
                                                         ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                         ,p_staging_column_name  => 'LIST_LINE_TYPE_CODE'
                                                         ,p_staging_column_value => lt_line(j).list_line_type_code
                                                         ,p_source_system_ref    => lt_line(j).source_system_ref
                                                         ,p_batch_id             => p_batch_id
                                                         ,p_exception_log        => 'Not a valid List Line Type Code'
                                                         ,p_oracle_error_code    => NULL
                                                         ,p_oracle_error_msg     => NULL
                                                        );
                                           lc_err_line_msg := 'E';
                                       WHEN 'NE' THEN
                                           NULL;
                                       ELSE
                                           log_procedure(
                                                         p_control_id            => lt_line(j).control_id
                                                         ,p_source_system_code   => lt_line(j).source_system_code
                                                         ,p_procedure_name       => 'VALIDATE_LINE_TYPE_CODE'
                                                         ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                         ,p_staging_column_name  => 'LIST_LINE_TYPE_CODE'
                                                         ,p_staging_column_value => lt_line(j).list_line_type_code
                                                         ,p_source_system_ref    => lt_line(j).source_system_ref
                                                         ,p_batch_id             => p_batch_id
                                                         ,p_exception_log        => NULL
                                                         ,p_oracle_error_code    => NULL
                                                         ,p_oracle_error_msg     => lc_err_msg
                                                         );
                                           lc_err_line_msg := 'E';
                                   END CASE;
                                 END IF;

                                 -- -----------------------------------------------------
                                 -- Validate the phase_id if modifier_level_code IS NULL
                                 -- -----------------------------------------------------
                                 IF lt_line(j).modifier_level_code IS NULL THEN
                                             
                                   log_procedure(
                                                 p_control_id            => lt_line(j).control_id
                                                 ,p_source_system_code   => lt_line(j).source_system_code
                                                 ,p_procedure_name       => 'VALIDATE_RECORDS'
                                                 ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                 ,p_staging_column_name  => 'MODIFIER_LEVEL_CODE'
                                                 ,p_staging_column_value => lt_line(j).modifier_level_code
                                                 ,p_source_system_ref    => lt_line(j).source_system_ref
                                                 ,p_batch_id             => p_batch_id
                                                 ,p_exception_log        => 'MODIFIER_LEVEL_CODE Cannot be Null'
                                                 ,p_oracle_error_code    => NULL
                                                 ,p_oracle_error_msg     => NULL
                                                );
                                   lc_err_line_msg := 'E';
                                 
                                    
                                 ELSE
                                             
                                     -- --------------------------------------------------
                                     -- Validate the modifier_level_code
                                     -- --------------------------------------------------
                                     validate_modifier_level_code(
                                                                  p_modifier_level_code => lt_line(j).modifier_level_code
                                                                  ,x_err_mod_code        => lc_err_msg
                                                                 );

                                     CASE lc_err_msg
                                         WHEN 'E' THEN
                                             log_procedure(
                                                           p_control_id            => lt_line(j).control_id
                                                           ,p_source_system_code   => lt_line(j).source_system_code
                                                           ,p_procedure_name       => 'VALIDATE_MODIFIER_LEVEL_CODE'
                                                           ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                           ,p_staging_column_name  => 'MODIFIER_LEVEL_CODE'
                                                           ,p_staging_column_value => lt_line(j).modifier_level_code
                                                           ,p_source_system_ref    => lt_line(j).source_system_ref
                                                           ,p_batch_id             => p_batch_id
                                                           ,p_exception_log        => 'Not a valid Modifier Level Code'
                                                           ,p_oracle_error_code    => NULL
                                                           ,p_oracle_error_msg     => NULL
                                                          );
                                             lc_err_line_msg := 'E';
                                         WHEN 'NE' THEN
                                             derive_phase_id(
                                                             p_modifier_level_code  => lt_line(j).modifier_level_code
                                                             ,x_phase_id            => ln_phase_id
                                                             ,x_status              => lc_err_int_msg
                                                            );
                                                            
                                             IF lt_line(j).modifier_level_code = 'LINE' THEN
                                               lc_staging_column_value := 'LINE';
                                               lc_exception_log        := 'Phase Id does not exist when modifier_level_code = LINE';
                                             ELSIF lt_line(j).modifier_level_code = 'ORDER' THEN
                                                  lc_staging_column_value := 'ORDER';
                                                  lc_exception_log        := 'Phase Id does not exist when modifier_level_code = ORDER';
                                             ELSE
                                                  lc_staging_column_value := 'LINEGROUP';
                                                  lc_exception_log        := 'Phase Id does not exist when modifier_level_code = LINEGROUP';
                                             END IF;
                                                      
                                             CASE lc_err_int_msg
                                                 WHEN 'E' THEN
                                                     log_procedure(
                                                                   p_control_id            => lt_line(j).control_id
                                                                   ,p_source_system_code   => lt_line(j).source_system_code
                                                                   ,p_procedure_name       => 'DERIVE_PHASE_ID'
                                                                   ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                                   ,p_staging_column_name  => 'MODIFIER_LEVEL_CODE'
                                                                   ,p_staging_column_value => lc_staging_column_value
                                                                   ,p_source_system_ref    => lt_line(j).source_system_ref
                                                                   ,p_batch_id             => p_batch_id
                                                                   ,p_exception_log        => lc_exception_log
                                                                   ,p_oracle_error_code    => NULL
                                                                   ,p_oracle_error_msg     => NULL
                                                                  );
                                                     lc_err_line_msg := 'E';
                                                 WHEN 'NE' THEN
                                                     NULL;
                                                 ELSE
                                                     log_procedure(
                                                                   p_control_id            => lt_line(j).control_id
                                                                   ,p_source_system_code   => lt_line(j).source_system_code
                                                                   ,p_procedure_name       => 'DERIVE_PHASE_ID'
                                                                   ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                                   ,p_staging_column_name  => 'MODIFIER_LEVEL_CODE'
                                                                   ,p_staging_column_value => lc_staging_column_value
                                                                   ,p_source_system_ref    => lt_line(j).source_system_ref
                                                                   ,p_batch_id             => p_batch_id
                                                                   ,p_exception_log        => NULL
                                                                   ,p_oracle_error_code    => NULL
                                                                   ,p_oracle_error_msg     => lc_err_msg
                                                                  );
                                                     lc_err_line_msg := 'E';
                                             END CASE;
                                           

                                         ELSE
                                             log_procedure(
                                                           p_control_id            => lt_line(j).control_id
                                                           ,p_source_system_code   => lt_line(j).source_system_code
                                                           ,p_procedure_name       => 'VALIDATE_MODIFIER_LEVEL_CODE'
                                                           ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                           ,p_staging_column_name  => 'MODIFIER_LEVEL_CODE'
                                                           ,p_staging_column_value => lt_line(j).modifier_level_code
                                                           ,p_source_system_ref    => lt_line(j).source_system_ref
                                                           ,p_batch_id             => p_batch_id
                                                           ,p_exception_log        => NULL
                                                           ,p_oracle_error_code    => NULL
                                                           ,p_oracle_error_msg     => lc_err_msg
                                                          );
                                             lc_err_line_msg := 'E';

                                     END CASE; -- validate_modifier_level_code
                                 END IF; -- lt_line(j).modifier_level_code

                                 -- --------------------------------------------------
                                 -- Validate the  arithmetic_operator of a line
                                 -- --------------------------------------------------

                                 IF lt_line(j).arithmetic_operator IS NOT NULL THEN

                                   validate_arithmetic_operator(
                                                                p_arithmetic_operator      => lt_line(j).arithmetic_operator
                                                                ,x_err_arithmetic_operator => lc_err_arithmetic_operator
                                                                ,x_status                  => lc_err_msg
                                                               );
                                   CASE lc_err_msg
                                       WHEN 'E' THEN
                                           log_procedure(
                                                         p_control_id           => lt_line(j).control_id
                                                         ,p_source_system_code   => lt_line(j).source_system_code
                                                         ,p_procedure_name       => 'VALIDATE_ARITHMETIC_OPERATOR'
                                                         ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                         ,p_staging_column_name  => 'ARITHMETIC_OPERATOR'
                                                         ,p_staging_column_value => lt_line(j).arithmetic_operator
                                                         ,p_source_system_ref    => lt_line(j).source_system_ref
                                                         ,p_batch_id             => p_batch_id
                                                         ,p_exception_log        => 'Not a valid arithmetic operator'
                                                         ,p_oracle_error_code    => NULL
                                                         ,p_oracle_error_msg     => NULL
                                                        );
                                           lc_err_line_msg := 'E';
                                       WHEN 'NE' THEN
                                           NULL;
                                       ELSE
                                           log_procedure(
                                                         p_control_id           => lt_line(j).control_id
                                                         ,p_source_system_code   => lt_line(j).source_system_code
                                                         ,p_procedure_name       => 'VALIDATE_ARITHMETIC_OPERATOR'
                                                         ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                         ,p_staging_column_name  => 'ARITHMETIC_OPERATOR'
                                                         ,p_staging_column_value => lt_line(j).arithmetic_operator
                                                         ,p_source_system_ref    => lt_line(j).source_system_ref
                                                         ,p_batch_id             => p_batch_id
                                                         ,p_exception_log        => NULL
                                                         ,p_oracle_error_code    => NULL
                                                         ,p_oracle_error_msg     => lc_err_msg
                                                        );
                                           lc_err_line_msg := 'E';
                                       END CASE;
                                 END IF;

                                 IF lc_err_line_msg = 'S' THEN
                                   -- ---------------------------------------
                                   -- Assign the process_flag of the line
                                   -- ---------------------------------------
                                   lt_line_process_flag(ln_line_index) := 4;
                                 ELSE
                                     -- ---------------------------------------
                                     -- Assign the process_flag of the line
                                     -- ---------------------------------------
                                     lt_line_process_flag(ln_line_index) := 3;
                                     -- ---------------------------------------
                                     -- Assign the process_flag of the header
                                     -- ---------------------------------------
                                     lt_hdr_process_flag(ln_hdr_index) := 3;
                                 END IF;

                                 -- ------------------------------------------------------------------------------
                                 -- Get the records from the pricing attributes staging table into the table type
                                 -- ------------------------------------------------------------------------------
                                 OPEN lcu_pric_attrib(
                                                      p_header_orig  => lt_header(i).orig_sys_header_ref
                                                      ,p_line_ref    => lt_line(j).orig_sys_line_ref
                                                      ,p_batch_id    => p_batch_id
                                                     );

                                 LOOP
                                     BEGIN

                                          FETCH lcu_pric_attrib BULK COLLECT INTO lt_pric_attrib LIMIT G_LIMIT_SIZE;

                                          IF lt_pric_attrib.COUNT <> 0 THEN

                                            FOR k IN 1 .. lt_pric_attrib.COUNT
                                            LOOP
                                                BEGIN

                                                     ln_pric_attrib_index := ln_pric_attrib_index + 1;
                                                     lt_pric_row_id(ln_pric_attrib_index) := lt_pric_attrib(k).rowid;
                                                     lc_err_pric_attrib := 'S';

                                                     -- ------------------------------------------------------------------------------
                                                     -- Validate product_attr_value of a pricing attribute
                                                     -- ------------------------------------------------------------------------------
                                                     IF lt_pric_attrib(k).product_attr_value NOT IN ('ALL','ITEM_CATEGORY') THEN

                                                       validate_inventory_item_id(
                                                                                  p_inventory_item  => lt_pric_attrib(k).product_attr_value
                                                                                  ,p_uom_code       => lt_pric_attrib(k).product_uom_code
                                                                                  ,x_inv_item       => ln_inv_item
                                                                                  ,x_status         => lc_err_msg
                                                                                 );

                                                       CASE lc_err_msg
                                                           WHEN 'NE' THEN
                                                               NULL;
                                                           WHEN 'E' THEN
                                                               log_procedure(
                                                                             p_control_id           => lt_pric_attrib(k).control_id
                                                                             ,p_source_system_code   => lt_pric_attrib(k).source_system_code
                                                                             ,p_procedure_name       => 'VALIDATE_INVENTORY_ITEM_ID'
                                                                             ,p_staging_table_name   => 'XX_QP_PRICING_ATTRIBUTES_STG'
                                                                             ,p_staging_column_name  => 'PRODUCT_ATTR_VALUE'
                                                                             ,p_staging_column_value => lt_pric_attrib(k).product_attr_value
                                                                             ,p_source_system_ref    => lt_pric_attrib(k).source_system_ref
                                                                             ,p_batch_id             => p_batch_id
                                                                             ,p_exception_log        => 'Not a valid Inventory Item.'
                                                                             ,p_oracle_error_code    => NULL
                                                                             ,p_oracle_error_msg     => NULL
                                                                            );
                                                               lc_err_pric_attrib := 'E';
                                                           ELSE
                                                               log_procedure(
                                                                             p_control_id           => lt_pric_attrib(k).control_id
                                                                             ,p_source_system_code   => lt_pric_attrib(k).source_system_code
                                                                             ,p_procedure_name       => 'VALIDATE_INVENTORY_ITEM_ID'
                                                                             ,p_staging_table_name   => 'XX_QP_PRICING_ATTRIBUTES_STG'
                                                                             ,p_staging_column_name  => 'PRODUCT_ATTR_VALUE'
                                                                             ,p_staging_column_value => lt_pric_attrib(k).product_attr_value
                                                                             ,p_source_system_ref    => lt_pric_attrib(k).source_system_ref
                                                                             ,p_batch_id             => p_batch_id
                                                                             ,p_exception_log        => NULL
                                                                             ,p_oracle_error_code    => NULL
                                                                             ,p_oracle_error_msg     => lc_err_msg
                                                                            );
                                                               lc_err_pric_attrib := 'E';
                                                       END CASE;

                                                     END IF;

                                                     IF lc_err_pric_attrib = 'S' THEN
                                                       -- ----------------------------------------------------
                                                       -- Assign the process_flag of the pricing attribute
                                                       -- -----------------------------------------------------
                                                       lt_pric_process_flag(ln_pric_attrib_index) := 4;
                                                     ELSE
                                                         -- ----------------------------------------------------
                                                         -- Assign the process_flag of the pricing attribute
                                                         -- -----------------------------------------------------
                                                         lt_pric_process_flag(ln_pric_attrib_index) := 3;
                                                         -- ----------------------------------------------------
                                                         -- Assign the process_flag of the line
                                                         -- -----------------------------------------------------
                                                         lt_line_process_flag(ln_line_index) := 3;
                                                         -- ----------------------------------------------------
                                                         -- Assign the process_flag of the header
                                                         -- -----------------------------------------------------
                                                         lt_hdr_process_flag(ln_hdr_index) := 3;
                                                     END IF;

                                                EXCEPTION
                                                   WHEN OTHERS THEN
                                                       x_errbuf := 'Error in validate_records inside pricing attributes loop : '||SQLERRM;
                                                       display_log(x_errbuf);
                                                       x_retcode := 2;
                                                       log_procedure(
                                                                     p_control_id           => NULL
                                                                     ,p_source_system_code   => NULL
                                                                     ,p_procedure_name       => NULL
                                                                     ,p_staging_table_name   => 'XX_QP_PRICING_ATTRIBUTES_STG'
                                                                     ,p_staging_column_name  => NULL
                                                                     ,p_staging_column_value => NULL
                                                                     ,p_source_system_ref    => NULL
                                                                     ,p_batch_id             => p_batch_id
                                                                     ,p_exception_log        => NULL
                                                                     ,p_oracle_error_code    => SQLCODE
                                                                     ,p_oracle_error_msg     => SQLERRM
                                                                    );
                                                END;

                                            END LOOP; -- lt_pric_attrib.COUNT

                                            FORALL ln_pric_attrib_index IN lt_pric_row_id.FIRST .. lt_pric_row_id.LAST
                                            UPDATE xx_qp_pricing_attributes_stg XQPA
                                            SET    XQPA.process_flag = lt_pric_process_flag(ln_pric_attrib_index)
                                            WHERE  XQPA.rowid = lt_pric_row_id(ln_pric_attrib_index);

                                          END IF; -- lt_pric_attrib.COUNT

                                     EXCEPTION
                                        WHEN OTHERS THEN
                                            IF lcu_pric_attrib%ISOPEN THEN
                                              CLOSE lcu_pric_attrib;
                                            END IF;
                                            x_errbuf := 'Error in validate_records inside pricing attributes loop : '||SQLERRM;
                                            display_log(x_errbuf);
                                            x_retcode := 2;
                                            log_procedure(
                                                          p_control_id           => NULL
                                                          ,p_source_system_code   => NULL
                                                          ,p_procedure_name       => NULL
                                                          ,p_staging_table_name   => 'XX_QP_PRICING_ATTRIBUTES_STG'
                                                          ,p_staging_column_name  => NULL
                                                          ,p_staging_column_value => NULL
                                                          ,p_source_system_ref    => NULL
                                                          ,p_batch_id             => p_batch_id
                                                          ,p_exception_log        => NULL
                                                          ,p_oracle_error_code    => SQLCODE
                                                          ,p_oracle_error_msg     => SQLERRM
                                                         );
                                     END;

                                 EXIT WHEN lcu_pric_attrib%NOTFOUND;
                                 END LOOP;
                                 CLOSE lcu_pric_attrib;

                            EXCEPTION
                               WHEN OTHERS THEN
                                   x_errbuf := 'Error in validate_records inside line loop : '||SQLERRM;
                                   display_log(x_errbuf);
                                   x_retcode := 2;
                                   log_procedure(
                                                 p_control_id           => NULL
                                                 ,p_source_system_code   => NULL
                                                 ,p_procedure_name       => NULL
                                                 ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                                 ,p_staging_column_name  => NULL
                                                 ,p_staging_column_value => NULL
                                                 ,p_source_system_ref    => NULL
                                                 ,p_batch_id             => p_batch_id
                                                 ,p_exception_log        => NULL
                                                 ,p_oracle_error_code    => SQLCODE
                                                 ,p_oracle_error_msg     => SQLERRM
                                                );
                            END;
                        END LOOP;

                        FORALL ln_line_index IN lt_line_row_id.FIRST .. lt_line_row_id.LAST
                        UPDATE xx_qp_list_lines_stg XQLL
                        SET    XQLL.process_flag = lt_line_process_flag(ln_line_index)
                        WHERE  XQLL.rowid  = lt_line_row_id(ln_line_index);

                     END IF; -- lt_line.COUNT

                 EXCEPTION
                    WHEN OTHERS THEN
                        IF lcu_line%ISOPEN THEN
                          CLOSE lcu_line;
                        END IF;
                        x_errbuf := 'Error in validate_records inside line loop : '||SQLERRM;
                        display_log(x_errbuf);
                        x_retcode := 2;
                        log_procedure(
                                      p_control_id            => NULL
                                      ,p_source_system_code   => NULL
                                      ,p_procedure_name       => NULL
                                      ,p_staging_table_name   => 'XX_QP_LIST_LINES_STG'
                                      ,p_staging_column_name  => NULL
                                      ,p_staging_column_value => NULL
                                      ,p_source_system_ref    => NULL
                                      ,p_batch_id             => p_batch_id
                                      ,p_exception_log        => NULL
                                      ,p_oracle_error_code    => SQLCODE
                                      ,p_oracle_error_msg     => SQLERRM
                                     );

                 END;

             EXIT WHEN lcu_line%NOTFOUND;
             END LOOP;
             CLOSE lcu_line;

          EXCEPTION
             WHEN OTHERS THEN
                 x_errbuf := 'Error in validate_records inside header loop : '||SQLERRM;
                 x_retcode := 2;
                 display_log(x_errbuf);
                 log_procedure(
                               p_control_id            => NULL
                               ,p_source_system_code   => NULL
                               ,p_procedure_name       => NULL
                               ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                               ,p_staging_column_name  => NULL
                               ,p_staging_column_value => NULL
                               ,p_source_system_ref    => NULL
                               ,p_batch_id             => p_batch_id
                               ,p_exception_log        => x_errbuf
                               ,p_oracle_error_code    => SQLCODE
                               ,p_oracle_error_msg     => SQLERRM
                              );
          END;

      END LOOP; -- lt_header

      -- ------------------------------------------------------------------------
      -- Update the records of the header staging table with its corresponding
      -- process_flag
      -- ------------------------------------------------------------------------
      BEGIN
         FORALL ln_hdr_index IN  lt_hdr_row_id.FIRST .. lt_hdr_row_id.LAST
         UPDATE xx_qp_list_headers_stg XQPL
         SET    XQPL.process_flag = lt_hdr_process_flag(ln_hdr_index)
         WHERE  XQPL.rowid = lt_hdr_row_id(ln_hdr_index);
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
             x_errbuf := 'Error while updating header records : '||SQLERRM;
             x_retcode := 2;
             display_log(x_errbuf);
             log_procedure(
                           p_control_id            => NULL
                           ,p_source_system_code   => NULL
                           ,p_procedure_name       => NULL
                           ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                           ,p_staging_column_name  => NULL
                           ,p_staging_column_value => NULL
                           ,p_source_system_ref    => NULL
                           ,p_batch_id             => p_batch_id
                           ,p_exception_log        => x_errbuf
                           ,p_oracle_error_code    => SQLCODE
                           ,p_oracle_error_msg     => SQLERRM
                          );
      END;

   ELSE
       RAISE EX_NO_VALID_DATA;
   END IF; -- lt_header.COUNT

EXCEPTION
   WHEN EX_NO_VALID_DATA THEN
       x_retcode := 1;
       log_procedure(
                     p_control_id            => NULL
                     ,p_source_system_code   => NULL
                     ,p_procedure_name       => NULL
                     ,p_staging_table_name   => 'XX_QP_LIST_HEADERS_STG'
                     ,p_staging_column_name  => NULL
                     ,p_staging_column_value => NULL
                     ,p_source_system_ref    => NULL
                     ,p_batch_id             => p_batch_id
                     ,p_exception_log        => 'There is no valid data in the staging table.'
                     ,p_oracle_error_code    => NULL
                     ,p_oracle_error_msg     => NULL
                    );
   WHEN OTHERS THEN
       x_retcode := 2;
       log_procedure(
                     p_control_id            => NULL
                     ,p_source_system_code   => NULL
                     ,p_procedure_name       => 'VALIDATE_RECORDS'
                     ,p_staging_table_name   => NULL
                     ,p_staging_column_name  => NULL
                     ,p_staging_column_value => NULL
                     ,p_source_system_ref    => NULL
                     ,p_batch_id             => p_batch_id
                     ,p_exception_log        => NULL
                     ,p_oracle_error_code    => SQLCODE
                     ,p_oracle_error_msg     => SQLERRM
                    );
END validate_records;

-- +====================================================================+
-- | Name        :  process_modifiers                                   |
-- |                                                                    |
-- | Description :  This procedure is invoked to process the records    |
-- |                to the EBS table by calling the API with            |
-- |                process flag = 5 for a particular batch             |
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- |                                                                    |
-- +====================================================================+


PROCEDURE process_modifiers(
                            p_batch_id IN  NUMBER
                            ,x_retcode OUT NOCOPY VARCHAR2
                           )

IS

-- -----------------------------
-- Local variable Declaration
-- -----------------------------
lc_active_flag             VARCHAR2(03);
ln_pro_hdr_index           PLS_INTEGER := 0;
ln_tbl_line_index          PLS_INTEGER := 0;
ln_tbl_pa_index            PLS_INTEGER := 0;
ln_tbl_qua_index           PLS_INTEGER := 0;
ln_operand                 NUMBER(10,2);
ln_phase_id                PLS_INTEGER;
ln_inventory_item_id       PLS_INTEGER;
ln_list_line_id            PLS_INTEGER;
l_data                     VARCHAR2(2000);
ln_pricing_phase_id        PLS_INTEGER;
l_count                    PLS_INTEGER  ;
l_status                   VARCHAR2(1000);
lc_status                  VARCHAR2(10);
ln_last_mod_parent_index   PLS_INTEGER := 0;
ln_mod_parent_index        PLS_INTEGER := 0;
ln_count                   PLS_INTEGER := 0;
lc_last_price_break_code   VARCHAR2(1000);
lc_price_break_code        VARCHAR2(1000);
lc_attribute7              VARCHAR2(240);

-- --------------------------------------------------------------------
-- IN Parameter Declaration of the API
-- ---------------------------------------------------------------------

l_modifier_list_rec        qp_modifiers_pub.modifier_list_rec_type         :=  qp_modifiers_pub.g_miss_modifier_list_rec;
l_miss_modifier_list_rec   qp_modifiers_pub.modifier_list_rec_type         :=  qp_modifiers_pub.g_miss_modifier_list_rec;
l_modifier_list_val_rec    qp_modifiers_pub.modifier_list_val_rec_type     :=  qp_modifiers_pub.g_miss_modifier_list_val_rec;

l_modifiers_tbl            qp_modifiers_pub.modifiers_tbl_type             :=  qp_modifiers_pub.g_miss_modifiers_tbl;
l_miss_modifiers_tbl       qp_modifiers_pub.modifiers_tbl_type             :=  qp_modifiers_pub.g_miss_modifiers_tbl;
l_modifiers_val_tbl        qp_modifiers_pub.modifiers_val_tbl_type         :=  qp_modifiers_pub.g_miss_modifiers_val_tbl;

l_qualifiers_rec_type      qp_qualifier_rules_pub.qualifiers_rec_type      :=  qp_qualifier_rules_pub.g_miss_qualifiers_rec;
l_miss_qualifiers_rec_type qp_qualifier_rules_pub.qualifiers_rec_type      :=  qp_qualifier_rules_pub.g_miss_qualifiers_rec;
l_qualifiers_tbl           qp_qualifier_rules_pub.qualifiers_tbl_type      :=  qp_qualifier_rules_pub.g_miss_qualifiers_tbl;
l_miss_qualifiers_tbl      qp_qualifier_rules_pub.qualifiers_tbl_type      :=  qp_qualifier_rules_pub.g_miss_qualifiers_tbl;
l_qualifiers_val_tbl       qp_qualifier_rules_pub.qualifiers_val_tbl_type  :=  qp_qualifier_rules_pub.g_miss_qualifiers_val_tbl;

l_pricing_attr_tbl         qp_modifiers_pub.pricing_attr_tbl_type          :=  qp_modifiers_pub.g_miss_pricing_attr_tbl;
l_miss_pricing_attr_tbl    qp_modifiers_pub.pricing_attr_tbl_type          :=  qp_modifiers_pub.g_miss_pricing_attr_tbl;
l_pricing_attr_val_tbl     qp_modifiers_pub.pricing_attr_val_tbl_type      :=  qp_modifiers_pub.g_miss_pricing_attr_val_tbl;

-- --------------------------------------------------------------------
-- OUT Parameter Declaration of the API
-- ---------------------------------------------------------------------

x_modifier_list_rec        qp_modifiers_pub.modifier_list_rec_type         :=  qp_modifiers_pub.g_miss_modifier_list_rec;
x_modifier_list_val_rec    qp_modifiers_pub.modifier_list_val_rec_type     :=  qp_modifiers_pub.g_miss_modifier_list_val_rec;

x_modifiers_tbl            qp_modifiers_pub.modifiers_tbl_type             :=  qp_modifiers_pub.g_miss_modifiers_tbl;
x_modifiers_val_tbl        qp_modifiers_pub.modifiers_val_tbl_type         :=  qp_modifiers_pub.g_miss_modifiers_val_tbl;

x_qualifiers_tbl           qp_qualifier_rules_pub.qualifiers_tbl_type      :=  qp_qualifier_rules_pub.g_miss_qualifiers_tbl;
x_qualifiers_val_tbl       qp_qualifier_rules_pub.qualifiers_val_tbl_type  :=  qp_qualifier_rules_pub.g_miss_qualifiers_val_tbl;

x_pricing_attr_tbl         qp_modifiers_pub.pricing_attr_tbl_type          :=  qp_modifiers_pub.g_miss_pricing_attr_tbl;
x_pricing_attr_val_tbl     qp_modifiers_pub.pricing_attr_val_tbl_type      :=  qp_modifiers_pub.g_miss_pricing_attr_val_tbl;

-- ----------------------------------------------------------------
-- Cursor to fetch the records from the header staging table with
-- process_flag = 5 of a particular batch
-- ----------------------------------------------------------------
CURSOR lcu_process_header(
                          p_batch_id IN NUMBER
                         )
IS
SELECT XQPL.rowid, XQPL.*
FROM   xx_qp_list_headers_stg XQPL
WHERE  XQPL.process_flag IN (4,5,6)
AND    XQPL.load_batch_id = p_batch_id
ORDER BY XQPL.control_id;

-- -------------------------------------------------
-- Table Type for holding header staging table data
-- -------------------------------------------------
TYPE pro_header_tbl_type IS TABLE OF lcu_process_header%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_pro_header pro_header_tbl_type;

-- -------------------------------------------------------------------
-- Table Type for holding rowid of header staging table
-- -------------------------------------------------------------------
TYPE pro_hdr_row_id_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_pro_hdr_row_id pro_hdr_row_id_tbl_type;

-- -------------------------------------------------------------------
-- Table Type for holding process_flag of header staging table
-- -------------------------------------------------------------------
TYPE hdr_pro_flag_tbl_type IS TABLE OF xx_qp_list_headers_stg.process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_hdr_pro_flag hdr_pro_flag_tbl_type;

-- ----------------------------------------------------------------
-- Cursor to fetch the records from the line staging table with
-- process_flag = 5 of a particular header for a particular batch
-- ----------------------------------------------------------------
CURSOR lcu_process_line(
                        p_header_orig IN VARCHAR2
                        ,p_batch_id   IN NUMBER
                       )
IS
SELECT XQLL.*
FROM   xx_qp_list_lines_stg XQLL
WHERE  XQLL.process_flag IN (4,5,6)
AND    XQLL.orig_sys_header_ref = p_header_orig
AND    XQLL.load_batch_id = p_batch_id
ORDER BY attribute7, (CASE list_line_type_code
                          WHEN 'PRG' THEN 1
                          WHEN 'PBH' THEN 2
                          WHEN 'OID' THEN 3
                          WHEN 'RLTD' THEN 4
                          WHEN 'DIS'  THEN 5
                      END);

-- -------------------------------------------------
-- Table Type for holding line staging table data
-- -------------------------------------------------
TYPE pro_line_tbl_type IS TABLE OF lcu_process_line%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_pro_line pro_line_tbl_type;

-- ------------------------------------------------------------------------------
-- Cursor to fetch the records from the pricing attributes staging table with
-- process_flag = 5 of a particular header and line for a particular batch
-- ------------------------------------------------------------------------------
CURSOR lcu_process_pric_attr(
                             p_header_orig IN VARCHAR2
                             ,p_line_orig  IN VARCHAR2
                             ,p_batch_id   IN NUMBER
                            )
IS
SELECT XQPA.*
FROM   xx_qp_pricing_attributes_stg XQPA
WHERE  XQPA.process_flag IN (4,5,6)
AND    XQPA.orig_sys_header_ref = p_header_orig
AND    XQPA.orig_sys_line_ref   = p_line_orig
AND    XQPA.load_batch_id = p_batch_id
ORDER BY XQPA.control_id;

-- -------------------------------------------------
-- Table Type for holding pricing attributes staging table data
-- -------------------------------------------------
TYPE pro_pric_attrib_tbl_type IS TABLE OF lcu_process_pric_attr%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_pro_pric_attrib pro_pric_attrib_tbl_type;

-- ------------------------------------------------------------------------------
-- Cursor to fetch the records from the qualifiers staging table with
-- process_flag = 5 of a particular header and line for a particular batch
-- ------------------------------------------------------------------------------
CURSOR lcu_pro_qualifiers(
                          p_header_orig IN VARCHAR2,
                          p_batch_id    IN NUMBER
                         )
IS
SELECT XQQS.*
FROM   xx_qp_qualifiers_stg XQQS
WHERE  XQQS.process_flag IN (4,5,6)
AND    XQQS.orig_sys_header_ref = p_header_orig
AND    XQQS.load_batch_id = p_batch_id
ORDER BY XQQS.control_id;

-- -------------------------------------------------
-- Table Type for holding qualifiers staging table data
-- -------------------------------------------------
TYPE pro_qual_tbl_type IS TABLE OF lcu_pro_qualifiers%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_pro_qual pro_qual_tbl_type;

BEGIN

   CASE gc_pro_flag
       WHEN 'S' THEN

           l_modifier_list_rec    :=  l_miss_modifier_list_rec;
           l_modifiers_tbl        :=  l_miss_modifiers_tbl;
           l_qualifiers_rec_type  :=  l_miss_qualifiers_rec_type;
           l_qualifiers_tbl       :=  l_miss_qualifiers_tbl;
           l_pricing_attr_tbl     :=  l_miss_pricing_attr_tbl;

           -- ------------------------------------------------------------------
           -- Get the records from the header staging table into the table type
           -- ------------------------------------------------------------------

           OPEN  lcu_process_header(p_batch_id);
           FETCH lcu_process_header BULK COLLECT INTO lt_pro_header;
           CLOSE lcu_process_header;

           IF lt_pro_header.COUNT <> 0 THEN

             FOR i IN 1 .. lt_pro_header.COUNT
             LOOP
                 BEGIN

                      OE_MSG_PUB.initialize;

                      -- ------------------------------------------------------------------
                      -- Create a savepoint for the header record
                      -- ------------------------------------------------------------------
                      SAVEPOINT s_header;

                      ln_pro_hdr_index := ln_pro_hdr_index + 1;
                      lt_pro_hdr_row_id(ln_pro_hdr_index) := lt_pro_header(i).rowid;
                      
                      -- ------------------------------------------------------------------
                      -- Setting up the modifier list record type
                      -- ------------------------------------------------------------------
                      l_modifier_list_rec.automatic_flag           := 'Y'; 
                      l_modifier_list_rec.comments                 := lt_pro_header(i).comments;
                      l_modifier_list_rec.context                  := G_HEADER_CONTEXT;
                      l_modifier_list_rec.created_by               := FND_GLOBAL.user_id;
                      l_modifier_list_rec.creation_date            := SYSDATE;
                      l_modifier_list_rec.currency_code            := lt_pro_header(i).currency_code;
                      l_modifier_list_rec.discount_lines_flag      := lt_pro_header(i).discount_lines_flag;
                      l_modifier_list_rec.end_date_active          := TRUNC(TO_DATE(TO_CHAR(lt_pro_header(i).end_date_active,'DD-MON-YYYY'),'DD-MON-YYYY'));
                      l_modifier_list_rec.freight_terms_code       := lt_pro_header(i).freight_terms_code;
                      l_modifier_list_rec.gsa_indicator            := lt_pro_header(i).gsa_indicator;
                      l_modifier_list_rec.last_updated_by          := FND_GLOBAL.user_id;
                      l_modifier_list_rec.last_update_date         := SYSDATE;
                      l_modifier_list_rec.last_update_login        := FND_GLOBAL.user_id;
                      l_modifier_list_rec.list_header_id           := FND_API.G_MISS_NUM;
                      l_modifier_list_rec.list_type_code           := G_LIST_TYPE_CODE;
                      l_modifier_list_rec.program_application_id   := NULL;
                      l_modifier_list_rec.program_id               := NULL;
                      l_modifier_list_rec.program_update_date      := NULL;
                      l_modifier_list_rec.prorate_flag             := NVL(lt_pro_header(i).prorate_flag,FND_API.G_MISS_CHAR); 
                      l_modifier_list_rec.request_id               := NULL;
                      l_modifier_list_rec.rounding_factor          := lt_pro_header(i).rounding_factor;
                      l_modifier_list_rec.ship_method_code         := lt_pro_header(i).ship_method_code;
                      l_modifier_list_rec.start_date_active        := TRUNC(TO_DATE(TO_CHAR(lt_pro_header(i).start_date_active,'DD-MON-YYYY'),'DD-MON-YYYY'));
                      l_modifier_list_rec.terms_id                 := lt_pro_header(i).terms_id;
                      l_modifier_list_rec.source_system_code       := G_SOURCE_SYSTEM_CODE;

                      IF (lt_pro_header(i).end_date_active IS NULL OR  lt_pro_header(i).end_date_active > SYSDATE) THEN
                        lc_active_flag  :=  'Y';
                      ELSE
                          lc_active_flag :=  'N';
                      END IF;

                      l_modifier_list_rec.active_flag              := lc_active_flag;
                      l_modifier_list_rec.parent_list_header_id    := NVL(lt_pro_header(i).parent_list_header_id,FND_API.G_MISS_NUM);
                      l_modifier_list_rec.start_date_active_first  := lt_pro_header(i).start_date_active_first;
                      l_modifier_list_rec.end_date_active_first    := lt_pro_header(i).end_date_active_first;
                      l_modifier_list_rec.active_date_first_type   := lt_pro_header(i).active_date_first_type;
                      l_modifier_list_rec.start_date_active_second := lt_pro_header(i).start_date_active_second;
                      l_modifier_list_rec.end_date_active_second   := lt_pro_header(i).end_date_active_second;
                      l_modifier_list_rec.active_date_second_type  := lt_pro_header(i).active_date_second_type;
                      l_modifier_list_rec.ask_for_flag             := 'Y';
                      l_modifier_list_rec.return_status            := NULL;
                      l_modifier_list_rec.db_flag                  := NULL;
                      l_modifier_list_rec.version_no               := lt_pro_header(i).version_no;
                      l_modifier_list_rec.operation                := QP_GLOBALS.G_OPR_CREATE;
                      l_modifier_list_rec.name                     := lt_pro_header(i).name;
                      l_modifier_list_rec.pte_code                 := G_PTE_CODE;
                      l_modifier_list_rec.description              := lt_pro_header(i).description;
                      l_modifier_list_rec.attribute8               := lt_pro_header(i).attribute8;
                      l_modifier_list_rec.attribute10              := lt_pro_header(i).attribute10;
                      l_modifier_list_rec.attribute11              := lt_pro_header(i).attribute11;
                      l_modifier_list_rec.attribute12              := lt_pro_header(i).attribute12;
                      l_modifier_list_rec.attribute13              := lt_pro_header(i).attribute13;
                      l_modifier_list_rec.attribute14              := lt_pro_header(i).attribute14;
                      l_modifier_list_rec.attribute15              := lt_pro_header(i).attribute15;
                      l_modifier_list_rec.attribute5               := lt_pro_header(i).attribute5;
                      l_modifier_list_rec.attribute4               := 'CPNWIZ';
                      

                      -- ------------------------------------------------------------------
                      -- Derive the operand for the line with attribute9 = 'Q'for that header
                      -- ------------------------------------------------------------------
                      IF lt_pro_header(i).attribute12 = '2A' AND lt_pro_header(i).attribute10 > 1 THEN

                        get_operand(
                                    p_orig_sys_header_ref  => lt_pro_header(i).orig_sys_header_ref
                                    ,p_batch_id             => p_batch_id
                                    ,x_operand              => ln_operand
                                    ,x_status               => lc_status
                                   );
                      END IF;

                      -- ------------------------------------------------------------------
                      -- Get the records from the line staging table into the table type
                      -- ------------------------------------------------------------------
                      OPEN lcu_process_line(
                                            p_header_orig => lt_pro_header(i).orig_sys_header_ref
                                            ,p_batch_id    => p_batch_id
                                           );
                      FETCH lcu_process_line BULK COLLECT INTO lt_pro_line;
                      CLOSE lcu_process_line;

                      IF lt_pro_line.COUNT <> 0 THEN
                      

                        FOR j IN 1 .. lt_pro_line.COUNT
                        LOOP
                            
                            -- ------------------------------------------------------------------
                            -- Setting up the modifier table type
                            -- ------------------------------------------------------------------
                            ln_tbl_line_index := ln_tbl_line_index + 1;
                            
                            l_modifiers_tbl(ln_tbl_line_index).arithmetic_operator   := lt_pro_line(j).arithmetic_operator;
                            l_modifiers_tbl(ln_tbl_line_index).attribute7            := lt_pro_line(j).attribute7;
                            l_modifiers_tbl(ln_tbl_line_index).attribute8            := lt_pro_line(j).attribute8;
                            l_modifiers_tbl(ln_tbl_line_index).attribute9            := lt_pro_line(j).attribute9;
                            l_modifiers_tbl(ln_tbl_line_index).attribute10           := lt_pro_line(j).attribute10;
                            l_modifiers_tbl(ln_tbl_line_index).automatic_flag        :='Y'; 
                            l_modifiers_tbl(ln_tbl_line_index).comments              := lt_pro_line(j).comments;
                            l_modifiers_tbl(ln_tbl_line_index).context               := G_HEADER_CONTEXT;
                            l_modifiers_tbl(ln_tbl_line_index).created_by            := FND_GLOBAL.user_id;
                            l_modifiers_tbl(ln_tbl_line_index).creation_date         := SYSDATE;
                            l_modifiers_tbl(ln_tbl_line_index).effective_period_uom  := lt_pro_line(j).effective_period_uom;
                            l_modifiers_tbl(ln_tbl_line_index).end_date_active       := TRUNC(TO_DATE(TO_CHAR(lt_pro_line(j).end_date_active,'DD-MON-YYYY'),'DD-MON-YYYY'));
                            l_modifiers_tbl(ln_tbl_line_index).estim_accrual_rate    := lt_pro_line(j).estim_accrual_rate;
                            
                            IF lt_pro_header(i).attribute12 = '2A' AND lt_pro_header(i).attribute10 > 1 AND UPPER(lt_pro_line(j).attribute9) = UPPER('Buy') THEN
                              l_modifiers_tbl(ln_tbl_line_index).operand  := 0;
                            ELSIF lt_pro_header(i).attribute12 = '2A' AND lt_pro_header(i).attribute10 > 1 AND UPPER(lt_pro_line(j).attribute9) = UPPER('Get') THEN
                                 l_modifiers_tbl(ln_tbl_line_index).operand  := ln_operand;
                            ELSE
                                IF lt_pro_line(j).operand <> 0 THEN
                                  l_modifiers_tbl(ln_tbl_line_index).operand  := lt_pro_line(j).operand;
                                END IF;
                            END IF;
                             
                            l_modifiers_tbl(ln_tbl_line_index).list_line_type_code       := lt_pro_line(j).list_line_type_code;
                            l_modifiers_tbl(ln_tbl_line_index).modifier_level_code       := lt_pro_line(j).modifier_level_code;
                            l_modifiers_tbl(ln_tbl_line_index).accrual_flag              := lt_pro_line(j).accrual_flag;
                            l_modifiers_tbl(ln_tbl_line_index).start_date_active         := trunc(TO_DATE(TO_CHAR(lt_pro_line(j).start_date_active,'DD-MON-YYYY'),'DD-MON-YYYY'));
                            l_modifiers_tbl(ln_tbl_line_index).pricing_group_sequence    := 2;
                            l_modifiers_tbl(ln_tbl_line_index).product_precedence        := lt_pro_line(j).product_precedence;
                            l_modifiers_tbl(ln_tbl_line_index).operation                 := QP_GLOBALS.G_OPR_CREATE;
                            l_modifiers_tbl(ln_tbl_line_index).attribute11               := lt_pro_line(j).attribute11;
                            l_modifiers_tbl(ln_tbl_line_index).attribute10               := lt_pro_line(j).attribute10;
                            l_modifiers_tbl(ln_tbl_line_index).attribute15               := lt_pro_line(j).attribute15;
                            l_modifiers_tbl(ln_tbl_line_index).last_updated_by           := FND_GLOBAL.user_id;
                            l_modifiers_tbl(ln_tbl_line_index).last_update_date          := sysdate;
                            l_modifiers_tbl(ln_tbl_line_index).last_update_login         := FND_GLOBAL.user_id;
                            l_modifiers_tbl(ln_tbl_line_index).list_header_id            := FND_API.G_MISS_NUM;
                            l_modifiers_tbl(ln_tbl_line_index).list_line_id              := FND_API.G_MISS_NUM;
                            
                            l_modifiers_tbl(ln_tbl_line_index).generate_using_formula_id := lt_pro_line(j).generate_using_formula_id;
                            l_modifiers_tbl(ln_tbl_line_index).list_price                := lt_pro_line(j).list_price;
                            l_modifiers_tbl(ln_tbl_line_index).number_effective_periods  := lt_pro_line(j).number_effective_periods;
                            l_modifiers_tbl(ln_tbl_line_index).override_flag             := NVL(lt_pro_line(j).override_flag,FND_API.G_MISS_CHAR);
                            l_modifiers_tbl(ln_tbl_line_index).number_expiration_periods := lt_pro_line(j).number_expiration_periods;

                            IF (lt_pro_line(j).list_line_type_code = 'DIS' AND) THEN
                              l_modifiers_tbl(ln_tbl_line_index).price_break_type_code:='POINT';
                            ELSIF (lt_pro_line(j).list_line_type_code = 'PBH') THEN
                                 l_modifiers_tbl(ln_tbl_line_index).price_break_type_code:='RANGE';
                            ELSE
                                l_modifiers_tbl(ln_tbl_line_index).price_break_type_code := lt_pro_line(j).price_break_type_code;
                            END IF; 

                            l_modifiers_tbl(ln_tbl_line_index).percent_price            := lt_pro_line(j).percent_price;
                            l_modifiers_tbl(ln_tbl_line_index).price_by_formula_id      := lt_pro_line(j).price_by_formula_id;
                            l_modifiers_tbl(ln_tbl_line_index).primary_uom_flag         := lt_pro_line(j).primary_uom_flag;
                            l_modifiers_tbl(ln_tbl_line_index).print_on_invoice_flag    := NVL(lt_pro_line(j).print_on_invoice_flag,FND_API.G_MISS_CHAR);
                            l_modifiers_tbl(ln_tbl_line_index).program_application_id   := lt_pro_line(j).program_application_id;
                            l_modifiers_tbl(ln_tbl_line_index).rebate_trxn_type_code    := lt_pro_line(j).rebate_trxn_type_code;
                            l_modifiers_tbl(ln_tbl_line_index).related_item_id          := lt_pro_line(j).related_item_id;
                            l_modifiers_tbl(ln_tbl_line_index).relationship_type_id     := lt_pro_line(j).relationship_type_id;
                            l_modifiers_tbl(ln_tbl_line_index).reprice_flag             := lt_pro_line(j).reprice_flag;
                            l_modifiers_tbl(ln_tbl_line_index).revision                 := lt_pro_line(j).revision;
                            l_modifiers_tbl(ln_tbl_line_index).revision_date            := lt_pro_line(j).revision_date;
                            l_modifiers_tbl(ln_tbl_line_index).revision_reason_code     := lt_pro_line(j).revision_reason_code;
                            l_modifiers_tbl(ln_tbl_line_index).substitution_attribute   := lt_pro_line(j).substitution_attribute;
                            l_modifiers_tbl(ln_tbl_line_index).substitution_context     := lt_pro_line(j).substitution_context;
                            l_modifiers_tbl(ln_tbl_line_index).substitution_value       := lt_pro_line(j).substitution_value;
                            l_modifiers_tbl(ln_tbl_line_index).accrual_flag             := lt_pro_line(j).accrual_flag;
                            l_modifiers_tbl(ln_tbl_line_index).incompatibility_grp_code := lt_pro_line(j).incompatibility_grp_code;
                            l_modifiers_tbl(ln_tbl_line_index).list_line_no             := Nvl(lt_pro_line(j).list_line_no,FND_API.G_MISS_CHAR);
                            l_modifiers_tbl(ln_tbl_line_index).from_rltd_modifier_id    := lt_pro_line(j).from_rltd_modifier_id;

                            derive_phase_id(
                                              p_modifier_level_code => lt_pro_line(j).modifier_level_code
                                              ,x_phase_id => ln_phase_id
                                              ,x_status   => lc_status
                                             );
                            
                            l_modifiers_tbl(ln_tbl_line_index).pricing_phase_id             := ln_phase_id;
                            l_modifiers_tbl(ln_tbl_line_index).expiration_period_uom        := lt_pro_line(j).expiration_period_uom;
                            l_modifiers_tbl(ln_tbl_line_index).expiration_date              := lt_pro_line(j).expiration_date;
                            l_modifiers_tbl(ln_tbl_line_index).estim_gl_value               := lt_pro_line(j).estim_gl_value;
                            l_modifiers_tbl(ln_tbl_line_index).benefit_limit                := lt_pro_line(j).benefit_limit;
                            l_modifiers_tbl(ln_tbl_line_index).charge_type_code             := lt_pro_line(j).charge_type_code;
                            l_modifiers_tbl(ln_tbl_line_index).charge_subtype_code          := lt_pro_line(j).charge_subtype_code;
                            l_modifiers_tbl(ln_tbl_line_index).accrual_conversion_rate      := lt_pro_line(j).accrual_conversion_rate;
                            l_modifiers_tbl(ln_tbl_line_index).expiration_period_start_date := lt_pro_line(j).expiration_period_start_date;
                            l_modifiers_tbl(ln_tbl_line_index).proration_type_code          := NVL(lt_pro_line(j).proration_type_code,FND_API.G_MISS_CHAR);
                            l_modifiers_tbl(ln_tbl_line_index).return_status                := lt_pro_line(j).return_status;
                            l_modifiers_tbl(ln_tbl_line_index).db_flag                      := NULL;

                            -- ------------------------------------------------------------------------------
                            -- Get the records from the pricing attributes staging table into the table type
                            -- ------------------------------------------------------------------------------
                            OPEN lcu_process_pric_attr(
                                                       p_header_orig  => lt_pro_header(i).orig_sys_header_ref
                                                       ,p_line_orig   => lt_pro_line(j).orig_sys_line_ref
                                                       ,p_batch_id    => p_batch_id
                                                      );
                            FETCH lcu_process_pric_attr BULK COLLECT INTO lt_pro_pric_attrib;
                            CLOSE lcu_process_pric_attr;

                            IF lt_pro_pric_attrib.COUNT <> 0 THEN

                              FOR k IN 1 .. lt_pro_pric_attrib.COUNT
                              LOOP
                                  
                                  
                                  ln_tbl_pa_index := ln_tbl_pa_index + 1;
                                  
                                  IF lt_pro_line(j).list_line_type_code = 'PBH' THEN
                                    l_modifiers_tbl(ln_tbl_line_index).price_break_type_code:='RANGE';
                                  ELSE
                                      IF lt_pro_pric_attrib(k).pricing_attribute_context = 'VOLUME' THEN --OR ln_last_mod_parent_index = ln_mod_parent_index THEN
                                        l_modifiers_tbl(ln_tbl_line_index).price_break_type_code:='POINT';
                                  END IF;
                                  
                                  lc_price_break_code := l_modifiers_tbl(ln_tbl_line_index).price_break_type_code;

                                 
                                  -- ------------------------------------------------------------------------------
                                  -- Setting up the pricing attribute table type
                                  -- ------------------------------------------------------------------------------

                                 -- l_modifiers_tbl(ln_tbl_line_index).price_break_type_code:= lc_line_type_code;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).product_attribute_context  := 'ITEM';
                                  l_pricing_attr_tbl(ln_tbl_pa_index).product_attribute          := lt_pro_pric_attrib(k).product_attribute;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).pricing_attribute_context  := NVL(lt_pro_pric_attrib(k).pricing_attribute_context,FND_API.G_MISS_CHAR);
                                  l_pricing_attr_tbl(ln_tbl_pa_index).pricing_attribute          := NVL(lt_pro_pric_attrib(k).pricing_attribute,FND_API.G_MISS_CHAR);
                                  l_pricing_attr_tbl(ln_tbl_pa_index).pricing_attr_value_from    := NVL(lt_pro_pric_attrib(k).pricing_attr_value_from,FND_API.G_MISS_CHAR);
                                  l_pricing_attr_tbl(ln_tbl_pa_index).comparison_operator_code   := lt_pro_pric_attrib(k).comparison_operator_code;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).pricing_attr_value_to      := NVL(lt_pro_pric_attrib(k).pricing_attr_value_to,FND_API.G_MISS_CHAR);
                                  l_pricing_attr_tbl(ln_tbl_pa_index).product_uom_code           := lt_pro_pric_attrib(k).product_uom_code;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).pricing_attribute_datatype := lt_pro_pric_attrib(k).pricing_attribute_datatype;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).excluder_flag              := NVL(lt_pro_pric_attrib(k).excluder_flag,FND_API.G_MISS_CHAR);
                                  l_pricing_attr_tbl(ln_tbl_pa_index).modifiers_index            := ln_tbl_line_index;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).pricing_phase_id           := NVL(NVL(ln_phase_id,lt_pro_line(j).pricing_phase_id),lt_pro_pric_attrib(k).pricing_phase_id);
                                  l_pricing_attr_tbl(ln_tbl_pa_index).operation                  := QP_GLOBALS.G_OPR_CREATE;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).attribute_grouping_no      := NVL(lt_pro_pric_attrib(k).attribute_grouping_no,FND_API.G_MISS_NUM);
                                  l_pricing_attr_tbl(ln_tbl_pa_index).context                    := lt_pro_pric_attrib(k).context;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).created_by                 := FND_GLOBAL.user_id;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).creation_date              := sysdate;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).last_updated_by            := FND_GLOBAL.user_id;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).last_update_date           := sysdate;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).last_update_login          := FND_GLOBAL.user_id;
                                  l_modifiers_tbl(ln_tbl_line_index).benefit_qty                := NVL(lt_pro_pric_attrib(k).pricing_attr_value_from,lt_pro_line(j).benefit_qty);
                                  l_modifiers_tbl(ln_tbl_line_index).benefit_uom_code           := NVL(lt_pro_pric_attrib(k).product_uom_code,lt_pro_line(j).benefit_uom_code);

                                  -- ------------------------------------------------------------------------------
                                  -- Derive the inventory_item_id for a product_attr_value of a pricing attribute
                                  -- ------------------------------------------------------------------------------

                                  IF lt_pro_pric_attrib(k).product_attr_value NOT IN ('ALL','ITEM_CATEGORY') THEN

                                    validate_inventory_item_id(
                                                               p_inventory_item  => lt_pro_pric_attrib(k).product_attr_value
                                                               ,p_uom_code       => lt_pro_pric_attrib(k).product_uom_code
                                                               ,x_inv_item       => ln_inventory_item_id
                                                               ,x_status         => lc_status
                                                              );
                                  END IF;

                                  IF lt_pro_pric_attrib(k).product_attr_value = 'ALL' THEN
                                    l_pricing_attr_tbl(ln_tbl_pa_index).product_attr_value := 'ALL';
                                  ELSIF lt_pro_pric_attrib(k).product_attr_value = 'ITEM_CATEGORY' THEN
                                       l_pricing_attr_tbl(ln_tbl_pa_index).product_attr_value := 'ITEM_CATEGORY';
                                  ELSE
                                      l_pricing_attr_tbl(ln_tbl_pa_index).product_attr_value := To_Char(ln_inventory_item_id);
                                  END IF;

                                  
                                  -- ------------------------------------------------------------------------------
                                  -- Derive the benefit_list_line_id for a rltd_modifier_grp_type of a pricing attribute
                                  -- ------------------------------------------------------------------------------
                                  IF (lt_pro_line(j).rltd_modifier_grp_type IN('QUALIFIER','BENEFIT')) THEN

                                    derive_benefit_list_line_id(
                                                                p_inv_item_id  => ln_inventory_item_id
                                                                ,x_list_line_id => ln_list_line_id
                                                                ,x_status       => lc_status
                                                               );

                                    l_modifiers_tbl(ln_tbl_line_index).benefit_price_list_line_id := NVL(ln_list_line_id,lt_pro_line(j).benefit_price_list_line_id);
                                    l_modifiers_tbl(ln_tbl_line_index).rltd_modifier_grp_no       := lt_pro_line(j).rltd_modifier_grp_no;
                                    l_modifiers_tbl(ln_tbl_line_index).rltd_modifier_grp_type     := lt_pro_line(j).rltd_modifier_grp_type;
                                    l_modifiers_tbl(ln_tbl_line_index).benefit_qty                := NVL(lt_pro_pric_attrib(k).pricing_attr_value_from,lt_pro_line(j).benefit_qty);
                                    l_modifiers_tbl(ln_tbl_line_index).benefit_uom_code           := NVL(lt_pro_pric_attrib(k).product_uom_code,lt_pro_line(j).benefit_uom_code);
                                  END IF;

                                  l_pricing_attr_tbl(ln_tbl_pa_index).program_application_id     := lt_pro_pric_attrib(k).program_application_id;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).program_id                 := lt_pro_pric_attrib(k).program_id;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).program_update_date        := lt_pro_pric_attrib(k).program_update_date;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).product_attribute_datatype := lt_pro_pric_attrib(k).product_attribute_datatype;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).db_flag                    := lt_pro_pric_attrib(k).db_flag;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).return_status              := lt_pro_pric_attrib(k).return_status;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).pricing_attribute_id       := FND_API.G_MISS_NUM;
                                  l_pricing_attr_tbl(ln_tbl_pa_index).list_line_id               := FND_API.G_MISS_NUM;

                                  
                              END LOOP; -- End of Pricing Attributes Loop
                             -- lt_pro_pric_attrib.DELETE;
                            END IF;
                            
                        END LOOP; -- End of Lines Loop
                      --  lt_pro_line.DELETE;
                      END IF; -- End of Lines Loop

                      -- ----------------------------------------------------------------------
                      -- Get the records from the qualifiers staging table into the table type
                      -- ----------------------------------------------------------------------
                      OPEN lcu_pro_qualifiers(
                                              p_header_orig => lt_pro_header(i).orig_sys_header_ref
                                              ,p_batch_id    => p_batch_id
                                             );
                      FETCH lcu_pro_qualifiers BULK COLLECT INTO lt_pro_qual;
                      CLOSE lcu_pro_qualifiers;

                      IF lt_pro_qual.COUNT <> 0 THEN

                        FOR l IN 1 .. lt_pro_qual.COUNT
                        LOOP

                            ln_tbl_qua_index := ln_tbl_qua_index + 1;

                            -- ----------------------------------------------------------------------
                            -- Setting up the qualifier table type
                            -- ----------------------------------------------------------------------
                            l_qualifiers_tbl(ln_tbl_qua_index).attribute1               := lt_pro_qual(l).attribute1;
                            l_qualifiers_tbl(ln_tbl_qua_index).attribute15              := lt_pro_qual(l).attribute15;
                            l_qualifiers_tbl(ln_tbl_qua_index).comparison_operator_code := lt_pro_qual(l).comparison_operator_code;
                            l_qualifiers_tbl(ln_tbl_qua_index).context                  := lt_pro_qual(l).context;
                            l_qualifiers_tbl(ln_tbl_qua_index).created_by               := FND_GLOBAL.user_id;
                            l_qualifiers_tbl(ln_tbl_qua_index).created_from_rule_id     := lt_pro_qual(l).created_from_rule_id;
                            l_qualifiers_tbl(ln_tbl_qua_index).creation_date            := sysdate;
                            l_qualifiers_tbl(ln_tbl_qua_index).end_date_active          := lt_pro_qual(l).end_date_active;
                            l_qualifiers_tbl(ln_tbl_qua_index).last_updated_by          := FND_GLOBAL.user_id;
                            l_qualifiers_tbl(ln_tbl_qua_index).last_update_date         := sysdate;
                            l_qualifiers_tbl(ln_tbl_qua_index).last_update_login        := FND_GLOBAL.user_id;
                            l_qualifiers_tbl(ln_tbl_qua_index).list_header_id           := FND_API.G_MISS_NUM;
                            l_qualifiers_tbl(ln_tbl_qua_index).list_line_id             := FND_API.G_MISS_NUM;
                            l_qualifiers_tbl(ln_tbl_qua_index).program_application_id   := lt_pro_qual(l).program_application_id;
                            l_qualifiers_tbl(ln_tbl_qua_index).program_id               := lt_pro_qual(l).program_id;
                            l_qualifiers_tbl(ln_tbl_qua_index).program_update_date      := lt_pro_qual(l).program_update_date;
                            l_qualifiers_tbl(ln_tbl_qua_index).qualifier_attribute      := lt_pro_qual(l).qualifier_attribute;
                            l_qualifiers_tbl(ln_tbl_qua_index).qualifier_attr_value     := lt_pro_qual(l).qualifier_attr_value;
                            l_qualifiers_tbl(ln_tbl_qua_index).qualifier_context        := lt_pro_qual(l).qualifier_context;
                            l_qualifiers_tbl(ln_tbl_qua_index).qualifier_grouping_no    := lt_pro_qual(l).qualifier_grouping_no;
                            l_qualifiers_tbl(ln_tbl_qua_index).qualifier_precedence     := lt_pro_qual(l).qualifier_precedence;
                            l_qualifiers_tbl(ln_tbl_qua_index).qualifier_id             := FND_API.G_MISS_NUM;
                            l_qualifiers_tbl(ln_tbl_qua_index).qualifier_rule_id        := lt_pro_qual(l).qualifier_rule_id;
                            l_qualifiers_tbl(ln_tbl_qua_index).start_date_active        := sysdate;
                            l_qualifiers_tbl(ln_tbl_qua_index).return_status            := lt_pro_qual(l).return_status;
                            l_qualifiers_tbl(ln_tbl_qua_index).db_flag                  := NVL(lt_pro_qual(l).db_flag,FND_API.G_MISS_CHAR);
                            l_qualifiers_tbl(ln_tbl_qua_index).request_id               := lt_pro_qual(l).request_id;
                            l_qualifiers_tbl(ln_tbl_qua_index).excluder_flag            := lt_pro_qual(l).excluder_flag;
                            l_qualifiers_tbl(ln_tbl_qua_index).operation                := QP_GLOBALS.G_OPR_CREATE;

                        END LOOP; -- End of Qualifiers Loop
                       --lt_pro_qual.DELETE;
                      END IF;

                      BEGIN
                           
                           -- -------------------------------------------------
                           -- Call the Stabdard API for Process Modifiers API
                           -- ---------------------------------------------------
                           qp_modifiers_pub.process_modifiers(
                                                              p_api_version_number      => 1.0
                                                              ,p_init_msg_list          => FND_API.G_FALSE
                                                              ,p_return_values          => FND_API.G_FALSE
                                                              ,p_commit                 => FND_API.G_FALSE
                                                              ,x_return_status          => l_status
                                                              ,x_msg_count              => l_count
                                                              ,x_msg_data               => l_data
                                                              ,p_modifier_list_rec      => l_modifier_list_rec
                                                              ,p_modifier_list_val_rec  => l_modifier_list_val_rec
                                                              ,p_modifiers_tbl          => l_modifiers_tbl
                                                              ,p_modifiers_val_tbl      => l_modifiers_val_tbl
                                                              ,p_qualifiers_tbl         => l_qualifiers_tbl
                                                              ,p_qualifiers_val_tbl     => l_qualifiers_val_tbl
                                                              ,p_pricing_attr_tbl       => l_pricing_attr_tbl
                                                              ,p_pricing_attr_val_tbl   => l_pricing_attr_val_tbl
                                                              ,x_modifier_list_rec      => x_modifier_list_rec
                                                              ,x_modifier_list_val_rec  => x_modifier_list_val_rec
                                                              ,x_modifiers_tbl          => x_modifiers_tbl
                                                              ,x_modifiers_val_tbl      => x_modifiers_val_tbl
                                                              ,x_qualifiers_tbl         => x_qualifiers_tbl
                                                              ,x_qualifiers_val_tbl     => x_qualifiers_val_tbl
                                                              ,x_pricing_attr_tbl       => x_pricing_attr_tbl
                                                              ,x_pricing_attr_val_tbl   => x_pricing_attr_val_tbl
                                                              );

                           -- -------------------------------------------------
                           -- Check the return status of the API
                           -- ---------------------------------------------------
                           IF l_status <> FND_API.G_RET_STS_SUCCESS THEN
                             -- ----------------------------------------------------
                             -- Assign the process_flag of header
                             -- -----------------------------------------------------
                             lt_hdr_pro_flag(ln_pro_hdr_index) := 6;
                             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                           ELSE
                               -- ----------------------------------------------------
                               -- Assign the process_flag of header
                               -- -----------------------------------------------------
                               lt_hdr_pro_flag(ln_pro_hdr_index) := 7;
                               COMMIT;
                           END IF;

                      EXCEPTION
                         WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
                             lt_hdr_pro_flag(ln_pro_hdr_index) := 6;
                             FOR k IN 1 .. l_count
                             LOOP
                                 l_data := oe_msg_pub.get(
                                                          p_msg_index  => k
                                                          ,p_encoded   => 'F'
                                                         );
                                 log_procedure(
                                               p_control_id           => lt_pro_header(i).control_id
                                               ,p_source_system_code   => lt_pro_header(i).source_system_code
                                               ,p_procedure_name       => 'PROCESS_MODIFIERS'
                                               ,p_staging_table_name   => NULL
                                               ,p_staging_column_name  => NULL
                                               ,p_staging_column_value => NULL
                                               ,p_source_system_ref    => lt_pro_header(i).source_system_ref
                                               ,p_batch_id             => p_batch_id
                                               ,p_exception_log        => l_data
                                               ,p_oracle_error_code    => NULL
                                               ,p_oracle_error_msg     => NULL
                                              );
                             END LOOP;
                             ROLLBACK TO s_header;
                         WHEN OTHERS THEN
                             lt_hdr_pro_flag(ln_pro_hdr_index) := 6;
                             l_data := SQLERRM;
                             x_retcode := 2;
                             log_procedure(
                                           p_control_id           => lt_pro_header(i).control_id
                                           ,p_source_system_code   => lt_pro_header(i).source_system_code
                                           ,p_procedure_name       => 'PROCESS_MODIFIERS'
                                           ,p_staging_table_name   => NULL
                                           ,p_staging_column_name  => NULL
                                           ,p_staging_column_value => NULL
                                           ,p_source_system_ref    => lt_pro_header(i).source_system_ref
                                           ,p_batch_id             => p_batch_id
                                           ,p_exception_log        => NULL
                                           ,p_oracle_error_code    => SQLCODE
                                           ,p_oracle_error_msg     => l_data
                                           );
                             ROLLBACK TO s_header;
                      END;

                 EXCEPTION
                    WHEN OTHERS THEN
                        
                        lt_hdr_pro_flag(ln_pro_hdr_index) := 6;
                        l_data := SQLERRM;
                        x_retcode := 2;
                        log_procedure(
                                      p_control_id            => lt_pro_header(i).control_id
                                      ,p_source_system_code   => lt_pro_header(i).source_system_code
                                      ,p_procedure_name       => 'PROCESS_MODIFIERS'
                                      ,p_staging_table_name   => NULL
                                      ,p_staging_column_name  => NULL
                                      ,p_staging_column_value => NULL
                                      ,p_source_system_ref    => lt_pro_header(i).source_system_ref
                                      ,p_batch_id             => p_batch_id
                                      ,p_exception_log        => NULL
                                      ,p_oracle_error_code    => SQLCODE
                                      ,p_oracle_error_msg     => l_data
                                     );
                        ROLLBACK TO s_header;
                 END;

             END LOOP;

             -- ------------------------------------------------------------------------
             -- Update the records of the header staging table with the corresponding
             -- process_flag
             -- ------------------------------------------------------------------------
             FORALL ln_pro_hdr_index IN  lt_pro_hdr_row_id.FIRST .. lt_pro_hdr_row_id.LAST
             UPDATE xx_qp_list_headers_stg XQLS
             SET    XQLS.process_flag = lt_hdr_pro_flag(ln_pro_hdr_index)
             WHERE  XQLS.rowid = lt_pro_hdr_row_id(ln_pro_hdr_index);

             COMMIT;

           END IF; -- IF  lt_pro_header.COUNT

       ELSE
           x_retcode := 1;
   END CASE;

EXCEPTION
   WHEN OTHERS THEN
       x_retcode := 2;
       log_procedure(
                     p_control_id            => NULL
                     ,p_source_system_code   => NULL
                     ,p_procedure_name       => 'PROCESS_MODIFIERS'
                     ,p_staging_table_name   => NULL
                     ,p_staging_column_name  => NULL
                     ,p_staging_column_value => NULL
                     ,p_source_system_ref    => NULL
                     ,p_batch_id             => p_batch_id
                     ,p_exception_log        => NULL
                     ,p_oracle_error_code    => SQLCODE
                     ,p_oracle_error_msg     => SQLERRM
                    );

END process_modifiers;

-- +====================================================================+
-- | Name        :  launch_exception_report                             |
-- | Description :  This procedure is invoked to Launch Exception       |
-- |                Report for that batch                               |
-- |                                                                    |
-- | Parameters  :                                                      |
-- +====================================================================+

PROCEDURE launch_exception_report(
                                  p_batch_id IN  NUMBER
                                  ,x_errbuf  OUT NOCOPY VARCHAR2
                                  ,x_retcode OUT NOCOPY VARCHAR2
                                 )
IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------
EX_REP_EXC           EXCEPTION;
ln_excep_request_id  PLS_INTEGER;
ln_child_request_id  PLS_INTEGER := FND_GLOBAL.CONC_REQUEST_ID;

BEGIN

   -- ----------------------------------------
   -- Launch the exception report of a batch
   -- ----------------------------------------
   ln_excep_request_id := FND_REQUEST.submit_request(
                                                     application  => G_COMM_APPLICATION
                                                     ,program     => G_EXCEP_PROGRAM
                                                     ,sub_request => FALSE               -- TRUE means is a sub request
                                                     ,argument1   => G_CONVERSION_CODE   -- conversion_code
                                                     ,argument2   => NULL                -- MASTER REQUEST ID
                                                     ,argument3   => ln_child_request_id -- REQUEST ID
                                                     ,argument4   => p_batch_id          -- BATCH ID
                                                    );

   IF  ln_excep_request_id = 0 THEN
      x_errbuf  := FND_MESSAGE.GET;
      RAISE EX_REP_EXC;
   ELSE
      COMMIT;
   END IF;

EXCEPTION
  WHEN EX_REP_EXC THEN
       x_retcode := 2;
       x_errbuf  := 'Exception Summary Report for the batch '||p_batch_id||' could not be submitted: ' || x_errbuf;

END launch_exception_report;

-- +====================================================================+
-- | Name        :  update_err_child_batch_id                           |
-- |                                                                    |
-- | Description :  This procedure is invoked to reset process_flag to 2|
-- |                for previously errored out records for a particular |
-- |                batch                                               |
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- +====================================================================+

PROCEDURE update_err_child_batch_id(
                                    p_batch_id  IN NUMBER
                                    ,x_retcode  OUT NOCOPY VARCHAR2
                                    ,x_errbuf   OUT NOCOPY VARCHAR2
                                   )
IS
BEGIN

   -- ------------------------------------------------------------------------
   -- Update the records of the header staging table with process_flag = 2
   -- for a particular batch
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_list_headers_stg XQPL
   SET    XQPL.process_flag = 2
   WHERE  XQPL.process_flag NOT IN (0,7)
   AND    XQPL.load_batch_id = p_batch_id;

   COMMIT;

   -- ------------------------------------------------------------------------
   -- Update the records of the line staging table with process_flag = 2
   -- for a particular batch
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_list_lines_stg XQLL
   SET    XQLL.process_flag = 2
   WHERE  XQLL.process_flag NOT IN (0,7)
   AND    XQLL.load_batch_id = p_batch_id
   AND    XQLL.orig_sys_header_ref IN (
                                       SELECT XQPL.orig_sys_header_ref
                                       FROM   xx_qp_list_headers_stg XQPL
                                       WHERE  process_flag =2
                                       AND    XQPL.load_batch_id = p_batch_id
                                      );

   COMMIT;

   -- ------------------------------------------------------------------------
   -- Update the records of the pricing attribute staging table with process_flag = 2
   -- for a particular batch
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_pricing_attributes_stg XQPA
   SET    XQPA.process_flag = 2
   WHERE  XQPA.process_flag NOT IN (0,7)
   AND    XQPA.load_batch_id = p_batch_id
   AND    XQPA.orig_sys_header_ref IN (
                                       SELECT XQPL.orig_sys_header_ref
                                       FROM   xx_qp_list_headers_stg XQPL
                                       WHERE  XQPL.process_flag =2
                                       AND    XQPL.load_batch_id = p_batch_id
                                      )
   AND    XQPA.orig_sys_line_ref  IN (
                                      SELECT XQLL.orig_sys_line_ref
                                      FROM   xx_qp_list_lines_stg XQLL
                                      WHERE  XQLL.process_flag =2
                                      AND    XQLL.load_batch_id = p_batch_id
                                     );
   COMMIT;

   -- ------------------------------------------------------------------------
   -- Update the records of the qualifier staging table with process_flag = 2
   -- for a particular batch
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_qualifiers_stg XQQS
   SET    XQQS.process_flag = 2
   WHERE  XQQS.process_flag NOT IN (0,7)
   AND    XQQS.load_batch_id = p_batch_id
   AND    XQQS.orig_sys_header_ref IN (
                                       SELECT XQPL.orig_sys_header_ref
                                       FROM   xx_qp_list_headers_stg XQPL
                                       WHERE  XQPL.process_flag =2
                                       AND    XQPL.load_batch_id = p_batch_id
                                      );
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
       log_procedure(
                     p_control_id           => NULL
                     ,p_source_system_code   => NULL
                     ,p_procedure_name       => 'UPDATE_ERR_CHILD_BATCH_ID'
                     ,p_staging_table_name   => NULL
                     ,p_staging_column_name  => NULL
                     ,p_staging_column_value => NULL
                     ,p_source_system_ref    => NULL
                     ,p_batch_id             => p_batch_id
                     ,p_exception_log        => NULL
                     ,p_oracle_error_code    => SQLCODE
                     ,p_oracle_error_msg     => SQLERRM
                    );
       x_errbuf  := 'Error in update_err_child_batch_id : '||SQLERRM;
       x_retcode := 2;
       display_log(x_errbuf);
END update_err_child_batch_id;

-- +====================================================================+
-- | Name        :  update_child_batch_id                               |
-- |                                                                    |
-- | Description :  This procedure is invoked to update the header,     |
-- |                line, qualifier and pricing attribute records       |
-- |                                                                    |
-- | Parameters  :  p_conversion_id                                     |
-- |                p_batch_id                                          |
-- |                                                                    |
-- | Returns     :  Master_Request_Id                                   |
-- |                                                                    |
-- +====================================================================+

PROCEDURE update_child_batch_id(
                                p_batch_id      IN NUMBER
                                ,p_hdr_pro_flag IN NUMBER
                                ,p_new_pro_flag IN NUMBER
                               )
IS
BEGIN

   -- ------------------------------------------------------------------------
   -- Update the records of the line staging table with process_flag = 5 or 6 or 7
   -- for a particular batch
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_list_lines_stg XQLL
   SET    XQLL.process_flag = p_new_pro_flag
   WHERE  XQLL.orig_sys_header_ref IN (
                                       SELECT orig_sys_header_ref
                                       FROM   xx_qp_list_headers_stg XQPL
                                       WHERE  XQPL.load_batch_id = p_batch_id
                                       AND    XQPL.process_flag  = p_hdr_pro_flag
                                      )
   AND    XQLL.load_batch_id = p_batch_id;

   COMMIT;

   -- ------------------------------------------------------------------------
   -- Update the records of the pricing attributes staging table with process_flag = 5 or 6 or 7
   -- for a particular batch
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_pricing_attributes_stg XQPA
   SET    XQPA.process_flag = p_new_pro_flag
   WHERE  XQPA.orig_sys_header_ref IN (
                                       SELECT orig_sys_header_ref
                                       FROM   xx_qp_list_headers_stg XQPL
                                       WHERE  XQPL.load_batch_id = p_batch_id
                                       AND    XQPL.process_flag  = p_hdr_pro_flag
                                      )
   AND    XQPA.orig_sys_line_ref IN   (
                                       SELECT orig_sys_line_ref
                                       FROM   xx_qp_list_lines_stg XQLL
                                       WHERE  XQLL.load_batch_id = p_batch_id
                                       AND    XQLL.process_flag  = p_new_pro_flag
                                      )
   AND    XQPA.load_batch_id       = p_batch_id;

   COMMIT;

   -- ------------------------------------------------------------------------
   -- Update the records of the qualifier staging table with process_flag = 5 or 6 or 7
   -- for a particular batch
   -- ------------------------------------------------------------------------
   UPDATE xx_qp_qualifiers_stg XQQS
   SET    XQQS.process_flag = p_new_pro_flag
   WHERE  XQQS.orig_sys_header_ref IN (
                                       SELECT orig_sys_header_ref
                                       FROM   xx_qp_list_headers_stg XQPL
                                       WHERE  XQPL.load_batch_id = p_batch_id
                                       AND    XQPL.process_flag  = p_hdr_pro_flag
                                      )
   AND    XQQS.load_batch_id = p_batch_id;

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
       log_procedure(
                     p_control_id           => NULL
                     ,p_source_system_code   => NULL
                     ,p_procedure_name       => 'UPDATE_CHILD_BATCH_ID'
                     ,p_staging_table_name   => NULL
                     ,p_staging_column_name  => NULL
                     ,p_staging_column_value => NULL
                     ,p_source_system_ref    => NULL
                     ,p_batch_id             => p_batch_id
                     ,p_exception_log        => NULL
                     ,p_oracle_error_code    => SQLCODE
                     ,p_oracle_error_msg     => SQLERRM
                    );

END update_child_batch_id;


-- +====================================================================+
-- | Name        :  get_master_request_id                               |
-- |                                                                    |
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

     SELECT XCCIC.master_request_id
     INTO   x_master_request_id
     FROM   xx_com_control_info_conv XCCIC
     WHERE  XCCIC.conversion_id = p_conversion_id
     AND    XCCIC.batch_id      = p_batch_id;

EXCEPTION
   WHEN OTHERS THEN
        x_master_request_id := NULL;
END get_master_request_id;

-- +====================================================================+
-- | Name        :  to_print_out                                        |
-- |                                                                    |
-- | Description :  This procedure is invoked to print the results in   |
-- |                the output file and launch the exception report for |
-- |                that batch                                          |
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE to_print_out(
                       p_batch_id  IN         NUMBER
                       ,x_errbuf   OUT NOCOPY VARCHAR2
                       ,x_retcode  OUT NOCOPY VARCHAR2
                      )

IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------
ln_total_mod_hdr_count      PLS_INTEGER;
ln_succ_mod_hdr_count       PLS_INTEGER;
ln_err_mod_hdr_count        PLS_INTEGER;
ln_err_valid_mod_hdr_count  PLS_INTEGER;
ln_total_err_mod_hdr_count  PLS_INTEGER;
ln_total_mod_line_count     PLS_INTEGER;
ln_succ_mod_line_count      PLS_INTEGER;
ln_total_err_mod_line_count PLS_INTEGER;
ln_succ_valid_line_count    PLS_INTEGER;
ln_total_mod_pa_count       PLS_INTEGER;
ln_succ_mod_pa_count        PLS_INTEGER;
ln_total_err_mod_pa_count   PLS_INTEGER;
ln_succ_valid_pa_count      PLS_INTEGER;
ln_total_mod_qual_count     PLS_INTEGER;
ln_succ_mod_qual_count      PLS_INTEGER;
ln_succ_valid_qual_count    PLS_INTEGER;
ln_total_err_mod_qual_count PLS_INTEGER;
ln_conversion_id            PLS_INTEGER;
ln_batch_size               PLS_INTEGER;
ln_max_child_req            PLS_INTEGER;
lc_return_status            VARCHAR2(20);
ln_request_id               PLS_INTEGER;

BEGIN

   -- --------------------------------------------------------------------------------------
   -- Count the total number of header records of a particilar batch
   -- --------------------------------------------------------------------------------------

   SELECT COUNT(1)
   INTO   ln_total_mod_hdr_count
   FROM   xx_qp_list_headers_stg XQPL
   WHERE  XQPL.load_batch_id = p_batch_id
   ORDER BY XQPL.control_id;

   -- --------------------------------------------------------------------------------------
   -- Count the number of header records where process_flag in 3 or 6 or 7
   -- of a particilar batch
   -- --------------------------------------------------------------------------------------

   SELECT COUNT  (CASE WHEN process_flag = 3 THEN 1 END)
          ,COUNT (CASE WHEN process_flag = 6 THEN 1 END)
          ,COUNT (CASE WHEN process_flag = 7 THEN 1 END)
   INTO   ln_err_valid_mod_hdr_count
          ,ln_err_mod_hdr_count
          ,ln_succ_mod_hdr_count
   FROM   xx_qp_list_headers_stg XQPL
   WHERE  XQPL.load_batch_id=p_batch_id;

   ln_total_err_mod_hdr_count := ln_err_mod_hdr_count + ln_err_valid_mod_hdr_count;

   -- --------------------------------------------------------------------------------------
   -- Count the total number of line records of a particilar batch
   -- --------------------------------------------------------------------------------------

   SELECT COUNT(1)
   INTO   ln_total_mod_line_count
   FROM   xx_qp_list_lines_stg XQLL
   WHERE  XQLL.load_batch_id = p_batch_id
   ORDER BY XQLL.control_id;

   -- --------------------------------------------------------------------------------------
   -- Count the number of line records where process_flag in 3 or 4 or 6 or 7
   -- of a particilar batch
   -- --------------------------------------------------------------------------------------

   SELECT COUNT  (CASE WHEN process_flag = 4 THEN 1 END)
          ,COUNT (CASE WHEN process_flag IN (3,6) THEN 1 END)
          ,COUNT (CASE WHEN process_flag = 7 THEN 1 END)
   INTO   ln_succ_valid_line_count
          ,ln_total_err_mod_line_count
          ,ln_succ_mod_line_count
   FROM   xx_qp_list_lines_stg XQLL
   WHERE  XQLL.load_batch_id=p_batch_id;

   -- --------------------------------------------------------------------------------------
   -- Count the total number of pricing attribute records of a particilar batch
   -- --------------------------------------------------------------------------------------

   SELECT COUNT(1)
   INTO   ln_total_mod_pa_count
   FROM   xx_qp_pricing_attributes_stg XQPA
   WHERE  XQPA.load_batch_id = p_batch_id
   ORDER BY XQPA.control_id;

   -- --------------------------------------------------------------------------------------
   -- Count the number of pricing attribute records where process_flag in 3 or 4 or 6 or 7
   -- of a particilar batch
   -- -----------------------------------------------------------------------------------

   SELECT COUNT  (CASE WHEN process_flag = 4 THEN 1 END)
          ,COUNT (CASE WHEN process_flag IN (3,6) THEN 1 END)
          ,COUNT (CASE WHEN process_flag = 7 THEN 1 END)
   INTO   ln_succ_valid_pa_count
          ,ln_total_err_mod_pa_count
          ,ln_succ_mod_pa_count
   FROM   xx_qp_pricing_attributes_stg XQPA
   WHERE  XQPA.load_batch_id=p_batch_id;

   -- --------------------------------------------------------------------------------------
   -- Count the total number of qualifier records of a particilar batch
   -- --------------------------------------------------------------------------------------

   SELECT COUNT(1)
   INTO   ln_total_mod_qual_count
   FROM   xx_qp_qualifiers_stg XQQS
   WHERE  XQQS.load_batch_id = p_batch_id
   ORDER BY XQQS.control_id;

   -- --------------------------------------------------------------------------------------
   -- Count the number of pricing attribute records where process_flag in 3 or 4 or 6 or 7
   -- of a particilar batch
   -- -----------------------------------------------------------------------------------
   SELECT COUNT  (CASE WHEN process_flag = 4 THEN 1 END)
          ,COUNT (CASE WHEN process_flag IN (3,6) THEN 1 END)
          ,COUNT (CASE WHEN process_flag = 7 THEN 1 END)
   INTO   ln_succ_valid_qual_count
          ,ln_total_err_mod_qual_count
          ,ln_succ_mod_qual_count
   FROM   xx_qp_qualifiers_stg XQQS
   WHERE  XQQS.load_batch_id=p_batch_id;


   ---------------------------------------------------------------------------------------------
   -- XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc is called over
   -- to log the exception of the record while processing
   ---------------------------------------------------------------------------------------------

   get_master_request_id(
                         p_conversion_id      => gn_conversion_id
                         ,p_batch_id          => p_batch_id
                         ,x_master_request_id => ln_request_id
                        );

   IF ln_request_id IS NOT NULL THEN

      XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                                                     p_conc_mst_req_id              => ln_request_id --APPS.FND_GLOBAL.CONC_REQUEST_ID
                                                     ,p_batch_id                    => p_batch_id
                                                     ,p_conversion_id               => gn_conversion_id
                                                     ,p_num_bus_objs_failed_valid   => ln_err_valid_mod_hdr_count
                                                     ,p_num_bus_objs_failed_process => ln_err_mod_hdr_count
                                                     ,p_num_bus_objs_succ_process   => ln_succ_mod_hdr_count
                                                    );
   END IF;

   display_out(RPAD('=',67,'='));
   display_out(RPAD('Total No. Of Modifier Header Records                    : ',58,' ')||RPAD(ln_total_mod_hdr_count,9,' '));
   display_out(RPAD('No. Of Modifier Header Records Processed                : ',58,' ')||RPAD(ln_succ_mod_hdr_count,9,' '));
   display_out(RPAD('No. Of Modifier Header Records Errored                  : ',58,' ')||RPAD(ln_total_err_mod_hdr_count,9,' '));
   display_out(RPAD('=',67,'='));
   display_out(RPAD(' ',67,' '));
   display_out(RPAD('=',67,'='));
   display_out(RPAD('Total No. Of Modifier Line Records                      : ',58,' ')||RPAD(ln_total_mod_line_count,9,' '));
   display_out(RPAD('No. Of Modifier Line Records Processed                  : ',58,' ')||RPAD(ln_succ_mod_line_count,9,' '));
   display_out(RPAD('No. Of Modifier Line Records Errored                    : ',58,' ')||RPAD(ln_total_err_mod_line_count,9,' '));
   display_out(RPAD('No. Of Modifier Line Records Successfully Validated     : ',58,' ')||RPAD(ln_succ_valid_line_count,9,' '));
   display_out(RPAD('=',67,'='));
   display_out(RPAD(' ',67,' '));
   display_out(RPAD('=',67,'='));
   display_out(RPAD('Total No. Of Pricing Attribute Records                  : ',58,' ')||RPAD(ln_total_mod_pa_count,9,' '));
   display_out(RPAD('No. Of Pricing Attribute Records Processed              : ',58,' ')||RPAD(ln_succ_mod_pa_count,9,' '));
   display_out(RPAD('No. Of Pricing Attribute Records Errored                : ',58,' ')||RPAD(ln_total_err_mod_pa_count,9,' '));
   display_out(RPAD('No. Of Pricing Attribute Records Successfully Validated : ',58,' ')||RPAD(ln_succ_valid_pa_count,9,' '));
   display_out(RPAD('=',67,'='));
   display_out(RPAD(' ',67,' '));
   display_out(RPAD('=',67,'='));
   display_out(RPAD('Total No. Of Qualifier Records                          : ',58,' ')||RPAD(ln_total_mod_qual_count,9,' '));
   display_out(RPAD('No. Of Qualifier Records Processed                      : ',58,' ')||RPAD(ln_succ_mod_qual_count,9,' '));
   display_out(RPAD('No. Of Qualifier Records Errored                        : ',58,' ')||RPAD(ln_total_err_mod_qual_count,9,' '));
   display_out(RPAD('No. Of Qualifier Records Successfully Validated         : ',58,' ')||RPAD(ln_succ_valid_qual_count,9,' '));
   display_out(RPAD('=',67,'='));

EXCEPTION
   WHEN OTHERS THEN
       x_retcode := 2;
       log_procedure(
                     p_control_id           => NULL
                     ,p_source_system_code   => NULL
                     ,p_procedure_name       => 'TO_PRINT_OUT'
                     ,p_staging_table_name   => NULL
                     ,p_staging_column_name  => NULL
                     ,p_staging_column_value => NULL
                     ,p_source_system_ref    => NULL
                     ,p_batch_id             => p_batch_id
                     ,p_exception_log        => NULL
                     ,p_oracle_error_code    => SQLCODE
                     ,p_oracle_error_msg     => SQLERRM
                    );
END to_print_out;


-- +=================================================================================+
-- | Name        :  child_main                                                       |
-- |                                                                                 |
-- | Description :  This procedure is invoked from the OD: QP Modifiers              |
-- |                Conversion Child Concurrent Request.This would                   |
-- |                validate the records and call qp_modifiers_pub.process_modifiers |
-- |                to process the records to the EBS tables.                        |
-- |                                                                                 |
-- |                                                                                 |
-- | Parameters  :  p_validate_only_flag                                             |
-- |                p_reset_status_flag                                              |
-- |                p_batch_id                                                       |
-- |                                                                                 |
-- | Returns     :                                                                   |
-- |                                                                                 |
-- +=================================================================================+

PROCEDURE child_main(
                     x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag IN  VARCHAR2
                     ,p_reset_status_flag  IN  VARCHAR2
                     ,p_batch_id           IN  NUMBER
                    )


IS

-- ------------------------------------------
-- Local Exceptions and Variables Declaration
-- ------------------------------------------
EX_NO_ENTRY           EXCEPTION;
EX_NO_VALID_DATA      EXCEPTION;
ln_user_id            PLS_INTEGER;
lc_conv_return_status VARCHAR2(03);
lx_errbuf             VARCHAR2(2000);
lx_retcode            VARCHAR2(10);


BEGIN

   ln_user_id := FND_GLOBAL.user_id;

   get_conversion_id(
                     x_conversion_id  => gn_conversion_id
                     ,x_batch_size    => gn_batch_size
                     ,x_max_threads   => gn_max_child_req
                     ,x_return_status => lc_conv_return_status
                     ,x_errbuf        => lx_errbuf
                    );
   CASE
      WHEN lc_conv_return_status = 'S' THEN

      BEGIN
         -- -------------------------------------------------------
         -- Update the errored records if Reset Status flag = 'Y'
         -- --------------------------------------------------------
         lx_retcode := NULL;
         lx_errbuf  := NULL;

         IF NVL(p_reset_status_flag,'N') = 'Y' THEN
            update_err_child_batch_id(
                                      p_batch_id => p_batch_id
                                      ,x_errbuf   => lx_errbuf
                                      ,x_retcode  => lx_retcode
                                     );
         END IF;

         -- -------------------------------------------------------
         -- Validate the records for a particular batch
         -- ---------------------------------------------------------

         validate_records(
                          p_batch_id => p_batch_id
                          ,x_retcode  => lx_retcode
                          ,x_errbuf   => lx_errbuf
                         );
         display_log('x_retcode : '||x_retcode);

         IF lx_retcode IS NOT NULL THEN
            x_retcode := lx_retcode;
         END IF;

         -- -------------------------------------------------------
         -- Check if Validate Only Flag = 'Y' then Exit
         -- Else Continue with Processing
         -- ---------------------------------------------------------

         IF NVL(p_validate_only_flag,'N') <> 'Y' THEN

            -- --------------------------------------------------------
            -- Call to process the records
            -- --------------------------------------------------------
            lx_retcode := NULL;
            process_modifiers(
                              p_batch_id => p_batch_id
                              ,x_retcode  => lx_retcode
                             );
            IF lx_retcode IS NOT NULL THEN
               x_retcode := lx_retcode;
            END IF;

            -- ----------------------------------------------------------------------
            -- Update the process_flag of line, qualfiers and pricing attributes to 6
            -- of those records where the process flag of header is equal to 6
            -- ----------------------------------------------------------------------
            update_child_batch_id(
                                  p_batch_id      => p_batch_id
                                  ,p_hdr_pro_flag  => 6
                                  ,p_new_pro_flag  => 6
                                 );

            -- ----------------------------------------------------------------------
            -- Update the process_flag of line, qualfiers and pricing attributes to 7
            -- of those records where the process flag of header is equal to 7
            -- ----------------------------------------------------------------------
            update_child_batch_id(
                                  p_batch_id      => p_batch_id
                                  ,p_hdr_pro_flag  => 7
                                  ,p_new_pro_flag  => 7
                                 );

         ELSE

            display_log('Program invoked in Validation Only mode. No processing done.');

         END IF; -- p_validate_only_flag

         -- --------------------------------------------------------
         -- To print in the output file
         -- --------------------------------------------------------
         lx_retcode := NULL;
         to_print_out(
                      p_batch_id => p_batch_id
                      ,x_errbuf  => x_errbuf
                      ,x_retcode => lx_retcode
                     );
         IF lx_retcode IS NOT NULL THEN
            x_retcode := lx_retcode;
         END IF;

      EXCEPTION
         WHEN OTHERS THEN
             x_retcode := 2;
             x_errbuf  := 'Error in child_main : '||SQLERRM;
             display_log(x_errbuf);
             log_procedure(
                           p_control_id           => NULL
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
      display_log('x_retcode : '||x_retcode);

      --------------------------------------------------------------------------------------------
      -- To launch the Exception Log Report for this batch
      --------------------------------------------------------------------------------------------
         lx_errbuf  := NULL;
         lx_retcode := NULL;
         launch_exception_report(
                                 p_batch_id => p_batch_id
                                 ,x_errbuf   => lx_errbuf
                                 ,x_retcode  => lx_retcode
                                );
         IF lx_retcode IS NOT NULL THEN
            x_retcode := lx_retcode;
            CASE
                WHEN x_errbuf is null THEN
                     x_errbuf  := lx_errbuf;
                ELSE
                     x_errbuf  := x_errbuf||'/'||lx_errbuf;
            END CASE;
         END IF;
      ELSE
         RAISE EX_NO_ENTRY;
   END CASE;
   display_log('x_retcode : '||x_retcode);



EXCEPTION
   WHEN EX_NO_ENTRY THEN
      x_retcode := 2;
      display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code ' ||G_CONVERSION_CODE);

END child_main;

-- +====================================================================+
-- | Name        :  master_main                                         |
-- |                                                                    |
-- | Description :  This procedure is invoked from the OD: QP Modifiers |
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
                      ,p_validate_only_flag IN         VARCHAR2
                      ,p_reset_status_flag  IN         VARCHAR2
                     )
IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------
EX_SUB_REQ       EXCEPTION;
lc_error_message VARCHAR2(4000);
ln_return_status PLS_INTEGER;

BEGIN

   gn_master_request_id := FND_GLOBAL.conc_request_id;

   -- --------------------------
   -- Call to submit_sub_requests
   -- --------------------------
   submit_sub_requests(
                       p_validate_only_flag => p_validate_only_flag
                       ,p_reset_status_flag => p_reset_status_flag
                       ,x_errbuf            => lc_error_message
                       ,x_retcode           => ln_return_status
                      );

   IF ln_return_status <> 0 THEN
     x_errbuf := lc_error_message;
     RAISE EX_SUB_REQ;
   END IF;

EXCEPTION
   WHEN EX_SUB_REQ THEN
       x_retcode := 2;
   WHEN NO_DATA_FOUND THEN
       x_retcode := 1;
       x_errbuf  := 'No Data Found in the table : '||SQLERRM;
       display_log(x_errbuf);
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected error in master_main procedure - '||SQLERRM;
       display_log(x_errbuf);
END master_main;
END XX_QP_MODIFIERS_IMPORT_PKG;
/
SHOW ERRORS;
