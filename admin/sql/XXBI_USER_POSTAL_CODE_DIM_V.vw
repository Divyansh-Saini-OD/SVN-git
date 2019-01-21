SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_USER_POSTAL_CODE_DIM_V AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_USER_POSTAL_CODE_DIM_V.VW                     |
-- | Description :  PostalCode Dimension for Customer/Prospct Dashboard|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  ============      ==========`================|
-- |1.0       03/04/2010  Kishore Jena      Initial Version            |
-- |                                                                   | 
-- +===================================================================+
SELECT DISTINCT postal_code id, postal_code value
FROM   XXBI_USER_SITE_DTL_FCT_V
ORDER BY 1;

SHOW ERRORS;
EXIT;

  