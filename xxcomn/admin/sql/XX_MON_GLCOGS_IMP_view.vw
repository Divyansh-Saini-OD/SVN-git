-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_GLCOGS_IMP                                                           |
-- | Description : View to select details of the  HV Journal Import Program                    |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- |   2     2010/09/03     R.Hartman       Defect 7765 - GL Archive GL.* - schema name remove |
-- +===========================================================================================+

CREATE OR REPLACE FORCE VIEW APPS.XX_MON_GLCOGS_IMP("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME")
AS
   SELECT FCR.request_id                                                         REQUEST_ID   -- XXCOGSJRNLIMPPRG Request Id
         ,'GL Imp-COGS-ALL'                                                      PROGRAM_NAME -- GL Journal for ALL types
         ,FCR.actual_start_date                                                  START_DATE
         ,FCR.actual_completion_date                                             END_DATE
         ,SUM(apps.XX_FIN_PERF_METRICS_PKG.XX_GET_JE_LINE_CNT(GJb.je_batch_id))  VOLUME
         ,ROUND((FCR.actual_completion_date-FCR.actual_start_date)*24*60*60)     PROCESSING_TIME_IN_SEC
         ,ROUND(SUM(apps.XX_FIN_PERF_METRICS_PKG.XX_GET_JE_LINE_CNT(GJb.je_batch_id))/DECODE((FCR.actual_completion_date-FCR.actual_start_date), 0, 1, (FCR.actual_completion_date-FCR.actual_start_date)*24*60*60), 2) Throughput
         ,FPO.profile_option_value                                               ORG_ID
         ,NULL                                                                   CYCLE_DATE
         ,NULL                                                                   EVENT
         ,FU.user_name                                                           USER_NAME
     FROM fnd_concurrent_requests FCR
         ,fnd_concurrent_programs FCP
         ,fnd_profile_option_values FPO
         ,fnd_user FU
         --Grand Child request Tables--Journal Import--
         ,fnd_concurrent_programs GCFCP
         ,fnd_concurrent_requests GCFCR
         --GL Base Tables--
         ,gl_je_batches           GJB
   WHERE FCP.concurrent_program_name   = 'XXCOGSJRNLIMPPRG'   -- OD: AR HV Journal Import
     AND FCP.application_id            = 20043              -- XXFIN application id
     AND FCR.concurrent_program_id     = FCP.concurrent_program_id
     AND FCR.phase_code                = 'C'
     AND FPO.profile_option_id         = (SELECT profile_option_id FROM fnd_profile_options WHERE profile_option_name = 'ORG_ID')
     AND FPO.level_value               = FCR.responsibility_id
--     AND FCR.request_date                >= (SYSDATE-1)
--     AND FCR.request_date                <= (SYSDATE)
     AND FCR.request_id                = GCFCR.parent_request_id
     AND GCFCP.concurrent_program_id   = GCFCR.concurrent_program_id
     AND GCFCP.concurrent_program_name = 'GLLEZL'          -- Journal Import
     AND GCFCP.application_id          = 101               -- GL application id
     AND GJB.name                      LIKE 'OD COGS%'||GCFCR.request_id||'%'
     AND FU.user_id                    = FCR.requested_by
   GROUP BY FCR.Request_id
           ,FCR.actual_start_date
           ,FCR.actual_completion_date
           ,FPO.profile_option_value
           ,FU.user_name;
/
