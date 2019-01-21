-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_MON_I1025                                                                |
-- | Description : View to select details of the I1025 MASTER Program                          |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2010/07/21     Bhuvaneswary S  Modified to fetch org_id,cycle_date,event,user_name|
-- |   1.1   2016/02/03     Vasu Raparla    Removed schema References for R.12.2               |
-- +===========================================================================================+

CREATE OR REPLACE FORCE VIEW "XX_MON_I1025" ("REQUEST_ID","PROGRAM_NAME","START_DATE","END_DATE","VOLUME","PROCESSING_TIME_IN_SEC",
"THROUGHPUT","ORG_ID","CYCLE_DATE","EVENT","USER_NAME") AS
  SELECT fcr.parent_request_id                                          Request_ID
         ,'I1025'                                                        Program_name
         ,pcr.actual_start_date                                          start_date
         ,pcr.actual_completion_date                                     end_date
         ,(SELECT COUNT(1)
           FROM xx_om_return_tenders_all xort
           WHERE xort.I1025_process_id LIKE TO_CHAR(fcr.parent_request_id)||'-%' ) volume
         ,ROUND ((pcr.actual_completion_date - pcr.actual_start_date) * (24*60*60)) PROCESSING_TIME_IN_SEC
         ,ROUND ((SELECT COUNT(1)
                  FROM xx_om_return_tenders_all xort
                  WHERE xort.I1025_process_id LIKE TO_CHAR(fcr.parent_request_id)||'-%' )
                  / ( TO_NUMBER(pcr.actual_completion_date - pcr.actual_start_date) * (24*60*60) ),2)  THROUGHPUT
        ,fcr.argument1           ORG_ID       -- Added for Defect#6615
         ,NULL                   CYCLE_DATE
         ,NULL                   EVENT
        ,fu.user_name     -- Added for Defect#6615
  FROM fnd_concurrent_requests fcr,
       fnd_concurrent_programs_vl pcp,
       fnd_concurrent_requests pcr,
       fnd_application fa
      ,fnd_user fu    -- Added for Defect#6615
 WHERE fcr.parent_request_id = pcr.request_id
   AND pcp.application_id = pcr.program_application_id
   AND pcp.concurrent_program_id = pcr.concurrent_program_id
   AND pcp.concurrent_program_name = 'XX_AR_I1025_MASTER'
   AND pcp.application_id= fa.application_id
   AND fa.application_short_name = 'XXFIN'
   AND fcr.parent_request_id > 0
   AND fcr.is_sub_request = 'Y'
   AND fu.user_id = fcr.requested_by             -- Added for Defect#6615
GROUP BY fcr.parent_request_id,
       pcr.actual_start_date,
       pcr.actual_completion_date,
       TO_NUMBER(pcr.actual_completion_date - pcr.actual_start_date) * (24*60*60)
       ,fcr.argument1       -- Added for Defect#6615
       ,FU.USER_NAME        -- Added for Defect#6615
order by request_id;
/