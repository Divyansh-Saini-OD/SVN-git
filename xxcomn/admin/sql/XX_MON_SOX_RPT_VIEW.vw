CREATE OR REPLACE VIEW "XX_MON_SOX_RPT" ("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME") 
-- +===========================================================================================+
-- |                                 Office Depot Inc.                                         |
-- +===========================================================================================+
-- | Name        : XX_MON_SOX_RPT                                                              |
-- | Description : View to select details of the SOX Report Programs                           |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1.0    2016/02/09   Manikant Kasu    Initial Draft                                      |
-- +===========================================================================================+
AS SELECT FAR.request_id
         , 'SOX Report'
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
WHERE program               = 'OD: AR Billing SOX Report'
AND   far.argument_text     like '%Certegy%'
AND   far.request_id        = fcr.request_id
AND   FPO.profile_option_id = (SELECT profile_option_id FROM fnd_profile_options WHERE profile_option_name = 'ORG_ID')
AND   FPO.level_value       = FCR.responsibility_id
ORDER BY actual_Start_date ASC;
/
