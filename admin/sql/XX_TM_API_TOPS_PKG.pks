SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_TM_API_TOPS_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_API_TOPS_PKG.pks                                                    |
-- | Description : Package Body to perform perform the reassignment of resource,role         |
-- |               and group on the basis of territory ID.                                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   12-Mar-2008       Piyush Khandelwal     Initial draft version                 |
-- |DRAFT 1b   18-Mar-2008       Piyush Khandelwal     Incorporated Code review comments.    |
-- +=========================================================================================+
AS
  -- Global Variable
  
  G_REQUEST_ID                PLS_INTEGER           := FND_GLOBAL.CONC_REQUEST_ID;
    
   --------------------------------------------------------------------------------------------
  --Procedure registered as Concurrent program to perform the reassignment of resource,role --
  -- and group on the basis of territory ID                                                 --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_PROC(X_ERRBUF  OUT NOCOPY VARCHAR2,
                      X_RETCODE OUT NOCOPY NUMBER);

END XX_TM_API_TOPS_PKG;

/
SHOW ERRORS;
EXIT;
