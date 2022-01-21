  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                Oracle NAIO Consulting Organization                |
  -- +===================================================================+
  -- | Name         :XXOD_CRM_SERVICE_REQUEST_V.vw                       |
  -- | Rice ID      :                                                    |
  -- | Description  :View for all Case Management Reports	         |		
  -- |                                                           	 |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author           Remarks                     |
  -- |=======   ==========  =============    ============================|
  -- |V 1.0		     BI Team	     Taken Backup		 |
  -- |V 1.1 	06-Oct-09    Raj Jagarlamudi Cahnged the Shipeed to Seq  | 
  -- |                                       field and added decode      |
  -- |                                       for Operating_system cloumn |
  -- +===================================================================+
  
  
  
  SET VERIFY OFF;
  WHENEVER SQLERROR CONTINUE;
  WHENEVER OSERROR EXIT FAILURE ROLLBACK;



CREATE OR REPLACE FORCE VIEW "APPS"."XXOD_CRM_SERVICE_REQUEST_V" ("SR_ID", "SR_NUMBER", "SR_DATE", "SR_URGENCY", "SR_SEVERITY", "SR_TYPE", "SR_STATUS", "SR_ORG_ID", "PROBLEM_CODE", "PROBLEM_SUMMARY", "CHANNEL", "CREATED_ON", "RESPONSE_BY", "RESPONSE_ON", "RESPONSE_TIME", "RESOLVED_BY", "RESOLVED_ON", "RESOLVE_TIME", "SR_GROUP_NAME", "SR_GROUP_ID", "CSR", "CUSTOMER", "TIME_ZONE", "RESOLUTION_CODE", "ORDER_NUMBER", "DELIVERY_DATE", "AOPS_CUSTOMER", "SHIP_TO_SEQ", "ESCALATION", "REASSIGNMENT", "STORE_ID", "ORG_ID", "RESOURCE_ID", "CSR_LOC_ID", "OTHER_LOCATION", "SKU", "INQUIRY_TYPE", "CONTRACT", "OFFER", "INCIDENT_CONTEXT", "VENDOR","CLOSE_DATE","LAST_UPDATE_DATE") AS 
  SELECT CI.incident_id               SR_ID
         ,CI.incident_number          SR_NUMBER
         ,CI.incident_date            SR_DATE
         ,CIUT.NAME                   SR_URGENCY
         ,CISEVT.NAME                 SR_SEVERITY
         ,CITT.NAME                   SR_TYPE
         ,CIST.NAME                   SR_STATUS
         ,CI.org_id                   SR_ORG_ID
         ,CL.description              PROBLEM_CODE
         ,CI.summary                  PROBLEM_SUMMARY
         ,CI.sr_creation_channel      CHANNEL
         ,CI.creation_date            CREATED_ON
         ,CI.obligation_date          RESPONSE_BY
         ,CI.inc_responded_by_date    RESPONSE_ON
         ,DECODE(CI.inc_responded_by_date
                 ,NULL, NULL
                 ,xxod_crm_sr_pkg.get_time_diff (CI.incident_date
                                                 ,CI.inc_responded_by_date
                                                 ,CI.incident_attribute_10
                                                )
             )                         RESPONSE_TIME
          ,CI.expected_resolution_date RESOLVED_BY
          ,CI.incident_resolved_date   RESOLVED_ON
          ,DECODE(CI.incident_resolved_date
                  ,NULL, NULL
                  ,xxod_crm_sr_pkg.get_time_diff (CI.incident_date
                                                  ,CI.incident_resolved_date
                                                  ,CI.incident_attribute_10
                                                  )
             )                         RESOLVE_TIME
          ,JRGT.group_name             SR_GROUP_NAME
          , JRGT.group_id              SR_GROUP_ID
          ,JRRE.source_name            CSR
          ,HP.party_name               CUSTOMER
          ,FTB.timezone_code           TIME_ZONE
          ,FLV.meaning                 RESOLUTION_CODE
          ,CI.incident_attribute_1     ORDER_NUMBER
          ,ci.incident_attribute_2    DELIVERY_DATE
          ,ci.incident_attribute_9   AOPS_CUSTOMER
          ,DECODE(NVL(CI.operating_system,'~'),'~','','''' ||operating_system||'''') SHIP_TO_SEQ -- Added to avoid the trunc issues in the report
          ,FLV1.meaning                ESCALATION
          ,xxod_crm_sr_pkg.is_reassigned(CI.incident_id) REASSIGNMENT
          ,CI.incident_attribute_11 STORE_ID
          ,CI.org_id
          ,JRRE.resource_id
          ,CI.incident_attribute_3       CSR_LOC_ID   --- Added for Defect 8330 on 25-Jun-2008
          ,CI.incident_attribute_6       OTHER_LOCATION ------ Added for Defect 8330 on 25-Jun-2008
	    ,CI.incident_attribute_8       SKU
	    ,CI.incident_attribute_4       INQUIRY_TYPE
	    ,CI.incident_attribute_5       CONTRACT
	    ,CI.incident_attribute_12      OFFER
          ,CI.incident_context           INCIDENT_CONTEXT
          ,CI.external_attribute_4   VENDOR         -- Added for Defect#260 on 16-JUL-2009
          ,CI.last_update_date	     last_update_date  --Added for changes to the SR status report
          ,CI.close_date	     close_date    -- Added for changes to the SR status report      
     FROM cs_incidents                CI
          ,jtf_rs_groups_tl           JRGT
          ,jtf_rs_group_usages        JRGU
          ,jtf_rs_resource_extns      JRRE
          ,cs_incident_statuses_vl    CIST
          ,cs_incident_types_tl       CITT
          ,cs_incident_urgencies_tl   CIUT
          ,cs_incident_severities_tl  CISEVT
          ,hz_parties                 HP
          ,fnd_timezones_b            FTB
          ,fnd_lookup_values          FLV
          ,jtf_task_references_b      JTRB
          ,jtf_tasks_b                JTB
          ,fnd_lookup_values          FLV1
	  ,apps.cs_lookups            CL
    WHERE CI.owner_group_id           = JRGT.GROUP_ID(+)
      AND JRGT.GROUP_ID               = JRGU.group_id(+)
      AND CI.incident_owner_id        = JRRE.resource_id(+)
      AND CI.incident_status_id       = CIST.incident_status_id
      AND CI.incident_type_id         = CITT.incident_type_id
      AND CI.incident_urgency_id      = CIUT.incident_urgency_id(+)
      AND CI.incident_severity_id     = CISEVT.incident_severity_id
      AND CI.customer_id              = HP.party_id
      AND CI.time_zone_id             = FTB.upgrade_tz_id(+)
      AND CI.resolution_code          = FLV.lookup_code(+)
      AND JTRB.object_id(+)           = CI.incident_id
      AND JTRB.object_type_code(+)    = 'SR'
      AND JTRB.reference_code(+)      = 'ESC'
      AND JTB.task_id(+)              = JTRB.task_id
      AND FLV1.lookup_type(+)         = 'JTF_TASK_ESC_LEVEL'
      AND FLV.lookup_type(+)          = 'REQUEST_RESOLUTION_CODE'
      AND FLV1.lookup_code(+)         = JTB.escalation_level
      AND NVL(jrgu.usage,'X')         = 'SUPPORT'
      AND CI.org_id = FND_PROFILE.VALUE('ORG_ID')
      AND CL.lookup_type = 'REQUEST_PROBLEM_CODE'
      AND CL.lookup_code = CI.problem_code
      AND CIST.end_date_active IS NULL;

SHOW ERRORS;
