SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_ACTIVITIES_USER_FCT_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_ACTIVITIES_USER_FCT_V.vw                      |
-- | Description :  Activities Fact View to restrict data by user      |
-- |                logged in.                                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       03/24/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT tfmv."TASK_ID",
  tfmv."CREATED_BY",
  tfmv."CREATED_RESOURCE_ID",
  tfmv."CREATED_RESOURCE_NAME",
  tfmv."CREATION_DATE",
  tfmv."LAST_UPDATED_BY",
  tfmv."LAST_UPDATE_DATE",
  tfmv."TASK_NUMBER",
  tfmv."TASK_TYPE_ID",
  tfmv."TASK_TYPE_NAME",
  tfmv."TASK_STATUS_ID",
  tfmv."TASK_STATUS_NAME",
  tfmv."OWNER_ID",
  tfmv."OWNER_USER_ID",
  tfmv."OWNER_RESOURCE_NAME",
  tfmv."OWNER_RESOURCE_NAME_DUP",
  tfmv."OWNER_TYPE_CODE",
  tfmv."PLANNED_START_DATE",
  tfmv."PARENT_TASK_ID",
  tfmv."DELETED_FLAG",
  tfmv."ACTUAL_START_DATE",
  tfmv."PRIVATE_FLAG",
  tfmv."PUBLISH_FLAG",
  tfmv."ACTUAL_END_DATE",
  tfmv."ENTITY_TYPE",
  tfmv."ENTITY_TYPE_NAME",
  tfmv."ENTITY_ID",
  tfmv."SOURCE_OBJECT_NAME",
  tfmv."PLANNED_END_DATE",
  tfmv."SCHEDULED_START_DATE",
  tfmv."DUE_DATE",
  tfmv."CALENDAR_END_DATE",
  tfmv."TASK_NAME",
  tfmv."DESCRIPTION",
  tfmv."OPEN_FLAG",
  tfmv."PARTY_ID",
  tfmv."PARTY_NAME",
  tfmv."PARTY_NAME_DUPLICATE",
  tfmv."PARTY_SITE_ID",
  tfmv."PARTY_SITE_NAME",
  tfmv."PARTY_SITE_ADDRESS",
  tfmv."ASSIGNED_USER_ID",
  nvl(tfmv.ASSIGNED_RESOURCE_ID,-1) ASSIGNED_RESOURCE_ID,
  tfmv."ASSIGNED_RESOURCE_ID_DUP",
  tfmv."ASSIGNED_RESOURCE_NAME",
  tfmv."ASSIGNED_RESOURCE_NAME_DUP",
  tfmv."ASSIGNED_ROLE_ID",
  tfmv."ASSIGNED_ROLE_NAME",
  tfmv."ASSIGNED_GROUP_ID",
  tfmv."M1_RESOURCE_ID",
  tfmv."M1_USER_ID",
  tfmv."M1_RESOURCE_NAME",
  tfmv."M2_USER_ID",
  tfmv."M2_RESOURCE_ID",
  tfmv."M2_RESOURCE_NAME",
  tfmv."M3_USER_ID",
  tfmv."M3_RESOURCE_ID",
  tfmv."M3_RESOURCE_NAME",
  tfmv."M4_USER_ID",
  tfmv."M4_RESOURCE_ID",
  tfmv."M4_RESOURCE_NAME",
  tfmv."TASK_WEEK_ID",
  tfmv."TASK_YEAR_ID",
  tfmv."TASK_WEEK_NUMBER",
  tfmv."TASK_WEEK_DESC",
  tfmv."ORG_NUMBER",
  tfmv."ORG_NUMBER_DUPLICATE",
  tfmv."ORG_TYPE",
  tfmv."ORG_TYPE_DUPLICATE",
  tfmv."SITE_USE",
  tfmv."SITE_USE_DUPLICATE",
  tfmv."SITE_ORIG_SYS_REF",
  tfmv."UPDATE_DETAILS",
  tfmv."CREATE_APPOINTMENT",
  tfmv."VIEW_DETAILS",
  tfmv.PARTY_ID PARTY_ID_HL,
  tfmv.PARTY_SITE_ID PARTY_SITE_ID_HL,
tfmv.org_site_status
FROM xxcrm.xxbi_tasks_fct_mv tfmv,
  xxcrm.xxbi_group_mbr_user_id_mv gmi
WHERE(((tfmv.created_by = gmi.map_user_id OR tfmv.owner_user_id = gmi.map_user_id OR 
        (tfmv.assigned_user_id = gmi.map_user_id AND
         -- function to filter records assigned to active res/role/grp for a rep 
         -- and all records for a manager
         xxbi_utility_pkg.check_active_res_role_grp(fnd_global.user_id,
                                                    tfmv.assigned_resource_id,
                                                    tfmv.assigned_role_id,
                                                    tfmv.assigned_group_id
                                                   ) = 'Y'

        )
       )
AND gmi.user_id = fnd_global.user_id
 )
 and TASK_STATUS_NAME IN ('Completed', 'Closed')
and TASK_TYPE_NAME IN ('In Person Visit', 'Call') 
 );
SHOW ERRORS;
--EXIT;