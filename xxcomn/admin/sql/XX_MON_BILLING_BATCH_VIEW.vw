CREATE OR REPLACE VIEW "XX_MON_BILLING_BATCH" ("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME") 
-- +===========================================================================================+
-- |                                 Office Depot Inc.                                         |
-- +===========================================================================================+
-- |Name         : XX_MON_BILLING_BATCH                                                        |
-- |Description  : View to select details of the Billing Cycle Programs                        |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1.0    2016/02/09   Manikant Kasu    Initial Draft                                      |
-- +===========================================================================================+
AS SELECT FAR.request_id
         , 'Billing Batch'
         , FAR.actual_start_date
         , ( select x.end_date 
               from XX_MON_SOX_RPT x 
              where x.request_id > far.request_id 
                and x.org_id = FPO.profile_option_value 
                and rownum < 2 ) actual_completion_date
         , NULL volume
         , round((( select x.end_date from XX_MON_SOX_RPT x where x.request_id > far.request_id and x.org_id = FPO.profile_option_value and rownum < 2 ) - FAR.actual_start_date)*1440*60) rtime
         , NULL tps
         , FPO.profile_option_value org_id
         , NULL cycle_date
         , NULL event
         , FAR.user_name
FROM fnd_amp_requests_v FAR
    ,fnd_concurrent_requests FCR
    ,fnd_profile_option_values FPO
WHERE program               = 'OD: AR Invoice Manage Frequencies Master'
AND   far.request_id        = fcr.request_id
AND   FPO.profile_option_id = (SELECT profile_option_id FROM fnd_profile_options WHERE profile_option_name = 'ORG_ID')
AND   FPO.level_value       = FCR.responsibility_id
AND   FCR.phase_code        = 'C'
ORDER BY actual_Start_date ASC;
/

