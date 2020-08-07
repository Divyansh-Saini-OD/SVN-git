-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : XX_MON_AR_WC_RECON.vw                                                       |
-- | Description : Used for monitor performance of AR Reconciliation program                   |
-- |                                                                                           |
-- | Change Record:                                                                            |
-- | ===============                                                                           |
-- | Version  Date         Author         Remarks                                              |
-- | =======  ===========  =============  =====================================================|
-- |  1.0     12-JUN-2012  Jay Gupta      Initial version (Defect 12129)                       |
-- |  1.1     2016/02/03  Vasu Raparla    Removed schema References for R.12.2                 |
-- +===========================================================================================+

CREATE OR REPLACE FORCE VIEW XX_MON_AR_WC_RECON
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
 SELECT GLSTG.request_id ,
  GLSTG.program_name ,
  GLSTG.start_date START_DATE ,
  GLSTG.completion_date END_DATE ,
  GLSTG.records_processed ,
  DECODE(GLSTG.processing_time_in_Sec, 0, 1, GLSTG.processing_time_in_Sec) PROCESSING_TIME_IN_SEC ,
  ROUND(GLSTG.records_processed / DECODE(GLSTG.processing_time_in_Sec, 0, 1, GLSTG.processing_time_in_Sec), 2) THROUGHPUT ,
  GLSTG.ORG_ID ORG_ID,
  GLSTG.process_Date CYCLE_DATE ,
  GLSTG.event_number EVENT ,
  GLSTG.USER_NAME USER_NAME
FROM
  (SELECT FCR.request_id ,
    'WC_AR_RECON' PROGRAM_NAME ,
    FCR.actual_start_date START_DATE ,
    FCR.actual_completion_date COMPLETION_DATE ,
    SUM(XCIL.total_records) RECORDS_PROCESSED ,
    ROUND((FCR.actual_completion_date - FCR.actual_start_date)*24*60*60) PROCESSING_TIME_IN_SEC ,
    FPO.profile_option_value ORG_ID,
    FU.USER_NAME, 
    XCIL.cycle_date process_Date ,
    XCIL.batch_num event_number
  FROM fnd_concurrent_requests FCR ,
    fnd_concurrent_programs FCP ,
    xx_crmar_int_log XCIL ,
    fnd_profile_option_values FPO, 
    fnd_user FU                    
  WHERE FCP.concurrent_program_name = 'XXARCDHRECON'
  AND FCP.application_id            = 20043    
  AND FCP.concurrent_program_id     = FCR.concurrent_program_id
  AND FCP.application_id            = FCR.program_application_id
  AND FCR.phase_code                = 'C'
    --            AND FCR.request_date            >= (SYSDATE-1)
    --            AND FCR.request_date            <= (SYSDATE)
  AND FPO.profile_option_id =
    (SELECT profile_option_id
    FROM fnd_profile_options
    WHERE profile_option_name = 'ORG_ID'
    )                                        
  AND FPO.level_value = FCR.responsibility_id
  AND FU.user_id      = FCR.requested_by   
  AND FCR.request_id  = XCIL.request_id  
  GROUP BY FCR.request_id,
    'WC_AR_RECON',
    FCR.actual_start_date,
    FCR.actual_completion_date,
    ROUND((FCR.actual_completion_date - FCR.actual_start_date)*24*60*60),
    FPO.profile_option_value,
    FU.USER_NAME,
    XCIL.cycle_date,
    XCIL.batch_num
  ) GLSTG
ORDER BY 1 DESC;
/
