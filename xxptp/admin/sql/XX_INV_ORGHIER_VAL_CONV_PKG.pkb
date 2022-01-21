SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_INV_ORGHIER_VAL_CONV_PKG

-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |         Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +======================================================================================+
-- |                                                                                      |
-- | Name             :  XX_INV_ORGHIER_VAL_CONV_PKG                                      |
-- | Description      :  This package body is used in conversion of                       |
-- |                     Inventory Organization Hierarchy                                 |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date        Author           Remarks                                        |
-- |=======   ==========  ===============  ===============================================|
-- |Draft 1a  15-Apr-2007 Chandan U H      Initial draft version                          |
-- |Draft 1b  11-May-2007 Chandan U H      Incrporated the Master Conversion Program Logic|
-- |Draft 1c  04-Jun-2007 Chandan U H      Incorporated Onsite review comments and naming |
-- |                                       convention changes as per updated MD.040       |
-- |Draft 1d  08-Jun-2007 Chandan U H      Incorporated Onsite Review Comments            |
-- |Draft 1e  08-Jun-2007 Parvez Siddiqui  TL Review                                      |
-- |Draft 1f  19-Jun-2007 Chandan U H      Changed the parameter for the call to conform  |
-- |                                       with change in Interface                       |
-- |Draft 1g  20-Jun-2007 Chandan U H      Changes for:                                   |
-- |                                       a. New approach where ETL will load Hierarchy  |
-- |                                          Level in the staging table                  |
-- |                                       b. Onsite Testing Comments                     |
-- |Draft 1h  20-Jun-2007 Parvez Siddiqui  TL Review                                      |
-- |Draft 1i  22-Jun-2007 Chandan U H      Incorporated Onsite Review Comments and        |
-- |                                       p_action for API call changed to 'C' from 'ADD'|
-- |Draft 1j  22-Jun-2007 Parvez Siddiqui  TL Review                                      |
-- |Draft 1k  26-Jun-2007 Chandan U H      Incorporated Onsite Comments and now passing   |
-- |                                       gn_master_request_id in launch_summary_report  |
-- |                                       to show report only for that run of master     | 
-- |                                       program.Also changed the Order by clause.      |
-- |Draft 1l  26-Jun-2007 Parvez Siddiqui  TL Review                                      |
-- +======================================================================================+
AS

-- ----------------------------
-- Declaring Global Constants
-- ----------------------------
G_SLEEP                    CONSTANT PLS_INTEGER  := 60;
G_MAX_WAIT_TIME            CONSTANT PLS_INTEGER  := 300;
G_COMN_APPLICATION         CONSTANT VARCHAR2(30) := 'XXCOMN';
G_SUMRY_REPORT_PRGM        CONSTANT VARCHAR2(30) := 'XXCOMCONVSUMMREP';
G_EXCEP_REPORT_PRGM        CONSTANT VARCHAR2(30) := 'XXCOMCONVEXPREP';
G_CONVERSION_CODE          CONSTANT VARCHAR2(30) := 'C0304_OrgHierarchy';
G_CHLD_PROG_APPLICATION    CONSTANT VARCHAR2(30) := 'INV';
G_CHLD_PROG_EXECUTABLE     CONSTANT VARCHAR2(30) := 'XX_INV_ORGHIER_CNV_CHILD_MAIN';
G_PACKAGE_NAME             CONSTANT VARCHAR2(30) := 'XX_INV_ORGHIER_VAL_CONV_PKG';
G_STAGING_TABLE_NAME       CONSTANT VARCHAR2(30) := 'XX_INV_ORGHIER_VAL_STG';
G_HIERARCHY_LVL_CHAIN      CONSTANT VARCHAR2(30) := 'CHAIN';
G_HIERARCHY_LVL_AREA       CONSTANT VARCHAR2(30) := 'AREA';
G_HIERARCHY_LVL_REGION     CONSTANT VARCHAR2(30) := 'REGION';
G_HIERARCHY_LVL_DISTRICT   CONSTANT VARCHAR2(30) := 'DISTRICT';
G_ACTION                   CONSTANT VARCHAR2(30) := 'C';

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

-- +===========================================================================+
-- | Name        :  display_log                                                |
-- | Description :  This procedure is invoked to print in the log file         |
-- |                                                                           |
-- | In Parameter :  Log Message                                               |
-- +===========================================================================+
PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END display_log;

-- +===========================================================================+
-- | Name        :  display_out                                                |
-- | Description :  This procedure is invoked to print in the output file      |
-- |                                                                           |
-- | In Parameter :  Log Message                                               |
-- +===========================================================================+
PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END display_out;

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

     -- -----------------------------------------------------------------
     -- Call the common package to log exceptions
     -- -----------------------------------------------------------------
     
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
EXCEPTION

  WHEN OTHERS THEN
      display_log('Error in logging exception messages in log_procedure of child_main procedure');
      display_log(SQLERRM);
END log_procedure;

-- +===========================================================================+
-- | Name        :  update_batch_id                                            |
-- | Description :  This procedure is invoked to reset Batch Id to Null        |
-- |                for Previously Errored Out Records                         |
-- |                                                                           |
-- | Parameters  :                                                             |
-- +===========================================================================+

PROCEDURE update_batch_id
                        ( x_errbuf    OUT NOCOPY VARCHAR2
                         ,x_retcode   OUT NOCOPY VARCHAR2
                         )

IS

BEGIN
     -- ----------------------------------------
     -- Updating hte previously errored records
     -- ----------------------------------------
     UPDATE xx_inv_orghier_val_stg XIOHVS
     SET    XIOHVS.load_batch_id = NULL
           ,XIOHVS.process_flag  = 1
     WHERE  XIOHVS.process_flag NOT IN (0,7);

     COMMIT;

EXCEPTION
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Error in updating the failure records for reprocessing.';
       display_log(x_errbuf);
       
       log_procedure(   p_control_id           => NULL,
                        p_source_system_code   => NULL,
                        p_procedure_name       => 'UPDATE_BATCH_ID',
                        p_staging_table_name   => NULL,
                        p_staging_column_name  => NULL,
                        p_staging_column_value => NULL,
                        p_source_system_ref    => NULL,
                        p_batch_id             => NULL,
                        p_exception_log        => NULL,
                        p_oracle_error_code    => SQLCODE,
                        p_oracle_error_msg     => SQLERRM
                    );

END update_batch_id;

-- +====================================================================+
-- | Name        :  launch_summary_report                               |
-- | Description :  This procedure is invoked to Launch Conversion      |
-- |                Processing Summary Report for that run              |
-- |                                                                    |
-- | Parameters  :                                                      |
-- +====================================================================+

PROCEDURE launch_summary_report(
                                x_errbuf  OUT NOCOPY VARCHAR2,
                                x_retcode OUT NOCOPY VARCHAR2
                               )

IS

-- ----------------------------------------
-- Local Exception and Variable Declaration
-- ----------------------------------------
EX_SUMM_REP             EXCEPTION;

lc_phase                VARCHAR2(3);
ln_summ_request_id      PLS_INTEGER;

BEGIN

     FOR i IN gt_req_id.FIRST .. gt_req_id.LAST
     LOOP
         LOOP
             -- ----------------------------------------
             -- Get the status of the concurrent request
             -- ----------------------------------------
           BEGIN
             SELECT FCR.phase_code
             INTO   lc_phase
             FROM   fnd_concurrent_requests FCR
             WHERE  FCR.request_id = gt_req_id(i);
           EXCEPTION
              WHEN OTHERS THEN
                x_retcode := 1;              
                display_log('When Others raised when selecting phase_code from fnd_concurrent_requests table');           
           END;
             --- ------------------------------------------------
             --  If the concurrent requests completed sucessfully
             -- -------------------------------------------------

             IF
                lc_phase = 'C' THEN
                   EXIT;
              ELSE
                 dbms_lock.sleep(G_SLEEP);
             END IF;

         END LOOP;

     END LOOP;

     -- ---------------------------------------------
     -- Launch the summary report
     -- ---------------------------------------------

     ln_summ_request_id := FND_REQUEST.submit_request(
                                                      application  => G_COMN_APPLICATION,
                                                      program      => G_SUMRY_REPORT_PRGM,
                                                      sub_request  => FALSE,             
                                                      argument1    => G_CONVERSION_CODE, 
                                                      argument2    => gn_master_request_id,
                                                      argument3    => NULL,
                                                      argument4    => NULL
                                                     );

     CASE
         WHEN ln_summ_request_id = 0 THEN
              x_errbuf  := FND_MESSAGE.GET;
              RAISE EX_SUMM_REP;
         ELSE
             COMMIT;
     END CASE;

EXCEPTION

   WHEN EX_SUMM_REP THEN
       x_retcode := 1;
       x_errbuf  := 'Processing Summary Report could not be submitted.';
       display_log(x_errbuf);
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := ('When Others Exception in Processing Summary Report SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);
       display_log(x_errbuf);

END launch_summary_report;

-- +====================================================================+
-- | Name        :  launch_exception_report                             |
-- | Description :  This procedure is invoked to Launch Exception       |
-- |                Report for that batch                               |
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- +====================================================================+

PROCEDURE launch_exception_report(
                                   x_errbuf   OUT NOCOPY VARCHAR2
                                  ,x_retcode  OUT NOCOPY VARCHAR2
                                  ,p_batch_id IN  NUMBER
                                 )
IS

-- -----------------------------------------
-- Local Exception and Variables declaration
-- -----------------------------------------
EX_REP_EXC               EXCEPTION;

ln_excep_request_id      PLS_INTEGER;
ln_conc_request_id       PLS_INTEGER := FND_GLOBAL.conc_request_id;
lc_error_code            VARCHAR2(2000);

BEGIN    
   
     ln_excep_request_id := FND_REQUEST.submit_request(
                                                       application => G_COMN_APPLICATION,
                                                       program     => G_EXCEP_REPORT_PRGM,
                                                       sub_request => FALSE,
                                                       argument1   => G_CONVERSION_CODE,
                                                       argument2   => NULL,
                                                       argument3   => ln_conc_request_id,
                                                       argument4   => p_batch_id
                                                       );                                                    
                                                       

     CASE
         WHEN ln_excep_request_id = 0 THEN
              x_errbuf  := FND_MESSAGE.GET;
              RAISE EX_REP_EXC;
         ELSE
             COMMIT;
     END CASE;

EXCEPTION

   WHEN EX_REP_EXC THEN
       x_retcode := 1;
       x_errbuf  := 'Exception Summary Report for the batch '||p_batch_id||' could not be submitted.';
       log_procedure(p_control_id           => NULL,
                     p_source_system_code   => NULL,
                     p_procedure_name       => 'LAUNCH_EXCEPTION_REPORT',
                     p_staging_table_name   => NULL,
                     p_staging_column_name  => NULL,
                     p_staging_column_value => NULL,
                     p_source_system_ref    => NULL,
                     p_batch_id             => NULL,
                     p_exception_log        => NULL,
                     p_oracle_error_code    => SQLCODE,
                     p_oracle_error_msg     => SQLERRM
                     );

   WHEN OTHERS THEN
       x_retcode     := 2;
       lc_error_code := SQLCODE;
       x_errbuf      := SUBSTR(SQLERRM,12,2000);
       log_procedure(p_control_id           => NULL,
                     p_source_system_code   => NULL,
                     p_procedure_name       => 'LAUNCH_EXCEPTION_REPORT',
                     p_staging_table_name   => NULL,
                     p_staging_column_name  => NULL,
                     p_staging_column_value => NULL,
                     p_source_system_ref    => NULL,
                     p_batch_id             => NULL,
                     p_exception_log        => NULL,
                     p_oracle_error_code    => SQLCODE,
                     p_oracle_error_msg     => SQLERRM
                     );

END launch_exception_report;

-- +====================================================================+
-- | Name        :  get_conversion_details                              |
-- | Description :  This procedure is invoked to get the conversion_id  |
-- |                batch_size and max_threads                          |
-- |                                                                    |
-- |Out Parameters : Conversion_ID                                      |
-- |                 Batch_Size                                         |
-- |                 Max Threads                                        |
-- |                 x_return_status                                    |
-- |                                                                    |
-- +====================================================================+
PROCEDURE get_conversion_details(
                                x_conversion_id  OUT NOCOPY NUMBER,
                                x_batch_size     OUT NOCOPY NUMBER,
                                x_max_threads    OUT NOCOPY NUMBER,
                                x_return_status  OUT NOCOPY VARCHAR2
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

 -- ------------------------------------------------
 -- Get the conversion details into the out variable
 -- ------------------------------------------------
 x_return_status := 'S';

EXCEPTION
   WHEN NO_DATA_FOUND THEN
     x_return_status := 'E';
     display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code C0304_OrgHierarchy');
   WHEN OTHERS THEN
     display_log('Error while deriving conversion_id - '||SQLERRM);
END get_conversion_details;

-- +===========================================================================+
-- | Name        :  bat_child                                                  |
-- | Description :  This procedure is invoked from the submit_sub_requests     |
-- |                procedure. This would submit child requests based          |
-- |                on batch_size.                                             |
-- |                                                                           |
-- |                                                                           |
-- | In Parameters :p_request_id                                               |
-- |                p_validate_only_flag                                       |
-- |                p_reset_status_flag                                        |
-- |                                                                           |
-- |Out Parameters  x_time                                                     |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE bat_child(
                     x_errbuf             OUT   NOCOPY VARCHAR2
                    ,x_retcode            OUT   NOCOPY VARCHAR2
                    ,x_time               OUT   NOCOPY DATE
                    ,p_request_id         IN    NUMBER
                    ,p_validate_only_flag IN    VARCHAR2
                    ,p_reset_status_flag  IN    VARCHAR2

                   )
IS

-- -----------------------------------------
-- Local Exception and Variables declaration
-- -----------------------------------------
EX_SUBMIT_CHILD           EXCEPTION;

ln_batch_size_count       PLS_INTEGER;
ln_seq                    PLS_INTEGER;
ln_req_count              PLS_INTEGER;
ln_conc_request_id        PLS_INTEGER;

BEGIN

     -- ----------------------------------
     -- Get the batch_id from the sequence
     -- ----------------------------------
     
   BEGIN
     SELECT xx_inv_orghier_val_stg_bat_s.NEXTVAL
     INTO   ln_seq
     FROM   DUAL;
     
   EXCEPTION    
      WHEN OTHERS THEN
         x_retcode := 1;
         x_errbuf  := 'Unexpected errors occured when selecting xx_inv_orghier_val_stg_bat_s.NEXTVAL';
         display_log(x_errbuf);
   END;      
   
     
     
     -- -----------------------------
     -- Assign batches to the records
     -- -----------------------------

     UPDATE xx_inv_orghier_val_stg XIOHVS
     SET    XIOHVS.load_batch_id  = ln_seq
            ,XIOHVS.process_flag  = 2
     WHERE  XIOHVS.load_batch_id IS NULL
     AND    XIOHVS.process_flag   = 1
     AND    rownum <= gn_batch_size;

     ln_batch_size_count := SQL%ROWCOUNT;

     COMMIT;

     gn_record_count := gn_record_count + ln_batch_size_count;

     LOOP
         -- --------------------------------------------
         -- Get the count of running concurrent requests
         -- --------------------------------------------
       BEGIN  
         
         SELECT COUNT(1)
         INTO   ln_req_count
         FROM   fnd_concurrent_requests FCR
         WHERE  FCR.parent_request_id  = gn_master_request_id
         AND    FCR.phase_code IN ('P','R'); 
         
        EXCEPTION    
          WHEN OTHERS THEN
             x_retcode := 1;
             x_errbuf  := 'Unexpected errors occured when selecting ln_req_count from fnd_concurrent_requests';
             display_log(x_errbuf);
        END;      
         IF ln_req_count < gn_max_child_req THEN

            -- ---------------------------------------------------------
            -- Call the custom concurrent program for parallel execution
            -- ---------------------------------------------------------

            ln_conc_request_id := FND_REQUEST.submit_request(
                                                             application  => G_CHLD_PROG_APPLICATION,
                                                             program      => G_CHLD_PROG_EXECUTABLE,
                                                             sub_request  => FALSE,
                                                             argument1    => p_validate_only_flag,
                                                             argument2    => p_reset_status_flag,
                                                             argument3    => ln_seq
                                                            );

            IF ln_conc_request_id = 0 THEN

               x_errbuf  := FND_MESSAGE.GET;
               RAISE EX_SUBMIT_CHILD;

            ELSE

                COMMIT;

                gn_index_req_id := gn_index_req_id + 1;
                gt_req_id(gn_index_req_id) := ln_conc_request_id;
                gn_batch_count  := gn_batch_count + 1;
                x_time := SYSDATE;

                ---------------------------------------------------
                -- Procedure to Log Conversion Control Informations.
                ---------------------------------------------------

                XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                                                               p_conversion_id          => gn_conversion_id,
                                                               p_batch_id               => ln_seq,
                                                               p_num_bus_objs_processed => ln_batch_size_count
                                                              );
                EXIT;

            END IF;

         ELSE
             dbms_lock.sleep(G_SLEEP);
         END IF;

     END LOOP;

EXCEPTION
   WHEN EX_SUBMIT_CHILD THEN
      x_retcode := 1;
      x_errbuf  := 'Child Requests Could Not be Submitted.';
      display_log(x_errbuf);
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := ('When Others Exception in bat_child SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);
       display_log(x_errbuf);

END bat_child;

-- +===========================================================================+
-- | Name        :  get_master_request_id                                      |
-- | Description :  This procedure is invoked to get the                       |
-- |                master_request_Id                                          |
-- |                                                                           |
-- | In Parameters :p_conversion_id                                            |
-- |                p_batch_id                                                 |
-- |                                                                           |
-- | Out Parameters:Master_Request_Id                                          |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE get_master_request_id(
                                 p_conversion_id      IN    NUMBER
                                ,p_batch_id           IN    NUMBER
                                ,x_master_request_id  OUT   NOCOPY  NUMBER
                               )
IS
BEGIN

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

-- +============================================================================+
-- | Name             :submit_sub_requests                                      |
-- | Description      :This Procedure is invoked from batch_main(Master Program)|
-- |                   which would call Child Programs based on Batch Size.     |
-- |                                                                            |
-- |  Parameters      :p_validate_only_flag                                     |
-- |                  ,p_reset_status_flag                                      |
-- +============================================================================+

PROCEDURE submit_sub_requests(
                               x_errbuf                  OUT  NOCOPY  VARCHAR2
                              ,x_retcode                 OUT  NOCOPY  NUMBER
                              ,p_validate_only_flag      IN           VARCHAR2
                              ,p_reset_status_flag       IN           VARCHAR2
                             )
IS

-- -----------------------------------------
-- Local Exception and Variables declaration
-- -----------------------------------------
EX_NO_CONV_DETAILS   EXCEPTION;
EX_NO_DATA           EXCEPTION;
EX_UPDATE_BAT        EXCEPTION;

ld_check_time        DATE;
ld_current_time      DATE;
ln_rem_time          NUMBER;
ln_current_count     PLS_INTEGER;
ln_last_count        PLS_INTEGER;
lc_return_status     VARCHAR2(3);
lc_launch            VARCHAR2(2):='N';


BEGIN

      get_conversion_details(
                             x_conversion_id  => gn_conversion_id,
                             x_batch_size     => gn_batch_size,
                             x_max_threads    => gn_max_child_req,
                             x_return_status  => lc_return_status
                             );

     IF lc_return_status = 'S' THEN

        IF NVL(p_reset_status_flag,'N') = 'Y' THEN

           -- --------------------------------------------------------
           -- Call update_batch_id to change status of errored records
           -- --------------------------------------------------------
          update_batch_id ( x_errbuf
                           ,x_retcode
                          );
                          
             IF x_retcode <> 0 THEN          
                RAISE EX_UPDATE_BAT;
             END IF;                       

        END IF;

        ld_check_time := SYSDATE;

        ln_current_count := 0;

        LOOP

              ln_last_count := ln_current_count;

           -- -----------------------------------------
           -- Get the current count of eligible records
           -- -----------------------------------------
           BEGIN
              SELECT COUNT(1)
              INTO   ln_current_count
              FROM   xx_inv_orghier_val_stg XIOHVS
              WHERE  XIOHVS.load_batch_id IS NULL
              AND    XIOHVS.process_flag = 1;
           EXCEPTION
              WHEN OTHERS THEN
               x_retcode := 1;              
               display_log('When Others raised when selecting count of records in staging table');           
           END;
           
           IF (ln_current_count >= gn_batch_size) THEN

              -- -------------------------------------------
              -- Call bat_child to launch the child requests
              -- -------------------------------------------
              
              bat_child(
                        p_request_id         => gn_master_request_id,
                        p_validate_only_flag => p_validate_only_flag,
                        p_reset_status_flag  => p_reset_status_flag,
                        x_time               => ld_check_time,
                        x_errbuf             => x_errbuf,
                        x_retcode            => x_retcode
                        );

              lc_launch := 'Y';

           ELSE

               IF ln_last_count = ln_current_count THEN

                  ld_current_time := SYSDATE;

                  ln_rem_time := (ld_current_time - ld_check_time)*86400;

                  IF  ln_rem_time > G_MAX_WAIT_TIME THEN
                      EXIT;
                  ELSE
                      dbms_lock.sleep(G_SLEEP);
                  END IF; -- ln_rem_time > G_MAX_WAIT_TIME

               ELSE

                   dbms_lock.sleep(G_SLEEP);

               END IF; -- ln_last_count = ln_current_count

           END IF; --  ln_current_count >= gn_batch_size

        END LOOP;

        IF ln_current_count <> 0 THEN

           bat_child(
                     p_request_id         => gn_master_request_id,
                     p_validate_only_flag => p_validate_only_flag,
                     p_reset_status_flag  => p_reset_status_flag,
                     x_time               => ld_check_time,
                     x_errbuf             => x_errbuf,
                     x_retcode            => x_retcode
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
                                  x_errbuf  => x_errbuf,
                                  x_retcode => x_retcode
                                 );

        END IF;

        display_out(RPAD('=',38,'='));
        display_out(RPAD('Batch Size                 : ',29,' ')||RPAD(gn_batch_size,9,' '));
        display_out(RPAD('Number of Batches Launched : ',29,' ')||RPAD(gn_batch_count,9,' '));
        display_out(RPAD('Number of Records          : ',29,' ')||RPAD(gn_record_count,9,' '));
        display_out(RPAD('=',38,'='));

     ELSE

        RAISE EX_NO_CONV_DETAILS;

     END IF;

EXCEPTION

   WHEN EX_UPDATE_BAT THEN
       x_retcode := 2;
   WHEN EX_NO_DATA THEN
       x_retcode := 1;
       x_errbuf  := 'No Eligible Records in the Staging Table XX_INV_ORGHIER_VAL_STG';
       display_log(x_errbuf);
   WHEN EX_NO_CONV_DETAILS THEN
       x_retcode := 2;
       x_errbuf  := 'There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code  C0304_OrgHierarchy';
       display_log(x_errbuf);
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := ('When Others Exception in submit_sub_requests SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);
       display_log(x_errbuf);
END submit_sub_requests;

-- +======================================================================================+
-- | Name             : child_main                                                        |
-- | Description      : This Procedure is called by master_man Procedure for each batch   |
-- |                    or from 'OD: INV Organization Hierarchy Child Program'         .  |
-- |                    This inturn calls a custom Procedure                              |
-- |                   'XX_INV_ORG_HIERARCHY_PKG.PROCESS_ORG_HIERARCHY' which validates   |
-- |                     and calls Standard API to populate the base tables               |
-- |                                                                                      |
-- | Parameters        :p_process_name                                                    |
-- |                    p_validate_only_flag                                              |
-- |                    p_reset_status_flag                                               |
-- |                    p_batch_id                                                        |
-- +======================================================================================+
PROCEDURE child_main (
                       x_errbuf                   OUT  NOCOPY   VARCHAR2
                      ,x_retcode                  OUT  NOCOPY   NUMBER
                      ,p_validate_only_flag       IN            VARCHAR2
                      ,p_reset_status_flag        IN            VARCHAR2
                      ,p_batch_id                 IN            NUMBER
                     )
IS
-- -----------------------------------------
-- Local Exceptions and Variables declaration
-- -----------------------------------------

EX_PROCESSING_SMRY_REPRT       EXCEPTION;
EX_FLEX_VALUE_SET_NAME         EXCEPTION;
EX_NO_DATA_FOUND_STG           EXCEPTION;
EX_VALUE_CATEGORY              EXCEPTION;
EX_VALIDATE_ONLY               EXCEPTION;
EX_NO_CONV_DETAILS             EXCEPTION;

lc_message_code                NUMBER;
ln_chain_number                NUMBER;
ln_area_number                 NUMBER;
ln_region_number               NUMBER;
ln_request_id                  PLS_INTEGER;
ln_max_child_req               PLS_INTEGER;
lx_retcode                     PLS_INTEGER;
ln_success_count               PLS_INTEGER:=0;
ln_error_count                 PLS_INTEGER:=0;
ln_validated_err               PLS_INTEGER:=0;
ln_total_records               PLS_INTEGER;
ln_val_success_count           PLS_INTEGER:=0;
ln_batch_size                  PLS_INTEGER;
lc_valid                       VARCHAR2(1);
lc_retcode_flag                VARCHAR2(1) := 'N';
lc_return_status               VARCHAR2(3);
lc_hierarchy_level             VARCHAR2(100);
lc_staging_column_name         VARCHAR2(100);
lc_staging_column_value        VARCHAR2(100);
lc_exception_log               VARCHAR2(100);
lc_oracle_error_code           VARCHAR2(100);
lc_return_msg                  VARCHAR2(1000); 
lc_error_msg                   VARCHAR2(1000); 

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

TYPE row_id_tbl_type         IS TABLE OF   ROWID
INDEX BY BINARY_INTEGER;
lt_row_id_tbl   row_id_tbl_type;

TYPE process_flag_tbl_tbl_type   IS TABLE OF   xx_inv_orghier_val_stg.process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_process_flag  process_flag_tbl_tbl_type;

TYPE error_messsage_tbl_type     IS TABLE OF   xx_inv_orghier_val_stg.error_message%TYPE
INDEX BY BINARY_INTEGER;
lt_error_message  error_messsage_tbl_type;

-- ------------------------------------------------------------------
-- Declare cursor to fetch the records in vaidation in progress state
-- ------------------------------------------------------------------
CURSOR lcu_batch_data_stg
IS
SELECT  XIOHVS.rowid,XIOHVS.*
FROM    xx_inv_orghier_val_stg  XIOHVS
WHERE   XIOHVS.load_batch_id = p_batch_id
AND     XIOHVS.process_flag <> 7
ORDER BY (CASE flex_value_set_name
                WHEN G_HIERARCHY_LVL_CHAIN        THEN  1 
                WHEN G_HIERARCHY_LVL_AREA         THEN  2
                WHEN G_HIERARCHY_LVL_REGION       THEN  3
                WHEN G_HIERARCHY_LVL_DISTRICT     THEN  4
           END ); 
           
TYPE  xx_org_hier_stg_tbl_type   IS TABLE OF   lcu_batch_data_stg%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_xx_org_hier_stg_tbl  xx_org_hier_stg_tbl_type;       

BEGIN
    get_conversion_details(
                           x_conversion_id  =>  gn_conversion_id
                          ,x_batch_size     =>  ln_batch_size
                          ,x_max_threads    =>  ln_max_child_req
                          ,x_return_status  =>  lc_return_status
                          );                         
                                               

    IF lc_return_status = 'S' THEN

     -- -------------------------------------------------------
     -- Collect the data into the table type
     -- Limit is not used because we are batching at the Master
     -- -------------------------------------------------------
       OPEN  lcu_batch_data_stg;
       FETCH lcu_batch_data_stg BULK COLLECT INTO lt_xx_org_hier_stg_tbl;
       CLOSE lcu_batch_data_stg;

      IF lt_xx_org_hier_stg_tbl.COUNT <> 0 THEN

         FOR i IN  1 .. lt_xx_org_hier_stg_tbl.last

         LOOP

            BEGIN
                ln_chain_number  :=NULL;
                ln_area_number   :=NULL;
                ln_region_number :=NULL;
                lt_row_id_tbl(i) :=lt_xx_org_hier_stg_tbl(i).rowid;
                lc_error_msg     :='S';             

                lc_hierarchy_level       := lt_xx_org_hier_stg_tbl(i).flex_value_set_name;
                lt_process_flag(i)       := lt_xx_org_hier_stg_tbl(i).process_flag;
                
                   IF lc_hierarchy_level  IS NOT NULL THEN

                      IF lc_hierarchy_level   =  G_HIERARCHY_LVL_CHAIN   THEN
                         NULL;
                      ELSIF lc_hierarchy_level   =  G_HIERARCHY_LVL_AREA THEN
                           IF  lt_xx_org_hier_stg_tbl(i).attribute1 IS NOT NULL THEN
                               ln_chain_number  :=  TO_NUMBER(lt_xx_org_hier_stg_tbl(i).attribute1);
                           ELSE
                               lc_error_msg := 'Chain Number does not exist for the Area';                               
                               log_procedure(
                                   p_control_id            => lt_xx_org_hier_stg_tbl(i).control_id,
                                   p_source_system_code    => lt_xx_org_hier_stg_tbl(i).source_system_code,
                                   p_procedure_name        => 'CHILD_MAIN',
                                   p_staging_table_name    => G_STAGING_TABLE_NAME,
                                   p_staging_column_name   => 'ATTRIBUTE1',
                                   p_staging_column_value  => 'NULL',
                                   p_source_system_ref     => lt_xx_org_hier_stg_tbl(i).source_system_ref,
                                   p_batch_id              => p_batch_id,
                                   p_exception_log         => lc_error_msg,
                                   p_oracle_error_code     => NULL,
                                   p_oracle_error_msg      => NULL
                               );                                      
                           END IF;      

                      ELSIF lc_hierarchy_level   =  G_HIERARCHY_LVL_REGION THEN
                           IF  lt_xx_org_hier_stg_tbl(i).attribute1 IS NOT NULL THEN
                               ln_area_number  :=  TO_NUMBER(lt_xx_org_hier_stg_tbl(i).attribute1);
                           ELSE
                               lc_error_msg := 'Area Number does not exist for the Region';
                               log_procedure(
                                   p_control_id            => lt_xx_org_hier_stg_tbl(i).control_id,
                                   p_source_system_code    => lt_xx_org_hier_stg_tbl(i).source_system_code,
                                   p_procedure_name        => 'CHILD_MAIN',
                                   p_staging_table_name    => G_STAGING_TABLE_NAME,
                                   p_staging_column_name   => 'ATTRIBUTE1',
                                   p_staging_column_value  => 'NULL',
                                   p_source_system_ref     => lt_xx_org_hier_stg_tbl(i).source_system_ref,
                                   p_batch_id              => p_batch_id,
                                   p_exception_log         => lc_error_msg,
                                   p_oracle_error_code     => NULL,
                                   p_oracle_error_msg      => NULL
                               );
                           END IF;    
                      ELSIF lc_hierarchy_level   =  G_HIERARCHY_LVL_DISTRICT THEN
                           IF  lt_xx_org_hier_stg_tbl(i).attribute1 IS NOT NULL THEN
                                ln_region_number  :=  TO_NUMBER(lt_xx_org_hier_stg_tbl(i).attribute1);
                           ELSE
                               lc_error_msg := 'Region Number does not exist for the District';
                               log_procedure(
                                   p_control_id            => lt_xx_org_hier_stg_tbl(i).control_id,
                                   p_source_system_code    => lt_xx_org_hier_stg_tbl(i).source_system_code,
                                   p_procedure_name        => 'CHILD_MAIN',
                                   p_staging_table_name    => G_STAGING_TABLE_NAME,
                                   p_staging_column_name   => 'ATTRIBUTE1',
                                   p_staging_column_value  => 'NULL',
                                   p_source_system_ref     => lt_xx_org_hier_stg_tbl(i).source_system_ref,
                                   p_batch_id              => p_batch_id,
                                   p_exception_log         => lc_error_msg,
                                   p_oracle_error_code     => NULL,
                                   p_oracle_error_msg      => NULL
                               );
                           END IF;
                      
                      ELSE

                       lc_error_msg   := 'Not a Valid Hierarchy';

                       log_procedure(
                                      p_control_id           => lt_xx_org_hier_stg_tbl(i).control_id,
                                      p_source_system_code   => lt_xx_org_hier_stg_tbl(i).source_system_code,
                                      p_procedure_name       => 'CHILD_MAIN',
                                      p_staging_table_name   =>  G_STAGING_TABLE_NAME,
                                      p_staging_column_name  => 'FLEX_VALUE_SET_NAME',
                                      p_staging_column_value => lt_xx_org_hier_stg_tbl(i).flex_value_set_name,
                                      p_source_system_ref    => lt_xx_org_hier_stg_tbl(i).source_system_ref,
                                      p_batch_id             => p_batch_id,
                                      p_exception_log        => lc_error_msg,
                                      p_oracle_error_code    => NULL,
                                      p_oracle_error_msg     => NULL
                                     );


                      END IF;
                   ELSE
                       lc_error_msg   := 'FLEX_VALUE_SET_NAME cannot be null';
                       log_procedure(
                                     p_control_id           => lt_xx_org_hier_stg_tbl(i).control_id,
                                     p_source_system_code   => lt_xx_org_hier_stg_tbl(i).source_system_code,
                                     p_procedure_name       => 'CHILD_MAIN',
                                     p_staging_table_name   =>  G_STAGING_TABLE_NAME,
                                     p_staging_column_name  => 'FLEX_VALUE_SET_NAME',
                                     p_staging_column_value => 'NULL',
                                     p_source_system_ref    => lt_xx_org_hier_stg_tbl(i).source_system_ref,
                                     p_batch_id             => p_batch_id,
                                     p_exception_log        => lc_error_msg,
                                     p_oracle_error_code    => NULL,
                                     p_oracle_error_msg     => NULL
                                     );
                  END IF;   

                   IF lc_error_msg = 'S' THEN 
                      ln_val_success_count := ln_val_success_count + 1;                        
                      lt_process_flag(i) := 4;                      
                      lt_error_message(i) := 'Successfully validated. No Error.';
                   ELSE
                      ln_validated_err  := ln_validated_err + 1;
                      lt_process_flag(i) := 3;                      
                      lt_error_message(i) := lc_error_msg;
                   END IF;
                   
                -- -------------------------------------------------------
                -- If Validate Only flag is Yes,Then Stop here.
                -- If Validate Only is No,Then continue processing  
                -- -------------------------------------------------------
                
                IF NVL(p_validate_only_flag,'N') = 'N' THEN                   
                
                   IF lt_process_flag(i) IN (4,5,6) THEN   
                       ------------------------------------------------------------------------------------------------
                       --         This Custom Procedure is called  which inturn calls Standard API
                       --                          to populate data in base tables
                       ------------------------------------------------------------------------------------------------

                       --ln_success_count := 0;--Initialise to if processing being done.
                       ln_val_success_count := 0;                       
                       lc_message_code := NULL;
                       lc_return_msg   := NULL;
                       BEGIN
                            XX_INV_ORG_HIERARCHY_PKG.PROCESS_ORG_HIERARCHY(
                                                                           p_hierarchy_level => lc_hierarchy_level
                                                                          ,p_value           => lt_xx_org_hier_stg_tbl(i).fnd_value
                                                                          ,p_description     => lt_xx_org_hier_stg_tbl(i).fnd_value_description
                                                                          ,p_action          => G_ACTION
                                                                          ,p_chain_number    => ln_chain_number
                                                                          ,p_area_number     => ln_area_number
                                                                          ,p_region_number   => ln_region_number
                                                                          ,x_message_code    => lc_message_code 
                                                                          ,x_message_data    => lc_return_msg
                                                                         );
                                                                         
                       EXCEPTION
                          WHEN OTHERS THEN
                              lt_process_flag(i) := 6;
                              ln_error_count := ln_error_count + 1; 
                              log_procedure(
                                            p_control_id           => lt_xx_org_hier_stg_tbl(i).control_id,
                                            p_source_system_code   => lt_xx_org_hier_stg_tbl(i).source_system_code,
                                            p_procedure_name       => 'CHILD_MAIN',
                                            p_staging_table_name   => 'Error in Call To API',
                                            p_staging_column_name  => NULL,
                                            p_staging_column_value => NULL,
                                            p_source_system_ref    => lt_xx_org_hier_stg_tbl(i).source_system_ref,
                                            p_batch_id             => p_batch_id,
                                            p_exception_log        => NULL,
                                            p_oracle_error_code    => SQLCODE,
                                            p_oracle_error_msg     => SQLERRM
                                           );
                              lc_message_code := 2;
                              lc_return_msg   := SQLERRM;
                              x_retcode       := 2;

                       END;   

                       CASE lc_message_code
                            WHEN 0 THEN
                                 lt_process_flag(i) := 7;
                                 lt_error_message(i) := NULL;
                                 ln_success_count := ln_success_count + 1;
                                 
                            ELSE
                                lt_process_flag(i) := 6;
                                ln_error_count := ln_error_count + 1;
                                log_procedure(
                                              p_control_id           => lt_xx_org_hier_stg_tbl(i).control_id,
                                              p_source_system_code   => lt_xx_org_hier_stg_tbl(i).source_system_code,
                                              p_procedure_name       => 'CHILD_MAIN',
                                              p_staging_table_name   => 'Processing Failed',
                                              p_staging_column_name  => NULL,
                                              p_staging_column_value => NULL,
                                              p_source_system_ref    => lt_xx_org_hier_stg_tbl(i).source_system_ref,
                                              p_batch_id             => p_batch_id,
                                              p_exception_log        => lc_return_msg,
                                              p_oracle_error_code    => NULL,
                                              p_oracle_error_msg     => NULL
                                             );
                                display_log('The Record with control_id '||lt_xx_org_hier_stg_tbl(i).control_id||' failed process');
                       END CASE;
                       lt_error_message(i) := lc_return_msg;                                                                                                           

                   END IF;--End If for lt_process_flag(i) IN (4,5,6)
                ELSE
                     display_log('Program invoked in Validation Only mode. No processing done.');
                END IF;
            EXCEPTION
               WHEN OTHERS THEN
               log_procedure(
                             p_control_id           => NULL,
                             p_source_system_code   => NULL,
                             p_procedure_name       => 'CHILD_MAIN',
                             p_staging_table_name   => 'Unexpected Error in child_main',
                             p_staging_column_name  => NULL,
                             p_staging_column_value => NULL,
                             p_source_system_ref    => NULL,
                             p_batch_id             => p_batch_id,
                             p_exception_log        => NULL,
                             p_oracle_error_code    => SQLERRM,
                             p_oracle_error_msg     => SQLCODE
                            );
            END;
         END LOOP;
         
           -- ------------------------------------------------
            -- Bulk Update the table with the validated results
            -- ------------------------------------------------
           FORALL i IN  lt_row_id_tbl.FIRST..lt_row_id_tbl.LAST
           
           UPDATE xx_inv_orghier_val_stg XIOVS
           SET XIOVS.process_flag  = lt_process_flag(i)
              ,XIOVS.error_message = lt_error_message(i)
           WHERE XIOVS.rowid = lt_row_id_tbl(i);
         
           COMMIT;   
           
         --------------------------------------------------------------------------------------------------
         --Gets the master request Id which needs to be passed while updating Control Information Log Table
         --------------------------------------------------------------------------------------------------
         get_master_request_id(
                                p_conversion_id      => gn_conversion_id
                               ,p_batch_id           => p_batch_id
                               ,x_master_request_id  => ln_request_id
                              );                             
                              
         -----------------------------------------------------------------------------------------
         --This is a custom Procedure  called to  Update Conversion Control Information Log Table
         -----------------------------------------------------------------------------------------
         XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                                                         p_conc_mst_req_id                  => ln_request_id
                                                        ,p_batch_id                         => p_batch_id
                                                        ,p_conversion_id                    => gn_conversion_id
                                                        ,p_num_bus_objs_failed_valid        => ln_validated_err
                                                        ,p_num_bus_objs_failed_process      => ln_error_count
                                                        ,p_num_bus_objs_succ_process        => ln_success_count
                                                        );
      ELSE      
       
          x_retcode := 1;
          lc_retcode_flag :='Y';
          display_log('No eligible records in staging table to be picked');
          log_procedure(
                         p_control_id           => NULL,
                         p_source_system_code   => NULL,
                         p_procedure_name       => 'CHILD_MAIN',
                         p_staging_table_name   => G_STAGING_TABLE_NAME,
                         p_staging_column_name  => NULL,
                         p_staging_column_value => NULL,
                         p_source_system_ref    => NULL,
                         p_batch_id             => p_batch_id,
                         p_exception_log        => 'No eligible records in staging table to be picked',
                         p_oracle_error_code    => NULL,
                         p_oracle_error_msg     => NULL
                );  
                      
        
      END IF;

      --------------------------------------------------------------------------------------------
      -- To launch the Exception Log Report for this batch
      --------------------------------------------------------------------------------------------
          launch_exception_report(
                                   x_errbuf        => x_errbuf
                                  ,x_retcode       => lx_retcode
                                  ,p_batch_id      => p_batch_id
                                  );

          IF lx_retcode NOT IN (1,2) THEN
              NULL;
          ELSE
              x_retcode := lx_retcode;
          END IF;       
          

          IF lc_retcode_flag = 'Y' THEN
             x_retcode := 1;
          END IF; 
                            
          ln_total_records := ln_error_count + ln_success_count + ln_validated_err + ln_val_success_count;--count of total records
          
          display_out('==================================================================================');
          display_out(RPAD('Total No.Of Organization Hierarchy Records                  :',65)||ln_total_records);
          display_out(RPAD('Total No.Of Organization Hierarchy Records Failed Validation:',65)||ln_validated_err);
          display_out(RPAD('Total No.Of Organization Hierarchy Records Processed        :',65)||ln_success_count);
          display_out(RPAD('Total No.Of Organization Hierarchy Records Errored          :',65)||ln_error_count);
          display_out('==================================================================================');
    ELSE
       RAISE EX_NO_CONV_DETAILS;
    END IF;      

----------------------------
--Handling Exceptions
----------------------------
EXCEPTION

      WHEN EX_NO_CONV_DETAILS THEN
        x_retcode := 2;
        display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code C0304_OrgHierarchy');
        log_procedure( p_control_id           => NULL,
                       p_source_system_code   => NULL,
                       p_procedure_name       => 'CHILD_MAIN',
                       p_staging_table_name   => NULL,
                       p_staging_column_name  => NULL,
                       p_staging_column_value => NULL,
                       p_source_system_ref    => NULL,
                       p_batch_id             => NULL,
                       p_exception_log        => NULL,
                       p_oracle_error_code    => SQLCODE,
                       p_oracle_error_msg     => SQLERRM
                    );
                                       
     
      WHEN NO_DATA_FOUND THEN
         x_retcode := 1;
         x_errbuf  := 'No Data Found Exception Raised'||substr(SQLERRM,1,200);
         log_procedure(p_control_id           => NULL,
                       p_source_system_code   => NULL,
                       p_procedure_name       => 'CHILD_MAIN',
                       p_staging_table_name   => NULL,
                       p_staging_column_name  => NULL,
                       p_staging_column_value => NULL,
                       p_source_system_ref    => NULL,
                       p_batch_id             => NULL,
                       p_exception_log        => NULL,
                       p_oracle_error_code    => SQLCODE,
                       p_oracle_error_msg     => SQLERRM
                      );

      WHEN OTHERS THEN
         x_errbuf  := 'Unexpected Exception is Raised in Procedure MAIN '||substr(SQLERRM,1,200);
         x_retcode := 2;
         log_procedure( p_control_id         => NULL,
                      p_source_system_code   => NULL,
                      p_procedure_name       => 'CHILD_MAIN',
                      p_staging_table_name   => NULL,
                      p_staging_column_name  => NULL,
                      p_staging_column_value => NULL,
                      p_source_system_ref    => NULL,
                      p_batch_id             => NULL,
                      p_exception_log        => NULL,
                      p_oracle_error_code    => SQLCODE,
                      p_oracle_error_msg     => SQLERRM
                      );
                      
END child_main;

-- +===========================================================================+
-- | Name        :  master_main                                                |
-- | Description :  This procedure is invoked from  OD:INV Organization        |
-- |                Hierarchy Master Program Concurrent Request.               |
-- |                This would submit child programs based on batch_size       |
-- |                                                                           |
-- |   Parameters:  p_validate_only_flag                                       |
-- |                p_reset_status_flag                                        |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE master_main(
                      x_errbuf             OUT NOCOPY VARCHAR2,
                      x_retcode            OUT NOCOPY NUMBER,
                      p_validate_only_flag IN  VARCHAR2,
                      p_reset_status_flag  IN  VARCHAR2
                     )
IS

-- -----------------------------------------
-- Local Exception and Variables declaration
-- -----------------------------------------

EX_SUB_REQ       EXCEPTION;
EX_SUB_REQU      EXCEPTION;

ln_return_status PLS_INTEGER;
lc_error_message VARCHAR2(4000);


BEGIN

     gn_master_request_id := FND_GLOBAL.conc_request_id;

     submit_sub_requests(
                         p_validate_only_flag => p_validate_only_flag,
                         p_reset_status_flag  => p_reset_status_flag,
                         x_errbuf             => lc_error_message,
                         x_retcode            => ln_return_status
                        );

    IF ln_return_status = 1 THEN
          x_errbuf := lc_error_message;
          display_log('Error in submit_sub_requests.');
          RAISE EX_SUB_REQ;

     ELSIF ln_return_status = 2 THEN
             x_errbuf := lc_error_message;
             display_log('Error in submit_sub_requests.');            
          RAISE EX_SUB_REQU;

     END IF;     

EXCEPTION

  WHEN EX_SUB_REQ THEN
         x_retcode := 1;  
  WHEN EX_SUB_REQU THEN
       x_retcode := 2;
  WHEN NO_DATA_FOUND THEN
       x_retcode := 1;
       display_log('No Data Found');
  WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected error in child_main procedure - '||SQLERRM;
       display_log(x_errbuf);
END master_main;

END XX_INV_ORGHIER_VAL_CONV_PKG;
/
SHOW ERRORS;

EXIT;