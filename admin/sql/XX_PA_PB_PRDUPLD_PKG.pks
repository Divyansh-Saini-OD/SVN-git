SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_PA_PB_PRDUPLD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PB_PRDUPLD_PKG.pkb		               |
-- | Description :  OD PB PA Product Upload Package                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       23-Sep-2010 Paddy Sanjeevi     Initial version           |
-- |1.1       23-Oct-2010 Subbu Saripalli    added xx_submit_conc_prog |
-- +===================================================================+
AS

------------------------------------------------------------------------------------------------
--Declaring xx_process_data
------------------------------------------------------------------------------------------------

FUNCTION get_image_path RETURN VARCHAR2;

PROCEDURE xx_process_data  (  x_errbuf               OUT NOCOPY VARCHAR2
		             ,x_retcode              OUT NOCOPY VARCHAR2
                	   );

PROCEDURE xx_submit_conc_pgm  (  o_request_id               OUT NUMBER
                     );  
END;
/
