create or replace
PACKAGE BODY XX_AR_WC_UTILITY_PKG 
AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                        Office Depot Organization                          |
-- +===========================================================================+
-- | Name         : XX_AR_WC_UTILITY_PKG                                       |
-- |                                                                           |
-- | RICE#        : I2158                                                      |
-- |                                                                           |
-- | Description  : This package contains procedures to execute the            |
-- |                necessary pre-processing and post-processing steps         |
-- |                required for extracting/generating data for WebCollect     |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date         Author         Remarks                             |
-- |=========  ===========  =============  ====================================|
-- | Draft     15-DEC-2011  Rick Aldridge                                      |
-- |                                                                           |
-- |  1.1      16-JAN-2012  Akhilesh       Change in post_processor for defect |
-- |                                       #16273 (It's checking customers with|
-- |                                       conversion flag of N that have 0    |
-- |                                       data to convert)                    |
-- |                                                                           |
-- |  1.2      25-JAN-2012  R.Aldridge     Change validation of action type to |
-- |                                       include check for "C" or conversion |
-- |                                                                           |
-- |  1.3      27-JAN-2012  R.Aldridge     Add ar_pre_conversion procedure     |
-- |                                                                           |
-- |  1.4      04-FEB-2012  R.Aldridge     Defect 16768 - Create new utility   |
-- |                                       to remove special characters        |
-- |                                                                           |
-- |  1.5      24-FEB-2012  R.Aldridge     Defect 17210 - Change EXT_TYPE value|
-- |                                       for insert into XX_AR_WC_UPD_PS     |
-- |                                       applies to intial conversion        |
-- |                                                                           |
-- |  2.1      07-MAR-2012  R.Aldridge     Defect 17213 - Changes for          | 
-- |                                       customer_id difference              |
-- |                                       (override pmt sched customer id)    |
-- |                                                                           |
-- |  2.2      15-MAR-2012  R.Aldridge     Defect 17213 - Revert to 162388     | 
-- |                                                                           |
-- |  2.3      07-MAR-2012  R.Aldridge     Defect 17213 - Changes for          | 
-- |                                       customer_id difference              |
-- |                                       (override receipt customer id)      |
-- |                                                                           |
-- |  2.4      28-MAR-2012  R.Aldridge     Defect 17805 - Added new procedure  | 
-- |                                       copy_staged_recs to copy staged     |
-- |                                       trans to a temp table               |
-- |                                                                           |
-- |  2.5      12-APR-2012  R.Aldridge     Defect 18013 - Fix performance issue| 
-- |                                       with full daily UPD pre-process     |
-- |  2.6      07-JUN-2012  Jay Gupta      Defect 18936 - Fix performance issue|
-- |                                       with using index in hint            |
-- |                                                                           |
-- |  2.7      05-OCT-2012  D.Isbell       Defect 19343 - We no longer will    |
-- |                                       run the WC Diary notes extract.     |
-- |                                       We will make it look like the job   |
-- |                                       ran by setting diary_notes_ext      |
-- |                                       flag from 'N' to 'Y'.               |
-- |                                                                           |
-- |  2.8      06-NOV-2015  Vasu Raparla   Removed Schema References for R.12.2|
-- +===========================================================================+ 

   -- +====================================================================+
   -- | GLOBAL VARIABLES                                                   |
   -- +====================================================================+

   gn_req_id_delta               NUMBER(15);
   gn_req_id_full                NUMBER(15);

   gc_req_data                   VARCHAR2(240)   := NULL;
   gb_print_option               BOOLEAN         := FALSE;
   gc_error_loc                  VARCHAR2(2000)  := NULL;
   gn_request_id                 NUMBER          := fnd_global.conc_request_id;
   gn_user_id                    NUMBER          := fnd_profile.VALUE ('USER_ID');
   gd_creation_date              DATE            := SYSDATE;
   gn_created_by                 NUMBER          := NVL (fnd_profile.VALUE ('USER_ID'),-1);

   -- Global Constants
   GC_YES                       VARCHAR2(1)      := 'Y';

   -- Variables for Interface Settings
   gn_limit                      NUMBER;
   gn_threads_delta              NUMBER;
   gn_threads_full               NUMBER;
   gn_threads_file               NUMBER;
   gc_conc_short_delta           xx_fin_translatevalues.target_value16%TYPE;
   gc_conc_short_full            xx_fin_translatevalues.target_value17%TYPE;
   gc_conc_short_file            xx_fin_translatevalues.target_value18%TYPE;
   gc_delimiter                  xx_fin_translatevalues.target_value3%TYPE;
   gc_file_name                  xx_fin_translatevalues.target_value4%TYPE;
   gc_email                      xx_fin_translatevalues.target_value5%TYPE;
   gc_compute_stats              xx_fin_translatevalues.target_value6%TYPE;
   gn_line_size                  NUMBER;
   gc_file_path                  xx_fin_translatevalues.target_value8%TYPE;
   gn_num_records                NUMBER;
   gc_debug                      xx_fin_translatevalues.target_value10%TYPE;
   gc_ftp_file_path              xx_fin_translatevalues.target_value11%TYPE;
   gc_arch_file_path             xx_fin_translatevalues.target_value12%TYPE;
   gn_full_num_days              NUMBER;
   gc_staging_table              xx_fin_translatevalues.target_value19%TYPE;
   gb_retrieved_trans            BOOLEAN        := FALSE;
   gc_err_msg_trans              VARCHAR2(100)  := NULL;

   -- Variables for Cycle Date and Batch Cycle Settings
   gc_process_type               xx_ar_mt_wc_details.process_type%TYPE;
   gc_action_type                xx_ar_mt_wc_details.action_type%TYPE;
   gd_cycle_date                 xx_ar_wc_ext_control.cycle_date%TYPE;
   gn_batch_num                  xx_ar_wc_ext_control.batch_num%TYPE;
   gb_ready_to_execute           BOOLEAN       := FALSE;
   gb_reprocessing_required      BOOLEAN       := FALSE;
   gb_retrieved_cntl             BOOLEAN       := FALSE;
   gc_err_msg_cntl               VARCHAR2(100) := NULL;
   gc_post_process_status        VARCHAR(1)    := 'N';
   gd_delta_from_date            DATE;
   gd_full_from_date             DATE;
   gd_control_to_date            DATE;
   gc_reprocess_cnt              NUMBER;

   -- Custom Exceptions
   EX_NO_CONTROL_RECORD          EXCEPTION;
   EX_CYCLE_COMPLETED            EXCEPTION;
   EX_STAGING_COMPLETED          EXCEPTION;
   EX_INVALID_CYCLE_DATE         EXCEPTION;
   EX_POST_PROCESS_COMPLETE      EXCEPTION;
   EX_PRE_PROCESS_COMPLETED      EXCEPTION;
   EX_INVALID_BATCH_NUM          EXCEPTION;
   EX_INSERT_ERROR               EXCEPTION;
   EX_INVALID_STATUS             EXCEPTION;
   EX_ERROR_UPD_POST_PROCESS     EXCEPTION;
   EX_UNABLE_TO_SUBMIT_UPD       EXCEPTION;
   EX_PMT_UPD_ERROR              EXCEPTION;
   EX_INVALID_PROCESS_TYPE       EXCEPTION;
   EX_PRIOR_CYCLE_INCOMPLETE     EXCEPTION;

   -- +===================================================================+
   -- | FUNCTION   : REMOVE_SPECIAL_CHARACTERS                            |
   -- |                                                                   |
   -- | DESCRIPTION: Removes special characters from text string          |
   -- |                                                                   |
   -- | PARAMETERS : p_text_string     IN                                 |
   -- |                                                                   |
   -- |                                                                   |
   -- | RETURNS    : varchar2                                             |
   -- +===================================================================+
   FUNCTION remove_special_characters (p_text_string     IN   VARCHAR2)
   RETURN VARCHAR2
   IS
   BEGIN
      RETURN TRANSLATE(TRANSLATE(p_text_string,CHR (10),' '),CHR (13),' '); 
   END remove_special_characters;

   -- +===================================================================+
   -- | FUNCTION   : VALIDATE_PARAM_TRANS_VALUE                           |
   -- |                                                                   |
   -- | DESCRIPTION: Determines if paramter is not null, if so it is used |
   -- |              else translation value is used                       |
   -- |                                                                   |
   -- | PARAMETERS : p_conc_parameter     IN                              |
   -- |              p_trans_value        IN                              |
   -- |                                                                   |
   -- |                                                                   |
   -- | RETURNS    : p_trans_value                                        |
   -- +===================================================================+
   FUNCTION validate_param_trans_value (p_conc_parameter      IN   VARCHAR2
                                       ,p_trans_value         IN   VARCHAR2)
   RETURN VARCHAR2
   IS
   BEGIN
      IF p_conc_parameter IS NOT NULL THEN
         RETURN p_conc_parameter;
      ELSE
         RETURN p_trans_value;
      END IF;
   END validate_param_trans_value;

   -- +====================================================================+
   -- | Name       : PRINT_TIME_STAMP_TO_LOGFILE                           |
   -- |                                                                    |
   -- | Description: This private procedure is used to print the time to   |
   -- |              the log                                               |
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE print_time_stamp_to_logfile
   IS
   BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||'*** Current system time is '||
                            TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')||' ***'||chr(10));
   END print_time_stamp_to_logfile;

   -- +===================================================================+
   -- | PROCEDURE  : LOCATION_AND_LOG                                     |
   -- |                                                                   |
   -- | DESCRIPTION: Performs the following actions based on parameters   |
   -- |              1. Sets gc_error_location                            |
   -- |              2. Writes to log file if debug is on                 |
   -- |                                                                   |
   -- | PARAMETERS : p_debug, p_debug_msg                                 |
   -- |                                                                   |
   -- | RETURNS    : None                                                 |
   -- +===================================================================+
   PROCEDURE location_and_log (p_debug           IN  VARCHAR2
                              ,p_debug_msg       IN  VARCHAR2)
   IS
   BEGIN
      gc_error_loc := p_debug_msg;   -- set error location

      IF p_debug = 'Y' THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, gc_error_loc);
      END IF;

   END LOCATION_AND_LOG;

   -- +====================================================================+
   -- | Name       : COMPUTE_STAT                                          |
   -- |                                                                    |
   -- | Description: This procedure is used gather statistics              |
   -- |               to log file                                          |
   -- |                                                                    |
   -- | Parameters : p_compute_stats   IN                                  |
   -- |              p_ownname         IN                                  |
   -- |              p_tabname         IN                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE compute_stat (p_compute_stats   IN  VARCHAR2
                          ,p_ownname         IN  VARCHAR2
                          ,p_tabname         IN  VARCHAR2)
   IS
   BEGIN
      IF p_compute_stats = 'Y' THEN
         fnd_stats.gather_table_stats (ownname => p_ownname, tabname => p_tabname);
      END IF;
   END compute_stat;

   -- +====================================================================+
   -- | Name       : GET_INTERFACE_SETTINGS                                |
   -- |                                                                    |
   -- | Description: This procedure will retrieve all of the source values |
   -- |              from the XXOD_WEBCOLLECT_INTERFACE translation        |
   -- |              definition, and print them to the log file            |
   -- |                                                                    |
   -- | Parameters :                 p_process_type       IN               |
   -- |                              p_bulk_limit         OUT              |
   -- |                              p_delimiter          OUT              |
   -- |                              p_num_threads_delta  OUT              |
   -- |                              p_file_name          OUT              |
   -- |                              p_email              OUT              |
   -- |                              p_gather_stats       OUT              |
   -- |                              p_line_size          OUT              |
   -- |                              p_file_path          OUT              |
   -- |                              p_num_records        OUT              |
   -- |                              p_debug              OUT              |
   -- |                              p_ftp_file_path      OUT              |
   -- |                              p_arch_file_path     OUT              |
   -- |                              p_full_num_days      OUT              |
   -- |                              p_num_threads_full   OUT              |
   -- |                              p_num_threads_file   OUT              |
   -- |                              p_child_conc_delta   OUT              |
   -- |                              p_child_conc_full    OUT              |
   -- |                              p_child_conc_file    OUT              |
   -- |                              p_staging_table      OUT              |
   -- |                              p_retrieved          OUT              |
   -- |                              p_error_message      OUT              |
   -- |                                                                    |
   -- | Returns    :                 None                                  |
   -- |                                                                    |
   -- +====================================================================+
   PROCEDURE get_interface_settings (p_process_type       IN    VARCHAR2
                                    ,p_bulk_limit         OUT   NUMBER
                                    ,p_delimiter          OUT   VARCHAR2
                                    ,p_num_threads_delta  OUT   NUMBER
                                    ,p_file_name          OUT   VARCHAR2
                                    ,p_email              OUT   VARCHAR2
                                    ,p_gather_stats       OUT   VARCHAR2
                                    ,p_line_size          OUT   NUMBER
                                    ,p_file_path          OUT   VARCHAR2
                                    ,p_num_records        OUT   NUMBER
                                    ,p_debug              OUT   VARCHAR2
                                    ,p_ftp_file_path      OUT   VARCHAR2
                                    ,p_arch_file_path     OUT   VARCHAR2
                                    ,p_full_num_days      OUT   NUMBER
                                    ,p_num_threads_full   OUT   NUMBER
                                    ,p_num_threads_file   OUT   NUMBER
                                    ,p_child_conc_delta   OUT   VARCHAR2
                                    ,p_child_conc_full    OUT   VARCHAR2
                                    ,p_child_conc_file    OUT   VARCHAR2
                                    ,p_staging_table      OUT   VARCHAR2
                                    ,p_retrieved          OUT   BOOLEAN
                                    ,p_error_message      OUT   VARCHAR2
                                    ,p_print_to_req_log   IN    VARCHAR2 DEFAULT 'Y')
   IS
      -- Declaration of Local Variables
      ln_int_cnt NUMBER := 0;

      -- Cursor to retrieve interface settings
      CURSOR lcu_int_settings
      IS
         SELECT TO_NUMBER(XFTV.target_value1)    BULK_LIMIT
               ,XFTV.target_value2               DELIMITER
               ,TO_NUMBER(XFTV.target_value3)    NUM_THREADS_DELTA
               ,XFTV.target_value4               FILE_NAME
               ,XFTV.target_value5               EMAIL
               ,XFTV.target_value6               GATHER_STATS
               ,TO_NUMBER(XFTV.target_value7)    LINE_SIZE
               ,XFTV.target_value8               FILE_PATH
               ,TO_NUMBER(XFTV.target_value9)    NUM_RECORDS
               ,XFTV.target_value10              DEBUG_FLAG
               ,XFTV.target_value11              FTP_FILE_PATH
               ,XFTV.target_value12              ARCH_FILE_PATH
               ,TO_NUMBER(XFTV.target_value13)   FULL_NUM_DAYS
               ,TO_NUMBER(XFTV.target_value14)   NUM_THREADS_FULL
               ,TO_NUMBER(XFTV.target_value15)   NUM_THREADS_FILE
               ,XFTV.target_value16              CHILD_CONC_DELTA
               ,XFTV.target_value17              CHILD_CONC_FULL
               ,XFTV.target_value18              CHILD_CONC_FILE
               ,XFTV.target_value19              STAGING_TABLE
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = p_process_type
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';

         ltab_int_settings_rec lcu_int_settings%ROWTYPE;
   BEGIN
      --========================================================================
      -- Retreiving Translation Definition Values
      --========================================================================
      BEGIN
         location_and_log(p_debug,'    Retreiving Translation Definition Values');
         location_and_log(p_debug,'      Opening lcu_int_settings');
         OPEN lcu_int_settings;
         LOOP
            FETCH lcu_int_settings INTO ltab_int_settings_rec;
            EXIT WHEN lcu_int_settings%NOTFOUND;
            ln_int_cnt := ln_int_cnt + 1;
         END LOOP;
         CLOSE lcu_int_settings;
         location_and_log(p_debug,'     Closed lcu_int_settings');
      END;  -- Retreive Translation Definition Values

      --========================================================================
      -- Print Interface Settings to Log File
      --========================================================================
      BEGIN
         location_and_log(p_debug,'     Print Interface Settings to Log File');
         IF ln_int_cnt = 1 THEN
            p_bulk_limit        := ltab_int_settings_rec.bulk_limit;
            p_delimiter         := ltab_int_settings_rec.delimiter;
            p_num_threads_delta := ltab_int_settings_rec.num_threads_delta;
            p_file_name         := ltab_int_settings_rec.file_name;
            p_email             := ltab_int_settings_rec.email;
            p_gather_stats      := ltab_int_settings_rec.gather_stats;
            p_line_size         := ltab_int_settings_rec.line_size;
            p_file_path         := ltab_int_settings_rec.file_path;
            p_num_records       := ltab_int_settings_rec.num_records;
            p_debug             := ltab_int_settings_rec.debug_flag;
            p_ftp_file_path     := ltab_int_settings_rec.ftp_file_path;
            p_arch_file_path    := ltab_int_settings_rec.arch_file_path;
            p_full_num_days     := ltab_int_settings_rec.full_num_days;
            p_num_threads_full  := ltab_int_settings_rec.num_threads_full;
            p_num_threads_file  := ltab_int_settings_rec.num_threads_file;
            p_child_conc_delta  := ltab_int_settings_rec.child_conc_delta;
            p_child_conc_full   := ltab_int_settings_rec.child_conc_full;
            p_child_conc_file   := ltab_int_settings_rec.child_conc_file;
            p_staging_table     := ltab_int_settings_rec.staging_table;

            p_retrieved      := TRUE;
            p_error_message  := NULL;

            IF p_print_to_req_log = 'Y' THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG, '');
               FND_FILE.PUT_LINE (FND_FILE.LOG, '******************* INTERFACE SETTINGS FROM TRANS DEFINITION *******************');
               FND_FILE.PUT_LINE (FND_FILE.LOG, '');
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Number of Threads Delta: '||p_num_threads_delta);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Number of Threads Full : '||p_num_threads_full);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Number of Threads File : '||p_num_threads_file);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Short Name Delta       : '||p_child_conc_delta);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Short Name Full        : '||p_child_conc_full);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Short Name File        : '||p_child_conc_file);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Full Conversion Days   : '||p_full_num_days);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Gather Stats           : '||p_gather_stats);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Bulk Limit             : '||p_bulk_limit);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Debug Flag             : '||p_debug);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     File Name              : '||p_file_name);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Delimiter              : '||p_delimiter);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Line Size              : '||p_line_size);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Records per File       : '||p_num_records);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     File Path              : '||p_file_path);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     FTP File Path          : '||p_ftp_file_path);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Archive File Path      : '||p_arch_file_path);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '     Staging Table          : '||p_staging_table);
               FND_FILE.PUT_LINE (FND_FILE.LOG, '');
               FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
               FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            END IF;
         ELSE
            p_retrieved      := FALSE;
            p_error_message  := 'Interface (TARGET_VALUE) is not defined: '||p_process_type;
         END IF;

      END;  -- Print Interface Settings to Log File

   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at ' ||gc_error_loc||' .'||SQLERRM);
         p_retrieved       := FALSE;
         p_error_message   := 'WHEN OTHERS - Interface (TARGET_VALUE) could not be retrieved: '||p_process_type;
         print_time_stamp_to_logfile;

   END get_interface_settings;

   -- +====================================================================+
   -- | Name       : GET_CONTROL_INFO                                      |
   -- |                                                                    |
   -- | Description: This procedure will be used to retrieve certain values|
   -- |              from the control table.  All of the fields from the   |
   -- |              control table will be written to the log file except  |
   -- |              the WHO columns.  In addition, it will calculate/     |
   -- |              derive certain statuses and return the values.        |
   -- |                                                                    |
   -- | Parameters : p_cycle_date                IN                        |
   -- |              p_batch_num                 IN                        |
   -- |              p_process_type              IN                        |
   -- |              p_action_type               IN                        |
   -- |                                                                    |
   -- |              p_delta_from_date           OUT                       |
   -- |              p_full_from_date            OUT                       |
   -- |              p_control_to_date           OUT                       |
   -- |              p_post_process_status       OUT                       |
   -- |              p_ready_to_execute          OUT                       |
   -- |              p_reprocessing_required     OUT                       |
   -- |              p_reprocess_cnt             OUT                       |
   -- |              p_retrieved                 OUT                       |
   -- |              p_error_message             OUT                       |
   -- |                                                                    |
   -- | Returns    :  none                                                 |
   -- +====================================================================+
   PROCEDURE get_control_info (p_cycle_date               IN   DATE
                              ,p_batch_num                IN   NUMBER
                              ,p_process_type             IN   VARCHAR2
                              ,p_action_type              IN   VARCHAR2
                              ,p_delta_from_date          OUT  DATE
                              ,p_full_from_date           OUT  DATE
                              ,p_control_to_date          OUT  DATE
                              ,p_post_process_status      OUT  VARCHAR2
                              ,p_ready_to_execute         OUT  BOOLEAN
                              ,p_reprocessing_required    OUT  BOOLEAN
                              ,p_reprocess_cnt            OUT  NUMBER
                              ,p_retrieved                OUT  BOOLEAN
                              ,p_error_message            OUT  VARCHAR2)

   IS
      -- Declaration of Local Variables
      ln_control_cnt          NUMBER := 0;
      lc_reprocess_cnt        NUMBER := 0;

      -- Cursor for Selecting Conrol Information
      CURSOR lcu_control_info
      IS
         SELECT *
           FROM xx_ar_wc_ext_control
          WHERE cycle_date = p_cycle_date
            AND batch_num  = p_batch_num;

      ltab_control_info_rec lcu_control_info%ROWTYPE;

   BEGIN
      --========================================================================
      -- Retreive Control Record
      --========================================================================
      BEGIN
         location_and_log(gc_debug,'     Retreiving Control Record');
         location_and_log(gc_debug,'     Opening lcu_control_info');
         OPEN lcu_control_info;
         LOOP
            FETCH lcu_control_info INTO ltab_control_info_rec;
            EXIT WHEN lcu_control_info%NOTFOUND;
            ln_control_cnt := ln_control_cnt + 1;
         END LOOP;
         CLOSE lcu_control_info;
      END;  -- Retreiving Control Record

      --========================================================================
      -- Validate Control Record
      --========================================================================
      BEGIN
         location_and_log(gc_debug,'     Validate Control Record');
         location_and_log(gc_debug,'     Checking Control Record Count: '||ln_control_cnt);
         IF ln_control_cnt = 1 THEN

            p_retrieved            := TRUE;
            p_error_message        := NULL;
            p_post_process_status  := ltab_control_info_rec.post_process_status;

            location_and_log(gc_debug,'     Determine if child require reprocess');
            SELECT COUNT(1)
              INTO lc_reprocess_cnt
              FROM xx_ar_mt_wc_details
             WHERE cycle_date   = p_cycle_date
               AND batch_num    = p_batch_num
               AND process_type = p_process_type
               AND action_type  = p_action_type
               AND status      IN ('P','E');

            location_and_log(gc_debug,'     Checking Processing Count');
            IF lc_reprocess_cnt > 0 THEN
               p_reprocessing_required := TRUE;
            ELSE
               p_reprocessing_required := FALSE;
            END IF;

            location_and_log(gc_debug,'     Checking Action Type and Processing Type');
            location_and_log(gc_debug,'          Action Type     = '||p_action_type);
            location_and_log(gc_debug,'          Processing Type = '||p_process_type);

            IF (ltab_control_info_rec.post_process_status    = 'Y' AND 
               p_process_type <> 'AR_RECON')       THEN
               p_ready_to_execute      := FALSE;
               p_reprocessing_required := FALSE;

            -- Transactions - Full
            ELSIF (p_action_type IN ('F','C') AND p_process_type = 'AR_TRANS') THEN
               IF (ltab_control_info_rec.pmt_upd_full  = 'Y' AND
                  ltab_control_info_rec.trx_ext_full  <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Transactions - Delta
            ELSIF (p_action_type = 'I' AND p_process_type = 'AR_TRANS') THEN
               IF (ltab_control_info_rec.pmt_upd_delta  = 'Y' AND
                  ltab_control_info_rec.trx_ext_delta  <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Transactions - File
            ELSIF (p_action_type = 'G' AND p_process_type = 'AR_TRANS') THEN
               IF (ltab_control_info_rec.trx_ext_full = 'Y' AND
                  ltab_control_info_rec.trx_ext_delta = 'Y' AND
                  ltab_control_info_rec.trx_gen_file <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Receipts - Full
            ELSIF (p_action_type IN ('F','C') AND p_process_type = 'AR_CASH_RECEIPTS') THEN
               IF (ltab_control_info_rec.pmt_upd_full = 'Y' AND
                  ltab_control_info_rec.rec_ext_full <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Receipts - Delta
            ELSIF (p_action_type = 'I' AND p_process_type = 'AR_CASH_RECEIPTS') THEN
               IF (ltab_control_info_rec.pmt_upd_delta = 'Y' AND
                  ltab_control_info_rec.rec_ext_delta <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Receipts - File
            ELSIF (p_action_type = 'G' AND p_process_type = 'AR_CASH_RECEIPTS') THEN
               IF (ltab_control_info_rec.rec_ext_full = 'Y' AND
                  ltab_control_info_rec.rec_ext_delta = 'Y' AND
                  ltab_control_info_rec.rec_gen_file <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Adjustments - Full
            ELSIF (p_action_type IN ('F','C') AND p_process_type = 'AR_ADJUSTMENTS') THEN
               IF (ltab_control_info_rec.pmt_upd_full  = 'Y' AND
                   ltab_control_info_rec.trx_ext_full  = 'Y' AND
                   ltab_control_info_rec.adj_ext_full <> 'Y'    ) THEN
                   p_ready_to_execute := TRUE;
               ELSE
                   p_ready_to_execute := FALSE;
               END IF;

            -- Adjustments - Delta
            ELSIF (p_action_type = 'I' AND p_process_type = 'AR_ADJUSTMENTS') THEN
               IF (ltab_control_info_rec.pmt_upd_delta  = 'Y' AND
                  ltab_control_info_rec.adj_ext_delta  <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Adjustments - File
            ELSIF (p_action_type = 'G' AND p_process_type = 'AR_ADJUSTMENTS') THEN
               IF (ltab_control_info_rec.adj_ext_delta = 'Y' AND
                  ltab_control_info_rec.adj_ext_full   = 'Y' AND
                  ltab_control_info_rec.adj_gen_file  <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Payment Schedules - Full
            ELSIF (p_action_type IN ('F','C') AND p_process_type = 'AR_PAYMENT_SCHEDULE') THEN
               IF (ltab_control_info_rec.pmt_upd_full  = 'Y' AND
                  ltab_control_info_rec.trx_ext_full   = 'Y' AND
                  ltab_control_info_rec.rec_ext_full   = 'Y' AND
                  ltab_control_info_rec.pmt_ext_full  <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Payment Schedules - Delta
            ELSIF (p_action_type = 'I' AND p_process_type = 'AR_PAYMENT_SCHEDULE') THEN
               IF (ltab_control_info_rec.pmt_upd_delta  = 'Y' AND
                  ltab_control_info_rec.trx_ext_delta   = 'Y' AND
                  ltab_control_info_rec.rec_ext_delta   = 'Y' AND
                  ltab_control_info_rec.pmt_ext_delta  <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Payment Schedules - File
            ELSIF (p_action_type = 'G' AND p_process_type = 'AR_PAYMENT_SCHEDULE') THEN
               IF (ltab_control_info_rec.pmt_ext_full = 'Y' AND
                  ltab_control_info_rec.pmt_ext_delta = 'Y' AND
                  ltab_control_info_rec.pmt_gen_file <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Receivable Applications - Full
            ELSIF (p_action_type IN ('F','C') AND p_process_type = 'AR_RECEIVABLE_APP') THEN
               IF (ltab_control_info_rec.pmt_upd_full  = 'Y' AND
                  ltab_control_info_rec.trx_ext_full   = 'Y' AND
                  ltab_control_info_rec.rec_ext_full   = 'Y' AND
                  ltab_control_info_rec.app_ext_full  <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Receivable Applications - Delta
            ELSIF (p_action_type = 'I' AND p_process_type = 'AR_RECEIVABLE_APP') THEN
               IF (ltab_control_info_rec.pmt_upd_delta     = 'Y' AND
                  ltab_control_info_rec.trx_ext_delta      = 'Y' AND
                  ltab_control_info_rec.rec_ext_delta      = 'Y' AND
                  ltab_control_info_rec.app_ext_delta     <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
               END IF;

            -- Receivable Applications - File
            ELSIF (p_action_type = 'G' AND p_process_type = 'AR_RECEIVABLE_APP') THEN
               IF (ltab_control_info_rec.app_ext_delta = 'Y' AND
                  ltab_control_info_rec.app_ext_full   = 'Y' AND
                  ltab_control_info_rec.app_gen_file  <> 'Y'    ) THEN
                  p_ready_to_execute := TRUE;
               ELSE
                  p_ready_to_execute := FALSE;
              END IF;

            -- AR Pre-process
            ELSIF p_process_type = 'AR_PRE_PROCESS' THEN
               IF (ltab_control_info_rec.pmt_upd_full      = 'Y' AND
                  ltab_control_info_rec.pmt_upd_delta      = 'Y'    )  THEN
                  p_ready_to_execute      := FALSE;
                  p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
               ELSIF (ltab_control_info_rec.pmt_upd_full   = 'N' AND
                     ltab_control_info_rec.pmt_upd_delta   = 'N'    )
                   OR
                     (ltab_control_info_rec.pmt_upd_full   = 'Y' AND
                     ltab_control_info_rec.pmt_upd_delta   = 'N'    )
                   OR
                     (ltab_control_info_rec.pmt_upd_full      = 'N' AND
                      ltab_control_info_rec.pmt_upd_delta     = 'Y'    ) THEN
                   -- control already record exists, but PMT UPD not completed
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
               ELSE
                   -- control already record exists, but PMT UPD partially completed
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := TRUE;      -- Set manually since not multithreaded
               END IF;

            -- AR UPD PMT - Full(F) or Full Initial (C)
            ELSIF (p_action_type IN ('F','C') AND p_process_type = 'AR_UPD_PS_FULL') THEN
               IF ltab_control_info_rec.pmt_upd_full    = 'Y' THEN
                  p_ready_to_execute      := FALSE;
                  p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
               ELSIF ltab_control_info_rec.pmt_upd_full IN ('N','C') THEN
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
               ELSE
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := TRUE;      -- Set manually since not multithreaded
               END IF;

            -- AR UPD PMT - Delta
            ELSIF (p_action_type = 'I' AND p_process_type = 'AR_UPD_PS_DELTA') THEN
               IF ltab_control_info_rec.pmt_upd_delta    = 'Y' THEN
                  p_ready_to_execute      := FALSE;
                  p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
               ELSIF ltab_control_info_rec.pmt_upd_delta = 'N' THEN
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
               ELSE
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := TRUE;      -- Set manually since not multithreaded
               END IF;

            -- AR Pre-CONVERSION
            ELSIF p_process_type = 'AR_PRE_CONVERSION' THEN
               IF (ltab_control_info_rec.pmt_upd_full      = 'Y' AND
                  ltab_control_info_rec.pmt_upd_delta      = 'Y'    ) THEN
                  p_ready_to_execute      := FALSE;
                  p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
               ELSIF (ltab_control_info_rec.pmt_upd_full   = 'C' AND      -- C is for conversion
                     ltab_control_info_rec.pmt_upd_delta   = 'Y'    ) THEN
                   -- control already record exists, but PMT UPD FULL INITIAL not completed
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
               ELSE
                   -- control already record exists, but PMT UPD partially completed
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := TRUE;      -- Set manually since not multithreaded
               END IF;

            -- AR Post-processing
            ELSIF p_process_type = 'AR_POST_PROCESS' THEN
               IF (ltab_control_info_rec.pmt_upd_full     = 'Y' AND
                  ltab_control_info_rec.pmt_upd_delta     = 'Y' AND
                  ltab_control_info_rec.trx_ext_full      = 'Y' AND
                  ltab_control_info_rec.trx_ext_delta     = 'Y' AND
                  ltab_control_info_rec.trx_gen_file      = 'Y' AND
                  ltab_control_info_rec.rec_ext_full      = 'Y' AND
                  ltab_control_info_rec.rec_ext_delta     = 'Y' AND
                  ltab_control_info_rec.rec_gen_file      = 'Y' AND
                  ltab_control_info_rec.adj_ext_full      = 'Y' AND
                  ltab_control_info_rec.adj_ext_delta     = 'Y' AND
                  ltab_control_info_rec.adj_gen_file      = 'Y' AND
                  ltab_control_info_rec.pmt_ext_full      = 'Y' AND
                  ltab_control_info_rec.pmt_ext_delta     = 'Y' AND
                  ltab_control_info_rec.pmt_gen_file      = 'Y' AND
                  ltab_control_info_rec.app_ext_full      = 'Y' AND
                  ltab_control_info_rec.app_ext_delta     = 'Y' AND
                  ltab_control_info_rec.app_gen_file      = 'Y'    ) THEN

                  IF ltab_control_info_rec.post_process_status    = 'Y' THEN
                     p_ready_to_execute      := FALSE;
                     p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
                  ELSIF ltab_control_info_rec.post_process_status = 'N' THEN
                     p_ready_to_execute      := TRUE;
                     p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
                  ELSE
                     p_ready_to_execute      := TRUE;
                     p_reprocessing_required := TRUE;      -- Set manually since not multithreaded
                  END IF;
               ELSE
                  p_ready_to_execute      := FALSE;
                  p_reprocessing_required := FALSE;      -- Set manually since not multithreaded
               END IF;

            -- Diary Notes
            ELSIF p_process_type = 'DIARY_NOTES' THEN
               IF ltab_control_info_rec.diary_notes_ext = 'Y' THEN
                  p_ready_to_execute      := FALSE;
                  p_reprocessing_required := FALSE;
               ELSIF ltab_control_info_rec.diary_notes_ext = 'N' THEN
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := FALSE;
               ELSE
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := TRUE;
               END IF;

            -- Diary Notes INITIAL
            ELSIF p_process_type = 'DIARY_NOTES_CONV' THEN
               IF ltab_control_info_rec.diary_notes_ext = 'Y' THEN
                  p_ready_to_execute      := FALSE;
                  p_reprocessing_required := FALSE;
               ELSIF ltab_control_info_rec.diary_notes_ext = 'C' THEN
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := FALSE;
               ELSE
                  p_ready_to_execute      := TRUE;
                  p_reprocessing_required := TRUE;
               END IF;

            -- AR Reconciliation
            ELSIF p_process_type = 'AR_RECON'    THEN
               p_ready_to_execute      := TRUE;  -- AR Recon will always return TRUE, if control exists
               p_reprocessing_required := TRUE;
            ELSE
               p_ready_to_execute      := FALSE;
               p_reprocessing_required := FALSE;
            END IF;

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '************************** INTERFACE CONTROL RECORD ****************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Cycle Date           : '||p_cycle_date);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Batch Number         : '||p_batch_num);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Processing Type      : '||p_process_type);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Pre-Processing RID   : '||ltab_control_info_rec.pre_process_req_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Post-Processing RID  : '||ltab_control_info_rec.post_process_req_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Post-Process Status  : '||ltab_control_info_rec.post_process_status);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Delta From Date      : '||TO_CHAR(ltab_control_info_rec.delta_from_date,'DD-MON-YYYY HH24:MI:SS'));
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Full From Date       : '||TO_CHAR(ltab_control_info_rec.full_from_date,'DD-MON-YYYY HH24:MI:SS'));
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Control To Date      : '||TO_CHAR(ltab_control_info_rec.control_to_date,'DD-MON-YYYY HH24:MI:SS'));
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     PMT_UPD_FULL         : '||ltab_control_info_rec.pmt_upd_full);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     PMT_UPD_DELTA        : '||ltab_control_info_rec.pmt_upd_delta);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     TRX_EXT_FULL         : '||ltab_control_info_rec.trx_ext_full);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     TRX_EXT_DELTA        : '||ltab_control_info_rec.trx_ext_delta);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     TRX_GEN_FILE         : '||ltab_control_info_rec.trx_gen_file);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     REC_EXT_FULL         : '||ltab_control_info_rec.rec_ext_full);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     REC_EXT_DELTA        : '||ltab_control_info_rec.rec_ext_delta);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     REC_GEN_FILE         : '||ltab_control_info_rec.rec_gen_file);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     ADJ_EXT_FULL         : '||ltab_control_info_rec.adj_ext_full);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     ADJ_EXT_DELTA        : '||ltab_control_info_rec.adj_ext_delta);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     ADJ_GEN_FILE         : '||ltab_control_info_rec.adj_gen_file);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     PMT_EXT_FULL         : '||ltab_control_info_rec.pmt_ext_full);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     PMT_EXT_DELTA        : '||ltab_control_info_rec.pmt_ext_delta);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     PMT_GEN_FILE         : '||ltab_control_info_rec.pmt_gen_file);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     APP_EXT_FULL         : '||ltab_control_info_rec.app_ext_full);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     APP_EXT_DELTA        : '||ltab_control_info_rec.app_ext_delta);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     APP_GEN_FILE         : '||ltab_control_info_rec.app_gen_file);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Children to Reprocess: '||p_reprocess_cnt);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     DIARY_NOTES_EXT      : '||ltab_control_info_rec.diary_notes_ext);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     AR_RECON             : '||ltab_control_info_rec.ar_recon);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');

         ELSE
            p_retrieved             := FALSE;
            p_error_message         := 'Interface Record Not Found';

            IF p_process_type = 'AR_PRE_PROCESS' THEN
               p_ready_to_execute      := TRUE;    -- control record can be created
               p_reprocessing_required := FALSE;
               p_post_process_status   := 'N';
            ELSIF p_process_type = 'AR_PRE_CONVERSION' THEN
               p_ready_to_execute      := TRUE;    -- initial control record can be created
               p_reprocessing_required := FALSE;
               p_post_process_status   := 'N';
            ELSE
               p_ready_to_execute      := FALSE; 
               p_reprocessing_required := FALSE;
               p_post_process_status   := 'N';
            END IF;

         END IF;
      END;  -- Validate Control Record

      location_and_log(gc_debug,' Assigning Delta_From_Date, Full_From_Date and Control_to_date ');
      p_delta_from_date := ltab_control_info_rec.delta_from_date;
      p_full_from_date  := ltab_control_info_rec.full_from_date;
      p_control_to_date := ltab_control_info_rec.control_to_date;

      --========================================================================
      -- Print Ready for Execution and Reprocessing Status to Log
      --========================================================================
      BEGIN
         location_and_log(gc_debug,'     Print Ready for Execution and Reprocessing Status to Log');
         IF p_ready_to_execute THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Ready for Execution  : '||'TRUE');
         ELSE
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Ready for Execution  : '||'FALSE');
         END IF;

         IF p_reprocessing_required THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Reprocessing Required: '||'TRUE');
         ELSE
            FND_FILE.PUT_LINE (FND_FILE.LOG, '     Reprocessing Required: '||'FALSE');
         END IF;

         FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, '');
      END;  -- Print Ready for Execution and Reprocessing Status to Log

   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at ' ||gc_error_loc||' .'||SQLERRM);
         p_retrieved       := FALSE;
         p_error_message   := 'WHEN OTHERS - Encountered During Retrieval of Control Information';
         print_time_stamp_to_logfile;
   END get_control_info;

   -- +====================================================================+
   -- | Name       : ar_upd_ps_init                                        |
   -- |                                                                    |
   -- | Description: This procedure will initiate the capture of payment   |
   -- |              schedule records from ar_payment_schedules_all which  |
   -- |              is used to extract full/delta transactions and        |
   -- |              receipts using two separate procedures /              |
   -- |              concurrent requests                                   |
   -- |                                                                    |
   -- | Parameters :  p_cycle_date        IN                               |
   -- |               p_batch_num         IN                               |
   -- |               p_compute_stats     IN                               |
   -- |               p_debug             IN                               |
   -- |               p_process_type      IN                               |
   -- |                                                                    |
   -- |               p_upd_ps_submitted  OUT                              |
   -- |                                                                    |
   -- | Returns    :  none                                                 |
   -- +====================================================================+
   PROCEDURE ar_upd_ps_init (p_upd_ps_submitted  OUT  BOOLEAN
                            ,p_cycle_date        IN   VARCHAR2
                            ,p_batch_num         IN   NUMBER
                            ,p_debug             IN   VARCHAR2
                            ,p_process_type      IN   VARCHAR2)
   IS
      ln_conc_req_id         NUMBER;
      ln_idx                 NUMBER   := 1;
      ld_cycle_date          DATE;

      lc_dev_phase           VARCHAR2 (200);
      lc_dev_status          VARCHAR2 (200);
      lc_phase               VARCHAR2 (200);
      lc_status              VARCHAR2 (20);
      lc_message             VARCHAR2 (2000);

      ln_error_cnt           NUMBER  := 0;
      ln_warning_cnt         NUMBER  := 0;
      ln_normal_cnt          NUMBER  := 0;
   BEGIN
      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN
         location_and_log(GC_YES,'Initialize Processing.'||chr(10));
         ld_cycle_date := FND_DATE.CANONICAL_TO_DATE(p_cycle_date);
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Submit PMT UPD Programs for Full and Delta
      --========================================================================
      BEGIN
         location_and_log(GC_YES,'Submit PMT UPD Programs for Full and Delta.'||chr(10));
         ---------------------------------------------------------
         -- Submit Child Request - FULL
         ---------------------------------------------------------
         BEGIN
            location_and_log(p_debug,'     Submitting Full PMT UPD');

            location_and_log(p_debug,'     Set Print Options');
            gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer => NULL
                                                            ,copies  => 0);

            gn_req_id_full :=
                fnd_request.submit_request (application      => 'XXFIN'
                                           ,program          => 'XX_AR_UPD_PS_WC_F'
                                           ,description      => ''
                                           ,start_time       => ''
                                           ,sub_request      => TRUE
                                           ,argument1        => p_cycle_date
                                           ,argument2        => p_batch_num
                                           ,argument3        => 'N'
                                           ,argument4        => p_debug
                                           ,argument5        => 'AR_UPD_PS_FULL'
                                           ,argument6        => 'F');

            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID       : '||gn_req_id_full);

            location_and_log(p_debug,'     Updating control table to indicate FULL is in-progress '||gn_req_id_full);
            UPDATE xx_ar_wc_ext_control
               SET pmt_upd_full = 'P'           -- in-progess
             WHERE cycle_date   = ld_cycle_date
               AND batch_num    = p_batch_num;

         END;

         print_time_stamp_to_logfile;

         ---------------------------------------------------------
         -- Submit Child Request - DELTA
         ---------------------------------------------------------
         BEGIN
            location_and_log(GC_YES,'Submitting DELTA PMT UPD');


            location_and_log(p_debug,'     Set Print Options');
            gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer => NULL
                                                            ,copies  => 0);

            gn_req_id_delta :=
                fnd_request.submit_request (application      => 'XXFIN'
                                           ,program          => 'XX_AR_UPD_PS_WC_D'
                                           ,description      => ''
                                           ,start_time       => ''
                                           ,sub_request      => TRUE
                                           ,argument1        => p_cycle_date
                                           ,argument2        => p_batch_num
                                           ,argument3        => 'N'
                                           ,argument4        => p_debug
                                           ,argument5        => 'AR_UPD_PS_DELTA'
                                           ,argument6        => 'I');

            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID       : '||gn_req_id_delta);

            location_and_log(p_debug,'     Updating control table to indicate DELTA is in-progress '||gn_req_id_delta);
            UPDATE xx_ar_wc_ext_control
               SET pmt_upd_delta = 'P'           -- in-progess
             WHERE cycle_date    = ld_cycle_date
               AND batch_num     = p_batch_num;

         END;  -- Submit Child Request - DELTA

         location_and_log(p_debug,'     Issuing commit to submit requests');
         COMMIT;

         p_upd_ps_submitted := TRUE;

      END; -- Submit PMT UPD Programs for Full and Delta

      print_time_stamp_to_logfile;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND at: ' ||gc_error_loc||' .'||SQLERRM);
         p_upd_ps_submitted := FALSE;
         print_time_stamp_to_logfile;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at: ' ||gc_error_loc||' .'||SQLERRM);
         p_upd_ps_submitted := FALSE;
         print_time_stamp_to_logfile;

   END ar_upd_ps_init;

   -- +====================================================================+
   -- | Name       : ar_upd_ps                                             |
   -- |                                                                    |
   -- | Description: This procedure will fetch data from                   |
   -- |              ar_payment_schedules_all that were last updated based |
   -- |              on a date range, for the cycle date, from the control |
   -- |              table. This procedure is used for Full extracts which |
   -- |              required specific payment schedules                   |
   -- |                                                                    |
   -- | Parameters : p_cycle_date      IN                                  |
   -- |              p_batch_num       IN                                  |
   -- |              p_compute_stats   IN                                  |
   -- |              p_debug           IN                                  |
   -- |              p_process_type    IN                                  |
   -- |              p_action_type     IN                                  |
   -- |                                                                    |
   -- |              p_errbuf          OUT                                 |
   -- |              p_retcode         OUT                                 |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE ar_upd_ps (p_errbuf         OUT  VARCHAR2
                       ,p_retcode        OUT  NUMBER
                       ,p_cycle_date     IN   VARCHAR2
                       ,p_batch_num      IN   NUMBER
                       ,p_compute_stats  IN   VARCHAR2
                       ,p_debug          IN   VARCHAR2
                       ,p_process_type   IN   VARCHAR2
                       ,p_action_type    IN   VARCHAR2)
   IS
      ln_request_id      NUMBER             := fnd_global.conc_request_id;
      ln_batchlimit      NUMBER;
      ln_count           NUMBER;

      ln_insert_cnt      NUMBER :=0;
      ln_insert_tot      NUMBER :=0;

      --Variable declaration of Table type
      lt_upd_ps       upd_ps_tbl_type;

      -------------------------------------------------------
      -- Cursor for Full DAILY Conversion of New Customers 
      -------------------------------------------------------
      CURSOR lcu_upd_ps_full (p_cycledate_f        IN   DATE
                             ,p_batchnum_f         IN   NUMBER
                             ,p_full_from_date_f   IN   DATE
                             ,p_control_to_date_f  IN   DATE)
      IS
        -- V2.6 SELECT /*+ index(XCWC XX_CRM_WCELG_CUST_B1) use_nl(XCWC APS) */

          SELECT /*+ index(XCWC XX_CRM_WCELG_CUST_B1) index(APS AR_PAYMENT_SCHEDULES_N6) use_nl(XCWC APS) */
                payment_schedule_id
               ,status
               ,CLASS
               ,cust_trx_type_id
               ,customer_id
               ,customer_site_use_id
               ,customer_trx_id
               ,cash_receipt_id
               ,aps.last_update_date
               ,amount_due_original
               ,amount_due_remaining
               ,amount_applied
               ,amount_adjusted
               ,amount_in_dispute
               ,amount_credited
               ,cash_applied_amount_last
               ,cash_receipt_amount_last
               ,adjustment_amount_last
               ,gd_creation_date           CREATION_DATE
               ,gn_created_by              CREATED_BY
               ,ln_request_id              PMT_UPD_REQUEST_ID
               ,APS.creation_date          PMT_UPD_CREATION_DATE
               ,p_action_type              EXT_TYPE
               ,p_cycledate_f              CYCLE_DATE
               ,p_batchnum_f               BATCH_NUM
           FROM ar_payment_schedules_all APS
               ,xx_crm_wcelg_cust        XCWC
          WHERE APS.customer_id = XCWC.cust_account_id
            AND aps.last_update_date BETWEEN p_full_from_date_f
                                         AND p_control_to_date_f
            AND XCWC.ar_converted_flag  = 'N'
            AND XCWC.cust_mast_head_ext = 'Y';

      -------------------------------------------------------
      -- Cursor for INITIAL Conversion of New Customers 
      -------------------------------------------------------
      CURSOR lcu_upd_ps_full_conv (p_cycledate_f        IN   DATE
                                  ,p_batchnum_f         IN   NUMBER
                                  ,p_full_from_date_f   IN   DATE
                                  ,p_control_to_date_f  IN   DATE)
      IS
         SELECT /*+ FULL(APS) FULL(XCWC) PARALLEL(APS,4) */
                payment_schedule_id
               ,status
               ,CLASS
               ,cust_trx_type_id
               ,customer_id
               ,customer_site_use_id
               ,customer_trx_id
               ,cash_receipt_id
               ,aps.last_update_date
               ,amount_due_original
               ,amount_due_remaining
               ,amount_applied
               ,amount_adjusted
               ,amount_in_dispute
               ,amount_credited
               ,cash_applied_amount_last
               ,cash_receipt_amount_last
               ,adjustment_amount_last
               ,gd_creation_date           CREATION_DATE
               ,gn_created_by              CREATED_BY
               ,ln_request_id              PMT_UPD_REQUEST_ID
               ,APS.creation_date          PMT_UPD_CREATION_DATE
               ,'F'                        EXT_TYPE
               ,p_cycledate_f              CYCLE_DATE
               ,p_batchnum_f               BATCH_NUM
           FROM ar_payment_schedules_all APS
               ,xx_crm_wcelg_cust        XCWC
          WHERE APS.customer_id = XCWC.cust_account_id
            AND aps.last_update_date BETWEEN p_full_from_date_f
                                         AND p_control_to_date_f
            AND XCWC.ar_converted_flag  = 'N'
            AND XCWC.cust_mast_head_ext = 'Y';

      -------------------------------------------------------
      -- Cursor for DELTA
      -------------------------------------------------------
      CURSOR lcu_upd_ps_delta (p_cycledate_d        IN   DATE
                              ,p_batchnum_d         IN   NUMBER
                              ,p_delta_from_date_d  IN   DATE
                              ,p_control_to_date_d  IN   DATE)
      IS
         SELECT /*+ leading (APS) full(xcwc)*/
                payment_schedule_id
               ,status
               ,CLASS
               ,cust_trx_type_id
               ,customer_id
               ,customer_site_use_id
               ,customer_trx_id
               ,cash_receipt_id
               ,aps.last_update_date
               ,amount_due_original
               ,amount_due_remaining
               ,amount_applied
               ,amount_adjusted
               ,amount_in_dispute
               ,amount_credited
               ,cash_applied_amount_last
               ,cash_receipt_amount_last
               ,adjustment_amount_last
               ,gd_creation_date           CREATION_DATE
               ,gn_created_by              CREATED_BY
               ,ln_request_id              PMT_UPD_REQUEST_ID
               ,APS.creation_date          PMT_UPD_CREATION_DATE
               ,p_action_type              EXT_TYPE
               ,p_cycledate_d              CYCLE_DATE
               ,p_batchnum_d               BATCH_NUM
           FROM ar_payment_schedules_all APS
               ,xx_crm_wcelg_cust XCWC
          WHERE APS.customer_id = XCWC.cust_account_id
            AND aps.last_update_date BETWEEN p_delta_from_date_d
                                         AND p_control_to_date_d
            AND XCWC.ar_converted_flag = 'Y'
            AND XCWC.cust_mast_head_ext = 'Y'
            AND APS.creation_date   < XCWC.ar_conv_from_date_full
            AND p_control_to_date_d > XCWC.ar_conv_to_date_full;

   BEGIN
      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN
         location_and_log(GC_YES,'Initialize Processing.'||chr(10));

         gd_cycle_date   := fnd_date.canonical_to_date (p_cycle_date);
         gn_batch_num    := p_batch_num;
         gc_process_type := p_process_type;
         gc_action_type  := p_action_type;

         ------------------------------------------------
         -- Print Parameter Names and Values to Log File
         ------------------------------------------------
         FND_FILE.PUT_LINE (FND_FILE.LOG, '');
         FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date             : '|| gd_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch Number           : '|| gn_batch_num);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Gather Statistics      : '|| p_compute_stats);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : '|| p_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type           : '|| gc_process_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type            : '|| p_action_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID             : '|| ln_request_id);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, '');
      END;

      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      BEGIN
         location_and_log(GC_YES, 'Retrieving Interface Settings From Translation Definition'||chr(10));
         get_interface_settings (p_process_type      => gc_process_type
                                ,p_bulk_limit        => gn_limit
                                ,p_delimiter         => gc_delimiter
                                ,p_num_threads_delta => gn_threads_delta
                                ,p_file_name         => gc_file_name
                                ,p_email             => gc_email
                                ,p_gather_stats      => gc_compute_stats
                                ,p_line_size         => gn_line_size
                                ,p_file_path         => gc_file_path
                                ,p_num_records       => gn_num_records
                                ,p_debug             => gc_debug
                                ,p_ftp_file_path     => gc_ftp_file_path
                                ,p_arch_file_path    => gc_arch_file_path
                                ,p_full_num_days     => gn_full_num_days
                                ,p_num_threads_full  => gn_threads_full
                                ,p_num_threads_file  => gn_threads_file
                                ,p_child_conc_delta  => gc_conc_short_delta
                                ,p_child_conc_full   => gc_conc_short_full
                                ,p_child_conc_file   => gc_conc_short_file
                                ,p_staging_table     => gc_staging_table
                                ,p_retrieved         => gb_retrieved_trans
                                ,p_error_message     => gc_err_msg_trans);
      END;  -- Retrieve Interface Settings

      --========================================================================
      -- Retrieve Cycle Date Information from Control Table
      --========================================================================
      BEGIN
         location_and_log(GC_YES, 'Retrieve Cycle Date Information from Control Table'||chr(10));
         get_control_info (p_cycle_date            => gd_cycle_date
                          ,p_batch_num             => gn_batch_num
                          ,p_process_type          => gc_process_type
                          ,p_action_type           => p_action_type
                          ,p_delta_from_date       => gd_delta_from_date
                          ,p_full_from_date        => gd_full_from_date
                          ,p_control_to_date       => gd_control_to_date
                          ,p_post_process_status   => gc_post_process_status
                          ,p_ready_to_execute      => gb_ready_to_execute
                          ,p_reprocessing_required => gb_reprocessing_required
                          ,p_reprocess_cnt         => gc_reprocess_cnt
                          ,p_retrieved             => gb_retrieved_cntl
                          ,p_error_message         => gc_err_msg_cntl);
      END;  -- Retrieve Cycle Date Information from Control Table

      print_time_stamp_to_logfile;

      --========================================================================
      -- Override Debug and Gather Statistics with Parameter Values if NOT NULL
      --========================================================================
      BEGIN
         location_and_log(GC_YES, 'Determine if parameter value for debug/stats is used'||chr(10));
         gc_debug         := validate_param_trans_value(p_debug,gc_debug);
         gc_compute_stats := validate_param_trans_value(p_compute_stats,gc_compute_stats);
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Validate Control Information to Determine Processing Required
      --========================================================================
      BEGIN
         location_and_log(GC_YES, 'Evaluate Control Record Status.'||chr(10));
         IF NOT gb_retrieved_cntl THEN
            location_and_log(gc_debug, gc_error_loc||' - Control Record Not Retrieved');
            RAISE EX_NO_CONTROL_RECORD;

         ELSIF gc_post_process_status = 'Y' THEN
            location_and_log(gc_debug, gc_error_loc||' - Cycle Date and Batch Number Already Completed.');
            RAISE EX_CYCLE_COMPLETED;

         ELSIF gb_ready_to_execute = FALSE THEN
            location_and_log(gc_debug, gc_error_loc||' - Data has already been staged for this process.');
            RAISE EX_STAGING_COMPLETED;

         ELSIF gb_ready_to_execute = TRUE AND gc_action_type = 'F' THEN

            location_and_log(gc_debug, '     Start UPD PS - FULL DAILY');
            --========================================================================
            -- UPD PS - FULL DAILY
            --========================================================================
            BEGIN
               location_and_log(gc_debug, '     Opening cursor lcu_upd_ps_full');
               OPEN lcu_upd_ps_full (p_cycledate_f       => gd_cycle_date
                                    ,p_batchnum_f        => gn_batch_num
                                    ,p_full_from_date_f  => gd_full_from_date
                                    ,p_control_to_date_f => gd_control_to_date);
               LOOP
                  FETCH lcu_upd_ps_full
                  BULK COLLECT INTO lt_upd_ps LIMIT gn_limit;

                  FORALL i IN 1 .. lt_upd_ps.COUNT
                     INSERT INTO xx_ar_wc_upd_ps
                          VALUES lt_upd_ps (i);

                  IF lt_upd_ps.COUNT > 0 THEN
                     location_and_log(gc_debug,'     lt_upd_ps.COUNT = '||lt_upd_ps.COUNT);
                     ln_insert_cnt := SQL%ROWCOUNT;
                     ln_insert_tot := ln_insert_tot + ln_insert_cnt;
                  END IF;

                  location_and_log(gc_debug,'     FULL - Records Inserted into XX_AR_WC_UPD_PS for '||' : '||ln_insert_cnt);
                  location_and_log(gc_debug,'     FULL - Issue commit for inserting into UPD PS table');
                  COMMIT;

                  EXIT WHEN lcu_upd_ps_full%NOTFOUND;

               END LOOP;

               CLOSE lcu_upd_ps_full;
               location_and_log(gc_debug,'     Closed cursor lcu_upd_ps_full');

               location_and_log(GC_YES,'     Total Records Inserted into XX_AR_WC_UPD_PS: '||ln_insert_tot);

               location_and_log(gc_debug,'     FULL - Update control table status to Y');
               UPDATE xx_ar_wc_ext_control
                  SET pmt_upd_full = 'Y'           -- in-progess
                WHERE cycle_date   = gd_cycle_date
                  AND batch_num    = p_batch_num;

               location_and_log(p_debug,'     FULL - Issue commit for updating control table');
               COMMIT;

               print_time_stamp_to_logfile;

            END;  -- UPD PS FULL Daily

         ELSIF gb_ready_to_execute = TRUE AND gc_action_type = 'C' THEN

            location_and_log(gc_debug, '     Start UPD PS - FULL INITIAL');
            --========================================================================
            -- UPD PS - FULL INITIAL
            --========================================================================
            BEGIN
               -----------------------------------
               -- Insert pre-processing PMT table
               -----------------------------------
               location_and_log(gc_debug, '     Opening cursor lcu_upd_ps_full_conv');
               OPEN lcu_upd_ps_full_conv (p_cycledate_f       => gd_cycle_date
                                         ,p_batchnum_f        => gn_batch_num
                                         ,p_full_from_date_f  => gd_full_from_date
                                         ,p_control_to_date_f => gd_control_to_date);
               LOOP
                  FETCH lcu_upd_ps_full_conv
                  BULK COLLECT INTO lt_upd_ps LIMIT gn_limit;

                  FORALL i IN 1 .. lt_upd_ps.COUNT
                     INSERT INTO xx_ar_wc_upd_ps
                          VALUES lt_upd_ps (i);

                  IF lt_upd_ps.COUNT > 0 THEN
                     location_and_log(gc_debug,'     lt_upd_ps.COUNT = '||lt_upd_ps.COUNT);
                     ln_insert_cnt := SQL%ROWCOUNT;
                     ln_insert_tot := ln_insert_tot + ln_insert_cnt;
                  END IF;

                  location_and_log(gc_debug,'     FULL - Records Inserted into XX_AR_WC_UPD_PS for '||' : '||ln_insert_cnt);
                  location_and_log(gc_debug,'     FULL - Issue commit for inserting into UPD PS table');
                  COMMIT;

                  EXIT WHEN lcu_upd_ps_full_conv%NOTFOUND;

               END LOOP;

               CLOSE lcu_upd_ps_full_conv;
               location_and_log(gc_debug,'     Closed cursor lcu_upd_ps_full_conv');

               location_and_log(GC_YES,'     Total Records Inserted into XX_AR_WC_UPD_PS: '||ln_insert_tot);

               -----------------------------------
               -- Update control table
               -----------------------------------
               location_and_log(gc_debug,'     FULL - Update control table status to Y');
               UPDATE xx_ar_wc_ext_control
                  SET pmt_upd_full = 'Y'           -- in-progess
                WHERE cycle_date   = gd_cycle_date
                  AND batch_num    = p_batch_num;

               location_and_log(p_debug,'     FULL - Issue commit for updating control table');
               COMMIT;

               print_time_stamp_to_logfile;

            END;  -- UPD PS FULL INITIAL

         ELSIF gb_ready_to_execute = TRUE AND gc_action_type = 'I' THEN

            location_and_log(gc_debug, '     Start UPD PS - DELTA');
            --========================================================================
            -- UPD PS - DELTA
            --========================================================================
            BEGIN
               location_and_log(gc_debug, '     Opening cursor lcu_upd_ps_delta');
               OPEN lcu_upd_ps_delta (p_cycledate_d       => gd_cycle_date
                                     ,p_batchnum_d        => gn_batch_num
                                     ,p_delta_from_date_d => gd_delta_from_date
                                     ,p_control_to_date_d => gd_control_to_date);
               LOOP
                  location_and_log(gc_debug, '     Fetching from lcu_upd_ps_delta');
                  FETCH lcu_upd_ps_delta
                  BULK COLLECT INTO lt_upd_ps LIMIT gn_limit;

                  FORALL i IN 1 .. lt_upd_ps.COUNT
                     INSERT INTO XX_AR_WC_UPD_PS
                          VALUES lt_upd_ps (i);

                  IF lt_upd_ps.COUNT > 0 THEN
                  location_and_log(GC_YES,'     lt_upd_ps.COUNT = '||lt_upd_ps.COUNT);
                  ln_insert_cnt := SQL%ROWCOUNT;
                  ln_insert_tot := ln_insert_tot + ln_insert_cnt;
                  END IF;

                  location_and_log(gc_debug,'     Records Inserted into XX_AR_WC_UPD_PS for '||' : '||ln_insert_cnt);
                  location_and_log(gc_debug,'     DELTA - Issue commit for inserting into UPD PS table');
                  COMMIT;

                  EXIT WHEN lcu_upd_ps_delta%NOTFOUND;

               END LOOP;

               CLOSE lcu_upd_ps_delta;
               location_and_log(gc_debug,'     Closed ursor lcu_upd_ps_delta');

               location_and_log(GC_YES,'     Total Records Inserted into XX_AR_WC_UPD_PS: '||ln_insert_tot);

               location_and_log(gc_debug,'     DELTA - Update control table status to Y');
               UPDATE xx_ar_wc_ext_control
                  SET pmt_upd_delta = 'Y'           -- in-progess
                WHERE cycle_date   = gd_cycle_date
                  AND batch_num    = p_batch_num;

               location_and_log(gc_debug,'     DELTA - Issue commit for updating control table');
               COMMIT;

            END;  -- UPD PS DELTA

         ELSE
            location_and_log(gc_debug,'Invalid processing type or control record status.');
            RAISE EX_INVALID_STATUS;

         END IF;  -- end validation

      END;  -- Validate control information

      print_time_stamp_to_logfile;

      --========================================================================
      -- Gather Stats on PMT UPD Staging Table
      --========================================================================
      BEGIN
         location_and_log(GC_YES, 'Determine if gathering stats'||chr(10));
         IF gc_compute_stats = 'Y' THEN
            compute_stat (gc_compute_stats, 'XXFIN', gc_staging_table);
            location_and_log(GC_YES, '     Gather Stats completed');
         ELSE
            location_and_log(GC_YES, '     Gather Stats was not executed');
        END IF;
      END; -- Gather Stats on PMT UPD Staging Table

      print_time_stamp_to_logfile;

   EXCEPTION
      WHEN EX_NO_CONTROL_RECORD THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_NO_CONTROL_RECORD at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_CYCLE_COMPLETED THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_CYCLE_COMPLETED at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_STAGING_COMPLETED THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_STAGING_COMPLETED at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_STATUS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG,'EX_INVALID_STATUS at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND at ' ||gc_error_loc||' .'||SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at ' ||gc_error_loc||' .'||SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

   END ar_upd_ps;

   -- +====================================================================+
   -- | Name       : ar_pre_process                                        |
   -- |                                                                    |
   -- | Description: This procedure will perform the overall pre-processing|
   -- |              for the current cycle date.  It will validate the last|
   -- |              cycle date to ensure it completed before initializing |
   -- |              the pre-processing steps for the current cycle date.  |
   -- |              It also calls the procedure to capture certain payment|
   -- |              schedules records used for full/delta extracts for    |
   -- |              transactions and receipts.                            |
   -- |                                                                    |
   -- | Parameters :  p_cycle_date        IN                               |
   -- |               p_batch_num         IN                               |
   -- |               p_compute_stats     IN                               |
   -- |               p_debug             IN                               |
   -- |               p_process_type      IN                               |
   -- |                                                                    |
   -- |               p_errbuf            OUT                              |
   -- |               p_retcode           OUT                              |
   -- |                                                                    |
   -- | Returns    :  none                                                 |
   -- +====================================================================+
   PROCEDURE ar_pre_process (p_errbuf         OUT  VARCHAR2
                            ,p_retcode        OUT  NUMBER
                            ,p_cycle_date     IN   VARCHAR2
                            ,p_batch_num      IN   NUMBER
                            ,p_compute_stats  IN   VARCHAR2
                            ,p_debug          IN   VARCHAR2
                            ,p_process_type   IN   VARCHAR2)
   IS
      -- Used for tracking status of PMT UPD programs
      p_upd_ps_submitted            BOOLEAN := FALSE;

      -- Used for Verifying Prior Run and Calculating Date Ranges
      ld_control_date               xx_ar_wc_ext_control.control_to_date%TYPE;
      ld_full_from_date             xx_ar_wc_ext_control.full_from_date%TYPE;
      ld_delta_from_date            xx_ar_wc_ext_control.delta_from_date%TYPE;
      ld_last_delta_from_date       xx_ar_wc_ext_control.delta_from_date%TYPE;
      lc_last_cntl_request_id       xx_ar_wc_ext_control.request_id%TYPE;
      ld_last_cycle_date            xx_ar_wc_ext_control.cycle_date%TYPE;
      ln_last_batch_num             xx_ar_wc_ext_control.batch_num%TYPE;
      lc_last_post_process_status   xx_ar_wc_ext_control.post_process_status%TYPE;

      -- Used for determining the actions required after retrievin control record
      lb_new_control_record         BOOLEAN    := FALSE;
      lb_upd_pmt_reprocessing       BOOLEAN    := FALSE;

      ltab_child_requests           FND_CONCURRENT.REQUESTS_TAB_TYPE;
      ln_success_cnt                NUMBER := 0;
      ln_error_cnt                  NUMBER := 0;
      ln_child_cnt                  NUMBER := 0;

      lc_print_to_log               VARCHAR2(1) := 'Y';
      lc_process_type               fnd_concurrent_requests.argument5%TYPE;

   BEGIN

      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN
         gc_req_data     := FND_CONC_GLOBAL.REQUEST_DATA;
         IF gc_req_data IS NULL THEN
            location_and_log(GC_YES,'Initialize Processing.'||chr(10));
         ELSE
            location_and_log(GC_YES,'Initialize Processing for Restart.'||chr(10));
         END IF;

         gd_cycle_date   := FND_DATE.CANONICAL_TO_DATE (p_cycle_date);
         gn_batch_num    := p_batch_num;
         gc_process_type := p_process_type;

         ------------------------------------------------
         -- Print Parameter Names and Values to Log File
         ------------------------------------------------
         IF gc_req_data IS NULL THEN
            -- parameters are not printed on restart
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date             : ' || gd_cycle_date);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch Number           : ' || p_batch_num);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Gather Statistics      : ' || p_compute_stats);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || p_debug);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type           : ' || p_process_type);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID             : ' || gn_request_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
         END IF;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      BEGIN
         ---------------------------------------------
         -- Check Print Interface Settings to Log File
         ---------------------------------------------
         IF gc_req_data IS NOT NULL THEN
            lc_print_to_log := 'N';
         END IF;

         ---------------------------------------------
         -- Retrieve Interface Settings
         ---------------------------------------------
         location_and_log(GC_YES, 'Retrieving Interface Settings From Translation Definition'||chr(10));
         get_interface_settings (p_process_type      => p_process_type
                                ,p_bulk_limit        => gn_limit
                                ,p_delimiter         => gc_delimiter
                                ,p_num_threads_delta => gn_threads_delta
                                ,p_file_name         => gc_file_name
                                ,p_email             => gc_email
                                ,p_gather_stats      => gc_compute_stats
                                ,p_line_size         => gn_line_size
                                ,p_file_path         => gc_file_path
                                ,p_num_records       => gn_num_records
                                ,p_debug             => gc_debug
                                ,p_ftp_file_path     => gc_ftp_file_path
                                ,p_arch_file_path    => gc_arch_file_path
                                ,p_full_num_days     => gn_full_num_days
                                ,p_num_threads_full  => gn_threads_full
                                ,p_num_threads_file  => gn_threads_file
                                ,p_child_conc_delta  => gc_conc_short_delta
                                ,p_child_conc_full   => gc_conc_short_full
                                ,p_child_conc_file   => gc_conc_short_file
                                ,p_staging_table     => gc_staging_table
                                ,p_retrieved         => gb_retrieved_trans
                                ,p_error_message     => gc_err_msg_trans
                                ,p_print_to_req_log  => lc_print_to_log);
       END; -- Retrieve interface settings

      print_time_stamp_to_logfile;

      --========================================================================
      -- Override Debug and Gather Statistics with Parameter Values if NOT NULL
      --========================================================================
      BEGIN
         location_and_log(GC_YES, 'Determine if parameter value for debug/stats is used'||chr(10));
         gc_debug         := validate_param_trans_value(p_debug,gc_debug);
         gc_compute_stats := validate_param_trans_value(p_compute_stats,gc_compute_stats);

         FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** PARAMETER OVERRIDES *****************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || gc_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Gather Statistics      : ' || gc_compute_stats);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');

      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Checking Request Data to Determine if 1st Time or Restarting
      --========================================================================
      IF gc_req_data IS NULL THEN
         -- This is NOT a restart

         --========================================================================
         -- Retrieve Last Control Record
         --========================================================================
         BEGIN
            location_and_log(GC_YES, 'Retrieve Last Control Record'||chr(10));
            location_and_log(gc_debug, '     Fetch MAX RID from control table');
            SELECT MAX(request_id)
              INTO lc_last_cntl_request_id
              FROM xx_ar_wc_ext_control;

            location_and_log(gc_debug, '     Fetch information for MAX RID');
            SELECT cycle_date
                  ,batch_num
                  ,control_to_date
                  ,post_process_status
              INTO ld_last_cycle_date
                  ,ln_last_batch_num
                  ,ld_last_delta_from_date
                  ,lc_last_post_process_status
              FROM xx_ar_wc_ext_control
             WHERE request_id = lc_last_cntl_request_id;

            location_and_log(GC_YES, '     Last request ID         : '||lc_last_cntl_request_id);
            location_and_log(GC_YES, '     Last cycle date         : '||ld_last_cycle_date);
            location_and_log(GC_YES, '     Last batch number       : '||ln_last_batch_num);
            location_and_log(GC_YES, '     Last delta from date    : '||ld_last_delta_from_date);
            location_and_log(GC_YES, '     Last post process status: '||lc_last_post_process_status);

            print_time_stamp_to_logfile;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND at: ' ||gc_error_loc||' .'||SQLERRM);
               RAISE EX_NO_CONTROL_RECORD;

         END; -- retrieve last control record

         --========================================================================
         -- Validate Cycle Date and Batch Number Paramter Values
         --========================================================================
         BEGIN
            location_and_log(GC_YES, 'Validate Cycle Date and Batch Number Paramter Values'||chr(10));
            IF ld_last_cycle_date = gd_cycle_date THEN
               location_and_log(GC_YES, '     Compare batch num parameter to batch number of last cycle.');
               IF ln_last_batch_num = p_batch_num THEN
                  location_and_log(GC_YES, '     Control record already exists for parameter values.');

                  --==================================================================
                  -- Retrieve Cycle Date Information from Control Table
                  --==================================================================
                  location_and_log(GC_YES, '     Calling get_control_info to evaluate cycle date information');
                  get_control_info (p_cycle_date            => gd_cycle_date
                                   ,p_batch_num             => p_batch_num
                                   ,p_process_type          => p_process_type
                                   ,p_action_type           => NULL
                                   ,p_delta_from_date       => gd_delta_from_date
                                   ,p_full_from_date        => gd_full_from_date
                                   ,p_control_to_date       => gd_control_to_date
                                   ,p_post_process_status   => gc_post_process_status
                                   ,p_ready_to_execute      => gb_ready_to_execute
                                   ,p_reprocessing_required => gb_reprocessing_required
                                   ,p_reprocess_cnt         => gc_reprocess_cnt
                                   ,p_retrieved             => gb_retrieved_cntl
                                   ,p_error_message         => gc_err_msg_cntl);

                  print_time_stamp_to_logfile;

                  IF (gc_post_process_status   = 'Y') THEN
                     location_and_log(gc_debug, 'Post Process Status Flag shows already processed.');
                     RAISE EX_POST_PROCESS_COMPLETE;

                  ELSIF (gb_ready_to_execute      = FALSE AND
                         gb_reprocessing_required = FALSE    ) THEN
                     location_and_log(gc_debug, 'Processing completed for cycle date and batch number already completed');
                     RAISE EX_PRE_PROCESS_COMPLETED;

                  ELSIF (gb_ready_to_execute      = TRUE AND
                         gb_reprocessing_required = TRUE     )
                         OR
                        (gb_ready_to_execute      = TRUE  AND
                         gb_reprocessing_required = FALSE     )
                         THEN

                     location_and_log(gc_debug, '     PMT Schedule UPD initializing will be reprocessed');
                     lb_upd_pmt_reprocessing := TRUE;
                  END IF;

               ELSIF ln_last_batch_num > p_batch_num THEN
                  location_and_log(gc_debug, 'BATCH_NUM must be greater than last BATCH_NUM for same cycle date');
                  RAISE EX_INVALID_BATCH_NUM;

               ELSE
                  location_and_log(GC_YES, '     New control record required');
                  location_and_log(GC_YES, '     P_BATCH_NUM is greater than last BATCH_NUM for the same cycle_date');
                  lb_new_control_record := TRUE;
               END IF;  -- end batch number check

            ELSIF (ld_last_cycle_date > gd_cycle_date )
                 OR
                  (gd_cycle_date > TRUNC(SYSDATE))  THEN

               location_and_log(GC_YES, '     P_CYCLE_DATE is an invalid date');
               location_and_log(GC_YES, '          Last Cycle Date is :'||ld_last_cycle_date);
               location_and_log(GC_YES, '          P_CYCLE_DATE is    :'||gd_cycle_date);
               location_and_log(GC_YES, '     Cycle Date should be greater than or equal to last control record');
               RAISE EX_INVALID_CYCLE_DATE;

            ELSIF ld_last_cycle_date < gd_cycle_date THEN
               IF lc_last_post_process_status <> 'Y' THEN
                  location_and_log(GC_YES, '     Previous Cycle is Incomplete.  See '||ld_last_cycle_date);
                  RAISE EX_PRIOR_CYCLE_INCOMPLETE;
               ELSE
                  location_and_log(GC_YES, '     New control record required');
                  location_and_log(GC_YES, '     Cycle_date < P_CYCLE_DATE which means this is a new run');
                  lb_new_control_record := TRUE;
               END IF;
            ELSE
               location_and_log(GC_YES, '     Unable to evaluate control information');
               RAISE EX_INVALID_CYCLE_DATE;
            END IF;   -- end date check

         END;  -- Validate Cycle Date and Batch Number Paramter Values

         print_time_stamp_to_logfile;

         --========================================================================
         -- Determine if New Control Record Required
         --========================================================================
         BEGIN
            location_and_log(GC_YES, 'Determine if New Control Record Required'||chr(10));
            IF lb_new_control_record THEN
               -----------------------------------
               -- Calculate Date Ranges
               -----------------------------------
               --The three dates calculated below will be for all 5 AR Webcollect outbounds

               location_and_log(gc_debug, '     Retrieve Control TO Date');
               SELECT SYSDATE
                 INTO ld_control_date
                 FROM DUAL;

               location_and_log(gc_debug, '     Set Delta FROM Date - Delta FROM Date is the TO Date for the last cycle in control table');
               ld_delta_from_date := ld_last_delta_from_date;

               location_and_log(gc_debug, '     Set Full FROM Date. Full FROM Date is the control TO Date minus number of days to convert');
               ld_full_from_date := ld_control_date - gn_full_num_days;

               -----------------------------------
               -- Insert New Control Record
               -----------------------------------
               print_time_stamp_to_logfile;
               location_and_log(GC_YES, '     Insert New Control Record');
               BEGIN
                  INSERT INTO xx_ar_wc_ext_control
                       VALUES (gd_cycle_date        -- CYCLE_DATE
                              ,p_batch_num         -- BATCH_NUM
                              ,gn_request_id       -- PRE_PROCESS_REQ_ID
                              ,gn_request_id       -- POST_PROCESS_REQ_ID
                              ,'N'                 -- POST_PROCESS_STATUS
                              ,ld_delta_from_date  -- DELTA_FROM_DATE
                              ,ld_full_from_date   -- FULL_FROM_DATE
                              ,ld_control_date     -- CONTROL_TO_DATE
                              ,'N'                 -- PMT_UPD_FULL
                              ,'N'                 -- PMT_UPD_DELTA
                              ,'N'                 -- TRX_EXT_FULL
                              ,'N'                 -- TRX_EXT_DELTA
                              ,'N'                 -- TRX_GEN_FILE
                              ,'N'                 -- REC_EXT_FULL
                              ,'N'                 -- REC_EXT_DELTA
                              ,'N'                 -- REC_GEN_FILE
                              ,'N'                 -- ADJ_EXT_FULL
                              ,'N'                 -- ADJ_EXT_DELTA
                              ,'N'                 -- ADJ_GEN_FILE
                              ,'N'                 -- PMT_EXT_FULL
                              ,'N'                 -- PMT_EXT_DELTA
                              ,'N'                 -- PMT_GEN_FILE
                              ,'N'                 -- APP_EXT_FULL
                              ,'N'                 -- APP_EXT_DELTA
                              ,'N'                 -- APP_GEN_FILE
                              ,'Y'                 -- DIARY_NOTES_EXT --defect 19343 from N to Y
                              ,'N'                 -- AR_RECON
                              ,SYSDATE             -- CREATION_DATE
                              ,gn_user_id          -- CREATED_BY
                              ,SYSDATE             -- LAST_UPDATE_DATE
                              ,gn_user_id          -- LAST_UPATED_BY
                              ,gn_request_id       -- REQUEST_ID
                             );

                  location_and_log(gc_debug,'     Issue commit for inserting control record');
                  COMMIT;

                  location_and_log(GC_YES, '     Successfully Inserted Control Table');

                  print_time_stamp_to_logfile;

               EXCEPTION
                  WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at: ' ||gc_error_loc||' .'||SQLERRM);
                     RAISE EX_INSERT_ERROR;

               END;  -- insert into control table

               print_time_stamp_to_logfile;

               -----------------------------------
               -- Truncate Staging Tables
               -----------------------------------
               location_and_log(GC_YES, '     Truncating Staging Tables');
               BEGIN
                  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_ADJ_WC_STG';
                  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_CR_WC_STG';
                  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_PS_WC_STG';
                  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_RECAPPL_WC_STG';
                  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_TRANS_WC_STG';

                  location_and_log(GC_YES, '     Completed Truncating 5 Staging Tables');

                  print_time_stamp_to_logfile;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND at: ' ||gc_error_loc||' .'||SQLERRM);
                     print_time_stamp_to_logfile;
                     p_retcode := 2;

                  WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at: ' ||gc_error_loc||' .'||SQLERRM);
                     print_time_stamp_to_logfile;
                     p_retcode := 2;
               END;  -- end truncate staging tables

            END IF; -- end new control record check

         END;  -- New Control Record Required

         print_time_stamp_to_logfile;

         --========================================================================
         -- Truncate PMT Schedules Last Update Pre-processing Table
         --========================================================================
         BEGIN
            location_and_log(GC_YES, 'Checking if Truncating PMT UPD Staging Table'||chr(10));
            IF lb_upd_pmt_reprocessing OR lb_new_control_record THEN
               location_and_log('N', '     Before truncate');
               EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_WC_UPD_PS';
               location_and_log(GC_YES, '     Completed Truncating PMT UPD Staging Table');
            END IF;
         END; -- end PMT UPD update

         print_time_stamp_to_logfile;

         --========================================================================
         -- Call AR_UPD_PS_INIT to Submit DELTA and FULL concurrent program
         --========================================================================
         BEGIN
            location_and_log(GC_YES, 'Checking if calling AR_UPD_PS_INIT to submit both programs'||chr(10));
            IF lb_upd_pmt_reprocessing OR lb_new_control_record THEN
               location_and_log(GC_YES, 'Call AR_UPD_PS_INIT to Submit DELTA and FULL concurrent program');
               AR_UPD_PS_INIT (p_upd_ps_submitted => p_upd_ps_submitted
                              ,p_cycle_date       => p_cycle_date
                              ,p_batch_num        => p_batch_num
                              ,p_debug            => gc_debug
                              ,p_process_type     => p_process_type);

               IF p_upd_ps_submitted THEN
                  location_and_log(GC_YES, '     PMT Schedules Last Update for DELTA and FULL successfully submitted.');
                  p_retcode := 0;
               ELSE
                  location_and_log(GC_YES, '     PMT Schedules Last Update for DELTA and FULL were not successfully submitted.');
                  RAISE EX_UNABLE_TO_SUBMIT_UPD;
               END IF;

               location_and_log(gc_debug,'     End of calling AR_UPD_PS_INIT');
            END IF;

            location_and_log(GC_YES, '     Pausing AR_PRE_PROCESS......'||chr(10));
            FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  => 'PAUSED',
                                            request_data => 'PMT_UPD');

         END;  -- end of call to AR_UPD_PS_INIT

         print_time_stamp_to_logfile;

      ELSE
         location_and_log(GC_YES, '     Restarting after PMT_UPD Completed');
         location_and_log(gc_debug,'     Checking Child Requests');
         --========================================================================
         -- Post-Processing for Child Requests (INCREMENTAL and FULL)
         --========================================================================
         BEGIN
            location_and_log(GC_YES,'Post-processing for Child Requests.'||chr(10));

            ltab_child_requests := FND_CONCURRENT.GET_SUB_REQUESTS(gn_request_id);

            location_and_log(GC_YES,'     Checking Child Requests');
            IF ltab_child_requests.count > 0 THEN
               FOR i IN ltab_child_requests.FIRST .. ltab_child_requests.LAST
               LOOP

                  ln_child_cnt := ln_child_cnt + 1;  -- tracks children...should only be 2
                  location_and_log(GC_YES,CHR (10)||'     ltab_child_requests(i).request_id :'||ltab_child_requests(i).request_id);
                  location_and_log(GC_YES,          '     ltab_child_requests(i).dev_phase  :'||ltab_child_requests(i).dev_phase);
                  location_and_log(GC_YES,          '     ltab_child_requests(i).dev_status :'||ltab_child_requests(i).dev_status);

                  -----------------------------------
                  -- Determine Process Type
                  -----------------------------------
                  location_and_log(gc_debug,'     Determine Process Type.');
                  SELECT argument5
                    INTO lc_process_type
                    FROM fnd_concurrent_requests
                   WHERE request_id = ltab_child_requests(i).request_id;

                  ------------------------------------------------
                  -- Update Control Table based on Type and Status
                  ------------------------------------------------
                  location_and_log(gc_debug,'     Update control table based on process type and RID status.');
                  IF lc_process_type = 'AR_UPD_PS_FULL'
                  THEN
                     location_and_log(gc_debug,'     Process Type: '||lc_process_type);
                     location_and_log(gc_debug,'     FULL - Request ID');
                     IF ltab_child_requests(i).dev_phase  = 'COMPLETE' AND
                        ltab_child_requests(i).dev_status IN ('NORMAL','WARNING')
                     THEN
                        location_and_log(gc_debug,'     FULL - Update pmt_upd_full to Y');
                        ln_success_cnt := ln_success_cnt + 1;
                        UPDATE xx_ar_wc_ext_control
                           SET pmt_upd_full = 'Y'
                         WHERE cycle_date   = gd_cycle_date
                           AND batch_num    = p_batch_num;

                     ELSE
                        location_and_log(gc_debug,'     FULL - Update pmt_upd_full to E');
                        ln_error_cnt := ln_error_cnt + 1;
                        UPDATE xx_ar_wc_ext_control
                           SET pmt_upd_full = 'E'
                         WHERE cycle_date   = gd_cycle_date
                           AND batch_num    = p_batch_num;
                     END IF;

                  ELSIF lc_process_type = 'AR_UPD_PS_DELTA'
                  THEN
                     location_and_log(gc_debug,'     Process Type: '||lc_process_type);
                     location_and_log(gc_debug,'     DELTA - Request ID');
                     IF ltab_child_requests(i).dev_phase  = 'COMPLETE' AND
                        ltab_child_requests(i).dev_status IN ('NORMAL','WARNING')
                     THEN
                        location_and_log(gc_debug,'     DELTA - Update pmt_upd_full to Y');
                        ln_success_cnt := ln_success_cnt + 1;
                        UPDATE xx_ar_wc_ext_control
                           SET pmt_upd_delta = 'Y'
                         WHERE cycle_date    = gd_cycle_date
                           AND batch_num     = p_batch_num;

                     ELSE
                        location_and_log(gc_debug,'     DELTA - Update pmt_upd_full to E');
                        ln_error_cnt := ln_error_cnt + 1;
                        UPDATE xx_ar_wc_ext_control
                           SET pmt_upd_delta = 'E'
                         WHERE cycle_date    = gd_cycle_date
                           AND batch_num     = p_batch_num;
                     END IF;
                  ELSE
                     RAISE EX_INVALID_PROCESS_TYPE;
                  END IF;

               END LOOP; -- sub requests

            END IF; -- retrieve child requests

            location_and_log(GC_YES, '     ln_error_cnt  : '||ln_error_cnt);
            location_and_log(GC_YES, '     ln_success_cnt: '||ln_success_cnt);

            IF ln_error_cnt <> 0 THEN
               RAISE EX_PMT_UPD_ERROR;
            ELSE
               --========================================================================
               -- Gather Stats on Staging Table
               --========================================================================
               location_and_log(GC_YES, '     Determine if gathering stats: '||gc_compute_stats);

               IF gc_compute_stats = 'Y' THEN
                  compute_stat (gc_compute_stats, 'XXFIN', gc_staging_table);
                  location_and_log(GC_YES, '     Gather Stats completed');
               ELSE
                  location_and_log(GC_YES, 'Gather Stats was not exeucted');
               END IF;

            END IF;  -- Check for Error count

         END;  -- Post-Processing for Child Requests

      END IF;  -- request_data check

   EXCEPTION
      WHEN EX_INSERT_ERROR THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_INSERT_ERROR at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_NO_CONTROL_RECORD THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_NO_CONTROL_RECORD at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_CYCLE_DATE THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_INVALID_CYCLE_DATE at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_POST_PROCESS_COMPLETE THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_INVALID_CYCLE_DATE at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_PRE_PROCESS_COMPLETED THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_PRE_PROCESS_COMPLETED at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_BATCH_NUM THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_INVALID_BATCH_NUM at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_UNABLE_TO_SUBMIT_UPD THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_UNABLE_TO_SUBMIT_UPD at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_PROCESS_TYPE THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_INVALID_PROCESS_TYPE at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_PMT_UPD_ERROR THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_PMT_UPD_ERROR at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_PRIOR_CYCLE_INCOMPLETE THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_PRIOR_CYCLE_INCOMPLETE at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND at ' ||gc_error_loc||' .'||SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at ' ||gc_error_loc||' .'||SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

   END ar_pre_process;

   -- +====================================================================+
   -- | Name       : ar_post_process                                       |
   -- |                                                                    |
   -- | Description: This procedure will perform the post-processing       |
   -- |              required a given cycle date.  It will validate that   |
   -- |              all of the extracts and files have been generated for |
   -- |              the current cycle date                                |
   -- |                                                                    |
   -- | Parameters : p_cycle_date      IN                                  |
   -- |              p_batch_num       IN                                  |
   -- |              p_compute_stats   IN                                  |
   -- |              p_debug           IN                                  |
   -- |              p_process_type    IN                                  |
   -- |              p_action_type     IN                                  |
   -- |                                                                    |
   -- |              p_errbuf          OUT                                 |
   -- |              p_retcode         OUT                                 |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE ar_post_process (p_errbuf         OUT  VARCHAR2
                             ,p_retcode        OUT  NUMBER
                             ,p_cycle_date     IN   VARCHAR2
                             ,p_batch_num      IN   NUMBER
                             ,p_compute_stats  IN   VARCHAR2
                             ,p_debug          IN   VARCHAR2
                             ,p_process_type   IN   VARCHAR2)
   IS
      -- Cursor to select newly converted TRX/REC and pre-conversion TRX/REC
      CURSOR lcu_conv IS
         (SELECT DISTINCT XATWS.customer_trx_id "ID", 'TRX', gd_cycle_date, p_batch_num
            FROM xx_ar_trans_wc_stg          XATWS
           WHERE XATWS.ext_type = 'F'
             AND NOT EXISTS (SELECT 1
                               FROM xx_ar_wc_converted_rec_trx  XAWCRT
                              WHERE XAWCRT.id   = XATWS.customer_trx_id
                                AND XAWCRT.type = 'TRX')
          UNION
          SELECT DISTINCT XATWS.customer_trx_id "ID", 'TRX', gd_cycle_date, p_batch_num
            FROM xx_ar_trans_wc_stg  XATWS
                ,xx_crm_wcelg_cust   XCWC
           WHERE XATWS.ext_type = 'I'
             AND XATWS.bill_to_customer_id = XCWC.cust_account_id
             AND XATWS.trx_creation_date   < XCWC.ar_conv_from_date_full
             AND NOT EXISTS (SELECT 1
                               FROM xx_ar_wc_converted_rec_trx  XAWCRT
                              WHERE XAWCRT.id   = XATWS.customer_trx_id
                                AND XAWCRT.type = 'TRX')
          UNION
          SELECT DISTINCT XACWS.cash_receipt_id "ID", 'REC', gd_cycle_date, p_batch_num
            FROM xx_ar_cr_wc_stg     XACWS
           WHERE XACWS.ext_type = 'F'
             AND NOT EXISTS (SELECT 1
                               FROM xx_ar_wc_converted_rec_trx  XAWCRT
                              WHERE XAWCRT.id   = XACWS.cash_receipt_id
                                AND XAWCRT.type = 'REC')
          UNION
          SELECT DISTINCT XACWS.cash_receipt_id "ID", 'REC', gd_cycle_date, p_batch_num
            FROM xx_ar_cr_wc_stg     XACWS
                ,xx_crm_wcelg_cust   XCWC
           WHERE XACWS.ext_type = 'I'
             AND XACWS.customer_account_id = XCWC.cust_account_id
             AND XACWS.rec_creation_date   < XCWC.ar_conv_from_date_full
             AND NOT EXISTS (SELECT 1
                               FROM xx_ar_wc_converted_rec_trx  XAWCRT
                              WHERE XAWCRT.id   = XACWS.cash_receipt_id
                                AND XAWCRT.type = 'REC'));

      -- Cursor to select customers that had diary notes staged/extracted
      CURSOR lcu_cust_id_notes
      IS
         SELECT DISTINCT cust_account_id
            FROM xx_iex_diary_notes_stg;

      -- Cursor to select customers that had AR staged/extracted
      CURSOR lcu_cust_id
      IS
         (SELECT bill_to_customer_id
            FROM xx_ar_trans_wc_stg
           WHERE ext_type = 'F'
          UNION
          SELECT customer_account_id
            FROM xx_ar_cr_wc_stg
           WHERE ext_type = 'F'
          UNION
          SELECT cust_account_id
            FROM xx_ar_adj_wc_stg
           WHERE ext_type = 'F');

      TYPE conv_tbl_rec_type IS RECORD (id        NUMBER
                                       ,type       VARCHAR2(3)
                                       ,cycle_date DATE
                                       ,batch_num  NUMBER);

      --conv_tbl_rec_type xx_ar_wc_converted_recBATCH_NUMCYCLE_DATETYPEID_trx%ROWTYPE;
      TYPE conv_tbl_type IS TABLE OF conv_tbl_rec_type INDEX BY BINARY_INTEGER;

      TYPE cust_id_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

      lt_conv                   conv_tbl_type;
      lt_cust_id                cust_id_tbl_type;
      ln_control_cnt            NUMBER;
      ln_update_ar_conv_cnt     NUMBER := 0;
      ln_update_ar_conv_tot     NUMBER := 0;
      ln_update_ar_notes_cnt    NUMBER := 0;
      ln_update_ar_notes_tot    NUMBER := 0;
      ln_insert_cnt             NUMBER := 0;
      ln_insert_tot             NUMBER := 0;
      ln_update_ar_no_data_cnt  NUMBER := 0;
      ln_update_notes_cnt       NUMBER := 0;

    BEGIN

      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN
         location_and_log(GC_YES,'Initialize Processing.'||chr(10));

         gd_cycle_date   := FND_DATE.CANONICAL_TO_DATE (p_cycle_date);
         gn_batch_num    := p_batch_num;
         gc_process_type := p_process_type;

         ------------------------------------------------
         -- Print Parameter Names and Values to Log File
         ------------------------------------------------
         FND_FILE.PUT_LINE (FND_FILE.LOG, '');
         FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date             : ' || gd_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch Number           : ' || p_batch_num);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Gather Statistics      : ' || p_compute_stats);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || p_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type           : ' || p_process_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID             : ' || gn_request_id);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, '');
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      BEGIN
         location_and_log(GC_YES, 'Retrieving Interface Settings From Translation Definition'||chr(10));
         get_interface_settings (p_process_type      => p_process_type
                                ,p_bulk_limit        => gn_limit
                                ,p_delimiter         => gc_delimiter
                                ,p_num_threads_delta => gn_threads_delta
                                ,p_file_name         => gc_file_name
                                ,p_email             => gc_email
                                ,p_gather_stats      => gc_compute_stats
                                ,p_line_size         => gn_line_size
                                ,p_file_path         => gc_file_path
                                ,p_num_records       => gn_num_records
                                ,p_debug             => gc_debug
                                ,p_ftp_file_path     => gc_ftp_file_path
                                ,p_arch_file_path    => gc_arch_file_path
                                ,p_full_num_days     => gn_full_num_days
                                ,p_num_threads_full  => gn_threads_full
                                ,p_num_threads_file  => gn_threads_file
                                ,p_child_conc_delta  => gc_conc_short_delta
                                ,p_child_conc_full   => gc_conc_short_full
                                ,p_child_conc_file   => gc_conc_short_file
                                ,p_staging_table     => gc_staging_table
                                ,p_retrieved         => gb_retrieved_trans
                                ,p_error_message     => gc_err_msg_trans);
      END; -- Retrieve interface settings

      print_time_stamp_to_logfile;

      --========================================================================
      -- Override Debug and Gather Statistics with Parameter Values if NOT NULL
      --========================================================================
      BEGIN
         location_and_log(GC_YES, 'Determine if parameter value for debug/stats is used'||chr(10));
         gc_debug         := validate_param_trans_value(p_debug,gc_debug);
         gc_compute_stats := validate_param_trans_value(p_compute_stats,gc_compute_stats);

         FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** PARAMETER OVERRIDES *****************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || gc_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Gather Statistics      : ' || gc_compute_stats);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve Cycle Date Information from Control Table
      --========================================================================
      BEGIN
         location_and_log(GC_YES,'Retrieve Cycle Date Information from Control Table'||chr(10));
         location_and_log(gc_debug,'     gd_cycle_date :'||gd_cycle_date);
         get_control_info (p_cycle_date            => gd_cycle_date
                          ,p_batch_num             => p_batch_num
                          ,p_process_type          => p_process_type
                          ,p_action_type           => NULL
                          ,p_delta_from_date       => gd_delta_from_date
                          ,p_full_from_date        => gd_full_from_date
                          ,p_control_to_date       => gd_control_to_date
                          ,p_post_process_status   => gc_post_process_status
                          ,p_ready_to_execute      => gb_ready_to_execute
                          ,p_reprocessing_required => gb_reprocessing_required
                          ,p_reprocess_cnt         => gc_reprocess_cnt
                          ,p_retrieved             => gb_retrieved_cntl
                          ,p_error_message         => gc_err_msg_cntl);
      END;

      location_and_log(GC_YES, ' full from '||gd_full_from_date||' control to '||gd_control_to_date||chr(10));

      print_time_stamp_to_logfile;

      --========================================================================
      -- Validate Control Information to Determine Processing Required
      --========================================================================
      BEGIN
         location_and_log(GC_YES, 'Evaluate Control Record Status.'||chr(10));
         IF NOT gb_retrieved_cntl THEN
            location_and_log(gc_debug, gc_error_loc||' - Control Record Not Retrieved');
            RAISE EX_NO_CONTROL_RECORD;

         ELSIF gc_post_process_status = 'Y' THEN
            location_and_log(gc_debug, gc_error_loc||' - Cycle Date and Batch Number Already Completed.');
            RAISE EX_CYCLE_COMPLETED;

         ELSIF gb_ready_to_execute = FALSE THEN
            location_and_log(gc_debug, gc_error_loc||' - Cycle Date and Batch Number Already Completed.');
            RAISE EX_CYCLE_COMPLETED;

         ELSIF gb_ready_to_execute = TRUE THEN
            location_and_log(GC_YES, 'Post-Processing is Ready To Complete'||chr(10));

            print_time_stamp_to_logfile;

            --========================================================================
            -- Process Conversion and Pre-Conversion Invoice/Receipt IDs
            --========================================================================
            BEGIN
               location_and_log(GC_YES, 'Process Conversion and Pre-Conversion Invoice/Receipt IDs.'||chr(10));

               location_and_log(gc_debug, '     Opening cursor lcu_upd_ps_delta');
               OPEN lcu_conv;
               LOOP
                  location_and_log(gc_debug, '     Fetching from lcu_conv ');
                  FETCH lcu_conv
                  BULK COLLECT INTO lt_conv LIMIT gn_limit;

                  FORALL i IN 1 .. lt_conv.COUNT
                     INSERT INTO xx_ar_wc_converted_rec_trx
                          VALUES lt_conv (i);
                          location_and_log(gc_debug,'     Issue commit for inserting into converted trx table');

                  IF lt_conv.COUNT > 0
                  THEN
                     location_and_log (GC_YES, 'lt_conv.COUNT = ' || lt_conv.COUNT);
                     ln_insert_cnt := SQL%ROWCOUNT;
                     ln_insert_tot := ln_insert_tot + ln_insert_cnt;
                  END IF;

                  location_and_log (gc_debug, '     Records inserted into xx_ar_wc_converted_rec_trx: ' || ln_insert_cnt);

                  COMMIT;
                  EXIT WHEN lcu_conv%NOTFOUND;
               END LOOP;

               CLOSE lcu_conv;
               location_and_log(gc_debug,'     Closed cursor lcu_conv');

               location_and_log (GC_YES, 'Total records inserted into xx_ar_wc_converted_rec_trx: ' || ln_insert_tot);

            END;

            print_time_stamp_to_logfile;

            --========================================================================
            -- Update Customer Eligibility Table for Full Conversion
            --========================================================================
            BEGIN
               location_and_log(GC_YES, 'Update Customer Eligibility Table for Full Conversion'||chr(10));

               location_and_log(gc_debug, '     Fetching from lcu_cust_id ');
               OPEN lcu_cust_id;
               LOOP
                  location_and_log(gc_debug, '     Fetching from lcu_cust_id');
                  FETCH lcu_cust_id
                  BULK COLLECT INTO lt_cust_id LIMIT gn_limit;

                  FORALL i IN 1 .. lt_cust_id.COUNT
                       UPDATE xx_crm_wcelg_cust
                          SET ar_converted_flag      = 'Y'
                             ,ar_conv_from_date_full = gd_full_from_date
                             ,ar_conv_to_date_full   = gd_control_to_date
                        WHERE cust_account_id        = lt_cust_id (i)
                          AND ar_converted_flag      = 'N'
                          AND cust_mast_head_ext     = 'Y';
                       location_and_log(gc_debug,'     Updated the xx_crm_wcelg_cust ');

                  IF lt_cust_id.COUNT > 0
                  THEN
                     location_and_log (GC_YES, 'lt_cust_id.COUNT = ' || lt_cust_id.COUNT);
                     ln_update_ar_conv_cnt := SQL%ROWCOUNT;
                     ln_update_ar_conv_tot := ln_update_ar_conv_tot + ln_update_ar_conv_cnt;
                  END IF;

                  location_and_log (gc_debug, '     Records updated in xx_crm_wcelg_cust: ' || ln_update_ar_conv_cnt);

                  COMMIT;
                  EXIT WHEN lcu_cust_id%NOTFOUND;

               END LOOP;
               CLOSE lcu_cust_id;
               location_and_log(gc_debug,'     Closed cursor lcu_cust_id');

               location_and_log (GC_YES, 'Total records updated in xx_crm_wcelg_cust for AR conv flag: ' || ln_update_ar_conv_tot);

            END; --  Update Customer Eligibility Table for Full Conversion

            print_time_stamp_to_logfile;

            --========================================================================
            -- Update Customer Eligibility Table for AR diary notes
            --========================================================================
            BEGIN
               location_and_log(GC_YES, 'Update Customer Eligibility Table for AR diary notes'||chr(10));

               location_and_log(gc_debug, '     Fetching from lcu_cust_id_notes ');
               OPEN lcu_cust_id_notes;
               LOOP
                  location_and_log(gc_debug, '     Fetching from lcu_cust_id_notes');
                  FETCH lcu_cust_id_notes
                  BULK COLLECT INTO lt_cust_id LIMIT gn_limit;

                  FORALL i IN 1 .. lt_cust_id.COUNT
                       UPDATE xx_crm_wcelg_cust
                          SET notes_processed_to_wc  = 'Y'
                        WHERE cust_account_id        = lt_cust_id (i)
                          AND notes_processed_to_wc  = 'N'
                          AND cust_mast_head_ext     = 'Y';
                       location_and_log(gc_debug,'     Updated the xx_crm_wcelg_cust ');

                  IF lt_cust_id.COUNT > 0
                  THEN
                     location_and_log (GC_YES, 'lt_cust_id.COUNT = ' || lt_cust_id.COUNT);
                     ln_update_ar_notes_cnt := SQL%ROWCOUNT;
                     ln_update_ar_notes_tot := ln_update_ar_notes_tot + ln_update_ar_notes_cnt;
                  END IF;

                  location_and_log (gc_debug, '     Records updated in xx_crm_wcelg_cust: ' || ln_update_ar_notes_cnt);

                  COMMIT;
                  EXIT WHEN lcu_cust_id_notes%NOTFOUND;

               END LOOP;
               CLOSE lcu_cust_id_notes;
               location_and_log(gc_debug,'     Closed cursor lcu_cust_id_notes');

               location_and_log (GC_YES, 'Total records updated in xx_crm_wcelg_cust for AR diary notes: ' || ln_update_ar_notes_tot);

            END; --  Update Customer Eligibility Table for AR diary notes

            print_time_stamp_to_logfile;

            --========================================================================
            -- Update Control Table for Post-Processing Status
            --========================================================================
            BEGIN
               location_and_log(GC_YES, 'Update Control Table for Post-Processing Status'||chr(10));

               location_and_log(gc_debug,'     Before Update Post process details in the Control Table');
               -- AR reconcilation is not checked on purpose since it can run anytime required
               UPDATE xx_ar_wc_ext_control
                  SET post_process_req_id = gn_request_id
                     ,post_process_status = 'Y'
                WHERE cycle_date      = gd_cycle_date
                  AND batch_num       = p_batch_num
                  AND pmt_upd_full    = 'Y'
                  AND pmt_upd_delta   = 'Y'
                  AND trx_ext_full    = 'Y'
                  AND trx_ext_delta   = 'Y'
                  AND trx_gen_file    = 'Y'
                  AND rec_ext_full    = 'Y'
                  AND rec_ext_delta   = 'Y'
                  AND rec_gen_file    = 'Y'
                  AND adj_ext_full    = 'Y'
                  AND adj_ext_delta   = 'Y'
                  AND adj_gen_file    = 'Y'
                  AND pmt_ext_full    = 'Y'
                  AND pmt_ext_delta   = 'Y'
                  AND pmt_gen_file    = 'Y'
                  AND app_ext_full    = 'Y'
                  AND app_ext_delta   = 'Y'
                  AND app_gen_file    = 'Y'
                  AND diary_notes_ext = 'Y';

               IF SQL%NOTFOUND THEN
                  location_and_log(gc_debug, 'Post Process Status Flag is not updated to Y.');
                  RAISE EX_ERROR_UPD_POST_PROCESS;
               ELSE
                  location_and_log(gc_debug,'     Successfully Completed Post Processing');
               END IF;

               COMMIT;
               location_and_log(GC_YES,'     Updated the Post process details in the Control Table.');

            END;  -- Update Control Table for Post-Processing Status

            print_time_stamp_to_logfile;

            -- Start: below block added for Defect# 16273 
            --=================================================================================+===============
            -- Update Customer Eligibility Table for eligible customers who had no transactions during this run
            --==================================================================================+==============
            BEGIN
               location_and_log(GC_YES, 'Update Customer Eligibility Table for eligible customers who had no transactions in Full Conversion'||chr(10));

               UPDATE xx_crm_wcelg_cust
                  SET ar_converted_flag      = 'Y'
                     ,ar_conv_from_date_full = gd_full_from_date
                     ,ar_conv_to_date_full   = gd_control_to_date
                WHERE ar_converted_flag      = 'N'
                  AND cust_mast_head_ext     = 'Y';
                        
               ln_update_ar_no_data_cnt := SQL%ROWCOUNT;
                        
               location_and_log (GC_YES, 'Total records updated in xx_crm_wcelg_cust for AR conv flag for customers who had no transactions : ' || ln_update_ar_no_data_cnt);

               COMMIT;
            END; --  Update Customer Eligibility Table for Full Conversion

            print_time_stamp_to_logfile;
            -- End for Defect# 16273 
            
             -- Start: below block added for Defect# 16366
        --=================================================================================+===============
        -- Update Customer Eligibility Table for eligible customers who had no transactions during this run
        --==================================================================================+==============
        BEGIN
           location_and_log(GC_YES, 'Update Customer Eligibility Table once the notes are processed'||chr(10));

           UPDATE xx_crm_wcelg_cust
              SET notes_processed_to_wc = 'Y'
            WHERE notes_processed_to_wc = 'N' 
              AND cust_mast_head_ext    = 'Y';

           ln_update_notes_cnt := SQL%ROWCOUNT;

           location_and_log (GC_YES, 'Total records updated in xx_crm_wcelg_cust for AR conv flag for notes processed : ' || ln_update_notes_cnt);

           COMMIT;
        END; --  Update Customer Eligibility Table 

        print_time_stamp_to_logfile;
            -- End for Defect# 16366 

         ELSE
            location_and_log(gc_debug, gc_error_loc||' - Invalid processing type or control record status. ');
            RAISE EX_INVALID_STATUS;

         END IF;  -- Evaluate Control Record Status.

      END; --  Validate Control Information to Determine Processing Required

   EXCEPTION
      WHEN EX_NO_CONTROL_RECORD THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_NO_CONTROL_RECORD at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_CYCLE_COMPLETED THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_CYCLE_COMPLETED at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_ERROR_UPD_POST_PROCESS THEN
         ROLLBACK;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_ERROR_UPD_POST_PROCESS at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_STATUS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_INVALID_STATUS at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND at: ' ||gc_error_loc||'. '||SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at: ' ||gc_error_loc||'. '||SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

   END ar_post_process;

   -- +====================================================================+
   -- | Name       : ar_pre_conversion                                     |
   -- |                                                                    |
   -- | Description: This procedure is used for pre-processing the initial |
   -- |              conversion only.                                      |
   -- |                                                                    |
   -- | Parameters : p_cycle_date      IN                                  |
   -- |              p_batch_num       IN                                  |
   -- |              p_compute_stats   IN                                  |
   -- |              p_debug           IN                                  |
   -- |              p_process_type    IN                                  |
   -- |              p_action_type     IN                                  |
   -- |                                                                    |
   -- |              p_errbuf          OUT                                 |
   -- |              p_retcode         OUT                                 |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE ar_pre_conversion (p_errbuf         OUT  VARCHAR2
                               ,p_retcode        OUT  NUMBER
                               ,p_cycle_date     IN   VARCHAR2
                               ,p_batch_num      IN   NUMBER
                               ,p_compute_stats  IN   VARCHAR2
                               ,p_debug          IN   VARCHAR2
                               ,p_process_type   IN   VARCHAR2)
   IS
      ltab_child_requests           FND_CONCURRENT.REQUESTS_TAB_TYPE;
      ln_success_cnt                NUMBER := 0;
      ln_error_cnt                  NUMBER := 0;
      ln_child_cnt                  NUMBER := 0;

      lc_print_to_log               VARCHAR2(1) := 'Y';
      lc_process_type               fnd_concurrent_requests.argument5%TYPE;

      -- Used for Verifying Prior Run and Calculating Date Ranges
      ld_control_date               xx_ar_wc_ext_control.control_to_date%TYPE;
      ld_full_from_date             xx_ar_wc_ext_control.full_from_date%TYPE;
      ld_delta_from_date            xx_ar_wc_ext_control.delta_from_date%TYPE;
      ld_last_delta_from_date       xx_ar_wc_ext_control.delta_from_date%TYPE;
      lc_last_cntl_request_id       xx_ar_wc_ext_control.request_id%TYPE        :=0;
      ld_last_cycle_date            xx_ar_wc_ext_control.cycle_date%TYPE;
      ln_last_batch_num             xx_ar_wc_ext_control.batch_num%TYPE;
      lc_last_post_process_status   xx_ar_wc_ext_control.post_process_status%TYPE;

   BEGIN

      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN      
         gc_req_data     := FND_CONC_GLOBAL.REQUEST_DATA;
         IF gc_req_data IS NULL THEN
            location_and_log(GC_YES,'Initialize Processing.'||chr(10));
         ELSE
            location_and_log(GC_YES,'Initialize Processing for Restart.'||chr(10));
         END IF;

         gd_cycle_date   := FND_DATE.CANONICAL_TO_DATE (p_cycle_date);
         gn_batch_num    := p_batch_num;
         gc_process_type := p_process_type;

         ------------------------------------------------
         -- Print Parameter Names and Values to Log File
         ------------------------------------------------
         IF gc_req_data IS NULL THEN
            -- parameters are not printed on restart
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date             : ' || gd_cycle_date);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch Number           : ' || p_batch_num);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Gather Statistics      : ' || p_compute_stats);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || p_debug);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type           : ' || p_process_type);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID             : ' || gn_request_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
         END IF;
      END;

      print_time_stamp_to_logfile;

      --==================================================================
      -- Retrieve Interface Settings
      --==================================================================
      BEGIN
         location_and_log(GC_YES, 'Retrieving Interface Settings From Translation Definition'||chr(10));
         get_interface_settings (p_process_type      => p_process_type
                                ,p_bulk_limit        => gn_limit
                                ,p_delimiter         => gc_delimiter
                                ,p_num_threads_delta => gn_threads_delta
                                ,p_file_name         => gc_file_name
                                ,p_email             => gc_email
                                ,p_gather_stats      => gc_compute_stats
                                ,p_line_size         => gn_line_size
                                ,p_file_path         => gc_file_path
                                ,p_num_records       => gn_num_records
                                ,p_debug             => gc_debug
                                ,p_ftp_file_path     => gc_ftp_file_path
                                ,p_arch_file_path    => gc_arch_file_path
                                ,p_full_num_days     => gn_full_num_days
                                ,p_num_threads_full  => gn_threads_full
                                ,p_num_threads_file  => gn_threads_file
                                ,p_child_conc_delta  => gc_conc_short_delta
                                ,p_child_conc_full   => gc_conc_short_full
                                ,p_child_conc_file   => gc_conc_short_file
                                ,p_staging_table     => gc_staging_table
                                ,p_retrieved         => gb_retrieved_trans
                                ,p_error_message     => gc_err_msg_trans
                                ,p_print_to_req_log  => lc_print_to_log);
       END; -- Retrieve interface settings

      --========================================================================
      -- Checking Request Data to Determine if 1st Time or Restarting
      --========================================================================
      IF gc_req_data IS NULL THEN
         -- This is NOT a restart

         --==================================================================
         -- Retrieve Last Control Record
         --==================================================================
         BEGIN
            location_and_log(GC_YES, 'Retrieve Last Control Record'||chr(10));
            location_and_log(gc_debug, '     Fetch MAX RID from control table');
            SELECT MAX(request_id)
              INTO lc_last_cntl_request_id
              FROM xx_ar_wc_ext_control;
   
            location_and_log(GC_YES, '     Last request ID         : '||lc_last_cntl_request_id);
   
            IF lc_last_cntl_request_id <> 0 THEN
               location_and_log(gc_debug, '     Fetch information for MAX RID');
               SELECT cycle_date
                     ,batch_num
                     ,control_to_date
                     ,post_process_status
                 INTO ld_last_cycle_date
                     ,ln_last_batch_num
                     ,ld_last_delta_from_date
                     ,lc_last_post_process_status
                 FROM xx_ar_wc_ext_control
                WHERE request_id = lc_last_cntl_request_id;
   
               location_and_log(GC_YES, '     Last cycle date         : '||ld_last_cycle_date);
               location_and_log(GC_YES, '     Last batch number       : '||ln_last_batch_num);
               location_and_log(GC_YES, '     Last delta from date    : '||ld_last_delta_from_date);
               location_and_log(GC_YES, '     Last post process status: '||lc_last_post_process_status);
   
            END IF;  
   
            print_time_stamp_to_logfile;
   
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND at: ' ||gc_error_loc||' .'||SQLERRM);
               RAISE EX_NO_CONTROL_RECORD;
         END; -- retrieve last control record
   
         --==================================================================
         -- Check Processing Type
         --==================================================================      
         BEGIN
            IF lc_last_cntl_request_id = 0 OR lc_last_cntl_request_id IS NULL THEN
   
               --==================================================================
               -- Insert Control Record for INITIAL CONVERSION
               --==================================================================      
               BEGIN
                  -----------------------------------
                  -- Calculate Date Ranges
                  -----------------------------------
                  --The three dates calculated below will be for all 5 AR Webcollect outbounds
   
                  location_and_log(gc_debug, '     Retrieve Control TO Date');
                  SELECT SYSDATE
                    INTO ld_control_date
                   FROM DUAL;
   
                  location_and_log(gc_debug, '     Set Delta FROM Date');
                  ld_delta_from_date := ld_control_date;
   
                  location_and_log(gc_debug, '     Set Full FROM Date. Full FROM Date is the control TO Date minus number of days to convert');
                  ld_full_from_date := ld_control_date - gn_full_num_days;
   
                  -----------------------------------
                  -- Insert New Control Record
                  -----------------------------------
                  print_time_stamp_to_logfile;
                  location_and_log(GC_YES, '     Insert New Control Record');
   
                  INSERT INTO xx_ar_wc_ext_control
                       VALUES (gd_cycle_date       -- CYCLE_DATE
                              ,p_batch_num         -- BATCH_NUM
                              ,gn_request_id       -- PRE_PROCESS_REQ_ID
                              ,gn_request_id       -- POST_PROCESS_REQ_ID
                              ,'N'                 -- POST_PROCESS_STATUS
                              ,ld_delta_from_date  -- DELTA_FROM_DATE
                              ,ld_full_from_date   -- FULL_FROM_DATE
                              ,ld_control_date     -- CONTROL_TO_DATE
                              ,'C'                 -- PMT_UPD_FULL
                              ,'Y'                 -- PMT_UPD_DELTA
                              ,'C'                 -- TRX_EXT_FULL
                              ,'Y'                 -- TRX_EXT_DELTA
                              ,'N'                 -- TRX_GEN_FILE
                              ,'C'                 -- REC_EXT_FULL
                              ,'Y'                 -- REC_EXT_DELTA
                              ,'N'                 -- REC_GEN_FILE
                              ,'C'                 -- ADJ_EXT_FULL
                              ,'Y'                 -- ADJ_EXT_DELTA
                              ,'N'                 -- ADJ_GEN_FILE
                              ,'C'                 -- PMT_EXT_FULL
                              ,'Y'                 -- PMT_EXT_DELTA
                              ,'N'                 -- PMT_GEN_FILE
                              ,'C'                 -- APP_EXT_FULL
                              ,'Y'                 -- APP_EXT_DELTA
                              ,'N'                 -- APP_GEN_FILE
                              ,'Y'                 -- DIARY_NOTES_EXT  --defect 19343 from N to Y
                              ,'Y'                 -- AR_RECON
                              ,SYSDATE             -- CREATION_DATE
                              ,gn_user_id          -- CREATED_BY
                              ,SYSDATE             -- LAST_UPDATE_DATE
                              ,gn_user_id          -- LAST_UPATED_BY
                              ,gn_request_id       -- REQUEST_ID
                             );
   
                  location_and_log(gc_debug,'     Issue commit for inserting control record');
                  COMMIT;
   
                  location_and_log(GC_YES, '     Successfully Inserted Control Table');
   
                  print_time_stamp_to_logfile;
      
               EXCEPTION
                  WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at: ' ||gc_error_loc||' .'||SQLERRM);
                     RAISE EX_INSERT_ERROR;
   
               END;  -- insert into control table
   
               --==================================================================
               -- Retrieve Cycle Date Information from Control Table
               --==================================================================
               BEGIN
                  location_and_log(GC_YES, '     Calling get_control_info to evaluate cycle date information');
                  get_control_info (p_cycle_date            => gd_cycle_date
                                   ,p_batch_num             => p_batch_num
                                   ,p_process_type          => p_process_type
                                   ,p_action_type           => NULL
                                   ,p_delta_from_date       => gd_delta_from_date
                                   ,p_full_from_date        => gd_full_from_date
                                   ,p_control_to_date       => gd_control_to_date
                                   ,p_post_process_status   => gc_post_process_status
                                   ,p_ready_to_execute      => gb_ready_to_execute
                                   ,p_reprocessing_required => gb_reprocessing_required
                                   ,p_reprocess_cnt         => gc_reprocess_cnt
                                   ,p_retrieved             => gb_retrieved_cntl
                                   ,p_error_message         => gc_err_msg_cntl);
   
               END; 
   
               print_time_stamp_to_logfile;
            
            ELSE
   
               --==================================================================
               -- Insert Control Record for INITIAL CONVERSION
               --==================================================================      
               BEGIN        
                  -------------------------------------------------------
                  -- Retrieve Cycle Date Information from Control Table
                  -------------------------------------------------------
                  location_and_log(GC_YES, '     Calling get_control_info to evaluate cycle date information');
                  get_control_info (p_cycle_date            => gd_cycle_date
                                   ,p_batch_num             => p_batch_num
                                   ,p_process_type          => p_process_type
                                   ,p_action_type           => NULL
                                   ,p_delta_from_date       => gd_delta_from_date
                                   ,p_full_from_date        => gd_full_from_date
                                   ,p_control_to_date       => gd_control_to_date
                                   ,p_post_process_status   => gc_post_process_status
                                   ,p_ready_to_execute      => gb_ready_to_execute
                                   ,p_reprocessing_required => gb_reprocessing_required
                                   ,p_reprocess_cnt         => gc_reprocess_cnt
                                   ,p_retrieved             => gb_retrieved_cntl
                                   ,p_error_message         => gc_err_msg_cntl);
               END;   
   
            END IF;   
   
            print_time_stamp_to_logfile;
   
            --========================================================================
            -- Evaluate Control Record
            --========================================================================
            BEGIN
               location_and_log(GC_YES, 'Evaluate Control Record Status.'||chr(10));
               IF NOT gb_retrieved_cntl THEN
                  location_and_log(gc_debug, gc_error_loc||' - Control Record Not Retrieved');
                  RAISE EX_NO_CONTROL_RECORD;
   
               ELSIF gc_post_process_status = 'Y' THEN
                  location_and_log(gc_debug, gc_error_loc||' - Cycle Date and Batch Number Already Completed.');
                  RAISE EX_CYCLE_COMPLETED;
   
               ELSIF gb_ready_to_execute = FALSE THEN
                  location_and_log(gc_debug, gc_error_loc||' - Data has already been staged for this process.');
                  RAISE EX_STAGING_COMPLETED;
   
               ELSIF gb_ready_to_execute = TRUE THEN
                  -----------------------------------
                  -- Truncate Staging Tables
                  -----------------------------------
                  location_and_log(GC_YES, '     Truncating Staging Tables');
                  BEGIN
                     EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_ADJ_WC_STG';
                     EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_CR_WC_STG';
                     EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_PS_WC_STG';
                     EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_RECAPPL_WC_STG';
                     EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_TRANS_WC_STG';
   
                     location_and_log(GC_YES, '     Completed Truncating 5 Staging Tables');
   
                     print_time_stamp_to_logfile;
   
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND at: ' ||gc_error_loc||' .'||SQLERRM);
                        print_time_stamp_to_logfile;
                        p_retcode := 2;
   
                     WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at: ' ||gc_error_loc||' .'||SQLERRM);
                        print_time_stamp_to_logfile;
                        p_retcode := 2;
                  END;  -- end truncate staging tables

                  print_time_stamp_to_logfile;
                  
                  --========================================================================
                  -- Truncate PMT Schedules Last Update Pre-processing Table
                  --========================================================================
                  BEGIN
                     location_and_log(GC_YES, 'Truncating PMT UPD Staging Table'||chr(10));
                     EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_WC_UPD_PS';
                     location_and_log(GC_YES, '     Completed Truncating PMT UPD Staging Table');
                  END; -- end PMT UPD update
      
                  print_time_stamp_to_logfile;
   
                  --========================================================================
                  -- Submit PMT UPD Full INITIAL
                  --========================================================================
                  BEGIN
                     location_and_log(GC_YES,'Submit PMT UPD Programs for Full INITIAL.'||chr(10));
      
                     location_and_log(p_debug,'     Set Print Options');
                     gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer => NULL
                                                                     ,copies  => 0);
      
                     gn_req_id_full :=
                         fnd_request.submit_request (application      => 'XXFIN'
                                                    ,program          => 'XX_AR_UPD_PS_WC_C'
                                                    ,description      => ''
                                                    ,start_time       => ''
                                                    ,sub_request      => TRUE
                                                    ,argument1        => p_cycle_date
                                                    ,argument2        => p_batch_num
                                                    ,argument3        => 'Y'
                                                    ,argument4        => p_debug
                                                    ,argument5        => 'AR_UPD_PS_FULL'
                                                    ,argument6        => 'C');
      
                     FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID       : '||gn_req_id_full);
                     print_time_stamp_to_logfile;
         
                  END;  -- Submit PMT UPD Full INITIAL

               ELSE
                  location_and_log(gc_debug, gc_error_loc||' - Invalid processing type or control record status. ');
                  RAISE EX_INVALID_STATUS;
               END IF;    -- Evaluate control record status
         
            END;  -- Evaluate control record
            
         END;   -- check processing type
      
         location_and_log(GC_YES, '     Pausing AR_PRE_CONVERSION......'||chr(10));
         FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  => 'PAUSED',
                                         request_data => 'PMT_UPD');
      
      ELSE
         location_and_log(GC_YES, '     Restarting after PMT_UPD Completed');
         location_and_log(gc_debug,'     Checking Child Requests');
         --========================================================================
         -- Post-Processing for Child Request FULL
         --========================================================================
         BEGIN
            location_and_log(GC_YES,'Post-processing for Child Requests.'||chr(10));

            ltab_child_requests := FND_CONCURRENT.GET_SUB_REQUESTS(gn_request_id);

            location_and_log(GC_YES,'     Checking Child Requests');
            IF ltab_child_requests.count > 0 THEN
               FOR i IN ltab_child_requests.FIRST .. ltab_child_requests.LAST
               LOOP

                  ln_child_cnt := ln_child_cnt + 1;  -- tracks children...should only be 2
                  location_and_log(GC_YES,CHR (10)||'     ltab_child_requests(i).request_id :'||ltab_child_requests(i).request_id);
                  location_and_log(GC_YES,          '     ltab_child_requests(i).dev_phase  :'||ltab_child_requests(i).dev_phase);
                  location_and_log(GC_YES,          '     ltab_child_requests(i).dev_status :'||ltab_child_requests(i).dev_status);

                  -----------------------------------
                  -- Determine Process Type
                  -----------------------------------
                  location_and_log(gc_debug,'     Determine Process Type.');
                  SELECT argument5
                    INTO lc_process_type
                    FROM fnd_concurrent_requests
                   WHERE request_id = ltab_child_requests(i).request_id;

                  ------------------------------------------------
                  -- Update Control Table based on Type and Status
                  ------------------------------------------------
                  location_and_log(gc_debug,'     Update control table based on process type and RID status.');
                  IF lc_process_type = 'AR_UPD_PS_FULL'
                  THEN
                     location_and_log(gc_debug,'     Process Type: '||lc_process_type);
                     location_and_log(gc_debug,'     FULL - Request ID');
                     IF ltab_child_requests(i).dev_phase  = 'COMPLETE' AND
                        ltab_child_requests(i).dev_status IN ('NORMAL','WARNING')
                     THEN
                        location_and_log(gc_debug,'     FULL - Update pmt_upd_full to Y');
                        ln_success_cnt := ln_success_cnt + 1;
                        UPDATE xx_ar_wc_ext_control
                           SET pmt_upd_full = 'Y'
                         WHERE cycle_date   = gd_cycle_date
                           AND batch_num    = p_batch_num;

                     ELSE
                        location_and_log(gc_debug,'     FULL - Update pmt_upd_full error count');
                        ln_error_cnt := ln_error_cnt + 1;
                     END IF;

                  ELSE
                     RAISE EX_INVALID_PROCESS_TYPE;
                  END IF;

               END LOOP; -- sub requests

            END IF; -- retrieve child requests

            location_and_log(GC_YES, '     ln_error_cnt  : '||ln_error_cnt);
            location_and_log(GC_YES, '     ln_success_cnt: '||ln_success_cnt);

            IF ln_error_cnt <> 0 THEN
               RAISE EX_PMT_UPD_ERROR;
            ELSE
               --========================================================================
               -- Gather Stats on Staging Table
               --========================================================================
               location_and_log(GC_YES, '     Determine if gathering stats: '||gc_compute_stats);

               IF gc_compute_stats = 'Y' THEN
                  compute_stat (gc_compute_stats, 'XXFIN', gc_staging_table);
                  location_and_log(GC_YES, '     Gather Stats completed');
               ELSE
                  location_and_log(GC_YES, 'Gather Stats was not exeucted');
               END IF;

            END IF;  -- Check for Error count

         END;  -- Post-Processing for Child Requests

      END IF;  -- check request_data

   EXCEPTION
      WHEN EX_NO_CONTROL_RECORD THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_NO_CONTROL_RECORD at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_CYCLE_COMPLETED THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_CYCLE_COMPLETED at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_STAGING_COMPLETED THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_STAGING_COMPLETED at: '||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_STATUS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_INVALID_STATUS at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND at ' ||gc_error_loc||' .'||SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at ' ||gc_error_loc||' .'||SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

   END ar_pre_conversion;

   -- +====================================================================+
   -- | Name       : copy_staged_recs                                      |
   -- |                                                                    |
   -- | Description: This procedure is used for copying records from       |
   -- |              staging tables to temporary tables                    |
   -- |                                                                    |
   -- | Parameters : p_truncate_flag   IN                                  |
   -- |              p_compute_stats   IN                                  |
   -- |              p_debug           IN                                  |
   -- |                                                                    |
   -- |              p_errbuf          OUT                                 |
   -- |              p_retcode         OUT                                 |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE copy_staged_recs (p_errbuf         OUT  VARCHAR2
                              ,p_retcode        OUT  NUMBER
                              ,p_truncate_flag  IN   VARCHAR2
                              ,p_compute_stats  IN   VARCHAR2
                              ,p_debug          IN   VARCHAR2)
   IS
      EX_TRUNCATE_AR_RECON_STG    EXCEPTION;
      EX_TRUNCATE_AR_STG          EXCEPTION;   
      EX_INSERT_TMP_TABLES        EXCEPTION;
      EX_GATHER_STATS             EXCEPTION;

   BEGIN
      --========================================================================
      -- Truncate Data Staging Tables Based on Parameter
      --========================================================================
      BEGIN
         location_and_log(GC_YES,'     Checking p_truncate_flag to determine if AR data temp tables should be truncated.');
         IF p_truncate_flag = 'Y' THEN

            location_and_log(GC_YES,'          Truncating xx_iex_diary_notes_stg_tmp.');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_IEX_DIARY_NOTES_STG_TMP';

            location_and_log(GC_YES,'          Truncating xx_ar_cr_wc_stg_tmp.');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_CR_WC_STG_TMP';

            location_and_log(GC_YES,'          Truncating xx_ar_adj_wc_stg_tmp.');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_ADJ_WC_STG_TMP';

            location_and_log(GC_YES,'          Truncating xx_ar_ps_wc_stg_tmp.');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_PS_WC_STG_TMP';

            location_and_log(GC_YES,'          Truncating xx_ar_recappl_wc_stg_tmp.');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_RECAPPL_WC_STG_TMP';

            location_and_log(GC_YES,'          Truncating xx_ar_trans_wc_stg_tmp.');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_TRANS_WC_STG_TMP';

            location_and_log(GC_YES,'          Truncating xx_ar_wc_upd_ps_tmp.');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_WC_UPD_PS_TMP';
            
            location_and_log(GC_YES,'          Truncating xx_ar_recon_open_itm_tmp.');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_RECON_OPEN_ITM_TMP';

            location_and_log(GC_YES,'          Truncating xx_ar_recon_trans_stg_tmp.');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_RECON_TRANS_STG_TMP';

            location_and_log(GC_YES,'     Complete truncating of AR data temp tables.');            

         ELSE
            location_and_log(GC_YES,'     AR data temp tables were not truncated based on p_truncate_flag.');
         END IF;

      EXCEPTION
         WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS (truncate) at ' ||gc_error_loc||' .'||SQLERRM);
            RAISE EX_TRUNCATE_AR_RECON_STG;
      END;
      print_time_stamp_to_logfile;

      --========================================================================
      -- Inserting Records from Staging Tables into Temp Tables
      --========================================================================
      location_and_log(GC_YES,'     Inserting records from staging tables into temp tables');
      BEGIN
         INSERT INTO xx_iex_diary_notes_stg_tmp USING SELECT * FROM xx_iex_diary_notes_stg;
         location_and_log(GC_YES,'          Records inserted into xx_iex_diary_notes_stg_tmp: '||SQL%ROWCOUNT);
         COMMIT;

         INSERT INTO xx_ar_cr_wc_stg_tmp        USING SELECT * FROM xx_ar_cr_wc_stg;
         location_and_log(GC_YES,'          Records inserted into xx_ar_cr_wc_stg_tmp       : '||SQL%ROWCOUNT);
         COMMIT;
         
         INSERT INTO xx_ar_adj_wc_stg_tmp       USING SELECT * FROM xx_ar_adj_wc_stg;
         location_and_log(GC_YES,'          Records inserted into xx_ar_adj_wc_stg_tmp      : '||SQL%ROWCOUNT);
         COMMIT;         
         
         INSERT INTO xx_ar_ps_wc_stg_tmp        USING SELECT * FROM xx_ar_ps_wc_stg;
         location_and_log(GC_YES,'          Records inserted into xx_ar_ps_wc_stg_tmp       : '||SQL%ROWCOUNT);
         COMMIT;

         INSERT INTO xx_ar_recappl_wc_stg_tmp   USING SELECT * FROM xx_ar_recappl_wc_stg;
         location_and_log(GC_YES,'          Records inserted into xx_ar_recappl_wc_stg_tmp  : '||SQL%ROWCOUNT);
         COMMIT;

         INSERT INTO xx_ar_trans_wc_stg_tmp     USING SELECT * FROM xx_ar_trans_wc_stg;
         location_and_log(GC_YES,'          Records inserted into xx_ar_trans_wc_stg_tmp    : '||SQL%ROWCOUNT);
         COMMIT;

         INSERT INTO xx_ar_wc_upd_ps_tmp        USING SELECT * FROM xx_ar_wc_upd_ps;
         location_and_log(GC_YES,'          Records inserted into xx_ar_wc_upd_ps_tmp       : '||SQL%ROWCOUNT);
         COMMIT;

         INSERT INTO xx_ar_recon_open_itm_tmp 
                     (payment_schedule_id
                     ,staged_dunning_level
                     ,dunning_level_override_date
                     ,last_update_date
                     ,last_updated_by
                     ,creation_date
                     ,created_by
                     ,last_update_login
                     ,due_date
                     ,amount_due_original
                     ,amount_due_remaining
                     ,number_of_due_dates
                     ,status
                     ,invoice_currency_code
                     ,class
                     ,cust_trx_type_id
                     ,customer_id
                     ,customer_site_use_id
                     ,customer_trx_id
                     ,cash_receipt_id
                     ,associated_cash_receipt_id
                     ,term_id
                     ,terms_sequence_number
                     ,gl_date_closed
                     ,actual_date_closed
                     ,discount_date
                     ,amount_line_items_original
                     ,amount_line_items_remaining
                     ,amount_applied
                     ,amount_adjusted
                     ,amount_in_dispute
                     ,amount_credited
                     ,receivables_charges_charged
                     ,receivables_charges_remaining
                     ,freight_original
                     ,freight_remaining
                     ,tax_original
                     ,tax_remaining
                     ,discount_original
                     ,discount_remaining
                     ,discount_taken_earned
                     ,discount_taken_unearned
                     ,in_collection
                     ,cash_applied_id_last
                     ,cash_applied_date_last
                     ,cash_applied_amount_last
                     ,cash_applied_status_last
                     ,cash_gl_date_last
                     ,cash_receipt_id_last
                     ,cash_receipt_date_last
                     ,cash_receipt_amount_last
                     ,cash_receipt_status_last
                     ,exchange_rate_type
                     ,exchange_date
                     ,exchange_rate
                     ,adjustment_id_last
                     ,adjustment_date_last
                     ,adjustment_gl_date_last
                     ,adjustment_amount_last
                     ,follow_up_date_last
                     ,follow_up_code_last
                     ,promise_date_last
                     ,promise_amount_last
                     ,collector_last
                     ,call_date_last
                     ,trx_number
                     ,trx_date
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
                     ,reversed_cash_receipt_id
                     ,amount_adjusted_pending
                     ,attribute11
                     ,attribute12
                     ,attribute13
                     ,attribute14
                     ,attribute15
                     ,gl_date
                     ,acctd_amount_due_remaining
                     ,program_application_id
                     ,program_id
                     ,program_update_date
                     ,receipt_confirmed_flag
                     ,request_id
                     ,selected_for_receipt_batch_id
                     ,last_charge_date
                     ,second_last_charge_date
                     ,dispute_date
                     ,org_id
                     ,global_attribute1
                     ,global_attribute2
                     ,global_attribute3
                     ,global_attribute4
                     ,global_attribute5
                     ,global_attribute6
                     ,global_attribute7
                     ,global_attribute8
                     ,global_attribute9
                     ,global_attribute10
                     ,global_attribute11
                     ,global_attribute12
                     ,global_attribute13
                     ,global_attribute14
                     ,global_attribute15
                     ,global_attribute16
                     ,global_attribute17
                     ,global_attribute18
                     ,global_attribute19
                     ,global_attribute20
                     ,global_attribute_category
                     ,cons_inv_id
                     ,cons_inv_id_rev
                     ,exclude_from_dunning_flag
                     ,mrc_customer_trx_id
                     ,mrc_exchange_rate_type
                     ,mrc_exchange_date
                     ,mrc_exchange_rate
                     ,mrc_acctd_amount_due_remaining
                     ,br_amount_assigned
                     ,reserved_type
                     ,reserved_value
                     ,active_claim_flag
                     ,exclude_from_cons_bill_flag
                     ,payment_approval
                     ,last_unaccrue_chrg_date
                     ,second_last_unaccrue_chrg_dt
                     ,recon_to_wc
                     ,tmp_request_id
                     ,tmp_creation_date)
               SELECT payment_schedule_id
                     ,staged_dunning_level
                     ,dunning_level_override_date
                     ,last_update_date
                     ,last_updated_by
                     ,creation_date
                     ,created_by
                     ,last_update_login
                     ,due_date
                     ,amount_due_original
                     ,amount_due_remaining
                     ,number_of_due_dates
                     ,status
                     ,invoice_currency_code
                     ,class
                     ,cust_trx_type_id
                     ,customer_id
                     ,customer_site_use_id
                     ,customer_trx_id
                     ,cash_receipt_id
                     ,associated_cash_receipt_id
                     ,term_id
                     ,terms_sequence_number
                     ,gl_date_closed
                     ,actual_date_closed
                     ,discount_date
                     ,amount_line_items_original
                     ,amount_line_items_remaining
                     ,amount_applied
                     ,amount_adjusted
                     ,amount_in_dispute
                     ,amount_credited
                     ,receivables_charges_charged
                     ,receivables_charges_remaining
                     ,freight_original
                     ,freight_remaining
                     ,tax_original
                     ,tax_remaining
                     ,discount_original
                     ,discount_remaining
                     ,discount_taken_earned
                     ,discount_taken_unearned
                     ,in_collection
                     ,cash_applied_id_last
                     ,cash_applied_date_last
                     ,cash_applied_amount_last
                     ,cash_applied_status_last
                     ,cash_gl_date_last
                     ,cash_receipt_id_last
                     ,cash_receipt_date_last
                     ,cash_receipt_amount_last
                     ,cash_receipt_status_last
                     ,exchange_rate_type
                     ,exchange_date
                     ,exchange_rate
                     ,adjustment_id_last
                     ,adjustment_date_last
                     ,adjustment_gl_date_last
                     ,adjustment_amount_last
                     ,follow_up_date_last
                     ,follow_up_code_last
                     ,promise_date_last
                     ,promise_amount_last
                     ,collector_last
                     ,call_date_last
                     ,trx_number
                     ,trx_date
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
                     ,reversed_cash_receipt_id
                     ,amount_adjusted_pending
                     ,attribute11
                     ,attribute12
                     ,attribute13
                     ,attribute14
                     ,attribute15
                     ,gl_date
                     ,acctd_amount_due_remaining
                     ,program_application_id
                     ,program_id
                     ,program_update_date
                     ,receipt_confirmed_flag
                     ,request_id
                     ,selected_for_receipt_batch_id
                     ,last_charge_date
                     ,second_last_charge_date
                     ,dispute_date
                     ,org_id
                     ,global_attribute1
                     ,global_attribute2
                     ,global_attribute3
                     ,global_attribute4
                     ,global_attribute5
                     ,global_attribute6
                     ,global_attribute7
                     ,global_attribute8
                     ,global_attribute9
                     ,global_attribute10
                     ,global_attribute11
                     ,global_attribute12
                     ,global_attribute13
                     ,global_attribute14
                     ,global_attribute15
                     ,global_attribute16
                     ,global_attribute17
                     ,global_attribute18
                     ,global_attribute19
                     ,global_attribute20
                     ,global_attribute_category
                     ,cons_inv_id
                     ,cons_inv_id_rev
                     ,exclude_from_dunning_flag
                     ,mrc_customer_trx_id
                     ,mrc_exchange_rate_type
                     ,mrc_exchange_date
                     ,mrc_exchange_rate
                     ,mrc_acctd_amount_due_remaining
                     ,br_amount_assigned
                     ,reserved_type
                     ,reserved_value
                     ,active_claim_flag
                     ,exclude_from_cons_bill_flag
                     ,payment_approval
                     ,last_unaccrue_chrg_date
                     ,second_last_unaccrue_chrg_dt
                     ,recon_to_wc
                     ,gn_request_id
                     ,gd_creation_date
                 FROM xx_ar_recon_open_itm;
         location_and_log(GC_YES,'          Records inserted into xx_ar_recon_open_itm_tmp  : '||SQL%ROWCOUNT);
         COMMIT;
         
         INSERT INTO xx_ar_recon_trans_stg_tmp
                     (customer_number
                     ,cust_account_id
                     ,customer_site_use_id
                     ,customer_name
                     ,ap_dunning_contact
                     ,collector_id
                     ,collector_name
                     ,org_id
                     ,currency
                     ,trx_number
                     ,open_balance
                     ,type
                     ,cust_trx_id
                     ,cash_receipt_id
                     ,creation_date
                     ,created_by
                     ,request_id  
                     ,tmp_request_id
                     ,tmp_creation_date)
               SELECT customer_number
                     ,cust_account_id
                     ,customer_site_use_id
                     ,customer_name
                     ,ap_dunning_contact
                     ,collector_id
                     ,collector_name
                     ,org_id
                     ,currency
                     ,trx_number
                     ,open_balance
                     ,type
                     ,cust_trx_id
                     ,cash_receipt_id
                     ,creation_date
                     ,created_by
                     ,request_id  
                     ,gn_request_id
                     ,gd_creation_date
                 FROM xx_ar_recon_trans_stg;
         location_and_log(GC_YES,'          Records inserted into xx_ar_recon_trans_stg_tmp : '||SQL%ROWCOUNT);
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS (INSERT) at ' ||gc_error_loc||' .'||SQLERRM);
            RAISE EX_INSERT_TMP_TABLES;
      END;      
      print_time_stamp_to_logfile;

      --========================================================================
      -- Gather Statistics
      --========================================================================
      location_and_log(GC_YES,'     Checking if gathering statistics');
      BEGIN
         IF p_compute_stats = 'Y' THEN
            location_and_log(GC_YES,'     Gathering statistics on temp tables');         
            compute_stat (p_compute_stats, 'XXFIN', 'XX_IEX_DIARY_NOTES_STG_TMP');
            compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_CR_WC_STG_TMP');
            compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_ADJ_WC_STG_TMP');
            compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_PS_WC_STG_TMP');
            compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_RECAPPL_WC_STG_TMP');         
            compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_TRANS_WC_STG_TMP');
            compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_WC_UPD_PS_TMP');
            compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_RECON_OPEN_ITM_TMP');
            compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_RECON_TRANS_STG_TMP');         
            location_and_log(GC_YES,'     Gathering statistics has completed.');         
         ELSE
            location_and_log(GC_YES,'     Statistics were not gathered on tables based on p_compute_stats.');         
         END IF;
      EXCEPTION
         WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS (STATS) at ' ||gc_error_loc||' .'||SQLERRM);
            RAISE EX_GATHER_STATS;
      END;
      print_time_stamp_to_logfile;

   EXCEPTION
      WHEN EX_TRUNCATE_AR_RECON_STG THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_TRUNCATE_AR_RECON_STG at ' ||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_TRUNCATE_AR_STG THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_TRUNCATE_AR_STG at ' ||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INSERT_TMP_TABLES THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_INSERT_TMP_TABLES at ' ||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_GATHER_STATS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_GATHER_STATS at ' ||gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN OTHERS THEN 
         FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS at ' ||gc_error_loc||' .'||SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;
   END copy_staged_recs;

END XX_AR_WC_UTILITY_PKG;
/
SHOW ERRORS
