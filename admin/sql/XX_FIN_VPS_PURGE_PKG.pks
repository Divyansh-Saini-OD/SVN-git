create or replace 
PACKAGE XX_FIN_VPS_PURGE_PKG
as
-- =========================================================================================================================
--   NAME:       XX_FIN_VPS_PURGE_PKG .
--   PURPOSE:    This package used to delete all the stagging tables data used in VPS based on specific duration. 
--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  -------------------------------------------------------------------------------
--   1.0        23/10/2017  Uday Jadhav      Created this package. 
-- =========================================================================================================================
procedure purge_process(
						p_errbuf_out              OUT      VARCHAR2
						,p_retcod_out              OUT      VARCHAR2 
                       );

END;
/
