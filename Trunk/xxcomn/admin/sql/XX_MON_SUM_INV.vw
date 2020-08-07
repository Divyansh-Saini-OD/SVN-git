-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : XX_MON_SUM_INV                                                              |
-- | Description : Used for monitor performance of invoice summarization program               |
-- |                                                                                           |
-- | Change Record:                                                                            |
-- | ===============                                                                           |
-- | Version  Date         Author         Remarks                                              |
-- | =======  ===========  =============  =====================================================|
-- |  1.0     18-JUN-2011  R. Aldridge    Initial version (Defect 12129)                       |
-- |  1.0     21-MAY-2012  R. Aldridge    Defect 13019 - Modify for multithreaded version      |
-- |  1.1     2016/02/03  Vasu Raparla    Removed schema References for R.12.2                  |
-- +===========================================================================================+
CREATE OR REPLACE FORCE VIEW XX_MON_SUM_INV 
   (request_id
   ,program_name
   ,start_date
   ,end_date
   ,volume
   ,processing_time_in_sec
   ,throughput
   ,org_id
   ,cycle_date
   ,event
   ,user_name)
AS
SELECT FCR.request_id                                       REQUEST_ID
      ,'SUMMARY_INV'                                        PROGRAM_NAME
      ,FCR.actual_start_date                                START_DATE
      ,FCR.actual_completion_date                           END_DATE
      ,SUM(AI.volume)                                       VOLUME
      ,ROUND((FCR.actual_completion_date - FCR.actual_start_date) * 24 * 60 * 60,0)                            PROCESSING_TIME_IN_SEC
      ,ROUND(SUM(AI.volume) / ROUND((FCR.actual_completion_date - FCR.actual_start_date) * 24 * 60 * 60,0),2)  THROUGHPUT
      ,FCR.argument6                   ORG_ID
      ,TO_DATE(SUBSTR(FCR.argument_text,1,10),'YYYY/MM/DD') CYCLE_DATE
      ,FCR.argument7                                        EVENT
      ,FU.user_name                                         USER_NAME
 FROM fnd_concurrent_programs       FCP
     ,fnd_concurrent_requests       FCR
     ,fnd_concurrent_programs_tl    FCPT
     ,fnd_user                      FU
    ,(SELECT PR.ai_master_rid     AI_MASTER_RID
             ,PR.pos_child_rid     POS_CHILD_RID
             ,PR.pos_parent_rid    POS_PARENT_RID
             ,COUNT(1)             VOLUME
         FROM fnd_concurrent_requests CFCR
             ,fnd_concurrent_programs CFC
             ,ra_customer_trx_lines_all    RCTL
             ,(SELECT FCR.request_id          AI_MASTER_RID
                     ,FCR.parent_request_id   POS_CHILD_RID
                     ,FCR2.parent_request_id  POS_PARENT_RID
                FROM fnd_concurrent_requests     FCR 
                    ,fnd_concurrent_programs     FCP
                    ,fnd_concurrent_programs_tl  PFCP 
                    ,fnd_concurrent_requests     FCR2 
                    ,fnd_concurrent_programs     FCP2
                    ,fnd_concurrent_programs_tl  PFCP2
               WHERE FCP2.concurrent_program_name = 'XX_AR_SUMMARIZE_POS_INV_CHILD'
                 -- XX_AR_SUMMARIZE_POS_INV_CHILD (parent program)
                 AND FCR2.concurrent_program_id   = FCP2.concurrent_program_id
                 AND FCR2.program_application_id  = FCP2.application_id
                 AND FCP2.application_id          = 20043
                 AND FCP2.concurrent_program_id   = PFCP2.concurrent_program_id
                 AND FCP2.application_id          = PFCP2.application_id
                 AND PFCP2.language               = 'US'
                 AND FCR2.request_id              = FCR.parent_request_id
                 -- RAXMTR (child program)
                 AND FCR.concurrent_program_id     = FCP.concurrent_program_id 
                 AND FCR.program_application_id    = FCP.application_id
                 AND FCP.concurrent_program_name   = 'RAXMTR' -- Autoinvoice Master
                 AND FCP.application_id            = 222
                 AND FCP.concurrent_program_id     = PFCP.concurrent_program_id
                 AND FCP.application_id            = PFCP.application_id
                 AND PFCP.language                 = 'US'
                 ) PR
        WHERE PR.ai_master_rid            = CFCR.parent_request_id
          AND CFCR.concurrent_program_id  = CFC.concurrent_program_id
          AND CFCR.program_application_id = CFC.application_id
          AND CFCR.request_id             = RCTL.request_id
          GROUP BY PR.ai_master_rid
                  ,PR.pos_child_rid
                  ,PR.pos_parent_rid) ai
 WHERE FCP.concurrent_program_name   = 'XX_AR_SUMMARIZE_POS_INVOICES'
   AND FCP.application_id            = 20043
   AND FCP.concurrent_program_id     = FCR.concurrent_program_id
   AND FCP.application_id            = FCR.program_application_id
   AND FCP.concurrent_program_id     = FCPT.concurrent_program_id
   AND FCP.application_id            = FCPT.application_id
   AND FCPT.language                 = 'US'
   AND FCR.requested_by              = FU.user_id
   AND FCR.request_id                = AI.pos_parent_rid
 GROUP BY FCR.request_id
         ,'SUMMARY_INV'
         ,FCR.actual_start_date
         ,FCR.actual_completion_date
         ,ROUND((FCR.actual_completion_date - FCR.actual_start_date) * 24 * 60 * 60,0)
         ,FCR.argument6
         ,TO_DATE(SUBSTR(FCR.argument_text,1,10),'YYYY/MM/DD')
         ,FCR.argument7
         ,FU.user_name
 ORDER BY 1 DESC

/