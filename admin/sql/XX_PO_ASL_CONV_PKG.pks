SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_ASL_CONV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PO_ASL_CONV_PKG.pks                             |
-- | Description :  PO ASL Conversion Package Spec                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  30-Oct-2007 Paddy Sanjeevi     Initial draft version     |
-- +===================================================================+

AS

----------------------------------------------------------------------------
--Declaring import_asl procedure which gets called FROM OD: PO ASL Interface
----------------------------------------------------------------------------
PROCEDURE import_asl(
                      x_errbuf             OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                    );


END XX_PO_ASL_CONV_PKG;
/
SHOW ERRORS
EXIT;
