SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE APPS.XX_INV_RMS_INT_PURGE_PKG
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- +============================================================================+
-- | Name        :  XX_ITEM_INTF_PKG.pks                                        |
-- | Description :  INV Item Interface from RMS to EBS                          |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author             Remarks                            |
-- |========  =========== ================== ===================================|
-- |1.0       10-Jun-2008 Paddy Sanjeevi     Initial version                    |
-- |1.1       02-Oct-2008 Paddy Sanjeevi     Added RMS_EBS_RECON for            |
-- |                                         Reconciliation between RMS and EBS |
-- |1.2       10-Nov-2008 Paddy Sanjeevi	   Modfied PURGE_PROCESSED_RECS |
-- |                                         procedure to add p_days parameter  |
-- |1.3       04-Jan-2010 Paddy Sanjeevi     Added item_reprocess and           |
-- |                                         send_notification procedure        |
-- +============================================================================+
AS

PROCEDURE SEND_NOTIFICATION( p_subject IN VARCHAR2
			    ,p_email_list IN VARCHAR2
			    ,p_text IN VARCHAR2 );


PROCEDURE item_reprocess( x_errbuf             OUT NOCOPY VARCHAR2
                         ,x_retcode            OUT NOCOPY VARCHAR2
						 ,P_FROM_DATE   IN VARCHAR2
						 ,P_TO_DATE     IN VARCHAR2
			 ,Cat_reproc	       IN  VARCHAR2);

PROCEDURE PURGE_PROCESSED_RECS(
  	                    x_errbuf             OUT NOCOPY VARCHAR2
                         ,x_retcode            OUT NOCOPY VARCHAR2
				 ,p_days		     IN  NUMBER
                         );

PROCEDURE RMS_EBS_RECON(
  	                    x_errbuf             OUT NOCOPY VARCHAR2
                         ,x_retcode            OUT NOCOPY VARCHAR2
                         );

END XX_INV_RMS_INT_PURGE_PKG;
/
SHOW ERRORS
EXIT;
