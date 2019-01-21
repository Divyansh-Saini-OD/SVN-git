/*SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
                   
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK; */
CREATE OR REPLACE PACKAGE BODY XX_AR_GL_PARALLEL_PKG AS
-- +===========================================================================+
-- |                     Office Depot - Project Simplify                       |
-- +===========================================================================+
-- | PACKAGE NAME : XX_AR_GL_PARALLEL_PKG                                      |
-- |                                                                           |
-- | RICE#        : E2050  (Defect 3260)                                       |
-- |                                                                           |
-- | DESCRIPTION  : Package contains code necessary to implement the           |
-- |                parallel capability of the standard General Ledger         |
-- |                Transfer Program (ARGLTP).                                 |
-- |                                                                           |
-- |                                                                           | 
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date         Author            Remarks                           |
-- |========  ===========  ===============   ==================================|
-- |1.0       20-JAN-2010  R.Aldridge        10.2 Initial -  revision # 83975  |
-- |                                                                           |
-- |1.1       15-APR-2010  R.Aldridge        10.3 Performance changes for      |
-- |                                         Defect 4889.  See revision # 83975|
-- |                                         for code that was removed         |
-- |1.2       22-APR-2010  Ganga Devi R      Modified and Added Procedure      |
-- |                                         PREPARE_RECEIPTS for defect#4889  |
-- |1.3       26-OCT-2015  Vasu Raparla      Removed Schema References for     |
-- |                                          R12.2                            |
-- +===========================================================================+

  -- Define Global Private Package Variables
  gn_total_updated_rows     NUMBER       :=0;
         
  -- +=========================================================================+
  -- | PROCEDURE NAME : POPULATE_WORKER_TRX_ADJ                                |
  -- |                                                                         |
  -- | DESCRIPTION    : This private procedure updates posting_worker_number   |
  -- |                  column on the following tables when the submitting the |
  -- |                  GL Transfer with more than 1 worker/thread             |
  -- |                                                                         |
  -- |                  RA_CUST_TRX_LINE_GL_DIST_ALL                           |
  -- |                  AR_ADJUSTMENTS_ALL                                     |
  -- |                  AR_TRANSACTION_HISTORY_ALL                             |
  -- |                                                                         |
  -- | PARAMETERS     : p_max_workers    - Number of parallel workers/threads  |
  -- |                  p_start_date     - Starting GL Date                    |
  -- |                  p_post_thru_date - End GL Date                         |
  -- |                  p_set_of_books   - Set of Books ID                     |
  -- |                  p_org_id         - Organization ID                     |       
  -- |                  p_batch_size     - Batch size for assigning to worker  |
  -- |                                                                         |
  -- | RETURNS        : none                                                   |
  -- +=========================================================================+
  PROCEDURE POPULATE_WORKER_TRX_ADJ(p_max_workers     IN  NUMBER
                                   ,p_start_date      IN  VARCHAR2
                                   ,p_post_thru_date  IN  VARCHAR2
                                   ,p_set_of_books    IN  NUMBER
                                   ,p_org_id          IN  NUMBER
                                   ,p_batch_size      IN  NUMBER
                                   ,p_processing_type IN  VARCHAR2
                                   ,p_ret_code        OUT NUMBER)
  AS   
      
     CURSOR postable_dist (p_max_workers    NUMBER
                          ,p_start_date     DATE
                          ,p_post_thru_date DATE
                          ,p_set_of_books   NUMBER) 
     IS
        SELECT GLD.ROWID
             ,(MOD(CEIL((DENSE_RANK() over(ORDER BY             
                  GLD.customer_trx_id))/p_batch_size), p_max_workers) + 1)
          FROM ra_cust_trx_line_gl_dist_all GLD
              ,ra_customer_trx_all TRX
         WHERE GLD.gl_date BETWEEN p_start_date AND p_post_thru_date
           AND GLD.posting_control_id = -3
           AND GLD.set_of_books_id    = p_set_of_books
           AND GLD.account_set_flag   = 'N'
           AND GLD.customer_trx_id    = TRX.customer_trx_id
           AND TRX.complete_flag      = 'Y'
        FOR UPDATE SKIP LOCKED;
       
     CURSOR postable_adj (p_max_workers    NUMBER
                         ,p_start_date     DATE
                         ,p_post_thru_date DATE
                         ,p_set_of_books   NUMBER)
     IS
        SELECT AAA.ROWID
              ,(MOD(CEIL((DENSE_RANK() over(ORDER BY 
                    AAA.customer_trx_id))/p_batch_size), p_max_workers) + 1)  
          FROM ar_adjustments_all  AAA
              ,ra_customer_trx_all TRX
         WHERE AAA.gl_date BETWEEN p_start_date AND p_post_thru_date
           AND AAA.posting_control_id = -3
           AND AAA.set_of_books_id    = p_set_of_books
           AND NVL(AAA.postable,'Y')  ='Y'
           AND AAA.customer_trx_id    = TRX.customer_trx_id
           AND TRX.complete_flag      = 'Y'
        FOR UPDATE SKIP LOCKED;
          
     CURSOR postable_hist (p_max_workers    NUMBER
                          ,p_start_date     DATE
                          ,p_post_thru_date DATE
                          ,p_set_of_books   NUMBER)
     IS
        SELECT ATH.ROWID
              ,(MOD(CEIL((DENSE_RANK() over(ORDER BY             
                   ATH.customer_trx_id))/p_batch_size), p_max_workers) + 1)  
          FROM ar_transaction_history_all ATH
              ,ra_customer_trx_all        TRX
         WHERE ATH.gl_date BETWEEN p_start_date AND p_post_thru_date
           AND ATH.posting_control_id = -3
           AND TRX.set_of_books_id    = p_set_of_books
           AND ATH.postable_flag      = 'Y'
           AND ATH.customer_trx_id    = TRX.customer_trx_id
           AND TRX.complete_flag      = 'Y'
        FOR UPDATE SKIP LOCKED;
         
     TYPE rowid_table_type   IS  TABLE OF VARCHAR2(128) INDEX BY BINARY_INTEGER;
     TYPE worker_number_type IS  TABLE OF NUMBER        INDEX BY BINARY_INTEGER;
   
     gld_rowids rowid_table_type;
     worker_ids worker_number_type;
                        
     g_bulk_fetch_rows  NUMBER            := 10000;
     l_last_fetch       BOOLEAN           := FALSE;
     l_rows             NUMBER            := 0;
     l_total_rows       NUMBER            := 0;
     lc_error           VARCHAR2(100)     := NULL;
     lc_error_loc       VARCHAR2(2000)    := NULL;      
                        
  BEGIN
     lc_error_loc := 'Starting POPULATE_WORKER_TRX_ADJ Procedure';       
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Starting POPULATE_WORKER_TRX_ADJ for Transaction and Adjustment Processing');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');          
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');     

     lc_error_loc := 'Setting Org context';       
     FND_CLIENT_INFO.SET_ORG_CONTEXT(p_org_id);
      
     lc_error_loc := 'Evaluate Processing Type: TRX or ALL';       
     IF p_processing_type IN ('TRX', 'ALL') THEN
        lc_error_loc := 'Begin processing of postable TRX records';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ----------------------------------------------------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start Processing: RA_CUST_TRX_LINE_GL_DIST_ALL at '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
                  
        lc_error_loc := 'Select and update postable TRX records';
        OPEN postable_dist(p_max_workers
                          ,p_start_date
                          ,p_post_thru_date
                          ,p_set_of_books);
        LOOP
           -- Fetch the data in 10000 row blocks
           lc_error_loc := 'Bulk collect postable TRX records';
           FETCH postable_dist BULK COLLECT INTO gld_rowids, worker_ids
           LIMIT g_bulk_fetch_rows;
                               
           lc_error_loc := 'Check if selection of postable TRX records have been fetched';                                      
           IF gld_rowids.COUNT = 0 AND l_total_rows = 0 THEN
              lc_error_loc := 'No postable TRX rows were found for processing/updating';                                                 
              FND_FILE.PUT_LINE(FND_FILE.LOG,'    No postable rows were found for processing/updating.');               
              -- exiting loop due to no records where found for processing
              EXIT;              
           ELSIF gld_rowids.COUNT = 0 THEN
              lc_error_loc := 'Last fetch was completed for TRX records';                                                 
              FND_FILE.PUT_LINE(FND_FILE.LOG,'    Last fetch was completed.  All postable records have been updated.');
              -- exiting loop due to no more records to process
              EXIT;
           ELSE
              -- Update locked rows for current fetch (assigning worker number)
              lc_error_loc := 'Assign worker number to postable TRX records for current fetch';                    
              FORALL I IN 1 .. gld_rowids.COUNT
                 UPDATE ra_cust_trx_line_gl_dist_all GLD
                    SET GLD.posting_worker_number = worker_ids(i)
                  WHERE ROWID = gld_rowids(i);       
           
              lc_error_loc := 'Track row counts of updated postable TRX records.';             
              l_rows       := SQL%ROWCOUNT;
              l_total_rows := l_total_rows + l_rows;
           
           END IF;
        
        END LOOP;
        
        CLOSE postable_dist;  -- End of Bulk Fetch of transactions
        
        lc_error_loc := 'Add updated TRX rows to global variable'; 
        gn_total_updated_rows := gn_total_updated_rows + l_total_rows;
        
        lc_error_loc := 'End of processing for postable TRX records';                     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'    Rows Updated: ' || l_total_rows);      
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End Processing  : RA_CUST_TRX_LINE_GL_DIST_ALL at '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));              
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');                      
         
        lc_error_loc := 'Reset variables for processing TRX HIST records';                     
        l_total_rows := 0;
        l_last_fetch := FALSE;
                     
        lc_error_loc := 'Begin processing of TRX HIST postable records';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ----------------------------------------------------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start Processing: AR_TRANSACTION_HISTORY_ALL at '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        
        lc_error_loc := 'Select and update postable TRX HIST records';        
        OPEN postable_hist(p_max_workers
                          ,p_start_date
                          ,p_post_thru_date
                          ,p_set_of_books);
        LOOP
           --  Fetch the data in 10000 row blocks 
           lc_error_loc := 'Select and update postable TRX HIST records';
           FETCH postable_hist BULK COLLECT INTO gld_rowids, worker_ids
           LIMIT g_bulk_fetch_rows;

           lc_error_loc := 'Check if selection of postable TRX HIST records have been fetched';                                      
           IF gld_rowids.COUNT = 0 AND l_total_rows = 0 THEN
              lc_error_loc := 'No postable TRX HIST rows were found for processing/updating';                                                 
              FND_FILE.PUT_LINE(FND_FILE.LOG,'    No postable rows were found for processing/updating.');               
              -- exiting loop due to no records where found for processing
              EXIT;              
           ELSIF gld_rowids.COUNT = 0 THEN
              lc_error_loc := 'Last fetch was completed for TRX HIST';                                                 
              FND_FILE.PUT_LINE(FND_FILE.LOG,'    Last fetch was completed.  All postable records have been updated.');
              -- exiting loop due to no records to process
              EXIT;
           ELSE
              -- Update locked rows for current fetch (assigning worker number)
              lc_error_loc := 'Assign worker number to postable TRX HIST records for current fetch';                    
              FORALL i IN 1 .. gld_rowids.COUNT
                 UPDATE ar_transaction_history_all ATH
                    SET ATH.posting_worker_number = worker_ids(i)
                  WHERE ROWID = gld_rowids(i);

              lc_error_loc := 'Track row counts of updated postable TRX HIST records.';             
              l_rows       := SQL%ROWCOUNT;
              l_total_rows := l_total_rows + l_rows;
           
           END IF;
        
        END LOOP;
         
        CLOSE postable_hist;
        
        lc_error_loc := 'Add updated TRX HIST rows to global variable'; 
        gn_total_updated_rows := gn_total_updated_rows + l_total_rows;
                        
        lc_error_loc := 'End of processing for postable TRX HIST records';                      
        FND_FILE.PUT_LINE(FND_FILE.LOG,'    Rows Updated: ' || l_total_rows);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End Processing  : AR_TRANSACTION_HISTORY_ALL at '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));  
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');                      
        
     END IF; --- End of TRX processing
     
     lc_error_loc := 'Evaluate processing type: ADJ or ALL';       
     IF p_processing_type IN ('ADJ', 'ALL') THEN  
        lc_error_loc := 'Begin processing of ADJ postable records';        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ----------------------------------------------------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start Processing: AR_ADJUSTMENTS_ALL at '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
         
        lc_error_loc := 'Set variables for processing ADJ records';                
        l_total_rows := 0;
                         
        lc_error_loc := 'Select and update postable ADJ records';           
        OPEN postable_adj(p_max_workers
                         ,p_start_date
                         ,p_post_thru_date
                         ,p_set_of_books);
        LOOP
           -- Fetch the data in 10000 row blocks 
           lc_error_loc := 'Bulk collect postable ADJ records';
           FETCH postable_adj BULK COLLECT INTO gld_rowids, worker_ids
           LIMIT g_bulk_fetch_rows;
           
           lc_error_loc := 'Check if selection of postable ADJ records have been fetched';                                      
           IF gld_rowids.COUNT = 0 AND l_total_rows = 0 THEN
              lc_error_loc := 'No postable ADJ rows were found for processing/updating';                                                 
              FND_FILE.PUT_LINE(FND_FILE.LOG,'    No postable rows were found for processing/updating.');               
              -- exiting loop due to no records where found for processing
              EXIT;              
           ELSIF gld_rowids.COUNT = 0 THEN
              lc_error_loc := 'Last fetch was completed for ADJ';                                                 
              FND_FILE.PUT_LINE(FND_FILE.LOG,'    Last fetch was completed.  All postable records have been updated.');
              -- exiting loop due to no records to process
              EXIT;
           ELSE
              -- Update locked rows for current fetch (assigning worker number)
              lc_error_loc := 'Assign worker number to postable ADJ records for current fetch';                    
              FORALL i IN 1 .. gld_rowids.COUNT
                 UPDATE ar_adjustments_all AAA
                    SET AAA.posting_worker_number = worker_ids(i)
                  WHERE ROWID = gld_rowids(i);
                         
              lc_error_loc := 'Track row counts of updated postable ADJ records.';             
              l_rows       := SQL%ROWCOUNT;
              l_total_rows := l_total_rows + l_rows;
           
           END IF;           
                   
        END LOOP;
                            
        CLOSE postable_adj;
        
        lc_error_loc := 'Add updated ADJ rows to global variable'; 
        gn_total_updated_rows := gn_total_updated_rows + l_total_rows;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'    Rows Updated: ' || l_total_rows);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End Processing  : AR_ADJUSTMENTS_ALL at '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));  
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ----------------------------------------------------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');                      
                     
     END IF; -- End ADJUSTMENTS processing
               
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'   ');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'  No data error during transaction or adj processing (POPULATE_WORKER_TRX_ADJ) at: '||lc_error_loc);
          FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
          p_ret_code:=1;
             
     WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised during transaction or adj processing (POPULATE_WORKER_TRX_ADJ) at: '||lc_error_loc);
          FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised during transaction or adj processing at: '||lc_error_loc);
          p_ret_code:=2;
                  
  END POPULATE_WORKER_TRX_ADJ; 
            
--Changed the description of the procedure as per defect #4889
  -- +=========================================================================+
  -- | PROCEDURE NAME : POPULATE_WORKER_RECEIPTS                               |
  -- |                                                                         |
  -- | DESCRIPTION    : This private procedure inserts the data into interim   |
  -- |                  table and calls the XXARGLTR Program to Update below   |
  -- |                  tables                                                 |
  -- |                                                                         |
  -- |                     AR_MISC_CASH_DISTRIBUTIONS                          |
  -- |                     AR_RECEIVABLE_APPLICATIONS_ALL                      |
  -- |                     AR_CASH_RECEIPT_HISTORY                             |
  -- |                                                                         |
  -- | PARAMETERS     : p_max_workers    - Number of parallel workers/threads  |
  -- |                  p_start_date     - Starting GL Date                    |
  -- |                  p_post_thru_date - End GL Date                         |
  -- |                  p_set_of_books   - Set of Books ID                     |
  -- |                  p_org_id         - Organization ID                     |       
  -- |                  p_batch_size     - Batch size for assigning to worker  |
  -- |                                                                         |
  -- | RETURNS        : none                                                   |
  -- |                                                                         |
  -- +=========================================================================+
  PROCEDURE POPULATE_WORKER_RECEIPTS(p_max_workers     IN  NUMBER
                                    ,p_start_date      IN  DATE
                                    ,p_post_thru_date  IN  DATE
                                    ,p_set_of_books_id IN  NUMBER
                                    ,p_org_id          IN  NUMBER
                                    ,p_batch_size      IN  NUMBER
                                    ,p_errbuf          OUT VARCHAR2    --Added for defect#4889
                                    ,p_ret_code        OUT NUMBER)
  AS
--Commented for defect#4889--

   /*CURSOR lc_postable_receipts
     IS
        SELECT /*+ parallel(XAPWI,4)*/
               /*XAPWI.source_id
              ,XAPWI.worker_number
          FROM xx_ar_posting_worker_interim XAPWI
         WHERE XAPWI.org_id = p_org_id;
           
     TYPE worker_number_type   IS   TABLE OF NUMBER   INDEX BY BINARY_INTEGER;
     TYPE source_id_table_type IS   TABLE OF NUMBER   INDEX BY BINARY_INTEGER;
           
     worker_ids worker_number_type;
     x_source_id source_id_table_type;

     g_bulk_fetch_rows   NUMBER            := 10000;
     l_last_fetch        BOOLEAN           := FALSE;
     lc_error            VARCHAR2(10)      := NULL;
     ln_ara_rows         NUMBER            := 0;
     ln_ara_total_rows   NUMBER            := 0;
     ln_ach_rows         NUMBER            := 0;
     ln_ach_total_rows   NUMBER            := 0;
     ln_amc_rows         NUMBER            := 0;
     ln_amc_total_rows   NUMBER            := 0;*/

     ln_insert_count     NUMBER            := 0;
     ld_start_date       DATE;
     ld_post_thru_date   DATE;
     lc_error_loc        VARCHAR2(2000)    := NULL;

--   Start of adding variables for defect#4889  --

     l_reqid                  FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE  := NULL; 
     l_complete               BOOLEAN                                  := FALSE;
     lb_argltp_error          BOOLEAN                                  := FALSE;
     lc_phase                 VARCHAR2(50)                             := NULL;
     lc_status                VARCHAR2(50)                             := NULL;
     lc_devphase              VARCHAR2(50)                             := NULL;
     lc_devstatus             VARCHAR2(50)                             := NULL;
     lc_message               VARCHAR2(50)                             := NULL;
     ln_argltp_error_cnt      NUMBER                                   := 0;
     ln_argltp_warning_cnt    NUMBER                                   := 0;
     ln_idx                   NUMBER                                   := 0;
     ln_max_wait              NUMBER                                   := 36000;

     TYPE data_table_type IS RECORD (
        reqids      NUMBER,
        prgm_name   VARCHAR2(50));
                  
     TYPE lt_rec_tab IS TABLE OF data_table_type
        INDEX BY BINARY_INTEGER;
                  
     tb_rec_data    lt_rec_tab;
--   End of changes for defect#4889  --

  BEGIN

     EXECUTE IMMEDIATE 'ALTER TABLE xxfin.xx_ar_posting_worker_interim TRUNCATE PARTITION XX_AR_POSTING_WORKER_ITM_'||to_char(p_org_id);
   
     ld_start_date         := TO_DATE((p_start_date    ||' 00:00:00'),'DD-MON-RR HH24:MI:SS');
     ld_post_thru_date     := TO_DATE((p_post_thru_date||' 23:59:59'),'DD-MON-RR HH24:MI:SS');

     lc_error_loc := 'Starting POPULATE_WORKER_RECEIPTS Procedure';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Starting POPULATE_WORKER_RECEIPTS for Receipt Processing');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');          
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');     

     lc_error_loc := 'Setting Org context';       
     FND_CLIENT_INFO.SET_ORG_CONTEXT(p_org_id);
      
     -- Identify the postable receipts and cache worker for each cash_receipt_id 
     lc_error_loc := 'Inserting postable receipts IDs into global temp table';       
     INSERT INTO xx_ar_posting_worker_interim
        SELECT cr.org_id 
              ,cr.cash_receipt_id
              ,MOD(CEIL((DENSE_RANK() over(ORDER BY             
                      cr.cash_receipt_id))/p_batch_size), p_max_workers) + 1
         FROM ar_cash_receipts CR
             ,(
               SELECT /*+ index(ARA AR_RECEIVABLE_APPLICATIONS_N11) */ ARA.org_id
                     ,ARA.cash_receipt_id
                 FROM ar_receivable_applications ARA
                WHERE ARA.gl_date BETWEEN ld_start_date AND ld_post_thru_date
                  AND ARA.posting_control_id       = -3
                  AND NVL(ARA.postable, 'Y')       = 'Y'
                  AND NVL(ARA.confirmed_flag, 'Y') = 'Y'
                  AND ARA.status = DECODE(ARA.application_type, 'CASH', ARA.status,
                                    'CM', DECODE(ARA.applied_payment_schedule_id, 
                                     -8, 'ACTIVITY','APP'))
               UNION
               SELECT /*+ index(ACH AR_CASH_RECEIPT_HISTORY_N4) */ ACH.org_id
                     ,ACH.cash_receipt_id
                 FROM ar_cash_receipt_history  ACH
                WHERE ACH.gl_date BETWEEN ld_start_date AND ld_post_thru_date
                  AND ACH.posting_control_id = -3
                  AND ACH.postable_flag      = 'Y'
               UNION
               SELECT /*+ index(AMC AR_MISC_CASH_DISTRIBUTIONS_N4) */ AMC.org_id
                     ,AMC.cash_receipt_id
                 FROM ar_misc_cash_distributions AMC
                WHERE AMC.gl_date BETWEEN ld_start_date AND ld_post_thru_date
                  AND AMC.posting_control_id = -3
              ) PR
        WHERE CR.cash_receipt_id = PR.cash_receipt_id;

        ln_insert_count := SQL%ROWCOUNT;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'    Rows inserted into XX_AR_POSTING_WORKER_INTERIM   : ' || ln_insert_count);
        
     COMMIT;                    
--Start of changes for defect#4889--
              -- Submitting a OD: AR Prepare Receipts for GL Transfer Program for each worker number
              lc_error_loc := 'Submitting XXARGLTR for each worker ';
              FOR i IN 1..p_max_workers 
              LOOP
                 l_reqid:= '';
                 l_reqid := FND_REQUEST.SUBMIT_REQUEST(application => 'xxfin'
                                                      ,program     => 'XXARGLTR'
                                                      ,sub_request => FALSE
                                                      ,argument1   => i
                                                      ,argument2   => p_org_id
                                                      ,argument3   => p_start_date
                                                      ,argument4   => p_post_thru_date);
                 lc_error_loc := 'Commit XXARGLTR worker submission number: ' || i;
                 COMMIT;                                             
                         
                 -- Write submission information to request log
                 lc_error_loc := 'Checking request submission for XXARGLTR worker number: ' || i;        
                 IF l_reqid = 0 THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error in submitting the XXARGLTR for worker number: '||i);
                    p_ret_code := 2;
                 ELSE
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Submitted Request XXARGLTR for worker number# '||i||' : '||l_reqid);
                 END IF;
                           
                 -- Track concurrent request for request output                                                   
                 lc_error_loc := 'Track single XXARGLTR submssion for reporting';
                 tb_rec_data(ln_idx).reqids    := l_reqid;
                 tb_rec_data(ln_idx).prgm_name := 'OD: AR Prepare Receipts for GL Transfer';
                 ln_idx                        := ln_idx + 1;
                               
              END LOOP;
                          
              -- Wait for every OD: AR Prepare Receipts for GL Transfer Program to complete
              -- Check every 60 seconds for 600 minutes        
              lc_error_loc := 'Wait for parallel XXARGLTR submissions to complete';
              FOR i IN tb_rec_data.FIRST .. tb_rec_data.LAST
              LOOP
                 l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => tb_rec_data(i).reqids
                                                              ,INTERVAL   => 60
                                                              ,max_wait   => ln_max_wait
                                                              ,phase      => lc_phase
                                                              ,status     => lc_status
                                                              ,dev_phase  => lc_devphase
                                                              ,dev_status => lc_devstatus
                                                              ,message    => lc_message); 
                 
                 -- Check completion status of each XXARGLTR and track number of ERRORS and WARNINGS
                 lc_error_loc := 'Check request status XXARGLTR worker number: ' || i;
                 IF UPPER(lc_status) = 'ERROR' THEN
                    ln_argltp_error_cnt   := ln_argltp_error_cnt + 1;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  XXARGLTR worker number '||i||' completed in ERROR status.  RID: '||tb_rec_data(i).reqids);
                 ELSIF UPPER(lc_status) = 'WARNING' THEN
                    ln_argltp_warning_cnt := ln_argltp_warning_cnt + 1;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  XXARGLTR worker number '||i||' completed in WARNING status.  RID: '||tb_rec_data(i).reqids);
                 END IF;
                                   
              END LOOP; -- end check for XXARGLTR submission status
                        
              -- Set concurrent request status of parallel program based on
              --  completion status of child workers - XXARGLTR
              IF ln_argltp_error_cnt > 0 THEN
                 p_errbuf         := ln_argltp_error_cnt   || ' child XXARGLTR requests completed in ERROR';
                 p_ret_code       := 2;
                 -- When this variable is assigned ERROR at least once, it should not populate worker receipts.
                 lb_argltp_error := TRUE;
              ELSIF ln_argltp_warning_cnt > 0 THEN
                 p_errbuf         := ln_argltp_warning_cnt || ' child XXARGLTR requests completed in WARNING';
                 p_ret_code       := 1;
              END IF;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'   ');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'No data error during receipt processing (POPULATE_WORKER_RECEIPTS) at: '||lc_error_loc);
          FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
          p_ret_code:=1;

     WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'   ');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised during receipt processing (POPULATE_WORKER_RECEIPTS) at: '||lc_error_loc);
          FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised during receipt processing at: '||lc_error_loc);
          p_ret_code:=2;
                     
  END POPULATE_WORKER_RECEIPTS;

  -- +=========================================================================+
  -- | PROCEDURE NAME : PREPARE_RECEIPTS                                       |
  -- |                                                                         |
  -- | DESCRIPTION    : This local procedure updates posting_worker_number     |
  -- |                  column on the following tables when the submitting the |
  -- |                  GL Transfer with more than 1 worker/thread             |
  -- |                                                                         |
  -- |                     AR_MISC_CASH_DISTRIBUTIONS                          |
  -- |                     AR_RECEIVABLE_APPLICATIONS_ALL                      |
  -- |                     AR_CASH_RECEIPT_HISTORY                             |
  -- |                                                                         |
  -- | PARAMETERS     : p_worker_number  - Number of parallel workers/threads  |
  -- |                  p_org_id         - Organization ID                     |
  -- |                  p_start_date     - Starting GL Date                    |
  -- |                  p_post_thru_date - End GL Date                         |
  -- |                                                                         |
  -- | RETURNS        : none                                                   |
  -- |                                                                         |
  -- +=========================================================================+
  PROCEDURE PREPARE_RECEIPTS(x_errbuf          OUT VARCHAR2
                            ,x_retcode         OUT NUMBER
                            ,p_worker_number   IN  NUMBER
                            ,p_org_id          IN  NUMBER
                            ,p_start_date      IN  DATE
                            ,p_post_thru_date  IN  DATE)
  AS
     CURSOR lc_postable_receipts
     IS
        SELECT /*+ parallel(XAPWI,4)*/
               XAPWI.source_id
              ,XAPWI.worker_number
        FROM xx_ar_posting_worker_interim XAPWI
        WHERE XAPWI.org_id = p_org_id
          AND XAPWI.worker_number = p_worker_number;

     TYPE worker_number_type   IS   TABLE OF NUMBER   INDEX BY BINARY_INTEGER;
     TYPE source_id_table_type IS   TABLE OF NUMBER   INDEX BY BINARY_INTEGER;
           
     worker_ids worker_number_type;
     x_source_id source_id_table_type;

     ld_start_date       DATE              := TO_DATE((p_start_date    ||' 00:00:00'),'DD-MON-RR HH24:MI:SS');
     ld_post_thru_date   DATE              := TO_DATE((p_post_thru_date||' 23:59:59'),'DD-MON-RR HH24:MI:SS');
     lc_error_loc        VARCHAR2(2000)    := NULL;
     ln_bulk_fetch_rows  NUMBER            := 10000;
     ln_ara_rows         NUMBER            := 0;
     ln_ara_total_rows   NUMBER            := 0;
     ln_ach_rows         NUMBER            := 0;
     ln_ach_total_rows   NUMBER            := 0;
     ln_amc_rows         NUMBER            := 0;
     ln_amc_total_rows   NUMBER            := 0;

  BEGIN
--End of changes for defect#4889--
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ----------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Begin Updating Receipt tables '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
     lc_error_loc := 'Update postable rows';  
     OPEN lc_postable_receipts;
     LOOP
        -- Fetch the data in 10000 row blocks 
        lc_error_loc := 'Bulk collect postable records';
        FETCH lc_postable_receipts BULK COLLECT INTO x_source_id, worker_ids
      --LIMIT g_bulk_fetch_rows;               --Commented for defect#4889
        LIMIT ln_bulk_fetch_rows;              --Added for defect#4889

        lc_error_loc := 'Check if selection of postable records have been fetched';                                      
        IF (x_source_id.COUNT = 0 AND 
            ln_ara_total_rows = 0 AND
            ln_amc_total_rows = 0 AND 
            ln_ach_total_rows = 0) THEN
           lc_error_loc := 'No postable rows were found for processing/updating';                                                 
           FND_FILE.PUT_LINE(FND_FILE.LOG,'    No postable rows were found for processing/updating.');               
           -- exiting loop due to no records where found for processing
           EXIT;              
        ELSIF x_source_id.COUNT = 0 THEN
           lc_error_loc := 'Last fetch was completed for postable rows';                                                 
           FND_FILE.PUT_LINE(FND_FILE.LOG,'    Last fetch was completed.  All postable records have been updated.');
           -- exiting loop due to no more records to process
           EXIT;
        ELSE
           -- Update locked rows for current fetch (assigning worker number)
           lc_error_loc := 'Assign worker number to postable records for current fetch';                    
           FORALL i IN 1 .. x_source_id.COUNT
              UPDATE /*+ index(ACH AR_CASH_RECEIPT_HISTORY_N1)*/ ar_cash_receipt_history_all ACH
                 SET ACH.posting_worker_number = worker_ids(i)
               WHERE ACH.cash_receipt_id       = x_source_id(i)
                 AND ACH.org_id                = p_org_id
                 AND ACH.gl_date BETWEEN ld_start_date AND ld_post_thru_date
                 AND ACH.posting_control_id = -3
                 AND ACH.postable_flag      = 'Y';

           ln_ach_rows       := SQL%ROWCOUNT;
           ln_ach_total_rows := ln_ach_total_rows + ln_ach_rows;

           FORALL i IN 1 .. x_source_id.COUNT
              UPDATE /*+ index(AMC AR_MISC_CASH_DISTRIBUTIONS_N1)*/ ar_misc_cash_distributions_all AMC
                 SET AMC.posting_worker_number = worker_ids(i)
               WHERE AMC.cash_receipt_id       = x_source_id(i)
                 AND AMC.org_id                = p_org_id               
                 AND AMC.posting_control_id    = -3
                 AND AMC.gl_date BETWEEN ld_start_date AND ld_post_thru_date;
           
           ln_amc_rows       := SQL%ROWCOUNT;
           ln_amc_total_rows := ln_amc_total_rows + ln_amc_rows;

           FORALL i IN 1 .. x_source_id.COUNT
              UPDATE /*+ index(ARA AR_RECEIVABLE_APPLICATIONS_N1)*/ ar_receivable_applications_all ARA
                 SET ARA.posting_worker_number = worker_ids(i)
               WHERE ARA.cash_receipt_id       = x_source_id(i)
                 AND ARA.org_id                = p_org_id               
                 AND ARA.posting_control_id    = -3
                 AND ARA.gl_date BETWEEN ld_start_date AND ld_post_thru_date
                 AND NVL(ARA.postable, 'Y')    = 'Y'
                 AND NVL(ARA.confirmed_flag,'Y') = 'Y'
                 AND ARA.status = DECODE(ARA.application_type, 'CASH', ARA.status,
                                                                 'CM', DECODE(ARA.applied_payment_schedule_id, 
                                                                   -8, 'ACTIVITY','APP'));

           ln_ara_rows       := SQL%ROWCOUNT;
           ln_ara_total_rows := ln_ara_total_rows + ln_ara_rows;
           
        END IF;
                     
     END LOOP;
                 
     CLOSE lc_postable_receipts;

     FND_FILE.PUT_LINE(FND_FILE.LOG,'    Rows Updated for AR_CASH_RECEIPT_HISTORY_ALL   : ' || ln_ach_total_rows);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'    Rows Updated for AR_MISC_CASH_DISTRIBUTIONS_ALL: ' || ln_amc_total_rows);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'    Rows Updated for AR_RECEIVABLE_APPLICATIONS_ALL: ' || ln_ara_total_rows);     
     FND_FILE.PUT_LINE(FND_FILE.LOG,' ');                           
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  End Processing at '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));  
     FND_FILE.PUT_LINE(FND_FILE.LOG,' ');                      
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ----------------------------------------------------------------------------------------------');

     gn_total_updated_rows := gn_total_updated_rows + 
                              ln_ach_total_rows     + 
                              ln_amc_total_rows     +
                              ln_ara_total_rows;

  EXCEPTION
     WHEN NO_DATA_FOUND THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'   ');
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'No data error during receipt processing (POPULATE_WORKER_RECEIPTS) at: '||lc_error_loc);  --Commented for defect#4889
          FND_FILE.PUT_LINE(FND_FILE.LOG,'No data error during receipt processing (PREPARE_RECEIPTS) at: '||lc_error_loc);          --Added for defect#4889
          FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
        --p_ret_code:=1;               --Commented for defect#4889
          x_retcode:=1;                --Added for defect#4889

     WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'   ');
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised during receipt processing (POPULATE_WORKER_RECEIPTS) at: '||lc_error_loc);  --Commented for defect#4889
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised during receipt processing (PREPARE_RECEIPTS) at: '||lc_error_loc);          --Added for defect#4889
          FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised during receipt processing at: '||lc_error_loc);
        --p_ret_code:=2;               --Commented for defect#4889
          x_retcode:=2;                --Added for defect#4889

  END PREPARE_RECEIPTS;                --Added for defect#4889
--END POPULATE_WORKER_RECEIPTS;        --Commented for defect#4889

  -- +=========================================================================+
  -- | PROCEDURE  : MAIN                                                       |
  -- |                                                                         |
  -- | RICE#      : E2050                                                      |
  -- |                                                                         |
  -- | DESCRIPTION: This procedure is registered as concurrent program.  It    |
  -- |              can be submitted for 1 or more threads of ARGLTP.  When    |
  -- |              submitted for multiple workers (parallel), the following   |
  -- |              steps are performed.                                       |
  -- |                  Step#1 - Submit Revenue Recognition                    |
  -- |                  Step#2 - Submit Revenue Analyzer                       |
  -- |                  Step#3 - Delete AR_CCID_CORRECTIONS                    |
  -- |                  Step#4 - Populate Worker Number Columns                |
  -- |                  Step#5 - Submit ARGLTP parallel threads                |
  -- |                                                                         | 
  -- |              This program can also be submit the Unposted Items Report, |
  -- |              submit for 1 thread of ARGLTP (which takes care of steps 1 |
  -- |              to 4 automatically), or reprocess a failed parallel worker |
  -- |                                                                         |
  -- |              This program uses two procedures to prepare/update         |
  -- |              postable records for the following tables based on supplied|
  -- |              parameters.                                                |
  -- |                                                                         |
  -- |              AR_MISC_CASH_DISTRIBUTIONS                                 |
  -- |              AR_RECEIVABLE_APPLICATIONS_ALL                             |
  -- |              AR_CASH_RECEIPT_HISTORY                                    |
  -- |              RA_CUST_TRX_LINE_GL_DIST_ALL                               |
  -- |              AR_ADJUSTMENTS_ALL                                         |
  -- |              AR_TRANSACTION_HISTORY_ALL                                 |
  -- |                                                                         |
  -- | Parameters :  p_start_date     - Starting GL Date                       |
  -- |               p_end_date       - Ending GL Date                         |
  -- |               p_gl_posted_date - Posting date assigned to transfered rec| 
  -- |               p_report_only    - Determines report or update mode       |
  -- |               p_summary_flag   - Determines how journal is imported     |
  -- |               p_journal_import - Determines if journal import submitted |
  -- |               p_posting_days_per_cycle - Determines number of cycles    | 
  -- |               p_posting_control_id     - Default posting control id     |        
  -- |               p_debug_flag             - Debug parameter                | 
  -- |               p_org_id                 - Organization ID                |
  -- |               p_sob_id                 - Set of books ID                |
  -- |               p_processing_type        - Transaction Type               |
  -- |               p_worker_number          - Worker for reprocessing        |
  -- |               p_max_workers            - Number of workers used         |
  -- |               p_skip_unposted_items    - Skip unposted report Y/N       | 
  -- |               p_skip_revenue           - Skip unposted report Y/N       |
  -- |               p_batch_size     - Batch size used for assigning to worker|
  -- |                                                                         |
  -- | Returns     : x_errbuf         - error message                          |
  -- |             : x_retcode        - return code used for request status    |
  -- |                                                                         |
  -- |Version   Date         Author               Remarks                      |
  -- |=======   ===========  ===================  =============================|
  -- |1.0       20-NOV-2009  Sreelatha Givvimani  Intial version - Defect 3260 |
  -- +=========================================================================+
  PROCEDURE MAIN(x_errbuf                    OUT NOCOPY VARCHAR2
                ,x_retcode                   OUT NOCOPY NUMBER
                ,p_gl_start_date             IN  VARCHAR2
                ,p_gl_end_date               IN  VARCHAR2
                ,p_gl_posted_date            IN  VARCHAR2
                ,p_report_only               IN  VARCHAR2
                ,p_summary_flag              IN  VARCHAR2
                ,p_journal_import            IN  VARCHAR2
                ,p_posting_days_per_cycle    IN  NUMBER
                ,p_posting_control_id        IN  NUMBER
                ,p_debug_flag                IN  VARCHAR2
                ,p_org_id                    IN  NUMBER
                ,p_sob_id                    IN  NUMBER
                ,p_processing_type           IN  VARCHAR2
                ,p_worker_number             IN  NUMBER
                ,p_max_workers               IN  NUMBER
                ,p_skip_unposted_items       IN  VARCHAR2
                ,p_skip_revenue              IN  VARCHAR2
                ,p_batch_size                IN  NUMBER
                )                            
  IS
     ln_user_id               NUMBER                                   := NULL;
     ld_start_date            DATE                                     := NULL;
     ld_post_through_date     DATE                                     := NULL;
     ld_gl_posted_date        DATE                                     := NULL;
     ld_run_date              DATE                                     := NULL;
     lb_req_status            BOOLEAN                                  := NULL;
     lc_phase                 VARCHAR2(50)                             := NULL;
     lc_status                VARCHAR2(50)                             := NULL;
     lc_devphase              VARCHAR2(50)                             := NULL;
     lc_devstatus             VARCHAR2(50)                             := NULL;
     lc_message               VARCHAR2(50)                             := NULL;
     l_reqid                  FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE  := NULL;
     l_complete               BOOLEAN                                  := FALSE;
     l_coa                    NUMBER                                   := NULL;
     l_cur                    VARCHAR2(10)                             := NULL;
     ln_rows                  NUMBER                                   := 0;
     lc_msg                   VARCHAR2(100)                            := NULL;
     ln_master_reqid          NUMBER                                   := 0;
     ln_idx                   NUMBER                                   := 0;
     l_req_data               VARCHAR2(20)                             := NULL;
     ln_max_wait              NUMBER                                   := 36000;
     lc_error_loc             VARCHAR2(2000)                           := NULL;                                      
     lb_rev_recog_error       BOOLEAN                                  := FALSE;
     lb_rev_contin_error      BOOLEAN                                  := FALSE;
     lb_del_ar_ccid_error     BOOLEAN                                  := FALSE;
     lb_argltp_error          BOOLEAN                                  := FALSE;
     ln_argltp_error_cnt      NUMBER                                   := 0;
     ln_argltp_warning_cnt    NUMBER                                   := 0;
     ln_ar_ccid_rows          NUMBER                                   := 0;
                       
     TYPE data_table_type IS RECORD (
        reqids      NUMBER,
        prgm_name   VARCHAR2(50));
                  
     TYPE lt_rec_tab IS TABLE OF data_table_type
        INDEX BY BINARY_INTEGER;
                  
     tb_rec_data    lt_rec_tab;
               
  BEGIN
     lc_error_loc := 'Starting Main Procedure';

     -- Initialize Variables and Set Context
     lc_error_loc := 'Set org context and initial variables in Main procedure';
     ln_master_reqid      := fnd_global.conc_request_id;        
     ld_start_date        := FND_DATE.CANONICAL_TO_DATE(p_gl_start_date);
     ld_post_through_date := FND_DATE.CANONICAL_TO_DATE(p_gl_end_date);
     ld_gl_posted_date    := FND_DATE.CANONICAL_TO_DATE(p_gl_posted_date);
     ln_user_id           := NVL(fnd_global.user_id, -1);
     FND_CLIENT_INFO.SET_ORG_CONTEXT(p_org_id); 
                                                        
     -- Write parameter values to the concurrent request log file
     lc_error_loc := 'Write parameter values to log file';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Parameters Passed in       :');
     FND_FILE.PUT_LINE(FND_FILE.LOG,' GL Start Date              :'||p_gl_start_date           );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' GL End Date                :'||p_gl_end_date             );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' GL Posted Date             :'||p_gl_posted_date          );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Report Only                :'||p_report_only             );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Summary Flag               :'||p_summary_flag            );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Run Journal Import         :'||p_journal_import          );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Posting Days per Cycle     :'||p_posting_days_per_cycle  );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Posting Control Id         :'||p_posting_control_id      );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Debug Mode                 :'||p_debug_flag              );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Org ID                     :'||p_org_id                  );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Set of Books Id            :'||p_sob_id                  );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Processing type            :'||p_processing_type         );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Worker Number              :'||p_worker_number           );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Max Workers                :'||p_max_workers             );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Skip Unposted Items Report :'||p_skip_unposted_items     );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Skip Revenue Programs      :'||p_skip_revenue            );
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Batch Size                 :'||p_batch_size              );          
     FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');

     -- Write RICE# to log
     lc_error_loc := 'Write RICE# to concurrent request log file';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'***** See RICE# E2050 for Design Information *****');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'');                                                  
     
     -- Write report header information to the concurrent request output file      
     lc_error_loc := 'Write report header information to log file';
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'__________________________________________________________________________________________________');        
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Office Depot                                                                             '||SYSDATE);
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '||ln_master_reqid);
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                          OD: AR Parallel GL Transfer Program                              ');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Parameters:');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Start Date        : '||p_gl_start_date);
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   End Date          : '||p_gl_end_date);
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   GL Posted Date    : '||p_gl_posted_date);
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Processing Type   : '||p_processing_type);
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Max Workers       : '||p_max_workers);
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Worker Number     : '||p_worker_number);
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Skip Unposted     : '||p_skip_unposted_items);
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Skip Rev Programs : '||p_skip_revenue);
                                                                 
     IF p_debug_flag = 'Y' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting the main program : '||l_req_data);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'General Ledger Transfer Programs (children) will be submitted with debug turned ON');        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
     END IF;  
                                                 
     -- This IF statement is used to determine the number of General Ledger Transfer Programs 
     -- that should be submitted based on the max worker parameter               
      
     lc_error_loc := 'Checking if value used for max workers';
     IF p_max_workers = 0 THEN
             -- Set program to error status since max workers should be 1 or more
        lc_error_loc := 'Set program to error status due to max workers being 0';
        x_errbuf  := 'No programs are submitted with max workers is 0';
        x_retcode := 1; 
                                                 
     ELSIF p_max_workers = 1  THEN
        -- One instance/concurrent request is submitted for the General Ledger Transfer Program
        -- Revenue programs and Unposted Items Report will be submitted as normal                 
        lc_error_loc := 'Max workers set to 1 - submitting single ARGLTP';        
        l_reqid := '';
        l_reqid := FND_REQUEST.SUBMIT_REQUEST('AR'
                                             ,'ARGLTP'
                                             ,NULL
                                             ,NULL
                                             ,FALSE
                                             ,TO_CHAR(ld_start_date,'YYYY/MM/DD HH:MI:SS')
                                             ,TO_CHAR(ld_post_through_date,'YYYY/MM/DD HH:MI:SS')
                                             ,TO_CHAR(ld_gl_posted_date,'YYYY/MM/DD HH:MI:SS')
                                             ,p_report_only
                                             ,p_summary_flag
                                             ,p_journal_import      
                                             ,p_posting_days_per_cycle
                                             ,p_posting_control_id
                                             ,p_debug_flag 
                                             ,p_org_id
                                             ,p_sob_id
                                             ,p_processing_type
                                             ,p_skip_unposted_items);
        lc_error_loc := 'Committing single ARGLTP submission';                
        COMMIT;
          
        -- Write submission information to request log
        lc_error_loc := 'Checking if single ARGLTP was submitted properly';        
        IF l_reqid = 0 THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in submitting the request for single ARGLTP : ');
           x_retcode := 2;
        ELSE
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitted Requests for single ARGLTP : '||l_reqid);
        END IF;
                                    
        -- Wait for single General Ledger Transfer Program to complete
        -- Checks every 60 seconds        
        lc_error_loc := 'Wait for single ARGLTP to complete';        
        l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => l_reqid
                                                     ,INTERVAL   => 60
                                                     ,max_wait   => ln_max_wait
                                                     ,phase      => lc_phase
                                                     ,status     => lc_status
                                                     ,dev_phase  => lc_devphase
                                                     ,dev_status => lc_devstatus
                                                     ,message    => lc_message);   
                            
        -- Track concurrent request for request output                                  
        lc_error_loc := 'Track single ARGLTP submssion for reporting';        
        ln_idx                        := ln_idx + 1;                                                     
        tb_rec_data(ln_idx).reqids    := l_reqid;
        tb_rec_data(ln_idx).prgm_name := 'General Ledger Transfer Program';
         
        -- Set concurrent request status of parallel program based on the
        -- single General Ledger Transfer Program request completion status        
        lc_error_loc := 'Check request status for single ARGLTP submission';
        IF UPPER(lc_status) = 'ERROR' THEN
           x_errbuf  := lc_message;
           x_retcode := 2;
           lb_argltp_error := TRUE;
        ELSIF UPPER(lc_status) = 'WARNING' THEN
           x_errbuf  := lc_message;
           x_retcode := 1;         
        END IF;        
                                      
     -- Multiple GL Transfer Programs will be submitted when p_max_workers > 1     
     ELSIF p_max_workers > 1  THEN
        lc_error_loc := 'Begin submisssion of multiple parallel ARGLTP requests';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Max workers greater than 1.  Parallel ARGLTP will be submitted.');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');                         
        
        -- Check if revenue programs should be submitted or not
        -- The programs are submitted automatically when one worker is used              
        lc_error_loc := 'Check with revenue programs to submit';
        IF p_skip_revenue  = 'N' THEN

           -------------------------------------------------------------
           -- Parallel Processing Step#1 - Revenue Recognition        --
           -------------------------------------------------------------
           
           -- Obtain information for set of books
           -- Information is required for submitting revenue programs          
           lc_error_loc := 'Obtain set of books info for revenue programs';
           SELECT chart_of_accounts_id 
                 ,currency_code
           INTO   l_coa
                 ,l_cur
           FROM   gl_sets_of_books sob
           WHERE  sob.set_of_books_id = p_sob_id;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Set of Books ID      : ' || l_cur);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Chart of Accounts ID : ' || l_coa);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Currency Code        : ' || l_cur);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
               
           -- Submit Revenue Recognition concurrent program                        
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
           lc_error_loc := 'Submit Revenue Recognition program';
           l_reqid := '';
           l_reqid := FND_REQUEST.SUBMIT_REQUEST(application => 'AR'
                                                ,program     => 'ARBARL'
                                                ,sub_request => FALSE
                                                ,argument1   => ln_user_id
                                                ,argument2   => l_coa
                                                ,argument3   => p_report_only 
                                                ,argument4   => 'N'           
                                                ,argument5   => 'Y'   
                                                ,argument6   => p_debug_flag
                                                ,argument7   => p_org_id
                                                ,argument8   => 'Y'        
                                                ,argument9   => 'Y');       
           lc_error_loc := 'Committing Revenue Recognition submission';
           COMMIT;
                       
           -- Write submission information to request log
           lc_error_loc := 'Checking if Revenue Recognition was submitted properly';
           IF l_reqid = 0 THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error in submitting the Revenue Recognition: ');
              x_errbuf  := 'Error in submitting the Revenue Recognition';
              x_retcode := 2;
           ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  Successfully Submitted Revenue Recognition         : '||l_reqid);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
              
              -- Track concurrent request for request output                                  
              lc_error_loc := 'Track Revenue Recognition submssion for reporting';
              tb_rec_data(ln_idx).reqids    := l_reqid;
              tb_rec_data(ln_idx).prgm_name := 'Revenue Recognition';
              ln_idx                        := ln_idx + 1;  
             
              -- Wait for Revenue Recognition to complete
              -- Check every 5 seconds for 600 minutes        
              lc_error_loc := 'Wait for Revenue Recognition to complete';
              l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => l_reqid
                                                           ,INTERVAL   => 5
                                                           ,max_wait   => ln_max_wait
                                                           ,phase      => lc_phase
                                                           ,status     => lc_status
                                                           ,dev_phase  => lc_devphase
                                                           ,dev_status => lc_devstatus
                                                           ,message    => lc_message);
              
              -- Set concurrent request status of parallel program based on the
              -- Revenue Recognition request completion status   
              lc_error_loc := 'Check request status for Revenue Recognition submission';
              IF UPPER(lc_status) = 'ERROR' THEN
                 lb_rev_recog_error := TRUE;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'  Revenue Recognition completed in ERROR status.  RID: '||l_reqid);
                 x_errbuf  := lc_message;
                 x_retcode := 2;
              ELSIF UPPER(lc_status) = 'WARNING' THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'  Revenue Recognition completed in WARNING status.  RID: '||l_reqid);
                 x_errbuf  := lc_message;
                 x_retcode := 1;
              END IF;
               
           END IF; -- end checking of revenue recognition
           
           -------------------------------------------------------------
           -- Parallel Processing Step#2 - Revenue Analyzer           --
           -------------------------------------------------------------
           IF NOT lb_rev_recog_error THEN
              -- Submit Revenue Contingency Analyzer concurrent program             
              lc_error_loc := 'Submit Revenue Contingency Analyzer program';
              l_reqid := '';
              l_reqid :=  FND_REQUEST.SUBMIT_REQUEST (application => 'AR'
                                                     ,program     => 'ARREVSWP'
                                                     ,sub_request => FALSE);
              lc_error_loc := 'Committing Revenue Contingency Analyzer submission';
              COMMIT;                                   
                                  
              -- Write submission information to request log
              lc_error_loc := 'Checking if Revenue Contingency Analyzer was submitted properly';
              IF l_reqid = 0 THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,  '  Error in submitting the Revenue Contingency Analyzer: ');
                 x_retcode := 2;
              ELSE
                 FND_FILE.PUT_LINE(FND_FILE.LOG,  '  Successfully Submitted Revenue Contingency Analyzer: '||l_reqid);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,  '  ');
                 -- Track concurrent request for request output                                  
                 lc_error_loc := 'Track Revenue Contingency Analyzer submssion for reporting';
                 tb_rec_data(ln_idx).reqids    := l_reqid;
                 tb_rec_data(ln_idx).prgm_name := 'Revenue Contingency Analyzer';
                 ln_idx                        := ln_idx + 1;                                                     
                     
                 -- Wait for Revenue Contingency Analyzer to complete
                 -- Check every 5 seconds for 600 minutes        
                 lc_error_loc := 'Wait for Revenue Contingency Analyzer to complete';
                 l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => l_reqid
                                                              ,INTERVAL   => 5
                                                              ,max_wait   => ln_max_wait
                                                              ,phase      => lc_phase
                                                              ,status     => lc_status
                                                              ,dev_phase  => lc_devphase
                                                              ,dev_status => lc_devstatus
                                                              ,message    => lc_message);
              
                 -- Set concurrent request status of parallel program based on 
                 -- The Revenue Contingency Analyzer request completion status        
                 lc_error_loc := 'Check request status for Revenue Contingency Analyzer submission';
                 IF UPPER(lc_status) = 'ERROR' THEN
                    lb_rev_contin_error := TRUE;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Revenue Contingency Analyzer completed in ERROR status.  RID: '||l_reqid);
                    x_errbuf  := lc_message;
                    x_retcode := 2;
                 ELSIF UPPER(lc_status) = 'WARNING' THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Revenue Contingency Analyzer completed in WARNING status.  RID: '||l_reqid);
                    x_errbuf  := lc_message;
                    x_retcode := 1;         
                 END IF;
                     
              END IF;  -- End checking of Revenue Contingency Analyzer Completion Status
              
           END IF; -- End checking for submitting Revenue Contingency Analyzer Program
                  
        END IF; -- End of Revenue programs
        
        -------------------------------------------------------------
        -- Parallel Processing Step#3 - Delete AR_CCID_CORRECTIONS --
        -------------------------------------------------------------
        -- Clear AR_CCID_CORRECTIONS when multiple General Ledger Transfer
        -- Programs are submitted.  A single GL Transfer handles this
        -- automatically.
        -- Delete ar_ccid_corrections only if both revenue programs completed successfully.
        
        lc_error_loc := 'Checking completion status of both revenue programs';
        IF lb_rev_recog_error OR lb_rev_contin_error THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  One or both of the revenue programs failed'||
                                          ' AR_CCID_CORRECTIONS will not be deleted.');
        ELSE
           
           lc_error_loc := 'Deleting AR_CCID_CORRECTIONS';
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
           BEGIN
              DELETE FROM AR_CCID_CORRECTIONS;
              ln_ar_ccid_rows := SQL%rowcount;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rows deleted from AR_CCID_CORRECTIONS: '||ln_ar_ccid_rows);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
           
           EXCEPTION
              WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error in deleting the CCID corrections (MAIN) at: '||lc_error_loc);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
                 x_retcode := 2;
                 x_errbuf  := 'Deletion of AR_CCID_CORRECTIONS failed.  See log file.';
                 lb_del_ar_ccid_error := TRUE;
           END;              
        END IF; -- end of error check for revenue programs                            
        
        IF lb_rev_recog_error   OR  
           lb_rev_contin_error  OR 
           lb_del_ar_ccid_error THEN
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   ');
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Parallel General Ledger Transfer '||
                                             'Program could not submitted due to an error.');
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'See Log File for more information.');
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   ');
           
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Parallel General Ledger Transfer '||
                                            'Programs were not submitted due to an error');           
           FND_FILE.PUT_LINE(FND_FILE.LOG,'   ');
        ELSE  -- continue processing
              
           -- Submit the Individual Worker (ARGLTP) for reprocessing if worker
           -- worker number is passed in as a parameter value        
           lc_error_loc := 'Reprocess individual ARGLTP';
           IF p_worker_number IS NOT NULL THEN
              lc_error_loc := 'Submit single ARGLTP for reprocessing';
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  REPROCESSING will be performed for prior run.  Worker# '||p_worker_number);                             
              l_reqid := '';
              l_reqid := FND_REQUEST.SUBMIT_REQUEST('AR'
                                                   ,'ARGLTP'
                                                   ,NULL
                                                   ,NULL
                                                   ,FALSE
                                                   ,TO_CHAR(ld_start_date,'YYYY/MM/DD HH:MI:SS')
                                                   ,TO_CHAR(ld_post_through_date,'YYYY/MM/DD HH:MI:SS')
                                                   ,TO_CHAR(ld_gl_posted_date,'YYYY/MM/DD HH:MI:SS')
                                                   ,p_report_only
                                                   ,p_summary_flag
                                                   ,p_journal_import       
                                                   ,p_posting_days_per_cycle
                                                   ,p_posting_control_id
                                                   ,p_debug_flag 
                                                   ,p_org_id
                                                   ,p_sob_id
                                                   ,p_processing_type
                                                   ,p_skip_unposted_items
                                                   ,p_worker_number
                                                   ,'');
              lc_error_loc := 'Committing single ARGLTP reprocessing submission';
              COMMIT;
                                
              -- Write submission information to request log             
              lc_error_loc := 'Checking if single ARGLTP for reprocessing was submitted properly';
              IF l_reqid = 0 THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error in submitting the Single ARGLTP program for REPROCESSING: ');
                 x_retcode := 2;
              ELSE
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'  Submitted Single ARGLTP request for REPROCESSING');
              END IF;
                              
              -- Wait for single General Ledger Transfer Program to complete
              -- Check every 60 seconds for 600 minutes        
              lc_error_loc := 'Wait for single ARGLTP reprocessing request to complete';
              l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => l_reqid
                                                           ,INTERVAL   => 60
                                                           ,max_wait   => ln_max_wait
                                                           ,phase      => lc_phase
                                                           ,status     => lc_status
                                                           ,dev_phase  => lc_devphase
                                                           ,dev_status => lc_devstatus
                                                           ,message    => lc_message);      
                      
              -- Track concurrent request for request output                                  
              lc_error_loc := 'Track single ARGLTP reprocessing submssion for reporting';
              tb_rec_data(ln_idx).reqids    := l_reqid;
              tb_rec_data(ln_idx).prgm_name := 'General Ledger Transfer Program';
              ln_idx                        := ln_idx + 1;                                                     
                    
              -- Set concurrent request status of parallel program based on the
              -- General Ledger Transfer Program request completion status        
              lc_error_loc := 'Check request status for single ARGLTP reprocesing submission';
              IF UPPER(lc_status) = 'ERROR' THEN
                 x_errbuf  := lc_message;
                 x_retcode := 2;
                 lb_argltp_error := TRUE;
              ELSIF UPPER(lc_status) = 'WARNING' THEN
                 x_errbuf  := lc_message;
                 x_retcode := 1;         
              END IF;   
                 
           ELSIF p_worker_number IS NULL THEN  
              
              -------------------------------------------------------------
              -- Parallel Processing Step#4 - Populate Worker Number     --
              -------------------------------------------------------------
              
              lc_error_loc := 'Populate Worker Numbers for Parallel ARGLTP processing';
              IF p_processing_type IN ('TRX','ADJ','ALL') THEN          
                 -- This procedure is cused to populate the worker number
                 -- for identify and marking postable transactions and adjustments
                 -- with a worker number           
                 lc_error_loc := 'Execute POPULATE_WORKER_TRX_ADJ for transactions and adj';
                 POPULATE_WORKER_TRX_ADJ(p_max_workers
                                        ,ld_start_date
                                        ,ld_post_through_date
                                        ,p_sob_id
                                        ,p_org_id
                                        ,p_batch_size
                                        ,p_processing_type
                                        ,x_retcode);
              END IF;

              IF p_processing_type IN ('REC', 'ALL') THEN  
                 -- This procedure is used to populate the worker number
                 -- for identifying and marking postable receipts with a worker number
                 lc_error_loc := 'Execute POPULATE_WORKER_RECEIPTS for receipts';
                 POPULATE_WORKER_RECEIPTS(p_max_workers
                                         ,ld_start_date
                                         ,ld_post_through_date
                                         ,p_sob_id
                                         ,p_org_id
                                         ,p_batch_size
                                         ,x_errbuf       --Added parameter for defect#4889
                                         ,x_retcode); 
              END IF;

              lc_error_loc := 'Writing total updated rows to log file'; 
              FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  Total Rows Updated: ' || gn_total_updated_rows);
              FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
              FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
              
              -------------------------------------------------------------
              -- Parallel Processing Step#5 - Submit Workers             --
              -------------------------------------------------------------
              
              -- Submit a General Ledger Transfer Program for each worker number
              lc_error_loc := 'Submit parallel workers for ARGLTP';
              FOR I IN 1..p_max_workers 
              LOOP
                 l_reqid:= '';
                 l_reqid := FND_REQUEST.SUBMIT_REQUEST('AR'
                                                      ,'ARGLTP'
                                                      ,NULL
                                                      ,NULL
                                                      ,FALSE
                                                      ,TO_CHAR(ld_start_date,'YYYY/MM/DD HH:MI:SS')
                                                      ,TO_CHAR(ld_post_through_date,'YYYY/MM/DD HH:MI:SS')
                                                      ,TO_CHAR(ld_gl_posted_date,'YYYY/MM/DD HH:MI:SS')
                                                      ,p_report_only
                                                      ,p_summary_flag
                                                      ,p_journal_import       
                                                      ,p_posting_days_per_cycle
                                                      ,p_posting_control_id
                                                      ,p_debug_flag 
                                                      ,p_org_id
                                                      ,p_sob_id
                                                      ,p_processing_type
                                                      ,p_skip_unposted_items
                                                      ,I
                                                      ,'');  
                 lc_error_loc := 'Commit ARGLTP worker submission number: ' || I;
                 COMMIT;                                             
              -- Write submission information to request log
                 lc_error_loc := 'Checking request submission for ARLGTP worker number: ' || I;        
                 IF l_reqid = 0 THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error in submitting the ARGLTP for worker number: '||I);
                    x_retcode := 2;
                 ELSE
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Submitted Request ARGLTP for worker number# '||I||' : '||l_reqid);
                 END IF;
                           
                 -- Track concurrent request for request output                                                   
                 lc_error_loc := 'Track single ARGLTP submssion for reporting';
                 tb_rec_data(ln_idx).reqids    := l_reqid;
                 tb_rec_data(ln_idx).prgm_name := 'General Ledger Transfer Program';
                 ln_idx                        := ln_idx + 1;                                                     
                               
              END LOOP;
                          
              -- Wait for every General Ledger Transfer Program to complete
              -- Check every 60 seconds for 600 minutes        
              lc_error_loc := 'Wait for parallel ARGLTP submissions to complete';
              FOR I IN tb_rec_data.FIRST .. tb_rec_data.LAST
              LOOP
                 l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => tb_rec_data(I).reqids
                                                              ,INTERVAL   => 60
                                                              ,max_wait   => ln_max_wait
                                                              ,phase      => lc_phase
                                                              ,status     => lc_status
                                                              ,dev_phase  => lc_devphase
                                                              ,dev_status => lc_devstatus
                                                              ,message    => lc_message); 
                 
                 -- Check completion status of each ARGLTP and track number of ERRORS and WARNINGS
                 lc_error_loc := 'Check request status ARGLTP worker number: ' || I;
                 IF UPPER(lc_status) = 'ERROR' THEN
                    ln_argltp_error_cnt   := ln_argltp_error_cnt + 1;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  ARGLTP worker number '||I||' completed in ERROR status.  RID: '||tb_rec_data(I).reqids);
                 ELSIF UPPER(lc_status) = 'WARNING' THEN
                    ln_argltp_warning_cnt := ln_argltp_warning_cnt + 1;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  ARGLTP worker number '||I||' completed in WARNING status.  RID: '||tb_rec_data(I).reqids);
                 END IF;
                                   
              END LOOP; -- end check for ARGLTP submission status
                        
              -- Set concurrent request status of parallel program based on
              --  completion status of child workers - ARGLTP
              IF ln_argltp_error_cnt > 0 THEN
                 x_errbuf         := ln_argltp_error_cnt   || ' child ARGLTP requests completed in ERROR';
                 x_retcode        := 2;
                 -- When this variable is assigned ERROR at least once, Unposted Items Report will not be submitted.
                 lb_argltp_error := TRUE;
              ELSIF ln_argltp_warning_cnt > 0 THEN
                 x_errbuf         := ln_argltp_warning_cnt || ' child ARGLTP requests completed in WARNING';
                 x_retcode        := 1;
              END IF;   
                     
           END IF; -- p_worker_number check to determine reprocessing or not
                        
        END IF; -- end of prerequsite error check before parallel ARGLTP processing
                                                
     END IF; -- p_max_workers check to determine number of parallel ARGLTP workers
     
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
     
     lc_error_loc := 'Check for errors prior to Unposted Items processing ';
     IF lb_rev_recog_error   OR 
        lb_rev_contin_error  OR
        lb_del_ar_ccid_error OR
        lb_argltp_error      THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Unposted Items Report was not submitted due to '||           
                                         'revenue programs or deletion of ar_ccid_corrections. ');           
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');           
     ELSE
        lc_error_loc := 'Check if processing required for unposted';                                                                                          
        IF p_skip_unposted_items = 'N' THEN
           -- Submit Unposted Items Report     
           lc_error_loc := 'Submit Unposted Items Report';
           l_reqid:= '';
           l_reqid := FND_REQUEST.SUBMIT_REQUEST(application => 'AR'
                                                ,program     => 'ARXGER'
                                                ,sub_request => FALSE
                                                ,argument1   => p_sob_id
                                                ,argument2   => ''
                                                ,argument3   => p_gl_start_date
                                                ,argument4   => p_gl_posted_date
                                                ,argument5   => '-999'
                                                ,argument6   => '-999'
                                                ,argument7   => '-999'
                                                ,argument8   => '-999'
                                                ,argument9   => '-999'
                                                ,argument10  => '-999');
           lc_error_loc := 'Commit Unposted Items Report request submission';
           COMMIT;
                                                        
           -- Write submission information to request log
           lc_error_loc := 'Checking if Unposted Items Report was submitted properly';
           IF l_reqid = 0 THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error in submitting the Unposted Items Report: ');
              x_retcode := 1;
           ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  Submitted Unposted Items Report: '||l_reqid);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
           END IF;
                                     
           -- Track concurrent request for request output                                                                                              
           lc_error_loc := 'Track Unposted Items Report submssion for reporting';
           tb_rec_data(ln_idx).reqids    := l_reqid;
           tb_rec_data(ln_idx).prgm_name := 'Unposted Items Report';
           ln_idx                        := ln_idx + 1;                                                     
                               
           -- Wait for Unposted Items Report to complete
           -- Check every 60 seconds for 600 minutes        
           lc_error_loc := 'Wait for Unposted Items Report to complete';
           l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => l_reqid
                                                        ,INTERVAL   => 60
                                                        ,max_wait   => ln_max_wait
                                                        ,phase      => lc_phase
                                                        ,status     => lc_status
                                                        ,dev_phase  => lc_devphase
                                                        ,dev_status => lc_devstatus
                                                        ,message    => lc_message);
                                                                            
           -- Set concurrent request status of parallel program based on the
           -- Unposted Items Report request completion status        
           lc_error_loc := 'Check request status for Unposted Items Report submission';
           IF UPPER(lc_status) = 'ERROR' THEN
              x_errbuf  := lc_message;
              x_retcode := 2;
           ELSIF UPPER(lc_status) = 'WARNING' THEN
              x_errbuf  := lc_message;
              x_retcode := 1;         
           END IF;                                
                                    
              END IF; -- End of Unposted Items Report
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        
     END IF; -- End check for prerequisite processing inorder to submit unposted
     
     -- Write heading information to output for submitted requests      
     lc_error_loc := 'Write heading info to output for submitted requests';
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                          ');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                          ');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Child Processes Submitted:');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                          ');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                          ');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request_id          Concurrent Program                       Phase                   Status    ');        
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------          --------------------------------         ---------               ------    ');        
                      
     -- Obtain information about each submitted request and write to output
     lc_error_loc := 'Obtain request status for each submitted program and write to output';
     FOR I IN tb_rec_data.FIRST .. tb_rec_data.LAST
     LOOP
        l_complete := FND_CONCURRENT.GET_REQUEST_STATUS(tb_rec_data(i).reqids 
                                                       ,NULL 
                                                       ,NULL
                                                       ,lc_phase 
                                                       ,lc_status 
                                                       ,lc_devphase 
                                                       ,lc_devstatus 
                                                       ,lc_message); 
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,''||tb_rec_data(i).reqids||'             '||RPAD(tb_rec_data(i).prgm_name,32)||'        '||lc_phase||'               '||lc_status);        
     END LOOP;
                      
     -- Write to output to indicate end of report
     lc_error_loc := 'Write end of report message to output';
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                 ');        
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                               End Of the Report                                 ');        
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'_________________________________________________________________________________________________');        
                     
  EXCEPTION      
     WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'   ');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised at: '||lc_error_loc);
          FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised at: '||lc_error_loc);
          x_retcode := 2;
                      
  END MAIN;
                     
END XX_AR_GL_PARALLEL_PKG;
/
SHOW ERRORS;
