-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_PREPAY                                                               |
-- | Description : View to select details of the Prepayments Matching Program                  |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- |   1.1   2016/02/03     Vasu Raparla    Removed schema References for R.12.2               |
-- +===========================================================================================+

CREATE OR REPLACE FORCE VIEW "XX_MON_PREPAY" ("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME") AS
  SELECT  FCR.request_id                request_id
       ,'PrePay'                      Program_name
       ,fcr.actual_start_date         Start_date
       ,fcr.actual_completion_date    End_date
       ,COUNT(ARA.request_id)         volume
       ,ROUND(TO_NUMBER(MAX(fcr.actual_completion_date) - MIN(fcr.actual_start_date) ) * (24*60*60)) PROCESSING_TIME_IN_SEC
       ,ROUND(COUNT(ARA.request_id) / DECODE(TO_NUMBER(MAX(fcr.actual_completion_date) - MIN(fcr.actual_start_date) ),0,1,
        (TO_NUMBER(MAX(fcr.actual_completion_date) - MIN(fcr.actual_start_date) ) * (24*60*60))), 2) Throughput
       ,FPO.profile_option_value                ORG_ID      -- Added for Defect#6615
       ,NULL                   CYCLE_DATE
       ,NULL                   EVENT
       ,FU.user_name     -- Added for Defect#6615
FROM    fnd_concurrent_programs_vl     FCP
       ,fnd_concurrent_requests        FCR
       ,ar_receivable_applications_all ARA
       ,fnd_profile_option_values      FPO            -- Added for Defect#6615
       ,fnd_user                       FU             -- Added for Defect#6615
WHERE   FCP.concurrent_program_name = 'ARPREMAT'--Prepayments Matching Program
    AND FCP.application_id = 222
    AND FCR.concurrent_program_id = FCP.concurrent_program_id
    AND FCR.request_id = ARA.request_id
    AND FPO.profile_option_id = (SELECT profile_option_id FROM fnd_profile_options WHERE profile_option_name = 'ORG_ID')              -- Added for Defect#6615
    AND FPO.level_value = FCR.responsibility_id   -- Added for Defect#6615
    AND FU.user_id=FCR.requested_by               -- Added for Defect#6615
GROUP   BY FCR.request_id, fcp.concurrent_program_name,
        fcp.user_concurrent_program_name, phase_code, status_code,
        fcr.request_date,
        actual_start_date,
        actual_completion_date, argument_text
      ,FPO.profile_option_value        -- Added for Defect#6615
      ,FU.user_name               -- Added for Defect#6615
order by 1 desc;
/