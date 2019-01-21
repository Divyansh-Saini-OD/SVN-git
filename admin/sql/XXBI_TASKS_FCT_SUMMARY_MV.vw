SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW XXCRM.XXBI_TASKS_FCT_SUMMARY_MV
  BUILD DEFERRED
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_FCT_SUMMARY_MV.vw                               |
-- | Description :  Tasks Fact Materialized View(for all reps)         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       04/12/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- +===================================================================+
AS
SELECT 
count(TASK_ID) TASK_COUNT,
ASSIGNED_USER_ID,ASSIGNED_RESOURCE_ID,ASSIGNED_RESOURCE_NAME, ASSIGNED_RESOURCE_ID ASSIGNED_RESOURCE_ID_DUP,
M4_USER_ID,M4_RESOURCE_ID,M4_RESOURCE_NAME,
M3_USER_ID,M3_RESOURCE_ID,M3_RESOURCE_NAME,
M2_USER_ID,M2_RESOURCE_ID,M2_RESOURCE_NAME,
M1_USER_ID,M1_RESOURCE_ID,M1_RESOURCE_NAME,
OWNER_M4_USER_ID,OWNER_M4_RESOURCE_ID,OWNER_M4_RESOURCE_NAME,
OWNER_M3_USER_ID,OWNER_M3_RESOURCE_ID,OWNER_M3_RESOURCE_NAME,
OWNER_M2_USER_ID,OWNER_M2_RESOURCE_ID,OWNER_M2_RESOURCE_NAME,
OWNER_M1_USER_ID,OWNER_M1_RESOURCE_ID,OWNER_M1_RESOURCE_NAME,
OWNER_USER_ID,OWNER_ID,OWNER_RESOURCE_NAME,
LAST_UPDATED_M4_USER_ID,LAST_UPDATED_M4_RESOURCE_ID,LAST_UPDATED_M4_RESOURCE_NAME,
LAST_UPDATED_M3_USER_ID,LAST_UPDATED_M3_RESOURCE_ID,LAST_UPDATED_M3_RESOURCE_NAME,
LAST_UPDATED_M2_USER_ID,LAST_UPDATED_M2_RESOURCE_ID,LAST_UPDATED_M2_RESOURCE_NAME,
LAST_UPDATED_M1_USER_ID,LAST_UPDATED_M1_RESOURCE_ID,LAST_UPDATED_M1_RESOURCE_NAME,
LAST_UPDATED_BY,LAST_UPDATED_RESOURCE_ID,LAST_UPDATED_RESOURCE_NAME,
CREATED_M4_USER_ID,CREATED_M4_RESOURCE_ID,CREATED_M4_RESOURCE_NAME,
CREATED_M3_USER_ID,CREATED_M3_RESOURCE_ID,CREATED_M3_RESOURCE_NAME,
CREATED_M2_USER_ID,CREATED_M2_RESOURCE_ID,CREATED_M2_RESOURCE_NAME,
CREATED_M1_USER_ID,CREATED_M1_RESOURCE_ID,CREATED_M1_RESOURCE_NAME,
CREATED_BY, CREATED_RESOURCE_ID,CREATED_RESOURCE_NAME,
ORG_TYPE,
SITE_USE,
ENTITY_TYPE,ENTITY_TYPE_NAME,
TASK_TYPE_ID,TASK_TYPE_NAME,
TASK_STATUS_ID, TASK_STATUS_NAME,
TASK_YEAR_ID, TASK_WEEK_NUMBER, TASK_WEEK_DESC
FROM apps.XXBI_TASKS_FCT_MV
group by 
ASSIGNED_USER_ID,ASSIGNED_RESOURCE_ID,ASSIGNED_RESOURCE_NAME,
M4_USER_ID,M4_RESOURCE_ID,M4_RESOURCE_NAME,
M3_USER_ID,M3_RESOURCE_ID,M3_RESOURCE_NAME,
M2_USER_ID,M2_RESOURCE_ID,M2_RESOURCE_NAME,
M1_USER_ID,M1_RESOURCE_ID,M1_RESOURCE_NAME,
OWNER_M4_USER_ID,OWNER_M4_RESOURCE_ID,OWNER_M4_RESOURCE_NAME,
OWNER_M3_USER_ID,OWNER_M3_RESOURCE_ID,OWNER_M3_RESOURCE_NAME,
OWNER_M2_USER_ID,OWNER_M2_RESOURCE_ID,OWNER_M2_RESOURCE_NAME,
OWNER_M1_USER_ID,OWNER_M1_RESOURCE_ID,OWNER_M1_RESOURCE_NAME,
OWNER_USER_ID,OWNER_ID,OWNER_RESOURCE_NAME,
LAST_UPDATED_M4_USER_ID,LAST_UPDATED_M4_RESOURCE_ID,LAST_UPDATED_M4_RESOURCE_NAME,
LAST_UPDATED_M3_USER_ID,LAST_UPDATED_M3_RESOURCE_ID,LAST_UPDATED_M3_RESOURCE_NAME,
LAST_UPDATED_M2_USER_ID,LAST_UPDATED_M2_RESOURCE_ID,LAST_UPDATED_M2_RESOURCE_NAME,
LAST_UPDATED_M1_USER_ID,LAST_UPDATED_M1_RESOURCE_ID,LAST_UPDATED_M1_RESOURCE_NAME,
LAST_UPDATED_BY,LAST_UPDATED_RESOURCE_ID,LAST_UPDATED_RESOURCE_NAME,
CREATED_M4_USER_ID,CREATED_M4_RESOURCE_ID,CREATED_M4_RESOURCE_NAME,
CREATED_M3_USER_ID,CREATED_M3_RESOURCE_ID,CREATED_M3_RESOURCE_NAME,
CREATED_M2_USER_ID,CREATED_M2_RESOURCE_ID,CREATED_M2_RESOURCE_NAME,
CREATED_M1_USER_ID,CREATED_M1_RESOURCE_ID,CREATED_M1_RESOURCE_NAME,
CREATED_BY, CREATED_RESOURCE_ID,CREATED_RESOURCE_NAME,
ORG_TYPE,
SITE_USE,
ENTITY_TYPE,ENTITY_TYPE_NAME,
TASK_TYPE_ID,TASK_TYPE_NAME,
TASK_STATUS_ID, TASK_STATUS_NAME,
TASK_YEAR_ID, TASK_WEEK_NUMBER, TASK_WEEK_DESC;
----------------------------------------------------------
-- Grant to APPS
----------------------------------------------------------
GRANT ALL ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV TO APPS;
----------------------------------------------------------
-- Create All indexes
----------------------------------------------------------
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N2
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (ASSIGNED_RESOURCE_ID_DUP);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N3
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (ASSIGNED_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N4
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (ASSIGNED_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N5
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (M1_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N6
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (M1_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N7
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (M2_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N8
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (M2_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N9
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (M3_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N10
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (M3_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N11
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (M4_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N12
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (M4_USER_ID);


CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N13
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N14
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N15
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_M1_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N16
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_M1_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N17
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_M2_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N18
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_M2_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N19
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_M3_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N20
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_M3_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N21
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_M4_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N22
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (OWNER_M4_USER_ID);

CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N23
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_BY);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N24
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N25
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_M1_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N26
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_M1_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N27
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_M2_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N28
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_M2_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N29
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_M3_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N30
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_M3_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N31
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_M4_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N32
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (CREATED_M4_USER_ID);

CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N33
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_BY);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N34
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N35
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_M1_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N36
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_M1_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N37
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_M2_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N38
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_M2_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N39
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_M3_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N40
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_M3_USER_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N41
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_M4_RESOURCE_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N42
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (LAST_UPDATED_M4_USER_ID);


CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N47
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (TASK_YEAR_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N48
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (TASK_WEEK_NUMBER);

CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N50
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (ORG_TYPE);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N51
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (SITE_USE);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N53
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (TASK_STATUS_ID);
CREATE INDEX XXCRM.XXBI_TASKS_FCT_SUMMARY_MV_N54
  ON XXCRM.XXBI_TASKS_FCT_SUMMARY_MV (TASK_TYPE_ID);

SHOW ERRORS;
EXIT;
