
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;



CREATE OR REPLACE
PACKAGE XX_CRM_CPD_DEPLOYMENT_CHK_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_UTILITY_PKG.pks                               |
-- | Description :  DBI Package Contains Common Utilities              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0                                      Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS


PROCEDURE object_validate (
         x_errbuf       OUT NOCOPY VARCHAR2,
         x_retcode      OUT NOCOPY VARCHAR2
   );



END XX_CRM_CPD_DEPLOYMENT_CHK_PKG;
/
SHOW ERRORS;