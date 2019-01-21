-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_E80                                                                  |
-- | Description : View to select details of the Create Autoinvoice Accounting Master Program  |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- +===========================================================================================+

CREATE OR REPLACE VIEW APPS.XX_MON_E80(request_id,program_name,start_date,end_date,volume,processing_time_in_sec,throughput,org_id,cycle_date,event,user_name) 
AS 
SELECT FAR.request_id,
       FAR.program,
       FAR.actual_start_date sdate,
       FAR.actual_completion_date cdate,
       NULL volume,
       ROUND((FAR.actual_completion_date - FAR.actual_start_date)*1440*60) rtime,
       NULL throughput,
       FPO.profile_option_value org_id,
       NULL cycle_date,
       SUBSTR(FCR.argument12,LENGTH(FCR.argument12)) event,
       FAR.user_name
FROM   apps.fnd_amp_requests_v FAR
      ,apps.fnd_concurrent_requests FCR
      ,apps.fnd_profile_option_values FPO
WHERE  program                = 'OD: AR Create Autoinvoice Accounting Master'
AND    nvl(FAR.actual_start_date,trunc(sysdate)) BETWEEN trunc(sysdate-8) AND trunc(sysdate)
AND    FAR.request_id         = FCR.request_id
AND    FPO.profile_option_id  = (SELECT profile_option_id FROM fnd_profile_options WHERE profile_option_name = 'ORG_ID')
AND    FPO.level_value        = FCR.responsibility_id
ORDER BY FAR.actual_Start_date ASC;
/