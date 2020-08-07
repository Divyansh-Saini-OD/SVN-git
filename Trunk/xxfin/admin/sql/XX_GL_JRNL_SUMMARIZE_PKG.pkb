SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF 
SET FEEDBACK OFF
SET TERM ON  

PROMPT Creating Package Body XX_GL_JRNL_SUMMARIZE_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_GL_JRNL_SUMMARIZE_PKG
AS
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                        Office Depot Organization                      |
-- +=======================================================================+
-- | Name         : XX_GL_JRNL_SUMMARIZE_PKG                               |
-- |                                                                       |
-- | RICE#        : E2049                                                  |
-- |                                                                       |
-- | Description  : This package is used to staging, summarize, and then   |
-- |                import high volume journals.                           |
-- |                                                                       |
-- |                The STAGING procedure will perform the following       |
-- |                steps:                                                 |
-- |                                                                       |
-- |                1. Copy journals from gl_interface to the high volume  |
-- |                   interface table (xx_gl_interface_high_vol_na).      |
-- |                2. Verify counts                                       |
-- |                3. Delete journal from gl_interface                    |
-- |                                                                       |
-- |                The SUMMARIZE procedure will perform the following     |
-- |                steps:                                                 |
-- |                                                                       |
-- |                1. Create new summary journal from detailed journal    |
-- |                2. Submit Journal Import for new journal               |
-- |                3. Delete reference information for summary journal    |
-- |                4. Insert reference information from the detailed      |
-- |                   journal into gl_import_references to maintain       |
-- |                   drill back.                                         |
-- |                5. Verify counts and balances between summarized and   |
-- |                   detailed journal.                                   |
-- |                6. Delete detailed journal from gl_interface           |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version    Date         Author         Remarks                         |
-- |=========  ===========  =============  ================================|
-- | 1 to 2.2  various      various        Defect 2851 - Version 2.2 of the|
-- |                                       code was the initial production |
-- |                                       version of the code.  It was    |
-- |                                       implemented as part of R10.2.   |
-- |                                       See subversion revision 94176   |
-- |                                       for any commented changes made  |
-- |                                       through version 2.2             |
-- |                                                                       |
-- | 2.3       09-MAR-2010  R.Aldridge     Defect 4690 - Enhance the       |
-- |                                       reprocessing capabilities.      |
-- |                                       Defect 4925 - Enhance to submit |
-- |                                       by source only.                 |
-- |                                                                       |
-- | 2.4       15-APR-2010  R.Aldridge     10.3 Performance changes for    |
-- |                                       Defect 4918 - HV Import Program |
-- |                                       *** Note: Bundled with 4690 *** |
-- |                                                                       |
-- | 2.5       09-JUN-2010  R.Aldridge     Defect 4918/4916 - Improve HV   |
-- |                                       performance via HINTS           |
-- | 2.6       30-AUG-2010  R.Hartman      Defect 7765 - Remove GL.*       |
-- |                                       schema name for Archive         |
-- +=======================================================================+

   ----------------------
   -- GLOBAL VARIABLES --
   ----------------------
   gc_program_name       fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
   gn_this_request_id    fnd_concurrent_requests.request_id%TYPE := 0;
   gc_error_loc          VARCHAR2(2000) := NULL;
   -- variable is used for displaying additional messages to output file regarding if reprocessing was performed
   gc_output_message     VARCHAR2(2000) := NULL;

   ----------------------
   -- GLOBAL CONSTANTS --
   ----------------------
   G_NEW                 CONSTANT xx_gl_high_volume_jrnl_control.interface_status%TYPE  := 'NEW';
   G_STAGING             CONSTANT xx_gl_high_volume_jrnl_control.interface_status%TYPE  := 'STAGING';
   G_STAGED              CONSTANT xx_gl_high_volume_jrnl_control.interface_status%TYPE  := 'STAGED';
   G_IMPORTING           CONSTANT xx_gl_high_volume_jrnl_control.interface_status%TYPE  := 'IMPORTING';
   G_INSERTED_REFERENCES CONSTANT xx_gl_high_volume_jrnl_control.interface_status%TYPE  := 'INSERTED-REFERENCES';
   G_IMPORTED            CONSTANT xx_gl_high_volume_jrnl_control.interface_status%TYPE  := 'IMPORTED';

   -- +====================================================================+
   -- | Name       : XX_OBTAIN_PROGRAM_INFO                                |
   -- |                                                                    |
   -- | Description: This procedure is used obtain the request ID and      |
   -- |              program name for the staging and import program       |
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE XX_OBTAIN_PROGRAM_INFO
   IS
   BEGIN
      gc_error_loc := 'Obtaining concurrent program request id';
      gn_this_request_id := fnd_global.conc_request_id;
      FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||'Request ID: '||gn_this_request_id||chr(10));

      gc_error_loc := 'Obtaining concurrent program name';
      SELECT user_concurrent_program_name
        INTO gc_program_name
        FROM fnd_concurrent_requests    FCR
            ,fnd_concurrent_programs_tl FCP
       WHERE FCR.request_id = gn_this_request_id
         AND FCR.program_application_id = FCP.application_id
         AND FCR.concurrent_program_id  = FCP.concurrent_program_id;
   END XX_OBTAIN_PROGRAM_INFO;

   -- +====================================================================+
   -- | Name       : XX_PRINT_TIME_STAMP_TO_LOGFILE                        |
   -- |                                                                    |
   -- | Description: This private procedure is used to print the time to   |
   -- |              the log                                               |
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE XX_PRINT_TIME_STAMP_TO_LOGFILE
   IS
   BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')||chr(10));
   END XX_PRINT_TIME_STAMP_TO_LOGFILE;

   -- +====================================================================+
   -- | Name       : XX_GL_JRNL_PRINT_OUTPUT_BODY                          |
   -- |                                                                    |
   -- | Description: This private procedure used to print the requests to  |
   -- |              the output (used as the body)                         |
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE XX_GL_JRNL_PRINT_OUTPUT_BODY
               (p_group_id           gl_interface.group_id%TYPE                             := NULL
               ,p_staging_request_id xx_gl_high_volume_jrnl_control.hv_stg_req_id%TYPE      := NULL
               ,p_period_name        xx_gl_high_volume_jrnl_control.period_name%TYPE        := NULL
               ,p_sob_id             xx_gl_high_volume_jrnl_control.set_of_books_id%TYPE
               ,p_source             xx_gl_high_volume_jrnl_control.user_je_source_name%TYPE)
   IS

      ln_sum_dr_entered        xx_gl_high_volume_jrnl_control.entered_dr%TYPE :=0;
      ln_sum_cr_entered        xx_gl_high_volume_jrnl_control.entered_cr%TYPE :=0;
      ln_total_count           xx_gl_high_volume_jrnl_control.volume%TYPE     :=0;

      -- Cursor is used to obtain information for the interfaces processed
      -- Staging program uses p_staging_request_id for criteria
      -- Import program uses p_group_id and p_period_name for criteria
      CURSOR gcu_cntl_info
      IS
         SELECT XGHVJC.parent_request_id
               ,XGHVJC.request_id
               ,FCPT.user_concurrent_program_name
               ,XGHVJC.gl_interface_group_id
               ,XGHVJC.volume
               ,XGHVJC.entered_dr
               ,XGHVJC.entered_cr
               ,XGHVJC.currency
               ,XGHVJC.interface_status
           FROM xx_gl_high_volume_jrnl_control XGHVJC
               ,fnd_concurrent_programs_tl     FCPT
          WHERE XGHVJC.user_je_source_name     = p_source
            AND XGHVJC.set_of_books_id         = p_sob_id
            AND XGHVJC.concurrent_program_id   = FCPT.concurrent_program_id
            AND XGHVJC.program_application_id  = FCPT.application_id
            AND ((       XGHVJC.journal_import_group_id = p_group_id
                     AND XGHVJC.period_name             = p_period_name)
                  OR     XGHVJC.hv_stg_req_id      = p_staging_request_id);

      gtab_cntl_rec gcu_cntl_info%ROWTYPE;

   BEGIN
      gc_error_loc := 'Printing details of interfaces to output';
      -- Printing interface data in output file
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Status of Interfaces:'||chr(10));
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
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,  RPAD('-',(15-1),'-')||'   '
                                        ||RPAD('-',(15-1),'-')||'   '
                                        ||RPAD('-',(40-1),'-')||'   '
                                        ||RPAD('-',(15-1),'-')||'   '
                                        ||RPAD('-',(15-1),'-')||'   '
                                        ||RPAD('-',(20-1),'-')||'   '
                                        ||RPAD('-',(20-1),'-')||'   '
                                        ||RPAD('-',(18-1),'-')||'   '
                                        ||RPAD('-',(15-1),'-')
                                        );
      OPEN gcu_cntl_info;
      LOOP
         FETCH gcu_cntl_info INTO gtab_cntl_rec;
         EXIT WHEN gcu_cntl_info%NOTFOUND;
         ln_sum_dr_entered := ln_sum_dr_entered + gtab_cntl_rec.entered_cr;
         ln_sum_cr_entered := ln_sum_cr_entered + gtab_cntl_rec.entered_cr;
         ln_total_count := ln_total_count + gtab_cntl_rec.volume;
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   '
                                           ||RPAD(gtab_cntl_rec.parent_request_id,12,' ')
                                           ||LPAD(gtab_cntl_rec.request_id,12,' ')
                                           ||LPAD(gtab_cntl_rec.user_concurrent_program_name,42,' ')
                                           ||LPAD(gtab_cntl_rec.gl_interface_group_id,16,' ')
                                           ||LPAD(gtab_cntl_rec.volume,18,' ')
                                           ||LPAD(gtab_cntl_rec.entered_dr,22,' ')
                                           ||LPAD(gtab_cntl_rec.entered_cr,20,' ')
                                           ||LPAD(gtab_cntl_rec.currency,19,' ')
                                           ||LPAD(gtab_cntl_rec.interface_status,19,' ')
                                           );
      END LOOP;
      CLOSE gcu_cntl_info;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(' ',(15-1),' ')      ||'   '
                                            ||RPAD(' ',(15-1),' ')||'   '
                                            ||RPAD(' ',(40-1),' ')||'   '
                                            ||RPAD(' ',(15-1),' ')||'   '
                                            ||RPAD('-',(15-1),'-')||'   '
                                            ||RPAD('-',(20-1),'-')||'   '
                                            ||RPAD('-',(20-1),'-')
                                           );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  '
                                            ||LPAD(ln_total_count,101,' ')
                                            ||LPAD(ln_sum_dr_entered,22,' ')
                                            ||LPAD(ln_sum_cr_entered,20,' ')
                                            );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(' ',(15-1),' ')      ||'   '
                                            ||RPAD(' ',(15-1),' ')||'   '
                                            ||RPAD(' ',(40-1),' ')||'   '
                                            ||RPAD(' ',(15-1),' ')||'   '
                                            ||RPAD('-',(15-1),'-')||'   '
                                            ||RPAD('-',(20-1),'-')||'   '
                                            ||RPAD('-',(20-1),'-')
                                            );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10)||gc_output_message||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('*** End of Report ***',90,' '));

   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - XX_GL_JRNL_STG_PRINT_OUTPUT (When Others)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside creating request output '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside creating request output  '||gc_error_loc);
         xx_print_time_stamp_to_logfile();
   END XX_GL_JRNL_PRINT_OUTPUT_BODY;

   -- +====================================================================+
   -- | Name       : XX_GL_JRNL_STG                                        |
   -- |                                                                    |
   -- | Description: This procedure is used to stage/copy journals from the|
   -- |              GL interface table to the high volume GL interface.   |
   -- |              The XX_GL_JRNL_STG procedure will perform the         |
   -- |              following actions:                                    |
   -- |                                                                    |
   -- |              A. Process (complete) journals in STAGING status      |
   -- |              B. Process journals in NEW status using the           |
   -- |                 following steps:                                   |
   -- |                   1. Copy new summary journal from GL_INTERFACE to |
   -- |                      to staging table                              |
   -- |                   2. Validate the volume against the data captured |
   -- |                      in control table                              |
   -- |                   3. Delete detailed journal from gl_interface     |
   -- |                                                                    |
   -- | Parameters : p_source, p_request_id, p_request_type, p_sob_id      |
   -- |                                                                    |
   -- | Returns    : x_errbuf, x_retcode                                   |
   -- |                                                                    |
   -- +====================================================================+
   PROCEDURE XX_GL_JRNL_STG (x_errbuf             OUT    VARCHAR2
                            ,x_ret_code           OUT    NUMBER
                            ,p_source             IN     VARCHAR2
                            ,p_sob_id             IN     NUMBER)
   IS
      -- used for comparing volumes in tables or DML operations
      ln_cntl_volume                xx_gl_high_volume_jrnl_control.volume%TYPE  :=0;
      ln_inserted_stg_vol           xx_gl_high_volume_jrnl_control.volume%TYPE  :=0;
      ln_del_gl_int_volume          xx_gl_high_volume_jrnl_control.volume%TYPE  :=0;

      -- used for holding information retrieved about staging for comparisions
      ln_stg_volume                 xx_gl_high_volume_jrnl_control.volume%TYPE  :=0;
      ln_stg_ent_dr                 xx_gl_interface_high_vol_na.entered_dr%TYPE;
      ln_stg_ent_cr                 xx_gl_interface_high_vol_na.entered_cr%TYPE;
      ln_stg_acc_dr                 xx_gl_interface_high_vol_na.accounted_dr%TYPE;
      ln_stg_acc_cr                 xx_gl_interface_high_vol_na.accounted_cr%TYPE;

      -- used for holding information retrieved about gl_interface for comparisions
      ln_glint_ent_dr               xx_gl_interface_high_vol_na.entered_dr%TYPE;
      ln_glint_ent_cr               xx_gl_interface_high_vol_na.entered_cr%TYPE;
      ln_glint_acc_dr               xx_gl_interface_high_vol_na.accounted_dr%TYPE;
      ln_glint_acc_cr               xx_gl_interface_high_vol_na.accounted_cr%TYPE;

      -- used for tracking number of requests processed for completion of STAGING
      ln_stg_bat_sql_cnt            xx_gl_high_volume_jrnl_control.volume%TYPE  :=0;
      ln_stg_bat_total_cnt          xx_gl_high_volume_jrnl_control.volume%TYPE  :=0;
      ln_gl_del_failed_cnt          xx_gl_high_volume_jrnl_control.volume%TYPE  :=0;

      -- exceptions
      ex_staging_volume_diff        EXCEPTION;
      ex_no_staging_records         EXCEPTION;
      ex_glint_delete_volume_diff   EXCEPTION;

      CURSOR lcu_stg_status
      IS
         SELECT NVL(SUM(XGHVJC.entered_dr),0)         ENTERED_DR
               ,NVL(SUM(XGHVJC.entered_cr),0)         ENTERED_CR
               ,NVL(SUM(XGHVJC.accounted_dr),0)       ACCOUNTED_DR
               ,NVL(SUM(XGHVJC.accounted_cr),0)       ACCOUNTED_CR
               ,NVL(SUM(XGHVJC.volume),0)             VOLUME
               ,XGHVJC.interface_status
               ,XGHVJC.request_id
               ,XGHVJC.gl_imp_req_id
               ,XGHVJC.hv_imp_req_id
               ,XGHVJC.hv_stg_req_id           PRIOR_STG_REQ_ID
               ,XGHVJC.derived_je_batch_name
               ,XGHVJC.je_batch_id
           FROM xx_gl_high_volume_jrnl_control  XGHVJC
          WHERE XGHVJC.interface_status    = G_STAGING
            AND XGHVJC.user_je_source_name = p_source
            AND XGHVJC.set_of_books_id     = p_sob_id
         GROUP BY XGHVJC.interface_status
                 ,XGHVJC.request_id
                 ,XGHVJC.gl_imp_req_id
                 ,XGHVJC.hv_imp_req_id
                 ,XGHVJC.hv_stg_req_id
                 ,XGHVJC.derived_je_batch_name
                 ,XGHVJC.je_batch_id;

      ltab_stg_status_rec    lcu_stg_status%ROWTYPE;

   BEGIN
      gc_error_loc := 'Print Parameters and RICE# to concurrent request log file';
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'** See RICE# E2049 for Design Info on OD: <source name> HV Journal Staging **');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters Values Used'||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Journal Source : '||p_source);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Set of Books ID: '||p_sob_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');

      -- get request id and program name of this concurrent program
      gc_error_loc := 'Obtaining concurrent program information';
      xx_obtain_program_info();

      gc_error_loc := 'Print report header information to concurrent request output file';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Office Depot',50,' ')||LPAD('Date : '||TO_CHAR(SYSDATE, 'DD-MON-YYYY'),135,' '));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '||RPAD(gn_this_request_id,45,' ')||LPAD('Page : '||1,118,' ')||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(gc_program_name,95,' ')||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Source: '||p_source);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books  : '||p_sob_id||chr(10));

      FND_FILE.PUT_LINE(FND_FILE.LOG,'=============================================================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Process STAGING interface_status (Delete staged jrnls from GL_INTERFACE)--');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================================================='||chr(10));
      BEGIN
         gc_error_loc := 'Checking for interfaces in control table with interface status = STAGING';
         OPEN lcu_stg_status;
         LOOP
            FETCH lcu_stg_status INTO ltab_stg_status_rec;
            EXIT WHEN lcu_stg_status%NOTFOUND;

            -- If a records exists this means records were staged to high volume interface table, but
            -- the delete from GL_INTERFACE was rollback due to termination of concurrent program, etc.
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Information Retrieved for Interface Request ID '||ltab_stg_status_rec.request_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Interface Status     : '||ltab_stg_status_rec.interface_status);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume               : '||ltab_stg_status_rec.volume);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered DR           : '||ltab_stg_status_rec.entered_dr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered CR           : '||ltab_stg_status_rec.entered_cr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted DR         : '||ltab_stg_status_rec.accounted_dr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted CR         : '||ltab_stg_status_rec.accounted_cr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       GL Imp Req ID        : '||ltab_stg_status_rec.gl_imp_req_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       JE Batch Name        : '||ltab_stg_status_rec.derived_je_batch_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       JE Batch ID          : '||ltab_stg_status_rec.je_batch_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       HV Imp Req ID        : '||ltab_stg_status_rec.hv_imp_req_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       HV Stg Req ID (Prior): '||ltab_stg_status_rec.prior_stg_req_id||chr(10));

            BEGIN
               gc_error_loc := 'Checking staged volume for interface_status = STAGING';
               IF ltab_stg_status_rec.volume > 0 THEN

                  -- Obtain count of records from high volume inteface table where
                  gc_error_loc := 'Obtaining count from XX_GL_INTERFACE_HIGH_VOL_NA for interfaces that have a status of STAGING';
                  SELECT COUNT(1)
                        ,NVL(SUM(entered_dr),0)
                        ,NVL(SUM(entered_cr),0)
                        ,NVL(SUM(accounted_dr),0)
                        ,NVL(SUM(accounted_dr),0)
                    INTO ln_stg_volume
                        ,ln_stg_ent_dr
                        ,ln_stg_ent_cr
                        ,ln_stg_acc_dr
                        ,ln_stg_acc_cr
                    FROM xx_gl_interface_high_vol_na XGIHVN
                   WHERE XGIHVN.request_id = ltab_stg_status_rec.request_id;

                  -- Obtain count of records from gl_inteface table where
                  gc_error_loc := 'Obtaining count from GL_INTERFACE for interfaces that have a status of STAGING';
                  SELECT NVL(SUM(GLI.entered_dr),0)
                        ,NVL(SUM(GLI.entered_cr),0)
                        ,NVL(SUM(GLI.accounted_dr),0)
                        ,NVL(SUM(GLI.accounted_dr),0)
                    INTO ln_glint_ent_dr
                        ,ln_glint_ent_cr
                        ,ln_glint_acc_dr
                        ,ln_glint_acc_cr
                    FROM gl_interface GLI
                   WHERE GLI.request_id = ltab_stg_status_rec.request_id;

                  -- Deleting detail journal lines from GL_INTERFACE for journals that were successfully copied to staging table
                  gc_error_loc := 'Deleting records from GL_INTERFACE for interfaces that have a status of STAGING';
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Deleting records from GL_INTERFACE for interfaces that have a status of STAGING'||chr(10));
                  DELETE /*+FULL(GI) PARALLEL(GI,8)*/ FROM gl_interface GI
                  WHERE EXISTS (SELECT /*+ FULL(XGHVJC) PARALLEL(XGHVJC,8) */ 1
                                  FROM xx_gl_high_volume_jrnl_control  XGHVJC
                                 WHERE XGHVJC.interface_status    = G_STAGING
                                   AND XGHVJC.user_je_source_name = p_source
                                   AND XGHVJC.set_of_books_id     = p_sob_id
                                   AND XGHVJC.request_id          = ltab_stg_status_rec.request_id
                                   AND XGHVJC.request_id          = GI.request_id)
                       AND GI.user_je_source_name = p_source;

                  ln_del_gl_int_volume := SQL%ROWCOUNT;

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Compare deletion of GL interface table (STAGING status) with high volume interface and control tables');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume from XX_GL_HIGH_VOLUME_JRNL_CONTROL: '||ltab_stg_status_rec.volume);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume from XX_GL_INTERFACE_HIGH_VOL_NA   : '||ln_stg_volume);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume deleted from GL_INTERFACE          : '||ln_del_gl_int_volume||chr(10));

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Amounts from staging interface for comparision to control amounts (see above for control amounts)');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered DR   - XX_GL_INTERFACE_HIGH_VOL_NA: '||ln_stg_ent_dr);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered CR   - XX_GL_INTERFACE_HIGH_VOL_NA: '||ln_stg_ent_cr);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted DR - XX_GL_INTERFACE_HIGH_VOL_NA: '||ln_stg_acc_dr);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted CR - XX_GL_INTERFACE_HIGH_VOL_NA: '||ln_stg_acc_cr||chr(10));

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Amounts from GL interface for comparision to control amounts (see above for control amounts)');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered DR   - GL_INTERFACE               : '||ln_glint_ent_dr);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered CR   - GL_INTERFACE               : '||ln_glint_ent_cr);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted DR - GL_INTERFACE               : '||ln_glint_acc_dr);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted CR - GL_INTERFACE               : '||ln_glint_acc_cr||chr(10));

                  gc_error_loc := 'Comparing control table, high volume table, records deleted, amounts, and volume where interface_status = STAGING';
                  IF (ln_del_gl_int_volume <> ltab_stg_status_rec.volume        OR
                      ln_del_gl_int_volume <> ln_stg_volume                     OR
                      ln_stg_volume        <> ltab_stg_status_rec.volume)       THEN
                      gc_error_loc := 'Volume comparision: delete of GL_INTERFACE vs. control table.';
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Comparision failed for volume (Journal amounts not compared).');
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Starting rollback for deletion of GL_INTERFACE.');
                      ROLLBACK;
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rollback completed for deletion of GL_INTERFACE.');

                      -- track count of failed deletion comparision.
                      ln_gl_del_failed_cnt := ln_gl_del_failed_cnt + 1;

                      -- this status code could be elevated to ERROR during subsequent processing.
                      x_ret_code :=1;
                  ELSIF (ln_stg_ent_dr <> ltab_stg_status_rec.entered_dr    OR
                         ln_stg_ent_cr <> ltab_stg_status_rec.entered_cr    OR
                         ln_stg_acc_dr <> ltab_stg_status_rec.accounted_dr  OR
                         ln_stg_acc_cr <> ltab_stg_status_rec.accounted_cr) THEN

                         gc_error_loc := 'Journal amount comparision: XX_GL_INTERFACE_HIGH_VOL_NA vs. control table.';
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Comparision failed for amounts.');
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Starting rollback for deletion of GL_INTERFACE.');
                         ROLLBACK;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rollback completed for deletion of GL_INTERFACE.');

                         -- track count of failed deletion comparision.
                         ln_gl_del_failed_cnt := ln_gl_del_failed_cnt + 1;

                         -- this status code could be elevated to ERROR during subsequent processing.
                         x_ret_code :=1;
                  ELSIF (ln_glint_ent_dr <> ltab_stg_status_rec.entered_dr   OR
                         ln_glint_ent_cr <> ltab_stg_status_rec.entered_cr   OR
                         ln_glint_acc_dr <> ltab_stg_status_rec.accounted_dr OR
                         ln_glint_acc_dr <> ltab_stg_status_rec.accounted_cr) THEN

                         gc_error_loc := 'Journal amount comparision: GL_INTERFACE vs. control table.';
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Comparision failed for amounts.');
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Starting rollback for deletion of GL_INTERFACE.');
                         ROLLBACK;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rollback completed for deletion of GL_INTERFACE.');

                         -- track count of failed deletion comparision.
                         ln_gl_del_failed_cnt := ln_gl_del_failed_cnt + 1;

                         -- this status code could be elevated to ERROR during subsequent processing.
                         x_ret_code :=1;

                  -- Update the interface_status to STAGED from STAGING
                  ELSE
                     gc_error_loc := 'Updating status to STAGED in control table for previously staged journals';
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Comparision of volumes and amounts were equal.');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updating interface status to STAGED for the interfaces that were deleted from GL_INTERFACE.');
                     UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                        SET XGHVJC.interface_status    = G_STAGED
                      WHERE XGHVJC.interface_status    = G_STAGING
                        AND XGHVJC.user_je_source_name = p_source
                        AND XGHVJC.set_of_books_id     = p_sob_id
                        AND XGHVJC.request_id          = ltab_stg_status_rec.request_id;

                     -- Track records updated
                     ln_stg_bat_sql_cnt   := SQL%ROWCOUNT;
                     ln_stg_bat_total_cnt := ln_stg_bat_total_cnt + ln_stg_bat_sql_cnt;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||ln_stg_bat_sql_cnt||' interface record(s) updated to STAGED from STAGING in control '||
                                                                              'table during clean-up for STAGING interface status.');
                     -- Commit update of control table.
                     gc_error_loc := 'Commit updating status to STAGED in control table for previously staged journals';
                     COMMIT;

                  END IF;  -- end volume comparison between 3 tables

               ELSE -- There are no interface records in control table with interface_status = STAGING
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  There are no interface records in control table with interface_status = STAGING');
               END IF;

            EXCEPTION
               WHEN OTHERS THEN
                  gc_error_loc := 'Entering Exception Handling for during deletion of detailed records';
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for during deletion of detailed records');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised while '||gc_error_loc);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Delete of detailed records in staging table not successful for interface Request ID '||ltab_stg_status_rec.request_id);
                  ROLLBACK;
                  xx_print_time_stamp_to_logfile();
            END; -- end check for STAGING status

            xx_print_time_stamp_to_logfile();

        END LOOP;
        CLOSE lcu_stg_status;

        gc_error_loc := 'Write message to output if No interface records were updated to interface_status of STAGED';
        IF ln_stg_bat_total_cnt = 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  No interface records were updated to interface_status of STAGED.'||chr(10));
        ELSE
            -- update global variable to writing message to concurrent request output to indicate clean-up of interfaces stuck in STAGING status
            gc_output_message := gc_output_message||'Additional processing was performed for interfaces that were in STAGING status from a previsous run.  '
                                                  ||'See log file for more information.'||chr(10);
        END IF;

        gc_error_loc := 'Write message to output if No interface records were updated to interface_status of STAGED';
        IF ln_gl_del_failed_cnt > 0 THEN
            -- update global variable to writing message to concurrent request output to indicate clean-up of interfaces stuck in STAGING status
            gc_output_message := gc_output_message||'Processing was UNABLE to be performed for interfaces that were in STAGING status from a previsous run.  '
                                                  ||'See log file for more information.'||chr(10);
        END IF;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for Clean-Up Interface Status of STAGING');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised while '||gc_error_loc);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while '||gc_error_loc);
      END;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'=============================================================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Process NEW interface_status (Move jrnls to XX_GL_INTERFACE_HIGH_VOL_NA)--');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================================================='||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Step #1 - Copy to HV Interface Tab --');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
      xx_print_time_stamp_to_logfile();

      -- Re-initialize variable
      ln_del_gl_int_volume := 0;

      -- Update the interface_status to STAGING in control table to identify records to be processed
      gc_error_loc := 'Updating interface_status to STAGING and hv_stg_req_id in control table';
      UPDATE xx_gl_high_volume_jrnl_control XGHVJC
         SET XGHVJC.interface_status    = G_STAGING
            ,XGHVJC.hv_stg_req_id       = gn_this_request_id
       WHERE XGHVJC.interface_status    = G_NEW
         AND XGHVJC.user_je_source_name = p_source
         AND XGHVJC.set_of_books_id     = p_sob_id;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated interface status to STAGING'||chr(10));

      gc_error_loc := 'Inserting records into high volume staging table';
      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Begin normal processing/staging for interface records where interface_status = NEW');
      INSERT INTO xx_gl_interface_high_vol_na   --- staging table created with multi-table journal import API's
      SELECT /*+ FULL(GI) FULL(XGHVJC) PARALLEL(XGHVJC,8) PARALLEL(GI,8)*/ GI.*
        FROM gl_interface                   GI
            ,xx_gl_high_volume_jrnl_control XGHVJC
       WHERE XGHVJC.interface_status    = G_STAGING
         AND XGHVJC.user_je_source_name = p_source
         AND XGHVJC.set_of_books_id     = p_sob_id
         AND XGHVJC.hv_stg_req_id       = gn_this_request_id
         AND XGHVJC.request_id          = GI.request_id
         AND GI.user_je_source_name     = p_source;

      ln_inserted_stg_vol := SQL%ROWCOUNT;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Inserted '||ln_inserted_stg_vol|| ' records into XX_GL_INTERFACE_HIGH_VOL_NA');
      xx_print_time_stamp_to_logfile();

      IF (ln_inserted_stg_vol = 0) THEN
         -- When no records in gl_interface to match the parameters passed set program to complete in warning
         RAISE ex_no_staging_records;
      END IF;

      gc_error_loc := 'Selecting volume information from high volume control table';
      SELECT SUM(volume)
        INTO ln_cntl_volume
        FROM xx_gl_high_volume_jrnl_control XGHVJC
       WHERE XGHVJC.interface_status    = G_STAGING
         AND XGHVJC.user_je_source_name = p_source
         AND XGHVJC.set_of_books_id     = p_sob_id
         AND XGHVJC.hv_stg_req_id       = gn_this_request_id;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Step #2 - Validate Journal Volume  --');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------'||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Compare volume copied to staging table to control table');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume from XX_GL_HIGH_VOLUME_JRNL_CONTROL: '||ln_cntl_volume);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume from XX_GL_INTERFACE_HIGH_VOL_NA   : '||ln_inserted_stg_vol);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume Difference (Control vs. Staging)   : '||(ln_inserted_stg_vol - ln_cntl_volume));
      xx_print_time_stamp_to_logfile();

      --Compare volume of staging table and control table information
      IF (ln_inserted_stg_vol = ln_cntl_volume ) THEN

         -- Commit insert into high volume interface table and update of control table.
         gc_error_loc := 'Commit status update to STAGING in control table for interfaces being processed';
         COMMIT;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Step #3 - Delete GL INTERFACE      --');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
         -- Deleting detail journal lines from GL_INTERFACE as the journals are successfully copied to staging table
         gc_error_loc := 'Deleting records from GL_INTERFACE';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Begin deleting GL_INTERFACE'||chr(10));
         DELETE /*+ FULL(GI) PARALLEL(GI,8)*/ FROM gl_interface GI
          WHERE GI.user_je_source_name = p_source
            AND EXISTS (SELECT /*+ FULL(XGHVJC) PARALLEL(XGHVJC,8) */ 1
                          FROM xx_gl_high_volume_jrnl_control XGHVJC
                         WHERE XGHVJC.interface_status    = G_STAGING
                           AND XGHVJC.user_je_source_name = p_source
                           AND XGHVJC.set_of_books_id     = p_sob_id
                           AND XGHVJC.hv_stg_req_id       = gn_this_request_id
                           AND XGHVJC.request_id          = GI.request_id);

         ln_del_gl_int_volume := SQL%ROWCOUNT;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||ln_del_gl_int_volume||' records deleted from GL_INTERFACE');
         xx_print_time_stamp_to_logfile();

         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Compare deletion of GL interface table to control table (Processing for NEW status)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume from XX_GL_HIGH_VOLUME_JRNL_CONTROL: '||ln_cntl_volume);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume deleted from GL_INTERFACE          : '||ln_del_gl_int_volume);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume Difference                         : '||(ln_cntl_volume-ln_del_gl_int_volume)||chr(10));

         gc_error_loc := 'Comparing control table versus records deleted from the gl_interface table where interface_status = STAGING';
         IF (ln_cntl_volume = ln_del_gl_int_volume) THEN

            -- Update the interface_status to STAGED from STAGING
            gc_error_loc := 'Updating status to STAGED in control table';
            UPDATE xx_gl_high_volume_jrnl_control XGHVJC
               SET XGHVJC.interface_status    = G_STAGED
             WHERE XGHVJC.interface_status    = G_STAGING
               AND XGHVJC.user_je_source_name = p_source
               AND XGHVJC.set_of_books_id     = p_sob_id
               AND XGHVJC.hv_stg_req_id       = gn_this_request_id;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated interface status to STAGED');
            xx_print_time_stamp_to_logfile();

            gc_error_loc := 'Commit status update to STAGED in control table for interfaces that have been successfully staged';
            COMMIT;
         ELSE
            gc_error_loc := 'Raising exception to ROLLBACK delete from gl_interface table due to volume difference';
            RAISE ex_glint_delete_volume_diff;
         END IF;
      ELSE  -- volume difference
         gc_error_loc := 'Raising exception to ROLLBACK insert into staging table due to volume difference';
         RAISE ex_staging_volume_diff;
      END IF;  -- end volume comparision

      -- Printing interface data in output file
      gc_error_loc := 'Printing Output Section for Staged Interfaces';
      -- Group ID and Period Name is not applicable when printing information for imported interfaces
      xx_gl_jrnl_print_output_body(p_group_id           => NULL
                                  ,p_staging_request_id => gn_this_request_id
                                  ,p_period_name        => NULL
                                  ,p_sob_id             => p_sob_id
                                  ,p_source             => p_source);
   EXCEPTION
      WHEN ex_no_staging_records THEN
         ROLLBACK;
         gc_output_message := gc_output_message||'No interfaces were found NEW interface status.'||chr(10);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  No interfaces were found NEW interface status.');

         -- Printing interface data in output file
         xx_gl_jrnl_print_output_body(p_group_id           => NULL
                                     ,p_staging_request_id => gn_this_request_id
                                     ,p_period_name        => NULL
                                     ,p_sob_id             => p_sob_id
                                     ,p_source             => p_source);
           x_ret_code:=1;
      WHEN ex_staging_volume_diff THEN
         ROLLBACK;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Volume does not match. Rollback completed for the '||ln_inserted_stg_vol||' records inserted into staging table: XX_GL_INTERFACE_HIGH_VOL_NA');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Setting program status to ERROR');
         xx_print_time_stamp_to_logfile();
         x_ret_code:=2;

         -- Updating hv_stg_req_id in the control table with current high volume request id to all for displaying in the output.
         gc_error_loc := 'Updating hv_stg_req_id in the control table with current high staging volume request id in ex_staging_volume_diff';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updating hv_stg_req_id in the control table with current high volume staging request id.');
         UPDATE xx_gl_high_volume_jrnl_control XGHVJC
            SET XGHVJC.hv_stg_req_id       = gn_this_request_id
          WHERE XGHVJC.interface_status    = G_NEW
            AND XGHVJC.user_je_source_name = p_source
            AND XGHVJC.set_of_books_id     = p_sob_id;

         gc_error_loc := 'Commit update to control table for high volume staging request id in ex_staging_volume_diff';
         COMMIT;

         -- Printing interface data in output file
         gc_output_message := gc_output_message||'Staged volume does not match control table for NEW interface status. Rollback completed for the '
                                               ||ln_inserted_stg_vol||' records inserted into staging table: XX_GL_INTERFACE_HIGH_VOL_NA. '
                                               ||'See log file for more information.'||chr(10);

         gc_error_loc := 'Printing Output Section for Interfaces that could not be staged';
         -- Group ID and Period Name is not applicable when printing information for imported interfaces
         xx_gl_jrnl_print_output_body(p_group_id           => NULL
                                     ,p_staging_request_id => gn_this_request_id
                                     ,p_period_name        => NULL
                                     ,p_sob_id             => p_sob_id
                                     ,p_source             => p_source);
      WHEN ex_glint_delete_volume_diff THEN
         ROLLBACK;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Volume does not match. Rollback completed for the '||ln_del_gl_int_volume||' records deleted from GL_INTERFACE');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Setting program status to ERROR');
         xx_print_time_stamp_to_logfile();
         x_ret_code:=2;

         -- Updating hv_stg_req_id in the control table with current high volume request id to all for displaying in the output.
         gc_error_loc := 'Updating hv_stg_req_id in the control table with current high staging volume request id in ex_staging_volume_diff';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updating hv_stg_req_id in the control table with current high volume staging request id.');
         UPDATE xx_gl_high_volume_jrnl_control XGHVJC
            SET XGHVJC.hv_stg_req_id       = gn_this_request_id
          WHERE XGHVJC.interface_status    = G_NEW
            AND XGHVJC.user_je_source_name = p_source
            AND XGHVJC.set_of_books_id     = p_sob_id;

         gc_error_loc := 'Commit update to control table for high volume staging request id in ex_staging_volume_diff';
         COMMIT;

         -- Printing interface data in output file
         gc_output_message := gc_output_message||'Staged volume does not match control table. Rollback completed for the '||ln_del_gl_int_volume||' records deleted from GL_INTERFACE. '
                                               ||'See log file for more information.'||chr(10);

         gc_error_loc := 'Printing Output Section for Interfaces that could not be staged';
         -- Group ID and Period Name is not applicable when printing information for imported interfaces
         xx_gl_jrnl_print_output_body(p_group_id           => NULL
                                     ,p_staging_request_id => gn_this_request_id
                                     ,p_period_name        => NULL
                                     ,p_sob_id             => p_sob_id
                                     ,p_source             => p_source);
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for XX_GL_JRNL_STG (When Others)');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised while '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         x_ret_code:=2;

   END XX_GL_JRNL_STG;

   -- +====================================================================+
   -- | Name       : XX_GL_JRNL_SUM                                        |
   -- |                                                                    |
   -- | Description: This procedure is used to create and import a summary |
   -- |              journal from all of the journals that have been staged|
   -- |              in the high volume journal interface table by         |
   -- |              XX_GL_JRNL_STG procedure.  XX_GL_JRNL_SUM will also   |
   -- |              maintain drill-back information for the imported jrnl |
   -- |                                                                    |
   -- |              The following actions will be performed               |
   -- |                                                                    |
   -- |              A. Clean-up of interface_status of IMPORTING for      |
   -- |                 reprocessing as STAGED                             |
   -- |                                                                    |
   -- |              B. Processing/completion for interface_status of      |
   -- |                 INSERTED-REFERENCES.                               |
   -- |                                                                    |
   -- |              C. Process/import journals in STAGED status using the |
   -- |                 following steps:                                   |
   -- |                   1. Create Summary Journal                        |
   -- |                   2. Verify Summary Journal DR/CR Amounts          |
   -- |                   3. Submit GL Journal Import                      |
   -- |                   4. Insert Reference Information (for drill-back) |
   -- |                   5. Delete Detailed Journals (from interface)     |
   -- |                   6. Update cntrl as IMPORTED                      |
   -- |                                                                    |
   -- | Parameters : p_source, p_period_name, p_process_date,              |
   -- |              p_jrnl_batch_name_prefix and p_sob_id                 |
   -- |                                                                    |
   -- | Returns    : x_errbuf, x_retcode                                   |
   -- |                                                                    |
   -- +====================================================================+
   PROCEDURE XX_GL_JRNL_SUM (x_errbuf                  OUT   VARCHAR2
                             ,x_ret_code               OUT   NUMBER
                             ,p_source                 IN    VARCHAR2
                             ,p_period_name            IN    VARCHAR2
                             ,p_process_date           IN    VARCHAR2
                             ,p_jrnl_batch_name_prefix IN    VARCHAR2
                             ,p_sob_id                 IN    NUMBER)
   IS
      ln_user_id               gl_import_references.last_updated_by%TYPE;
      lc_profile_value         fnd_profile_option_values.profile_option_value%TYPE;

      -- used for holding/formatting p_process_date parameter value as a date value
      ld_process_date          xx_gl_high_volume_jrnl_control.process_date%TYPE := NULL;

      -- used for holding information retrieved about control for comparisions
      ln_cntrl_ent_dr          xx_gl_high_volume_jrnl_control.entered_dr%TYPE;
      ln_cntrl_ent_cr          xx_gl_high_volume_jrnl_control.entered_cr%TYPE;
      ln_cntrl_acc_dr          xx_gl_high_volume_jrnl_control.accounted_dr%TYPE;
      ln_cntrl_acc_cr          xx_gl_high_volume_jrnl_control.accounted_cr%TYPE;
      ln_cntrl_volume          xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;
      ln_cntrl_int_cnt         xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;

      -- used for holding information retrieved about staging for comparisions
      ln_stg_ent_dr            xx_gl_interface_high_vol_na.entered_dr%TYPE;
      ln_stg_ent_cr            xx_gl_interface_high_vol_na.entered_cr%TYPE;
      ln_stg_acc_dr            xx_gl_interface_high_vol_na.accounted_dr%TYPE;
      ln_stg_acc_cr            xx_gl_interface_high_vol_na.accounted_cr%TYPE;
      ln_stg_delete_cnt        xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;

      -- used for holding information about imported or to be imported journal
      ln_jrnl_request_id       xx_gl_high_volume_jrnl_control.request_id%TYPE   :=0;
      ln_group_id              gl_interface.group_id%TYPE;
      lc_batch_name            gl_interface.reference1%TYPE;
      ln_total_dr              gl_je_batches.running_total_dr%TYPE;
      ln_total_cr              gl_je_batches.running_total_cr%TYPE;
      ln_total_accounted_dr    gl_je_batches.running_total_accounted_dr%TYPE;
      ln_total_accounted_cr    gl_je_batches.running_total_accounted_cr%TYPE;
      ln_je_batch_id           gl_je_batches.je_batch_id%TYPE;
      ln_min_je_header_id      gl_je_headers.je_header_id%TYPE;
      ln_max_je_header_id      gl_je_headers.je_header_id%TYPE;
      ln_total_references      gl_je_headers.je_header_id%TYPE;

      -- used for holding counts of certain SQL operations for validation
      ln_inserted_ref_cnt      xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;
      ln_inserted_sum_cnt      xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;
      ln_deleted_sum_refs      xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;

      -- used for capturing amount of journal batches deleted
      ln_je_bat_deleted        xx_gl_high_volume_jrnl_control.accounted_cr%TYPE :=0;

      -- used for holding information for output regarding processed/imported jrnls
      ln_tot_jrnl_dr           xx_gl_high_volume_jrnl_control.accounted_dr%TYPE :=0;
      ln_tot_jrnl_cr           xx_gl_high_volume_jrnl_control.accounted_cr%TYPE :=0;

      -- used for reprocessing IMPORTING and INSERTED-REFERENCES statuses
      ln_imp_bat_sql_cnt       xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;
      ln_imp_bat_total_cnt     xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;
      ln_ref_bat_sql_cnt       xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;
      ln_ref_bat_total_cnt     xx_gl_high_volume_jrnl_control.volume%TYPE       :=0;

      -- exceptions
      ex_validation_warning       EXCEPTION;
      ex_validation_error         EXCEPTION;

      -- variables for submitting journal import
      lc_phase                 VARCHAR2(50);
      lc_status                VARCHAR2(50);
      lc_devphase              VARCHAR2(50);
      lc_devstatus             VARCHAR2(50);
      lc_message               VARCHAR2(250);
      ln_interface_run_id      gl_interface_control.interface_run_id%TYPE;
      lc_intface_tbl_name      gl_interface_control.interface_table_name%TYPE :='XX_GL_INTERFACE_HIGH_VOL_NA';
      lc_output_msg            VARCHAR2(2000);
      lb_req_status            BOOLEAN;
      lb_fnc_status            BOOLEAN;

      -- This cursor is used to identify interfaces that have a status of INSERTED-REFERENCES
      -- If records are returned by this cursor, the program will complete remaining steps for import
      CURSOR lcu_int_status (p_interface_status xx_gl_high_volume_jrnl_control.interface_status%TYPE)
      IS
         SELECT NVL(SUM(XGHVJC.entered_dr),0)         ENTERED_DR
               ,NVL(SUM(XGHVJC.entered_cr),0)         ENTERED_CR
               ,NVL(SUM(XGHVJC.accounted_dr),0)       ACCOUNTED_DR
               ,NVL(SUM(XGHVJC.accounted_cr),0)       ACCOUNTED_CR
               ,NVL(SUM(XGHVJC.volume),0)             VOLUME
               ,XGHVJC.interface_status
               ,XGHVJC.gl_imp_req_id
               ,XGHVJC.hv_imp_req_id
               ,XGHVJC.derived_je_batch_name
               ,XGHVJC.je_batch_id
               ,XGHVJC.journal_import_group_id
           FROM xx_gl_high_volume_jrnl_control  XGHVJC
          WHERE XGHVJC.interface_status    = p_interface_status
            AND XGHVJC.user_je_source_name = p_source
            AND XGHVJC.set_of_books_id     = p_sob_id
            AND XGHVJC.process_date        = p_process_date
            AND XGHVJC.period_name         = p_period_name
         GROUP BY XGHVJC.interface_status
                 ,XGHVJC.gl_imp_req_id
                 ,XGHVJC.hv_imp_req_id
                 ,XGHVJC.derived_je_batch_name
                 ,XGHVJC.je_batch_id
                 ,XGHVJC.journal_import_group_id;

      ltab_int_status_rec         lcu_int_status%ROWTYPE;

      -- +====================================================================+
      -- | Name       : XX_GL_SUMMARY_DEL_PROC                                |
      -- | Description: Procedure to delete the imported journal details from |
      -- |              base tables                                           |
      -- | Parameters : p_je_batch_id - gl batch id                           |
      -- | Returns    : p_je_deleted  - number of batches deleted             |
      -- +====================================================================+
      PROCEDURE XX_GL_SUMMARY_DEL_PROC (p_je_batch_id IN  NUMBER
                                       ,p_je_deleted  OUT NUMBER)
      IS
         lc_row_id       ROWID;
         lc_batch_name   gl_je_batches.name%TYPE;
      BEGIN
         p_je_deleted := 0;
         gc_error_loc := 'XX_GL_SUMMARY_DEL_PROC - Selecting ROWID';
         SELECT GJB.rowid
               ,GJB.name
           INTO lc_row_id
               ,lc_batch_name
           FROM gl_je_batches GJB
          WHERE GJB.je_batch_id = p_je_batch_id;

         gc_error_loc := 'Executing GL_JE_BATCHES_PKG.delete_row';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Executing GL_JE_BATCHES_PKG.delete_row for the following:');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'          GL Batch Name: '||lc_batch_name);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'          GL Batch ID  : '||p_je_batch_id||chr(10));

         GL_JE_BATCHES_PKG.delete_row(lc_row_id,p_je_batch_id);
         p_je_deleted := SQL%ROWCOUNT;

         IF p_je_deleted > 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Imported summary journal was successfully deleted.');
         ELSE
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Imported summary journal was NOT deleted.');
         END IF;
         xx_print_time_stamp_to_logfile();

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - Delete GL Batch Function (When NO_DATA_FOUND)');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside delete GL batch function while '||gc_error_loc);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  GL Batch ID '||p_je_batch_id||' could not be found and therefore there was nothing to delete.');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'GL Batch ID '||p_je_batch_id||' could not be found and therefore there was nothing to delete.');
            xx_print_time_stamp_to_logfile();

         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling - Delete GL Batch Function (When Others)');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised inside delete GL batch function while '||gc_error_loc);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised inside delete GL batch function while '||gc_error_loc);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'GL Batch ID '||p_je_batch_id||' ccould not be deleted.');
            xx_print_time_stamp_to_logfile();
      END;

   BEGIN
      -- Assign date passsed in as varchar2 to a date variable
      ld_process_date         := p_process_date;

      -- Printing parameter list and RICE# to log
      gc_error_loc := 'Print Parameters and RICE# to concurrent request log file';
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'** See RICE# E2049 for design info on OD: <source name> HV Journal Import  **');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters Values Used');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Journal Source       : '||p_source);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Period Name          : '||p_period_name);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Process Date         : '||p_process_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Journal Batch prefix : '||p_jrnl_batch_name_prefix);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Set Of Books ID      : '||p_sob_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');

      gc_error_loc := 'Obtaing concurrent program information';
      xx_obtain_program_info();

      -- Printing output report header information
      gc_error_loc := 'Printing report header information to concurrent request output';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Office Depot',50,' ')||LPAD('Date : '||TO_CHAR(SYSDATE, 'DD-MON-YYYY'),124,' '));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '||RPAD(gn_this_request_id,45,' ')||LPAD('Page : '||1,107,' ')||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(gc_program_name,95,' ')||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Source: '||p_source);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period Name   : '||p_period_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Process Date  : '||TO_CHAR(ld_process_date, 'YYYY/MM/DD'));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books  : '||p_sob_id||chr(10));

      FND_FILE.PUT_LINE(FND_FILE.LOG,'=============================================================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Process IMPORTING interface status (Delete summary journal and reset)   --');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================================================='||chr(10));
      BEGIN

         gc_error_loc := 'Checking for interfaces in control table with interface status = IMPORTING';
         OPEN lcu_int_status(G_IMPORTING);
         LOOP
            FETCH lcu_int_status INTO ltab_int_status_rec;
            EXIT WHEN lcu_int_status%NOTFOUND;

            ln_je_bat_deleted := 0;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Information Retrieved for High Volume Journal Import Request ID: '||ltab_int_status_rec.hv_imp_req_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Interface Status : '||ltab_int_status_rec.interface_status);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume           : '||ltab_int_status_rec.volume);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered DR       : '||ltab_int_status_rec.entered_dr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered CR       : '||ltab_int_status_rec.entered_cr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted DR     : '||ltab_int_status_rec.accounted_dr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted CR     : '||ltab_int_status_rec.accounted_cr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       GL Imp Req ID    : '||ltab_int_status_rec.gl_imp_req_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       JE Batch Name    : '||ltab_int_status_rec.derived_je_batch_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       JE Batch ID      : '||ltab_int_status_rec.je_batch_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Jrnl Imp Group ID: '||ltab_int_status_rec.journal_import_group_id||chr(10));

            gc_error_loc := 'Obtain summary journal amounts from the high volume interface table for IMPORTING status';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entered and Accounted DR/CR from staging table (xx_gl_interface_high_vol_na)');
            SELECT NVL(SUM(XGIHVN.entered_dr),0)
                  ,NVL(SUM(XGIHVN.entered_cr),0)
                  ,NVL(SUM(XGIHVN.accounted_dr),0)
                  ,NVL(SUM(XGIHVN.accounted_cr),0)
              INTO ln_stg_ent_dr
                  ,ln_stg_ent_cr
                  ,ln_stg_acc_dr
                  ,ln_stg_acc_cr
              FROM xx_gl_interface_high_vol_na     XGIHVN
                  ,xx_gl_high_volume_jrnl_control  XGHVJC
             WHERE XGHVJC.interface_status    = G_IMPORTING
               AND XGHVJC.user_je_source_name = p_source
               AND XGHVJC.set_of_books_id     = p_sob_id
               AND XGHVJC.process_date        = ld_process_date
               AND XGHVJC.period_name         = p_period_name
               AND XGHVJC.hv_imp_req_id       = ltab_int_status_rec.hv_imp_req_id
               AND XGHVJC.hv_imp_req_id       = XGIHVN.request_id;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered   DR    : '||ln_stg_ent_dr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered   CR    : '||ln_stg_ent_cr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted DR    : '||ln_stg_acc_dr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted CR    : '||ln_stg_acc_cr);
            xx_print_time_stamp_to_logfile();

            -- Compare the totals obtained
            -- if totals match, the summary journal was not imported and therefore needs to be deleted
            gc_error_loc := 'Comparing the sum Entered and Accounted CR/DR ';

            -- Check if control table is out of balance
            IF (ltab_int_status_rec.entered_dr   - ltab_int_status_rec.entered_cr)   +
               (ltab_int_status_rec.accounted_dr - ltab_int_status_rec.accounted_cr) <> 0 THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  Control table is out of balance.  Summary journal or imported journal will not be deleted.');

            -- Check if summary is out of balance
            ELSIF (ln_stg_ent_dr - ln_stg_ent_cr) +
                  (ln_stg_acc_dr - ln_stg_acc_cr) <> 0 THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Summary Journal is out of balance in staging table.  Summary journal will not be deleted.');

            -- Check if staging and control table balance
            -- If no summary journal in the table, then the imported journal will be deleted.
            ELSIF (ln_stg_ent_dr = ltab_int_status_rec.entered_dr    AND
                   ln_stg_ent_cr = ltab_int_status_rec.entered_cr    AND
                   ln_stg_acc_dr = ltab_int_status_rec.accounted_dr  AND
                   ln_stg_acc_cr = ltab_int_status_rec.accounted_cr) THEN

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Summary journal was not imported.  Deleting summary journal.'||chr(10));

                  -- Delete summary journal from high volume journal interface table
                  gc_error_loc := 'Deleting summary journal from high volume journal interface table during clean-up for IMPORTING interface status.';
                  DELETE /*+ INDEX(XGIHVN XX_GL_INTERFACE_HIGH_VOL_NA_N2) */
                         xx_gl_interface_high_vol_na XGIHVN
                   WHERE XGIHVN.request_id IN (ltab_int_status_rec.gl_imp_req_id, ltab_int_status_rec.hv_imp_req_id)
                     AND XGIHVN.user_je_source_name = p_source
                     AND XGIHVN.set_of_books_id     = p_sob_id;

                  ln_stg_delete_cnt := SQL%ROWCOUNT;

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||ln_stg_delete_cnt||' records deleted from high volume interface for summary journal during clean-up for IMPORTING interface status.');
                  xx_print_time_stamp_to_logfile();
            ELSE
               FND_FILE.PUT_LINE(FND_FILE.LOG,'  There was no imported summary journal to delete from staging table (see above). Deleting Summary Journal if it was imported.'||chr(10));
               BEGIN
                  -- summary journal does not exist in the staging table, it was imported.
                  -- Delete imported journal
                  gc_error_loc := 'Deleting imported summary journal during clean-up for IMPORTING interface status, it it exists.';
                  xx_gl_summary_del_proc(p_je_batch_id => ltab_int_status_rec.je_batch_id
                                        ,p_je_deleted  => ln_je_bat_deleted);
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'  Summary Journal was not imported.  There was no imported summary journal to delete .');
               END;
            END IF;

            -- Set interface status to STAGED if imported journal deleted or summary journal deleted
            gc_error_loc := 'Check if imported journal or summary journal from high volume interface was deleted.';
            IF ln_je_bat_deleted > 0 or ln_stg_delete_cnt > 0 THEN
               -- RESETTING INTERFACE_STATUS back to STAGED from IMPORTING
               gc_error_loc := 'Updating/resetting interface_status back to STAGED in control table during clean-up for IMPORTING interface status.';
               UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                  SET XGHVJC.interface_status    = G_STAGED
                WHERE XGHVJC.interface_status    = G_IMPORTING
                  AND XGHVJC.user_je_source_name = p_source
                  AND XGHVJC.set_of_books_id     = p_sob_id
                  AND XGHVJC.process_date        = ld_process_date
                  AND XGHVJC.period_name         = p_period_name
                  AND XGHVJC.hv_imp_req_id       = ltab_int_status_rec.hv_imp_req_id;

               -- Track records updated
               ln_imp_bat_sql_cnt   := SQL%ROWCOUNT;
               ln_imp_bat_total_cnt := ln_imp_bat_total_cnt + ln_imp_bat_sql_cnt;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'   '||ln_imp_bat_sql_cnt||' records updated back to STAGED from IMPORTING in control table during clean-up for IMPORTING interface status.');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'  JE Batch ID, Batch Name, GL Imp RID, HV Imp RID, and Jrnl Imp Group id have been set to -1.');
               xx_print_time_stamp_to_logfile();

               -- reset variable for subsequent processing for STAGED interface status
               lc_batch_name := NULL;

               gc_error_loc := 'Commit status update to STAGED in control table for interfaces having a status of IMPORTING';
               COMMIT;
            ELSE
               gc_error_loc := 'Rolling back deletion of summary journal.';
               FND_FILE.PUT_LINE(FND_FILE.LOG,'  Summary journal was not deleted.');
               x_ret_code :=1;   -- Set concurrent program to WARNING status, but this could be overwritten by subsequent processing.
               -- Rollback should not really be required since a journal was not deleted.
               ROLLBACK;
            END IF;
        END LOOP;
        CLOSE lcu_int_status;

        gc_error_loc := 'Write message to output if no interface records were reset back to interface_status of STAGED';
        IF ln_imp_bat_total_cnt = 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  No interface records were reset back to interface_status of STAGED.'||chr(10));
        ELSE
            -- update global variable to writing message to concurrent request output to indicate clean-up of interfaces stuck in STAGING status
            gc_output_message := gc_output_message||'Additional processing was performed for interfaces that were in IMPORTING status from a previsous run.  '
                                                  ||'See log file for more information.'||chr(10);
            IF ln_je_bat_deleted > 0 THEN
               gc_output_message := gc_output_message||'The previously imported summary journal, '||ltab_int_status_rec.derived_je_batch_name||', has been deleted.  See log file for more information.'||chr(10);
            END IF;
        END IF;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for Resetting Interface Status of IMPORTING');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised while '||gc_error_loc);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while '||gc_error_loc);
            ROLLBACK;
            xx_print_time_stamp_to_logfile();
            x_ret_code :=1;   -- Set concurrent program to WARNING status, but this could be overwritten by subsequent processing.
            -- close cursor if still open
            IF lcu_int_status%ISOPEN THEN
               CLOSE lcu_int_status;
            END IF;
      END;  -- End processing for IMPORTING interface status

      FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'=============================================================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Process INSERTED-REFERENCES interface status (Delete staged jrnl lines) --');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================================================='||chr(10));
      BEGIN

         gc_error_loc := 'Checking for interfaces in control table with interface status = INSERTED-REFERENCES';
         OPEN lcu_int_status(G_INSERTED_REFERENCES);
         LOOP
            FETCH lcu_int_status INTO ltab_int_status_rec;
            EXIT WHEN lcu_int_status%NOTFOUND;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Information Retrieved for High Volume Journal Import Request ID: '||ltab_int_status_rec.hv_imp_req_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Interface Status : '||ltab_int_status_rec.interface_status);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume           : '||ltab_int_status_rec.volume);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered DR       : '||ltab_int_status_rec.entered_dr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Entered CR       : '||ltab_int_status_rec.entered_cr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted DR     : '||ltab_int_status_rec.accounted_dr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Accounted CR     : '||ltab_int_status_rec.accounted_cr);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       GL Imp Req ID    : '||ltab_int_status_rec.gl_imp_req_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       JE Batch Name    : '||ltab_int_status_rec.derived_je_batch_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       JE Batch ID      : '||ltab_int_status_rec.je_batch_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'       Jrnl Imp Group ID: '||ltab_int_status_rec.journal_import_group_id||chr(10));

            BEGIN
               gc_error_loc := 'Selecting information about imported summary journal during repocessing for INSERTED-REFERENCES';
               FND_FILE.PUT_LINE(FND_FILE.LOG,'  Selecting information about imported summary journal into GL');
               SELECT GJB.running_total_dr
                     ,GJB.running_total_cr
                     ,GJB.running_total_accounted_dr
                     ,GJB.running_total_accounted_cr
                     ,XX_FIN_PERF_METRICS_PKG.XX_GET_JE_LINE_CNT(ltab_int_status_rec.je_batch_id)
                 INTO ln_total_dr
                     ,ln_total_cr
                     ,ln_total_accounted_dr
                     ,ln_total_accounted_cr
                     ,ln_total_references
                 FROM gl_je_batches GJB
                     ,gl_je_headers GJH
                WHERE GJB.je_batch_id     = ltab_int_status_rec.je_batch_id
                  AND GJB.je_batch_id     = GJH.je_batch_id
                  AND GJB.set_of_books_id = p_sob_id
                GROUP BY GJB.je_batch_id
                        ,GJB.running_total_dr
                        ,GJB.running_total_cr
                        ,GJB.running_total_accounted_dr
                        ,GJB.running_total_accounted_cr;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'     Batch Total Entered DR  : '||ln_total_dr);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'     Batch Total Entered CR  : '||ln_total_cr);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'     Batch Total Accounted DR: '||ln_total_accounted_dr);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'     Batch Total Accounted CR: '||ln_total_accounted_cr);
               xx_print_time_stamp_to_logfile();

               gc_error_loc := 'Deleting detailed journal lines from staging table for reprocessing INSERTED-REFERENCES status';
               DELETE /*+ FULL(XGIHVN) PARALLEL(XGIHVN,8)*/ xx_gl_interface_high_vol_na XGIHVN
               WHERE EXISTS (SELECT /*+ FULL(XGHVJC) PARALLEL(XGHVJC,8) */ 1
                               FROM xx_gl_high_volume_jrnl_control  XGHVJC
                              WHERE XGHVJC.interface_status    = G_INSERTED_REFERENCES
                                AND XGHVJC.user_je_source_name = p_source
                                AND XGHVJC.set_of_books_id     = p_sob_id
                                AND XGHVJC.process_date        = ld_process_date
                                AND XGHVJC.period_name         = p_period_name
                                AND XGHVJC.hv_imp_req_id       = ltab_int_status_rec.hv_imp_req_id
                                AND XGHVJC.request_id          = XGIHVN.request_id)
                 AND XGIHVN.user_je_source_name = p_source;
               ln_stg_delete_cnt := SQL%ROWCOUNT;


               FND_FILE.PUT_LINE(FND_FILE.LOG,'  Compariosn of rows deleted from high volume interface to control table:');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'       Rows deleted from XX_GL_INTERFACE_HIGH_VOL_NA: '||ln_stg_delete_cnt);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'       Volume from XX_GL_HIGH_VOLUME_JRNL_CONTROL   : '||ltab_int_status_rec.volume);
               xx_print_time_stamp_to_logfile();

               gc_error_loc := 'Verify volume and amounts for control table, staging, and interface table for INSERTED-REFERENCES';
               IF (ln_stg_delete_cnt     <> ltab_int_status_rec.volume)  THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Unable to complete processing due to delete volume does not match staging table.'||chr(10));
                  ROLLBACK;
                  x_ret_code :=1;   -- Set concurrent program to WARNING status.  Status may be overwritten.

               ELSIF (ln_total_dr           <> ltab_int_status_rec.entered_dr    OR
                      ln_total_cr           <> ltab_int_status_rec.entered_cr    OR
                      ln_total_accounted_dr <> ltab_int_status_rec.accounted_dr  OR
                      ln_total_accounted_cr <> ltab_int_status_rec.accounted_cr) THEN

                      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Unable to complete processing due to journal amounts are not matching staging table.'||chr(10));
                      ROLLBACK;
                      x_ret_code :=1;   -- Set concurrent program to WARNING status.  Status may be overwritten.

               ELSIF (ln_total_references <> ltab_int_status_rec.volume) THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Unable to complete processing due to volume of references does not match staging table.'||chr(10));
                      ROLLBACK;
                      x_ret_code :=1;   -- Set concurrent program to WARNING status.  Status may be overwritten.

               ELSE FND_FILE.PUT_LINE(FND_FILE.LOG,'  Delete from staging table successfully completed and passed all validations.');
                     xx_print_time_stamp_to_logfile();

                    gc_error_loc := 'Updating journal_import_group_id, interface_status and journal batch id in control table';
                    UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                       SET XGHVJC.interface_status    = G_IMPORTED
                     WHERE XGHVJC.interface_status    = G_INSERTED_REFERENCES
                       AND XGHVJC.user_je_source_name = p_source
                       AND XGHVJC.set_of_books_id     = p_sob_id
                       AND XGHVJC.process_date        = ld_process_date
                       AND XGHVJC.period_name         = p_period_name
                       AND XGHVJC.hv_imp_req_id       = ltab_int_status_rec.hv_imp_req_id;

                    -- Track records updated
                    ln_ref_bat_sql_cnt   := SQL%ROWCOUNT;
                    ln_ref_bat_total_cnt := ln_ref_bat_total_cnt + ln_ref_bat_sql_cnt;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||ln_ref_bat_sql_cnt||' records updated back to IMPORTED from INSERTED-REFERNCES in control '||
                                                                              'table during clean-up for INSERTED-REFERENCES interface status.');
                    xx_print_time_stamp_to_logfile();
                    gc_error_loc := 'Commit status update to IMPORTED in control table for interfaces that were completed';
                    COMMIT;
               END IF;

            EXCEPTION
               WHEN TOO_MANY_ROWS THEN
                  gc_error_loc := 'Too many gl batch ids selected during reprocessing for INSERTED-REFERENCES';
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for too many gl batch ids during reprocessing for INSERTED-REFERENCES.');
                  xx_print_time_stamp_to_logfile();
                  x_ret_code :=1;   -- Set concurrent program to WARNING status, but this could be overwritten by subsequent processing.

               WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for during deletion of detailed records');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised while '||gc_error_loc);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Delete of detailed records in staging table not successful.');
                  ROLLBACK;
                  xx_print_time_stamp_to_logfile();
                  x_ret_code :=1;   -- Set concurrent program to WARNING status, but this could be overwritten by subsequent processing.
            END;

        END LOOP;
        CLOSE lcu_int_status;

        gc_error_loc := 'Write message to output if no interface records were reset back to interface_status of IMPORTED';
        IF ln_ref_bat_total_cnt = 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  No interface records were reset back to interface_status of IMPORTED.'||chr(10));
        ELSE
            -- Update global variable to writing message to concurrent request output to indicate clean-up of interfaces stuck in STAGING status
            gc_output_message := gc_output_message||'Additional processing was performed for interfaces that were in '
                                                  ||'INSERTED-REFERENCES status from a previsous run.  See log file for more information.'||chr(10);
        END IF;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for Clean-Up Interface Status of INSERTED-REFERENCES');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised while '||gc_error_loc);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while '||gc_error_loc);

            ROLLBACK;
            -- close cursor if still open
            IF lcu_int_status%ISOPEN THEN
               CLOSE lcu_int_status;
            END IF;

      END;  -- End processing for INSERTED-REFERENCES interface status

      FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||chr(10));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'=============================================================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Process STAGED interface status (Summarize, Import, Insert References)  --');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================================================='||chr(10));
      BEGIN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Step #1 - Create Summary Journal   --');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');

         -- Updating INTERFACE_STATUS to IMPORTING and updateing hv import RID to mark interfaces that are in-progress
         gc_error_loc := 'Updating interface_status to IMPORTING in control table - Initial Update';
         UPDATE xx_gl_high_volume_jrnl_control XGHVJC
            SET XGHVJC.interface_status    = G_IMPORTING
               ,XGHVJC.hv_imp_req_id       = gn_this_request_id
          WHERE XGHVJC.interface_status    = G_STAGED
            AND XGHVJC.user_je_source_name = p_source
            AND XGHVJC.set_of_books_id     = p_sob_id
            AND XGHVJC.process_date        = ld_process_date
            AND XGHVJC.period_name         = p_period_name;

         ln_cntrl_int_cnt :=SQL%ROWCOUNT;

         gc_error_loc := 'Verify if interfaces exist for importing (interface_status = STAGED)';
         IF (ln_cntrl_int_cnt > 0) THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated interface status to IMPORTING in control table to designate records as in-progress'||chr(10));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Count of interfaces selected for IMPORTING: '||ln_cntrl_int_cnt);

            -- Get group_id for summary journal
            gc_error_loc := 'Selecting value for group_id from sequence';
            SELECT apps.gl_interface_control_s.NEXTVAL
              INTO ln_group_id
              FROM dual;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Group ID used for summary journal: '||ln_group_id);

            -- generate INITIAL/partial batch name (reference1) before journal import adds on to it
            gc_error_loc := 'Assigning value for batch name';
            IF (p_jrnl_batch_name_prefix IS NOT NULL) THEN
               lc_batch_name := p_jrnl_batch_name_prefix||' '||TO_CHAR(ld_process_date,'RRRR/MM/DD')||' ';
            ELSE
               lc_batch_name := TO_CHAR(ld_process_date,'RRRR/MM/DD')||' ';
            END IF;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Derived INITIAL/PARTIAL GL Batch Name: '||lc_batch_name);

         ELSE
            -- When no records in STAGED status raise exception to stop program
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  No interface were found with an interface_status of STAGED');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Setting concurrent program to WARNING status.');
            gc_output_message := gc_output_message||'Summary journal cannot be created.  There are no records in the control table with interface_status = STAGED.  '
                                                  ||'See log file for more information.'||chr(10);
            RAISE ex_validation_warning;
         END IF;

         -- create summary journal from detailed journals
         xx_print_time_stamp_to_logfile();
         gc_error_loc := 'Creating/inserting summary journal lines in staging table';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Creating/inserting summary journal lines in staging table');
         INSERT INTO XX_GL_INTERFACE_HIGH_VOL_NA   --- staging table created with multi-table journal import API's
               (status
               ,set_of_books_id
               ,accounting_date
               ,currency_code
               ,actual_flag
               ,user_je_category_name
               ,user_je_source_name
               ,currency_conversion_date
               ,encumbrance_type_id
               ,budget_version_id
               ,user_currency_conversion_type
               ,currency_conversion_rate
               ,average_journal_flag
               ,originating_bal_seg_value
               ,segment1
               ,segment2
               ,segment3
               ,segment4
               ,segment5
               ,segment6
               ,segment7
               ,entered_dr
               ,entered_cr
               ,accounted_dr
               ,accounted_cr
               ,reference1
               ,reference21
               ,code_combination_id
               ,group_id
               ,request_id
               ,date_created
               ,created_by)
         SELECT /*+ FULL(XGIHVN) PARALLEL(XGIHVN,4)*/
                G_NEW
               ,XGIHVN.set_of_books_id
               ,XGIHVN.accounting_date
               ,XGIHVN.currency_code
               ,XGIHVN.actual_flag
               ,XGIHVN.user_je_category_name
               ,XGIHVN.user_je_source_name
               ,XGIHVN.currency_conversion_date
               ,XGIHVN.encumbrance_type_id
               ,XGIHVN.budget_version_id
               ,XGIHVN.user_currency_conversion_type
               ,XGIHVN.currency_conversion_rate
               ,XGIHVN.average_journal_flag
               ,XGIHVN.originating_bal_seg_value
               ,XGIHVN.segment1
               ,XGIHVN.segment2
               ,XGIHVN.segment3
               ,XGIHVN.segment4
               ,XGIHVN.segment5
               ,XGIHVN.segment6
               ,XGIHVN.segment7
               ,SUM(XGIHVN.entered_dr)
               ,SUM(XGIHVN.entered_cr)
               ,SUM(XGIHVN.accounted_dr)
               ,SUM(XGIHVN.accounted_cr)
               ,lc_batch_name
               ,ln_group_id
               ,XGIHVN.code_combination_id
               ,ln_group_id
               ,gn_this_request_id
               ,SYSDATE
               ,FND_GLOBAL.USER_ID
           FROM xx_gl_interface_high_vol_na XGIHVN
               ,xx_gl_high_volume_jrnl_control XGHVJC
         WHERE XGHVJC.interface_status    = G_IMPORTING
           AND XGHVJC.user_je_source_name = p_source
           AND XGHVJC.set_of_books_id     = p_sob_id
           AND XGHVJC.process_date        = ld_process_date
           AND XGHVJC.period_name         = p_period_name
           AND XGHVJC.hv_imp_req_id       = gn_this_request_id
           AND XGIHVN.request_id          = XGHVJC.request_id
         GROUP BY XGIHVN.set_of_books_id
                 ,XGIHVN.accounting_date
                 ,XGIHVN.currency_code
                 ,XGIHVN.actual_flag
                 ,XGIHVN.user_je_category_name
                 ,XGIHVN.user_je_source_name
                 ,XGIHVN.currency_conversion_date
                 ,XGIHVN.encumbrance_type_id
                 ,XGIHVN.budget_version_id
                 ,XGIHVN.user_currency_conversion_type
                 ,XGIHVN.currency_conversion_rate
                 ,XGIHVN.average_journal_flag
                 ,XGIHVN.originating_bal_seg_value
                 ,XGIHVN.segment1
                 ,XGIHVN.segment2
                 ,XGIHVN.segment3
                 ,XGIHVN.segment4
                 ,XGIHVN.segment5
                 ,XGIHVN.segment6
                 ,XGIHVN.segment7
                 ,XGIHVN.code_combination_id
                 ,DECODE(XGIHVN.entered_dr, NULL, 1, 0)
                 ,DECODE(XGIHVN.entered_cr, NULL, 1, 0);

         ln_inserted_sum_cnt := SQL%ROWCOUNT;

         gc_error_loc := 'Verify count of journal lines created for summary journal';
         IF (ln_inserted_sum_cnt > 0) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Count of journal lines created for summary journal: '||ln_inserted_sum_cnt);
            xx_print_time_stamp_to_logfile();
         ELSE
            -- When no records in STAGED status raise exception to stop program
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Summary journal was not created.  There are no records in the control table with interface_status = STAGED');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Setting concurrent program to WARNING status.');
            gc_output_message := gc_output_message||'Summary journal can not created.  There are no records in the control table with interface_status = STAGED.  '
                                                  ||'See log file for more information.'||chr(10);
            RAISE ex_validation_warning;
         END IF;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Step #2 - Verify Summary DR/CR Amt --');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');

         gc_error_loc := 'Fetching the sum Entered and Accounted CR/DR from control table';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entered and Accounted CR/DR from control table (xx_gl_high_volume_jrnl_control)');
         SELECT NVL(SUM(XGHVJC.entered_dr),0)
               ,NVL(SUM(XGHVJC.entered_cr),0)
               ,NVL(SUM(XGHVJC.accounted_dr),0)
               ,NVL(SUM(XGHVJC.accounted_cr),0)
               ,NVL(SUM(XGHVJC.volume),0)
           INTO ln_cntrl_ent_dr
               ,ln_cntrl_ent_cr
               ,ln_cntrl_acc_dr
               ,ln_cntrl_acc_cr
               ,ln_cntrl_volume
           FROM xx_gl_high_volume_jrnl_control XGHVJC
          WHERE XGHVJC.interface_status    = G_IMPORTING
            AND XGHVJC.user_je_source_name = p_source
            AND XGHVJC.set_of_books_id     = p_sob_id
            AND XGHVJC.process_date        = ld_process_date
            AND XGHVJC.period_name         = p_period_name
            AND XGHVJC.hv_imp_req_id       = gn_this_request_id ;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Entered   DR: '||ln_cntrl_ent_dr);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Entered   CR: '||ln_cntrl_ent_cr);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Accounted DR: '||ln_cntrl_acc_dr);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Accounted CR: '||ln_cntrl_acc_cr);
         xx_print_time_stamp_to_logfile();

         -- Calculate the sum Entered and Accounted CR/DR for summarized journal lines in xx_gl_interface_high_vol_na staging table
         gc_error_loc := 'Fetching the sum Entered and Accounted CR/DR from staging table';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entered and Accounted CR/DR from staging table (xx_gl_interface_high_vol_na)');

         SELECT NVL(SUM(XGIHVN.entered_dr),0)
               ,NVL(SUM(XGIHVN.entered_cr),0)
               ,NVL(SUM(XGIHVN.accounted_dr),0)
               ,NVL(SUM(XGIHVN.accounted_cr),0)
           INTO ln_stg_ent_dr
               ,ln_stg_ent_cr
               ,ln_stg_acc_dr
               ,ln_stg_acc_cr
           FROM xx_gl_interface_high_vol_na XGIHVN
          WHERE XGIHVN.user_je_source_name = p_source
            AND XGIHVN.set_of_books_id     = p_sob_id
            AND XGIHVN.request_id          = gn_this_request_id   -- high volume import RID
            AND XGIHVN.group_id            = ln_group_id;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Entered   DR: '||ln_stg_ent_dr);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Entered   CR: '||ln_stg_ent_cr);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Accounted DR: '||ln_stg_acc_dr);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     Accounted CR: '||ln_stg_acc_cr);
         xx_print_time_stamp_to_logfile();

         -- Compare the totals between control and staging table
         gc_error_loc := 'Comparing the sum Entered and Accounted CR/DR ';
         IF (ln_cntrl_ent_dr = ln_stg_ent_dr  AND
             ln_cntrl_ent_cr = ln_stg_ent_cr  AND
             ln_cntrl_acc_dr = ln_stg_acc_dr  AND
             ln_cntrl_acc_cr = ln_stg_acc_cr) THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'  The sum of Entered and Accounted CR/DR match for summary journals and control table.'||chr(10));

            FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Step #3 - Submit GL Journal Import --');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
            -- this allow the journal source to be processed by the standard Journal Import program
            gc_error_loc := 'Calling populate_interface_control ';
            apps.gl_journal_import_pkg.populate_interface_control
                                  (user_je_source_name => p_source
                                  ,group_id            => ln_group_id
                                  ,set_of_books_id     => p_sob_id
                                  ,interface_run_id    => ln_interface_run_id
                                  ,table_name          => lc_intface_tbl_name);

            -- submit Journal Import (not Program - Import Journals)
            gc_error_loc := 'Submitting Journal Import';
            ln_jrnl_request_id := apps.fnd_request.submit_request
                                    (application => 'SQLGL'
                                    ,program     => 'GLLEZL'
                                    ,description => NULL
                                    ,start_time  => NULL
                                    ,sub_request => FALSE
                                    ,argument1   => TO_CHAR(ln_interface_run_id)
                                    ,argument2   => p_sob_id
                                    ,argument3   => 'N'
                                    ,argument4   => NULL
                                    ,argument5   => NULL
                                    ,argument6   => 'Y'
                                    ,argument7   => 'N');

            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Journal Import Request ID '|| TO_CHAR (ln_jrnl_request_id)||' Submitted.'||chr(10));

            -- Derive full batch name for journal to be imported
            lc_batch_name := lc_batch_name||p_source||' '||ln_jrnl_request_id||': A '||ln_group_id;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Derived FINAL GL Batch Name: '||lc_batch_name||chr(10));

            IF ln_jrnl_request_id = 0   THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Status    : NOT SUBMITTED');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Request ID: NONE'||chr(10));
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error: Unable to submit Journal Import');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error: Unable to submit Journal Import');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rolling Back Summary Journal');
               xx_print_time_stamp_to_logfile();

               ROLLBACK;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rolling Back Completed');
               RAISE ex_validation_error;
            -- Journal Import was Successfully Submitted
            ELSE
               -- Updating control table with journal import request id and derived batch name
               -- Inteface status was previously updated to IMPORTING before the creation of the summary journal to mark records for processing
               gc_error_loc := 'Updating interface_status to IMPORTING to indicate Journal Import has been successfully submitted.';
               UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                  SET XGHVJC.interface_status        = G_IMPORTING
                     ,XGHVJC.gl_imp_req_id           = ln_jrnl_request_id
                     ,XGHVJC.hv_imp_req_id           = gn_this_request_id
                     ,XGHVJC.derived_je_batch_name   = lc_batch_name
                     ,XGHVJC.journal_import_group_id = ln_group_id
                WHERE XGHVJC.interface_status    = G_IMPORTING
                  AND XGHVJC.user_je_source_name = p_source
                  AND XGHVJC.set_of_books_id     = p_sob_id
                  AND XGHVJC.process_date        = ld_process_date
                  AND XGHVJC.period_name         = p_period_name
                  AND XGHVJC.hv_imp_req_id       = gn_this_request_id;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated interface status to IMPORTING, request ids, and batch name in control table'||chr(10));

               gc_error_loc := 'Commit summary journal, interface status update to IMPORTING, and submission of journal import';
               COMMIT;

               gc_error_loc := 'Waiting for Journal Import concurrent request to complete';
               lb_req_status := fnd_concurrent.wait_for_request(request_id => ln_jrnl_request_id
                                                               ,INTERVAL   => '10'
                                                               ,max_wait   => ''
                                                               ,phase      => lc_phase
                                                               ,status     => lc_status
                                                               ,dev_phase  => lc_devphase
                                                               ,dev_status => lc_devstatus
                                                               ,message    => lc_message);

               FND_FILE.PUT_LINE(FND_FILE.LOG,'  Journal Import Request ID '|| TO_CHAR (ln_jrnl_request_id)||' Completed.');

               xx_print_time_stamp_to_logfile();

               IF (lc_devstatus <> 'NORMAL') AND (lc_devphase = 'COMPLETE') THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')||chr(10));
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Warning: Failed to successfully complete Journal Import');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Please review Journal Import Execution report (output) for more information.'||chr(10));
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Status    : NOT IMPORTED');
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Request ID: '||ln_jrnl_request_id||chr(10));
                  gc_output_message := gc_output_message||'See Journal Import Execution Report Request ID '||ln_jrnl_request_id
                                                        ||' for more information about imported journal.'||chr(10);

                  -- Check if Journal Import Was Terminated.  If so, need determine if journal was still imported so it can be deleted
                  IF lc_devstatus = 'TERMINATED' THEN
                     gc_error_loc := 'Journal Import was terminated';
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Journal Import was terminated.  Deleting imported summary journal if it exists (imported).');

                     BEGIN
                        gc_error_loc := 'Journal Import was terminated - Checking if summary journal was imported still';
                        SELECT GJB.je_batch_id
                          INTO ln_je_batch_id
                          FROM gl_je_batches GJB
                              ,gl_je_headers GJH
                         WHERE GJB.name            = lc_batch_name
                           AND GJB.set_of_books_id = p_sob_id
                           AND GJB.je_batch_id     = GJH.je_batch_id;

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  JE Batch ID: '||ln_je_batch_id);
                        xx_gl_summary_del_proc(p_je_batch_id => ln_je_batch_id
                                              ,p_je_deleted  => ln_je_bat_deleted);
                        IF ln_je_bat_deleted > 0 THEN
                           gc_output_message := gc_output_message||'Imported Journal has been deleted.  See log file for more information.'||chr(10);
                        END IF;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'  Summary Journal was not imported.  Journal Import was terminated in time.');
                     END;
                  END IF;

                  xx_print_time_stamp_to_logfile();

                  -- Delete summary journal if Journal Import was not successful
                  gc_error_loc := 'Deleting summary journal due to unsuccessful journal import.';
                  DELETE /*+ INDEX(XGIHVN XX_GL_INTERFACE_HIGH_VOL_NA_N2) */
                         xx_gl_interface_high_vol_na XGIHVN
                   WHERE XGIHVN.request_id IN (ln_jrnl_request_id, gn_this_request_id)
                     AND XGIHVN.user_je_source_name = p_source;

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQL%ROWCOUNT||' records deleted from gl_interface for summary journal that failed to import.');
                  xx_print_time_stamp_to_logfile();

                  -- RESETTING INTERFACE_STATUS back to STAGED from IMPORTING
                  gc_error_loc := 'Updating/resetting interface_status back to STAGED in control table - after unsuccessful journal import.';
                  UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                     SET XGHVJC.interface_status    = G_STAGED
                   WHERE XGHVJC.interface_status    = G_IMPORTING
                     AND XGHVJC.user_je_source_name = p_source
                     AND XGHVJC.set_of_books_id     = p_sob_id
                     AND XGHVJC.process_date        = ld_process_date
                     AND XGHVJC.period_name         = p_period_name
                     AND XGHVJC.hv_imp_req_id       = gn_this_request_id;

                  gc_error_loc := 'Commit status update to STAGED in control table - after unsuccessful journal import.';
                  COMMIT;

                  -- Raise exception and setting concurrent program status to ERROR due to Journal Import failed
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated/reset interface status back to STAGED from IMPORTING in control table due to unsuccessful journal import.');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Setting concurrent program to ERROR status.');
                  RAISE EX_VALIDATION_ERROR;

               ELSE
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Status    : IMPORTED');
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Request ID: '||ln_jrnl_request_id);

                  -- select information about imported summary journal
                  -- The fully derived journal batch name will be used to determine if journal imported successfully.
                  -- The header ID's and the single batch id below is needed in order to insert GL_IMPORT_REFERENCES
                  BEGIN
                     gc_error_loc := 'Selecting information about imported summary journal';
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Selecting information about imported summary journal into GL');
                     SELECT GJB.je_batch_id
                           ,GJB.running_total_dr
                           ,GJB.running_total_cr
                           ,GJB.running_total_accounted_dr
                           ,GJB.running_total_accounted_cr
                           ,MIN(GJH.je_header_id)
                           ,MAX(GJH.je_header_id)
                       INTO ln_je_batch_id
                           ,ln_total_dr
                           ,ln_total_cr
                           ,ln_total_accounted_dr
                           ,ln_total_accounted_cr
                           ,ln_min_je_header_id
                           ,ln_max_je_header_id
                       FROM gl_je_batches GJB
                           ,gl_je_headers GJH
                      WHERE GJB.name            = lc_batch_name
                        AND GJB.je_batch_id     = GJH.je_batch_id
                        AND GJB.set_of_books_id = p_sob_id
                      GROUP BY GJB.je_batch_id
                              ,GJB.running_total_dr
                              ,GJB.running_total_cr
                              ,GJB.running_total_accounted_dr
                              ,GJB.running_total_accounted_cr;

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     JE Batch ID             : '||ln_je_batch_id);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     Batch Total Entered DR  : '||ln_total_dr);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     Batch Total Entered CR  : '||ln_total_cr);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     Batch Total Accounted DR: '||ln_total_accounted_dr);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     Batch Total Accounted CR: '||ln_total_accounted_cr);
                     xx_print_time_stamp_to_logfile();

                     gc_error_loc := 'Updating je_batch_id for IMPORTING interface_status where journal was successfully imported.';
                     UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                        SET XGHVJC.je_batch_id           = ln_je_batch_id
                      WHERE XGHVJC.interface_status    = G_IMPORTING
                        AND XGHVJC.user_je_source_name = p_source
                        AND XGHVJC.set_of_books_id     = p_sob_id
                        AND XGHVJC.process_date        = ld_process_date
                        AND XGHVJC.period_name         = p_period_name
                        AND XGHVJC.hv_imp_req_id       = gn_this_request_id;

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updating je_batch_id for IMPORTING interface_status where journal was successfully imported.'||chr(10));

                     COMMIT;

                  EXCEPTION
                      WHEN TOO_MANY_ROWS THEN
                         gc_error_loc := 'Deleting imported summary journal due to too many gl batch ids';
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for too many gl batch ids.');
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Deleting imported summary journal due to too many gl batch ids.');

                         xx_gl_summary_del_proc(p_je_batch_id => ln_je_batch_id
                                               ,p_je_deleted  => ln_je_bat_deleted);

                         IF ln_je_bat_deleted > 0 THEN
                           gc_output_message := gc_output_message||'Imported Journal has been deleted.  See log file for more information.'||chr(10);
                         END IF;

                         -- Resetting INTERFACE_STATUS back to STAGED from IMPORTING
                         gc_error_loc := 'Updating/resetting interface_status back to STAGED due to too many gl batch ids';
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updating/resetting interface_status back to STAGED due to too many gl batch ids.');
                         UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                            SET XGHVJC.interface_status    = G_STAGED
                          WHERE XGHVJC.interface_status    = G_IMPORTING
                            AND XGHVJC.user_je_source_name = p_source
                            AND XGHVJC.set_of_books_id     = p_sob_id
                            AND XGHVJC.process_date        = ld_process_date
                            AND XGHVJC.period_name         = p_period_name
                            AND XGHVJC.hv_imp_req_id       = gn_this_request_id;

                         gc_error_loc := 'Commit status update to STAGED in control table - too many gl batch ids.';
                         COMMIT;

                         -- Raise exception and setting concurrent program status to ERROR due to too many GL batch ids
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated/reset interface status back to STAGED from IMPORTING in control table.');
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Setting concurrent program status to ERROR status due to too many gl batch ids.');
                         RAISE EX_VALIDATION_ERROR;
                  END;

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Step #4 - Insert Reference Info.   --');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
                  BEGIN
                     -- Reference information of summary records are deleted as they are not used for drill back purpose and would result in volume difference issue
                     gc_error_loc := 'Deleting Reference information of summary records';
                     DELETE gl_import_references GIR
                      WHERE GIR.je_header_id BETWEEN ln_min_je_header_id AND ln_max_je_header_id
                        AND GIR.reference_1 = ln_group_id;

                     ln_deleted_sum_refs := SQL%ROWCOUNT;

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Deleted '||ln_deleted_sum_refs|| ' summarized journal information from gl_import_references between '
                                            ||ln_min_je_header_id||' and '||ln_max_je_header_id||' for group_id '||ln_group_id);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Comparision of summary journal lines to deleted summary references.');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'       Number of summary journal Lines created and imported     : '||ln_inserted_sum_cnt);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'       Number of references deleted for imported summary journal: '||ln_deleted_sum_refs||chr(10));

                     gc_error_loc := 'Check if summary journal count and deleted summary journal references match';
                     IF ln_inserted_sum_cnt <> ln_deleted_sum_refs THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Number of deleted summary journal references does not match the number of summary journals created.');
                        gc_output_message := gc_output_message||'Number of deleted summary journal references does not match the number of summary journals created.'
                                                              ||'See log file for more information.'||chr(10);
                        ROLLBACK;  -- deletion of summary references
                        RAISE ex_validation_error;
                     END IF;
                     xx_print_time_stamp_to_logfile();

                     -- initialize variabes used for inserting references
                     ln_user_id       := FND_GLOBAL.USER_ID;
                     lc_profile_value := FND_PROFILE.value('GL_JI_ALWAYS_GROUP_BY_DATE');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  GL_JI_ALWAYS_GROUP_BY_DATE Profile Option Value: '||lc_profile_value||chr(10));

                     -- Insert Detailed Reference Info
                     gc_error_loc := 'Inserting Detailed Reference Information';
                     -- Version 2.4 Modified on 15-APR-2010 to remove ORDERED hint
                     -- Version 2.5 Modified on 09-JUN-2010 for adding additional hints
                     --             and changed order of FROM clause to obtain a better plan
                     INSERT /*+ PARALLEL(GIR,8) */ INTO gl_import_references PARTITION(GL_IMPORT_REFERENCES_OVRFL) GIR
                     SELECT /*+ FULL(XGIHVN) PARALLEL(XGIHVN,8) FULL(GJH) PARALLEL(GJH,8) */
                            GJH.je_batch_id
                           ,GJL.je_header_id
                           ,GJL.je_line_num
                           ,SYSDATE              last_update_date
                           ,ln_user_id           last_updated_by
                           ,SYSDATE              creation_date
                           ,ln_user_id           created_by
                           ,ln_user_id           last_update_login
                           ,XGIHVN.reference21
                           ,XGIHVN.reference22
                           ,XGIHVN.reference23
                           ,XGIHVN.reference24
                           ,XGIHVN.reference25
                           ,XGIHVN.reference26
                           ,XGIHVN.reference27
                           ,XGIHVN.reference28
                           ,XGIHVN.reference29
                           ,XGIHVN.reference30
                           ,XGIHVN.gl_sl_link_id
                           ,XGIHVN.gl_sl_link_table
                           ,XGIHVN.subledger_doc_sequence_id
                           ,XGIHVN.subledger_doc_sequence_value
                       FROM xxfin.xx_gl_high_volume_jrnl_control XGHVJC
								   ,xx_gl_interface_high_vol_na       XGIHVN
								   ,gl_je_headers                     GJH
								   ,gl_je_lines                       GJL
								   ,gl_je_sources_tl                  GJS
     							   ,gl_je_categories_tl               GJC
                       -- FROM gl_je_headers                  GJH
                       --     ,gl_je_lines                    GJL
                       --     ,xx_gl_interface_high_vol_na    XGIHVN
                       --     ,xx_gl_high_volume_jrnl_control XGHVJC
                       --     ,gl_je_categories               GJC
                       --     ,gl_je_sources                  GJS
                      WHERE XGHVJC.interface_status    = G_IMPORTING
                        AND XGHVJC.user_je_source_name = p_source
                        AND XGHVJC.set_of_books_id     = p_sob_id
                        AND XGHVJC.process_date        = ld_process_date
                        AND XGHVJC.period_name         = p_period_name
                        AND XGHVJC.hv_imp_req_id       = gn_this_request_id
                        AND XGHVJC.request_id          = XGIHVN.request_id
                        AND GJH.je_batch_id            = ln_je_batch_id
                        AND GJH.je_header_id           = GJL.je_header_id
                        AND GJS.user_je_source_name    = XGIHVN.user_je_source_name
                        AND GJC.user_je_category_name  = XGIHVN.user_je_category_name
                        AND GJH.je_source              = GJS.je_source_name
                        AND GJH.je_category            = GJC.je_category_name
                        AND ((lc_profile_value = 'Y'
                              AND GJH.default_effective_date = TRUNC(XGIHVN.accounting_date)
                              )
                              OR NVL(lc_profile_value,'N') = 'N'
                              )
                        AND GJH.currency_code          = XGIHVN.currency_code
                        AND GJL.code_combination_id    = XGIHVN.code_combination_id
                        AND DECODE(XGIHVN.entered_dr, NULL, 1, 0) = DECODE(GJL.entered_dr, NULL, 1, 0)
                        AND DECODE(XGIHVN.entered_cr, NULL, 1, 0) = DECODE(GJL.entered_cr, NULL, 1, 0);

                     gc_error_loc := 'Fetching the count of detailed reference information';
                     ln_inserted_ref_cnt := SQL%ROWCOUNT;

                  EXCEPTION
                     WHEN ex_validation_error THEN
                        -- Delete summary journal entry
                        gc_error_loc := 'Deleting imported summary journal due to failure during deletion of summary references';
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for error during deletion of summary refernences');
                        xx_gl_summary_del_proc(p_je_batch_id => ln_je_batch_id
                                              ,p_je_deleted  => ln_je_bat_deleted);
                        IF ln_je_bat_deleted > 0 THEN
                           gc_output_message := gc_output_message||'Imported Journal has been deleted.  See log file for more information.'||chr(10);
                        END IF;

                        -- Resetting INTERFACE_STATUS back to STAGED from IMPORTING
                        gc_error_loc := 'Updating/resetting interface_status back to STAGED due to failure of summary journals vs. deletion of summary references';
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updating/resetting interface_status back to STAGED due to failure of summary journals vs. deletion of summary references.');
                        UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                           SET XGHVJC.interface_status    = G_STAGED
                         WHERE XGHVJC.interface_status    = G_IMPORTING
                           AND XGHVJC.user_je_source_name = p_source
                           AND XGHVJC.set_of_books_id     = p_sob_id
                           AND XGHVJC.process_date        = ld_process_date
                           AND XGHVJC.period_name         = p_period_name
                           AND XGHVJC.hv_imp_req_id       = gn_this_request_id;

                        gc_error_loc := 'Commit status update to STAGED in control table - failed to delete summary references.';
                        COMMIT;

                        -- Raise exception and setting concurrent program status to ERROR due to failure during insert of references
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated/reset interface status back to STAGED from IMPORTING in control table');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Setting program status to error due to failure during deletion of detailed references');

                        RAISE ex_validation_error;  -- propagate to main block exception

                     WHEN OTHERS THEN
                        ROLLBACK;
                        -- Delete summary journal entry
                        gc_error_loc := 'Deleting imported summary journal due to failure during insert of detailed references';
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for error during insert of detailed refernences');
                        -- Version 2.4 Modified on 15-APR-2010 - Added SQLERRM to log file
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
                        xx_gl_summary_del_proc(p_je_batch_id => ln_je_batch_id
                                              ,p_je_deleted  => ln_je_bat_deleted);
                        IF ln_je_bat_deleted > 0 THEN
                           gc_output_message := gc_output_message||'Imported Journal has been deleted.  See log file for more information.'||chr(10);
                        END IF;

                        -- Resetting INTERFACE_STATUS back to STAGED from IMPORTING
                        gc_error_loc := 'Updating/resetting interface_status back to STAGED due to failure during insert of detailed references';
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updating/resetting interface_status back to STAGED due to failure during insert of detailed references');
                        UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                           SET XGHVJC.interface_status    = G_STAGED
                         WHERE XGHVJC.interface_status    = G_IMPORTING
                           AND XGHVJC.user_je_source_name = p_source
                           AND XGHVJC.set_of_books_id     = p_sob_id
                           AND XGHVJC.process_date        = ld_process_date
                           AND XGHVJC.period_name         = p_period_name
                           AND XGHVJC.hv_imp_req_id       = gn_this_request_id;

                        gc_error_loc := 'Commit status update to STAGED in control table - failed to insert detailed references.';
                        COMMIT;

                        -- Raise exception and setting concurrent program status to ERROR due to failure during insert of references
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated/reset interface status back to STAGED from IMPORTING in control table');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Setting program status to error due to failure during insert of detailed references');
                        RAISE ex_validation_error;

                  END;  -- Step 4 Insert Reference information

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  Comparision of records inserted into GL import reference table vs. control table');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'      Volume from XX_GL_HIGH_VOLUME_JRNL_CONTROL     : '||ln_cntrl_volume);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'      Volume inserted into GL_IMPORT_REFERENCES      : '||ln_inserted_ref_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'      Volume Difference (Control vs. References)     : '||(ln_cntrl_volume - ln_inserted_ref_cnt)||chr(10));

                  -- Validate volume information of detailed reference information and control table
                  IF (ln_inserted_ref_cnt = ln_cntrl_volume) THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Volume of inserted reference information matches the volume per the control table.');
                     xx_print_time_stamp_to_logfile();

                     gc_error_loc := 'Updating/resetting interface_status to INSERTED-REFERENCES STAGED in control table to indicate the completion of GL_IMPORT references have completed.';
                     UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                        SET XGHVJC.interface_status    = G_INSERTED_REFERENCES
                           ,XGHVJC.je_batch_id           = ln_je_batch_id
                      WHERE XGHVJC.interface_status    = G_IMPORTING
                        AND XGHVJC.user_je_source_name = p_source
                        AND XGHVJC.set_of_books_id     = p_sob_id
                        AND XGHVJC.process_date        = ld_process_date
                        AND XGHVJC.period_name         = p_period_name
                        AND XGHVJC.hv_imp_req_id       = gn_this_request_id;

                     gc_error_loc := 'Commit status update to INSERTED-REFERENCES after successfuly insert';
                     COMMIT;

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Step #5 - Delete Detailed Journals --');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
                     BEGIN
                        gc_error_loc := 'Deleting detailed journal lines from staging table during normal processing of STAGED records';
                        DELETE /*+ FULL(XGIHVN) PARALLEL(XGIHVN,8)*/ xx_gl_interface_high_vol_na XGIHVN
                         WHERE EXISTS (SELECT /*+ FULL(XGHVJC) PARALLEL(XGHVJC,8) */ 1
                                         FROM xx_gl_high_volume_jrnl_control  XGHVJC
                                        WHERE XGHVJC.interface_status    = G_INSERTED_REFERENCES
                                          AND XGHVJC.user_je_source_name = p_source
                                          AND XGHVJC.set_of_books_id     = p_sob_id
                                          AND XGHVJC.process_date        = ld_process_date
                                          AND XGHVJC.period_name         = p_period_name
                                          AND XGHVJC.request_id          = XGIHVN.request_id)
                           AND XGIHVN.user_je_source_name = p_source;
                        ln_stg_delete_cnt :=SQL%ROWCOUNT;

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Comparision of detailed records deleted from high volume interface table vs. control table');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'      Volume from XX_GL_HIGH_VOLUME_JRNL_CONTROL     : '||ln_cntrl_volume);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'      Volume deleted from XX_GL_INTERFACE_HIGH_VOL_NA: '||ln_stg_delete_cnt);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'      Volume Difference (Control vs. Staging)        : '||(ln_cntrl_volume - ln_stg_delete_cnt)||chr(10));

                        gc_error_loc := 'Verify volume deleted from XX_GL_INTERFACE_HIGH_VOL_NA for detailed journals.';
                        IF (ln_stg_delete_cnt = 0) THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Delete of detailed records from interface table was not successful.  Number of rows deleted '||ln_stg_delete_cnt);
                            gc_output_message := gc_output_message||'Delete of detailed records from interface table was not successful for imported journals. '
                                                                  ||'See log file for more information.'||chr(10);
                            ROLLBACK;
                            RAISE ex_validation_error;
                        ELSIF (ln_stg_delete_cnt <> ln_cntrl_volume) THEN
                            -- Raise exception and setting concurrent program status to ERROR due to detailed lines not deleted
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Delete of detailed records in staging table not successful. Number of rows deleted '||ln_stg_delete_cnt);
                            gc_output_message := gc_output_message||'Delete of detailed records from staging table was not successful for imported journals. '
                                                                  ||'See log file for more information.'||chr(10);
                            ROLLBACK;
                            RAISE ex_validation_error;
                        ELSE
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Volume of detailed records deleted from interface table matches the control table.');
                           xx_print_time_stamp_to_logfile();

                           FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Step #6 - Update cntrl to IMPORTED --');
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------------------------');
                           gc_error_loc := 'Updating journal_import_group_id, interface_status and journal batch id in control table';
                           UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                              SET XGHVJC.interface_status    = G_IMPORTED
                            WHERE XGHVJC.interface_status    = G_INSERTED_REFERENCES
                              AND XGHVJC.user_je_source_name = p_source
                              AND XGHVJC.set_of_books_id     = p_sob_id
                              AND XGHVJC.process_date        = ld_process_date
                              AND XGHVJC.period_name         = p_period_name
                              AND XGHVJC.hv_imp_req_id       = gn_this_request_id;

                           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated interface status to IMPORTED in control table');
                           xx_print_time_stamp_to_logfile();

                           gc_error_loc := 'Committing update for interface status to IMPORTED.';
                           COMMIT;

                        END IF;

                     EXCEPTION
                        WHEN ex_validation_error THEN
                             RAISE ex_validation_error;  -- propagate to main exception handling
                        WHEN OTHERS THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering Exception Handling for during deletion of detailed records');
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised while '||gc_error_loc);
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
                           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Delete of detailed records in staging table not successful.');
                           ROLLBACK;
                           RAISE ex_validation_error;    -- propagate to main exception handling
                     END;  -- Step 5 delete detailed journals

                  -- Volume of detailed reference information and control table do not match
                  ELSE
                     gc_output_message := gc_output_message||'Volume of inserted reference information does not match the volume per the control table. '
                                                           ||'See log file for more information.'||chr(10);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Volume of inserted reference information does not match the volume per the control table.');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ROLLBACK will be performed of inserted detailed references (gl_import_references)');
                     xx_print_time_stamp_to_logfile();

                     gc_error_loc := 'Rollback of inserted of detailed references since volume does not match.';
                     ROLLBACK;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  ROLLBACK Completed for insertion of detailed references');
                     xx_print_time_stamp_to_logfile();

                     gc_error_loc := 'Deleting imported summary journal due to ROLLBACK of insert of detailed references.';
                     xx_gl_summary_del_proc(p_je_batch_id => ln_je_batch_id
                                           ,p_je_deleted  => ln_je_bat_deleted);

                     gc_output_message := gc_output_message||'Imported Summary Journal was deleted and ROLLBACK Completed for insertion of detailed references. '
                                                           ||'See log file for more information.'||chr(10);

                     -- RESETTING INTERFACE_STATUS back to STAGED from IMPORTING
                     gc_error_loc := 'Updating/resetting interface_status back to STAGED in control table due to ROLLBACK of insert of detailed references';
                     UPDATE xx_gl_high_volume_jrnl_control XGHVJC
                        SET XGHVJC.interface_status    = G_STAGED
                      WHERE XGHVJC.interface_status    = G_IMPORTING
                        AND XGHVJC.user_je_source_name = p_source
                        AND XGHVJC.set_of_books_id     = p_sob_id
                        AND XGHVJC.process_date        = ld_process_date
                        AND XGHVJC.period_name         = p_period_name
                        AND XGHVJC.hv_imp_req_id       = gn_this_request_id;

                     gc_error_loc := 'Commit of update of interface status to STAGED due to rollback of insertion of detailed references';
                     COMMIT;

                     -- Raise exception and setting concurrent program status to ERROR due to insert of detailed reference failure
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Updated/reset interface status back to STAGED from IMPORTING in control table.');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'  Setting program status to ERROR due to ROLLBACK of insert of detailed references.');
                     RAISE ex_validation_error;
                  END IF; -- End of volume check of reference information
               END IF; -- End of check for successful journal import
            END IF; -- End of check if journal import was submitted
         --Else block if sum of entered and accounted CR/DR does not match
         ELSE
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Status    : NOT SUBMITTED');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Request ID: NONE'||chr(10));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Differences');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Entered DR  : '||(ln_cntrl_ent_dr - ln_stg_ent_dr));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Entered CR  : '||(ln_cntrl_ent_cr - ln_stg_ent_cr));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Accounted DR: '||(ln_cntrl_acc_dr - ln_stg_acc_dr));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     Accounted CR: '||(ln_cntrl_acc_cr - ln_stg_acc_cr)||chr(10));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Sum of entered and accounted CR/DR does not match for summarized journal. Setting program to ERROR.');

            gc_output_message := gc_output_message||'Processing was UNABLE to be performed for interfaces that have a STAGED status since entered '
                                                  ||'and accounted CR/DR does not match for summarized journal.'||chr(10);
            ROLLBACK;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Rollback of summary journal creation and control table update completed');
            RAISE ex_validation_error;

         END IF; -- End of comparing the total of entered and accounted CR/DR

         -- Begin Printing output section used for high volume journal import only
         gc_error_loc := 'Printing Output Section - Headings for Volume';
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10)||'Journal Created:'||chr(10));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  '
                                          ||RPAD('Group ID  ',25)
                                          ||RPAD('Journal Batch Name ',35)
                                          ||RPAD('Total Accounted DR ',21)
                                          ||RPAD('Total Accounted CR ',23)
                                          );
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('-',(12-1),'-') ||'   '
                                          ||RPAD('-',(45-1),'-')||'   '
                                          ||RPAD('-',(20-1),'-')||'   '
                                          ||RPAD('-',(20-1),'-')
                                          );

         gc_error_loc := 'Selecting Volume Information for Output Section';
         SELECT SUM(XGHVJC.accounted_dr)
               ,SUM(XGHVJC.accounted_cr)
           INTO ln_tot_jrnl_dr
               ,ln_tot_jrnl_cr
           FROM xx_gl_high_volume_jrnl_control XGHVJC
          WHERE XGHVJC.interface_status        = G_IMPORTED
            AND XGHVJC.user_je_source_name     = p_source
            AND XGHVJC.set_of_books_id         = p_sob_id
            AND XGHVJC.journal_import_group_id = ln_group_id
            AND XGHVJC.process_date            = ld_process_date
            AND XGHVJC.period_name             = p_period_name;

         gc_error_loc := 'Printing Output Section - Headings for Request Status';
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   '
                                          ||LPAD(ln_group_id,5,' ')
                                          ||LPAD(lc_batch_name,49,' ')
                                          ||LPAD(ln_tot_jrnl_dr,19,' ')
                                          ||LPAD(ln_tot_jrnl_cr,21,' ')
                                          ||chr(10));
         gc_output_message := gc_output_message||'See Journal Import Execution Report Request ID '||ln_jrnl_request_id
                                               ||' for more information about imported journal.'||chr(10);
         -- End printing of specific information for high volume journal import only

         gc_error_loc := 'Printing Output Section for Imported Interfaces';
         xx_gl_jrnl_print_output_body(p_group_id           => ln_group_id
                                     ,p_staging_request_id => NULL
                                     ,p_period_name        => p_period_name
                                     ,p_sob_id             => p_sob_id
                                     ,p_source             => p_source);
      EXCEPTION
         WHEN ex_validation_warning THEN
            xx_print_time_stamp_to_logfile();
            x_ret_code :=1;   -- Set concurrent program to WARNING status
            gc_error_loc := 'Printing Output Section for Imported Interfaces in ex_validation_warning exception';
            xx_gl_jrnl_print_output_body(p_group_id           => ln_group_id
                                        ,p_period_name        => p_period_name
                                        ,p_sob_id             => p_sob_id
                                        ,p_source             => p_source);
         WHEN ex_validation_error THEN
            xx_print_time_stamp_to_logfile();
            x_ret_code :=2;   -- Set concurrent program to ERROR status
            gc_error_loc := 'Printing Output Section for Imported Interfaces in ex_validation_error exception';
            xx_gl_jrnl_print_output_body(p_group_id           => ln_group_id
                                        ,p_period_name        => p_period_name
                                        ,p_sob_id             => p_sob_id
                                        ,p_source             => p_source);
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering When OTHERS Exception Handling during normal processing for STAGED interface status.');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised while '||gc_error_loc);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while '||gc_error_loc);
            x_ret_code:=2;    -- Set concurrent program to ERROR status
      END;
   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Entering When OTHERS Exception Handling for XX_GL_JRNL_SUM Procedure');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Exception raised while '||gc_error_loc);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while '||gc_error_loc);
         x_ret_code:=2;       -- Set concurrent program to ERROR status
   END XX_GL_JRNL_SUM;

END XX_GL_JRNL_SUMMARIZE_PKG;
/
SHOW ERR
