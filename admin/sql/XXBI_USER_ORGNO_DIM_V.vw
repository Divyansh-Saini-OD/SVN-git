SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_USER_ORGNO_DIM_V AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_USER_ORGNO_DIM_V.VW                           |
-- | Description :  Org. No Dimension for Customer/Prospct Dashboard   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  ============      ==========`================|
-- |1.0       03/04/2010  Kishore Jena      Initial Version            |
-- |1.1       05/08/2010  Lokesh Kumar      Modified value for defect  |
-- |                                        6427                       |
-- |                                                                   | 
-- +===================================================================+
SELECT DISTINCT party_id id, concat(org_number,' ('||site_address||')') value
FROM   APPS.XXBI_USER_SITE_DTL_FCT_V
ORDER BY 2;


SHOW ERRORS;
EXIT;
