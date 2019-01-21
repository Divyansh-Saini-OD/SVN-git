SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_TM_INSERT_TPS_STG_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_INSERT_TPS_STG_PKG.pks                                              |
-- | Description : Package Spec to insert records in TOPS Staging Table for Retro Assignments|
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   25-Jul-2008       Piyush Khandelwal     Initial draft version                 |
-- |                                                                                         |
-- +=========================================================================================+
AS
  -- Global Variable
  
  --G_REQUEST_ID                PLS_INTEGER           := FND_GLOBAL.CONC_REQUEST_ID;
    
   --------------------------------------------------------------------------------------------
  --Procedure registered as Concurrent program to perform the reassignment of resource,role --
  -- and group on the basis of territory ID                                                 --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_PROC(X_ERRBUF  OUT NOCOPY VARCHAR2,
                      X_RETCODE OUT NOCOPY NUMBER);

END XX_TM_INSERT_TPS_STG_PKG;

/
SHOW ERRORS;
EXIT;
