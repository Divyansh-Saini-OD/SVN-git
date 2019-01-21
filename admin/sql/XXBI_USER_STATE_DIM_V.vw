SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_USER_STATE_DIM_V AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_USER_STATE_DIM_V.VW                           |
-- | Description :  State Dimension for Customer/Prospect Dashboard    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  ============      ==========`================|
-- |1.0       03/04/2010  Kishore Jena      Initial Version            |
-- |                                                                   | 
-- +===================================================================+
SELECT DISTINCT state_province id, state_province value
FROM   APPS.XXBI_USER_SUMMARY_FCT_V
ORDER BY 1;


SHOW ERRORS;
EXIT;
