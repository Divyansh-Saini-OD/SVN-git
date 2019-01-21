SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CRM_CONC_JOBS_ALERTER_PKG AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_CRM_CONC_JOBS_ALERTER_PKG                                      |
-- |                                                                                |
-- | Description:  This procedure alerts the system about abnormal jobs.            |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 12-Jan-2009 Sarah Maria Justina        Initial draft version           |
-- |1.1      12-Jan-2010 Indra Varada               New Procedure for email reports |
-- +================================================================================+

   PROCEDURE main (
      x_errbuf       OUT   VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_module       IN    VARCHAR2,
      p_submodule    IN    VARCHAR2,
      p_application  IN    VARCHAR2
   );
   
   PROCEDURE job_report (
      x_errbuf       OUT   VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_module       IN    VARCHAR2,
      p_submodule    IN    VARCHAR2,
      p_application  IN    VARCHAR2,
      p_rep_period   IN    NUMBER,
      p_mail_to      IN    VARCHAR2
   );

END XX_CRM_CONC_JOBS_ALERTER_PKG;
/

SHOW ERRORS
EXIT;