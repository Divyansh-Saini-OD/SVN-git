SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_FA_MASS_RETIRE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_FA_MASS_RETIRE_PKG.pkb		               |
-- | Description :  Plsql package for Fixed Assets Mass Retirement     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       25-Jan-2013 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

G_trx_date 		DATE;

PROCEDURE asset_retirement   ( x_errbuf       OUT NOCOPY VARCHAR2 
                              ,x_retcode      OUT NOCOPY VARCHAR2
        		      ,p_process_mode IN  VARCHAR2
			      ,p_book_type IN  VARCHAR2
		             );


END;
/
