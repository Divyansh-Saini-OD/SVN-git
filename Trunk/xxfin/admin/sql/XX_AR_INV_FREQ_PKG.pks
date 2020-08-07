create or replace PACKAGE XX_AR_INV_FREQ_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      AR Invoice Frequency synchronization                  |
-- | Description : To pupulate the invoices according to the customer  |
-- |                documents                                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       09-AUG-2007  Gowri Shankar        Initial version        |
-- |1.1       13-MAY-2008  Agnes Poornima M     Performance Fix        |
-- |                                            for Special Handling   |
-- |                                            and Paper              |
-- |1.2       18-JUN-2008  Gowri Shankar        Defect# 8253           |
-- |                                            To Add the printer     |
-- |                                            parameter              |
-- |1.3       14-JUL-2008  Gowri Shankar        Defect# 8726           |
-- |                                            Zipping Program        |
-- |1.4       23-JUL-2008  Gowri Shankar        Defect# 9076           |
-- |                                            To add "As Of Date"    |
-- |                                              Parameter            |
-- |1.5       04-SEP-2008  Gowri Shankar        Defect# 9632,          |
-- |                                            Perf improvement       |
-- |                                                                   |
-- |1.6       01-Dec-2008  Sambasiva Reddy      Defect# 12223, Adding  |
-- |                                            a additional Prineter  |
-- |1.7       07-Feb-2009  Ranjith Prabhu       Commented for the      |
-- |                                            Defect # 13101         |
-- |1.8       31-Aug-2009  Tamil Vendhan L      R1.1Defect # 1451      |
-- |                                            (CR 626) To add gift   |
-- |                                            card  functions        |
-- |1.9       06-JAN-2009  Tamil Vendhan L      Modified for R1.2      |
-- |                                            CR 466 Defect 1201     |
-- |2.0       15-MAR-2010  Tamil Vendhan L      Modified for R1.3      |
-- |                                            CR 738 Defect 2766     |
-- |2.1       14-JUN-2010  Ranjith Thangasamy   Change for Defect  6375|
-- |2.2       20-JUL-2010  Sambasiva Reddy D    Modified for defect    |
-- |                                            6818 (Changed multi-   |
-- |                                            threading approach)    |
-- |2.3       22-JUL-2010  Sambasiva Reddy S    Modifed for defect 6818|
-- |                                            gathering stats        |
-- +===================================================================+

-- +===================================================================+
-- | Name : SYNCH                                                      |
-- | Description : This Program automatic ally will picks all the new   |
-- |                 invoices and inserts into the frequency table,    |
-- |                  by computing the efffective print date           |
-- |                                                                   |
-- | Program "OD: AR Invoice Manage Frequencies"                       |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+
    FUNCTION COMPUTE_EFFECTIVE_DATE(
                                  --p_extension_id              IN    NUMBER     --Commented for the Defect# 9632
                                    p_payment_term              IN    VARCHAR2   --Added for the Defect# 9632
                                   ,p_invoice_creation_date     IN    DATE
                                   )  RETURN DATE;

-- Added the below function for the R1.1 Defect # 1451 (CR 626)
----------------------------
    FUNCTION GIFT_CARD_INV(
                           p_customer_trx_id          IN  NUMBER
                          ,p_header_id                IN  VARCHAR2
                          )  RETURN VARCHAR2;

-- Added the below function for the R1.1 defect # 1451 (CR 626)
    FUNCTION GIFT_CARD_CM(
                           p_customer_trx_id          IN  NUMBER
                           ,p_header_id                IN  VARCHAR2
                          )  RETURN VARCHAR2;

-- Start of changes for R1.3 Defect 2766 CR 738 - Added the below procedure SYNCH_MASTER as part of R1.3 Defect# 2766 CR# 738.
-- +===================================================================+
-- | Name : SYNCH_MASTER                                               |
-- | Description :    This is used to submit the Individual billing    |
-- |                  program "OD: AR Invoice Manage Frequencies in    |
-- |                  batches. This is the master program which will   |
-- |                  filter out the cust docs which needs to be sent  |
-- |                  today (current billing cycle).                   |
-- |                                                                   |
-- | Program :OD: AR Invoice Manage Frequencies  Master                |
-- |                                                                   |
-- | Returns  : x_error_buff,x_ret_code                                |
-- +===================================================================+

 PROCEDURE SYNCH_MASTER ( x_error_buff              OUT    VARCHAR2
                         ,x_ret_code                OUT    NUMBER
                         ,p_batch_size              IN     NUMBER
                         ,p_as_of_date              IN     VARCHAR2
                         ,p_no_workers              IN     NUMBER  -- Added for defect #6818 on 7/20/2010
                         ,p_gather_stats            IN     VARCHAR2 DEFAULT 'Y'-- Added for defect #6818 on 7/22/2010
                        );

-- Added the below function XX_AR_INFOCOPY_HANDLING as part of R1.3 Defect# 2766 CR# 738.
-- +===================================================================+
-- | Name : XX_AR_INFOCOPY_HANDLING                                    |
-- | Description :    This function is used to decide whether a        |
-- |                  infocopy can be sent or not                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns  : lc_infocopy_flag                                       |
-- +===================================================================+

FUNCTION XX_AR_INFOCOPY_HANDLING (p_cust_trx_id      IN NUMBER
                                 ,p_cust_doc_id      IN NUMBER
                                 ,p_cust_acct_id     IN NUMBER
                                 ,p_effec_start_date IN DATE
                                 ,p_info_pay_term    IN VARCHAR2
                                 ,p_attr_group_id    IN NUMBER
                                 ,p_as_of_date       IN DATE
                                 ,p_attribute15      IN VARCHAR2  -- Added for Deect 6375
                                 ) RETURN VARCHAR2;

-- End of changes for R1.3 Defect 2766 CR 738

    PROCEDURE SYNCH      (x_error_buff                OUT VARCHAR2
                          ,x_ret_code                 OUT NUMBER
                          ,p_batch_id                 IN  NUMBER             -- Added for R1.3 CR 738 Defect 2766
                          ,p_as_of_date               IN  VARCHAR2           -- Added for R1.3 CR 738 Defect 2766
                          );

    /* Commented for the Defect # 13101
    PROCEDURE ERR_HANDLE (x_error_buff                OUT VARCHAR2
                          ,x_ret_code                 OUT NUMBER);
    */

    PROCEDURE XX_MULTI_THREAD_NEW (x_error_buff       OUT VARCHAR2
                          ,x_ret_code                 OUT NUMBER
                          ,p_cust_trx_class           IN VARCHAR2
                          ,p_cust_trx_type_id         IN NUMBER
                          ,p_delete_freq_table        IN VARCHAR2
                          ,p_source                   IN VARCHAR2
                          ,p_tax_registration_number  IN VARCHAR2
                          ,p_batch_size               IN NUMBER
                          ,p_as_of_date               IN VARCHAR2);  --Added for the Defect# 9076

     PROCEDURE XX_MULTI_THREAD_SPL (x_error_buff      OUT VARCHAR2
                          ,x_ret_code                 OUT NUMBER
                          ,p_cust_trx_class           IN VARCHAR2
                          ,p_cust_trx_type_id         IN NUMBER
                          ,p_delete_freq_table        IN VARCHAR2
                          ,p_source                   IN VARCHAR2
                          ,p_tax_registration_number  IN VARCHAR2
                          ,p_batch_size               IN NUMBER
                          ,p_as_of_date               IN VARCHAR2
                          ,p_printer_style            IN VARCHAR2   --Added for the Defect#8253
                          ,p_printer_name             IN VARCHAR2   --Added for the Defect#8253
                          ,p_number_copies            IN NUMBER     --Added for the Defect#8253
                          ,p_save_output              IN VARCHAR2   --Added for the Defect#8253
                          ,p_print_together           IN VARCHAR2   --Added for the Defect#8253
                          ,p_validate_printer         IN VARCHAR2   --Added for the Defect#8253
                          ,p_another_printer           IN VARCHAR2);   --Added for Defect # 12223


--Added for the Defect#8726

-- +===================================================================+
-- | Name : CERT_RPTZIP                                                |
-- | Description : This program is used wrapper to the Certegy Report  |
-- |               and the zipping program                             |
-- |                                                                   |
-- |                                                                   |
-- | Program "OD: AR Invoice Certegy Report and Zipping"               |
-- |                                                                   |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+


    PROCEDURE CERT_RPTZIP
                          (x_error_buff               OUT VARCHAR2
                          ,x_ret_code                 OUT NUMBER
                          ,p_cust_trx_class           IN VARCHAR2
                          ,p_cust_trx_type_id         IN NUMBER
                          ,p_delete_freq_table        IN VARCHAR2
                          ,p_source                   IN VARCHAR2
                          ,p_tax_registration_number  IN VARCHAR2
                          ,p_batch_size               IN NUMBER
                          ,p_as_of_date               IN VARCHAR2  --Added for the Defect# 9076
                          ,p_data_file_name           IN VARCHAR2
                          ,p_zip_file_name            IN VARCHAR2
                          ,p_done_file_name           IN VARCHAR2
                          ,p_file_size                IN NUMBER
                          ,p_archive_path_zip_file    IN VARCHAR2
                          ,p_archive_path_data_file   IN VARCHAR2
                          ,p_delete_file              IN VARCHAR2);

--+====================================================================+
-- | Name : PURGE_HIST                                                 |
-- | Description : This is the program to purge the Frequency History  |
-- |                table.                                             |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Program :"OD: AR Purge Invoice Frequency History"                 |
-- |                                                                   |
-- |                                                                   |
-- | Returns  : x_error_buff,x_ret_code                                |
-- +===================================================================+

PROCEDURE PURGE_HIST
                    (x_error_buff               OUT VARCHAR2
                    ,x_ret_code                 OUT NUMBER
                    ,p_purge_date               IN   VARCHAR2);

-- Start of changes for R1.2 Defect 1201 (CR 466)
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : Address Exception Handling                                          |
-- | Description : To Handle address exceptions                                        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       22-Dec-09    Tamil Vendhan L      Initial Version                        |
-- +===================================================================================+

FUNCTION XX_AR_ADDR_EXCP_HANDLING ( p_cust_account_id     NUMBER
                                   ,p_cust_doc_id         NUMBER
                                   ,p_attr_group_id       NUMBER
                                   ,p_bill_to_site_use_id NUMBER
                                   ,p_ship_to_site_use_id NUMBER
                                   )  RETURN NUMBER;

-- End of changes for R1.2 Defect 1201 (CR 466)

-- Start of changes for R1.2 Defect 1201 CR 466 - Added the below procedure REPRINT_IND_DOC_WRAP as part of R1.2 Defect# 1201 CR# 466.
-- +===================================================================+
-- | Name : REPRINT_IND_DOC_WRAP                                       |
-- | Description : 1. This is used to submit the individual reprint    |
-- |                 program for each separate transactions in multiple|
-- |                 trx number parameter if customer number is not    |
-- |                 passed.                                           |
-- |               2. If customer number is passed then only one       |
-- |                 Individual reprint program will be submitted even |
-- |                 in case of multiple trx number parameter passed.  |
-- |                                                                   |
-- | Program :OD: AR Invoice Reprint Paper Invoices - Main             |
-- |                                                                   |
-- | Returns  : x_error_buff,x_ret_code                                |
-- +===================================================================+

 PROCEDURE REPRINT_IND_DOC_WRAP ( x_error_buffer            OUT    VARCHAR2
                                 ,x_return_code             OUT    NUMBER
                                 ,p_infocopy_flag           IN     VARCHAR2
                                 ,p_search_by               IN     VARCHAR2
                                 ,p_cust_account_id         IN     NUMBER
                                 ,p_date_from               IN     VARCHAR2
                                 ,p_date_to                 IN     VARCHAR2
                                 ,p_customer_trx_id         IN     NUMBER
                                 ,p_multiple_trx            IN     VARCHAR2
                                 ,p_open_invoices           IN     VARCHAR2
                                 ,p_cust_doc_id             IN     NUMBER
                                 ,p_mbs_document_id         IN     NUMBER
                                 ,p_override_doc_flag       IN     VARCHAR2
                                 ,p_email_option            IN     VARCHAR2
                                 ,p_dummy                   IN     VARCHAR2
                                 ,p_email_address           IN     VARCHAR2
                                 ,p_fax_number              IN     VARCHAR2
                                 ,p_source                  IN     VARCHAR2
                                );

-- End of changes for R1.2 Defect 1201 CR 466
END XX_AR_INV_FREQ_PKG;
/
