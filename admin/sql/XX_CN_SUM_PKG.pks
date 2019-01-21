SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CN_SUM_PKG AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_CN_SUM_PKG                                                     |
-- |                                                                                |
-- | Description: This procedure will summarize data into custom                    |
-- |              table XX_CN_SUM_TRX                                               |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 12-OCT-2007 Sarah Maria Justina     Initial draft version              |
-- +================================================================================+
   PROCEDURE SUMMARIZE_MAIN (
      x_errbuf        OUT  VARCHAR2,
      x_retcode       OUT  NUMBER,
      p_start_date         VARCHAR2,
      p_end_date           VARCHAR2
   );

END XX_CN_SUM_PKG;
/

SHOW ERRORS
EXIT;