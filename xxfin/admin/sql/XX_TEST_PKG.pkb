  create or replace
PACKAGE BODY XX_TEST_PKG AS


-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_TEST_PKG                                                                        |
-- |  Description:  This package is used to test ITG migration and synching with opposite       |
-- |                workflow instances and subversion copy to opposite branch.                  |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         2011-09-28   Joe Klein        Initial version                                  |
-- | 1.1         2012-04-23   Rajesh           Version 13                                       |
-- | 1.1         2012-04-23   Joe Klein        Version 14 test                                  |
-- | 1.2         2012-07-23   AMS              Testing locks in
-- +============================================================================================+
-- added this comment on 2011-11-01 11:04
-- ===========================================================================
-- procedure for ...
-- ===========================================================================
  PROCEDURE MAIN
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER)
  IS
  BEGIN
    
    fnd_file.put_line(fnd_file.LOG, 'Date and time = ' || sysdate);
    fnd_file.put_line(fnd_file.LOG, 'rev 014 ');
    
  END MAIN;
  
END XX_TEST_PKG;


/
