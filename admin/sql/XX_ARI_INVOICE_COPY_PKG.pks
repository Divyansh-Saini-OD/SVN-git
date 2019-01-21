create or replace
PACKAGE      XX_ARI_INVOICE_COPY_PKG AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify - E1293                                                   |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_ARI_INVOICE_COPY_PKG                                                            |
-- |  Description:  This package is used by iReceivables to send copies of invoices to the      |
-- |           customer via email or fax (through the use of the XML Publisher Delivery Mgr)    |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         25-Jun-2007  B.Looman         Initial version                                  |
-- | 1.1         14-Nov-2008  B.Thomas         Added get get_invoice procs for defect 11979     |
-- | 1.2         08-Jul-2009  B.Thomas         Added procs to get unprinted trx; prd defect 487 |
-- | 1.3         20-Oct-2009  B.Thomas         Updated for consolidated bills R1.2 CR629 E2052  |
-- | 1.5         16-NOV-2016  Suresh Naragam   Changes to purge the XDO requests tables         |
-- |                                           data Defect#39482                                |
-- | 1.6		 10-MAR-2016  Madhu Bolli      Defect#41197 - Added 2 new global variables      |
-- | 1.7         21-Apr-2017  Madhu Bolli      Added new proc save_pdf_invoice_copy to store PDF Copy| 
-- +============================================================================================+


GC_SOURCE_APP_CODE       CONSTANT VARCHAR2(50)       := 'AR';
GC_CONC_REQUEST_NAME     CONSTANT VARCHAR2(200)      := 'OD: Customer Invoice Copy';
GC_SUB_REQUEST_NAME      CONSTANT VARCHAR2(200)      := 'OD: Print Invoice';
GC_SOURCE_NAME           CONSTANT VARCHAR2(100)      := 'OD Customer Invoice Copy';
GC_CONC_REQ_DEF_NAME     CONSTANT VARCHAR2(50)       := 'OD: Send Invoice Deferred';

GN_DEFAULT_DOCUMENT_ID   CONSTANT NUMBER             := 10000;

-- 1.6 These variables can be used to pass data between 2 procedures without passing as parameters.
--   Procedure get_invoice(with 2 params) is standard and don't want to change this signature
--   and at same time want to reuse this get_invoice(with 2 params) which makes easy for retrofit

GC_OD_GET_INV_WAIT_FLAG           VARCHAR2(1)        := NULL;
GN_OD_GET_INV_CONC_REQ_ID         NUMBER             := NULL;
GC_OD_IS_DUPLICATE_CONC_REQ		  VARCHAR2(1)		 := NULL;


-- +============================================================================================+
-- |  Name: GET_TEMP_SELECTED_TRX_LIST                                                          |
-- |  Description: This function returns the iReceivables current transaction list from the     |
-- |                 global temp table "AR_IREC_PAYMENT_LIST_GT" as a comma-delimited list.     |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_cust_account_id        Customer Account ID                                            |
-- |                                                                                            |
-- |  Returns :    comma-delimited list of the selected transactions in iReceivables            |
-- +============================================================================================+
FUNCTION get_temp_selected_trx_list
( p_cust_account_id        IN   NUMBER    DEFAULT NULL )
RETURN VARCHAR2;

-- +============================================================================================+
-- |  Name: GET_TEMP_SELECTED_CONBILL_LIST                                                      |
-- |  Description: This function returns the iReceivables current transaction list from the     |
-- |                 global temp table "AR_IREC_PAYMENT_LIST_GT" as a comma-delimited list      |
-- |                 of unique consolidated bill numbers                                        |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_cust_account_id        Customer Account ID                                            |
-- |                                                                                            |
-- |  Returns :    comma-delimited list of the selected consolidated bills in iReceivables      |
-- +============================================================================================+
FUNCTION get_temp_selected_conbill_list
( p_cust_account_id        IN   NUMBER    DEFAULT NULL )
RETURN VARCHAR2;

-- +============================================================================================+ 
-- |  Name: GET_UNREPRINTABLE_TRXS                                                              |
-- |  Description: This function returns comma-delimited list of unprinted trxs for the given   |
-- |               comma-delimited trx list (those with batch source of "CONVERSION_OD").       | 
-- |                                                                                            | 
-- |  Parameters:                                                                               |  
-- |    p_cust_account_id        Customer Account ID                                            |
-- |    p_invoice_trx_list       Customer Trx List (comma-delimited)                            |
-- |                                                                                            | 
-- |  Returns :  Converted Trx List (comma-delimited)                                           |
-- +============================================================================================+ 
FUNCTION get_unreprintable_trxs
( p_cust_account_id        IN   NUMBER    DEFAULT NULL,
  p_invoice_trx_list       IN   VARCHAR2  DEFAULT NULL )
RETURN VARCHAR2;

-- +============================================================================================+
-- |  Name: SEND_INVOICES_DEFERRED                                                              |
-- |  Description: This procedure sends a copy of the given invoices to the customer via        |
-- |                 any number of the XML publisher destinations through a concurrent          |
-- |                 program to prevent the user from waiting on the submission                 |
-- |                                                                                            |
-- |          It assumes checks have already been made to ensure trx/consbill request is valid  |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_cust_account_id        Customer Account ID                                            |
-- |    p_invoice_trx_list       Invoice Trx List                                               |
-- |    p_cons_bill_list         Consolidated Bill List                                         |
-- |    p_email_flag             Email Flag (Y/N)                                               |
-- |    p_email_address          Email Address                                                  |
-- |    p_fax_flag               Fax Flag (Y/N)                                                 |
-- |    p_fax_number             Fax Number                                                     |
-- |    p_print_flag             Print Flag (Y/N)                                               |
-- |    p_printer_location       Printer Location (unix style "/printers/XXXXX" )               |
-- |                                                                                            |
-- | Returns :     N/A                                                                          |
-- +============================================================================================+
FUNCTION send_invoices_deferred
( p_cust_account_id        IN   NUMBER,
  p_invoice_trx_list       IN   VARCHAR2    DEFAULT NULL,
  p_cons_bill_list         IN   VARCHAR2    DEFAULT NULL,
  p_email_flag             IN   VARCHAR2    DEFAULT 'N',
  p_email_address          IN   VARCHAR2    DEFAULT NULL,
  p_fax_flag               IN   VARCHAR2    DEFAULT 'N',
  p_fax_number             IN   VARCHAR2    DEFAULT NULL,
  p_print_flag             IN   VARCHAR2    DEFAULT 'N',
  p_printer_location       IN   VARCHAR2    DEFAULT NULL )
RETURN NUMBER;

-- +============================================================================================+
-- |  Name: SEND_INVOICES_CP                                                                    |
-- |  Description: This procedure sends a copy of the given invoices to the customer via        |
-- |                 any number of the XML publisher destinations, it is submitted through a    |
-- |                 concurrent program by SEND_INVOICES_DEFERRED                               |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_cust_account_id        Customer Account ID                                            |
-- |    p_invoice_trx_list       Invoice Trx List                                               |
-- |    p_email_flag             Email Flag (Y/N)                                               |
-- |    p_email_address          Email Address                                                  |
-- |    p_fax_flag               Fax Flag (Y/N)                                                 |
-- |    p_fax_number             Fax Number                                                     |
-- |    p_print_flag             Print Flag (Y/N)                                               |
-- |    p_printer_location       Printer Location (unix style "/printers/XXXXX" )               |
-- |                                                                                            |
-- | Returns :     N/A                                                                          |
-- +============================================================================================+
PROCEDURE send_invoices_cp
( x_error_buffer           OUT  VARCHAR2,
  x_return_code            OUT  NUMBER,
  p_cust_account_id        IN   NUMBER,
  p_invoice_trx_list       IN   VARCHAR2    DEFAULT NULL,
  p_cons_bill_list         IN   VARCHAR2    DEFAULT NULL,
  p_email_flag             IN   VARCHAR2    DEFAULT 'N',
  p_email_address          IN   VARCHAR2    DEFAULT NULL,
  p_fax_flag               IN   VARCHAR2    DEFAULT 'N',
  p_fax_number             IN   VARCHAR2    DEFAULT NULL,
  p_print_flag             IN   VARCHAR2    DEFAULT 'N',
  p_printer_location       IN   VARCHAR2    DEFAULT NULL );

-- +============================================================================================+
-- |  Name: GET_INVOICE                                                                         |
-- |  Description: The procedure runs a concurrent program to generate an invoice PDF as output |
-- |                 waits for it to finish, and returns a URL to display it internally.        |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_customer_trx_id      IN  -- invoice transaction id                                    |
-- |                                                                                            |
-- |    x_blob                 OUT -- Blob to display PDF                                       |
-- +============================================================================================+
PROCEDURE get_invoice
( p_customer_trx_id      IN   VARCHAR2,
  x_blob                 OUT  BLOB );


-- +============================================================================================+
-- |  Name: GET_INVOICE                                                                         |
-- |  Description: The procedure runs a concurrent program to generate an invoice PDF as output |
-- |                 waits for it to finish, and returns a URL to display it internally.        |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_customer_trx_id      IN  -- invoice transaction id                                    |
-- |                                                                                            |
-- |    x_blob                 OUT -- Blob to display PDF                                       |
-- |    x_request_id           OUT -- request_id without waiting                                |
-- +============================================================================================+
PROCEDURE get_invoice
( p_customer_trx_id      IN   VARCHAR2,
  x_blob                 OUT  BLOB, 
  x_request_id			 OUT  NUMBER,
  x_is_duplicate_creq    OUT  VARCHAR2 );  

-- +============================================================================================+
-- |  Name: has_consolidated_bill_setup                                                         |
-- |  Description: This function returns Y/N indicating if the customer is setup to request     |
-- |                 consolidated bills via email or fax.                                       |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_cust_account_id        Customer Account ID                                            |
-- |                                                                                            |
-- |  Returns :  Y/N                                                                            |
-- +============================================================================================+
FUNCTION has_consolidated_bill_setup
( p_cust_account_id          IN   NUMBER)
RETURN VARCHAR2;

-- +============================================================================================+
-- |  Name: has_individual_invoice_setup                                                        |
-- |  Description: This function returns Y/N indicating if the customer is setup to request     |
-- |                 individual invoices via email or fax.                                      |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_cust_account_id        Customer Account ID                                            |
-- |                                                                                            |
-- |  Returns :  Y/N                                                                            |
-- +============================================================================================+
FUNCTION has_individual_invoice_setup
( p_cust_account_id      IN   NUMBER    DEFAULT NULL )
RETURN VARCHAR2;

-- +============================================================================================+
-- |  Name: purge_xdo_requests_data                                                             |
-- |  Description: This program is to purge the xdo requests tables data                        |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_no_of_days              IN -- number days                                             |
-- +============================================================================================+
PROCEDURE purge_xdo_requests_data
( p_error_buff  OUT  VARCHAR2,
  p_ret_code    OUT  NUMBER,
  p_no_of_days  IN   NUMBER	);

-- +============================================================================================+
-- |  Name: save_pdf_invoice_copy                                                               |
-- |  Description: This procedure saves the output of given request_id, of PDF Copy, into a table|
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_customer_trx_id         IN -- Transaction Id of PDF Copy Invoice or Consolidated Invoice|
-- |    p_request_id              IN -- RequestId of Individual Invoice and Parent Request of Consolidated Invoice |
-- +============================================================================================+
PROCEDURE save_pdf_invoice_copy(
  x_error_buff  OUT  VARCHAR2,
  x_ret_code    OUT  NUMBER,
  p_customer_trx_id      IN   VARCHAR2,
  p_request_id           IN   NUMBER
);


END;
/