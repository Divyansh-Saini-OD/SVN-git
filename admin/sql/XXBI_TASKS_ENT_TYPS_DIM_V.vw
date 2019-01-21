SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_TASKS_USER_ENT_TYPS_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_USER_ENT_TYPS_DIM_V.vw                 |
-- | Description :  Entity Type Dimension View for Task dashboard      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========`================|
-- |1.0       03/24/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT
DISTINCT entity_type id, entity_type value
from apps.XXBI_TASKS_USER_FCT_V;

SHOW ERRORS;
EXIT;
