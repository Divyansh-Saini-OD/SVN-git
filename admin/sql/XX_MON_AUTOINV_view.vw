-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_AUTOINV                                                              |
-- | Description : View to select details of the Autoinvoice Master Program                    |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- |   1.1     2016/02/03   Vasu Raparla    Removed schema References for R.12.2               |
-- +===========================================================================================+

CREATE OR REPLACE FORCE VIEW "XX_MON_AUTOINV" ("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME") AS
SELECT PR.request_id                                        Request_ID
      ,'AutoInv'                                            program_name
      ,pr.start_date                                        start_date
      ,pr.end_date                                          end_date
      ,count(1)                                             Volume
      ,ROUND(PR.thruput_time)                               Processing_Time_In_Sec
      ,round ((count(1)/pr.thruput_time), 2)                throughput
      ,(SUBSTR(CFCR.argument_text,length(argument_text)-3)) org_id
      , NULL cycle_date
      , NULL event
      ,FU.user_name
  FROM fnd_concurrent_requests    CFCR
      ,fnd_concurrent_programs    CFC
      ,ra_customer_trx_lines_all  RCTL
      ,fnd_user FU
      ,(SELECT FCR.request_id
              ,(FCR.actual_completion_date - FCR.actual_start_date) * 24 * 60 * 60 Thruput_Time
              ,PFCP.user_concurrent_program_name                                   Parent_Program
              ,fcr.actual_start_date start_date
              ,fcr.actual_completion_date end_date
          FROM fnd_concurrent_requests    FCR
              ,fnd_concurrent_programs    FCP
              ,fnd_concurrent_programs_tl PFCP
         WHERE FCR.concurrent_program_id    = FCP.concurrent_program_id
           AND FCR.program_application_id   = FCP.application_id
           AND FCP.concurrent_program_name  = 'RAXMTR' -- 'Autoinvoice Master Program'
           AND FCP.application_id           = 222
           AND FCP.concurrent_program_id    = PFCP.concurrent_program_id
           AND FCP.application_id           = PFCP.application_id
           AND PFCP.language                = 'US'
               ) PR
 WHERE PR.request_id              = CFCR.parent_request_id
   AND CFCR.concurrent_program_id = CFC.concurrent_program_id
   AND CFCR.program_application_id   = CFC.application_id
   AND RCTL.request_id            = CFCR.request_id
   AND FU.user_id              = CFCR.requested_by
   AND rctl.line_type = 'LINE'
GROUP BY PR.request_id
        ,PR.parent_program
        ,PR.thruput_time
        ,pr.start_date
        ,pr.end_date
        ,CFCR.argument_text
        ,FU.user_name
ORDER BY PR.request_id;
/