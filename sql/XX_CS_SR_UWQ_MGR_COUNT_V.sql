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
    AND obj.object_code = 'SR'
;
 