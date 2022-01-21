CREATE OR REPLACE PACKAGE xx_ap_nachaboa_eft_pkg
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           Office Depot Organization                               |
-- +===================================================================+
-- | Name  : xx_ap_nachaboa_eft_pkg                                    |
-- | Description      :  Package contains program units which will be  | 
-- |                     called in the payment process request hook    |
-- |                     package to generate extra information for     |
-- |                     format payment which will be                  |  
-- |                     sent to Bank of America. This program replaces|
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========   =============    ===========================|
-- |1.0       27-JUL-2013   Satyajeet M     I0438-Initial draft version|
-- |1.1       09-DEC-2013   Satyajeet M     Changed the retturn type of|
-- |                                        paymented_details function |
-- |                                        to CLOB from VARCHAR2      |
-- |1.2       19-Mar-2014   Darshini        Changes for defects 28958 and 28983.  |
-- |                                        Included parameters for    |
-- |                                        payment_details function.  |
-- |1.3       25-Mar-2014   Veronica        Changed the get_dec_ccno   |
-- |                                        to a private function.     |
-- |1.4       04-Nov-2015  Harvinder Rakhra Retroffit R12.2            |
-- +===================================================================+
AS

-- +===================================================================+
-- | Name  : get_dec_ccno                                               |
-- | Description: This  fuction will return decrypted creditcard numnber|
-- |                                                                   |
-- +===================================================================+
   --FUNCTION get_dec_ccno(p_identifier IN VARCHAR2
   --						,p_encrypted  IN VARCHAR2)
   -- RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : SETTLE_DATE                                               |
-- | Description: This  fuction will return the next available business|
-- |             date. The number to days to settle a payment will be  |
-- |          stored on the xx_po_vendor_sites_kff_v (eft_settle_days) |
-- |           field                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |                                                                   |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  17-Sep-2014 Satyajeet M      Initial draft version       |
-- |                                                                   |
-- +===================================================================+
   FUNCTION settle_date (
      p_vendor_id        IN   NUMBER,
      p_vendor_site_id   IN   NUMBER,
      p_check_date       IN   DATE
   )RETURN VARCHAR2;
   
   FUNCTION payment_details (
      p_vendor_id         IN       NUMBER,
      p_vendor_site_id    IN       NUMBER,
      p_vendor_type       IN       VARCHAR2,
      p_payment_type      IN       VARCHAR2,
      p_payment_id        IN       NUMBER,
      p_batch_cnt         IN       NUMBER,
      p_isa_seq_num       IN       NUMBER, -- Changes for defect 28958 and 28983
      p_st_cntrl_num      IN       NUMBER, -- Changes for defect 28958 and 28983
      x_addenda_rec_cnt   OUT      NUMBER
   )
    --  RETURN VARCHAR2; -- Commented 09122013
    RETURN CLOB; -- Added 09122013

   FUNCTION eft_file_move (
                                   p_sub_guid IN RAW,
                                   p_event    IN OUT WF_EVENT_T
                                 ) RETURN VARCHAR2;
END xx_ap_nachaboa_eft_pkg;
/