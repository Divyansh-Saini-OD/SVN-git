SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE BODY      XX_GI_RCV_CONV_PKG_BK

-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- +=============================================================================+
-- | Name        :  XX_GI_RCV_CONV_PKG_BK.pkb                                    |
-- | Description :  Historical receipts Package body                             |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |  Version      Date         Author             Remarks                       |
-- | =========  =========== =============== ==================================== |
-- |    1.0     21-Dec-2007   Rama Dwibhashyam   Baselined                       |
-- +=============================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------
G_USER_ID                   CONSTANT mtl_transactions_interface.created_by%TYPE         :=  FND_GLOBAL.user_id;
G_TRANSACTION_TYPE          CONSTANT mtl_transaction_types.transaction_type_name%TYPE   :=  'OD Conv History Receipts';
G_RTV_TRAN_TYPE             CONSTANT mtl_transaction_types.transaction_type_name%TYPE   :=  'OD RTV Return Receipts';
G_SUBINVENTORY_CODE         CONSTANT VARCHAR2(10)                                       :=  'STOCK';
G_CONVERSION_CODE           CONSTANT xx_com_conversions_conv.conversion_code%TYPE       :=  'C0108_Receipts';
G_PROCESS_FLAG              CONSTANT PLS_INTEGER                                        :=  1;
G_VALIDATION_REQUIRED       CONSTANT PLS_INTEGER                                        :=  1;
G_TRANSACTION_MODE          CONSTANT PLS_INTEGER                                        :=  2;--Concurrent
G_LIMIT_SIZE                CONSTANT PLS_INTEGER                                        :=  500;
G_COMM_APPLICATION          CONSTANT VARCHAR2(10)                                       :=  'XXCOMN';
G_SUMM_PROGRAM              CONSTANT VARCHAR2(50)                                       :=  'XXCOMCONVSUMMREP';
G_EXCEP_PROGRAM             CONSTANT VARCHAR2(50)                                       :=  'XXCOMCONVEXPREP';
G_PACKAGE_NAME              CONSTANT VARCHAR2(50)                                       :=  'XX_GI_RCV_CONV_PKG';
G_STAGING_TBL               CONSTANT VARCHAR2(50)                                       :=  'XX_GI_RCV_STG';
G_SUCCESS                   CONSTANT VARCHAR2(1)                                        :=  FND_API.G_TRUE;
G_FAILURE                   CONSTANT VARCHAR2(1)                                        :=  FND_API.G_FALSE;
G_SIV_SOURCE                CONSTANT VARCHAR2(50)                                       :=  'OD Legacy SIV Intransit';
G_WIV_SOURCE                CONSTANT VARCHAR2(50)                                       :=  'OD Legacy WIV Intransit';
G_RCC_SOURCE                CONSTANT VARCHAR2(50)                                       :=  'OD Legacy RCC Intransit';

-------------------------------------------------
--Declaring Global Exception and Global Variables
-------------------------------------------------
EX_HANDLE_SUB_OTHERS        EXCEPTION;
gn_batch_size               PLS_INTEGER                                                 :=  5000;
gn_batch_count              PLS_INTEGER                                                 :=  0;
gn_record_count             PLS_INTEGER                                                 :=  0;
gn_index_request_id         PLS_INTEGER                                                 :=  0;
gn_max_child_req            PLS_INTEGER ;
gn_conversion_id            xx_com_exceptions_log_conv.converion_id%TYPE;
gn_request_id               fnd_concurrent_requests.request_id%TYPE;
gc_sqlerrm                  VARCHAR2(5000);
gc_sqlcode                  VARCHAR2(20);
gn_debug_flag               VARCHAR2(1);
gn_max_wait_time            PLS_INTEGER;
gn_sleep                    PLS_INTEGER;
gn_child_request_id         fnd_concurrent_requests.request_id%TYPE;

---------------------------------------------------
--Declaring record variable for logging bulk errors
---------------------------------------------------
gr_trans_err_rec         xx_com_exceptions_log_conv%ROWTYPE;
gr_trans_err_empty_rec   xx_com_exceptions_log_conv%ROWTYPE;

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
-- | Parameters  :  p_message                                           |
-- +====================================================================+
PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
    IF  NVL(gn_debug_flag,'N') = 'Y' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
    END IF;
END;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the out file  |
-- |                                                                    |
-- | Parameters  :  p_message                                           |
-- +====================================================================+
PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END;

-- +====================================================================+
-- | Name        :  bulk_log_error                                      |
-- | Description :  This procedure is invoked to insert errors into     |
-- |                xx_com_exceptions_log_conv                          |
-- |                                                                    |
-- | Parameters  :  p_error_msg                                         |
-- |                p_error_code                                        |
-- |                p_control_id                                        |
-- |                p_request_id                                        |
-- |                p_converion_id                                      |
-- |                p_package_name                                      |
-- |                p_procedure_name                                    |
-- |                p_staging_table_name                                |
-- |                p_batch_id                                          |
-- |                p_staging_column_name                               |
-- |                p_staging_column_value                              |
-- +====================================================================+
PROCEDURE bulk_log_error(
                          p_error_msg             IN VARCHAR2
                         ,p_error_code            IN VARCHAR2
                         ,p_control_id            IN NUMBER
                         ,p_request_id            IN NUMBER
                         ,p_converion_id          IN NUMBER
                         ,p_package_name          IN VARCHAR2
                         ,p_procedure_name        IN VARCHAR2
                         ,p_staging_table_name    IN VARCHAR2
                         ,p_batch_id              IN NUMBER
                         ,p_staging_column_name   IN VARCHAR2
                         ,p_staging_column_value  IN VARCHAR2
                       )
IS
BEGIN
    ------------------------------------
    --Initializing the error record type
    ------------------------------------
    gr_trans_err_rec                           :=  gr_trans_err_empty_rec;
    ------------------------------------------------------
    --Assigning values to the columns of error record type
    ------------------------------------------------------
    gr_trans_err_rec.oracle_error_msg          :=  p_error_msg;
    gr_trans_err_rec.oracle_error_code         :=  p_error_code;
    gr_trans_err_rec.record_control_id         :=  p_control_id;
    gr_trans_err_rec.request_id                :=  p_request_id;
    gr_trans_err_rec.converion_id              :=  p_converion_id;
    gr_trans_err_rec.package_name              :=  p_package_name;
    gr_trans_err_rec.procedure_name            :=  p_procedure_name;
    gr_trans_err_rec.staging_table_name        :=  p_staging_table_name;
    gr_trans_err_rec.batch_id                  :=  p_batch_id;
    gr_trans_err_rec.staging_column_name       :=  p_staging_column_name;
    gr_trans_err_rec.staging_column_value      :=  p_staging_column_value;

    XX_COM_CONV_ELEMENTS_PKG.bulk_add_message(gr_trans_err_rec);
END bulk_log_error;

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
-- |                x_errbuf                                              |
-- |                x_retcode                                             |
-- +======================================================================+
PROCEDURE bat_child(
                      p_request_id          IN         NUMBER
                     ,p_validate_only_flag  IN         VARCHAR2
                     ,p_reset_status_flag   IN         VARCHAR2
                     ,p_conversion_type     IN         VARCHAR2
                     ,x_time                OUT NOCOPY DATE
                     ,x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode             OUT NOCOPY VARCHAR2
                   )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_SUBMIT_CHILD     EXCEPTION;

ln_batch_size_count PLS_INTEGER;
ln_seq              PLS_INTEGER;
ln_req_count        PLS_INTEGER;
ln_master_count     PLS_INTEGER;
ln_conc_request_id  FND_CONCURRENT_REQUESTS.request_id%TYPE;

BEGIN
    SELECT XX_GI_BATCH_INFO_ID_S1.NEXTVAL 
    INTO   ln_seq
    FROM   DUAL;
    -------------------------------------------------------------
    --Updating Staging table with load batch id and process flags
    -------------------------------------------------------------
    UPDATE xx_gi_rcv_stg XGRS
    SET    XGRS.batch_id = ln_seq
          ,XGRS.process_flag = 2
    WHERE  XGRS.batch_id IS NULL
    AND    XGRS.process_flag = 1
    AND    XGRS.source_system_code = p_conversion_type
    AND    ROWNUM             <= gn_batch_size;

    ---------------------------------------------------------
    --Fetching Count of Eligible Records in the Staging Table
    ---------------------------------------------------------
    ln_master_count := SQL%ROWCOUNT;

    COMMIT;

    ---------------------------------------------------------------------------------------------
    --Initializing the batch size count ,record count variables and taking next value of sequence
    ---------------------------------------------------------------------------------------------
    ln_batch_size_count := ln_master_count;
    gn_record_count     := gn_record_count + ln_batch_size_count;

    -----------------------------------------
    --Submitting Child Program for each batch
    -----------------------------------------
    LOOP
        SELECT COUNT(1)
        INTO   ln_req_count
        FROM   fnd_concurrent_requests FCR
        WHERE  FCR.parent_request_id  = gn_request_id
        AND    FCR.phase_code IN ('P','R');

        IF  ln_req_count < gn_max_child_req THEN
            ln_conc_request_id := FND_REQUEST.submit_request(
                                                              application => 'xxcnv'
                                                             ,program     => 'XX_GI_RCV_CHILD_MAIN'
                                                             ,sub_request => FALSE
                                                             ,argument1   => p_validate_only_flag
                                                             ,argument2   => p_reset_status_flag
                                                             ,argument3   => ln_seq
                                                             ,argument4   => gn_debug_flag
                                                             ,argument5   => gn_sleep
                                                             ,argument6   => gn_max_wait_time
                                                             ,argument7   => p_conversion_type
                                                            );
            IF  ln_conc_request_id = 0 THEN
                x_errbuf  := FND_MESSAGE.GET;
                RAISE EX_SUBMIT_CHILD;
            ELSE
                COMMIT;
                gn_index_request_id := gn_index_request_id + 1;
                gn_batch_count := gn_batch_count + 1;
                gt_req_id(gn_index_request_id) := ln_conc_request_id;
                x_time := sysdate;
                ------------------------------------
                --Log Conversion Control Information
                ------------------------------------
                XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                                                                p_conversion_id           => gn_conversion_id
                                                               ,p_batch_id                => ln_seq
                                                               ,p_num_bus_objs_processed  => ln_batch_size_count
                                                              );
                EXIT;
            END IF;-- IF  ln_conc_request_id = 0
        ELSE
            DBMS_LOCK.SLEEP(gn_sleep);
        END IF;--ln_req_count < gn_max_child_req
    END LOOP;--Submitting Child Program for each batch

EXCEPTION
    WHEN EX_SUBMIT_CHILD THEN
        x_retcode := 2;
        x_errbuf  := 'Error in submitting child requests: ' || x_errbuf;
    WHEN OTHERS THEN
        x_retcode := 2;
        x_errbuf  := 'Unexpected error in Bat_Child: ' || sqlerrm;
END bat_child;

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
                             x_conversion_id  OUT NOCOPY NUMBER
                            ,x_batch_size     OUT NOCOPY NUMBER
                            ,x_max_threads    OUT NOCOPY NUMBER
                            ,x_return_status  OUT NOCOPY VARCHAR2
                           )
IS
------------------------------------------
--Declaring local Variables and exceptions
------------------------------------------
ln_conversion_id PLS_INTEGER;
ln_batch_size    PLS_INTEGER;
ln_max_threads   PLS_INTEGER;

BEGIN
    SELECT  XCCC.conversion_id
           ,XCCC.batch_size
           ,XCCC.max_threads
    INTO    ln_conversion_id
           ,ln_batch_size
           ,ln_max_threads
    FROM    xx_com_conversions_conv XCCC
    WHERE   XCCC.conversion_code = G_CONVERSION_CODE;

    x_conversion_id := ln_conversion_id;
    x_batch_size    := ln_batch_size;
    x_max_threads   := ln_max_threads;
    x_return_status := 'S';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_return_status := 'E';
        display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '|| G_CONVERSION_CODE);
    WHEN OTHERS THEN
        x_return_status := 'E';
        display_log('Error while deriving conversion_id - '||SQLERRM);
END get_conversion_id;

-- +====================================================================+
-- | Name        :  update_batch_id                                     |
-- | Description :  This procedure is invoked to reset Batch Id to Null |
-- |                for Previously Errored Out Records                  |
-- |                                                                    |
-- | Parameters  :                                                      |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE update_batch_id( x_errbuf   OUT NOCOPY VARCHAR2
                          ,x_retcode  OUT NOCOPY VARCHAR2
                          ,p_batch_id IN         NUMBER
                          ,p_conversion_type IN  VARCHAR2
                         )
IS
BEGIN
    ----------------------------------------
    --Updating Process Flag for Reprocessing
    ----------------------------------------
    UPDATE xx_gi_rcv_stg XGRS
    SET    XGRS.batch_id = p_batch_id
          ,XGRS.process_flag  = 1
    WHERE  XGRS.process_flag  IN (2,3,4,6)
    AND    XGRS.source_system_code = p_conversion_type
    AND    XGRS.batch_id      = NVL(p_batch_id,XGRS.batch_id);
EXCEPTION
    WHEN OTHERS THEN
        x_errbuf  := 'Unexpected error in update_batch_id - '||SQLERRM;
        x_retcode := 2;
END update_batch_id;

-- +====================================================================+
-- | Name        :  launch_summary_report                               |
-- | Description :  This procedure is invoked to Launch Conversion      |
-- |                Processing Summary Report for that run              |
-- |                                                                    |
-- | Returns  :     x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE launch_summary_report( x_errbuf   OUT NOCOPY VARCHAR2
                                ,x_retcode  OUT NOCOPY VARCHAR2
                               )
IS
------------------------------------------
--Declaring local Variables and exceptions
------------------------------------------
EX_REP_SUMM             EXCEPTION;
lc_phase                VARCHAR2(03);
ln_summ_request_id      PLS_INTEGER;

BEGIN
    IF gt_req_id.count<>0 THEN
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
                    DBMS_LOCK.SLEEP(gn_sleep);
                END IF;
            END LOOP;
        END LOOP;
    END IF;

    ----------------------------------------------
    --Submitting the Summary Report for each batch
    ----------------------------------------------
    ln_summ_request_id := FND_REQUEST.submit_request(
                                                       application => G_COMM_APPLICATION
                                                      ,program     => G_SUMM_PROGRAM
                                                      ,sub_request => FALSE                               -- TRUE means is a sub request
                                                      ,argument1   => G_CONVERSION_CODE                   -- CONVERSION_CODE
                                                      ,argument2   => gn_request_id                       -- MASTER REQUEST ID
                                                      ,argument3   => NULL                                -- REQUEST ID
                                                      ,argument4   => NULL                                -- BATCH ID
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
        x_errbuf  := 'Processing Summary Report could not be submitted: '|| x_errbuf;
    WHEN OTHERS THEN
        x_retcode := 2;
        x_errbuf  := 'Unexpected Exception in procedure - Launch Summary Report. Error:  '|| SQLERRM;
END launch_summary_report;

-- +====================================================================+
-- | Name        :  launch_exception_report                             |
-- | Description :  This procedure is invoked to Launch Exception       |
-- |                Report for that batch                               |
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- |                p_conc_req_id                                       |
-- |                p_master_req_id                                     |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE launch_exception_report(
                                   p_batch_id         IN         NUMBER
                                  ,p_conc_req_id      IN         NUMBER
                                  ,p_master_req_id    IN         NUMBER
                                  ,x_errbuf           OUT NOCOPY VARCHAR2
                                  ,x_retcode          OUT NOCOPY VARCHAR2
                                 )
IS
------------------------------------------
--Declaring local variables and Exceptions
------------------------------------------
EX_REP_EXC              EXCEPTION;
ln_excep_request_id     PLS_INTEGER;

BEGIN
    ------------------------------------------------
    --Submitting the Exception Report for each batch
    ------------------------------------------------
    ln_excep_request_id := FND_REQUEST.submit_request(
                                                         application =>  G_COMM_APPLICATION
                                                        ,program     =>  G_EXCEP_PROGRAM
                                                        ,sub_request =>  FALSE             -- TRUE means is a sub request
                                                        ,argument1   =>  G_CONVERSION_CODE -- conversion_code
                                                        ,argument2   =>  p_master_req_id   -- MASTER REQUEST ID
                                                        ,argument3   =>  p_conc_req_id     -- REQUEST ID
                                                        ,argument4   =>  p_batch_id        -- BATCH ID
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
        bulk_log_error( p_error_msg            =>  'Exception Summary Report for the batch '||p_batch_id||' could not be submitted: ' || x_errbuf
                       ,p_error_code           =>  NULL
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  NULL
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'launch_exception_report'
                       ,p_staging_table_name   =>  NULL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
    WHEN OTHERS THEN
        x_retcode := 2;
        x_errbuf  := 'Unexpected Exception in procedure - Launch Exception Report. Error:  '|| SQLERRM;
END launch_exception_report;
-- +===================================================================+
-- | Name        :  submit_sub_requests                                |
-- | Description :  This procedure is invoked from the master_main     |
-- |                procedure. This would submit child requests based  |
-- |                on batch_size.                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_validate_omly_flag                               |
-- |                p_reset_status_flag                                |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE submit_sub_requests(
                               p_validate_only_flag  IN         VARCHAR2
                              ,p_reset_status_flag   IN         VARCHAR2
                              ,p_conversion_type     IN         VARCHAR2
                              ,x_errbuf              OUT NOCOPY VARCHAR2
                              ,x_retcode             OUT NOCOPY VARCHAR2
                             )

IS
------------------------------------------
--Declaring Local Variables and Exceptions
------------------------------------------
EX_NO_ENTRY          EXCEPTION;
ld_check_time        DATE;
ld_current_time      DATE;
ln_rem_time          PLS_INTEGER;
ln_current_count     PLS_INTEGER;
ln_last_count        PLS_INTEGER;
ln_last_loc_count    PLS_INTEGER;
ln_current_loc_count PLS_INTEGER;
lc_return_status     VARCHAR2(03);
lc_launch            VARCHAR2(02) := 'N';

BEGIN
    ---------------------------
    --Getting the Conversion id
    ---------------------------
    get_conversion_id(
                       x_conversion_id  => gn_conversion_id
                      ,x_batch_size     => gn_batch_size
                      ,x_max_threads    => gn_max_child_req
                      ,x_return_status  => lc_return_status
                     );

    -------------------------------------------
    --Update Batch Id if p_reset_status_flag='Y'
    -------------------------------------------
    IF lc_return_status = 'S' THEN
        IF  NVL(p_reset_status_flag,'N') = 'Y' THEN
            update_batch_id ( x_errbuf
                             ,x_retcode
                             ,NULL
                             ,p_conversion_type
                            );
        END IF;
        ld_check_time := sysdate;
        ln_current_count := 0;

        ---------------------------------------------------------------------------------------------------------------------------------------------------------
        --Getting the Count of Eligible records and call batch child if count>=batch size, else wait for the wait time specified and recheck for eligible records
        ---------------------------------------------------------------------------------------------------------------------------------------------------------
        LOOP
            ln_last_count     := ln_current_count;

            SELECT COUNT(1)
            INTO   ln_current_count
            FROM   xx_gi_rcv_stg XGRS
            WHERE  XGRS.batch_id IS NULL
            AND    XGRS.source_system_code = p_conversion_type             
            AND    XGRS.process_flag = 1;

            IF (ln_current_count >= gn_batch_size ) THEN
                bat_child(
                           p_request_id          => gn_request_id
                          ,p_validate_only_flag  => p_validate_only_flag
                          ,p_reset_status_flag   => p_reset_status_flag
                          ,p_conversion_type     => p_conversion_type
                          ,x_time                => ld_check_time
                          ,x_errbuf              => x_errbuf
                          ,x_retcode             => x_retcode
                         );
                lc_launch := 'Y';
            ELSE
                IF  ln_last_count = ln_current_count   THEN
                    ld_current_time := sysdate;
                    ln_rem_time := (ld_current_time - ld_check_time)*86400;

                    IF  ln_rem_time > gn_max_wait_time THEN
                        EXIT;
                    ELSE
                        DBMS_LOCK.SLEEP(gn_sleep);
                    END IF; -- ln_rem_time > gn_max_wait_time
                ELSE
                    DBMS_LOCK.SLEEP(gn_sleep);
                END IF; -- ln_last_count = ln_current_count
            END IF; --  ln_current_count >= gn_batch_size
        END LOOP;

        IF (ln_current_count <> 0  )THEN
            bat_child(
                       p_request_id          => gn_request_id
                      ,p_validate_only_flag  => p_validate_only_flag
                      ,p_reset_status_flag   => p_reset_status_flag
                      ,p_conversion_type     => p_conversion_type
                      ,x_time                => ld_check_time
                      ,x_errbuf              => x_errbuf
                      ,x_retcode             => x_retcode
                     );
            lc_launch := 'Y';
        END IF;

        IF  lc_launch = 'N' THEN
            display_log('No Data Found in the Table XX_GI_RCV_STG');
            x_retcode := 1;
        ELSE
            -----------------------
            --Launch Summary Report
            -----------------------
            launch_summary_report(
                                   x_errbuf
                                  ,x_retcode
                                 );
            -------------------------
            --Launch Exception Report
            -------------------------
            launch_exception_report(
                                     NULL                       -- p_batch_id
                                    ,NULL                       -- Child request id
                                    ,gn_request_id              -- Master Request id
                                    ,x_errbuf
                                    ,x_retcode
                                   );
        END IF;-- lc_launch = 'N'
        --------------------------------------------------------------------------------
        --Displaying the Batch and Item Information in the output file of Matser Program
        --------------------------------------------------------------------------------
        display_out(RPAD('=',38,'='));
        display_out(RPAD('Batch Size                 : ',29,' ')||RPAD(gn_batch_size,9,' '));
        display_out(RPAD('Number of Batches Launched : ',29,' ')||RPAD(gn_batch_count,9,' '));
        display_out(RPAD('Number of Records          : ',29,' ')||RPAD(gn_record_count,9,' '));
        display_out(RPAD('=',38,'='));
    ELSE
        RAISE EX_NO_ENTRY;
    END IF; -- lc_return_status

EXCEPTION
    WHEN EX_NO_ENTRY THEN
        x_retcode := 2;
    WHEN OTHERS THEN
        x_retcode := 2;
        display_log ('Unexpected error in submit_sub_request - '||SQLERRM);
END submit_sub_requests;

-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: GI Receipts  |
-- |                Conversion Master                                   |
-- |                Concurrent Request.This would submit child          |
-- |                programs based on batch_size                        |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_validate_omly_flag                                |
-- |                p_reset_status_flag                                 |
-- |                p_reset_status_flag                                 |
-- |                p_debug_flag                                        |
-- |                p_sleep_time                                        |
-- |                p_max_wait_time                                     |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE master_main(
                       x_errbuf              OUT NOCOPY VARCHAR2
                      ,x_retcode             OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag  IN         VARCHAR2
                      ,p_reset_status_flag   IN         VARCHAR2
                      ,p_debug_flag          IN         VARCHAR2
                      ,p_sleep_time          IN         NUMBER
                      ,p_max_wait_time       IN         NUMBER
                      ,p_conversion_type     IN         VARCHAR2
                     )
IS
------------------------------------------
--Declaring Local Variables and Exceptions
------------------------------------------
EX_SUB_REQ       EXCEPTION;
lc_request_data  VARCHAR2(1000);
lc_error_message VARCHAR2(4000);
ln_return_status NUMBER;

BEGIN
    -------------------------------------------------------------
    --Submitting Sub Requests corresponding to the Child Programs
    -------------------------------------------------------------
    gn_debug_flag              :=  p_debug_flag;
    gn_max_wait_time           :=  p_max_wait_time;
    gn_sleep                   :=  p_sleep_time;
    gn_request_id              :=  FND_GLOBAL.CONC_REQUEST_ID;

    submit_sub_requests(
                         p_validate_only_flag
                        ,p_reset_status_flag
                        ,p_conversion_type
                        ,lc_error_message
                        ,ln_return_status
                       );

    IF ln_return_status <> 0 THEN
        x_errbuf := lc_error_message;
        RAISE EX_SUB_REQ;
    END IF;

EXCEPTION
    WHEN EX_SUB_REQ THEN
        x_retcode := ln_return_status;
    WHEN NO_DATA_FOUND THEN
        x_retcode := 2;
        display_log('No Data Found');
    WHEN OTHERS THEN
        x_retcode := 2;
        x_errbuf  := 'Unexpected error in batch_main procedure - '||SQLERRM;
END master_main;

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
        display_log('There is no entry in the table XX_COM_CONTROL_INFO_CONV for the batch_id : '||p_batch_id);
    WHEN OTHERS THEN
        display_log('Error while deriving master_request_id - '||SQLERRM);
END get_master_request_id;

-- +===================================================================+
-- | Name        :  VALIDATE_TRANSACTION                               |
-- | Description :  OD: GI Receipts Conversion Child                   |
-- |                Concurrent Request.This would                      |
-- |                validate transaction records based on input        |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE validate_transaction(
                               x_errbuf      OUT    NOCOPY   VARCHAR2
                              ,x_retcode     OUT    NOCOPY   VARCHAR2
                              ,p_batch_id    IN              NUMBER
                              )
IS
------------------------------------------
--Declaring local Variables and Exceptions
------------------------------------------
EX_TRANSACTION_NO_DATA           EXCEPTION;
EX_ENTRY_EXCEP                   EXCEPTION;

ln_transaction_type_id           mtl_transaction_types.transaction_type_id%type;
ln_batch_size                    PLS_INTEGER;
ln_max_child_req                 PLS_INTEGER;
ln_from_organization_id          hr_all_organization_units.organization_id%type;
ln_from_location_id              hr_all_organization_units.location_id%type;
ln_to_organization_id            hr_all_organization_units.organization_id%type;
ln_ship_to_location_id           hr_all_organization_units.location_id%type;
ln_inventory_item_id             mtl_system_items_b.inventory_item_id%type;
lc_mtl_trans_enabled_flag        mtl_system_items_b.mtl_transactions_enabled_flag%type;
lc_primary_uom_code              mtl_system_items_b.primary_uom_code%type;
lc_primary_uom                   mtl_system_items_b.primary_unit_of_measure%type;
lc_subinventory_name             mtl_secondary_inventories.secondary_inventory_name%type;
ln_charge_acct_id                NUMBER;
ln_vendor_id                     po_vendors.vendor_id%type;
ln_vendor_site_id                po_vendor_sites_all.vendor_site_id%type;
ln_po_header_id                  po_headers_all.po_header_id%type;
ln_po_line_id                    po_lines_all.po_line_id%type;
ln_po_line_location_id           po_line_locations_all.line_location_id%type;
ln_po_distribution_id            po_distributions_all.po_distribution_id%type;
l_validated_trans_count          PLS_INTEGER;
lc_message                       VARCHAR2(4000);
lc_trans_message                 VARCHAR2(4000);
lc_return_status                 VARCHAR2(1);
lc_transaction_type_flag         VARCHAR2(1);
lc_from_organization_flag        VARCHAR2(1);
lc_item_flag_from                VARCHAR2(1);
lc_item_flag_to                  VARCHAR2(1);
lc_trans_enable_flag             VARCHAR2(1);
lc_subinventory_flag             VARCHAR2(1);
lc_to_organization_flag          VARCHAR2(1);
lc_ship_to_location_flag         VARCHAR2(1);
lc_transaction_date_flag         VARCHAR2(1);
lc_ship_network_flag             VARCHAR2(1);
lc_po_vendor_flag                VARCHAR2(1);
lc_charge_acct_flag              VARCHAR2(1);
lx_status                        VARCHAR2(100);
lx_error_code                    NUMBER;
lx_error_message                 VARCHAR2(2000);

--------------------------------
--Declaring table type variables
--------------------------------
TYPE trans_control_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.control_id%type
INDEX BY BINARY_INTEGER;
lt_trans_control_id trans_control_id_tbl_typ;

TYPE process_flag_tbl_type IS TABLE OF xx_gi_rcv_stg.process_flag%type
INDEX BY BINARY_INTEGER;
lt_process_flag process_flag_tbl_type;

TYPE transaction_type_id_tbl_type IS TABLE OF xx_gi_rcv_stg.transaction_type_id%type
INDEX BY BINARY_INTEGER;
lt_transaction_type_id transaction_type_id_tbl_type;

TYPE from_organization_tbl_type IS TABLE OF xx_gi_rcv_stg.organization_id%type
INDEX BY BINARY_INTEGER;
lt_from_organization_id from_organization_tbl_type;

TYPE inventory_item_id_tbl_type IS TABLE OF xx_gi_rcv_stg.item_id%type
INDEX BY BINARY_INTEGER;
lt_inventory_item_id inventory_item_id_tbl_type;

TYPE primary_uom_code_tbl_type IS TABLE OF xx_gi_rcv_stg.transaction_uom%type
INDEX BY BINARY_INTEGER;
lt_primary_uom_code primary_uom_code_tbl_type;

TYPE primary_uom_tbl_type IS TABLE OF xx_gi_rcv_stg.unit_of_measure%type
INDEX BY BINARY_INTEGER;
lt_primary_uom primary_uom_tbl_type;

TYPE subinventory_code_tbl_type IS TABLE OF xx_gi_rcv_stg.subinventory%type
INDEX BY BINARY_INTEGER;
lt_subinventory_code subinventory_code_tbl_type;

TYPE to_organization_id_tbl_type IS TABLE OF xx_gi_rcv_stg.to_organization_id%type
INDEX BY BINARY_INTEGER;
lt_to_organization_id to_organization_id_tbl_type;

TYPE ship_to_location_id_tbl_type IS TABLE OF xx_gi_rcv_stg.ship_to_location_id%type
INDEX BY BINARY_INTEGER;
lt_ship_to_location_id ship_to_location_id_tbl_type;

TYPE transaction_date_tbl_type IS TABLE OF xx_gi_rcv_stg.transaction_date%type
INDEX BY BINARY_INTEGER;
lt_transaction_date transaction_date_tbl_type;

TYPE charge_acct_id_tbl_type IS TABLE OF xx_gi_rcv_stg.charge_account_id%type
INDEX BY BINARY_INTEGER;
lt_charge_acct_id charge_acct_id_tbl_type;

TYPE vendor_id_tbl_type IS TABLE OF xx_gi_rcv_stg.vendor_id%type
INDEX BY BINARY_INTEGER;
lt_vendor_id vendor_id_tbl_type;

TYPE vendor_site_id_tbl_type IS TABLE OF xx_gi_rcv_stg.vendor_site_id%type
INDEX BY BINARY_INTEGER;
lt_vendor_site_id vendor_site_id_tbl_type;

TYPE po_header_id_tbl_type IS TABLE OF xx_gi_rcv_stg.po_header_id%type
INDEX BY BINARY_INTEGER;
lt_po_header_id po_header_id_tbl_type;

TYPE po_line_id_tbl_type IS TABLE OF xx_gi_rcv_stg.po_line_id%type
INDEX BY BINARY_INTEGER;
lt_po_line_id po_line_id_tbl_type;

TYPE po_line_location_id_tbl_type IS TABLE OF xx_gi_rcv_stg.po_line_location_id%type
INDEX BY BINARY_INTEGER;
lt_po_line_location_id po_line_location_id_tbl_type;

TYPE po_distribution_id_tbl_type IS TABLE OF xx_gi_rcv_stg.po_distribution_id%type
INDEX BY BINARY_INTEGER;
lt_po_distribution_id po_distribution_id_tbl_type;

TYPE error_message_tbl_type IS TABLE OF xx_gi_rcv_stg.error_msg%type
INDEX BY BINARY_INTEGER;
lt_error_message error_message_tbl_type;

TYPE rowid_tbl_typ IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_transaction_rowid       rowid_tbl_typ;

---------------------------------------
--Cursor to get the Transaction Details
---------------------------------------
CURSOR lcu_transactions (p_batch_id IN NUMBER)
IS
    SELECT   XGRS.ROWID
            ,XGRS.attribute1 from_loc_id
            ,XGRS.item_segment1 sku
            ,XGRS.attribute2 to_loc_id
            ,XGRS.transaction_date ship_dt
            ,XGRS.attribute7 ship_tm
            ,XGRS.control_id
            ,XGRS.attribute5 doc_num
            ,XGRS.document_line_num Line_num
            ,XGRS.source_system_code
            ,XGRS.receipt_source_code
    FROM     xx_gi_rcv_stg XGRS
    WHERE    XGRS.process_flag IN (1,2,3)
    AND      XGRS.batch_id=p_batch_id
    ORDER BY XGRS.control_id;

TYPE transaction_tbl_type IS TABLE OF lcu_transactions%rowtype
INDEX BY BINARY_INTEGER;
lt_transaction transaction_tbl_type;

---------------------------------------
--Cursor to derive the Transaction Type
---------------------------------------
CURSOR lcu_transaction_type (p_transaction_type IN VARCHAR2)
IS
    SELECT transaction_type_id
    FROM   mtl_transaction_types
    WHERE  transaction_type_name= P_TRANSACTION_TYPE;
    
---------------------------------------
--Cursor to derive the Charge Account ID 
---------------------------------------
CURSOR lcu_charge_acct (p_organization_id IN NUMBER)
IS
    SELECT material_account
    FROM   mtl_parameters
    WHERE  organization_id = p_organization_id;    

------------------------------------------------------
--Cursor to derive the organization id and location id
------------------------------------------------------
CURSOR lcu_organization(p_organization IN VARCHAR2)
IS
    SELECT haou.organization_id,haou.location_id
    FROM   hr_all_organization_units haou,
           hr_organization_information hoi
    WHERE  haou.organization_id=hoi.organization_id
    AND    hoi.org_information_context = 'CLASS'
    AND    hoi.org_information1        = 'INV'
    AND    hoi.org_information2        = 'Y'
    AND    haou.attribute1             = p_organization;

-------------------------------------------------------------------------
--Cursor to derive the inventory_item_id,UOM and transaction enabled flag
-------------------------------------------------------------------------
CURSOR lcu_item (p_item IN VARCHAR2, p_from_organization IN NUMBER)
IS
    SELECT  inventory_item_id
           ,mtl_transactions_enabled_flag
           ,primary_uom_code
           ,primary_unit_of_measure
    FROM    mtl_system_items_b
    WHERE   segment1        = p_item
    AND     organization_id = p_from_organization;

---------------------------------------------------------
--Cursor to validate the subinventory for an organization
---------------------------------------------------------
CURSOR lcu_subinventory(p_from_organization IN NUMBER)
IS
    SELECT  secondary_inventory_name
    FROM    mtl_secondary_inventories msi
    WHERE   msi.secondary_inventory_name = G_SUBINVENTORY_CODE
    AND     msi.organization_id          = p_from_organization;
    
    
---------------------------------------------------------
--Cursor to derive po and vendor information
---------------------------------------------------------
CURSOR lcu_po_vendor(p_doc_number IN VARCHAR2
                    ,p_item_id    IN NUMBER
                    ,p_ship_to_org_id IN NUMBER)
IS
    SELECT  poh.vendor_id
           ,poh.vendor_site_id
           ,poh.po_header_id
           ,pol.po_line_id
           ,poll.line_location_id
           ,pod.po_distribution_id
    FROM    po_headers_all poh
           ,po_lines_all pol
           ,po_line_locations_all poll
           ,po_distributions_all pod
    WHERE   poh.po_header_id = pol.po_header_id
    AND     pol.po_line_id   = poll.po_line_id
    AND     poll.line_location_id = pod.line_location_id
    AND     poh.authorization_status = 'APPROVED'  
    AND     NVL(poh.closed_code,'OPEN') <> 'CLOSED'
    AND     pol.closed_flag = 'N'
    AND     poll.closed_code = 'OPEN'
    AND     poh.segment1     = p_doc_number
    AND     pol.item_id      = p_item_id
    AND     poll.ship_to_organization_id = p_ship_to_org_id ;    

BEGIN
    ---------------------------
    --Getting the Conversion Id
    ---------------------------
    get_conversion_id(
                      x_conversion_id  => gn_conversion_id
                     ,x_batch_size     => ln_batch_size
                     ,x_max_threads    => ln_max_child_req
                     ,x_return_status  => lc_return_status
                     );
    IF lc_return_status = 'S' THEN

        -----------------------------------------
        --Feching and Validating Transaction Data
        -----------------------------------------
        OPEN lcu_transactions(p_batch_id);
        FETCH lcu_transactions BULK COLLECT INTO lt_transaction;
        CLOSE lcu_transactions;

        IF lt_transaction.count <> 0 THEN
            XX_COM_CONV_ELEMENTS_PKG.bulk_table_initialize;
            FOR i in 1..lt_transaction.count
            LOOP
                ------------------------
                --Initializing Variables
                ------------------------
                lt_trans_control_id(i)       :=  lt_transaction(i).control_id;
                lt_transaction_rowid(i)      :=  lt_transaction(i).ROWID;

                lt_transaction_type_id(i)    :=  NULL;
                lt_from_organization_id(i)   :=  NULL;
                lt_inventory_item_id(i)      :=  NULL;
                lt_primary_uom_code(i)       :=  NULL;
                lt_primary_uom(i)            :=  NULL;
                lt_subinventory_code(i)      :=  NULL;
                lt_ship_to_location_id(i)    :=  NULL;
                lt_transaction_date(i)       :=  NULL;
                lt_process_flag(i)           :=  NULL;
                lt_error_message(i)          :=  NULL;

                lc_trans_message             :=  NULL;
                lc_message                   :=  NULL;
                ln_transaction_type_id       :=  NULL;
                ln_from_organization_id      :=  NULL;
                ln_from_location_id          :=  NULL;
                ln_inventory_item_id         :=  NULL;
                lc_mtl_trans_enabled_flag    :=  NULL;
                lc_primary_uom_code          :=  NULL;
                lc_primary_uom               :=  NULL;
                lc_subinventory_name         :=  NULL;
                ln_to_organization_id        :=  NULL;
                ln_ship_to_location_id       :=  NULL;
                ln_vendor_id                 :=  NULL;
                ln_charge_acct_id            :=  NULL;
                ln_vendor_site_id            :=  NULL;
                ln_po_header_id              :=  NULL;
                ln_po_line_id                :=  NULL;
                ln_po_line_location_id       :=  NULL;
                ln_po_distribution_id        :=  NULL;
                

                lc_transaction_type_flag     :=  NULL;
                lc_from_organization_flag    :=  NULL;
                lc_item_flag_from            :=  NULL;
                lc_item_flag_to              :=  NULL;
                lc_trans_enable_flag         :=  NULL;
                lc_subinventory_flag         :=  NULL;
                lc_to_organization_flag      :=  NULL;
                lc_ship_to_location_flag     :=  NULL;
                lc_transaction_date_flag     :=  NULL;
                lc_ship_network_flag         :=  NULL;
                lc_po_vendor_flag            :=  NULL;

                -----------------------------
                --Validating transaction type
                -----------------------------
               IF lt_transaction(i).source_system_code = 'INVENTORY'
               THEN
               
                OPEN  lcu_transaction_type (G_TRANSACTION_TYPE);
                FETCH lcu_transaction_type INTO ln_transaction_type_id;
                    IF lcu_transaction_type%NOTFOUND THEN
                        lc_transaction_type_flag:= G_FAILURE;
                        lt_transaction_type_id(i):= 0;
                        fnd_message.set_name('XXCNV','XX_GI_60001_RCV_INVALID_TRANS');
                        fnd_message.set_token('TRANSACTION',G_TRANSACTION_TYPE);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error(
                                        p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  NULL
                                       ,p_staging_column_value =>  NULL
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lc_transaction_type_flag:= G_SUCCESS;
                        lt_transaction_type_id(i):= ln_transaction_type_id;
                    END IF;
                CLOSE lcu_transaction_type;

               ELSIF lt_transaction(i).source_system_code = 'RTV'
               THEN
               
               OPEN  lcu_transaction_type (G_RTV_TRAN_TYPE);
                FETCH lcu_transaction_type INTO ln_transaction_type_id;
                    IF lcu_transaction_type%NOTFOUND THEN
                        lc_transaction_type_flag:= G_FAILURE;
                        lt_transaction_type_id(i):= 0;
                        fnd_message.set_name('XXCNV','XX_GI_60001_RCV_INVALID_TRANS');
                        fnd_message.set_token('TRANSACTION',G_TRANSACTION_TYPE);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error(
                                        p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  NULL
                                       ,p_staging_column_value =>  NULL
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lc_transaction_type_flag:= G_SUCCESS;
                        lt_transaction_type_id(i):= ln_transaction_type_id;
                    END IF;
                CLOSE lcu_transaction_type;
               
               END IF; -- end checking source system code
                ----------------------------------------------
                --Validating and deriving from Organization Id
                ----------------------------------------------
                
              IF lt_transaction(i).source_system_code = 'INVENTORY'
              THEN  
                OPEN lcu_organization(lt_transaction(i).from_loc_id);
                FETCH lcu_organization INTO ln_from_organization_id
                                           ,ln_from_location_id;
                    IF  lcu_organization%NOTFOUND THEN
                        lc_from_organization_flag:=G_FAILURE;
                        lt_from_organization_id(i):= 0;
                        fnd_message.set_name('XXCNV','XX_GI_60002_RCV_INVAL_FROMORG');
                        fnd_message.set_token('ORGANIZATION',lt_transaction(i).from_loc_id);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error( p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  'ATTRIBUTE1'
                                       ,p_staging_column_value =>  lt_transaction(i).from_loc_id
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lt_from_organization_id(i):= ln_from_organization_id;
                        lc_from_organization_flag:=G_SUCCESS;
                    END IF;
                CLOSE lcu_organization;

                -------------------------------------------------------------
                --Validating Item and deriving inventory_item_id and UOM_CODE
                --Validating if item is defined in FROM LOC ID
                -------------------------------------------------------------
                OPEN lcu_item(lt_transaction(i).sku,ln_from_organization_id);
                FETCH lcu_item INTO ln_inventory_item_id
                                   ,lc_mtl_trans_enabled_flag
                                   ,lc_primary_uom_code
                                   ,lc_primary_uom;
                    IF lcu_item%NOTFOUND THEN
                        lc_item_flag_from:=G_FAILURE;
                        lt_inventory_item_id(i):=0;
                        lt_primary_uom_code(i):=NULL;
                        fnd_message.set_name('XXCNV','XX_GI_60003_RCV_INVALID_ITEM');
                        fnd_message.set_token('ITEM',lt_transaction(i).sku);
                        fnd_message.set_token('ORGANIZATION',lt_transaction(i).from_loc_id);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error( p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  'ITEM_SEGMENT1'
                                       ,p_staging_column_value =>  lt_transaction(i).sku
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lc_item_flag_from       :=  G_SUCCESS;
                        lt_inventory_item_id(i) :=  ln_inventory_item_id;
                        lt_primary_uom_code(i)  :=  lc_primary_uom_code;
                        lt_primary_uom(i)       :=  lc_primary_uom;
                        -------------------------------------------
                        --Validating if item is transaction enabled
                        -------------------------------------------
                        IF nvl(lc_mtl_trans_enabled_flag,'N') = 'Y' THEN
                            lc_trans_enable_flag:=G_SUCCESS;
                        ELSE
                            lc_trans_enable_flag:=G_FAILURE;
                            fnd_message.set_name('XXCNV','XX_GI_60004_RCV_ITEM_NONTRANS');
                            fnd_message.set_token('ITEM',lt_transaction(i).sku);
                            fnd_message.set_token('ORGANIZATION',lt_transaction(i).from_loc_id);
                            lc_message:= fnd_message.get;
                            --Adding error message to stack
                            bulk_log_error( p_error_msg            =>  lc_message
                                           ,p_error_code           =>  NULL
                                           ,p_control_id           =>  lt_trans_control_id(i)
                                           ,p_request_id           =>  gn_child_request_id
                                           ,p_converion_id         =>  gn_conversion_id
                                           ,p_package_name         =>  G_PACKAGE_NAME
                                           ,p_procedure_name       =>  'validate_transaction'
                                           ,p_staging_table_name   =>  G_STAGING_TBL
                                           ,p_batch_id             =>  p_batch_id
                                           ,p_staging_column_name  =>  'ITEM_SEGMENT1'
                                           ,p_staging_column_value =>  lt_transaction(i).sku
                                          );
                            lc_trans_message := lc_trans_message ||        lc_message;
                        END IF;
                    END IF;
                CLOSE lcu_item;

              END IF; --end checking the source system code.
                ---------------------------------------------------------------
                --Validating if subinventory is configured for the organization
                ---------------------------------------------------------------
              IF lt_transaction(i).source_system_code = 'INVENTORY'
              THEN  
                OPEN lcu_subinventory(ln_from_organization_id);
                FETCH lcu_subinventory INTO lc_subinventory_name;
                    IF lcu_subinventory%NOTFOUND THEN
                        lc_subinventory_flag:=G_FAILURE;
                        lt_subinventory_code(i):= NULL;
                        fnd_message.set_name('XXCNV','XX_GI_60005_RCV_INVAL_SUBINV');
                        fnd_message.set_token('SUBINVENTORY',G_SUBINVENTORY_CODE);
                        fnd_message.set_token('ORGANIZATION',lt_transaction(i).from_loc_id);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error( p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  NULL
                                       ,p_staging_column_value =>  NULL
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lc_subinventory_flag:=G_SUCCESS;
                        lt_subinventory_code(i):= lc_subinventory_name;
                    END IF;
                CLOSE lcu_subinventory;

              END IF; -- end checking the source system code.
                -----------------------------------------------
                --Validating and deriving transfer Organization
                -----------------------------------------------
                OPEN lcu_organization(lt_transaction(i).to_loc_id);
                FETCH lcu_organization INTO ln_to_organization_id
                                           ,ln_ship_to_location_id;
                    IF  lcu_organization%NOTFOUND THEN
                        lc_to_organization_flag:=G_FAILURE;
                        lt_to_organization_id(i):= 0;
                        fnd_message.set_name('XXCNV','XX_GI_60006_RCV_INVAL_TRANORG');
                        fnd_message.set_token('ORGANIZATION',lt_transaction(i).to_loc_id);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error( p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  'ATTRIBUTE2'
                                       ,p_staging_column_value =>  lt_transaction(i).to_loc_id
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lt_to_organization_id(i):= ln_to_organization_id;
                        lc_to_organization_flag:=G_SUCCESS;
                        ---------------------------------
                        --Validating ship_to_loocation_id
                        ---------------------------------
                        IF  ln_ship_to_location_id IS NULL THEN
                            lc_ship_to_location_flag:=G_FAILURE;
                            lt_ship_to_location_id(i):= 0;
                            fnd_message.set_name('XXCNV','XX_GI_60007_RCV_INVAL_TRANLOC');
                            fnd_message.set_token('ORGANIZATION',lt_transaction(i).to_loc_id);
                            lc_message:= fnd_message.get;
                            --Adding error message to stack
                            bulk_log_error( p_error_msg            =>  lc_message
                                           ,p_error_code           =>  NULL
                                           ,p_control_id           =>  lt_trans_control_id(i)
                                           ,p_request_id           =>  gn_child_request_id
                                           ,p_converion_id         =>  gn_conversion_id
                                           ,p_package_name         =>  G_PACKAGE_NAME
                                           ,p_procedure_name       =>  'validate_transaction'
                                           ,p_staging_table_name   =>  G_STAGING_TBL
                                           ,p_batch_id             =>  p_batch_id
                                           ,p_staging_column_name  =>  'ATTRIBUTE2'
                                           ,p_staging_column_value =>  lt_transaction(i).to_loc_id
                                          );
                            lc_trans_message := lc_trans_message ||        lc_message;
                        ELSE
                            lt_ship_to_location_id(i):= ln_ship_to_location_id;
                            lc_ship_to_location_flag:=G_SUCCESS;
                        END IF;
                    END IF;
                CLOSE lcu_organization;

                --------------------------------------------
                --Validating if item is defined in TO LOC ID
                --------------------------------------------
                OPEN lcu_item(lt_transaction(i).sku,ln_to_organization_id);
                FETCH lcu_item INTO ln_inventory_item_id
                                   ,lc_mtl_trans_enabled_flag
                                   ,lc_primary_uom_code
                                   ,lc_primary_uom;
                    IF lcu_item%NOTFOUND THEN
                        lc_item_flag_to:=G_FAILURE;
                        lt_inventory_item_id(i) :=  0;
                        lt_primary_uom_code(i)  :=  NULL;
                        fnd_message.set_name('XXCNV','XX_GI_60003_RCV_INVALID_ITEM');
                        fnd_message.set_token('ITEM',lt_transaction(i).sku);
                        fnd_message.set_token('ORGANIZATION',lt_transaction(i).to_loc_id);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error( p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  'ITEM_SEGMENT1'
                                       ,p_staging_column_value =>  lt_transaction(i).sku
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lc_item_flag_to              :=  G_SUCCESS;
                        lt_inventory_item_id(i)      :=  ln_inventory_item_id;
                        lt_primary_uom_code(i)       :=  lc_primary_uom_code;
                        lt_primary_uom(i)            :=  lc_primary_uom;
                    END IF;
                CLOSE lcu_item;
                
                ---------------------------------------------------------
                --Validating shipping network between from loc and to loc
                ---------------------------------------------------------
               IF lt_transaction(i).source_system_code = 'INVENTORY'
               THEN
               
                XX_GI_SHIPNET_CREATION_PKG.DYNAMIC_BUILD(
                           p_from_organization_id         => ln_from_organization_id 
                          ,p_to_organization_id           => ln_to_organization_id 
                          ,p_transfer_type                => NULL 
                          ,p_fob_point                    => NULL
                          ,p_interorg_transfer_code       => NULL
                          ,p_receipt_routing_id           => NULL
                          ,p_internal_order_required_flag => NULL
                          ,p_intransit_inv_account        => NULL
                          ,p_interorg_transfer_cr_account => NULL
                          ,p_interorg_receivables_account => NULL
                          ,p_interorg_payables_account    => NULL
                          ,p_interorg_price_var_account   => NULL
                          ,p_elemental_visibility_enabled => NULL
                          ,p_manual_receipt_expense       => NULL
                          ,x_status                       => lx_status
                          ,x_error_code                   => lx_error_code
                          ,x_error_message                => lx_error_message
                          );
                
                    IF lx_status <> 'S' THEN
                        lc_ship_network_flag :=G_FAILURE;
                        fnd_message.set_name('XXCNV','XX_GI_60003_RCV_INVALID_SHIPNETWORK');
                        fnd_message.set_token('ORGANIZATION',lt_transaction(i).to_loc_id);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error( p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  'ATTRIBUTE2'
                                       ,p_staging_column_value =>  lt_transaction(i).to_loc_id
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lc_ship_network_flag         :=  G_SUCCESS;
                    END IF;
               END IF; -- end checking the source system code
                
                --------------------------------------------
                --Validating vendor info and po information
                --------------------------------------------
               IF lt_transaction(i).source_system_code = 'VENDOR'
               THEN                
               
                OPEN lcu_po_vendor(lt_transaction(i).doc_num
                                  ,ln_inventory_item_id
                                  ,ln_to_organization_id);
                FETCH lcu_po_vendor INTO ln_vendor_id
                                   ,ln_vendor_site_id
                                   ,ln_po_header_id
                                   ,ln_po_line_id
                                   ,ln_po_line_location_id
                                   ,ln_po_distribution_id;
                    IF lcu_po_vendor%NOTFOUND THEN
                        lc_po_vendor_flag :=G_FAILURE;
                        lt_vendor_id(i) :=  0;
                        lt_vendor_site_id(i) :=  0;
                        lt_po_header_id(i) :=  0;
                        lt_po_line_id(i) :=  0;
                        lt_po_line_location_id(i) :=  0;
                        lt_po_distribution_id(i) :=  0;
                        
                        fnd_message.set_name('XXCNV','XX_GI_60003_RCV_INVALID_PO_NUMBER');
                        fnd_message.set_token('DOCNUMBER',lt_transaction(i).doc_num);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error( p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  'ATTRIBUTE5'
                                       ,p_staging_column_value =>  lt_transaction(i).doc_num
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lc_po_vendor_flag            :=  G_SUCCESS;
                        lt_vendor_id(i)              :=  ln_vendor_id;
                        lt_vendor_site_id(i)         :=  ln_vendor_site_id;
                        lt_po_header_id(i)           :=  ln_po_header_id;
                        lt_po_line_id(i)             :=  ln_po_line_id;
                        lt_po_line_location_id(i)    :=  ln_po_line_location_id;
                        lt_po_distribution_id(i)     :=  ln_po_distribution_id;
                    END IF;
                CLOSE lcu_po_vendor;

                  lc_transaction_type_flag     := G_SUCCESS;
                  lc_from_organization_flag    := G_SUCCESS;
                  lc_item_flag_from            := G_SUCCESS;
                  lc_trans_enable_flag         := G_SUCCESS;
                  lc_subinventory_flag         := G_SUCCESS;
                  lc_ship_network_flag         := G_SUCCESS;
          
                
               END IF;  -- end checking source system code
               
                --------------------------------------------
                --Validating vendor info and po information
                --------------------------------------------
               IF lt_transaction(i).source_system_code = 'RTV'
               THEN                
               
                OPEN lcu_charge_acct(ln_to_organization_id);
                FETCH lcu_charge_acct INTO ln_charge_acct_id;
                    IF lcu_charge_acct%NOTFOUND THEN
                        lc_charge_acct_flag :=G_FAILURE;
                        lt_charge_acct_id(i) :=  0;
                       
                        fnd_message.set_name('XXCNV','XX_GI_60003_RCV_INVALID_CHARGE_ACCT');
                        fnd_message.set_token('DOCNUMBER',lt_transaction(i).doc_num);
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error( p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  'ATTRIBUTE2'
                                       ,p_staging_column_value =>  lt_transaction(i).doc_num
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                    ELSE
                        lc_charge_acct_flag          :=  G_SUCCESS;
                        lt_charge_acct_id(i)         :=  ln_charge_acct_id;
                    END IF;
                CLOSE lcu_charge_acct;

                  lc_from_organization_flag    := G_SUCCESS;
                  lc_item_flag_from            := G_SUCCESS;
                  lc_trans_enable_flag         := G_SUCCESS;
                  lc_subinventory_flag         := G_SUCCESS;
                  lc_ship_network_flag         := G_SUCCESS;
          
                
               END IF;  -- end checking source system code               
               
               
               
                ---------------------------
                --Deriving transaction date
                ---------------------------
                BEGIN
                    lt_transaction_date(i) := TO_DATE(lt_transaction(i).ship_dt);
                    lc_transaction_date_flag := G_SUCCESS;
                EXCEPTION
                    WHEN OTHERS THEN
                        lc_transaction_date_flag := G_FAILURE;
                        fnd_message.set_name('XXCNV','XX_GI_60008_RCV_INVAL_TRANDAT');
                        lc_message:= fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error( p_error_msg            =>  lc_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_trans_control_id(i)
                                       ,p_request_id           =>  gn_child_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_transaction'
                                       ,p_staging_table_name   =>  G_STAGING_TBL
                                       ,p_batch_id             =>  p_batch_id
                                       ,p_staging_column_name  =>  'TRANSACTION_DATE'
                                       ,p_staging_column_value =>  lt_transaction(i).ship_dt
                                      );
                        lc_trans_message := lc_trans_message ||        lc_message;
                END;

                IF      lc_transaction_type_flag     =G_SUCCESS
                    AND lc_from_organization_flag    =G_SUCCESS
                    AND lc_item_flag_to              =G_SUCCESS
                    AND lc_item_flag_from            =G_SUCCESS
                    AND lc_trans_enable_flag         =G_SUCCESS
                    AND lc_subinventory_flag         =G_SUCCESS
                    AND lc_to_organization_flag      =G_SUCCESS
                    AND lc_ship_to_location_flag     =G_SUCCESS
                    AND lc_transaction_date_flag     =G_SUCCESS
                    AND lc_ship_network_flag         =G_SUCCESS
                    AND lc_po_vendor_flag            =G_SUCCESS
                THEN
                    lt_process_flag(i)  :=   4;
                    lt_error_message(i) :=  NULL;
                ELSE
                    lt_process_flag(i)   := 3;
                    lt_error_message(i)  :=  lc_trans_message;
                END IF;
                display_log('lt_process_flag(i)        '||lt_process_flag(i));
                display_log('lt_from_organization_id(i)'||lt_from_organization_id(i));
                display_log('lt_inventory_item_id(i)   '||lt_inventory_item_id(i));
                display_log('lt_primary_uom_code(i)    '||lt_primary_uom_code(i));
                display_log('lt_to_organization_id(i)  '||lt_to_organization_id(i));
                display_log('lt_ship_to_location_id(i) '||lt_ship_to_location_id(i));
                display_log('lt_subinventory_code(i)   '||lt_subinventory_code(i));
                display_log('lt_transaction_type_id(i) '||lt_transaction_type_id(i));
                display_log('lt_transaction_date(i)    '||lt_transaction_date(i));
                display_log('lt_error_message(i)       '||lt_error_message(i));
                display_log('gn_child_request_id       '||gn_child_request_id);
                display_log('lt_transaction_rowid      '||lt_transaction_rowid(i));

            END LOOP;--i in 1..lt_transaction.count

            ------------------------------------------------------------------------
            --Invoke Common Conversion API to Bulk Insert the Trnsaction Data Errors
            -------------------------------------------------------------------------
            XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

            -------------------------------------------------------------------------
            -- Bulk Update XX_GI_RCV_STG with Process flags and Ids
            -------------------------------------------------------------------------
            display_log('Before Update');
            FORALL i IN 1 .. lt_transaction.LAST
            UPDATE xx_gi_rcv_stg XGRS
            SET    XGRS.process_flag             =  lt_process_flag(i)
                  ,XGRS.organization_id          =  lt_from_organization_id(i)
                  ,XGRS.item_id                  =  lt_inventory_item_id(i)
                  ,XGRS.transaction_uom          =  lt_primary_uom_code(i)
                  ,XGRS.unit_of_measure          =  lt_primary_uom(i)
                  ,XGRS.to_organization_id       =  lt_to_organization_id(i)
                  ,XGRS.ship_to_location_id      =  lt_ship_to_location_id(i)
                  ,XGRS.charge_account_id        =  lt_charge_acct_id(i)
                  ,XGRS.subinventory             =  lt_subinventory_code(i)
                  ,XGRS.transaction_type_id      =  lt_transaction_type_id(i)
                  ,XGRS.transaction_date         =  lt_transaction_date(i)
                  ,XGRS.vendor_id                =  lt_vendor_id(i)
                  ,XGRS.vendor_site_id           =  lt_vendor_site_id(i)
                  ,XGRS.po_header_id             =  lt_po_header_id(i)
                  ,XGRS.po_line_id               =  lt_po_line_id(i)
                  ,XGRS.po_line_location_id      =  lt_po_line_location_id(i)
                  ,XGRS.po_distribution_id       =  lt_po_distribution_id(i)
                  ,XGRS.error_msg                =  lt_error_message(i)
                  ,XGRS.request_id               =  gn_child_request_id
            WHERE XGRS.ROWID                     =  lt_transaction_rowid(i);
            display_log('After Update');
        ELSE
            RAISE EX_TRANSACTION_NO_DATA;
        END IF; --lt_transactions.count <> 0
    ELSE
        RAISE EX_ENTRY_EXCEP;
    END IF;-- If lc_return_status ='S'
EXCEPTION
    WHEN EX_TRANSACTION_NO_DATA THEN
        --------------------------------------------------
        --Check if records are present in validated status
        --------------------------------------------------
        SELECT count(1)
        INTO   l_validated_trans_count
        FROM   xx_gi_rcv_stg XGRS
        WHERE  XGRS.process_flag   =  4
        AND    XGRS.batch_id  =  p_batch_id;

        IF l_validated_trans_count = 0 THEN
        x_retcode := 1;
        x_errbuf  := 'No data found in the staging table XX_GI_RCV_STG with batch_id - '||p_batch_id;
        --Adding error message to stack
        bulk_log_error( p_error_msg            =>  x_errbuf
                       ,p_error_code           =>  NULL
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'validate_transaction'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        ELSE
             x_retcode := 0;
        END IF;
    WHEN EX_ENTRY_EXCEP THEN
        x_retcode := 2;
        gc_sqlerrm:='There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE;
        gc_sqlcode:=SQLCODE;
        x_errbuf:=gc_sqlerrm;
        --Adding error message to stack
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'validate_transaction'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error in Validate Transactions - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'validate_transaction'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
END validate_transaction;


-- +===================================================================+
-- | Name        :  PROCESS_EXPECTED_RECEIPTS                          |
-- | Description :  OD: GI receipts Conversion Child                   |
-- |                Concurrent Request.This would                      |
-- |                process transaction records based on input         |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE process_expected_receipts(
                                     x_errbuf      OUT  NOCOPY  VARCHAR2
                                    ,x_retcode     OUT  NOCOPY  VARCHAR2
                                    ,p_batch_id    IN           NUMBER
                                  )
IS


   CURSOR lcu_exp_hdr_curr(p_batch_id NUMBER) 
   IS 
    SELECT rsh.*
      FROM rcv_shipment_headers rsh
     WHERE 1=1
      -- AND rsh.shipment_header_id = 100073
       AND EXISTS (SELECT (1)
                     FROM rcv_shipment_lines rsl,
                          mtl_material_transactions mmt
                    WHERE rsl.shipment_header_id = rsh.shipment_header_id
                      AND rsl.mmt_transaction_id = mmt.transaction_id
                      AND rsl.source_document_code = 'INVENTORY'
                      --AND mmt.source_code = 'SIV Inter Org Receipts'
                      AND mmt.attribute15 = to_char(p_batch_id)
                      AND rsl.shipment_line_status_code = 'EXPECTED');
                          
    TYPE lt_exp_hdr_curr_ty IS TABLE OF lcu_exp_hdr_curr%ROWTYPE
    INDEX BY BINARY_INTEGER;
                          
     lt_exp_hdr_curr  lt_exp_hdr_curr_ty;
                          


  --Cursor to get the details of the Shipments
   CURSOR lcu_expected_curr(p_shipment_header_id NUMBER,p_batch_id NUMBER)
   IS                
   SELECT rsl.shipment_line_id,
          rsl.shipment_header_id,
          rsl.line_num,
          rsl.quantity_shipped,
          mmt.transaction_date,
          mmt.source_line_id,
          mmt.transaction_uom,
          mtu.unit_of_measure,
          rsl.item_id,
          rsl.item_description,
          rsl.from_organization_id,
          rsl.to_organization_id,
          mmt.attribute1,
          mmt.attribute2,
          mmt.attribute3,
          mmt.attribute4,
          mmt.attribute5,
          mmt.attribute6,
          mmt.attribute7,
          mmt.attribute8,
          mmt.attribute9,
          mmt.attribute10,
          mmt.attribute11,
          mmt.attribute12,
          mmt.attribute13,
          mmt.attribute14,
          mmt.attribute15
     FROM rcv_shipment_lines rsl,
          mtl_material_transactions mmt,
          mtl_units_of_measure_tl mtu
    WHERE rsl.shipment_header_id = p_shipment_header_id
      AND rsl.mmt_transaction_id = mmt.transaction_id
      AND mmt.transaction_uom = mtu.uom_code
      AND rsl.source_document_code = 'INVENTORY'
      --AND mmt.source_code = 'SIV Inter Org Receipts'
      AND mmt.attribute15 = to_char(p_batch_id)
      AND rsl.shipment_line_status_code = 'EXPECTED'  ;  
   
                                                         
     TYPE lt_exp_curr_ty IS TABLE OF lcu_expected_curr%ROWTYPE
     INDEX BY BINARY_INTEGER;
     lt_exp_curr  lt_exp_curr_ty;
     
     TYPE trans_work_request_id_tbl_typ IS TABLE OF rcv_transactions_interface.request_id%type
     INDEX BY BINARY_INTEGER;
     lt_trans_work_request_id trans_work_request_id_tbl_typ;
     
     ln_head_nex_id  NUMBER;
     ln_grp_nex_id   NUMBER;
     lc_receipt_num  VARCHAR2(30);
     ln_tran_nex_id  NUMBER;
     EX_RCV_TRANS_WORK   EXCEPTION;
     ln_trans_work_request_id       fnd_concurrent_requests.request_id%type;
     ln_request_count               PLS_INTEGER   :=0;
     lc_phase                       fnd_concurrent_requests.phase_code%type;
 
BEGIN

   OPEN lcu_exp_hdr_curr(p_batch_id) ;
     FETCH lcu_exp_hdr_curr  BULK COLLECT INTO lt_exp_hdr_curr ;
       FOR i IN 1..lt_exp_hdr_curr.COUNT
       LOOP
       
           SELECT rcv_headers_interface_s.NEXTVAL
             INTO ln_head_nex_id
             FROM sys.dual;
                                 
           SELECT rcv_interface_groups_s.NEXTVAL
             INTO ln_grp_nex_id
             FROM sys.dual;
             
           --SELECT xx_gi_receipt_num_us_s.NEXTVAL
           --  INTO lc_receipt_num
           --  FROM sys.dual;
       
                                                       
                --Insert into RCV_HEADERS_INTERFACE
           INSERT INTO RCV_HEADERS_INTERFACE(
                 header_interface_id  
                ,group_id 
                ,processing_status_code 
                ,receipt_source_code 
                ,transaction_type 
                ,last_update_date 
                ,last_updated_by 
                ,last_update_login 
                ,creation_date 
                ,created_by 
                ,shipment_num 
                ,shipped_date 
                ,validation_flag 
                ,from_organization_id
                ,ship_to_organization_id 
                ,auto_transact_code
                ,expected_receipt_date
                ,receipt_num
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                )
                VALUES
                ( 
                 ln_head_nex_id               --header_interface_id , 
                ,ln_grp_nex_id               --group_id ,
                ,'PENDING'                   --processing_status_code ,
                ,lt_exp_hdr_curr(i).receipt_source_code       --receipt_source_code ,
                ,'NEW'                   --transaction_type ,
                ,sysdate                 --last_update_date ,
                ,fnd_global.user_id               --last_updated_by ,
                ,fnd_global.login_id               --last_update_login ,
                ,sysdate                  --creation_date ,
                ,fnd_global.user_id               --created_by ,
                ,lt_exp_hdr_curr(i).shipment_num          --shipment_num ,
                ,lt_exp_hdr_curr(i).shipped_date       --shipped_date ,
                ,'Y'                       --validation_flag ,
                ,lt_exp_hdr_curr(i).organization_id         
                ,lt_exp_hdr_curr(i).ship_to_org_id  --ship_to_organization_code ,
                ,'DELIVER'                   --auto_transact_code,
                ,NVL(lt_exp_hdr_curr(i).expected_receipt_date,sysdate)       --expected_receipt_date,
                ,NULL  --lc_receipt_num         --xx_gi_receipt_num_us_s.NEXTVAL       --receipt_num,
                ,lt_exp_hdr_curr(i).attribute1           --attribute1,
                ,lt_exp_hdr_curr(i).attribute2           --attribute2,
                ,lt_exp_hdr_curr(i).attribute3           --attribute3,
                ,lt_exp_hdr_curr(i).attribute4           --attribute4,
                ,lt_exp_hdr_curr(i).attribute5           --attribute5,
                ,lt_exp_hdr_curr(i).attribute6           --attribute6,
                ,lt_exp_hdr_curr(i).attribute7           --attribute7,
                ,lt_exp_hdr_curr(i).attribute8           --attribute8,
                ,lt_exp_hdr_curr(i).attribute9           --attribute9,
                ,lt_exp_hdr_curr(i).attribute10           --attribute10,
                ,lt_exp_hdr_curr(i).attribute11           --attribute11,
                ,lt_exp_hdr_curr(i).attribute12           --attribute12,
                ,lt_exp_hdr_curr(i).attribute13           --attribute13,
                ,lt_exp_hdr_curr(i).attribute14           --attribute14,
                ,lt_exp_hdr_curr(i).attribute15            --attribute15
                 );
       
       
       OPEN lcu_expected_curr (lt_exp_hdr_curr(i).shipment_header_id,p_batch_id);
         FETCH lcu_expected_curr BULK COLLECT INTO lt_exp_curr;
          FOR i IN 1..lt_exp_curr.COUNT
          LOOP     
                                     
                                                  
                 SELECT rcv_transactions_interface_s.NEXTVAL
                   INTO ln_tran_nex_id
                   FROM sys.dual;
                                        
                 UPDATE xx_gi_rcv_stg
                    SET interface_transaction_id =  ln_tran_nex_id
                  WHERE control_id = lt_exp_curr(i).source_line_id;

                                                      
                 INSERT INTO RCV_TRANSACTIONS_INTERFACE(
                   interface_transaction_id 
                  ,header_interface_id 
                  ,group_id 
                  ,last_update_date 
                  ,last_updated_by 
                  ,last_update_login 
                  ,creation_date 
                  ,created_by 
                  ,transaction_type 
                  ,transaction_date 
                  ,expected_receipt_date
                  ,processing_status_code 
                  ,processing_mode_code 
                  ,transaction_status_code 
                  ,quantity 
                  ,unit_of_measure
                  ,item_id
                  ,item_description
                  ,uom_code 
                  ,receipt_source_code 
                  ,source_document_code
                  ,destination_type_code
                  ,shipment_header_id
                  ,shipment_line_id
                  ,validation_flag
                  ,auto_transact_code
                  ,from_subinventory
                  ,subinventory
                  ,currency_code
                  ,currency_conversion_type
                  ,currency_conversion_rate
                  ,currency_conversion_date
                  ,from_organization_id
                  ,to_organization_id
                  ,attribute1
                  ,attribute2
                  ,attribute3
                  ,attribute4
                  ,attribute5
                  ,attribute6
                  ,attribute7
                  ,attribute8
                  ,attribute9
                  ,attribute10
                  ,attribute11
                  ,attribute12
                  ,attribute13
                  ,attribute14
                  ,attribute15
                  ) 
                  SELECT
                   ln_tran_nex_id                   --interface_transaction_id ,
                  ,ln_head_nex_id                   --header_interface_id ,
                  ,ln_grp_nex_id                   --group_id ,
                  ,sysdate           --last_update_date ,
                  ,fnd_global.user_id               --last_updated_by ,
                  ,fnd_global.login_id               --last_update_login ,
                  ,sysdate           --creation_date ,
                  ,fnd_global.user_id               --created_by ,
                  ,'RECEIVE'                    --transaction_type ,
                  ,lt_exp_curr(i).transaction_date                      --transaction_date ,
                  ,lt_exp_curr(i).transaction_date                      --transaction_date ,
                  ,'PENDING'                       --processing_status_code ,
                  ,'BATCH'                       --processing_mode_code ,
                  ,'PENDING'                       --transaction_status_code ,
                  ,lt_exp_curr(i).quantity_shipped               --quantity ,
                  ,lt_exp_curr(i).unit_of_measure
                  ,lt_exp_curr(i).item_id
                  ,lt_exp_curr(i).item_description
                  ,lt_exp_curr(i).transaction_uom           --uom_code ,
                  ,'INVENTORY'   --lt_exp_curr(i).receipt_source_code       --receipt_source_code ,
                  ,'INVENTORY'                   --source_document_code ,
                  ,'INVENTORY'                                  -- destination_type_code
                  ,lt_exp_curr(i).shipment_header_id           --shipment_header_id,
                  ,lt_exp_curr(i).shipment_line_id           --shipment_line_id,
                  ,'Y'                       --validation_flag,
                  ,'DELIVER'                       --auto_transact_code,
                  ,'STOCK'                        -- from subinventory
                  ,'STOCK'                       --subinventory,
                  ,null    --lt_exp_curr(i).currency_code            --currency_code
                  ,null    --lt_exp_curr(i).conversion_rate_type        --currency_conversion_type
                  ,null    --lt_exp_curr(i).conversion_rate        --currency_conversion_rate
                  ,null    --lt_exp_curr(i).conversion_date        --currency_conversion_date
                  ,lt_exp_curr(i).from_organization_id        -- from_organization_id
                  ,lt_exp_curr(i).to_organization_id        --to_organization_id
                  ,lt_exp_curr(i).attribute1               --attribute1,
                  ,lt_exp_curr(i).attribute2               --attribute2,
                  ,lt_exp_curr(i).attribute3               --attribute3,
                  ,lt_exp_curr(i).attribute4               --attribute4,
                  ,lt_exp_curr(i).attribute5               --attribute5,
                  ,lt_exp_curr(i).attribute6               --attribute6,
                  ,lt_exp_curr(i).attribute7               --attribute7,
                  ,lt_exp_curr(i).attribute8               --attribute8,
                  ,lt_exp_curr(i).attribute9               --attribute9,
                  ,lt_exp_curr(i).attribute10           --attribute10,
                  ,lt_exp_curr(i).attribute11           --attribute11,
                  ,lt_exp_curr(i).attribute12           --attribute12,
                  ,lt_exp_curr(i).attribute13           --attribute13,
                  ,lt_exp_curr(i).attribute14           --attribute14,
                  ,lt_exp_curr(i).attribute15            --attribute15
                   FROM sys.dual;
                                      
                                                                  
       END LOOP; -- Second Cursor ending point
     
       CLOSE lcu_expected_curr ;
                                                       
     COMMIT;             
    END LOOP;
    CLOSE lcu_exp_hdr_curr ;  
        -------------------------------
        --Submitting Transaction Worker
        -------------------------------
        ln_trans_work_request_id:= fnd_request.submit_request (application       => 'PO'
                                                              ,program           => 'RVCTP'
                                                              ,description       => NULL
                                                              ,start_time        => NULL
                                                              ,sub_request       => FALSE
                                                              ,argument1         => 'BATCH'
                                                              ,argument2         => NULL
                                                              ,argument3         => NULL
                                                              ,argument4         => NULL
                                                              );
        display_log('Transaction Worker Submitted with request id '||ln_trans_work_request_id);
        IF ln_trans_work_request_id = 0 THEN
            RAISE EX_RCV_TRANS_WORK;
        END IF;
        ln_request_count:=ln_request_count+1;
        lt_trans_work_request_id(ln_request_count):=ln_trans_work_request_id;
        COMMIT;

 
           

    -------------------------------------------------------------------
    --Wait till all the Transaction Workers are complete for this Batch
    -------------------------------------------------------------------
    IF lt_trans_work_request_id.count <>0 THEN
    FOR i IN lt_trans_work_request_id.FIRST .. lt_trans_work_request_id.LAST
    LOOP
        LOOP
            SELECT FCR.phase_code
            INTO   lc_phase
            FROM   FND_CONCURRENT_REQUESTS FCR
            WHERE  FCR.request_id = lt_trans_work_request_id(i);
            IF  lc_phase = 'C' THEN
                EXIT;
            ELSE
                DBMS_LOCK.SLEEP(gn_sleep);
            END IF;
        END LOOP;
     END LOOP;
     END IF;   

EXCEPTION
    WHEN EX_RCV_TRANS_WORK THEN
            gc_sqlerrm := SQLERRM;
            gc_sqlcode := SQLCODE;
            x_errbuf   := 'Error while submitting Receipt transaction Worker - '||gc_sqlerrm;
            x_retcode  := 2;
            bulk_log_error( p_error_msg            =>  gc_sqlerrm
                           ,p_error_code           =>  gc_sqlcode
                           ,p_control_id           =>  NULL
                           ,p_request_id           =>  gn_child_request_id
                           ,p_converion_id         =>  gn_conversion_id
                           ,p_package_name         =>  G_PACKAGE_NAME
                           ,p_procedure_name       =>  'process_expected_receipts'
                           ,p_staging_table_name   =>  G_STAGING_TBL
                           ,p_batch_id             =>  p_batch_id
                           ,p_staging_column_name  =>  NULL
                           ,p_staging_column_value =>  NULL
                          );
            XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        IF lcu_exp_hdr_curr%ISOPEN
        THEN
            CLOSE lcu_exp_hdr_curr;
        END IF;
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error in process_expected_receipts - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_expected_receipts'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        IF lcu_exp_hdr_curr%ISOPEN
        THEN
            CLOSE lcu_exp_hdr_curr;
        END IF;
END process_expected_receipts;


-- +===================================================================+
-- | Name        :  PROCESS_TRANSACTION                                |
-- | Description :  OD: GI receipts Conversion Child                   |
-- |                Concurrent Request.This would                      |
-- |                process transaction records based on input         |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_transaction(
                               x_errbuf      OUT  NOCOPY  VARCHAR2
                              ,x_retcode     OUT  NOCOPY  VARCHAR2
                              ,p_batch_id    IN           NUMBER
                             )
IS
---------------------------
--Declaring Local Variables
---------------------------
EX_TRANS_WORK                  EXCEPTION;
ln_load_batch_id               NUMBER;
ln_trans_work_request_id       fnd_concurrent_requests.request_id%type;
ln_request_count               PLS_INTEGER   :=0;
lc_phase                       fnd_concurrent_requests.phase_code%type;
lx_errbuf                      VARCHAR2(2000);
lx_retcode                     VARCHAR2(20);

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE transaction_record_tbl_typ IS TABLE OF xx_gi_rcv_stg%rowtype
INDEX BY BINARY_INTEGER;
lt_transaction_record transaction_record_tbl_typ;

TYPE source_code_tbl_typ IS TABLE OF xx_gi_rcv_stg.receipt_source_code%type
INDEX BY BINARY_INTEGER;
lt_source_code_tbl_typ source_code_tbl_typ;

TYPE control_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.control_id%type
INDEX BY BINARY_INTEGER;
lt_control_id control_id_tbl_typ;
lt_success_control_id control_id_tbl_typ;
lt_error_control_id control_id_tbl_typ;

TYPE inventory_item_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.item_id%type
INDEX BY BINARY_INTEGER;
lt_inventory_item_id inventory_item_id_tbl_typ;

TYPE sku_tbl_typ IS TABLE OF xx_gi_rcv_stg.item_segment1%type
INDEX BY BINARY_INTEGER;
lt_sku sku_tbl_typ;

TYPE organization_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.organization_id%type
INDEX BY BINARY_INTEGER;
lt_organization_id organization_id_tbl_typ;

TYPE ship_qty_tbl_typ IS TABLE OF xx_gi_rcv_stg.quantity%type
INDEX BY BINARY_INTEGER;
lt_ship_qty ship_qty_tbl_typ;

TYPE transaction_uom_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_uom%type
INDEX BY BINARY_INTEGER;
lt_transaction_uom transaction_uom_tbl_typ;

TYPE transaction_date_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_date%type
INDEX BY BINARY_INTEGER;
lt_transaction_date transaction_date_tbl_typ;

TYPE subinventory_code_tbl_typ IS TABLE OF xx_gi_rcv_stg.subinventory%type
INDEX BY BINARY_INTEGER;
lt_subinventory_code subinventory_code_tbl_typ;

TYPE transaction_type_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_type_id%type
INDEX BY BINARY_INTEGER;
lt_transaction_type_id transaction_type_id_tbl_typ;

TYPE license_plate_tbl_typ IS TABLE OF xx_gi_rcv_stg.license_plate_number%type
INDEX BY BINARY_INTEGER;
lt_license_plate license_plate_tbl_typ;

TYPE extended_cost_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_cost%type
INDEX BY BINARY_INTEGER;
lt_extended_cost extended_cost_tbl_typ;

TYPE ship_to_location_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.ship_to_location_id%type
INDEX BY BINARY_INTEGER;
lt_ship_to_location_id ship_to_location_id_tbl_typ;

TYPE transfer_organization_tbl_typ IS TABLE OF xx_gi_rcv_stg.to_organization_id%type
INDEX BY BINARY_INTEGER;
lt_transfer_organization transfer_organization_tbl_typ;

TYPE transfer_nbr_tbl_typ IS TABLE OF xx_gi_rcv_stg.shipment_num%type
INDEX BY BINARY_INTEGER;
lt_transfer_nbr transfer_nbr_tbl_typ;

TYPE from_loc_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.attribute1%type
INDEX BY BINARY_INTEGER;
lt_from_loc_id from_loc_id_tbl_typ;

TYPE to_loc_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.attribute2%type
INDEX BY BINARY_INTEGER;
lt_to_loc_id to_loc_id_tbl_typ;

TYPE comments_tbl_typ IS TABLE OF xx_gi_rcv_stg.comments%type
INDEX BY BINARY_INTEGER;
lt_comments comments_tbl_typ;

TYPE tran_ref_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_reference%type
INDEX BY BINARY_INTEGER;
lt_tran_ref tran_ref_tbl_typ;

TYPE error_message_tbl_typ IS TABLE OF xx_gi_rcv_stg.error_msg%type
INDEX BY BINARY_INTEGER;
lt_error_message error_message_tbl_typ;

TYPE trans_work_request_id_tbl_typ IS TABLE OF mtl_transactions_interface.request_id%type
INDEX BY BINARY_INTEGER;
lt_trans_work_request_id trans_work_request_id_tbl_typ;

TYPE attribute_tbl_typ IS TABLE OF mtl_transactions_interface.attribute1%type
INDEX BY BINARY_INTEGER;
lt_attribute_category       attribute_tbl_typ;
lt_attribute1               attribute_tbl_typ;
lt_attribute2               attribute_tbl_typ;
lt_attribute3               attribute_tbl_typ;
lt_attribute4               attribute_tbl_typ;
lt_attribute5               attribute_tbl_typ;
lt_attribute6               attribute_tbl_typ;
lt_attribute7               attribute_tbl_typ;
lt_attribute8               attribute_tbl_typ;
lt_attribute9               attribute_tbl_typ;
lt_attribute10              attribute_tbl_typ;
lt_attribute11              attribute_tbl_typ;
lt_attribute12              attribute_tbl_typ;
lt_attribute13              attribute_tbl_typ;
lt_attribute14              attribute_tbl_typ;
lt_attribute15              attribute_tbl_typ;

TYPE rowid_tbl_typ IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_success_rowid      rowid_tbl_typ;
lt_error_rowid        rowid_tbl_typ;

-----------------------------------------------------------------------
--Cursor to fetch Successfully validated records for a particular batch
-----------------------------------------------------------------------
CURSOR lcu_transaction_data
IS
SELECT XGITIS.*
FROM   xx_gi_rcv_stg XGITIS
WHERE  XGITIS.batch_id   = p_batch_id
AND    XGITIS.process_flag    = 4;

------------------------------------------------
--Cursor to fetch successful transaction records
------------------------------------------------
CURSOR lcu_success_records
IS
SELECT XGRS.control_id, XGRS.ROWID
FROM   xx_gi_rcv_stg XGRS
      ,mtl_material_transactions MMT
WHERE  MMT.source_line_id           =  XGRS.control_id
AND    XGRS.batch_id                =  p_batch_id
AND    XGRS.process_flag            =  4
--AND    XGRS.receipt_source_code     IN (G_SIV_SOURCE, G_WIV_SOURCE,G_RCC_SOURCE)
AND    MMT.request_id               >  gn_child_request_id;

------------------------------------------------
--Cursor to fetch errored transaction records
------------------------------------------------
CURSOR lcu_errored_records
IS
SELECT XGRS.control_id,MTI.error_explanation,XGRS.ROWID
FROM   xx_gi_rcv_stg XGRS
      ,mtl_transactions_interface MTI
WHERE  MTI.source_line_id           =  XGRS.control_id
AND    XGRS.batch_id                =  p_batch_id
AND    XGRS.process_flag            =  4
--AND    XGRS.receipt_source_code    IN (G_SIV_SOURCE, G_WIV_SOURCE,G_RCC_SOURCE)
AND    MTI.request_id               >  gn_child_request_id;

BEGIN
display_log('Start Processing');

-------------------------------------------------------------
--Fetching Successful records to insert 500 records at a time
-------------------------------------------------------------
    OPEN lcu_transaction_data;
    LOOP
    BEGIN
    FETCH lcu_transaction_data BULK COLLECT INTO lt_transaction_record LIMIT G_LIMIT_SIZE;

        EXIT WHEN lt_transaction_record.count =0;
        IF lt_transaction_record.count<>0 THEN
            FOR i IN lt_transaction_record.first..lt_transaction_record.count
            LOOP
                lt_source_code_tbl_typ(i)      :=lt_transaction_record(i).receipt_source_code;
                lt_control_id (i)              :=lt_transaction_record(i).control_id;
                lt_inventory_item_id(i)        :=lt_transaction_record(i).item_id;
                lt_sku(i)                      :=lt_transaction_record(i).item_segment1;
                lt_organization_id(i)          :=lt_transaction_record(i).organization_id;
                lt_ship_qty(i)                 :=lt_transaction_record(i).transaction_quantity * -1 ;
                lt_transaction_uom(i)          :=lt_transaction_record(i).transaction_uom;
                lt_transaction_date(i)         :=lt_transaction_record(i).transaction_date;
                lt_subinventory_code(i)        :=lt_transaction_record(i).subinventory;
                lt_transaction_type_id(i)      :=lt_transaction_record(i).transaction_type_id;
                lt_license_plate(i)            :=lt_transaction_record(i).license_plate_number;
                lt_extended_cost(i)            :=lt_transaction_record(i).transaction_cost;
                lt_ship_to_location_id(i)      :=lt_transaction_record(i).ship_to_location_id;
                lt_transfer_organization(i)    :=lt_transaction_record(i).to_organization_id;
                lt_transfer_nbr(i)             :=lt_transaction_record(i).shipment_num;
                lt_attribute_category(i)       :=lt_transaction_record(i).attribute_category;
                lt_from_loc_id(i)              :=lt_transaction_record(i).attribute1;
                lt_to_loc_id(i)                :=lt_transaction_record(i).attribute2;
                lt_transfer_nbr(i)             :=lt_transaction_record(i).shipment_num;
                lt_comments(i)                 :=lt_transaction_record(i).comments;
                lt_tran_ref(i)                 :=lt_transaction_record(i).transaction_reference;
                lt_attribute1(i)               :=lt_transaction_record(i).attribute1;
                lt_attribute2(i)               :=lt_transaction_record(i).attribute2;
                lt_attribute3(i)               :=lt_transaction_record(i).attribute3;
                lt_attribute4(i)               :=lt_transaction_record(i).attribute4;
                lt_attribute5(i)               :=lt_transaction_record(i).attribute5;
                lt_attribute6(i)               :=lt_transaction_record(i).attribute6;
                lt_attribute7(i)               :=lt_transaction_record(i).attribute7;
                lt_attribute8(i)               :=lt_transaction_record(i).attribute8;
                lt_attribute9(i)               :=lt_transaction_record(i).attribute9;
                lt_attribute10(i)              :=lt_transaction_record(i).attribute10;
                lt_attribute11(i)              :=lt_transaction_record(i).attribute11;
                lt_attribute12(i)              :=lt_transaction_record(i).attribute12;
                lt_attribute13(i)              :=lt_transaction_record(i).attribute13;
                lt_attribute14(i)              :=lt_transaction_record(i).attribute14;
                lt_attribute15(i)              :=to_char(p_batch_id);  --lt_transaction_record(i).attribute15;
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
            FORALL i in 1..lt_transaction_record.count
            INSERT INTO MTL_TRANSACTIONS_INTERFACE
            (
                SOURCE_CODE
               ,TRANSACTION_HEADER_ID
               ,SOURCE_LINE_ID
               ,SOURCE_HEADER_ID
               ,PROCESS_FLAG
               ,VALIDATION_REQUIRED
               ,TRANSACTION_MODE
               ,LAST_UPDATE_DATE
               ,LAST_UPDATED_BY
               ,CREATION_DATE
               ,CREATED_BY
               ,INVENTORY_ITEM_ID
               ,ITEM_SEGMENT1
               ,ORGANIZATION_ID
               ,TRANSACTION_QUANTITY
               ,TRANSACTION_UOM
               ,TRANSACTION_DATE
               ,SUBINVENTORY_CODE
               ,TRANSACTION_TYPE_ID
               ,TRANSACTION_REFERENCE
               ,TRANSACTION_COST
               ,SHIP_TO_LOCATION_ID
               ,TRANSFER_ORGANIZATION
               ,SHIPMENT_NUMBER
               ,ATTRIBUTE_CATEGORY
               ,ATTRIBUTE1
               ,ATTRIBUTE2
               ,ATTRIBUTE3
               ,ATTRIBUTE4               
               ,ATTRIBUTE5
               ,ATTRIBUTE6
               ,ATTRIBUTE7
               ,ATTRIBUTE8
               ,ATTRIBUTE9
               ,ATTRIBUTE10
               ,ATTRIBUTE11
               ,ATTRIBUTE12
               ,ATTRIBUTE13
               ,ATTRIBUTE14
               ,ATTRIBUTE15
            )
            VALUES
            (
                lt_source_code_tbl_typ(i)
               ,ln_load_batch_id
               ,lt_control_id (i)
               ,lt_control_id (i)
               ,G_PROCESS_FLAG
               ,G_VALIDATION_REQUIRED
               ,G_TRANSACTION_MODE
               ,SYSDATE
               ,G_USER_ID
               ,SYSDATE
               ,G_USER_ID
               ,lt_inventory_item_id(i)
               ,lt_sku(i)
               ,lt_organization_id(i)
               ,lt_ship_qty(i)
               ,lt_transaction_uom(i)
               ,lt_TRANSACTION_DATE(i)
               ,lt_subinventory_code(i)
               ,lt_transaction_type_id(i)
               ,lt_tran_ref(i)
               ,lt_extended_cost(i)
               ,lt_ship_to_location_id(i)
               ,lt_transfer_organization(i)
               ,lt_transfer_nbr(i)
               ,lt_attribute_category(i)
               ,lt_attribute1(i)
               ,lt_attribute2(i)
               ,lt_attribute3(i)
               ,lt_attribute4(i)
               ,lt_attribute5(i)
               ,lt_attribute6(i)
               ,lt_attribute7(i)
               ,lt_attribute8(i)
               ,lt_attribute9(i)
               ,lt_attribute10(i)
               ,lt_attribute11(i)
               ,lt_attribute12(i)
               ,lt_attribute13(i)
               ,lt_attribute14(i)
               ,lt_attribute15(i)
            );
        END IF;--lt_transaction_record.count<>0 THEN
        COMMIT;

        -------------------------------
        --Submitting Transaction Worker
        -------------------------------
        ln_trans_work_request_id:= fnd_request.submit_request (application       => 'INV'
                                                              ,program           => 'INCTCW'
                                                              ,description       => NULL
                                                              ,start_time        => NULL
                                                              ,sub_request       => FALSE
                                                              ,argument1         => ln_load_batch_id
                                                              ,argument2         => 1 --Interface Table
                                                              ,argument3         => NULL
                                                              ,argument4         => NULL
                                                              );
        display_log('Transaction Worker Submitted for Sub Batch '||ln_load_batch_id||' with request id '||ln_trans_work_request_id);
        IF ln_trans_work_request_id = 0 THEN
            RAISE EX_TRANS_WORK;
        END IF;
        ln_request_count:=ln_request_count+1;
        lt_trans_work_request_id(ln_request_count):=ln_trans_work_request_id;
        COMMIT;
    EXCEPTION
    WHEN EX_TRANS_WORK THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf   := 'Error while submitting transaction Worker - '||gc_sqlerrm;
        x_retcode  := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_transaction'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error while inserting records in interface table and invoking transaction worker - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_transaction'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END;
    END LOOP; --lcu_transaction_date
    CLOSE lcu_transaction_data;

    -------------------------------------------------------------------
    --Wait till all the Transaction Workers are complete for this Batch
    -------------------------------------------------------------------
    IF lt_trans_work_request_id.count <>0 THEN
    FOR i IN lt_trans_work_request_id.FIRST .. lt_trans_work_request_id.LAST
    LOOP
        LOOP
            SELECT FCR.phase_code
            INTO   lc_phase
            FROM   FND_CONCURRENT_REQUESTS FCR
            WHERE  FCR.request_id = lt_trans_work_request_id(i);
            IF  lc_phase = 'C' THEN
                EXIT;
            ELSE
                DBMS_LOCK.SLEEP(gn_sleep);
            END IF;
        END LOOP;
     END LOOP;
     END IF;

    -----------------------------------------------------------
    --Updating Process Flags for Successful Transaction Records
    -----------------------------------------------------------
    OPEN lcu_success_records;
    FETCH lcu_success_records BULK COLLECT INTO lt_success_control_id, lt_success_rowid;
        IF lt_success_control_id.COUNT>0 THEN
            FORALL i IN 1..lt_success_control_id.COUNT
            UPDATE xx_gi_rcv_stg XGRS
            SET    XGRS.PROCESS_FLAG = 7
                  ,XGRS.request_id   = gn_child_request_id
            WHERE  XGRS.ROWID=lt_success_rowid(i);
        END IF;
    CLOSE lcu_success_records;

    ------------------------------------------------
    --Logging Errors for Errored Transaction Records
    ------------------------------------------------
    OPEN lcu_errored_records;
    FETCH lcu_errored_records BULK COLLECT INTO lt_error_control_id, lt_error_message, lt_error_rowid;
        IF lt_error_control_id.COUNT > 0 THEN
            FOR i IN 1..lt_error_control_id.COUNT
            LOOP
                bulk_log_error( p_error_msg            =>  lt_error_message(i)
                               ,p_error_code           =>  NULL
                               ,p_control_id           =>  lt_error_control_id(i)
                               ,p_request_id           =>  gn_child_request_id
                               ,p_converion_id         =>  gn_conversion_id
                               ,p_package_name         =>  G_PACKAGE_NAME
                               ,p_procedure_name       =>  'process_transaction'
                               ,p_staging_table_name   =>  G_STAGING_TBL
                               ,p_batch_id             =>  p_batch_id
                               ,p_staging_column_name  =>  NULL
                               ,p_staging_column_value =>  NULL
                              );
            END LOOP;
            XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
             --------------------------------------------------------
             --Updating Process Flags for Errored Transaction Records
             --------------------------------------------------------
             FORALL i IN 1..lt_error_control_id.COUNT
             UPDATE xx_gi_rcv_stg XGRS
             SET    XGRS.process_flag  = 6
                   ,XGRS.error_msg     = lt_error_message(i)
                   ,XGRS.request_id    = gn_child_request_id
             WHERE  XGRS.batch_id      = p_batch_id
             AND    XGRS.ROWID         = lt_error_rowid(i);
        END IF;
    CLOSE lcu_errored_records;
    
    
    --------------------------------------------------------
    --Processing the expected receipt records
    --------------------------------------------------------
         process_expected_receipts(x_errbuf      => lx_errbuf
                                  ,x_retcode     => lx_retcode
                                  ,p_batch_id    => p_batch_id
                                  );    

EXCEPTION
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error in process_transaction - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_transaction'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        IF lcu_transaction_data%ISOPEN
        THEN
            CLOSE lcu_transaction_data;
        END IF;
END process_transaction;


-- +===================================================================+
-- | Name        :  process_po_receipts                                |
-- | Description :  OD: GI receipts Conversion Child                   |
-- |                Concurrent Request.This would                      |
-- |                process transaction records based on input         |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_po_receipts(
                               x_errbuf      OUT  NOCOPY  VARCHAR2
                              ,x_retcode     OUT  NOCOPY  VARCHAR2
                              ,p_batch_id    IN           NUMBER
                             )
IS
---------------------------
--Declaring Local Variables
---------------------------
EX_TRANS_WORK                  EXCEPTION;
ln_load_batch_id               NUMBER;
ln_header_id                   NUMBER;
ln_group_id                    NUMBER;
ln_transaction_id              NUMBER;
ln_trans_work_request_id       fnd_concurrent_requests.request_id%type;
ln_request_count               PLS_INTEGER   :=0;
lc_phase                       fnd_concurrent_requests.phase_code%type;
lx_errbuf                      VARCHAR2(2000);
lx_retcode                     VARCHAR2(20);

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE transaction_record_tbl_typ IS TABLE OF xx_gi_rcv_stg%rowtype
INDEX BY BINARY_INTEGER;
lt_transaction_record transaction_record_tbl_typ;

TYPE source_code_tbl_typ IS TABLE OF xx_gi_rcv_stg.receipt_source_code%type
INDEX BY BINARY_INTEGER;
lt_source_code_tbl_typ source_code_tbl_typ;

TYPE control_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.control_id%type
INDEX BY BINARY_INTEGER;
lt_control_id control_id_tbl_typ;
lt_success_control_id control_id_tbl_typ;
lt_error_control_id control_id_tbl_typ;

TYPE inventory_item_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.item_id%type
INDEX BY BINARY_INTEGER;
lt_inventory_item_id inventory_item_id_tbl_typ;

TYPE sku_tbl_typ IS TABLE OF xx_gi_rcv_stg.item_segment1%type
INDEX BY BINARY_INTEGER;
lt_sku sku_tbl_typ;

TYPE organization_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.organization_id%type
INDEX BY BINARY_INTEGER;
lt_organization_id organization_id_tbl_typ;

TYPE ship_qty_tbl_typ IS TABLE OF xx_gi_rcv_stg.quantity%type
INDEX BY BINARY_INTEGER;
lt_ship_qty ship_qty_tbl_typ;

TYPE transaction_uom_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_uom%type
INDEX BY BINARY_INTEGER;
lt_transaction_uom transaction_uom_tbl_typ;

TYPE unit_of_measure_tbl_typ IS TABLE OF xx_gi_rcv_stg.unit_of_measure%type
INDEX BY BINARY_INTEGER;
lt_unit_of_measure unit_of_measure_tbl_typ;

TYPE transaction_date_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_date%type
INDEX BY BINARY_INTEGER;
lt_transaction_date transaction_date_tbl_typ;

TYPE subinventory_code_tbl_typ IS TABLE OF xx_gi_rcv_stg.subinventory%type
INDEX BY BINARY_INTEGER;
lt_subinventory_code subinventory_code_tbl_typ;

TYPE transaction_type_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_type_id%type
INDEX BY BINARY_INTEGER;
lt_transaction_type_id transaction_type_id_tbl_typ;

TYPE license_plate_tbl_typ IS TABLE OF xx_gi_rcv_stg.license_plate_number%type
INDEX BY BINARY_INTEGER;
lt_license_plate license_plate_tbl_typ;

TYPE extended_cost_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_cost%type
INDEX BY BINARY_INTEGER;
lt_extended_cost extended_cost_tbl_typ;

TYPE ship_to_location_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.ship_to_location_id%type
INDEX BY BINARY_INTEGER;
lt_ship_to_location_id ship_to_location_id_tbl_typ;

TYPE transfer_organization_tbl_typ IS TABLE OF xx_gi_rcv_stg.to_organization_id%type
INDEX BY BINARY_INTEGER;
lt_transfer_organization transfer_organization_tbl_typ;

TYPE transfer_nbr_tbl_typ IS TABLE OF xx_gi_rcv_stg.shipment_num%type
INDEX BY BINARY_INTEGER;
lt_transfer_nbr transfer_nbr_tbl_typ;

TYPE from_loc_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.attribute1%type
INDEX BY BINARY_INTEGER;
lt_from_loc_id from_loc_id_tbl_typ;

TYPE to_loc_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.attribute2%type
INDEX BY BINARY_INTEGER;
lt_to_loc_id to_loc_id_tbl_typ;

TYPE vendor_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.vendor_id%type
INDEX BY BINARY_INTEGER;
lt_vendor_id vendor_id_tbl_typ;

TYPE vendor_site_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.vendor_site_id%type
INDEX BY BINARY_INTEGER;
lt_vendor_site_id vendor_site_id_tbl_typ;

TYPE po_header_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.po_header_id%type
INDEX BY BINARY_INTEGER;
lt_po_header_id po_header_id_tbl_typ;

TYPE po_line_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.po_line_id%type
INDEX BY BINARY_INTEGER;
lt_po_line_id po_line_id_tbl_typ;

TYPE po_line_location_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.po_line_location_id%type
INDEX BY BINARY_INTEGER;
lt_po_line_location_id po_line_location_id_tbl_typ;

TYPE po_distribution_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.po_distribution_id%type
INDEX BY BINARY_INTEGER;
lt_po_distribution_id po_distribution_id_tbl_typ;

TYPE comments_tbl_typ IS TABLE OF xx_gi_rcv_stg.comments%type
INDEX BY BINARY_INTEGER;
lt_comments comments_tbl_typ;

TYPE tran_ref_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_reference%type
INDEX BY BINARY_INTEGER;
lt_tran_ref tran_ref_tbl_typ;

TYPE error_message_tbl_typ IS TABLE OF xx_gi_rcv_stg.error_msg%type
INDEX BY BINARY_INTEGER;
lt_error_message error_message_tbl_typ;

TYPE trans_work_request_id_tbl_typ IS TABLE OF mtl_transactions_interface.request_id%type
INDEX BY BINARY_INTEGER;
lt_trans_work_request_id trans_work_request_id_tbl_typ;

TYPE attribute_tbl_typ IS TABLE OF mtl_transactions_interface.attribute1%type
INDEX BY BINARY_INTEGER;
lt_attribute_category       attribute_tbl_typ;
lt_attribute1               attribute_tbl_typ;
lt_attribute2               attribute_tbl_typ;
lt_attribute3               attribute_tbl_typ;
lt_attribute4               attribute_tbl_typ;
lt_attribute5               attribute_tbl_typ;
lt_attribute6               attribute_tbl_typ;
lt_attribute7               attribute_tbl_typ;
lt_attribute8               attribute_tbl_typ;
lt_attribute9               attribute_tbl_typ;
lt_attribute10              attribute_tbl_typ;
lt_attribute11              attribute_tbl_typ;
lt_attribute12              attribute_tbl_typ;
lt_attribute13              attribute_tbl_typ;
lt_attribute14              attribute_tbl_typ;
lt_attribute15              attribute_tbl_typ;

TYPE rowid_tbl_typ IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_success_rowid      rowid_tbl_typ;
lt_error_rowid        rowid_tbl_typ;


-----------------------------------------------------------------------
--Cursor to fetch Successfully validated records for a particular batch
-----------------------------------------------------------------------
CURSOR lcu_header_data 
IS
SELECT XGITIS.attribute8 key_rec
      ,XGITIS.vendor_id
      ,XGITIS.vendor_site_id
      ,XGITIS.to_organization_id
      ,XGITIS.ship_to_location_id
      ,count(*) key_rec_count
FROM   xx_gi_rcv_stg XGITIS
WHERE  XGITIS.batch_id   = p_batch_id
AND    XGITIS.process_flag    = 4
GROUP BY XGITIS.attribute8 
        ,XGITIS.vendor_id
        ,XGITIS.vendor_site_id
        ,XGITIS.to_organization_id
        ,XGITIS.ship_to_location_id;

-----------------------------------------------------------------------
--Cursor to fetch Successfully validated records for a particular batch
--and for a keyrec
-----------------------------------------------------------------------
CURSOR lcu_transaction_data (p_keyrec_num VARCHAR2)
IS
SELECT XGITIS.*
FROM   xx_gi_rcv_stg XGITIS
WHERE  XGITIS.batch_id   = p_batch_id
AND    XGITIS.attribute8 = p_keyrec_num
AND    XGITIS.process_flag    = 4;

------------------------------------------------
--Cursor to fetch successful transaction records
------------------------------------------------
CURSOR lcu_success_records
IS
SELECT XGRS.control_id, XGRS.ROWID
FROM   xx_gi_rcv_stg XGRS
      ,rcv_shipment_lines RSL
WHERE  RSL.attribute15              =  XGRS.control_id
AND    XGRS.batch_id                =  p_batch_id
AND    XGRS.process_flag            =  4
--AND    XGRS.receipt_source_code     IN (G_SIV_SOURCE, G_WIV_SOURCE,G_RCC_SOURCE)
AND    RSL.request_id               >  gn_child_request_id;

------------------------------------------------
--Cursor to fetch errored transaction records
------------------------------------------------
CURSOR lcu_errored_records
IS
SELECT XGRS.control_id,null error_explanation,XGRS.ROWID
FROM   xx_gi_rcv_stg XGRS
      ,rcv_transactions_interface RTI
WHERE  RTI.attribute15           =  XGRS.control_id
AND    XGRS.batch_id                =  p_batch_id
AND    XGRS.process_flag            =  4
--AND    XGRS.receipt_source_code    IN (G_SIV_SOURCE, G_WIV_SOURCE,G_RCC_SOURCE)
AND    RTI.request_id               >  gn_child_request_id;

TYPE header_record_tbl_typ IS TABLE OF lcu_header_data%rowtype
INDEX BY BINARY_INTEGER;
lt_header_record      header_record_tbl_typ;

BEGIN
display_log('Start Processing');

-------------------------------------------------------------
--Fetching Successful records to insert 500 records at a time
-------------------------------------------------------------

   OPEN lcu_header_data;
   LOOP
   BEGIN
   FETCH lcu_header_data BULK COLLECT INTO lt_header_record LIMIT G_LIMIT_SIZE;
   
      EXIT WHEN lt_header_record.count = 0;
      IF lt_header_record.count<>0 THEN
         FOR i IN lt_header_record.first..lt_header_record.count
         LOOP
         
            SELECT rcv_headers_interface_s.NEXTVAL
            INTO   ln_header_id
            FROM   sys.dual;
                                 
            SELECT rcv_interface_groups_s.NEXTVAL
            INTO   ln_group_id
            FROM   sys.dual; 
             
            lt_ship_to_location_id(i)      :=lt_header_record(i).ship_to_location_id;
            lt_transfer_organization(i)    :=lt_header_record(i).to_organization_id;
            lt_vendor_id(i)                :=lt_header_record(i).vendor_id;
            lt_vendor_site_id(i)           :=lt_header_record(i).vendor_site_id;
            lt_attribute8(i)               :=lt_header_record(i).key_rec;
            
            OPEN lcu_transaction_data(lt_header_record(i).key_rec);
            LOOP
            FETCH lcu_transaction_data BULK COLLECT INTO lt_transaction_record LIMIT G_LIMIT_SIZE;

            EXIT WHEN lt_transaction_record.count =0;
            IF lt_transaction_record.count<>0 THEN
              FOR i IN lt_transaction_record.first..lt_transaction_record.count
              LOOP
                lt_source_code_tbl_typ(i)      :=lt_transaction_record(i).receipt_source_code;
                lt_control_id (i)              :=lt_transaction_record(i).control_id;
                lt_inventory_item_id(i)        :=lt_transaction_record(i).item_id;
                lt_sku(i)                      :=lt_transaction_record(i).item_segment1;
                lt_organization_id(i)          :=lt_transaction_record(i).organization_id;
                lt_ship_qty(i)                 :=lt_transaction_record(i).transaction_quantity ;
                lt_transaction_uom(i)          :=lt_transaction_record(i).transaction_uom;
                lt_unit_of_measure(i)          :=lt_transaction_record(i).unit_of_measure;
                lt_transaction_date(i)         :=lt_transaction_record(i).transaction_date;
                lt_subinventory_code(i)        :=lt_transaction_record(i).subinventory;
                lt_transaction_type_id(i)      :=lt_transaction_record(i).transaction_type_id;
                lt_license_plate(i)            :=lt_transaction_record(i).license_plate_number;
                lt_extended_cost(i)            :=lt_transaction_record(i).transaction_cost;
                lt_ship_to_location_id(i)      :=lt_transaction_record(i).ship_to_location_id;
                lt_transfer_organization(i)    :=lt_transaction_record(i).to_organization_id;
                lt_transfer_nbr(i)             :=lt_transaction_record(i).shipment_num;
                lt_attribute_category(i)       :=lt_transaction_record(i).attribute_category;
                lt_from_loc_id(i)              :=lt_transaction_record(i).attribute1;
                lt_to_loc_id(i)                :=lt_transaction_record(i).attribute2;
                lt_transfer_nbr(i)             :=lt_transaction_record(i).shipment_num;
                lt_vendor_id(i)                :=lt_transaction_record(i).vendor_id;
                lt_vendor_site_id(i)           :=lt_transaction_record(i).vendor_site_id;
                lt_po_header_id(i)             :=lt_transaction_record(i).po_header_id;
                lt_po_line_id(i)               :=lt_transaction_record(i).po_line_id;
                lt_po_line_location_id(i)      :=lt_transaction_record(i).po_line_location_id;
                lt_po_distribution_id(i)       :=lt_transaction_record(i).po_distribution_id;
                lt_comments(i)                 :=lt_transaction_record(i).comments;
                lt_tran_ref(i)                 :=lt_transaction_record(i).transaction_reference;
                lt_attribute1(i)               :=lt_transaction_record(i).attribute1;
                lt_attribute2(i)               :=lt_transaction_record(i).attribute2;
                lt_attribute3(i)               :=lt_transaction_record(i).attribute3;
                lt_attribute4(i)               :=lt_transaction_record(i).attribute4;
                lt_attribute5(i)               :=lt_transaction_record(i).attribute5;
                lt_attribute6(i)               :=lt_transaction_record(i).attribute6;
                lt_attribute7(i)               :=lt_transaction_record(i).attribute7;
                lt_attribute8(i)               :=lt_transaction_record(i).attribute8;
                lt_attribute9(i)               :=lt_transaction_record(i).attribute9;
                lt_attribute10(i)              :=lt_transaction_record(i).attribute10;
                lt_attribute11(i)              :=lt_transaction_record(i).attribute11;
                lt_attribute12(i)              :=lt_transaction_record(i).attribute12;
                lt_attribute13(i)              :=lt_transaction_record(i).attribute13;
                lt_attribute14(i)              :=lt_transaction_record(i).attribute14;
                lt_attribute15(i)              :=lt_transaction_record(i).control_id;  --lt_transaction_record(i).attribute15;
              END LOOP;

            ---------------------------------------------------------------
            --Deriving batch id to invoke transaction worker in sub batches
            ---------------------------------------------------------------
              SELECT rcv_transactions_interface_s.NEXTVAL
              INTO   ln_transaction_id
              FROM   dual;

            -------------------------------------------------------------
            --Bulk Insert records for each sub batch into interface table
            -------------------------------------------------------------
              FORALL i in 1..lt_transaction_record.count
              INSERT INTO RCV_TRANSACTIONS_INTERFACE
              ( interface_transaction_id 
               ,header_interface_id 
               ,group_id 
               ,last_update_date 
               ,last_updated_by 
               ,last_update_login 
               ,creation_date 
               ,created_by 
               ,transaction_type 
               ,transaction_date 
               ,processing_status_code 
               ,processing_mode_code 
               ,transaction_status_code 
               ,quantity 
               ,unit_of_measure 
               ,item_id
               ,uom_code
               ,auto_transact_code
               ,receipt_source_code 
               ,to_organization_id
               ,source_document_code
               ,po_header_id
               ,po_line_id
               ,po_line_location_id
               ,po_distribution_id
               ,destination_type_code
               ,subinventory
               ,comments
               ,employee_id
               ,attribute_category
               ,attribute1
               ,attribute2
               ,attribute3
               ,attribute4
               ,attribute5
               ,attribute6
               ,attribute7
               ,attribute8
               ,attribute9
               ,attribute10
               ,attribute11
               ,attribute12
               ,attribute13
               ,attribute14
               ,attribute15
               ,validation_flag
              )
              VALUES
              (
                ln_transaction_id         --interface_transaction_id
               ,ln_header_id              --header_interface_id
               ,ln_group_id               --group_id
               ,SYSDATE                   --last_update_date
               ,G_USER_ID                 --last_updated_by
               ,G_USER_ID                 --last_update_login
               ,SYSDATE                   --creation_date
               ,G_USER_ID                 --created_by
               ,'RECEIVE'                 --transaction_type
               ,lt_TRANSACTION_DATE(i)    --transaction_date
               ,'PENDING'                 --processing_status_code
               ,'BATCH'                   --processing_mode_code
               ,'PENDING'                 --transaction_status_code
               ,lt_ship_qty(i)            --quantity
               ,lt_unit_of_measure(i)     --unit_of_measure
               ,lt_inventory_item_id(i)   --item_id
               ,lt_transaction_uom(i)     --uom_code
               ,'DELIVER'                 --auto_transact_code
               ,'VENDOR'                  --receipt_source_code
               ,lt_transfer_organization(i) --to_organization_id
               ,'PO'                        --source_document_code
               ,lt_po_header_id(i)          --po_header_id
               ,lt_po_line_id(i)            --po_line_id
               ,lt_po_line_location_id(i)   --po_line_location_id
               ,lt_po_distribution_id(i)    --po_distribution_id
               ,'INVENTORY'                 --destination_type_code
               ,'STOCK'                     --subinventory
               ,lt_comments(i)              --comments
               ,1421                        --employee_id
               ,lt_attribute_category(i)    --attribute_category
               ,lt_attribute1(i)            --attribute1
               ,lt_attribute2(i)            --attribute2
               ,lt_attribute3(i)            --attribute3
               ,lt_attribute4(i)            --attribute4
               ,lt_attribute5(i)            --attribute5
               ,lt_attribute6(i)            --attribute6
               ,lt_attribute7(i)            --attribute7
               ,lt_attribute8(i)            --attribute8
               ,lt_attribute9(i)            --attribute9
               ,lt_attribute10(i)           --attribute10
               ,lt_attribute11(i)           --attribute11
               ,lt_attribute12(i)            --attribute12
               ,lt_attribute13(i)           --attribute13
               ,lt_attribute14(i)           --attribute14
               ,lt_attribute15(i)           --attribute15
               ,'Y'                         --validation_flag
               );
             END IF;--lt_transaction_record.count<>0 THEN
             COMMIT;

        END LOOP; --lcu_transaction_data
        CLOSE lcu_transaction_data;
        
        END LOOP; -- to end the header loop
            -------------------------------------------------------------
            --Bulk Insert records for each sub batch into interface table
            -------------------------------------------------------------
              FORALL i in 1..lt_header_record.count
              INSERT INTO RCV_HEADERS_INTERFACE
              ( header_interface_id  
               ,group_id 
               ,processing_status_code 
               ,receipt_source_code 
               ,transaction_type 
               ,last_update_date 
               ,last_updated_by 
               ,last_update_login
               ,creation_date
               ,created_by 
               --,shipment_num
               ,shipped_date
               ,expected_receipt_date
               ,vendor_id
               ,vendor_site_id
               ,validation_flag 
               ,ship_to_organization_id
               ,location_id
               ,auto_transact_code
               ,receipt_num
               ,attribute8
              )
              VALUES
              ( ln_header_id   --interface_header_id
               ,ln_group_id    --group_id
               ,'PENDING'      --processing_status_code
               ,'VENDOR'       --receipt_source_code
               ,'NEW'          --transaction_type
               ,SYSDATE        --last_update_date
               ,G_USER_ID      --last_updated_by
               ,G_USER_ID      --last_update_login
               ,SYSDATE        --creation_date
               ,G_USER_ID      --created_by
               --,NULL           --shipment_num
               ,SYSDATE        --shipped_date
               ,SYSDATE        --expected_receipt_date
               ,lt_vendor_id(i)  --vendor_id
               ,lt_vendor_site_id(i)  --vendor_site_id
               ,'Y'               --validation_flag
               ,lt_transfer_organization(i) --ship_to_organization_id
               ,lt_ship_to_location_id(i)   --location_id
               ,'DELIVER'                   --auto_transact_code
               ,NULL                        --receipt_num
               ,lt_attribute8(i)            --attribute8
               );
             END IF;--lt_header_record.count<>0 THEN
             COMMIT;
        
        
        -------------------------------
        --Submitting Transaction Worker
        -------------------------------
        ln_trans_work_request_id:= fnd_request.submit_request (application       => 'PO'
                                                              ,program           => 'RVCTP'
                                                              ,description       => NULL
                                                              ,start_time        => NULL
                                                              ,sub_request       => FALSE
                                                              ,argument1         => 'BATCH'
                                                              ,argument2         => ln_group_id
                                                              ,argument3         => NULL
                                                              ,argument4         => NULL
                                                              );
        display_log('Transaction Worker Submitted for Sub Batch '||ln_load_batch_id||' with request id '||ln_trans_work_request_id);
        IF ln_trans_work_request_id = 0 THEN
            RAISE EX_TRANS_WORK;
        END IF;
        ln_request_count:=ln_request_count+1;
        lt_trans_work_request_id(ln_request_count):=ln_trans_work_request_id;
        COMMIT;
    EXCEPTION
    WHEN EX_TRANS_WORK THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf   := 'Error while submitting transaction Worker - '||gc_sqlerrm;
        x_retcode  := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_po_receipts'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error while inserting records in interface table and invoking transaction worker - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_po_receipts'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END;
    END LOOP; --lcu_header_data
    CLOSE lcu_header_data;

    -------------------------------------------------------------------
    --Wait till all the Transaction Workers are complete for this Batch
    -------------------------------------------------------------------
    IF lt_trans_work_request_id.count <>0 THEN
    FOR i IN lt_trans_work_request_id.FIRST .. lt_trans_work_request_id.LAST
    LOOP
        LOOP
            SELECT FCR.phase_code
            INTO   lc_phase
            FROM   FND_CONCURRENT_REQUESTS FCR
            WHERE  FCR.request_id = lt_trans_work_request_id(i);
            IF  lc_phase = 'C' THEN
                EXIT;
            ELSE
                DBMS_LOCK.SLEEP(gn_sleep);
            END IF;
        END LOOP;
     END LOOP;
     END IF;

    -----------------------------------------------------------
    --Updating Process Flags for Successful Transaction Records
    -----------------------------------------------------------
    OPEN lcu_success_records;
    FETCH lcu_success_records BULK COLLECT INTO lt_success_control_id, lt_success_rowid;
        IF lt_success_control_id.COUNT>0 THEN
            FORALL i IN 1..lt_success_control_id.COUNT
            UPDATE xx_gi_rcv_stg XGRS
            SET    XGRS.PROCESS_FLAG = 7
                  ,XGRS.request_id   = gn_child_request_id
            WHERE  XGRS.ROWID=lt_success_rowid(i);
        END IF;
    CLOSE lcu_success_records;

    ------------------------------------------------
    --Logging Errors for Errored Transaction Records
    ------------------------------------------------
    OPEN lcu_errored_records;
    FETCH lcu_errored_records BULK COLLECT INTO lt_error_control_id, lt_error_message, lt_error_rowid;
        IF lt_error_control_id.COUNT > 0 THEN
            FOR i IN 1..lt_error_control_id.COUNT
            LOOP
                bulk_log_error( p_error_msg            =>  lt_error_message(i)
                               ,p_error_code           =>  NULL
                               ,p_control_id           =>  lt_error_control_id(i)
                               ,p_request_id           =>  gn_child_request_id
                               ,p_converion_id         =>  gn_conversion_id
                               ,p_package_name         =>  G_PACKAGE_NAME
                               ,p_procedure_name       =>  'process_po_receipts'
                               ,p_staging_table_name   =>  G_STAGING_TBL
                               ,p_batch_id             =>  p_batch_id
                               ,p_staging_column_name  =>  NULL
                               ,p_staging_column_value =>  NULL
                              );
            END LOOP;
            XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
             --------------------------------------------------------
             --Updating Process Flags for Errored Transaction Records
             --------------------------------------------------------
             FORALL i IN 1..lt_error_control_id.COUNT
             UPDATE xx_gi_rcv_stg XGRS
             SET    XGRS.process_flag  = 6
                   ,XGRS.error_msg     = lt_error_message(i)
                   ,XGRS.request_id    = gn_child_request_id
             WHERE  XGRS.batch_id      = p_batch_id
             AND    XGRS.ROWID         = lt_error_rowid(i);
        END IF;
    CLOSE lcu_errored_records;
    

EXCEPTION
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error in process_transaction - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_po_receipts'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        IF lcu_transaction_data%ISOPEN
        THEN
            CLOSE lcu_transaction_data;
        END IF;
END process_po_receipts;


PROCEDURE process_rtv_transaction(
                               x_errbuf      OUT  NOCOPY  VARCHAR2
                              ,x_retcode     OUT  NOCOPY  VARCHAR2
                              ,p_batch_id    IN           NUMBER
                             )
IS
---------------------------
--Declaring Local Variables
---------------------------
EX_TRANS_WORK                  EXCEPTION;
ln_load_batch_id               NUMBER;
ln_trans_work_request_id       fnd_concurrent_requests.request_id%type;
ln_request_count               PLS_INTEGER   :=0;
lc_phase                       fnd_concurrent_requests.phase_code%type;
lx_errbuf                      VARCHAR2(2000);
lx_retcode                     VARCHAR2(20);

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE transaction_record_tbl_typ IS TABLE OF xx_gi_rcv_stg%rowtype
INDEX BY BINARY_INTEGER;
lt_transaction_record transaction_record_tbl_typ;

TYPE source_code_tbl_typ IS TABLE OF xx_gi_rcv_stg.receipt_source_code%type
INDEX BY BINARY_INTEGER;
lt_source_code_tbl_typ source_code_tbl_typ;

TYPE control_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.control_id%type
INDEX BY BINARY_INTEGER;
lt_control_id control_id_tbl_typ;
lt_success_control_id control_id_tbl_typ;
lt_error_control_id control_id_tbl_typ;

TYPE inventory_item_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.item_id%type
INDEX BY BINARY_INTEGER;
lt_inventory_item_id inventory_item_id_tbl_typ;

TYPE sku_tbl_typ IS TABLE OF xx_gi_rcv_stg.item_segment1%type
INDEX BY BINARY_INTEGER;
lt_sku sku_tbl_typ;

TYPE organization_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.organization_id%type
INDEX BY BINARY_INTEGER;
lt_organization_id organization_id_tbl_typ;

TYPE ship_qty_tbl_typ IS TABLE OF xx_gi_rcv_stg.quantity%type
INDEX BY BINARY_INTEGER;
lt_ship_qty ship_qty_tbl_typ;

TYPE transaction_uom_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_uom%type
INDEX BY BINARY_INTEGER;
lt_transaction_uom transaction_uom_tbl_typ;

TYPE transaction_date_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_date%type
INDEX BY BINARY_INTEGER;
lt_transaction_date transaction_date_tbl_typ;

TYPE subinventory_code_tbl_typ IS TABLE OF xx_gi_rcv_stg.subinventory%type
INDEX BY BINARY_INTEGER;
lt_subinventory_code subinventory_code_tbl_typ;

TYPE transaction_type_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_type_id%type
INDEX BY BINARY_INTEGER;
lt_transaction_type_id transaction_type_id_tbl_typ;

TYPE license_plate_tbl_typ IS TABLE OF xx_gi_rcv_stg.license_plate_number%type
INDEX BY BINARY_INTEGER;
lt_license_plate license_plate_tbl_typ;

TYPE extended_cost_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_cost%type
INDEX BY BINARY_INTEGER;
lt_extended_cost extended_cost_tbl_typ;

TYPE ship_to_location_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.ship_to_location_id%type
INDEX BY BINARY_INTEGER;
lt_ship_to_location_id ship_to_location_id_tbl_typ;

TYPE transfer_organization_tbl_typ IS TABLE OF xx_gi_rcv_stg.to_organization_id%type
INDEX BY BINARY_INTEGER;
lt_transfer_organization transfer_organization_tbl_typ;

TYPE transfer_nbr_tbl_typ IS TABLE OF xx_gi_rcv_stg.shipment_num%type
INDEX BY BINARY_INTEGER;
lt_transfer_nbr transfer_nbr_tbl_typ;

TYPE charge_acct_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.charge_account_id%type
INDEX BY BINARY_INTEGER;
lt_charge_account_id charge_acct_id_tbl_typ;

TYPE from_loc_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.attribute1%type
INDEX BY BINARY_INTEGER;
lt_from_loc_id from_loc_id_tbl_typ;

TYPE to_loc_id_tbl_typ IS TABLE OF xx_gi_rcv_stg.attribute2%type
INDEX BY BINARY_INTEGER;
lt_to_loc_id to_loc_id_tbl_typ;

TYPE comments_tbl_typ IS TABLE OF xx_gi_rcv_stg.comments%type
INDEX BY BINARY_INTEGER;
lt_comments comments_tbl_typ;

TYPE tran_ref_tbl_typ IS TABLE OF xx_gi_rcv_stg.transaction_reference%type
INDEX BY BINARY_INTEGER;
lt_tran_ref tran_ref_tbl_typ;

TYPE error_message_tbl_typ IS TABLE OF xx_gi_rcv_stg.error_msg%type
INDEX BY BINARY_INTEGER;
lt_error_message error_message_tbl_typ;

TYPE trans_work_request_id_tbl_typ IS TABLE OF mtl_transactions_interface.request_id%type
INDEX BY BINARY_INTEGER;
lt_trans_work_request_id trans_work_request_id_tbl_typ;

TYPE attribute_tbl_typ IS TABLE OF mtl_transactions_interface.attribute1%type
INDEX BY BINARY_INTEGER;
lt_attribute_category       attribute_tbl_typ;
lt_attribute1               attribute_tbl_typ;
lt_attribute2               attribute_tbl_typ;
lt_attribute3               attribute_tbl_typ;
lt_attribute4               attribute_tbl_typ;
lt_attribute5               attribute_tbl_typ;
lt_attribute6               attribute_tbl_typ;
lt_attribute7               attribute_tbl_typ;
lt_attribute8               attribute_tbl_typ;
lt_attribute9               attribute_tbl_typ;
lt_attribute10              attribute_tbl_typ;
lt_attribute11              attribute_tbl_typ;
lt_attribute12              attribute_tbl_typ;
lt_attribute13              attribute_tbl_typ;
lt_attribute14              attribute_tbl_typ;
lt_attribute15              attribute_tbl_typ;

TYPE rowid_tbl_typ IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_success_rowid      rowid_tbl_typ;
lt_error_rowid        rowid_tbl_typ;

-----------------------------------------------------------------------
--Cursor to fetch Successfully validated records for a particular batch
-----------------------------------------------------------------------
CURSOR lcu_transaction_data
IS
SELECT XGITIS.*
FROM   xx_gi_rcv_stg XGITIS
WHERE  XGITIS.batch_id   = p_batch_id
AND    XGITIS.process_flag    = 4;

------------------------------------------------
--Cursor to fetch successful transaction records
------------------------------------------------
CURSOR lcu_success_records
IS
SELECT XGRS.control_id, XGRS.ROWID
FROM   xx_gi_rcv_stg XGRS
      ,mtl_material_transactions MMT
WHERE  MMT.source_line_id           =  XGRS.control_id
AND    XGRS.batch_id                =  p_batch_id
AND    XGRS.process_flag            =  4
--AND    XGRS.receipt_source_code     IN (G_SIV_SOURCE, G_WIV_SOURCE,G_RCC_SOURCE)
AND    MMT.request_id               >  gn_child_request_id;

------------------------------------------------
--Cursor to fetch errored transaction records
------------------------------------------------
CURSOR lcu_errored_records
IS
SELECT XGRS.control_id,MTI.error_explanation,XGRS.ROWID
FROM   xx_gi_rcv_stg XGRS
      ,mtl_transactions_interface MTI
WHERE  MTI.source_line_id           =  XGRS.control_id
AND    XGRS.batch_id                =  p_batch_id
AND    XGRS.process_flag            =  4
--AND    XGRS.receipt_source_code    IN (G_SIV_SOURCE, G_WIV_SOURCE,G_RCC_SOURCE)
AND    MTI.request_id               >  gn_child_request_id;

BEGIN
display_log('Start Processing');

-------------------------------------------------------------
--Fetching Successful records to insert 500 records at a time
-------------------------------------------------------------
    OPEN lcu_transaction_data;
    LOOP
    BEGIN
    FETCH lcu_transaction_data BULK COLLECT INTO lt_transaction_record LIMIT G_LIMIT_SIZE;

        EXIT WHEN lt_transaction_record.count =0;
        IF lt_transaction_record.count<>0 THEN
            FOR i IN lt_transaction_record.first..lt_transaction_record.count
            LOOP
                lt_source_code_tbl_typ(i)      :=lt_transaction_record(i).receipt_source_code;
                lt_control_id (i)              :=lt_transaction_record(i).control_id;
                lt_inventory_item_id(i)        :=lt_transaction_record(i).item_id;
                lt_sku(i)                      :=lt_transaction_record(i).item_segment1;
                lt_organization_id(i)          :=lt_transaction_record(i).organization_id;
                lt_ship_qty(i)                 :=lt_transaction_record(i).transaction_quantity;
                lt_transaction_uom(i)          :=lt_transaction_record(i).transaction_uom;
                lt_transaction_date(i)         :=lt_transaction_record(i).transaction_date;
                lt_subinventory_code(i)        :=lt_transaction_record(i).subinventory;
                lt_transaction_type_id(i)      :=lt_transaction_record(i).transaction_type_id;
                lt_charge_account_id(i)        :=lt_transaction_record(i).charge_account_id;
                lt_license_plate(i)            :=lt_transaction_record(i).license_plate_number;
                lt_extended_cost(i)            :=lt_transaction_record(i).transaction_cost;
                lt_ship_to_location_id(i)      :=lt_transaction_record(i).ship_to_location_id;
                lt_transfer_organization(i)    :=lt_transaction_record(i).to_organization_id;
                lt_transfer_nbr(i)             :=lt_transaction_record(i).shipment_num;
                lt_attribute_category(i)       :=lt_transaction_record(i).attribute_category;
                lt_from_loc_id(i)              :=lt_transaction_record(i).attribute1;
                lt_to_loc_id(i)                :=lt_transaction_record(i).attribute2;
                lt_transfer_nbr(i)             :=lt_transaction_record(i).shipment_num;
                lt_comments(i)                 :=lt_transaction_record(i).comments;
                lt_tran_ref(i)                 :=lt_transaction_record(i).transaction_reference;
                lt_attribute1(i)               :=lt_transaction_record(i).attribute1;
                lt_attribute2(i)               :=lt_transaction_record(i).attribute2;
                lt_attribute3(i)               :=lt_transaction_record(i).attribute3;
                lt_attribute4(i)               :=lt_transaction_record(i).attribute4;
                lt_attribute5(i)               :=lt_transaction_record(i).attribute5;
                lt_attribute6(i)               :=lt_transaction_record(i).attribute6;
                lt_attribute7(i)               :=lt_transaction_record(i).attribute7;
                lt_attribute8(i)               :=lt_transaction_record(i).attribute8;
                lt_attribute9(i)               :=lt_transaction_record(i).attribute9;
                lt_attribute10(i)              :=lt_transaction_record(i).attribute10;
                lt_attribute11(i)              :=lt_transaction_record(i).attribute11;
                lt_attribute12(i)              :=lt_transaction_record(i).attribute12;
                lt_attribute13(i)              :=lt_transaction_record(i).attribute13;
                lt_attribute14(i)              :=lt_transaction_record(i).attribute14;
                lt_attribute15(i)              :=to_char(p_batch_id);  --lt_transaction_record(i).attribute15;
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
            FORALL i in 1..lt_transaction_record.count
            INSERT INTO MTL_TRANSACTIONS_INTERFACE
            (
                SOURCE_CODE
               ,TRANSACTION_HEADER_ID
               ,SOURCE_LINE_ID
               ,SOURCE_HEADER_ID
               ,PROCESS_FLAG
               ,VALIDATION_REQUIRED
               ,TRANSACTION_MODE
               ,LAST_UPDATE_DATE
               ,LAST_UPDATED_BY
               ,CREATION_DATE
               ,CREATED_BY
               ,INVENTORY_ITEM_ID
               ,ITEM_SEGMENT1
               ,ORGANIZATION_ID
               ,TRANSACTION_QUANTITY
               ,TRANSACTION_UOM
               ,TRANSACTION_DATE
               ,SUBINVENTORY_CODE
               ,TRANSACTION_TYPE_ID
               ,TRANSACTION_REFERENCE
               ,TRANSACTION_COST
               --,SHIP_TO_LOCATION_ID
               --,TRANSFER_ORGANIZATION
               --,SHIPMENT_NUMBER
               ,DISTRIBUTION_ACCOUNT_ID
               ,ATTRIBUTE_CATEGORY
               ,ATTRIBUTE1
               ,ATTRIBUTE2
               ,ATTRIBUTE3
               ,ATTRIBUTE4               
               ,ATTRIBUTE5
               ,ATTRIBUTE6
               ,ATTRIBUTE7
               ,ATTRIBUTE8
               ,ATTRIBUTE9
               ,ATTRIBUTE10
               ,ATTRIBUTE11
               ,ATTRIBUTE12
               ,ATTRIBUTE13
               ,ATTRIBUTE14
               ,ATTRIBUTE15
            )
            VALUES
            (
                lt_source_code_tbl_typ(i)
               ,ln_load_batch_id
               ,lt_control_id (i)
               ,lt_control_id (i)
               ,G_PROCESS_FLAG
               ,G_VALIDATION_REQUIRED
               ,G_TRANSACTION_MODE
               ,SYSDATE
               ,G_USER_ID
               ,SYSDATE
               ,G_USER_ID
               ,lt_inventory_item_id(i)
               ,lt_sku(i)
               ,lt_organization_id(i)
               ,lt_ship_qty(i)
               ,lt_transaction_uom(i)
               ,lt_TRANSACTION_DATE(i)
               ,lt_subinventory_code(i)
               ,lt_transaction_type_id(i)
               ,lt_tran_ref(i)
               ,lt_extended_cost(i)
               --,lt_ship_to_location_id(i)
               --,lt_transfer_organization(i)
               --,lt_transfer_nbr(i)
               ,lt_charge_account_id(i)
               ,lt_attribute_category(i)
               ,lt_attribute1(i)
               ,lt_attribute2(i)
               ,lt_attribute3(i)
               ,lt_attribute4(i)
               ,lt_attribute5(i)
               ,lt_attribute6(i)
               ,lt_attribute7(i)
               ,lt_attribute8(i)
               ,lt_attribute9(i)
               ,lt_attribute10(i)
               ,lt_attribute11(i)
               ,lt_attribute12(i)
               ,lt_attribute13(i)
               ,lt_attribute14(i)
               ,lt_attribute15(i)
            );
        END IF;--lt_transaction_record.count<>0 THEN
        COMMIT;

        -------------------------------
        --Submitting Transaction Worker
        -------------------------------
        ln_trans_work_request_id:= fnd_request.submit_request (application       => 'INV'
                                                              ,program           => 'INCTCW'
                                                              ,description       => NULL
                                                              ,start_time        => NULL
                                                              ,sub_request       => FALSE
                                                              ,argument1         => ln_load_batch_id
                                                              ,argument2         => 1 --Interface Table
                                                              ,argument3         => NULL
                                                              ,argument4         => NULL
                                                              );
        display_log('Transaction Worker Submitted for Sub Batch '||ln_load_batch_id||' with request id '||ln_trans_work_request_id);
        IF ln_trans_work_request_id = 0 THEN
            RAISE EX_TRANS_WORK;
        END IF;
        ln_request_count:=ln_request_count+1;
        lt_trans_work_request_id(ln_request_count):=ln_trans_work_request_id;
        COMMIT;
    EXCEPTION
    WHEN EX_TRANS_WORK THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf   := 'Error while submitting transaction Worker - '||gc_sqlerrm;
        x_retcode  := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_transaction'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error while inserting records in interface table and invoking transaction worker - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_transaction'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END;
    END LOOP; --lcu_transaction_date
    CLOSE lcu_transaction_data;

    -------------------------------------------------------------------
    --Wait till all the Transaction Workers are complete for this Batch
    -------------------------------------------------------------------
    IF lt_trans_work_request_id.count <>0 THEN
    FOR i IN lt_trans_work_request_id.FIRST .. lt_trans_work_request_id.LAST
    LOOP
        LOOP
            SELECT FCR.phase_code
            INTO   lc_phase
            FROM   FND_CONCURRENT_REQUESTS FCR
            WHERE  FCR.request_id = lt_trans_work_request_id(i);
            IF  lc_phase = 'C' THEN
                EXIT;
            ELSE
                DBMS_LOCK.SLEEP(gn_sleep);
            END IF;
        END LOOP;
     END LOOP;
     END IF;

    -----------------------------------------------------------
    --Updating Process Flags for Successful Transaction Records
    -----------------------------------------------------------
    OPEN lcu_success_records;
    FETCH lcu_success_records BULK COLLECT INTO lt_success_control_id, lt_success_rowid;
        IF lt_success_control_id.COUNT>0 THEN
            FORALL i IN 1..lt_success_control_id.COUNT
            UPDATE xx_gi_rcv_stg XGRS
            SET    XGRS.PROCESS_FLAG = 7
                  ,XGRS.request_id   = gn_child_request_id
            WHERE  XGRS.ROWID=lt_success_rowid(i);
        END IF;
    CLOSE lcu_success_records;

    ------------------------------------------------
    --Logging Errors for Errored Transaction Records
    ------------------------------------------------
    OPEN lcu_errored_records;
    FETCH lcu_errored_records BULK COLLECT INTO lt_error_control_id, lt_error_message, lt_error_rowid;
        IF lt_error_control_id.COUNT > 0 THEN
            FOR i IN 1..lt_error_control_id.COUNT
            LOOP
                bulk_log_error( p_error_msg            =>  lt_error_message(i)
                               ,p_error_code           =>  NULL
                               ,p_control_id           =>  lt_error_control_id(i)
                               ,p_request_id           =>  gn_child_request_id
                               ,p_converion_id         =>  gn_conversion_id
                               ,p_package_name         =>  G_PACKAGE_NAME
                               ,p_procedure_name       =>  'process_transaction'
                               ,p_staging_table_name   =>  G_STAGING_TBL
                               ,p_batch_id             =>  p_batch_id
                               ,p_staging_column_name  =>  NULL
                               ,p_staging_column_value =>  NULL
                              );
            END LOOP;
            XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
             --------------------------------------------------------
             --Updating Process Flags for Errored Transaction Records
             --------------------------------------------------------
             FORALL i IN 1..lt_error_control_id.COUNT
             UPDATE xx_gi_rcv_stg XGRS
             SET    XGRS.process_flag  = 6
                   ,XGRS.error_msg     = lt_error_message(i)
                   ,XGRS.request_id    = gn_child_request_id
             WHERE  XGRS.batch_id      = p_batch_id
             AND    XGRS.ROWID         = lt_error_rowid(i);
        END IF;
    CLOSE lcu_errored_records;
    
    
    --------------------------------------------------------
    --Processing the expected receipt records
    --------------------------------------------------------
         process_expected_receipts(x_errbuf      => lx_errbuf
                                  ,x_retcode     => lx_retcode
                                  ,p_batch_id    => p_batch_id
                                  );    

EXCEPTION
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error in process_transaction - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  gn_child_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_transaction'
                       ,p_staging_table_name   =>  G_STAGING_TBL
                       ,p_batch_id             =>  p_batch_id
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        IF lcu_transaction_data%ISOPEN
        THEN
            CLOSE lcu_transaction_data;
        END IF;
END process_rtv_transaction;





-- +===================================================================+
-- | Name        :  child_main                                         |
-- | Description :  This procedure is invoked from the OD: GI Receipts |
-- |                Conversion Child                                   |
-- |                Concurrent Request.This would                      |
-- |                submit conversion programs based on input    .     |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                p_batch_id                                         |
-- |                p_debug_flag                                       |
-- |                p_sleep_time                                       |
-- |                p_max_wait_time                                    |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE child_main(
                     x_errbuf              OUT NOCOPY VARCHAR2
                    ,x_retcode             OUT NOCOPY VARCHAR2
                    ,p_validate_only_flag  IN         VARCHAR2
                    ,p_reset_status_flag   IN         VARCHAR2
                    ,p_batch_id            IN         NUMBER
                    ,p_debug_flag          IN         VARCHAR2
                    ,p_sleep_time          IN         NUMBER
                    ,p_max_wait_time       IN         NUMBER
                    ,p_conversion_type     IN         VARCHAR2
                    )
IS
------------------------------------------
--Declaring Local Variables and Exceptions
------------------------------------------
EX_ENTRY_EXCEP              EXCEPTION;

lx_errbuf                   VARCHAR2(2000);
lx_retcode                  VARCHAR2(20);
ln_trans_processed          PLS_INTEGER;
ln_trans_failed             PLS_INTEGER;
ln_trans_invalid            PLS_INTEGER;
ln_request_id               PLS_INTEGER;
ln_trans_total              PLS_INTEGER;

--------------------------------------------------------
--Cursor to get the Control Information for Transactions
--------------------------------------------------------
CURSOR lcu_trans_info (p_batch_id IN NUMBER)
IS
SELECT COUNT (CASE WHEN process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='6' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='7' THEN 1 END)
FROM   XX_GI_RCV_STG XGRS
WHERE  XGRS.batch_id = p_batch_id
AND    XGRS.request_id    = gn_child_request_id;

BEGIN
    BEGIN
        display_log('*Batch_id* '||p_batch_id);
        gn_debug_flag              :=  p_debug_flag;
        gn_max_wait_time           :=  p_max_wait_time;
        gn_sleep                   :=  p_sleep_time;
        gn_child_request_id        :=  fnd_global.conc_request_id;

        IF  NVL(p_reset_status_flag,'N') = 'Y' THEN
                    update_batch_id ( x_errbuf
                                     ,x_retcode
                                     ,p_batch_id
                                     ,p_conversion_type
                                    );
        END IF;
        ------------------------------
        --Initializing local variables
        ------------------------------
        ln_trans_total          :=0;
        ln_trans_processed      :=0;
        ln_trans_failed         :=0;
        ln_trans_invalid        :=0;

        ---------------------------------------------------
        --Calling validate_transaction for Data Validations
        ---------------------------------------------------
        validate_transaction(
                             x_errbuf                  =>lx_errbuf
                            ,x_retcode                 =>lx_retcode
                            ,p_batch_id                =>p_batch_id
                            );
        IF lx_retcode <> 0 THEN
            x_retcode := lx_retcode;
            CASE WHEN x_errbuf IS NULL
            THEN x_errbuf  := lx_errbuf;
            ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
            END CASE;
        END IF;

        ---------------------------------------------
        --Processing data if p_validate_only_flag='N'
        ---------------------------------------------
        IF p_validate_only_flag= 'N' THEN
            lx_errbuf     := NULL;
            lx_retcode    := NULL;
            
            IF p_conversion_type = 'INVENTORY' THEN
                process_transaction(
                                     x_errbuf                   =>lx_errbuf
                                    ,x_retcode                  =>lx_retcode
                                    ,p_batch_id                 =>p_batch_id
                                   );
            ELSIF p_conversion_type = 'VENDOR' THEN
                process_po_receipts(
                                     x_errbuf                   =>lx_errbuf
                                    ,x_retcode                  =>lx_retcode
                                    ,p_batch_id                 =>p_batch_id
                                   );
            
            ELSIF p_conversion_type = 'RTV' THEN
                process_rtv_transaction(
                                     x_errbuf                   =>lx_errbuf
                                    ,x_retcode                  =>lx_retcode
                                    ,p_batch_id                 =>p_batch_id
                                   );
            END IF; --end checking conversion type
            
            IF lx_retcode <> 0 THEN
                x_retcode := lx_retcode;
                CASE WHEN x_errbuf IS NULL
                THEN x_errbuf  := lx_errbuf;
                ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
                END CASE;
            END IF;
        END IF;
    EXCEPTION
        WHEN EX_HANDLE_SUB_OTHERS THEN
            x_retcode := lx_retcode;
            CASE WHEN x_errbuf IS NULL
            THEN x_errbuf  := gc_sqlerrm;
            ELSE x_errbuf  := x_errbuf||'/'||gc_sqlerrm;
            END CASE;
        WHEN OTHERS THEN
            x_retcode := 2;
            bulk_log_error(
                            p_error_msg            =>  SQLERRM
                           ,p_error_code           =>  SQLCODE
                           ,p_control_id           =>  NULL
                           ,p_request_id           =>  gn_child_request_id
                           ,p_converion_id         =>  gn_conversion_id
                           ,p_package_name         =>  G_PACKAGE_NAME
                           ,p_procedure_name       =>  'child_main'
                           ,p_staging_table_name   =>  NULL
                           ,p_batch_id             =>  p_batch_id
                           ,p_staging_column_name  =>  NULL
                           ,p_staging_column_value =>  NULL
                          );
    END;
    -------------------------------------------------------------
    --Getting the Master Request Id to update Control Information
    -------------------------------------------------------------
    get_master_request_id(
                          p_conversion_id     => gn_conversion_id
                         ,p_batch_id          => p_batch_id
                         ,x_master_request_id => ln_request_id
                         );
    IF ln_request_id IS NOT NULL THEN

        --------------------------------------------------------------------------
        --Fetching Number of Invalid, Processing Failed and Processed Transactions
        --------------------------------------------------------------------------
        OPEN lcu_trans_info(p_batch_id);
        FETCH lcu_trans_info INTO ln_trans_invalid,ln_trans_failed,ln_trans_processed;
        CLOSE lcu_trans_info;

        ----------------------------------
        --Updating the Control Information
        ----------------------------------
        XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                                                        p_conc_mst_req_id             => ln_request_id
                                                       ,p_batch_id                    => p_batch_id
                                                       ,p_conversion_id               => gn_conversion_id
                                                       ,p_num_bus_objs_failed_valid   => ln_trans_invalid
                                                       ,p_num_bus_objs_failed_process => ln_trans_failed
                                                       ,p_num_bus_objs_succ_process   => ln_trans_processed
                                                      );
    END IF;

    -------------------------------------------------
    -- Launch the Exception Log Report for this batch
    -------------------------------------------------
    lx_errbuf     := NULL;
    lx_retcode    := NULL;
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

    ---------------------------------------------------------
    --Displaying the Trsansaction Information in the Out file
    ---------------------------------------------------------
    ln_trans_total := ln_trans_invalid + ln_trans_failed + ln_trans_processed;
    display_out(RPAD('=',58,'='));
    display_out(RPAD('Total No. Of Transaction Records                : ',56,' ')||RPAD(ln_trans_total,9,' '));
    display_out(RPAD('No. Of Transaction Records Processed            : ',56,' ')||RPAD(ln_trans_processed,9,' '));
    display_out(RPAD('No. Of Transaction Records Errored              : ',56,' ')||RPAD(ln_trans_failed,9,' '));
    display_out(RPAD('No. Of Transaction Records Failed Validation    : ',56,' ')||RPAD(ln_trans_invalid,9,' '));
    display_out(RPAD('=',58,'='));

EXCEPTION
    WHEN OTHERS THEN
        x_errbuf  := 'Unexpected error in child_main - '||SQLERRM;
        x_retcode := 2;
        bulk_log_error(  p_error_msg            =>  SQLERRM
                        ,p_error_code           =>  SQLCODE
                        ,p_control_id           =>  NULL
                        ,p_request_id           =>  gn_child_request_id
                        ,p_converion_id         =>  gn_conversion_id
                        ,p_package_name         =>  G_PACKAGE_NAME
                        ,p_procedure_name       =>  'child_main'
                        ,p_staging_table_name   =>  NULL
                        ,p_batch_id             =>  p_batch_id
                        ,p_staging_column_name  =>  NULL
                        ,p_staging_column_value =>  NULL
                       );
END child_main;

END XX_GI_RCV_CONV_PKG_BK; 
/
SHOW ERRORS;

EXIT;