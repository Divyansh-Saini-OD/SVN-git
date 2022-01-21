SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GI_CON_DECON_LOAD_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name        :  XX_GI_CON_DECON_LOAD_PKG.pks                       |
-- | Description :  This package is used for Consignment Conversion and|
-- |                Deconversion.                                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft 1a  27-Sep-2007 Madhukar Salunke Initial draft version       |
-- +===================================================================+
IS

--+=======================================================================================+
--| PROCEDURE   : Consign_change_load                                                     |
--| Description : This procedures is used to load record from parameters table to consign table|
--| X_ERRBUF               OUT   VARCHAR2                                                 |
--| X_RETCODE              OUT   NUMBER                                                   |
--+=======================================================================================+
PROCEDURE consign_change_load(
          x_errbuf               OUT   VARCHAR2
         ,x_retcode              OUT   NUMBER
          );

gn_conc_req_id             NUMBER       := FND_GLOBAL.CONC_REQUEST_ID;
gn_prog_app_id             NUMBER       := FND_GLOBAL.PROG_APPL_ID;
gn_conc_prog_id            NUMBER       := FND_GLOBAL.CONC_PROGRAM_ID;
gn_user_id                 NUMBER       := FND_GLOBAL.USER_ID;
   
END xx_gi_con_decon_load_pkg;
/
SHOW ERRORS;
EXIT;
-- --------------------------------------------------------------------------------
-- +==============================================================================+
-- |                         End of Script                                        |
-- +==============================================================================+
-- --------------------------------------------------------------------------------