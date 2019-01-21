SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_TASKS_USER_CRTD_BY_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_USER_CRTD_BY_DIM_V.vw                        |
-- | Description :  Tasks Created by Dim  View(for the user logged in)           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       03/24/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT
distinct created_resource_id id, created_resource_name value
from apps.XXBI_TASKS_USER_FCT_V;

SHOW ERRORS;
EXIT;