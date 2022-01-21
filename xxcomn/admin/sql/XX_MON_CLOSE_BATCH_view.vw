-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_CLOSE_BATCH                                                          |
-- | Description : View to select details of the IBY Settlement Close Batch Program            |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- |   1.1   2016/02/03     Vasu Raparla    Removed schema References for R.12.2               |
-- +===========================================================================================+
CREATE OR REPLACE VIEW "XX_MON_CLOSE_BATCH" ("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME") 
AS SELECT FAR.request_id
         , 'Close Batch'
         , FAR.actual_start_date
         , FAR.actual_completion_date
         , NULL volume
         , round((FAR.actual_completion_date - FAR.actual_start_date)*1440*60) rtime
         , NULL tps
         , FPO.profile_option_value org_id
         , NULL cycle_date
         , NULL event
         , FAR.user_name
FROM fnd_amp_requests_v FAR
    ,fnd_concurrent_requests FCR
    ,fnd_profile_option_values FPO
WHERE program               = 'OD: AR IBY Settlement Close Batch Program'
AND   far.request_id        = fcr.request_id
AND   FPO.profile_option_id = (SELECT profile_option_id FROM fnd_profile_options WHERE profile_option_name = 'ORG_ID')
AND   FPO.level_value       = FCR.responsibility_id
ORDER BY actual_Start_date ASC;
/

