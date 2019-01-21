SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_ASN_ADD_LOOKUP_CODE_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name   : XX_ASN_ADD_LOOKUP_CODE_PKG.pks                                                |
-- | Rice Id      : E1307_Site_Level_Attributes                                              |  
-- | Description      : This package adds a new lookup value 'PARTY_SITE'to                  |
-- |                    two lookups ASN_LEAD_VIEW_NOTES and ASN_OPPTY_VIEW_NOTES             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0        20-Nov-2007       Ankur Tandon        Initial Creation                        |
-- |                                                                                         |
-- +=========================================================================================+

AS

      -- +===================================================================+
      -- | Name : create_lookup_value_main                                      |
      -- | Description : This procedure will be called from the Concurrent   |
      -- |               Program 'OD: Create PARTY_SITE Lookup Codes.         |
      -- |                                                                   |
      -- +===================================================================+
      PROCEDURE create_lookup_value_main( x_errbuf  OUT NOCOPY  VARCHAR2
                                      ,x_retcode OUT NOCOPY  NUMBER);
END;
/

SHOW ERROR;