-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : XX_MON_AR_WC_EXTRACTS.vw                                                    |
-- | Description : Used for monitor performance of AR Extracts program                         |
-- |                                                                                           |
-- | Change Record:                                                                            |
-- | ===============                                                                           |
-- | Version  Date         Author         Remarks                                              |
-- | =======  ===========  =============  =====================================================|
-- |  1.0     12-JUN-2012  Jay Gupta      Initial version (Defect 12129)                       |
-- |  1.1     2016/02/03  Vasu Raparla    Removed schema References for R.12.2                 |
-- +===========================================================================================+

CREATE OR REPLACE FORCE VIEW XX_MON_AR_WC_EXTRACTS
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
  GLSTG.org_id ORG_ID ,
  GLSTG.process_Date CYCLE_DATE ,
  GLSTG.event_number EVENT ,
  GLSTG.user_name USER_NAME
FROM
  (SELECT FCR.request_id ,
    'WC_AR_EXTRACTS' PROGRAM_NAME ,
    FCR.actual_start_date START_DATE ,
    FCR.actual_completion_date COMPLETION_DATE ,
    SUM(XCIL.total_records) RECORDS_PROCESSED ,
    ROUND((FCR.actual_completion_date - FCR.actual_start_date)*24*60*60) PROCESSING_TIME_IN_SEC ,
    FPO.profile_option_value ORG_ID ,
    FU.user_name ,
    XCIL.cycle_date PROCESS_DATE ,
    XCIL.batch_num EVENT_NUMBER
  FROM fnd_concurrent_requests FCR ,
    fnd_concurrent_programs FCP ,
    xx_crmar_int_log XCIL ,
    fnd_profile_option_values FPO ,
    fnd_user FU ,
    fnd_concurrent_requests FCR_CHILD
  WHERE FCP.application_id      = 20043
  AND FCP.concurrent_program_id = FCR.concurrent_program_id
  AND FCP.application_id        = FCR.program_application_id
  AND FCR.phase_code            = 'C'
  AND FPO.profile_option_id     =
    (SELECT profile_option_id
    FROM fnd_profile_options
    WHERE profile_option_name = 'ORG_ID'
    )
  AND FPO.level_value                  = FCR.responsibility_id
  AND FU.user_id                       = FCR.requested_by
  AND ( ( FCP.concurrent_program_name IN ('XXARDADJWCMT' ,'XXARFADJWCMT' ,'XXARDRAWCMT' ,'XXARFRAWCMT' ,'XXARDPSWCMT' ,'XXARFPSWCMT' ,'XXARDCRWCMT' ,'XXARFCRWCMT' ,'XXARDTXNWCMT' ,'XXARFTXNWCMT')
  AND FCR.request_id                   = FCR_CHILD.parent_request_id
  AND FCR_CHILD.request_id             = XCIL.request_id)
  OR ( FCP.concurrent_program_name     = 'XXIEXEXTWC'
  AND FCR.request_id                   = XCIL.request_id
  AND FCR.request_id                   = FCR_CHILD.request_id) )
  GROUP BY FCR.request_id ,
    'WC_AR_EXTRACTS' ,
    FCR.actual_start_date ,
    FCR.actual_completion_date ,
    ROUND((FCR.actual_completion_date - FCR.actual_start_date)*24*60*60) ,
    FPO.profile_option_value ,
    FU.USER_NAME ,
    XCIL.cycle_date ,
    XCIL.batch_num
  ) GLSTG
ORDER BY 1 DESC;
/
