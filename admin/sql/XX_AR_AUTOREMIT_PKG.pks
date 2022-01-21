 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package Specification XX_AR_AUTOREMIT_PKG
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE PACKAGE XX_AR_AUTOREMIT_PKG
 AS
 -- +============================================================================+
 -- |                  Office Depot - Project Simplify                           |
 -- |                       WIPRO Technologies                                   |
 -- +============================================================================+
 -- | Name :      AR AutoRemittance                                              |
 -- | Description : To run the batches of AutoRemittance in parallel             |
 -- |                                                                            |
 -- |                                                                            |
 -- |Change Record:                                                              |
 -- |===============                                                             |
 -- |Version   Date          Author              Remarks                         |
 -- |=======   ==========   =============        ================================|
 -- |1.0       18-APR-2008  Anitha Devarajulu,   Initial version                 |
 -- |                       Wipro Technologies                                   |
 -- |1.1       21-APR-2008  Sambasiva Reddy,     Adding Debug parameters         |
 -- |                       Wipro Technologies                                   |
 -- |1.2       26-MAY-2008  Hemalatha S.         Defect 7376                     |
 -- |1.3       20-NOV-2009  Anitha Devarajulu    Defect 3358                     |
 -- |1.4       17-MAR-2010  Lincy K              Defect 3358                     |
 -- |1.5       14-APR-2010  Rani Asaithambi      Defect 3358                     |
 -- |1.6       14-JUL-2010  Lincy K              Defect 6794 - Added receipt_date|
 -- |                                            receipt_number (low/high) as    |
 -- |                                            parameter                       |
 -- |1.7       19-SEP-2012 Bapuji N              DIFF between REL and PROD PATH  |
 -- |                                            CHANGE UPDATE                   |
 -- +============================================================================+

    PROCEDURE SCHEDULER(
          x_error_buff                 OUT    VARCHAR2
         ,x_ret_code                   OUT    NUMBER
         ,p_process_type               IN     VARCHAR2
         ,p_batch_date                 IN     VARCHAR2
         ,p_batch_gl_date              IN     VARCHAR2
         ,p_create_flag                IN     VARCHAR2
         ,p_approve_flag               IN     VARCHAR2
         ,p_format_flag                IN     VARCHAR2
         ,p_batch_id                   IN     VARCHAR2
         ,p_debug_flag                 IN     VARCHAR2
         ,p_batch_currency             IN     VARCHAR2
         ,p_exchange_date              IN     VARCHAR2
         ,p_exchange_rate              IN     VARCHAR2
         ,p_exchange_type              IN     VARCHAR2
         ,p_remit_method_code          IN     VARCHAR2
         ,p_receipt_class_id           IN     VARCHAR2
         ,p_receipt_payment_method_id  IN     VARCHAR2
         ,p_media_ref                  IN     VARCHAR2
         ,p_remit_bank_branch_id       IN     VARCHAR2
         ,p_remit_bank_account_id      IN     VARCHAR2
         ,p_remit_deposit_number       IN     VARCHAR2
         ,p_comments                   IN     VARCHAR2
         ,p_receipt_date_low           IN     VARCHAR2
         ,p_receipt_date_high          IN     VARCHAR2
         ,p_maturity_date_low          IN     VARCHAR2
         ,p_maturity_date_high         IN     VARCHAR2
         ,p_receipt_num_low            IN     VARCHAR2
         ,p_receipt_num_high           IN     VARCHAR2
         ,p_doc_num_low                IN     VARCHAR2
         ,p_doc_num_high               IN     VARCHAR2
         ,p_cust_num_low               IN     VARCHAR2
         ,p_cust_num_high              IN     VARCHAR2
         ,p_cust_name_low              IN     VARCHAR2
         ,p_cust_name_high             IN     VARCHAR2
         ,p_cust_id                    IN     VARCHAR2
         ,p_site_low                   IN     VARCHAR2
         ,p_site_high                  IN     VARCHAR2
         ,p_site_id                    IN     VARCHAR2
         ,p_min_amount                 IN     VARCHAR2
         ,p_max_amount                 IN     VARCHAR2
         ,p_bill_num_low               IN     VARCHAR2
         ,p_bill_num_high              IN     VARCHAR2
         ,p_bank_act_num_low           IN     VARCHAR2
         ,p_bank_act_num_high          IN     VARCHAR2
         ,p_batch_type                 IN     VARCHAR2 -- Added for defect 7376
         ,p_batch_count                IN     NUMBER   -- Added for defect 7376
         ,p_auto_remit_submit          IN     VARCHAR2
         ,p_debug                      IN     VARCHAR2
         ,p_debug_file                 IN     VARCHAR2);

    PROCEDURE CORRECT_ERR_RCPT(
         x_error_buff                 OUT    VARCHAR2
        ,x_ret_code                   OUT    NUMBER       -- NB DIFF BETWEEN PROD and REL PATH
        ,p_auto_remit_submit          IN     VARCHAR2
        ,p_chunk_size                 IN     NUMBER        -- Added for defect 3358 (v1.4)
        ,p_batch_date                 IN     VARCHAR2      -- Added for defect 3358 (v1.4)
        ,p_batch_currency             IN     VARCHAR2      -- Added for defect 3358 (v1.4)
        ,p_remit_method               IN     VARCHAR2      -- Added for defect 3358 (v1.9)
        ,p_rcptclassid                IN     NUMBER        -- Added for defect 3358 (v1.9)
        ,p_receipt_method_id          IN     NUMBER        -- Added for defect 3358 (v1.9)
        ,p_bank_branch_id             IN     NUMBER        -- Added for defect 3358 (v1.9)
        ,p_bank_account_id            IN     NUMBER        -- Added for defect 3358 (v1.9)
       -- Start of changes for defect 6794 - on 14.7.10
        ,p_receipt_date_low           IN     VARCHAR2
        ,p_receipt_date_high          IN     VARCHAR2
        ,p_receipt_num_low            IN     VARCHAR2
        ,p_receipt_num_high           IN     VARCHAR2);
       -- End of changes for defect 6794 - on 14.7.10

     PROCEDURE DISPLAY_LOG (
                           p_debug_file      IN  VARCHAR2
                          ,p_debug_msg       IN  VARCHAR2);

 END XX_AR_AUTOREMIT_PKG;
/
 SHOW ERR