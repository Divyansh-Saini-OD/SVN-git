-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_GLSTG                                                                |
-- | Description : View to select details of the HV Journal Staging Program                    |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- +===========================================================================================+

CREATE OR REPLACE FORCE VIEW APPS.XX_MON_GLSTG ("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME")
AS
   SELECT GLSTG.request_id
         ,GLSTG.program_name
         ,GLSTG.start_date                                                              START_DATE
         ,GLSTG.completion_date                                                         END_DATE
         ,GLSTG.records_processed
         ,DECODE(GLSTG.processing_time_in_Sec, 0, 1, GLSTG.processing_time_in_Sec)      PROCESSING_TIME_IN_SEC
         ,ROUND(GLSTG.records_processed / DECODE(GLSTG.processing_time_in_Sec, 0, 1,
                                                 GLSTG.processing_time_in_Sec), 2)      THROUGHPUT
         ,GLSTG.ORG_ID                                                                  ORG_ID-- Added for Defect#6615
         ,GLSTG.process_Date                                                            CYCLE_DATE
         ,GLSTG.event_number                                                            EVENT
         ,GLSTG.USER_NAME                                                               USER_NAME-- Added for Defect#6615
    FROM (SELECT FCR.request_id
                ,'GL STG-ARGLTP-ALL'                     PROGRAM_NAME
                ,FCR.actual_start_date                   START_DATE
                ,FCR.actual_completion_date              COMPLETION_DATE
                ,SUM(XGHVJC.volume)                      RECORDS_PROCESSED
                ,ROUND((FCR.actual_completion_date -
                        FCR.actual_start_date)*24*60*60) PROCESSING_TIME_IN_SEC
                ,FPO.profile_option_value                ORG_ID      -- Added for Defect#6615
                ,FU.USER_NAME                -- Added for Defect#6615
                ,XGHVJC.process_Date
                ,XGHVJC.event_number
           FROM apps.fnd_concurrent_requests        FCR
               ,apps.fnd_concurrent_programs        FCP
               ,apps.xx_gl_high_volume_jrnl_control XGHVJC
               ,apps.fnd_profile_option_values      FPO            -- Added for Defect#6615
               ,apps.fnd_user                       FU            -- Added for Defect#6615
          WHERE FCP.concurrent_program_name   = 'XXARJRNLSTGPRG'   -- OD: AR HV Journal Staging
            AND FCP.application_id            = 20043              -- XXFIN application id
            AND FCP.concurrent_program_id     = FCR.concurrent_program_id
            AND FCP.application_id            = FCR.program_application_id
            AND FCR.phase_code                = 'C'
--            AND FCR.request_date            >= (SYSDATE-1)
--            AND FCR.request_date            <= (SYSDATE)
           AND FPO.profile_option_id = (SELECT profile_option_id FROM fnd_profile_options WHERE profile_option_name = 'ORG_ID')              -- Added for Defect#6615
           AND FPO.level_value = FCR.responsibility_id   -- Added for Defect#6615
           AND FU.user_id = FCR.requested_by             -- Added for Defect#6615
           AND FCR.request_id                = XGHVJC.hv_stg_req_id
     GROUP BY FCR.request_id
            ,FCR.actual_start_date
            ,FCR.actual_completion_date
            ,FPO.profile_option_value        -- Added for Defect#6615
            ,FU.user_name        -- Added for Defect#6615
            ,XGHVJC.process_Date
            ,XGHVJC.event_number
            ) GLSTG
    ORDER BY 1 DESC;
/
