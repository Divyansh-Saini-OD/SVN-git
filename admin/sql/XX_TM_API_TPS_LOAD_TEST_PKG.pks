
SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE XX_TM_API_TPS_LOAD_TEST_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_API_TPS_LOAD_TEST.pks                                               |
-- | Description : Package Spec to insert data in TPS table for load testing                 |
-- |               and group on the basis of territory ID.                                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   17-Mar-2008       Piyush Khandelwal     Initial draft version                 |
-- +=========================================================================================+
AS
  -- Global Variable
  
      
   --------------------------------------------------------------------------------------------
  --Procedure registered as Concurrent program to perform the reassignment of resource,role --
  -- and group on the basis of territory ID                                                 --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_PROC(X_ERRBUF  OUT NOCOPY VARCHAR2,
                      X_RETCODE OUT NOCOPY NUMBER,
                      P_FROM_ENT_ID1 IN NUMBER,
                      P_FROM_ENT_ID2 IN NUMBER,
                      P_TO_ENT_ID1   IN NUMBER,
                      P_TO_ENT_ID2   IN NUMBER,
                      P_From_rownum  IN NUMBER,
                      P_TO_rownum    IN NUMBER                     
                      );

END XX_TM_API_TPS_LOAD_TEST_PKG;

/
SHOW ERRORS;

