 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                                                                   |
 -- +===================================================================+
 -- | Name         :XX_CS_SR_UWQ_AGENT_V                                |
 -- | Description  :Agent UWQ View Creation                             |
 -- |                                                                   |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date        Author              Remarks                  |
 -- |=======   ==========  =============       =========================|
 -- |DRAFT 1A 24-OCT-07  Rajeswari Jagarlamudi   Initial draft version  |
 -- |                                                                   |
 -- +===================================================================+
 
 SET VERIFY OFF;
 WHENEVER SQLERROR CONTINUE;
 WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
 
  CREATE OR REPLACE FORCE VIEW "APPS"."XX_CS_SR_UWQ_AGENT_V" ("INCIDENT_ID", "INCIDENT_NUMBER", "STATUS", "SUMMARY", "OWNER_ID", "OWNER_GROUP_ID", "OWNER", "SR_TYPE", "ESCALATED", "INCIDENT_SEVERITY_ID", "INCIDENT_STATUS_ID", "INCIDENT_TYPE_ID", "RESOURCE_TYPE", "RESOURCE_ID", "SEVERITY", "IEU_OBJECT_FUNCTION", "IEU_OBJECT_PARAMETERS", "IEU_MEDIA_TYPE_UUID", "IEU_PARAM_PK_COL", "IEU_PARAM_PK_VALUE", "EXPECTED_RESOLUTION_DATE", "OBLIGATION_DATE", "CREATION_DATE", "MODIFIED_DATE", "PROBLEM_CODE", "RESOLUTION_CODE", "URGENCY", "LINKED_ORDERS", "ELAPSED_TIME", "TMZ_PRIORITY", "TM_TO_RESP", "TM_TO_RESOL", "TIME_ZONE_ID", "TIMEZONE_CODE", "OBJECT_VERSION_NUMBER") AS 
   SELECT inc_b.incident_id,
          inc_b.incident_number,
          stat.name status,
          inc_b.summary,
          inc_b.incident_owner_id owner_id,
          inc_b.owner_group_id    owner_group_id,
          jtfg.group_name owner,
          typ.name sr_type,
          lkp1.meaning escalated,
          inc_b.incident_severity_id,
          inc_b.incident_status_id,
          inc_b.incident_type_id,
          inc_b.group_type resource_type,
          inc_b.incident_owner_id resource_id,
          sev.name severity,
          obj.object_function ieu_object_function,
          obj.object_parameters ieu_object_parameters,
          NULL ieu_media_type_uuid,
          'Incident_id' ieu_param_pk_col,
          to_char(inc_b.incident_id) ieu_param_pk_value,
          inc_b.expected_resolution_date,
          inc_b.obligation_date,
          inc_b.creation_date,
          inc_b.last_update_date modified_date,
          inc_b.problem_code,
          inc_b.resolution_code,
          urg.name urgency,
          decode(inc_b.incident_attribute_12,null,inc_b.incident_attribute_1,inc_b.incident_attribute_1||','||inc_b.incident_attribute_12) linked_orders,
          xx_cs_uwq_dtls_pkg.get_elapsed_time(nvl(inc_b.time_zone_id,1),inc_b.creation_date,'OD ST CAL') Elapsed_time,
          xx_cs_uwq_dtls_pkg.get_tmz_priority(nvl(inc_b.time_zone_id,1),'OD ST CAL') tmz_priority,
          xx_cs_uwq_dtls_pkg.get_time_to_disp(nvl(inc_b.time_zone_id,1),inc_b.obligation_date,'OD ST CAL') tm_to_resp,
          xx_cs_uwq_dtls_pkg.get_time_to_disp(nvl(inc_b.time_zone_id,1),inc_b.expected_resolution_date,'OD ST CAL') tm_to_resol,
          inc_b.time_zone_id,
          ftb.timezone_code,
          inc_b.object_version_number,
          decode(inc_b.incident_attribute_6,null,inc_b.incident_attribute_2,inc_b.incident_attribute_6) Delivery_date
    FROM  cs_incidents  inc_b,
          cs_incident_statuses_tl stat,
          cs_incident_severities_tl sev,
          cs_incident_types_tl typ,
          cs_incident_urgencies_tl urg,
          jtf_rs_groups_tl jtfg,
          jtf_objects_b obj,
          jtf_task_references_b tsk_ref,
          jtf_tasks_b tsk,
          fnd_lookup_values lkp1,
          fnd_timezones_b ftb
    WHERE inc_b.status_flag = 'O'
      AND inc_b.incident_severity_id = sev.incident_severity_id
      AND inc_b.incident_status_id = stat.incident_status_id
      AND inc_b.incident_type_id = typ.incident_type_id
      AND jtfg.group_id = inc_b.owner_group_id
      AND obj.object_code = 'SR'
      AND tsk_ref.object_id(+) = inc_b.incident_id
      AND tsk_ref.object_type_code(+) = 'SR'
      AND tsk_ref.reference_code(+) = 'ESC'
      AND tsk.task_id(+) = tsk_ref.task_id
      AND lkp1.lookup_type(+) = 'JTF_TASK_ESC_LEVEL'
      AND lkp1.lookup_code(+) = tsk.escalation_level
      AND lkp1.view_application_id(+) = 0
      AND inc_b.incident_urgency_id = urg.incident_urgency_id(+)
      AND nvl(inc_b.time_zone_id,-1) = ftb.upgrade_tz_id(+)
      AND ftb.enabled_flag(+) = 'Y'
    ORDER BY tmz_priority, ftb.upgrade_tz_id, lkp1.lookup_code, tm_to_resp, tm_to_resol;
 
SHOW ERRORS;