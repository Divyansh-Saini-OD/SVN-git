SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT 'Creating XX_INV_MERCHIER_VAL_CONV_PKG package body'
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_INV_MERCHIER_VAL_CONV_PKG
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                         |
-- +=====================================================================================+
-- |                                                                                     |
-- | Name             :  XX_INV_MERCHIER_VAL_CONV_PKG.pkb                                |
-- | Description      :  This package read and batch the records. It submits a child     |
-- |                     concurrent program for each batch for the further processing.   |
-- |                                                                                     |
-- |                                                                                     |
-- | Change Record:                                                                      |
-- |===============                                                                      |
-- |Version   Date        Author           Remarks                                       |
-- |=======   ==========  =============    ==============================================|
-- |Draft 1a  16-Apr-2007 Gowri Nagarajan  Initial draft version                         |
-- |Draft 1b  11-May-2007 Gowri Nagarajan  Incoporated the Master Conversion Prog Logic  |
-- |Draft 1c  04-Jun-2007 Gowri Nagarajan  Incorporated Onsite review comments and naming|
-- |                                       convention changes as per updated MD.040      |
-- |Draft 1d  08-Jun-2007 Abhradip Ghosh   Incorporated Onsite Review Comments           |
-- |Draft 1e  08-Jun-2007 Parvez Siddiqui  TL Review                                     |
-- |Draft 1f  12-Jun-2007 Abhradip Ghosh   Change for flip of the Value Set / Values     |
-- |Draft 1g  13-Jun-2007 Gowri Nagarajan  Changes for:                                  |
-- |                                       a. New approach where ETL will load Hierarchy |
-- |                                       Level in the staging table                    |
-- |                                       b. Onsite Testing Comments                    |
-- |Draft 1h  13-Jun-2007 Parvez Siddiqui  TL Review                                     |
-- |Draft 1i  20-Jun-2007 Gowri Nagarajan  Incorporated Onsite Review Comments           |
-- |                                       a) Used ROWID instead of control_id           |
-- |                                       b) Changed the return code value to 1 for     |
-- |                                          warning conditions                         |
-- |Draft 1j  20-Jun-2007 Parvez Siddiqui  TL Review                                     |
-- |Draft 1k  21-Jun-2007 Gowri Nagarajan  Updated Conversion action to 'C' because      |
-- |                                       of action change in                           |
-- |                                       XX_INV_MERC_HIERARCHY_PKG.process_merc_       |
-- |                                       hierarchy interface                           |
-- |Draft 1l  21-Jun-2007 Parvez Siddiqui  TL Review                                     |
-- |Draft 1m  26-Jun-2007 Gowri Nagarajan  a)Changed query for the ORDER BY Clause       |
-- |                                       b)Added Master_request_id as a parameter      |
-- |                                          for launching Summary report               |
-- |Draft 1n  26-Jun-2007 Parvez Siddiqui  TL Review                                     |
-- +=====================================================================================+

AS

-- ----------------------------
-- Declaring Global Constants
-- ----------------------------
G_SLEEP                    CONSTANT PLS_INTEGER  :=  60;
G_MAX_WAIT_TIME            CONSTANT PLS_INTEGER  :=  300;
G_COMN_APPLICATION         CONSTANT VARCHAR2(30) := 'XXCOMN';
G_SUMRY_REPORT_PRGM        CONSTANT VARCHAR2(30) := 'XXCOMCONVSUMMREP';
G_EXCEP_REPORT_PRGM        CONSTANT VARCHAR2(30) := 'XXCOMCONVEXPREP';
G_CONVERSION_CODE          CONSTANT VARCHAR2(30) := 'C0273_MerchHierarchy';
G_CHLD_PROG_APPLICATION    CONSTANT VARCHAR2(30) := 'INV';
G_CHLD_PROG_EXECUTABLE     CONSTANT VARCHAR2(30) := 'XX_INV_MH_CONV_PKG_CHILD_MAIN';
G_PACKAGE_NAME             CONSTANT VARCHAR2(30) := 'XX_INV_MERCHIER_VAL_CONV_PKG';
G_STAGING_TABLE_NAME       CONSTANT VARCHAR2(30) := 'XX_INV_MERCHIER_VAL_STG';
G_HIERARCHY_LVL_DIVISION   CONSTANT VARCHAR2(30) := 'DIVISION';
G_HIERARCHY_LVL_GROUP      CONSTANT VARCHAR2(30) := 'GROUP';
G_HIERARCHY_LVL_DEPARTMENT CONSTANT VARCHAR2(30) := 'DEPARTMENT';
G_HIERARCHY_LVL_CLASS      CONSTANT VARCHAR2(30) := 'CLASS';
G_HIERARCHY_LVL_SUBCLASS   CONSTANT VARCHAR2(30) := 'SUBCLASS';
G_ACTION                   CONSTANT VARCHAR2(1) :=  'C';


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

END display_log;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the output    |
-- |                file                                                |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+

PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )

IS

BEGIN
     
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
     
END display_out;

-- +====================================================================+
-- | Name        :  update_batch_id                                     |
-- | Description :  This procedure is invoked to reset Batch Id to Null |
-- |                for Previously Errored Out Records                  |
-- |                                                                    |
-- | Parameters  :                                                      |
-- +====================================================================+

PROCEDURE update_batch_id(
                          x_errbuf    OUT NOCOPY VARCHAR2
                         ,x_retcode  OUT NOCOPY VARCHAR2
                         )

IS

BEGIN
     -- ----------------------------------------
     -- Updating hte previously errored records
     -- ----------------------------------------
     UPDATE xx_inv_merchier_val_stg XIFFVS
     SET    XIFFVS.load_batch_id  = NULL,
            XIFFVS.process_flag   = 1
     WHERE  XIFFVS.process_flag NOT IN (0,7);

     COMMIT;

EXCEPTION
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Error in updating the failure records for reprocessing.';       
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

-- --------------------------
-- Local Variable Declaration
-- --------------------------
EX_REP_SUMM             EXCEPTION;
lc_status               VARCHAR2(03);
ln_summ_request_id PLS_INTEGER;

BEGIN

     FOR i IN gt_req_id.FIRST .. gt_req_id.LAST
     LOOP
         LOOP
             -- ----------------------------------------
             -- Get the status of the concurrent request
             -- ----------------------------------------
     
             SELECT FCR.phase_code
             INTO   lc_status
             FROM   fnd_concurrent_requests FCR
             WHERE  FCR.request_id = gt_req_id(i);
     
             --- ------------------------------------------------
             --  If the concurrent requests completed sucessfully
             -- -------------------------------------------------
     
             CASE 
                 WHEN lc_status = 'C' THEN
                      EXIT;
                 ELSE
                     dbms_lock.sleep(G_SLEEP);
             END CASE;
             
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
              RAISE EX_REP_SUMM;
         ELSE
             COMMIT;
     END CASE;           

EXCEPTION

   WHEN EX_REP_SUMM THEN
       x_retcode := 1;
       x_errbuf  := 'Processing Summary Report could not be submitted.';
    
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := ('When Others Exception in Processing Summary Report SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);
      
END launch_summary_report;

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

-- +====================================================================+
-- | Name        :  launch_exception_report                             |
-- | Description :  This procedure is invoked to Launch Exception       |
-- |                Report for that batch                               |
-- |                                                                    |
-- | Parameters  :                                                      |
-- +====================================================================+

PROCEDURE launch_exception_report(
                                  p_batch_id IN NUMBER,
                                  x_errbuf   OUT NOCOPY VARCHAR2,
                                  x_retcode  OUT NOCOPY VARCHAR2
                                 )
IS

-- --------------------------
-- Local Variable declaration
-- --------------------------
EX_REP_EXC               EXCEPTION;
ln_excep_request_id      PLS_INTEGER;
ln_child_request_id      PLS_INTEGER := FND_GLOBAL.conc_request_id;
lc_error_code            VARCHAR2(2000);

BEGIN

     ln_excep_request_id := FND_REQUEST.submit_request(
                                                            application => G_COMN_APPLICATION,
                                                            program     => G_EXCEP_REPORT_PRGM,
                                                            sub_request => FALSE,
                                                            argument1   => G_CONVERSION_CODE, 
                                                            argument2   => NULL,
                                                            argument3   => ln_child_request_id,
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

   WHEN OTHERS THEN
       x_retcode     := 2;       
       lc_error_code := SQLCODE;
       x_errbuf      := SUBSTR(SQLERRM,12,2000);                  

END launch_exception_report;

-- +====================================================================+
-- | Name        :  get_conversion_id                                   |
-- | Description :  This procedure is invoked to get the conversion_id  |
-- |               ,batch_size and max_threads                          |
-- |                                                                    |
-- | Parameters  :                                                      |
-- |                                                                    |
-- | Returns     :  Conversion_ID                                       |
-- |                Batch_Size                                          |
-- |                                                                    |
-- +====================================================================+

PROCEDURE get_conversion_id(
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
      display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code C0273_MerchHierarchy');
      
  WHEN OTHERS THEN   
      display_log('Error while deriving conversion_id - '||SQLERRM);

END get_conversion_id;

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
                    p_request_id         IN  NUMBER,
                    p_validate_only_flag IN  VARCHAR2,
                    p_reset_status_flag  IN  VARCHAR2,
                    x_time               OUT NOCOPY DATE,
                    x_errbuf             OUT NOCOPY VARCHAR2,
                    x_retcode            OUT NOCOPY VARCHAR2
                   )

IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------

EX_SUBMIT_CHILD     EXCEPTION;
ln_batch_size_count PLS_INTEGER;
ln_seq              PLS_INTEGER;
ln_req_count        PLS_INTEGER;
ln_conc_request_id  PLS_INTEGER;


BEGIN

     -- ----------------------------------
     -- Get the batch_id from the sequence
     -- ----------------------------------
     SELECT xx_inv_merchier_val_stg_bat_s.NEXTVAL
     INTO   ln_seq
     FROM   DUAL;

     -- -----------------------------
     -- Assign batches to the records
     -- -----------------------------

     UPDATE xx_inv_merchier_val_stg XIFFVS
     SET    XIFFVS.load_batch_id  = ln_seq
            ,XIFFVS.process_flag  = 2
     WHERE  XIFFVS.load_batch_id IS NULL
     AND    XIFFVS.process_flag = 1
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
                x_time := sysdate;

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
      x_retcode := 2;
      x_errbuf  := 'Child Requests Could Not be Submitted.';
      
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := ('When Others Exception in bat_child SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);       

END bat_child;

-- +===========================================================================+
-- | Name             : get_master_request_id                                  |
-- | Description      : This Procedure is called to get master_request_id      |
-- |                                                                           |
-- | Parameters         p_conversion_id                                        |
-- |                    p_batch_id                                             |
-- |                    x_master_request_id                                    |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE get_master_request_id(
                                p_conversion_id     IN  NUMBER,
                                p_batch_id          IN  NUMBER,
                                x_master_request_id OUT NOCOPY NUMBER,
                                x_return_status     OUT VARCHAR2
                               )
IS  

BEGIN

     SELECT XCCIC.master_request_id
     INTO   x_master_request_id
     FROM   XX_COM_CONTROL_INFO_CONV XCCIC
     WHERE  XCCIC.conversion_id = p_conversion_id
     AND    XCCIC.batch_id      = p_batch_id;  
  
     
     x_return_status := 'S';
     
     
        
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_master_request_id := NULL;
       x_return_status := 'E';
   WHEN OTHERS THEN
       x_master_request_id := NULL;       
END get_master_request_id;

-- +===================================================================+
-- | Name        :  submit_sub_requests                                |
-- | Description :  This procedure is invoked from the conv_master_main|
-- |                procedure. This would submit child requests based  |
-- |                on batch_size.                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_validate_omly_flag                               |
-- |                p_reset_status_flag                                |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE submit_sub_requests(
                              p_validate_only_flag IN  VARCHAR2,
                              p_reset_status_flag  IN  VARCHAR2,
                              x_errbuf             OUT NOCOPY VARCHAR2,
                              x_retcode            OUT NOCOPY VARCHAR2
                             )

IS

-- --------------------------
-- Local Variable declaration
-- --------------------------

EX_NO_DATA        EXCEPTION;
EX_NO_ENTRY       EXCEPTION;
ld_check_time     DATE;
ld_current_time   DATE;
ln_rem_time       NUMBER;
ln_current_count  PLS_INTEGER;
ln_last_count     PLS_INTEGER;
lc_return_status  VARCHAR2(03);
lc_launch         VARCHAR2(02):='N';


BEGIN

     get_conversion_id(
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
           FROM   xx_inv_merchier_val_stg XIFFVS
           WHERE  XIFFVS.load_batch_id IS NULL
           AND    XIFFVS.process_flag = 1;

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

                  ld_current_time := sysdate;

                  ln_rem_time := (ld_current_time - ld_check_time)*86400;

                  IF  ln_rem_time > G_MAX_WAIT_TIME THEN
                      EXIT;
                  ELSE
                      dbms_lock.sleep(G_SLEEP);
                  END IF;

               ELSE

                   dbms_lock.sleep(G_SLEEP);

               END IF;

           END IF;

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

        RAISE EX_NO_ENTRY;

     END IF;

EXCEPTION

   WHEN  EX_NO_DATA THEN
      x_retcode := 1;
      x_errbuf  := 'No Data Found in the Table xx_inv_merchier_val_stg';   
      
      
      
   WHEN EX_NO_ENTRY  THEN
      x_retcode := 2;
      x_errbuf  := 'There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code C0273_MerchHierarchy';
      
     
   WHEN OTHERS THEN
      x_retcode := 2;
      x_errbuf  := 'Unexpected error in submit_sub_requests '||SQLERRM;
      
   
END submit_sub_requests;


-- +===================================================================+
-- | Name       :    validate_process_records                          |
-- |                                                                   |
-- | Description:    It performs the validations before calling the    |
-- |                 custom API                                        |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE validate_process_records(
                                   p_batch_id            IN NUMBER,
                                   p_validate_only_flag  IN VARCHAR2,
                                   x_no_of_records       OUT NOCOPY NUMBER,  
                                   x_val_failed          OUT NOCOPY NUMBER,
                                   x_proc_success        OUT NOCOPY NUMBER,
                                   x_proc_failed         OUT NOCOPY NUMBER
                                  )
IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------

lc_value                     xx_inv_merchier_val_stg.fnd_value%TYPE;
lc_description               xx_inv_merchier_val_stg.fnd_value_description%TYPE;
lc_return_msg                VARCHAR2(1000);
lc_division_number           VARCHAR2(500);
lc_group_number              VARCHAR2(500);
lc_dept_number               VARCHAR2(500);
lc_class_number              VARCHAR2(500);
lc_dept_forecastingind       VARCHAR2(500);
lc_dept_aipfilterind         VARCHAR2(500);
lc_dept_planningind          VARCHAR2(500);
lc_dept_noncodeind           VARCHAR2(500);
lc_dept_ppp_ind              VARCHAR2(500);
lc_class_nbrdaysamd          VARCHAR2(500);
lc_class_fifthmrkdwnprocsscd VARCHAR2(500);
lc_class_prczcostflg         VARCHAR2(500);
lc_class_prczpriceflag       VARCHAR2(500);
lc_class_priczlistflag       VARCHAR2(500);
lc_class_furnitureflag       VARCHAR2(500);
lc_class_aipfilterind        VARCHAR2(500);
lc_subclass_defaulttaxcat    VARCHAR2(500);
lc_subclass_globalcontentind VARCHAR2(500);
lc_subclass_aipfilterind     VARCHAR2(500);
lc_subclass_ppp_ind          VARCHAR2(500);
lc_hierarchy_level           xx_inv_merchier_val_stg.flex_value_set_name%TYPE;
ln_error_code                NUMBER; 
lc_error_msg                 VARCHAR2(5000);



--------------------------------
--Declaring Table Type Variables
--------------------------------

TYPE row_id_tbl_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
lt_row_id  row_id_tbl_type;

TYPE pro_flg_tbl_type IS TABLE OF xx_inv_merchier_val_stg.process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_pro_flg  pro_flg_tbl_type;

TYPE err_msg_tbl_type IS TABLE OF xx_inv_merchier_val_stg.error_message%TYPE
INDEX BY BINARY_INTEGER;
lt_err_msg  err_msg_tbl_type;

-- ------------------------------------------------------------------
-- Declare cursor to fetch the records in vaidation in progress state
-- ------------------------------------------------------------------

CURSOR lcu_elig_rec
IS
SELECT XIMVS.*,XIMVS.ROWID     
FROM   xx_inv_merchier_val_stg XIMVS
WHERE  XIMVS.process_flag  NOT IN (0,7)
AND    XIMVS.load_batch_id = p_batch_id
ORDER BY (CASE flex_value_set_name
            WHEN G_HIERARCHY_LVL_DIVISION   THEN 1  
            WHEN G_HIERARCHY_LVL_GROUP      THEN 2
            WHEN G_HIERARCHY_LVL_DEPARTMENT THEN 3
            WHEN G_HIERARCHY_LVL_CLASS      THEN 4
            WHEN G_HIERARCHY_LVL_SUBCLASS   THEN 5
          END );   


TYPE stg_rec_tbl_type IS TABLE OF lcu_elig_rec%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_stg_record  stg_rec_tbl_type;


BEGIN     
     
     x_val_failed                 := 0;
     x_proc_success               := 0;
     x_proc_failed                := 0; 
     -- -------------------------------------------------------
     -- Collect the data into the table type
     -- Limit is not used because we are batching at the Master
     -- -------------------------------------------------------
     OPEN  lcu_elig_rec;
     FETCH lcu_elig_rec BULK COLLECT INTO lt_stg_record;
     CLOSE lcu_elig_rec;

     -- -------------------------------
     -- Validate the records one by one
     -- -------------------------------

     IF lt_stg_record.COUNT <> 0 THEN
        
        x_no_of_records := lt_stg_record.COUNT;        
        
        
        FOR i IN lt_stg_record.FIRST..lt_stg_record.LAST
        LOOP

            BEGIN                 
                 
                                  
                 lt_row_id(i)                 := lt_stg_record(i).rowid     ;
                 lt_pro_flg(i)                := lt_stg_record(i).process_flag;
                 lt_err_msg(i)                := NULL;
                 lc_error_msg                 := 'S';
                 
                 lc_value                     := lt_stg_record(i).fnd_value;
                 lc_description               := lt_stg_record(i).fnd_value_description;
                 lc_hierarchy_level           := lt_stg_record(i).flex_value_set_name;
                 lc_division_number           := NULL;
                 lc_group_number              := NULL;
                 lc_dept_number               := NULL;
                 lc_class_number              := NULL;
                 lc_dept_forecastingind       := NULL;
                 lc_dept_aipfilterind         := NULL;
                 lc_dept_planningind          := NULL;
                 lc_dept_noncodeind           := NULL;
                 lc_dept_ppp_ind              := NULL;
                 lc_class_nbrdaysamd          := NULL;
                 lc_class_fifthmrkdwnprocsscd := NULL;
                 lc_class_prczcostflg         := NULL;
                 lc_class_prczpriceflag       := NULL;
                 lc_class_priczlistflag       := NULL;
                 lc_class_furnitureflag       := NULL;
                 lc_class_aipfilterind        := NULL;
                 lc_subclass_defaulttaxcat    := NULL;
                 lc_subclass_globalcontentind := NULL;
                 lc_subclass_aipfilterind     := NULL;
                 lc_subclass_ppp_ind          := NULL;
                 ln_error_code                := NULL;
              
                          
                             CASE
                                 WHEN lc_hierarchy_level = G_HIERARCHY_LVL_GROUP THEN
                                      CASE 
                                          WHEN lt_stg_record(i).attribute1 IS NOT NULL THEN
                                               lc_division_number := lt_stg_record(i).attribute1;
                                          ELSE
                                              lc_error_msg := 'Division Number does not exist for the Group';
                                              log_procedure(
                                                            p_control_id            => lt_stg_record(i).control_id,
                                                            p_source_system_code    => lt_stg_record(i).source_system_code,
                                                            p_procedure_name        => 'VALIDATE_PROCESS_RECORDS',
                                                            p_staging_table_name    => G_STAGING_TABLE_NAME,
                                                            p_staging_column_name   => 'ATTRIBUTE1',
                                                            p_staging_column_value  => 'NULL',
                                                            p_source_system_ref     => lt_stg_record(i).source_system_ref,
                                                            p_batch_id              => p_batch_id,
                                                            p_exception_log         => lc_error_msg,
                                                            p_oracle_error_code     => NULL,
                                                            p_oracle_error_msg      => NULL
                                                           );
                                      END CASE;
                                 WHEN lc_hierarchy_level = G_HIERARCHY_LVL_DEPARTMENT THEN
                                      CASE 
                                          WHEN lt_stg_record(i).attribute1 IS NOT NULL THEN
                                               lc_group_number        := lt_stg_record(i).attribute1;
                                               lc_dept_forecastingind := lt_stg_record(i).attribute4;
                                               lc_dept_aipfilterind   := lt_stg_record(i).attribute9;
                                               lc_dept_planningind    := lt_stg_record(i).attribute3;
                                               lc_dept_noncodeind     := lt_stg_record(i).attribute5;
                                               lc_dept_ppp_ind        := lt_stg_record(i).attribute6;
                                          ELSE
                                              lc_error_msg := 'Group Number does not exists for the Department';
                                              log_procedure(
                                                            p_control_id            => lt_stg_record(i).control_id,
                                                            p_source_system_code    => lt_stg_record(i).source_system_code,
                                                            p_procedure_name        => 'VALIDATE_PROCESS_RECORDS',
                                                            p_staging_table_name    => G_STAGING_TABLE_NAME,
                                                            p_staging_column_name   => 'ATTRIBUTE1',
                                                            p_staging_column_value  => 'NULL',
                                                            p_source_system_ref     => lt_stg_record(i).source_system_ref,
                                                            p_batch_id              => p_batch_id,
                                                            p_exception_log         => lc_error_msg,
                                                            p_oracle_error_code     => NULL,
                                                            p_oracle_error_msg      => NULL
                                                           );
                                          END CASE;
                                 WHEN lc_hierarchy_level = G_HIERARCHY_LVL_CLASS THEN
                                      CASE 
                                          WHEN lt_stg_record(i).attribute1 IS NOT NULL THEN
                                               lc_dept_number               := lt_stg_record(i).attribute1;
                                               lc_class_nbrdaysamd          := lt_stg_record(i).attribute3;
                                               lc_class_fifthmrkdwnprocsscd := lt_stg_record(i).attribute4;
                                               lc_class_prczcostflg         := lt_stg_record(i).attribute5;
                                               lc_class_prczpriceflag       := lt_stg_record(i).attribute6;
                                               lc_class_priczlistflag       := lt_stg_record(i).attribute7;
                                               lc_class_furnitureflag       := lt_stg_record(i).attribute8;
                                               lc_class_aipfilterind        := lt_stg_record(i).attribute9;
                                          ELSE
                                              lc_error_msg := 'Department Number does not exists for the Class';
                                              log_procedure(                                                                            
                                                            p_control_id           => lt_stg_record(i).control_id,                      
                                                            p_source_system_code   => lt_stg_record(i).source_system_code,
                                                            p_procedure_name       => 'VALIDATE_PROCESS_RECORDS',
                                                            p_staging_table_name   => G_STAGING_TABLE_NAME,
                                                            p_staging_column_name  => 'ATTRIBUTE1',                                     
                                                            p_staging_column_value => 'NULL',                                           
                                                            p_source_system_ref    => lt_stg_record(i).source_system_ref,
                                                            p_batch_id             => p_batch_id,                                       
                                                            p_exception_log        => lc_error_msg,
                                                            p_oracle_error_code    => NULL,
                                                            p_oracle_error_msg     => NULL
                                                           );                                                                           
                                                                                                                                    
                                      END CASE;
                                 WHEN lc_hierarchy_level = G_HIERARCHY_LVL_SUBCLASS THEN
                                      CASE 
                                          WHEN (lt_stg_record(i).attribute1 IS NOT NULL AND lt_stg_record(i).attribute2 IS NOT NULL) THEN
                                               lc_dept_number               := lt_stg_record(i).attribute2;
                                               lc_class_number              := lt_stg_record(i).attribute1; 
                                               lc_subclass_defaulttaxcat    := lt_stg_record(i).attribute10;
                                               lc_subclass_globalcontentind := lt_stg_record(i).attribute8;
                                               lc_subclass_aipfilterind     := lt_stg_record(i).attribute9;
                                               lc_subclass_ppp_ind          := lt_stg_record(i).attribute6;
                                          ELSE
                                              lc_error_msg := 'Class number does not exists for the Subclass';
                                              log_procedure(                                                                                  
                                                            p_control_id           => lt_stg_record(i).control_id,                            
                                                            p_source_system_code   => lt_stg_record(i).source_system_code,
                                                            p_procedure_name       => 'VALIDATE_PROCESS_RECORDS',
                                                            p_staging_table_name   => G_STAGING_TABLE_NAME,
                                                            p_staging_column_name  => 'ATTRIBUTE1/ATTRIBUTE2',                                           
                                                            p_staging_column_value => 'NULL',                                                 
                                                            p_source_system_ref    => lt_stg_record(i).source_system_ref,                     
                                                            p_batch_id             => p_batch_id,
                                                            p_exception_log        => lc_error_msg,
                                                            p_oracle_error_code    => NULL,
                                                            p_oracle_error_msg     => NULL
                                                           );                                                                                 
                                      END CASE;
                                 WHEN lc_hierarchy_level = G_HIERARCHY_LVL_DIVISION THEN
                                      lc_division_number := NULL;
                                 
                                 ELSE                                       
                                        lc_error_msg   := 'Not a Valid Hierarchy';
                                      
                                        log_procedure(                                                                          
                                                      p_control_id           => lt_stg_record(i).control_id,                    
                                                      p_source_system_code   => lt_stg_record(i).source_system_code, 
                                                      p_procedure_name       => 'VALIDATE_PROCESS_RECORDS',
                                                      p_staging_table_name   =>  G_STAGING_TABLE_NAME,
                                                      p_staging_column_name  => 'FLEX_VALUE_SET_NAME',                        
                                                      p_staging_column_value => lt_stg_record(i).flex_value_set_name,            
                                                      p_source_system_ref    => lt_stg_record(i).source_system_ref,
                                                      p_batch_id             => p_batch_id,                                     
                                                      p_exception_log        => lc_error_msg,
                                                      p_oracle_error_code    => NULL,
                                                      p_oracle_error_msg     => NULL
                                                     );                                                                
                                 
                                     
                             END CASE;                                                               
                          
                             CASE 
                                 WHEN lc_error_msg = 'S' THEN
                                      lt_pro_flg(i) := 4;
                                      lt_err_msg(i) := 'Successfully validated. No Error.';
                                 ELSE
                                     lt_pro_flg(i) := 3;
                                     lt_err_msg(i) := lc_error_msg;
                                     x_val_failed := x_val_failed +1;
                             END CASE;                                                     
                                                    
                          -- ---------------------------------------------
                          -- If the validated records need to be processed
                          -- ---------------------------------------------

                          CASE 
                              WHEN NVL(p_validate_only_flag,'N') ='N' THEN
                                   
                                            -- ------------------------------------------------------
                                            -- Call XX_INV_MERC_HIERARCHY_PKG. Process_Merc_Hierarchy
                                            -- ------------------------------------------------------
                                            
                                            BEGIN
                                                 XX_INV_MERC_HIERARCHY_PKG.process_merc_hierarchy(
                                                                                                  p_hierarchy_level           => lc_hierarchy_level,
                                                                                                  p_value                     => lc_value,
                                                                                                  p_description               => lc_description,
                                                                                                  p_action                    => G_ACTION,
                                                                                                  p_division_number           => lc_division_number,
                                                                                                  p_group_number              => lc_group_number,
                                                                                                  p_dept_number               => lc_dept_number,
                                                                                                  p_class_number              => lc_class_number,
                                                                                                  p_dept_forecastingind       => lc_dept_forecastingind,
                                                                                                  p_dept_aipfilterind         => lc_dept_aipfilterind,
                                                                                                  p_dept_planningind          => lc_dept_planningind,
                                                                                                  p_dept_noncodeind           => lc_dept_noncodeind,
                                                                                                  p_dept_ppp_ind              => lc_dept_ppp_ind,
                                                                                                  p_class_nbrdaysamd          => lc_class_nbrdaysamd,
                                                                                                  p_class_fifthmrkdwnprocsscd => lc_class_fifthmrkdwnprocsscd,
                                                                                                  p_class_prczcostflg         => lc_class_prczcostflg,
                                                                                                  p_class_prczpriceflag       => lc_class_prczpriceflag,
                                                                                                  p_class_priczlistflag       => lc_class_priczlistflag,
                                                                                                  p_class_furnitureflag       => lc_class_furnitureflag,
                                                                                                  p_class_aipfilterind        => lc_class_aipfilterind,
                                                                                                  p_subclass_defaulttaxcat    => lc_subclass_defaulttaxcat,
                                                                                                  p_subclass_globalcontentind => lc_subclass_globalcontentind,
                                                                                                  p_subclass_aipfilterind     => lc_subclass_aipfilterind,
                                                                                                  p_subclass_ppp_ind          => lc_subclass_ppp_ind,
                                                                                                  x_error_msg                 => lc_return_msg,
                                                                                                  x_error_code                => ln_error_code
                                                                                                 );
                                            EXCEPTION
                                               WHEN OTHERS THEN
                                                   lt_pro_flg(i) := 6;
                                                   log_procedure(                                                                    
                                                                 p_control_id           => lt_stg_record(i).control_id,              
                                                                 p_source_system_code   => lt_stg_record(i).source_system_code,      
                                                                 p_procedure_name       => 'VALIDATE_PROCESS_RECORDS',               
                                                                 p_staging_table_name   => 'API Error',                     
                                                                 p_staging_column_name  => NULL,                                     
                                                                 p_staging_column_value => NULL,                                     
                                                                 p_source_system_ref    => lt_stg_record(i).source_system_ref,       
                                                                 p_batch_id             => p_batch_id,                               
                                                                 p_exception_log        => NULL,                                     
                                                                 p_oracle_error_code    => SQLCODE,                                  
                                                                 p_oracle_error_msg     => SQLERRM                                   
                                                                );  
                                                   ln_error_code := 2;
                                                   lc_return_msg := SQLERRM;
                                                   
                                            END;                                              
                                            
                                            CASE ln_error_code
                                                WHEN 0 THEN
                                                     lt_pro_flg(i) := 7;
                                                     lt_err_msg(i) := NULL;
                                                     
                                                     x_proc_success := x_proc_success +1;
                                                     
                                                ELSE
                                                    lt_pro_flg(i) := 6;
                                                    log_procedure(                                                                          
                                                                  p_control_id           => lt_stg_record(i).control_id,                    
                                                                  p_source_system_code   => lt_stg_record(i).source_system_code, 
                                                                  p_procedure_name       => 'VALIDATE_PROCESS_RECORDS',
                                                                  p_staging_table_name   => 'API Error',
                                                                  p_staging_column_name  => NULL,                        
                                                                  p_staging_column_value => NULL,                                         
                                                                  p_source_system_ref    => lt_stg_record(i).source_system_ref,
                                                                  p_batch_id             => p_batch_id,                                     
                                                                  p_exception_log        => lc_return_msg,
                                                                  p_oracle_error_code    => SQLCODE,
                                                                  p_oracle_error_msg     => SQLERRM
                                                                 );
                                                                 
                                                    x_proc_failed := x_proc_failed +1;
                                                
                                            END CASE;
                                            lt_err_msg(i) := lc_return_msg;
                                   
                                       
                              ELSE
                                 
                                 display_log('Program invoked in Validation Only mode. No processing done.');
                                      
                          END CASE;      
             
            EXCEPTION
              WHEN OTHERS THEN
                  lt_pro_flg(i) := 3;
                  lc_error_msg  := SQLERRM;
                  lt_err_msg(i) := lc_error_msg;
                  log_procedure(                                                                          
                                p_control_id           => lt_stg_record(i).control_id,                    
                                p_source_system_code   => lt_stg_record(i).source_system_code, 
                                p_procedure_name       => 'VALIDATE_PROCESS_RECORDS',
                                p_staging_table_name   => G_STAGING_TABLE_NAME,
                                p_staging_column_name  => NULL,                        
                                p_staging_column_value => NULL,                                       
                                p_source_system_ref    => lt_stg_record(i).source_system_ref,
                                p_batch_id             => p_batch_id,                                     
                                p_exception_log        => NULL,
                                p_oracle_error_code    => SQLCODE,
                                p_oracle_error_msg     => SQLERRM
                               );                                        
                  x_val_failed := x_val_failed +1;
            END;
            
        END LOOP;     
         
        -- ------------------------------------------------
        -- Bulk Update the table with the validated results
        -- ------------------------------------------------
        FORALL i IN lt_row_id.FIRST..lt_row_id.LAST
        UPDATE xx_inv_merchier_val_stg XIMVS
        SET XIMVS.process_flag  = lt_pro_flg(i),
            XIMVS.error_message = lt_err_msg(i)       
        WHERE XIMVS.rowid  = lt_row_id(i);
        
        COMMIT;
     
     ELSE
         
         x_no_of_records := 0;         
         
     END IF;
       
EXCEPTION      
     
   WHEN OTHERS THEN
       
       lc_error_msg := 'SQL Error';
       log_procedure(                                                                          
                     p_control_id           => NULL,                    
                     p_source_system_code   => NULL, 
                     p_procedure_name       => 'VALIDATE_PROCESS_RECORDS',
                     p_staging_table_name   => G_STAGING_TABLE_NAME,
                     p_staging_column_name  => NULL,                        
                     p_staging_column_value => NULL,                                       
                     p_source_system_ref    => NULL,
                     p_batch_id             => p_batch_id,                                     
                     p_exception_log        => lc_error_msg,
                     p_oracle_error_code    => SQLCODE,
                     p_oracle_error_msg     => SQLERRM
                    );                                  
       RAISE;
       
END validate_process_records;    

-- +===================================================================+
-- | Name       :    child_main                                        |
-- |                                                                   |
-- | Description:    It reads the records from the staging table for   |
-- |                 each batch, and processes the records by calling  |
-- |                 custom API to import the records to EBS tables.   |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE child_main(
                     x_errbuf             OUT NOCOPY VARCHAR2,
                     x_retcode            OUT NOCOPY NUMBER,
                     p_validate_only_flag IN  VARCHAR2,
                     p_reset_status_flag  IN  VARCHAR2,
                     p_batch_id           IN  NUMBER
                    )
IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------
EX_ENTRY_EXCEP       EXCEPTION;
EX_NO_DATA           EXCEPTION;
ln_request_id        PLS_INTEGER;
ln_val_failed        PLS_INTEGER;
ln_proc_success      PLS_INTEGER;
ln_proc_failed       PLS_INTEGER;
ln_new_rec_cnt       PLS_INTEGER;
ln_master_request_id PLS_INTEGER;
lc_return_status     VARCHAR2(1);
ln_excpn_request_id  PLS_INTEGER;
ln_no_of_records     PLS_INTEGER;
lc_return_msg        VARCHAR2(1000);




BEGIN

    BEGIN
     -- ------------------------------------
     -- Get the conversion_id and batch size
     -- ------------------------------------

     get_conversion_id(
                       x_conversion_id => gn_conversion_id
                      ,x_batch_size    => gn_batch_size
                      ,x_max_threads   => gn_max_child_req
                      ,x_return_status => lc_return_status
                      );

     IF lc_return_status = 'S' THEN
        
        validate_process_records(
                                 p_batch_id           => p_batch_id,
                                 p_validate_only_flag => p_validate_only_flag,
                                 x_no_of_records      => ln_no_of_records,                                
                                 x_val_failed         => ln_val_failed,
                                 x_proc_success       => ln_proc_success,
                                 x_proc_failed        => ln_proc_failed
                                 );                         
            
        
        IF ln_no_of_records <> 0 THEN          
                   
           -- ------------------------------------------------------------------------------------------------
           -- Gets the master request Id which needs to be passed while updating Control Information Log Table
           -- ------------------------------------------------------------------------------------------------
           
           get_master_request_id(
                                 p_conversion_id     => gn_conversion_id,
                                 p_batch_id          => p_batch_id,
                                 x_master_request_id => ln_master_request_id,
                                 x_return_status     => lc_return_status
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
                                                          p_num_bus_objs_failed_valid   => ln_val_failed,
                                                          p_num_bus_objs_failed_process => ln_proc_failed,
                                                          p_num_bus_objs_succ_process   => ln_proc_success
                                                         );            
           
           display_out('====================================================================================');
           display_out(RPAD('Total no Of Merchandising Hierarchy Records               :',60)||ln_no_of_records);
           display_out(RPAD('No Of Merchandising Hierarchy Records failed in validation:',60)||ln_val_failed);
           display_out(RPAD('No Of Merchandising Hierarchy Records Processed           :',60)||ln_proc_success);
           display_out(RPAD('No Of Merchandising Hierarchy Records Errored             :',60)||ln_proc_failed);
           display_out('====================================================================================');
           
           ELSE 
              
              IF lc_return_status = 'E' THEN
           
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
             ELSE              
                            
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
                            p_oracle_error_msg      => SQLERRM
                           );             
                          
            END IF;              
           
        END IF;
        
        ELSE
           RAISE EX_NO_DATA;            
        END IF;

     ELSE
     
           IF lc_return_status = 'E' THEN          
             
           
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
                                                                     
           ELSE
            
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
                            p_oracle_error_msg      => SQLERRM
                           );         
                               
              
           END IF;     

     END IF;
     
     EXCEPTION              
              
              WHEN OTHERS THEN
                  x_retcode := 2;
                  x_errbuf  := 'When Others Exception in Child_main';
                  log_procedure(
                                p_control_id            => NULL,
                                p_source_system_code    => NULL,
                                p_procedure_name        => 'CHILD_MAIN',
                                p_staging_table_name    => NULL,
                                p_staging_column_name   => NULL,
                                p_staging_column_value  => NULL,
                                p_source_system_ref     => NULL,
                                p_batch_id              => p_batch_id,
                                p_exception_log         => x_errbuf,
                                p_oracle_error_code     => SQLCODE,
                                p_oracle_error_msg      => SQLERRM
                    );
              
     END;
     
     --------------------------------------------------------------------------------------------
     -- To launch the Exception Log Report for this batch
     --------------------------------------------------------------------------------------------
                   
                launch_exception_report(
                                        p_batch_id => p_batch_id,
                                        x_errbuf   => x_errbuf,
                                        x_retcode  => x_retcode
                                        );
     
        IF lc_return_status = 'S' THEN
             x_retcode := 0;
             
        ELSIF lc_return_status = 'E' THEN
             x_retcode := 2;
             
        ELSE 
            x_retcode := 2;
        END IF;
        
        IF ln_no_of_records = 0 THEN
          RAISE EX_NO_DATA;
        END IF;
        

EXCEPTION
 
   WHEN EX_NO_DATA THEN
          x_retcode := 1;
          x_errbuf  := 'There is no valid data in the staging table';
          
          log_procedure(
                        p_control_id            => NULL,
                        p_source_system_code    => NULL,
                        p_procedure_name        => 'CHILD_MAIN',
                        p_staging_table_name    => G_STAGING_TABLE_NAME,
                        p_staging_column_name   => NULL,
                        p_staging_column_value  => NULL,
                        p_source_system_ref     => NULL,
                        p_batch_id              => p_batch_id,
                        p_exception_log         => x_errbuf,
                        p_oracle_error_code     => NULL,
                        p_oracle_error_msg      => NULL
                        );
                        
   WHEN NO_DATA_FOUND THEN
       x_retcode := 1;
       x_errbuf  := 'When No_data_Found Exception in Child_main';
       
       log_procedure(
                     p_control_id            => NULL,
                     p_source_system_code    => NULL,
                     p_procedure_name        => 'CHILD_MAIN',
                     p_staging_table_name    => NULL,
                     p_staging_column_name   => NULL,
                     p_staging_column_value  => NULL,
                     p_source_system_ref     => NULL,
                     p_batch_id              => p_batch_id,
                     p_exception_log         => x_errbuf,
                     p_oracle_error_code     => SQLCODE,
                     p_oracle_error_msg      => SQLERRM
                    );
                    
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'When Others Exception in Child_main';
       log_procedure(
                     p_control_id            => NULL,
                     p_source_system_code    => NULL,
                     p_procedure_name        => 'CHILD_MAIN',
                     p_staging_table_name    => NULL,
                     p_staging_column_name   => NULL,
                     p_staging_column_value  => NULL,
                     p_source_system_ref     => NULL,
                     p_batch_id              => p_batch_id,
                     p_exception_log         => x_errbuf,
                     p_oracle_error_code     => SQLCODE,
                     p_oracle_error_msg      => SQLERRM
                    );

END child_main;

-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: OD: MercHier |
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
                      x_errbuf             OUT NOCOPY VARCHAR2,
                      x_retcode            OUT NOCOPY NUMBER,
                      p_validate_only_flag IN  VARCHAR2,
                      p_reset_status_flag  IN  VARCHAR2
                     )
IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------
EX_SUB_REQ       EXCEPTION;
EX_SUB_REQU      EXCEPTION;
lc_error_message VARCHAR2(4000);
ln_return_status PLS_INTEGER;
   
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
          RAISE EX_SUB_REQU;
          
     ELSIF ln_return_status = 2 THEN
     
             x_errbuf := lc_error_message;              
             RAISE EX_SUB_REQ;
     
     END IF;

EXCEPTION

  WHEN EX_SUB_REQ THEN
       x_retcode := 2;
       
  WHEN EX_SUB_REQU THEN
       x_retcode := 1;
       
  WHEN NO_DATA_FOUND THEN
       x_retcode := 1;
       display_log('No Data Found');

  WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected error in child_main procedure - '||SQLERRM;       

END master_main;

END XX_INV_MERCHIER_VAL_CONV_PKG;
/
SHOW ERRORS;
EXIT;
