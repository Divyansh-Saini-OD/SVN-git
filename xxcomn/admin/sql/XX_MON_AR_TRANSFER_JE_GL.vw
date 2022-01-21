-- +===========================================================================================+
-- |                                   Office Depot                                            |
-- |                                                                                           |
-- +===========================================================================================+
-- | Name        : XX_MON_AR_TRANSFER_JE_GL.vw                                                 |
-- | RICE#       : E2025                                                                       |
-- | Description : View to select details of the Create Accounting (for AR)                    |
-- |                                                                                           |
-- | Version  Date         Author           Remarks                                            |
-- | =======  ===========  ===============  ===================================================|
-- |  1.0     10-FEB-2014  R. Aldridge      Defect 28157 - Initial creation of view            |
-- |  1.1     14-AUG-2015  Manikant Kasu    made change to convert request_id to number        |
-- |  1.2     12-DEC-2015  Vasu Raparla     Removed Schema References for R12.2                |
-- +===========================================================================================+
CREATE OR REPLACE VIEW APPS.XX_MON_AR_TRANSFER_JE_GL
     (REQUEST_ID
     ,PROGRAM_NAME
     ,START_DATE
     ,END_DATE
     ,VOLUME
     ,PROCESSING_TIME_IN_SEC
     ,THROUGHPUT
     ,ORG_ID
     ,CYCLE_DATE
     ,EVENT
     ,USER_NAME)
AS 
SELECT ACCTG.request_id
      ,ACCTG.program_name
      ,ACCTG.start_date        START_DATE
      ,ACCTG.completion_date   COMPLETION_DATE
      ,ACCTG.records_processed
      ,DECODE(ACCTG.processing_time_in_Sec, 0, 1, ACCTG.processing_time_in_Sec) PROCESSING_TIME_IN_SEC
      ,ROUND(ACCTG.records_processed/DECODE(ACCTG.processing_time_in_Sec, 0, 1, ACCTG.processing_time_in_Sec), 2) THRUPUT
      ,ACCTG.ORG_ID
      ,ACCTG.process_Date                   CYCLE_DATE
      ,NULL                                 EVENT
      ,ACCTG.user_name
 FROM (SELECT /*+ ordered index(XLH XLA_AE_HEADERS_N4)*/ 
              to_number(FCR.request_id)                    REQUEST_ID
             ,'AR_TRANSFER_JE'                             PROGRAM_NAME
             ,FCR.actual_start_date                        START_DATE
             ,FCR.actual_completion_date                   COMPLETION_DATE
             ,FCR.status_code
             ,FCR.phase_code
             ,COUNT(XLL.ae_header_id)                      RECORDS_PROCESSED
             ,ROUND((FCR.actual_completion_date - FCR.actual_start_date) * 24 * 60 * 60) PROCESSING_TIME_IN_SEC
             ,FPO.profile_option_value                     ORG_ID
             ,FU.user_name                                 
             ,TRUNC(TO_DATE(FCR.argument6,'YYYY/MM/DD HH24:MI:SS'))      PROCESS_DATE
         FROM fnd_concurrent_programs        FCP 
             ,fnd_concurrent_requests        FCR
             ,fnd_user                       FU     
             ,fnd_profile_option_values      FPO
             ,xla_ae_headers partition(AR)   XLH
             ,xla_ae_lines   partition(AR)   XLL
        WHERE FCP.concurrent_program_name  = 'XLAGLTRN'                  -- Transfer Journal Entries to GL
          AND FCP.application_id           = 602                         -- Subledger Accounting
          AND FCP.concurrent_program_id    = FCR.concurrent_program_id
          AND FCP.application_id           = FCR.program_application_id
          AND FCR.argument1                = '222'                       -- Receivables
          AND FCR.phase_code               = 'C'
          AND FCR.requested_by             = FU.user_id     
          AND FCR.request_id               = XLH.request_id
          AND TO_NUMBER(FCR.argument2)     = XLH.application_id
          AND XLH.application_id           = 222                         -- Receivables
          AND XLH.ae_header_id             = XLL.ae_header_id
          AND FCR.responsibility_id        = FPO.level_value
          AND FPO.profile_option_id        = (SELECT profile_option_id 
                                                FROM fnd_profile_options 
                                               WHERE profile_option_name = 'ORG_ID')
       GROUP BY FCR.request_id
               ,'AR_TRANSFER_JE'
               ,FCR.actual_start_date
               ,FCR.actual_completion_date
               ,FCR.status_code
               ,FCR.phase_code
               ,ROUND((FCR.actual_completion_date - FCR.actual_start_date) * 24 * 60 * 60)
               ,FPO.profile_option_value 
               ,FU.user_name
               ,TRUNC(TO_DATE(FCR.argument6,'YYYY/MM/DD HH24:MI:SS'))
       ORDER BY FCR.request_id) ACCTG;
/
