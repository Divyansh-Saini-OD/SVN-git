CREATE OR REPLACE
PACKAGE  xx_cdh_hvop_purge_pkg
AS
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  xx_cdh_hvop_purge_pkg.pks                                           |
-- | Description :  This script purges the entries based on the creation date and the   |
-- |                input parameter p_purge_age                                         |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===========================================|
-- |DRAFT 1a  19-Sep-2008 Kathirvel          Initial draft version                      |
-- +=====================================================================================+

PROCEDURE xx_cdh_hvop_purge_proc(
                                            x_errbuf		OUT NOCOPY    VARCHAR2
                                          , x_retcode		OUT NOCOPY    VARCHAR2
                                          , p_purge_age         IN            NUMBER
					  , p_commit_flag       IN            VARCHAR2
                                          ) ;
                                          
END xx_cdh_hvop_purge_pkg;
/