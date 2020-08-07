
REM APPS XX_CS_SR_UWQ_AGENT_COUNT_V

  CREATE OR REPLACE FORCE VIEW "APPS"."XX_CS_SR_UWQ_AGENT_COUNT_V" ("INCIDENT_ID", "INCIDENT_NUMBER", "OWNER_ID", "INCIDENT_SEVERITY_ID", "INCIDENT_STATUS_ID", "INCIDENT_TYPE_ID", "OWNER", "RESOURCE_TYPE", "RESOURCE_ID", "IEU_OBJECT_FUNCTION", "IEU_OBJECT_PARAMETERS", "IEU_MEDIA_TYPE_UUID", "IEU_PARAM_PK_COL", "IEU_PARAM_PK_VALUE") AS 
  SELECT inc_b.incident_id,
        inc_b.incident_number,
        inc_b.incident_owner_id owner_id,
        inc_b.incident_severity_id,
        inc_b.incident_status_id,
        inc_b.incident_type_id,
        jtfg.group_name owner,
        inc_b.group_type resource_type,
        inc_b.incident_owner_id resource_id,
        obj.object_function ieu_object_function,
        obj.object_parameters ieu_object_parameters,
        NULL ieu_media_type_uuid,
        'Incident_id' ieu_param_pk_col,
        to_char(inc_b.incident_id) ieu_param_pk_value
  FROM  cs_incidents inc_b,
        jtf_rs_groups_tl jtfg,
        jtf_objects_b obj
  WHERE inc_b.status_flag = 'O'
    AND inc_b.owner_group_id = jtfg.group_id
    AND obj.object_code = 'SR';
 
REM APPS XX_CS_SR_UWQ_AGENT_V

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
        inc_b.incident_attribute_1 linked_orders,
        xx_cs_uwq_dtls.get_elapsed_time(nvl(inc_b.time_zone_id,1),inc_b.creation_date,inc_b.incident_attribute_10) Elapsed_time,
        xx_cs_uwq_dtls.get_tmz_priority(nvl(inc_b.time_zone_id,1),inc_b.incident_attribute_10) tmz_priority,
        xx_cs_uwq_dtls.get_time_to_disp(nvl(inc_b.time_zone_id,1),inc_b.obligation_date,inc_b.incident_attribute_10) tm_to_resp,
        xx_cs_uwq_dtls.get_time_to_disp(nvl(inc_b.time_zone_id,1),inc_b.expected_resolution_date,inc_b.incident_attribute_10) tm_to_resol,
        inc_b.time_zone_id,
        ftb.timezone_code,
        inc_b.object_version_number
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
 
REM APPS XX_CS_SR_UWQ_GROUP_COUNT_V

  CREATE OR REPLACE FORCE VIEW "APPS"."XX_CS_SR_UWQ_GROUP_COUNT_V" ("INCIDENT_ID", "INCIDENT_NUMBER", "OWNER_ID", "INCIDENT_SEVERITY_ID", "INCIDENT_STATUS_ID", "INCIDENT_TYPE_ID", "OWNER", "RESOURCE_TYPE", "RESOURCE_ID", "IEU_OBJECT_FUNCTION", "IEU_OBJECT_PARAMETERS", "IEU_MEDIA_TYPE_UUID", "IEU_PARAM_PK_COL", "IEU_PARAM_PK_VALUE") AS 
  SELECT inc_b.incident_id,
        inc_b.incident_number,
        inc_b.incident_owner_id owner_id,
        inc_b.incident_severity_id,
        inc_b.incident_status_id,
        inc_b.incident_type_id,
        jtfg.group_name owner,
        inc_b.group_type resource_type,
        inc_b.owner_group_id resource_id,
        obj.object_function ieu_object_function,
        obj.object_parameters ieu_object_parameters,
        NULL ieu_media_type_uuid,
        'Incident_id' ieu_param_pk_col,
        to_char(xx_cs_uwq_dtls.get_first(rownum,inc_b.incident_id)) ieu_param_pk_value
  FROM  cs_incidents inc_b,
        jtf_rs_groups_tl jtfg,
        jtf_objects_b obj
  WHERE inc_b.group_type = 'RS_GROUP'
   AND inc_b.status_flag = 'O'
   AND jtfg.group_id = inc_b.owner_group_id
   AND obj.object_code = 'SR';
 
REM APPS XX_CS_SR_UWQ_GROUP_V

  CREATE OR REPLACE FORCE VIEW "APPS"."XX_CS_SR_UWQ_GROUP_V" ("INCIDENT_ID", "INCIDENT_NUMBER", "STATUS", "SUMMARY", "OWNER_ID", "OWNER_GROUP_ID", "OWNER", "SR_TYPE", "ESCALATED", "INCIDENT_SEVERITY_ID", "INCIDENT_STATUS_ID", "INCIDENT_TYPE_ID", "RESOURCE_TYPE", "RESOURCE_ID", "SEVERITY", "IEU_OBJECT_FUNCTION", "IEU_OBJECT_PARAMETERS", "IEU_MEDIA_TYPE_UUID", "IEU_PARAM_PK_COL", "IEU_PARAM_PK_VALUE", "EXPECTED_RESOLUTION_DATE", "OBLIGATION_DATE", "CREATION_DATE", "MODIFIED_DATE", "PROBLEM_CODE", "RESOLUTION_CODE", "URGENCY", "LINKED_ORDERS", "ELAPSED_TIME", "TMZ_PRIORITY", "TM_TO_RESP", "TM_TO_RESOL", "TIME_ZONE_ID", "TIMEZONE_CODE", "OBJECT_VERSION_NUMBER", "FIRST_SR_ID") AS 
  SELECT c.INCIDENT_ID,c.INCIDENT_NUMBER,c.STATUS,c.SUMMARY,c.OWNER_ID,c.OWNER_GROUP_ID,c.OWNER,c.SR_TYPE,c.ESCALATED,c.INCIDENT_SEVERITY_ID,c.INCIDENT_STATUS_ID,c.INCIDENT_TYPE_ID,c.RESOURCE_TYPE,c.RESOURCE_ID,c.SEVERITY,c.IEU_OBJECT_FUNCTION,c.IEU_OBJECT_PARAMETERS,c.IEU_MEDIA_TYPE_UUID,c.IEU_PARAM_PK_COL,c.IEU_PARAM_PK_VALUE,c.EXPECTED_RESOLUTION_DATE,c.OBLIGATION_DATE,c.CREATION_DATE,c.MODIFIED_DATE,c.PROBLEM_CODE,c.RESOLUTION_CODE,c.URGENCY,c.LINKED_ORDERS,c.elapsed_time,c.TMZ_PRIORITY,c.TM_TO_RESP,c.TM_TO_RESOL,c.TIME_ZONE_ID,c.TIMEZONE_CODE,c.OBJECT_VERSION_NUMBER,
       ieu_param_pk_value first_sr_id
FROM
(SELECT inc_b.incident_id,
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
        inc_b.owner_group_id resource_id,
        sev.name severity,
        obj.object_function ieu_object_function,
        obj.object_parameters ieu_object_parameters,
        NULL ieu_media_type_uuid,
        'Incident_id' ieu_param_pk_col,
        to_char(xx_cs_uwq_dtls.get_first(rownum,inc_b.incident_id)) ieu_param_pk_value,
        inc_b.expected_resolution_date,
        inc_b.obligation_date,
        inc_b.creation_date,
        inc_b.last_update_date modified_date,
        inc_b.problem_code,
        inc_b.resolution_code,
        urg.name urgency,
        inc_b.incident_attribute_1 linked_orders,
        xx_cs_uwq_dtls.get_elapsed_time(nvl(inc_b.time_zone_id,1), inc_b.creation_date, inc_b.incident_attribute_10)  Elapsed_time,
        xx_cs_uwq_dtls.get_tmz_priority(nvl(inc_b.time_zone_id,1), inc_b.incident_attribute_10) tmz_priority,
        xx_cs_uwq_dtls.get_time_to_disp(nvl(inc_b.time_zone_id,1),inc_b.obligation_date, inc_b.incident_attribute_10) tm_to_resp,
        xx_cs_uwq_dtls.get_time_to_disp(nvl(inc_b.time_zone_id,1),inc_b.expected_resolution_date, inc_b.incident_attribute_10) tm_to_resol,
        inc_b.time_zone_id,
        ftb.timezone_code,
        inc_b.object_version_number
  FROM  cs_incidents inc_b,
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
  ORDER BY tmz_priority, ftb.upgrade_tz_id, lkp1.lookup_code, tm_to_resp, tm_to_resol) c;
 
REM APPS XX_CS_SR_UWQ_MGR_COUNT_V

  CREATE OR REPLACE FORCE VIEW "APPS"."XX_CS_SR_UWQ_MGR_COUNT_V" ("INCIDENT_ID", "INCIDENT_NUMBER", "OWNER_ID", "INCIDENT_SEVERITY_ID", "INCIDENT_STATUS_ID", "INCIDENT_TYPE_ID", "OWNER", "RESOURCE_TYPE", "RESOURCE_ID", "IEU_OBJECT_FUNCTION", "IEU_OBJECT_PARAMETERS", "IEU_MEDIA_TYPE_UUID", "IEU_PARAM_PK_COL", "IEU_PARAM_PK_VALUE") AS 
  SELECT inc_b.incident_id,
        inc_b.incident_number,
        inc_b.incident_owner_id owner_id,
        inc_b.incident_severity_id,
        inc_b.incident_status_id,
        inc_b.incident_type_id,
        jtfg.group_name owner,
        inc_b.group_type resource_type,
        inc_b.owner_group_id resource_id,
        obj.object_function ieu_object_function,
        obj.object_parameters ieu_object_parameters,
        NULL ieu_media_type_uuid,
        'Incident_id' ieu_param_pk_col,
        to_char(inc_b.incident_id) ieu_param_pk_value
  FROM  cs_incidents inc_b,
        jtf_rs_groups_tl jtfg,
        jtf_objects_b obj
  WHERE inc_b.status_flag = 'O'
    AND inc_b.owner_group_id = jtfg.group_id(+)
    AND obj.object_code = 'SR';
 
REM APPS XX_CS_SR_UWQ_MGR_V

  CREATE OR REPLACE FORCE VIEW "APPS"."XX_CS_SR_UWQ_MGR_V" ("INCIDENT_ID", "INCIDENT_NUMBER", "STATUS", "SUMMARY", "OWNER_ID", "OWNER_GROUP_ID", "OWNER", "SR_TYPE", "ESCALATED", "INCIDENT_SEVERITY_ID", "INCIDENT_STATUS_ID", "INCIDENT_TYPE_ID", "RESOURCE_TYPE", "RESOURCE_ID", "SEVERITY", "IEU_OBJECT_FUNCTION", "IEU_OBJECT_PARAMETERS", "IEU_MEDIA_TYPE_UUID", "IEU_PARAM_PK_COL", "IEU_PARAM_PK_VALUE", "EXPECTED_RESOLUTION_DATE", "OBLIGATION_DATE", "CREATION_DATE", "MODIFIED_DATE", "PROBLEM_CODE", "RESOLUTION_CODE", "URGENCY", "LINKED_ORDERS", "ELAPSED_TIME", "TMZ_PRIORITY", "TM_TO_RESP", "TM_TO_RESOL", "TIME_ZONE_ID", "TIMEZONE_CODE", "OBJECT_VERSION_NUMBER") AS 
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
        inc_b.owner_group_id resource_id,
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
        inc_b.incident_attribute_1 linked_orders,
        xx_cs_uwq_dtls.get_elapsed_time(nvl(inc_b.time_zone_id,1),inc_b.creation_date,inc_b.incident_attribute_10) Elapsed_time,
        xx_cs_uwq_dtls.get_tmz_priority(nvl(inc_b.time_zone_id,1),inc_b.incident_attribute_10) tmz_priority,
        xx_cs_uwq_dtls.get_time_to_disp(nvl(inc_b.time_zone_id,1),inc_b.obligation_date,inc_b.incident_attribute_10) tm_to_resp,
        xx_cs_uwq_dtls.get_time_to_disp(nvl(inc_b.time_zone_id,1),inc_b.expected_resolution_date,inc_b.incident_attribute_10) tm_to_resol,
        inc_b.time_zone_id,
        ftb.timezone_code,
        inc_b.object_version_number
  FROM  cs_incidents inc_b,
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
    AND jtfg.group_id(+) = inc_b.owner_group_id
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
  ORDER BY tmz_priority, ftb.upgrade_tz_id, lkp1.lookup_code, tm_to_resp, tm_to_resol, creation_date;
 