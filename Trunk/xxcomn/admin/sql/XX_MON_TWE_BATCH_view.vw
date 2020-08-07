-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_TWE_BATCH                                                            |
-- | Description : View to select details of the TWE Batch Audit Master Program                |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- |   1.1   2016/02/03     Vasu Raparla    Removed schema References for R.12.2               |
-- +===========================================================================================+

CREATE OR REPLACE FORCE VIEW "XX_MON_TWE_BATCH" ("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME")
AS
SELECT  FCR.request_id Request_Id
        , 'TWE Batch'
        , FCR.actual_start_date Start_Date
        , FCR.actual_completion_date End_Date
        , COUNT(1) volume
        , Round ((FCR.actual_completion_date-FCR.actual_start_date)*24*60*60) Processing_Time
        , Round (COUNT(1)/DECODE((FCR.actual_completion_date-FCR.actual_start_date), 0, 1,
         (FCR.actual_completion_date-FCR.actual_start_date)*24*60*60), 2)
        ,FPO.profile_option_value                ORG_ID      -- Added for Defect#6615
         ,NULL                   CYCLE_DATE
         ,NULL                   EVENT
        ,FU.user_name                 -- Added for Defect#6615
FROM    fnd_concurrent_requests FCR
        , fnd_concurrent_programs_vl FCP
        , xx_ar_twe_audit_trans_all TWE
        , fnd_application FA
        ,fnd_profile_option_values  FPO            -- Added for Defect#6615
        ,fnd_user         FU   -- Added for Defect#6615
WHERE   FCR.concurrent_program_id = FCP.concurrent_program_id
AND     FCP.concurrent_program_name = 'XXAR_TWE_BATCH_AUD_MASTER'
AND     FCP.application_id = FA.application_id
AND     FA.application_short_name = 'XXFIN'
and     FCR.status_code = 'C'
and     FCR.phase_code = 'C'
--AND FCR.request_date >= (SYSDATE-1)
--AND FCR.request_date <= (SYSDATE)
and     TWE.parent_request_id = FCR.request_id
AND     FPO.profile_option_id = (SELECT profile_option_id FROM fnd_profile_options WHERE profile_option_name = 'ORG_ID')              -- Added for Defect#6615
AND     FPO.level_value = FCR.responsibility_id   -- Added for Defect#6615
AND     FU.user_id=FCR.requested_by             -- Added for Defect#6615
GROUP BY FCR.request_id
        , FCP.user_concurrent_program_name
        , FCR.actual_start_date
        , FCR.actual_completion_date
        , FPO.profile_option_value
        , FU.user_name;  
/