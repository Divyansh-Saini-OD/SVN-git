SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_TM_ASSGN_TPS_REPORT_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_ASSGN_TPS_REPORT_PKG.pkb                                            |
-- | Description : Package Specification for display Tops Request assignment                 |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   20-May-2008       Jeevan Babu         Initial draft version                   |
-- |V1.0       27-Dec-2014       Pooja Mehra         Created another procedure to generate   |
-- |                                                 OMX data.						         |
-- +=========================================================================================+
as

G_LEVEL_ID                      CONSTANT  NUMBER       := 10001;
G_LEVEL_VALUE                   CONSTANT  NUMBER       := 0;
-- +===================================================================+
-- | Name             : MAIN_PROC                                      |
-- | Description      : This procedure extracts customer assignments   |
-- |                    data, finds its corresponding legacy values    |
-- |                   from  AOPS.                                     |
-- |                                                                   |
-- | parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE MAIN_PROC( x_errbuf              OUT NOCOPY VARCHAR2
                    ,x_retcode             OUT NOCOPY NUMBER
                       ) ;

PROCEDURE OMX_PROC( x_errbuf              OUT NOCOPY VARCHAR2
                    ,x_retcode             OUT NOCOPY NUMBER
                       ) ;

					   
END XX_TM_ASSGN_TPS_REPORT_PKG;

/
SHOW ERRORS;
/