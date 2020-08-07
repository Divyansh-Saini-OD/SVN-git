SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_ROQ_PREPROC_PKG

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_ROQ_PREPROC_PKG                                                |
-- | Description      : Package Body for E0406_PO_ROQ_PreProcessor                           |
-- |                                                                                         |
-- | This package contains the following sub programs:                                       |
-- | =================================================                                       |
-- | Type        Name                 Description                                            |
-- | =========   ===========          ===================================                    |
-- | PROCEDURE   write_log            This procedure is used to write messages into the log  |
-- |                                  file.                                                  |
-- |                                                                                         |
-- | PROCEDURE   write_out            This procedure is used to write messages into the      |
-- |                                  output file.                                           |
-- |                                                                                         |
-- | PROCEDURE   assign_val_id        This procedure is used to assign validation thread ids |
-- |                                  to records which need to be processed .                |
-- |                                                                                         |
-- | PROCEDURE   call_val_cp          This procedure is used to call the Concurrent Program  |
-- |                                  "OD: PO ROQ Preprocessor Validate Program"             |
-- |                                                                                         |
-- | PROCEDURE   assign_batch_id      This procedure is used to Assign batch ids to the valid|
-- |                                  records in the interface table.                        |
-- |                                                                                         |
-- | PROCEDURE   call_std_import      This procedure is to call the "Standard Import Purchase|
-- |                                  Order" Concurrent Program from the Preprocessor        |
-- |                                                                                         |
-- | PROCEDURE   update_po_quot       This procedure is to Update the successfully created   |
-- |                                  PO lines with the quotation details.                   |
-- |                                                                                         |
-- | PROCEDURE   create_alloc         This procedure is used to create allocations for POs   |
-- |                                  which were successfully created by the preprocessor.   |
-- |                                                                                         |
-- | PROCEDURE   update_stg           This procedure is to update the staging tables with    |
-- |                                  status messages                                        |
-- |                                                                                         |
-- | PROCEDURE   delete_data          This procedure is to delete data from the staging      |
-- |                                  tables after profile defined amount of time            |
-- |                                                                                         |
-- | PROCEDURE   val_po_lines         This procedure is used to validate number of PO lines  |
-- |                                  present for a give PO header record.                   |
-- |                                                                                         |
-- | PROCEDURE   get_ebs_supp_data    This procedure is used to get ebs data from given      |
-- |                                  legacy supplier number                                 |
-- |                                                                                         |
-- | PROCEDURE   get_ebs_loc_data     This procedure is used to get ebs data from given      |
-- |                                  legacy location id.                                    |
-- |                                                                                         |
-- | PROCEDURE   get_buyer_potype     This procedure is used to get determine the buyer and  |
-- |                                  the PO type for the PO record being processed          |
-- |                                                                                         |
-- | PROCEDURE   get_prms_dt          This procedure is used to get the Promise date         |
-- |                                                                                         |
-- | PROCEDURE   get_quot_dtls        This procedure is used to get the quotation details and|
-- |                                  also the unit price                                    |
-- |                                                                                         |
-- | PROCEDURE   val_ven_min          This procedure is used to validate the vendor minimum  |
-- |                                  of the PO record being processed                       |
-- |                                                                                         |
-- | PROCEDURE   populate_intf        This procedure is used to populate the interface tables|
-- |                                  with validated data.                                   |
-- |                                                                                         |
-- | PROCEDURE   Preproc_Main         This procedure will be called by the concurrent program|
-- |                                  "OD: PO ROQ Preprocessor Main Program"                 |
-- |                                                                                         |
-- | PROCEDURE   Validate_Main        This procedure will be called by the concurrent program|
-- |                                  "OD: PO ROQ Preprocessor Validate Program"             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |Draft 1a   28-MAY-2007       Remya Sasi       Initial draft version                      |
-- |Draft 1b   25-Jul-2007       Remya Sasi       Updated as per Review Comments             |
-- |1.0        25-Jul-2007       Remya Sasi       Baselined                                  |
-- |1.1        06-Aug-2007       Remya Sasi       Mapped PO_HEADERS_INTERFACE.attribute10 to |
-- |                                              nextval of sequence XX_PO_GSS_PO_NUMBER_S  |
-- |                                              Org_id added to get_buyer_potype procedure |
-- |1.2        21-Sep-2007       Remya Sasi       Added Timestamp to promise date.Modified   |
-- |                                              cursor lcu_buyer to use planner_id         | 
-- |1.3        03-Oct-2007       Remya Sasi       Modified for Promise Date API changes      |
-- |1.4        28-Nov-2007       Remya Sasi       Changes made as per latest MD.050 v6.0     |
-- |1.5        02-Jan-2008       Remya Sasi       Changes made as per onsite comments        |
-- |1.6        15-Jan-2008       Vikas Raina      Changes made to fix defects as reported by |
-- |                                              onsite after testing.                      |
-- |1.7        31-Jan-2008       Remya Sasi       Changes made as per onsite comments        |
-- +=========================================================================================+

AS
    -- ==============================
    -- Global datatype declaration --
    -- ==============================
    g_user_id         CONSTANT po_headers_interface.created_by%TYPE     := FND_GLOBAL.user_id;         -- User Id
    g_date            CONSTANT po_headers_interface.creation_date%TYPE  := SYSDATE;
    g_limit_size      CONSTANT PLS_INTEGER                              := 15000;

    gc_debug_flag     VARCHAR2(1);                               -- to hold the parameter p_debug
    gn_request_id     PLS_INTEGER := FND_GLOBAL.conc_request_id; -- Concurrent Program request id
    gn_appl_id        PLS_INTEGER := FND_GLOBAL.prog_appl_id;    -- Program Application Id
    gn_conc_prog_id   PLS_INTEGER := FND_GLOBAL.conc_program_id; -- Concurrent Porgram Id
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   : write_log                                                  |
  -- |                                                                         |
  -- |DESCRIPTION : This procedure is used to write the messages into the log  |
  -- |              file. If p_print is 1, it will print the message.          |
  -- |                                                                         |
  -- |                                                                         |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode   TYPE        DESCRIPTION                         |
  -- |---------------  ------ ---------- -------------------------             |
  -- |                                                                         |
  -- | p_message        IN    VARCHAR2    Carries message to be printed in log |
  -- | p_print          IN    PLS_INTEGER If 1 then the message is printed.    |
  -- +=========================================================================+
  
    PROCEDURE write_log( p_print     IN  PLS_INTEGER,
                         p_message   IN  VARCHAR2
                       )
    IS

    BEGIN
    
        IF p_print = 1 THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
        
        ELSIF gc_debug_flag = 'Y' THEN
        
            FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

        END IF;
    
    EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error "'||SQLERRM||'" while writing the message: "'||p_message||'" to the log file. ');
    END write_log;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :write_out                                                   |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to write the messages into the output|
  -- |              file.                                                      |
  -- |                                                                         |
  -- |                                                                         |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME     Mode  TYPE       DESCRIPTION                                |
  -- |-----------  ----  ---------- -------------------------                  |
  -- |                                                                         |
  -- | p_message   IN    VARCHAR2   Carries message to be printed in the output|
  -- +=========================================================================+
  
    PROCEDURE write_out( p_message   IN  VARCHAR2 )

    IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

    EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error "'||SQLERRM||'" encountered while writing the message "'||p_message||'" to the output file.');
    END write_out;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :assign_val_id                                               |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to assign validation thread ids to   |
  -- |             records which need to be processed by the Preprocessor.     |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode TYPE      DESCRIPTION                             |
  -- |----------------  ---- --------  -------------------------               |
  -- | p_status         IN   VARCHAR2  Status Code                             |
  -- | p_thread_size    IN   VARCHAR2  Thread Size                             |
  -- +=========================================================================+
  
    PROCEDURE assign_val_id(p_status      IN VARCHAR2
                           ,p_thread_size IN PLS_INTEGER)
    IS
    
    -- =============================================
    -- Cursor to pick header sequence id of records 
    -- to be processed
    -- =============================================
    CURSOR  lcu_header(p_status_cd    IN VARCHAR2)
    IS 
    SELECT  header_sequence_id
    FROM    xx_po_headers_stage
    WHERE   status_code = DECODE(p_status_cd,'ALL',status_code,p_status_cd)-- Changed by Remya, V1.7
    AND     status_code IN ('NEW','CORRECTED');
    
    -- ======================
    -- Variable Declarations
    -- ======================
    thread_size_ctr         PLS_INTEGER := 0;
    ln_validate_thread_id   PLS_INTEGER := NULL;
    ln_hdr_seq_id           PLS_INTEGER;
    ln_new_hdr_seq_id       PLS_INTEGER;
    

    BEGIN
        ----------------------------------
        -- Getting Validation thread id
        ----------------------------------
        SELECT  xx_po_preproc_vldt_s.NEXTVAL
        INTO    ln_validate_thread_id
        FROM    DUAL;

        FOR rec_hdr IN lcu_header(p_status)
        LOOP
            
            thread_size_ctr := thread_size_ctr + 1;
            ln_hdr_seq_id   := rec_hdr.header_sequence_id;
            
            ---------------------------------------
            -- Updating Staging table records with 
            -- validation thread id
            -- for V1.6
            ---------------------------------------
            
            UPDATE  xx_po_headers_stage 
            SET     validate_thread_id  = ln_validate_thread_id
                    ,request_id          = gn_request_id
                    ,last_update_date    = g_date
                    ,last_updated_by     = g_user_id
            WHERE   header_sequence_id  = rec_hdr.header_sequence_id;
            
            ---------------------------------
            -- Commented out by Remya, V1.7
            ---------------------------------
            /* 
            ---------------------------------------
            -- Updating Staging table records with 
            -- New hdr and line id to avoid unique
            -- constraint issue. V1.6
            ---------------------------------------
            
            UPDATE xx_po_headers_stage 
            SET    header_sequence_id  = po_headers_interface_s.NEXTVAL 
            WHERE  header_sequence_id  = (SELECT interface_header_id FROM po_headers_interface
                              WHERE interface_header_id =  rec_hdr.header_sequence_id
                             )
            RETURNING header_sequence_id INTO ln_new_hdr_seq_id ; -- V1.6   
            
            --************************************************************************************************
            -- This is to update all the lines id which  have same LINE_SEQUENCE_ID as  
            -- interface_line_id FROM po_lines_interface so as to avoid  'Error "ORA-00001: unique constraint 
            -- (PO.PO_LINES_INTERFACE_U1) violated error. -- V1.6
            -- ************************************************************************************************
            
              UPDATE  xx_po_lines_stage 
                SET     header_sequence_id  =   NVL(ln_new_hdr_seq_id,header_sequence_id)
                 ,line_sequence_id    =   po_lines_interface_s.NEXTVAL
              WHERE  ( header_sequence_id  =   ln_hdr_seq_id  )
                     OR (line_sequence_id IN ( SELECT interface_line_id FROM po_lines_interface)
             ) ;
             
             */
             -------------------------------
             -- End of comments, Remya, V1.7
             -------------------------------

            IF thread_size_ctr  = p_thread_size THEN 
                -------------------------------------
                -- Getting Next Validation thread id
                -- once thread size has been met.
                -------------------------------------
                
                thread_size_ctr := 0;
                
                SELECT  xx_po_preproc_vldt_s.NEXTVAL
                INTO    ln_validate_thread_id
                FROM    DUAL;

            END IF;

        END LOOP;
       
       COMMIT;
    
    END assign_val_id;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :call_val_cp                                                 |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to Invoke the Validation Concurrent  |
  -- |             Programs for the Preprocessor.                              |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode TYPE      DESCRIPTION                             |
  -- |----------------  ---- --------  -------------------------               |
  -- | p_debug_flag     IN   VARCHAR2  Debug Flag to display log messages      |
  -- +=========================================================================+
  
    PROCEDURE call_val_cp(p_debug_flag    IN    VARCHAR2)
    IS

    -- ======================
    -- Variable Declarations
    -- ======================
    TYPE cp_rec_type IS RECORD(
                                batch_id              PLS_INTEGER
                               ,request_id            PLS_INTEGER);

    TYPE cp_tbl_type IS TABLE of cp_rec_type
    INDEX BY BINARY_INTEGER;
    lt_validate_cp_tbl      cp_tbl_type;
    
    lb_req_wait             BOOLEAN;
    ln_val_cp_count         PLS_INTEGER := 0;
    lt_vldt_conc_req_id     PLS_INTEGER := NULL;
    lc_dev_phase            VARCHAR2(50);
    lc_dev_status           VARCHAR2(50);
    lc_mesg                 VARCHAR2(200);
    lc_phase                VARCHAR2(50);
    lc_status               VARCHAR2(50);
    lc_req_status           VARCHAR2(20);
    lc_message              VARCHAR2(2000);
    

    BEGIN
    
    ----------------------------------------------
    -- For records corresponding to validation
    -- thread ids assigned by the preprocessor
    ----------------------------------------------
    FOR rec_val IN (SELECT  DISTINCT validate_thread_id
                    FROM    xx_po_headers_stage
                    WHERE   request_id = gn_request_id
                    ORDER BY validate_thread_id ASC)
    LOOP
        ------------------------------------------------------
        -- Launching  OD: PO ROQ Preprocessor Validate Program 
        ------------------------------------------------------
        write_log(0,' .. Launch  OD: PO ROQ Preprocessor Validate Program for thread id '||rec_val.validate_thread_id);
        ln_val_cp_count := ln_val_cp_count + 1;
        lt_vldt_conc_req_id := FND_REQUEST.submit_request
                                        (application => 'PO'
                                        ,program     => 'XX_PO_ROQ_PREPROC_V_MAIN'
                                        ,description => 'OD: PO ROQ Preprocessor Validate Program'
                                        ,sub_request => FALSE
                                        ,argument1   => rec_val.validate_thread_id 
                                        ,argument2   => p_debug_flag);
        IF lt_vldt_conc_req_id>0 THEN
            COMMIT;
            write_log(0,' .. Submitted Validation Program for thread id = '||rec_val.validate_thread_id);
        ELSE
            write_log(0,' .. Failed to submit Validation Program for thread id = '||rec_val.validate_thread_id);
        END IF;

        lt_validate_cp_tbl(ln_val_cp_count).batch_id        := rec_val.validate_thread_id;
        lt_validate_cp_tbl(ln_val_cp_count).request_id      := lt_vldt_conc_req_id;

    END LOOP;
    
    ----------------------------------------------------
    -- Verifying all the launched requests are Completed
    ----------------------------------------------------
    IF ln_val_cp_count > 0 THEN
        write_log(0,' -- Waiting till all the processes are complete --');

        FOR i IN lt_validate_cp_tbl.FIRST..lt_validate_cp_tbl.LAST
        LOOP

            lb_req_wait := FND_CONCURRENT.wait_for_request
                                                      (  request_id => lt_validate_cp_tbl(i).request_id 
                                                        ,interval   => 10
                                                        ,max_wait   => NULL
                                                        ,phase      => lc_phase
                                                        ,status     => lc_status
                                                        ,dev_phase  => lc_dev_phase
                                                        ,dev_status => lc_dev_status
                                                        ,message    => lc_mesg
                                                      );

            IF lc_dev_phase = 'COMPLETE' AND lc_dev_status = 'NORMAL' THEN
                write_log(0,' .. Validation Program completed normally, request_id = '|| TO_CHAR (lt_validate_cp_tbl(i).request_id));
            ELSIF lc_dev_phase  = 'COMPLETE' AND lc_dev_status ='WARNING' THEN
                lc_message := ' .. Validation Program Ended in Warning, request_id = '|| TO_CHAR (lt_validate_cp_tbl(i).request_id);
                write_log(0,lc_message);
                lc_req_status := 'WARNING';
            ELSIF lc_dev_phase  = 'COMPLETE' AND lc_dev_status = 'ERROR' THEN --in ('ERROR','WARNING') THEN
                lc_message := ' .. Validation Program Ended in error, request_id = '|| TO_CHAR (lt_validate_cp_tbl(i).request_id);
                write_log(0,lc_message);
                lc_req_status := 'ERROR';
            END IF;

            write_log(0,' .. Request Id '||lt_validate_cp_tbl(i).request_id||'; Phase = '||lc_dev_phase||'; Status = '||lc_dev_status);

        END LOOP;
        
    ELSE --(corresponds to "IF ln_val_cp_count > 0 THEN")

      write_log(0,'  .. No Validation Processes were launched.');

    END IF; --(corresponds to "IF ln_val_cp_count > 0 THEN")

    write_out(' ');
    write_out('Number of Pre-Processor Validation Programs launched:    '||ln_val_cp_count);
    write_out('Request Ids of all the Validation Programs launched:');

    IF ln_val_cp_count <> 0 AND ln_val_cp_count IS NOT NULL THEN
    
        FOR i IN lt_validate_cp_tbl.FIRST..lt_validate_cp_tbl.LAST
        LOOP
            write_out('                                                       '||lt_validate_cp_tbl(i).request_id);
        END LOOP;
        
    END IF;
    
    END call_val_cp;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :assign_batch_id                                             |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to Assign batch ids to all the valid |
  -- |             records in the interface table.                             |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode TYPE      DESCRIPTION                             |
  -- |----------------  ---- --------  -------------------------               |
  -- | p_batch_sz       IN   VARCHAR2  Parameter carrying permissible batch    |
  -- |                                 size.                                   |
  -- +=========================================================================+
  
    PROCEDURE assign_batch_id(p_batch_sz    IN PLS_INTEGER)
    IS
    
    -- ==================================================
    -- Cursor to pick records from interface table to be
    --  assigned batch ids depending on approval status
    -- ==================================================
    CURSOR     lcu_batch(p_approval_status  IN  VARCHAR2)
    IS
    SELECT     PHI.interface_header_id
    FROM       po_headers_interface     PHI
              ,xx_po_headers_stage      XPHS
    WHERE      PHI.process_code        = 'PENDING'
    AND        PHI.interface_header_id = XPHS.header_sequence_id
    AND        PHI.approval_status     = p_approval_status
    AND        PHI.request_id IN (SELECT request_id
                                  FROM   fnd_concurrent_requests
                                  WHERE  parent_request_id = gn_request_id);

    -- ======================
    -- Variable Declarations
    -- ======================

    batch_size_ctr          PLS_INTEGER;
    ln_batch_id             PLS_INTEGER;

    BEGIN
            
        batch_size_ctr := 0;
        ---------------------------------
        -- Getting new value of batch id
        ---------------------------------
        SELECT xx_po_preproc_batch_s.NEXTVAL
        INTO   ln_batch_id
        FROM   DUAL;
        
        ------------------------------------
        -- For 'APPROVED' interface records
        ------------------------------------
        write_log(0,' .. For records with APPROVED status');
        FOR rec_appr IN lcu_batch('APPROVED')
        LOOP
            
            batch_size_ctr := batch_size_ctr +1;
            -----------------------------------------
            -- Updating interface table with batch id
            -----------------------------------------
            UPDATE  po_headers_interface 
            SET     batch_id                = ln_batch_id
                   ,request_id              = gn_request_id
                   ,last_update_date        = g_date
                   ,last_updated_by         = g_user_id
            WHERE   interface_header_id     = rec_appr.interface_header_id;

            IF batch_size_ctr   = p_batch_sz THEN 
                ---------------------------------
                -- Getting next value of batch id
                -- once batch size has been met
                ---------------------------------
                
                SELECT xx_po_preproc_batch_s.NEXTVAL
                INTO   ln_batch_id
                FROM   DUAL;

                batch_size_ctr      := 0;
            END IF;
            
        END LOOP;
        
        COMMIT;

        ---------------------------------
        -- Getting new value of batch id
        ---------------------------------
        batch_size_ctr := 0;
        SELECT xx_po_preproc_batch_s.NEXTVAL
        INTO   ln_batch_id
        FROM   DUAL;
        
        ------------------------------------
        -- For 'INCOMPLETE' interface records
        ------------------------------------
        write_log(0,' .. For records with INCOMPLETE status');
        FOR rec_inc IN lcu_batch('INCOMPLETE')
        LOOP
        
            batch_size_ctr := batch_size_ctr + 1;
            -----------------------------------------
            -- Updating interface table with batch id
            -----------------------------------------
            UPDATE  po_headers_interface 
            SET     batch_id = ln_batch_id
                   ,request_id              = gn_request_id
                   ,last_update_date        = g_date
                   ,last_updated_by         = g_user_id
            WHERE   interface_header_id     = rec_inc.interface_header_id;

            IF  batch_size_ctr  = p_batch_sz THEN
                
                ---------------------------------
                -- Getting next value of batch id
                -- once batch size has been met
                ---------------------------------               
                SELECT xx_po_preproc_batch_s.NEXTVAL
                INTO   ln_batch_id
                FROM   DUAL;

                batch_size_ctr := 0;
            END IF;
            
        END LOOP;
        
        COMMIT;
        
    END assign_batch_id;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   : call_std_import                                            |
  -- |                                                                         |
  -- |DESCRIPTION : This procedure is used to call the Standard Import Purchase|
  -- |              Order Concurrent Program from the Preprocessor.            |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode TYPE          DESCRIPTION                         |
  -- |----------------  ---- --------      -------------------------           |
  -- |                                                                         |
  -- +=========================================================================+
  
    PROCEDURE call_std_import -- Commented out '(p_batch_id  IN PLS_INTEGER)', Remya, V1.4
    IS
    

    -- ==================================================
    -- Cursor to pick batch Id and approval status
    -- of records to be imported from interface table  
    -- ==================================================
    -- Modified by Remya , V1.4 
    CURSOR  lcu_import
    IS
    SELECT  DISTINCT PHI.batch_id
           ,DECODE(PHI.approval_status,'APPROVED','INITIATE APPROVAL','INCOMPLETE') approval_status
           ,PHI.org_id
           ,FRT.responsibility_id 
           ,FRT.application_id
           ,FRT.responsibility_name
    FROM    po_headers_interface    PHI
           ,xx_po_headers_stage     XPHS
           ,hr_operating_units      HOU
           ,fnd_responsibility_tl   FRT
    WHERE   PHI.process_code         = 'PENDING'
    AND     PHI.document_type_code   = 'STANDARD'
    AND     PHI.interface_header_id  = XPHS.header_sequence_id
    AND     FRT.responsibility_name  = 'OD ('||SUBSTR(HOU.name,4,2)||') PO Superuser'
    AND     HOU.organization_id      = PHI.org_id
    AND     PHI.request_id           = gn_request_id;
    
    -- End of modifications by Remya, V1.4
    
    
    -- ======================
    -- Variable Declarations
    -- ======================
    TYPE cp_rec_type IS RECORD(
                                batch_id              PLS_INTEGER
                               ,request_id            PLS_INTEGER
                                );
                                
    TYPE cp_tbl_type IS TABLE of cp_rec_type
    INDEX BY BINARY_INTEGER;
    lt_std_import_cp_tbl    cp_tbl_type;

    ln_cp_count             PLS_INTEGER := 0;
    lt_import_conc_req_id   PLS_INTEGER;
    lb_req_wait             BOOLEAN;
    lc_dev_phase            VARCHAR2(50);
    lc_dev_status           VARCHAR2(50);
    lc_mesg                 VARCHAR2(200);
    lc_phase                VARCHAR2(50);
    lc_status               VARCHAR2(50);
    lc_req_status           VARCHAR2(20);
    lc_approval_status      VARCHAR2(50);
    lc_message              VARCHAR2(2000);
    ln_responsibility_id    PLS_INTEGER; -- Added by Remya, V1.4
    ln_application_id       PLS_INTEGER; -- Added by Remya, V1.4
    
    BEGIN

        ----------------------------------------
        -- For records in interface table ready
        -- to be imported
        ----------------------------------------
        FOR rec_import IN lcu_import
        LOOP
            -- Added By Remya, V1.4
            -- Apps Initialization to overcome the problem of passing charge account
            -- When creating Purchase order in a OU different from current responsibility.
            FND_GLOBAL.APPS_INITIALIZE(user_id      => g_user_id
                                      ,resp_id      => rec_import.responsibility_id
                                      ,resp_appl_id => rec_import.application_id
                                       );
            -- End of additions By Remya, V1.4
            ln_cp_count := ln_cp_count + 1;
            write_log(0,' .. Launching Std Import Program #'||ln_cp_count);
            write_log(0,' .. with batch id: '||rec_import.batch_id||' and status :'||rec_import.approval_status);

            ------------------------------------------------------------
            -- Launch Import Standard Purchase Orders Concurrent Program
            ------------------------------------------------------------
            lt_import_conc_req_id := FND_REQUEST.submit_request
                                            (application => 'PO'
                                            ,program     => 'POXPOPDOI'
                                            ,description => 'Import Standard Purchase Orders'
                                            ,sub_request => FALSE
                                            ,argument1   => NULL -- Default Buyer 
                                            ,argument2   => 'STANDARD' -- Document Type
                                            ,argument3   => NULL -- Document SubType
                                            ,argument4   => 'N' -- Create or Update Items
                                            ,argument5   => NULL -- Create Sourcing Rules
                                            ,argument6   => rec_import.approval_status -- Approval Status
                                            ,argument7   => NULL -- Release Generation Method
                                            ,argument8   => rec_import.batch_id -- Batch_Id
                                            ,argument9   => rec_import.org_id -- Operating Unit
                                            ,argument10  => NULL -- Global Agreement
                                             );
            IF lt_import_conc_req_id>0 THEN
                COMMIT;
                write_log(0,' .. Submitted Std Import Program for batch id = '||rec_import.batch_id);
            ELSE
                write_log(0,' .. Failed to submit Std Import Program for batch id = '||rec_import.batch_id);
            END IF;

        lt_std_import_cp_tbl(ln_cp_count).batch_id        := rec_import.batch_id;
        lt_std_import_cp_tbl(ln_cp_count).request_id      := lt_import_conc_req_id;

        END LOOP;

        ------------------------------------------------------
        -- Verifying all the launched processes are completed
        ------------------------------------------------------
        IF ln_cp_count > 0 THEN
            write_log(0,' -- Waiting till all the processes are complete --');

            FOR i IN lt_std_import_cp_tbl.FIRST..lt_std_import_cp_tbl.LAST
            LOOP

                lb_req_wait := FND_CONCURRENT.wait_for_request
                                                          (  request_id => lt_std_import_cp_tbl(i).request_id 
                                                            ,interval   => 10
                                                            ,max_wait   => NULL
                                                            ,phase      => lc_phase
                                                            ,status     => lc_status
                                                            ,dev_phase  => lc_dev_phase
                                                            ,dev_status => lc_dev_status
                                                            ,message    => lc_mesg
                                                            );
                IF lc_dev_phase = 'COMPLETE' AND lc_dev_status = 'NORMAL' THEN
                    write_log(0,' .. Std Import Program completed normally, request_id = '|| TO_CHAR (lt_std_import_cp_tbl(i).request_id));
                ELSIF lc_dev_phase  = 'COMPLETE' AND lc_dev_status IN ('WARNING') THEN
                    lc_message := ' .. Std Import Program Ended in Warning, request_id = '|| TO_CHAR (lt_std_import_cp_tbl(i).request_id);
                    write_log(0,lc_message);
                ELSIF lc_dev_phase  = 'COMPLETE' AND lc_dev_status = 'ERROR' THEN --in ('ERROR','WARNING') THEN
                    lc_message := ' .. Std Import Program Ended in error, request_id = '|| TO_CHAR (lt_std_import_cp_tbl(i).request_id);
                    write_log(0,lc_message);
                END IF;

            END LOOP;

        ELSE    -- (corresponds to "IF ln_cp_count > 0 THEN" statement)

            write_log(0,' .. No Standard Import Processes were launched.');

        END IF;  -- (corresponds to "IF ln_cp_count > 0 THEN" statement)

        write_log(0,'--------------------------------------');
            
    END call_std_import;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :update_po_quot                                              |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to Update the successfully created   |
  -- |             PO lines with the quotation details.                        |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode TYPE      DESCRIPTION                             |
  -- |----------------  ---- --------  -------------------------               |
  -- |  x_err           OUT VARCHAR2     Returns error code in case of error   |
  -- +=========================================================================+
  
    PROCEDURE update_po_quot(x_err OUT VARCHAR2) -- Modified by Remya, V1.4
    IS
    
    -- ==================================================
    -- Cursor to pick quotation details for successfully
    -- created POs in EBS
    -- ==================================================
    CURSOR  lcu_quot_dtl 
    IS
    SELECT  PHA.po_header_id
           ,PLA.po_line_id
           ,XPLS.from_header_id
           ,XPLS.from_line_id
           ,XPLS.from_line_location_id
    FROM    po_headers_all          PHA
           ,po_lines_all            PLA
           ,xx_po_lines_stage       XPLS
           ,xx_po_headers_stage     XPHS
    WHERE   PHA.vendor_order_num    = ('POROQ-'||XPHS.header_sequence_id) 
    AND     XPHS.header_sequence_id = XPLS.header_sequence_id
    AND     XPHS.status_code        = 'PASSED PDOI' -- Added by Remya, V1.4
    AND     PLA.item_id             = XPLS.item_id  -- Added by Remya, V1.4   
    AND     PHA.po_header_id        = PLA.po_header_id
    AND     XPLS.from_header_id IS NOT NULL -- Added by Remya, V1.4
    AND     XPLS.from_line_id IS NOT NULL -- Added by Remya, V1.4
    AND     XPLS.from_line_location_id IS NOT NULL; -- Added by Remya, V1.4
    
    -- ======================
    -- Variable Declarations
    -- ======================
    TYPE quot_tbl_type IS TABLE OF PLS_INTEGER
    INDEX BY BINARY_INTEGER;
    lt_rec_po_hdr_id      quot_tbl_type;
    
    TYPE po_line_tbl_type IS TABLE OF PLS_INTEGER;
    lt_rec_po_line_id   po_line_tbl_type;

    TYPE quot_hdr_tbl_type IS TABLE OF PLS_INTEGER;
    lt_rec_quot_hdr_id  quot_hdr_tbl_type;

    TYPE quot_line_tbl_type IS TABLE OF PLS_INTEGER;
    lt_rec_quot_line_id  quot_line_tbl_type;

    TYPE quot_line_loc_tbl_type IS TABLE OF PLS_INTEGER;
    lt_rec_quot_line_loc_id  quot_line_loc_tbl_type;
    
    BEGIN
        
        x_err := NULL; -- Added by Remya, V1.4
        
        OPEN    lcu_quot_dtl;
        LOOP
            ----------------------------------------------
            -- Fetchin quotation details corresponding to
            -- all the POs created by the Preprocessor
            ----------------------------------------------
            FETCH   lcu_quot_dtl BULK COLLECT INTO lt_rec_po_hdr_id
                                                  ,lt_rec_po_line_id
                                                  ,lt_rec_quot_hdr_id
                                                  ,lt_rec_quot_line_id
                                                  ,lt_rec_quot_line_loc_id LIMIT G_LIMIT_SIZE;
            IF lt_rec_po_hdr_id.COUNT > 0 THEN
                ------------------------------------
                -- Updating PO lines with quotations
                ------------------------------------
                FORALL i IN lt_rec_po_hdr_id.FIRST..lt_rec_po_hdr_id.LAST
                    UPDATE  po_lines_all
                    SET     from_header_id          = lt_rec_quot_hdr_id(i)
                           ,from_line_id            = lt_rec_quot_line_id(i)
                           ,last_update_date        = g_date
                           ,last_updated_by         = g_user_id
                    WHERE   po_line_id              = lt_rec_po_line_id(i)
                    AND     po_header_id            = lt_rec_po_hdr_id(i);

                ----------------------------------------------
                -- Updating PO line Locations with quotations
                -----------------------------------------------
                FORALL i IN lt_rec_po_hdr_id.FIRST..lt_rec_po_hdr_id.LAST
                    UPDATE  po_line_locations_all
                    SET     from_header_id          = lt_rec_quot_hdr_id(i)
                           ,from_line_id            = lt_rec_quot_line_id(i)
                           ,from_line_location_id   = lt_rec_quot_line_loc_id(i)
                           ,last_update_date        = g_date
                           ,last_updated_by         = g_user_id
                    WHERE   po_line_id              = lt_rec_po_line_id(i)
                    AND     po_header_id            = lt_rec_po_hdr_id(i);
                    
            END IF;
            
            EXIT WHEN lcu_quot_dtl%NOTFOUND;
            
        END LOOP;
        
        CLOSE   lcu_quot_dtl;
             
                 
        COMMIT;
        
        lt_rec_po_hdr_id.DELETE;
        lt_rec_po_line_id.DELETE;
        lt_rec_quot_hdr_id.DELETE;
        lt_rec_quot_line_id.DELETE;
        lt_rec_quot_line_loc_id.DELETE;
        
    EXCEPTION   -- Added by Remya, V1.4
    WHEN OTHERS THEN
        write_log(1,' .. Post Process Error "'||SQLERRM||'" while updating POs with quotation details ');
        x_err := 'E'; 
    END update_po_quot;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :create_alloc                                                |
  -- |                                                                         |
  -- |DESCRIPTION : This procedure is used to create allocations for POs       |
  -- |              which were successfully created by the preprocessor.       |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME         Mode TYPE          DESCRIPTION                          |
  -- |---------------  ---- --------     -------------------------             |
  -- |  x_count         OUT PLS_INTEGER  Returns the number of headers inserted|
  -- |  x_err           OUT VARCHAR2     Returns error code in case of error   |
  -- +=========================================================================+
  
    PROCEDURE create_alloc(x_count OUT PLS_INTEGER
                          ,x_err   OUT VARCHAR2)  -- Added by Remya, V1.4

    IS
    -- ==============================================
    -- Cursor to pick item and batch combination for
    -- allocation header records
    -- ==============================================
    CURSOR  lcu_alloc_rec
    IS
    SELECT  DISTINCT PLA.item_id
           ,XPAS.batch_no
           ,XPAS.batch_description
           ,PHA.org_id
           ,PHA.vendor_id
           ,PHA.vendor_site_id
           ,PHA.agent_id
    FROM    po_lines_all            PLA
           ,po_headers_all          PHA
           ,xx_po_allocations_stage XPAS
           ,xx_po_headers_stage     XPHS -- Added by Remya, V1.4
    WHERE   PLA.po_header_id        = PHA.po_header_id
    AND     PHA.vendor_order_num    ='POROQ-'||XPAS.header_sequence_id
    AND     XPHS.header_sequence_id = XPAS.header_sequence_id -- Added by Remya, V1.4
    AND     XPHS.status_code        = 'PASSED PDOI'; -- Changed from 'QUOTATION-LINKED' by Remya, V1.5  

    -- ==================================================
    -- Cursor to pick data for creating allocation lines
    -- ==================================================
    CURSOR  lcu_alloc_line_rec (p_item_id   IN  PLS_INTEGER
                               ,p_batch_no  IN  PLS_INTEGER)
    IS
    SELECT  PLA.po_line_id
           ,PLA.po_header_id
           ,XPAS.alloc_organization_id
           ,XPAS.alloc_qty
           ,XPAS.ship_to_org_id
           ,PHA.segment1
           ,PLA.line_num
           ,PLL.line_location_id    -- V1.6
           ,PLL.shipment_num        -- V1.6
    FROM    po_lines_all            PLA
           ,po_headers_all          PHA
           ,xx_po_allocations_stage XPAS
           ,po_line_locations_all   PLL   -- V1.6
    WHERE   PLA.po_header_id = PHA.po_header_id
    AND     PLA.item_id      = p_item_id
    AND     XPAS.batch_no    = p_batch_no
    AND     PHA.vendor_order_num = 'POROQ-'||XPAS.header_sequence_id
    AND     XPAS.line_num        = PLA.line_num
    AND     PLL.po_line_id       = PLA.po_line_id;

    -- ======================
    -- Variable Declarations
    -- ======================
    ln_alloc_hdr_id         PLS_INTEGER;
    ln_alloc_line_id        PLS_INTEGER;
    ln_alloc_hdr_count      PLS_INTEGER := 0;
    ln_line_location_id     PLS_INTEGER;
    lc_shipment_num         po_line_locations_all.shipment_num%TYPE;


    BEGIN
        x_err := NULL; -- Added by Remya, V1.4
        
        FOR lcr_alloc_rec IN lcu_alloc_rec
        LOOP
            write_log(0,' .. For item id '||lcr_alloc_rec.item_id);
            -- ---------------------------------------
            --  Getting new Allocation Header Id value
            -- ---------------------------------------
            SELECT  xx_po_alloc_hdr_id_s.NEXTVAL
            INTO    ln_alloc_hdr_id
            FROM    DUAL;
            -------------------------------------
            -- Populating Allocation Header Table 
            --------------------------------------
            write_log(0,' .. Inserting values into xx_po_allocation_header table');
            write_log(0,' .. with allocation header id :'||ln_alloc_hdr_id);
            INSERT INTO xx_po_allocation_header
                                (allocation_header_id
                                ,org_id
                                ,batch_no
                                ,batch_desc
                                ,item_id
                                ,vendor_id
                                ,vendor_site_id
                                ,agent_id
                                ,creation_date
                                ,created_by
                                ,last_update_date
                                ,last_updated_by
                                )
                          VALUES(ln_alloc_hdr_id
                                ,lcr_alloc_rec.org_id
                                ,lcr_alloc_rec.batch_no
                                ,lcr_alloc_rec.batch_description 
                                ,lcr_alloc_rec.item_id 
                                ,lcr_alloc_rec.vendor_id
                                ,lcr_alloc_rec.vendor_site_id
                                ,lcr_alloc_rec.agent_id
                                ,g_date
                                ,g_user_id
                                ,g_date
                                ,g_user_id
                               );
            ln_alloc_hdr_count := ln_alloc_hdr_count + 1;

            FOR lcr_alloc_line_rec IN lcu_alloc_line_rec(lcr_alloc_rec.item_id, lcr_alloc_rec.batch_no)
            LOOP
                write_log(0,' .. ');
                write_log(0,' ... For po_header_id '||lcr_alloc_line_rec.po_header_id||' and po_line_id '||lcr_alloc_line_rec.po_line_id);
                -- ---------------------------------------
                --  Getting new Allocation Line Id value
                -- ---------------------------------------
                SELECT  xx_po_alloc_line_id_s.NEXTVAL
                INTO    ln_alloc_line_id
                FROM    DUAL;

              /** Commented V1.6 and added with cursor lcu_alloc_line_rec
                -- ---------------------------------------------
                --  Getting Line Location Id and Shipment number
                -- ---------------------------------------------
                SELECT  line_location_id
                       ,shipment_num
                INTO    ln_line_location_id
                       ,lc_shipment_num
                FROM    po_line_locations_all
                WHERE   po_header_id = lcr_alloc_line_rec.po_header_id
                AND     po_line_id   = lcr_alloc_line_rec.po_line_id;
                *****/
                -------------------------------------
                -- Populating Allocation Lines Table 
                --------------------------------------
                write_log(0,' ... Inserting values into xx_po_allocation_lines table');
                write_log(0,' ... with allocation line id :'||ln_alloc_line_id);
                INSERT INTO xx_po_allocation_lines
                                        (allocation_header_id
                                        ,allocation_line_id
                                        ,po_header_id
                                        ,po_line_id
                                        ,line_location_id
                                        ,locked_in
                                        ,alloc_organization_id
                                        ,ship_to_organization_id
                                        ,allocation_qty
                                        ,po_line_shipment
                                        ,creation_date
                                        ,created_by
                                        ,last_update_date
                                        ,last_updated_by
                                        )
                                  VALUES(ln_alloc_hdr_id
                                        ,ln_alloc_line_id
                                        ,lcr_alloc_line_rec.po_header_id
                                        ,lcr_alloc_line_rec.po_line_id
                                        ,lcr_alloc_line_rec.line_location_id 
                                        ,'Y'
                                        ,lcr_alloc_line_rec.alloc_organization_id
                                        ,lcr_alloc_line_rec.ship_to_org_id
                                        ,lcr_alloc_line_rec.alloc_qty
                                        ,lcr_alloc_line_rec.segment1||lcr_alloc_line_rec.line_num||lcr_alloc_line_rec.shipment_num
                                        ,g_date
                                        ,g_user_id
                                        ,g_date
                                        ,g_user_id
                                        );
            END LOOP;
        
        END LOOP;
        
        x_count :=     ln_alloc_hdr_count ;
        
        -- =================================================
    -- Deleting data from staging table
    -- once allocations have been created
    -- The allocation data should be deleted
    -- only when allocation has been made successfully
        -- V1.6
    -- =================================================
        
         write_log(0,' .. Deleting successful records from staging tables which have exceeded allowed number of days');
     ----------------------------------------------------------------------
     -- Deleting Allocation staging table records which have been successfully
     -- processed and exceed number of days specified by profile
     ----------------------------------------------------------------------
            DELETE
            FROM  xx_po_allocations_stage  
            WHERE header_sequence_id IN 
                    (SELECT XPHS.header_sequence_id
                     FROM   xx_po_headers_stage XPHS
                     WHERE (TRUNC(SYSDATE)-XPHS.creation_date) > fnd_profile.VALUE_SPECIFIC('XX_PO_ROQ_NUM_DAYS'
                                                                                            ,FND_PROFILE.VALUE('RESP_ID')
                                                                                            ,FND_PROFILE.VALUE('RESP_APPL_ID')
                                                                                            ,XPHS.org_id)
                  AND XPHS.status_code = 'POST PROCESS DONE');
        
        write_log(0,' .. Number of records deleted from xx_po_allocations_stage : '||SQL%ROWCOUNT);
        -- ======================================
        -- Updating status code in staging table
        -- once allocations have been created
        -- ======================================
        -- Added by Remya, V1.4
        UPDATE xx_po_headers_stage XPHS
        SET    XPHS.status_code = 'POST PROCESS DONE'
        WHERE  XPHS.header_sequence_id IN 
                             (SELECT  XPAS.header_sequence_id
                              FROM    po_headers_all          PHA
                                     ,xx_po_allocations_stage XPAS
                              WHERE   PHA.vendor_order_num    ='POROQ-'||XPAS.header_sequence_id
                              AND     XPHS.header_sequence_id = XPAS.header_sequence_id) 
        AND     XPHS.status_code        = 'PASSED PDOI'; -- Changed from 'QUOTATION-LINKED' by Remya, V1.5  
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
        write_log(1,' .. Post Process Error "'||SQLERRM||'" encountered while creating allocations');
        x_count := 0;
        x_err := 'E'; -- Added by Remya, V1.4

    END create_alloc;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :update_stg                                                  |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to update the staging tables with    |
  -- |             apt status messages                                         |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode TYPE        DESCRIPTION                           |
  -- |----------------  ---- --------   -------------------------              |
  -- | p_status         IN   VARCHAR2    Status                                | 
  -- | p_msg            IN   VARCHAR2    Error Message                         |
  -- | p_hdr_seq_id     IN   PLS_INTEGER Header Sequence Id                    |
  -- | p_line_seq_id    IN   PLS_INTEGER Line Sequence Id                      |
  -- +=========================================================================+
  
    PROCEDURE update_stg(p_status       IN VARCHAR2 -- Added by Remya, V1.4
                        ,p_msg          IN VARCHAR2
                        ,p_hdr_seq_id   IN PLS_INTEGER
                        ,p_line_seq_id  IN PLS_INTEGER DEFAULT NULL)
    IS

    BEGIN
        
        IF p_line_seq_id IS NULL THEN
            ---------------------------------
            -- For a header level error
            ---------------------------------
            -----------------------------------------------------
            -- Updating header record with error code and message
            -----------------------------------------------------
            UPDATE  xx_po_headers_stage
            SET     status_code         = p_status -- Changed from 'ERROR' by Remya, V1.4
                   ,last_update_date    = g_date
                   ,last_updated_by     = g_user_id
                   ,request_id          = gn_request_id
                   ,error_message       = p_msg
            WHERE   header_sequence_id  = p_hdr_seq_id;
            
        ELSE
            ---------------------------------
            -- For a line level error
            ---------------------------------
            -----------------------------------------
            -- Updating header record with error code
            -----------------------------------------
            UPDATE  xx_po_headers_stage
            SET     status_code         = p_status -- Changed from 'ERROR' by Remya, V1.4
                   ,last_update_date    = g_date
                   ,last_updated_by     = g_user_id
                   ,request_id          = gn_request_id
            WHERE   header_sequence_id  = p_hdr_seq_id;

            ------------------------------------------
            -- Updating line record with error message
            ------------------------------------------
            UPDATE  xx_po_lines_stage  
            SET     error_message       = p_msg
                   ,last_update_date    = g_date
                   ,last_updated_by     = g_user_id
            WHERE   header_sequence_id  = p_hdr_seq_id
            AND     line_sequence_id    = p_line_seq_id;
            
        END IF;
        
    EXCEPTION
    
    WHEN OTHERS THEN
    
        write_log(1,'Unable to update error message for record: '||p_hdr_seq_id);
    
    END update_stg;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   : delete_data                                                |
  -- |                                                                         |
  -- |DESCRIPTION : This procedure is used to delete processed data from       |
  -- |              staging tables after profile specified amount of time      |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode TYPE      DESCRIPTION                             |
  -- |----------------  ---- --------  -------------------------               |
  -- |                                                                         |
  -- +=========================================================================+
  
    PROCEDURE delete_data
    IS
    
    BEGIN
        ---------------------------
        -- Modified by Remya, V1.4
        ---------------------------
       
       /**************V1.6
        write_log(0,' .. Deleting successful records from staging tables which have exceeded allowed number of days');
        ----------------------------------------------------------------------
        -- Deleting Allocation staging table records which have been successfully
        -- processed and exceed number of days specified by profile
        ----------------------------------------------------------------------
        DELETE
        FROM  xx_po_allocations_stage  
        WHERE header_sequence_id IN 
                (SELECT XPHS.header_sequence_id
                 FROM   xx_po_headers_stage XPHS
                 WHERE (TRUNC(SYSDATE)-XPHS.creation_date) > fnd_profile.VALUE_SPECIFIC('XX_PO_ROQ_NUM_DAYS'
                                                                                        ,FND_PROFILE.VALUE('RESP_ID')
                                                                                        ,FND_PROFILE.VALUE('RESP_APPL_ID')
                                                                                        ,XPHS.org_id)
                  AND XPHS.status_code = 'POST PROCESS DONE');
       ****************/
       
        ----------------------------------------------------------------------
        -- Deleting PO lines staging table records which have been successfully
        -- processed and exceed number of days specified by profile
        ----------------------------------------------------------------------
        DELETE
        FROM  xx_po_lines_stage  
        WHERE header_sequence_id IN 
                (SELECT XPHS.header_sequence_id
                 FROM   xx_po_headers_stage XPHS
                 WHERE (TRUNC(SYSDATE)-XPHS.creation_date) > fnd_profile.VALUE_SPECIFIC('XX_PO_ROQ_NUM_DAYS'
                                                                                  ,FND_PROFILE.VALUE('RESP_ID')
                                                                                  ,FND_PROFILE.VALUE('RESP_APPL_ID')
                                                                                  ,XPHS.org_id)
                  AND XPHS.status_code = 'POST PROCESS DONE');
                  
        write_log(1,' .. Number of records deleted from xx_po_lines_stage: '||SQL%ROWCOUNT);                  
        ----------------------------------------------------------------------
        -- Deleting PO headers staging table records which have been successfully
        -- processed and exceed number of days specified by profile
        ----------------------------------------------------------------------
        
        DELETE
        FROM xx_po_headers_stage XPHS
        WHERE (TRUNC(SYSDATE)-XPHS.creation_date) > fnd_profile.VALUE_SPECIFIC('XX_PO_ROQ_NUM_DAYS'
                                                                       ,FND_PROFILE.VALUE('RESP_ID')
                                                                       ,FND_PROFILE.VALUE('RESP_APPL_ID')
                                                                       ,XPHS.org_id)
        AND XPHS.status_code = 'POST PROCESS DONE';
        
        write_log(1,' .. Number of records deleted from xx_po_headers_stage:'||SQL%ROWCOUNT);
        
        -- --------------------
        -- End of modifications
        -- --------------------
    
    EXCEPTION
    WHEN OTHERS THEN
        write_log(1,'Error "'||SQLERRM||'"while deleting staging table data');
    END delete_data;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :val_po_lines                                                |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to validate whether the actual number|
  -- |             of PO lines corresponding to a PO header record is the same |
  -- |             as the number of lines indicated by the 'total_po_lines'    |
  -- |             field of the header record and also updates the error       |
  -- |             message in the staging table against the records.           |
  -- |                                                                         |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME    Mode TYPE        DESCRIPTION                                 |
  -- |----------- ---- ----------  -------------------------                   |
  -- |                                                                         |
  -- |p_thread_id  IN  PLS_INTEGER All records corrsponding to this validation |
  -- |                             thread id will be validated                 |
  -- +=========================================================================+
  
    PROCEDURE val_po_lines (p_thread_id IN  PLS_INTEGER)
                            
    IS
        
    BEGIN
      
        ------------------------------------------------------------
        -- Updating Error Code and Message for records with a mismatch
        -- in xx_po_headers_stage.total_po_lines and actual
        -- number of po lines in the xx_po_lines_stage table.
        -----------------------------------------------------------
        UPDATE  xx_po_headers_stage XPHS
        SET     XPHS.status_code        ='FAILED VALIDATIONS' -- Changed from 'ERROR' by Remya, V1.4 
               ,XPHS.error_message      = 'The total number of PO Lines do not match with the value in the Headers Stage table for the header sequence ID '|| XPHS.header_sequence_id
               ,XPHS.last_update_date   = g_date
               ,XPHS.last_updated_by    = g_user_id
               ,XPHS.request_id         = gn_request_id
        WHERE   XPHS.total_po_lines<>(SELECT COUNT(1)
                                      FROM  xx_po_lines_stage   XPLS
                                      WHERE XPHS.header_sequence_id = XPLS.header_sequence_id)
        AND     XPHS.total_po_lines IS NOT NULL
        AND     XPHS.validate_thread_id = p_thread_id;

        COMMIT;
        
    EXCEPTION -- Added by Remya, V1.4
    WHEN OTHERS THEN
        write_log(1,' .. Error "'||SQLERRM||'" while Validating Number of PO lines for thread id '||p_thread_id);
    END val_po_lines;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :get_ebs_supp_data                                           |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to get ebs data from given values of |
  -- |             legacy supplier number                                      |
  -- |                                                                         |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME         Mode  TYPE           DESCRIPTION                        |
  -- |-----------      ----  ---------      -------------------------          |
  -- | p_lgcy_sup_no    IN   VARCHAR2       Legacy Supplier Number             |
  -- | x_vendor_id      OUT  PLS_INTEGER    Vendor Id                          |
  -- | x_vendor_site_id OUT  PLS_INTEGER    Vendor Site Id                     |
  -- | x_org_id         OUT  PLS_INTEGER    Org Id                             |
  -- | x_attribute8     OUT  VARCHAR2       Attribute8 of PO_VENDOR_SITES      |
  -- | x_sob_id         OUT  PLS_INTEGER    Set of Books ID                    |
  -- | x_err            OUT  VARCHAR2       Returns code 'E' in case of errors |
  -- +=========================================================================+
  
    PROCEDURE get_ebs_supp_data
                          (p_lgcy_sup_no        IN  VARCHAR2    -- V1.6 : Changed from Numeric to character to avoid ORA-01406
                          ,x_vendor_id          OUT PLS_INTEGER
                          ,x_vendor_site_id     OUT PLS_INTEGER
                          ,x_org_id             OUT PLS_INTEGER
                          ,x_attribute8         OUT VARCHAR2
                          ,x_sob_id             OUT PLS_INTEGER
                          ,x_err                OUT VARCHAR2)
    IS 

    -- ====================================================
    -- Cursor to get EBS data for legacy supplier number
    -- ====================================================
    CURSOR  lcu_supplier_data (p_lgcy_supp_no IN VARCHAR2)
    IS
    SELECT  PVS.vendor_id
           ,PVS.vendor_site_id
           ,PVS.org_id
           ,PVS.attribute8
    FROM    po_vendor_sites_all PVS
    WHERE   LTRIM(PVS.attribute9,0)     =  p_lgcy_supp_no -- Modified by Remya, V1.4
    AND     PVS.purchasing_site_flag    ='Y';

    -- ===============================
    -- Cursor to get Set of Books ID
    -- ===============================
    CURSOR  lcu_sob_id(p_org_id IN PLS_INTEGER)
    IS
    SELECT  OOD.set_of_books_id
    FROM    org_organization_definitions    OOD
    WHERE   OOD.operating_unit     = p_org_id
    AND     ROWNUM = 1;
    
    -- ======================
    -- Variable Declarations
    -- ======================
    ln_vendor_id            PLS_INTEGER          := NULL;
    ln_vendor_site_id       PLS_INTEGER          := NULL;
    ln_org_id               PLS_INTEGER          := NULL;
    lc_attribute8           po_vendor_sites_all.attribute8%TYPE    := NULL;
    ln_sob_id               PLS_INTEGER          := NULL;

    BEGIN
        x_err := 'S';       
        OPEN lcu_supplier_data(p_lgcy_sup_no);
        ---------------------------------
        -- Fetching EBS supplier data
        ---------------------------------
        FETCH lcu_supplier_data INTO
                         ln_vendor_id
                        ,ln_vendor_site_id
                        ,ln_org_id
                        ,lc_attribute8;
        --------------------------------------------
        -- Setting Error status when data not found
        --------------------------------------------
        IF lcu_supplier_data%NOTFOUND THEN
            x_err := 'E'; 
        END IF;
        
        CLOSE lcu_supplier_data;        
        
        OPEN  lcu_sob_id(ln_org_id);
        FETCH lcu_sob_id INTO ln_sob_id;
        CLOSE lcu_sob_id;


        x_vendor_id          := ln_vendor_id;
        x_vendor_site_id     := ln_vendor_site_id;
        x_org_id             := ln_org_id;
        x_attribute8         := lc_attribute8;
        x_sob_id             := ln_sob_id;
    
    EXCEPTION
    WHEN OTHERS THEN
        x_err                := 'E';
        x_vendor_id          := ln_vendor_id;
        x_vendor_site_id     := ln_vendor_site_id;
        x_org_id             := ln_org_id;
        x_attribute8         := lc_attribute8;
        x_sob_id             := ln_sob_id;
        
    END get_ebs_supp_data;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :get_ebs_loc_data                                            |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to get ebs data from given values of |
  -- |             legacy location id                                          |
  -- |                                                                         |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME           Mode TYPE            DESCRIPTION                      |
  -- |-----------------  ---- --------       -------------------------         |
  -- | p_lgcy_loc_id     IN   VARCHAR2       Legacy Location Id                |
  -- | x_organization_id OUT  PLS_INTEGER    Organization ID                   |
  -- | x_location_id     OUT  PLS_INTEGER    Location ID                       |
  -- | x_err             OUT  VARCHAR2       Returns code 'E' in case of error |
  -- +=========================================================================+
  
    PROCEDURE get_ebs_loc_data
                          (p_lgcy_loc_id        IN  VARCHAR2  -- V1.6 : Changed from Numeric to char to avoid ORA-01406
                          ,x_organization_id    OUT PLS_INTEGER
                          ,x_location_id        OUT PLS_INTEGER
                          ,x_err                OUT VARCHAR2)
    IS

    -- ====================================================
    -- Cursor to get EBS data for legacy location id
    -- ====================================================
    CURSOR  lcu_loc_data(p_lgcy_loc_id  IN VARCHAR2)
    IS
    SELECT  HOU.organization_id
           ,HOU.location_id
    FROM    hr_organization_units           HOU
    WHERE   HOU.attribute1          = p_lgcy_loc_id; 
    

    ln_organization_id      PLS_INTEGER := NULL;
    ln_location_id          PLS_INTEGER := NULL;

    BEGIN
        x_err := 'S';
        ---------------------------------
        -- Fetching EBS location data
        ---------------------------------
        OPEN lcu_loc_data(p_lgcy_loc_id);

        FETCH lcu_loc_data INTO  ln_organization_id
                                ,ln_location_id;

        --------------------------------------------
        -- Setting Error status when data not found
        --------------------------------------------
        IF lcu_loc_data%NOTFOUND THEN
            x_err := 'E';
        END IF;

        CLOSE lcu_loc_data;
       
        x_organization_id    := ln_organization_id;
        x_location_id        := ln_location_id;

    EXCEPTION
    WHEN OTHERS THEN
        x_err                := 'E';
        x_organization_id    := ln_organization_id;
        x_location_id        := ln_location_id;
    END get_ebs_loc_data;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :get_buyer_potype                                            |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to get determine the buyer and the   |
  -- |             PO type for the PO record being processed.                  |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME           Mode TYPE        DESCRIPTION                          |
  -- |-----------------  ---- --------    -------------------------            |
  -- | p_header_seq_id   IN  PLS_INTEGER   Header Sequence Id                  |
  -- | p_ven_site_id     IN  PLS_INTEGER   Vendor Site ID                      |
  -- | p_loc_id          IN  PLS_INTEGER   Location ID                         |
  -- | p_org_id          IN  PLS_INTEGER   Org ID                              |
  -- | p_attrib8         IN  VARCHAR2      Attribute 8 from PO_VENDOR_SITES    |
  -- | x_emp_id          OUT PLS_INTEGER   Employee ID of the Buyer            |
  -- | x_po_type         OUT VARCHAR2      PO Type ('Trade' or 'Trade Import') |
  -- +=========================================================================+
  
    PROCEDURE get_buyer_potype
                             (p_header_seq_id  IN PLS_INTEGER
                             ,p_ven_site_id    IN PLS_INTEGER
                             ,p_loc_id         IN PLS_INTEGER
                             ,p_org_id         IN PLS_INTEGER -- Added by Remya,V1.1, 02-Aug-07
                             ,p_attrib8        IN VARCHAR2
                             ,x_emp_id        OUT PLS_INTEGER
                             ,x_po_type       OUT VARCHAR2                             
                             )
    IS

    -- ========================================
    -- Cursor to get employee id of the Buyer  
    -- ========================================
   
    -- Modified by Remya, V1.1, 02-Aug-07
    CURSOR lcu_buyer(p_hdr_seq_id    IN PLS_INTEGER
                    ,p_vend_site_id  IN PLS_INTEGER 
                    ,p_org_id        IN PLS_INTEGER) 
    IS
    SELECT  *
    FROM (  SELECT  XWS.planner_id -- Changed from employee_id by Remya, V1.2
                   ,PAP.first_name
            FROM    xx_po_lines_stage   XPL
                   ,xx_wfh_item_vendor_all XWS 
--                   ,mtl_system_items    MSI
                   ,per_all_people_f    PAP
                   ,po_agents           PA      -- Added by Remya, V1.5
            WHERE   XPL.header_sequence_id  = p_hdr_seq_id
--            AND     XWS.item_id             = MSI.inventory_item_id
--            AND     XPL.item                = MSI.segment1
            AND     XWS.planner_id          = PAP.person_id     -- Changed from employee_id by Remya, V1.2
            AND     XWS.vendor_site_id      = p_vend_site_id
            AND     XWS.org_id              = p_org_id
            AND     PA.agent_id             = PAP.person_id     -- Added by Remya, V1.5
            ORDER BY    PAP.first_name ASC)
    WHERE ROWNUM = 1;
    


    -- ====================================================
    -- Cursor to get OD PO type xx_po_global_indicator table 
    -- ====================================================
    CURSOR  lcu_po_type (p_vendor_site_id   IN PLS_INTEGER
                        ,p_location_id      IN PLS_INTEGER)
    IS
    SELECT  global_indicator_name meaning  
    FROM    xx_po_global_indicator  XPO
           ,po_vendor_sites_all     PVS
           ,hr_locations_all        HL
    WHERE   XPO.source_territory_code       = PVS.country
    AND     XPO.destination_territory_code  = HL.country
    AND     PVS.vendor_site_id              = p_vendor_site_id
    AND     HL.ship_to_location_id          = p_location_id
    AND     SYSDATE BETWEEN NVL(XPO.start_date,SYSDATE)
                        AND NVL(XPO.end_date,SYSDATE +1);

    -- ======================
    -- Variable Declarations
    -- ======================
    ln_employee_id      PLS_INTEGER          := NULL;
    lc_po_type          xx_po_global_indicator.global_indicator_name%type    := NULL;
    lc_first_name       per_all_people_f.first_name%type                     := NULL;

    BEGIN
    
        write_log(0,' -- Determining Buyer -- ');
        write_log(0,' .. Getting the employee id of the buyer');

        --------------------------------
        -- Fetching Buyer's Employee ID
        --------------------------------
        OPEN lcu_buyer(p_header_seq_id,p_ven_site_id,p_org_id); 
        FETCH lcu_buyer INTO ln_employee_id, lc_first_name; 

        ---------------------------------------
        -- Defaulting to Merchandize Planner
        -- when buyer data is not found.
        ---------------------------------------
        IF lcu_buyer%NOTFOUND THEN 
            write_log(0,' .. Planner not found as buyer');
            SELECT  person_id 
            INTO    ln_employee_id
            FROM    per_all_people_f
            WHERE   UPPER(first_name)  = 'PLANNER'
            AND     UPPER(last_name)   = 'MERCHANDIZE';
            write_log(0,' .. Defaulting buyer to "Merchandize, Planner"');-- Modified by Remya, V1.4
        END IF;

        CLOSE lcu_buyer; 
        write_log(0,'--------------------------------------------------------');


        write_log(0,' -- Determining OD PO Type -- ');
        write_log(0,' .. Getting PO type from xx_po_global_indicator table');

        ------------------------
        -- Fetching OD PO Type
        ------------------------
        OPEN lcu_po_type  (p_ven_site_id
                          ,p_loc_id);
        FETCH lcu_po_type INTO lc_po_type;


        ---------------------------------------
        -- Getting PO type from PO_VENDOR_SITES.
        -- attribute8 when not found above.
        ----------------------------------------
        IF lcu_po_type%NOTFOUND THEN
            write_log(0,' .. PO type not found in');
            lc_po_type := NULL;
            write_log(0,' .. Getting PO type from attribute8 of po_vendor_sites_all');

            IF UPPER(p_attrib8) LIKE 'TR-IMP' THEN --Modified by Remya, V1.4 
                lc_po_type      := 'Trade-Import';
            ELSE
                lc_po_type      := 'Trade';
            END IF;

            write_log(0,' .. PO Type determined :'||lc_po_type);
            
        END IF;-- corresponds to (IF lcu_po_type%NOTFOUND THEN)

        CLOSE lcu_po_type;

        x_emp_id    := ln_employee_id;
        x_po_type   := lc_po_type;
        
    END get_buyer_potype;
    
    
  -- +==========================================================================+
  -- |                                                                          |
  -- |                                                                          |
  -- |PROCEDURE   :get_prms_dt                                                  |
  -- |                                                                          |
  -- |DESCRIPTION :This procedure is used to get the Promise date by calling    |
  -- |             custom API XX_PO_DEFAULT_PROMISE_DATE_PKG.calc_promise_date  |
  -- |PARAMETERS  :                                                             |
  -- |                                                                          |
  -- |    NAME         Mode  TYPE          DESCRIPTION                          |
  -- |---------------  ----  --------     -------------------------             |
  -- | p_item_id         IN  PLS_INTEGER  Item Id                               |
  -- | p_ven_site_id     IN  PLS_INTEGER  Vendor Site ID                        |
  -- | p_po_type         IN  VARCHAR2     PO Type (Trade or Trade Import)       |
  -- | p_order_date      IN  DATE         Order Date                            |
  -- | p_promise_date    IN  DATE         Promise Date                          |
  -- | p_loc_id          IN  PLS_INTEGER  Ship to Location ID                   |
  -- | p_organiz_id      IN  PLS_INTEGER  Ship to organization ID               |
  -- | x_prms_dt        OUT  DATE         Value returned by API                 |
  -- | x_err            OUT  VARCHAR2     Returns error message in case of error |
  -- +==========================================================================+
  
    PROCEDURE  get_prms_dt(p_item_id        IN  PLS_INTEGER
                          ,p_ven_site_id    IN  PLS_INTEGER
                          ,p_po_type        IN  VARCHAR2
                          ,p_order_date     IN  DATE
                          ,p_promise_date   IN  DATE
                          ,p_loc_id         IN  PLS_INTEGER
                          ,p_organiz_id     IN  PLS_INTEGER
                          ,x_prms_dt        OUT DATE -- Changed from 'VARCHAR2' by Remya, V1.3
                          ,x_err            OUT VARCHAR2)-- Added by Remya, V1.4
    IS
    
    -- ======================
    -- Variable Declarations
    -- ======================
    ld_ret_prom_date    DATE := NULL; -- Changed from 'VARCHAR2' by Remya, V1.3
    ln_prm_date_err     PLS_INTEGER;
    lc_err              VARCHAR2(200)   := NULL;-- Added by Remya, V1.4

    BEGIN
        
        write_log(0,' --- Deriving Promise Date --');
        ------------------------------------------------------
        -- Invoking Custom API XX_PO_DEFAULT_PROMISE_DATE_PKG
        -- .calc_promise_date to extract Promise Date 
        ------------------------------------------------------
        write_log(0,' ... Invoking Custom API to extract Promise Date ');
        ld_ret_prom_date  := XX_PO_DEFAULT_PROMISE_DATE_PKG.calc_promise_date
                                        (
                                         p_item                 =>p_item_id
                                        ,p_supplier             =>p_ven_site_id
                                        ,p_po_type              =>p_po_type
                                        ,p_revision_num         => 0
                                        ,p_order_date           =>p_order_date
                                        ,p_promise_date         =>p_promise_date
                                        ,p_ship_to_location_id  =>p_loc_id
                                        ,p_ship_to_org_id       =>p_organiz_id
                                        ,x_error_status         =>ln_prm_date_err
                                        );
        write_log(0,' ... Value returned from API is :'||ld_ret_prom_date);

        x_prms_dt := NVL(ld_ret_prom_date,NVL(p_promise_date,SYSDATE));
    
    EXCEPTION-- Added by Remya, V1.4
    WHEN OTHERS THEN
        x_prms_dt := NVL(p_promise_date,SYSDATE);
        x_err     := 'Error "'||SQLERRM||'" while extracting Promise Date ';
    END get_prms_dt;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :get_quot_dtls                                               |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to get the catalog quotation details |
  -- |             and also the unit price                                     |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode TYPE         DESCRIPTION                          |
  -- |----------------  ---- --------    -------------------------             |
  -- | p_ven_site_id      IN PLS_INTEGER  Vendor Site ID                       |
  -- | p_item_id          IN PLS_INTEGER  Item ID                              |
  -- | p_sob_id           IN PLS_INTEGER  Set of Books ID                      |
  -- | p_qty              IN PLS_INTEGER  Quantity                             |
  -- | p_organization_id  IN PLS_INTEGER  Organization ID                      |
  -- | p_location_id      IN PLS_INTEGER  Location ID                          |
  -- | x_quot_hdr_id     OUT PLS_INTEGER  Quotation Header ID                  |
  -- | x_quot_line_id    OUT PLS_INTEGER  Quotation Line ID                    |
  -- | x_line_loc_id     OUT PLS_INTEGER  Quotation Line Location ID           |
  -- | x_currency_code   OUT VARCHAR2     Currency Code                        |
  -- | x_func_curr_code  OUT VARCHAR2     Functional Currency Code             |
  -- | x_quot_uom        OUT VARCHAR2     UOM from quotation                   |
  -- | x_quot_unit_price OUT VARCHAR2     Unit Price from quotation            |
  -- | x_tot_land_price  OUT VARCHAR2     Total Landed Price                   |
  -- | x_err             OUT VARCHAR2     Error Code                           |
  -- +=========================================================================+
  
    PROCEDURE get_quot_dtls(p_ven_site_id     IN  PLS_INTEGER
                           ,p_item_id         IN  PLS_INTEGER
                           ,p_sob_id          IN  PLS_INTEGER
                           ,p_qty             IN  PLS_INTEGER
                           ,p_organization_id IN  PLS_INTEGER
                           ,p_location_id     IN  PLS_INTEGER
                           ,x_quot_hdr_id     OUT PLS_INTEGER
                           ,x_quot_line_id    OUT PLS_INTEGER
                           ,x_line_loc_id     OUT PLS_INTEGER
                           ,x_currency_code   OUT VARCHAR2
                           ,x_func_curr_code  OUT VARCHAR2
                           ,x_quot_uom        OUT VARCHAR2
                           ,x_quot_unit_price OUT VARCHAR2
                           ,x_tot_land_price  OUT VARCHAR2
                           ,x_err             OUT VARCHAR2)
    IS

    -- ====================================================
    -- Cursor to get catalog quotation details 
    -- ====================================================
    CURSOR lcu_catalog_quot( p_vendor_site_id IN PLS_INTEGER
                            ,p_item_id        IN PLS_INTEGER)
    IS
    SELECT  *
    FROM   (SELECT  PHA.po_header_id
                   ,PLA.po_line_id
                   ,PHA.currency_code
                   ,PLA.unit_meas_lookup_code 
                  -- ,PLA.attribute6 -- Commented out by Remya, V1.7
            FROM    po_headers_all PHA
                   ,po_lines_all  PLA
            WHERE   PHA.vendor_site_id                  = p_vendor_site_id
            AND     PLA.item_id                         = p_item_id
            AND     UPPER(PHA.type_lookup_code)         = 'QUOTATION'
            AND     UPPER(PHA.quote_type_lookup_code)   = 'CATALOG'
            AND     PHA.po_header_id                    = PLA.po_header_id
            AND     SYSDATE BETWEEN NVL(PHA.start_date,SYSDATE)
                                AND NVL(PHA.end_date,SYSDATE +1) 
            ORDER BY PHA.last_update_date DESC)
    WHERE ROWNUM = 1;

    -- ======================
    -- Variable Declarations
    -- ======================
    ln_quot_hdr_id          PLS_INTEGER          := NULL;
    ln_quot_line_id         PLS_INTEGER          := NULL;
    ln_quot_line_loc_id     PLS_INTEGER          := NULL;
    lc_currency_code        po_headers_all.currency_code%TYPE       := NULL;
    lc_func_curr_code       gl_sets_of_books.currency_code%TYPE     := NULL;
    lc_quot_uom_lkp_cd      po_lines_all.unit_meas_lookup_code%TYPE := NULL;
    lc_total_landed_price   po_line_locations_all.attribute6%TYPE   := NULL; -- Modified from po_lines_all.attribute6%TYPE by Remya, V1.7
    lc_quot_unit_price      po_line_locations_all.price_override%TYPE    := NULL;
    lc_quot_uom             mtl_units_of_measure.uom_code%TYPE      := NULL;

    EX_NO_QUOTE             EXCEPTION;
    
    
    BEGIN
        x_err             :=  NULL;
        -----------------------------------------------
        -- Fetching functional currency code for the PO
        -----------------------------------------------
        write_log(0,' ... Fetching currency code for the PO ');
        BEGIN
            SELECT  currency_code
            INTO    lc_func_curr_code
            FROM    gl_sets_of_books
            WHERE   set_of_books_id = p_sob_id;
        EXCEPTION
        WHEN OTHERS THEN
            write_log(0,' ... Error while getting Functional Currency Code is: '||SQLERRM);
        END;

        write_log(0,' ... Functional Currency Code is: '||lc_func_curr_code);
        
        ------------------------------------------------------
        -- Fetching Data from the Cataglog Quotation of the PO
        ------------------------------------------------------
        write_log(0,' ... Getting catalog quotation details');
        OPEN lcu_catalog_quot(p_ven_site_id,p_item_id);
        FETCH lcu_catalog_quot INTO ln_quot_hdr_id
                                   ,ln_quot_line_id
                                   ,lc_currency_code
                                   ,lc_quot_uom_lkp_cd;
                                   --,lc_total_landed_price; -- Commented out by Remya, V1.7
        ------------------------------------------------------
        -- Raising exception when No active quotation is found
        ------------------------------------------------------
        IF lcu_catalog_quot%NOTFOUND THEN
            RAISE EX_NO_QUOTE;
        END IF;

        CLOSE lcu_catalog_quot;

        write_log(0,' ... An active quotation is present for the PO');

/******************* 
-- no longer required v1.5
        ----------------------------------------------
        -- Getting UOM code from the Catalog Quotation
        ----------------------------------------------
        BEGIN
            
            write_log(0,' ... Getting UOM code from the Quotation.');
            SELECT  MUM.uom_code
            INTO    lc_quot_uom
            FROM    mtl_units_of_measure MUM
            WHERE   UPPER(MUM.unit_of_measure) = UPPER(lc_quot_uom_lkp_cd);
            write_log(0,' ... UOM code is '||lc_quot_uom);
            
        EXCEPTION
            WHEN OTHERS THEN
            write_log(0,' ... Error while getting code from the Quotation is: '||SQLERRM);
        END;
************/
        ---------------------------------------------------------
        -- Invoking Standard API PO_SOURCING2_SV.get_break_price
        ---------------------------------------------------------
        write_log(0,' ... Getting Unit Price using Standard API');

        lc_quot_unit_price := PO_SOURCING2_SV.get_break_price
                                    (x_order_quantity   => p_qty
                                    ,x_ship_to_org      => p_organization_id  
                                    ,x_ship_to_loc      => p_location_id
                                    ,x_po_line_id       => ln_quot_line_id
                                    ,x_cum_flag         => TRUE
                                    ,p_need_by_date     => NULL
                                    ,x_line_location_id => NULL
                                     );
        write_log(0,' ... Unit Price derived from std API is:'||lc_quot_unit_price);
        
        ----------------------------
        -- Getting Line Location Id 
        ----------------------------
        BEGIN

            write_log(0,' ... Getting the Line Location Id');
            SELECT  line_location_id
                   ,attribute6 -- Added by Remya, V1.7
            INTO    ln_quot_line_loc_id
                   ,lc_total_landed_price -- Added by Remya, V1.7
            FROM    po_line_locations_all
            WHERE   price_override  = lc_quot_unit_price
            AND     po_line_id      = ln_quot_line_id
            AND     po_header_id    = ln_quot_hdr_id
            AND     SYSDATE BETWEEN NVL(start_date,SYSDATE) AND NVL(end_date, SYSDATE + 1);
            write_log(0,' ... Line location id of the quotation is: '||ln_quot_line_loc_id);

        EXCEPTION
        WHEN OTHERS THEN
            write_log(0,' ... Error while getting line location id is: '||SQLERRM);
        END;
        write_log(0,' ... UOM Code: '||lc_quot_uom_lkp_cd);
        x_quot_hdr_id      := ln_quot_hdr_id;
        x_quot_line_id     := ln_quot_line_id;
        x_line_loc_id      := ln_quot_line_loc_id;
        x_currency_code    := lc_currency_code;
        x_func_curr_code   := lc_func_curr_code;
--        x_quot_uom         := lc_quot_uom;
        x_quot_uom         := lc_quot_uom_lkp_cd;
        x_quot_unit_price  := lc_quot_unit_price;
        x_tot_land_price   := lc_total_landed_price;
        x_err              := NULL;
        
    EXCEPTION
    WHEN EX_NO_QUOTE THEN
        
        CLOSE lcu_catalog_quot;
        
        x_err   := 'E';
        x_quot_hdr_id      := ln_quot_hdr_id;
        x_quot_line_id     := ln_quot_line_id;
        x_line_loc_id      := ln_quot_line_loc_id;
        x_currency_code    := lc_currency_code;
        x_func_curr_code   := lc_func_curr_code;
        x_quot_uom         := lc_quot_uom;
        x_quot_unit_price  := lc_quot_unit_price;
        x_tot_land_price   := lc_total_landed_price;

    WHEN OTHERS THEN
    
        write_log(0,' ... Error while Getting Unit Price is: '||SQLERRM);
        x_quot_hdr_id      := ln_quot_hdr_id;
        x_quot_line_id     := ln_quot_line_id;
        x_line_loc_id      := ln_quot_line_loc_id;
        x_currency_code    := lc_currency_code;
        x_func_curr_code   := lc_func_curr_code;
        x_quot_uom         := lc_quot_uom;
        x_quot_unit_price  := lc_quot_unit_price;
        x_tot_land_price   := lc_total_landed_price;

    END get_quot_dtls;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :val_ven_min                                                 |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to validate the vendor minimum of    |
  -- |             PO record being processed if it has active quotation        |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME           Mode TYPE       DESCRIPTION                           |
  -- |-----------------  ---- --------   -------------------------             |
  -- | p_hdr_seq_id      IN  PLS_INTEGER Header Sequence Id                    |
  -- | p_po_curr         IN  VARCHAR2    PO Currency                           |
  -- | p_ven_site_id     IN  PLS_INTEGER Vendor Site ID                        |
  -- | x_status         OUT  VARCHAR2    Returns APPROVED or INCOMPLETE status |
  -- +=========================================================================+
  
    PROCEDURE val_ven_min(p_hdr_seq_id  IN  PLS_INTEGER
                         ,p_po_curr     IN  VARCHAR2
                         ,p_ven_site_id IN  PLS_INTEGER
                         ,x_status      OUT VARCHAR2)
    IS
    -- =============================
    -- Cursor to get approval status
    -- =============================
    CURSOR  lcu_appr(p_hdr IN PLS_INTEGER)
    IS 
    SELECT  approval_status
    FROM    xx_po_headers_stage
    WHERE   header_sequence_id = p_hdr;

    -- ===============================
    -- Cursor to get total po amount
    -- ===============================
    CURSOR  lcu_po_tot(p_hdr IN PLS_INTEGER)
    IS
    SELECT  SUM(quantity*unit_price)
    FROM    xx_po_lines_stage  
    WHERE   header_sequence_id = p_hdr;

    -- ======================
    -- Variable Declarations
    -- ======================
    ln_po_total_amount  PLS_INTEGER       := NULL;
    lc_ret_appr_status  VARCHAR2(50) := NULL;
    lc_ven_min_err      VARCHAR2(2000):= NULL;
    lc_ap_status        xx_po_headers_stage.approval_status%TYPE := NULL;

    BEGIN

        write_log(0,' .. Getting the Approval Status of the Record');
        -----------------------------------
        -- Fetchin already existing approval
        -- status from the staging table
        ------------------------------------
        OPEN lcu_appr(p_hdr_seq_id);
        FETCH lcu_appr INTO lc_ap_status;
        CLOSE lcu_appr;

        write_log(0,' .. Approval Status is :'||lc_ap_status);

        write_log(0,' .. Getting the total PO amount');
        -----------------------------------
        -- Fetchin Total PO amount from 
        -- the PO lines of staging table
        ------------------------------------
        OPEN lcu_po_tot(p_hdr_seq_id);
        FETCH lcu_po_tot INTO  ln_po_total_amount;
        CLOSE lcu_po_tot;
        
        write_log(0,' .. Total PO amount is : '||ln_po_total_amount);

        IF UPPER(lc_ap_status) = 'INCOMPLETE' THEN 

            write_log(0,' .. Did not validate vendor minimum as approval status is already '||lc_ap_status);

        ELSE -- corresponds to (IF lc_ap_status = 'INCOMPLETE' THEN)
        
            ----------------------------------------------------------------------------
            -- Invoking  vendor min. custom API when approval status is not 'INCOMPLETE'
            ----------------------------------------------------------------------------
            write_log(0,' .. Calling custom API to validate Vendor Minimum');
            lc_ret_appr_status := XX_PO_VEN_MIN_PKG.main_calc_vendor_min(
                             p_supplier_site_id  => p_ven_site_id
                            ,p_po_amount         => ln_po_total_amount
                            ,p_po_currency       => p_po_curr
                            ,x_error_msg         => lc_ven_min_err
                            );
            write_log(0,' .. Value returned from API is :'||lc_ret_appr_status);

            --------------------------------------------------
            -- Setting approval status "APPROVED/INCOMPLETE"
            -- based on value returned from API "PASS/FAIL"
            --------------------------------------------------
            IF UPPER(lc_ret_appr_status) = 'PASS' THEN
                lc_ap_status := 'APPROVED';
                write_log(0,' .. PASS : Setting status to APPROVED');
            ELSE
                lc_ap_status:= 'INCOMPLETE';
                write_log(0,' .. FAIL : Setting status to INCOMPLETE');
            END IF;

        END IF; -- corresponds to (IF lc_ap_status = 'INCOMPLETE' THEN)
        
        x_status := lc_ap_status;
    END val_ven_min;
    
    
  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   :populate_intf                                               |
  -- |                                                                         |
  -- |DESCRIPTION :This procedure is used to update the populate the interface |
  -- |             tables with validated data                                  |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME       Mode TYPE         DESCRIPTION                             |
  -- |-------------  ---- -----------  -------------------------               |
  -- | p_thread_id   IN   PLS_INTEGER  Thread ID to pick up validated records  |
  -- +=========================================================================+
  
    PROCEDURE populate_intf(p_thread_id  IN PLS_INTEGER
                           ,x_count     OUT PLS_INTEGER)
    
    IS
    -- ================================================
    -- Cursor to pick all the valid header records from 
    -- staging table for the given validation thread 
    -- which need to be inserted into interface table 
    -- ================================================
    CURSOR  lcu_ins_rec(p_vldt_thread_id    IN  PLS_INTEGER)
    IS 
    SELECT  *
    FROM    xx_po_headers_stage
    WHERE   UPPER(status_code) = 'PASSED VALIDATIONS' -- Changed from "<> 'ERROR'"by Remya, V1.4 
    AND     validate_thread_id = p_vldt_thread_id
    ORDER BY header_sequence_id;


    -- ================================================
    -- Cursor to pick all the valid PO line records from
    -- staging table for the current header record 
    -- which need to be inserted into interface table 
    -- ================================================
    CURSOR  lcu_ins_line_rec(p_header_sequence_id   IN  PLS_INTEGER)
    IS
    SELECT  *
    FROM    xx_po_lines_stage  
    WHERE   header_sequence_id = p_header_sequence_id
    ORDER BY line_sequence_id;
        
    -- ======================
    -- Variable Declarations
    -- ======================
    ln_insert_count                 PLS_INTEGER;
    ln_interface_distribution_id    PLS_INTEGER;
    lc_error                        VARCHAR2(2000) := NULL; -- Added by Remya, V1.4
    ln_hdr_id                       NUMBER;-- Added by Remya, V1.4
    ln_line_id                      NUMBER;-- Added by Remya, V1.4
    
    EX_INSERT_ERROR                 EXCEPTION;
    
    BEGIN

        ln_insert_count  := 0;
        SAVEPOINT before_inserts;
        -------------------------------------
        -- For succesfully validated records
        -------------------------------------
        write_log(0,' ');
        write_log(0,' -- Populating interface tables with valid data --');
        
        FOR lcr_ins_rec IN lcu_ins_rec(p_thread_id)
        LOOP
            BEGIN
            
            SAVEPOINT before_header_insert;
            ----------------------------------
            -- Populating PO_HEADERS_INTERFACE
            ----------------------------------
                BEGIN
                    write_log(0,' .. Inserting values into po_headers_interface table for '||lcr_ins_rec.header_sequence_id);
                    ln_insert_count := ln_insert_count + 1;

                    INSERT INTO po_headers_interface
                                (interface_header_id
                                ,process_code
                                ,action
                                ,org_id
                                ,document_type_code
                                ,currency_code
                                ,rate_type
                                ,rate_date
                                ,agent_id
                                ,vendor_id
                                ,vendor_site_id
                                ,ship_to_location_id
                                ,approval_status
                                ,note_to_receiver
                                ,comments
                                ,vendor_doc_num
                                ,attribute_category
                                ,attribute1
                                ,attribute6
                                ,attribute7
                                ,attribute8
                                ,attribute9
                                ,attribute10 -- Added by Remya, V1.1, 02-Aug-07
                                ,creation_date
                                ,created_by
                                ,last_update_date
                                ,last_updated_by
                                ,program_application_id
                                ,program_id
                                ,program_update_date
                                ,request_id
                                )
                          VALUES(lcr_ins_rec.header_sequence_id
                                ,'PENDING'
                                ,'Original'
                                ,lcr_ins_rec.org_id
                                ,'STANDARD'
                                ,lcr_ins_rec.currency_code
                                ,lcr_ins_rec.rate_type
                                ,lcr_ins_rec.rate_date
                                ,lcr_ins_rec.agent_id
                                ,lcr_ins_rec.vendor_id
                                ,lcr_ins_rec.vendor_site_id
                                ,lcr_ins_rec.ship_to_location_id
                                ,lcr_ins_rec.approval_status
                                ,lcr_ins_rec.comments
                                ,lcr_ins_rec.comments
                                ,('POROQ-'||lcr_ins_rec.header_sequence_id)
                                ,lcr_ins_rec.attribute_category
                                ,lcr_ins_rec.po_source
                                ,lcr_ins_rec.attribute6
                                ,lcr_ins_rec.attribute7
                                ,lcr_ins_rec.attribute8
                                ,lcr_ins_rec.attribute9
                                ,DECODE(lcr_ins_rec.attribute_category,'Trade-Import',xx_po_gss_po_number_s.NEXTVAL,NULL) -- Added by Remya, V1.1, 02-Aug-07
                                ,g_date
                                ,g_user_id
                                ,g_date
                                ,g_user_id
                                ,gn_appl_id
                                ,gn_conc_prog_id
                                ,g_date
                                ,gn_request_id
                                 );
                EXCEPTION -- Added by Remya, V1.4
                WHEN OTHERS THEN
                    lc_error    :=  ' .. Error "'||SQLERRM||'" encountered while '||'populating po_headers_interface table for '||lcr_ins_rec.header_sequence_id;
                    ln_hdr_id   := lcr_ins_rec.header_sequence_id;
                    ln_line_id  := NULL;
                    RAISE ex_insert_error;
                END;
            

                FOR lcr_ins_line_rec IN lcu_ins_line_rec(lcr_ins_rec.header_sequence_id)
                LOOP
                ----------------------------------
                -- Populating PO_LINES_INTERFACE
                ----------------------------------
                    BEGIN
                        write_log(0,' ... Inserting values into po_lines_interface table for line number '||lcr_ins_line_rec.line_number);
                        INSERT INTO po_lines_interface
                                    (interface_line_id
                                    ,interface_header_id
                                    ,line_num
                                    ,shipment_num
                                    ,item
                                    ,item_id
                                    ,unit_of_measure
                                    ,quantity
                                    ,unit_price
                                    ,ship_to_organization_id
                                    ,ship_to_location_id
                                    ,promised_date
                                    ,line_attribute_category_lines
                                    ,line_attribute6
                                    ,shipment_attribute_category
                                    ,last_update_date
                                    ,last_updated_by
                                    ,creation_date
                                    ,created_by
                                    ,program_application_id
                                    ,program_id
                                    ,program_update_date)
                              VALUES(lcr_ins_line_rec.line_sequence_id
                                    ,lcr_ins_rec.header_sequence_id
                                    ,lcr_ins_line_rec.line_number
                                    ,'1'
                                    ,lcr_ins_line_rec.item
                                    ,lcr_ins_line_rec.item_id
                                    ,lcr_ins_line_rec.uom_code
                                    ,lcr_ins_line_rec.quantity
                                    ,lcr_ins_line_rec.unit_price
                                    ,lcr_ins_line_rec.ship_to_organization_id 
                                    ,lcr_ins_line_rec.ebs_location_id
                                    ,lcr_ins_line_rec.ebs_promise_date
                                    ,lcr_ins_rec.attribute_category
                                    ,DECODE(lcr_ins_rec.attribute_category,'Trade-Import',lcr_ins_line_rec.total_landed_price,NULL)
                                    ,lcr_ins_rec.attribute_category
                                    ,g_date
                                    ,g_user_id
                                    ,g_date
                                    ,g_user_id
                                    ,gn_appl_id
                                    ,gn_conc_prog_id
                                    ,g_date);
                    EXCEPTION -- Added by Remya, V1.4
                    WHEN OTHERS THEN
                        lc_error    :=  ' .. Error "'||SQLERRM||'" encountered while '||'populating po_lines_interface table';
                        ln_hdr_id   := lcr_ins_rec.header_sequence_id;
                        ln_line_id  := lcr_ins_line_rec.line_sequence_id;
                        RAISE EX_INSERT_ERROR;
                    END;

                    SELECT  po_distributions_interface_s.NEXTVAL
                    INTO    ln_interface_distribution_id
                    FROM    DUAL;

                    ---------------------------------------
                    -- Populating PO_DISTRIBUTIONS_INTERFACE
                    ----------------------------------------
                    BEGIN
                        write_log(0,' ... Inserting values into po_distributions_interface table for distribution number 1');
                        INSERT INTO po_distributions_interface
                                    (interface_header_id
                                    ,interface_line_id
                                    ,interface_distribution_id
                                    ,distribution_num
                                    ,org_id
                                    ,attribute_category
                                    ,quantity_ordered
                                    ,last_update_date
                                    ,last_updated_by
                                    ,creation_date
                                    ,created_by
                                    ,program_application_id
                                    ,program_id
                                    ,program_update_date)
                              VALUES(lcr_ins_rec.header_sequence_id 
                                    ,lcr_ins_line_rec.line_sequence_id
                                    ,ln_interface_distribution_id
                                    ,'1'
                                    ,lcr_ins_rec.org_id
                                    ,lcr_ins_rec.attribute_category
                                    ,lcr_ins_line_rec.quantity
                                    ,g_date
                                    ,g_user_id
                                    ,g_date
                                    ,g_user_id
                                    ,gn_appl_id
                                    ,gn_conc_prog_id
                                    ,g_date);
                    EXCEPTION -- Added by Remya, V1.4
                    WHEN OTHERS THEN
                        lc_error    :=  ' .. Error "'||SQLERRM||'" encountered while '||'populating po_distributions_interface table';
                        ln_hdr_id   := lcr_ins_rec.header_sequence_id;
                        ln_line_id  := lcr_ins_line_rec.line_sequence_id;
                        RAISE ex_insert_error;

                    END;
                
                END LOOP;
            
            EXCEPTION
            WHEN EX_INSERT_ERROR THEN -- Added by Remya, V1.4
                ln_insert_count := ln_insert_count - 1;

                ROLLBACK TO before_header_insert;
                write_log(1,' .. Inside EX_INSERT_ERROR Exception...Rollback record' );
                write_log(1,lc_error);

                update_stg(p_status     => 'FAILED VALIDATIONS' 
                          ,p_msg         => lc_error
                          ,p_hdr_seq_id  => ln_hdr_id
                          ,p_line_seq_id => ln_line_id);
            WHEN OTHERS THEN
                ln_insert_count := ln_insert_count - 1;

                ROLLBACK TO before_header_insert;
                write_log(1,' .. Rollback record' );
                write_log(1,lc_error);

                update_stg(p_status     => 'FAILED VALIDATIONS' 
                          ,p_msg        => lc_error
                          ,p_hdr_seq_id => ln_hdr_id
                          ,p_line_seq_id=> ln_line_id);
            END;
        END LOOP;
        
        x_count := ln_insert_count;
        
        write_log(0,'--------------------------------------------------------');
        write_log(0,' ');
    
    COMMIT;
    
    EXCEPTION
        
    WHEN OTHERS THEN
        ROLLBACK TO before_inserts;
        write_log(1,' .. Rollback all records of this thread');
        write_log(1,' .. Error while inserting interface data is '||SQLERRM);
        x_count := 0;
        
    END populate_intf;


  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   : Preproc_Main                                               |
  -- |                                                                         |
  -- |DESCRIPTION : This procedure will be used to invoke Validation Concurrent|
  -- |              Programs to process data from the staging tables           |
  -- |              It updates the validated records in the interface tables   |
  -- |              with batch_id and calls standard Import Purchase Order API.|
  -- |              It also creates allocations for the created POs and updates|
  -- |              the newly created POs with their quotation details. Finally|
  -- |              it purges the staging tables of processed records.         |
  -- |                                                                         |
  -- |                                                                         |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME        Mode  TYPE        DESCRIPTION                            |
  -- |--------------  ----  ----------  -------------------------              |
  -- |                                                                         |
  -- | x_errbuf       OUT   VARCHAR2    Returns message to Concurrent Manager  |
  -- | x_retcode      OUT   PLS_INTEGER Returns status to Concurrent Manager   |
  -- | p_status_code  IN    VARCHAR2    Status Code of records                 |
  -- | p_batch_size   IN    PLS_INTEGER Batch Size permitted                   |
  -- | p_threads      IN    PLS_INTEGER No. of Validation Threads              |
  -- | p_debug        IN    VARCHAR2    Determines if debug messages should    |
  -- |                                  be printed.                            |
  -- +=========================================================================+
  
    PROCEDURE Preproc_Main(
                            x_errbuf        OUT VARCHAR2
                           ,x_retcode       OUT PLS_INTEGER
                           ,p_status_code   IN  VARCHAR2 
                        --   ,p_batch_id      IN  PLS_INTEGER -- Commented by Remya, V1.4
                           ,p_batch_size    IN  PLS_INTEGER
                           ,p_threads       IN  PLS_INTEGER
                        --   ,p_purge         IN  VARCHAR2 -- Commented by Remya, V1.4
                           ,p_debug         IN  VARCHAR2
                           )

    IS

    -- ==================================================
    -- Cursor to pick error messages from PreProcessor
    -- validations to be displayed
    -- ==================================================
    CURSOR  lcu_pp_err_msg
    IS
    SELECT  XLS.header_sequence_id
           ,XLS.line_number
           ,XLS.error_message
    FROM    xx_po_headers_stage     XHS 
           ,xx_po_lines_stage       XLS
    WHERE   XHS.header_sequence_id = XLS.header_sequence_id
    AND     XHS.status_code        = 'FAILED VALIDATIONS' -- Changed from 'ERROR' by Remya, V1.4
    AND     XLS.error_message IS NOT NULL
    AND     XHS.request_id         IN (SELECT   request_id
                                       FROM     fnd_concurrent_requests
                                       WHERE    parent_request_id = gn_request_id)
    UNION
    SELECT  XHS.header_sequence_id 
          , NULL
          , XHS.error_message
    FROM    xx_po_headers_stage XHS 
    WHERE   XHS.status_code        = 'FAILED VALIDATIONS' -- Changed from 'ERROR' by Remya, V1.4
    AND     XHS.error_message IS NOT NULL  
    AND     XHS.request_id         IN (SELECT   request_id
                                       FROM     fnd_concurrent_requests
                                       WHERE    parent_request_id = gn_request_id);

    -- ==================================================
    -- Cursor to pick error messages from standard API
    -- validations to be displayed
    -- ==================================================
    CURSOR  lcu_api_err_msg
    IS  
    SELECT  DISTINCT PIE.interface_header_id
           ,PIE.interface_line_id
           ,PLI.line_num 
           ,PIE.error_message
    FROM    po_interface_errors     PIE 
           ,po_headers_interface    PHI
           ,po_lines_interface      PLI 
           ,xx_po_headers_stage     XHS
    WHERE  PIE.interface_header_id  = PHI.interface_header_id
    AND    PHI.interface_header_id  = XHS.header_sequence_id
    AND    PHI.request_id           = XHS.request_id
    AND    XHS.request_id           = gn_request_id
    AND    PHI.interface_header_id  = PLI.interface_header_id
    AND    PLI.interface_line_id    = PIE.interface_line_id
    AND    UPPER(PHI.process_code)  = 'REJECTED'
    AND    PIE.interface_line_id IS NOT NULL
    UNION
    SELECT  DISTINCT PIE.interface_header_id
           ,PIE.interface_line_id
           ,NULL 
           ,PIE.error_message
    FROM    po_interface_errors     PIE 
           ,po_headers_interface    PHI
           ,xx_po_headers_stage     XHS
    WHERE  PIE.interface_header_id  = PHI.interface_header_id
    AND    PHI.request_id           = XHS.request_id
    AND    PHI.interface_header_id  = XHS.header_sequence_id
    AND    XHS.request_id           = gn_request_id
    AND    UPPER(PHI.process_code)  = 'REJECTED'
    AND    PIE.interface_line_id IS NULL
    ORDER BY interface_header_id, line_num;
 
    -- =============================
    -- Local Variable Declaration
    -- =============================
    ln_thread_size          PLS_INTEGER := 0;
    ln_tot_hdrs             PLS_INTEGER := 0;
    ln_no_of_threads        PLS_INTEGER := 0;
    ln_ebs_fail_count       PLS_INTEGER := 0;
    ln_val_fail_count       PLS_INTEGER := 0;
    ln_incomplete_po_count  PLS_INTEGER := 0;
    ln_approved_po_count    PLS_INTEGER := 0;
    ln_alloc_hdr_count      PLS_INTEGER := 0;
    lc_error_message        VARCHAR2(2000) := NULL;
    lc_alloc_err            VARCHAR2(3) := NULL; -- Added by Remya, V1.4
    lc_upd_quot_err         VARCHAR2(3) := NULL; -- Added by Remya, V1.4
    
    EX_VAL_ASSIGN           EXCEPTION;
    EX_VAL_CP_CALL          EXCEPTION;
    EX_STD_IMPORT           EXCEPTION;
    EX_NO_HDRS              EXCEPTION;
    
    BEGIN
        write_out('==============================================================================');
        write_out(' Office Depot                                    Date : '||TO_CHAR(SYSDATE,'dd-Mon-yy hh24:mi:ss'));
        write_out('                         OD: PO ROQ Preprocessor Main Program                 ');
        write_out(' ');
        write_out('==============================================================================');
        
        gc_debug_flag          := p_debug;
                       
        write_log(0,'Pre Processor Begins');
        write_log(0,' ');
        
        ln_tot_hdrs             := NULL;
        ln_no_of_threads        := NULL;
        ln_thread_size          := NULL;
        
        BEGIN
        
            SELECT  COUNT(header_sequence_id),DECODE(p_threads,0,1,p_threads)
            INTO    ln_tot_hdrs, ln_no_of_threads
            FROM    xx_po_headers_stage 
            WHERE   status_code = DECODE(p_status_code,'ALL',status_code,p_status_code)-- Modified by Remya, V1.7
            AND     status_code IN ('NEW','CORRECTED');
            write_log(0,'..Number of headers is '|| ln_tot_hdrs);

            IF ln_tot_hdrs = 0 THEN
                RAISE EX_NO_HDRS;
            END IF;

            write_log(0,'..Number of threads is '|| ln_no_of_threads);

            ln_thread_size := CEIL(ln_tot_hdrs/ln_no_of_threads);
            write_log(0,'..Thread size is '|| ln_thread_size);


            ----------------------------------
            --Assigning Validation thread Ids 
            ----------------------------------
            BEGIN
                write_log(0,' -- Calling Procedure assign_val_id with ');
                write_log(0,' .. p_status :'||p_status_code||' and p_thread_size: '||ln_thread_size);

                assign_val_id(p_status      => p_status_code
                             ,p_thread_size => ln_thread_size );

            EXCEPTION
            WHEN OTHERS THEN
                lc_error_message := ' .. Error "'||SQLERRM||'" encountered while assiging validation thread ids';
                RAISE EX_VAL_ASSIGN;
            END;

            write_log(0,'--------------------------------------');

            --------------------------------------------------------------------
            -- Calling the Validation Concurrent Program for each of the threads
            --------------------------------------------------------------------
            BEGIN
                write_log(0,' -- Calling Procedure call_val_cp ');

                call_val_cp(p_debug_flag => p_debug);

            EXCEPTION
            WHEN OTHERS THEN
                lc_error_message := ' .. Error "'||SQLERRM||'" encountered when launching validation processes.';
                RAISE EX_VAL_CP_CALL;
            END;

            --------------------------------------------------------------------
            -- Getting Total number of POs which failed pre-processor validations
            --------------------------------------------------------------------
            SELECT  COUNT(1)
            INTO    ln_val_fail_count
            FROM    xx_po_headers_stage
            WHERE   status_code = 'FAILED VALIDATIONS' -- Changed from 'ERROR' by Remya, V1.4
            AND     request_id  IN (SELECT request_id
                                    FROM   fnd_concurrent_requests
                                    WHERE  parent_request_id = gn_request_id);

            write_log(0,' .. '||ln_val_fail_count||' Header records failed validations');

            write_log(0,'--------------------------------------');

            ------------------------------------------------------------------
            -- Assigning batch Ids to all the records in the interface table 
            ------------------------------------------------------------------
            BEGIN
                write_log(0,' -- Calling Procedure assign_batch_id with p_batch_sz :'||p_batch_size);

                assign_batch_id(p_batch_sz => p_batch_size);

            EXCEPTION
            WHEN OTHERS THEN
                write_log(1,' .. Error "'||SQLERRM||'" while Assigning batch ids to validated records in interface table.');
            END;

            write_log(0,'--------------------------------------');


            -----------------------------------------------
            -- Calling the Import Standard Purchase Order 
            -- Concurrent Program for each of the batches 
            -----------------------------------------------
            BEGIN
                write_log(0,' -- Calling Procedure call_std_import ');

                call_std_import;-- Commented out parameter '(p_batch_id => NULL);' by Remya, V1.4
                
                
                -- Updating successfully processed records with status_code 'PASSED PDOI' --
                -- Added by Remya, V1.4
                For x in (SELECT   SUBSTR(vendor_order_num,7) hdr
                                               FROM     xx_po_headers_stage  XH 
                                                       ,po_headers           PH 
                                               WHERE    PH.vendor_order_num = ('POROQ-'||XH.header_sequence_id)
                                               AND      XH.status_code = 'PASSED VALIDATIONS')
                                               loop
                fnd_file.put_line(fnd_file.log,'Hdr sequence id: '|| x.hdr);
                end loop;

                UPDATE  xx_po_headers_stage XPHS
                SET     XPHS.status_code        ='PASSED PDOI'
                       ,XPHS.error_message      = NULL
                       ,XPHS.last_update_date   = g_date
                       ,XPHS.last_updated_by    = g_user_id
                       ,XPHS.request_id         = gn_request_id
                WHERE   header_sequence_id IN (SELECT   SUBSTR(vendor_order_num,7)
                                               FROM     xx_po_headers_stage  XH 
                                                       ,po_headers           PH 
                                               WHERE    PH.vendor_order_num = ('POROQ-'||XH.header_sequence_id)
                                               AND      XH.status_code = 'PASSED VALIDATIONS');
                 
                 write_log(0,' # of Records updated to status PASSED PDOI '||SQL%ROWCOUNT);
                 COMMIT;
                 
            EXCEPTION
            WHEN OTHERS THEN

                lc_error_message := ' .. Error "'||SQLERRM||'" encountered while invoking Standard Import Program';
                RAISE EX_STD_IMPORT;

            END;


            write_log(0,' ');
            write_log(0,'--------------------------------------');
            -------------------
            -- Post Processor
            -------------------
            --------------------------------------
            -- Updating PO Lines with quotation--
            --------------------------------------
            write_log(0,' -- Calling Procedure update_po_quot ');

            update_po_quot(x_err => lc_upd_quot_err);

            write_log(0,'--------------------------------------');
            
            -----------------------------------------------------
            -- Creating Allocations for successfully created POs 
            -----------------------------------------------------
            write_log(0,' -- Calling Procedure create_alloc ');

            create_alloc(x_count => ln_alloc_hdr_count
                        ,x_err   => lc_alloc_err);

            write_log(0,'--------------------------------------');

            -------------------------------------------------------------------
            -- Getting Total number of POs failed EBS standard API validations 
            -------------------------------------------------------------------
            SELECT  COUNT(*)
            INTO    ln_ebs_fail_count
            FROM    po_headers_interface    PHI
                   ,xx_po_headers_stage     XPHS
            WHERE   PHI.process_code        = 'REJECTED'
            AND     PHI.interface_header_id = XPHS.header_sequence_id
            AND     XPHS.request_id         = gn_request_id
            AND     PHI.request_id          = XPHS.request_id;
            write_log(0,' .. '||ln_ebs_fail_count||' POs failed EBS standard API validations ');

            ---------------------------------------------------------------
            -- Getting Total number of Incomplete EBS standard POs created 
            ---------------------------------------------------------------
            SELECT  COUNT(*)
            INTO    ln_incomplete_po_count
            FROM    po_headers_interface    PHI
                   ,xx_po_headers_stage     XPHS
            WHERE   PHI.process_code         = 'ACCEPTED'
            AND     PHI.approval_status      = 'INCOMPLETE'
            AND     PHI.interface_header_id  = XPHS.header_sequence_id
            AND     XPHS.request_id          = gn_request_id
            AND     PHI.request_id           = XPHS.request_id;
            write_log(0,' .. '||ln_incomplete_po_count||' Incomplete POs were created.');

            ---------------------------------------------------------------
            -- Getting Total number of Approved EBS standard POs created --
            ---------------------------------------------------------------
            SELECT  COUNT(*)
            INTO    ln_approved_po_count
            FROM    po_headers_interface    PHI
                   ,xx_po_headers_stage     XPHS
            WHERE   PHI.process_code        = 'ACCEPTED'
            AND     PHI.approval_status     = 'APPROVED'
            AND     PHI.interface_header_id = XPHS.header_sequence_id
            AND     XPHS.request_id         = gn_request_id -- Added by Remya, V1.4
            AND     PHI.request_id          = XPHS.request_id;
            write_log(0,' .. '||ln_approved_po_count||' Approved POs were created.');
            write_log(0,'--------------------------------------');


            write_out(' ');
            write_out('------------------------------------------------------------------------------');
            write_out('                           ------------------------');
            write_out('                            PO Creation Summary  ');
            write_out('                           ------------------------');
            write_out('------------------------------------------------------------------------------');
            write_out(' ');
--            write_out('Total number of PO records processed:                    '||ln_tot_hdrs);-- Commented out by Remya, V1.4
            write_out('Total number of POs to be created:                       '||ln_tot_hdrs);-- Added by Remya, V1.4
            write_out('Total number of Incomplete EBS standard POs created:     '||ln_incomplete_po_count);
            write_out('Total number of Approved EBS standard POs created:       '||ln_approved_po_count);
            write_out('Total number of POs failed pre-processor validations:    '||ln_val_fail_count);
            write_out('Total number of POs failed EBS standard API validations: '||ln_ebs_fail_count);
            write_out('Total number of Allocation headers created:              '||ln_alloc_hdr_count);
            write_out(' ');


            ------------------------------------------------------------------
            -- Displaying all the errors in the output log of the main program
            ------------------------------------------------------------------
            write_log(0, ' ');
            write_log(0,' -- Getting Summary of Errors for output log -- ');

            write_out(' ');
            write_out(' -----------------------------------------------------------------');
            write_out('  Error Messages from Pre-Processor validations                   ');
            write_out(' -----------------------------------------------------------------');
            write_out(' ');
            write_out(' HEADER SEQUENCE ID   LINE NUMBER   ERROR MESSAGE                 ');
            write_out(' ------------------   -----------   ------------------------------');

            FOR rec_pp_err_msg IN lcu_pp_err_msg
            LOOP

                write_out(' '||RPAD(rec_pp_err_msg.header_sequence_id,21,' ')||RPAD(NVL(TO_CHAR(rec_pp_err_msg.line_number),'-'),14,' ')||rec_pp_err_msg.error_message);
            END LOOP;

            write_out(' ');
            write_out(' -----------------------------------------------------------------');
            write_out(' Error Messages from Standard API validations                     ');
            write_out(' -----------------------------------------------------------------');
            write_out(' ');
            write_out(' INTERFACE HEADER ID   LINE NUMBER   ERROR_MESSAGE                 ');
            write_out(' -------------------   -----------   -----------------------------');

            write_log(0,'--------------------------------------');
            write_log(0,' -- Updating Staging Tables with Standard API errors --');

            FOR rec_api_err_msg IN lcu_api_err_msg
            LOOP
                write_out(' '||RPAD(rec_api_err_msg.interface_header_id,22,' ')||RPAD(NVL(TO_CHAR(rec_api_err_msg.line_num),'-'),14,' ')||rec_api_err_msg.error_message);

                --------------------------------------------------
                -- Updating Staging Table with Standard API errors
                --------------------------------------------------
                update_stg(p_status         => 'FAILED PDOI'
                          ,p_msg            => rec_api_err_msg.error_message
                          ,p_hdr_seq_id     => rec_api_err_msg.interface_header_id
                          ,p_line_seq_id    => rec_api_err_msg.interface_line_id);
            END LOOP;
            write_log(0,'--------------------------------------');
            
            -------------------------------------------------------------------------------------
            --Deleting data from staging tables for successfully created POs after profile time
            -------------------------------------------------------------------------------------
                write_log(0,' -- Calling Procedure delete_data'); 
                delete_data;

            
            write_log(0,'--------------------------------------');
            
            write_log(0,'----------------------------------------------------------------------------');


            IF (ln_val_fail_count <> 0 OR ln_ebs_fail_count <> 0
                OR lc_upd_quot_err = 'E' OR lc_alloc_err = 'E') THEN -- Added by Remya, V1.4
                x_retcode := 1; -- Warning
            ELSE
                x_retcode := 0;
            END IF;

        EXCEPTION
        WHEN EX_NO_HDRS THEN
            write_log(1,'No data to be processed');
            write_out('                     *** NO DATA FOUND ***');
            x_retcode := 1;
        
        WHEN EX_VAL_ASSIGN THEN
            write_log(1,lc_error_message);
            x_retcode := 1;

        WHEN EX_VAL_CP_CALL THEN
           write_log(1,lc_error_message);
           x_retcode := 1;

        WHEN EX_STD_IMPORT THEN
            write_log(1,lc_error_message);
            x_retcode := 1;

        WHEN OTHERS THEN
            write_log(1,' .. Error "'||SQLERRM||'"encountered by Preprocessor');
            x_retcode := 1;
        END;
    
    write_out('------------------------------------------------------------------------------');
    write_out(' ');
    write_out('                     *** End of Report - Pre-Processor ***');
    write_out(' ');
    write_out(' ');
    write_out('------------------------------------------------------------------------------');

    EXCEPTION
    
    WHEN OTHERS THEN
        write_log(1,'Unexpected Error "'||SQLERRM||'" encountered by Preprocessor');
        x_retcode := 1;
    END Preproc_Main;
            

      -- +============================================================================+
      -- |                                                                            |
      -- |                                                                            |
      -- |PROCEDURE   : Validate_Main                                                 |
      -- |                                                                            |
      -- |DESCRIPTION : This procedure will be used to read the records from the      |
      -- |              staging tables, validate them and populate the PO interface   |
      -- |              table with validated records from Custom staging tables.      |
      -- |                                                                            |
      -- |                                                                            |
      -- |                                                                            |
      -- |PARAMETERS  :                                                               |
      -- |                                                                            |
      -- |    NAME             Mode TYPE        DESCRIPTION                           |
      -- |-------------------  ---- --------    -----------------------------         |
      -- |x_v_errbuf            OUT VARCHAR2    To pass message to concurrent manager |
      -- |x_v_retcode           OUT PLS_INTEGER To pass status to concurrent manager  |
      -- |p_validate_thread_id  IN  VARCHAR2    Validation thread id                  |
      -- |p_debug               IN  VARCHAR2    Determines if debug messages should   |
      -- |                                      be printed.                           |
      -- +============================================================================+


    PROCEDURE Validate_Main(
                             x_v_errbuf               OUT VARCHAR2
                            ,x_v_retcode              OUT PLS_INTEGER
                            ,p_validate_thread_id     IN  PLS_INTEGER
                            ,p_debug                  IN  VARCHAR2
                            )

    IS

    -- =======================================
    -- Cursor to pick records from the staging
    -- table for a given validation thread id
    -- for validations.
    -- ======================================
    CURSOR  lcu_rec_thread(p_vld_thread_id  IN  PLS_INTEGER)
    IS
    SELECT  header_sequence_id
           ,legacy_supplier_no
           ,legacy_location_id
           ,creation_date
    FROM    xx_po_headers_stage
    WHERE   validate_thread_id = p_vld_thread_id
    AND     status_code <> 'FAILED VALIDATIONS'-- Changed from 'ERROR', Remya, V1.4
    ORDER BY header_sequence_id;


    -- ============================================
    -- Cursor to pick all the PO line records for 
    -- a given header sequence id
    -- ===========================================
    CURSOR  lcu_rec_po_line(p_header_sequence_id    IN  PLS_INTEGER)
    IS
    SELECT  *
    FROM    xx_po_lines_stage   XPLS
    WHERE   XPLS.header_sequence_id = p_header_sequence_id
    ORDER BY line_sequence_id;


    -- ====================================================
    -- Cursor to select item master details for given item
    -- ====================================================
    CURSOR  lcu_item_dtl(p_item IN VARCHAR2,p_organization_id IN NUMBER) ---- Modified by Remya, V1.7
    IS
    SELECT  MSI.inventory_item_id
           --,MSI.primary_uom_code    -- Commented out by Remya, V1.7
    FROM    mtl_system_items    MSI 
          -- ,mtl_parameters      MP  -- Commented out by Remya, V1.7
    WHERE  MSI.segment1                = p_item
    AND    MSI.organization_id         = p_organization_id; -- Added by Remya, V1.7
    -- AND     MP.organization_id          = MSI.organization_id -- Commented out by Remya, V1.7
    -- AND     MP.master_organization_id   = MSI.organization_id -- Commented out by Remya, V1.7
    

    
    -- =============================
    -- Local Variable Declaration
    -- =============================
    ln_vendor_id                    PLS_INTEGER;
    ln_vendor_site_id               PLS_INTEGER;
    ln_org_id                       PLS_INTEGER;
    ln_organization_id              PLS_INTEGER;
    ln_location_id                  PLS_INTEGER;
    ln_sob_id                       PLS_INTEGER;
    ln_employee_id                  PLS_INTEGER;
 --   lc_promise_date                 VARCHAR2(50); -- Removed by Remya, V1.3
    ld_promise_date                 DATE;           -- Added by Remya, V1.3
    lc_err                          VARCHAR2(3);
    ln_quot_hdr_id                  PLS_INTEGER;
    ln_quot_line_id                 PLS_INTEGER;
    ln_quot_line_loc_id             PLS_INTEGER;
    lc_rate_type                    VARCHAR2(20);
    ld_rate_date                    DATE;
    lc_active_quot_flag             VARCHAR2(1);
    ln_val_fail_count               PLS_INTEGER := 0;
    ln_tot_validate_count           PLS_INTEGER := 0;
    ln_item_id                      PLS_INTEGER;
    lc_error_message                VARCHAR2(2000);
    ln_parent_req_id                PLS_INTEGER;
    ln_intfc_insert_count           PLS_INTEGER;
    lc_attribute8                   po_vendor_sites_all.attribute8%TYPE;
    lc_po_type                      xx_po_global_indicator.global_indicator_name%TYPE;
    lc_approval                     xx_po_headers_stage.approval_status%TYPE ;
    lc_func_curr_code               gl_sets_of_books.currency_code%TYPE;
    lc_currency_code                po_headers_all.currency_code%TYPE;
    lc_total_landed_price           po_line_locations_all.attribute6%TYPE; -- Modified by Remya, V1.7
    lc_quot_unit_price              po_line_locations_all.price_override%TYPE;
--    lc_quot_uom                     mtl_units_of_measure.uom_code%TYPE;
    lc_quot_uom                     xx_po_lines_stage.uom_code%TYPE := NULL;
--    lc_primary_uom_code             mtl_system_items.primary_uom_code%TYPE;  -- Commented out by Remya, V1.7
    lc_buying_agents_vsid           xx_po_vendor_sites_kff_v.buying_agent_site_id%TYPE;
    lc_manufacturers_vsid           xx_po_vendor_sites_kff_v.manufacturing_site_id%TYPE;
    lc_freight_forwarders_vsid      xx_po_vendor_sites_kff_v.freight_forwarder_site_id%TYPE;
    lc_ship_from_port               xx_po_vendor_sites_kff_v.ship_from_port_id%TYPE;
    lc_status                       VARCHAR2(50);  -- Added by Remya, V1.4


    
    EX_INVALID_LOCATION             EXCEPTION;
    EX_INVALID_SUPPLIER             EXCEPTION;
    EX_INVALID_ITEM                 EXCEPTION;
    EX_NO_QUOTATION                 EXCEPTION;

    BEGIN

        write_out('==============================================================================');
        write_out(' Office Depot                                Date : '||TO_CHAR(SYSDATE,'dd-Mon-yy hh24:mi:ss'));
        write_out('                     OD: PO ROQ Preprocessor Validate Program                 ');
        write_out(' ');
        write_out('==============================================================================');

        gc_debug_flag          := p_debug;

        write_log(0,'--Valdiation Begins for thread id '||p_validate_thread_id||'--');
        write_log(0,' ');
        
        -- ====================================== --
        --     Validating Number of PO Lines      --
        -- ====================================== --
        BEGIN
            write_log(0,' -- Calling procedure val_po_lines with p_thread_id :'||p_validate_thread_id);

            val_po_lines(p_thread_id => p_validate_thread_id
                        );
            
        EXCEPTION
        WHEN OTHERS THEN
            write_log(1,' .. Error "'||SQLERRM||'" while Validating Number of PO lines for thread id '||p_validate_thread_id);
        END;
        
        write_log(0,' ----------------------------------------------------------------');

        FOR rec_thread IN lcu_rec_thread(p_validate_thread_id)
        LOOP
        
        BEGIN
            write_log(0,' ');
            write_log(0,'--------------------------------------------------------');
            write_log(0,' * Validations for record of header seq id :'||rec_thread.header_sequence_id);
            write_log(0,'--------------------------------------------------------');

            ln_vendor_id                := NULL;
            ln_vendor_site_id           := NULL;
            ln_org_id                   := NULL;
            lc_attribute8               := NULL;
            ln_organization_id          := NULL;
            ln_location_id              := NULL;
            ln_sob_id                   := NULL;
            lc_buying_agents_vsid       := NULL;
            lc_manufacturers_vsid       := NULL;
            lc_freight_forwarders_vsid  := NULL;
            lc_ship_from_port           := NULL;
            ln_employee_id              := NULL;
            lc_active_quot_flag         := 'Y';
            

            -- ====================================== --
            --   Transform Legacy data to EBS format  --
            -- ====================================== --

            write_log(0,' -- Getting EBS data for legacy supplier number ');
            
            write_log(0,' .. Calling procedure get_ebs_supp_data with Legacy_supplier_no :'||rec_thread.legacy_supplier_no);

            lc_err := NULL;

            get_ebs_supp_data
                            (p_lgcy_sup_no       =>rec_thread.legacy_supplier_no
                            ,x_vendor_id         =>ln_vendor_id
                            ,x_vendor_site_id    =>ln_vendor_site_id
                            ,x_org_id            =>ln_org_id
                            ,x_attribute8        =>lc_attribute8
                            ,x_sob_id            =>ln_sob_id
                            ,x_err               =>lc_err);
                            
            IF lc_err = 'E' THEN
            
                RAISE EX_INVALID_SUPPLIER;
                
            END IF;

            
            write_log(0,' -- Getting EBS legacy location id '||rec_thread.legacy_location_id);
            
            lc_err := NULL;
            write_log(0,' .. Calling procedure get_ebs_loc_data with p_lgcy_loc_id :'||rec_thread.legacy_location_id);
            
            get_ebs_loc_data
                            (p_lgcy_loc_id       =>rec_thread.legacy_location_id
                            ,x_organization_id   =>ln_organization_id
                            ,x_location_id       =>ln_location_id
                            ,x_err               =>lc_err);
                            
            IF lc_err = 'E' THEN
            
                RAISE EX_INVALID_LOCATION;
                
            END IF;
            
            write_log(0,'--------------------------------------------------------');

            -- ====================================== --
            --    Determining Buyer and OD PO Type    --
            -- ====================================== --
            
            BEGIN
                write_log(0,' -- Calling procedure get_buyer_potype with p_header_seq_id :'||rec_thread.header_sequence_id );
                write_log(0,' .. , p_ven_site_id: '||ln_vendor_site_id||', p_loc_id: '||ln_location_id||', p_attrib8 :'||lc_attribute8||' Organization: '||ln_organization_id);
                
                get_buyer_potype(p_header_seq_id  =>rec_thread.header_sequence_id 
                                ,p_ven_site_id    =>ln_vendor_site_id
                                ,p_loc_id         =>ln_location_id
                                ,p_org_id         =>ln_org_id   -- Added by Remya, V1.1, 02-Aug-07
                                ,p_attrib8        =>lc_attribute8
                                ,x_emp_id         =>ln_employee_id
                                ,x_po_type        =>lc_po_type                
                                );
            EXCEPTION
            WHEN OTHERS THEN
                write_log(1,' .. Error while Determining Buyer and PO type for record :'||rec_thread.header_sequence_id );
            END;
            
            IF UPPER(lc_po_type) = 'TRADE-IMPORT' THEN
                BEGIN
            
                    SELECT   buying_agent_site_id 
                            ,manufacturing_site_id 
                            ,freight_forwarder_site_id 
                            ,ship_from_port_id 
                    INTO    lc_buying_agents_vsid
                           ,lc_manufacturers_vsid
                           ,lc_freight_forwarders_vsid
                           ,lc_ship_from_port
                    FROM    xx_po_vendor_sites_kff_v
                    WHERE   vendor_site_id = ln_vendor_site_id;

                EXCEPTION
               
               WHEN OTHERS THEN
                  write_log(0,' .. Error "'||SQLERRM||'" while deriving buying agents, manufacturers and freight forwarders vendor site id and ship from port');
               END;
               
           END IF;   
            write_log(0,'--------------------------------------------------------');

            -- ============================================= --
            --     Deriving Promise Date and Unit Price      --
            --                for each PO line               --
            -- ============================================= --
            write_log(0,' -- Deriving Promise Date and Unit Price for each PO line --');
            write_log(0,' ');

            FOR rec_po_line IN lcu_rec_po_line(rec_thread.header_sequence_id)
            LOOP
                BEGIN
                
                    ln_item_id              := NULL;
                   -- lc_primary_uom_code     := NULL; -- Removed by Remya, V1.7
                   -- lc_promise_date         := NULL; -- Removed by Remya, V1.3
                    ld_promise_date         := NULL;   -- Added by Remya, V1.3
                    lc_func_curr_code       := NULL;
                    lc_quot_uom             := NULL;
                    ln_quot_hdr_id          := NULL;
                    ln_quot_line_id         := NULL;
                    lc_currency_code        := NULL;
                    lc_total_landed_price   := NULL;
                    ln_quot_line_loc_id     := NULL;
                    lc_quot_unit_price      := NULL;
                    lc_error_message        := NULL;
                    lc_rate_type            := NULL;
                    ld_rate_date            := NULL;
                    
                    write_log(0,' --- For line number '||rec_po_line.line_number);
                    write_log(0,' ... Getting Item details for the SKU '||rec_po_line.item);

                    OPEN lcu_item_dtl(rec_po_line.item, ln_organization_id); -- Modified by Remya, V1.7
                    FETCH lcu_item_dtl INTO ln_item_id; -- Removed ',lc_primary_uom_code' , Remya, V1.7;

                    IF lcu_item_dtl%NOTFOUND THEN 

                        RAISE EX_INVALID_ITEM;-- stop processing this record here as header will error out when one line has no active quot.

                    END IF;

                    CLOSE lcu_item_dtl;

                    ----------------------------
                    -- Deriving Promise Date  --
                    ----------------------------
                    BEGIN
                        lc_err := NULL; -- Added by Remya, V1.4
                        
                        write_log(0,' ... Calling procedure get_prms_dt');
                        
                        get_prms_dt(
                               p_item_id        =>ln_item_id
                              ,p_ven_site_id    =>ln_vendor_site_id
                              ,p_po_type        =>lc_po_type
                              ,p_order_date     =>TO_CHAR(NVL(rec_po_line.creation_date, SYSDATE))
                              ,p_promise_date   =>TO_CHAR(rec_po_line.legacy_promise_date)
                              ,p_loc_id         =>ln_location_id
                              ,p_organiz_id     =>ln_organization_id
                              ,x_prms_dt        =>ld_promise_date
                              ,x_err            =>lc_err); -- Added by Remya, V1.4
                              
                        IF lc_err IS NOT NULL THEN -- Added by Remya, V1.4
                            write_log(0,' ... '||lc_err);
                        
                            update_stg(p_status         => 'FAILED VALIDATIONS' -- Added by Remya, V1.4
                                      ,p_msg            => lc_err
                                      ,p_hdr_seq_id     => rec_thread.header_sequence_id
                                      ,p_line_seq_id    => rec_po_line.line_sequence_id);
                        END IF;
                   
                    EXCEPTION
                    WHEN OTHERS THEN
                        lc_error_message := 'Error "'||SQLERRM||'" while extracting Promise Date ';
                        write_log(0,' ... '||lc_error_message);

                        update_stg(p_status         => 'FAILED VALIDATIONS' -- Added by Remya, V1.4
                                  ,p_msg            => lc_error_message
                                  ,p_hdr_seq_id     => rec_thread.header_sequence_id
                                  ,p_line_seq_id    => rec_po_line.line_sequence_id);
                    END;
                    
                    write_log(0,' ... Promise Date derived is :'||ld_promise_date);

                    -------------------------------------------------
                    --Assigning Unit Price from catalog quotation --
                    -------------------------------------------------
                    lc_err := NULL;
                    write_log(0,' --- Calling procedure get_quot_dtls');
                    
                    get_quot_dtls(
                               p_ven_site_id     => ln_vendor_site_id
                              ,p_item_id         => ln_item_id
                              ,p_sob_id          => ln_sob_id
                              ,p_qty             => rec_po_line.quantity
                              ,p_organization_id => ln_organization_id
                              ,p_location_id     => ln_location_id
                              ,x_quot_hdr_id     => ln_quot_hdr_id
                              ,x_quot_line_id    => ln_quot_line_id
                              ,x_line_loc_id     => ln_quot_line_loc_id
                              ,x_currency_code   => lc_currency_code
                              ,x_func_curr_code  => lc_func_curr_code
                              ,x_quot_uom        => lc_quot_uom
                              ,x_quot_unit_price => lc_quot_unit_price
                              ,x_tot_land_price  => lc_total_landed_price
                              ,x_err             => lc_err);
                    
                    IF  lc_err = 'E' THEN
                        RAISE EX_NO_QUOTATION;
                    END IF;

                    IF  lc_currency_code <> lc_func_curr_code THEN

                        write_log(0,' ... When functional currency code and currency code are not the same');
                        --lc_rate_type           := 'Corporate'; -- Commented by Remya, V1.4 
                        -- Added by Remya , V1.4
                        BEGIN
                        
                            SELECT default_rate_type
                            INTO   lc_rate_type
                            FROM   po_system_parameters_all
                            WHERE  org_id = ln_org_id; 
                            
                        EXCEPTION
                        WHEN OTHERS THEN
                            write_log(0,' ... Error '||SQLERRM||'while deriving rate type from po_system_parameters_all');
                            lc_rate_type := NULL;
                        END;
                        -- End of additions by Remya, V1.4
                        
                        ld_rate_date           := g_date;

                        write_log(0,' ... Setting rate type '||lc_rate_type||' and rate date for header sequence id '||rec_thread.header_sequence_id);
                    END IF;
                
                EXCEPTION
                
                WHEN EX_INVALID_ITEM THEN

                    CLOSE lcu_item_dtl;

                    FND_MESSAGE.SET_NAME('XXPTP','XX_PO_60005_NO_SKU'); 
                    FND_MESSAGE.SET_TOKEN('SKU',rec_po_line.item);
                    lc_error_message    := FND_MESSAGE.GET;
                    write_log(0,' ... '||lc_error_message);

                    update_stg(p_status     => 'FAILED VALIDATIONS' -- Added by Remya, V1.4
                              ,p_msg         => lc_error_message
                              ,p_hdr_seq_id  => rec_thread.header_sequence_id
                              ,p_line_seq_id => rec_po_line.line_sequence_id);

                    lc_active_quot_flag := 'N'; -- One of the PO lines doesnt have an active quote since item doesnt exist.
                    write_log(0,' ...* No further validations for line '||rec_po_line.line_number||' of header seq id '||rec_thread.header_sequence_id);

               WHEN EX_NO_QUOTATION THEN
               
                    FND_MESSAGE.SET_NAME('XXPTP','XX_PO_60003_NO_ACTIVE_QUOTE'); 
                    FND_MESSAGE.SET_TOKEN('SKU',rec_po_line.item);
                    FND_MESSAGE.SET_TOKEN('SUPPLIER',ln_vendor_id);
                    FND_MESSAGE.SET_TOKEN('SITE',ln_vendor_site_id);
                    lc_error_message    := FND_MESSAGE.GET;
                    write_log(0,' ... '||lc_error_message);

                    update_stg(p_status       => 'FAILED VALIDATIONS' -- Added by Remya, V1.4
                              ,p_msg          => lc_error_message
                              ,p_hdr_seq_id   => rec_thread.header_sequence_id
                              ,p_line_seq_id  => rec_po_line.line_sequence_id);
                               
                    lc_active_quot_flag := 'N'; -- One of the PO lines doesnt have an active quote.
                    write_log(0,' ...* No further validations for line '||rec_po_line.line_number||' of header seq id '||rec_thread.header_sequence_id);
                    
                WHEN OTHERS THEN

                    lc_error_message := ('Error while processing line '||rec_po_line.line_number||' of header seq id '||rec_thread.header_sequence_id||' is :'||SQLERRM);
                    write_log(0,' ... '||lc_error_message);

                    update_stg(p_status      => 'FAILED VALIDATIONS' -- Added by Remya, V1.4
                              ,p_msg         => lc_error_message
                              ,p_hdr_seq_id  => rec_thread.header_sequence_id
                              ,p_line_seq_id => rec_po_line.line_sequence_id);
                               
                    write_log(0,' ...* No further validations for line '||rec_po_line.line_number||' of header seq id '||rec_thread.header_sequence_id);

                END;
            
                write_log(0,' ... Updating staging tables with Promise Date, Unit Price and Quotation details');
                
                UPDATE  xx_po_lines_stage  
                SET     ebs_promise_date        = ld_promise_date -- Changed from 'TO_DATE(lc_promise_date,'DD-MON-YYYY HH24:MI:SS')' by Remya, V1.3 
                       ,item_id                 = ln_item_id
                       ,unit_price              = lc_quot_unit_price
                       ,uom_code                = lc_quot_uom
                       ,from_header_id          = ln_quot_hdr_id
                       ,from_line_id            = ln_quot_line_id
                       ,from_line_location_id   = ln_quot_line_loc_id
                       ,total_landed_price      = lc_total_landed_price
                       ,ship_to_organization_id = ln_organization_id
                       ,ebs_location_id         = ln_location_id
                       ,attribute_category      = lc_po_type
                       ,last_update_date        = g_date
                       ,last_updated_by         = g_user_id
                WHERE   header_sequence_id      = rec_po_line.header_sequence_id
                AND     line_sequence_id        = rec_po_line.line_sequence_id;

                -----------------------------------
                -- Commented out by Remya, V1.7
                -----------------------------------
                /*
                UPDATE  xx_po_headers_stage
                SET     currency_code       = NVL(lc_currency_code ,lc_func_curr_code)
                       ,rate_type           = lc_rate_type
                       ,rate_date           = ld_rate_date
                       ,last_update_date    = g_date
                       ,last_updated_by     = g_user_id
                WHERE   header_sequence_id  = rec_thread.header_sequence_id;
                */
                ---------------------------------
                -- End of changes, Remya, V1.7
                ---------------------------------
                write_log(0,' --- Finished line number '||rec_po_line.line_number);
                write_log(0,' ----------------------------- ');
            
            END LOOP;
            
            COMMIT;
            write_log(0,'--------------------------------------------------------');
            
            -- ============================== --
            --  Validating Vendor Minimum     --
            -- ============================== --
            write_log(0,' -- Validating Vendor Minimum -- ');
            lc_status := NULL;
            IF  lc_active_quot_flag <> 'N' THEN -- (No validation if any of the PO lines didnt have an active quot)
                
                write_log(0,' .. All the lines have active quotations hence validating vendor minimum.');    
                
                BEGIN
                
                    val_ven_min(p_hdr_seq_id  =>rec_thread.header_sequence_id
                               ,p_po_curr     =>NVL(lc_currency_code, lc_func_curr_code)
                               ,p_ven_site_id =>ln_vendor_site_id
                               ,x_status      =>lc_approval);
                    lc_status := 'PASSED VALIDATIONS'; -- Added by Remya, V1.4 

                EXCEPTION
                WHEN OTHERS THEN
                    write_log(1,' .. Encountered Error "'||SQLERRM||'" while validating Vendor Minimum for record '||rec_thread.header_sequence_id );
                    lc_status := 'FAILED VALIDATIONS'; -- Added by Remya, V1.4 

                END;
                
            ELSE
                
                write_log(0,' .. Did not validate vendor minimum as one or more PO lines didnt have an active quotation');
                lc_status := 'FAILED VALIDATIONS'; -- Added by Remya, V1.4 
            END IF;
                
            write_log(0,' .. Updating stg tables with EBS data, buyer, PO type for header :'||rec_thread.header_sequence_id);

            UPDATE  xx_po_headers_stage
            SET     vendor_id           = ln_vendor_id
                   ,vendor_site_id      = ln_vendor_site_id
                   ,org_id              = ln_org_id
                   ,set_of_books_id     = ln_sob_id
                   ,ship_to_location_id = ln_location_id 
                   ,attribute_category  = lc_po_type
                   ,agent_id            = ln_employee_id
                   ,approval_status     = lc_approval
                   ,attribute6          = lc_buying_agents_vsid
                   ,attribute7          = lc_manufacturers_vsid
                   ,attribute8          = lc_freight_forwarders_vsid
                   ,attribute9          = lc_ship_from_port
                   ,last_update_date    = g_date
                   ,last_updated_by     = g_user_id
                   ,status_code         = lc_status                 -- Added by Remya, V1.4 
                   ,currency_code       = NVL(lc_currency_code ,lc_func_curr_code)  -- Added by Remya, V1.7 
                   ,rate_type           = lc_rate_type              -- Added by Remya, V1.7 
                   ,rate_date           = ld_rate_date              -- Added by Remya, V1.7 
            WHERE   header_sequence_id  = rec_thread.header_sequence_id;

            -- Commented out by Remya, V1.7
            /*
            UPDATE  xx_po_lines_stage  
            SET     ship_to_organization_id = ln_organization_id
                   ,ebs_location_id         = ln_location_id
                   ,attribute_category      = lc_po_type
                   ,last_update_date        = SYSDATE
                   ,last_updated_by         = g_user_id
            WHERE   header_sequence_id      = rec_thread.header_sequence_id;
            */  
            

            write_log(0,'--------------------------------------------------------');

        EXCEPTION

        WHEN EX_INVALID_SUPPLIER THEN --  Stop processing this record here
            
            FND_MESSAGE.SET_NAME('XXPTP','XX_PO_60001_SUPPLIER_INVALID'); 
            FND_MESSAGE.SET_TOKEN('LEGACY_NUMBER',rec_thread.legacy_supplier_no);
            lc_error_message    := FND_MESSAGE.get;
            write_log(0,' .. '||lc_error_message);

            update_stg(p_status     => 'FAILED VALIDATIONS' -- Added by Remya, V1.4
                      ,p_msg        => lc_error_message
                      ,p_hdr_seq_id => rec_thread.header_sequence_id);


            write_log(0,'--------------------------------------------------------');
            write_log(0,' * No further validations for record of header seq id '||rec_thread.header_sequence_id);
            write_log(0,' ');

        WHEN EX_INVALID_LOCATION THEN -- Stop processing this record here 
            
            FND_MESSAGE.SET_NAME('XXPTP','XX_PO_60002_LOCATION_INVALID'); 
            FND_MESSAGE.SET_TOKEN('LEGACY_LOCATION_ID',rec_thread.legacy_location_id);
            lc_error_message    := FND_MESSAGE.get;
            write_log(0,' .. '||lc_error_message);

            update_stg(p_status     => 'FAILED VALIDATIONS' -- Added by Remya, V1.4
                      ,p_msg        => lc_error_message
                      ,p_hdr_seq_id => rec_thread.header_sequence_id
                      );

            
            write_log(0,'--------------------------------------------------------');
            write_log(0,' * No further validations for record of header seq id '||rec_thread.header_sequence_id);
            write_log(0,' ');

        WHEN OTHERS THEN
        
            lc_error_message := 'Error while processing record of header sequence id: '||rec_thread.header_sequence_id||' is '||SQLERRM;
            write_log(0,' .. '||lc_error_message);
            
            update_stg(p_status     => 'FAILED VALIDATIONS' -- Added by Remya, V1.4
                      ,p_msg        => lc_error_message
                      ,p_hdr_seq_id => rec_thread.header_sequence_id
                      );

            write_log(0,'--------------------------------------------------------');
            write_log(0,' * No further validations for record of header seq id '||rec_thread.header_sequence_id);
            write_log(0,' ');

        END;
            
        write_log(0,'--------------------------------------------------------');
        write_log(0,' * End of validations for record of header seq id '||rec_thread.header_sequence_id);
        write_log(0,'--------------------------------------------------------');
        write_log(0,' ');
            
        END LOOP;-- End of Validations.

        COMMIT;
        write_log(0,'--------------------------------------------------------');
        write_log(0,' -- End of all Validations -- ');
        write_log(0,'--------------------------------------------------------');


        -- ================================================ --
        --   Populating interface tables with valid data    --
        -- ================================================ --
        write_log(0,' .. Calling procedure populate_intf');
        populate_intf(p_thread_id   =>  p_validate_thread_id
                     ,x_count       =>  ln_intfc_insert_count);

        write_log(0,'--------------------------------------------------------');
        SELECT  COUNT(1)
        INTO    ln_tot_validate_count
        FROM    xx_po_headers_stage
        WHERE   validate_thread_id = p_validate_thread_id;

        write_log(0,'   '||ln_tot_validate_count||' records were validated in this thread');


        SELECT  COUNT(1)
        INTO    ln_val_fail_count
        FROM    xx_po_headers_stage
        WHERE   validate_thread_id = p_validate_thread_id
        AND     UPPER(status_code) = 'FAILED VALIDATIONS'; -- Changed from 'ERROR' by Remya, V1.4
        
        write_log(0,'   '||ln_val_fail_count||' records failed validations');
        write_log(0,'   '||ln_intfc_insert_count||' records were inserted into interface tables');
        write_log(0,'----------------------------------------------------------------------------');
        write_log(0,' ');
        
        SELECT  parent_request_id
        INTO    ln_parent_req_id
        FROM    FND_CONCURRENT_REQUESTS
        WHERE   request_id = gn_request_id;

        write_out(' ');
        write_out('Parent Concurrent Program Request Id :   '||ln_parent_req_id);
        write_out('Validation thread number :               '||p_validate_thread_id);
        write_out(' ');

        write_out('------------------------------------------------------------------------------');
        write_out(' ');
        write_out('-------------------------');
        write_out('   Validation Summary');
        write_out('-------------------------');
        write_out(' ');
        write_out('Total number of PO records validated in this thread:                         '||ln_tot_validate_count);
        write_out('Total number of PO records failed pre-processor validations in this thread:  '||ln_val_fail_count);
        write_out('Total number of PO records successfully inserted into interface tables:      '||ln_intfc_insert_count);
        write_out(' ');
        write_out('------------------------------------------------------------------------------');
        write_out(' ');
        write_out('        *** End of Report - Pre-Processor Validation Program ***');
        write_out(' ');
        write_out(' ');
        write_out('------------------------------------------------------------------------------');

    IF ln_tot_validate_count = 0 THEN
        x_v_retcode := 2; -- Error : None validated
    ELSIF ln_val_fail_count = 0 THEN
        x_v_retcode := 0; -- Success : None failed
    ELSE   
        x_v_retcode := 1; -- Warning : Some failed
    END IF;

    END Validate_Main;
    
    

END XX_PO_ROQ_PREPROC_PKG;
/
SHOW ERRORS;
EXIT ;

