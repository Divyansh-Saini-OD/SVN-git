CREATE OR REPLACE PACKAGE APPS.xx_ce_recon_form_pkg
AS
   -- +============================================================================================+
   -- |  Office Depot - Project Simplify                                                           |
   -- |  Providge Consulting                                                                       |
   -- +============================================================================================+
   -- |  Name:  XX_CE_RECON_FORM_PKG                                                               |
   -- |  Description:  This package is used by the OD Unmatched CC Deposits form.                  |
   -- |                                                                                            |
   -- |  Change Record:                                                                            |
   -- +============================================================================================+
   -- | Version     Date         Author           Remarks                                          |
   -- | =========   ===========  =============    ===============================================  |
   -- | 1.0         14-Feb-2007  B.Looman         Initial version                                  |
   -- |             03-Jun-2008  D.Gowda          Defect 7632 Add parameter p_trx_001_id to        |
   -- |                                           update submitted_bank_stmt_ln and lockbox_stmt   |
   -- | 2.0         08-Jul-2013  Darshini         E1297 - Modified for R12 Upgrade Retrofit        |
   -- | 2.1         19-SEP-2013  Darshini         E1297 - Modified to change trx_code_id           | 
   -- |                                           to trx_code                                      |
   -- |                                                                                            |
   -- +============================================================================================+

   -- +============================================================================================+
   -- |  Name: GET_AR_SYSTEM_PARAMETERS                                                            |
   -- |  Description: This function fetches the org-specific AR system parameters.                 |
   -- |                  (i.e. set of books, currency, etc.)                                       |
   -- |                                                                                            |
   -- |  Parameters:  x_charts_of_accounts_id - Chart of Accounts for this org                     |
   -- |               x_currency_code - Currency for this org                                      |
   -- |               x_gl_short_name - GL Short Name for this org                                 |
   -- |               x_set_of_books_id - Set of Books for this org                                |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
-- Commented and added by Darshini(2.0) for R12 Upgrade Retrofit
/*   PROCEDURE get_ar_system_parameters(
      x_chart_of_accounts_id  OUT  gl_sets_of_books.chart_of_accounts_id%TYPE
    , x_currency_code         OUT  gl_sets_of_books.currency_code%TYPE
    , x_gl_short_name         OUT  gl_sets_of_books.short_name%TYPE
    , x_set_of_books_id       OUT  gl_sets_of_books.set_of_books_id%TYPE
   ); */
   PROCEDURE get_ar_system_parameters (
      x_chart_of_accounts_id   OUT   gl_ledgers.chart_of_accounts_id%TYPE
    , x_currency_code          OUT   gl_ledgers.currency_code%TYPE
    , x_gl_short_name          OUT   gl_ledgers.short_name%TYPE
    , x_set_of_books_id        OUT   gl_ledgers.ledger_id%TYPE
   );


   -- +============================================================================================+
   -- |  Name: GET_999_INTERFACE_NEXTVAL                                                           |
   -- |  Description: This function gets the nextval from the XX_CE_999_INTERFACE_S sequence.      |
   -- |                                                                                            |
   -- |  Parameters:  N/A                                                                          |
   -- |                                                                                            |
   -- |  Returns :    XX_CE_999_INTERFACE_S.NEXTVAL                                                |
   -- +============================================================================================+
   FUNCTION get_999_interface_nextval
      RETURN NUMBER;

   -- +============================================================================================+
   -- |  Name: GET_LOCKBOX_TRANS_ID_NEXTVAL                                                        |
   -- |  Description: This function gets the nextval from the XX_CE_LOCKBOX_TRANS_ID_S sequence.   |
   -- |                                                                                            |
   -- |  Parameters:  N/A                                                                          |
   -- |                                                                                            |
   -- |  Returns :    XX_CE_LOCKBOX_TRANS_ID_S.NEXTVAL                                             |
   -- +============================================================================================+
   FUNCTION get_lockbox_trans_id_nextval
      RETURN NUMBER;

   -- +============================================================================================+
   -- |  Name: GET_RECON_JRNL_ID_NEXTVAL                                                           |
   -- |  Description: This function gets the nextval from the XX_CE_RECON_JRNL_ID_S sequence.      |
   -- |                                                                                            |
   -- |  Parameters:  N/A                                                                          |
   -- |                                                                                            |
   -- |  Returns :    XX_CE_RECON_JRNL_ID_S.NEXTVAL                                                |
   -- +============================================================================================+
   FUNCTION get_recon_jrnl_id_nextval
      RETURN NUMBER;

   -- +============================================================================================+
   -- |  Name: GET_GL_IFACE_GROUP_ID_NEXTVAL                                                       |
   -- |  Description: This function gets the nextval from the GL_INTERFACE_CONTROL_S sequence.     |
   -- |                                                                                            |
   -- |  Parameters:  N/A                                                                          |
   -- |                                                                                            |
   -- |  Returns :    GL_INTERFACE_CONTROL_S.NEXTVAL                                               |
   -- +============================================================================================+
   FUNCTION get_gl_iface_group_id_nextval
      RETURN NUMBER;

   -- +============================================================================================+
   -- |  Name: IS_BANK_STMT_SUBMITTED                                                              |
   -- |  Description: This function returns True/False if bank deposit statement has already       |
   -- |                 been submitted.                                                            |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |               p_statement_line_id - Statement Line Id                                      |
   -- |                                                                                            |
   -- |  Returns :    TRUE/FALSE (if stmt submitted)                                               |
   -- +============================================================================================+
   FUNCTION is_bank_stmt_submitted(
      p_statement_header_id  IN  ce_statement_headers.statement_header_id%TYPE
    , p_statement_line_id    IN  ce_statement_lines.statement_line_id%TYPE
   )
      RETURN BOOLEAN;

   -- +============================================================================================+
   -- |  Name: LOCKBOX_TRANSMISSIONS_EXIST                                                         |
   -- |  Description: This function returns True/False if lines exist in                           |
   -- |                 XX_CE_LOCKBOX_TRANSMISSIONS for this lockbox statement.                    |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   FUNCTION lockbox_transmissions_exist(
      p_statement_header_id  IN  ce_statement_headers.statement_header_id%TYPE
    , p_bank_account_id      IN  ce_statement_headers.bank_account_id%TYPE
    , p_lockbox_number       IN  ar_lockboxes.lockbox_number%TYPE
    , p_statement_date       IN  ce_statement_headers.statement_date%TYPE
   )
      RETURN BOOLEAN;

   -- +============================================================================================+
   -- |  Name: IS_LOCKBOX_IN_INTERFACE                                                             |
   -- |  Description: This function returns True/False if lines exist in XX_CE_999_INTERFACE for   |
   -- |                 this lockbox statement.                                                    |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   FUNCTION is_lockbox_in_interface(
      p_statement_header_id  IN  ce_statement_headers.statement_header_id%TYPE
    , p_lockbox_number       IN  ar_lockboxes.lockbox_number%TYPE
   )
      RETURN BOOLEAN;

   -- +============================================================================================+
   -- |  Name: CREATE_LOCKBOX_TRANSMISSIONS                                                        |
   -- |  Description: This procedure creates the initial records in XX_CE_LOCKBOX_TRANSMISSIONS    |
   -- |                 for lockbox statement lines.                                               |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   PROCEDURE create_lockbox_transmissions(
      p_statement_header_id  IN      ce_statement_headers.statement_header_id%TYPE
    , p_bank_account_id      IN      ce_statement_headers.bank_account_id%TYPE
    , p_lockbox_number       IN      ar_lockboxes.lockbox_number%TYPE
    , p_statement_date       IN      ce_statement_headers.statement_date%TYPE
    , x_receipt_method_id    OUT     ar_receipt_methods.receipt_method_id%TYPE
   );

   -- +============================================================================================+
   -- |  Name: CREATE_LOCKBOX_INTERFACE_LINES                                                      |
   -- |  Description: This procedure creates the initial records in XX_CE_999_INTERFACE for        |
   -- |                 the lockbox statement lines.                                               |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |               p_receipt_method_id - Receipt Method Id from the Transmission                |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   PROCEDURE create_lockbox_interface_lines(
      p_statement_header_id  IN  ce_statement_headers.statement_header_id%TYPE
    , p_lockbox_number       IN  ar_lockboxes.lockbox_number%TYPE
    , p_receipt_method_id    IN  ar_receipt_methods.receipt_method_id%TYPE
   );

   -- +============================================================================================+
   -- |  Name: UPDATE_SUBMITTED_BANK_STMT_LN                                                       |
   -- |  Description: This procedure updates the statement line for the submitted bank deposit     |
   -- |                 statement.                                                                 |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |               p_statement_line_id - Statement Line Id                                      |
   -- |               p_bank_account_id - Statement Bank Account Id                                |
   -- |               p_interface_trx_id - XX_CE_999_INTERFACE Trx Id                              |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   PROCEDURE update_submitted_bank_stmt_ln(
      p_statement_header_id  IN  ce_statement_headers.statement_header_id%TYPE
    , p_statement_line_id    IN  ce_statement_lines.statement_line_id%TYPE
    , p_interface_trx_id     IN  xx_ce_999_interface.trx_id%TYPE
    , p_trx_001_id           IN  ce_transaction_codes.transaction_code_id%TYPE
	, p_trx_001_code          IN   ce_transaction_codes.trx_code%TYPE --Added for R12 Upgrade Retrofit
   );

   -- +============================================================================================+
   -- |  Name: UPDATE_SUBMITTED_LOCKBOX_STMT                                                       |
   -- |  Description: This procedure updates the statement line for the submitted bank deposit     |
   -- |                 statement.                                                                 |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |               p_bank_account_id - Statement Bank Account Id                                |
   -- |               p_lockbox_number - Lockbox Number                                            |
   -- |               p_statement_date - Statement Date                                            |
   -- |               p_interface_trx_id - XX_CE_999_INTERFACE Trx Id                              |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   PROCEDURE update_submitted_lockbox_stmt(
      p_statement_header_id  IN  ce_statement_headers.statement_header_id%TYPE
    , p_bank_account_id      IN  xx_ce_stmt_cc_deposits_v.bank_account_id%TYPE
    , p_lockbox_number       IN  ar_lockboxes.lockbox_number%TYPE
    , p_statement_date       IN  ce_statement_headers.statement_date%TYPE
    , p_interface_trx_id     IN  xx_ce_999_interface.trx_id%TYPE
    , p_trx_001_id           IN  ce_transaction_codes.transaction_code_id%TYPE
	, p_trx_001_code         IN  ce_transaction_codes.trx_code%TYPE --Added for R12 Upgrade Retrofit
   );

   -- +============================================================================================+
   -- |  Name: CREATE_AJB_CC_GL                                                                    |
   -- |  Description: This procedure creates gl journal enteries for the recon of this AJB stmt.   |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |               p_statement_line_id - Statement Line Id                                      |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   PROCEDURE create_ajb_cc_gl(
      p_statement_header_id  IN  ce_statement_headers.statement_header_id%TYPE
    , p_statement_line_id    IN  ce_statement_lines.statement_line_id%TYPE
   );

   -- +============================================================================================+
   -- |  Name: CREATE_LOCKBOX_GL                                                                   |
   -- |  Description: This procedure creates gl journal enteries for the recon of this lockbox.    |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |               p_bank_account_id - Statement Bank Account Id                                |
   -- |               p_lockbox_number - Lockbox Number                                            |
   -- |               p_statement_date - Statement Date                                            |
   -- |               p_interface_trx_id - XX_CE_999_INTERFACE Trx Id                              |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   PROCEDURE create_lockbox_gl(
      p_statement_header_id  IN  ce_statement_headers.statement_header_id%TYPE
    , p_bank_account_id      IN  xx_ce_stmt_cc_deposits_v.bank_account_id%TYPE
    , p_lockbox_number       IN  ar_lockboxes.lockbox_number%TYPE
    , p_statement_date       IN  ce_statement_headers.statement_date%TYPE
   );

   -- +============================================================================================+
   -- |  Name: DELETE_INCOMPLETE_INTERFACE_LN                                                      |
   -- |  Description: This procedure deletes all manually matched records from xx_ce_999_interface |
   -- |               that have not been Submitted.                                                |
   -- |                                                                                            |
   -- |  Parameters:  N/A                                                                          |
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   PROCEDURE delete_incomplete_interface_ln;
   
   -- +============================================================================================+
   -- |  Name: CHECK_INCOMPLETE_LINES     		                                                   |
   -- |  Description: This procedure updates the incomplete details of manually matched records in |
   -- |               xx_ce_999_interface that have been Submitted.                                |
   -- |                                                                                            |
   -- |  Parameters:  p_statement_header_id - Statement Header Id                                  |
   -- |               p_statement_line_id - Statement Line Id       	                           |
   -- |               p_bank_rec_id - Bank Rec ID                         		                   |
   -- |               p_processor_id - Processor ID                             	               |
   -- |               p_trx_type - Trx Type       							                       |                           
   -- |               p_currency - Currency Code                             					   |      
   -- |                                                                                            |
   -- |  Returns :    N/A                                                                          |
   -- +============================================================================================+
   PROCEDURE CHECK_INCOMPLETE_LINES(
		p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
	  , p_statement_line_id     IN   ce_statement_lines.statement_line_id%TYPE
	  , p_bank_rec_id			IN	 xx_ce_999_interface.bank_rec_id%type
	  , p_processor_id			IN	 xx_ce_999_interface.processor_id%type
	  , p_trx_type				IN	 xx_ce_999_interface.trx_type%type
	  , p_currency				IN	 xx_ce_999_interface.currency_code%type	
	);
END;
/

