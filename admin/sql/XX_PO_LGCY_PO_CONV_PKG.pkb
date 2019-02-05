SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_LGCY_PO_CONV_PKG
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                Oracle NAIO Consulting Organization                            |
-- +===============================================================================+
-- | Name        :  XX_PO_LGCY_PO_CONV_PKG.pkb                                     |
-- | Description :  This package read and batch the records. It submits a child    |
-- |                concurrent program for each batch for the further processing.  |
-- |                This package also invokes the standard Purchase Order import   |
-- |                concurrent program to populate the data into EBS base tables.  |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date           Author                      Remarks                   |
-- |========  =========== ================== ======================================|
-- |DRAFT 1a  09-MAY-2007  Seemant Gour         Initial draft version              |
-- |Draft 1B  18-JUN-2007  Ritu Shukla                                             |
-- |Draft 1C  28-JUN-2007  Ritu Shukla          TL Review Comments                 |
-- | 1.0      17-JUL-2007  Ritu Shukla          Included Debug_flag,record id      |
-- |                                            linking                            |
-- | 1.1      04-SEP-2007  Ritu Shukla          Changed Query to link Quotation    |
-- | 1.2      24-SEP-2007  Remya Sasi           Changed G_SLEEP and G_MAX_WAIT_TIME|
-- |                                            values to 0                        |
-- | 1.3      09-OCT-2007  Remya Sasi           Changed cursor lcu_ship_to_location|
-- | 1.4      29-OCT-2007  Vikas Raina          Updated for PO's belonging to      |
-- |                                            different OU                       |
-- +===============================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------
G_SLEEP                     CONSTANT PLS_INTEGER                                           := 0; -- Changed from 60 by Remya, V1.2
G_MAX_WAIT_TIME             CONSTANT PLS_INTEGER                                           := 0; -- Changed from 300 by Remya, V1.2
G_USER_ID                   CONSTANT po_headers_interface.created_by%TYPE                  := FND_GLOBAL.user_id;
G_CONVERSION_CODE           CONSTANT xx_com_conversions_conv.conversion_code%TYPE          := 'C0106_PurchaseOrders';
G_COMM_APPLICATION          CONSTANT VARCHAR2(10)                                          := 'XXCOMN';
G_SUMM_PROGRAM              CONSTANT VARCHAR2(50)                                          := 'XXCOMCONVSUMMREP';
G_EXCEP_PROGRAM             CONSTANT VARCHAR2(50)                                          := 'XXCOMCONVEXPREP';
G_DESTINATION_TYPE_CODE     CONSTANT po_distributions_interface.destination_type_code%TYPE := 'INVENTORY';
G_PACKAGE_NAME              CONSTANT VARCHAR2(50)                                          := 'XX_PO_LGCY_PO_CONV_PKG';
G_HDR_TABLE_NAME            CONSTANT VARCHAR2(50)                                          := 'XX_PO_HDRS_CONV_STG';
G_LINE_TABLE_NAME           CONSTANT VARCHAR2(50)                                          := 'XX_PO_LINES_CONV_STG';

-------------------------------------------------
--Declaring Global Exception and Global Variables
-------------------------------------------------
gn_interface_source_code    po_headers_interface.interface_source_code%TYPE;
gn_batch_size               PLS_INTEGER                                                 :=5000;
gn_batch_count              PLS_INTEGER                                                 := 0;
gn_record_count             PLS_INTEGER                                                 := 0;
gn_index_request_id         PLS_INTEGER                                                 := 0;
gn_max_child_req            PLS_INTEGER ;
gn_conversion_id            xx_com_exceptions_log_conv.converion_id%TYPE;
gn_request_id               fnd_concurrent_requests.request_id%TYPE ;
gc_sqlerrm                  VARCHAR2(5000);
gc_sqlcode                  VARCHAR2(20);
gc_debug_flag               VARCHAR2(1);

---------------------------------------------------
--Declaring record variable for logging bulk errors
---------------------------------------------------
gr_po_err_rec         xx_com_exceptions_log_conv%ROWTYPE;
gr_po_err_empty_rec   xx_com_exceptions_log_conv%ROWTYPE;

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
    IF nvl(gc_debug_flag,'N') ='Y' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
    END IF;
END;

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
END;

-- +====================================================================+
-- | Name        :  bulk_log_error                                      |
-- | Description :  This procedure is invoked to insert errors into     |
-- |                xx_com_exceptions_log_conv                          |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
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
                         ,p_staging_column_name   IN VARCHAR2
                         ,p_staging_column_value  IN VARCHAR2
                         ,p_batch_id              IN NUMBER
                       )

IS
BEGIN
    ------------------------------------
    --Initializing the error record type
    ------------------------------------
    gr_po_err_rec                     :=  gr_po_err_empty_rec;
    ------------------------------------------------------
    --Assigning values to the columns of error record type
    ------------------------------------------------------
    gr_po_err_rec.oracle_error_msg     :=  p_error_msg;
    gr_po_err_rec.oracle_error_code    :=  p_error_code;
    gr_po_err_rec.record_control_id    :=  p_control_id;
    gr_po_err_rec.request_id           :=  p_request_id;
    gr_po_err_rec.converion_id         :=  p_converion_id;
    gr_po_err_rec.package_name         :=  p_package_name;
    gr_po_err_rec.procedure_name       :=  p_procedure_name;
    gr_po_err_rec.staging_table_name   :=  p_staging_table_name;
    gr_po_err_rec.staging_column_name  :=  p_staging_column_name;
    gr_po_err_rec.staging_column_value :=  p_staging_column_value;
    gr_po_err_rec.batch_id             :=  p_batch_id;

    XX_COM_CONV_ELEMENTS_PKG.bulk_add_message(gr_po_err_rec);
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
ln_header_count     PLS_INTEGER;
ln_line_count       PLS_INTEGER;
ln_conc_request_id  FND_CONCURRENT_REQUESTS.request_id%TYPE;

BEGIN
    SELECT XX_PO_POCONV_BATCHID_S.NEXTVAL
    INTO   ln_seq
    FROM   DUAL;

    -----------------------------------------------------------------------
    --Updating PO Header Staging table with load batch id and process flags
    -----------------------------------------------------------------------
    UPDATE xx_po_hdrs_conv_stg XPHCS
    SET    XPHCS.batch_id = ln_seq
          ,XPHCS.process_flag = 2
    WHERE  XPHCS.batch_id IS NULL
    AND    XPHCS.process_flag = 1
    AND    ROWNUM<=gn_batch_size;

    ---------------------------------------------------------
    --Fetching Count of Eligible Records in the Staging Table
    ---------------------------------------------------------
    ln_header_count := SQL%ROWCOUNT;

    ---------------------------------------------------------------------
    --Updating PO Line Staging table with load batch id and process flags
    ---------------------------------------------------------------------
    UPDATE xx_po_lines_conv_stg XPLCS
    SET    XPLCS.batch_id = ln_seq
          ,XPLCS.process_flag = 2
    WHERE  XPLCS.batch_id IS NULL
    AND    XPLCS.process_flag = 1
    AND    XPLCS.parent_record_id IN (SELECT XPHCS.record_id
                                         FROM   xx_po_hdrs_conv_stg XPHCS
                                         WHERE  XPHCS.batch_id=ln_seq
                                     );


    ---------------------------------------------------------
    --Fetching Count of Eligible Records in the Staging Table
    ---------------------------------------------------------
    ln_line_count := SQL%ROWCOUNT;

    COMMIT;

    ---------------------------------------------------------------------------------------------
    --Initializing the batch size count ,record count variables and taking next value of sequence
    ---------------------------------------------------------------------------------------------
    ln_batch_size_count := ln_header_count;
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
                                                              application => 'PO'
                                                             ,program     => 'XX_PO_CONV_CHILD_MAIN'
                                                             ,sub_request => FALSE
                                                             ,argument1   => p_validate_only_flag
                                                             ,argument2   => p_reset_status_flag
                                                             ,argument3   => ln_seq
                                                             ,argument4   => gc_debug_flag
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
            END IF;
        ELSE
            DBMS_LOCK.SLEEP(G_SLEEP);
        END IF;

    END LOOP;
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
-- +====================================================================+
PROCEDURE update_batch_id( x_errbuf   OUT NOCOPY VARCHAR2
                          ,x_retcode  OUT NOCOPY VARCHAR2
                          ,p_batch_id IN         NUMBER
                         )
IS
BEGIN
    -------------------------------------------------------
    --Updating Process Flag for Reprocessing for PO Headers
    -------------------------------------------------------
    UPDATE XX_PO_HDRS_CONV_STG XPHCS
    SET    XPHCS.batch_id = p_batch_id
          ,XPHCS.process_flag = 1
    WHERE  XPHCS.process_flag IN (2,3,4,6)
    AND    XPHCS.batch_id=nvl(p_batch_id,XPHCS.batch_id);

    -----------------------------------------------------
    --Updating Process Flag for Reprocessing for PO Lines
    -----------------------------------------------------

    UPDATE XX_PO_LINES_CONV_STG XPLCS
    SET    XPLCS.batch_id = p_batch_id
          ,XPLCS.process_flag = 1
    WHERE  XPLCS.process_flag IN (2,3,4,6)
    AND    XPLCS.batch_id=nvl(p_batch_id,XPLCS.batch_id);

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
    IF gt_req_id.FIRST IS NOT NULL AND gt_req_id.LAST IS NOT NULL THEN
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
    END IF;

    ----------------------------------------------
    --Submitting the Summary Report for each batch
    ----------------------------------------------
    ln_summ_request_id := FND_REQUEST.submit_request(
                                                      application => G_COMM_APPLICATION
                                                     ,program     => G_SUMM_PROGRAM
                                                     ,sub_request => FALSE               -- TRUE means is a sub request
                                                     ,argument1   => G_CONVERSION_CODE   -- CONVERSION_CODE
                                                     ,argument2   => FND_GLOBAL.conc_request_id                -- MASTER REQUEST ID
                                                     ,argument3   => NULL                -- REQUEST ID
                                                     ,argument4   => NULL                -- BATCH ID
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
END launch_summary_report;

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
                                   p_batch_id         IN         NUMBER
                                  ,p_conc_req_id      IN         NUMBER
                                  ,p_master_req_id    IN         NUMBER --16 Jul
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
                       ,p_request_id           =>  fnd_global.conc_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'launch_exception_report'
                       ,p_staging_table_name   =>  G_HDR_TABLE_NAME
                       ,p_staging_column_name  =>  NULL  
                       ,p_staging_column_value =>  NULL 
                       ,p_batch_id             =>  p_batch_id
                      );
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
ln_batch_size        PLS_INTEGER;
ln_max_child_req     PLS_INTEGER;
lc_return_status     VARCHAR2(03);
lc_launch            VARCHAR2(02) := 'N';

BEGIN

    ---------------------------
    --Getting the Conversion id
    ---------------------------
    get_conversion_id(
                       x_conversion_id  => gn_conversion_id
                      ,x_batch_size     => ln_batch_size
                      ,x_max_threads    => ln_max_child_req
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
            FROM   xx_po_hdrs_conv_stg XPHCS
            WHERE  XPHCS.batch_id IS NULL
            AND    XPHCS.process_flag = 1;
            IF (ln_current_count >= gn_batch_size ) THEN
                bat_child(
                           p_request_id          => gn_request_id
                          ,p_validate_only_flag  => p_validate_only_flag
                          ,p_reset_status_flag   => p_reset_status_flag
                          ,x_time                => ld_check_time
                          ,x_errbuf              => x_errbuf
                          ,x_retcode             => x_retcode
                         );
                lc_launch := 'Y';
            ELSE
                IF  ln_last_count = ln_current_count   THEN
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
        IF (ln_current_count <> 0  )THEN
            bat_child(
                       p_request_id          => gn_request_id
                      ,p_validate_only_flag  => p_validate_only_flag
                      ,p_reset_status_flag   => p_reset_status_flag
                      ,x_time                => ld_check_time
                      ,x_errbuf              => x_errbuf
                      ,x_retcode             => x_retcode
                     );
            lc_launch := 'Y';
        END IF;

        IF  lc_launch = 'N' THEN
            display_log('No Data Found in the Table XX_PO_HDRS_CONV_STG');
            x_retcode := 1;
        ELSE
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
                                   ,FND_GLOBAL.conc_request_id -- Master Request id
                                   ,x_errbuf
                                   ,x_retcode
                                  );

        END IF;

        --------------------------------------------------------------------------------
    --Displaying the Batch and Item Information in the output file of Matser Program
        --------------------------------------------------------------------------------
        display_out(RPAD('=',38,'='));
        display_out(RPAD('Batch Size                 : ',29,' ')||RPAD(gn_batch_size,9,' '));
        display_out(RPAD('Number of Batches Launched : ',29,' ')||RPAD(gn_batch_count,9,' '));
        display_out(RPAD('Number of Header Records   : ',29,' ')||RPAD(gn_record_count,9,' '));
        display_out(RPAD('=',38,'='));
    ELSE
        RAISE EX_NO_ENTRY;
    END IF; -- lc_return_status

EXCEPTION
    WHEN EX_NO_ENTRY THEN
        x_retcode := 1;
    WHEN OTHERS THEN
        x_retcode := 2;
        display_log ('Unexpected error in submit_sub_request - '||SQLERRM);
END submit_sub_requests;


-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: PO Purchase  |
-- |                Order Conversion Master Concurrent Request.This     |
-- |                would submit child programs based on batch_size     |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_validate_omly_flag                                |
-- |                p_reset_status_flag                                 |
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
                      ,p_batch_size          IN         NUMBER
                      ,p_max_thread          IN         NUMBER
                      ,p_debug_flag          IN         VARCHAR2
                     )
IS
------------------------------------------
--Declaring Local Variables and Exceptions
------------------------------------------
EX_SUB_REQ       EXCEPTION;
lc_request_data  VARCHAR2(1000);
lc_error_message VARCHAR2(4000);
ln_return_status PLS_INTEGER;

BEGIN

    -------------------------------------------------------------
    --Submitting Sub Requests corresponding to the Child Programs
    -------------------------------------------------------------
    gc_debug_flag    := p_debug_flag;
    gn_batch_size    := p_batch_size;
    gn_max_child_req := p_max_thread;
    gn_request_id    := FND_GLOBAL.CONC_REQUEST_ID;
    submit_sub_requests(
                         p_validate_only_flag
                        ,p_reset_status_flag
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
        x_errbuf  := 'Unexpected error in master_main procedure - '||SQLERRM;
END master_main;

-- +====================================================================+
-- | Name        :  validate_po                                         |
-- | Description :  This procedure is invoked from the child_main. This |
-- |                would do all header and line level validations      |
-- |                for the batch passed as a parameter                 |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_validate_omly_flag                                |
-- |                p_reset_status_flag                                 |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+

PROCEDURE validate_po(
                       x_errbuf                  OUT NOCOPY VARCHAR2
                      ,x_retcode                 OUT NOCOPY VARCHAR2
                      ,p_batch_id                IN NUMBER
                     )
IS

------------------------------------------
--Declaring local Variables and Exceptions
------------------------------------------
EX_TRANSACTION_NO_DATA           EXCEPTION;
EX_ENTRY_EXCEP                   EXCEPTION;
ln_agent_id                      po_headers_interface.agent_id%type;
ln_batch_size                    PLS_INTEGER;
ln_max_child_req                 PLS_INTEGER;
ln_process_flag                  PLS_INTEGER;
lc_return_status                 VARCHAR2(1);
lc_agent_flag                    VARCHAR2(1);
lc_vendor_flag                   VARCHAR2(1);
lc_ship_to_location_flag         VARCHAR2(1);
lc_ship_to_location_line_flag    VARCHAR2(1);
lc_ship_to_Organization_flag     VARCHAR2(1);
lc_no_line_flag                  VARCHAR2(1);
lc_inventory_flag                VARCHAR2(1);
lc_error_message                 VARCHAR2(2000);
lc_header_message                VARCHAR2(4000);
lc_line_message                  VARCHAR2(4000);
ln_vendor_id                     po_headers_interface.vendor_id%type;
ln_vendor_site_id                po_headers_interface.vendor_site_id%type;
ln_org_id                        po_headers_interface.org_id%type;
ln_ship_to_location_id           po_headers_interface.ship_to_location_id%type;
ln_ship_to_organization_id       po_lines_interface.ship_to_organization_id%type;
ln_interface_header_id           po_headers_interface.interface_header_id%type;
ln_interface_line_id             po_lines_interface.interface_line_id%type;
ln_inventory_item_id             po_lines_interface.item_id%type;

--------------------------------
--Declaring table type variables
--------------------------------
TYPE po_control_id_tbl_type IS TABLE OF xx_po_hdrs_conv_stg.control_id%type
INDEX BY BINARY_INTEGER;
lt_po_control_id po_control_id_tbl_type;
lt_po_line_control_id po_control_id_tbl_type;

TYPE agent_id_tbl_type IS TABLE OF xx_po_hdrs_conv_stg.agent_id%type
INDEX BY BINARY_INTEGER;
lt_agent_id agent_id_tbl_type;

TYPE vendor_id_tbl_type IS TABLE OF po_headers_interface.vendor_id%type
INDEX BY BINARY_INTEGER;
lt_vendor_id vendor_id_tbl_type;

TYPE vendor_site_id_tbl_type IS TABLE OF po_headers_interface.vendor_site_id%type
INDEX BY BINARY_INTEGER;
lt_vendor_site_id vendor_site_id_tbl_type;

TYPE org_id_tbl_type IS TABLE OF po_headers_interface.org_id%type
INDEX BY BINARY_INTEGER;
lt_org_id org_id_tbl_type;

TYPE ship_to_location_id_tbl_type IS TABLE OF po_headers_interface.ship_to_location_id%type
INDEX BY BINARY_INTEGER;
lt_ship_to_location_id ship_to_location_id_tbl_type;
lt_ship_to_location_line_id ship_to_location_id_tbl_type;

TYPE ship_to_org_id_tbl_type IS TABLE OF po_lines_interface.ship_to_organization_id%type
INDEX BY BINARY_INTEGER;
lt_ship_to_organization_id ship_to_org_id_tbl_type;

TYPE interface_header_id_tbl_type IS TABLE OF po_headers_interface.interface_header_id%type
INDEX BY BINARY_INTEGER;
lt_interface_header_id interface_header_id_tbl_type;

TYPE inventory_item_id_tbl_type IS TABLE OF po_lines_interface.item_id%type
INDEX BY BINARY_INTEGER;
lt_inventory_item_id inventory_item_id_tbl_type;

TYPE interface_line_id_tbl_type IS TABLE OF po_lines_interface.interface_line_id%type
INDEX BY BINARY_INTEGER;
lt_interface_line_id interface_line_id_tbl_type;

TYPE po_line_num_tbl_type IS TABLE OF po_lines_interface.line_num%type
INDEX BY BINARY_INTEGER;
lt_po_line_num po_line_num_tbl_type;

TYPE process_flag_tbl_typ IS TABLE OF xx_po_hdrs_conv_stg.process_flag%type
INDEX BY BINARY_INTEGER;
lt_process_flag process_flag_tbl_typ;

TYPE po_lgcy_intf_line_id_tbl_typ IS TABLE OF xx_po_lines_conv_stg.interface_line_id%type
INDEX BY BINARY_INTEGER;
lt_po_lgcy_intf_line_id po_lgcy_intf_line_id_tbl_typ;

TYPE error_message_tbl_typ IS TABLE OF xx_po_lines_conv_stg.error_message%type
INDEX BY BINARY_INTEGER;
lt_header_error_message error_message_tbl_typ;
lt_line_error_message error_message_tbl_typ;

TYPE rowid_tbl_typ IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_header_rowid rowid_tbl_typ;
lt_line_rowid rowid_tbl_typ;

-------------------------------------
--Cursor to get the PO Header Details
-------------------------------------
CURSOR lcu_po_header (p_batch_id IN NUMBER)
IS
    SELECT   XPHCS.ROWID
            ,XPHCS.control_id
            ,XPHCS.record_id --16Jul
            ,XPHCS.agent_name
            ,XPHCS.vendor_site_code
            ,XPHCS.ship_to_location
            ,XPHCS.batch_id
            ,XPHCS.document_num
            ,XPHCS.interface_header_id
    FROM     xx_po_hdrs_conv_stg XPHCS
    WHERE    XPHCS.process_flag IN (1,2,3)
    AND      XPHCS.batch_id=p_batch_id
    ORDER BY XPHCS.control_id;

TYPE po_header_tbl_type IS TABLE OF lcu_po_header%rowtype
INDEX BY BINARY_INTEGER;
lt_po_header po_header_tbl_type;

--------------------------------
--Cursor to get PO Lines Details
--------------------------------
CURSOR lcu_po_line (p_batch_id IN NUMBER, p_parent_record_id IN NUMBER)
IS
    SELECT   XPLCS.ROWID
            ,XPLCS.control_id
            ,XPLCS.interface_line_id
            ,XPLCS.item
            ,XPLCS.ship_to_location
    FROM     xx_po_lines_conv_stg XPLCS
    WHERE    XPLCS.process_flag IN (1,2,3)
    AND      XPLCS.batch_id=p_batch_id
    AND      XPLCS.parent_record_id=p_parent_record_id;

TYPE po_line_tbl_type IS TABLE OF lcu_po_line%rowtype
INDEX BY BINARY_INTEGER;
lt_po_line po_line_tbl_type;

---------------------------
--Cursor to derive Agent id
---------------------------
Cursor lcu_agent(p_agent IN VARCHAR2)
IS
    SELECT PAPF.person_id
    FROM   per_all_people_f PAPF
    WHERE  PAPF.employee_number = p_agent
    AND    sysdate BETWEEN PAPF.effective_start_date AND PAPF.EFFECTIVE_END_DATE;

------------------------------------------------------
--Cursor to derive vendor_id,vendor_site_id and org_id
------------------------------------------------------
CURSOR lcu_vendor_detail(p_vendor_site_code IN VARCHAR2)
IS
    SELECT PVS.vendor_id
          ,PVS.vendor_site_id
          ,PVS.org_id
    FROM   po_vendor_sites_all PVS
    WHERE  PVS.attribute9    = p_vendor_site_code
    AND    purchasing_site_flag = 'Y';

--------------------------------------
--Cursor to derive ship_to_location_id
--------------------------------------
CURSOR lcu_ship_to_location (p_ship_to_location IN VARCHAR2)
IS
    SELECT HAOU.location_id,HAOU.organization_id
    FROM   hr_all_organization_units HAOU,
           mtl_parameters mp
    WHERE  HAOU.attribute1      = p_ship_to_location -- Changed for V1.3
    AND    HAOU.organization_id = mp.organization_id;

-----------------------------------
--Cursor to derive inventor_item_id
-----------------------------------
CURSOR lcu_inventory_item_id (p_item IN VARCHAR2, p_organization_id IN mtl_System_items_b.organization_id%TYPE)
IS
    SELECT MSIB.inventory_item_id
    FROM   mtl_system_items_b MSIB
    WHERE  MSIB.segment1 = p_item    
    AND    organization_id = p_organization_id;
    --AND    ROWNUM = 1;              

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

        display_log('getting conversion id');
        ---------------------------------------
        --Feching and Validating PO Header Data
        ---------------------------------------
        OPEN  lcu_po_header(p_batch_id);
        FETCH lcu_po_header BULK COLLECT INTO lt_po_header;
        CLOSE lcu_po_header;

        display_log('Before if');

        IF lt_po_header.count <> 0 THEN
            XX_COM_CONV_ELEMENTS_PKG.bulk_table_initialize;
        display_log('After if');

            FOR i in lt_po_header.first..lt_po_header.last
            LOOP
                display_log('Inside loop');
                lt_po_control_id(i)        := lt_po_header(i).control_id;
                lt_header_rowid(i)         := lt_po_header(i).ROWID;
                lc_header_message          := '';
                lt_agent_id(i)             := 0;
                lt_vendor_id(i)            := 0;
                lt_vendor_site_id(i)       := 0;
                lt_org_id(i)               := 0;
                lt_ship_to_location_id(i)  := 0;
                lt_process_flag(i)         := 3;
                lt_interface_header_id(i)  := 0;
                lt_header_error_message(i) := '';


                ------------------
                --Validating Agent
                ------------------
                OPEN lcu_agent(lt_po_header(i).agent_name);
                FETCH lcu_agent INTO ln_agent_id;
                    IF lcu_agent%NOTFOUND THEN
                        lc_agent_flag:='N';
                        lt_agent_id(i):=0;
                        display_log('Agent Not Found - Agent Name '||lt_po_header(i).agent_name);
                        fnd_message.set_name('XXPTP','XX_PO_60001_AGENT_ID_INVALID');
                        fnd_message.set_token('AGENT',lt_po_header(i).agent_name);
                        fnd_message.set_token('SEGMENT1',lt_po_header(i).document_num);
                        lc_error_message := fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error(
                                        p_error_msg            =>  lc_error_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_po_control_id(i)
                                       ,p_request_id           =>  fnd_global.conc_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_po'
                                       ,p_staging_table_name   =>  G_HDR_TABLE_NAME
                                       ,p_staging_column_name  =>  'AGENT_NAME'  
                                       ,p_staging_column_value =>  lt_po_header(i).agent_name 
                                       ,p_batch_id             =>  p_batch_id
                                      );
                        lc_header_message:=lc_header_message||lc_error_message;
                    ELSE
                        lc_agent_flag:='Y';
                        lt_agent_id(i):=ln_agent_id;
                        display_log('Agent Found - Agent Id '||lt_agent_id(i));
                    END IF;
                CLOSE lcu_agent;

                ----------------------------------------------------------
                --Validate and derive vendor id, vendor site id and org id
                ----------------------------------------------------------
                OPEN lcu_vendor_detail(lt_po_header(i).vendor_site_code);
                FETCH lcu_vendor_detail INTO ln_vendor_id, ln_vendor_site_id, ln_org_id;
                    IF lcu_vendor_detail%NOTFOUND THEN
                        lc_vendor_flag:='N';
                        lt_vendor_id(i):=0;
                        lt_vendor_site_id(i):=0;
                        lt_org_id(i):=0;
                        display_log('Vendor Not Found - Vendor Site Code '||lt_po_header(i).vendor_site_code);
                        fnd_message.set_name('XXPTP','XX_PO_60001_VENDOR_ID_INVALID');
                        fnd_message.set_token('VENDOR_SITE',lt_po_header(i).vendor_site_code);
                        fnd_message.set_token('SEGMENT1',lt_po_header(i).document_num);
                        lc_error_message := fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error(
                                        p_error_msg            =>  lc_error_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_po_control_id(i)
                                       ,p_request_id           =>  fnd_global.conc_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_po'
                                       ,p_staging_table_name   =>  G_HDR_TABLE_NAME
                                       ,p_staging_column_name  =>  'VENDOR_SITE_CODE'  
                                       ,p_staging_column_value =>  lt_po_header(i).vendor_site_code 
                                       ,p_batch_id             =>  p_batch_id
                                      );
                        lc_header_message:=lc_header_message||lc_error_message;
                    ELSE
                        lc_vendor_flag:='Y';
                        lt_vendor_id(i):=ln_vendor_id;
                        lt_vendor_site_id(i):=ln_vendor_site_id;
                        lt_org_id(i):=ln_org_id;
                        display_log('Vendor Found - Vendor Site Id '||lt_vendor_site_id(i));
                    END IF;
                CLOSE lcu_vendor_detail;

                ----------------------------------------------------------
                --Deriving Ship to Location Id and Ship to Organization Id
                ----------------------------------------------------------
                OPEN  lcu_ship_to_location(lt_po_header(i).ship_to_location);
                FETCH lcu_ship_to_location INTO ln_ship_to_location_id,ln_ship_to_organization_id;
                    IF lcu_ship_to_location%NOTFOUND
                    OR ln_ship_to_location_id IS NULL
                    THEN
                        lc_ship_to_location_flag:='N';
                        lt_ship_to_location_id(i):=0;
                        display_log('Header Ship to Location Not Found - Ship to Location '||lt_po_header(i).ship_to_location);
                        fnd_message.set_name('XXPTP','XX_PO_60001_HLOC_ID_INVALID');
                        fnd_message.set_token('LOCATION',lt_po_header(i).ship_to_location);
                        fnd_message.set_token('SEGMENT1',lt_po_header(i).document_num);
                        lc_error_message := fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error(
                                        p_error_msg            =>  lc_error_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_po_control_id(i)
                                       ,p_request_id           =>  fnd_global.conc_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_po'
                                       ,p_staging_table_name   =>  G_HDR_TABLE_NAME
                                       ,p_staging_column_name  =>  'SHIP_TO_LOCATION'  
                                       ,p_staging_column_value =>  lt_po_header(i).ship_to_location 
                                       ,p_batch_id             =>  p_batch_id
                                      );
                        lc_header_message:=lc_header_message||lc_error_message;
                    ELSE
                        lc_ship_to_location_flag:='Y';
                        lt_ship_to_location_id(i):=ln_ship_to_location_id;
                        display_log('Header Ship to Location Found - Ship to Location id '||lt_ship_to_location_id(i));
                    END IF;
                CLOSE lcu_ship_to_location;

                -------------------------------
                --Deriving Interface_header_id
                -------------------------------
                SELECT po_headers_interface_s.NEXTVAL
                INTO ln_interface_header_id
                FROM DUAL;
                lt_interface_header_id(i):=ln_interface_header_id;

                -------------------------
                --Validating line records
                -------------------------
                lc_inventory_flag:='Y';
                lc_ship_to_organization_flag:='Y';
                lc_ship_to_location_line_flag:='Y';

                OPEN  lcu_po_line(lt_po_header(i).batch_id,lt_po_header(i).record_id);--16Jul
                FETCH lcu_po_line BULK COLLECT INTO lt_po_line;
                CLOSE lcu_po_line;

                    IF lt_po_line.count <> 0 THEN
                        display_log('Inside Line IF');
                        display_log('lt_po_header(i).record_id'||lt_po_header(i).record_id);
                        display_log(' lc_no_line_flag'|| lc_no_line_flag);
                        display_log('lt_po_line.count'||lt_po_line.count);

                        lc_no_line_flag:='Y';
                        display_log(' lc_no_line_flag'|| lc_no_line_flag);
                        FOR j in lt_po_line.first..lt_po_line.last
                        LOOP
                            display_log('Inside For');
                            lt_po_line_control_id(j)         := lt_po_line(j).control_id;
                            lt_po_lgcy_intf_line_id(j)       := lt_po_line(j).interface_line_id;
                            lt_line_rowid(j)                 := lt_po_line(j).ROWID;
                            lc_line_message                  := '';
                            lt_inventory_item_id(j)          := 0;
                            lt_ship_to_organization_id(j)    := 0;
                            lt_ship_to_location_line_id(j)   := 0;
                            lt_interface_line_id(j)          := 0;
                            lt_po_line_num(j)                := 0;
                            lt_line_error_message(j)         := '';

                            -------------------------------------------------------------------
                --Deriving Ship to location id and ship to organization id for line
                -------------------------------------------------------------------
                ln_ship_to_location_id:=NULL;
                ln_ship_to_organization_id:=NULL;
                
                OPEN lcu_ship_to_location(lt_po_line(j).ship_to_location);
                FETCH lcu_ship_to_location INTO ln_ship_to_location_id,ln_ship_to_organization_id;
                    IF lcu_ship_to_location%NOTFOUND
                    OR ln_ship_to_location_id IS NULL
                    THEN
                        lc_ship_to_organization_flag:='N';
                        lt_ship_to_organization_id(j):=0;
                        display_log('Line Ship to Organization Not Found - Ship to Location '||lt_po_line(j).ship_to_location);
                        fnd_message.set_name('XXPTP','XX_PO_60001_LLOC_ID_INVALID');
                        fnd_message.set_token('LOCATION',lt_po_line(j).ship_to_location);
                        fnd_message.set_token('ITEM',lt_po_line(j).item);
                        fnd_message.set_token('SEGMENT1',lt_po_header(i).document_num);
                        lc_error_message := fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error(
                                        p_error_msg            =>  lc_error_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_po_line_control_id(j)
                                       ,p_request_id           =>  fnd_global.conc_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_po'
                                       ,p_staging_table_name   =>  G_LINE_TABLE_NAME
                                       ,p_staging_column_name  =>  'SHIP_TO_LOCATION'  
                                                   ,p_staging_column_value =>  lt_po_line(j).ship_to_location
                                       ,p_batch_id             =>  p_batch_id
                                      );
                        lc_line_message:=lc_line_message||lc_error_message;
                    ELSE
                        lt_ship_to_organization_id(j):=ln_ship_to_organization_id;
                        lt_ship_to_location_line_id(j):=ln_ship_to_location_id;
                        display_log('Line Ship to Organization Found - Ship to Location id '||lt_ship_to_location_line_id(j)||' Ship to Organization Id '||lt_ship_to_organization_id(j));
                    END IF;
                            CLOSE lcu_ship_to_location;
                            
                            ----------------------------
                            --Deriving Inventory_item_id
                            ----------------------------
                            OPEN lcu_inventory_item_id(lt_po_line(j).item,ln_ship_to_organization_id ); 
                            FETCH lcu_inventory_item_id INTO ln_inventory_item_id;
                                IF lcu_inventory_item_id%NOTFOUND THEN
                                    lt_inventory_item_id(j):=0;
                                    display_log('Item Not Found - Item '||lt_po_line(j).item);
                                    lc_inventory_flag:='N';
                                    fnd_message.set_name('XXPTP','XX_PO_60001_ITEM_ID_INVALID');
                                    fnd_message.set_token('ITEM',lt_po_line(j).item);
                                    fnd_message.set_token('SEGMENT1',lt_po_header(i).document_num);
                                    lc_error_message := fnd_message.get;
                                    --Adding error message to stack
                                    bulk_log_error(
                                                    p_error_msg            =>  lc_error_message
                                                   ,p_error_code           =>  NULL
                                                   ,p_control_id           =>  lt_po_line_control_id(j)
                                                   ,p_request_id           =>  fnd_global.conc_request_id
                                                   ,p_converion_id         =>  gn_conversion_id
                                                   ,p_package_name         =>  G_PACKAGE_NAME
                                                   ,p_procedure_name       =>  'validate_po'
                                                   ,p_staging_table_name   =>  G_LINE_TABLE_NAME
                                                   ,p_staging_column_name  =>  'ITEM'  
                                                   ,p_staging_column_value =>  lt_po_line(j).item
                                                   ,p_batch_id             =>  p_batch_id
                                                  );
                                    lc_line_message:=lc_line_message||lc_error_message;
                                ELSE
                                    lt_inventory_item_id(j):=ln_inventory_item_id;
                                    display_log('Item Found - Inventory Item Id '||lt_inventory_item_id(j));
                                END IF;
                            CLOSE lcu_inventory_item_id;

                            
                            ----------------------------
                            --Deriving Interface_Line_id
                            ----------------------------
                            SELECT po_lines_interface_s.NEXTVAL
                            INTO ln_interface_line_id
                            FROM DUAL;
                            lt_interface_line_id(j):=ln_interface_line_id;

                            ----------------------
                            --Deriving Line Number
                            ----------------------
                            lt_po_line_num(j):=j;
                            lt_line_error_message(j):=lc_line_message;

                            display_log('lt_inventory_item_id(j)'||lt_inventory_item_id(j));
                            display_log('lt_ship_to_organization_id(j)'||lt_ship_to_organization_id(j));
                            display_log('lt_ship_to_location_line_id(j)'||lt_ship_to_location_line_id(j));
                            display_log('lt_interface_line_id(j)'||lt_interface_line_id(j));
                            display_log('lt_interface_header_id(i)'||lt_interface_header_id(i));
                            display_log('lt_po_line_num(j)'||lt_po_line_num(j));
                            display_log('lt_line_error_message(j)'||lt_line_error_message(j));


                       END LOOP;
                    display_log('After line loop');
                    ELSE
                        lc_no_line_flag:='N';
                        fnd_message.set_name('XXPTP','XX_PO_60001_NO_LINES');
                        fnd_message.set_token('SEGMENT1',lt_po_header(i).document_num);
                        lc_error_message := fnd_message.get;
                        --Adding error message to stack
                        bulk_log_error(
                                        p_error_msg            =>  lc_error_message
                                       ,p_error_code           =>  NULL
                                       ,p_control_id           =>  lt_po_control_id(i)
                                       ,p_request_id           =>  fnd_global.conc_request_id
                                       ,p_converion_id         =>  gn_conversion_id
                                       ,p_package_name         =>  G_PACKAGE_NAME
                                       ,p_procedure_name       =>  'validate_po'
                                       ,p_staging_table_name   =>  G_LINE_TABLE_NAME
                                       ,p_staging_column_name  =>  NULL
                                       ,p_staging_column_value =>  NULL
                                       ,p_batch_id             =>  p_batch_id
                                      );
                        lc_header_message:=lc_header_message||lc_error_message;
                    END IF;

                IF      lc_inventory_flag                = 'Y'
                    AND lc_ship_to_location_line_flag    = 'Y'
                    AND lc_ship_to_organization_flag     = 'Y'
                    AND lc_agent_flag                    = 'Y'
                    AND lc_vendor_flag                   = 'Y'
                    AND lc_ship_to_location_flag         = 'Y'
                    AND lc_no_line_flag                  = 'Y'
                THEN
                    lt_process_flag(i):= 4;
                    ln_process_flag:=4;
                    lt_header_error_message(i):='';
                ELSE
                    lt_process_flag(i):= 3;
                    ln_process_flag:=3;
                    lt_header_error_message(i):=lc_header_message;
                END IF;
                display_log('before update line');
                --------------------------------------------------------------
                -- Bulk Update XX_PO_LINES_CONV_STG with Process flags and Ids
                --------------------------------------------------------------
                FORALL k IN 1.. lt_po_line.COUNT
                    UPDATE xx_po_lines_conv_stg XPLCS
                    SET    XPLCS.item_id                 = lt_inventory_item_id(k)
                          ,XPLCS.process_flag            = ln_process_flag
                          ,XPLCS.ship_to_organization_id = lt_ship_to_organization_id(k)
                          ,XPLCS.ship_to_location_id     = lt_ship_to_location_line_id(k)
                          ,XPLCS.interface_line_id       = lt_interface_line_id(k)
                          ,XPLCS.interface_header_id     = lt_interface_header_id(i)
                          ,XPLCS.line_num                = lt_po_line_num(k)
                          ,XPLCS.error_message           = lt_line_error_message(k)
                    WHERE  ROWID                         = lt_line_rowid(k);
                    display_log('after update line');
            END LOOP;

            ------------------------------------------------------------------------
            --Invoke Common Conversion API to Bulk Insert the Trnsaction Data Errors
            -------------------------------------------------------------------------
            XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

            -------------------------------------------------------------
            -- Bulk Update XX_PO_HDRS_CONV_STG with Process flags and Ids
            -------------------------------------------------------------
            display_log('before update header');
            FORALL i IN 1.. lt_po_header.COUNT
                UPDATE xx_po_hdrs_conv_stg XPHCS
                SET    XPHCS.agent_id                = lt_agent_id(i)
                      ,XPHCS.vendor_id               = lt_vendor_id(i)
                      ,XPHCS.vendor_site_id          = lt_vendor_site_id(i)
                      ,XPHCS.org_id                  = lt_org_id(i)
                      ,XPHCS.ship_to_location_id     = lt_ship_to_location_id(i)
                      ,XPHCS.process_flag            = lt_process_flag(i)
                      ,XPHCS.interface_header_id     = lt_interface_header_id(i)
                      ,XPHCS.error_message           = lt_header_error_message(i)
                WHERE  ROWID                         = lt_header_rowid (i);
                display_log('after update header');
            COMMIT;
        ELSE
            RAISE EX_TRANSACTION_NO_DATA;
        END IF; --lt_po_header.count <> 0
    ELSE
        RAISE EX_ENTRY_EXCEP;
    END IF;-- If lc_return_status ='S'
EXCEPTION
    WHEN EX_TRANSACTION_NO_DATA THEN
        x_retcode := 1;
        x_errbuf  := 'No data found in the staging table XX_PO_HDRS_CONV_STG  with batch_id - '||p_batch_id;
        --Adding error message to stack
        bulk_log_error( p_error_msg          =>  x_errbuf
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_po'
                       ,p_staging_table_name =>  G_HDR_TABLE_NAME
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    WHEN EX_ENTRY_EXCEP THEN
        x_retcode := 2;
        gc_sqlerrm:='There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE;
        gc_sqlcode:=SQLCODE;
        x_errbuf:=gc_sqlerrm;
        --Adding error message to stack
        bulk_log_error( p_error_msg          =>  gc_sqlerrm
                       ,p_error_code         =>  gc_sqlcode
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_po'
                       ,p_staging_table_name =>  G_HDR_TABLE_NAME
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error in Validate po - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg          =>  gc_sqlerrm
                       ,p_error_code         =>  gc_sqlcode
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_po'
                       ,p_staging_table_name =>  G_HDR_TABLE_NAME
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
END validate_po;

-- +===================================================================+
-- | Name        :  PROCESS_PO                                         |
-- | Description :  This procedure is invoked from the child main      |
-- |                procedure. This procedure will insert records into |
-- |                interface table and submit the standard import     |
-- |                program to import data into base tables            |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_po(
                      x_errbuf      OUT  NOCOPY  VARCHAR2
                     ,x_retcode     OUT  NOCOPY  VARCHAR2
                     ,p_batch_id    IN           NUMBER
                    )
IS
------------------------------------------
--Declaring Local Variables and Exceptions
------------------------------------------
    EX_SUBMIT_IMPORT        EXCEPTION;
    EX_INSERT               EXCEPTION;
    ln_conc_request_id      FND_CONCURRENT_REQUESTS.request_id%TYPE;
    ln_original_org_id      po_headers_interface.org_id%type;
    lc_phase                fnd_concurrent_requests.phase_code%type;
    lc_staging_table_name   VARCHAR2(200);
    ln_import_req_index     PLS_INTEGER;
    lc_hdr_error_message    VARCHAR2(2000);
    lc_line_error_message   VARCHAR2(2000);
--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE success_rowid_tbl_typ IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_success_rowid success_rowid_tbl_typ;
--lt_error_document_num document_num_tbl_typ;

TYPE error_message_tbl_typ IS TABLE OF po_interface_errors.error_message%type
INDEX BY BINARY_INTEGER;
lt_error_message error_message_tbl_typ;
lt_hdr_error_message error_message_tbl_typ;
lt_line_error_message error_message_tbl_typ;

TYPE error_control_id_tbl_typ IS TABLE OF xx_po_hdrs_conv_stg.control_id%type
INDEX BY BINARY_INTEGER;
lt_error_control_id error_control_id_tbl_typ;

TYPE table_name_tbl_typ IS TABLE OF po_interface_errors.table_name%type
INDEX BY BINARY_INTEGER;
lt_table_name table_name_tbl_typ;

TYPE conc_request_id_tbl_typ IS TABLE OF fnd_concurrent_requests.request_id%type
INDEX BY BINARY_INTEGER;
lt_conc_request_id conc_request_id_tbl_typ;

TYPE int_header_id_tbl_typ IS TABLE OF po_headers_interface.interface_header_id%type
INDEX BY BINARY_INTEGER;
lt_int_header_id int_header_id_tbl_typ;

TYPE int_line_id_tbl_typ IS TABLE OF po_lines_interface.interface_line_id%type
INDEX BY BINARY_INTEGER;
lt_int_line_id int_line_id_tbl_typ;

----------------------------------------------------
--Cursor to fetch Distinct Operating unit in a batch
----------------------------------------------------
/*CURSOR lcu_operating_unit
IS
    SELECT DISTINCT PHI.org_id
    FROM   po_headers_interface PHI
    WHERE  PHI.batch_id=p_batch_id
    AND    PHI.interface_source_code = gn_interface_source_code;
*/
-- Added for v1.4

 --------------------------------------------------------------------
 --Cursor to fetch the distinct Operating Unit from the staging table
 --------------------------------------------------------------------
      CURSOR lcu_operating_unit
      IS
      SELECT FRT.responsibility_id
            ,FRT.application_id
            ,FRT.responsibility_name
            ,HOU.organization_id   org_id
      FROM   hr_operating_units HOU
            ,fnd_responsibility_tl FRT
      WHERE  FRT.responsibility_name like 'OD ('||SUBSTR(HOU.name,4,2)||') PO Superuser'  
      AND    HOU.organization_id IN 
            (SELECT DISTINCT PHI.org_id
             FROM   po_headers_interface PHI
             WHERE  PHI.batch_id=p_batch_id
             AND    PHI.interface_source_code = gn_interface_source_code
            );           

---------------------------------------
--Cursor to fetch all sucessful records
---------------------------------------
CURSOR lcu_success_records
IS
    SELECT XPHCS.ROWID
    FROM   po_headers_interface PHI,
           xx_po_hdrs_conv_stg XPHCS
    WHERE  PHI.vendor_doc_num           = XPHCS.vendor_doc_num
    AND    PHI.interface_header_id      = XPHCS.interface_header_id
    AND    PHI.process_code             = 'ACCEPTED'
    AND    PHI.batch_id                 = p_batch_id
    AND    PHI.interface_source_code    = gn_interface_source_code;

-------------------------------------
--Cursor to fetch all errored records
-------------------------------------
CURSOR lcu_errored_records
IS
    SELECT XPHCS.control_id,PIE.error_message,PIE.table_name
    FROM   po_headers_interface PHI
          ,po_interface_errors PIE
          ,xx_po_hdrs_conv_stg XPHCS
    WHERE  PHI.process_code             = 'REJECTED'
    AND    PIE.interface_header_id      = PHI.interface_header_id
    AND    PHI.interface_header_id      = XPHCS.interface_header_id
    AND    PHI.batch_id                 = p_batch_id
    AND    PHI.interface_source_code    = gn_interface_source_code;

--------------------------------------------
--Cursor to select errored interface headers
--------------------------------------------
CURSOR lcu_error_update_header
IS
SELECT     XPHCS.interface_header_id
    FROM   xx_po_hdrs_conv_stg XPHCS
    WHERE  XPHCS.batch_id   = p_batch_id
    AND    XPHCS.interface_header_id IN (SELECT PHI.Interface_header_id
                                        FROM   po_headers_interface PHI
                                              ,po_interface_errors PIE
                                        WHERE  PHI.process_code = 'REJECTED'
                                        AND    PIE.interface_header_id = PHI.interface_header_id
                                        );
TYPE error_update_header_tbl_typ IS TABLE OF  lcu_error_update_header%rowtype
INDEX BY BINARY_INTEGER;
lt_error_update_header error_update_header_tbl_typ;

------------------------------------------
--Cursor to select errored interface lines
------------------------------------------
CURSOR lcu_error_update_line
IS
    SELECT XPLCS.interface_line_id
    FROM   xx_po_lines_conv_stg XPLCS
    WHERE  XPLCS.batch_id   = p_batch_id
    AND    XPLCS.interface_line_id IN
                                       (SELECT PIE.interface_line_id
                                        FROM   po_headers_interface PHI
                                              ,po_interface_errors PIE
                                        WHERE  PHI.process_code = 'REJECTED'
                                        AND    PHI.batch_id   = p_batch_id
                                        AND    PIE.interface_header_id = PHI.interface_header_id
                                        AND    PIE.interface_line_id IS NOT NULL);

TYPE error_update_line_tbl_typ IS TABLE OF lcu_error_update_line%rowtype
INDEX BY BINARY_INTEGER;
lt_error_update_line error_update_line_tbl_typ;

------------------------------------------------------
--Cursor to select all the error messages for a header
------------------------------------------------------
CURSOR lcu_hdr(p_interface_header_id IN NUMBER)
IS
SELECT PIE.interface_header_id,PIE.error_message
FROM po_interface_errors PIE
WHERE interface_header_id = p_interface_header_id
AND interface_line_id IS NULL;

--------------------------------------------------
--Cursor to select all the error messages for line
--------------------------------------------------
CURSOR lcu_line(p_interface_line_id IN NUMBER)
IS
SELECT PIE.interface_header_id,PIE.interface_line_id,PIE.error_message
FROM po_interface_errors PIE
WHERE interface_line_id   = p_interface_line_id ;

----------------------------------------
--Cursor to derive interface_source_code
----------------------------------------
CURSOR lcu_source_code
IS
    SELECT interface_source_code
    FROM xx_po_hdrs_conv_stg
    WHERE ROWNUM=1;

BEGIN

    -------------------------------
    --Derving interface_source_code
    -------------------------------
    OPEN  lcu_source_code;
    FETCH lcu_source_code INTO gn_interface_source_code;
    CLOSE lcu_source_code;

    -------------------------------------------------
    --Inserting records into po_lines_interface_table
    -------------------------------------------------
    BEGIN
        INSERT INTO PO_HEADERS_INTERFACE
        (
          INTERFACE_HEADER_ID
         ,BATCH_ID
         ,INTERFACE_SOURCE_CODE
         ,PROCESS_CODE
         ,ACTION
         ,GROUP_CODE
         ,ORG_ID
         ,DOCUMENT_TYPE_CODE
         ,DOCUMENT_SUBTYPE
         ,DOCUMENT_NUM
         ,PO_HEADER_ID
         ,RELEASE_NUM
         ,PO_RELEASE_ID
         ,RELEASE_DATE
         ,CURRENCY_CODE
         ,RATE_TYPE
         ,RATE_TYPE_CODE
         ,RATE_DATE
         ,RATE
         ,AGENT_NAME
         ,AGENT_ID
         ,VENDOR_NAME
         ,VENDOR_ID
         ,VENDOR_SITE_CODE
         ,VENDOR_SITE_ID
         ,VENDOR_CONTACT
         ,VENDOR_CONTACT_ID
         ,SHIP_TO_LOCATION
         ,SHIP_TO_LOCATION_ID
         ,BILL_TO_LOCATION
         ,BILL_TO_LOCATION_ID
         ,PAYMENT_TERMS
         ,TERMS_ID
         ,FREIGHT_CARRIER
         ,FOB
         ,FREIGHT_TERMS
         ,APPROVAL_STATUS
         ,APPROVED_DATE
         ,REVISED_DATE
         ,REVISION_NUM
         ,NOTE_TO_VENDOR
         ,NOTE_TO_RECEIVER
         ,CONFIRMING_ORDER_FLAG
         ,COMMENTS
         ,ACCEPTANCE_REQUIRED_FLAG
         ,ACCEPTANCE_DUE_DATE
         ,AMOUNT_AGREED
         ,AMOUNT_LIMIT
         ,MIN_RELEASE_AMOUNT
         ,EFFECTIVE_DATE
         ,EXPIRATION_DATE
         ,PRINT_COUNT
         ,PRINTED_DATE
         ,FIRM_FLAG
         ,FROZEN_FLAG
         ,CLOSED_CODE
         ,CLOSED_DATE
         ,REPLY_DATE
         ,REPLY_METHOD
         ,RFQ_CLOSE_DATE
         ,QUOTE_WARNING_DELAY
         ,VENDOR_DOC_NUM
         ,APPROVAL_REQUIRED_FLAG
         ,VENDOR_LIST
         ,VENDOR_LIST_HEADER_ID
         ,FROM_HEADER_ID
         ,FROM_TYPE_LOOKUP_CODE
         ,USSGL_TRANSACTION_CODE
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
         ,CREATION_DATE
         ,CREATED_BY
         ,LAST_UPDATE_DATE
         ,LAST_UPDATED_BY
         ,LAST_UPDATE_LOGIN
     --    ,REQUEST_ID
         ,PROGRAM_APPLICATION_ID
         ,PROGRAM_ID
         ,PROGRAM_UPDATE_DATE
         ,REFERENCE_NUM
         ,LOAD_SOURCING_RULES_FLAG
         ,VENDOR_NUM
         ,FROM_RFQ_NUM
         ,WF_GROUP_ID
         ,PCARD_ID
         ,PAY_ON_CODE
         ,GLOBAL_AGREEMENT_FLAG
         ,CONSUME_REQ_DEMAND_FLAG
         ,SHIPPING_CONTROL
         ,ENCUMBRANCE_REQUIRED_FLAG
         ,AMOUNT_TO_ENCUMBER
         ,CHANGE_SUMMARY
         ,BUDGET_ACCOUNT_SEGMENT1
         ,BUDGET_ACCOUNT_SEGMENT2
         ,BUDGET_ACCOUNT_SEGMENT3
         ,BUDGET_ACCOUNT_SEGMENT4
         ,BUDGET_ACCOUNT_SEGMENT5
         ,BUDGET_ACCOUNT_SEGMENT6
         ,BUDGET_ACCOUNT_SEGMENT7
         ,BUDGET_ACCOUNT_SEGMENT8
         ,BUDGET_ACCOUNT_SEGMENT9
         ,BUDGET_ACCOUNT_SEGMENT10
         ,BUDGET_ACCOUNT_SEGMENT11
         ,BUDGET_ACCOUNT_SEGMENT12
         ,BUDGET_ACCOUNT_SEGMENT13
         ,BUDGET_ACCOUNT_SEGMENT14
         ,BUDGET_ACCOUNT_SEGMENT15
         ,BUDGET_ACCOUNT_SEGMENT16
         ,BUDGET_ACCOUNT_SEGMENT17
         ,BUDGET_ACCOUNT_SEGMENT18
         ,BUDGET_ACCOUNT_SEGMENT19
         ,BUDGET_ACCOUNT_SEGMENT20
         ,BUDGET_ACCOUNT_SEGMENT21
         ,BUDGET_ACCOUNT_SEGMENT22
         ,BUDGET_ACCOUNT_SEGMENT23
         ,BUDGET_ACCOUNT_SEGMENT24
         ,BUDGET_ACCOUNT_SEGMENT25
         ,BUDGET_ACCOUNT_SEGMENT26
         ,BUDGET_ACCOUNT_SEGMENT27
         ,BUDGET_ACCOUNT_SEGMENT28
         ,BUDGET_ACCOUNT_SEGMENT29
         ,BUDGET_ACCOUNT_SEGMENT30
         ,BUDGET_ACCOUNT
         ,BUDGET_ACCOUNT_ID
         ,GL_ENCUMBERED_DATE
         ,GL_ENCUMBERED_PERIOD_NAME
        )
    SELECT
          INTERFACE_HEADER_ID
         ,BATCH_ID
         ,INTERFACE_SOURCE_CODE
         ,PROCESS_CODE
         ,ACTION
         ,GROUP_CODE
         ,ORG_ID
         ,DOCUMENT_TYPE_CODE
         ,DOCUMENT_SUBTYPE
         ,DOCUMENT_NUM
         ,PO_HEADER_ID
         ,RELEASE_NUM
         ,PO_RELEASE_ID
         ,RELEASE_DATE
         ,CURRENCY_CODE
         ,RATE_TYPE
         ,RATE_TYPE_CODE
         ,RATE_DATE
         ,RATE
         ,AGENT_NAME
         ,AGENT_ID
         ,VENDOR_NAME
         ,VENDOR_ID
         ,VENDOR_SITE_CODE
         ,VENDOR_SITE_ID
         ,VENDOR_CONTACT
         ,VENDOR_CONTACT_ID
         ,SHIP_TO_LOCATION
         ,SHIP_TO_LOCATION_ID
         ,BILL_TO_LOCATION
         ,BILL_TO_LOCATION_ID
         ,PAYMENT_TERMS
         ,TERMS_ID
         ,FREIGHT_CARRIER
         ,FOB
         ,FREIGHT_TERMS
         ,APPROVAL_STATUS
         ,APPROVED_DATE
         ,REVISED_DATE
         ,REVISION_NUM
         ,NOTE_TO_VENDOR
         ,NOTE_TO_RECEIVER
         ,CONFIRMING_ORDER_FLAG
         ,COMMENTS
         ,ACCEPTANCE_REQUIRED_FLAG
         ,ACCEPTANCE_DUE_DATE
         ,AMOUNT_AGREED
         ,AMOUNT_LIMIT
         ,MIN_RELEASE_AMOUNT
         ,EFFECTIVE_DATE
         ,EXPIRATION_DATE
         ,PRINT_COUNT
         ,PRINTED_DATE
         ,FIRM_FLAG
         ,FROZEN_FLAG
         ,CLOSED_CODE
         ,CLOSED_DATE
         ,REPLY_DATE
         ,REPLY_METHOD
         ,RFQ_CLOSE_DATE
         ,QUOTE_WARNING_DELAY
         ,VENDOR_DOC_NUM
         ,APPROVAL_REQUIRED_FLAG
         ,VENDOR_LIST
         ,VENDOR_LIST_HEADER_ID
         ,FROM_HEADER_ID
         ,FROM_TYPE_LOOKUP_CODE
         ,USSGL_TRANSACTION_CODE
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
         ,sysdate--CREATION_DATE
         ,G_USER_ID--CREATED_BY
         ,sysdate--LAST_UPDATE_DATE
         ,G_USER_ID--LAST_UPDATED_BY
         ,G_USER_ID--LAST_UPDATE_LOGIN
    --     ,REQUEST_ID
         ,PROGRAM_APPLICATION_ID
         ,PROGRAM_ID
         ,PROGRAM_UPDATE_DATE
         ,REFERENCE_NUM
         ,LOAD_SOURCING_RULES_FLAG
         ,VENDOR_NUM
         ,FROM_RFQ_NUM
         ,WF_GROUP_ID
         ,PCARD_ID
         ,PAY_ON_CODE
         ,GLOBAL_AGREEMENT_FLAG
         ,CONSUME_REQ_DEMAND_FLAG
         ,SHIPPING_CONTROL
         ,ENCUMBRANCE_REQUIRED_FLAG
         ,AMOUNT_TO_ENCUMBER
         ,CHANGE_SUMMARY
         ,BUDGET_ACCOUNT_SEGMENT1
         ,BUDGET_ACCOUNT_SEGMENT2
         ,BUDGET_ACCOUNT_SEGMENT3
         ,BUDGET_ACCOUNT_SEGMENT4
         ,BUDGET_ACCOUNT_SEGMENT5
         ,BUDGET_ACCOUNT_SEGMENT6
         ,BUDGET_ACCOUNT_SEGMENT7
         ,BUDGET_ACCOUNT_SEGMENT8
         ,BUDGET_ACCOUNT_SEGMENT9
         ,BUDGET_ACCOUNT_SEGMENT10
         ,BUDGET_ACCOUNT_SEGMENT11
         ,BUDGET_ACCOUNT_SEGMENT12
         ,BUDGET_ACCOUNT_SEGMENT13
         ,BUDGET_ACCOUNT_SEGMENT14
         ,BUDGET_ACCOUNT_SEGMENT15
         ,BUDGET_ACCOUNT_SEGMENT16
         ,BUDGET_ACCOUNT_SEGMENT17
         ,BUDGET_ACCOUNT_SEGMENT18
         ,BUDGET_ACCOUNT_SEGMENT19
         ,BUDGET_ACCOUNT_SEGMENT20
         ,BUDGET_ACCOUNT_SEGMENT21
         ,BUDGET_ACCOUNT_SEGMENT22
         ,BUDGET_ACCOUNT_SEGMENT23
         ,BUDGET_ACCOUNT_SEGMENT24
         ,BUDGET_ACCOUNT_SEGMENT25
         ,BUDGET_ACCOUNT_SEGMENT26
         ,BUDGET_ACCOUNT_SEGMENT27
         ,BUDGET_ACCOUNT_SEGMENT28
         ,BUDGET_ACCOUNT_SEGMENT29
         ,BUDGET_ACCOUNT_SEGMENT30
         ,BUDGET_ACCOUNT
         ,BUDGET_ACCOUNT_ID
         ,GL_ENCUMBERED_DATE
         ,GL_ENCUMBERED_PERIOD_NAME
    FROM  xx_po_hdrs_conv_stg XPHCS
    WHERE XPHCS.batch_id=p_batch_id
    AND   XPHCS.process_flag=4;
    EXCEPTION
        WHEN OTHERS THEN
        x_retcode := 2;
        x_errbuf  := 'Exception While inserting data into PO_HEADERS_INTERFACE - '||SQLERRM;
        display_log(x_errbuf||SQLERRM);
        RAISE EX_INSERT;
    END;

    -------------------------------------------------
    --Inserting records into po_lines_interface_table
    -------------------------------------------------
    BEGIN
        INSERT INTO PO_LINES_INTERFACE
        (
          INTERFACE_LINE_ID
         ,INTERFACE_HEADER_ID
         ,ACTION
         ,GROUP_CODE
         ,LINE_NUM
         ,PO_LINE_ID
         ,SHIPMENT_NUM
         ,LINE_LOCATION_ID
         ,SHIPMENT_TYPE
         ,REQUISITION_LINE_ID
         ,DOCUMENT_NUM
         ,RELEASE_NUM
         ,PO_HEADER_ID
         ,PO_RELEASE_ID
         ,SOURCE_SHIPMENT_ID
         ,CONTRACT_NUM
         ,LINE_TYPE
         ,LINE_TYPE_ID
         ,ITEM
         ,ITEM_ID
         ,ITEM_REVISION
         ,CATEGORY
         ,CATEGORY_ID
         ,ITEM_DESCRIPTION
         ,VENDOR_PRODUCT_NUM
         ,UOM_CODE
         ,UNIT_OF_MEASURE
         ,QUANTITY
         ,COMMITTED_AMOUNT
         ,MIN_ORDER_QUANTITY
         ,MAX_ORDER_QUANTITY
         ,UNIT_PRICE
         ,LIST_PRICE_PER_UNIT
         ,MARKET_PRICE
         ,ALLOW_PRICE_OVERRIDE_FLAG
         ,NOT_TO_EXCEED_PRICE
         ,NEGOTIATED_BY_PREPARER_FLAG
         ,UN_NUMBER
         ,UN_NUMBER_ID
         ,HAZARD_CLASS
         ,HAZARD_CLASS_ID
         ,NOTE_TO_VENDOR
         ,TRANSACTION_REASON_CODE
         ,TAXABLE_FLAG
         ,TAX_NAME
         ,TYPE_1099
         ,CAPITAL_EXPENSE_FLAG
         ,INSPECTION_REQUIRED_FLAG
         ,RECEIPT_REQUIRED_FLAG
         ,PAYMENT_TERMS
         ,TERMS_ID
         ,PRICE_TYPE
         ,MIN_RELEASE_AMOUNT
         ,PRICE_BREAK_LOOKUP_CODE
         ,USSGL_TRANSACTION_CODE
         ,CLOSED_CODE
         ,CLOSED_REASON
         ,CLOSED_DATE
         ,CLOSED_BY
         ,INVOICE_CLOSE_TOLERANCE
         ,RECEIVE_CLOSE_TOLERANCE
         ,FIRM_FLAG
         ,DAYS_EARLY_RECEIPT_ALLOWED
         ,DAYS_LATE_RECEIPT_ALLOWED
         ,ENFORCE_SHIP_TO_LOCATION_CODE
         ,ALLOW_SUBSTITUTE_RECEIPTS_FLAG
         ,RECEIVING_ROUTING
         ,RECEIVING_ROUTING_ID
         ,QTY_RCV_TOLERANCE
         ,OVER_TOLERANCE_ERROR_FLAG
         ,QTY_RCV_EXCEPTION_CODE
         ,RECEIPT_DAYS_EXCEPTION_CODE
         ,SHIP_TO_ORGANIZATION_CODE
         ,SHIP_TO_ORGANIZATION_ID
         ,SHIP_TO_LOCATION
         ,SHIP_TO_LOCATION_ID
         ,NEED_BY_DATE
         ,PROMISED_DATE
         ,ACCRUE_ON_RECEIPT_FLAG
         ,LEAD_TIME
         ,LEAD_TIME_UNIT
         ,PRICE_DISCOUNT
         ,FREIGHT_CARRIER
         ,FOB
         ,FREIGHT_TERMS
         ,EFFECTIVE_DATE
         ,EXPIRATION_DATE
         ,FROM_HEADER_ID
         ,FROM_LINE_ID
         ,FROM_LINE_LOCATION_ID
         ,LINE_ATTRIBUTE_CATEGORY_LINES
         ,LINE_ATTRIBUTE1
         ,LINE_ATTRIBUTE2
         ,LINE_ATTRIBUTE3
         ,LINE_ATTRIBUTE4
         ,LINE_ATTRIBUTE5
         ,LINE_ATTRIBUTE6
         ,LINE_ATTRIBUTE7
         ,LINE_ATTRIBUTE8
         ,LINE_ATTRIBUTE9
         ,LINE_ATTRIBUTE10
         ,LINE_ATTRIBUTE11
         ,LINE_ATTRIBUTE12
         ,LINE_ATTRIBUTE13
         ,LINE_ATTRIBUTE14
         ,LINE_ATTRIBUTE15
         ,SHIPMENT_ATTRIBUTE_CATEGORY
         ,SHIPMENT_ATTRIBUTE1
         ,SHIPMENT_ATTRIBUTE2
         ,SHIPMENT_ATTRIBUTE3
         ,SHIPMENT_ATTRIBUTE4
         ,SHIPMENT_ATTRIBUTE5
         ,SHIPMENT_ATTRIBUTE6
         ,SHIPMENT_ATTRIBUTE7
         ,SHIPMENT_ATTRIBUTE8
         ,SHIPMENT_ATTRIBUTE9
         ,SHIPMENT_ATTRIBUTE10
         ,SHIPMENT_ATTRIBUTE11
         ,SHIPMENT_ATTRIBUTE12
         ,SHIPMENT_ATTRIBUTE13
         ,SHIPMENT_ATTRIBUTE14
         ,SHIPMENT_ATTRIBUTE15
         ,LAST_UPDATE_DATE
         ,LAST_UPDATED_BY
         ,LAST_UPDATE_LOGIN
         ,CREATION_DATE
         ,CREATED_BY
     --    ,REQUEST_ID
         ,PROGRAM_APPLICATION_ID
         ,PROGRAM_ID
         ,PROGRAM_UPDATE_DATE
         ,ORGANIZATION_ID
         ,ITEM_ATTRIBUTE_CATEGORY
         ,ITEM_ATTRIBUTE1
         ,ITEM_ATTRIBUTE2
         ,ITEM_ATTRIBUTE3
         ,ITEM_ATTRIBUTE4
         ,ITEM_ATTRIBUTE5
         ,ITEM_ATTRIBUTE6
         ,ITEM_ATTRIBUTE7
         ,ITEM_ATTRIBUTE8
         ,ITEM_ATTRIBUTE9
         ,ITEM_ATTRIBUTE10
         ,ITEM_ATTRIBUTE11
         ,ITEM_ATTRIBUTE12
         ,ITEM_ATTRIBUTE13
         ,ITEM_ATTRIBUTE14
         ,ITEM_ATTRIBUTE15
         ,UNIT_WEIGHT
         ,WEIGHT_UOM_CODE
         ,VOLUME_UOM_CODE
         ,UNIT_VOLUME
         ,TEMPLATE_ID
         ,TEMPLATE_NAME
         ,LINE_REFERENCE_NUM
         ,SOURCING_RULE_NAME
         ,TAX_STATUS_INDICATOR
         ,PROCESS_CODE
         ,PRICE_CHG_ACCEPT_FLAG
         ,PRICE_BREAK_FLAG
         ,PRICE_UPDATE_TOLERANCE
         ,TAX_USER_OVERRIDE_FLAG
         ,TAX_CODE_ID
         ,NOTE_TO_RECEIVER
         ,OKE_CONTRACT_HEADER_ID
         ,OKE_CONTRACT_HEADER_NUM
         ,OKE_CONTRACT_VERSION_ID
         ,SECONDARY_UNIT_OF_MEASURE
         ,SECONDARY_UOM_CODE
         ,SECONDARY_QUANTITY
         ,PREFERRED_GRADE
         ,VMI_FLAG
         ,AUCTION_HEADER_ID
         ,AUCTION_LINE_NUMBER
         ,AUCTION_DISPLAY_NUMBER
         ,BID_NUMBER
         ,BID_LINE_NUMBER
         ,ORIG_FROM_REQ_FLAG
         ,CONSIGNED_FLAG
         ,SUPPLIER_REF_NUMBER
         ,CONTRACT_ID
         ,JOB_ID
         ,AMOUNT
         ,JOB_NAME
         ,CONTRACTOR_FIRST_NAME
         ,CONTRACTOR_LAST_NAME
         ,DROP_SHIP_FLAG
         ,BASE_UNIT_PRICE
         ,TRANSACTION_FLOW_HEADER_ID
         ,JOB_BUSINESS_GROUP_ID
         ,JOB_BUSINESS_GROUP_NAME
    )
    SELECT
          XPLCS.INTERFACE_LINE_ID
         ,XPLCS.INTERFACE_HEADER_ID
         ,XPLCS.ACTION
         ,XPLCS.GROUP_CODE
         ,XPLCS.LINE_NUM
         ,XPLCS.PO_LINE_ID
         ,XPLCS.SHIPMENT_NUM
         ,XPLCS.LINE_LOCATION_ID
         ,XPLCS.SHIPMENT_TYPE
         ,XPLCS.REQUISITION_LINE_ID
         ,XPLCS.DOCUMENT_NUM
         ,XPLCS.RELEASE_NUM
         ,XPLCS.PO_HEADER_ID
         ,XPLCS.PO_RELEASE_ID
         ,XPLCS.SOURCE_SHIPMENT_ID
         ,XPLCS.CONTRACT_NUM
         ,XPLCS.LINE_TYPE
         ,XPLCS.LINE_TYPE_ID
         ,XPLCS.ITEM
         ,XPLCS.ITEM_ID
         ,XPLCS.ITEM_REVISION
         ,XPLCS.CATEGORY
         ,XPLCS.CATEGORY_ID
         ,XPLCS.ITEM_DESCRIPTION
         ,XPLCS.VENDOR_PRODUCT_NUM
         ,XPLCS.UOM_CODE
         ,XPLCS.UNIT_OF_MEASURE
         ,XPLCS.QUANTITY
         ,XPLCS.COMMITTED_AMOUNT
         ,XPLCS.MIN_ORDER_QUANTITY
         ,XPLCS.MAX_ORDER_QUANTITY
         ,XPLCS.UNIT_PRICE
         ,XPLCS.LIST_PRICE_PER_UNIT
         ,XPLCS.MARKET_PRICE
         ,XPLCS.ALLOW_PRICE_OVERRIDE_FLAG
         ,XPLCS.NOT_TO_EXCEED_PRICE
         ,XPLCS.NEGOTIATED_BY_PREPARER_FLAG
         ,XPLCS.UN_NUMBER
         ,XPLCS.UN_NUMBER_ID
         ,XPLCS.HAZARD_CLASS
         ,XPLCS.HAZARD_CLASS_ID
         ,XPLCS.NOTE_TO_VENDOR
         ,XPLCS.TRANSACTION_REASON_CODE
         ,XPLCS.TAXABLE_FLAG
         ,XPLCS.TAX_NAME
         ,XPLCS.TYPE_1099
         ,XPLCS.CAPITAL_EXPENSE_FLAG
         ,XPLCS.INSPECTION_REQUIRED_FLAG
         ,XPLCS.RECEIPT_REQUIRED_FLAG
         ,XPLCS.PAYMENT_TERMS
         ,XPLCS.TERMS_ID
         ,XPLCS.PRICE_TYPE
         ,XPLCS.MIN_RELEASE_AMOUNT
         ,XPLCS.PRICE_BREAK_LOOKUP_CODE
         ,XPLCS.USSGL_TRANSACTION_CODE
         ,XPLCS.CLOSED_CODE
         ,XPLCS.CLOSED_REASON
         ,XPLCS.CLOSED_DATE
         ,XPLCS.CLOSED_BY
         ,XPLCS.INVOICE_CLOSE_TOLERANCE
         ,XPLCS.RECEIVE_CLOSE_TOLERANCE
         ,XPLCS.FIRM_FLAG
         ,XPLCS.DAYS_EARLY_RECEIPT_ALLOWED
         ,XPLCS.DAYS_LATE_RECEIPT_ALLOWED
         ,XPLCS.ENFORCE_SHIP_TO_LOCATION_CODE
         ,XPLCS.ALLOW_SUBSTITUTE_RECEIPTS_FLAG
         ,XPLCS.RECEIVING_ROUTING
         ,XPLCS.RECEIVING_ROUTING_ID
         ,XPLCS.QTY_RCV_TOLERANCE
         ,XPLCS.OVER_TOLERANCE_ERROR_FLAG
         ,XPLCS.QTY_RCV_EXCEPTION_CODE
         ,XPLCS.RECEIPT_DAYS_EXCEPTION_CODE
         ,XPLCS.SHIP_TO_ORGANIZATION_CODE
         ,XPLCS.SHIP_TO_ORGANIZATION_ID
         ,XPLCS.SHIP_TO_LOCATION
         ,XPLCS.SHIP_TO_LOCATION_ID
         ,XPLCS.NEED_BY_DATE
         ,XPLCS.PROMISED_DATE
         ,XPLCS.ACCRUE_ON_RECEIPT_FLAG
         ,XPLCS.LEAD_TIME
         ,XPLCS.LEAD_TIME_UNIT
         ,XPLCS.PRICE_DISCOUNT
         ,XPLCS.FREIGHT_CARRIER
         ,XPLCS.FOB
         ,XPLCS.FREIGHT_TERMS
         ,XPLCS.EFFECTIVE_DATE
         ,XPLCS.EXPIRATION_DATE
         ,XPLCS.FROM_HEADER_ID
         ,XPLCS.FROM_LINE_ID
         ,XPLCS.FROM_LINE_LOCATION_ID
         ,XPLCS.LINE_ATTRIBUTE_CATEGORY_LINES
         ,XPLCS.LINE_ATTRIBUTE1
         ,XPLCS.LINE_ATTRIBUTE2
         ,XPLCS.LINE_ATTRIBUTE3
         ,XPLCS.LINE_ATTRIBUTE4
         ,XPLCS.LINE_ATTRIBUTE5
         ,XPLCS.LINE_ATTRIBUTE6
         ,XPLCS.LINE_ATTRIBUTE7
         ,XPLCS.LINE_ATTRIBUTE8
         ,XPLCS.LINE_ATTRIBUTE9
         ,XPLCS.LINE_ATTRIBUTE10
         ,XPLCS.LINE_ATTRIBUTE11
         ,XPLCS.LINE_ATTRIBUTE12
         ,XPLCS.LINE_ATTRIBUTE13
         ,XPLCS.LINE_ATTRIBUTE14
         ,XPLCS.LINE_ATTRIBUTE15
         ,XPLCS.SHIPMENT_ATTRIBUTE_CATEGORY
         ,XPLCS.SHIPMENT_ATTRIBUTE1
         ,XPLCS.SHIPMENT_ATTRIBUTE2
         ,XPLCS.SHIPMENT_ATTRIBUTE3
         ,XPLCS.SHIPMENT_ATTRIBUTE4
         ,XPLCS.SHIPMENT_ATTRIBUTE5
         ,XPLCS.SHIPMENT_ATTRIBUTE6
         ,XPLCS.SHIPMENT_ATTRIBUTE7
         ,XPLCS.SHIPMENT_ATTRIBUTE8
         ,XPLCS.SHIPMENT_ATTRIBUTE9
         ,XPLCS.SHIPMENT_ATTRIBUTE10
         ,XPLCS.SHIPMENT_ATTRIBUTE11
         ,XPLCS.SHIPMENT_ATTRIBUTE12
         ,XPLCS.SHIPMENT_ATTRIBUTE13
         ,XPLCS.SHIPMENT_ATTRIBUTE14
         ,XPLCS.SHIPMENT_ATTRIBUTE15
         ,sysdate--LAST_UPDATE_DATE
         ,G_USER_ID--LAST_UPDATED_BY
         ,G_USER_ID--LAST_UPDATE_LOGIN
         ,sysdate--CREATION_DATE
         ,G_USER_ID--CREATED_BY
    --     ,XPLCS.REQUEST_ID
         ,XPLCS.PROGRAM_APPLICATION_ID
         ,XPLCS.PROGRAM_ID
         ,XPLCS.PROGRAM_UPDATE_DATE
         ,XPLCS.ORGANIZATION_ID
         ,XPLCS.ITEM_ATTRIBUTE_CATEGORY
         ,XPLCS.ITEM_ATTRIBUTE1
         ,XPLCS.ITEM_ATTRIBUTE2
         ,XPLCS.ITEM_ATTRIBUTE3
         ,XPLCS.ITEM_ATTRIBUTE4
         ,XPLCS.ITEM_ATTRIBUTE5
         ,XPLCS.ITEM_ATTRIBUTE6
         ,XPLCS.ITEM_ATTRIBUTE7
         ,XPLCS.ITEM_ATTRIBUTE8
         ,XPLCS.ITEM_ATTRIBUTE9
         ,XPLCS.ITEM_ATTRIBUTE10
         ,XPLCS.ITEM_ATTRIBUTE11
         ,XPLCS.ITEM_ATTRIBUTE12
         ,XPLCS.ITEM_ATTRIBUTE13
         ,XPLCS.ITEM_ATTRIBUTE14
         ,XPLCS.ITEM_ATTRIBUTE15
         ,XPLCS.UNIT_WEIGHT
         ,XPLCS.WEIGHT_UOM_CODE
         ,XPLCS.VOLUME_UOM_CODE
         ,XPLCS.UNIT_VOLUME
         ,XPLCS.TEMPLATE_ID
         ,XPLCS.TEMPLATE_NAME
         ,XPLCS.LINE_REFERENCE_NUM
         ,XPLCS.SOURCING_RULE_NAME
         ,XPLCS.TAX_STATUS_INDICATOR
         ,XPLCS.PROCESS_CODE
         ,XPLCS.PRICE_CHG_ACCEPT_FLAG
         ,XPLCS.PRICE_BREAK_FLAG
         ,XPLCS.PRICE_UPDATE_TOLERANCE
         ,XPLCS.TAX_USER_OVERRIDE_FLAG
         ,XPLCS.TAX_CODE_ID
         ,XPLCS.NOTE_TO_RECEIVER
         ,XPLCS.OKE_CONTRACT_HEADER_ID
         ,XPLCS.OKE_CONTRACT_HEADER_NUM
         ,XPLCS.OKE_CONTRACT_VERSION_ID
         ,XPLCS.SECONDARY_UNIT_OF_MEASURE
         ,XPLCS.SECONDARY_UOM_CODE
         ,XPLCS.SECONDARY_QUANTITY
         ,XPLCS.PREFERRED_GRADE
         ,XPLCS.VMI_FLAG
         ,XPLCS.AUCTION_HEADER_ID
         ,XPLCS.AUCTION_LINE_NUMBER
         ,XPLCS.AUCTION_DISPLAY_NUMBER
         ,XPLCS.BID_NUMBER
         ,XPLCS.BID_LINE_NUMBER
         ,XPLCS.ORIG_FROM_REQ_FLAG
         ,XPLCS.CONSIGNED_FLAG
         ,XPLCS.SUPPLIER_REF_NUMBER
         ,XPLCS.CONTRACT_ID
         ,XPLCS.JOB_ID
         ,XPLCS.AMOUNT
         ,XPLCS.JOB_NAME
         ,XPLCS.CONTRACTOR_FIRST_NAME
         ,XPLCS.CONTRACTOR_LAST_NAME
         ,XPLCS.DROP_SHIP_FLAG
         ,XPLCS.BASE_UNIT_PRICE
         ,XPLCS.TRANSACTION_FLOW_HEADER_ID
         ,XPLCS.JOB_BUSINESS_GROUP_ID
         ,XPLCS.JOB_BUSINESS_GROUP_NAME
    FROM xx_po_lines_conv_stg XPLCS
    WHERE XPLCS.batch_id=p_batch_id
    AND   XPLCS.process_flag=4;
    EXCEPTION
        WHEN OTHERS THEN
        x_retcode := 2;
        x_errbuf  := 'Exception While inserting data into PO_LINES_INTERFACE - '||SQLERRM;
        display_log(x_errbuf||SQLERRM);
        RAISE EX_INSERT;
    END;

    BEGIN
    INSERT INTO PO_DISTRIBUTIONS_INTERFACE
    (
          INTERFACE_HEADER_ID
         ,INTERFACE_LINE_ID
         ,INTERFACE_DISTRIBUTION_ID
         ,DESTINATION_TYPE_CODE
         ,DESTINATION_ORGANIZATION_ID
         ,QUANTITY_ORDERED
         ,CREATED_BY
         ,CREATION_DATE
         ,LAST_UPDATED_BY
         ,LAST_UPDATE_DATE
         ,LAST_UPDATE_LOGIN
    )
    SELECT
          PLI.INTERFACE_HEADER_ID
         ,PLI.INTERFACE_LINE_ID
         ,PO_DISTRIBUTIONS_S.NEXTVAL
         ,G_DESTINATION_TYPE_CODE
         ,PLI.SHIP_TO_ORGANIZATION_ID
         ,PLI.quantity
         ,G_USER_ID
         ,SYSDATE
         ,G_USER_ID
         ,SYSDATE
         ,G_USER_ID
    FROM  PO_LINES_INTERFACE PLI,
          PO_HEADERS_INTERFACE PHI
    WHERE PLI.INTERFACE_HEADER_ID=PHI.INTERFACE_HEADER_ID
    AND   PHI.BATCH_ID=P_BATCH_ID;
    EXCEPTION
        WHEN OTHERS THEN
        x_retcode := 2;
        x_errbuf  := 'Exception While inserting data into PO_DISTRIBUTIONS_INTERFACE - '||SQLERRM;
        display_log(x_errbuf||SQLERRM);
        RAISE EX_INSERT;
    END;

    COMMIT;
    ------------------------------------------
    --Storing the current Org_id in a variable
    ------------------------------------------
    ln_original_org_id := FND_PROFILE.VALUE('ORG_ID');

    ln_import_req_index:=0;
    FOR lcu_operating_unit_rec IN lcu_operating_unit
    LOOP

                 -- Apps Initialization to overcome the problem of passing charge account
                 -- When creating Purchase order in a OU different from current responsibility.
                 -- Added for v1.4
                 FND_GLOBAL.APPS_INITIALIZE(user_id          => G_USER_ID
                                           ,resp_id          => lcu_operating_unit_rec.responsibility_id
                                           ,resp_appl_id     => lcu_operating_unit_rec.application_id
                                           );   
        ---------------------------------------------------------------
        -- Submitting Standard Purchase Order Import concurrent program
        ---------------------------------------------------------------
        ln_conc_request_id := FND_REQUEST.submit_request(
                                                          application  => 'PO'
                                                         ,program      => 'POXPOPDOI'
                                                         ,description  => 'Import Standard Purchase Orders'
                                                         ,start_Time   => NULL
                                                         ,sub_request  => FALSE
                                                         ,argument1    => NULL
                                                         ,argument2    => 'STANDARD' 
                                                         ,argument3    => NULL
                                                         ,argument4    => 'N'
                                                         ,argument5    => NULL
                                                         ,argument6    => 'Approved'
                                                         ,argument7    => NULL
                                                         ,argument8    => p_batch_id
                                                         ,argument9    => lcu_operating_unit_rec.org_id
                                                         ,argument10   => NULL
                                                        );
        IF ln_conc_request_id = 0 THEN
            x_errbuf  := FND_MESSAGE.GET;
            display_log('Standard PO Import program failed to submit: ' || x_errbuf);
            RAISE EX_SUBMIT_IMPORT;
        ELSE
            ln_import_req_index:=ln_import_req_index+1;
            lt_conc_request_id(ln_import_req_index):=ln_conc_request_id;
            COMMIT;
            display_log('Submitted Standard PO Import program Successfully : '|| TO_CHAR( ln_conc_request_id ));
            END IF;
    END LOOP;

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
                    WHERE  FCR.request_id = lt_conc_request_id(i);--ln_conc_request_id;
                    IF  lc_phase = 'C' THEN
                        EXIT;
                    ELSE
                        DBMS_LOCK.SLEEP(G_SLEEP);
                   END IF;
               END LOOP;
           END IF;
        END LOOP;
    END IF;

    ---------------------------------------------------------
    --Updating Process Flags for Successful PO Header Records
    ---------------------------------------------------------
    OPEN lcu_success_records;
    FETCH lcu_success_records BULK COLLECT INTO lt_success_rowid;
        IF lt_success_rowid.count<>0 THEN
            FORALL i IN lt_success_rowid.FIRST..lt_success_rowid.LAST
            UPDATE xx_po_hdrs_conv_stg XPHCS
            SET    XPHCS.process_flag=7
                  ,XPHCS.error_message=NULL
            WHERE  ROWID = lt_success_rowid(i);
        END IF;
    CLOSE lcu_success_records;

    -------------------------------------------------------
    --Updating Process Flags for Successful PO Line Records
    -------------------------------------------------------
    UPDATE xx_po_lines_conv_stg XPLCS1
    SET    XPLCS1.process_flag=7
          ,XPLCS1.error_message=NULL
    WHERE  XPLCS1.ROWID IN (SELECT     XPLCS.ROWID
                                FROM   xx_po_hdrs_conv_stg XPHCS
                                      ,xx_po_lines_conv_stg XPLCS
                                WHERE  XPHCS.record_id=XPLCS.parent_record_id--XPHCS.control_id=XPLCS.control_id--16 Jul
                                AND    XPHCS.batch_id=p_batch_id
                                AND    XPHCS.process_flag=7);

    ----------------------------------------
    --Logging Errors for Errored PO Records
    ----------------------------------------
    OPEN lcu_errored_records;
    FETCH lcu_errored_records BULK COLLECT INTO lt_error_control_id,lt_error_message,lt_table_name;
        IF lt_error_control_id.count<>0 THEN
            FOR i IN lt_error_control_id.FIRST..lt_error_control_id.LAST
            LOOP
                SELECT DECODE(lt_table_name(i),'PO_HEADERS_INTERFACE',G_HDR_TABLE_NAME
                                              ,'PO_LINES_INTERFACE',G_LINE_TABLE_NAME
                                              ,'PO_DESTRIBUTIONS_INTERFACE',G_LINE_TABLE_NAME
                                              ,G_HDR_TABLE_NAME
                             )
                INTO   lc_staging_table_name
                FROM dual;
                bulk_log_error( p_error_msg            =>  lt_error_message(i)
                               ,p_error_code           =>  NULL
                               ,p_control_id           =>  lt_error_control_id(i)
                               ,p_request_id           =>  fnd_global.conc_request_id
                               ,p_converion_id         =>  gn_conversion_id
                               ,p_package_name         =>  G_PACKAGE_NAME
                               ,p_procedure_name       =>  'process_po'
                               ,p_staging_table_name   =>  lc_staging_table_name
                               ,p_staging_column_name  =>  NULL
                               ,p_staging_column_value =>  NULL
                               ,p_batch_id             =>  p_batch_id
                              );

            END LOOP;
        END IF;
    CLOSE lcu_errored_records;
    XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

    ------------------------------------------------------
    --Updating Process Flags for Errored PO Header Records
    ------------------------------------------------------
    UPDATE xx_po_hdrs_conv_stg XPHCS
    SET    process_flag = 6
    WHERE  XPHCS.batch_id = p_batch_id
    AND    XPHCS.process_flag = 4;--16jul

    ----------------------------------------------------
    --Updating Process Flags for Errored PO Line Records
    ----------------------------------------------------
    UPDATE xx_po_lines_conv_stg XPLCS
    SET    process_flag = 6
    WHERE  XPLCS.batch_id = p_batch_id
    AND    XPLCS.process_flag = 4; --16Jul

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
            lt_int_header_id(i):= lt_error_update_header(i).interface_header_id;
            lc_hdr_error_message:=NULL;
            FOR lcu_hdr_rec IN lcu_hdr(lt_error_update_header(i).interface_header_id)
            LOOP
                lc_hdr_error_message:=SUBSTR(lc_hdr_error_message||lcu_hdr_rec.error_message,1,500);
            END LOOP;
            lt_hdr_error_message(i):=lc_hdr_error_message;
        END LOOP;
    END IF;

    FORALL i IN lt_error_update_header.FIRST..lt_error_update_header.LAST
    UPDATE xx_po_hdrs_conv_stg XPHCS
    SET error_message= lt_hdr_error_message(i)
    WHERE interface_header_id=lt_int_header_id(i);

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
            lt_int_line_id(i)  := lt_error_update_line(i).interface_line_id;
            lc_line_error_message:=NULL ;
            FOR lcu_line_rec IN lcu_line(lt_error_update_line(i).interface_line_id)
            LOOP
                lc_line_error_message:=SUBSTR(lc_line_error_message||lcu_line_rec.error_message,1,500);
            END LOOP;
            lt_line_error_message(i):=lc_line_error_message;
        END LOOP;
    END IF;

    FORALL i IN lt_error_update_line.FIRST..lt_error_update_line.LAST
    UPDATE xx_po_lines_conv_stg XPLCS
    SET error_message= lt_line_error_message(i)
    WHERE interface_line_id=lt_int_line_id(i);

    COMMIT;

EXCEPTION
    WHEN EX_INSERT THEN
        x_retcode := 2;
        IF x_errbuf LIKE '% PO_HEADERS_INTERFACE - %' THEN
            lc_staging_table_name:=G_HDR_TABLE_NAME;
        ELSIF x_errbuf LIKE'%PO_LINES_INTERFACE - %' THEN
            lc_staging_table_name:=G_LINE_TABLE_NAME;
        ELSE
            lc_staging_table_name:=NULL;
        END IF;
        bulk_log_error( p_error_msg            =>  x_errbuf
                       ,p_error_code           =>  NULL
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  fnd_global.conc_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'validate_po'
                       ,p_staging_table_name   =>  lc_staging_table_name
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                       ,p_batch_id             =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        gc_sqlerrm:=x_errbuf;
        gc_sqlcode:=x_retcode;
    WHEN EX_SUBMIT_IMPORT THEN
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  fnd_global.conc_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_po'
                       ,p_staging_table_name   =>  G_HDR_TABLE_NAME
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                       ,p_batch_id             =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        gc_sqlerrm:=x_errbuf;
        gc_sqlcode:=x_retcode;
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error in process_po - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  gc_sqlerrm
                       ,p_error_code           =>  gc_sqlcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  fnd_global.conc_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_po'
                       ,p_staging_table_name   =>  G_HDR_TABLE_NAME
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                       ,p_batch_id             =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        gc_sqlerrm:=x_errbuf;
        gc_sqlcode:=x_retcode;
        IF lcu_operating_unit%ISOPEN THEN
            CLOSE lcu_operating_unit;
        END IF;
END process_po;

-- +===================================================================+
-- | Name        :  POST_PROCESSING                                    |
-- | Description :  This procedure is invoked from the child main      |
-- |                procedure. This procedure will link the newly      |
-- |                created purchase orders to existing quotations     |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE post_processing(
                           x_errbuf    OUT NOCOPY VARCHAR2
                          ,x_retcode   OUT NOCOPY VARCHAR2
                          ,p_batch_id  IN         VARCHAR2
                         )
IS

------------------------------------------
--Declaring Local Variables and Exceptions
------------------------------------------
ln_price_break_id      NUMBER;
ln_price_override      po_line_locations_all.price_override%type;
lc_return_status       VARCHAR2(02);
ln_header_id           po_headers_all.po_header_id%type;
ln_line_id             po_lines_all.po_line_id%type;
ln_line_location_id    po_line_locations_all.line_location_id%type;

--------------------------------
--Declaring Table Type variables
--------------------------------
TYPE header_id_tbl_typ IS TABLE OF po_headers_all.po_header_id%type
INDEX BY BINARY_INTEGER;
lt_header_id header_id_tbl_typ;

TYPE line_id_tbl_typ IS TABLE OF po_lines_all.po_line_id%type
INDEX BY BINARY_INTEGER;
lt_line_id line_id_tbl_typ;

TYPE line_location_id_tbl_typ IS TABLE OF po_line_locations_all.line_location_id%type
INDEX BY BINARY_INTEGER;
lt_line_location_id line_location_id_tbl_typ;

TYPE rowid_tbl_typ IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_line_rowid                  rowid_tbl_typ;
lt_line_location_rowid         rowid_tbl_typ;

----------------------------------------------------------------
--Cursor to fetch Successful Purchase Orders for post processing
----------------------------------------------------------------
CURSOR lcu_po_details
IS
SELECT XPHIS.vendor_id
      ,XPHIS.vendor_site_id
      ,PLA.item_id
      ,PLA.quantity
      ,PHA.po_header_id
      ,PLA.po_line_id
      ,PLLA.ship_to_organization_id
      ,PLLA.ship_to_location_id
      ,PHA1.po_header_id quot_header_id
      ,PLA1.po_line_id quot_line_id
      ,PLA.ROWID line_rowid
      ,PLLA.ROWID line_location_rowid
FROM   xx_po_hdrs_conv_stg   XPHIS,
       po_headers_all        PHA
      ,po_lines_all          PLA
      ,po_line_locations_all PLLA
      ,po_headers_all        PHA1
      ,po_lines_all          PLA1
WHERE  XPHIS.batch_id              = p_batch_id
AND    XPHIS.vendor_doc_num        = PHA.vendor_order_num
AND    PHA.po_header_id            = PLA.po_header_id
AND    PLA.po_line_id              = PLLA.po_line_id
AND    PLA1.item_id                = PLA.item_id
AND    PLA1.po_header_id           = PHA1.po_header_id
AND    PHA1.vendor_id              = XPHIS.vendor_id
AND    PHA1.type_lookup_code       = 'QUOTATION'
AND    PHA1.quote_type_lookup_code = 'CATALOG';

TYPE po_details_tbl_typ IS TABLE OF lcu_po_details%rowtype
INDEX BY BINARY_INTEGER;
lt_po_details po_details_tbl_typ;

--------------------------------------------------------
--Cursor to fetch PO Id's to link the PO's to Quotations
--------------------------------------------------------
CURSOR lcu_link_quotation(p_item_id IN NUMBER,p_vendor_id IN NUMBER,p_price_override IN NUMBER)
IS
SELECT PHA.po_header_id
      ,PLA.po_line_id
      ,PLLA.line_location_id
FROM   po_headers_all        PHA
      ,po_lines_all          PLA
      ,po_line_locations_all PLLA
WHERE  PLA.item_id                = p_item_id
AND    PLA.po_header_id           = PHA.po_header_id
AND    PLA.po_line_id             = PLLA.po_line_id
AND    PHA.vendor_id              = p_vendor_id
AND    PHA.type_lookup_code       = 'QUOTATION'
AND    PHA.quote_type_lookup_code = 'CATALOG'
AND    PLLA.price_override        = p_price_override;

BEGIN
    display_log('*****');
    OPEN  lcu_po_details;
    FETCH lcu_po_details BULK COLLECT INTO lt_po_details;
    CLOSE lcu_po_details;

    IF lt_po_details.COUNT<>0 THEN
        display_Log ('Linking POs to Quotation');
        FOR i IN lt_po_details.FIRST..lt_po_details.LAST
            LOOP
            lt_line_rowid(i)            := lt_po_details(i).line_rowid;
            lt_line_location_rowid(i)   := lt_po_details(i).line_location_rowid;
            
            --------------------------------------------------------------------------------------------------
            --Calling Standard API PO_SOURCING2_SV.GET_BREAK_PRICE to get the price from the referenced quote.
            --------------------------------------------------------------------------------------------------
            PO_SOURCING2_SV.get_break_price(
                                             p_api_version                 => 1.0
                                            ,p_order_quantity              => lt_po_details(i).quantity
                                            ,p_ship_to_org                 => lt_po_details(i).ship_to_organization_id
                                            ,p_ship_to_loc                 => lt_po_details(i).ship_to_location_id
                                            ,p_po_line_id                  => lt_po_details(i).quot_line_id--po_line_id
                                            ,p_cum_flag                    => TRUE
                                            ,p_need_by_date                => NULL--lt_po_details(i).need_by_date
                                            ,p_line_location_id            => NULL--lt_po_details(i).line_location_id
                                            ,x_price_break_id              => ln_price_break_id
                                            ,x_price                       => ln_price_override
                                            ,x_return_status               => lc_return_status
                                           );

            display_log('Price Override....'||ln_price_override);
            display_log('Item Id....'||lt_po_details(i).item_id);
            display_log('Vendor Id....'||lt_po_details(i).vendor_id);
            display_log('Quotation Line Id...'||lt_po_details(i).quot_line_id);

            OPEN  lcu_link_quotation(lt_po_details(i).item_id,lt_po_details(i).vendor_id,ln_price_override);
            FETCH lcu_link_quotation INTO ln_header_id,ln_line_id,ln_line_location_id;
            IF lcu_link_quotation%FOUND THEN
                lt_header_id(i)             := ln_header_id;
                lt_line_id(i)               := ln_line_id;
                lt_line_location_id(i)      := ln_line_location_id;
            ELSE 
                lt_header_id(i)             := NULL;
                lt_line_id(i)               := NULL;
                lt_line_location_id(i)      := NULL;
            END IF;
            CLOSE lcu_link_quotation;

            Display_log('Linked Quotation Detail: Header Id....'||ln_header_id||'  Line Id....'||ln_line_id||'  Line Location Id....'||ln_line_location_id);
        END LOOP;

        ------------------------------------------------------
        --Updating po line table  id's to link it to quotation
        ------------------------------------------------------
        FORALL i IN 1..lt_line_id.COUNT
            UPDATE po_lines_all PLA
            SET    PLA.from_header_id          = lt_header_id(i)
                  ,PLA.from_line_id            = lt_line_id(i)
                  ,PLA.from_line_location_id   = lt_line_location_id(i)
            WHERE  PLA.ROWID                   = lt_line_rowid(i);

        ---------------------------------------------------------------
        --Updating po line location table  id's to link it to quotation
        ---------------------------------------------------------------
        FORALL i IN 1..lt_line_id.COUNT
            UPDATE po_line_locations_all PLLA
            SET    PLLA.from_header_id         = lt_header_id(i)
                  ,PLLA.from_line_id           = lt_line_id(i)
                  ,PLLA.from_line_location_id  = lt_line_location_id(i)
            WHERE  PLLA.ROWID                  = lt_line_location_rowid(i);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        x_errbuf:=  'Unexpected Error in Post Processing '||SQLERRM;
        display_log(x_errbuf);
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  x_errbuf
                       ,p_error_code           =>  x_retcode
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  fnd_global.conc_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'process_po'
                       ,p_staging_table_name   =>  NULL
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                       ,p_batch_id             =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
END post_processing;

-- +===================================================================+
-- | Name        :  child_main                                         |
-- | Description :  This procedure is invoked from the OD: PO Purchase |
-- |                Order Conversion Child Program.This would          |
-- |                submit conversion programs based on input    .     |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE child_main(
                      x_errbuf             OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag IN         VARCHAR2
                     ,p_reset_status_flag  IN         VARCHAR2
                     ,p_batch_id           IN         NUMBER
                     ,p_debug_flag         IN         VARCHAR2
                )
IS
------------------------------------------
--Declaring Local Variables and Exceptions
------------------------------------------
EX_ENTRY_EXCEP              EXCEPTION;

lx_errbuf                   VARCHAR2(2000);
lx_retcode                  VARCHAR2(20);
ln_po_header_processed      PLS_INTEGER;
ln_po_header_failed         PLS_INTEGER;
ln_po_header_invalid        PLS_INTEGER;
ln_po_line_processed        PLS_INTEGER;
ln_po_line_failed           PLS_INTEGER;
ln_po_line_invalid          PLS_INTEGER;
ln_request_id               PLS_INTEGER;
ln_po_header_total          PLS_INTEGER;
ln_po_line_total            PLS_INTEGER;

------------------------------------------------------
--Cursor to get the Control Information for PO Headers
------------------------------------------------------
CURSOR lcu_header_info (p_batch_id IN NUMBER)
IS
SELECT COUNT (CASE WHEN process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='6' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='7' THEN 1 END)
FROM   xx_po_hdrs_conv_stg XPHCS
WHERE  XPHCS.batch_id=p_batch_id;

----------------------------------------------------
--Cursor to get the Control Information for PO Lines
----------------------------------------------------
CURSOR lcu_line_info (p_batch_id IN NUMBER)
IS
SELECT COUNT (CASE WHEN process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='6' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='7' THEN 1 END)
FROM   xx_po_lines_conv_stg XPLCS
WHERE  XPLCS.batch_id=p_batch_id;

BEGIN
    BEGIN
        gc_debug_flag:= p_debug_flag;
        display_log('*Batch_id* '||p_batch_id);
        IF  NVL(p_reset_status_flag,'N') = 'Y' THEN
            update_batch_id ( x_errbuf
                             ,x_retcode
                             ,p_batch_id
                            );
        END IF;

        ------------------------------
        --Initializing local variables
        ------------------------------
        ln_po_header_total          :=0;
        ln_po_header_processed      :=0;
        ln_po_header_failed         :=0;
        ln_po_header_invalid        :=0;

        ------------------------------------------
        --Calling validate_po for Data Validations
        ------------------------------------------
        display_log('Validation....');
        validate_po(
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
            --------------------
            --Calling process PO
            --------------------
            display_log('Processing....');
            process_po(
                        x_errbuf                   =>lx_errbuf
                       ,x_retcode                  =>lx_retcode
                       ,p_batch_id                 =>p_batch_id
                      );
            IF lx_retcode <> 0 THEN
                x_retcode := lx_retcode;
                CASE WHEN x_errbuf IS NULL
                THEN x_errbuf  := lx_errbuf;
                ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
                END CASE;
            END IF;

            -------------------------
            --Calling post_processing
            -------------------------
            display_log('Post Processing....');
            post_processing(
                             x_errbuf                   =>lx_errbuf
                            ,x_retcode                  =>lx_retcode
                            ,p_batch_id                 =>p_batch_id
                           );
            IF lx_retcode <> 0 THEN
                x_retcode := lx_retcode;
                CASE WHEN x_errbuf IS NULL
                THEN x_errbuf  := lx_errbuf;
                ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
                END CASE;
            END IF;
        END IF;--p_valdate_only_flag='N'
    EXCEPTION
        WHEN OTHERS THEN
        lx_retcode := 2;
    --  display_log('SUB_OTHERS'||x_retcode);
        CASE WHEN x_errbuf IS NULL
            THEN x_errbuf  := gc_sqlerrm;
            ELSE x_errbuf  := x_errbuf||'/'||gc_sqlerrm;
        END CASE;
            bulk_log_error(
                            p_error_msg            =>  SQLERRM
                           ,p_error_code           =>  SQLCODE
                           ,p_control_id           =>  NULL
                           ,p_request_id           =>  fnd_global.conc_request_id
                           ,p_converion_id         =>  gn_conversion_id
                           ,p_package_name         =>  G_PACKAGE_NAME
                           ,p_procedure_name       =>  'child_main'
                           ,p_staging_table_name   =>  NULL
                           ,p_staging_column_name  =>  NULL
                           ,p_staging_column_value =>  NULL
                           ,p_batch_id             =>  p_batch_id
                          );
         XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END ;
    -------------------------------------------------------------
    --Getting the Master Request Id to update Control Information
    -------------------------------------------------------------
    get_master_request_id(
                           p_conversion_id     => gn_conversion_id
                          ,p_batch_id          => p_batch_id
                          ,x_master_request_id => ln_request_id
                         );
    IF ln_request_id IS NOT NULL THEN

        ------------------------------------------------------------------------
        --Fetching Number of Invalid, Processing Failed and Processed PO Headers
        ------------------------------------------------------------------------
        OPEN lcu_header_info(p_batch_id);
        FETCH lcu_header_info INTO ln_po_header_invalid,ln_po_header_failed,ln_po_header_processed;
        CLOSE lcu_header_info;

        ----------------------------------------------------------------------
        --Fetching Number of Invalid, Processing Failed and Processed PO Lines
        ----------------------------------------------------------------------
        OPEN lcu_line_info(p_batch_id);
        FETCH lcu_line_info INTO ln_po_line_invalid,ln_po_line_failed,ln_po_line_processed;
        CLOSE lcu_line_info;

        ----------------------------------
        --Updating the Control Information
        ----------------------------------
        XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                                                        p_conc_mst_req_id             => ln_request_id --APPS.FND_GLOBAL.CONC_REQUEST_ID
                                                       ,p_batch_id                    => p_batch_id
                                                       ,p_conversion_id               => gn_conversion_id
                                                       ,p_num_bus_objs_failed_valid   => ln_po_header_invalid
                                                       ,p_num_bus_objs_failed_process => ln_po_header_failed
                                                       ,p_num_bus_objs_succ_process   => ln_po_header_processed
                                                      );
    END IF;

    -------------------------------------------------
    -- Launch the Exception Log Report for this batch
    -------------------------------------------------
    launch_exception_report(
                             p_batch_id         =>p_batch_id                    -- Batch id
                            ,p_conc_req_id      =>fnd_global.conc_request_id    -- Child Request id
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

    ------------------------------------------------------
    --Displaying the PO Header Information in the Out file
    ------------------------------------------------------
    ln_po_header_total := ln_po_header_invalid+ln_po_header_failed + ln_po_header_processed;--1
    display_out(RPAD('=',58,'='));
    display_out(RPAD('Total No. Of Purchase Order Header Records      : ',49,' ')||RPAD(ln_po_header_total,9,' '));
    display_out(RPAD('No. Of Purchase Order Header Records Processed  : ',49,' ')||RPAD(ln_po_header_processed,9,' '));
    display_out(RPAD('No. Of Purchase Order Header Records Errored    : ',49,' ')||RPAD(ln_po_header_failed+ln_po_header_invalid,9,' '));
    display_out(RPAD('=',58,'='));

    ---------------------------------------------------
    --Displaying the PO Line Information in the Out file
    ----------------------------------------------------
    ln_po_line_total := ln_po_line_invalid+ln_po_line_failed + ln_po_line_processed;--1
    display_out(RPAD('=',58,'='));
    display_out(RPAD('Total No. Of Purchase Order Line Records      : ',49,' ')||RPAD(ln_po_line_total,9,' '));
    display_out(RPAD('No. Of Purchase Order Line Records Processed  : ',49,' ')||RPAD(ln_po_line_processed,9,' '));
    display_out(RPAD('No. Of Purchase Order Line Records Errored    : ',49,' ')||RPAD(ln_po_line_failed+ln_po_line_invalid,9,' '));
    display_out(RPAD('=',58,'='));


EXCEPTION
    WHEN OTHERS THEN
        x_errbuf  := 'Unexpected error in child_main - '||SQLERRM;
        x_retcode := 2;
        bulk_log_error( p_error_msg            =>  SQLERRM
                       ,p_error_code           =>  SQLCODE
                       ,p_control_id           =>  NULL
                       ,p_request_id           =>  fnd_global.conc_request_id
                       ,p_converion_id         =>  gn_conversion_id
                       ,p_package_name         =>  G_PACKAGE_NAME
                       ,p_procedure_name       =>  'child_main'
                       ,p_staging_table_name   =>  NULL
                       ,p_staging_column_name  =>  NULL
                       ,p_staging_column_value =>  NULL
                       ,p_batch_id             =>  p_batch_id
                        );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
END child_main;
END XX_PO_LGCY_PO_CONV_PKG;
/
EXIT;
/
SHOW ERRORS
EXIT;

