SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_TASKS_USER_FCT_SUMMARY_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_USER_FCT_SUMMARY_V.vw                             |
-- | Description :  Tasks Fact View to restrict data by user logged in.     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       04/12/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT tfmv."TASK_COUNT",
  tfmv."ASSIGNED_USER_ID",
  nvl(tfmv.ASSIGNED_RESOURCE_ID,-1) ASSIGNED_RESOURCE_ID,
  tfmv."ASSIGNED_RESOURCE_NAME",
  tfmv."ASSIGNED_RESOURCE_ID_DUP",
  tfmv."ASSIGNED_ROLE_ID",
  tfmv."ASSIGNED_GROUP_ID",
  tfmv."M4_USER_ID",
  tfmv."M4_RESOURCE_ID",
  tfmv."M4_RESOURCE_NAME",
  tfmv."M3_USER_ID",
  tfmv."M3_RESOURCE_ID",
  tfmv."M3_RESOURCE_NAME",
  tfmv."M2_USER_ID",
  tfmv."M2_RESOURCE_ID",
  tfmv."M2_RESOURCE_NAME",
  tfmv."M1_USER_ID",
  tfmv."M1_RESOURCE_ID",
  tfmv."M1_RESOURCE_NAME",
   tfmv."OWNER_USER_ID",
  tfmv."OWNER_ID",
  tfmv."OWNER_RESOURCE_NAME",
   tfmv."LAST_UPDATED_BY",
   tfmv."CREATED_BY",
  tfmv."CREATED_RESOURCE_ID",
  tfmv."CREATED_RESOURCE_NAME",
  tfmv."ORG_TYPE",
  tfmv."SITE_USE",
  tfmv."ENTITY_TYPE",
  tfmv."ENTITY_TYPE_NAME",
  tfmv."TASK_TYPE_ID",
  tfmv."TASK_TYPE_NAME",
  tfmv."TASK_STATUS_ID",
  tfmv."TASK_STATUS_NAME",
  tfmv."TASK_YEAR_ID",
  tfmv."TASK_WEEK_NUMBER",
  tfmv."TASK_WEEK_DESC",
tfmv."TASK_WEEK_ID",
tfmv.org_site_status
FROM xxcrm.xxbi_tasks_fct_summary_mv tfmv,
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
 AND gmi.user_id = fnd_global.user_id));
SHOW ERRORS;
EXIT;