SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_TASKS_REP_CRTD_BY_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_REP_CRTD_BY_DIM_V.vw                        |
-- | Description :  Tasks Created by Dim  View(for all reps)           |
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
SELECT
distinct created_by_resource_id id, created_by_resource_name name
from apps.XXBI_TASKS_DB_REP_FCT_V;
----------------------------------------------------------
-- Grant to XXCRM
----------------------------------------------------------
GRANT ALL ON APPS.XXBI_TASKS_REP_CRTD_BY_DIM_V TO XXCRM;

SHOW ERRORS;
EXIT;