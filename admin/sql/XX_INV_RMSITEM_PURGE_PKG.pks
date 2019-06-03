CREATE OR REPLACE PACKAGE APPS.XX_INV_RMSITEM_PURGE_PKG
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- +============================================================================+
-- | Name        :  XX_INV_RMSITEMLOC_PURGE_PKG.pks                             |
-- | Description :  RMS EBS Item Loc Purge                                      |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author             Remarks                            |
-- |========  =========== ================== ===================================|
-- |1.0       10-Jun-2008 Paddy Sanjeevi     Initial version                    |
-- +============================================================================+
AS

PROCEDURE child_main(
                       x_errbuf             OUT NOCOPY VARCHAR2
	              ,x_retcode            OUT NOCOPY VARCHAR2
        	      ,p_process     	    IN  VARCHAR2
                      ,p_batch_id           IN  NUMBER
                    );

--PROCEDURE extract_item(
--                       x_errbuf             OUT NOCOPY VARCHAR2
--	              ,x_retcode            OUT NOCOPY VARCHAR2
--                    );


PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode             OUT NOCOPY VARCHAR2
		     ,p_item_size	    IN  NUMBER
	             ,p_mode                IN  VARCHAR2
        	     ,p_threads             IN  NUMBER
	             ,p_batch_size          IN  NUMBER
                     );

END XX_INV_RMSITEM_PURGE_PKG;
/

