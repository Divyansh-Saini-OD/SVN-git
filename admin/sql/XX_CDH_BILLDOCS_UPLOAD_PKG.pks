CREATE OR REPLACE PACKAGE XX_CDH_BILLDOCS_UPLOAD_PKG
AS
-- +=========================================================================+
-- |                                                  |
-- +=========================================================================+
-- | Name  : XX_CDH_BILLDOCS_UPLOAD_PKG                                              |
-- | Rice ID: E3116                                                         |
-- | Description      : This Program will extract all the RCC transactions   |
-- |                    into an XML file for RACE                            |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============== =====================================|
-- |1.0     21-MAY-2015 Arun G          Initial draft version                |
-- +=========================================================================+

-- +===================================================================+
-- | Name  : extract
-- | Description     : The extract procedure is the main               |
-- |                   procedure that will extract all the unprocessed |
-- |                   records and process them via Oracle API         |
-- |                                                                   |
-- | Parameters      : x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- |                   p_debug_flag        IN -> Debug Flag            |
-- |                   p_status            IN -> Record status         |
-- +===================================================================+

PROCEDURE   get_data(p_aops_number             IN  xx_cdh_billdocs_upload_stg.aops_customer_number%TYPE,
                     p_mbs_doc_id              IN  xx_cdh_billdocs_upload_stg.mbs_doc_id%TYPE,
                     p_paydoc                  IN  xx_cdh_billdocs_upload_stg.paydoc%TYPE,
                     p_delivery_method         IN  xx_cdh_billdocs_upload_stg.delivery_method%TYPE,
                     p_direct_document         IN  xx_cdh_billdocs_upload_stg.is_parent%TYPE,
                     p_is_parent               IN  xx_cdh_billdocs_upload_stg.direct_document%TYPE,
                     p_request_start_date      IN  xx_cdh_billdocs_upload_stg.request_start_date%TYPE,
                     p_payment_term            IN  xx_cdh_billdocs_upload_stg.payment_term%TYPE,
                     p_send_to_parent          IN  xx_cdh_billdocs_upload_stg.send_to_parent%TYPE,
                     p_parent_doc_id           IN  xx_cdh_billdocs_upload_stg.parent_doc_id%TYPE,
                     p_mail_to_Attention       IN  xx_cdh_billdocs_upload_stg.mail_to_attention%TYPE,
                     p_doc_status              IN  xx_cdh_billdocs_upload_stg.doc_status%TYPE,
                     p_transmission_type       IN  xx_cdh_billdocs_upload_stg.transmission_type%TYPE,
                     p_file_extension          IN  xx_cdh_billdocs_upload_stg.file_extension%TYPE,
                     p_ebill_associate         IN  xx_cdh_billdocs_upload_stg.ebill_associate%TYPE,
                     p_file_processing_method  IN  xx_cdh_billdocs_upload_stg.file_processing_method%TYPE,
                     p_max_file_size           IN  xx_cdh_billdocs_upload_stg.max_file_size%TYPE,
                     p_max_trans_size          IN  xx_cdh_billdocs_upload_stg.max_trans_size%TYPE,
                     p_zip_required            IN  xx_cdh_billdocs_upload_stg.zip_required%TYPE,
                     p_compress_utility        IN  xx_cdh_billdocs_upload_stg.compress_utility%TYPE,
                     p_compress_extension      IN  xx_cdh_billdocs_upload_stg.compress_extension%TYPE,
                     p_email_subject           IN  xx_cdh_billdocs_upload_stg.email_subject%TYPE,
                     p_standard_message        IN  xx_cdh_billdocs_upload_stg.standard_message%TYPE,
                     p_notify_customer         IN  xx_cdh_billdocs_upload_stg.notify_customer%TYPE,
                     p_ftp_direction           IN  xx_cdh_billdocs_upload_stg.ftp_direction%TYPE,
                     p_contact_name            IN  xx_cdh_billdocs_upload_stg.contact_name%TYPE,
                     p_destination_folder      IN  xx_cdh_billdocs_upload_stg.destination_folder%TYPE,
                     p_contact_email           IN  xx_cdh_billdocs_upload_stg.contact_email%TYPE,
                     p_FTP_if_zero_byte        IN  xx_cdh_billdocs_upload_stg.ftp_if_zero_byte%TYPE,
                     p_cc_list                 IN  xx_cdh_billdocs_upload_stg.cc_list%TYPE,
                     p_zero_byte_noty_list     IN  xx_cdh_billdocs_upload_stg.zero_byte_noty_list%TYPE,
                     p_ftp_email_subject       IN  xx_cdh_billdocs_upload_stg.ftp_email_subject%TYPE,
                     p_zero_byte_file_text     IN  xx_cdh_billdocs_upload_stg.zero_byte_file_text%TYPE,
                     p_email_content           IN  xx_cdh_billdocs_upload_stg.email_content%TYPE,
                     p_comments                IN  xx_cdh_billdocs_upload_stg.comments%TYPE,
                     p_contact_phone           IN  xx_cdh_billdocs_upload_stg.contact_phone%TYPE,
                     p_created_by              IN  xx_cdh_billdocs_upload_stg.created_by%TYPE);


PROCEDURE extract(x_retcode         OUT NOCOPY     NUMBER,
                  x_errbuf          OUT NOCOPY     VARCHAR2
                  );

END XX_CDH_BILLDOCS_UPLOAD_PKG;
/


