SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CN_AR_EXTRACT_PKG AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_CN_AR_EXTRACT                                                  |
-- |                                                                                |
-- | Description:  This procedure extracts takebacks and givebacks from AR          |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 24-SEP-2007 Sarah Maria Justina        Initial draft version           |
-- |1.0      16-OCT-2007 Sarah Maria Justina        Baselined after Testing         |
-- |1.1      30-OCT-2007 Sarah Maria Justina        Added data type for reporting   |
-- +================================================================================+
   TYPE xx_conc_requests_tbl_type IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE xx_ar_tbl_type IS TABLE OF xx_cn_ar_trx%ROWTYPE
      INDEX BY BINARY_INTEGER;
      
   TYPE xx_error_tbl_type IS TABLE OF VARCHAR2(4000)
      INDEX BY BINARY_INTEGER;

   PROCEDURE notify_clawbacks (
      p_start_date         DATE,
      p_end_date           DATE,
      p_process_audit_id   NUMBER
   );

   PROCEDURE notify_givebacks (
      p_start_date         DATE,
      p_end_date           DATE,
      p_process_audit_id   NUMBER
   );

   PROCEDURE extract_main (
      x_errbuf       OUT   VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_start_date         VARCHAR2 DEFAULT NULL,
      p_end_date           VARCHAR2 DEFAULT NULL,
      p_mode               VARCHAR2
   );

   PROCEDURE extract_clawbacks (
      x_errbuf             OUT   VARCHAR2,
      x_retcode            OUT   NUMBER,
      p_batch_id                 NUMBER,
      p_process_audit_id         NUMBER
   );

   PROCEDURE extract_givebacks (
      x_errbuf             OUT   VARCHAR2,
      x_retcode            OUT   NUMBER,
      p_batch_id                 NUMBER,
      p_process_audit_id         NUMBER
   );
END XX_CN_AR_EXTRACT_PKG;
/

SHOW ERRORS
EXIT;