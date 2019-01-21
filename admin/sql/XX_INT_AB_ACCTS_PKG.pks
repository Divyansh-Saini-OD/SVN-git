CREATE OR REPLACE PACKAGE XX_INT_AB_ACCTS_PKG AS

-- +====================================================================+
-- | Name  : XX_INT_AB_ACCTS_PKG.LOAD_INT_AB_TABLE                      |
-- | Description      : This Procedure will poplulate the interim table |
-- |                    XX_INT_AB_ACCOUNTS for use by the Credit backup |
-- |                                                                    |
-- | Parameters      none                                               |
-- +====================================================================+

PROCEDURE LOAD_INT_AB_TABLE(errbuf             OUT NOCOPY VARCHAR2,
                            retcode            OUT NOCOPY NUMBER);

-- +====================================================================+
-- | Name  : XX_INT_AB_ACCTS_PKG.UPDATE_INT_AB_TABLE                    |
-- | Description      : This Procedure will poplulate the interim table |
-- |                    XX_INT_AB_ACCOUNTS with open AR amounts         |
-- |                                                                    |
-- | Parameters      none                                               |
-- +====================================================================+

PROCEDURE UPDATE_INT_AB_TABLE(errbuf             OUT NOCOPY VARCHAR2,
                              retcode            OUT NOCOPY NUMBER);

-- +====================================================================+
-- | Name  : XX_INT_AB_ACCTS_PKG.EXTRACT_INT_AB_TABLE                   |
-- | Description      : This Procedure will extract the interim table   |
-- |                    XX_INT_AB_ACCOUNTS for use by the Credit backup |
-- |                                                                    |
-- | Parameters      none                                               |
-- +====================================================================+

PROCEDURE EXTRACT_INT_AB_TABLE(errbuf             OUT NOCOPY VARCHAR2,
                               retcode            OUT NOCOPY NUMBER);

END XX_INT_AB_ACCTS_PKG;
/
