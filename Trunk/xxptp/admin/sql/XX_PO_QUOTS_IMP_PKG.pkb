5SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_QUOTS_IMP_PKG
 -- +=====================================================================================+
 -- |                  Office Depot - Project Simplify                                    |
 -- |                 Oracle NAIO/WIPRO/Office Depot/Consulting Organization              |
 -- +=====================================================================================+
 -- | Name             :  XX_PO_QUOTS_IMP_PKG.pkb                                         |
 -- | Description      :  This package body is used in PO Quotation Conversion.           |
 -- |                                                                                     |
 -- | Change Record:                                                                      |
 -- |===============                                                                      |
 -- |Version   Date        Author           Remarks                                       |
 -- |=======   ==========  =============    ==============================================|
 -- |Draft 1a  16-MAY-2007  Chandan U H      Initial draft version with Master Conversion |
 -- |                                        Program Logic.                               |
 -- |Draft 1b  23-MAY-2007  Chandan U H      Incorporated Review Comments.                |
 -- | 1.0      25-MAY-2007  Chandan U H      Baselined.                                   |
 -- | 1.1      18-JUN-2007  Vikas Raina      Updated for updated CV.060.                  |
 -- | 1.2      02-JUL-2007  Ritu Shukla      Updated for updated CV.060.                  |
 -- | 1.3      18-Jul-2007  Ritu Shukla      Included Debug Flag,Updated after code review|
 -- | 1.4      17-Sept-2007 Madhukar Salunke Added G_PO_SOURCE, Mapped line start date and|
 -- |                                        If the end tiered quantity and cost is 0 then|
 -- |                                        no need to populate the price breaks.        |
 -- | 1.5      21-Nov-2007 Madhukar Salunke  Added Quotation approval API, Currency       |
 -- |                                        validation and added logic to reject         |
 -- |                                        duplicate record for same supplier.          |
 -- | 1.6      28-Nov-2007  Ritu Shukla      Updated for review comments from onsite      |
 -- +=====================================================================================+
AS
-- ---------------------------
-- Global Variable Declaration
-- ---------------------------

G_SLEEP                         CONSTANT PLS_INTEGER  :=  10;
G_COMN_APPLICATION              CONSTANT VARCHAR2(30) := 'XXCOMN';
G_SUMRY_REPORT_PRGM             CONSTANT VARCHAR2(30) := 'XXCOMCONVSUMMREP';
G_EXCEP_REPORT_PRGM             CONSTANT VARCHAR2(30) := 'XXCOMCONVEXPREP';
G_CONVERSION_CODE               CONSTANT VARCHAR2(30) := 'C0301_PurchasePriceFromRMS';
G_CHLD_PROG_APPLICATION         CONSTANT VARCHAR2(30) := 'PO';
G_CHLD_PROG_EXECUTABLE          CONSTANT VARCHAR2(30) := 'XX_PO_QUOTS_IMP_PKG_MAIN';
G_PACKAGE_NAME                  CONSTANT VARCHAR2(30) := 'XX_PO_QUOTS_IMP_PKG';
G_STAGING_TABLE_NAME            CONSTANT VARCHAR2(30) := 'XX_PO_QUOTATION_CONV_STG';
G_SOURCE_CODE                   CONSTANT VARCHAR2(30) := 'C0301 - RMS_PRICE_CONV';
G_PO_SOURCE                     CONSTANT VARCHAR2(30) := 'NA-RMSQTN';
G_USER_ID                       CONSTANT NUMBER       :=  FND_GLOBAL.user_id;

gn_conversion_id                PLS_INTEGER;
gn_batch_count                  PLS_INTEGER := 0;
gn_record_count                 PLS_INTEGER := 0;
gn_req_id                       PLS_INTEGER := 0;
gn_request_id                   FND_CONCURRENT_REQUESTS.request_id%TYPE ;
gn_batch_size                   VARCHAR2(15);
gn_max_child_req                VARCHAR2(15);
gn_debug_flag                   VARCHAR2(1);

GN_INDEX_REQUEST_ID             PLS_INTEGER    := 0;
GC_APPROVAL_TYPE                po_quotation_approvals_all.approval_type%TYPE :='ALL ORDERS' ;
GC_APPROVAL_REASON              po_quotation_approvals_all.approval_reason%TYPE := 'Quotation from RMS';
GC_COMMENTS                     po_quotation_approvals_all.comments%TYPE := 'Quotation from RMS';
G_AGENT_ID                      per_all_people_f.person_id%TYPE;--Stores Agent Id

----------------------------------
-- Type declaration for request_id
----------------------------------

TYPE req_id_tbl_type IS TABLE OF FND_CONCURRENT_REQUESTS.request_id%TYPE
INDEX BY BINARY_INTEGER;

TYPE xx_qty_price_rec IS RECORD (
                                  quantity NUMBER
                                 ,price    NUMBER
                                );

TYPE  gt_import_prg_req_rec IS RECORD
                                 (
                                  request_id fnd_concurrent_requests.request_id%TYPE
                                  );

TYPE row_id_tbl_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
gt_row_id  row_id_tbl_type;

-------------------------------------
-- Variable for request_id table type
-------------------------------------
lt_req_id req_id_tbl_type;

--------------------------------------------
-- Table type for holding staging table data
--------------------------------------------

TYPE stg_tbl_type                IS  TABLE  OF  xx_po_quotation_conv_stg%ROWTYPE                 INDEX BY BINARY_INTEGER;
TYPE ctrl_id_tbl_type            IS  TABLE  OF  xx_po_quotation_conv_stg.control_id%TYPE         INDEX BY BINARY_INTEGER;
TYPE pro_flg_tbl_type            IS  TABLE  OF  xx_po_quotation_conv_stg.process_flag%TYPE       INDEX BY BINARY_INTEGER;
TYPE err_msg_tbl_type            IS  TABLE  OF  xx_po_quotation_conv_stg.error_message%TYPE      INDEX BY BINARY_INTEGER;
TYPE qty_price_tbl_type          IS  TABLE  OF  xx_qty_price_rec                                 INDEX BY BINARY_INTEGER;
TYPE success_po_hdr_tbl_type     IS  TABLE  OF  xx_po_quotation_conv_stg.vendor_site_id%TYPE     INDEX BY BINARY_INTEGER;
TYPE unsuccess_po_hdr_tbl_type   IS  TABLE  OF  xx_po_quotation_conv_stg.vendor_site_id%TYPE     INDEX BY BINARY_INTEGER;
TYPE lt_bat_cntrl_id_tbl_type    IS  TABLE  OF  xx_po_quotation_conv_stg.control_id%TYPE         INDEX BY BINARY_INTEGER;
TYPE g_ready_for_proc_tbl_type   IS  TABLE  OF  xx_po_quotation_conv_stg%ROWTYPE                 INDEX BY BINARY_INTEGER;
TYPE inv_itm_id_tbl_type         IS  TABLE  OF  xx_po_quotation_conv_stg.inventory_item_id%TYPE  INDEX BY BINARY_INTEGER;
TYPE ven_site_id_tbl_type        IS  TABLE  OF  xx_po_quotation_conv_stg.vendor_site_id%TYPE     INDEX BY BINARY_INTEGER;
TYPE ven_id_tbl_type             IS  TABLE  OF  xx_po_quotation_conv_stg.ebs_vendor_id%TYPE      INDEX BY BINARY_INTEGER;
TYPE org_id_tbl_type             IS  TABLE  OF  xx_po_quotation_conv_stg.org_id%TYPE             INDEX BY BINARY_INTEGER;
TYPE agent_id_tbl_type           IS  TABLE  OF  xx_po_quotation_conv_stg.agent_id%TYPE           INDEX BY BINARY_INTEGER;
TYPE gt_import_prg_req_tbl_type  IS  TABLE  OF  gt_import_prg_req_rec                            INDEX BY BINARY_INTEGER;

-------------------------------------------
-- Variable declaration of type -table type
-------------------------------------------
g_stg_tbl                stg_tbl_type;
g_org_id_tbl             org_id_tbl_type;
g_ctrl_id_tbl            ctrl_id_tbl_type;
g_ctrl_id_tbl1           ctrl_id_tbl_type;
g_pro_flg_tbl            pro_flg_tbl_type;
g_err_msg_tbl            err_msg_tbl_type;
g_agent_id_tbl           agent_id_tbl_type;
qty_price_tbl            qty_price_tbl_type;
g_inv_itm_id_tbl         inv_itm_id_tbl_type;
g_ven_site_id_tbl        ven_site_id_tbl_type;
g_ven_id_tbl             ven_id_tbl_type;
g_success_po_hdr_tbl     success_po_hdr_tbl_type;
g_bat_control_id_tbl     lt_bat_cntrl_id_tbl_type;
g_ready_for_proc_tbl     g_ready_for_proc_tbl_type;
g_unsuccess_po_hdr_tbl   unsuccess_po_hdr_tbl_type;
gr_po_err_empty_rec      xx_com_exceptions_log_conv%ROWTYPE;
gr_po_err_rec            xx_com_exceptions_log_conv%ROWTYPE;
gt_import_prg_req_tbl    gt_import_prg_req_tbl_type;--to store the request Ids of Import Price catalogs

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
    IF NVL(gn_debug_flag,'N')='Y' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
    END IF;
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
-- | Parameters  :  None                                                |
-- +====================================================================+
PROCEDURE update_batch_id(p_batch_id IN NUMBER)

IS

-- ------------------------------------------------------------
-- Cursor declaration to get the previously errored out records
-- ------------------------------------------------------------
CURSOR   lcu_upd_batch
IS
SELECT   XOPQS.ROWID
FROM     xx_po_quotation_conv_stg XOPQS
WHERE    XOPQS.process_flag IN (3,6)
AND      XOPQS.operation_cd='CREATE'
ORDER BY XOPQS.control_id;

TYPE stg_rec_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_stg_record  stg_rec_tbl_type;

BEGIN
    ----------------------------
    -- Clear the table type data
    ----------------------------
    g_ctrl_id_tbl.DELETE ;
    g_ctrl_id_tbl1.DELETE;

    ------------------------------------------
    -- Collect the records into the table type
    ------------------------------------------
    OPEN  lcu_upd_batch;
    FETCH lcu_upd_batch BULK COLLECT INTO lt_stg_record;
    CLOSE lcu_upd_batch;

    display_log('g_ctrl_id_tbl.COUNT in Update Batch'||lt_stg_record.COUNT);

    IF lt_stg_record.COUNT <> 0 THEN
        FORALL i IN 1 .. lt_stg_record.COUNT
        UPDATE  xx_po_quotation_conv_stg XOPQS
        SET     XOPQS.load_batch_id  = NULL
               ,XOPQS.process_flag   = 1
               ,XOPQS.error_message  = NULL
               ,XOPQS.error_code     = NULL
        WHERE   XOPQS.ROWID           = lt_stg_record(i)
        AND     load_batch_id         = NVL(p_batch_id,load_batch_id);
        COMMIT;
    END IF;
END update_batch_id;

-- +===========================================================================+
-- | Name             : GET_MASTER_REQUEST_ID                                  |
-- | Description      : This Procedure is called to get master_request_id      |
-- |                                                                           |
-- | Parameters         p_conversion_id                                        |
-- |                    p_batch_id                                             |
-- |                    x_master_request_id                                    |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE GET_MASTER_REQUEST_ID (
                                 p_conversion_id        IN     NUMBER
                                ,p_batch_id             IN     NUMBER
                                ,x_master_request_id    OUT    NUMBER
                                 )
IS

BEGIN

    SELECT  master_request_id
    INTO    x_master_request_id
    FROM    xx_com_control_info_conv XCCIC
    WHERE   XCCIC.conversion_id = p_conversion_id
    AND     XCCIC.batch_id      = nvl(p_batch_id,XCCIC.batch_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        display_log('Master Request Id for the above batch not found');
    WHEN OTHERS THEN
        display_log('Unexpected Errors occured when fetching x_master_request_id');
END GET_MASTER_REQUEST_ID;

-- +====================================================================+
-- | Name          :  launch_summary_report                             |
-- | Description   :  This procedure is invoked to Launch Conversion    |
-- |                  Processing Summary Report for that run of Master  |
-- |                  Program                                           |
-- |                                                                    |
-- | Out Parameters:  x_errbuf                                          |
-- |                  x_retcode                                         |
-- +====================================================================+
PROCEDURE launch_summary_report(
                                x_errbuf   OUT VARCHAR2
                               ,x_retcode  OUT VARCHAR2
                               )

IS
-----------------------------
-- Local Variable Declaration
-----------------------------
EX_REP_SUMM             EXCEPTION;
EX_REP_PUR_ERR          EXCEPTION;
ln_master_req_id        PLS_INTEGER;
ln_request_id           PLS_INTEGER;
ln_batch_id             PLS_INTEGER;
lt_conc_summ_request_id FND_CONCURRENT_REQUESTS.request_id%TYPE;
lt_conc_pur_err_req_id  FND_CONCURRENT_REQUESTS.request_id%TYPE;
lc_status               VARCHAR2(3);

BEGIN
    FOR i IN lt_req_id.FIRST .. lt_req_id.LAST
    LOOP
        LOOP
            -------------------------------------------
            -- Get the status of the concurrent request
            -------------------------------------------
            SELECT FCR.phase_code
            INTO   lc_status
            FROM   FND_CONCURRENT_REQUESTS FCR
            WHERE  FCR.request_id = lt_req_id(i);

            ----------------------------------------------------
            --  If the concurrent requests completed sucessfully
            ----------------------------------------------------
            IF  lc_status = 'C' THEN
                EXIT;
            ELSE
                DBMS_LOCK.sleep(G_SLEEP);
            END IF;
        END LOOP;
    END LOOP;

    ln_master_req_id := NULL;
    ln_request_id    := NULL;
    ln_batch_id      := NULL;
    --------------------------------------------------------------------------------
    -- Call the Conversion Summary Report program after completion of child programs
    --------------------------------------------------------------------------------
    lt_conc_summ_request_id := FND_REQUEST.submit_request(
                                                           application => G_COMN_APPLICATION
                                                          ,program     => G_SUMRY_REPORT_PRGM
                                                          ,sub_request => FALSE                     -- FALSE means not a sub request
                                                          ,argument1   => G_CONVERSION_CODE         -- conversion_code
                                                          ,argument2   => gn_request_id             -- MASTER REQUEST ID
                                                          ,argument3   => ln_request_id             -- REQUEST ID
                                                          ,argument4   => ln_batch_id               -- BATCH ID
                                                         );

    IF  lt_conc_summ_request_id = 0 THEN
        x_errbuf := FND_MESSAGE.GET;
        RAISE EX_REP_SUMM;
    ELSE
        COMMIT;
    END IF;
EXCEPTION
    WHEN EX_REP_SUMM THEN
        x_retcode := 2;
        x_errbuf  := 'Processing Summary Report for this run of master program could not be submitted: '|| x_errbuf;
    WHEN EX_REP_PUR_ERR THEN
       x_retcode := 2;
       x_errbuf  := 'Purchasing Interface Errors Report his run of master program could not be submitted: '|| x_errbuf;
END launch_summary_report;

-- +====================================================================+
-- | Name        :  launch_exception_report                             |
-- | Description : This procedure is invoked to Launch Exception Report |
-- |               for every batch launched by the Master Program.      |
-- |                                                                    |
-- | In Parameters : p_batch_id                                         |
-- | Out Parameters: x_errbuf                                           |
-- |                 x_retcode                                          |
-- +====================================================================+
PROCEDURE launch_exception_report(
                                   p_batch_id         IN         NUMBER
                                  ,p_conc_req_id      IN         NUMBER
                                  ,p_master_req_id    IN         NUMBER
                                  ,x_errbuf           OUT NOCOPY VARCHAR2
                                  ,x_retcode          OUT NOCOPY VARCHAR2
                                 )
IS
-------------------------------------------
--Declaring local variables and Exceptions
------------------------------------------
EX_REP_EXC              EXCEPTION;
ln_excep_request_id     PLS_INTEGER;
ln_request_id           PLS_INTEGER;

BEGIN
    ln_request_id := FND_GLOBAL.CONC_REQUEST_ID;
    ------------------------------------------------
    --Submitting the Exception Report for each batch
    ------------------------------------------------
    ln_excep_request_id := FND_REQUEST.submit_request(
                                                         application =>  G_COMN_APPLICATION
                                                        ,program     =>  G_EXCEP_REPORT_PRGM
                                                        ,sub_request =>  FALSE             -- TRUE means is a sub request
                                                        ,argument1   =>  G_CONVERSION_CODE -- conversion_code
                                                        ,argument2   =>  p_master_req_id   -- MASTER REQUEST ID
                                                        ,argument3   =>  ln_request_id--p_conc_req_id     -- REQUEST ID
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
END launch_exception_report;

-- +====================================================================+
-- | Name        :  get_conversion_id                                   |
-- | Description :  This procedure is invoked to get the conversion_id  |
-- |               ,batch_size and max_threads.                         |
-- |                                                                    |
-- |Out Parameters: x_conversion_id                                     |
-- |                x_batch_size                                        |
-- |                x_max_threads                                       |
-- |                x_return_status                                     |
-- +====================================================================+
PROCEDURE get_conversion_id(
                            x_conversion_id  OUT  NUMBER
                           ,x_batch_size     OUT  NUMBER
                           ,x_max_threads    OUT  NUMBER
                           ,x_return_status  OUT  VARCHAR2
                           )
IS
-----------------------------
-- Local Variable Declaration
-----------------------------
ln_conversion_id PLS_INTEGER ;
ln_batch_size    PLS_INTEGER ;
ln_max_threads   PLS_INTEGER ;

BEGIN
    SELECT  XCCC.conversion_id
           ,XCCC.batch_size
           ,XCCC.max_threads
    INTO    ln_conversion_id
           ,ln_batch_size
           ,ln_max_threads
    FROM    XX_COM_CONVERSIONS_CONV XCCC
    WHERE   XCCC.conversion_code = G_CONVERSION_CODE;

    ---------------------------------------------------
    -- Get the conversion details into the out variable
    ---------------------------------------------------
    x_conversion_id := ln_conversion_id;
    x_batch_size    := ln_batch_size;
    x_max_threads   := ln_max_threads;
    x_return_status := 'S';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_return_status := 'E';
        display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code  '|| G_CONVERSION_CODE);
    WHEN OTHERS THEN
        x_return_status := 'E';
        display_log('Error while deriving conversion_id - '||SUBSTR(SQLERRM,1,500));
END get_conversion_id;

-- +======================================================================+
-- | Name        :  bat_child                                             |
-- | Description :  This procedure is invoked from the submit_sub_requests|
-- |                procedure. This would submit child requests based     |
-- |                on batch_size.                                        |
-- |                                                                      |
-- | In Parameters :p_request_id                                          |
-- |                p_validate_only_flag                                  |
-- |                p_reset_status_flag                                   |
-- |                                                                      |
-- | Out Parameters: x_time                                               |
-- |                 x_errbuf                                             |
-- |                 x_retcode                                            |
-- +======================================================================+
PROCEDURE bat_child(
                     p_request_id         IN  NUMBER
                    ,p_validate_only_flag IN  VARCHAR2
                    ,p_reset_status_flag  IN  VARCHAR2
                    ,x_time               OUT DATE
                    ,x_errbuf             OUT VARCHAR2
                    ,x_retcode            OUT VARCHAR2
                   )

IS
-----------------------------
-- Local Variable Declaration
-----------------------------
EX_SUBMIT_CHILD_FAILED EXCEPTION;
ln_batch_size_count    PLS_INTEGER;
ln_seq                 PLS_INTEGER;
ln_req_count           PLS_INTEGER;
ln_bat_size            PLS_INTEGER;
lt_conc_request_id     FND_CONCURRENT_REQUESTS.request_id%TYPE;

-- pl/sql table to hold all vendor count and vendors in the extracted data
TYPE rec_vendor_count IS RECORD
                            (
                              vendor_count   NUMBER
                             ,vendor_id      NUMBER
                            );
lr_rec_vendor_count  rec_vendor_count;

TYPE tab_vendor_count IS TABLE OF lr_rec_vendor_count%TYPE
INDEX BY BINARY_INTEGER;
ltab_quot_count       tab_vendor_count;

--------------------------------------------------------------
-- Declare cursor to get eligible records for batch assignment
--------------------------------------------------------------
CURSOR lcu_elig_rec
IS
SELECT control_id
FROM   xx_po_quotation_conv_stg XOPQS
WHERE  XOPQS.load_batch_id IS NULL
AND    XOPQS.process_flag = 1
AND    XOPQS.operation_cd = 'CREATE'
ORDER BY XOPQS.control_id;

 /************************************
 -- The query groups same vendor in
 -- one batch to process them together.
 -- **********************************/

CURSOR lcu_distinct_vendor
IS
SELECT COUNT(*) vendor_count
      ,vendor_id
FROM   xx_po_quotation_conv_stg XOPQS
WHERE  XOPQS.process_flag = 1
AND    XOPQS.operation_cd = 'CREATE'
GROUP  BY vendor_id ORDER BY 1 DESC;

CURSOR lcu_batch_count
IS
SELECT load_batch_id,count(*) batch_count
FROM XX_PO_QUOTATION_CONV_STG
WHERE process_flag=2
GROUP BY load_batch_id;

BEGIN
    ----------------------------
    -- Clear the table type data
    ----------------------------
    g_ctrl_id_tbl.DELETE ;

    --------------------------------------
    -- Get the records into the table type
    --------------------------------------
    OPEN  lcu_elig_rec;
    FETCH lcu_elig_rec BULK COLLECT INTO g_ctrl_id_tbl;
    CLOSE lcu_elig_rec;
    ln_batch_size_count := g_ctrl_id_tbl.COUNT;
    gn_record_count := gn_record_count + ln_batch_size_count;

    ------------------------------------
    -- Get the batch_id from the sequence
    ------------------------------------
    SELECT xx_po_quotation_conv_stg_bat_s.NEXTVAL
    INTO   ln_seq
    FROM   DUAL;

    OPEN lcu_distinct_vendor;
    FETCH lcu_distinct_vendor BULK COLLECT INTO ltab_quot_count;
    CLOSE lcu_distinct_vendor;

    FOR indx IN 1..ltab_quot_count.COUNT
    LOOP
        IF ltab_quot_count(indx).vendor_count > gn_batch_size THEN
            SELECT xx_po_quotation_conv_stg_bat_s.NEXTVAL
            INTO   ln_seq
            FROM   DUAL;

            UPDATE xx_po_quotation_conv_stg XOPQS
            SET    load_batch_id       = ln_seq
                  ,process_flag        = 2
            WHERE  nvl(vendor_id,1)           = nvl(ltab_quot_count(indx).vendor_id,1)
            AND    XOPQS.process_flag  <> 7
            AND    XOPQS.operation_cd  = 'CREATE';

            ln_bat_size :=  ln_bat_size + ltab_quot_count(indx).vendor_count;

        ELSE
            IF ln_bat_size < gn_batch_size THEN
                UPDATE xx_po_quotation_conv_stg XOPQS
                SET    load_batch_id = ln_seq
                      ,process_flag  = 2
                WHERE  nvl(vendor_id,1)   = nvl(ltab_quot_count(indx).vendor_id,1)
                AND    XOPQS.process_flag  <> 7
                AND    XOPQS.operation_cd = 'CREATE';

                ln_bat_size      :=  ln_bat_size + ltab_quot_count(indx).vendor_count ;

            ELSE
                SELECT xx_po_quotation_conv_stg_bat_s.NEXTVAL
                INTO   ln_seq
                FROM   DUAL;
                UPDATE xx_po_quotation_conv_stg XOPQS
                SET    load_batch_id       = ln_seq
                      ,process_flag  = 2
                WHERE  nvl(vendor_id,1)           = nvl(ltab_quot_count(indx).vendor_id,1)
                AND    XOPQS.process_flag  <>7
                AND    XOPQS.operation_cd = 'CREATE';
                ln_bat_size               :=  ltab_quot_count(indx).vendor_count ;
            END IF;
        END IF;


    END LOOP;
    COMMIT;

    FOR lcu_batch_count_rec IN lcu_batch_count
    LOOP
        ----------------------------------------------------
    -- Procedure to Log Conversion Control Informations.
        ----------------------------------------------------
        XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                                                        p_conversion_id          => gn_conversion_id
                                                       ,p_batch_id               => lcu_batch_count_rec.load_batch_id
                                                       ,p_num_bus_objs_processed => lcu_batch_count_rec.batch_count
                                                      );

    END LOOP;

    -------------------------------
    -- Assign batches to the records
    -------------------------------
    FOR indx IN (SELECT DISTINCT load_batch_id load_batch_id
                 FROM   xx_po_quotation_conv_stg
                 WHERE  process_flag < 3 )
    LOOP
        display_log('indx.load_batch_id'||indx.load_batch_id);
        LOOP
        -----------------------------------------------
        -- Get the count of running concurrent requests
        ----------------------------------------------
        SELECT COUNT(1)
        INTO   ln_req_count
        FROM   FND_CONCURRENT_REQUESTS
        WHERE  parent_request_id  = gn_request_id
        AND    phase_code IN ('P','R');

        IF ln_req_count < gn_max_child_req THEN
            -----------------------------------------------------------
            -- Call the custom concurrent program for parallel execution
            -----------------------------------------------------------
            lt_conc_request_id := Fnd_Request.Submit_Request
                                                            (
                                                              application => G_CHLD_PROG_APPLICATION --g_custom_appl_name
                                                             ,program     => G_CHLD_PROG_EXECUTABLE--g_custom_pgm_name
                                                             ,description => 'PO Quotation Conversion Child Program'
                                                             ,start_time  => NULL
                                                             ,sub_request => FALSE
                                                             ,argument1   => p_validate_only_flag
                                                             ,argument2   => p_reset_status_flag
                                                             ,argument3   => indx.load_batch_id
                                                             ,argument4   => gn_debug_flag
                                                            );
            IF lt_conc_request_id = 0 THEN
                x_errbuf := FND_MESSAGE.GET;
                RAISE EX_SUBMIT_CHILD_FAILED;
            ELSE
                COMMIT;
                gn_req_id := gn_req_id + 1;
                lt_req_id(gn_req_id) := lt_conc_request_id;
                gn_batch_count  := gn_batch_count + 1;
                x_time := sysdate;

                EXIT;
            END IF;
        ELSE
            DBMS_LOCK.sleep(G_SLEEP);
        END IF;
    END LOOP;
END LOOP;

x_retcode := 0;

EXCEPTION
    WHEN EX_SUBMIT_CHILD_FAILED THEN
        x_retcode := 2;
        display_log(x_errbuf);
    WHEN OTHERS THEN
        x_retcode := 2;
        display_log('Unexpected error in procedure bat_child '|| SUBSTR(SQLERRM,1,500));
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
-- |                p_batch_size                                       |
-- |                p_no_of_threads                                    |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE submit_sub_requests(
                               p_validate_only_flag  IN  VARCHAR2
                              ,p_reset_status_flag   IN  VARCHAR2
                              ,p_batch_size          IN  VARCHAR2
                              ,p_no_of_threads       IN  VARCHAR2
                              ,x_errbuf              OUT VARCHAR2
                              ,x_retcode             OUT VARCHAR2
                             )

IS

-----------------------------
-- Local Variable declaration
-----------------------------
EX_NO_ENTRY              EXCEPTION;
ld_check_time            DATE;
ld_current_time          DATE;
ln_current_count         PLS_INTEGER;
ln_last_count            PLS_INTEGER;
ln_rem_time              NUMBER;
lc_return_status         VARCHAR2(3);
lc_launch                VARCHAR2(2):='N';
ln_po_header_failed      PLS_INTEGER;
ln_po_header_invalid     PLS_INTEGER;
ln_po_header_processed   PLS_INTEGER;
ln_total_rec             PLS_INTEGER;
ln_already_proc_rec      PLS_INTEGER;
ln_ret_code              PLS_INTEGER;

----------------------------------
-- Cursor declaration
----------------------------------
CURSOR lcu_header_info
IS
SELECT COUNT (CASE WHEN process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='6' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='7' THEN 1 END)
FROM   xx_po_quotation_conv_stg  XPHCS
WHERE  XPHCS.operation_cd = 'CREATE';

CURSOR lcu_header_info1
IS
SELECT COUNT (CASE WHEN process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='2' THEN 1 END)
      ,COUNT (CASE WHEN process_flag ='4' THEN 1 END)
FROM   xx_po_quotation_conv_stg  XPHCS
WHERE  XPHCS.operation_cd = 'CREATE';

BEGIN
 

    SELECT COUNT(1)
    INTO   ln_already_proc_rec
    FROM   xx_po_quotation_conv_stg XOPQS
    WHERE  XOPQS.process_flag ='7';
 

    get_conversion_id(
                       x_conversion_id  => gn_conversion_id
                      ,x_batch_size     => gn_batch_size
                      ,x_max_threads    => gn_max_child_req
                      ,x_return_status  => lc_return_status
                     );

    gn_batch_size    := p_batch_size ;
    gn_max_child_req :=  p_no_of_threads;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch Size :'|| gn_batch_size);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No. Of Threads :'|| gn_max_child_req);

    IF lc_return_status = 'S' THEN
        IF NVL(p_reset_status_flag,'N') = 'Y' THEN
        ----------------------------------------------------------
        -- Call update_batch_id to change status of errored records
        ----------------------------------------------------------
        update_batch_id(NULL); -- Not for a specific batch hence NULL
        END IF;
        
        -- Get the count of records to be processed V1.6
	    SELECT COUNT(1)
	    INTO   ln_total_rec
	    FROM   xx_po_quotation_conv_stg XOPQS
            WHERE  XOPQS.operation_cd = 'CREATE'
            AND    XOPQS.process_flag = 1;
    
           fnd_file.put_line(fnd_file.log,'Initial Count: '||ln_total_rec);
        
        ld_check_time := sysdate;
        ln_current_count := 0;
        ln_last_count := ln_current_count;
        ----------------------------------------------
        -- Get the current count of eligible records
        ----------------------------------------------
        SELECT COUNT(1)
        INTO   ln_current_count
        FROM   xx_po_quotation_conv_stg  XOPQS
        WHERE  XOPQS.load_batch_id IS NULL
        AND    XOPQS.process_flag = 1
        AND    XOPQS.operation_cd = 'CREATE';

        IF (ln_current_count <> 0 ) THEN
            ----------------------------------------------
            -- Call bat_child to launch the child requests
            ----------------------------------------------
            bat_child(
                       p_request_id         => gn_request_id
                      ,p_validate_only_flag => p_validate_only_flag
                      ,p_reset_status_flag  => p_reset_status_flag
                      ,x_time               => ld_check_time
                      ,x_errbuf             => x_errbuf
                      ,x_retcode            => x_retcode
                    );
                
              --  Added for V1.6
              IF x_retcode IN (0,1) 
              THEN                 
              
                ----------------------------
		-- Launch the summary report
		----------------------------
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
               ELSE
                 display_log('Concurrent request errored out');
	         x_retcode := 1; 
               END IF;             
             
           ELSE
            
               display_log('No Data Found in Staging Table to Proceed ');
	       display_log('ln_current_count '||ln_current_count);
	       x_retcode := 1;

          END IF;
            
        /*END IF; -- Commented for V1.6
        
        --Code removed for rolling conversion--Version 1.2
        IF  lc_launch = 'N' THEN
            display_log('No Data Found in Staging Table to Proceed or the conc.request errored ');
            display_log('ln_current_count '||ln_current_count);
            x_retcode := 1;
        ELSE
            ------------------------------
            -- Lauunch the summary report
            ------------------------------
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
        */
        ---------------------------------------------------------------------------
        -- Fetching Number of Invalid, Processing Failed and Processed PO Headers
        ----------------------------------------------------------------------------
        IF NVL(p_validate_only_flag,'N') = 'Y' THEN
            OPEN lcu_header_info1;
            FETCH lcu_header_info1 INTO ln_po_header_invalid,ln_po_header_failed,ln_po_header_processed;
            CLOSE lcu_header_info1;
        ELSE
            OPEN lcu_header_info;
            FETCH lcu_header_info INTO ln_po_header_invalid,ln_po_header_failed,ln_po_header_processed;
            CLOSE lcu_header_info;
	    display_log('Processed records: '|| ln_po_header_processed||'  and already processed: '||ln_already_proc_rec);
	 -- Get the actual number of Records processed by this program V1.6
	    ln_po_header_processed :=  ln_po_header_processed - ln_already_proc_rec ; -- V1.6

        END IF;
                
        display_out(RPAD('=',38,'='));
        display_out(RPAD('Batch Size                 : ',29,' ')||RPAD(gn_batch_size,9,' '));
        display_out(RPAD('Number of Records          : ',29,' ')||RPAD(gn_record_count,9,' '));
        display_out(RPAD('Number of Batches Launched : ',29,' ')||RPAD(gn_batch_count,9,' '));
        display_out(RPAD('=',38,'='));

        IF gn_record_count = 0 THEN

        /* If no record is selected then reset summary report to 0 */

            ln_total_rec           := 0;
            ln_po_header_processed := 0;
            ln_po_header_invalid   := 0;
            ln_po_header_failed    := 0;

               display_out(' ');
               display_out(RPAD('=',45,'='));
               display_out('  ');
               display_out(RPAD('=',45,'='));
               display_out(RPAD('Total records to be processed        : ',39,' ')||RPAD(ln_total_rec,9,' '));
               display_out(RPAD('Total records successfully processed : ',39,' ')||RPAD(ln_po_header_processed,9,' '));
               display_out(RPAD('Total records failed validation      : ',39,' ')||RPAD(ln_po_header_invalid,9,' '));
               display_out(RPAD('Total records interface rejects      : ',39,' ')||RPAD(ln_po_header_failed,9,' '));
               display_out(RPAD('=',45,'='));

        ELSE
           IF NVL(p_validate_only_flag,'N') = 'N' THEN
               display_out(' ');
               display_out(RPAD('=',45,'='));
               display_out('  ');
               display_out(RPAD('=',45,'='));
               display_out(RPAD('Total records to be processed        : ',39,' ')||RPAD(ln_total_rec,9,' '));
               display_out(RPAD('Total records successfully processed : ',39,' ')||RPAD(ln_po_header_processed,9,' '));
               display_out(RPAD('Total records failed validation      : ',39,' ')||RPAD(ln_po_header_invalid,9,' '));
               display_out(RPAD('Total records interface rejects      : ',39,' ')||RPAD(ln_po_header_failed,9,' '));
               display_out(RPAD('=',45,'='));
           ELSE
               display_out(' ');
               display_out(RPAD('=',45,'='));
               display_out('  ');
               display_out(RPAD('=',45,'='));
               display_out(RPAD('Total records to be processed        : ',39,' ')||RPAD(ln_total_rec,9,' '));
               display_out(RPAD('Total records successfully validated :' ,39,' ')||RPAD(ln_po_header_processed,9,' '));
               display_out(RPAD('Total records failed validation      : ',39,' ')||RPAD(ln_po_header_failed,9,' '));
               display_out(RPAD('Total records interface rejects      : ',39,' ')||0);
               display_out(RPAD('=',45,'='));
           END IF;
        END IF; -- IF gn_record_count = 0 THEN
    ELSE
        RAISE EX_NO_ENTRY;
    END IF; -- lc_return_status
        
EXCEPTION
    WHEN EX_NO_ENTRY THEN
        x_retcode := 2;
        display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code C0301_PurchasePriceFromRMS');
    WHEN OTHERS THEN
        x_retcode := 2;
        display_log('Unexpected Error in procedure SUBMIT_SUB_REQUESTS '||SUBSTR(SQLERRM,1,500));
END SUBMIT_SUB_REQUESTS;

-- +===================================================================+
-- | Name       :    VALIDATE_PROCESS_RECORDS                          |
-- |                                                                   |
-- | Description:    This procedure performs the validations before    |
-- |                 calling the  custom API for further processing.   |
-- |                                                                   |
-- | In Parameters :  p_batch_id                                       |
-- |                  p_validate_only_flag                             |
-- |                                                                   |
-- | Out Parameters : x_return_status                                  |
-- |                  x_return_msg                                     |
-- +===================================================================+
PROCEDURE VALIDATE_PROCESS_RECORDS
                                (
                                  x_return_status             OUT   VARCHAR2
                                , x_return_msg                OUT   VARCHAR2
                                , p_batch_id                  IN    NUMBER
                                , p_validate_only_flag        IN    VARCHAR2
                                )
IS

-----------------------------
-- Local Variable Declaration
-----------------------------
EX_VAL_FAIL                  EXCEPTION;
ln_sucess_count              PLS_INTEGER;
--ln_agent_id                  PLS_INTEGER;
ln_vendor_site_id            po_vendor_sites_all.vendor_site_id%TYPE;
ln_vendor_id                 po_vendor_sites_all.vendor_id%TYPE;
ln_inventory_item_id         mtl_system_items_b.inventory_item_id%TYPE;
lc_prim_unit_of_measure      mtl_system_items_b.primary_unit_of_measure%TYPE;
ln_organization_id           hr_all_organization_units.organization_id%TYPE;
ln_legacy_vendor_id          xx_po_quotation_conv_stg.vendor_id%TYPE :=0;
ln_interface_header_id       po_headers_interface.interface_header_id%TYPE;
lc_return_status             VARCHAR2(1);
lc_error_flag                VARCHAR2(1);
lc_org_id_exists             VARCHAR2(1);
lc_inv_item_exists           VARCHAR2(1);
lc_vendor_id_exists          VARCHAR2(1);
lc_agent_id_exists           VARCHAR2(1):= NULL;
lc_return_msg                VARCHAR2(1000);
lc_error_message             VARCHAR2(1000);
lc_agent_err_msg             VARCHAR2(50):= NULL;
lc_org_id_err_msg            VARCHAR2(50);
lc_itm_id_err_msg            VARCHAR2(50);
lc_vendr_id_err_msg          VARCHAR2(50);
lc_staging_column_name       VARCHAR2(32);
lc_staging_column_value      VARCHAR2(500);
lc_currency_err_msg          VARCHAR2(240);
lc_dup_rec_err_msg           VARCHAR2(240);
lc_currency_exists           VARCHAR2(1);

TYPE interface_id_tbl_type IS TABLE OF po_headers_interface.interface_header_id%TYPE
INDEX BY BINARY_INTEGER;
lt_interface_header_id interface_id_tbl_type;

---------------------------------------------------------------------
-- Declare cursor to fetch the records in vaidation in progress state
---------------------------------------------------------------------
CURSOR lcu_ready_rec
IS
SELECT *
FROM   xx_po_quotation_conv_stg XOPQS
WHERE  XOPQS.process_flag  < 3
AND    XOPQS.load_batch_id = p_batch_id
ORDER BY operating_unit,vendor_id;

------------------------------
--Cursor to Validate Currency
------------------------------
CURSOR lcu_currency(p_currency_code IN VARCHAR2)
IS
SELECT  'Y'
FROM    FND_CURRENCIES   FC
WHERE   FC.currency_code   = p_currency_code
AND     FC.enabled_flag    = 'Y'
AND     TRUNC(SYSDATE)
BETWEEN TRUNC(NVL(FC.start_date_active, SYSDATE))
AND     TRUNC(NVL(FC.end_Date_active,SYSDATE));

BEGIN
    x_return_status :='E';
    ---------------------------
    -- Clear the table type data
    ----------------------------
    g_stg_tbl.DELETE;
    g_ctrl_id_tbl.DELETE;
    g_pro_flg_tbl.DELETE;
    g_err_msg_tbl.DELETE;

    ---------------------------------------
    -- Collect the data into the table type
    ---------------------------------------
    OPEN  lcu_ready_rec;
    FETCH lcu_ready_rec BULK COLLECT INTO g_stg_tbl;
    CLOSE lcu_ready_rec;
    -- Check Agent ID  Definition in EBS
    BEGIN
        SELECT PA.agent_id
        INTO   G_AGENT_ID
        FROM   po_agents PA
              ,per_all_people_f PAPF
        WHERE  PA.agent_id = PAPF.person_id
        AND   UPPER(PAPF.last_name) = 'INTERFACE'
        AND    UPPER(PAPF.first_name)  = 'BUYER';

        lc_agent_id_exists := 'Y';
        x_return_status    := 'S';

    EXCEPTION
        WHEN OTHERS THEN
            x_return_status :='E';
            FND_MESSAGE.set_name('XXPTP','XX_PO_60003_CONV_INVLD_AGENT');
            lc_agent_err_msg   := FND_MESSAGE.GET;
            --lc_agent_err_msg := 'Agent Id is not defined in EBS';
            XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
                                                       (
                                                         p_conversion_id        => gn_conversion_id
                                                        ,p_record_control_id    => NULL
                                                        ,p_source_system_code   => NULL
                                                        ,p_package_name         => G_PACKAGE_NAME
                                                        ,p_procedure_name       => 'VALIDATE_PROCESS_RECORDS'
                                                        ,p_staging_table_name   => G_STAGING_TABLE_NAME
                                                        ,p_staging_column_name  => NULL
                                                        ,p_staging_column_value => NULL
                                                        ,p_source_system_ref    => NULL
                                                        ,p_batch_id             => p_batch_id
                                                        ,p_exception_log        => NULL
                                                        ,p_oracle_error_code    => NULL
                                                        ,p_oracle_error_msg     => lc_agent_err_msg
                                                       );
    END;
    ----------------------------------
    -- Validate the records one by one
    ----------------------------------
    FOR i IN g_stg_tbl.FIRST..g_stg_tbl.LAST
    LOOP
    BEGIN

        ln_inventory_item_id    := NULL;
        lc_prim_unit_of_measure := NULL;
        ln_organization_id      := NULL;
        lc_org_id_exists        := NULL;
        lc_inv_item_exists      := NULL;
        lc_org_id_err_msg       := NULL;
        lc_itm_id_err_msg       := NULL;
        lc_vendr_id_err_msg     := NULL;
        lc_currency_exists      := NULL;
        display_log('validation_process');
                
        -- Validate only if New vendor id is being processed
        -- Also in case of NULL all the vendor records should get processed.
        
        IF nvl(g_stg_tbl(i).vendor_id,-2) <> nvl(ln_legacy_vendor_id,-1) THEN
        
            ln_legacy_vendor_id  := g_stg_tbl(i).vendor_id;
            
            SELECT PO_HEADERS_INTERFACE_S.NEXTVAL
            INTO ln_interface_header_id
            FROM dual;

            -- Check Vendor Site Id Definition in EBS ie.,Supplier
            ln_vendor_id            := NULL;
	    ln_vendor_site_id       := NULL;
	    lc_vendor_id_exists     := NULL;

            display_log('Inside vendor val for Vendor: '||g_stg_tbl(i).vendor_id); 

	    IF g_stg_tbl(i).vendor_id IS NOT NULL THEN
	    BEGIN
	        SELECT PVSA.vendor_site_id
	              ,PVSA.vendor_id
	        INTO   ln_vendor_site_id
	              ,ln_vendor_id
	        FROM   po_vendor_sites_all PVSA
	        WHERE  PVSA.attribute9 = TO_CHAR(g_stg_tbl(i).vendor_id)
	        AND    PVSA.purchasing_site_flag = 'Y'
	        AND    SYSDATE < NVL(inactive_date, SYSDATE + 1);

	        lc_vendor_id_exists := 'Y';
	        x_return_status :='S';

	        EXCEPTION
	            WHEN NO_DATA_FOUND THEN
	                x_return_status :='E';
	                --lc_vendr_id_err_msg := 'Supplier is not defined in EBS';
	                FND_MESSAGE.set_name('XXPTP','XX_PO_60002_CONV_INVLD_VENDOR');
	                FND_MESSAGE.SET_TOKEN('SUPPLIER',g_stg_tbl(i).vendor_id);
	                lc_vendr_id_err_msg   := FND_MESSAGE.GET;
	                lc_staging_column_name  := 'VENDOR_ID';
	                lc_staging_column_value := g_stg_tbl(i).vendor_id;
	                XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
	                                                            (
	                                                              p_conversion_id        => gn_conversion_id
	                                                             ,p_record_control_id    => g_stg_tbl(i).control_id
	                                                             ,p_source_system_code   => g_stg_tbl(i).source_system_code
	                                                             ,p_package_name         => G_PACKAGE_NAME
	                                                             ,p_procedure_name       => 'VALIDATE_PROCESS_RECORDS'
	                                                             ,p_staging_table_name   => G_STAGING_TABLE_NAME
	                                                             ,p_staging_column_name  => lc_staging_column_name
	                                                             ,p_staging_column_value => lc_staging_column_value
	                                                             ,p_source_system_ref    => g_stg_tbl(i).source_system_ref
	                                                             ,p_batch_id             => p_batch_id
	                                                             ,p_exception_log        => NULL
	                                                             ,p_oracle_error_code    => NULL
	                                                             ,p_oracle_error_msg     => lc_vendr_id_err_msg
	                                                            );

	            WHEN OTHERS THEN
	                x_return_status :='E';
	                lc_vendr_id_err_msg := 'WHEN OTHERS Error while selecting Vendor: '||TO_CHAR(g_stg_tbl(i).vendor_id)||' '||SUBSTR(SQLERRM,1,500);
	                lc_staging_column_name  := 'VENDOR_ID';
	                lc_staging_column_value := g_stg_tbl(i).vendor_id;
	                XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
	                                                            (
	                                                              p_conversion_id        => gn_conversion_id
	                                                             ,p_record_control_id    => g_stg_tbl(i).control_id
	                                                             ,p_source_system_code   => g_stg_tbl(i).source_system_code
	                                                             ,p_package_name         => G_PACKAGE_NAME
	                                                             ,p_procedure_name       => 'VALIDATE_PROCESS_RECORDS'
	                                                             ,p_staging_table_name   => G_STAGING_TABLE_NAME
	                                                             ,p_staging_column_name  => lc_staging_column_name
	                                                             ,p_staging_column_value => lc_staging_column_value
	                                                             ,p_source_system_ref    => g_stg_tbl(i).source_system_ref
	                                                             ,p_batch_id             => p_batch_id
	                                                             ,p_exception_log        => NULL
	                                                             ,p_oracle_error_code    => NULL
	                                                             ,p_oracle_error_msg     => lc_vendr_id_err_msg
	                                                           );
	        END;
	    ELSE
	        x_return_status :='E';
		lc_vendr_id_err_msg := 'Vendor id is not provided ';
		lc_staging_column_name  := 'VENDOR_ID';
		lc_staging_column_value := g_stg_tbl(i).vendor_id;
		XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
		                                            (
		                                              p_conversion_id        => gn_conversion_id
		                                             ,p_record_control_id    => g_stg_tbl(i).control_id
		                                             ,p_source_system_code   => g_stg_tbl(i).source_system_code
		                                             ,p_package_name         => G_PACKAGE_NAME
		                                             ,p_procedure_name       => 'VALIDATE_PROCESS_RECORDS'
		                                             ,p_staging_table_name   => G_STAGING_TABLE_NAME
		                                             ,p_staging_column_name  => lc_staging_column_name
		                                             ,p_staging_column_value => lc_staging_column_value
		                                             ,p_source_system_ref    => g_stg_tbl(i).source_system_ref
		                                             ,p_batch_id             => p_batch_id
		                                             ,p_exception_log        => NULL
		                                             ,p_oracle_error_code    => NULL
		                                             ,p_oracle_error_msg     => lc_vendr_id_err_msg
	                                   );
            END IF;
        END IF;

        g_stg_tbl(i).vendor_site_id := ln_vendor_site_id;
	g_stg_tbl(i).ebs_vendor_id  := ln_vendor_id;

        lt_interface_header_id(i):=ln_interface_header_id;
        -- Check Organization Definition in EBS
        IF g_stg_tbl(i).operating_unit IS NOT NULL THEN
            BEGIN
                SELECT HAOU.organization_id
                INTO   ln_organization_id
                FROM   hr_all_organization_units HAOU
                WHERE  HAOU.name = g_stg_tbl(i).operating_unit;
                lc_org_id_exists := 'Y';
                x_return_status :='S';
                g_stg_tbl(i).org_id := ln_organization_id;
            EXCEPTION
                WHEN OTHERS THEN
                    x_return_status :='E';
                    --lc_org_id_err_msg := 'Organization is not defined in EBS';
                    FND_MESSAGE.set_name('XXPTP','XX_PO_60005_CONV_INVLD_ORG_ID');
                    FND_MESSAGE.SET_TOKEN('OPERATING_UNIT',g_stg_tbl(i).operating_unit);
                    lc_org_id_err_msg   := FND_MESSAGE.GET;
                    lc_staging_column_name  := 'OPERATING_UNIT';
                    lc_staging_column_value := g_stg_tbl(i).operating_unit;
                    XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
                                                           (
                                                             p_conversion_id        => gn_conversion_id
                                                            ,p_record_control_id    => g_stg_tbl(i).control_id
                                                            ,p_source_system_code   => g_stg_tbl(i).source_system_code
                                                            ,p_package_name         => G_PACKAGE_NAME
                                                            ,p_procedure_name       => 'main'
                                                            ,p_staging_table_name   => G_STAGING_TABLE_NAME
                                                            ,p_staging_column_name  => lc_staging_column_name
                                                            ,p_staging_column_value => lc_staging_column_value
                                                            ,p_source_system_ref    => g_stg_tbl(i).source_system_ref
                                                            ,p_batch_id             => p_batch_id
                                                            ,p_exception_log        => NULL
                                                            ,p_oracle_error_code    => NULL
                                                            ,p_oracle_error_msg     => lc_org_id_err_msg
                                                           );
            END;
        END IF;


        IF g_stg_tbl(i).sku IS NOT NULL THEN
            BEGIN

                SELECT inventory_item_id
                INTO   ln_inventory_item_id
                FROM   mtl_system_items_b MSIB
                      ,mtl_parameters     MP
                WHERE  MSIB.segment1  = g_stg_tbl(i).sku
                AND    MSIB.organization_id = MP.organization_id
                AND    rownum = 1;

                lc_inv_item_exists := 'Y';
                x_return_status :='S';
                g_stg_tbl(i).inventory_item_id := ln_inventory_item_id;

                EXCEPTION
                    WHEN OTHERS THEN
                        x_return_status :='E';
                        --lc_itm_id_err_msg := 'Item is not defined in EBS';
                        FND_MESSAGE.set_name('XXPTP','XX_PO_60001_CONV_INVALID_ITEM');
                        FND_MESSAGE.SET_TOKEN('ITEM',g_stg_tbl(i).sku);
                        lc_itm_id_err_msg   := FND_MESSAGE.GET;
                        lc_staging_column_name  := 'SKU';
                        lc_staging_column_value := g_stg_tbl(i).sku;
                        XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
                                                                   (
                                                                     p_conversion_id        => gn_conversion_id
                                                                    ,p_record_control_id    => g_stg_tbl(i).control_id
                                                                    ,p_source_system_code   => g_stg_tbl(i).source_system_code
                                                                    ,p_package_name         => G_PACKAGE_NAME
                                                                    ,p_procedure_name       => 'main'
                                                                    ,p_staging_table_name   => G_STAGING_TABLE_NAME
                                                                    ,p_staging_column_name  => lc_staging_column_name
                                                                    ,p_staging_column_value => lc_staging_column_value
                                                                    ,p_source_system_ref    => g_stg_tbl(i).source_system_ref
                                                                    ,p_batch_id             => p_batch_id
                                                                    ,p_exception_log        => NULL
                                                                    ,p_oracle_error_code    => NULL
                                                                    ,p_oracle_error_msg     => lc_itm_id_err_msg
                                                                  );
                END;
        END IF;
        END;

-- V1.6 Currency check is being handled in the begining.

        /*IF g_stg_tbl(i).currency_cd IS NOT NULL THEN
            BEGIN
               --------------------------
               -- Validate Currency Code
               --------------------------
               SELECT  'Y'
               INTO    lc_currency_exists
               FROM    fnd_currencies   FC
               WHERE   FC.currency_code   = g_stg_tbl(i).currency_cd
               AND     FC.enabled_flag    = 'Y'
               AND     TRUNC(SYSDATE)
               BETWEEN TRUNC(NVL(FC.start_date_active, SYSDATE))
               AND     TRUNC(NVL(FC.end_Date_active,SYSDATE));

            EXCEPTION
                WHEN OTHERS THEN
                   x_return_status :='E';
                   fnd_message.set_name('XXPTP','XX_PO_60004_INVALID_CURRENCY');
                   fnd_message.set_token('CURRENCY',g_stg_tbl(i).currency_cd);
                   lc_currency_err_msg := SUBSTR(fnd_message.get,1,240);
                   --Adding error message to stack
                   lc_staging_column_name  := 'CURRENCY_CD';
                   lc_staging_column_value := g_stg_tbl(i).currency_cd;

                   XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
                                       (
                                         p_conversion_id        => gn_conversion_id
                                        ,p_record_control_id    => g_stg_tbl(i).control_id
                                        ,p_source_system_code   => g_stg_tbl(i).source_system_code
                                        ,p_package_name         => G_PACKAGE_NAME
                                        ,p_procedure_name       => 'main'
                                        ,p_staging_table_name   => G_STAGING_TABLE_NAME
                                        ,p_staging_column_name  => lc_staging_column_name
                                        ,p_staging_column_value => lc_staging_column_value
                                        ,p_source_system_ref    => g_stg_tbl(i).source_system_ref
                                        ,p_batch_id             => p_batch_id
                                        ,p_exception_log        => NULL
                                        ,p_oracle_error_code    => NULL
                                        ,p_oracle_error_msg     => lc_currency_err_msg
                                      );
            END;
        END IF;
*/

        IF lc_agent_id_exists = 'Y'AND lc_org_id_exists = 'Y' AND lc_vendor_id_exists = 'Y'
            AND lc_inv_item_exists = 'Y'  THEN
            ----------------------------------------------------------------
            -- Set the process_flag to '4' for sucessfully validated records
            ----------------------------------------------------------------
            g_stg_tbl(i).process_flag := 4;
            g_stg_tbl(i).error_message := NULL;
            x_return_status :='S';
        ELSE
            -----------------------------------------------------------
            -- Set the process_flag to '3' for validation failed records
            -----------------------------------------------------------
            g_stg_tbl(i).error_message :=  lc_agent_err_msg ||' '|| lc_org_id_err_msg||' '||
                                           lc_vendr_id_err_msg ||' '||lc_itm_id_err_msg||' '||lc_currency_err_msg;
            g_stg_tbl(i).process_flag := 3;
            x_return_status :='E';
        END IF;--If Return Status is 'S'

        --------------------------------------------------
        -- Get the records in their respective table types
        --------------------------------------------------
        g_ctrl_id_tbl(i)          :=  g_stg_tbl(i).control_id;
        g_pro_flg_tbl(i)          :=  g_stg_tbl(i).process_flag;
        g_err_msg_tbl(i)          :=  g_stg_tbl(i).error_message;
        g_inv_itm_id_tbl(i)       :=  g_stg_tbl(i).inventory_item_id;
        g_ven_site_id_tbl(i)      :=  g_stg_tbl(i).vendor_site_id;
        g_ven_id_tbl(i)           :=  g_stg_tbl(i).ebs_vendor_id;
        g_org_id_tbl(i)           :=  g_stg_tbl(i).org_id;
        g_agent_id_tbl(i)         :=  G_AGENT_ID;
    END LOOP;
    ---------------------------------------------------
    -- Bulk Update the table with the validated results
    ---------------------------------------------------
    FORALL i IN g_stg_tbl.FIRST..g_stg_tbl.LAST
        UPDATE xx_po_quotation_conv_stg
          SET  process_flag       =  g_pro_flg_tbl(i)
              ,error_message      =  g_err_msg_tbl(i)
              ,inventory_item_id  =  g_inv_itm_id_tbl(i)
              ,vendor_site_id     =  g_ven_site_id_tbl(i)
              ,ebs_vendor_id      =  g_ven_id_tbl(i)
              ,org_id             =  g_org_id_tbl(i)
              ,agent_id           =  g_agent_id_tbl(i)
              ,interface_header_id= lt_interface_header_id(i)
          WHERE  control_id       =  g_ctrl_id_tbl(i);
EXCEPTION
    WHEN OTHERS THEN
        x_return_status :='E';
        x_return_msg    :='When Others Exception in  Validate_records SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SUBSTR(SQLERRM,1,500);
        display_log(x_return_msg);
END VALIDATE_PROCESS_RECORDS;

-- +====================================================================+
-- | Name        : process_po                                           |
-- | Description : This procedure is invoked from the main procedure.   |
-- |               This procedure will submit the standard 'Import Price|
-- |               Catalog' concurrent to populate the EBS base tables. |
-- |                                                                    |
-- | In Parameters  :    p_batch_id                                     |
-- | Out Parameters :    x_errbuf                                       |
-- |                     x_retcode                                      |
-- |                                                                    |
-- +====================================================================+
PROCEDURE  PROCESS_PO(
                      x_errbuf         OUT    VARCHAR2
                    , x_retcode        OUT    NUMBER
                    , p_batch_id       IN     NUMBER
                     )
IS
------------------------------
--  Local Variable Declaration
------------------------------
EX_SUBMIT_FAIL              EXCEPTION;
EX_NORMAL_COMPLETION_FAIL   EXCEPTION;
ln_req_indx                 PLS_INTEGER := 0;
lb_program_status           BOOLEAN := TRUE ;
lb_wait                     BOOLEAN;
lt_conc_request_id          FND_CONCURRENT_REQUESTS.request_id%TYPE;
lv_phase                    VARCHAR2(50);
lv_status                   VARCHAR2(50);
lv_dev_phase                VARCHAR2(50);
lv_dev_status               VARCHAR2(50);
lv_message                  VARCHAR2(1000);

------------------------------
-- Variable for child request
------------------------------

TYPE req_rec_type IS RECORD (  req_id   NUMBER );
TYPE lt_req_tab IS TABLE OF req_rec_type
INDEX BY BINARY_INTEGER;
lt_child_req_tab         lt_req_tab;

------------------------
-- Exception declaration
------------------------
BEGIN
    FOR indx IN (SELECT DISTINCT org_id org_id
                 FROM po_headers_interface
                 WHERE batch_id = p_batch_id
                 AND interface_source_code = G_SOURCE_CODE--'C0301'
                )
    LOOP
        display_log(' Current Operating unit: '||indx.org_id);
        ----------------------------------------------------------
        -- Submitting Standard Purchase Order Import concurrent program
        ----------------------------------------------------------
        display_log('p_batch_id in req: '||p_batch_id);
        lt_conc_request_id := FND_REQUEST.submit_request(
                                                          application   => 'PO'
                                                         ,program       => 'POXPDOI'
                                                         ,description   => 'Importing Price Catalogs (Blanket and Quotation) Program'
                                                         ,start_time    => NULL
                                                         ,sub_request   => FALSE        -- FALSE means is not a sub request
                                                         ,argument1     => NULL         --Default Buyer
                                                         ,argument2     => 'Quotation'  -- Document Type
                                                         ,argument3     => 'Catalog'    -- Document  SubType
                                                         ,argument4     => 'N'          --Create or Update  Items
                                                         ,argument5     => 'N'          -- Create Sourcing Rules
                                                         ,argument6     => 'Approved'   --Approval Status
                                                         ,argument7     => NULL         --Release Generation Method
                                                         ,argument8     => p_batch_id
                                                         ,argument9     => indx.org_id
                                                         ,argument10    => NULL
                                                       );

        IF lt_conc_request_id = 0 THEN
            x_errbuf  := SUBSTR(FND_MESSAGE.GET,1,500);
            display_log('Standard Import Price Catalog program failed to submit: ' || x_errbuf);
            RAISE EX_SUBMIT_FAIL;
        ELSE
            lt_child_req_tab(ln_req_indx).req_id   := lt_conc_request_id ;
            ln_req_indx := ln_req_indx +1 ;

            gn_index_request_id := gn_index_request_id + 1;
            gt_import_prg_req_tbl(gn_index_request_id).request_id := lt_conc_request_id;

            COMMIT;
            display_log('Submitted Standard Import Price Catalog program Successfully : '|| lt_conc_request_id );
        END IF;
    END LOOP;
    IF lt_child_req_tab.COUNT > 0 THEN
        FOR ln_req1_indx IN lt_child_req_tab.FIRST..lt_child_req_tab.LAST
        LOOP
            LOOP
                lb_wait := fnd_concurrent.wait_for_request( request_id  => lt_child_req_tab(ln_req1_indx).req_id
                                                           ,interval    => 20
                                                           ,phase       => lv_phase
                                                           ,status      => lv_status
                                                           ,dev_phase   => lv_dev_phase
                                                           ,dev_status  => lv_dev_status
                                                           ,message     => lv_message
                                                          );
                -- *****************************************************************
                -- To make sure this program completes before it moves further
                -- *****************************************************************
                IF  lv_dev_phase  = 'COMPLETE' THEN
                    EXIT ;
                END IF ;
             END LOOP ;
            IF ((lv_dev_phase = 'COMPLETE') AND (lv_dev_status = 'NORMAL')) THEN
                display_log('Submitted Standard Import Price Catalog program Successfully Completed: '||lt_conc_request_id||'completed with normal status');
            ELSE
                display_log('Standard Import Price Catalog program with request id:'||lt_conc_request_id||'did not complete with normal status');
                lb_program_status := FALSE;
            END IF;
        END LOOP;
    END IF;
    ----------------------------------------------------------
    -- When standard prgram ends in error then raise exception
    ----------------------------------------------------------
    IF lb_program_status = FALSE THEN
        RAISE EX_NORMAL_COMPLETION_FAIL;
    END IF;
EXCEPTION
    WHEN EX_SUBMIT_FAIL THEN
        x_retcode := 2;
        x_errbuf  := 'Standard Import Price Catalog program failed to submit: ' || x_errbuf;
    WHEN EX_NORMAL_COMPLETION_FAIL THEN
        x_retcode := 2;
        x_errbuf  := 'Standard Import Price Catalog program failed to Complete Normally' || x_errbuf;
    WHEN OTHERS THEN
        x_errbuf  := 'Unexpected Exception is raised in Procedure PROCESS_PO '||substr(SQLERRM,1,500);
        x_retcode := 2;
END PROCESS_PO;

-- +===================================================================+
-- | Name        :  approve_quotation_lines                           |
-- |                                                                   |
-- | Description :  This procedure will approve the Quotation lines    |
-- |                by calling a Standard API QUOTATION_APPROVALS_PKG  |
-- |                                                                   |
-- | In Parameters : Same as API QUOTATION_APPROVALS_PKG               |
-- |                                                                   |
-- | Out Parameters: Same as API QUOTATION_APPROVALS_PKG x_errbuf      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE approve_quotation_lines
                       (
                         p_rowid                  IN OUT NOCOPY   VARCHAR2
                        ,p_quotation_approval_id  IN OUT NOCOPY   NUMBER
                        ,p_approval_type          IN     VARCHAR2
                        ,p_approval_reason        IN     VARCHAR2
                        ,p_comments               IN     VARCHAR2
                        ,p_approver_id            IN     NUMBER
                        ,p_start_date_active      IN     DATE
                        ,p_end_date_active        IN     DATE
                        ,p_line_location_id       IN     NUMBER
                        ,p_last_update_date       IN     DATE
                        ,p_last_updated_by        IN     NUMBER
                        ,p_last_update_login      IN     NUMBER
                        ,p_creation_date          IN     DATE
                        ,p_created_by             IN     NUMBER
                        ,p_attribute_category     IN     VARCHAR2
                        ,p_attribute1             IN     VARCHAR2
                        ,p_attribute2             IN     VARCHAR2
                        ,p_attribute3             IN     VARCHAR2
                        ,p_attribute4             IN     VARCHAR2
                        ,p_attribute5             IN     VARCHAR2
                        ,p_attribute6             IN     VARCHAR2
                        ,p_attribute7             IN     VARCHAR2
                        ,p_attribute8             IN     VARCHAR2
                        ,p_attribute9             IN     VARCHAR2
                        ,p_attribute10            IN     VARCHAR2
                        ,p_attribute11            IN     VARCHAR2
                        ,p_attribute12            IN     VARCHAR2
                        ,p_attribute13            IN     VARCHAR2
                        ,p_attribute14            IN     VARCHAR2
                        ,p_attribute15            IN     VARCHAR2
                       -- ,p_request_id             IN     NUMBER
                        ,p_program_application_id IN     NUMBER
                        ,p_program_id             IN     NUMBER
                        ,p_program_update_date    IN     DATE
                       )

IS

p_line_id       NUMBER;
ln_line_loc_id  NUMBER;

------------------------------------------------------
--Cursor to find the all the PO Line Location Ids that
--need to be approved
------------------------------------------------------
CURSOR lcu_line_loc_id(p_request_id NUMBER)
IS
   SELECT line_location_id
   FROM   po_line_locations_all plla
   WHERE  plla.request_id = p_request_id;

BEGIN

   IF gt_import_prg_req_tbl.COUNT > 0 THEN
     FOR req_id_idx IN gt_import_prg_req_tbl.FIRST..gt_import_prg_req_tbl.LAST
     LOOP

          FOR lcu_line_locations_rec IN lcu_line_loc_id(gt_import_prg_req_tbl(req_id_idx).request_id)
          LOOP
             display_log('Inside Loop of Cursor ');
             display_log('lcu_line_locations_rec.line_location_id '||lcu_line_locations_rec.line_location_id);
             QUOTATION_APPROVALS_PKG.Insert_Row(
                                             X_Rowid                    =>     p_rowid
                                            ,X_Quotation_Approval_ID    =>     p_quotation_approval_id
                                            ,X_Approval_Type            =>     p_approval_type
                                            ,X_Approval_Reason          =>     p_approval_reason
                                            ,X_Comments                 =>     p_comments
                                            ,X_Approver_ID              =>     p_approver_id
                                            ,X_Start_Date_Active        =>     p_start_date_active
                                            ,X_End_Date_Active          =>     p_end_date_active
                                            ,X_Line_Location_ID         =>     lcu_line_locations_rec.line_location_id
                                            ,X_Last_Update_Date         =>     p_last_update_date
                                            ,X_Last_Updated_By          =>     p_last_updated_by
                                            ,X_Last_Update_Login        =>     p_last_update_login
                                            ,X_Creation_Date            =>     p_creation_date
                                            ,X_Created_By               =>     p_created_by
                                            ,X_Attribute_Category       =>     p_attribute_category
                                            ,X_Attribute1               =>     p_attribute1
                                            ,X_Attribute2               =>     p_attribute2
                                            ,X_Attribute3               =>     p_attribute3
                                            ,X_Attribute4               =>     p_attribute4
                                            ,X_Attribute5               =>     p_attribute5
                                            ,X_Attribute6               =>     p_attribute6
                                            ,X_Attribute7               =>     p_attribute7
                                            ,X_Attribute8               =>     p_attribute8
                                            ,X_Attribute9               =>     p_attribute9
                                            ,X_Attribute10              =>     p_attribute10
                                            ,X_Attribute11              =>     p_attribute11
                                            ,X_Attribute12              =>     p_attribute12
                                            ,X_Attribute13              =>     p_attribute13
                                            ,X_Attribute14              =>     p_attribute14
                                            ,X_Attribute15              =>     p_attribute15
                                            ,X_Request_ID               =>     gt_import_prg_req_tbl(req_id_idx).request_id--p_request_id
                                            ,X_Program_Application_ID   =>     p_program_application_id
                                            ,X_Program_ID               =>     p_program_id
                                            ,X_Program_Update_Date      =>     p_program_update_date
                                             );

              p_rowid                  := NULL;
              p_quotation_approval_id  := NULL;
          END LOOP;

       END LOOP; -- End loop for number of request Ids(Differrent OU case)
   
     COMMIT;
   END IF;
EXCEPTION
    WHEN OTHERS THEN
            XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
                                                       (
                                                         p_conversion_id        => gn_conversion_id
                                                        ,p_record_control_id    => NULL
                                                        ,p_source_system_code   => NULL
                                                        ,p_package_name         => G_PACKAGE_NAME
                                                        ,p_procedure_name       => 'approve_quotation_lines'
                                                        ,p_staging_table_name   => G_STAGING_TABLE_NAME
                                                        ,p_staging_column_name  => NULL
                                                        ,p_staging_column_value => NULL
                                                        ,p_source_system_ref    => NULL
                                                        ,p_batch_id             => NULL
                                                        ,p_exception_log        => NULL
                                                        ,p_oracle_error_code    => SQLCODE
                                                        ,p_oracle_error_msg     => SUBSTR(SQLERRM,1,240)
                                                       );

END approve_quotation_lines;

-- +===================================================================+
-- | Name       :  child_main                                          |
-- |                                                                   |
-- | Description:  This Procedure picks the records from the staging   |
-- |               table for belonging to that batch,validates them and|
-- |               processes them  by calling custom API to import the |
-- |               the records to EBS tables.                          |
-- |                                                                   |
-- | In Parameters : p_validate_only_flag                              |
-- |                 p_reset_status_flag                               |
-- |                 p_batch_id                                        |
-- |                                                                   |
-- | Out Parameters :x_errbuf                                          |
-- |                 x_retcode                                         |
-- +===================================================================+
PROCEDURE child_main
             (
               x_errbuf              OUT VARCHAR2
             , x_retcode             OUT NUMBER
             , p_validate_only_flag  IN VARCHAR2
             , p_reset_status_flag   IN VARCHAR2
             , p_batch_id            IN NUMBER
             , p_debug_flag          IN VARCHAR2
             )
IS
-----------------------
-- Declaring Exceptions
-----------------------
EX_ENTRY_EXCEP                 EXCEPTION;
EX_PROCESS_PO_ERROR            EXCEPTION;

-----------------------------
-- Local Variable Declaration
-----------------------------
ln_vendor_site_id              PLS_INTEGER := 0; -- This variable will allow only one record for a given vendor.
ln_line_num                    PLS_INTEGER := 0; -- This variable will allow only one record for a given vendor.
ln_excpn_request_id            PLS_INTEGER;
lv_retcode                     PLS_INTEGER;
ln_request_id                  PLS_INTEGER;
ln_val_failed                  PLS_INTEGER;
ln_proc_success                PLS_INTEGER;
ln_proc_failed                 PLS_INTEGER;
ln_new_rec_cnt                 PLS_INTEGER;
ln_master_request_id           PLS_INTEGER;
ln_price_break                 PLS_INTEGER;
lc_return_msg                  VARCHAR2(1000);
lv_errbuf                      VARCHAR2(1000);
lc_action                      VARCHAR2(30);
lc_return_status               VARCHAR2(1);
x_return_status                VARCHAR2(1);
lc_vendor_exists               VARCHAR2(1):='N';
ln_total_line                  NUMBER;
ln_validation_failed           NUMBER;
ln_errored                     NUMBER;
ln_success                     NUMBER;
ln_count                       NUMBER;
ln_new_item_line_num           NUMBER :=0;
lc_document_num                po_headers_all.segment1%type;

lc_rowid                     VARCHAR2(100) ;
ln_quotation_approval_id     NUMBER   ;
--ln_approver_id               NUMBER   ;
ld_start_date_active         DATE     ;
ld_end_date_active           DATE     ;
ln_line_location_id          NUMBER   ;
ld_last_update_date          DATE     ;
ln_last_updated_by           NUMBER   ;
ln_last_update_login         NUMBER   ;
ld_creation_date             DATE     ;
ln_created_by                NUMBER   ;
lc_attribute_category        VARCHAR2(100) ;
lc_attribute1                VARCHAR2(100) ;
lc_attribute2                VARCHAR2(100) ;
lc_attribute3                VARCHAR2(100) ;
lc_attribute4                VARCHAR2(100) ;
lc_attribute5                VARCHAR2(100) ;
lc_attribute6                VARCHAR2(100) ;
lc_attribute7                VARCHAR2(100) ;
lc_attribute8                VARCHAR2(100) ;
lc_attribute9                VARCHAR2(100) ;
lc_attribute10               VARCHAR2(100) ;
lc_attribute11               VARCHAR2(100) ;
lc_attribute12               VARCHAR2(100) ;
lc_attribute13               VARCHAR2(100) ;
lc_attribute14               VARCHAR2(100) ;
lc_attribute15               VARCHAR2(100) ;
lc_dup_rec_err_msg           VARCHAR2(240) ;
lc_multiple_cur_err_msg      VARCHAR2(240) ;
lc_invalid_cur_err_msg       VARCHAR2(240) ;
ln_request_id1               NUMBER   ;
ln_program_application_id    NUMBER   ;
ln_program_id                NUMBER   ;
ld_program_update_date       DATE     ;


--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE error_message_tbl_typ IS TABLE OF xx_po_quotation_conv_stg.error_message%type
INDEX BY BINARY_INTEGER;
lt_error_message error_message_tbl_typ;

TYPE error_control_id_tbl_typ IS TABLE OF xx_po_quotation_conv_stg.control_id%type
INDEX BY BINARY_INTEGER;
lt_error_control_id error_control_id_tbl_typ;

TYPE error_line_id_tbl_typ IS TABLE OF xx_po_quotation_conv_stg.interface_line_id%type
INDEX BY BINARY_INTEGER;
lt_error_line_id error_line_id_tbl_typ;

TYPE table_name_tbl_typ IS TABLE OF po_interface_errors.table_name%type
INDEX BY BINARY_INTEGER;
lt_table_name table_name_tbl_typ;

TYPE column_name_tbl_typ IS TABLE OF po_interface_errors.column_name%type
INDEX BY BINARY_INTEGER;
lt_column_name column_name_tbl_typ;

CURSOR lcu_bat_control_id
IS
SELECT control_id
FROM   xx_po_quotation_conv_stg XOPQS
WHERE  XOPQS.load_batch_id = p_batch_id
AND    XOPQS.process_flag = 4;

CURSOR lcu_ready_for_proc_rec
IS
SELECT *
FROM   xx_po_quotation_conv_stg XOPQS
WHERE  XOPQS.process_flag = 5
AND    XOPQS.load_batch_id = p_batch_id
ORDER BY vendor_site_id ;

----------------------------------------------------------------------------------------------
-- Cursor to fetch the Header records for a PO's which got successfully created in EBS tables.
----------------------------------------------------------------------------------------------
CURSOR lcu_success_hdr_data
IS
SELECT vendor_site_id --SUBSTR(interface_source_code,7)
FROM   po_headers_interface POI
WHERE  POI.process_code = 'ACCEPTED'
AND    POI.interface_source_code = G_SOURCE_CODE -- 'C0301'
AND    POI.batch_id = p_batch_id;

---------------------------------------------------------------------
-- Cursor to fetch the Header records for a PO's which got rejected .
---------------------------------------------------------------------
CURSOR lcu_unsuccess_hdr_data
IS
SELECT vendor_site_id --SUBSTR(interface_source_code,7)
FROM   po_headers_interface POI
WHERE  POI.process_code = 'REJECTED'
AND    POI.interface_source_code = G_SOURCE_CODE --'C0301'
AND    POI.batch_id = p_batch_id;

--------------------------------------
--Cursor to fetch all errored records
--------------------------------------
CURSOR lcu_errored_records
IS
    SELECT XPQCS.control_id
          ,XPQCS.interface_line_id
          ,PIE.error_message
          ,PIE.table_name
          ,PIE.column_name
    FROM   po_headers_interface     PHI
          ,po_interface_errors      PIE
          ,xx_po_quotation_conv_stg XPQCS
    WHERE  PHI.process_code        ='REJECTED'
    AND    PIE.interface_header_id = PHI.interface_header_id
    AND    PHI.batch_id            = p_batch_id
    AND    PHI.vendor_site_id      = XPQCS.vendor_site_id
    AND    PIE.interface_type      ='PO_DOCS_OPEN_INTERFACE'
    AND    XPQCS.error_message IS NULL
    AND    XPQCS.process_flag      = 6
    AND    PHI.interface_source_code = G_SOURCE_CODE;

--------------------------------------------------------------------------
--Cursor to fetch number of line records process,validation failed,Errored
--------------------------------------------------------------------------
CURSOR lcu_line_info
IS
SELECT COUNT(CASE WHEN process_flag='3' THEN 1 END)
      ,COUNT(CASE WHEN process_flag='6' THEN 1 END)
      ,COUNT(CASE WHEN process_flag='7' THEN 1 END)
FROM   xx_po_quotation_conv_stg XPQCS
WHERE  XPQCS.load_batch_id = p_batch_id;

-----------------------------------------------------------------------------
--Cursor to select Selecting document number and po_header_id if item-vendor
--combination or vendor_site_id exists
-----------------------------------------------------------------------------
CURSOR lcu_hdr_id_doc_num(
                          p_vendor_site_id    IN NUMBER
                         )
IS
SELECT  PH.po_header_id
       ,PH.segment1
       ,PH.currency_code
       ,PL.line_num
       ,PL.po_line_id
       ,PL.line_type_id
       ,PL.item_id
FROM    po_lines_all PL
       ,po_headers_all PH
WHERE  PH.po_header_id = PL.po_header_id
AND    PH.quote_type_lookup_code = 'CATALOG'
AND    PH.type_lookup_code  = 'QUOTATION'
AND    PH.vendor_site_id  = p_vendor_site_id
AND    PH.status_lookup_code != 'C';

------------------------------------------------
--Cursor to fetch next line number for New Item
------------------------------------------------

CURSOR lcu_new_item_no(p_header_id IN NUMBER)
IS
SELECT MAX(line_num)
FROM   po_lines_all PLL
WHERE  PLL.po_header_id = p_header_id;

BEGIN
    gn_debug_flag := p_debug_flag;
    gr_po_err_rec  :=  gr_po_err_empty_rec;
    

    ---------------------------------------
    -- Get the conversion_id and batch size
    ---------------------------------------
    get_conversion_id
                     (
                      x_conversion_id => gn_conversion_id
                     ,x_batch_size    => gn_batch_size
                     ,x_max_threads   => gn_max_child_req
                     ,x_return_status => lc_return_status
                     );
                     
     IF lc_return_status = 'E' THEN
        RAISE EX_ENTRY_EXCEP;
     END IF;--If lc_return_status ='E'

    ---------------------------------------
    -- Update batch id of the current batch
    ---------------------------------------
    IF NVL(p_reset_status_flag,'N') = 'Y' THEN
        -----------------------------------------------------------
        -- Call update_batch_id to change status of errored records
        -----------------------------------------------------------
        update_batch_id (p_batch_id);
    END IF;

    BEGIN
          -------------------------------------------------------------------------------------
          --Update the records with status as 2 for those which have same supplier and item and
          --have their statuses NULL
          ---------------------------------------------------------------------------------------
           display_log('Error the duplicate records,if any');
           fnd_message.set_name('XXPTP','XX_PO_600010_DUPLICATE_RECORD');
           lc_dup_rec_err_msg := SUBSTR(fnd_message.get,1,240);

           UPDATE xx_po_quotation_conv_stg XPPFRS
           SET    XPPFRS.process_flag     =  3
                 ,XPPFRS.error_code       =  'DUPLICATE_REC'
                 ,XPPFRS.error_message    =  lc_dup_rec_err_msg
                 ,XPPFRS.last_update_date =  SYSDATE
                 ,XPPFRS.last_updated_by  =  G_USER_ID
           WHERE  XPPFRS.process_flag     = 2
           AND    XPPFRS.load_batch_id    = p_batch_id
           AND    XPPFRS.control_id IN (SELECT XPPFRS.control_id
                                       FROM   xx_po_quotation_conv_stg XPQCS
                                       WHERE  XPQCS.sku         =  XPPFRS.sku
                                       AND    XPQCS.vendor_id   =  XPPFRS.vendor_id
                                       AND    XPQCS.control_id  <> XPPFRS.control_id
                                       AND    XPQCS.process_flag = 2
                                      );

           display_log('Number of Duplicate Records updated: '||SQL%rowcount);
           
           fnd_message.set_name('XXPTP','XX_PO_60004_INVALID_CURRENCY');
	   lc_invalid_cur_err_msg:= SUBSTR(fnd_message.get,1,240);                  
	             
	          UPDATE xx_po_quotation_conv_stg XPPFRS
	   	  SET    XPPFRS.process_flag     =  3
	   	        ,XPPFRS.error_code       =  'INVALID_CUR'
	   	        ,XPPFRS.error_message    =  XPPFRS.error_message||lc_invalid_cur_err_msg
	   	        ,XPPFRS.last_update_date =  SYSDATE
	   	        ,XPPFRS.last_updated_by  =  G_USER_ID
	   	  WHERE  XPPFRS.process_flag     = 2
	   	  AND    XPPFRS.load_batch_id    = p_batch_id
	   	  AND    XPPFRS.control_id IN     (SELECT a.control_id 
	   	  	                          FROM xx_po_quotation_conv_stg a
	   	                                  WHERE NOT EXISTS
	   	                                  ( SELECT currency_code FROM fnd_currencies b 
	   	                                    WHERE a.currency_cd    = b.currency_code
	   	                                    AND  b.enabled_flag    = 'Y'
	                                            AND  TRUNC(SYSDATE) BETWEEN 
	                                            TRUNC(NVL(b.start_date_active, SYSDATE))
	                                            AND TRUNC(NVL(b.end_Date_active,SYSDATE))
	                                             ) 
	                                          ) ;
	   
           display_log('Number of Inavlid currency records updated: '||SQL%rowcount);
           display_log('Error the Multiple currency records,if any');
           fnd_message.set_name('XXPTP','XX_PO_60006_MULTIPLE_CURRENCY');
           lc_multiple_cur_err_msg := SUBSTR(fnd_message.get,1,240);

           UPDATE xx_po_quotation_conv_stg XPPFRS
           SET    XPPFRS.process_flag     =  3
                 ,XPPFRS.error_code       =  'MULTIPLE_CUR'
                 ,XPPFRS.error_message    =  XPPFRS.error_message||lc_multiple_cur_err_msg
                 ,XPPFRS.last_update_date =  SYSDATE
                 ,XPPFRS.last_updated_by  =  G_USER_ID
           WHERE  XPPFRS.process_flag     = 2
           AND    XPPFRS.load_batch_id    = p_batch_id
           AND    XPPFRS.control_id IN(SELECT XPPFRS.control_id
                                       FROM   xx_po_quotation_conv_stg XPQCS
                                       WHERE  XPQCS.currency_cd <>  XPPFRS.currency_cd
                                       AND    XPQCS.vendor_id   =  XPPFRS.vendor_id
                                       AND    XPQCS.control_id  <> XPPFRS.control_id
                                       AND    XPQCS.process_flag = 2
                                      );

          display_log('Number of Multiple currency records updated: '||SQL%rowcount);          
          
          FOR lc_error_rec IN (
                               SELECT control_id 
                                     ,source_system_code
                                     ,source_system_ref
                                     ,load_batch_id
                                     ,error_message
                                     ,DECODE(error_code,'DUPLICATE_REC','SKU'||'&'||'VENDOR_ID' 
                                            ,'MULTIPLE_CUR','CURRENCY_CD'
                                            ,'INVALID_CUR','CURRENCY_CD' ) staging_column_name
                                     ,DECODE(error_code,'DUPLICATE_REC','('||SKU||')('||VENDOR_ID||')' 
                                            ,'MULTIPLE_CUR',currency_cd
                                            ,'INVALID_CUR' ,currency_cd ) staging_column_value                                            
                               FROM   xx_po_quotation_conv_stg
                               WHERE process_flag     = 3
                               AND   load_batch_id    = p_batch_id
                               )
          LOOP
             XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
	                                         (
	                                           p_conversion_id        => gn_conversion_id
	                                          ,p_record_control_id    => lc_error_rec.control_id
	                                          ,p_source_system_code   => lc_error_rec.source_system_code
	                                          ,p_package_name         => G_PACKAGE_NAME
	                                          ,p_procedure_name       => 'main'
	                                          ,p_staging_table_name   => G_STAGING_TABLE_NAME
	                                          ,p_staging_column_name  => lc_error_rec.staging_column_name
	                                          ,p_staging_column_value => lc_error_rec.staging_column_value
	                                          ,p_source_system_ref    => lc_error_rec.source_system_ref
	                                          ,p_batch_id             => lc_error_rec.load_batch_id
	                                          ,p_exception_log        => NULL
	                                          ,p_oracle_error_code    => NULL
	                                          ,p_oracle_error_msg     => lc_error_rec.error_message
                                                  );
             END LOOP;
          COMMIT;

     EXCEPTION
         WHEN OTHERS THEN
           XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
                  (
                    p_conversion_id        => gn_conversion_id
                   ,p_record_control_id    => NULL
                   ,p_source_system_code   => NULL
                   ,p_package_name         => G_PACKAGE_NAME
                   ,p_procedure_name       => 'main'
                   ,p_staging_table_name   => G_STAGING_TABLE_NAME
                   ,p_staging_column_name  => NULL
                   ,p_staging_column_value => NULL
                   ,p_source_system_ref    => NULL
                   ,p_batch_id             => NULL
                   ,p_exception_log        => NULL
                   ,p_oracle_error_code    => NULL
                   ,p_oracle_error_msg     => SUBSTR(SQLERRM,1,240)
                  );
          display_log('Unexpected Errors when updating xx_po_price_from_rms_stg for duplicate records: '||SQLERRM);
     END;

    IF lc_return_status = 'S' THEN  --- From get_conversion_id API
    -----------------------------------------------------
    -- Get the count of new records based on the batch_id
    -----------------------------------------------------
    SELECT  COUNT(DISTINCT nvl(vendor_id,1))
    INTO    ln_new_rec_cnt
    FROM    xx_po_quotation_conv_stg XOPQS
    WHERE   XOPQS.process_flag <> 7
    AND     XOPQS.load_batch_id = p_batch_id;

    IF ln_new_rec_cnt > 0 THEN
        ------------------------------------------------------------------------------
        -- Perform the validations by calling  the VALIDATE_PROCESS_RECORDS  procedure
        ------------------------------------------------------------------------------
        VALIDATE_PROCESS_RECORDS
                                (
                                  x_return_status
                                 ,lc_return_msg
                                 ,p_batch_id
                                 ,p_validate_only_flag
                                );
        IF NVL(p_validate_only_flag,'N') ='N'  THEN
            OPEN  lcu_bat_control_id;
            FETCH lcu_bat_control_id BULK COLLECT INTO g_bat_control_id_tbl;
            CLOSE lcu_bat_control_id;

            FORALL i IN 1 .. g_bat_control_id_tbl.LAST
            UPDATE xx_po_quotation_conv_stg XOPQS
            SET    XOPQS.process_flag        = 5
                  --,XOPQS.control_id          = PO_HEADERS_INTERFACE_S.nextval
                  --,XOPQS.interface_line_id   = PO_LINES_INTERFACE_S.nextval
            WHERE  XOPQS.control_id          = g_bat_control_id_tbl(i);
          --  COMMIT;

            OPEN  lcu_ready_for_proc_rec;
            FETCH lcu_ready_for_proc_rec BULK COLLECT INTO g_ready_for_proc_tbl;
            CLOSE lcu_ready_for_proc_rec;

            IF g_ready_for_proc_tbl.COUNT > 0 THEN

                FOR i IN g_ready_for_proc_tbl.FIRST .. g_ready_for_proc_tbl.LAST
                LOOP
                    BEGIN
                        qty_price_tbl.DELETE;
                        qty_price_tbl(1).quantity := g_ready_for_proc_tbl(i).Tier1_qty;
                        qty_price_tbl(1).price    := g_ready_for_proc_tbl(i).Tier1_cost;
                        qty_price_tbl(2).quantity := g_ready_for_proc_tbl(i).Tier2_qty;
                        qty_price_tbl(2).price    := g_ready_for_proc_tbl(i).Tier2_cost;
                        qty_price_tbl(3).quantity := g_ready_for_proc_tbl(i).Tier3_qty;
                        qty_price_tbl(3).price    := g_ready_for_proc_tbl(i).Tier3_cost;
                        qty_price_tbl(4).quantity := g_ready_for_proc_tbl(i).Tier4_qty;
                        qty_price_tbl(4).price    := g_ready_for_proc_tbl(i).Tier4_cost;
                        qty_price_tbl(5).quantity := g_ready_for_proc_tbl(i).Tier5_qty;
                        qty_price_tbl(5).price    := g_ready_for_proc_tbl(i).Tier5_cost;
                        qty_price_tbl(6).quantity := g_ready_for_proc_tbl(i).Tier6_qty;
                        qty_price_tbl(6).price    := g_ready_for_proc_tbl(i).Tier6_cost;

                        -- If the end tiered qty and cost is 0, then no need to populate the price breaks. V1.6
                        IF nvl(qty_price_tbl(6).quantity,0) = 0 AND nvl(qty_price_tbl(6).price,0) = 0 THEN
                           IF nvl(qty_price_tbl(5).quantity,0) = 0 AND nvl(qty_price_tbl(5).price,0) = 0 THEN
                              IF nvl(qty_price_tbl(4).quantity,0) = 0 AND nvl(qty_price_tbl(4).price,0) = 0 THEN
                                 IF nvl(qty_price_tbl(3).quantity,0) = 0 AND nvl(qty_price_tbl(3).price,0) = 0 THEN
                                    IF nvl(qty_price_tbl(2).quantity,0) = 0 AND nvl(qty_price_tbl(2).price,0) = 0 THEN
                                       IF nvl(qty_price_tbl(1).quantity,0) = 0 AND nvl(qty_price_tbl(1).price,0) = 0 THEN
                                          ln_count := 0;
                                       ELSE
                                          ln_count := 1;
                                       END IF;
                                    ELSE
                                       ln_count := 2;
                                    END IF;
                                 ELSE
                                    ln_count := 3;
                                 END IF;
                              ELSE
                                 ln_count := 4;
                              END IF;
                           ELSE
                              ln_count := 5;
                           END IF;
                        ELSE
                           ln_count := 6;
                        END IF;

                        --------------------------------------------------------------------------------------------------------------------------------
                        -- Insert all the eligibile records which are having process_flag = 5 ("Processing In Progress") into PO Headers interface table
                        --------------------------------------------------------------------------------------------------------------------------------
                        IF g_ready_for_proc_tbl(i).vendor_site_id <> ln_vendor_site_id
                        THEN
                            ln_vendor_site_id  := g_ready_for_proc_tbl(i).vendor_site_id;
                            display_log('Vendor_site_id: '|| g_ready_for_proc_tbl(i).vendor_site_id);
                            FOR indx_hdr_id_doc_num IN lcu_hdr_id_doc_num(g_ready_for_proc_tbl(i).vendor_site_id)
                            LOOP
                               IF lcu_hdr_id_doc_num%NOTFOUND THEN
                                   lc_vendor_exists   :='N';
                                   ln_line_num        := 0;
                                   lc_document_num    := NULL;
                               ELSE
                                   OPEN  lcu_new_item_no(indx_hdr_id_doc_num.po_header_id);
                                   FETCH lcu_new_item_no INTO ln_new_item_line_num;

                                      IF lcu_new_item_no%NOTFOUND THEN
                                        ln_line_num        := 0;
                                      ELSE
                                        ln_line_num := ln_new_item_line_num;
                                      END IF;
                                   CLOSE lcu_new_item_no;
                                   lc_vendor_exists  :='Y';
                                   lc_document_num := indx_hdr_id_doc_num.segment1;
                               END IF;
                             END LOOP;
                             display_log('Document num '|| lc_document_num);
                             SELECT DECODE(lc_vendor_exists,'Y','UPDATE','ORIGINAL')
                             INTO lc_action
                             FROM dual;

                            INSERT INTO po_headers_interface(
                                                              INTERFACE_HEADER_ID --Unique ID
                                                             ,DOCUMENT_NUM
                                                             ,INTERFACE_SOURCE_CODE
                                                             ,PROCESS_CODE
                                                             ,BATCH_ID
                                                             ,ACTION
                                                             ,DOCUMENT_TYPE_CODE
                                                             ,DOCUMENT_SUBTYPE
                                                             ,CURRENCY_CODE
                                                             ,AGENT_ID
                                                             ,VENDOR_SITE_ID
                                                             ,VENDOR_ID
                                                             ,ORG_ID
                                                             ,QUOTE_WARNING_DELAY
                                                             ,ATTRIBUTE_CATEGORY
                                                             ,ATTRIBUTE1
                                                             ,CREATION_DATE
                                                             ,CREATED_BY
                                                             ,LAST_UPDATE_DATE
                                                             ,LAST_UPDATED_BY
                                                             ,LAST_UPDATE_LOGIN
                                                            )
                                                      VALUES(
                                                             g_ready_for_proc_tbl(i).interface_header_id -- This Value is already captured
                                                            ,lc_document_num
                                                            ,G_SOURCE_CODE --'C0301 - RMS_PRICE_CONV'--||g_ready_for_proc_tbl(i).control_id--'C0301_PurchasePriceFromRMS'
                                                            ,'PENDING'
                                                            ,p_batch_id
                                                            ,lc_action
                                                            ,'QUOTATION'
                                                            ,'CATALOG'
                                                            ,g_ready_for_proc_tbl(i).currency_cd
                                                            ,g_ready_for_proc_tbl(i).agent_id
                                                            ,g_ready_for_proc_tbl(i).vendor_site_id
                                                            ,g_ready_for_proc_tbl(i).ebs_vendor_id
                                                            ,g_ready_for_proc_tbl(i).org_id
                                                            ,0
                                                            ,'Trade Quotation'
                                                            ,G_PO_SOURCE
                                                            ,SYSDATE--g_ready_for_proc_tbl(i).creation_date
                                                            ,G_USER_ID--g_ready_for_proc_tbl(i).created_by
                                                            ,SYSDATE--g_ready_for_proc_tbl(i).last_update_date
                                                            ,G_USER_ID--g_ready_for_proc_tbl(i).last_updated_by
                                                            ,G_USER_ID--g_ready_for_proc_tbl(i).last_update_login
                                                            );
                        END IF;
                    EXCEPTION
                    WHEN OTHERS THEN
                        display_log('When OTHERS error while inserting data into PO Headers interface table'||SQLERRM);
                        x_retcode := 2;
                    END;
                    ---------------------------------------------------------------
                    -- Insert one record with 0 price into PO Lines interface table
                    ---------------------------------------------------------------
                    ln_line_num := ln_line_num + 1;
                    INSERT INTO po_lines_interface(
                                                    INTERFACE_LINE_ID
                                                   ,INTERFACE_HEADER_ID
                                                   ,ACTION
                                                   ,LINE_NUM
                                                   ,LINE_TYPE
                                                   ,ITEM
                                                   ,ITEM_ID
                                                   ,QUANTITY
                                                   ,UNIT_PRICE
                                                   ,SHIPMENT_TYPE
                                                   ,LINE_ATTRIBUTE_CATEGORY_LINES
                                                   ,SHIPMENT_ATTRIBUTE6
                                                   ,SHIPMENT_ATTRIBUTE7
                                                   ,SHIPMENT_ATTRIBUTE8
                                                   ,SHIPMENT_ATTRIBUTE_CATEGORY
                                                   ,CREATION_DATE
                                                   ,CREATED_BY
                                                   ,LAST_UPDATE_DATE
                                                   ,LAST_UPDATED_BY
                                                   ,LAST_UPDATE_LOGIN
                                                  )
                                           VALUES
                                                  (
                                                    PO_LINES_INTERFACE_S.nextval
                                                   ,g_ready_for_proc_tbl(i).interface_header_id-- g_ready_for_proc_tbl(i).control_id -- This Value is already captured --, PO_HEADERS_INTERFACE_S.currval
                                                   ,'ORIGINAL'
                                                   ,ln_line_num
                                                   ,'Goods'
                                                   ,g_ready_for_proc_tbl(i).sku
                                                   ,g_ready_for_proc_tbl(i).inventory_item_id--decode(i,1,10000000,g_ready_for_proc_tbl(i).inventory_item_id)--
                                                   ,NULL
                                                   ,0
                                                   ,'QUOTATION'
                                                   ,'Trade Quotation'
                                                   ,g_ready_for_proc_tbl(i).total_cost
                                                   ,g_ready_for_proc_tbl(i).price_protect_flg
                                                   ,g_ready_for_proc_tbl(i).active_date
                                                   ,'Trade Quotation'
                                                   ,SYSDATE--g_ready_for_proc_tbl(i).creation_date
                                                   ,G_USER_ID--g_ready_for_proc_tbl(i).created_by
                                                   ,SYSDATE--g_ready_for_proc_tbl(i).last_update_date
                                                   ,G_USER_ID--g_ready_for_proc_tbl(i).last_updated_by
                                                   ,G_USER_ID--g_ready_for_proc_tbl(i).last_update_login
                                                  );
                    -------------------------------------------------------------------------------------------------------------------------------------------------------
                    -- Insert one record with 0 price and quantity 1 for records which are having process_flag = 5 ("Processing In Progress") into PO Lines interface table
                    -------------------------------------------------------------------------------------------------------------------------------------------------------
                    INSERT INTO po_lines_interface(
                                                    INTERFACE_LINE_ID
                                                   ,INTERFACE_HEADER_ID
                                                   ,ACTION
                                                   ,LINE_NUM
                                                   ,SHIPMENT_NUM
                                                   ,LINE_TYPE
                                                   ,ITEM
                                                   ,ITEM_ID
                                                   ,QUANTITY
                                                   ,UNIT_PRICE
                                                   ,SHIPMENT_TYPE
                                                   ,LINE_ATTRIBUTE_CATEGORY_LINES
                                                   ,SHIPMENT_ATTRIBUTE6
                                                   ,SHIPMENT_ATTRIBUTE7
                                                   ,SHIPMENT_ATTRIBUTE8
                                                   ,SHIPMENT_ATTRIBUTE_CATEGORY
                                                   ,EFFECTIVE_DATE
                                                   ,CREATION_DATE
                                                   ,CREATED_BY
                                                   ,LAST_UPDATE_DATE
                                                   ,LAST_UPDATED_BY
                                                   ,LAST_UPDATE_LOGIN
                                                  )
                                           VALUES
                                                  (
                                                    PO_LINES_INTERFACE_S.nextval
                                                   ,g_ready_for_proc_tbl(i).interface_header_id--g_ready_for_proc_tbl(i).control_id -- This Value is already captured --, PO_HEADERS_INTERFACE_S.currval
                                                   ,'ORIGINAL'
                                                   ,ln_line_num
                                                   ,1
                                                   ,'Goods'
                                                   ,g_ready_for_proc_tbl(i).sku
                                                   ,g_ready_for_proc_tbl(i).inventory_item_id--decode(i,1,10000000,g_ready_for_proc_tbl(i).inventory_item_id)--
                                                   ,1
                                                   ,g_ready_for_proc_tbl(i).unit_cost
                                                   ,'QUOTATION'
                                                   ,'Trade Quotation'
                                                   ,g_ready_for_proc_tbl(i).total_cost
                                                   ,g_ready_for_proc_tbl(i).price_protect_flg
                                                   ,g_ready_for_proc_tbl(i).active_date
                                                   ,'Trade Quotation'
                                                   ,g_ready_for_proc_tbl(i).real_eff_date
                                                   ,SYSDATE--g_ready_for_proc_tbl(i).creation_date
                                                   ,G_USER_ID--g_ready_for_proc_tbl(i).created_by
                                                   ,SYSDATE--g_ready_for_proc_tbl(i).last_update_date
                                                   ,G_USER_ID--g_ready_for_proc_tbl(i).last_updated_by
                                                   ,G_USER_ID--g_ready_for_proc_tbl(i).last_update_login
                                                  );
                    -------------------------------------------------------------------------------------------------------------------------------
                    -- Insert all the eligibile records which are having process_flag = 5 ("Processing In Progress") into PO Lines interface table
                    -------------------------------------------------------------------------------------------------------------------------------
                    ln_price_break := 0 ;
                    FOR no_of_price_breaks IN 1..ln_count
                    LOOP
                        display_log('i Price'||i||'no_of_price_breaks'||no_of_price_breaks);
                        BEGIN
                        IF qty_price_tbl(no_of_price_breaks).quantity IS NOT NULL
                        AND qty_price_tbl(no_of_price_breaks).price IS NOT NULL  THEN
                            ln_price_break := no_of_price_breaks +1; -- This is to increment the price break for next shipment
                            INSERT INTO po_lines_interface(
                                                            INTERFACE_LINE_ID
                                                           ,INTERFACE_HEADER_ID
                                                           ,ACTION
                                                           ,LINE_NUM
                                                           ,SHIPMENT_NUM --Starts with 1,increments for each price break by 1.
                                                           ,LINE_TYPE
                                                           ,ITEM
                                                           ,ITEM_ID
                                                           ,QUANTITY
                                                           ,UNIT_PRICE
                                                           ,SHIPMENT_TYPE
                                                           ,LINE_ATTRIBUTE_CATEGORY_LINES
                                                           ,SHIPMENT_ATTRIBUTE6
                                                           ,SHIPMENT_ATTRIBUTE7
                                                           ,SHIPMENT_ATTRIBUTE8
                                                           ,SHIPMENT_ATTRIBUTE_CATEGORY
                                                           ,EFFECTIVE_DATE
                                                           ,CREATION_DATE
                                                           ,CREATED_BY
                                                           ,LAST_UPDATE_DATE
                                                           ,LAST_UPDATED_BY
                                                           ,LAST_UPDATE_LOGIN
                                                          )
                                                   VALUES
                                                          (
                                                            PO_LINES_INTERFACE_S.nextval
                                                           ,g_ready_for_proc_tbl(i).interface_header_id--g_ready_for_proc_tbl(i).control_id -- This Value is already captured --, PO_HEADERS_INTERFACE_S.currval
                                                           ,'ORIGINAL'
                                                           ,ln_line_num
                                                           ,ln_price_break--Starts with 1,increments for each price break by 1.
                                                           ,'Goods'
                                                           ,g_ready_for_proc_tbl(i).sku
                                                           ,g_ready_for_proc_tbl(i).inventory_item_id--decode(i,1,10000000,g_ready_for_proc_tbl(i).inventory_item_id)
                                                           ,qty_price_tbl(no_of_price_breaks).quantity
                                                           ,qty_price_tbl(no_of_price_breaks).price
                                                           ,'QUOTATION'
                                                           ,'Trade Quotation'
                                                           ,g_ready_for_proc_tbl(i).total_cost--'Trade Quotation'
                                                           ,g_ready_for_proc_tbl(i).price_protect_flg
                                                           ,g_ready_for_proc_tbl(i).active_date--g_ready_for_proc_tbl(i).total_cost
                                                           ,'Trade Quotation'
                                                           ,g_ready_for_proc_tbl(i).real_eff_date
                                                           ,SYSDATE--g_ready_for_proc_tbl(i).creation_date
                                                           ,G_USER_ID--g_ready_for_proc_tbl(i).created_by
                                                           ,SYSDATE--g_ready_for_proc_tbl(i).last_update_date
                                                           ,G_USER_ID--g_ready_for_proc_tbl(i).last_updated_by
                                                           ,G_USER_ID--g_ready_for_proc_tbl(i).last_update_login
                                                         );
                        END IF;
                        EXCEPTION
                            WHEN OTHERS THEN
                                display_log('When OTHERS error while inserting data into PO lines interface table');
                                x_retcode := 2;
                        END;
                    END LOOP;
                    --COMMIT; --com
                END LOOP;--header loop
                -- COMMIT;
            END IF; --g_ready_for_proc_tbl.COUNT > 0
        END IF; --NVL(p_validate_only_flag,'N') ='N'
        ---------------------------------------------------------------------------------------------------------------------------------
        -- Calling Process_po procedure to insert data in interface table and to submit Standard Import Price Catalog concurrent program.
        ---------------------------------------------------------------------------------------------------------------------------------
        process_po(
                    x_errbuf    => lv_errbuf
                   ,x_retcode   => lv_retcode
                   ,p_batch_id  => p_batch_id
                  );
        IF lv_retcode <> 0 THEN
            x_errbuf := lv_errbuf;
            display_log('Error in Calling Process_PO procedure :- ');
            RAISE EX_PROCESS_PO_ERROR;
        END IF;
        --------------------------------------------------------------------
        -- Header level cursor for the successful PO Quotation staging table
        --------------------------------------------------------------------
        OPEN  lcu_success_hdr_data;
        FETCH lcu_success_hdr_data BULK COLLECT INTO g_success_po_hdr_tbl;
        CLOSE lcu_success_hdr_data;

        -----------------------------------------------------------------------------------------------------------
        -- Updating Header Staging table with Process_flag to 7 for all those Quotations which got ACCEPTED in EBS.
        -----------------------------------------------------------------------------------------------------------
        FORALL i IN g_success_po_hdr_tbl.FIRST..g_success_po_hdr_tbl.LAST
        UPDATE  xx_po_quotation_conv_stg
        SET     process_flag    = 7
        WHERE   vendor_site_id  = g_success_po_hdr_tbl(i)
        AND     error_message IS NULL ;  -- This is to avoid records which got errored during validation

        ----------------------------------------------------------------------
        -- Header level cursor for the unsuccessful PO Quotation staging table
        ----------------------------------------------------------------------
        OPEN  lcu_unsuccess_hdr_data;
        FETCH lcu_unsuccess_hdr_data BULK COLLECT INTO g_unsuccess_po_hdr_tbl;
        CLOSE lcu_unsuccess_hdr_data;

        -----------------------------------------------------------------------------------------------------
        -- Updating Header Staging table with Process_flag to 6 for all those PO's which got REJECTED in EBS.
        -----------------------------------------------------------------------------------------------------
        FORALL i IN g_unsuccess_po_hdr_tbl.FIRST..g_unsuccess_po_hdr_tbl.LAST
        UPDATE  xx_po_quotation_conv_stg XOPQS
        SET     XOPQS.process_flag   = 6
        WHERE   XOPQS.vendor_site_id = g_unsuccess_po_hdr_tbl(i)
        AND     error_message IS NULL ;  -- This is to avoid records which got errored during validation

        COMMIT;

        -------------------------------------
        -- Get the validation failed records
        -------------------------------------
        SELECT COUNT(DISTINCT nvl(vendor_id,1))
        INTO   ln_val_failed
        FROM   xx_po_quotation_conv_stg XPQCS1
        WHERE  load_batch_id = p_batch_id
        AND    process_flag  = 3
        AND    NOT EXISTS (SELECT 1
                       FROM   xx_po_quotation_conv_stg XPQCS2
                       WHERE  XPQCS1.vendor_id=XPQCS2.vendor_id
                       AND process_flag='7');

        -----------------------------------------
        -- Get the successfully processed records
        -----------------------------------------
        SELECT COUNT(DISTINCT nvl(vendor_id,1))
        INTO   ln_proc_success
        FROM   xx_po_quotation_conv_stg
        WHERE  load_batch_id = p_batch_id
        AND    process_flag  = 7;

        ------------------------------------
        -- Get the processing failed records
        ------------------------------------
        SELECT COUNT(DISTINCT nvl(vendor_id,1))
        INTO   ln_proc_failed
        FROM   xx_po_quotation_conv_stg XPQCS1
        WHERE  load_batch_id = p_batch_id
        AND    process_flag = 6
        AND    NOT EXISTS (SELECT 1
                       FROM   xx_po_quotation_conv_stg XPQCS2
                       WHERE  XPQCS1.vendor_id=XPQCS2.vendor_id
                       AND process_flag='7');

        ---------------------------------------------------------------------------------
        --Deriving Validation falied, Errored, Successful and total records at line level
        ---------------------------------------------------------------------------------
        OPEN  lcu_line_info;
        FETCH lcu_line_info INTO ln_validation_failed,ln_errored,ln_success;
        CLOSE lcu_line_info;
        ln_total_line := ln_validation_failed+ln_errored+ln_success;

        -------------------------------------------------------------------
        -- Logging Errors for PO Records rejected by std. Interface program
        -------------------------------------------------------------------
        OPEN lcu_errored_records;
        FETCH lcu_errored_records BULK COLLECT
        INTO  lt_error_control_id
             ,lt_error_line_id
             ,lt_error_message
             ,lt_table_name
             ,lt_column_name;

        FORALL i IN lt_error_control_id.FIRST..lt_error_control_id.LAST
        UPDATE xx_po_quotation_conv_stg
        SET    error_message = lt_error_message(i)
        WHERE  control_id    = lt_error_control_id(i)
        OR     interface_line_id = lt_error_line_id(i); -- Update if error is at line level

        IF lt_error_control_id.count<>0 THEN
            FOR i IN lt_error_control_id.FIRST..lt_error_control_id.LAST
            LOOP
                ------------------------------------------------------
                --Assigning values to the columns of error record type
                ------------------------------------------------------
                gr_po_err_rec.oracle_error_msg    :=  lt_error_message(i);
                gr_po_err_rec.staging_column_name :=  lt_column_name(i);
                gr_po_err_rec.oracle_error_code   :=  NULL;
                gr_po_err_rec.record_control_id   :=  lt_error_control_id(i);
                gr_po_err_rec.request_id          :=  FND_GLOBAL.CONC_REQUEST_ID;
                gr_po_err_rec.converion_id        :=  gn_conversion_id;
                gr_po_err_rec.package_name        :=  G_PACKAGE_NAME;
                gr_po_err_rec.procedure_name      :=  'child_main';
                gr_po_err_rec.staging_table_name  :=  G_STAGING_TABLE_NAME;
                gr_po_err_rec.batch_id            :=  p_batch_id;
                XX_COM_CONV_ELEMENTS_PKG.bulk_add_message(gr_po_err_rec);
            END LOOP;
        END IF;
        CLOSE lcu_errored_records;
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;

        ---------------------------------------------------------------------------------------------------
        -- Gets the master request Id which needs to be passed while updating Control Information Log Table
        ---------------------------------------------------------------------------------------------------
        get_master_request_id
                              (
                              p_conversion_id     => gn_conversion_id
                             ,p_batch_id          => p_batch_id
                             ,x_master_request_id => ln_master_request_id
                             );

        ---------------------------------------------------------------------------------------------
        -- XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc is called over
        -- to log the exception of the record while processing
        ---------------------------------------------------------------------------------------------
        XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
                                                     (
                                                       p_conc_mst_req_id             => ln_master_request_id
                                                     , p_batch_id                    => p_batch_id
                                                     , p_conversion_id               => gn_conversion_id
                                                     , p_num_bus_objs_failed_valid   => ln_validation_failed--ln_val_failed
                                                     , p_num_bus_objs_failed_process => ln_errored--ln_proc_failed
                                                     , p_num_bus_objs_succ_process   => ln_success--ln_proc_success
                                                     );

        --------------------------------------------------------------------------------------------
        -- To launch the Exception Log Report for this batch
        --------------------------------------------------------------------------------------------
        launch_exception_report(
                                 p_batch_id         =>p_batch_id                    -- Batch id
                                ,p_conc_req_id      =>fnd_global.conc_request_id    -- Child Request id
                                ,p_master_req_id    =>NULL                          -- Master Request id
                                ,x_errbuf           =>x_errbuf
                                ,x_retcode          =>x_retcode
                               );

        --------------------------------------------------------------------------------------------
        -- Calling the Program to approve the Quotation Lines
        --------------------------------------------------------------------------------------------

        display_log('Calling the Program to approve the Quotation Lines');

        approve_quotation_lines
                       (
                           p_rowid                    =>     lc_rowid
                          ,p_Quotation_Approval_ID    =>     ln_quotation_approval_id
                          ,p_Approval_Type            =>     GC_APPROVAL_TYPE
                          ,p_Approval_Reason          =>     GC_APPROVAL_REASON
                          ,p_Comments                 =>     GC_COMMENTS
                          ,p_Approver_ID              =>     G_AGENT_ID --ln_approver_id
                          ,p_Start_Date_Active        =>     ld_start_date_active
                          ,p_End_Date_Active          =>     ld_end_date_active
                          ,p_Line_Location_ID         =>     ln_line_location_id
                          ,p_Last_Update_Date         =>     SYSDATE
                          ,p_Last_Updated_By          =>     G_USER_ID
                          ,p_Last_Update_Login        =>     ln_last_update_login
                          ,p_Creation_Date            =>     SYSDATE
                          ,p_Created_By               =>     G_USER_ID
                          ,p_Attribute_Category       =>     lc_attribute_category
                          ,p_Attribute1               =>     lc_attribute1
                          ,p_Attribute2               =>     lc_attribute2
                          ,p_Attribute3               =>     lc_attribute3
                          ,p_Attribute4               =>     lc_attribute4
                          ,p_Attribute5               =>     lc_attribute5
                          ,p_Attribute6               =>     lc_attribute6
                          ,p_Attribute7               =>     lc_attribute7
                          ,p_Attribute8               =>     lc_attribute8
                          ,p_Attribute9               =>     lc_attribute9
                          ,p_Attribute10              =>     lc_attribute10
                          ,p_Attribute11              =>     lc_attribute11
                          ,p_Attribute12              =>     lc_attribute12
                          ,p_Attribute13              =>     lc_attribute13
                          ,p_Attribute14              =>     lc_attribute14
                          ,p_Attribute15              =>     lc_attribute15
                        --  ,p_Request_ID               =>     ln_request_id1
                          ,p_Program_Application_ID   =>     ln_program_application_id
                          ,p_Program_ID               =>     ln_program_id
                          ,p_Program_Update_Date      =>     ld_program_update_date
                       );
        ----------------------------------------
        --Displaying information at header level
        ----------------------------------------
        display_out('====================================================================================');
        display_out(RPAD('Total no Of Puchase Price Header Records                     :',70)||ln_new_rec_cnt);
        display_out(RPAD('Total no Of Puchase Price Header Records failed in validation:',70)||ln_val_failed);
        display_out(RPAD('Total no Of Puchase Price Header Records Processed           :',70)||ln_proc_success);
        display_out(RPAD('Total no Of Puchase Price Header Records Errored             :',70)||ln_proc_failed);
        display_out('====================================================================================');

        --------------------------------------
        --Displaying information at line level
        --------------------------------------
        display_out('====================================================================================');
        display_out(RPAD('Total no Of Puchase Price Line Records                     :',70)||ln_total_line);
        display_out(RPAD('Total no Of Puchase Price Line Records failed in validation:',70)||ln_validation_failed);
        display_out(RPAD('Total no Of Puchase Price Line Records Processed           :',70)||ln_success);
        display_out(RPAD('Total no Of Puchase Price Line Records Errored             :',70)||ln_errored);
        display_out('====================================================================================');
        ELSE
             display_log('No records in staging with status as Validation in progress');
        END IF;--If ln_new_rec_cnt > 0
    ELSE
        RAISE EX_ENTRY_EXCEP;
    END IF;--If lc_return_status ='S'
EXCEPTION
    WHEN EX_PROCESS_PO_ERROR THEN
        x_errbuf  := 'Unexpected Exception is raised while calling Procedure PROCESS_PO ';
        x_retcode := 2;
    WHEN EX_ENTRY_EXCEP THEN
        x_retcode := 2;
        display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE);
    WHEN NO_DATA_FOUND THEN
        x_retcode := 2;
        x_errbuf  := ('When No_data_Found  Exception in  Main SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SUBSTR(SQLERRM,1,500));
        display_log(x_errbuf);
    WHEN OTHERS THEN
        x_retcode := 2;
        x_errbuf  := ('When Others Exception in  Main SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SUBSTR(SQLERRM,1,500));
        display_log(x_errbuf);
END child_main;

-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: PO Quotations|
-- |                Conversion Master Concurrent Request.This would     |
-- |                submit child programs based on batch_size           |
-- |                                                                    |
-- | Parameters  :  p_validate_only_flag                                |
-- |                p_reset_status_flag                                 |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- +====================================================================+
PROCEDURE MASTER_MAIN(
                      x_errbuf             OUT VARCHAR2
                     ,x_retcode            OUT NUMBER
                     ,p_validate_only_flag IN  VARCHAR2
                     ,p_reset_status_flag  IN  VARCHAR2
                     ,p_batch_size         IN  VARCHAR2
                     ,p_no_of_threads      IN  VARCHAR2
                     ,p_debug_flag         IN  VARCHAR2
                     )
IS

-----------------------------
-- Local Variable Declaration
-----------------------------
EX_SUB_REQ_ERROR   EXCEPTION;
ln_return_status   NUMBER;
lc_request_data    VARCHAR2(1000);
lc_error_message   VARCHAR2(4000);

BEGIN

    gn_debug_flag := p_debug_flag;
    lc_request_data := FND_CONC_GLOBAL.request_data;
    gn_request_id := FND_GLOBAL.CONC_REQUEST_ID;
    IF lc_request_data IS NULL THEN
        submit_sub_requests
                          (
                            p_validate_only_flag
                           ,p_reset_status_flag
                           ,p_batch_size
                           ,p_no_of_threads
                           ,lc_error_message
                           ,ln_return_status
                          );
        IF ln_return_status <> 0 THEN
            x_errbuf := lc_error_message;
            display_log('Error in submit_sub_requests :- ');
            display_log(lc_error_message );
            RAISE EX_SUB_REQ_ERROR;
        END IF;
    END IF;

COMMIT;

EXCEPTION
    WHEN EX_SUB_REQ_ERROR THEN
     -- x_retcode := 2;
        x_retcode := ln_return_status;
    WHEN NO_DATA_FOUND THEN
        x_retcode := 2;
        display_log('No Data Found to continue');
    WHEN OTHERS THEN
        x_retcode := 2;
        x_errbuf  := 'Unexpected error in main procedure - '||SUBSTR(SQLERRM,1,500);
        display_log('Unexpected error in main procedure - '||SUBSTR(SQLERRM,1,500));
END master_main;
END XX_PO_QUOTS_IMP_PKG;
/

SHOW ERRORS
EXIT;

-- ******************** End of Script ******************************