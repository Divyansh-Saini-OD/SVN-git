CREATE OR REPLACE PACKAGE XX_COM_AUDIT_TRANSACTIONS_PKG AUTHID CURRENT_USER 
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                Oracle NAIO Consulting Organization                        |
-- +===========================================================================+
-- | Name  :       XX_COM_AUDIT_TRANSACTIONS_PKG.pks                           |
-- | Description:  Package specification for audit capture process             |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date           Author                        Remarks             |
-- |=======   ==========  =============    ====================================|
-- |DRAFT 1a  18-SEP-2007  Lalitha Budithi   Initial draft version             |
-- +===========================================================================+
AS


  PROCEDURE CAPTURE_AUDIT (
                             x_errbuf        OUT NOCOPY VARCHAR2
                            ,x_retcode       OUT NOCOPY VARCHAR2
                            ,p_row_id        IN         VARCHAR2
                          --  ,p_audit_table   IN         VARCHAR2
                          );
		 			 		 

END  XX_COM_AUDIT_TRANSACTIONS_PKG;
/
SHOW ERRORS

