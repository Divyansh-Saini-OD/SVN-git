create or replace
PACKAGE XX_TEST_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_TEST_PKG                                                                        |
-- |  Description:  This package is used to test ITG migration and synching with opposite       |
-- |                workflow instances and subversion copy to opposite branch.                  |
-- |  Change Record:   test2                                                                    |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         2011-09-28   Joe Klein        rev 012                                          |
-- | 1.1         2012-04-23   Rajesh           rev 013                                          |
-- | 1.1         2012-04-24   Joe Klein        rev 014  test                                    |
-- +============================================================================================+

  PROCEDURE MAIN
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER);


END XX_TEST_PKG;


/
