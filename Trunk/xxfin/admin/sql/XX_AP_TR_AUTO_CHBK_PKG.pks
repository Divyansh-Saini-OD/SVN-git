create or replace 
PACKAGE  XX_AP_TR_AUTO_CHBK_PKG AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_AP_TR_AUTO_CHBK_PKG.pkb                               |
-- | RICE ID   :  E3522_OD Trade Match Foundation                            |
-- | Description :  Plsql package for Auto Chargeback                        |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       12-May-2017 Paddy Sanjeevi     Initial version                 |
-- |1.1       14-Nov-2017 Paddy Sanjeevi     Added Invoice source parameter  |
-- |1.2       19-Sep-2018 Ragni Gupta        Added po_header and po_line id 
--                                           parameter in xx_check_multi_inv function
-- +=========================================================================+
PROCEDURE log_exception (p_program_name       IN  VARCHAR2
                         ,p_error_location     IN  VARCHAR2
		                 ,p_error_msg          IN  VARCHAR2);
PROCEDURE print_debug_msg (p_message   IN VARCHAR2,
                           p_force     IN BOOLEAN DEFAULT FALSE);
PROCEDURE print_out_msg (p_message IN VARCHAR2);
--FUNCTION xx_check_multi_inv(p_invoice_id NUMBER)return varchar2;
FUNCTION xx_check_multi_inv(p_invoice_id NUMBER,p_po_line_id IN NUMBER,p_po_header_id IN NUMBER)return varchar2;
PROCEDURE chargeback_tolerance_check(p_source 		 IN VARCHAr2,
									 p_err_buf      OUT VARCHAR2,
                                     p_retcode      OUT VARCHAR2
                                     );
PROCEDURE main(p_errbuf       OUT  VARCHAR2
              ,p_retcode      OUT  VARCHAR2
			  ,p_source		  IN   VARCHAR2
              ,p_debug        IN   VARCHAR2
			  );
end;
/
SHOW ERRORS;
