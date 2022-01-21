SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF 
SET FEEDBACK OFF
SET TERM ON  

PROMPT Creating Package Body XX_AR_GL_TRANSFER_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AR_GL_TRANSFER_PKG
AS
-- +=======================================================================+
-- |                     Office Depot - Project Simplify                   |
-- |                          WIPRO Technologies                           |
-- +=======================================================================+
-- | Name :    XX_AR_GL_TRANSFER_PKG                                       |
-- | RICE :    E2015                                                       |
-- | Description : This package is used to submit the General Ledger       |
-- |               transfer program for AR                                 |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version  Date         Author         Remarks                           |
-- |=======  ===========  =============  ================================= |
-- | 1.0     14-OCT-2008  Aravind A      Initial version                   |
-- | 1.1     06-JAN-2009  P.Marco        Defect 12063.  Added no data found|
-- |                                     exception to force program to end |
-- |                                     with warning                      |
-- | 1.2     26-AUG-2009  Ganga Devi R   Added FULL hint per defect #2014  |
-- | 1.3     16-SEP-2009  Harini G       Added p_debug_mode parameter as   |
-- |                                     per the defect #2504              |
-- | 1.4     23-SEP-2009  Sneha Anand    Added if logic for defect #2555   |
-- | 1.5     28-DEC-2009  RamyaPriya M   Modified for Defect #2851         |
-- | 1.6     31-DEC-2009  Sneha Anand    Modified for the Defect #2851     |
-- | 1.7     15-JAN-2010  Sneha Anand    Perf Changes for Defect #2851     |
-- | 1.8     19-JAN-2010  Sneha Anand    Changes for Defect 2851 to add    |
-- |                                     period_name column to cntrl table |
-- | 1.9     29-JAN-2010  R.Aldridge     Defect 2851 Change parameters for |
-- |                                     submitting staging under xxfin    |
-- |                                     instead AR                        |
-- | 2.0     29-MAR-2010  R.Aldridge     Defect 4925 - 10.3 Release.  The  |
-- |                                     OD: AR HV Staging program needs to|
-- |                                     submitted via a parameter now and |
-- |                                     it will be submitted for source   |
-- |                                     only.                             |
-- | 2.1    26-OCT-2015  Vasu Raparla    Removed Schema References         |
-- |                                     for R12.2                         |
-- +=======================================================================+
-- +=======================================================================+
-- | Name        : SUBMIT_PROGRAM                                          |
-- | Description : The procedure is used to accomplish the following       |
-- |               tasks:                                                  |
-- |               1. Submit the OD: AR Parallel GL Transfer Program       |
-- |               2. Submit the General Ledger Transfer Program           |
-- |                  in multithread through the parallel program          |
-- |               3. Log the details about the GL Transfer program to     |
-- |                  the custom table XX_GL_HIGH_VOLUME_JRNL_CONTROL      |
-- |               4. Submit the OD: AR HV Journal Staging Program         |
-- |                                                                       |
-- | Parameters  :  p_start_date                                           |
-- |               ,p_post_through_date                                    |
-- |               ,p_gl_posted_date                                       |
-- |               ,p_set_of_books_id                                      |
-- |               ,p_org_id                                               |
-- |               ,p_transaction_type                                     |
-- |               ,p_wave_num                                             |
-- |               ,p_run_date                                             |
-- |               ,p_child_to_xptr                                        |
-- |               ,p_email_id                                             |
-- |               ,p_worker_number                                        |
-- |               ,p_max_workers                                          |
-- |               ,p_skip_unposted_items                                  |
-- |               ,p_skip_revenue_programs                                |
-- |               ,p_batch_size                                           |
-- |               ,p_debug_mode                                           |
-- |               ,p_submit_hv_staging                                    |
-- |                                                                       |
-- | Returns     :  x_error_buff                                           |
-- |               ,x_ret_code                                             |
-- +=======================================================================+
   -- -------------------------------------------
   -- Global Variables
   -- -------------------------------------------
   gc_receivables       VARCHAR2(25)  DEFAULT  'Receivables';
   gn_request_id        NUMBER        :=  FND_GLOBAL.CONC_REQUEST_ID;   -- Added for Defect 2851
   gn_gl_trf_req_id     fnd_concurrent_requests.request_id%TYPE;        -- Added for Defect 2851
   gn_gl_stg_req_id     fnd_concurrent_requests.request_id%TYPE;        -- Added for Defect 2851

   PROCEDURE SUBMIT_PROGRAM(x_error_buff            OUT      VARCHAR2
                           ,x_ret_code              OUT      NUMBER
                           ,p_start_date            IN       VARCHAR2
                           ,p_post_through_date     IN       VARCHAR2
                           ,p_gl_posted_date        IN       VARCHAR2
                           ,p_set_of_books_id       IN       NUMBER     -- Added for Defect 2851
                           ,p_org_id                IN       NUMBER     -- Added for Defect 2851
                           ,p_transaction_types     IN       VARCHAR2
                           ,p_wave_num              IN       NUMBER
                           ,p_run_date              IN       VARCHAR2
                           ,p_child_to_xptr         IN       VARCHAR2
                           ,p_email_id              IN       VARCHAR2
                           ,p_worker_number         IN       NUMBER     -- Added for Defect 2851
                           ,p_max_workers           IN       NUMBER     -- Added for Defect 2851
                           ,p_skip_unposted_items   IN       VARCHAR2   -- Added for Defect 2851
                           ,p_skip_revenue_programs IN       VARCHAR2   -- Added for Defect 2851
                           ,p_batch_size            IN       NUMBER
                           ,p_debug_mode            IN       VARCHAR2   -- Added for Defect 2504 (v1.3)
                           ,p_submit_hv_staging     IN       VARCHAR2   -- Added for Defect 4925 (v2.0)
                           )
   IS
      ln_gl_trf_req_id          fnd_concurrent_requests.request_id%TYPE                 := 0;
      ln_rec_multi_req_id       fnd_concurrent_requests.request_id%TYPE                 := 0;
      ln_conc_prog_id           fnd_concurrent_requests.concurrent_program_id%TYPE      := 0;
      ln_application_id         fnd_concurrent_requests.program_application_id%TYPE     := 0;
      ln_request_id             fnd_concurrent_requests.request_id%TYPE                 := 0;
      ln_par_req_id             fnd_concurrent_requests.parent_request_id%TYPE          := 0;
      lc_req_state              fnd_concurrent_requests.status_code%TYPE                := NULL;
      ld_req_date               fnd_concurrent_requests.request_date%TYPE               := NULL;
      ld_act_strt_date          fnd_concurrent_requests.actual_start_date%TYPE          := NULL;
      ld_act_comp_date          fnd_concurrent_requests.actual_completion_date%TYPE     := NULL;
      lc_currency               gl_interface.currency_code%TYPE                         := NULL;
      ln_count                  NUMBER                                                  := 0;
      ln_total_cr               gl_interface.entered_cr%TYPE                            := 0;
      ln_total_dr               gl_interface.entered_dr%TYPE                            := 0;
      ln_group_id               gl_interface.group_id%TYPE                              := 0;
      lc_error_loc              VARCHAR2(200)                                           := NULL;
      lc_object_type            xx_com_error_log.object_type%TYPE                       := 'AR to GL Transfer';
      ln_object_id              xx_com_error_log.object_id%TYPE                         := 0;
      lc_error_msg              xx_com_error_log.error_message%TYPE                     := 0;
      ld_start_date             DATE                                                    := NULL;
      ld_post_through_date      DATE                                                    := NULL;
      ld_gl_posted_date         DATE                                                    := NULL;
      ld_run_date               DATE                                                    := NULL;
      lb_req_status             BOOLEAN                                                 := NULL;
      lc_phase                  VARCHAR2(50)                                            := NULL;
      lc_status                 VARCHAR2(50)                                            := NULL;
      lc_devphase               VARCHAR2(50)                                            := NULL;
      lc_devstatus              VARCHAR2(50)                                            := NULL;
      lc_message                VARCHAR2(50)                                            := NULL;
      lb_req_status_mul         BOOLEAN                                                 := NULL;
      lb_print_option           BOOLEAN;
      lc_phase_mul              VARCHAR2(50)                                            := NULL;
      lc_status_mul             VARCHAR2(50)                                            := NULL;
      lc_devphase_mul           VARCHAR2(50)                                            := NULL;
      lc_devstatus_mul          VARCHAR2(50)                                            := NULL;
      lc_message_mul            VARCHAR2(50)                                            := NULL;
      ln_posting_days           ar_system_parameters.posting_days_per_cycle%TYPE        := NULL;
      lc_debug_mode             fnd_lookups.meaning%TYPE                                := NULL;
      ln_org_id                 ar_system_parameters.org_id%TYPE                        := NULL;
      ln_set_of_books_id        ar_system_parameters.set_of_books_id%TYPE               := NULL;
      ln_sob_id                 NUMBER;
      ln_multi_ro_mail_req_id   fnd_concurrent_requests.request_id%TYPE                 := 0;
      ln_gltp_ro_mail_req_id    fnd_concurrent_requests.request_id%TYPE                 := 0;
      ln_gl_imp_req_id          fnd_concurrent_requests.request_id%TYPE                 := 0;     -- Added for Defect #2555
      ln_this_request_id        fnd_concurrent_requests.request_id%TYPE                 := 0;     -- Added for Defect 2851
      ln_ref_count              NUMBER;                                                           -- Added for Defect 2851
      lc_insert_status          VARCHAR2(2)                                             := NULL;  -- added for defect 2851 - Sneha on 15.1.2010
      lc_compl_stat             BOOLEAN;                                                          -- added for defect 2851 - Sneha on 15.1.2010
      lc_period_start           VARCHAR2(15);                                                     -- added for defect 2851 - Sneha on 19.1.2010
      lc_period_end             VARCHAR2(15);                                                     -- added for defect 2851 - Sneha on 19.1.2010
      lc_report_only            VARCHAR2(5)                                             := 'N';
      lc_post_in_summary        VARCHAR2(5)                                             := 'Y';
      lc_run_journal_import     VARCHAR2(5)                                             := 'N';
      ln_posting_control_id     NUMBER                                                  := -99;
      lc_journal_source         VARCHAR2(15)                                            := 'Receivables';
      lc_chk_flag               VARCHAR2(120)                                           := NULL;
      ln_hv_stg_req_id          fnd_concurrent_requests.request_id%TYPE                 := 0;
      lc_request_data           VARCHAR2(120);
      lc_status_code            fnd_concurrent_requests.status_code%TYPE                := NULL;
      lc_status_code_stg        fnd_concurrent_requests.status_code%TYPE                := NULL;
      ln_sum_cr_entered         NUMBER                                                  :=0;
      ln_sum_dr_entered         NUMBER                                                  :=0;
      ln_total_count            NUMBER                                                  :=0;

      CURSOR lcu_req_summary   -- To get the Child Processes Submitted
      IS
         SELECT request_id                         REQUEST_ID
               ,user_concurrent_program_name       USER_CONCURRENT_PROGRAM_NAME
               ,DECODE(phase_code, 'C', 'Completed'
                                  ,'I', 'Inactive'
                                  ,'P', 'Pending'
                                  ,'R', 'Running')  PHASE_CODE
               ,DECODE(status_code,'C','Normal'
                                  ,'X','Terminated'
                                  ,'G','Warning'
                                  ,'W','Paused'
                                  ,'E','Error')    STATUS_CODE
           FROM fnd_conc_req_summary_v
          WHERE parent_request_id = gn_request_id
         UNION ALL
         SELECT request_id                         REQUEST_ID
               ,user_concurrent_program_name       USER_CONCURRENT_PROGRAM_NAME
               ,DECODE(phase_code, 'C', 'Completed'
                                  ,'I', 'Inactive'
                                  ,'P', 'Pending'
                                  ,'R', 'Running')  PHASE_CODE
               ,DECODE(status_code,'C','Normal'
                                  ,'X','Terminated'
                                  ,'G','Warning'
                                  ,'W','Paused'
                                  ,'E','Error')    STATUS_CODE
           FROM fnd_conc_req_summary_v
          WHERE parent_request_id = gn_gl_trf_req_id
          ORDER BY request_id;

      CURSOR lcu_log_req_summ_det    -- To get the General Ledger Transfer Program Details
      IS
         SELECT request_id
               ,status_code                -- Added for Defect #2851 - Sneha 15.1.10
           FROM fnd_conc_req_summary_v
          WHERE parent_request_id  = gn_gl_trf_req_id
            AND program_short_name = 'ARGLTP';
       
      CURSOR lcu_cntrl_info_summary  -- To get the Status of Interfaces
      IS
         SELECT XGHVJC.parent_request_id
               ,XGHVJC.request_id
               ,FCRSV.user_concurrent_program_name
               ,XGHVJC.gl_interface_group_id
               ,XGHVJC.volume
               ,XGHVJC.entered_dr
               ,XGHVJC.entered_cr
               ,XGHVJC.currency
               ,XGHVJC.interface_status
           FROM xx_gl_high_volume_jrnl_control XGHVJC
               ,fnd_conc_req_summary_v FCRSV
          WHERE XGHVJC.parent_request_id = gn_gl_trf_req_id
            AND XGHVJC.request_id        = FCRSV.request_id
            AND XGHVJC.set_of_books_id   = p_set_of_books_id;

      ltab_req_summ_rec        lcu_req_summary%ROWTYPE;
      ltab_cntrl_summ_rec      lcu_cntrl_info_summary%ROWTYPE;
      ltab_log_req_summ_rec    lcu_log_req_summ_det%ROWTYPE;

   BEGIN
      ln_this_request_id := fnd_global.conc_request_id; -- added for performance issue for defect 2851 - Sneha on 15.1.2010

      IF (NVL(SUBSTR(lc_chk_flag,1,INSTR(lc_chk_flag,'-',1)-1),'FIRST') <> 'COMPLETE') THEN
         lc_error_loc := 'Converting the date parameters';
         ld_start_date         := FND_DATE.CANONICAL_TO_DATE(p_start_date);
         ld_post_through_date  := FND_DATE.CANONICAL_TO_DATE(p_post_through_date);
         ld_gl_posted_date     := FND_DATE.CANONICAL_TO_DATE(p_gl_posted_date);
         ld_run_date           := FND_DATE.CANONICAL_TO_DATE(p_run_date);
         lc_chk_flag           := FND_CONC_GLOBAL.request_data;             -- Added for Defect # 2851

         -----------------------------------------------
         --  Submit OD: AR Parallel GL Transfer Program
         -----------------------------------------------
         FND_FILE.PUT_LINE(FND_FILE.LOG,' [WIP] Request_data - '||lc_chk_flag );
         
         SELECT posting_days_per_cycle
           INTO ln_posting_days
           FROM ar_system_parameters_all
          WHERE org_id = p_org_id
            AND set_of_books_id = p_set_of_books_id;
         
         --Added the below section on 19.1.2010 to compare the start and end date periods
         SELECT period_name 
           INTO lc_period_start
           FROM gl_periods GP
          WHERE GP.period_set_name = 'OD 445 CALENDAR'
            AND ld_start_date BETWEEN GP.start_date AND GP.end_date;
         
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Start Date Period: '||lc_period_start );
         
         SELECT period_name 
           INTO lc_period_end
           FROM gl_periods GP
          WHERE GP.period_set_name = 'OD 445 CALENDAR'
            AND ld_post_through_date BETWEEN GP.start_date AND GP.end_date;
          
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Post Through Date Period: '||lc_period_end );
         
         --The code changes done on 19.1.2010 ends
         IF (NVL(SUBSTR(lc_chk_flag,1,INSTR(lc_chk_flag,'-',1)-1),'FIRST') ='FIRST') THEN
            IF (lc_period_start = lc_period_end) THEN                                         -- Added for defect 2851 - Sneha on 19.1.2010
               BEGIN
                  ----------------------
                  -- Log Section --Start
                  ----------------------
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************OD: AR General Ledger Transfer Program**********************************');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters of the current Request:');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_start_date           : '||p_start_date);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_post_through_date    : '||p_post_through_date);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_gl_posted_date       : '||p_gl_posted_date);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_set_of_books_id      : '||p_set_of_books_id);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_org_id               : '||p_org_id);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_transaction_type     : '||p_transaction_types);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_wave_num             : '||p_wave_num);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_run_date             : '||p_run_date);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_child_to_xptr        : '||p_child_to_xptr);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_email_id             : '||p_email_id);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_worker_number        : '||p_worker_number);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_max_workers          : '||p_max_workers);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_skip_unposted_items  : '||p_skip_unposted_items);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_skip_revenue_programs: '||p_skip_revenue_programs);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_batch_size           : '||p_batch_size);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_debug_mode           : '||p_debug_mode);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_submit_hv_staging    : '||p_submit_hv_staging);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************************************************************************************');
                  ----------------------
                  -- Log Section --Ends
                  ----------------------
                  lc_error_loc := 'Step #1 - Submit OD: AR Parallel GL Transfer Program ';
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Step #1 - Submit OD: AR Parallel GL Transfer Program');
                  ln_gl_trf_req_id := FND_REQUEST.SUBMIT_REQUEST('XXFIN'
                                                                ,'XXARGLTM'
                                                                ,''
                                                                ,SYSDATE
                                                                ,TRUE
                                                                ,TO_CHAR(ld_start_date,'YYYY/MM/DD HH:MI:SS')
                                                                ,TO_CHAR(ld_post_through_date,'YYYY/MM/DD HH:MI:SS')
                                                                ,TO_CHAR(ld_gl_posted_date,'YYYY/MM/DD HH:MI:SS')
                                                                ,lc_report_only
                                                                ,lc_post_in_summary
                                                                ,lc_run_journal_import
                                                                ,ln_posting_days
                                                                ,ln_posting_control_id
                                                                ,p_debug_mode
                                                                ,p_org_id
                                                                ,p_set_of_books_id
                                                                ,p_transaction_types
                                                                ,p_worker_number
                                                                ,p_max_workers
                                                                ,p_skip_unposted_items
                                                                ,p_skip_revenue_programs
                                                                ,p_batch_size);
                  COMMIT;
                  lc_request_data := 'SECOND'||'-'||ln_gl_trf_req_id;

               EXCEPTION
                  WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_loc);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'--'||SQLERRM);
               END;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID  :'||ln_gl_trf_req_id);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Pause on the Main Transfer Program ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
               FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=> lc_request_data);
               RETURN;
            ELSE                                                                                   -- added for defect 2851 - Sneha on 19.1.2010
               FND_FILE.PUT_LINE(FND_FILE.LOG,'The Start Date and Post Through Date fall in different Periods, hence the Parallel Program is not submitted'); -- Added for defect 2851 - Sneha on 19.1.2010
               x_ret_code   := 2;                                                                  -- added for defect 2851 - Sneha on 19.1.2010
               RETURN;                                                                             -- added for defect 2851 - Sneha on 19.1.2010
            END IF;                                                                                -- added for defect 2851 - Sneha on 19.1.2010
         END IF;
          
         -------------------------------------------------------------------------------------
         --Step 2: Capture summary information if Parallel program does not complete in Error
         -------------------------------------------------------------------------------------
         IF (NVL(SUBSTR(lc_chk_flag,1,INSTR(lc_chk_flag,'-',1)-1),'FIRST') ='SECOND') THEN
            
            gn_gl_trf_req_id := TO_NUMBER(SUBSTR(lc_chk_flag,INSTR(lc_chk_flag,'-',1)+1));

            SELECT status_code
              INTO lc_status_code
              FROM fnd_concurrent_requests
             WHERE request_id = gn_gl_trf_req_id;

             FND_FILE.PUT_LINE(FND_FILE.LOG,'Status of Parallel Program: '||lc_status_code);
             lc_error_loc     := 'Step #2 - Capture Summary/Control Interface Information';
             
             -----------------------
             -- LOG Section - Start
             -----------------------
             FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
             FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: AR Parallel GL Transfer Program -- Request ID  :'||gn_gl_trf_req_id);
             FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Step #2 - Capture Summary/Control Interface Information');
             FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
             FND_FILE.PUT_LINE(FND_FILE.LOG,'General Ledger Transfer Program -- Request ID Details:');
             FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

             -- To get the General Ledger Transfer Program Details
             OPEN lcu_log_req_summ_det;
             LOOP
                FETCH lcu_log_req_summ_det INTO ltab_log_req_summ_rec;
                EXIT WHEN lcu_log_req_summ_det%NOTFOUND;
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID:  '||ltab_log_req_summ_rec.request_id);
                IF ltab_log_req_summ_rec.status_code='E' THEN
                   x_ret_code   := 2;
                END IF;
             END LOOP;
             CLOSE lcu_log_req_summ_det;

             ----------------------
             -- LOG Section - Ends
             ----------------------
             BEGIN
                INSERT INTO xx_gl_high_volume_jrnl_control(request_id
                                                          ,parent_request_id
                                                          ,program_short_name
                                                          ,concurrent_program_id
                                                          ,program_application_id
                                                          ,responsibility_id
                                                          ,responsibility_application_id
                                                          ,request_status
                                                          ,request_start_date
                                                          ,request_end_date
                                                          ,user_je_source_name
                                                          ,org_id
                                                          ,set_of_books_id
                                                          ,volume
                                                          ,currency
                                                          ,entered_dr
                                                          ,entered_cr
                                                          ,accounted_dr
                                                          ,accounted_cr
                                                          ,process_date
                                                          ,event_number
                                                          ,gl_interface_group_id
                                                          ,interface_status
                                                          ,journal_import_group_id
                                                          ,request_argument_text
                                                          ,creation_date
                                                          ,created_by
                                                          ,last_update_date
                                                          ,last_updated_by
                                                          ,period_name                             -- added for defect 2851 - Sneha on 19.1.2010
                                                          )
                                                          (SELECT GI.request_id
                                                                  ,FCR.parent_request_id
                                                                  ,'ARGLTP'
                                                                  ,FCR.concurrent_program_id
                                                                  ,FCR.program_application_id
                                                                  ,FCR.responsibility_id
                                                                  ,FCR.responsibility_application_id
                                                                  ,DECODE(FCR.status_code,'C','Completed','G','Warning')
                                                                  ,FCR.actual_start_date
                                                                  ,FCR.actual_completion_date
                                                                  ,gc_receivables
                                                                  ,p_org_id
                                                                  ,GI.set_of_books_id
                                                                  ,COUNT(GI.group_id)
                                                                  ,GI.currency_code
                                                                  ,NVL(SUM(entered_dr),0)
                                                                  ,NVL(SUM(entered_cr),0)
                                                                  ,NVL(SUM(accounted_dr),0)
                                                                  ,NVL(SUM(accounted_cr),0)
                                                                  ,FND_DATE.CANONICAL_TO_DATE(p_run_date)
                                                                  ,p_wave_num
                                                                  ,GI.group_id
                                                                  ,'NEW'
                                                                  ,0
                                                                  ,FCR.argument_text
                                                                  ,SYSDATE
                                                                  ,FND_GLOBAL.USER_ID
                                                                  ,SYSDATE
                                                                  ,FND_GLOBAL.USER_ID
                                                                  ,lc_period_start                    -- added for defect 2851 - Sneha on 19.1.2010
                                                              FROM fnd_concurrent_requests FCR
                                                                  ,gl_interface GI
                                                             WHERE FCR.request_id = GI.request_id
                                                               AND FCR.parent_request_id = gn_gl_trf_req_id
                                                             GROUP BY GI.request_id
                                                                     ,FCR.parent_request_id
                                                                     ,FCR.concurrent_program_id
                                                                     ,FCR.program_application_id
                                                                     ,FCR.responsibility_id
                                                                     ,FCR.responsibility_application_id
                                                                     ,DECODE(FCR.status_code,'C','Completed','G','Warning')
                                                                     ,FCR.actual_start_date
                                                                     ,FCR.actual_completion_date
                                                                     ,GI.set_of_books_id
                                                                     ,GI.currency_code
                                                                     ,GI.group_id
                                                                     ,FCR.argument_text
                                                                     );
               lc_error_loc := 'Fetching the count of tracking records inserted'; 
               ln_ref_count := SQL%ROWCOUNT;                                          --Added for Performance for defect 2851
               COMMIT;
             EXCEPTION
                WHEN OTHERS THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_loc);
                FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'--'||SQLERRM);
             END;
             
             -------------------------------------------------------
             --Step 3: Submit the OD: AR HV Journal Staging Program
             -------------------------------------------------------
             IF ln_ref_count >0 THEN                   -- Added for defect 2851 - Sneha on 15.1.2010

                IF p_submit_hv_staging = 'Y' THEN      -- Added for Defect 4925 - R.Aldridge 3/29/2010 (V2.0)

                   BEGIN
                      lc_error_loc := 'Step #3 - Submit OD: AR HV Journal Staging Program ';
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Step #3 - Submit OD: AR HV Journal Staging Program ');
                   
                      ln_hv_stg_req_id := FND_REQUEST.SUBMIT_REQUEST('XXFIN'            -- 1.9 Modified 1/29/2010 by R.Adridge - changed from AR
                                                                    ,'XXARJRNLSTGPRG'
                                                                    ,''
                                                                    ,SYSDATE
                                                                    ,TRUE
                                                                    ,gc_receivables
                                                                     --,'P'              -- 2.0 Removed 3/19/2010 by R.Aldridge -  Defect 4925
                                                                     --,gn_gl_trf_req_id -- 2.0 Removed 3/19/2010 by R.Aldridge -  Defect 4925
                                                                   ,p_set_of_books_id);
                  
                      COMMIT;
                      gn_gl_stg_req_id :=ln_hv_stg_req_id;
                   EXCEPTION
                      WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_loc);
                         FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'--'||SQLERRM);
                   END;

                   lc_request_data := 'COMPLETE'||'-'||gn_gl_trf_req_id;

                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID  :'||ln_hv_stg_req_id);
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Pause on the Main Transfer Program ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
                   FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=> lc_request_data);

                   RETURN;

                ELSE
                   FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||'OD: AR HV Staging program not submitted based on parameter value.  ');
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'The program needs to be submitted separately in order to stage the journals for high volume import.');
                END IF;
             
             ELSE 
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Records were not inserted in tracking table, hence the main program is set to Warning'); --Added for defect 2851 - Sneha on 15.1.2010
                lc_insert_status := 'N';
                x_ret_code       := 1;                    --Added for defect 2851 - Sneha on 15.1.2010
             END IF;                                      --Added for defect 2851 - Sneha on 15.1.2010
         END IF;
      END IF;

      ---------------------------
      -- Output Section -- Start
      ---------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Office Depot',50,' ')||LPAD('Date : '||TO_CHAR(SYSDATE, 'DD-MON-YYYY'),135,' '));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '||RPAD(ln_this_request_id,45,' ')||LPAD('Page : '||1,118,' '));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                               OD: AR General Ledger Transfer Program                                  ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Start Date             : '||p_start_date);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'End Date               : '||p_post_through_date);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'GL Posted Date         : '||p_gl_posted_date);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Processing Type        : '||p_transaction_types);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Max Workers            : '||p_max_workers);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Worker Number          : '||p_worker_number);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Skip Unposted          : '||p_skip_unposted_items);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Skip Revenue Programs  : '||p_skip_revenue_programs);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books           : '||p_set_of_books_id);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Submit HV Staging      : '||p_submit_hv_staging);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Child Process Submitted : ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Req ID',15)
                                         ||LPAD('Concurrent Program Name',25)
                                         ||LPAD('Phase',20)
                                         ||LPAD('Status',18)
                       );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',9,'-')
                                         ||'   '
                                         ||LPAD('-',38,'-')
                                         ||'   '
                                         ||LPAD('-',13,'-')
                                         ||'   '
                                         ||LPAD('-',15,'-')
                        );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      gn_gl_trf_req_id := TO_NUMBER(SUBSTR(lc_chk_flag,INSTR(lc_chk_flag,'-',1)+1)); --To get the OD: AR Parallel GL Transfer Program Req ID

      -- To get the Child Processes Submitted

      OPEN lcu_req_summary;
      LOOP
         FETCH lcu_req_summary INTO ltab_req_summ_rec;
         EXIT WHEN lcu_req_summary%NOTFOUND;
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(ltab_req_summ_rec.request_id,10,' ')
                                               ||'   '
                                               ||RPAD(ltab_req_summ_rec.user_concurrent_program_name,37,' ')
                                               ||LPAD(' ',5,' ')
                                               ||RPAD(ltab_req_summ_rec.phase_code,10,' ')
                                               ||LPAD(' ',7,' ')
                                               ||RPAD(ltab_req_summ_rec.status_code,20,' ')
                           );
      END LOOP;
      CLOSE lcu_req_summary;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Status of Interfaces:');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'    '
                                        ||RPAD('Parent',17)
                                        ||RPAD('Child',20)
                       );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  '
                                        ||RPAD('Request id',17)
                                        ||RPAD('Request id',30)
                                        ||RPAD('Program Name',30)
                                        ||RPAD('Group ID',18)
                                        ||RPAD('Count',17)
                                        ||RPAD('Entered DR',21)
                                        ||RPAD('Entered CR',23)
                                        ||RPAD('Currency',19)
                                        ||RPAD('Status',23)
                        );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('-',(15-1),'-')
                                        ||'   '
                                        ||RPAD('-',(15-1),'-')
                                        ||'   '
                                        ||RPAD('-',(40-1),'-')
                                        ||'   '
                                        ||RPAD('-',(15-1),'-')
                                        ||'   '
                                        ||RPAD('-',(15-1),'-')
                                        ||'   '
                                        ||RPAD('-',(20-1),'-')
                                        ||'   '
                                        ||RPAD('-',(20-1),'-')
                                        ||'   '
                                        ||RPAD('-',(18-1),'-')
                                        ||'   '
                                        ||RPAD('-',(15-1),'-')
                        );
      
      -- To get the Status of Interfaces
      OPEN lcu_cntrl_info_summary;
      LOOP
         FETCH lcu_cntrl_info_summary INTO ltab_cntrl_summ_rec;
         EXIT WHEN lcu_cntrl_info_summary%NOTFOUND;
         ln_sum_dr_entered := ln_sum_dr_entered + ltab_cntrl_summ_rec.entered_dr;
         ln_sum_cr_entered := ln_sum_cr_entered + ltab_cntrl_summ_rec.entered_cr;
         ln_total_count := ln_total_count + ltab_cntrl_summ_rec.volume;
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   '
                                          ||RPAD(ltab_cntrl_summ_rec.parent_request_id,12,' ')
                                          ||LPAD(ltab_cntrl_summ_rec.request_id,12,' ')
                                          ||LPAD(ltab_cntrl_summ_rec.user_concurrent_program_name,42,' ')
                                          ||LPAD(ltab_cntrl_summ_rec.gl_interface_group_id,16,' ')
                                          ||LPAD(ltab_cntrl_summ_rec.volume,18,' ')
                                          ||LPAD(ltab_cntrl_summ_rec.entered_dr,22,' ')
                                          ||LPAD(ltab_cntrl_summ_rec.entered_cr,20,' ')
                                          ||LPAD(ltab_cntrl_summ_rec.currency,19,' ')
                                          ||LPAD(ltab_cntrl_summ_rec.interface_status,19,' ')
                           );
      END LOOP;
      CLOSE lcu_cntrl_info_summary;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(' ',(15-1),' ')
                                        ||'   '
                                        ||RPAD(' ',(15-1),' ')
                                        ||'   '
                                        ||RPAD(' ',(40-1),' ')
                                        ||'   '
                                        ||RPAD(' ',(15-1),' ')
                                        ||'   '
                                        ||RPAD('-',(15-1),'-')
                                        ||'   '
                                        ||RPAD('-',(20-1),'-')
                                        ||'   '
                                        ||RPAD('-',(20-1),'-')
                       );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  '
                                        ||LPAD(ln_total_count,101,' ')
                                        ||LPAD(ln_sum_dr_entered,22,' ')
                                        ||LPAD(ln_sum_cr_entered,20,' ')
                        );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(' ',(15-1),' ')
                                        ||'   '
                                        ||RPAD(' ',(15-1),' ')
                                        ||'   '
                                        ||RPAD(' ',(40-1),' ')
                                        ||'   '
                                        ||RPAD(' ',(15-1),' ')
                                        ||'   '
                                        ||RPAD('-',(15-1),'-')
                                        ||'   '
                                        ||RPAD('-',(20-1),'-')
                                        ||'   '
                                        ||RPAD('-',(20-1),'-')
                       );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('*** End of Report ***',90,' '));
      --------------------------
      -- Output Section -- Ends
      --------------------------
      
      IF p_submit_hv_staging = 'Y' THEN                -- Added for Defect 4925 - R.Aldridge 3/29/2010 (V2.0)

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID  :'||gn_gl_stg_req_id);
         --To check the status of Staging Program
         IF (NVL(SUBSTR(lc_chk_flag,1,INSTR(lc_chk_flag,'-',1)-1),'COMPLETE') = 'COMPLETE') THEN
            SELECT status_code
              INTO lc_status_code_stg
              FROM fnd_conc_req_summary_v
             WHERE parent_request_id  = ln_this_request_id
               AND program_short_name = 'XXARJRNLSTGPRG';
            
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Status of Staging Program: '||lc_status_code_stg);
            
            IF lc_status_code_stg = 'E' THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Staging Program completed in Error, hence the parent program ended in Error');
               x_ret_code   := 2;
               -- added the below section for defect 2851 - Sneha on 15.1.2010
            ELSIF lc_status_code_stg = 'G' THEN  
               IF lc_insert_status = 'N' THEN 
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Insert Unsuccessful, hence the parent program ended in Error');
                  x_ret_code   := 2;
               ELSE 
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Staging Program completed in Warning, hence the parent program ended in Warning');
                  x_ret_code   := 1;
                END IF;
            END IF;
         -- Added section for defect 2851 ends
         END IF;

      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         lc_error_msg := 'Warning occurred in OD: AR General Ledger Transfer Program at '||lc_error_loc||'. The Oracle error is '||SQLERRM||' : '||SQLCODE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************************************************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Warning occurred in OD: AR General Ledger Transfer Program'||CHR(10)||'at '||lc_error_loc
                                         ||'. The Oracle error is '||SQLERRM||' : '||SQLCODE);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'End of OD: AR General Ledger Transfer Program');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************************************************************************************');
         XX_COM_ERROR_LOG_PUB.LOG_ERROR(p_program_type                => 'CONCURRENT PROGRAM'
                                       ,p_program_id                  => fnd_global.conc_program_id
                                       ,p_module_name                 => 'AR'
                                       ,p_error_location              => SUBSTR('Error at '|| lc_error_loc,1,60)
                                       ,p_error_message_count         => 1
                                       ,p_error_message_code          => 'W'
                                       ,p_error_message               => lc_error_msg
                                       ,p_error_message_severity      => 'Warning'
                                       ,p_notify_flag                 => 'N'
                                       ,p_object_type                 => lc_object_type
                                       ,p_object_id                   => ln_object_id
                                        );
         x_ret_code := 1;
      WHEN OTHERS THEN
         lc_error_msg := 'Error occurred in OD: AR General Ledger Transfer Program at '||lc_error_loc||'. The Oracle error is '||SQLERRM||' : '||SQLCODE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************************************************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error occurred in OD: AR General Ledger Transfer Program'||CHR(10)||'at '||lc_error_loc
                                         ||'. The Oracle error is '||SQLERRM||' : '||SQLCODE);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'End of OD: AR General Ledger Transfer Program');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************************************************************************************');
         XX_COM_ERROR_LOG_PUB.LOG_ERROR(p_program_type                => 'CONCURRENT PROGRAM'
                                       ,p_program_id                  => fnd_global.conc_program_id
                                       ,p_module_name                 => 'AR'
                                       ,p_error_location              => SUBSTR('Error at '|| lc_error_loc,1,60)
                                       ,p_error_message_count         => 1
                                       ,p_error_message_code          => 'E'
                                       ,p_error_message               => lc_error_msg
                                       ,p_error_message_severity      => 'Warning'
                                       ,p_notify_flag                 => 'N'
                                       ,p_object_type                 => lc_object_type
                                       ,p_object_id                   => ln_object_id
                                       );
         x_ret_code := 2;
   END SUBMIT_PROGRAM;
END XX_AR_GL_TRANSFER_PKG;
/
SHOW ERR
