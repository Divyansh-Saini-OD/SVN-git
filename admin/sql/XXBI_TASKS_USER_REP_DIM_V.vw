SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_TASKS_USER_REP_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_USER_REP_DIM_V.vw                       |
-- | Description :  Rep Dimension View for Manager Task dashboard      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       03/29/2010  Anirban Chaudhuri  Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT
DISTINCT assigned_resource_id id, assigned_resource_name value
from apps.XXBI_TASKS_USER_FCT_V;

SHOW ERRORS;
EXIT;
