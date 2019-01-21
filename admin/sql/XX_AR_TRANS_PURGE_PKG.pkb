CREATE OR REPLACE PACKAGE BODY apps.XX_AR_TRANS_PURGE_PKG IS
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                        Office Depot Organization                      |
-- +=======================================================================+
-- | Name       : XX_AR_TRANS_PURGE_PKG                                    |
-- |                                                                       |
-- | RICE#      : E2075_EBS_AR_Archive_Purge                               |
-- |                                                                       |
-- | Description: This package/RICE is used for purging AR delivered and   |
-- |              custom tables.  The follow                               |
-- |                                                                       |
-- |                                                                       |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version    Date         Author         Remarks                         |
-- |=========  ===========  =============  ================================|
-- |   1.0     14-DEC-2010  R.Aldridge     Initial Version - Defect 8950   |
-- |   2.0     16-MAR-2011  P.Sankaran     Defect 10610 - Fix start date   |
-- |                                       and cut-off date issues.        |
-- |   3.0     24-APR-2011  P.Sankaran     Change length of ARCHIVE_ID to  |
-- |                                       15 characters to accommodate    |
-- |                                       more than 99 threads.           |
-- +=======================================================================+

   /***********************
   ** GLOBAL VARIABLES   **
   ***********************/   

   -- Cursor and variables used to identify records to be purged
   CURSOR gcu_arch_trans(p_archive_id ar.ar_archive_header.archive_id%TYPE)
   IS
      SELECT AAH.transaction_class
            ,AAH.transaction_number
            ,AAH.transaction_id
            ,aah.rowid row_id
        FROM ar.ar_archive_header AAH
       WHERE AAH.archive_id = p_archive_id;
     
   TYPE g_arch_trans_tbl_type      IS TABLE OF gcu_arch_trans%ROWTYPE INDEX BY PLS_INTEGER;
   TYPE g_transaction_class_type   IS TABLE OF ar.ar_archive_header.transaction_class%TYPE  INDEX BY PLS_INTEGER;
   TYPE g_transaction_number_type  IS TABLE OF ar.ar_archive_header.transaction_number%TYPE INDEX BY PLS_INTEGER;
   TYPE g_transaction_id_type      IS TABLE OF ar.ar_archive_header.transaction_id%TYPE INDEX BY PLS_INTEGER;
   TYPE g_aah_rowid_type           IS TABLE of UROWID INDEX BY PLS_INTEGER;
   
   gt_arch_trans             g_arch_trans_tbl_type;
   gt_trans_class_i          g_transaction_class_type;
   gt_trans_num_i            g_transaction_number_type;   
   gt_trans_id_i             g_transaction_id_type;
   gt_aah_rowid              g_aah_rowid_type;
   gt_trans_class_r          g_transaction_class_type;
   gt_trans_num_r            g_transaction_number_type;   
   gt_trans_id_r             g_transaction_id_type;

   -- Variables used to track records fetched and deleted
   gn_total_fetched          NUMBER := 0;
   gn_total_deleted          NUMBER := 0;   
   gn_cogs_deleted_records   NUMBER := 0;
   gn_cogs_total_deleted     NUMBER := 0;
   gn_ar_deleted_records     NUMBER := 0;
   gn_ar_total_deleted       NUMBER := 0;
   gn_XACRE_deleted_records  NUMBER := 0;
   gn_XACRE_total_deleted    NUMBER := 0;
--   gn_XAREL_deleted_records  NUMBER := 0;
--   gn_XAREL_total_deleted    NUMBER := 0;
   gn_XIBCR_deleted_records  NUMBER := 0;
   gn_XIBCR_total_deleted    NUMBER := 0;
   gn_XAAH_inserted_records  NUMBER := 0;
   gn_XAAH_total_inserted    NUMBER := 0;
   gn_XAAH_deleted_records   NUMBER := 0;
   gn_XAAH_total_deleted     NUMBER := 0;

   -- Variables used for request ids and program information  
   gn_request_id             fnd_concurrent_requests.request_id%TYPE := NULL;
   gn_this_request_id        fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id;
   gc_program_name           fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
   gc_prog_shortname         fnd_concurrent_programs.concurrent_program_name%TYPE;
   gc_appl_short             fnd_application.application_short_name%TYPE;
   gc_child_error_cnt        NUMBER;

   -- Variables used for tracking duration and calculation TPS
   gd_start_time             DATE;
   gd_end_time               DATE;
   gn_duration               NUMBER := 0;
   gn_tps                    NUMBER := 0;

   -- Variables used for program errors
   gc_error_loc              VARCHAR2(2000) := NULL;   

   /***********************
   ** PRIVATE PROCEDURES **
   ***********************/
     
   -- +====================================================================+
   -- | Name       : PRINT_TIME_STAMP                                      |
   -- |                                                                    |
   -- | Description: This private procedure is used to print the time to   |
   -- |              the log                                               |
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE PRINT_TIME_STAMP
   IS
   BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')||chr(10));
   EXCEPTION   
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - PRINT_TIME_STAMP (WHEN OTHERS)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside PRINT_TIME_STAMP at '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside PRINT_TIME_STAMP at '||gc_error_loc);
   END PRINT_TIME_STAMP;
   
   -- +====================================================================+
   -- | Name       : PRINT_PROG_INFO                                       |
   -- |                                                                    |
   -- | Description: This procedure is used print program informaion to    |
   -- |              log file                                              |   
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE PRINT_PROG_INFO(parm1    IN  VARCHAR2 DEFAULT NULL
                            ,parm2    IN  VARCHAR2 DEFAULT NULL 
                            ,parm3    IN  VARCHAR2 DEFAULT NULL
                            ,parm4    IN  VARCHAR2 DEFAULT NULL
                            ,parm5    IN  VARCHAR2 DEFAULT NULL
                            ,parm6    IN  VARCHAR2 DEFAULT NULL
                            ,parm7    IN  VARCHAR2 DEFAULT NULL                
                            ,parm8    IN  VARCHAR2 DEFAULT NULL
                            ,parm9    IN  VARCHAR2 DEFAULT NULL
                            ,parm10   IN  VARCHAR2 DEFAULT NULL
                            ,parm11   IN  VARCHAR2 DEFAULT NULL
                            ,parm12   IN  VARCHAR2 DEFAULT NULL)
   IS
   BEGIN

      -- Capture user friendly concurrent program name for log file.
      gc_error_loc := 'Obtaining concurrent program name';
      SELECT user_concurrent_program_name
        INTO gc_program_name
        FROM fnd_concurrent_requests    FCR
            ,fnd_concurrent_programs_tl FCP
       WHERE FCR.request_id = gn_this_request_id
         AND FCR.program_application_id = FCP.application_id
         AND FCR.concurrent_program_id  = FCP.concurrent_program_id;

      -- Printing parameter list and RICE# to log
      gc_error_loc := 'Print Parameters and RICE# to concurrent request log file';
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'   See RICE# E2075 for design info for '|| gc_program_name ||'       ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID: '||gn_this_request_id||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters Values Used:');
      IF parm1  IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm1); END IF;
      IF parm2  IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm2); END IF;
      IF parm3  IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm3); END IF;
      IF parm4  IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm4); END IF;
      IF parm5  IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm5); END IF;
      IF parm6  IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm6); END IF;
      IF parm7  IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm7); END IF;
      IF parm8  IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm8); END IF;
      IF parm9  IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm9); END IF;
      IF parm10 IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm10); END IF;
      IF parm11 IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm11); END IF;
      IF parm12 IS NOT NULL THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'                       '||parm12); END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************'||chr(10));
   EXCEPTION   
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - PRINT_PROG_INFO (WHEN OTHERS)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside PRINT_PROG_INFO at '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside PRINT_PROG_INFO at '||gc_error_loc);
         print_time_stamp();
   END PRINT_PROG_INFO;
   
   -- +====================================================================+
   -- | Name       : GATHER_ARCHIVE_STATS                                  |
   -- |                                                                    |
   -- | Description: This private procedure is used to gather stats on     |
   -- |              archive tables used within this program               |
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE GATHER_ARCHIVE_STATS
   IS
   BEGIN
            FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_loc);            
        
            FND_STATS.GATHER_TABLE_STATS('AR','AR_ARCHIVE_CONTROL',10,4);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Stats have been gathered for AR.AR_ARCHIVE_CONTROL.');            
            print_time_stamp;
            
            FND_STATS.GATHER_TABLE_STATS('AR','AR_ARCHIVE_CONTROL_DETAIL',10,4);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Stats have been gathered for AR.AR_ARCHIVE_CONTROL_DETAIL.');            
            print_time_stamp;
            
            FND_STATS.GATHER_TABLE_STATS('AR','AR_ARCHIVE_HEADER',10,4);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Stats have been gathered for AR.AR_ARCHIVE_HEADER.');            
            print_time_stamp;
        
            FND_STATS.GATHER_TABLE_STATS('AR','AR_ARCHIVE_DETAIL',10,4);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Stats have been gathered for AR.AR_ARCHIVE_DETAIL.');                        
            print_time_stamp;
            
            FND_STATS.GATHER_TABLE_STATS('XXFIN','XX_AR_PURGE_CONTROL',10,4);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Stats have been gathered for XXFIN.XX_AR_PURGE_CONTROL.');                        
            print_time_stamp;

            FND_STATS.GATHER_TABLE_STATS('XXFIN','XX_AR_ARCHIVE_HEADER_ARCH',10,4);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Stats have been gathered for XXFIN.XX_AR_ARCHIVE_HEADER_ARCH.');            
            print_time_stamp;
        
   EXCEPTION   
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - GATHER_ARCHIVE_STATS (WHEN OTHERS)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside GATHER_ARCHIVE_STATS at '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside GATHER_ARCHIVE_STATS at '||gc_error_loc);
   END GATHER_ARCHIVE_STATS;
   
   -- +====================================================================+
   -- | Name       : CHECK_CHILD_STATUS                                    |
   -- |                                                                    |
   -- | Description: This private procedure is used to check status of     |
   -- |              child requests and write to log file                  |
   -- |                                                                    |
   -- | Parameters : p_request_id - Parent Request ID                      |
   -- |                                                                    |
   -- | Returns    : p_error_cnt  - Number of children completed in error  |
   -- +====================================================================+
   PROCEDURE CHECK_CHILD_STATUS (p_request_id   IN   NUMBER
                                ,p_error_cnt    OUT  NUMBER)
   IS
      CURSOR lcu_child_reqs
      IS
         SELECT FAR.request_id 
               ,FAR.status
               ,FAR.phase               
               ,FAR.program
           FROM fnd_amp_requests_v FAR
          WHERE FAR.parent_request_id = p_request_id;

   ltab_child_req_id_rec     lcu_child_reqs%ROWTYPE;
   ln_error_cnt              NUMBER := 0;

   BEGIN
      
      -- Print heads to log file
      gc_error_loc := 'Heading for status of child programs';
      FND_FILE.PUT_LINE(FND_FILE.LOG,CHR(10)||'     Status of Child Programs:'||CHR(10));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Request ID        Status            Program');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ---------------   ---------------   ----------------------------');

      -- Fetch and print child request id, status, and program name to log file
      gc_error_loc := 'Open cursor lcu_child_reqs and fetch into ltab_child_req_id_rec';
      OPEN lcu_child_reqs;
      LOOP
         FETCH lcu_child_reqs INTO ltab_child_req_id_rec;
         EXIT WHEN lcu_child_reqs%NOTFOUND;
         
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     '||RPAD(ltab_child_req_id_rec.request_id,18,' ')
                                               ||RPAD(ltab_child_req_id_rec.status    ,18,' ')
                                               ||ltab_child_req_id_rec.program);

         
         -- Increment counter if child completed in error status
         gc_error_loc := 'Increment counter if child completed in error status';
         IF ltab_child_req_id_rec.status = 'Error' THEN
            ln_error_cnt := ln_error_cnt + 1;
         END IF;

      END LOOP;
      CLOSE lcu_child_reqs;

      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      
      -- Set out variable for error count
      p_error_cnt := ln_error_cnt;
          
   EXCEPTION   
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - CHECK_CHILD_REQ (WHEN OTHERS)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside CHECK_CHILD_REQ procedure at '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside CHECK_CHILD_REQ procedure at '||gc_error_loc);
   END CHECK_CHILD_STATUS;

   /***********************
   ** PUBLIC PROCEDURES  **
   ***********************/   
   
   -- +====================================================================+
   -- | Name       : AR_PURGE_EXECUTE                                      |
   -- |                                                                    |
   -- | Description: Procedure is used for purging gl_import_references for|
   -- |              both AR and COGS journals based.  The procedure is    |
   -- |              also used to purge the following custom tables:       |
   -- |                  - XX_AR_CASH_RECEIPTS_EXT                         |
   -- |                  - XX_AR_REFUND_ERROR_LOG                          |
   -- |                  - XX_IBY_CC_REFUNDS                               |
   -- |                                                                    |
   -- |             This procedure purges gl_import_references and custom  |
   -- |             tables based on what is purge by the delivered standard|
   -- |             "New Archive and Purge" program (ARPURGE).             |
   -- |                                                                    |
   -- | Parameters : x_errbuf           - Error message for conc programs  |
   -- |              x_ret_code         - Return code for conc programs    |
   -- |              p_archive_id       - ID used for tracking purged trans|
   -- |              p_worker_number    - Specific Worker/thread Number    |
   -- |              p_bulk_limit       - Bulk processing size             |
   -- |              p_debug            - Debug flag                       |
   -- |                                                                    |
   -- |                                                                    |
   -- | Returns    : x_errbuf and x_ret_code - Both are required for       |
   -- |                                        EBS concurrent processing   |
   -- +====================================================================+
   PROCEDURE AR_PURGE_EXECUTE (x_errbuf         OUT VARCHAR2
                              ,x_ret_code       OUT NUMBER
                              ,p_archive_id     IN  NUMBER
                              ,p_worker_number  IN  NUMBER
                              ,p_bulk_limit     IN  NUMBER
                              ,p_debug          IN  VARCHAR2)  
   IS
      ln_org_id              hr.hr_all_organization_units.organization_id%TYPE;
      ld_cutoff_start        DATE;    
      ld_cutoff_end          DATE;
      ld_create_date         DATE;
      ln_user_id             applsys.fnd_user.user_id%TYPE;
      ln_i_count             integer;
      ln_r_count             integer;
      lt_arch_trans_null     g_arch_trans_tbl_type;
      lt_trans_class_null    g_transaction_class_type;
      lt_trans_num_null      g_transaction_number_type;   
      lt_trans_id_null       g_transaction_id_type;
      lt_aah_rowid_null      g_aah_rowid_type;
   BEGIN
      -- Set Module for the session
      dbms_application_info.set_module('XX_AR_TRANS_PURGE_EXECUTE-'||gn_this_request_id,null);

      -- Print parameters and values to log file
      print_prog_info(parm1  => 'p_archive_id   : '||p_archive_id
                     ,parm2  => 'p_worker_number: '||p_worker_number
                     ,parm3  => 'p_bulk_limit   : '||p_bulk_limit   
                     ,parm4  => 'p_debug        : '||p_debug
                     ,parm5  => NULL
                     ,parm6  => NULL
                     ,parm7  => NULL
                     ,parm8  => NULL 
                     ,parm9  => NULL
                     ,parm10 => NULL); 
      
      gd_start_time := SYSDATE;  -- Capture start time for calculating TPS (transactions per section)
      print_time_stamp;       
        
      -------------------------------------
      -- Variable Init and Fetch Env. Info.
      -------------------------------------
      gn_cogs_total_deleted     := 0;
      gn_ar_total_deleted       := 0;
      gn_XACRE_total_deleted    := 0;
      gn_XIBCR_total_deleted    := 0;

      gc_error_loc := 'Fetching info for insert into xx_ar_purge_control';
      SELECT TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'))     ORG_ID
            ,FCR.ARGUMENT1 CUTOFF_START    
            ,FCR.ARGUMENT2 CUTOFF_END      
            ,SYSDATE
            ,FND_GLOBAL.USER_ID
        INTO ln_org_id
            ,ld_cutoff_start
            ,ld_cutoff_end
            ,ld_create_date
            ,ln_user_id
        FROM ar_archive_control AACD
            ,fnd_concurrent_requests FCR
       WHERE AACD.archive_id = p_archive_id
         AND AACD.request_id = FCR.request_id;

      Begin
         --------------------------------------------------
         -- Select Previous totals from Purge Control Table
         --------------------------------------------------
         gc_error_loc := 'Update xx_ar_purge_control';
         Select ar_gl_imp_refs_cnt
               ,cogs_gl_imp_refs_cnt
               ,xx_ar_cash_receipts_ext_cnt
               ,xx_iby_cc_refunds_cnt
         into   gn_ar_total_deleted
               ,gn_cogs_total_deleted
               ,gn_XACRE_total_deleted
               ,gn_XIBCR_total_deleted
         from xx_ar_purge_control
         Where archive_id = p_archive_id
         and request_id = gn_this_request_id;
      Exception
         When No_data_found then
            gn_cogs_total_deleted     := 0;
            gn_ar_total_deleted       := 0;
            gn_XACRE_total_deleted    := 0;
            gn_XIBCR_total_deleted    := 0;
      End;

      <<main_loop>>
      LOOP
         -- Initialize the arrays
         gt_arch_trans := lt_arch_trans_null;
         gt_trans_class_i := lt_trans_class_null;
         gt_trans_num_i := lt_trans_num_null;   
         gt_trans_id_i := lt_trans_id_null;
         gt_trans_class_r := lt_trans_class_null;
         gt_trans_num_r := lt_trans_num_null;   
         gt_trans_id_r := lt_trans_id_null;
         gt_aah_rowid := lt_aah_rowid_null;

         -- Select transactions purged by standard archive program and delete gl_import_references and custom tables.
         gc_error_loc := 'Open cursor gcu_arch_trans for archive ID: '||p_archive_id||' (Worker Number: )';
         OPEN gcu_arch_trans(p_archive_id);
         -- Bulk fetch purged AR transactions to have related records purged
         gc_error_loc := 'Fetch transactions from cursor gcu_arch_trans for archive ID: '||p_archive_id||' (Worker Number: )';
         FETCH gcu_arch_trans BULK COLLECT INTO gt_arch_trans LIMIT p_bulk_limit;

         CLOSE gcu_arch_trans ;

         if gt_arch_trans.COUNT > 0 then
            -- Assign values pl/sql tables to faciliate bulk delete and checking of transaction class
            ln_i_count := 0;
            ln_r_count := 0;
            <<array_loop>>
            FOR i IN 1 .. gt_arch_trans.COUNT
            LOOP
               If gt_arch_trans(i).transaction_class in ('INV','DM','CM','CB','ADJ') then
                  ln_i_count := ln_i_count +1;
                  gt_trans_class_i(ln_i_count)     := gt_arch_trans(i).transaction_class;
                  gt_trans_num_i(ln_i_count)       := gt_arch_trans(i).transaction_number;
                  gt_trans_id_i(ln_i_count)        := gt_arch_trans(i).transaction_id;
               Elsif gt_arch_trans(i).transaction_class IN ('CASH','MISC') then
                  ln_r_count := ln_r_count +1;
                  gt_trans_class_r(ln_r_count)     := gt_arch_trans(i).transaction_class;
                  gt_trans_num_r(ln_r_count)       := gt_arch_trans(i).transaction_number;
                  gt_trans_id_r(ln_r_count)        := gt_arch_trans(i).transaction_id;
               Else
                  -- Check if transaction class is a known transaction class
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Records for transaction class of '||gt_arch_trans(i).transaction_class
                                               ||' will not be purged (Trans# - '||gt_arch_trans(i).transaction_number
                                               ||'Trans ID - '||gt_arch_trans(i).transaction_id);
               END IF;
               gt_aah_rowid(i)       := gt_arch_trans(i).row_id;
            END LOOP array_loop;
   
            print_time_stamp;                  
         
            gn_total_fetched := gn_total_fetched + gt_arch_trans.COUNT;  -- running total of fetched records
         
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Total Transaction Headers to Purge Details for : '||gt_arch_trans.COUNT||chr(10)); 

            -----------------------------------------------------------------
            -- Step #1 - Bulk Delete AR GL Imp References for Transactions --
            -----------------------------------------------------------------
            gc_error_loc := 'Deleting GL import references for AR transactions.';
            FORALL i IN 1 .. gt_trans_id_i.count
                DELETE /*+index(GIR XXFIN.XX_GL_IMPORT_REFERENCES_N2)*/ gl_import_references GIR
                 WHERE GIR.reference_4 = gt_trans_num_i(i)
   --                AND gt_trans_class_i(i) IN ('INV','DM','CM','CB','ADJ')
                   and GIR.reference_2 = to_char(gt_trans_id_i(i))
                   AND GIR.reference_10 IN ('AR_ADJUSTMENTS'
                                           ,'RA_CUST_TRX_LINE_GL_DIST'
                                           ,'AR_RECEIVABLE_APPLICATIONS');
   
            -- Tracking for records deleted during this fetch
            gn_ar_deleted_records := SQL%ROWCOUNT;    
            --------------------------------------------------------------------
            -- Step #1.5 - Bulk Delete AR GL Imp References for Cash Receipts --
            --------------------------------------------------------------------
            gc_error_loc := 'Deleting GL import references for AR Cash receipts.';
            FORALL i IN 1 .. gt_trans_id_r.count
                DELETE /*+index(GIR XXFIN.XX_GL_IMPORT_REFERENCES_N2)*/ gl_import_references GIR
                 WHERE GIR.reference_4 = gt_trans_num_r(i)
   --                AND gt_trans_class_r(i) IN ('CASH','MISC')                     
                   and GIR.reference_2 like to_char(gt_trans_id_r(i))||'%'
                   AND GIR.reference_10 IN ('AR_CASH_RECEIPT_HISTORY'
                                           ,'AR_MISC_CASH_DISTRIBUTIONS'
                                           ,'AR_RECEIVABLE_APPLICATIONS');
   
            -- Tracking for records deleted during this fetch
            gn_ar_deleted_records := nvl(gn_ar_deleted_records,0) + SQL%ROWCOUNT;    
            gn_ar_total_deleted   := gn_ar_total_deleted + gn_ar_deleted_records;
            gn_total_deleted      := gn_total_deleted    + gn_ar_deleted_records;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     AR GL_IMPORT_REFERENCES records deleted    '
                                         ||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                         ||':  '||gn_ar_deleted_records);              
   
            gn_ar_deleted_records := 0; -- Reset variable for next fetch
        
        
            ----------------------------------------------------------------------------
            -- Step #1.6 - Bulk Delete AR GL Imp References for Receipt Applications --
            ---------------------------------------------------------------------------
--            gc_error_loc := 'Deleting GL import references for Receivable Applications.';
--            FORALL i IN 1 .. gt_trans_id_r.count
--                DELETE /*+index(GIR XXFIN.XX_GL_IMPORT_REFERENCES_N2)*/ gl_import_references GIR
--                 WHERE GIR.reference_4 = gt_trans_num_r(i)
   --                AND gt_trans_class_r(i) IN ('CASH','MISC')                     
--                   and GIR.reference_2 like to_char(gt_trans_id_r(i))||'%'
--                   AND GIR.reference_10 = 'AR_RECEIVABLE_APPLICATIONS';
   
            -- Tracking for records deleted during this fetch
--            gn_ar_deleted_records := nvl(gn_ar_deleted_records,0) + SQL%ROWCOUNT;    
--            gn_ar_total_deleted   := gn_ar_total_deleted + gn_ar_deleted_records;
--            gn_total_deleted      := gn_total_deleted    + gn_ar_deleted_records;
   
--            FND_FILE.PUT_LINE(FND_FILE.LOG,'     AR GL_IMPORT_REFERENCES records deleted    '
--                                         ||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
--                                         ||':  '||gn_ar_deleted_records);              

--            gn_ar_deleted_records := 0; -- Reset variable for next fetch
         
            ---------------------------------------------------
            -- Steps #2 - Bulk Delete COGS GL Imp References --
            ---------------------------------------------------
            gc_error_loc := 'Deleting GL import references for COGS transactions.';
            FORALL i IN 1 .. gt_trans_id_i.count
                DELETE /*+index(GIR XXFIN.XX_GL_IMPORT_REFERENCES_N3)*/ gl_import_references GIR
                 WHERE GIR.reference_1 = TO_CHAR(gt_trans_id_i(i))
                   AND GIR.reference_9 = gt_trans_num_i(i)
                   AND gt_trans_class_i(i) IN ('INV','DM','CM')   
                   AND EXISTS (SELECT 'x'
                                 FROM gl_je_headers    GJH
                                     ,gl_je_sources_tl GJS
                                WHERE GJS.user_je_source_name = 'OD COGS'
                                  AND GJS.je_source_name      = GJH.je_source
                                  AND GJH.je_header_id        = GIR.je_header_id);
                            
            -- Tracking for records deleted during this fetch
            gn_cogs_deleted_records := SQL%ROWCOUNT;    
            gn_cogs_total_deleted   := gn_cogs_total_deleted + gn_cogs_deleted_records;
            gn_total_deleted        := gn_total_deleted      + gn_cogs_deleted_records;
         
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     COGS GL_IMPORT_REFERENCES records deleted  '
                                         ||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                         ||':  '||gn_cogs_deleted_records);                       
         
            gn_cogs_deleted_records := 0; -- Reset variable for next fetch

            ---------------------------------------------------
            -- Step #3 - Bulk Delete XX_AR_CASH_RECEIPTS_EXT --
            ---------------------------------------------------
            gc_error_loc := 'Deleting cash receipts from XX_AR_CASH_RECEIPTS_EXT';
            FORALL i IN 1 .. gt_trans_id_r.count
                DELETE /*+ index(XACRE XX_AR_CASH_RECEIPTS_EXT_PK)*/ xx_ar_cash_receipts_ext XACRE
                 WHERE XACRE.cash_receipt_id = gt_trans_id_r(i);
   --                AND gt_trans_class_r(i) IN ('CASH','MISC');   -- MISC is probably not required
                               
            -- Tracking for records deleted during this fetch         
            gn_XACRE_deleted_records := SQL%ROWCOUNT;    
            gn_XACRE_total_deleted   := gn_XACRE_total_deleted + gn_XACRE_deleted_records;
            gn_total_deleted         := gn_total_deleted       + gn_XACRE_deleted_records;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     XX_AR_CASH_RECEIPTS_EXT records deleted    '
                                          ||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                          ||':  '||gn_XACRE_deleted_records);

            gn_XACRE_deleted_records := 0;  -- Reset variable for next fetch
                   
   -- This section of code is removed because an Alternate Purge method will be considered to purge this custom table.
   --         ---------------------------------------------------
   --         -- Step #4 - Bulk Delete XX_AR_REFUND_ERROR_LOG  --
   --         ---------------------------------------------------
   --         gc_error_loc := 'Deleting cash receipts from XX_AR_REFUND_ERROR_LOG';
   --         FORALL i IN 1 .. gt_arch_trans.count
   --             DELETE /*+ index(XAREL ?????????????)*/ xx_ar_refund_error_log XAREL
   --              WHERE XAREL.trx_number = gt_trans_num(i)
   --                AND (
   --                      (XAREL.trx_type = 'Credit Memo'  AND gt_trans_class(i) = 'CM')
   --                     OR    
   --                      (XAREL.trx_type = 'Receipt'      AND gt_trans_class(i) IN ('CASH','MISC'))
   --                    );
   -- 
   --         -- Tracking for records deleted during this fetch                   
   --         gn_XAREL_deleted_records := SQL%ROWCOUNT;    
   --         gn_XAREL_total_deleted   := gn_XAREL_total_deleted + gn_XAREL_deleted_records;
   --         gn_total_deleted         := gn_total_deleted       + gn_XAREL_deleted_records;
   --
   --         FND_FILE.PUT_LINE(FND_FILE.LOG,'     XX_AR_REFUND_ERROR_LOG records deleted   '
   --                                       ||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
   --                                       ||':  '||gn_XAREL_deleted_records);                       
   --
   --         gn_XAREL_deleted_records := 0; -- Reset variable for next fetch
                  
            ---------------------------------------------------
            -- Step #5 - Bulk Delete XX_IBY_CC_REFUNDS       --
            ---------------------------------------------------
            gc_error_loc := 'Deleting cash receipts from XX_IBY_CC_REFUNDS';
            FORALL i IN 1 .. gt_trans_id_r.count
                DELETE /*+ index(XIBCR XX_IBY_CC_REFUNDS_N1)*/ xx_iby_cc_refunds XIBCR
                 WHERE XIBCR.cash_receipt_id = gt_trans_id_r(i);
   --                AND gt_trans_class_r(i) IN ('CASH','MISC');   -- MISC is probably not required
           
            -- Tracking for records deleted during this fetch                   
            gn_XIBCR_deleted_records := SQL%ROWCOUNT;    
            gn_XIBCR_total_deleted   := gn_XIBCR_total_deleted + gn_XIBCR_deleted_records;
            gn_total_deleted         := gn_total_deleted       + gn_XIBCR_deleted_records;
   
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     XX_IBY_CC_REFUNDS records deleted          '
                                          ||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                          ||':  '||gn_XIBCR_deleted_records);                       
   
            gn_XIBCR_deleted_records := 0; -- Reset variable for next fetch
   
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Total Records Deleted (GIR and Custom)         : '||gn_total_deleted||chr(10)); 
            --------------------------------------------------------------
            -- Step #6 - Bulk Insert in XX_AR_ARCHIVE_HEADER_ARCH       --
            --------------------------------------------------------------
            gc_error_loc := 'Inserting into XX_AR_ARCHIVE_HEADER_ARCH';
            FORALL i IN 1 .. gt_arch_trans.count
                INSERT INTO XX_AR_ARCHIVE_HEADER_ARCH
                Select * from AR_Archive_Header aah
                 WHERE aah.rowid = gt_aah_rowid(i);
        
            -- Tracking for records deleted during this fetch                   
            gn_XAAH_Inserted_records := SQL%ROWCOUNT;    
            gn_XAAH_total_Inserted   := gn_XAAH_total_Inserted + gn_XAAH_inserted_records;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     XX_AR_ARCHIVE_HEADER_ARCH records inserted '
                                          ||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                          ||':  '||gn_XAAH_inserted_records);                       

            --------------------------------------------------------------
            -- Step #7 - Bulk Insert in XX_AR_ARCHIVE_HEADER_ARCH       --
            --------------------------------------------------------------
            gc_error_loc := 'Inserting into XX_AR_ARCHIVE_HEADER_ARCH';
            FORALL i IN 1 .. gt_arch_trans.count
                DELETE AR_ARCHIVE_HEADER AAH
                 WHERE aah.rowid = gt_aah_rowid(i);
        
            -- Tracking for records deleted during this fetch                   
            gn_XAAH_Deleted_records := SQL%ROWCOUNT;    
            gn_XAAH_total_Deleted   := gn_XAAH_total_Deleted + gn_XAAH_Deleted_records;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     AR_ARCHIVE_HEADER records Deleted          '
                                          ||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                          ||':  '||gn_XAAH_Deleted_records);                       

            -----------------------------
            -- Update Purge Control Table
            -----------------------------
            gc_error_loc := 'Update xx_ar_purge_control';
            Update xx_ar_purge_control
            Set ar_gl_imp_refs_cnt          = gn_ar_total_deleted
               ,cogs_gl_imp_refs_cnt        = gn_cogs_total_deleted
               ,xx_ar_cash_receipts_ext_cnt = gn_XACRE_total_deleted
               ,xx_ar_refund_error_log_cnt  = 0
               ,xx_iby_cc_refunds_cnt       = gn_XIBCR_total_deleted
            Where archive_id = p_archive_id
            and   request_id = gn_this_request_id;

            If sql%rowcount = 0 Then
               -----------------------------------
               -- Insert Purge Control Table
               -----------------------------------      
               gc_error_loc := 'Insert xx_ar_purge_control';
               INSERT INTO xx_ar_purge_control
                        (archive_id
                        ,bulk_limit
                        ,request_id
                        ,org_id
                        ,cutoff_start
                        ,cutoff_end
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        ,last_updated_by
                        ,ar_gl_imp_refs_cnt
                        ,cogs_gl_imp_refs_cnt
                        ,xx_ar_cash_receipts_ext_cnt
                        ,xx_ar_refund_error_log_cnt
                        ,xx_iby_cc_refunds_cnt)
               VALUES
                        (p_archive_id
                        ,p_bulk_limit
                        ,gn_this_request_id
                        ,ln_org_id
                        ,ld_cutoff_start
                        ,ld_cutoff_end
                        ,ld_create_date
                        ,ln_user_id
                        ,ld_create_date
                        ,ln_user_id
                        ,gn_ar_total_deleted
                        ,gn_cogs_total_deleted
                        ,gn_XACRE_total_deleted
                        ,0
                        ,gn_XIBCR_total_deleted);
             End if;

            -- Issue commit for this fetch
            COMMIT;                               
            gc_error_loc := 'COMMIT completed for deletion of records.';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Committed delete of records.');

         End if;

         EXIT main_loop WHEN gt_arch_trans.COUNT < p_bulk_limit;

      END LOOP main_loop;

      print_time_stamp;
      
      -----------------------------------
      -- Records Deleted
      -----------------------------------      
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Total transactions headers processed                  : '||gn_total_fetched);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'          Total records deleted from GL_IMPORT_REFERENCES (AR)  : '||gn_ar_total_deleted);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'          Total records deleted from GL_IMPORT_REFERENCES (COGS): '||gn_cogs_total_deleted);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'          Total records deleted from XX_AR_CASH_RECEIPTS_EXT    : '||gn_XACRE_total_deleted);
--      FND_FILE.PUT_LINE(FND_FILE.LOG,'          Total records deleted from XX_AR_REFUND_ERROR_LOG     : '||gn_XAREL_total_deleted);                       
      FND_FILE.PUT_LINE(FND_FILE.LOG,'          Total records deleted from XX_IBY_CC_REFUNDS          : '||gn_XIBCR_total_deleted||chr(10));                       
      FND_FILE.PUT_LINE(FND_FILE.LOG,'          Total records inserted into XX_AR_ARCHIVE_HEADER_ARCH : '||gn_XAAH_total_inserted);                       
      FND_FILE.PUT_LINE(FND_FILE.LOG,'          Total records deleted from AR_ARCHIVE_HEADER          : '||gn_XAAH_total_deleted||chr(10));                       
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Total records Deleted (GIR and Custom)                : '||gn_total_deleted);

      -----------------------------------
      -- Calculate TPS
      -----------------------------------      
      gc_error_loc := 'Calculate TPS';
      gd_end_time  := SYSDATE;                                         -- Capture end time for calculating TPS (transactions per section)
      gn_duration  := ROUND((gd_end_time - gd_start_time)*24*60*60,0); -- Duration of program in seconds

      -- Calculate TPS if volume delete and duration are greater than zero
      IF gn_total_deleted > 0 AND gn_duration > 0 THEN                 
         gn_tps       := ROUND(gn_total_deleted / gn_duration,2);      
      END IF;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Total Duration in Seconds                             : '||gn_duration);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Transaction Per Second or TPS                         : '||gn_tps);
   
   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - XX_DELETE_AR_AR_GL_IMP_REFS (WHEN OTHERS)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside XX_DELETE_AR_AR_GL_IMP_REFS at '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside XX_DELETE_AR_AR_GL_IMP_REFS at '||gc_error_loc);
         print_time_stamp;
         ROLLBACK;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rollback completed.');
         x_ret_code := 2;
    END AR_PURGE_EXECUTE;
    
   -- +====================================================================+
   -- | Name       : AR_PURGE_MASTER                                       |
   -- |                                                                    |
   -- | Description: Procedure is used for submitting the custom AR purge  |
   -- |              program (AR_PURGE_EXECUTE procedure).                 |
   -- |                                                                    |
   -- | Parameters : x_errbuf           - Error message for conc programs  |
   -- |              x_ret_code         - Return code for conc programs    |
   -- |              p_archive_id_low   - Archive ID low value             |
   -- |              p_archive_id_high  - Archive ID high value            |
   -- |              p_bulk_limit       - Bulk processing size             |
   -- |              p_gather_tab_stats - Gathers stats on std archive tabs|
   -- |              p_debug            - Debug flag                       |
   -- |                                                                    |
   -- |                                                                    |
   -- | Returns    : x_errbuf and x_ret_code - Both are required for       |
   -- |                                        EBS concurrent processing   |
   -- +====================================================================+
   PROCEDURE AR_PURGE_MASTER (x_errbuf             OUT    VARCHAR2
                             ,x_ret_code           OUT    NUMBER
                             ,p_archive_id_low     IN     VARCHAR2
                             ,p_archive_id_high    IN     VARCHAR2
                             ,p_bulk_limit         IN     NUMBER
                             ,p_gather_tab_stats   IN     VARCHAR2
                             ,p_debug              IN     VARCHAR2)
   IS
      ---------------------
      -- LOCAL VARIABLES --
      ---------------------

      -- Cursor used to identify low and high archive ids of standard purge
      CURSOR lcu_archive_ids IS
         SELECT archive_id
           FROM ar_archive_control
          WHERE archive_id >= p_archive_id_low
            AND archive_id <= p_archive_id_high;

      ltab_arch_id_rec       lcu_archive_ids%ROWTYPE;
  
      ln_worker_number       NUMBER       := 0;
      
   BEGIN
	    
      --  IF request_date is NULL then this is NOT a restart of the program
      IF FND_CONC_GLOBAL.request_data IS NULL THEN  
         
         -- Print parameters and values to log file
         print_prog_info(parm1 => 'p_archive_id_low  : '||p_archive_id_low
                        ,parm2 => 'p_archive_id_high : '||p_archive_id_high
                        ,parm3 => 'p_bulk_limit      : '||p_bulk_limit   
                        ,parm4 => 'p_gather_tab_stats: '||p_gather_tab_stats
                        ,parm5 => 'p_debug           : '||p_debug
                        ,parm6 => NULL
                        ,parm7 => NULL
                        ,parm8 => NULL 
                        ,parm9  => NULL
                        ,parm10 => NULL); 
                        
         -------------------------------------
         -- Gather stats on AR Archive Tables
         --------------------------------------      
         gc_error_loc := 'Gathering Statistics on Standard AR Archive Tables';
         IF p_gather_tab_stats = 'Y' THEN
            gather_archive_stats;
         END IF;  -- Check if Gathering Statistics for Archive Tables
       
         -- Set variables for concurent program to be submitted
         gc_prog_shortname := 'XX_AR_TRANS_PURGE_EXECUTE';
         gc_appl_short     := 'XXFIN';
         
         -- Submit standard purge program and insert control information
         gc_error_loc := 'Submitting "New Archive and Purge" concurrent requests:';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     '||gc_error_loc||chr(10));
         
         -- Print header to log file for request listing
         FND_FILE.PUT_LINE(FND_FILE.LOG,'          Request ID     Archive ID       Worker');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'          ------------   --------------   ------');
                  
         --------------------------------------
         -- Submit Child Requests
         --------------------------------------      
         OPEN lcu_archive_ids;
         LOOP
            FETCH lcu_archive_ids INTO ltab_arch_id_rec;
            EXIT WHEN lcu_archive_ids%NOTFOUND;

            ln_worker_number      := ln_worker_number + 1;

            gc_error_loc := 'Submitting OD: AR Custom Purge Execute';
            gn_request_id := FND_REQUEST.SUBMIT_REQUEST (
                              application  => gc_appl_short
                             ,program      => gc_prog_shortname
                             ,description  => NULL
                             ,start_time   => SYSDATE
                             ,sub_request  => TRUE
                             ,argument1    => ltab_arch_id_rec.archive_id
                             ,argument2    => ln_worker_number
                             ,argument3    => p_bulk_limit
                             ,argument4    => p_debug);
             
            FND_FILE.PUT_LINE(FND_FILE.LOG,'          '||gn_request_id||'       '||ltab_arch_id_rec.archive_id||'     '||ln_worker_number);

            COMMIT;

         END LOOP ;

         print_time_stamp;

         if ln_worker_number = 0 then
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     No "OD: AR Custom Purge Child" workers submitted! Terminating!'||chr(10));         
            x_errbuf   := '     No "OD: AR Custom Purge Child" workers submitted! Terminating!';
            x_ret_code := 2;
            RETURN;
         end if;   

         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Waiting for "OD: AR Custom Purge Child" workers to complete........'||chr(10));         
         
         -- Set request data for request ID and submitted program
         FND_CONC_GLOBAL.set_req_globals(conc_status => 'PAUSED'
                                        ,request_data => 'XX_AR_TRANS_PURGE_EXECUTE'||'-'||gn_request_id);

         x_errbuf   := '';
         x_ret_code := 0;
         RETURN;
               
      ELSE  -- Program Restart Detected
         	       
         -- Determine if any children failed and write status of each child to log file
         gc_error_loc := 'Checking status of child programs (MASTER)';         
         check_child_status (p_request_id => gn_this_request_id
                            ,p_error_cnt  => gc_child_error_cnt);

         -- Determine completion status of wrapper program
         gc_error_loc := 'Setting return code based on the completion status of child programs (MASTER)';         
         IF gc_child_error_cnt > 0 THEN
            x_errbuf   := CHR(10)||'     Restarting after the completion of "OD: AR Custom Purge Child" workers.  One or more child programs completed in error.'||chr(10);
            x_ret_code := 2;
            FND_FILE.PUT_LINE(FND_FILE.LOG,CHR(10)||'     Setting to ERROR status based on one or more child programs completing in ERROR status.');            
         ELSE
            -- Setting completion status to ERROR
            x_errbuf   := CHR(10)||'     Restarting after the completion of "OD: AR Custom Purge Child" workers.'||chr(10);
            x_ret_code := 0;
         END IF;  -- End check for completion status of children
         
      END IF; -- End of checking for program START or RESTART

   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - AR_PURGE_MASTER (WHEN OTHERS)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside AR_PURGE_MASTER at '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside AR_PURGE_MASTER at '||gc_error_loc);
         print_time_stamp;
         ROLLBACK;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rollback completed.');
         x_ret_code:=2;
   END AR_PURGE_MASTER;

   
   -- +====================================================================+
   -- | Name       : STANDARD_AR_PURGE                                     |
   -- |                                                                    |
   -- | Description: Procedure is used to submit the standard archive and  |
   -- |              purge concurrent program called"New Archive and Purge"|
   -- |                                                                    |
   -- | Parameters : x_errbuf           - Error message for conc programs  |
   -- |              x_ret_code         - Return code for conc programs    |
   -- |              p_cut_off_date     - Archive trans cutoff date        |
   -- |              p_archive_level    - Level of archiving               |
   -- |              p_total_workers    - Number of child processes to use |
   -- |              p_customer_id      - Optionally limit by customer     |
   -- |              p_short_flag       - Log level for for standard purge |
   -- |              p_dm_purge_flag    - Purge DM Original Transactions   |
   -- |              p_bulk_limit       - Bulk processing size             |
   -- |                                                                    |
   -- | Returns    : x_errbuf and x_ret_code - Both are required for       |
   -- |                                        EBS concurrent processing   |
   -- +====================================================================+
   PROCEDURE STANDARD_AR_PURGE (x_errbuf             OUT    VARCHAR2
                               ,x_ret_code           OUT    NUMBER
                               ,p_start_gl_date      IN     VARCHAR2
                               ,p_cut_off_date       IN     VARCHAR2
                               ,p_archive_level      IN     VARCHAR2
                               ,p_total_workers      IN     NUMBER
                               ,p_customer_id        IN     NUMBER
                               ,p_short_flag         IN     VARCHAR2
                               ,p_dm_purge_flag      IN     VARCHAR2
                               ,p_bulk_limit         IN     NUMBER)
   IS
      ---------------------
      -- LOCAL VARIABLES --
      ---------------------
      ln_worker_number  NUMBER;
      ln_archive_id     ar_archive_header.archive_id%TYPE;
      lc_time           DATE;
      lc_time_start     VARCHAR2(30);
      ln_reqid          fnd_concurrent_requests.request_id%TYPE;
      ld_cut_off_date   DATE;
      ld_start_gl_date  DATE;
   
   BEGIN
      --  IF request_date is NULL then this is NOT a restart of the program
      IF FND_CONC_GLOBAL.request_data IS NULL THEN
         
         -- Print parameters and values to log file
         print_prog_info(parm1  => 'p_start_gl_date: '||p_start_gl_date
                        ,parm2  => 'p_cut_off_date : '||p_cut_off_date
                        ,parm3  => 'p_archive_level: '||p_archive_level
                        ,parm4  => 'p_total_workers: '||p_total_workers   
                        ,parm5  => 'p_customer_id  : '||p_customer_id
                        ,parm6  => 'p_short_flag   : '||p_short_flag
                        ,parm7  => 'p_dm_purge_flag: '||p_dm_purge_flag
                        ,parm8  => 'p_bulk_limit   : '||p_bulk_limit
                        ,parm9  => NULL 
                        ,parm10 => NULL); 

         -- Capture Single Date/time for generating archive id's
         lc_time        := SYSDATE;
         lc_time_start  := TO_CHAR(lc_time, 'DD-MON-RR HH24:MI');

         -- Convert cut off date parameter value (varchar2) to date
         ld_cut_off_date  := FND_DATE.CANONICAL_TO_DATE(p_cut_off_date);
         ld_start_gl_date := FND_DATE.CANONICAL_TO_DATE(p_start_gl_date);
      
         -- Set variables for concurent program to be submitted
         gc_prog_shortname := 'ARPURGE';
         gc_appl_short     := 'AR';

         -- Submit standard purge program and insert control information
         gc_error_loc := 'Submitting "New Archive and Purge" concurrent requests:';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     '||gc_error_loc||chr(10));
         
         -- Print header to log file for request listing
         FND_FILE.PUT_LINE(FND_FILE.LOG,'          Request ID     Archive ID       Worker');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'          ------------   --------------   ------');
         
         FOR ln_worker_number IN 1..p_total_workers
         LOOP
            gc_error_loc := 'Generate archive id using single date/time and worker number';
            ln_archive_id := TO_NUMBER(TO_CHAR(lc_time, 'YYMMDDHH24MISS')||
                                LPAD(ln_worker_number,3,'0'));																/*** V3.0 Changed LPAD argument from 2 to 3 - Prakash ***/
 
            gc_error_loc := 'Submit New Archive and Purge concurrent requests';
            ln_reqid      := FND_REQUEST.SUBMIT_REQUEST (
                                      application  => gc_appl_short
                                     ,program      => gc_prog_shortname
                                     ,description  => NULL
                                     ,start_time   => lc_time_start
                                     ,sub_request  => TRUE
                                     ,argument1    => ld_start_gl_date
                                     ,argument2    => ld_cut_off_date
                                     ,argument3    => ld_cut_off_date
                                     ,argument4    => p_archive_level
                                     ,argument5    => ln_archive_id
                                     ,argument6    => p_total_workers
                                     ,argument7    => ln_worker_number
                                     ,argument8    => p_customer_id
                                     ,argument9    => p_short_flag
                                     ,argument10   => p_dm_purge_flag
                                     ,argument11   => p_bulk_limit);

            FND_FILE.PUT_LINE(FND_FILE.LOG,'          '||ln_reqid||'       '||ln_archive_id||'     '||ln_worker_number);

            gc_error_loc := 'Inserting archive id and request information into control table';
            INSERT INTO ar_archive_control 
                     (creation_date
                     ,created_by
                     ,archive_level
                     ,number_of_processes	
                     ,request_id
                     ,archive_id)  
              VALUES (SYSDATE
                     ,0
                     ,p_archive_level
                     ,p_total_workers
                     ,ln_reqid
                     ,ln_archive_id);  
            
         END LOOP ;
    
         FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||'     Completed submission of workers and insert into control table.'||chr(10));         
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Waiting for "New Archive and Purge" workers to complete........'||chr(10));         
         
         print_time_stamp;
         
         -- Set request data for submitted program
         FND_CONC_GLOBAL.set_req_globals(conc_status => 'PAUSED',request_data => 'ARPURGE'||'-'||gn_request_id);

         x_errbuf   := 'New Archive and Purge submitted.';
         x_ret_code := 0;
         RETURN;
                   
      ELSE  -- Restart detected FND_CONC_GLOBAL.request_data = 'ARPURGE'
        
         -- Determine if any children failed and write status of each child to log file
         gc_error_loc := 'Checking status of child programs (STANDARD)';         
         check_child_status (p_request_id => gn_this_request_id
                            ,p_error_cnt  => gc_child_error_cnt);

         -- Determine completion status of wrapper program
         gc_error_loc := 'Setting return code based on the completion status of child programs (STANDARD)';         
         IF gc_child_error_cnt > 0 THEN
            x_errbuf   := CHR(10)||'     Restarting after the completion of "New Archive and Purge" workers.  One or more child programs completed in error.'||chr(10);
            x_ret_code := 2;
            FND_FILE.PUT_LINE(FND_FILE.LOG,CHR(10)||'     Setting to ERROR status based on one or more child programs completing in ERROR status.');            
         ELSE
            -- Setting completion status to ERROR
            x_errbuf   := CHR(10)||'     Restarting after the completion of "New Archive and Purge" workers.'||chr(10);
            x_ret_code := 0;
         END IF;  -- End check for completion status of children
                    
      END IF;   -- End of checking for program START or RESTART   
      
   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - SUBMIT_STD_AR_PURGE (WHEN OTHERS)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside SUBMIT_STD_AR_PURGE at '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside SUBMIT_STD_AR_PURGE at  '||gc_error_loc);
         print_time_stamp;
         ROLLBACK;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rollback completed.');
         x_ret_code := 2;
   END STANDARD_AR_PURGE;
   
   -- +====================================================================+
   -- | Name       : AR_PURGE_WRAPPER                                      |
   -- |                                                                    |
   -- | Description: Procedure is used for submitting standard AR archive  |
   -- |              and purge and the custom AR archive and purge         |
   -- |                                                                    |
   -- | Parameters : x_errbuf           - Error message for conc programs  |
   -- |              x_ret_code         - Return code for conc programs    |
   -- |              p_start_gl_date    - Archive trans start GL date      |
   -- |              p_cut_off_date     - Archive trans cutoff date        |
   -- |              p_archive_level    - Level of archiving               |
   -- |              p_total_workers    - Number of child processes to use |
   -- |              p_customer_id      - Optionally limit by customer     |
   -- |              p_short_flag       - Log level for for standard purge |
   -- |              p_dm_purge_flag    - Purge DM Original Transactions   |
   -- |              p_purge_window     - Purge Window End Date-time       |
   -- |              p_bulk_limit       - Bulk processing size             |
   -- |              p_gather_tab_stats - Gathers stats on std archive tabs|
   -- |              p_debug            - Debug flag                       |
   -- |                                                                    |
   -- |                                                                    |
   -- | Returns    : x_errbuf and x_ret_code - Both are required for       |
   -- |                                        EBS concurrent processing   |
   -- |                                                                    |
   -- +====================================================================+
   PROCEDURE AR_PURGE_WRAPPER (x_errbuf             OUT    VARCHAR2
                              ,x_ret_code           OUT    NUMBER
                              ,p_start_gl_date      IN     VARCHAR2
                              ,p_cut_off_date       IN     VARCHAR2
                              ,p_archive_level      IN     VARCHAR2
                              ,p_total_workers      IN     NUMBER
                              ,p_customer_id        IN     NUMBER
                              ,p_short_flag         IN     VARCHAR2
                              ,p_dm_purge_flag      IN     VARCHAR2
					,p_purge_window	    IN     VARCHAR2
                              ,p_bulk_limit         IN     NUMBER
                              ,p_gather_tab_stats   IN     VARCHAR2
                              ,p_debug              IN     VARCHAR2)
   IS
      ---------------------
      -- LOCAL VARIABLES --
      ---------------------

      -- Cursor and variables are used to identify high and low archive ids for this run
      CURSOR lcu_archive_ids (p_request_id fnd_concurrent_requests.parent_request_id%TYPE)
      IS
         SELECT MIN(FCR.argument5) MIN_ARCHIVE_ID
               ,MAX(FCR.argument5) MAX_ARCHIVE_ID
           FROM fnd_concurrent_Requests FCR     
          WHERE FCR.parent_request_id = p_request_id;

      gtab_archive_ids_rec lcu_archive_ids%ROWTYPE;

	-- Cursor to fetch start date of the fiscal period that is within minimum retention period
	cursor lcu_min_reten_date(p_no_of_period number)
	is
	select min(s.start_date)
	from apps.gl_period_STATUSES s,
	  (	select max(period_num) period_num, max(period_year) period_year
		from apps.gl_period_STATUSES s1
		where (sysdate+0) between s1.start_date and s1.end_date
		) s1
	where s.period_year >= s1.period_year-1
	and s.period_num >= s1.period_num-p_no_of_period
	and (	s.period_num <= s1.period_num and s.period_year = s1.period_year 
	    or s.period_num >=s1.period_num+12-p_no_of_period and s.period_year < s1.period_year);

	-- Cursor to fetch Date-Range Type information
	Cursor lcu_purge_schedule(pc_ou_name varchar2)
	is
	select	v.source_value1 date_range_type,
		v.source_value2 start_date, 
		v.source_value3 increment_date, 
		v.source_value4 end_date, 
		v.source_value5 status
	from	XX_FIN_TRANSLATEDEFINITION d, xx_fin_translatevalues v
	where d.translation_name = pc_ou_name||' - AR PURGE SCHEDULE'
	and d.translate_id = v.translate_id
	order by decode(v.source_value5,'C',2,'R',0,1), v.source_value1
	for update of v.source_value5;

	-- Cursor to fetch OU Name
	Cursor lcu_ou(p_org_id number)
	is
	select	name
	from	HR_OPERATING_UNITS
	where ORGANIZATION_ID = p_org_id;

      gtab_schedule_rec lcu_purge_schedule%ROWTYPE;

      -- Variable used for holding extracted request id
      ln_request_id        fnd_concurrent_requests.request_id%TYPE;
      ln_org_id         HR_OPERATING_UNITS.ORGANIZATION_ID%TYPE;
      lc_ou_name        HR_OPERATING_UNITS.NAME%TYPE;
      ld_start_gl_date	DATE;
      ld_cut_off_date	DATE;
      ld_purge_window	DATE;
      ld_purge_start_time	DATE;
	ln_increment	integer;
      ld_min_reten_date	DATE;
	ln_min_reten_prd	integer;
	lc_date_range_type	varchar2(240);

   BEGIN
      -- Print parameters and values to log file
      print_prog_info(parm1  => 'p_start_gl_date     : '||p_start_gl_date
                     ,parm2  => 'p_cut_off_date      : '||p_cut_off_date
                     ,parm3  => 'p_archive_level     : '||p_archive_level
                     ,parm4  => 'p_total_workers     : '||p_total_workers
                     ,parm5  => 'p_customer_id       : '||p_customer_id
                     ,parm6  => 'p_short_flag        : '||p_short_flag
                     ,parm7  => 'p_dm_purge_flag     : '||p_dm_purge_flag
                     ,parm8  => 'p_purge_window      : '||p_purge_window
                     ,parm9  => 'p_bulk_limit        : '||p_bulk_limit
                     ,parm10  => 'p_gather_tab_stats  : '||p_gather_tab_stats
                     ,parm11  => 'p_debug             : '||p_debug);         
      ----------------------------------------------------------------
      -- Step #0 - Validate Parameters and derive scheduling info   --
      ----------------------------------------------------------------
      -- Obtain OU Name.
      Declare
          invalid_session	exception;
      Begin
          FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Obtaining ORG_ID from System Profile');             
	    ln_org_id := to_number(fnd_profile.value('ORG_ID'));
          If nvl(ln_org_id,0) = 0 then
              raise invalid_session;
          End if;
	Exception
          When value_error or invalid_number or invalid_session then
              x_errbuf   := 'Invalid Org_Id in System Profile.';
              x_ret_code := 2;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Invalid Org_Id set in System Profile.');             
              RETURN;
      End;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG_ID = '||ln_org_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Determining OU Name');             
      -- Validate start date to be at least as old as the minimum retention period.
      open lcu_ou(ln_org_id);
      fetch lcu_ou into lc_ou_name;
	If lcu_ou%notfound then
          x_errbuf   := 'Unable to fetch OU Name. No data Found';
          x_ret_code := 2;
          close lcu_ou;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Determining OU Name FAILED - No data Found');             
          RETURN;
      End if;
      close lcu_ou;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'OU Name = '||lc_ou_name);

      -- Obtain Minimum Retention Period.
      Declare
          invalid_reten_period	exception;
      Begin
          FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Obtaining Min. Retention period from System Profile');             
	    ln_min_reten_prd := to_number(fnd_profile.value('OD_ARPURGE_MIN_RETENTION_PERIOD'));
          If nvl(ln_min_reten_prd,0) = 0 then
              raise invalid_reten_period;
          End if;
	Exception
          When value_error or invalid_number or invalid_reten_period then
              x_errbuf   := 'Invalid Minimum Retention period set in System Profile.';
              x_ret_code := 2;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Invalid Minimum Retention period set in System Profile.');             
              RETURN;
      End;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Min. Retention Period = '||ln_min_reten_prd);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Determining Min. Retention Date using GL Calendar');             
      -- Validate start date to be at least as old as the minimum retention period.
      open lcu_min_reten_date(ln_min_reten_prd);
      fetch lcu_min_reten_date into ld_min_reten_date;
	If lcu_min_reten_date%notfound then
          x_errbuf   := 'Unable to view GL Calendar to determine minimum retention period. No data Found';
          x_ret_code := 2;
          close lcu_min_reten_date;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Determining Min. Retention Date using GL Calendar FAILED - No data Found');             
          RETURN;
      End if;
      close lcu_min_reten_date;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Min. Retention Date = '||TO_CHAR(ld_min_reten_date,'DD-MON-YYYY'));
      If p_purge_window is not null then
         ld_purge_window := FND_DATE.CANONICAL_TO_DATE(p_purge_window);
      End if;
      -- Loop through the program until Purge Schedule is executed
      <<Schedule_Loop>>
      Loop
         If p_start_gl_date is null or p_cut_off_date is null then
             FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Getting Schedule info from Translation table');             
             open lcu_purge_schedule(lc_ou_name);
             Fetch lcu_purge_schedule into gtab_schedule_rec;
             If lcu_purge_schedule%notfound then
                 x_errbuf   := 'Schedule data is not setup in Translation Tables for '||lc_ou_name;
                 x_ret_code := 2;
                 Close lcu_purge_schedule;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Validate Parameters and derive scheduling info FAILED');             
                 RETURN;
             End if;
             Close lcu_purge_schedule;
             Begin
                 -- Convert cut off date parameter value (varchar2) to date
                 lc_date_range_type := gtab_schedule_rec.date_range_type;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Date Range Type = '||lc_date_range_type);
                 ld_start_gl_date := TO_DATE(gtab_schedule_rec.start_date,'DD-MON-YYYY');
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Start Date = '|| TO_CHAR(ld_start_gl_date,'DD-MON-YYYY'));
                 ld_cut_off_date  := TO_DATE(gtab_schedule_rec.end_date,'DD-MON-YYYY');
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Cut-Off Date = '|| TO_CHAR(ld_cut_off_date,'DD-MON-YYYY'));
                 ln_increment := to_number(gtab_schedule_rec.increment_date);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Increment = '||ln_increment);
                 -- Check if the Schedule cycle is complete
                 if gtab_schedule_rec.status = 'C' then
                     x_errbuf   := 'Date-Range Type '||lc_date_range_type||' is Complete. No Purge Jobs submitted.';
                     x_ret_code := 0;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Date-Range Type '||lc_date_range_type||' is Complete. No Purge Jobs submitted.');             
                     RETURN;
                 End if;
             Exception
                 when value_error or invalid_number then
                     x_errbuf   := 'Invalid Translate values set for Date-Range Type ='||lc_date_range_type;
                     x_ret_code := 2;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Invalid Translate values set for Date-Range Type ='||lc_date_range_type);             
                     RETURN;
             End;
         Else
             -- Convert cut off date parameter value (varchar2) to date
             FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Start and End date parameters will be used for this run');             
             ld_start_gl_date := FND_DATE.CANONICAL_TO_DATE(p_start_gl_date);
             ld_cut_off_date  := FND_DATE.CANONICAL_TO_DATE(p_cut_off_date);
         End if;

         /*  Moved this section before validation of dates takes place as part of defect # 10610  */
         If lc_date_range_type is not null then
             If ld_start_gl_date + ln_increment - 1 <= ld_cut_off_date then
                 ld_cut_off_date := ld_start_gl_date + ln_increment - 1;
             End if;
             FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Start Date='||to_char(ld_start_gl_date,'DD-MON-YYYY')||' End date='||to_char(ld_cut_off_date,'DD-MON-YYYY'));
         End if;
         if ld_cut_off_date is NULL then
             x_errbuf   := 'End Date is not specified. Please specify an End Date or verify purge schedule translation setup';
             x_ret_code := 2;
             FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - End Date is not specified. Please specify an End Date or verify purge schedule translation setup');
             RETURN;
         End if;
         if ld_cut_off_date > (ld_min_reten_date-1) then
             x_errbuf   := 'End Date specified is within the mininum retention period. End date cannot be greater than '||to_char(ld_min_reten_date-1,'DD-MON-YYYY');
             x_ret_code := 2;
             FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - End Date specified is within the mininum retention period. End date cannot be greater than '||to_char(ld_min_reten_date-1,'DD-MON-YYYY'));
             RETURN;
         End if;
         -- Validate Date Parameter Values
         If ld_start_gl_date > ld_cut_off_date then
             x_errbuf   := x_errbuf||chr(10)||'Invalid Date Range Parameter values passed. Start Date is Greater than End date.';
             x_ret_code := 2;
             FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #0 - Invalid Date Range Parameter values passed. Start Date is Greater than End date.');
             RETURN;
         End if;


         --  IF request_date is NULL then this is NOT a restart of the program
         IF FND_CONC_GLOBAL.request_data IS NULL THEN  -- not a restart of parent

            If lc_date_range_type is not null then
                -- Update Schedule to set the Running Status
                Update xx_fin_translatevalues v
                Set v.source_value5 = 'R'
                Where v.translate_id = (
                                        Select d.translate_id 
                                        from	XX_FIN_TRANSLATEDEFINITION d 
                                        where d.translation_name = lc_ou_name||' - AR PURGE SCHEDULE'
                                       )
                and v.source_value1 = lc_date_range_type;
            End if;
            ld_purge_start_time := sysdate;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Purge Start time is '|| TO_CHAR(ld_purge_start_time,'DD-MON-YYYY HH24:MI:SS'));
            ------------------------------------------------------------
            -- Step #1 - Submit OD: AR Custom Purge Submit Standard   --
            ------------------------------------------------------------      
            -- Set variables for concurent program to be submitted
            gc_prog_shortname := 'XX_AR_TRANS_PURGE_STANDARD';
            gc_appl_short     := 'XXFIN';

            -- Submit concurrent program OD: AR Custom Purge - Submit Standard
            gc_error_loc  := 'Submit OD: AR Custom Purge Submit Standard';
            gn_request_id := FND_REQUEST.SUBMIT_REQUEST (
                              application  => gc_appl_short
                             ,program      => gc_prog_shortname
                             ,description  => NULL
                             ,start_time   => SYSDATE
                             ,sub_request  => TRUE
                             ,argument1    => FND_DATE.DATE_TO_CANONICAL(ld_start_gl_date)
                             ,argument2    => FND_DATE.DATE_TO_CANONICAL(ld_cut_off_date)
                             ,argument3    => p_archive_level                                            
                             ,argument4    => p_total_workers
                             ,argument5    => p_customer_id
                             ,argument6    => p_short_flag
                             ,argument7    => p_dm_purge_flag
                             ,argument8    => p_bulk_limit);

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #1 - Submit OD: AR Custom Purge Submit Standard');             
            FND_FILE.PUT_LINE(FND_FILE.LOG,'          Request ID '||gn_request_id||' submitted.');            
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Waiting for "OD: AR Custom Purge Submit Standard" to complete........');         
   
            print_time_stamp;

            -- Set request data for request ID and submitted program
            FND_CONC_GLOBAL.set_req_globals(conc_status => 'PAUSED'
                                           ,request_data => 'XX_AR_TRANS_PURGE_STANDARD'||'|'||to_char(ld_purge_start_time,'YYYYMMDDHH24MISS')||'|'||gn_request_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Request Data Set to '||FND_CONC_GLOBAL.request_data);
   
            x_errbuf   := ' ';
            x_ret_code := 0;
            RETURN;

         -- Check if program was restarted after XX_AR_TRANS_PURGE_STANDARD was submitted/completed
         ELSIF SUBSTR(FND_CONC_GLOBAL.request_data,1,INSTR(FND_CONC_GLOBAL.request_data,'|', 1, 1)-1) 
               = 'XX_AR_TRANS_PURGE_STANDARD' THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Re-Started after "OD: AR Custom Purge Submit Standard" at '|| TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));

            -- Extracting Cut-Off date value used in prior session of this program
            gc_error_loc  := 'Extracting Cut-Off date value used in prior session of this program, from FND_CONC_GLOBAL.request_data';
            ld_purge_start_time := TO_DATE(SUBSTR(FND_CONC_GLOBAL.request_data,INSTR(FND_CONC_GLOBAL.request_data,'|', 1, 1)+1,14),'YYYYMMDDHH24MISS');
            ln_request_id := TO_NUMBER(SUBSTR(FND_CONC_GLOBAL.request_data,INSTR(FND_CONC_GLOBAL.request_data,'|', 1, 2)+1));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Extracted Purge Start time = '|| TO_CHAR(ld_purge_start_time,'DD-MON-YYYY HH24:MI:SS'));

            -- Fetch archive id's for input into XX_AR_TRANS_PURGE_MASTER
            gc_error_loc := 'Restarted Wrapper - Fetching archive ids for master';
            OPEN lcu_archive_ids(ln_request_id);
            FETCH lcu_archive_ids INTO gtab_archive_ids_rec;
            CLOSE lcu_archive_ids;     

            ----------------------------------------------------
            -- Step #2 - Submit OD: AR Custom Purge Master    --
            ----------------------------------------------------      

            -- Set variables for concurent program to be submitted
            gc_prog_shortname := 'XX_AR_TRANS_PURGE_MASTER';
            gc_appl_short     := 'XXFIN';

            print_time_stamp;
         
            -- Submit concurrent program OD: AR Custom Purge - Master
            gc_error_loc := 'Submit OD: AR Custom Purge Master';
            gn_request_id := FND_REQUEST.SUBMIT_REQUEST (
                              application  => gc_appl_short
                             ,program      => gc_prog_shortname
                             ,description  => NULL
                             ,start_time   => SYSDATE
                             ,sub_request  => TRUE
                             ,argument1    => gtab_archive_ids_rec.min_archive_id 
                             ,argument2    => gtab_archive_ids_rec.max_archive_id                           
                             ,argument3    => p_bulk_limit
                             ,argument4    => p_gather_tab_stats
                             ,argument5    => p_debug);

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Step #2 - Submit OD: AR Custom Purge Master');             
            FND_FILE.PUT_LINE(FND_FILE.LOG,'          Request ID '||gn_request_id||' submitted.');            
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Waiting for "OD: AR Custom Purge Master" to complete........');         

            print_time_stamp;

            -- Set request data for submitted program for detecting restart
            FND_CONC_GLOBAL.set_req_globals(conc_status => 'PAUSED'
                                           ,request_data => 'XX_AR_TRANS_PURGE_MASTER'||'|'||to_char(ld_purge_start_time,'YYYYMMDDHH24MISS'));

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Request Data Set to '||FND_CONC_GLOBAL.request_data);
            x_errbuf   := '';
            x_ret_code := 0;
            RETURN;

         ELSE  -- Restart detected - All children have completed
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Re-Started after "OD: AR Custom Purge Master" at '|| TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));
            -- Extract Purge Start time from request data  
            ld_purge_start_time := TO_DATE(SUBSTR(FND_CONC_GLOBAL.request_data,INSTR(FND_CONC_GLOBAL.request_data,'|', 1, 1)+1),'YYYYMMDDHH24MISS');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Extracted Purge Start time = '|| TO_CHAR(ld_purge_start_time,'DD-MON-YYYY HH24:MI:SS'));
            -- Determine if any children failed and write status of each child to log file
            gc_error_loc := 'Checking status of child programs (WRAPPER)';         
            check_child_status (p_request_id => gn_this_request_id
                               ,p_error_cnt  => gc_child_error_cnt);

            -- Determine completion status of wrapper program
            gc_error_loc := 'Setting return code based on the completion status of child programs (WRAPPER)';         
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Child Process Error count = '||gc_child_error_cnt);
            IF gc_child_error_cnt > 0 THEN
                If lc_date_range_type is not null then
                   -- Update Schedule to set the Error Status
                   Update xx_fin_translatevalues v
                   Set v.source_value5 = 'E'
                   Where v.translate_id = (
                                           Select d.translate_id 
                                           from	XX_FIN_TRANSLATEDEFINITION d 
                                           where d.translation_name = lc_ou_name||' - AR PURGE SCHEDULE'
                                          )
                   and v.source_value1 = lc_date_range_type;
                   Commit;
               End if;
               x_errbuf   := '';
               x_ret_code := 2;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'     Setting to ERROR status based on one or more child programs completing in ERROR status.');            
               RETURN;
            ELSE
                If lc_date_range_type is not null then
                   -- Update Schedule to set the Success Status
                   Update xx_fin_translatevalues v
                   Set v.source_value2 = decode(sign(nvl(to_date(v.source_value4,'DD-MON-YYYY'),ld_min_reten_date-1)-(ld_cut_off_date+1)),
                                                    -1,to_char(ld_cut_off_date,'DD-MON-YYYY'),
                                                    to_char(ld_cut_off_date+1,'DD-MON-YYYY')),
                       v.source_value5 = decode(sign(nvl(to_date(v.source_value4,'DD-MON-YYYY'),ld_min_reten_date-1)-(ld_cut_off_date+1)),
                                                    -1,'C',
                                                    'N')
                   Where v.translate_id = (
                                           Select d.translate_id 
                                           from	XX_FIN_TRANSLATEDEFINITION d 
                                           where d.translation_name = lc_ou_name||' - AR PURGE SCHEDULE'
                                          )
                   and v.source_value1 = lc_date_range_type;
               End if;
               -- Setting completion status to SUCCESS
               x_errbuf   := '';
               x_ret_code := 0;
            END IF;  -- End check for completion status of children
               
         END IF;    -- End of checking for program START or RESTART
         -- Check for various conditions to continue ot end the Loop
         Exit Schedule_Loop when lc_date_range_type is null OR ld_purge_window is NULL;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Purge Start time = '|| TO_CHAR(ld_purge_start_time,'DD-MON-YYYY HH24:MI:SS'));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Purge Window End = '|| TO_CHAR(ld_purge_window,'DD-MON-YYYY HH24:MI:SS'));
	   Exit Schedule_Loop when (sysdate + (sysdate - ld_purge_start_time)) > ld_purge_window;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Reseting Request Data ');
         FND_CONC_GLOBAL.set_req_globals(request_data => '');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Request Data Reset to '||nvl(FND_CONC_GLOBAL.request_data,'<NULL>'));
      End Loop Schedule_Loop;
   EXCEPTION
      WHEN VALUE_ERROR THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - AR_PURGE_WRAPPER (VALUE_ERROR)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside AR_PURGE_WRAPPER at '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside AR_PURGE_WRAPPER at '||gc_error_loc);
         print_time_stamp;
         If lc_date_range_type is not null then
             -- Update Schedule to set the Error Status
             Update xx_fin_translatevalues v
		 Set v.source_value5 = 'E'
             Where v.translate_id = (
                                        Select d.translate_id 
                                        from	XX_FIN_TRANSLATEDEFINITION d 
                                        where d.translation_name = lc_ou_name||' - AR PURGE SCHEDULE'
                                    )
             and v.source_value1 = lc_date_range_type;
             Commit;
         End if;
         x_errbuf   := CHR(10)||'     Exception raised inside AR_PURGE_WRAPPER at '||gc_error_loc||chr(10);
         x_ret_code := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - AR_PURGE_WRAPPER (WHEN OTHERS)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside AR_PURGE_WRAPPER at '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside AR_PURGE_WRAPPER at '||gc_error_loc);
         print_time_stamp;
         If lc_date_range_type is not null then
             -- Update Schedule to set the Error Status
             Update xx_fin_translatevalues v
		 Set v.source_value5 = 'E'
             Where v.translate_id = (
                                        Select d.translate_id 
                                        from	XX_FIN_TRANSLATEDEFINITION d 
                                        where d.translation_name = lc_ou_name||' - AR PURGE SCHEDULE'
                                    )
             and v.source_value1 = lc_date_range_type;
             Commit;
         End if;
         x_errbuf   := CHR(10)||'     Exception raised inside AR_PURGE_WRAPPER at '||gc_error_loc||chr(10);
         x_ret_code := 2;

   END AR_PURGE_WRAPPER;

END XX_AR_TRANS_PURGE_PKG;
/
SHOW ERR
