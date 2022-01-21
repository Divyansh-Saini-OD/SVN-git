-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_REMITTANCE                                                           |
-- | Description : View to select details of the Remittance Master Program                     |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version  Date        Author          Remarks                                               |
-- |=======  ==========  ==============  ======================================================|
-- |   1     2010/07/21  Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name   |
-- |   1     2014/02/14  R.Aldridge      Modified for R12 - Defect 28157                       |
-- |   2     2016/02/03  Vasu Raparla    Removed schema References for R.12.2                  |
-- +===========================================================================================+

CREATE OR REPLACE VIEW XX_MON_REMITTANCE ("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME")
AS
SELECT PR.request_id          Request_Id
      ,'Remittance' || PR.RC                         Program_Name
      ,pr.start_date                                 start_date
      ,pr.end_date                                   end_date
      ,COUNT(1)                                       Record_processed
      ,ROUND (PR.thruput_time)                        Processing_Time_In_Sec
      ,ROUND (COUNT(1)/pr.thruput_time,2)             throughput
      ,PR.ORG_ID     -- Added for Defect#6615
      ,NULL                   CYCLE_DATE
      ,NULL                   EVENT
      ,PR.USER_NAME  -- Added for Defect#6615
  FROM fnd_concurrent_requests    CFCR
      ,fnd_concurrent_programs    CFC
      ,ar_cash_receipt_history_all       RCTL
      ,(SELECT FCR.request_id
              ,(FCR.actual_completion_date - FCR.actual_start_date) * 24 * 60 * 60 Thruput_Time
              ,PFCP.user_concurrent_program_name                                   Parent_Program
              ,fcr.actual_start_date start_date
              ,fcr.actual_completion_date end_date
              ,DECODE(ARC.name, 'US_CC IRECEIVABLES_OD',' - iRec', 'US_CC_OD', ' - AR') RC
              ,FPO.profile_option_value                ORG_ID
              ,FU.user_name
          FROM fnd_concurrent_requests    FCR
              ,fnd_concurrent_programs    FCP
              ,fnd_concurrent_programs_tl PFCP
              ,ar_receipt_classes         ARC
              ,fnd_application            FA
              ,fnd_profile_option_values  FPO
              ,fnd_user                   FU
         WHERE FCP.concurrent_program_name  = 'XX_AR_AUTOREMIT_PKG_SCHEDULER'  --Remittance Master Program
           AND FCP.concurrent_program_id    = FCR.concurrent_program_id
           AND FCR.phase_code               = 'C'
           AND FCP.application_id           = FA.application_id
           AND FA.application_short_name    = 'XXFIN'
           AND FCP.concurrent_program_id    = PFCP.concurrent_program_id
           AND FCP.application_id           = PFCP.application_id
           AND PFCP.LANGUAGE                = 'US'
           AND TO_NUMBER(TRIM(FCR.argument14)) = ARC.receipt_class_id
           AND FPO.profile_option_id        = (SELECT profile_option_id 
                                                 FROM fnd_profile_options
                                                WHERE profile_option_name = 'ORG_ID') 
           AND FPO.level_value              = FCR.responsibility_id 
           AND FU.user_id                   = FCR.requested_by
           ) PR
 WHERE PR.request_id               = CFCR.parent_request_id
   AND CFCR.concurrent_program_id  = CFC.concurrent_program_id
   AND CFC.concurrent_program_name = 'AUTOREMAPI'
   AND CFCR.program_application_id = CFC.application_id
   AND RCTL.request_id             = CFCR.request_id
   AND RCTL.status                 = 'REMITTED'
   AND RCTL.current_record_flag    ='Y'
   GROUP BY PR.request_id
        ,PR.parent_program
        ,PR.thruput_time
        ,pr.start_date
        ,pr.end_date
        ,PR.rc
        ,PR.org_id
        ,PR.user_name
ORDER BY PR.request_id;
/
