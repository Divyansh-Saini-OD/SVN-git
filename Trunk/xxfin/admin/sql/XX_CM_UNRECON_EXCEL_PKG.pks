create or replace
PACKAGE XX_CM_UNRECON_EXCEL_PKG
AS
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                       WIPRO Technologies                                   |
-- +============================================================================+
-- | Name        : XX_CM_UNRECON_EXCEL_PKG                                      |
-- | RICE ID     : R0542                                                        |
-- | Description : This package is the executable of the wrapper program        |
-- |               that used for submitting the OD: OD:CM Unreconciled          |
-- |               Lines on Active Accounts Report with the desirable           |
-- |		           format of the user, and the default format is EXCEL          |
-- |                                                                            |
-- | Change Record:                                                             |
-- |===============                                                             |
-- |Version   Date              Author              Remarks                     |
-- |======   ==========     =============        =======================        |
-- |Draft 1A  20-FEB-09     Kantharaja Velayutham Initial version               |
-- |                                                                            |
-- |          18-JUL-12     Joe Klein             Defect 18359.  Added          |
-- |                                              parameters                    |
-- |                                              p_transaction_status and      |
-- |                                              p_transaction_code.           |
-- +============================================================================+

-- +============================================================================+
-- | Name       : XX_CM_UNRECON_WRAP_PROC                                       |
-- | Description: The procedure will submit the OD:CM Unreconciled              |
-- |              Lines on Active Accounts Report - Pdf in the specified format |
-- | Parameters : p_bank_name,p_bank_branch_name,p_bank_account_name,           |
-- |              p_bank_account_number,p_transaction_type,                     |
-- |              p_statement_from_date,p_statement_to_date                     |                 
-- | Returns    : x_err_buff,x_ret_code                                         |
-- +============================================================================+

PROCEDURE XX_CM_UNRECON_WRAP_PROC(
                                   x_err_buff            OUT VARCHAR2
                                  ,x_ret_code            OUT NUMBER
				                          ,p_bank_name           IN VARCHAR2
                                  ,p_bank_branch_name    IN VARCHAR2
                                  ,p_bank_account_name   IN VARCHAR2
                                  ,p_bank_account_number IN VARCHAR2
                                  ,p_transaction_type    IN VARCHAR2
                                  ,p_statement_from_date IN VARCHAR2
                                  ,p_statement_to_date   IN VARCHAR2
                                  ,p_transaction_status  IN VARCHAR2
                                  ,p_transaction_code    IN VARCHAR2
				  );

END XX_CM_UNRECON_EXCEL_PKG;

/