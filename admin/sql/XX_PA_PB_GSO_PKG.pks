SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_PA_PB_GSO_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PB_GSO_PKG.pks    	 	               |
-- | Description :  OD PB GSO PO Interface Package Spec                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       31-Aug-2010 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS


PROCEDURE import_po (
                      x_errbuf             OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                    );



END XX_PA_PB_GSO_PKG;
/
