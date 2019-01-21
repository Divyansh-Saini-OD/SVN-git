SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_USER_CITY_DIM_V AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_USER_CITY_DIM_V.VW                            |
-- | Description :  City Dimension for Customer/Prospect Dashboard     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  ============      ==========`================|
-- |1.0       03/04/2010  Kishore Jena      Initial Version            |
-- |                                                                   | 
-- +===================================================================+
SELECT DISTINCT city id, city value
FROM   APPS.XXBI_USER_SUMMARY_FCT_V
ORDER BY 1;


SHOW ERRORS;
EXIT;