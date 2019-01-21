SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_USER_SITENO_MGR_DIM_V AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_USER_SITENO_MGR_DIM_V.vw                      |
-- | Description :  Site No Dimension for Customer/Prospct Dashboard   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  ============      ==========`================|
-- |1.0       03/04/2010  Kishore Jena      Initial Version            |
-- |                                                                   | 
-- +===================================================================+
SELECT DISTINCT party_site_id id, org_site_number value
FROM   APPS.XXBI_USER_SITE_DTL_MGR_FCT_V
ORDER BY 2;


SHOW ERRORS;
EXIT;
