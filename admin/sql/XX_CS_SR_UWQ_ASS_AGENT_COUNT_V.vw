 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                                                                   |
 -- +===================================================================+
 -- | Name         :XX_CS_SR_UWQ_ASS_AGENT_COUNT_V                      |
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

CREATE OR REPLACE FORCE VIEW "APPS"."XX_CS_SR_UWQ_ASS_AGENT_COUNT_V" ("INCIDENT_ID", "INCIDENT_NUMBER", "RESOURCE_ID", "INCIDENT_STATUS_ID", "INCIDENT_TYPE_ID", "OWNER", "RESOURCE_TYPE", "RESOURCE_NAME", "IEU_OBJECT_FUNCTION", "IEU_OBJECT_PARAMETERS", "IEU_MEDIA_TYPE_UUID", "IEU_PARAM_PK_COL", "IEU_PARAM_PK_VALUE") AS 
  SELECT inc_b.incident_id,
          inc_b.incident_number,
          inc_b.incident_owner_id resource_id,
          inc_b.incident_status_id,
          inc_b.incident_type_id,
          jtfg.group_name owner,
          inc_b.group_type resource_type,
          jtex.source_name resource_name,
          obj.object_function ieu_object_function,
          obj.object_parameters ieu_object_parameters,
          NULL ieu_media_type_uuid,
          'Incident_id' ieu_param_pk_col,
          to_char(inc_b.incident_id) ieu_param_pk_value
    FROM  cs_incidents inc_b,
          jtf_rs_groups_tl jtfg,
          jtf_objects_b obj,
          jtf_rs_resource_extns jtex
    WHERE inc_b.status_flag = 'O'
      AND inc_b.owner_group_id = jtfg.group_id
      AND inc_b.incident_owner_id IS NOT NULL
      AND jtex.resource_id = inc_b.incident_owner_id
      AND obj.object_code = 'SR'
       AND not exists (select 'x' from fnd_responsibility
                          where responsibility_key like 'XX_%_AGENT%'
                    and responsibility_id = fnd_global.resp_id);
 
 SHOW ERRORS;
