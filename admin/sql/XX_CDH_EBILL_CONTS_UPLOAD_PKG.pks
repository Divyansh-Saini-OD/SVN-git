create or replace PACKAGE      xx_cdh_ebill_conts_upload_pkg 
AS
-- +==================================================================================+
-- |                        Office Depot                                              |
-- +==================================================================================+
-- | Name  : xx_cdh_ebill_conts_upload_pkg                                             |
-- | Rice ID:                                                                         |
-- | Description      : This program will process all the records and creates the     |
-- |                    ebilling contacts and link to corresponding billing document  |                      
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version Date        Author            Remarks                                     |
-- |======= =========== =============== ==============================================|
-- |1.0     15-JUN-2015 Havish Kasina   Initial draft version                         |
-- |2.0     10-SEP-2015 Havish Kasina   Changes done as per Defect 34999              | 
-- +==================================================================================+

g_debug_flag           BOOLEAN; 

PROCEDURE   get_data(
                     p_aops_cust_number        IN  xx_cdh_ebill_conts_upload_stg.aops_customer_number%TYPE,
                     p_bill_to_consignee       IN  xx_cdh_ebill_conts_upload_stg.bill_to_consignee%TYPE,
                     p_contact_last_name       IN  xx_cdh_ebill_conts_upload_stg.contact_last_name%TYPE,
                     p_contact_first_name      IN  xx_cdh_ebill_conts_upload_stg.contact_first_name%TYPE,
                     p_email_address           IN  xx_cdh_ebill_conts_upload_stg.email_address%TYPE,
                     p_created_by              IN  xx_cdh_ebill_conts_upload_stg.created_by%TYPE,
                     p_cust_doc_id             IN  xx_cdh_ebill_conts_upload_stg.cust_doc_id%TYPE 
                     );

-- +===================================================================+
-- | Name  : extract
-- | Description     : The extract procedure is the main               |
-- |                   procedure that will extract all the unprocessed |
-- |                   records and process them via Oracle API         |
-- |                                                                   |
-- | Parameters      : x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- +===================================================================+
     
PROCEDURE EXTRACT(
                  x_retcode              OUT NOCOPY    NUMBER,
                  x_errbuf               OUT NOCOPY    VARCHAR2
                 );
END xx_cdh_ebill_conts_upload_pkg;
/
SHOW ERRORS;