SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_ACT_USER_TASK_TYPES_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_ACT_USER_TASK_TYPES_DIM_V.vw                  |
-- | Description :  Task Type Dimension View for Activity dashboard    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       03/29/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
select distinct task_type_id id, name value from apps.jtf_task_types_vl
where upper (name) IN ('IN PERSON VISIT', 'CALL');

SHOW ERRORS;
EXIT;
