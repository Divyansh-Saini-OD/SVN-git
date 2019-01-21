SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_BPEL_EXTRACT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_BPEL_EXTRACT_PKG.pkb                        |
-- | Description :  To Control BPEL Extrat Start/Stop During EBIZ      |
-- |                DownTimes.                                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  26-Jan-2009 Indra Varada       Initial draft version     |
-- |1.1       15-Jan-2010 Indra Varada       Automation logic to handle| 
-- |                                         downtimes.                |
-- |                                                                   |
-- |1.2       04-May-2010 Indra Varada       logic modified to start   |
-- |                                         BPEL immediately          |
-- |1.3       18-Nov-2015 Manikant Kasu      Removed schema alias as   |
-- |                                         part of GSCC R12.2.2      |
-- |                                         Retrofit                  |
-- +===================================================================+

AS

PROCEDURE get_downtime_start_date 
( p_downtime_start_date  OUT    DATE,
  p_downtime_end_date    OUT    DATE,
  p_mail_address         OUT    VARCHAR2
);

PROCEDURE send_mail (
    p_bpel_off_req_id            NUMBER,
    p_downtime_start_date        DATE,
    p_bpel_on_req_id             NUMBER,
    p_downtime_end_date          DATE,
    p_bpel_alerts_off_req_id     NUMBER,
    p_alert_off_date             DATE,
    p_bpel_alerts_on_req_id      NUMBER,
    p_alert_on_date              DATE,
    p_alerts_req_id              NUMBER,
    p_extract_time_set_req_id    NUMBER,
    p_prog_run_date              DATE,
    p_extract_start_date         DATE,
    p_mail_to                    VARCHAR2,
    x_ret_status                 OUT NOCOPY VARCHAR2,
    x_ret_error_code             OUT NOCOPY VARCHAR2
  ) AS

lc_mailhost             VARCHAR2(64) := FND_PROFILE.VALUE('XX_CS_SMTP_SERVER');
lc_from                 VARCHAR2(64) := 'CRM_ENV_DOWNTIME@OfficeDepot.com';
lc_subject              VARCHAR2(64) := 'CRM EBIZ Down Time Notification';
lc_mail_conn            UTL_SMTP.connection;
lc_instance             VARCHAR2(240) := '';

BEGIN
   
     x_ret_status := 'S';
  
  IF p_mail_to IS NOT NULL THEN
     
     BEGIN
      SELECT name INTO lc_instance
      FROM v$database;
     EXCEPTION WHEN OTHERS THEN
       NULL;
     END;
     
     lc_subject := lc_instance || ':' || lc_subject;
  
     
  lc_mail_conn := UTL_SMTP.open_connection(lc_mailhost, 25);
	UTL_SMTP.helo(lc_mail_conn, lc_mailhost);
	UTL_SMTP.mail(lc_mail_conn, lc_from);
	UTL_SMTP.rcpt(lc_mail_conn, p_mail_to);
	UTL_SMTP.open_data(lc_mail_conn);
  
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'Date: '  ||TO_CHAR(SYSDATE,'DD MON RRRR hh24:mi:ss')||utl_tcp.CRLF);
	UTL_SMTP.WRITE_DATA(lc_mail_conn,'From: '  ||lc_from||utl_tcp.CRLF);
	UTL_SMTP.WRITE_DATA(lc_mail_conn,'To: '    ||p_mail_to||utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'Subject:'||lc_subject||utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'EBIZ DownTime Window - '  ||TO_CHAR(p_downtime_start_date + 1/24,'DD-MON-RRRR hh24:mi:ss') || ' To ' ||TO_CHAR(p_downtime_end_date - 1/24,'DD-MON-RRRR hh24:mi:ss') ||utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'Below Programs Have Been Scheduled To Run Under User - ''ODCDH'' and Responsibility - ''OD(US) Customer Conversion'' ');
  UTL_SMTP.WRITE_DATA(lc_mail_conn,utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'- Turn OFF BPEL at ' || TO_CHAR(p_downtime_start_date,'DD-MON-RRRR hh24:mi:ss') ||  ' (Request ID:' || p_bpel_off_req_id || ')' ||utl_tcp.CRLF );
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'- BPEL Would Be Turned ON Immediately Once the Environment is Up, Request ID:' || p_bpel_on_req_id ||utl_tcp.CRLF );
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'- Turn OFF BPEL Alerts at ' || TO_CHAR(p_alert_off_date,'DD-MON-RRRR hh24:mi:ss') ||  ' (Request ID:' || p_bpel_alerts_off_req_id || ')' ||utl_tcp.CRLF );
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'- Turn ON BPEL Alerts at ' || TO_CHAR(p_alert_on_date,'DD-MON-RRRR hh24:mi:ss') ||  ' (Request ID:' || p_bpel_alerts_on_req_id || ')' ||utl_tcp.CRLF );
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'- Concurrent program Alerts are turned OFF and will be turned back on at:' || TO_CHAR(p_downtime_end_date + 11/24,'DD-MON-RRRR hh24:mi:ss') || ', Request ID:' || p_alerts_req_id ||utl_tcp.CRLF );   
  UTL_SMTP.WRITE_DATA(lc_mail_conn,utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,utl_tcp.CRLF);
  UTL_SMTP.WRITE_DATA(lc_mail_conn,'**** Note : The ESP Schedule would automatically be adjusted based on the downtime ****');
  UTL_SMTP.close_data(lc_mail_conn);
	UTL_SMTP.quit(lc_mail_conn); 
 
 END IF;

EXCEPTION WHEN OTHERS THEN
 x_ret_status := 'E';
 x_ret_error_code := SQLERRM;
END;

PROCEDURE bpel_extract_main (
    x_errbuf             OUT NOCOPY VARCHAR2,
    x_retcode            OUT NOCOPY VARCHAR2
  ) AS
  
l_downtime_start_date         DATE;
l_downtime_end_date           DATE;
l_bpel_start_val              DATE;
l_user_id                     NUMBER;
l_resp_id                     NUMBER;
l_resp_appl_id                NUMBER;
l_alert_off_date              DATE;
l_alert_on_date               DATE;
l_prog_run_date               DATE;
l_extract_start_date          DATE;
l_conc_alerts_on_date         DATE;
l_alerts_req_id               NUMBER :=0;
lt_bpel_off_req_id            NUMBER :=0;
lt_bpel_on_req_id             NUMBER :=0;
lt_bpel_alerts_off_req_id     NUMBER :=0;
lt_bpel_alerts_on_req_id      NUMBER :=0;
lt_extract_time_set_req_id    NUMBER :=0;
x_mail_ret_status             VARCHAR2(1);
x_mail_ret_error_code         VARCHAR2(2000);
l_mail_to                     VARCHAR2(2000);
l_downtime_lag                VARCHAR2(64);
l_alert_req_id                NUMBER :=0; 
l_alert_req_status            BOOLEAN := FALSE;
l_repeat_option_stat          BOOLEAN := TRUE;
l_alert_msg                   VARCHAR2(2000);
 
BEGIN
    get_downtime_start_date
    (
     l_downtime_start_date,
     l_downtime_end_date,
     l_mail_to
    );
    

    l_downtime_lag   := NVL(FND_PROFILE.VALUE('XX_CDH_ENV_DOWN_TIME_LAG'),60);


 fnd_file.put_line (fnd_file.log, 'Down Time Start Date: ' || TO_CHAR(l_downtime_start_date, 'DD-MON-YYYY HH24:MI:SS'));
 fnd_file.put_line (fnd_file.log, 'Down Time End Date:   ' || TO_CHAR(l_downtime_end_date, 'DD-MON-YYYY HH24:MI:SS'));

 IF l_downtime_start_date IS NOT NULL AND l_downtime_end_date IS NOT NULL AND (l_downtime_start_date BETWEEN SYSDATE AND SYSDATE+1/2) THEN
     
     BEGIN
           SELECT user_id INTO l_user_id
           FROM FND_USER
           WHERE user_name = 'ODCDH';
         
           SELECT responsibility_id,application_id INTO l_resp_id,l_resp_appl_id
           FROM fnd_responsibility_vl
           WHERE responsibility_name = 'OD (US) Customer Conversion';
           
          FND_GLOBAL.APPS_INITIALIZE( l_user_id , l_resp_id , l_resp_appl_id);

          fnd_file.put_line(fnd_file.log,'Application Context Switched to ODCDH'); 
 
    EXCEPTION WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Application Context Could Not be Switched to ODCDH');
     END; 

     
     l_bpel_start_val := l_downtime_start_date + (l_downtime_lag/1440);

     l_conc_alerts_on_date   :=  l_downtime_end_date + 1/2;

     l_downtime_start_date   := l_downtime_start_date  - 1/24;
     l_downtime_end_date     := l_downtime_end_date    + 1/24;

     --- STEP - 1 : TURN OFF BPEL ----------
     
     lt_bpel_off_req_id := FND_REQUEST.submit_request
                                          (   application => 'XXCNV',
                                              program     => 'XX_CDH_RAISE_BE',
                                              description => NULL,
                                              start_time  => TO_CHAR(l_downtime_start_date, 'DD-MON-YYYY HH24:MI:SS'),
                                              sub_request => FALSE,
                                              argument1   => 'od.cdh.aops.jobs.pub',
                                              argument2   => 'code/action/parm1',
                                              argument3   => 'EXT/E/$XX_CDH_AOPS_LIB_REF'
                                          );
     IF lt_bpel_off_req_id = 0 THEN
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_RAISE_BE To Stop BPEL Extract Failed and Request To Start BPEL Extract Not Submitted');
     ELSE        
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_RAISE_BE To Stop BPEL Extract Successfully Submitted, Request ID: ' || lt_bpel_off_req_id);
        
     
     --- STEP - 2 : TURN ON BPEL ----------

           

           lt_bpel_on_req_id  := FND_REQUEST.submit_request
                                          (   application => 'XXCNV',
                                              program     => 'XX_CDH_RAISE_BE',
                                              description => NULL,
                                              start_time  => TO_CHAR(l_bpel_start_val, 'DD-MON-YYYY HH24:MI:SS'),
                                              sub_request => FALSE,
                                              argument1   => 'od.cdh.aops.jobs.pub',
                                              argument2   => 'code/action/parm1',
                                              argument3   => 'EXT/B/$XX_CDH_AOPS_LIB_REF'
                                          ); 
      IF lt_bpel_on_req_id = 0 THEN
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_RAISE_BE To Start BPEL Extract Failed, BPEL has to be Manually Started After DownTime');
      ELSE
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_RAISE_BE To Start BPEL Extract Successfully Submitted, Request ID: ' || lt_bpel_on_req_id);
      END IF;

     --- STEP - 3 : TURN OFF BPEL ALERTS ---------
   
      l_alert_off_date   := l_downtime_start_date - 1/48;

      lt_bpel_alerts_off_req_id := FND_REQUEST.submit_request
                                          (   application => 'XXCRM',
                                              program     => 'XX_CDH_SETUP_UPDATE',
                                              description => NULL,
                                              start_time  => TO_CHAR(l_alert_off_date, 'DD-MON-YYYY HH24:MI:SS'),
                                              sub_request => FALSE,
                                              argument1   => 'XXOD_CDH_BPEL_EMAIL_ALERT',
                                              argument2   => 'N',
                                              argument3   => 'SITE',
                                              argument4   => NULL,
                                              argument5   => NULL,
                                              argument6   => NULL,
                                              argument7   => NULL,
                                              argument8   => 'Y'
					                                );
                                          
     IF lt_bpel_alerts_off_req_id = 0 THEN
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_SETUP_UPDATE to Turn OFF BPEL Alerts Could Not Be Submitted');
     ELSE
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_SETUP_UPDATE to Turn OFF BPEL Alerts Successfully Submitted, Request ID: ' || lt_bpel_alerts_off_req_id);
     END IF;

    --- STEP - 4 : TURN ON BPEL ALERTS ---------
       
      l_alert_on_date   := l_downtime_end_date + 1/16;

      lt_bpel_alerts_on_req_id := FND_REQUEST.submit_request
                                          (   application => 'XXCRM',
                                              program     => 'XX_CDH_SETUP_UPDATE',
                                              description => NULL,
                                              start_time  => TO_CHAR(l_alert_on_date, 'DD-MON-YYYY HH24:MI:SS'),
                                              sub_request => FALSE,
                                              argument1   => 'XXOD_CDH_BPEL_EMAIL_ALERT',
                                              argument2   => 'Y',
                                              argument3   => 'SITE',
                                              argument4   => NULL,
                                              argument5   => NULL,
                                              argument6   => NULL,
                                              argument7   => NULL,
                                              argument8   => 'Y'
					                                 ); 
     IF lt_bpel_alerts_on_req_id = 0 THEN
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_SETUP_UPDATE to Turn ON BPEL Alerts Could Not Be Submitted');
     ELSE
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_SETUP_UPDATE to Turn ON BPEL Alerts Successfully Submitted, Request ID: ' || lt_bpel_alerts_on_req_id);
     END IF;


 /*   --- STEP - 5 : SET BPEL Extract Start Time ---------
       
      l_prog_run_date      := l_downtime_end_date - 1/96;
      l_extract_start_date := l_downtime_start_date - 1/96;

      lt_extract_time_set_req_id := FND_REQUEST.submit_request
                                          (   application => 'XXCRM',
                                              program     => 'XX_CDH_SETUP_UPDATE',
                                              description => NULL,
                                              start_time  => TO_CHAR(l_prog_run_date, 'DD-MON-YYYY HH24:MI:SS'),
                                              sub_request => FALSE,
                                              argument1   => 'XX_CDH_BPEL_EXTRACT_START_TIME',
                                              argument2   => TO_CHAR(l_extract_start_date, 'MM/DD/YYYY HH24:MI:SS'),
                                              argument3   => 'SITE',
                                              argument4   => NULL,
                                              argument5   => NULL,
                                              argument6   => NULL,
                                              argument7   => NULL,
                                              argument8   => 'Y'
					                                 ); 
                                           
     IF lt_extract_time_set_req_id = 0 THEN
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_SETUP_UPDATE to Turn ON BPEL Alerts Could Not Be Submitted');
     ELSE
        fnd_file.put_line (fnd_file.log, 'Request XX_CDH_SETUP_UPDATE to Turn ON BPEL Alerts Successfully Submitted, Request ID: ' || lt_extract_time_set_req_id);
     END IF;
     */

    END IF;

    -- STEP - 6 : Turn OFF Concurrent Program Alerter Job 
    

    	select max(request_id) into l_alert_req_id from fnd_concurrent_requests
	where concurrent_program_id in
	(
	select concurrent_program_id from fnd_concurrent_programs_vl 
	where concurrent_program_name ='XX_CRM_CONC_JOBS_ALERTER' AND phase_code = 'P'
	);
	
	IF l_alert_req_id = 0 THEN
	   
	        dbms_lock.sleep(90);
	   
	       	select max(request_id) into l_alert_req_id from fnd_concurrent_requests
	   	where concurrent_program_id in
	   	(
	   	select concurrent_program_id from fnd_concurrent_programs_vl 
	   	where concurrent_program_name ='XX_CRM_CONC_JOBS_ALERTER' AND phase_code IN ('P','R')
	        );
	
	END IF;

        IF l_alert_req_id != 0 THEN

           l_alert_req_status := fnd_concurrent.cancel_request
           (
            request_id  => l_alert_req_id,
            message     => l_alert_msg
           );

           IF l_alert_req_status THEN
              fnd_file.put_line (fnd_file.log, 'Request XX_CRM_CONC_JOBS_ALERTER - ' || l_alert_req_id || ' - Conc Job Alerter Program Turned OFF');
           ELSE
              fnd_file.put_line (fnd_file.log, 'Error: Request XX_CRM_CONC_JOBS_ALERTER - ' || l_alert_req_id || ' not Cancelled - ' || l_alert_msg); 
           END IF;

        END IF;

    -- STEP - 7 : Turn ON Concurrent Program Alerter Job

     IF l_alert_req_status THEN

      l_repeat_option_stat   := FND_REQUEST.set_repeat_options 
                                (
                                  repeat_time      => NULL,
                                  repeat_interval  => 3,
                                  repeat_unit      => 'HOURS',
                                  repeat_type      => 'START',
                                  repeat_end_time  => NULL,
                                  increment_dates  => 'N'
                                 );    

      l_alerts_req_id := FND_REQUEST.submit_request
                                          (   application => 'XXCRM',
                                              program     => 'XX_CRM_CONC_JOBS_ALERTER',
                                              description => NULL,
                                              start_time  => TO_CHAR(l_conc_alerts_on_date, 'DD-MON-YYYY HH24:MI:SS'),
                                              sub_request => FALSE,
                                              argument1   => NULL,
                                              argument2   => NULL,
                                              argument3   => 'CRM'
                                           ); 
                                           
     IF l_alerts_req_id = 0 THEN
        fnd_file.put_line (fnd_file.log, 'Request XX_CRM_CONC_JOBS_ALERTER to Turn ON Concurrent Program Alerter Job Could Not Be Submitted');
     ELSE
        fnd_file.put_line (fnd_file.log, 'Request XX_CRM_CONC_JOBS_ALERTER to Turn ON Concurrent Program Alerter Job Successfully Submitted, Request ID: ' || l_alerts_req_id);
     END IF;

    END IF;    
    
    fnd_file.put_line(fnd_file.log,'Sending Email Notification.....');
    
    send_mail 
    (
    p_bpel_off_req_id            => lt_bpel_off_req_id,
    p_downtime_start_date        => l_downtime_start_date,
    p_bpel_on_req_id             => lt_bpel_on_req_id,
    p_downtime_end_date          => l_downtime_end_date,
    p_bpel_alerts_off_req_id     => lt_bpel_alerts_off_req_id,
    p_alert_off_date             => l_alert_off_date,
    p_bpel_alerts_on_req_id      => lt_bpel_alerts_on_req_id,
    p_alert_on_date              => l_alert_on_date,
    p_alerts_req_id              => l_alerts_req_id,
    p_extract_time_set_req_id    => lt_extract_time_set_req_id,
    p_prog_run_date              => l_prog_run_date,
    p_extract_start_date         => l_extract_start_date,
    p_mail_to                    => l_mail_to,
    x_ret_status                 => x_mail_ret_status,
    x_ret_error_code             => x_mail_ret_error_code
    );
    
    IF x_mail_ret_status = 'S' THEN
      fnd_file.put_line(fnd_file.log,'Email Notification Successfully Sent To:' || NVL(l_mail_to,'NO MAIL ADDRESS SETUP'));
    ELSE
      fnd_file.put_line(fnd_file.log,'Error during Email Notification:'|| x_mail_ret_error_code);
    END IF;
    
 ELSE
     fnd_file.put_line (fnd_file.log, 'No DownTimes Noticed in the Window:' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') || ' And ' || TO_CHAR(SYSDATE+1/2,'DD-MON-YYYY HH24:MI:SS'));
     fnd_file.put_line (fnd_file.log, 'No Action Taken on BPEL Extract');
 END IF;
 
 
 COMMIT;

END bpel_extract_main;


PROCEDURE get_downtime_start_date 
( p_downtime_start_date  OUT    DATE,
  p_downtime_end_date    OUT    DATE,
  p_mail_address         OUT    VARCHAR2
)
IS
l_start_time          DATE;
l_expected_end_time   DATE;
l_program_run_value   VARCHAR2(50);
l_program_run_day     VARCHAR2(5);
l_increment_dates     NUMBER := 0;
l_program_run_date    VARCHAR2(40);
l_down_time_start     VARCHAR2(40) := NULL;
l_down_time_end       VARCHAR2(40) := NULL;
l_start_date_val      DATE := NULL;
l_end_date_val        DATE := NULL;
l_current_date        DATE := SYSDATE;
l_mail_address        VARCHAR2(2000);
BEGIN


     WHILE l_increment_dates <= 6 LOOP
     
      l_program_run_value  := TO_CHAR(l_current_date+l_increment_dates,'DY MM/DD/YYYY HH24:MI:SS');
      l_program_run_day    := substr (l_program_run_value,0,INSTR(l_program_run_value,' ')-1);
      l_program_run_value  := substr (l_program_run_value,INSTR(l_program_run_value,' ')+1); 
      l_program_run_date   := substr (l_program_run_value,0,INSTR(l_program_run_value,' ')-1);

      BEGIN
  
        SELECT target_value1,target_value2,target_value3 INTO l_down_time_start,l_down_time_end,l_mail_address
        FROM xx_fin_translatedefinition def,xx_fin_translatevalues val
        WHERE def.translate_id=val.translate_id
        AND   def.translation_name = 'XX_CRM_ENV_DOWN_TIMES'
        AND   NVL(val.source_value1,'X')=DECODE(val.source_value1,NULL,'X',l_program_run_date)
        AND   val.source_value2=l_program_run_day;

      EXCEPTION WHEN NO_DATA_FOUND THEN
       NULL;
      END;
      
      IF l_down_time_start IS NOT NULL AND l_down_time_end IS NOT NULL THEN
         l_start_date_val := TO_DATE(l_program_run_date || ' ' || l_down_time_start,'MM/DD/YYYY HH24:MI:SS');
         IF INSTR(l_down_time_end,'+') > 0 THEN
            l_end_date_val := TO_DATE(TO_CHAR(TO_DATE(l_program_run_date,'MM/DD/YYYY') + 1,'MM/DD/YYYY') || ' ' || l_down_time_end,'MM/DD/YYYY HH24:MI:SS');
         ELSE
           l_end_date_val := TO_DATE(l_program_run_date || ' ' || l_down_time_end,'MM/DD/YYYY HH24:MI:SS');
         END IF;
         IF l_current_date < l_start_date_val  THEN
           EXIT;
         ELSE
           l_down_time_start   := NULL;
           l_start_date_val    := NULL;
           l_end_date_val      := NULL;
         END IF;
      END IF;
      
      l_increment_dates := l_increment_dates + 1;
     
     END LOOP; 
     
     p_downtime_start_date  := l_start_date_val;
     p_downtime_end_date    := l_end_date_val;
     p_mail_address         := l_mail_address;
END get_downtime_start_date;

END XX_CDH_BPEL_EXTRACT_PKG;
/
SHOW ERRORS;