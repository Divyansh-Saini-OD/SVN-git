SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_ROQ_PREPROC_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_ROQ_PREPROC_PKG                                                |
-- | Description      : Package Spec for E0406_PO_ROQ_PreProcessor                           |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |Draft 1a   28-MAY-2007       Remya Sasi       Initial draft version                      |
-- |Draft 1b   25-Jul-2007       Remya Sasi       Updated as per Review Comments             |
-- |1.0        25-Jul-2007       Remya Sasi       Baselined                                  |
-- |1.4        28-Nov-2007       Remya Sasi       Changes made for latest MD.050 v6.0        |
-- +=========================================================================================+

AS

PROCEDURE Preproc_Main(
                        x_errbuf        OUT VARCHAR2
                       ,x_retcode       OUT PLS_INTEGER
                       ,p_status_code   IN  VARCHAR2 
                      -- ,p_batch_id      IN  PLS_INTEGER -- Commented out by Remya, V1.4
                       ,p_batch_size    IN  PLS_INTEGER
                       ,p_threads       IN  PLS_INTEGER
                      -- ,p_purge         IN  VARCHAR2 -- Commented out by Remya, V1.4
                       ,p_debug         IN  VARCHAR2
                       );
                       

PROCEDURE Validate_Main(                         
                         x_v_errbuf              OUT VARCHAR2
                        ,x_v_retcode             OUT PLS_INTEGER
                        ,p_validate_thread_id    IN  PLS_INTEGER
                        ,p_debug                 IN  VARCHAR2
                        );
                       

END XX_PO_ROQ_PREPROC_PKG;
/
SHOW ERRORS;

EXIT ;

