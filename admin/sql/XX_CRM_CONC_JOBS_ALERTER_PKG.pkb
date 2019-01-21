SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CRM_CONC_JOBS_ALERTER_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_CRM_CONC_JOBS_ALERTER_PKG                                      |
-- |                                                                                |
-- | Description:  This procedure alerts the system about abnormal jobs.            |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 12-Jan-2009 Sarah Maria Justina        Initial draft version           |
-- |1.1      01-Sep-2009 Indra Varada	            Added page on warning logic     |
-- |1.2      19-Nov-2009 Sarah Maria Justina	    Fixed page on warning query     |
-- |1.3      13-Jan-2010 Indra Varada               Changes made to send alerts when|
-- |                                                programs do not run,issue in chg|
-- |                                                1.2 fixed where source_val1 was |
-- |                                                mapped for source_val2          |
-- |1.4      18-Jan-2010 Indra Varada               New Procedure For Reporting     | 
-- +================================================================================+
----------------------------
--Declaring Global Constants
----------------------------


----------------------------
--Declaring Global Variables
----------------------------
-- +====================================================================+
 -- | Name        :  DISPLAY_LOG
 -- | Description :  This procedure is invoked to print in the log file
 -- | Parameters  :  p_message IN VARCHAR2
 -- |                p_optional IN NUMBER
 -- +====================================================================+
   PROCEDURE display_log (p_message IN VARCHAR2)
   IS
   BEGIN
         fnd_file.put_line (fnd_file.LOG, p_message);    
   END display_log;
-- +===========================================================================================================+
-- | Name        :  SEND_MAIL
-- | Description :  This procedure alerts the system about abnormal jobs.
-- | Parameters  :  p_job_short_name  IN VARCHAR2,
-- |                p_phase_code      IN VARCHAR2,
-- |                p_text            IN VARCHAR2,
-- |                p_mail_to         IN VARCHAR2
-- +===========================================================================================================+
PROCEDURE SEND_MAIL(
                       p_job_short_name  IN VARCHAR2,
                       p_request_id      IN NUMBER,
                       p_args            IN VARCHAR2,
                       p_phase_code      IN VARCHAR2,
                       p_text            IN VARCHAR2,
                       p_mail_to         IN VARCHAR2,
                       p_min_time        IN NUMBER,
                       p_max_time        IN NUMBER,
                       p_duration        IN NUMBER,
                       p_start_time      IN DATE,
                       p_criticality     IN VARCHAR2,
                       p_running_state   IN VARCHAR2,
                       p_status          IN VARCHAR2)
   IS
   lc_mailhost             VARCHAR2(64) := FND_PROFILE.VALUE('XX_CS_SMTP_SERVER');
   lc_from                 VARCHAR2(64) := 'CRM_CONVERSIONS@OfficeDepot.com';
   lc_subject              VARCHAR2(64) := 'Concurrent Job Monitor Notification';
   lc_mail_conn            UTL_SMTP.connection;
   lc_instance             VARCHAR2(240);
   lc_job_type             VARCHAR2(40);
   lc_email_options_flag   VARCHAR2(1);
   l_page_on_warning       VARCHAR2(1) := 'Y';

   CURSOR lcu_get_instance_info
   IS
   SELECT name
     FROM v$database;

   CURSOR lcu_get_email_options(p_job_type VARCHAR2) IS
   SELECT enabled_flag
     FROM fnd_lookup_values
    WHERE lookup_type = 'XX_CRM_MONITOR_EMAIL_OPTIONS'
      AND lookup_code = p_job_type;

   CURSOR lcu_get_critical_email_list IS
   SELECT xval.source_value1 email_group,
          xval.target_value1 email_id
    FROM  xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
   WHERE  xdef.translation_name = 'XX_CRM_MAIL_LIST'
     AND  xdef.translate_id = xval.translate_id
     AND  TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1))
     AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1));
     
   
   

   BEGIN
          IF(p_criticality='CRITICAL' AND
             p_running_state IN ('LONG_RUNNING','SHORT_RUNNING')) THEN
   	     lc_job_type := 'CRIT_OUT_OF_BOUNDS';
          ELSIF(p_status IN ('E','G') AND
             p_criticality='CRITICAL' AND
             p_running_state = 'NORMAL_RUNNING') THEN
             lc_job_type := 'CRIT_ABN';
          ELSIF(p_criticality='HIGH' AND
             p_running_state IN ('LONG_RUNNING','SHORT_RUNNING')) THEN
   	     lc_job_type := 'HIGH_OUT_OF_BOUNDS';
          ELSIF(p_status IN ('E','G') AND
             p_criticality='HIGH' AND
             p_running_state = 'NORMAL_RUNNING') THEN
             lc_job_type := 'HIGH_ABN';
          ELSIF(p_criticality='MEDIUM' AND
             p_running_state IN ('LONG_RUNNING','SHORT_RUNNING')) THEN
   	     lc_job_type := 'MED_OUT_OF_BOUNDS';
          ELSIF(p_status IN ('E','G') AND
             p_criticality='MEDIUM' AND
             p_running_state = 'NORMAL_RUNNING') THEN
             lc_job_type := 'MED_ABN';
          ELSIF(p_criticality='LOW' AND
             p_running_state IN ('LONG_RUNNING','SHORT_RUNNING')) THEN
   	     lc_job_type := 'LOW_OUT_OF_BOUNDS';
          ELSIF(p_status IN ('E','G') AND
             p_criticality='LOW' AND
             p_running_state = 'NORMAL_RUNNING') THEN
             lc_job_type := 'LOW_ABN';
          END IF;
   	  OPEN lcu_get_email_options(lc_job_type);
          FETCH lcu_get_email_options INTO lc_email_options_flag;
          CLOSE lcu_get_email_options;


  IF(lc_email_options_flag = 'Y') THEN
        OPEN  lcu_get_instance_info;
	FETCH lcu_get_instance_info into lc_instance;
	CLOSE lcu_get_instance_info;

	lc_mail_conn := UTL_SMTP.open_connection(lc_mailhost, 25);
	UTL_SMTP.helo(lc_mail_conn, lc_mailhost);
	UTL_SMTP.mail(lc_mail_conn, lc_from);
	UTL_SMTP.rcpt(lc_mail_conn, p_mail_to);

	UTL_SMTP.open_data(lc_mail_conn);

	UTL_SMTP.WRITE_DATA(lc_mail_conn,'Date: '  ||TO_CHAR(SYSDATE,'DD MON RRRR hh24:mi:ss')||utl_tcp.CRLF);
	UTL_SMTP.WRITE_DATA(lc_mail_conn,'From: '  ||lc_from||utl_tcp.CRLF);
	UTL_SMTP.WRITE_DATA(lc_mail_conn,'To: '    ||p_mail_to||utl_tcp.CRLF);
        
        IF p_status = 'G' THEN
          SELECT NVL(xval.source_value9,'Y')
          INTO   l_page_on_warning
          FROM  xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
          WHERE  xdef.translation_name = 'XX_CRM_CONC_JOBS_ALERTER'
            AND  xdef.translate_id = xval.translate_id
            AND  TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1))
            AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
            AND xval.source_value2 = p_job_short_name;
        END IF;
     
	IF(p_criticality= 'CRITICAL' AND l_page_on_warning = 'Y') THEN
	  for lt_get_email_list in lcu_get_critical_email_list
	  LOOP
	    UTL_SMTP.WRITE_DATA(lc_mail_conn,'Cc: '    ||lt_get_email_list.email_id||'@OfficeDepot.com'||utl_tcp.CRLF);
	  END LOOP;
	  UTL_SMTP.WRITE_DATA(lc_mail_conn,'Subject:'||'***page***'||lc_subject||utl_tcp.CRLF);
	ELSE
	  UTL_SMTP.WRITE_DATA(lc_mail_conn,'Subject:'||lc_subject||utl_tcp.CRLF);
	END IF;

	UTL_SMTP.WRITE_DATA(lc_mail_conn,utl_tcp.CRLF);
	UTL_SMTP.write_data(lc_mail_conn, 'The Concurrent Job Monitor has found abnormalities with the Job Below: '|| Chr(13));
	UTL_SMTP.write_data(lc_mail_conn, 'Concurrent Job                : '||p_job_short_name|| Chr(13));
	UTL_SMTP.write_data(lc_mail_conn, 'Arguments                     : '||p_args|| Chr(13));
  UTL_SMTP.write_data(lc_mail_conn, 'Request ID                    : '||p_request_id|| Chr(13));
  UTL_SMTP.write_data(lc_mail_conn, 'Status                        : '||p_phase_code|| Chr(13));
	UTL_SMTP.write_data(lc_mail_conn, 'Criticality                   : '||p_criticality|| Chr(13));
	UTL_SMTP.write_data(lc_mail_conn, 'Minimum Threshold Time        : '||p_min_time|| Chr(13));
	UTL_SMTP.write_data(lc_mail_conn, 'Maximum Threshold Time        : '||p_max_time|| Chr(13));
	UTL_SMTP.write_data(lc_mail_conn, 'Program Start Time            : '||TO_CHAR(p_start_time,'DD MON RRRR hh24:mi:ss')|| Chr(13));
	UTL_SMTP.write_data(lc_mail_conn, 'Program Duration              : '||TRUNC(p_duration,3)|| Chr(13));
	UTL_SMTP.write_data(lc_mail_conn, 'Description                   : '||p_text|| Chr(13));
	UTL_SMTP.write_data(lc_mail_conn, 'Mail Sender Instance          : '||lc_instance|| Chr(13));
	UTL_SMTP.close_data(lc_mail_conn);

	UTL_SMTP.quit(lc_mail_conn);
   END IF;
   END SEND_MAIL;
-- +===========================================================================================================+
-- | Name        :  PUSH_INTO_TMP
-- | Description :  This procedure inserts or updates the concurrent program details into a temporary table.
-- | Parameters  :  p_request_id IN NUMBER,
-- |                p_job__short_name IN VARCHAR2,
-- |                p_module_sub_appl IN VARCHAR2,
-- |                p_arg_text IN VARCHAR2,
-- |                p_start_date IN DATE,
-- |                p_time_taken IN NUMBER,
-- |                p_overdue_flag IN CHAR(1),
-- |                p_status_code IN CHAR(1),
-- |                p_phase_code IN CHAR(1)
-- +===========================================================================================================+
   PROCEDURE PUSH_INTO_TMP(p_request_id IN NUMBER,
                           p_job_short_name IN VARCHAR2,
                           p_module_sub_appl IN VARCHAR2,
                           p_arg_text IN VARCHAR2,
                           p_start_date IN DATE,
                           p_time_taken IN NUMBER,
                           p_overdue_flag IN VARCHAR2,
                           p_status_code IN VARCHAR2,
                           p_phase_code IN VARCHAR2,
                           p_description IN VARCHAR2)   
   IS
   ln_count NUMBER;
   BEGIN
   SELECT COUNT(1) 
     INTO ln_count
     FROM XX_CRM_CONC_JOBS_DETAILS
    WHERE REQUEST_ID = p_request_id 
    AND JOB_NAME = p_job_short_name
    AND NVL(ARGUMENT_TEXT,'XX') = NVL(p_arg_text,'XX');
   
   IF(ln_count > 0) THEN
   UPDATE XX_CRM_CONC_JOBS_DETAILS
   SET 
   REQUEST_ID =  p_request_id,
   ARGUMENT_TEXT = p_arg_text,
   DATE_STARTED = p_start_date,
   DURATION = p_time_taken,
   OVERDUE_FLAG =  p_overdue_flag,
   REQUEST_STATUS = p_status_code,
   REQUEST_PHASE = p_phase_code,
   DESCRIPTION =  p_description
   WHERE JOB_NAME= p_job_short_name
   AND   REQUEST_ID = p_request_id
   AND   NVL(ARGUMENT_TEXT,'XX') = NVL(p_arg_text,'XX');
   ELSE
   INSERT INTO XX_CRM_CONC_JOBS_DETAILS
   (REQUEST_ID,
    JOB_NAME,
    MODULE_SUB_APPL,
    ARGUMENT_TEXT,
    DATE_STARTED,
    DURATION,
    OVERDUE_FLAG,
    REQUEST_STATUS,
    REQUEST_PHASE,
    DESCRIPTION)
    VALUES
    (
    p_request_id,
    p_job_short_name,
    p_module_sub_appl,
    p_arg_text,
    p_start_date,
    p_time_taken,
    p_overdue_flag,
    p_status_code,
    p_phase_code,
    p_description
    );
    END IF;
   COMMIT;
   END PUSH_INTO_TMP;   
-- +===========================================================================================================+
-- | Name        :  MAIN
-- | Description :  This procedure alerts the system about abnormal jobs.
-- | Parameters  :  x_errbuf       OUT   VARCHAR2,
-- |                x_retcode      OUT   NUMBER,
-- |                p_module       IN    VARCHAR2,
-- |                p_submodule    IN    VARCHAR2,
-- |                p_application  IN    VARCHAR2 
-- +===========================================================================================================+
   PROCEDURE MAIN (
      x_errbuf       OUT   VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_module       IN    VARCHAR2,
      p_submodule    IN    VARCHAR2,
      p_application  IN    VARCHAR2      
   )
   IS
   ln_request_id           NUMBER;
   lc_status_code          VARCHAR2(1);
   lc_phase_code           VARCHAR2(1);   
   ld_start_date           DATE;
   ld_end_date             DATE;
   lc_text                 VARCHAR2(400);
   ln_time_taken           NUMBER;
   lc_arg_text             VARCHAR2(240);
   ln_workday_type         VARCHAR2(40);
   ln_schedule_name        VARCHAR2(80);
   ln_shift1_start_time    VARCHAR2(10);
   ln_shift1_end_time      VARCHAR2(10);   
   ln_shift2_start_time    VARCHAR2(10);
   ln_shift2_end_time      VARCHAR2(10);    
   ln_shift1_email_list    VARCHAR2(40); 
   ln_shift2_email_list    VARCHAR2(40);  
   ln_workday_count        NUMBER;
   ln_appln_id             VARCHAR2(240):= NULL;
   ln_module_id            VARCHAR2(240):= NULL;
   ln_sub_module_id        VARCHAR2(240):= NULL;  
   ln_request_exists       NUMBER := 0;
   l_job_count             NUMBER := 0;
   l_alert_count	   NUMBER := 0;
   
   EX_INVALID_SHIFT_TIMINGS_SET  EXCEPTION;
   EX_NO_SCHEDULE_DATA_FOUND     EXCEPTION;

   CURSOR lcu_conc_jobs(ln_appln_id VARCHAR2,ln_module_id VARCHAR2,ln_sub_module_id VARCHAR2) is
   SELECT xval.source_value1 job_conc_prog_short_name,
          xval.source_value2 conc_prog_desc,
          xval.source_value3 module,
          xval.source_value4 sub_module,
          xval.source_value5 application,
          xval.source_value6 min_threshold_time,
          xval.source_value7 max_threshold_time,
          xval.source_value8 criticality,
	  xval.source_value3
          || '/'
          || xval.source_value4
          || '/'
          || xval.source_value5 module_sub_appl,
          xval.target_value1 arguments,
          xval.target_value2 frequency,
          xval.target_value3 interval
    FROM  xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
   WHERE  xdef.translation_name = 'XX_CRM_CONC_JOBS_ALERTER'
     AND  xdef.translate_id = xval.translate_id
     AND  TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1))
     AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
     AND NVL(xval.source_value3,'N') = NVL (ln_module_id, NVL(xval.source_value3,'N'))
     AND NVL(xval.source_value4,'N') = NVL (ln_sub_module_id, NVL(xval.source_value4,'N'))
     AND NVL(xval.source_value5,'N') = NVL (ln_appln_id, NVL(xval.source_value5,'N'));
      
   CURSOR lcu_conc_job_details(p_job_short_name VARCHAR2, p_interval NUMBER, p_arguments VARCHAR2) is
   SELECT request_id, status_code, phase_code, actual_start_date,
          actual_completion_date,argument_text
    FROM fnd_concurrent_requests
    WHERE concurrent_program_id =
          (SELECT concurrent_program_id
                        FROM fnd_concurrent_programs
                       WHERE concurrent_program_name = p_job_short_name and enabled_flag='Y')
    AND actual_start_date BETWEEN SYSDATE - (p_interval/1440) AND SYSDATE
    AND DECODE(p_arguments,NULL,1,INSTR(argument_text,p_arguments)) > 0;
                       
   CURSOR lcu_get_work_timings(p_schedule_name VARCHAR2,p_appl VARCHAR2,p_module VARCHAR2,p_sub_module VARCHAR2) IS
   SELECT xval.source_value4 shift1_start_time,
          xval.source_value5 shift1_end_time,
          xval.source_value6 shift1_email_list,
          xval.source_value7 shift2_start_time,
	  xval.source_value8 shift2_end_time,
	  xval.source_value9 shift2_email_list
    FROM  xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
   WHERE  xdef.translation_name = p_schedule_name
     AND  xdef.translate_id = xval.translate_id
     AND  TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1))
     AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
     AND NVL(xval.source_value3,'N') = NVL (p_sub_module, NVL(xval.source_value3,'N'))
     AND NVL(xval.source_value2,'N') = NVL (p_module, NVL(xval.source_value2,'N'))
     AND NVL(xval.source_value1,'N') = NVL (p_appl, NVL(xval.source_value1,'N'));
     
   CURSOR lcu_get_shift(p_shift_start_time VARCHAR2,p_shift_end_time VARCHAR2) IS
   SELECT count(1)
     FROM dual
    WHERE sysdate
  BETWEEN to_date(TO_CHAR(sysdate, 'DD-MON-RRRR') ||' '||p_shift_start_time,'DD-MON-RRRR HH24:MI:SS')
      AND to_date(TO_CHAR(sysdate, 'DD-MON-RRRR') ||' '||p_shift_end_time,'DD-MON-RRRR HH24:MI:SS'); 
      
   BEGIN
     SELECT TO_CHAR (SYSDATE, 'DAY')
       INTO ln_workday_type
     FROM DUAL;
     ln_workday_type := TRIM(ln_workday_type);

     IF(ln_workday_type = 'MONDAY') THEN
       ln_schedule_name := 'XX_CRM_MON_SCHEDULE';
     ELSIF(ln_workday_type = 'TUESDAY') THEN
       ln_schedule_name := 'XX_CRM_TUE_SCHEDULE';
     ELSIF(ln_workday_type = 'WEDNESDAY') THEN
       ln_schedule_name := 'XX_CRM_WED_SCHEDULE';  
     ELSIF(ln_workday_type = 'THURSDAY') THEN
       ln_schedule_name := 'XX_CRM_THU_SCHEDULE'; 
     ELSIF(ln_workday_type = 'FRIDAY') THEN
       ln_schedule_name := 'XX_CRM_FRI_SCHEDULE'; 
     ELSIF(ln_workday_type = 'SATURDAY') THEN
       ln_schedule_name := 'XX_CRM_SAT_SCHEDULE'; 
     ELSIF(ln_workday_type = 'SUNDAY') THEN
       ln_schedule_name := 'XX_CRM_SUN_SCHEDULE';        
     END IF;
   
   IF(p_application IS NOT NULL) THEN
   ln_appln_id := UPPER(TRIM(p_application));
   display_log('ln_appln_id:'||ln_appln_id);
   ELSE
   ln_appln_id := NULL;
   display_log('ln_appln_id IS NULL');
   END IF;
   
   IF(p_module IS NOT NULL) THEN
   ln_module_id := UPPER(TRIM(p_module));
   display_log('ln_module_id:'||ln_module_id);
   ELSE 
   ln_module_id := NULL;
   display_log('ln_module_id IS NULL');   
   END IF;
   
   IF(p_submodule IS NOT NULL) THEN
   ln_sub_module_id := UPPER(TRIM(p_submodule));
   display_log('ln_sub_module_id:'||ln_sub_module_id);
   ELSE 
   ln_sub_module_id := NULL;
   display_log('ln_sub_module_id IS NULL');     
   END IF; 
   


   for lt_conc_jobs in lcu_conc_jobs(ln_appln_id,ln_module_id,ln_sub_module_id)
   LOOP
       BEGIN
       display_log('Conc Job Name:'||lt_conc_jobs.job_conc_prog_short_name);
       
       --------- Deriving Email List Begins ------------------- 

            
       ln_shift1_email_list := NULL;
       ln_shift2_email_list := NULL;
       ln_shift1_start_time := NULL;
       ln_shift2_start_time := NULL;
       ln_shift1_end_time := NULL;
       ln_shift2_end_time := NULL;
       OPEN lcu_get_work_timings(ln_schedule_name,lt_conc_jobs.application,lt_conc_jobs.module, lt_conc_jobs.sub_module);
       FETCH lcu_get_work_timings into ln_shift1_start_time,ln_shift1_end_time,ln_shift1_email_list,ln_shift2_start_time,ln_shift2_end_time,ln_shift2_email_list;
       CLOSE lcu_get_work_timings; 
 
       IF (ln_shift1_email_list IS NULL OR 
           ln_shift2_email_list IS NULL OR
           ln_shift1_start_time IS NULL OR
           ln_shift2_start_time IS NULL OR
           ln_shift1_end_time IS NULL OR
           ln_shift2_end_time IS NULL) THEN  
         RAISE EX_NO_SCHEDULE_DATA_FOUND;
       ELSE 
         display_log('Work Timings for Conc Job: '||lt_conc_jobs.conc_prog_desc||' exist');     
       END IF;

       BEGIN
	       OPEN lcu_get_shift(ln_shift1_start_time,ln_shift1_end_time);
	       FETCH lcu_get_shift INTO ln_workday_count;
	       CLOSE lcu_get_shift;
	     EXCEPTION
	     WHEN OTHERS THEN 
	         RAISE EX_INVALID_SHIFT_TIMINGS_SET;
       END;

       --------- Deriving Email List Begins ------------------- 



       l_job_count := 0;
       l_alert_count := 0;
       lc_text := NULL;

       SELECT COUNT(1) INTO l_alert_count
       FROM XX_CRM_CONC_JOBS_DETAILS
       WHERE request_id = -55555 
       AND JOB_NAME = lt_conc_jobs.job_conc_prog_short_name
       AND NVL(ARGUMENT_TEXT,'XX') = NVL(lt_conc_jobs.arguments,'XX')
       AND MODULE_SUB_APPL = lt_conc_jobs.module_sub_appl
       AND DATE_STARTED BETWEEN SYSDATE - (lt_conc_jobs.interval/1440) AND SYSDATE;

      IF l_alert_count = 0 THEN
      
       SELECT COUNT(1) INTO l_job_count
       FROM fnd_concurrent_requests
       WHERE concurrent_program_id =
             (SELECT concurrent_program_id
                        FROM fnd_concurrent_programs
                       WHERE concurrent_program_name = lt_conc_jobs.job_conc_prog_short_name and enabled_flag='Y')
       AND actual_start_Date BETWEEN SYSDATE - (lt_conc_jobs.interval/1440) AND SYSDATE
       AND DECODE(lt_conc_jobs.arguments,NULL,1,INSTR(argument_text,lt_conc_jobs.arguments)) > 0;

      IF  lt_conc_jobs.frequency <= l_job_count THEN
          display_log('All The Jobs For the program:' || lt_conc_jobs.job_conc_prog_short_name || ' have been successfully executed');
      ELSE
         PUSH_INTO_TMP
            (-55555,
             lt_conc_jobs.job_conc_prog_short_name,
             lt_conc_jobs.module_sub_appl,
             lt_conc_jobs.arguments,
             SYSDATE,
             NULL,
             NULL,
             NULL,
             NULL,
             lt_conc_jobs.conc_prog_desc);
         lc_text := 'The Program As Per Setup Should Run ' || lt_conc_jobs.frequency || ' times in ' || lt_conc_jobs.interval || ' Mins but it Ran Only ' || l_job_count || ' times';
         IF(ln_workday_count=1) THEN
           SEND_MAIL(lt_conc_jobs.conc_prog_desc,-55555,lt_conc_jobs.arguments,'Did Not Run',lc_text,ln_shift1_email_list||'@OfficeDepot.com',0,0,0,NULL,lt_conc_jobs.criticality,'SHORT_RUNNING',NULL);
         ELSE
           SEND_MAIL(lt_conc_jobs.conc_prog_desc,-55555,lt_conc_jobs.arguments,'Did Not Run',lc_text,ln_shift2_email_list||'@OfficeDepot.com',0,0,0,NULL,lt_conc_jobs.criticality,'SHORT_RUNNING',NULL);
         END IF; 
      END IF; 
      END IF;

      FOR l_conc_job_details IN lcu_conc_job_details(lt_conc_jobs.job_conc_prog_short_name,lt_conc_jobs.interval,lt_conc_jobs.arguments)
      LOOP
       lc_text := NULL;
       ln_request_exists := 0;
       display_log('Conc Job ln_request_id: '||l_conc_job_details.request_id||' ');
       BEGIN
       
       SELECT COUNT(1) 
         INTO ln_request_exists
         FROM XX_CRM_CONC_JOBS_DETAILS
        WHERE request_id = l_conc_job_details.request_id;
        display_log('Conc Job ln_request_id: NOT NULL');
        display_log('Conc Job ln_request_id: '||ln_request_exists||' ');

              
       IF(l_conc_job_details.phase_code='C') THEN
          ln_time_taken := (l_conc_job_details.actual_completion_date - l_conc_job_details.actual_start_date)*24*60;          
          IF(ln_time_taken<lt_conc_jobs.min_threshold_time) THEN
            IF(l_conc_job_details.status_code = 'E') THEN
              lc_text := 'Time taken is below the Minimum Threshold specified. Completed in Error';
            ELSIF(l_conc_job_details.status_code = 'G') THEN
              lc_text := 'Time taken is below the Minimum Threshold specified. Completed in Warning';
            ELSIF(l_conc_job_details.status_code = 'X') THEN
              lc_text := 'Time taken is below the Minimum Threshold specified. Completed by Termination';              
            ELSIF(l_conc_job_details.status_code = 'C') THEN
              lc_text := 'Time taken is below the Minimum Threshold specified. Completed Normally';  
            END IF;
            
            
            display_log('l_conc_job_details.phase_code C lc_status_code E:');     
            IF(ln_workday_count=1) THEN
              display_log('ln_workday_count = 1');
              IF(ln_request_exists = 0) THEN
              display_log('ln_request_exists <> 0 and ln_shift1_email_list:'||ln_shift1_email_list);
              SEND_MAIL(lt_conc_jobs.conc_prog_desc,l_conc_job_details.request_id,l_conc_job_details.argument_text,'Completed',lc_text,ln_shift1_email_list||'@OfficeDepot.com',lt_conc_jobs.min_threshold_time,lt_conc_jobs.max_threshold_time,ln_time_taken,l_conc_job_details.actual_start_date,lt_conc_jobs.criticality,'SHORT_RUNNING',l_conc_job_details.status_code);
              END IF;
            ELSE     
              IF(ln_request_exists = 0) THEN
              display_log('ln_request_exists <> 0 and ln_shift2_email_list:'||ln_shift2_email_list);
              SEND_MAIL(lt_conc_jobs.conc_prog_desc,l_conc_job_details.request_id,l_conc_job_details.argument_text,'Completed',lc_text,ln_shift2_email_list||'@OfficeDepot.com',lt_conc_jobs.min_threshold_time,lt_conc_jobs.max_threshold_time,ln_time_taken,l_conc_job_details.actual_start_date,lt_conc_jobs.criticality,'SHORT_RUNNING',l_conc_job_details.status_code);
              END IF;
            END IF;
            PUSH_INTO_TMP
            (l_conc_job_details.request_id,
             lt_conc_jobs.job_conc_prog_short_name,
             lt_conc_jobs.module_sub_appl,
             l_conc_job_details.argument_text,
             l_conc_job_details.actual_start_date,
             ln_time_taken,
             'U',
             l_conc_job_details.status_code,
             l_conc_job_details.phase_code,
             lt_conc_jobs.conc_prog_desc);
          ELSIF(ln_time_taken>lt_conc_jobs.max_threshold_time) THEN
            IF(l_conc_job_details.status_code = 'E') THEN
              lc_text := 'Time taken is above the Maximum Threshold specified. Completed in Error';
            ELSIF(l_conc_job_details.status_code = 'G') THEN
              lc_text := 'Time taken is above the Maximum Threshold specified. Completed in Warning';
            ELSIF(l_conc_job_details.status_code = 'X') THEN
              lc_text := 'Time taken is above the Maximum Threshold specified. Completed by Termination';               
            ELSIF(l_conc_job_details.status_code = 'C') THEN
              lc_text := 'Time taken is above the Maximum Threshold specified. Completed Normally';  
            END IF;
            
            IF(ln_workday_count=1) THEN
             IF(ln_request_exists = 0) THEN
             SEND_MAIL(lt_conc_jobs.conc_prog_desc,l_conc_job_details.request_id,l_conc_job_details.argument_text,'Completed',lc_text,ln_shift1_email_list||'@OfficeDepot.com',lt_conc_jobs.min_threshold_time,lt_conc_jobs.max_threshold_time,ln_time_taken,l_conc_job_details.actual_start_date,lt_conc_jobs.criticality,'LONG_RUNNING',l_conc_job_details.status_code);
             END IF;
            ELSE
             IF(ln_request_exists = 0) THEN
             SEND_MAIL(lt_conc_jobs.conc_prog_desc,l_conc_job_details.request_id,l_conc_job_details.argument_text,'Completed',lc_text,ln_shift2_email_list||'@OfficeDepot.com',lt_conc_jobs.min_threshold_time,lt_conc_jobs.max_threshold_time,ln_time_taken,l_conc_job_details.actual_start_date,lt_conc_jobs.criticality,'LONG_RUNNING',l_conc_job_details.status_code);            
             END IF;
            END IF;
            PUSH_INTO_TMP
            (l_conc_job_details.request_id,
             lt_conc_jobs.job_conc_prog_short_name,
             lt_conc_jobs.module_sub_appl,
             l_conc_job_details.argument_text,
             l_conc_job_details.actual_start_date,
             ln_time_taken,
             'Y',
             l_conc_job_details.status_code,
             l_conc_job_details.phase_code,
             lt_conc_jobs.conc_prog_desc); 
          ELSIF(ln_time_taken<=lt_conc_jobs.max_threshold_time AND ln_time_taken>=lt_conc_jobs.min_threshold_time) THEN
	    IF(l_conc_job_details.status_code IN ('E','G','X')) THEN
	    
		IF(l_conc_job_details.status_code = 'E') THEN
		  lc_text := 'Time taken is within the Minimum and Maximum Thresholds specified. Completed in Error';
		ELSIF(l_conc_job_details.status_code = 'X') THEN
		  lc_text := 'Time taken is within the Minimum and Maximum Thresholds specified. Completed by Termination'; 		  
		ELSIF(l_conc_job_details.status_code = 'G') THEN
		  lc_text := 'Time taken is within the Minimum and Maximum Thresholds specified. Completed in Warning';  
	        END IF;
	    
            IF(ln_workday_count=1) THEN
             IF(ln_request_exists = 0) THEN
             SEND_MAIL(lt_conc_jobs.conc_prog_desc,l_conc_job_details.request_id,l_conc_job_details.argument_text,'Completed',lc_text,ln_shift1_email_list||'@OfficeDepot.com',lt_conc_jobs.min_threshold_time,lt_conc_jobs.max_threshold_time,ln_time_taken,l_conc_job_details.actual_start_date,lt_conc_jobs.criticality,'NORMAL_RUNNING',l_conc_job_details.status_code);
             END IF;
            ELSE
             IF(ln_request_exists = 0) THEN
             SEND_MAIL(lt_conc_jobs.conc_prog_desc,l_conc_job_details.request_id,l_conc_job_details.argument_text,'Completed',lc_text,ln_shift2_email_list||'@OfficeDepot.com',lt_conc_jobs.min_threshold_time,lt_conc_jobs.max_threshold_time,ln_time_taken,l_conc_job_details.actual_start_date,lt_conc_jobs.criticality,'NORMAL_RUNNING',l_conc_job_details.status_code);            
             END IF;
            END IF;
            PUSH_INTO_TMP
            (l_conc_job_details.request_id,
             lt_conc_jobs.job_conc_prog_short_name,
             lt_conc_jobs.module_sub_appl,
             l_conc_job_details.argument_text,
             l_conc_job_details.actual_start_date,
             ln_time_taken,
             'N',
             l_conc_job_details.status_code,
             l_conc_job_details.phase_code,
             lt_conc_jobs.conc_prog_desc); 	    
	    END IF;      
          END IF;
       ELSIF(l_conc_job_details.phase_code='R') THEN
          ln_time_taken := (sysdate - l_conc_job_details.actual_start_date)*24*60;
          IF(ln_time_taken>lt_conc_jobs.max_threshold_time) THEN
            lc_text := 'Time taken is above the Maximum Threshold specified.';
            
            IF(ln_workday_count=1) THEN
              IF(ln_request_exists = 0) THEN
	      SEND_MAIL(lt_conc_jobs.conc_prog_desc,l_conc_job_details.request_id,l_conc_job_details.argument_text,'Running',lc_text,ln_shift1_email_list||'@OfficeDepot.com',lt_conc_jobs.min_threshold_time,lt_conc_jobs.max_threshold_time,ln_time_taken,l_conc_job_details.actual_start_date,lt_conc_jobs.criticality,'LONG_RUNNING',l_conc_job_details.status_code);
	      END IF;
	    ELSE
	      IF(ln_request_exists = 0) THEN
	      SEND_MAIL(lt_conc_jobs.conc_prog_desc,l_conc_job_details.request_id,l_conc_job_details.argument_text,'Running',lc_text,ln_shift2_email_list||'@OfficeDepot.com',lt_conc_jobs.min_threshold_time,lt_conc_jobs.max_threshold_time,ln_time_taken,l_conc_job_details.actual_start_date,lt_conc_jobs.criticality,'LONG_RUNNING',l_conc_job_details.status_code);	    
              END IF;
            END IF;
            
            PUSH_INTO_TMP
            (l_conc_job_details.request_id,
             lt_conc_jobs.job_conc_prog_short_name,
             lt_conc_jobs.module_sub_appl,
             l_conc_job_details.argument_text,
             l_conc_job_details.actual_start_date,
             ln_time_taken,
             'Y',
             l_conc_job_details.status_code,
             l_conc_job_details.phase_code,
             lt_conc_jobs.conc_prog_desc);	    
          END IF;
        END IF;
         END;
       END LOOP;
       EXCEPTION WHEN EX_NO_SCHEDULE_DATA_FOUND THEN
         ROLLBACK;
         x_retcode := 1;
         x_errbuf  := 'Procedure: MAIN: There are no Shift Timings available for some of the Conc Jobs';
         display_log('There are no Shift Timings available for the Conc Job:'||lt_conc_jobs.conc_prog_desc);
       END;
   END LOOP;
   EXCEPTION
     WHEN EX_INVALID_SHIFT_TIMINGS_SET THEN
       ROLLBACK;
       x_retcode := 2;
       x_errbuf  := 'Procedure: MAIN: The Shift Timings are set to an invalid value. They must be set in the format HH:MI:SS';
   END MAIN;

 PROCEDURE job_report (
      x_errbuf       OUT   VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_module       IN    VARCHAR2,
      p_submodule    IN    VARCHAR2,
      p_application  IN    VARCHAR2,
      p_rep_period   IN    NUMBER,
      p_mail_to      IN    VARCHAR2
   )
AS

lc_mailhost             VARCHAR2(64) := FND_PROFILE.VALUE('XX_CS_SMTP_SERVER');
lc_from                 VARCHAR2(64) := 'CRM_CONVERSIONS@OfficeDepot.com';
lc_subject              VARCHAR2(64) := 'Concurrent Job Monitor Notification';
lc_mail_conn            UTL_SMTP.connection;
lc_instance             VARCHAR2(240);
   
CURSOR job_details
IS
SELECT cj.request_id,
       cj.description,
       cj.argument_text,
       cj.date_started,
       cj.request_status,
       cj.request_phase,
       cj.overdue_flag,
       cj.duration
FROM  XX_CRM_CONC_JOBS_DETAILS cj
WHERE  cj.module_sub_appl = p_module
          || '/'
          || p_submodule
          || '/'
          || p_application
AND  DATE_STARTED BETWEEN SYSDATE - (p_rep_period/24) AND SYSDATE
ORDER BY DATE_STARTED DESC;

BEGIN
  
  fnd_file.put_line(fnd_file.log,'Parameter Text:'|| p_module
          || '/'
          || p_submodule
          || '/'
          || p_application);
          
  fnd_file.put_line(fnd_file.log,'Sending Email............');
  
     SELECT name INTO lc_instance
     FROM v$database;
     
  lc_mail_conn := UTL_SMTP.open_connection(lc_mailhost, 25);
	UTL_SMTP.helo(lc_mail_conn, lc_mailhost);
	UTL_SMTP.mail(lc_mail_conn, lc_from);
	UTL_SMTP.rcpt(lc_mail_conn, p_mail_to);

	UTL_SMTP.open_data(lc_mail_conn);

	UTL_SMTP.WRITE_DATA(lc_mail_conn,'Date: '  ||TO_CHAR(SYSDATE,'DD MON RRRR hh24:mi:ss')||utl_tcp.CRLF);
	UTL_SMTP.WRITE_DATA(lc_mail_conn,'From: '  ||lc_from||utl_tcp.CRLF);
	UTL_SMTP.WRITE_DATA(lc_mail_conn,'To: '    ||p_mail_to||utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'Subject:'||lc_instance || ':' || lc_subject||utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,Chr(10));
  UTL_SMTP.WRITE_DATA(lc_mail_conn,Chr(10));
  FOR l_job IN job_details LOOP
      IF l_job.request_id <> -55555 THEN
         UTL_SMTP.WRITE_DATA(lc_mail_conn,'Job Request ID:' || l_job.request_id||Chr(10));
      END IF;
      
      UTL_SMTP.WRITE_DATA(lc_mail_conn,'Job Description:' || l_job.description || ' ' ||Chr(10));
      UTL_SMTP.WRITE_DATA(lc_mail_conn,'Argument Text:' || l_job.argument_text|| Chr(10));
      
    IF l_job.request_id <> -55555 THEN
        UTL_SMTP.WRITE_DATA(lc_mail_conn,'Date Started:' || l_job.date_started|| Chr(10));
        
      IF l_job.overdue_flag = 'Y' THEN
        UTL_SMTP.WRITE_DATA(lc_mail_conn,'Run Time:'|| 'Job Run Time Is Above the Specified Threshold'|| Chr(10));
      ELSIF l_job.overdue_flag = 'U' THEN
        UTL_SMTP.WRITE_DATA(lc_mail_conn,'Run Time:'|| 'Job Run Time is Below the Specified Threshold'|| Chr(10));
      ELSE
        UTL_SMTP.WRITE_DATA(lc_mail_conn,'Run Time:'|| 'Job Ran On Time'|| Chr(10));
      END IF;
      
      IF l_job.request_phase = 'C' THEN
         IF l_job.request_status = 'E' THEN
             UTL_SMTP.WRITE_DATA(lc_mail_conn,'Job Status:'|| 'Request Completed with Error'|| Chr(10));
         ELSIF l_job.request_status = 'G' THEN
             UTL_SMTP.WRITE_DATA(lc_mail_conn,'Job Status:'|| 'Request Completed with Warning'|| Chr(10));
         ELSIF l_job.request_status = 'C' THEN
             UTL_SMTP.WRITE_DATA(lc_mail_conn,'Job Status:'|| 'Request Completed Normal'|| Chr(10));
         ELSIF l_job.request_status = 'X' THEN
             UTL_SMTP.WRITE_DATA(lc_mail_conn,'Job Status:'|| 'Request has been Terminated'|| Chr(10));
         END IF;
      ELSE
         UTL_SMTP.WRITE_DATA(lc_mail_conn,'Job Status:'|| 'Request Is Still Running'|| Chr(10));
      END IF;
   ELSE
      UTL_SMTP.WRITE_DATA(lc_mail_conn,'Job Status:'|| 'Job Did Not Run Expected Number Of Times'|| Chr(10));
   END IF;
    UTL_SMTP.WRITE_DATA(lc_mail_conn,Chr(10));
    UTL_SMTP.WRITE_DATA(lc_mail_conn,Chr(10));
  END LOOP;
  
  UTL_SMTP.close_data(lc_mail_conn);

	UTL_SMTP.quit(lc_mail_conn);
  
  fnd_file.put_line(fnd_file.log,'Email Sent Successfully');
   
EXCEPTION WHEN OTHERS THEN
  x_retcode := 2;
  x_errbuf  := 'Unexpected Error In Procedure job_report:' || SQLERRM;
END job_report;

END XX_CRM_CONC_JOBS_ALERTER_PKG;
/

SHOW ERRORS
EXIT;
