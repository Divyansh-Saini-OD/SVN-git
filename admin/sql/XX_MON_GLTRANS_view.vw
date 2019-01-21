-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_GLTRANS                                                              |
-- | Description : View to select details of the Parallel GL Transfer Program                  |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- +===========================================================================================+

CREATE OR REPLACE VIEW APPS.XX_MON_GLTRANS("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME")
AS
SELECT GLTP.request_id
         ,GLTP.program_name
         ,GLTP.start_date        START_DATE
         ,GLTP.completion_date   COMPLETION_DATE
         ,GLTP.records_processed
         ,DECODE(GLTP.processing_time_in_Sec, 0, 1, GLTP.processing_time_in_Sec) PROCESSING_TIME_IN_SEC
         ,ROUND(GLTP.records_processed/DECODE(GLTP.processing_time_in_Sec, 0, 1, GLTP.processing_time_in_Sec), 2) THRUPUT
         ,GLTP.ORG_ID       -- Added for Defect#6615
         ,GLTP.process_Date                   CYCLE_DATE
         ,GLTP.event_number                   EVENT
         ,GLTP.USER_NAME     -- Added for Defect#6615
     FROM (SELECT FCR.request_id                              REQUEST_ID
                 ,'GL Transfer-' || NVL(FCR.argument12,'ALL') PROGRAM_NAME
                 ,FCR.actual_start_date                       START_DATE
                 ,FCR.actual_completion_date                  COMPLETION_DATE
                 ,FCR.status_code
                 ,FCR.phase_code
                 ,SUM(XHVJC.volume)                           RECORDS_PROCESSED
                 ,ROUND((FCR.actual_completion_date - FCR.actual_start_date) * 24 * 60 * 60) PROCESSING_TIME_IN_SEC
                 ,FCR.ARGUMENT10                              ORG_ID       -- Added for Defect#6615
                 ,FU.USER_NAME                                             -- Added for Defect#6615
                 ,XHVJC.process_Date
                 ,XHVJC.event_number
             FROM apps.fnd_concurrent_requests        FCR
                 ,apps.fnd_concurrent_programs        FCP
                 ,apps.xx_gl_high_volume_jrnl_control XHVJC
                 ,apps.fnd_user                       FU            -- Added for Defect#6615
            WHERE FCP.concurrent_program_name = 'XXARGLTM'  -- OD: AR Parallel GL Transfer Program
              AND FCP.application_id          = 20043    -- value is XXFIN and never changes
              AND FCP.concurrent_program_id   = FCR.concurrent_program_id
              AND FCP.application_id          = FCR.program_application_id
              AND FCR.Request_Id              = XHVJC.parent_request_id
--              AND FCR.request_date            >= (SYSDATE-1)
--              AND FCR.request_date            <= (SYSDATE)
              AND FCR.phase_code = 'C'
           AND FU.USER_ID = FCR.REQUESTED_BY             -- Added for Defect#6615
           GROUP BY FCR.request_id
                   ,'GL Transfer-' || NVL(FCR.argument12,'ALL')
                   ,FCR.actual_start_date
                   ,FCR.actual_completion_date
                   ,FCR.status_code
                   ,FCR.phase_code
                   ,ROUND((FCR.actual_completion_date - FCR.actual_start_date) * 24 * 60 * 60)
                   ,FCR.ARGUMENT10       -- Added for Defect#6615
                   ,FU.USER_NAME        -- Added for Defect#6615
                   ,XHVJC.process_Date
                   ,XHVJC.event_number
           ORDER BY FCR.request_id) GLTP;
/
