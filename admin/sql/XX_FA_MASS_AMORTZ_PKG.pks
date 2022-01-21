SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_FA_MASS_AMORTZ_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_PPT_PKG.pkb		               	       |
-- | Description :  OD QA PPT Processing Package                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       22-Nov-2012 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

G_AMORTZ_FLAG		VARCHAR2(3);
G_trx_date 		DATE;
G_cal_per_close_date 	DATE;

PROCEDURE asset_amortization ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
                 	      ,p_process_mode 	IN  VARCHAR2
			      ,p_book_type	IN  VARCHAR2	
  		             );


END;
/
