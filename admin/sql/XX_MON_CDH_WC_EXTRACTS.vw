-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : XX_MON_CDH_WC_EXTRACTS.vw                                                   |
-- | Description : Used for monitor performance of CDH Extract program                         |
-- |                                                                                           |
-- | Change Record:                                                                            |
-- | ===============                                                                           |
-- | Version  Date         Author         Remarks                                              |
-- | =======  ===========  =============  =====================================================|
-- |  1.0     12-JUN-2012  Jay Gupta      Initial version (Defect 12129)                       |
-- |  1.1     2016/02/03  Vasu Raparla    Removed schema References for R.12.2                 |
-- +===========================================================================================+

CREATE OR REPLACE FORCE VIEW XX_MON_CDH_WC_EXTRACTS (request_id ,program_name ,start_date ,end_date ,volume ,processing_time_in_sec ,throughput ,org_id ,cycle_date ,event ,user_name)
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
      'WC_CUST_EXTRACTS' PROGRAM_NAME ,
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
    WHERE FCP.concurrent_program_name IN ('XX_CRM_CUST_SLSAS_EXTRACT_PKG','XX_CRM_CUST_HIER_EXTRACT_PKG'
,'XX_CRM_CUST_CONT_EXTRACT_PKG','XX_CRM_CUST_ADDR_EXTRACT_PKG','XX_CRM_CUST_HEAD_EXTRACT_PKG'
,'XX_CRM_CUST_DELTA_ACCT_ROLES' ,'XX_CRM_CUST_DELTA_PARTIES' ,'XX_CRM_CUST_DELTA_ACCOUNTS' 
,'XX_CRM_CUST_DELTA_CONTACTS' ,'XX_CRM_CUST_DELTA_ACCT_SITES' ,'XX_CRM_CUST_DELTA_PRF_AMTS' 
,'XX_CRM_CUST_DELTA_SITE_USES' ,'XX_CRM_CUST_DELTA_PROFILES' ,'XX_CRM_CUST_DELTA_ORG_CONT' 
,'XX_CRM_CUST_DELTA_PARTY_SITES' ,'XX_CRM_CUST_DELTA_LOCATIONS' ,'XX_CRM_CUST_DELTA_GROUP_MEM' 
,'XX_CRM_CUST_DELTA_TERRITORIES' ,'XX_CRM_CUST_DELTA_CONT_ROLES' ,'XX_CRM_CUST_DELTA_RESOURCE_EXT')
    AND FCP.APPLICATION_ID             = 20044
    AND FCP.concurrent_program_id      = FCR.concurrent_program_id
    AND FCP.application_id             = FCR.program_application_id
    AND FCR.phase_code                 = 'C'
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
      'WC_CUST_EXTRACTS',
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