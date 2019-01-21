PROMPT Creating Package Body XX_CDH_EBILL_CONVERSION_PKG
PROMPT Program exits if the creation is not successful

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CDH_EBILL_CONVERSION_PKG

AS

-- +==========================================================================+
-- |==========================================================================|
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name        : XX_CDH_EBILL_CONVERSION_PKG                                |
-- |                                                                          |
-- | Description : This Package is used to update the customer account id     |
-- |               and customer doc id in the summary table and it also       |
-- |               inserts the records in tables for :                        |
-- |                  1)eBilling Customer Document.                           |
-- |                  2)eBilling Contacts.                                    |
-- |                  3)eBilling File Name Parameter.                         |
-- |               It also inserts the Mail to Attention in EGO table.        |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date            Author              Remarks                     |
-- |=======   ==========    =============        =============================|
-- |1.0       29-MAR-10      Navin Agarwal       Initial version              |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

   PROCEDURE xx_ebill_conversion_master(
                        x_error_buff                OUT      VARCHAR2
                       ,x_ret_code                  OUT      NUMBER
                       ,p_cust_doc_sum_id           IN       NUMBER
                       ,p_file_name_parmt_sum_id    IN       NUMBER
                       ,p_contacts_sum_id           IN       NUMBER
                       ,p_Activate_Bulk_Batch       IN       NUMBER
                                       );    -- eBilling Conversion Master

   PROCEDURE xx_ebill_cust_doc_prc(
                        p_cust_doc_sum_id           IN       NUMBER
                       ,p_file_name_parmt_sum_id    IN       NUMBER
                       ,p_contacts_sum_id           IN       NUMBER
                       ,x_ret_code                  IN OUT   NUMBER
                                  );         -- eBilling Customer Document

   PROCEDURE xx_ebill_file_name_parmt_prc(
                        p_file_name_parmt_sum_id    IN       NUMBER
                       ,x_ret_code                  IN OUT   NUMBER
                                         );  -- eBilling File Name Parameter

   PROCEDURE xx_ebill_contacts_prc(
                        p_contacts_sum_id         IN       NUMBER
                       ,p_activate_bulk_batch     IN       NUMBER
                       ,x_ret_code                IN OUT   NUMBER
                                  );         -- eBilling Contacts
                            
   PROCEDURE xx_std_contacts_conversion(
                        p_contacts_sum_id         IN       NUMBER
                       ,p_Activate_Bulk_Batch     IN       NUMBER
                       ,x_ret_code                IN OUT   NUMBER
                                  );         -- STD Contacts Conversion.
                                  
   PROCEDURE xx_mail_pay_attn_prc(
                        x_error_buff              OUT      VARCHAR2
                       ,x_ret_code                OUT      NUMBER
                       ,p_mail_attn_sum_id        IN       NUMBER
                                 );          -- eBilling Mail to Attention

END XX_CDH_EBILL_CONVERSION_PKG;
/

SHOW ERROR;

