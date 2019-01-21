SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_TASKS_USER_TASK_STATUSES_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_USER_TASK_STATUSES_DIM_V.vw             |
-- | Description :  Task Status Dimension View for Rep Task dashboard  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       03/04/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
select distinct task_status_id id, name value from apps.jtf_task_statuses_vl 
where upper(name) IN ('COMPLETED', 'CLOSED','ASSIGNED','IN PROGRESS');

SHOW ERRORS;
EXIT;
