SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_TASKS_DB_REP_FCT_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_DB_REP_FCT_V.vw                             |
-- | Description :  Tasks Fact View to restrict data by sales Rep.     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       02/19/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT tfmv.*
FROM APPS.XXBI_TASKS_FCT_MV tfmv
WHERE ((tfmv.created_by = fnd_global.user_id) OR
(tfmv.assigned_resource_id IN 
(select a.resource_id from apps.jtf_rs_resource_extns_vl a where a.user_id = fnd_global.user_id)));
SHOW ERRORS;
EXIT;