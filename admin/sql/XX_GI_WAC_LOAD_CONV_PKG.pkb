SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_WAC_LOAD_CONV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_GI_WAC_LOAD_CONV_PKG.pkb                        |
-- | Description :  Weighted Average Costs Package Body                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date         Author           Remarks                   |
-- |========   ===========  ===============  ==========================|
-- |DRAFT 1a   17-Jul-2007  Abhradip Ghosh   Initial draft version     |
-- |DRAFT 1.0  03-Aug-2007  Parvez Siddiqui  TL Review                 |
-- +===================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------
G_STAGING_TABLE_NAME       CONSTANT VARCHAR2(50)                                 := 'XX_GI_MTL_TRANS_INTF_STG';
G_CONVERSION_CODE          CONSTANT xx_com_conversions_conv.conversion_code%TYPE := 'C0052_WAC';
G_CHLD_PROG_APPLICATION    CONSTANT VARCHAR2(30)                                 := 'INV';
G_CHLD_PROG_EXECUTABLE     CONSTANT VARCHAR2(30)                                 := 'XX_GI_WAC_LOAD_CNV_PKG_CHD_MN';
G_SLEEP                    PLS_INTEGER;
G_COMN_APPLICATION         CONSTANT VARCHAR2(30)                                 := 'XXCOMN';
G_SUMRY_REPORT_PRGM        CONSTANT VARCHAR2(30)                                 := 'XXCOMCONVSUMMREP';
G_PACKAGE_NAME             CONSTANT VARCHAR2(30)                                 := 'XX_GI_WAC_LOAD_CONV_PKG';
G_EXCEP_PROGRAM            CONSTANT VARCHAR2(30)                                 := 'XXCOMCONVEXPREP';
G_LIMIT_SIZE               CONSTANT PLS_INTEGER                                  := 500;
G_PROCESS_FLAG             CONSTANT PLS_INTEGER                                  := 1;
G_TRANSACTION_MODE         CONSTANT PLS_INTEGER                                  := 3;
G_LOCK_FLAG                CONSTANT PLS_INTEGER                                  := 2;
G_USER_ID                  CONSTANT mtl_transactions_interface.created_by%TYPE   := FND_GLOBAL.user_id;
G_TRANSACTION_QUANTITY     CONSTANT PLS_INTEGER                                  := 0; 
G_TRANSACTION_TYPE_ID      CONSTANT PLS_INTEGER                                  := 80; 
G_TRANS_WORKER_APPLICATION CONSTANT VARCHAR2(30)                                 := 'INV';
G_TRANS_WORKER_EXECUTABLE  CONSTANT VARCHAR2(30)                                 := 'INCTCW';
G_ATTRIBUTE_CATEGORY       CONSTANT VARCHAR2(240)                                := 'WAC_CONVERSION';
G_SOURCE_CODE              CONSTANT VARCHAR2(10)                                 := 'EBS';
G_TRANSACTION_COST         CONSTANT PLS_INTEGER                                  := 0; 
        
----------------------------
--Declaring Global Variables
----------------------------
gn_batch_size        PLS_INTEGER;
gn_conversion_id     PLS_INTEGER;
gn_max_child_req     PLS_INTEGER;
gn_master_request_id PLS_INTEGER;
gn_record_count      PLS_INTEGER := 0;
gn_index_req_id      PLS_INTEGER := 0;
gn_batch_count       PLS_INTEGER := 0;

---------------------------------------------------
--Declaring record variable for logging bulk errors
---------------------------------------------------
gr_wac_err_rec         xx_com_exceptions_log_conv%ROWTYPE;
gr_wac_err_empty_rec   xx_com_exceptions_log_conv%ROWTYPE;

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
-- | Description :  This procedure is invoked to print in the out file  |
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
   UPDATE xx_gi_mtl_trans_intf_stg XGM
   SET    XGM.load_batch_id               = NULL
          ,XGM.wac_process_flag           = 1
          ,XGM.material_account           = NULL
          ,XGM.material_overhead_account  = NULL
          ,XGM.resource_account           = NULL
          ,XGM.outside_processing_account = NULL
          ,XGM.overhead_account           = NULL
          ,XGM.default_cost_group         = NULL
   WHERE  XGM.wac_process_flag NOT IN (0,7);

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
           END IF; -- lc_phase
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
   END IF; -- ln_summ_request_id

EXCEPTION
   WHEN EX_REP_SUMM THEN
       x_retcode := 2;
       x_errbuf  := 'Processing Summary Report for the batch could not be submitted: '||SQLERRM;
       display_log(x_errbuf);
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected Error in launch_summary_report : '||SQLERRM;
       display_log(x_errbuf);
END launch_summary_report;

-- +====================================================================+
-- | Name        :  bulk_log_error                                      |
-- | Description :  This procedure is invoked to insert errors into     |
-- |                xx_com_exceptions_log_conv                          |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
PROCEDURE bulk_log_error(
                         p_error_msg            IN VARCHAR2
                         ,p_error_code          IN VARCHAR2
                         ,p_control_id          IN VARCHAR2
                         ,p_request_id          IN VARCHAR2
                         ,p_conversion_id       IN VARCHAR2
                         ,p_package_name        IN VARCHAR2
                         ,p_procedure_name      IN VARCHAR2
                         ,p_staging_table_name  IN VARCHAR2
                         ,p_batch_id            IN VARCHAR2
                        )

IS
BEGIN
   
    ------------------------------------
    --Initializing the error record type
    ------------------------------------
    gr_wac_err_rec                     :=  gr_wac_err_empty_rec;
    ------------------------------------------------------
    --Assigning values to the columns of error record type
    ------------------------------------------------------
    gr_wac_err_rec.oracle_error_msg    :=  p_error_msg;
    gr_wac_err_rec.oracle_error_code   :=  p_error_code;      
    gr_wac_err_rec.record_control_id   :=  p_control_id;
    gr_wac_err_rec.request_id          :=  p_request_id;
    gr_wac_err_rec.converion_id        :=  p_conversion_id;
    gr_wac_err_rec.package_name        :=  p_package_name;
    gr_wac_err_rec.procedure_name      :=  p_procedure_name;
    gr_wac_err_rec.staging_table_name  :=  p_staging_table_name;
    gr_wac_err_rec.batch_id            :=  p_batch_id;

    XX_COM_CONV_ELEMENTS_PKG.bulk_add_message(gr_wac_err_rec);

EXCEPTION
   WHEN OTHERS THEN
       display_log('Error in bulk_log_error : '||SQLERRM);
    
END bulk_log_error;

-- +====================================================================+
-- | Name        :  get_conversion_id                                   |
-- | Description :  This procedure is invoked to get the conversion_id  |
-- |                ,batch_size and max_threads                         |
-- |                                                                    |
-- | Parameters  :                                                      |
-- |                                                                    |
-- | Returns     :  x_conversion_id                                     |
-- |                x_batch_size                                        |
-- |                x_max_threads                                       |
-- |                x_return_status                                     |
-- +====================================================================+

PROCEDURE get_conversion_id(
                            x_conversion_id   OUT NOCOPY NUMBER
                            ,x_batch_size     OUT NOCOPY NUMBER
                            ,x_max_threads    OUT NOCOPY NUMBER
                            ,x_return_status  OUT NOCOPY VARCHAR2
                           )
IS

BEGIN
   SELECT XCC.conversion_id
          ,XCC.batch_size
          ,XCC.max_threads
   INTO   x_conversion_id
          ,x_batch_size
          ,x_max_threads
   FROM   xx_com_conversions_conv XCC
   WHERE  XCC.conversion_code = G_CONVERSION_CODE;

   x_return_status := 'S';
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_return_status := 'E';
   WHEN OTHERS THEN
       x_return_status := SQLERRM;
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
-- |                p_max_wait_time                                       |
-- |                p_sleep                                               |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+

PROCEDURE bat_child(
                    p_request_id          IN  NUMBER
                    ,p_validate_only_flag IN  VARCHAR2
                    ,p_reset_status_flag  IN  VARCHAR2
                    ,p_max_wait_time      IN  NUMBER
                    ,p_sleep              IN  NUMBER
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
lc_launch           VARCHAR2(03) := 'N';

---------------------------------------
--Declaring Local Table Type Variables
---------------------------------------
TYPE row_id_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_row_id row_id_tbl_type; 

------------------------
-- Declaring the cursor
------------------------
CURSOR lcu_elig_rec
IS
SELECT rowid
FROM   xx_gi_mtl_trans_intf_stg XGM
WHERE  XGM.wac_process_flag = 1;

BEGIN

   OPEN lcu_elig_rec;
   LOOP
       
       FETCH lcu_elig_rec BULK COLLECT INTO lt_row_id LIMIT gn_batch_size;
       EXIT WHEN lt_row_id.COUNT = 0;
       
       ln_batch_size_count := lt_row_id.COUNT;
       gn_record_count     := gn_record_count + ln_batch_size_count;
       
       -- ----------------------------------
       -- Get the batch_id from the sequence
       -- ----------------------------------
       SELECT xx_gi_mtl_trans_intf_stg_bat_s.NEXTVAL
       INTO   ln_seq
       FROM   DUAL;
       
       FORALL i IN 1 .. lt_row_id.COUNT
       UPDATE xx_gi_mtl_trans_intf_stg XGM
       SET    XGM.load_batch_id = ln_seq
              ,XGM.wac_process_flag = 2
       WHERE  XGM.rowid = lt_row_id(i);
       
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
           
           IF ln_req_count < gn_max_child_req THEN
             
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
                                                         ,argument4   => p_max_wait_time
                                                         ,argument5   => p_sleep
                                                        );
                                                        
             IF ln_request_id = 0 THEN
               
               x_errbuf  := FND_MESSAGE.get;
               RAISE EX_SUBMIT_CHILD;
               
             ELSE
                 
                 COMMIT;
                 gn_index_req_id            := gn_index_req_id + 1;
                 gt_req_id(gn_index_req_id) := ln_request_id;
                 gn_batch_count             := gn_batch_count + 1;
                 
                 ----------------------------------------------------
                 -- Procedure to Log Conversion Control Informations.
                 ----------------------------------------------------
                 XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                                                                p_conversion_id           => gn_conversion_id
                                                                ,p_batch_id               => ln_seq
                                                                ,p_num_bus_objs_processed => ln_batch_size_count
                                                                );
                 lc_launch := 'Y';
                 EXIT;

             END IF; -- ln_request_id
           
           ELSE
           
               DBMS_LOCK.sleep(G_SLEEP);
                                    
           END IF; -- ln_req_count < gn_max_child_req
       
       END LOOP;
              
   END LOOP;
   CLOSE lcu_elig_rec;
   
   IF lc_launch = 'Y' THEN
     
     -- --------------------------
     -- Launch the summary report
     -- --------------------------
     launch_summary_report(
                           x_errbuf  => x_errbuf
                           ,x_retcode => x_retcode
                          );
                          
   END IF; -- lc_launch

EXCEPTION
  WHEN EX_SUBMIT_CHILD THEN
       x_retcode := 2;
       x_errbuf  := 'Error in submitting child requests: ' ||SQLERRM;
       display_log(x_errbuf);
  WHEN OTHERS THEN
      x_retcode := 2;
      x_errbuf  := 'Unexpected error in bat_child : ' ||SQLERRM;
      display_log(x_errbuf);
END bat_child;

-- +===================================================================+
-- | Name        :  submit_sub_requests                                |
-- | Description :  This procedure is invoked from the conv_master_main|
-- |                procedure. This would submit child requests based  |
-- |                on batch_size.                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                p_max_wait_time                                     |
-- |                p_sleep                                             |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE submit_sub_requests(
                              p_validate_only_flag  IN  VARCHAR2
                              ,p_reset_status_flag  IN  VARCHAR2
                              ,p_max_wait_time      IN  NUMBER
                              ,p_sleep              IN  NUMBER
                              ,x_errbuf             OUT NOCOPY VARCHAR2
                              ,x_retcode            OUT NOCOPY VARCHAR2
                             )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_NO_ENTRY       EXCEPTION;
EX_NO_DATA        EXCEPTION;
lc_return_status  VARCHAR2(2000);
ln_current_count  PLS_INTEGER;

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
   
   CASE lc_return_status
       WHEN 'S' THEN
            ----------------------------------------------
            -- Update Batch Id if p_reset_status_flag='Y'
            ----------------------------------------------
            IF NVL(p_reset_status_flag,'N') = 'Y' THEN
              
              update_batch_id(
                              x_errbuf   => x_errbuf
                              ,x_retcode => x_retcode
                              );
            END IF; -- p_reset_status_flag
           
            ----------------------------------------
            -- Getting the Count of Eligible records 
            ----------------------------------------

            SELECT COUNT(1)
            INTO   ln_current_count
            FROM   xx_gi_mtl_trans_intf_stg XGM
            WHERE  XGM.wac_process_flag = 1;
            
            IF (ln_current_count <> 0) THEN
            
               bat_child(
                         p_request_id          => gn_master_request_id
                         ,p_validate_only_flag => p_validate_only_flag
                         ,p_reset_status_flag  => p_reset_status_flag
                         ,p_max_wait_time      => p_max_wait_time
                         ,p_sleep              => p_sleep
                         ,x_errbuf             => x_errbuf
                         ,x_retcode            => x_retcode
                         );
               
            ELSE
                
                RAISE EX_NO_DATA;
            
            END IF; -- ln_current_count <> 0
            
            -----------------------------------------------------------------------------------------
            -- Displaying the Batch and Transaction Information in the output file of Master Program
            -----------------------------------------------------------------------------------------
            
            display_out(RPAD('=',41,'='));
            display_out(RPAD('Batch Size                 : ',30,' ')||RPAD(gn_batch_size,11,' '));
            display_out(RPAD('Total Number Of Records    : ',30,' ')||RPAD(gn_record_count,11,' '));
            display_out(RPAD('Number of Batches Launched : ',30,' ')||RPAD(gn_batch_count,11,' '));
            display_out(RPAD('=',41,'='));
         
       WHEN 'E' THEN
           
           RAISE EX_NO_ENTRY;
           
       ELSE
           
           x_retcode := 2;
           x_errbuf  := lc_return_status;
           display_log(x_errbuf);
           
   END CASE;


EXCEPTION
   WHEN EX_NO_DATA THEN
       x_errbuf := 'No Data Found in the Table '||G_STAGING_TABLE_NAME;
       display_log(x_errbuf);
       x_retcode := 1;
   WHEN EX_NO_ENTRY THEN
       x_retcode := 2;
       display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE);
   WHEN OTHERS THEN
       x_errbuf := 'Error in submit_sub_requests : '||SQLERRM;
       x_retcode := 2;
       display_log(x_errbuf);
END submit_sub_requests;

-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: GI WAC       |
-- |                Conversion Master Program.This would submit child   |
-- |                programs based on batch_size                        |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_validate_only_flag                                |
-- |                p_reset_status_flag                                 |
-- |                p_max_wait_time                                     |
-- |                p_sleep                                             |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag IN  VARCHAR2
                      ,p_reset_status_flag  IN  VARCHAR2
                      ,p_max_wait_time      IN  NUMBER
                      ,p_sleep              IN  NUMBER
                     )
IS

------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_SUB_REQ       EXCEPTION;
lc_error_message VARCHAR2(4000);
ln_return_status NUMBER;

BEGIN

   gn_master_request_id := FND_GLOBAL.CONC_REQUEST_ID;
   
   G_SLEEP := p_sleep; 

   submit_sub_requests(
                       p_validate_only_flag  => p_validate_only_flag
                       ,p_reset_status_flag  => p_reset_status_flag
                       ,p_max_wait_time      => p_max_wait_time
                       ,p_sleep              => p_sleep
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
-- | Name        :  update_batch_id                                     |
-- | Description :  This procedure is invoked to reset Batch Id to Null |
-- |                for Previously Errored Out Records                  |
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- +====================================================================+

PROCEDURE update_chd_batch_id(
                              x_errbuf    OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                              ,p_batch_id IN  NUMBER
                             )
IS
BEGIN

   -- ------------------------------
   -- To update the errored records
   -- ------------------------------
   UPDATE xx_gi_mtl_trans_intf_stg XGM
   SET    XGM.wac_process_flag            = 2
          ,XGM.material_account           = NULL
          ,XGM.material_overhead_account  = NULL
          ,XGM.resource_account           = NULL
          ,XGM.outside_processing_account = NULL
          ,XGM.overhead_account           = NULL
          ,XGM.default_cost_group         = NULL
   WHERE  XGM.wac_process_flag NOT IN (0,7)
   AND    XGM.load_batch_id = p_batch_id;

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected error in update_chd_batch_id - '||SQLERRM;
       display_log(x_errbuf);
       bulk_log_error(
                      p_error_msg            => SQLERRM
                      ,p_error_code          => SQLCODE
                      ,p_control_id          => NULL
                      ,p_request_id          => fnd_global.conc_request_id
                      ,p_conversion_id       => gn_conversion_id
                      ,p_package_name        => G_PACKAGE_NAME
                      ,p_procedure_name      => 'UPDATE_CHD_BATCH_ID'
                      ,p_staging_table_name  => G_STAGING_TABLE_NAME
                      ,p_batch_id            => p_batch_id
                      );
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;  
       
END update_chd_batch_id;

-- +=====================================================================+
-- | Name        :  derive_org_details                                   |
-- | Description :  This procedure is invoked to derive            l     |
-- |                material_account, material_overhead_account,         |
-- |                resource_acount, outside_processing_account,         |
-- |                overhead_account and cost_group_id of an organization|
-- |                                                                     |
-- | Parameters  :  p_organization_id                                    |
-- |                p_control_id                                         |
-- |                p_batch_id                                           |
-- +=====================================================================+

PROCEDURE derive_org_details(
                             p_organization_id             IN NUMBER
                             ,p_control_id                 IN NUMBER
                             ,p_batch_id                   IN NUMBER
                             ,x_errbuf                     OUT NOCOPY VARCHAR2
                             ,x_retcode                    OUT NOCOPY PLS_INTEGER
                             ,x_material_account           OUT NOCOPY PLS_INTEGER
                             ,x_material_overhead_account  OUT NOCOPY PLS_INTEGER
                             ,x_resource_account           OUT NOCOPY PLS_INTEGER
                             ,x_outside_processing_account OUT NOCOPY PLS_INTEGER
                             ,x_overhead_account           OUT NOCOPY PLS_INTEGER
                             ,x_cost_group_id              OUT NOCOPY PLS_INTEGER
                            )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
ln_material_account           PLS_INTEGER;
ln_material_overhead_account  PLS_INTEGER;
ln_resource_account           PLS_INTEGER;
ln_outside_processing_account PLS_INTEGER;
ln_overhead_account           PLS_INTEGER;
ln_cost_group_id              PLS_INTEGER;

BEGIN

   SELECT  MP.material_account
           ,MP.material_overhead_account
           ,MP.resource_account
           ,MP.outside_processing_account
           ,MP.overhead_account
           ,MP.default_cost_group_id
   INTO    ln_material_account
           ,ln_material_overhead_account
           ,ln_resource_account
           ,ln_outside_processing_account
           ,ln_overhead_account
           ,ln_cost_group_id
   FROM    mtl_parameters                MP
           ,org_organization_definitions OOD
   WHERE   OOD.organization_id = MP.organization_id
   AND     MP.organization_id  = p_organization_id
   AND     rownum = 1;
   
   x_material_account           := ln_material_account;          
   x_material_overhead_account  := ln_material_overhead_account;
   x_resource_account           := ln_resource_account;
   x_outside_processing_account := ln_outside_processing_account;
   x_overhead_account           := ln_overhead_account;
   x_cost_group_id              := ln_cost_group_id;
   
   x_retcode := 0;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_retcode := 1;
       x_errbuf := 'Could not derive material_account,material_overhead_account,resource_acount,outside_processing_account,overhead_account and cost_group_id for the organization : '||p_organization_id;
       display_log(x_errbuf);
       bulk_log_error(
                      p_error_msg           => x_errbuf
                      ,p_error_code         => NULL
                      ,p_control_id         => p_control_id
                      ,p_request_id         => fnd_global.conc_request_id
                      ,p_conversion_id      => gn_conversion_id
                      ,p_package_name       => G_PACKAGE_NAME
                      ,p_procedure_name     => 'DERIVE_ORG_DETAILS'
                      ,p_staging_table_name => G_STAGING_TABLE_NAME
                      ,p_batch_id           => p_batch_id
                     );
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;  
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf := 'Unexpected Error in derive_org_details : '||SQLERRM;
       display_log(x_errbuf);
       bulk_log_error(
                      p_error_msg           => SQLERRM
                      ,p_error_code         => SQLCODE
                      ,p_control_id         => p_control_id
                      ,p_request_id         => fnd_global.conc_request_id
                      ,p_conversion_id      => gn_conversion_id
                      ,p_package_name       => G_PACKAGE_NAME
                      ,p_procedure_name     => 'DERIVE_ORG_DETAILS'
                      ,p_staging_table_name => G_STAGING_TABLE_NAME
                      ,p_batch_id           => p_batch_id
                     );
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;  

END derive_org_details;
-- +=====================================================================+
-- | Name        :  validate_records                                     |
-- | Description :  This procedure is invoked to derive material_account,|
-- |                material_overhead_account,resource_account,          |
-- |                outside_processing_acoount,overhead_account and      |
-- |                default_cost_group.                                  |
-- |                                                                     |
-- | Parameters  :  p_batch_id                                           |
-- +=====================================================================+

PROCEDURE validate_records(
                           p_batch_id          IN  NUMBER
                           ,x_err_valid_count  OUT NOCOPY NUMBER
                           ,x_total_count      OUT NOCOPY NUMBER
                           ,x_retcode          OUT NOCOPY VARCHAR2
                           ,x_errbuf           OUT NOCOPY VARCHAR2
                          )
IS

------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_NO_DATA                    EXCEPTION;
lc_msg                        VARCHAR2(2000);
ln_material_account           PLS_INTEGER;
ln_material_overhead_account  PLS_INTEGER;
ln_resource_account           PLS_INTEGER;
ln_outside_processing_account PLS_INTEGER;
ln_overhead_account           PLS_INTEGER;
ln_cost_group_id              PLS_INTEGER;
ln_retcode                    PLS_INTEGER;
ln_err_valid_count            PLS_INTEGER := 0;
ln_rec_count                  PLS_INTEGER := 0;

--------------------------------
--Declaring table type variables
--------------------------------
TYPE procs_flg_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.wac_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_procs_flg procs_flg_tbl_type;

TYPE mat_acc_tbl_type IS TABLE OF mtl_parameters.material_account%TYPE
INDEX BY BINARY_INTEGER;
lt_mat_acc mat_acc_tbl_type;

TYPE mat_oh_acc_tbl_type IS TABLE OF mtl_parameters.material_overhead_account%TYPE
INDEX BY BINARY_INTEGER;
lt_mat_oh_acc mat_oh_acc_tbl_type;

TYPE res_acc_tbl_type IS TABLE OF mtl_parameters.resource_account%TYPE
INDEX BY BINARY_INTEGER;
lt_res_acc res_acc_tbl_type;

TYPE out_pro_acc_tbl_type IS TABLE OF mtl_parameters.outside_processing_account%TYPE
INDEX BY BINARY_INTEGER;
lt_out_pro_acc out_pro_acc_tbl_type;

TYPE ovh_acc_tbl_type IS TABLE OF mtl_parameters.overhead_account%TYPE
INDEX BY BINARY_INTEGER;
lt_ovh_acc ovh_acc_tbl_type;

TYPE cst_grp_tbl_type IS TABLE OF mtl_parameters.default_cost_group_id%TYPE
INDEX BY BINARY_INTEGER;
lt_cst_grp cst_grp_tbl_type;

TYPE row_id_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_row_id row_id_tbl_type;

---------------------------------------
--Cursor to get the Transaction Details
---------------------------------------   
CURSOR lcu_valid_wac_records
IS
SELECT XGM.rowid,XGM.* 
FROM   xx_gi_mtl_trans_intf_stg XGM
WHERE  XGM.load_batch_id = p_batch_id
AND    XGM.wac_process_flag = 2;

TYPE wac_rec_tbl_type IS TABLE OF lcu_valid_wac_records%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_wac_rec wac_rec_tbl_type;


BEGIN

   OPEN  lcu_valid_wac_records;
   FETCH lcu_valid_wac_records BULK COLLECT INTO lt_wac_rec;
   CLOSE lcu_valid_wac_records;
   
   IF lt_wac_rec.COUNT <> 0 THEN
     
     ln_rec_count := lt_wac_rec.COUNT;
     
     FOR i IN 1 .. lt_wac_rec.COUNT
     LOOP
          
          lt_mat_acc(i)     := NULL;
          lt_mat_oh_acc(i)  := NULL;
          lt_res_acc(i)     := NULL;
          lt_out_pro_acc(i) := NULL;
          lt_ovh_acc(i)     := NULL;
          lt_cst_grp(i)     := NULL;
          lt_row_id(i)      := lt_wac_rec(i).rowid;
          lt_procs_flg(i)   := lt_wac_rec(i).wac_process_flag;
          
          derive_org_details(
                             p_organization_id             => lt_wac_rec(i).organization_id
                             ,p_control_id                 => lt_wac_rec(i).control_id
                             ,p_batch_id                   => p_batch_id
                             ,x_errbuf                     => lc_msg
                             ,x_retcode                    => ln_retcode
                             ,x_material_account           => ln_material_account
                             ,x_material_overhead_account  => ln_material_overhead_account
                             ,x_resource_account           => ln_resource_account
                             ,x_outside_processing_account => ln_outside_processing_account
                             ,x_overhead_account           => ln_overhead_account
                             ,x_cost_group_id              => ln_cost_group_id
                            );
            
            CASE ln_retcode
                WHEN 0 THEN
                    lt_mat_acc(i)       := ln_material_account;
                    lt_mat_oh_acc(i)    := ln_material_overhead_account;
                    lt_res_acc(i)       := ln_resource_account;
                    lt_out_pro_acc(i)   := ln_outside_processing_account;
                    lt_ovh_acc(i)       := ln_overhead_account;
                    lt_cst_grp(i)       := ln_cost_group_id;
                    lt_procs_flg(i)     := 4;
                                        
                ELSE
                    lt_procs_flg(i)    := 3;
                    ln_err_valid_count := ln_err_valid_count + 1;
                    
            END CASE;
          
     END LOOP;
      
      x_err_valid_count  := ln_err_valid_count;
      x_total_count      := ln_rec_count;
      
      FORALL i IN 1 .. lt_wac_rec.COUNT
      UPDATE xx_gi_mtl_trans_intf_stg XGM
      SET    XGM.wac_process_flag            = lt_procs_flg(i)
             ,XGM.material_account           = lt_mat_acc(i)
             ,XGM.material_overhead_account  = lt_mat_oh_acc(i)
             ,XGM.resource_account           = lt_res_acc(i)
             ,XGM.outside_processing_account = lt_out_pro_acc(i)
             ,XGM.overhead_account           = lt_ovh_acc(i)
             ,XGM.default_cost_group         = lt_cst_grp(i)
      WHERE  XGM.rowid = lt_row_id(i);
      
      COMMIT;
      
      

   ELSE
       RAISE EX_NO_DATA;
   END IF; -- lt_wac_rec.COUNT

EXCEPTION
   WHEN EX_NO_DATA THEN
       x_retcode := 1;
       x_errbuf  := 'No data found in the staging table '||G_STAGING_TABLE_NAME||' with batch_id - '||p_batch_id; 
       display_log(x_errbuf);
       --Adding error message to stack     
       bulk_log_error(
                      p_error_msg           =>  x_errbuf
                      ,p_error_code         =>  NULL
                      ,p_control_id         =>  NULL
                      ,p_request_id         =>  fnd_global.conc_request_id
                      ,p_conversion_id      =>  gn_conversion_id
                      ,p_package_name       =>  G_PACKAGE_NAME
                      ,p_procedure_name     =>  'VALIDATE_RECORDS'
                      ,p_staging_table_name =>  G_STAGING_TABLE_NAME
                      ,p_batch_id           =>  p_batch_id
                     );
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;  

END validate_records;

-- +====================================================================+
-- | Name        :  launch_exception_report                             |
-- | Description :  This procedure is invoked to Launch Exception       |
-- |                Report for that batch                               |
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE launch_exception_report(
                                  p_batch_id IN          NUMBER
                                  ,x_errbuf   OUT NOCOPY VARCHAR2
                                  ,x_retcode  OUT NOCOPY VARCHAR2
                                 )
IS
------------------------------------------
--Declaring local variables and Exceptions
------------------------------------------
EX_REP_EXC              EXCEPTION;
ln_excep_request_id     PLS_INTEGER;
ln_conc_request_id      PLS_INTEGER := FND_GLOBAL.conc_request_id;

BEGIN
    ------------------------------------------------
    --Submitting the Exception Report for each batch
    ------------------------------------------------
    ln_excep_request_id := FND_REQUEST.submit_request(
                                                      application  => G_COMN_APPLICATION
                                                      ,program     => G_EXCEP_PROGRAM
                                                      ,sub_request => FALSE            
                                                      ,argument1   => G_CONVERSION_CODE 
                                                      ,argument2   => NULL              
                                                      ,argument3   => ln_conc_request_id
                                                      ,argument4   => p_batch_id        
                                                     );
    IF  ln_excep_request_id = 0 THEN
        x_errbuf  := FND_MESSAGE.GET;
        RAISE EX_REP_EXC;
    ELSE
        COMMIT;
    END IF; -- ln_excep_request_id
EXCEPTION
   WHEN EX_REP_EXC THEN
       x_retcode := 2;
       x_errbuf  := 'Exception Summary Report for the batch '||p_batch_id||' could not be submitted: ' || x_errbuf;
       display_log(x_errbuf);
       bulk_log_error(p_error_msg           => x_errbuf
                      ,p_error_code         => NULL
                      ,p_control_id         => NULL
                      ,p_request_id         => fnd_global.conc_request_id
                      ,p_conversion_id      => gn_conversion_id
                      ,p_package_name       => G_PACKAGE_NAME
                      ,p_procedure_name     => 'LAUNCH_EXCEPTION_REPORT'
                      ,p_staging_table_name => G_STAGING_TABLE_NAME
                      ,p_batch_id           => p_batch_id
                     );
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
END launch_exception_report;

-- +====================================================================+
-- | Name        :  process_records                                     |
-- |                                                                    |
-- | Description :  This procedure is invoked to process the records    |
-- |                to the EBS table by calling the API with            |
-- |                wac_process_flag in 4, 5 or 6 for a particular batch|
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- |                                                                    |
-- +====================================================================+
PROCEDURE process_records(
                          p_batch_id        IN  NUMBER
                          ,x_succ_pro_count OUT NOCOPY NUMBER
                          ,x_err_pro_count  OUT NOCOPY NUMBER
                          ,x_retcode        OUT NOCOPY VARCHAR2
                          ,x_errbuf         OUT NOCOPY VARCHAR2
                         )
IS

------------------------------------------
--Declaring local variables and Exceptions
------------------------------------------
EX_TRANS_WORK                  EXCEPTION;
ln_trans_work_request_id       fnd_concurrent_requests.request_id%TYPE;
lc_phase                       fnd_concurrent_requests.phase_code%TYPE;
ln_load_batch_id               PLS_INTEGER;
ln_request_count               PLS_INTEGER :=0;
ln_count                       PLS_INTEGER := 0;
ln_success_count               PLS_INTEGER := 0;
ln_error_count                 PLS_INTEGER := 0;

----------------------------------
-- Declaring Table Type Variables
----------------------------------
TYPE wac_rec_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_wac_rec wac_rec_tbl_type; 

TYPE cntrl_id_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.control_id%TYPE
INDEX BY BINARY_INTEGER;
lt_cntrl_id cntrl_id_tbl_type;  

TYPE inv_item_id_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.inventory_item_id%TYPE
INDEX BY BINARY_INTEGER;
lt_inv_item_id inv_item_id_tbl_type;  

TYPE org_id_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.organization_id%TYPE
INDEX BY BINARY_INTEGER;
lt_org_id org_id_tbl_type;  

TYPE trans_uom_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.transaction_uom%TYPE
INDEX BY BINARY_INTEGER;
lt_trans_uom trans_uom_tbl_type;

TYPE trans_ref_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.transaction_reference%TYPE
INDEX BY BINARY_INTEGER;
lt_trans_ref trans_ref_tbl_type;

TYPE avg_cost_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.itemloc_average_cost%TYPE
INDEX BY BINARY_INTEGER;
lt_avg_cost avg_cost_tbl_type;

TYPE mtl_acc_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.material_account%TYPE
INDEX BY BINARY_INTEGER;
lt_mtl_acc mtl_acc_tbl_type;

TYPE mtl_ovh_acc_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.material_overhead_account%TYPE
INDEX BY BINARY_INTEGER;
lt_mtl_ovh_acc mtl_ovh_acc_tbl_type;

TYPE rsc_acc_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.resource_account%TYPE
INDEX BY BINARY_INTEGER;
lt_rsc_acc rsc_acc_tbl_type;

TYPE out_proc_acc_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.outside_processing_account%TYPE
INDEX BY BINARY_INTEGER;
lt_out_proc_acc out_proc_acc_tbl_type;

TYPE ovhd_acc_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.overhead_account%TYPE
INDEX BY BINARY_INTEGER;
lt_ovhd_acc ovhd_acc_tbl_type;

TYPE cst_grp_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.default_cost_group%TYPE
INDEX BY BINARY_INTEGER;
lt_cst_grp cst_grp_tbl_type;

TYPE trans_work_request_id_tbl_type IS TABLE OF mtl_transactions_interface.request_id%TYPE
INDEX BY BINARY_INTEGER;
lt_trans_work_request_id trans_work_request_id_tbl_type;

TYPE error_message_tbl_type IS TABLE OF xx_gi_mtl_trans_intf_stg.error_message%TYPE
INDEX BY BINARY_INTEGER;
lt_error_message error_message_tbl_type;

TYPE trans_intf_tbl_type IS TABLE OF mtl_transactions_interface.transaction_interface_id%TYPE
INDEX BY BINARY_INTEGER;
lt_trans_intf_id trans_intf_tbl_type;

-------------------------------------------------------------------------
-- Cursor to fetch Successfully validated records for a particular batch
-------------------------------------------------------------------------
CURSOR lcu_process_wac_records
IS
SELECT *
FROM   xx_gi_mtl_trans_intf_stg XGM
WHERE  XGM.load_batch_id    = p_batch_id
AND    XGM.wac_process_flag = 4;

------------------------------------------------
--Cursor to fetch errored transaction records
------------------------------------------------
CURSOR lcu_errored_records
IS
SELECT XGMTI.control_id, 
       MTI.error_explanation
FROM   xx_gi_mtl_trans_intf_stg XGMTI
       ,mtl_transactions_interface MTI
       ,fnd_concurrent_requests FCS
WHERE  XGMTI.control_id = MTI.source_line_id
AND    FCS.parent_request_id = fnd_global.conc_request_id 
AND    FCS. request_id = MTI.request_id
AND    XGMTI.load_batch_id   = p_batch_id
AND    XGMTI.wac_process_flag = 4;

BEGIN
   
   --------------------------------------------------------------
   --Fetching Successful records to insert 500 records at a time
   --------------------------------------------------------------
   
   OPEN lcu_process_wac_records;
   LOOP
      
         FETCH lcu_process_wac_records BULK COLLECT INTO lt_wac_rec LIMIT G_LIMIT_SIZE;
         EXIT WHEN lt_wac_rec.count = 0;  
         
         IF lt_wac_rec.COUNT<>0 THEN 
           BEGIN
               
               ln_count := ln_count + lt_wac_rec.COUNT;
               
               FOR i IN 1 .. lt_wac_rec.COUNT
               LOOP
                   
                   lt_cntrl_id(i)      := lt_wac_rec(i).control_id;
                   lt_inv_item_id(i)   := lt_wac_rec(i).inventory_item_id;
                   lt_org_id(i)        := lt_wac_rec(i).organization_id;
                   lt_trans_uom(i)     := lt_wac_rec(i).transaction_uom;
                   lt_trans_ref(i)     := lt_wac_rec(i).transaction_reference;
                   lt_avg_cost(i)      := lt_wac_rec(i).itemloc_average_cost;
                   lt_mtl_acc(i)       := lt_wac_rec(i).material_account;
                   lt_mtl_ovh_acc(i)   := lt_wac_rec(i).material_overhead_account;
                   lt_rsc_acc(i)       := lt_wac_rec(i).resource_account;
                   lt_out_proc_acc(i)  := lt_wac_rec(i).outside_processing_account;
                   lt_ovhd_acc(i)      := lt_wac_rec(i).overhead_account;
                   lt_cst_grp(i)       := lt_wac_rec(i).default_cost_group;
                   
               END LOOP;
           
               --------------------------------------------------------------- 
               --Deriving batch id to invoke transaction worker in sub batches
               ---------------------------------------------------------------
               SELECT xx_gi_trans_worker_bat_s.NEXTVAL     
               INTO   ln_load_batch_id
               FROM   dual;
               
               -------------------------------------------------------------
               --Bulk Insert records for each sub batch into interface table
               -------------------------------------------------------------   
               FORALL i in 1 .. lt_wac_rec.COUNT
               INSERT INTO MTL_TRANSACTIONS_INTERFACE(
                                                      source_code
                                                      ,source_line_id
                                                      ,source_header_id
                                                      ,transaction_header_id
                                                      ,process_flag
                                                      ,transaction_mode
                                                      ,lock_flag
                                                      ,last_update_date
                                                      ,last_updated_by
                                                      ,creation_date
                                                      ,created_by
                                                      ,last_update_login 
                                                      ,inventory_item_id
                                                      ,organization_id 
                                                      ,transaction_quantity 
                                                      ,transaction_uom
                                                      ,transaction_type_id
                                                      ,transaction_date
                                                      ,transaction_reference
                                                      ,transaction_cost 
                                                      ,new_average_cost 
                                                      ,attribute_category 
                                                      ,material_account 
                                                      ,material_overhead_account 
                                                      ,resource_account 
                                                      ,outside_processing_account 
                                                      ,overhead_account 
                                                      ,cost_group_id 
                                                     )
                                               VALUES(
                                                      G_SOURCE_CODE
                                                      ,lt_cntrl_id(i)
                                                      ,lt_cntrl_id(i)
                                                      ,ln_load_batch_id
                                                      ,G_PROCESS_FLAG  
                                                      ,G_TRANSACTION_MODE
                                                      ,G_LOCK_FLAG
                                                      ,SYSDATE
                                                      ,G_USER_ID
                                                      ,SYSDATE
                                                      ,G_USER_ID
                                                      ,G_USER_ID
                                                      ,lt_inv_item_id(i)   
                                                      ,lt_org_id(i)    
                                                      ,G_TRANSACTION_QUANTITY
                                                      ,lt_trans_uom(i)
                                                      ,G_TRANSACTION_TYPE_ID
                                                      ,SYSDATE
                                                      ,lt_trans_ref(i)
                                                      ,G_TRANSACTION_COST
                                                      ,lt_avg_cost(i) 
                                                      ,G_ATTRIBUTE_CATEGORY
                                                      ,lt_mtl_acc(i)
                                                      ,lt_mtl_ovh_acc(i)
                                                      ,lt_rsc_acc(i)
                                                      ,lt_out_proc_acc(i)
                                                      ,lt_ovhd_acc(i)
                                                      ,lt_cst_grp(i)
                                                     );  
               
               COMMIT;
                              
               ln_trans_work_request_id:= fnd_request.submit_request(
                                                                     application  => G_TRANS_WORKER_APPLICATION
                                                                     ,program     => G_TRANS_WORKER_EXECUTABLE
                                                                     ,sub_request => FALSE
                                                                     ,argument1   => ln_load_batch_id
                                                                     ,argument2   => 1 --Interface Table
                                                                     ,argument3   => NULL
                                                                     ,argument4   => NULL
                                                                     );
               display_log('Transaction Worker Submitted for Sub Batch '||ln_load_batch_id||' with request id '||ln_trans_work_request_id);
               
               IF ln_trans_work_request_id = 0 THEN
                 RAISE EX_TRANS_WORK;
               ELSE
                   COMMIT;
                   ln_request_count := ln_request_count + 1;
                   lt_trans_work_request_id(ln_request_count):=ln_trans_work_request_id;
               END IF; -- ln_trans_work_request_id
               
               
           
           EXCEPTION
              WHEN EX_TRANS_WORK THEN
                  x_errbuf  := 'Error while submitting transaction Worker - '||SQLERRM;
                  x_retcode := 2;
                  display_log(x_errbuf);
                  bulk_log_error(
                                 p_error_msg           => x_errbuf
                                 ,p_error_code         => SQLCODE
                                 ,p_control_id         => NULL
                                 ,p_request_id         => fnd_global.conc_request_id
                                 ,p_conversion_id       => gn_conversion_id
                                 ,p_package_name       => G_PACKAGE_NAME
                                 ,p_procedure_name     => 'PROCESS_RECORDS'
                                 ,p_staging_table_name => G_STAGING_TABLE_NAME
                                 ,p_batch_id           => p_batch_id
                                );                        
                  XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
              WHEN OTHERS THEN
                  x_errbuf  := 'Unexpected error while inserting records in interface table and invoking transaction worker - '||SQLERRM;
                  x_retcode := 2;
                  display_log(x_errbuf);
                  bulk_log_error(
                                 p_error_msg           => x_errbuf
                                 ,p_error_code         => SQLCODE
                                 ,p_control_id         => NULL
                                 ,p_request_id         => fnd_global.conc_request_id
                                 ,p_conversion_id      => gn_conversion_id
                                 ,p_package_name       => G_PACKAGE_NAME
                                 ,p_procedure_name     => 'PROCESS_RECORDS'
                                 ,p_staging_table_name => G_STAGING_TABLE_NAME
                                 ,p_batch_id           => p_batch_id
                                );  
                  XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;                
           END;
           
         END IF; -- lt_wac_rec.COUNT
   END LOOP;
   CLOSE lcu_process_wac_records;
   
   --------------------------------------
   -- Deleting the control_id table type
   --------------------------------------
   lt_cntrl_id.DELETE;
   
   IF ln_count <> 0 THEN
     
     -------------------------------------------------------------------
     --Wait till all the Transaction Workers are complete for this Batch 
     ------------------------------------------------------------------- 
     
     FOR i IN lt_trans_work_request_id.FIRST .. lt_trans_work_request_id.LAST
     LOOP
         LOOP
             SELECT FCR.phase_code
             INTO   lc_phase
             FROM   FND_CONCURRENT_REQUESTS FCR
             WHERE  FCR.request_id = lt_trans_work_request_id(i);
             
             IF lc_phase = 'C' THEN
               EXIT;
             ELSE
                 DBMS_LOCK.SLEEP(G_SLEEP);
             END IF; -- lc_phase
         END LOOP;
     END LOOP;
     
     --------------------------------------------------
     -- Logging Errors for Errored Transaction Records 
     --------------------------------------------------
     OPEN  lcu_errored_records;
     FETCH lcu_errored_records BULK COLLECT INTO lt_cntrl_id, lt_error_message;
     CLOSE lcu_errored_records;
     
     IF lt_cntrl_id.COUNT > 0 THEN
     
       ln_error_count := lt_cntrl_id.COUNT;
       
       FOR i IN 1 .. lt_cntrl_id.COUNT
       LOOP
           bulk_log_error(
                          p_error_msg             =>  lt_error_message(i)
                          ,p_error_code           =>  NULL
                          ,p_control_id           =>  lt_cntrl_id(i)
                          ,p_request_id           =>  fnd_global.conc_request_id
                          ,p_conversion_id        =>  gn_conversion_id
                          ,p_package_name         =>  G_PACKAGE_NAME
                          ,p_procedure_name       =>  'PROCESS_RECORDS'
                          ,p_staging_table_name   =>  G_STAGING_TABLE_NAME
                          ,p_batch_id             =>  p_batch_id
                         );
       END LOOP;
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
       
       FORALL i IN 1 .. lt_cntrl_id.COUNT
       UPDATE xx_gi_mtl_trans_intf_stg  XGMTIS
       SET    XGMTIS.wac_process_flag = 6
              ,XGMTIS.error_message = lt_error_message(i)
       WHERE   XGMTIS.control_id = lt_cntrl_id(i);                 
       
       COMMIT;
         
     END IF; -- lt_cntrl_id.COUNT
     
     ---------------------------------------------
     -- Update the Successful Transaction Records
     ---------------------------------------------
     UPDATE xx_gi_mtl_trans_intf_stg XGMTI
     SET    XGMTI.wac_process_flag = 7
     WHERE  XGMTI.wac_process_flag = 4
     AND    XGMTI.load_batch_id    = p_batch_id;
     
     ln_success_count := SQL%ROWCOUNT;
     
     COMMIT;
     
   END IF; -- ln_count
   
   x_succ_pro_count := ln_success_count;
   x_err_pro_count  := ln_error_count;

EXCEPTION
   WHEN OTHERS THEN
       x_errbuf  := 'Unexpected error in process_records - '||SQLERRM;
       x_retcode := 2;
       display_log(x_errbuf);
       bulk_log_error(
                      p_error_msg           =>  x_errbuf
                      ,p_error_code         =>  SQLCODE
                      ,p_control_id         =>  NULL
                      ,p_request_id         =>  fnd_global.conc_request_id
                      ,p_conversion_id      =>  gn_conversion_id
                      ,p_package_name       =>  G_PACKAGE_NAME
                      ,p_procedure_name     =>  'PROCESS_RECORDS'
                      ,p_staging_table_name =>  G_STAGING_TABLE_NAME
                      ,p_batch_id           =>  p_batch_id
                      );
       XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;              

END process_records;

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
                                 p_conversion_id      IN         NUMBER
                                ,p_batch_id           IN         NUMBER
                                ,x_master_request_id  OUT NOCOPY NUMBER
                               )
IS
BEGIN
    -------------------------------
    --Getting the master Request Id
    -------------------------------
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

-- +===================================================================+
-- | Name        :  child_main                                         |
-- | Description :  This procedure is invoked from the OD: GI WAC      |
-- |                Conversion Child Program based on input            |
-- |                parameters.                                        |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                p_batch_id                                         |
-- |                p_max_wait_time                                    |
-- |                p_sleep                                            |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE child_main(
                     x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag IN  VARCHAR2
                     ,p_reset_status_flag  IN  VARCHAR2                   
                     ,p_batch_id           IN  NUMBER
                     ,p_max_wait_time      IN  NUMBER
                     ,p_sleep              IN  NUMBER
                    )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_NO_ENTRY         EXCEPTION;
lc_return_status    VARCHAR2(2000);
ln_err_vald_count   PLS_INTEGER := 0;
ln_total_count      PLS_INTEGER := 0;
ln_succ_pro_count   PLS_INTEGER := 0;
ln_err_pro_count    PLS_INTEGER := 0;
ln_request_id       PLS_INTEGER;

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
   
   G_SLEEP := p_sleep;
   
   XX_COM_CONV_ELEMENTS_PKG.bulk_table_initialize; 
   
   CASE lc_return_status
       WHEN 'S' THEN
           ----------------------------------------------
           -- Update Batch Id if p_reset_status_flag='Y'
           ----------------------------------------------
           IF NVL(p_reset_status_flag,'N') = 'Y' THEN
             update_chd_batch_id(
                                 x_errbuf    => x_errbuf
                                 ,x_retcode  => x_retcode
                                 ,p_batch_id => p_batch_id
                                );
           END IF; -- p_reset_status_flag
           
           -- -------------------------------------------------------
           -- Validate the records for a particular batch
           -- ---------------------------------------------------------
           
           validate_records(
                            p_batch_id          => p_batch_id
                            ,x_err_valid_count  => ln_err_vald_count
                            ,x_total_count      => ln_total_count
                            ,x_retcode          => x_retcode
                            ,x_errbuf           => x_errbuf
                           );
                           
                      
           IF NVL(p_validate_only_flag,'N') <> 'Y' THEN
             
             process_records(
                             p_batch_id        => p_batch_id
                             ,x_succ_pro_count => ln_succ_pro_count
                             ,x_err_pro_count  => ln_err_pro_count
                             ,x_retcode        => x_retcode
                             ,x_errbuf         => x_errbuf
                            );
           
           END IF; -- p_validate_only_flag
           
           ---------------------------------------------------------------------------------------------
           -- Displaying the Transaction Information in the output file of Child Program for that batch
           ---------------------------------------------------------------------------------------------
           display_out(RPAD('=',55,'='));
           display_out(RPAD('Total Number of WAC Records             : ',44,' ')||RPAD(ln_total_count,11,' '));
           display_out(RPAD('Number Of WAC Records Processed         : ',44,' ')||RPAD(ln_succ_pro_count,11,' '));
           display_out(RPAD('Number Of WAC Records Failed Processing : ',44,' ')||RPAD(ln_err_pro_count,11,' '));
           display_out(RPAD('Number of WAC Records Failed Validation : ',44,' ')||RPAD(ln_err_vald_count,11,' '));
           display_out(RPAD('=',55,'='));
           
           
           -------------------------------------------------------------
           --Getting the Master Request Id to update Control Information
           -------------------------------------------------------------
           get_master_request_id(
                                 p_conversion_id      => gn_conversion_id
                                 ,p_batch_id          => p_batch_id
                                 ,x_master_request_id => ln_request_id
                                );
                                
           IF ln_request_id IS NOT NULL THEN
             ----------------------------------
             --Updating the Control Information
             ----------------------------------
             XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                                                            p_conc_mst_req_id              => ln_request_id --APPS.FND_GLOBAL.CONC_REQUEST_ID
                                                            ,p_batch_id                    => p_batch_id
                                                            ,p_conversion_id               => gn_conversion_id
                                                            ,p_num_bus_objs_failed_valid   => ln_err_vald_count
                                                            ,p_num_bus_objs_failed_process => ln_err_pro_count
                                                            ,p_num_bus_objs_succ_process   => ln_succ_pro_count
                                                           );
           END IF; -- ln_request_id

           -------------------------------------------------
           -- Launch the Exception Log Report for this batch
           -------------------------------------------------
                           
           launch_exception_report(
                                   p_batch_id => p_batch_id
                                   ,x_errbuf  => x_errbuf
                                   ,x_retcode => x_retcode
                                  );
       
       WHEN 'E' THEN
           
           RAISE EX_NO_ENTRY;
           
       ELSE
           
           x_retcode := 2;
           x_errbuf  := lc_return_status;
           display_log(x_errbuf);
           
   END CASE;
   
EXCEPTION
   WHEN EX_NO_ENTRY THEN
       x_retcode := 2;
       display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE);
   WHEN OTHERS THEN
       x_errbuf := 'Unexpected error in child_main : '||SQLERRM;
       x_retcode := 2;
       display_log(x_errbuf);
END child_main;


END XX_GI_WAC_LOAD_CONV_PKG;
/
SHOW ERRORS
EXIT;
