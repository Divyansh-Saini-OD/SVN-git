SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_TASKS_USER_TASK_TYPES_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_USER_TASK_TYPES_DIM_V.vw                |
-- | Description :  Task Type Dimension View for Rep Task dashboard    |
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
select distinct task_type_id id, name value from apps.jtf_task_types_vl
where upper (name) IN ('IN PERSON VISIT', 'CALL','EMAIL','MAIL','OTHER');

SHOW ERRORS;
EXIT;
