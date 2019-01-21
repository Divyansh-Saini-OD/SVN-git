SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_TASKS_MGR_DSM_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_MGR_DSM_DIM_V.vw                       |
-- | Description :  DSM Dimension View for Manager Task dashboard     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========`================|
-- |1.0       03/04/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT
DISTINCT dsm_resource_id id, dsm_resource_name name
from apps.XXBI_TASKS_DB_MGR_FCT_V;
----------------------------------------------------------
-- Grant to XXCRM
----------------------------------------------------------
GRANT ALL ON APPS.XXBI_TASKS_MGR_DSM_DIM_V TO XXCRM;

SHOW ERRORS;
EXIT;
