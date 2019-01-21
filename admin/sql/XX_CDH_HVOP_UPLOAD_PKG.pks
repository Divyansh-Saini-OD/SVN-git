SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_HVOP_UPLOAD_PKG.pks                         |
-- | Description :  HVOP error upload process program                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  20-NOV-2014 Sridhar Pamu     Initial draft version       |
-- |                                       for defect QC#31926                            |
-- +===================================================================+

CREATE OR REPLACE PACKAGE xx_cdh_hvop_upload_pkg
AS
   PROCEDURE upload_hvop_errors (
      p_errbuf    OUT NOCOPY   VARCHAR2,
      p_retcode   OUT NOCOPY   VARCHAR2
   );
END xx_cdh_hvop_upload_pkg;
/

SHOW ERRORS;