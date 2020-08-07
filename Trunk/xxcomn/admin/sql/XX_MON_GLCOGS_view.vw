-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_GLCOGS                                                               |
-- | Description : View to select details of the GL Interface for COGS Master Program          |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- |   1.1   2010/07/29     R. Aldridge     Removed cycle date due to format issue             |
-- +===========================================================================================+

  CREATE OR REPLACE FORCE VIEW "APPS"."XX_MON_GLCOGS" ("REQUEST_ID", "PROGRAM_NAME", "START_DATE", "END_DATE", "VOLUME", "PROCESSING_TIME_IN_SEC", "THROUGHPUT", "ORG_ID", "CYCLE_DATE", "EVENT", "USER_NAME") AS 
  SELECT GLSTG.request_id
         ,GLSTG.program_name
         ,GLSTG.start_date                           START_DATE
         ,GLSTG.completion_date                      END_DATE
         ,GLSTG.records_processed
         ,DECODE(GLSTG.processing_time_in_Sec, 0, 1,
                       GLSTG.processing_time_in_Sec) PROCESSING_TIME_IN_SEC
         ,ROUND(GLSTG.records_processed / DECODE(GLSTG.processing_time_in_Sec, 0, 1,
                                                    GLSTG.processing_time_in_Sec), 2) THROUGHPUT
         ,GLSTG.ORG_ID
         ,GLSTG.CYCLE_DATE
         ,GLSTG.EVENT
         ,GLSTG.USER_NAME
    FROM (SELECT FCR.request_id
                ,'GL COGS'                               PROGRAM_NAME
                ,FCR.actual_start_date                   START_DATE
                ,FCR.actual_completion_date              COMPLETION_DATE
                ,SUM(XGHVJC.volume)                      RECORDS_PROCESSED
                ,ROUND((FCR.actual_completion_date -
                        FCR.actual_start_date)*24*60*60) PROCESSING_TIME_IN_SEC
                ,FPO.profile_option_value                ORG_ID
                ,FU.user_name                            USER_NAME
                ,null     CYCLE_DATE
                ,FCR.argument8                           EVENT
           FROM apps.fnd_concurrent_requests  FCR
               ,apps.fnd_concurrent_programs  FCP
               ,apps.xx_gl_high_volume_jrnl_control XGHVJC
               ,apps.fnd_profile_option_values FPO
               ,apps.fnd_user FU
          WHERE FCP.concurrent_program_name   = 'XXGLCOGS_SCHEDULER'
            AND FCP.application_id            = 20043                        -- XXFIN application id
            AND FCP.concurrent_program_id     = FCR.concurrent_program_id
            AND FCP.application_id            = FCR.program_application_id
            AND FCR.phase_code                = 'C'
--          AND FCR.request_date                >= (SYSDATE-1)
--          AND FCR.request_date                <= (SYSDATE)
            AND FCR.request_id                = XGHVJC.parent_request_id
            AND FPO.profile_option_id         = (SELECT profile_option_id FROM fnd_profile_options WHERE profile_option_name = 'ORG_ID')
            AND FPO.level_value               = FCR.responsibility_id
            AND FU.user_id                    = FCR.requested_by
          GROUP BY FCR.request_id
            ,FCR.actual_start_date
            ,FCR.actual_completion_date
            ,FPO.profile_option_value
            ,FU.user_name
            ,FCR.argument8) GLSTG
   ORDER BY 1 desc;
/
