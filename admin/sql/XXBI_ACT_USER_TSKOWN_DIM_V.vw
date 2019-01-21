SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_ACT_USER_TSKOWN_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_ACT_USER_TSKOWN_DIM_V.vw                   |
-- | Description :  Tasks Owned by Dim  View(for the user logged in)   |
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
SELECT
distinct owner_id id, owner_resource_name value
from apps.XXBI_ACTIVITIES_USER_FCT_V;

SHOW ERRORS;
EXIT;