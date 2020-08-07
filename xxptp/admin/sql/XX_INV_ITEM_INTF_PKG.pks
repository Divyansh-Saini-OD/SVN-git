SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE APPS.XX_INV_ITEM_INTF_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_INV_ITEM_INTF_PKG.pks                           |
-- | Description :  INV Item Interface from RMS to EBS                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       10-Jun-2008 Paddy Sanjeevi     Initial version           |
-- |1.1       27-Jan-2014 Paddy Sanjeevi     R12 Index Sync            |
-- +===================================================================+
AS

------------------------------------------------------------------------------------------------
--Declaring master_main procedure which gets called from OD: INV Items Conversion Master Program
------------------------------------------------------------------------------------------------

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
	               ,x_retcode             OUT NOCOPY VARCHAR2
      		   ,p_master              IN  VARCHAR2
                     );

----------------------------------------------------------------------------------------------
--Declaring child_main procedure which gets called FROM OD: INV Items Conversion Child Program
----------------------------------------------------------------------------------------------
PROCEDURE child_main(
                      x_errbuf             OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
	               ,p_process	       IN  VARCHAR2
                     ,p_batch_id           IN  NUMBER
                    );


----------------------------------------------------------------------------------------------
--Procedure to submit Item Interface 
----------------------------------------------------------------------------------------------
PROCEDURE RMS_EBS_INTF(
  	                  x_errbuf             OUT NOCOPY VARCHAR2
                       ,x_retcode            OUT NOCOPY VARCHAR2
                      );

PROCEDURE RMS_EBS_EXTRACT(
  	                    x_errbuf             OUT NOCOPY VARCHAR2
                         ,x_retcode            OUT NOCOPY VARCHAR2
                         );


PROCEDURE sync_index(
                      x_errbuf              OUT NOCOPY VARCHAR2
	               ,x_retcode             OUT NOCOPY VARCHAR2
                     );

END XX_INV_ITEM_INTF_PKG;
/
SHOW ERRORS
EXIT;
