SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW XXCRM.XXBI_TASKS_FCT_MV
  BUILD DEFERRED
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_FCT_MV.vw                               |
-- | Description :  Tasks Fact Materialized View(for all reps)         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       02/19/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |2.0       03/29/2010  Anirban C          Added a few columns       | 
-- +===================================================================+
AS
SELECT 
t.TASK_ID,t.CREATED_BY,
apps.xxcrm_task_dashboard_helper.get_user_resource_id(t.created_by) CREATED_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_resource_name(t.created_by) CREATED_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_user_m1_user_id(t.created_by) CREATED_M1_USER_ID,
apps.xxcrm_task_dashboard_helper.get_user_m1_res_id(t.created_by) CREATED_M1_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_m1_res_name(t.created_by) CREATED_M1_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_user_m2_user_id(t.created_by) CREATED_M2_USER_ID,
apps.xxcrm_task_dashboard_helper.get_user_m2_res_id(t.created_by) CREATED_M2_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_m2_res_name(t.created_by) CREATED_M2_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_user_m3_user_id(t.created_by) CREATED_M3_USER_ID,
apps.xxcrm_task_dashboard_helper.get_user_m3_res_id(t.created_by) CREATED_M3_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_m3_res_name(t.created_by) CREATED_M3_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_user_m4_user_id(t.created_by) CREATED_M4_USER_ID,
apps.xxcrm_task_dashboard_helper.get_user_m4_res_id(t.created_by) CREATED_M4_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_m4_res_name(t.created_by) CREATED_M4_RESOURCE_NAME,
t.CREATION_DATE,
apps.xxcrm_task_dashboard_helper.get_task_week_id(t.creation_date) CREATION_WEEK_ID,
apps.xxcrm_task_dashboard_helper.get_task_year_id(t.creation_date) CREATION_YEAR_ID,
apps.xxcrm_task_dashboard_helper.get_task_week_number(t.creation_date) CREATION_WEEK_NUMBER,
apps.xxcrm_task_dashboard_helper.get_task_week_desc(t.creation_date) CREATION_WEEK_DESC,
cast(to_char(t.CREATION_DATE, 'J') as number) CREATION_DATE_JULIAN,
t.LAST_UPDATED_BY,
apps.xxcrm_task_dashboard_helper.get_user_resource_id(t.last_updated_by) LAST_UPDATED_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_resource_name(t.last_updated_by) LAST_UPDATED_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_user_m1_user_id(t.last_updated_by) LAST_UPDATED_M1_USER_ID,
apps.xxcrm_task_dashboard_helper.get_user_m1_res_id(t.last_updated_by) LAST_UPDATED_M1_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_m1_res_name(t.last_updated_by) LAST_UPDATED_M1_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_user_m2_user_id(t.last_updated_by) LAST_UPDATED_M2_USER_ID,
apps.xxcrm_task_dashboard_helper.get_user_m2_res_id(t.last_updated_by) LAST_UPDATED_M2_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_m2_res_name(t.last_updated_by) LAST_UPDATED_M2_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_user_m3_user_id(t.last_updated_by) LAST_UPDATED_M3_USER_ID,
apps.xxcrm_task_dashboard_helper.get_user_m3_res_id(t.last_updated_by) LAST_UPDATED_M3_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_m3_res_name(t.last_updated_by) LAST_UPDATED_M3_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_user_m4_user_id(t.last_updated_by) LAST_UPDATED_M4_USER_ID,
apps.xxcrm_task_dashboard_helper.get_user_m4_res_id(t.last_updated_by) LAST_UPDATED_M4_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_user_m4_res_name(t.last_updated_by) LAST_UPDATED_M4_RESOURCE_NAME,
t.LAST_UPDATE_DATE,
apps.xxcrm_task_dashboard_helper.get_task_week_id(t.last_update_date) LAST_UPDATE_WEEK_ID,
apps.xxcrm_task_dashboard_helper.get_task_year_id(t.last_update_date) LAST_UPDATE_YEAR_ID,
apps.xxcrm_task_dashboard_helper.get_task_week_number(t.last_update_date) LAST_UPDATE_WEEK_NUMBER,
apps.xxcrm_task_dashboard_helper.get_task_week_desc(t.last_update_date) LAST_UPDATE_WEEK_DESC,
cast(to_char(t.last_update_DATE, 'J') as number) LAST_UPDATE_DATE_JULIAN,
t.TASK_NUMBER,t.TASK_TYPE_ID,p.name TASK_TYPE_NAME,t.TASK_STATUS_ID, s.name TASK_STATUS_NAME,
t.TASK_PRIORITY_ID,t2.name task_priority_name,t.OWNER_ID,
apps.xxcrm_task_dashboard_helper.get_owner_user_id(t.owner_id) OWNER_USER_ID,
apps.xxcrm_task_dashboard_helper.get_owner_resource_name(t.owner_id) OWNER_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_owner_resource_name(t.owner_id) OWNER_RESOURCE_NAME_DUP,
apps.xxcrm_task_dashboard_helper.get_owner_m1_user_id(t.owner_id) OWNER_M1_USER_ID,
apps.xxcrm_task_dashboard_helper.get_owner_m1_resource_id(t.owner_id) OWNER_M1_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_owner_m1_resource_name(t.owner_id) OWNER_M1_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_owner_m2_user_id(t.owner_id) OWNER_M2_USER_ID,
apps.xxcrm_task_dashboard_helper.get_owner_m2_resource_id(t.owner_id) OWNER_M2_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_owner_m2_resource_name(t.owner_id) OWNER_M2_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_owner_m3_user_id(t.owner_id) OWNER_M3_USER_ID,
apps.xxcrm_task_dashboard_helper.get_owner_m3_resource_id(t.owner_id) OWNER_M3_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_owner_m3_resource_name(t.owner_id) OWNER_M3_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_owner_m4_user_id(t.owner_id) OWNER_M4_USER_ID,
apps.xxcrm_task_dashboard_helper.get_owner_m4_resource_id(t.owner_id) OWNER_M4_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_owner_m4_resource_name(t.owner_id) OWNER_M4_RESOURCE_NAME,
t.OWNER_TYPE_CODE,
t.PLANNED_START_DATE,
t.PARENT_TASK_ID,t.DELETED_FLAG,t.ACTUAL_START_DATE,t.PRIVATE_FLAG,t.PUBLISH_FLAG,
t.ACTUAL_END_DATE,t.SOURCE_OBJECT_TYPE_CODE ENTITY_TYPE,t.SOURCE_OBJECT_TYPE_CODE ENTITY_TYPE_NAME, t.SOURCE_OBJECT_ID ENTITY_ID,
t.SOURCE_OBJECT_NAME, t.PLANNED_END_DATE,t.SCHEDULED_START_DATE,t.SCHEDULED_END_DATE DUE_DATE,
t.CALENDAR_END_DATE, t.TASK_NAME,t.DESCRIPTION, t.OPEN_FLAG,
apps.xxcrm_task_dashboard_helper.get_party_id(t.source_object_type_code, t.source_object_id) PARTY_ID,
apps.xxcrm_task_dashboard_helper.get_party_name(t.source_object_type_code, t.source_object_id) PARTY_NAME,
apps.xxcrm_task_dashboard_helper.get_party_name(t.source_object_type_code, t.source_object_id) PARTY_NAME_DUPLICATE,
apps.xxcrm_task_dashboard_helper.get_party_site_id(t.source_object_type_code, t.source_object_id) PARTY_SITE_ID,
apps.xxcrm_task_dashboard_helper.get_party_site_name
(apps.xxcrm_task_dashboard_helper.get_party_site_id(t.source_object_type_code, t.source_object_id)) PARTY_SITE_NAME,
apps.xxcrm_task_dashboard_helper.get_party_site_address(t.source_object_type_code, t.source_object_id) PARTY_SITE_ADDRESS,
apps.xxcrm_task_dashboard_helper.get_assigned_user_id(t.source_object_type_code, t.source_object_id) ASSIGNED_USER_ID,
apps.xxcrm_task_dashboard_helper.get_assigned_resource_id(t.source_object_type_code, t.source_object_id) ASSIGNED_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_assigned_resource_id(t.source_object_type_code, t.source_object_id) ASSIGNED_RESOURCE_ID_DUP,
apps.xxcrm_task_dashboard_helper.get_assigned_resource_name(t.source_object_type_code, t.source_object_id) ASSIGNED_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_assigned_resource_name(t.source_object_type_code, t.source_object_id) ASSIGNED_RESOURCE_NAME_DUP,
apps.xxcrm_task_dashboard_helper.get_assigned_role_id(t.source_object_type_code, t.source_object_id) ASSIGNED_ROLE_ID,
apps.xxcrm_task_dashboard_helper.get_assigned_group_id(t.source_object_type_code, t.source_object_id) ASSIGNED_GROUP_ID,
apps.xxcrm_task_dashboard_helper.get_m1_resource_id(t.source_object_type_code, t.source_object_id) M1_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_m1_user_id(t.source_object_type_code, t.source_object_id) M1_USER_ID,
apps.xxcrm_task_dashboard_helper.get_m1_resource_name(t.source_object_type_code, t.source_object_id) M1_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_m2_user_id(t.source_object_type_code, t.source_object_id) M2_USER_ID,
apps.xxcrm_task_dashboard_helper.get_m2_resource_id(t.source_object_type_code, t.source_object_id) M2_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_m2_resource_name(t.source_object_type_code, t.source_object_id) M2_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_m3_user_id(t.source_object_type_code, t.source_object_id) M3_USER_ID,
apps.xxcrm_task_dashboard_helper.get_m3_resource_id(t.source_object_type_code, t.source_object_id) M3_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_m3_resource_name(t.source_object_type_code, t.source_object_id) M3_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_m4_user_id(t.source_object_type_code, t.source_object_id) M4_USER_ID,
apps.xxcrm_task_dashboard_helper.get_m4_resource_id(t.source_object_type_code, t.source_object_id) M4_RESOURCE_ID,
apps.xxcrm_task_dashboard_helper.get_m4_resource_name(t.source_object_type_code, t.source_object_id) M4_RESOURCE_NAME,
apps.xxcrm_task_dashboard_helper.get_task_week_id(nvl(t.scheduled_end_date, sysdate)) TASK_WEEK_ID,
apps.xxcrm_task_dashboard_helper.get_task_year_id(nvl(t.scheduled_end_date, sysdate)) TASK_YEAR_ID,
apps.xxcrm_task_dashboard_helper.get_task_week_number(nvl(t.scheduled_end_date, sysdate)) TASK_WEEK_NUMBER,
apps.xxcrm_task_dashboard_helper.get_task_week_desc(nvl(t.scheduled_end_date, sysdate)) TASK_WEEK_DESC,
apps.xxcrm_task_dashboard_helper.get_org_number
(apps.xxcrm_task_dashboard_helper.get_party_site_id(t.source_object_type_code, t.source_object_id)) ORG_NUMBER,
apps.xxcrm_task_dashboard_helper.get_org_number
(apps.xxcrm_task_dashboard_helper.get_party_site_id(t.source_object_type_code, t.source_object_id)) ORG_NUMBER_DUPLICATE,
apps.xxcrm_task_dashboard_helper.get_org_type
(apps.xxcrm_task_dashboard_helper.get_party_site_id(t.source_object_type_code, t.source_object_id)) ORG_TYPE,
apps.xxcrm_task_dashboard_helper.get_org_type
(apps.xxcrm_task_dashboard_helper.get_party_site_id(t.source_object_type_code, t.source_object_id)) ORG_TYPE_DUPLICATE,
apps.xxcrm_task_dashboard_helper.get_site_use
(apps.xxcrm_task_dashboard_helper.get_party_site_id(t.source_object_type_code, t.source_object_id)) SITE_USE,
apps.xxcrm_task_dashboard_helper.get_site_use
(apps.xxcrm_task_dashboard_helper.get_party_site_id(t.source_object_type_code, t.source_object_id)) SITE_USE_DUPLICATE,
apps.xxcrm_task_dashboard_helper.get_site_orig_sys_ref
(apps.xxcrm_task_dashboard_helper.get_party_site_id(t.source_object_type_code, t.source_object_id)) SITE_ORIG_SYS_REF,
'Update' UPDATE_DETAILS, 'Create' CREATE_APPOINTMENT,
'View Details' VIEW_DETAILS
FROM apps.jtf_tasks_vl t, apps.jtf_task_statuses_vl s, apps.jtf_task_types_vl p, 
apps.jtf_task_priorities_vl t2
WHERE t.task_status_id = s.task_status_id(+)
and t.task_type_id = p.task_type_id(+)
and t.task_priority_id = t2.task_priority_id(+);
----------------------------------------------------------
-- Grant to APPS
----------------------------------------------------------
GRANT ALL ON XXCRM.XXBI_TASKS_FCT_MV TO APPS;
----------------------------------------------------------
-- Create All indexes
----------------------------------------------------------

CREATE UNIQUE INDEX XXCRM.XXBI_TASKS_FCT_MV_U1
  ON XXCRM.XXBI_TASKS_FCT_MV (TASK_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N1
  ON XXCRM.XXBI_TASKS_FCT_MV (PARTY_SITE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N2
  ON XXCRM.XXBI_TASKS_FCT_MV (PARTY_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N3
  ON XXCRM.XXBI_TASKS_FCT_MV (ASSIGNED_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N4
  ON XXCRM.XXBI_TASKS_FCT_MV (ASSIGNED_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N5
  ON XXCRM.XXBI_TASKS_FCT_MV (M1_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N6
  ON XXCRM.XXBI_TASKS_FCT_MV (M1_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N7
  ON XXCRM.XXBI_TASKS_FCT_MV (M2_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N8
  ON XXCRM.XXBI_TASKS_FCT_MV (M2_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N9
  ON XXCRM.XXBI_TASKS_FCT_MV (M3_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N10
  ON XXCRM.XXBI_TASKS_FCT_MV (M3_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N11
  ON XXCRM.XXBI_TASKS_FCT_MV (M4_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N12
  ON XXCRM.XXBI_TASKS_FCT_MV (M4_USER_ID);


CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N13
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N14
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N15
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_M1_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N16
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_M1_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N17
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_M2_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N18
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_M2_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N19
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_M3_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N20
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_M3_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N21
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_M4_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N22
  ON XXCRM.XXBI_TASKS_FCT_MV (OWNER_M4_USER_ID);

--CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N23
--  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_BY);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N24
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N25
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_M1_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N26
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_M1_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N27
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_M2_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N28
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_M2_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N29
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_M3_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N30
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_M3_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N31
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_M4_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N32
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATED_M4_USER_ID);

--CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N33
--  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_BY);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N34
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N35
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_M1_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N36
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_M1_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N37
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_M2_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N38
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_M2_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N39
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_M3_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N40
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_M3_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N41
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_M4_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N42
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATED_M4_USER_ID);


CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N43
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATION_YEAR_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N44
  ON XXCRM.XXBI_TASKS_FCT_MV (CREATION_WEEK_NUMBER);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N45
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATE_YEAR_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N46
  ON XXCRM.XXBI_TASKS_FCT_MV (LAST_UPDATE_WEEK_NUMBER);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N47
  ON XXCRM.XXBI_TASKS_FCT_MV (TASK_YEAR_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N48
  ON XXCRM.XXBI_TASKS_FCT_MV (TASK_WEEK_NUMBER);

CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N49
  ON XXCRM.XXBI_TASKS_FCT_MV (ORG_NUMBER);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N50
  ON XXCRM.XXBI_TASKS_FCT_MV (ORG_TYPE);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N51
  ON XXCRM.XXBI_TASKS_FCT_MV (SITE_USE);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N52
  ON XXCRM.XXBI_TASKS_FCT_MV (SITE_ORIG_SYS_REF);

CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N53
  ON XXCRM.XXBI_TASKS_FCT_MV (TASK_STATUS_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N54
  ON XXCRM.XXBI_TASKS_FCT_MV (TASK_TYPE_ID);

CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N55
  ON XXCRM.XXBI_TASKS_FCT_MV (ORG_NUMBER_DUPLICATE);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N56
  ON XXCRM.XXBI_TASKS_FCT_MV (ORG_TYPE_DUPLICATE);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N57
  ON XXCRM.XXBI_TASKS_FCT_MV (SITE_USE_DUPLICATE);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_MV_N58
  ON XXCRM.XXBI_TASKS_FCT_MV (ASSIGNED_RESOURCE_ID_DUP);


SHOW ERRORS;
EXIT;
