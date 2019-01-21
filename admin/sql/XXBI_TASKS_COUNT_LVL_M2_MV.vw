SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW XXCRM.XXBI_TASKS_COUNT_LVL_M2_MV
  BUILD DEFERRED
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_COUNT_LVL_M2_MV.vw                      |
-- | Description :  Tasks Count at Level M2 Materialized View          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       12/04/2010  Anirban C          Initial draft version     |
-- +===================================================================+
AS
select count(task_id) task_count_by_resource, m2_resource_name resource_name
from (SELECT tfmv.*
FROM APPS.XXBI_TASKS_FCT_MV tfmv)
where m2_resource_id is not null
group by m2_resource_id, m2_resource_name
;
----------------------------------------------------------
-- Grant to APPS
----------------------------------------------------------
GRANT ALL ON XXCRM.XXBI_TASKS_COUNT_LVL_M2_MV TO APPS;
----------------------------------------------------------
-- Create All indexes
----------------------------------------------------------


SHOW ERRORS;
EXIT;
