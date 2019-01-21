SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_TM_NAM_TERR_HIST_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_NAM_TERR_HIST_PKG.pks                                               |
-- | Description : Package Body to perform the create records in XX_TM_NAM_TERR_HISTORY_DTLS |
-- |               records based on conversion or interface mode.                            |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   12-Mar-2008       jeevan babu           Initial draft version                 |
-- +=========================================================================================+
AS
  -- Global Variable
  
  G_REQUEST_ID                PLS_INTEGER           := FND_GLOBAL.CONC_REQUEST_ID;
  G_LEVEL_ID                  CONSTANT  NUMBER      := 10001;
  G_LEVEL_VALUE               CONSTANT  NUMBER      := 0;    
   --------------------------------------------------------------------------------------------
  --Procedure registered as Concurrent program to perform the reassignment of resource,role --
  -- and group on the basis of territory ID                                                 --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_CONV_PROC (
                           X_ERRBUF  OUT NOCOPY VARCHAR2,
                           X_RETCODE OUT NOCOPY NUMBER
                           );

PROCEDURE MAIN_INTER_PROC (
                           X_ERRBUF  OUT NOCOPY VARCHAR2,
                           X_RETCODE OUT NOCOPY NUMBER
                         ); 
                       
PROCEDURE MAIN_CUST_PROC(
                           X_ERRBUF  OUT NOCOPY VARCHAR2,
                           X_RETCODE OUT NOCOPY NUMBER
                         ); 
                       
END XX_TM_NAM_TERR_HIST_PKG;

/
SHOW ERRORS;
--EXIT;
