CREATE OR REPLACE PACKAGE XXAPPS_HISTORY_QUERY.XX_ARI_INVOICE_COPY_PKG AS
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
-- | 1.4         19-Jul-2016  Suresh Naragam   Version Compiled in History Schema (Defect#2157) |
-- +============================================================================================+


GC_SOURCE_APP_CODE       CONSTANT VARCHAR2(50)       := 'AR';
GC_CONC_REQUEST_NAME     CONSTANT VARCHAR2(200)      := 'OD: Customer Invoice Copy';
GC_SUB_REQUEST_NAME      CONSTANT VARCHAR2(200)      := 'OD: Print Invoice';
GC_SOURCE_NAME           CONSTANT VARCHAR2(100)      := 'OD Customer Invoice Copy';
GC_CONC_REQ_DEF_NAME     CONSTANT VARCHAR2(50)       := 'OD: Send Invoice Deferred';

GN_DEFAULT_DOCUMENT_ID   CONSTANT NUMBER             := 10000;


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

END;
/