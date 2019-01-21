SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_TASKS_REP_ENTITY_TYPES_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_REP_ENTITY_TYPES_DIM_V.vw                       |
-- | Description :  Entity Type Dimension View for Rep Task dashboard     |
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
DISTINCT entity_type id, entity_type name
from apps.XXBI_TASKS_DB_REP_FCT_V;
----------------------------------------------------------
-- Grant to XXCRM
----------------------------------------------------------
GRANT ALL ON APPS.XXBI_TASKS_REP_ENTITY_TYPES_DIM_V TO XXCRM;

SHOW ERRORS;
EXIT;
