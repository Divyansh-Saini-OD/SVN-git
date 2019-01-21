SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
SET TERM         ON

PROMPT Creating Package SPECIFICATION XX_CE_BANK_STMT_LOAD_PKG
PROMPT Program exits if the creation is not successful
 
WHENEVER SQLERROR CONTINUE
create or replace
PACKAGE XX_CE_BANK_STMT_LOAD_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      Bank statement Transaction text update program        |
-- | Description : To Update the transaction text with desctiption     |
-- |               of the corresponding transaction code               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |Draft 1   13-MAR-08     Ranjith            Initial version         |
-- |1         22-OCT-2008   Ranjith            Added details for       |
-- |                                           get_trx_desc and        |
-- |                                           get_inv_text functions  |
-- +===================================================================+
-- +===================================================================+
-- | Name : UPDATE_TRX_TEXT                                            |
-- | Description : update the TRX_TEXT field of                        |
-- | CE_STATEMENT_LINES_INTERFACE with description of the              |
-- | corresponding transaction code                                    |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: CE Bank Statement Loader                            |
-- | Parameters : x_error_buff, x_ret_code                             |
-- |                                                                   |
-- | Returns : Returns Code                                            |
-- |           Error Message                                           |
-- +===================================================================+
    PROCEDURE UPDATE_TRX_TEXT (
                     x_error_buff           OUT  NOCOPY    VARCHAR2
                    ,x_ret_code             OUT  NOCOPY    NUMBER
                    ,p_creation_date       IN VARCHAR2
                    ,p_org_id               IN VARCHAR2
                    );
 -- +===================================================================+
-- | Name : SUBMIT_REQUEST                                             |
-- | Description : This submits two requests                           |
-- |          Bank Statement Loader and                                |
-- |          OD: CE Update Transaction Text                           |
-- | Parameters : x_error_buff, x_ret_code,p_process_option,           |
-- |              ,p_load_name ,p_filename	,p_filepath                |
-- | Returns : Returns Code                                            |
-- |           Error Message                                           |
-- +===================================================================+

PROCEDURE SUBMIT_REQUEST (
                    x_error_buff           OUT  NOCOPY    VARCHAR2
                   ,x_ret_code             OUT  NOCOPY    NUMBER
                   ,p_process_option       IN             VARCHAR2
                   ,p_load_name            IN             VARCHAR2
                   ,p_filename			   IN     VARCHAR2
                   ,p_filepath             IN             VARCHAR2
                   ,p_creation_date       IN               VARCHAR2
                            );

 -- +===================================================================+
-- | Name : get_inv_text                                               |
-- | Description : This returns the invoice_text for the given         |
-- |               trx code and bank account number                    |
-- |          OD: CE Update Transaction Text                           |
-- | Parameters : p_trx_code , p_bank_acct_num                         |
-- | Returns : Invoice text                                            |
-- +===================================================================+

FUNCTION get_inv_text(p_trx_code NUMBER
                     ,p_bank_acct_num NUMBER
                     )
RETURN VARCHAR2;
 -- +===================================================================+
-- | Name : get_trx_desc                                               |
-- | Description : This returns the trx description for the given      |
-- |               trx code and bank account number                    |
-- |          OD: CE Update Transaction Text                           |
-- | Parameters : p_trx_code , p_bank_acct_num                         |
-- | Returns : transaction text description                            |
-- +===================================================================+


FUNCTION get_trx_desc(p_trx_code NUMBER
                      ,p_bank_acct_num NUMBER
                      )
RETURN VARCHAR2 ;

END XX_CE_BANK_STMT_LOAD_PKG;
/
SHOW ERROR