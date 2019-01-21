SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_UPD_PO_LOCATIONS_PKG
-- +========================================================================================+
-- |                  Office Depot - Project Simplify                                       |
-- |                   Oracle Consulting Organization                                       |
-- +========================================================================================+
-- | Name        :  XX_CDH_UPD_PO_LOCATIONS_PKG.pkb                                         |
-- | Description :  CDH Populate PO LOCATION ASSOCIATIONS Pkg Body                          |
-- |                                                                                        |
-- |Change Record:                                                                          |
-- |===============                                                                         |
-- |Version   Date        Author             Remarks                                        |
-- |========  =========== ================== ===============================================|
-- |      1.0 07-Apr-2008 Sreedhar Mohan     Created code to insert po_locations            |
-- +========================================================================================+
AS

PROCEDURE main
      (  x_errbuf            OUT NOCOPY VARCHAR2,
         x_retcode           OUT NOCOPY VARCHAR2
      );

END XX_CDH_UPD_PO_LOCATIONS_PKG;
/
SHOW ERRORS;
