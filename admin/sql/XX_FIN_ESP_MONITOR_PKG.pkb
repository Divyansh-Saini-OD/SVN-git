create or replace
PACKAGE BODY  XX_FIN_ESP_MONITOR_PKG AS
-- +=====================================================================================================+
-- |  Office Depot - Project Simplify                                                                    |
-- |  Providge Consulting                                                                                |
-- +=====================================================================================================+
-- |  RICE:                                                                                              |
-- |                                                                                                     |
-- |  Name:  XX_FIN_ESP_MONITOR_PKG                                                                      |
-- |                                                                                                     |
-- |  Description:  This package will monitor ESP Batch jobs and send email alerts for failures          |
-- |                                                                                                     |
-- |                                                                                                     |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- | 1.0         16-DEC-2011  R.Strauss            Initial version                                       |
-- +=====================================================================================================+
PROCEDURE MONITOR_ESP_BATCH(errbuf       OUT NOCOPY VARCHAR2,
                            retcode      OUT NOCOPY NUMBER,
                            p_email_addr IN         VARCHAR2)
IS

x_error_message		VARCHAR2(2000)	DEFAULT NULL;
x_return_status		VARCHAR2(20)	DEFAULT NULL;
x_msg_count			NUMBER		DEFAULT NULL;
x_msg_data			VARCHAR2(4000)	DEFAULT NULL;
x_return_flag		VARCHAR2(1)		DEFAULT NULL;

lc_instance             VARCHAR2;
ln_conc_id              NUMBER;
lc_req_id               NUMBER;
lc_start_dt             DATE;
lc_start_tm             VARCHAR2(8);
lc_email_flag           VARCHAR2(1)   := 'N';
lc_email_addr           VARCHAR2(50)  := 'rstrauss@officedepot.com';
lc_msg                  VARCHAR2(4000)    DEFAULT NULL;
lc_long_msg             VARCHAR2(4000)    DEFAULT NULL;
lc_err_buff             VARCHAR2(500);

-- ==========================================================================
-- failed program cursor 
-- ==========================================================================
CURSOR failed_pgm_cur IS
       SELECT R.request_id,
              R.parent_request_id,
              P.user_concurrent_program_name,
                CASE r.phase_code
                     WHEN 'C'  THEN 'COMPLETED  '
                     WHEN 'I'  THEN 'INACTIVE   '
                     WHEN 'P'  THEN 'PENDING    '
                     WHEN 'R'  THEN 'RUNNING    '
                     ELSE           'UNKNOWN    '
                     END                           AS PHASE,
                CASE r.status_code
                     WHEN 'A'  THEN 'Waiting    '
                     WHEN 'B'  THEN 'Resuming   '
                     WHEN 'C'  THEN 'Normal     '
                     WHEN 'D'  THEN 'Cancelled  '
                     WHEN 'E'  THEN 'Error      '
                     WHEN 'F'  THEN 'Scheduled  '
                     WHEN 'G'  THEN 'Warning    '
                     WHEN 'H'  THEN 'On Hold    '
                     WHEN 'I'  THEN 'Normal     '
                     WHEN 'M'  THEN 'No Manager '
                     WHEN 'Q'  THEN 'Standby    '
                     WHEN 'R'  THEN 'Normal     '
                     WHEN 'S'  THEN 'Suspended  '
                     WHEN 'T'  THEN 'Terminating'
                     WHEN 'U'  THEN 'Disabled   '
                     WHEN 'W'  THEN 'Paused     '
                     WHEN 'X'  THEN 'Terminated '
                     WHEN 'Z'  THEN 'Waiting    '
                     ELSE           'UNKNOWN    '
                     END                           AS STATUS,
              f.responsibility_name
       FROM   apps.fnd_concurrent_requests    R,
              apps.FND_CONCURRENT_PROGRAMS_VL P,
              apps.fnd_responsibility_tl      F,
              apps.FND_USER                   U
       WHERE  R.concurrent_program_id         = P.concurrent_program_id
       AND    R.responsibility_application_id = F.application_id
       AND    R.responsibility_id             = F.responsibility_id
       AND    R.requested_by                  = U.user_id
       AND    R.actual_completion_date        > ls_start_date
       AND    R.phase_code                    = 'C'
       AND    R.status_code               not in ('C', 'R')
       AND    U.user_name in ('SVC_BPEL_FIN',
                              'SVC_ESP_CRM',
                              'SVC_ESP_DBA',
                              'SVC_ESP_FIN',
                              'SVC_ESP_FIN_2',
                              'SVC_ESP_MER',
                              'SVC_ESP_OM',
                              'SVC_ESP_OM1',
                              'SVC_ESP_OM2',
                              'SVC_ESP_SER')
       ORDER BY  f.responsibility_name, R.request_id;
-- ==========================================================================
-- long running program cursor 
-- ==========================================================================
CURSOR long_run_pgm_cur IS
       SELECT R.request_id,
              R.parent_request_id,
              P.user_concurrent_program_name
       FROM   apps.fnd_concurrent_requests    R,
              apps.FND_CONCURRENT_PROGRAMS_VL P,
              apps.fnd_responsibility_tl      F,
              apps.FND_USER                   U
       WHERE  R.concurrent_program_id         = P.concurrent_program_id
       AND    R.responsibility_application_id = F.application_id
       AND    R.responsibility_id             = F.responsibility_id
       AND    R.requested_by                  = U.user_id
       AND    R.actual_completion_date        > lc_start_dt
       AND    R.phase_code                   <> 'C'
       AND    R.actual_start_date         is not null
       AND    ceil(((R.ACTUAL_COMPLETION_DATE - R.ACTUAL_START_DATE) * 1440) + .01) > 120
       AND    U.user_name in ('SVC_BPEL_FIN',
                              'SVC_ESP_CRM',
                              'SVC_ESP_DBA',
                              'SVC_ESP_FIN',
                              'SVC_ESP_FIN_2',
                              'SVC_ESP_MER',
                              'SVC_ESP_OM',
                              'SVC_ESP_OM1',
                              'SVC_ESP_OM2',
                              'SVC_ESP_SER')
       ORDER BY R.request_id;
-- ==========================================================================
-- inactive program cursor 
-- ==========================================================================
CURSOR inactive_pgm_cur IS
       SELECT R.request_id,
              R.parent_request_id,
              P.user_concurrent_program_name,
                CASE r.phase_code
                     WHEN 'C'  THEN 'COMPLETED  '
                     WHEN 'I'  THEN 'INACTIVE   '
                     WHEN 'P'  THEN 'PENDING    '
                     WHEN 'R'  THEN 'RUNNING    '
                     ELSE           'UNKNOWN    '
                     END                           AS PHASE,
                CASE r.status_code
                     WHEN 'A'  THEN 'Waiting    '
                     WHEN 'B'  THEN 'Resuming   '
                     WHEN 'C'  THEN 'Normal     '
                     WHEN 'D'  THEN 'Cancelled  '
                     WHEN 'E'  THEN 'Error      '
                     WHEN 'F'  THEN 'Scheduled  '
                     WHEN 'G'  THEN 'Warning    '
                     WHEN 'H'  THEN 'On Hold    '
                     WHEN 'I'  THEN 'Normal     '
                     WHEN 'M'  THEN 'No Manager '
                     WHEN 'Q'  THEN 'Standby    '
                     WHEN 'R'  THEN 'Normal     '
                     WHEN 'S'  THEN 'Suspended  '
                     WHEN 'T'  THEN 'Terminating'
                     WHEN 'U'  THEN 'Disabled   '
                     WHEN 'W'  THEN 'Paused     '
                     WHEN 'X'  THEN 'Terminated '
                     WHEN 'Z'  THEN 'Waiting    '
                     ELSE           'UNKNOWN    '
                     END                           AS STATUS,
              f.responsibility_name
       FROM   apps.fnd_concurrent_requests    R,
              apps.FND_CONCURRENT_PROGRAMS_VL P,
              apps.fnd_responsibility_tl      F,
              apps.FND_USER                   U
       WHERE  R.concurrent_program_id         = P.concurrent_program_id
       AND    R.responsibility_application_id = F.application_id
       AND    R.responsibility_id             = F.responsibility_id
       AND    R.requested_by                  = U.user_id
       AND    R.ACTUAL_START_DATE             > ls_start_date
       AND    R.phase_code                    <> 'C'
       AND    R.status_code               not in ('C', 'R')
       AND    U.user_name in ('SVC_BPEL_FIN',
                              'SVC_ESP_CRM',
                              'SVC_ESP_DBA',
                              'SVC_ESP_FIN',
                              'SVC_ESP_FIN_2',
                              'SVC_ESP_MER',
                              'SVC_ESP_OM',
                              'SVC_ESP_OM1',
                              'SVC_ESP_OM2',
                              'SVC_ESP_SER')
       ORDER BY  f.responsibility_name, R.request_id;
-- ==========================================================================
-- Main process
-- ==========================================================================
BEGIN
        IF length(p_email_addr) > 0 THEN
           lc_email_addr := p_email_addr;
        END IF;

	FND_FILE.PUT_LINE(fnd_file.log,'XX_FIN_ESP_MONITOR_PKG.MONITOR_ESP_BATCH - parameters:      ');
	FND_FILE.PUT_LINE(fnd_file.log,' ');
	FND_FILE.PUT_LINE(fnd_file.log,'                                           email_address: '||lc_email_addr);

   BEGIN
       SELECT NAME
       INTO   lc_instance
       FROM   v$database;

       SELECT X.request_id,
              X.actual_completion_date,
              TO_CHAR(X.actual_completion_date, 'HH24:MI:SS')
       INTO   lc_req_id,
              lc_start_dt,
              lc_start_tm
       FROM  (SELECT R.request_id,
                     R.actual_completion_date,
                     TO_CHAR(R.actual_completion_date, 'HH24:MI:SS')
              FROM   apps.fnd_concurrent_requests    R,
                     apps.FND_CONCURRENT_PROGRAMS_VL P
              WHERE  R.concurrent_program_id = P.concurrent_program_id
              AND    p.concurrent_program_name = 'XXFINESPMONITOR'
              AND    R.phase_code = 'C'
              ORDER BY R.request_id desc) X
       WHERE  ROWNUM = 1;

	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
	           lc_start_dt := SYSDATE-1;
   END;
  
      FND_FILE.PUT_LINE(fnd_file.log,'Searching for failed requests since '||TO_CHAR(lc_start_dt,'YYYY/MM/DD')||' '||lc_start_tm);
      FND_FILE.PUT_LINE(fnd_file.log,' ');

      FOR failed_rec IN failed_pgm_cur
	LOOP

         lc_msg := lc_msg||failed_rec.request_id||'     '||
                           failed_rec.parent_request_id||'      '||
                           failed_rec.user_concurrent_program_name||chr(10);

        END LOOP;

      FND_FILE.PUT_LINE(fnd_file.log,'Searching for long running requests since '||TO_CHAR(lc_start_dt,'YYYY/MM/DD')||' '||lc_start_tm);
      FND_FILE.PUT_LINE(fnd_file.log,' ');

      FOR long_rec IN long_run_pgm_cur
	LOOP

         lc_long_msg := lc_long_msg||long_rec.request_id||'     '||
                                     long_rec.parent_request_id||'      '||
                                     long_rec.user_concurrent_program_name||chr(10);

        END LOOP;

      IF lc_email_flag = 'Y' THEN
         FND_FILE.PUT_LINE(fnd_file.log,'Sending email notification');
         FND_FILE.PUT_LINE(fnd_file.log,' ');

         ln_conc_id := fnd_request.submit_request(
                                                  application => 'XXFIN'
                                                 ,program     => 'XXODEMAILER'
                                                 ,description =>  NULL
                                                 ,start_time  =>  SYSDATE
                                                 ,sub_request =>  FALSE
                                                 ,argument1   =>  lc_email_addr
                                                 ,argument2   =>  lc_subject
                                                 ,argument3   =>  lc_msg
                                                 );
      END IF;


END MONITOR_ESP_BATCH;	

END XX_FIN_ESP_MONITOR_PKG ;
/