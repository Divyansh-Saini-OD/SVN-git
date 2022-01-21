 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                                                                   |
 -- +===================================================================+
 -- | Name         :XX_CS_SR_UWQ_ASSIGNED_AGENT_V                       |
 -- | Description  :Agent Assigned UWQ View Creation                    |
 -- |                                                                   |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date        Author              Remarks                  |
 -- |=======   ==========  =============       =========================|
 -- |DRAFT 1A 11-AUG-09  Rajeswari Jagarlamudi   Initial draft version  |
 -- |                                                                   |
 -- +===================================================================+
 
  SET VERIFY OFF;
  WHENEVER SQLERROR CONTINUE;
  WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE FORCE VIEW "APPS"."XX_CS_SR_UWQ_ASSIGNED_AGENT_V" ("INCIDENT_ID", "INCIDENT_NUMBER", "STATUS", "SUMMARY", "RESOURCE_ID", "OWNER_GROUP_ID", "OWNER", "SR_TYPE", "INCIDENT_STATUS_ID", "INCIDENT_TYPE_ID", "RESOURCE_TYPE", "RESOURCE_NAME", "EXPECTED_RESOLUTION_DATE", "OBLIGATION_DATE", "CREATION_DATE", "MODIFIED_DATE", "PROBLEM_CODE", "RESOLUTION_CODE", "IEU_OBJECT_FUNCTION", "IEU_OBJECT_PARAMETERS", "IEU_MEDIA_TYPE_UUID", "IEU_PARAM_PK_COL", "IEU_PARAM_PK_VALUE") AS 
  SELECT inc_b.incident_id,
         inc_b.incident_number,
         stat.name status,
         inc_b.summary,
         inc_b.incident_owner_id resource_id,
         inc_b.owner_group_id    owner_group_id,
         jtfg.group_name owner,
         typ.name sr_type,
         inc_b.incident_status_id,
         inc_b.incident_type_id,
         inc_b.group_type resource_type,
         jtex.source_name resource_name,
         inc_b.expected_resolution_date,
         inc_b.obligation_date,
         inc_b.creation_date,
         inc_b.last_update_date modified_date,
         inc_b.problem_code,
         inc_b.resolution_code,
          obj.object_function ieu_object_function,
         obj.object_parameters ieu_object_parameters,
         NULL ieu_media_type_uuid,
         'Incident_id' ieu_param_pk_col,
         to_char(inc_b.incident_id) ieu_param_pk_value
   FROM  cs_incidents  inc_b,
         cs_incident_statuses_tl stat,
         cs_incident_types_tl typ,
         jtf_rs_groups_tl jtfg,
         jtf_objects_b obj,
         jtf_rs_resource_extns jtex
   WHERE inc_b.status_flag = 'O'
     AND obj.object_code = 'SR'
     AND inc_b.incident_status_id = stat.incident_status_id
     AND inc_b.incident_type_id = typ.incident_type_id
     AND jtfg.group_id = inc_b.owner_group_id
     AND jtex.resource_id = inc_b.incident_owner_id
     AND inc_b.incident_owner_id IS NOT NULL
     AND not exists (select 'x' from fnd_responsibility
                          where responsibility_key like 'XX_%_AGENT%'
                    and responsibility_id = fnd_global.resp_id);

                    
SHOW ERRORS;