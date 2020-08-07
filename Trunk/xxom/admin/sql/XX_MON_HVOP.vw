-- +==============================================================================+
-- |                        Office Depot - Project Simplify                       |
-- |                                                                              |
-- +==============================================================================+
-- | Name         : XX_MON_HVOP.vw                                                |
-- | Rice Id      :                                                               |
-- | Description  :                                                               |
-- | Purpose      : Create custom view to monitor TPS Rate for HVOP Batch Process |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version Date        Author            Remarks                                 | 
-- |======= =========== ================= ========================================+
-- |1.0     06-JUL-2010 Bapuji Nanapaneni   Initial Version                       |
-- |2.0     04-JAN-2017	Vasu Raparla        Removed Schema references for R.12.2  | 
-- +==============================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Creating Custom Views ......
PROMPT

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating View Name XX_MON_HVOP .....
PROMPT

CREATE OR REPLACE FORCE VIEW  xx_mon_hvop AS 
    SELECT fcr1.REQUEST_ID request_id
         , DECODE(user_concurrent_program_name, 'OD: SAS Trigger HVOP', 'HVOP',user_concurrent_program_name) program_name
         , MIN(fcr1.actual_start_date) start_date
         , MAX(fcr1.actual_completion_date) end_date
         , SUM(sfh.legacy_header_count * 3 + sfh.legacy_line_count + sfh.legacy_adj_count + sfh.legacy_payment_count) volume
         , ROUND(MAX((NVL(fcr1.actual_completion_date,SYSDATE)-NVL(fcr1.actual_start_date,SYSDATE))*24*60*60),2) processing_time_in_sec
         , ROUND(SUM((sfh.legacy_header_count * 3 + sfh.legacy_line_count + sfh.legacy_adj_count + sfh.legacy_payment_count) / ((NVL(fcr1.actual_completion_date,SYSDATE)-NVL(fcr1.actual_start_date,SYSDATE))*24*60*60)), 2) throughput
         , sfh.org_id
         , MIN(sfh.process_date) cycle_date
         , DECODE(fcr1.argument1,'SASUSEOT1.TXT',1
                                ,'SASUSEOT2.TXT',2
                                ,'SASUSEOT3.TXT',3
                                ,'SASUSEOT5.TXT',4
                                ,'SASCAEOT1.TXT',1
                                ,'SASCAEOT2.TXT',2
                                ,'SASCAEOT3.TXT',3
                                ,'SASCAEOT5.TXT',4
                                ,'SASUSEOT6.TXT',1
                                ,'SASUSEOT7.TXT',2
                                ,'SASUSEOT8.TXT',3
                                ,'SASUSEOT9.TXT',4
                                ,'SASCAEOT6.TXT',1
                                ,'SASCAEOT7.TXT',2
                                ,'SASCAEOT8.TXT',3
                                ,'SASCAEOT9.TXT',4
                                ) Event
         , fu.user_name
      FROM fnd_concurrent_processes fcproc
INNER JOIN fnd_concurrent_queues_tl fcql
        ON fcproc.queue_application_id = fcql.application_id
       AND fcproc.concurrent_queue_id = fcql.concurrent_queue_id
       AND fcql.language              = USERENV('LANG')
INNER JOIN fnd_concurrent_requests fcr
        ON fcr.controlling_manager = fcproc.concurrent_process_id
INNER JOIN fnd_concurrent_requests fcr1
        ON fcr.parent_request_id = fcr1.request_id
       AND fcr1.status_code = 'C'
       AND fcr1.phase_code  = 'C'
INNER JOIN xx_om_sacct_file_history sfh
        ON fcr.request_id = sfh.request_id
INNER JOIN fnd_concurrent_programs_vl fcprogl
        ON fcr1.concurrent_program_id   = fcprogl.concurrent_program_id
       AND fcr1.program_application_id = fcprogl.application_id
INNER JOIN FND_USER FU
        ON FCR.requested_by = FU.user_id
INNER JOIN FND_RESPONSIBILITY_TL FR
        ON FCR.responsibility_application_id = FR.application_id
       AND FCR.responsibility_id            = FR.responsibility_id
  GROUP BY fcr1.REQUEST_ID
         , DECODE(user_concurrent_program_name, 'OD: SAS Trigger HVOP', 'HVOP',user_concurrent_program_name)
         , sfh.org_id
       --  , sfh.process_date
         , DECODE(fcr1.argument1,'SASUSEOT1.TXT',1
                                ,'SASUSEOT2.TXT',2
                                ,'SASUSEOT3.TXT',3
                                ,'SASUSEOT5.TXT',4
                                ,'SASCAEOT1.TXT',1
                                ,'SASCAEOT2.TXT',2
                                ,'SASCAEOT3.TXT',3
                                ,'SASCAEOT5.TXT',4
                                ,'SASUSEOT6.TXT',1
                                ,'SASUSEOT7.TXT',2
                                ,'SASUSEOT8.TXT',3
                                ,'SASUSEOT9.TXT',4
                                ,'SASCAEOT6.TXT',1
                                ,'SASCAEOT7.TXT',2
                                ,'SASCAEOT8.TXT',3
                                ,'SASCAEOT9.TXT',4)
         , fu.user_name
--HAVING SUM(SFH.legacy_header_count * 3 + SFH.legacy_line_count + SFH.legacy_adj_count + SFH.legacy_payment_count) > 100000
  ORDER BY fcr1.REQUEST_ID;       
/

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;    