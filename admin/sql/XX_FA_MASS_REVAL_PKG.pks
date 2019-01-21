SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_FA_MASS_REVAL_PKG
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- +====================================================================+
-- | Name        :  XX_QA_PPT_PKG.pkb		               	        |
-- | Description :  OD QA PPT Processing Package                        |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date        Author             Remarks                    |
-- |========  =========== ================== ===========================|
-- |1.0       03-Oct-2011 Paddy Sanjeevi     Initial version            |
-- |1.1       19-Feb-2015 Paddy Sanjeevi     Modified for Reval by asset| 
-- +====================================================================+
AS

p_request_id   NUMBER;

p_report_type  VARCHAR2(100);

p_asset_where  VARCHAR2(3200);

function BeforeReportTrigger return boolean;


PROCEDURE asset_revaluation( x_errbuf      	OUT NOCOPY VARCHAR2
                            ,x_retcode     	OUT NOCOPY VARCHAR2
			    ,p_txn_type	    	IN  VARCHAR2
			    ,p_process_mode 	IN  VARCHAR2
  		           );


PROCEDURE reval_by_asset ( x_errbuf      	OUT NOCOPY VARCHAR2
                          ,x_retcode     	OUT NOCOPY VARCHAR2
			  ,p_txn_type	    	IN  VARCHAR2
			  ,p_process_mode 	IN  VARCHAR2
  		         );

END;
/
