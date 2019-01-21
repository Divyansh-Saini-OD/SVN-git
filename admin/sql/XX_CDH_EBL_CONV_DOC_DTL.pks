SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_cdh_ebl_conv_doc_dtl_pkg

  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XX_CDH_EBL_CONV_DOC_DTL_PKG                                 |
  -- | Description :                                                             |
  -- | This package body provides table handlers for the table                   |
  -- | XX_CDH_EBL_CONV_DOC_DTL.                                                  |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author           Remarks                              |
  -- |======== =========== ================ =====================================|
  -- |DRAFT 1A 09-DEC-2010 Devi Viswanathan Initial draft version                |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

AS

  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : INSERT_ROW                                                  |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | This procedure inserts data into the table  XX_CDH_EBL_CONV_DOC_DTL.      |
  -- |                                                                           |
  -- +===========================================================================+

PROCEDURE insert_row( x_status                         OUT VARCHAR2
                    , x_error_message                  OUT VARCHAR2
                    , p_ebl_conv_doc_id                 IN NUMBER
                    , p_new_cust_doc_id                 IN NUMBER
                    , p_new_doc_status                  IN VARCHAR2
                    , p_batch_id                        IN NUMBER
                    , p_cust_account_id                 IN NUMBER
                    , p_account_number                  IN VARCHAR2
                    , p_aops_number                     IN VARCHAR2
                    , p_old_cust_doc_id                 IN NUMBER
                    , p_old_frequency                   IN VARCHAR2
                    , p_old_report_day                  IN VARCHAR2
                    , p_billdocs_mbs_doc_id             IN NUMBER
                    , p_billdocs_pay_doc_ind            IN VARCHAR2
                    , p_billdocs_delivery_method        IN VARCHAR2
                    , p_billdocs_direct_flag            IN VARCHAR2
                    , p_billdocs_doc_type               IN VARCHAR2
                    , p_billdocs_combo_type             IN VARCHAR2
                    , p_billdocs_payment_term           IN VARCHAR2
                    , p_billdocs_term_id                IN NUMBER
                    , p_billdocs_is_parent              IN NUMBER
                    , p_billdocs_send_to_parent         IN NUMBER
                    , p_billdocs_parent_doc_id          IN NUMBER
                    , p_billdocs_mail_to_attention      IN VARCHAR2
                    , p_billdoc_status                  IN VARCHAR2
                    , p_billdocs_record_status          IN NUMBER
                    , p_billdocs_req_start_date         IN DATE
                    , p_ebill_transmission_type         IN VARCHAR2
                    , p_ebill_associate                 IN VARCHAR2
                    , p_file_processing_method          IN VARCHAR2
                    , p_file_name_ext                   IN VARCHAR2
                    , p_max_file_size                   IN NUMBER
                    , p_max_transmission_size           IN NUMBER
                    , p_zip_required                    IN VARCHAR2
                    , p_zipping_utility                 IN VARCHAR2
                    , p_zip_file_name_ext               IN VARCHAR2
                    , p_od_field_contact                IN VARCHAR2
                    , p_od_field_contact_phone          IN VARCHAR2
                    , p_od_field_contact_email          IN VARCHAR2
                    , p_client_tech_contact             IN VARCHAR2
                    , p_client_tech_contact_phone       IN VARCHAR2
                    , p_client_tech_contact_email       IN VARCHAR2
                    , p_field_selection                 IN VARCHAR2
                    , p_file_name_seq_reset             IN VARCHAR2
                    , p_file_next_seq_number            IN NUMBER
                    , p_file_seq_reset_date             IN DATE
                    , p_file_name_max_seq_number        IN NUMBER
                    , p_email_subject                   IN VARCHAR2
                    , p_email_std_message               IN VARCHAR2
                    , p_email_custom_message            IN VARCHAR2
                    , p_email_std_disclaimer            IN VARCHAR2
                    , p_email_signature                 IN VARCHAR2
                    , p_email_logo_required             IN VARCHAR2
                    , p_email_logo_file_name            IN VARCHAR2
                    , p_ftp_direction                   IN VARCHAR2
                    , p_ftp_transfer_type               IN VARCHAR2
                    , p_ftp_destination_site            IN VARCHAR2
                    , p_ftp_destination_folder          IN VARCHAR2
                    , p_ftp_user_name                   IN VARCHAR2
                    , p_ftp_password                    IN VARCHAR2
                    , p_ftp_pickup_server               IN VARCHAR2
                    , p_ftp_pickup_folder               IN VARCHAR2
                    , p_ftp_cust_contact_name           IN VARCHAR2
                    , p_ftp_cust_contact_email          IN VARCHAR2
                    , p_ftp_cust_contact_phone          IN VARCHAR2
                    , p_ftp_notify_customer             IN VARCHAR2
                    , p_ftp_cc_emails                   IN VARCHAR2
                    , p_ftp_email_sub                   IN VARCHAR2
                    , p_ftp_email_content               IN VARCHAR2
                    , p_ftp_send_zero_byte_file         IN VARCHAR2
                    , p_ftp_zero_byte_file_text         IN VARCHAR2
                    , p_ftp_zero_byte_notification      IN VARCHAR2
                    , p_cd_file_location                IN VARCHAR2
                    , p_cd_send_to_address              IN VARCHAR2
                    , p_comments                        IN VARCHAR2
                    , p_attribute1                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute2                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute3                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute4                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute5                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute6                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute7                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute8                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute9                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute10                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute11                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute12                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute13                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute14                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute15                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute16                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute17                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute18                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute19                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute20                     IN VARCHAR2 DEFAULT NULL
                    , p_last_update_date                IN DATE     DEFAULT SYSDATE
                    , p_last_updated_by                 IN NUMBER   DEFAULT FND_GLOBAL.USER_ID
                    , p_creation_date                   IN DATE     DEFAULT SYSDATE
                    , p_created_by                      IN NUMBER   DEFAULT FND_GLOBAL.USER_ID
                    , p_last_update_login               IN NUMBER   DEFAULT FND_GLOBAL.USER_ID
                    , p_request_id                      IN NUMBER   DEFAULT NULL
                    , p_program_application_id          IN NUMBER   DEFAULT NULL
                    , p_program_id                      IN NUMBER   DEFAULT NULL
                    , p_program_update_date             IN DATE     DEFAULT NULL
                    , p_wh_update_date                  IN DATE     DEFAULT NULL);


  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : UPDATE_ROW                                                  |
  -- |                                                                           |
  -- | Description :                                                             |
  -- |  This procedure shall update data into the table XX_CDH_EBL_CONV_DOC_DTL. |
  -- |                                                                           |
  -- +===========================================================================+

PROCEDURE update_row( x_status                         OUT VARCHAR2
                    , x_error_message                  OUT VARCHAR2 
                    , p_ebl_conv_doc_id                 IN NUMBER
                    , p_new_cust_doc_id                 IN NUMBER
                    , p_new_doc_status                  IN VARCHAR2
                    , p_batch_id                        IN NUMBER
                    , p_cust_account_id                 IN NUMBER
                    , p_account_number                  IN VARCHAR2
                    , p_aops_number                     IN VARCHAR2
                    , p_old_cust_doc_id                 IN NUMBER
                    , p_old_frequency                   IN VARCHAR2
                    , p_old_report_day                  IN VARCHAR2
                    , p_billdocs_mbs_doc_id             IN NUMBER
                    , p_billdocs_pay_doc_ind            IN VARCHAR2
                    , p_billdocs_delivery_method        IN VARCHAR2
                    , p_billdocs_direct_flag            IN VARCHAR2
                    , p_billdocs_doc_type               IN VARCHAR2
                    , p_billdocs_combo_type             IN VARCHAR2
                    , p_billdocs_payment_term           IN VARCHAR2
                    , p_billdocs_term_id                IN NUMBER
                    , p_billdocs_is_parent              IN NUMBER
                    , p_billdocs_send_to_parent         IN NUMBER
                    , p_billdocs_parent_doc_id          IN NUMBER
                    , p_billdocs_mail_to_attention      IN VARCHAR2
                    , p_billdoc_status                  IN VARCHAR2
                    , p_billdocs_record_status          IN NUMBER
                    , p_billdocs_req_start_date         IN DATE
                    , p_ebill_transmission_type         IN VARCHAR2
                    , p_ebill_associate                 IN VARCHAR2
                    , p_file_processing_method          IN VARCHAR2
                    , p_file_name_ext                   IN VARCHAR2
                    , p_max_file_size                   IN NUMBER
                    , p_max_transmission_size           IN NUMBER
                    , p_zip_required                    IN VARCHAR2
                    , p_zipping_utility                 IN VARCHAR2
                    , p_zip_file_name_ext               IN VARCHAR2
                    , p_od_field_contact                IN VARCHAR2
                    , p_od_field_contact_phone          IN VARCHAR2
                    , p_od_field_contact_email          IN VARCHAR2
                    , p_client_tech_contact             IN VARCHAR2
                    , p_client_tech_contact_phone       IN VARCHAR2
                    , p_client_tech_contact_email       IN VARCHAR2
                    , p_field_selection                 IN VARCHAR2
                    , p_file_name_seq_reset             IN VARCHAR2
                    , p_file_next_seq_number            IN NUMBER
                    , p_file_seq_reset_date             IN DATE
                    , p_file_name_max_seq_number        IN NUMBER
                    , p_email_subject                   IN VARCHAR2
                    , p_email_std_message               IN VARCHAR2
                    , p_email_custom_message            IN VARCHAR2
                    , p_email_std_disclaimer            IN VARCHAR2
                    , p_email_signature                 IN VARCHAR2
                    , p_email_logo_required             IN VARCHAR2
                    , p_email_logo_file_name            IN VARCHAR2
                    , p_ftp_direction                   IN VARCHAR2
                    , p_ftp_transfer_type               IN VARCHAR2
                    , p_ftp_destination_site            IN VARCHAR2
                    , p_ftp_destination_folder          IN VARCHAR2
                    , p_ftp_user_name                   IN VARCHAR2
                    , p_ftp_password                    IN VARCHAR2
                    , p_ftp_pickup_server               IN VARCHAR2
                    , p_ftp_pickup_folder               IN VARCHAR2
                    , p_ftp_cust_contact_name           IN VARCHAR2
                    , p_ftp_cust_contact_email          IN VARCHAR2
                    , p_ftp_cust_contact_phone          IN VARCHAR2
                    , p_ftp_notify_customer             IN VARCHAR2
                    , p_ftp_cc_emails                   IN VARCHAR2
                    , p_ftp_email_sub                   IN VARCHAR2
                    , p_ftp_email_content               IN VARCHAR2
                    , p_ftp_send_zero_byte_file         IN VARCHAR2
                    , p_ftp_zero_byte_file_text         IN VARCHAR2
                    , p_ftp_zero_byte_notification      IN VARCHAR2
                    , p_cd_file_location                IN VARCHAR2
                    , p_cd_send_to_address              IN VARCHAR2
                    , p_comments                        IN VARCHAR2
                    , p_attribute1                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute2                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute3                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute4                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute5                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute6                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute7                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute8                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute9                      IN VARCHAR2 DEFAULT NULL
                    , p_attribute10                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute11                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute12                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute13                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute14                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute15                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute16                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute17                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute18                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute19                     IN VARCHAR2 DEFAULT NULL
                    , p_attribute20                     IN VARCHAR2 DEFAULT NULL
                    , p_last_update_date                IN DATE     DEFAULT SYSDATE
                    , p_last_updated_by                 IN NUMBER   DEFAULT FND_GLOBAL.USER_ID
                    , p_creation_date                   IN DATE     DEFAULT SYSDATE
                    , p_created_by                      IN NUMBER   DEFAULT FND_GLOBAL.USER_ID
                    , p_last_update_login               IN NUMBER   DEFAULT FND_GLOBAL.USER_ID
                    , p_request_id                      IN NUMBER   DEFAULT NULL
                    , p_program_application_id          IN NUMBER   DEFAULT NULL
                    , p_program_id                      IN NUMBER   DEFAULT NULL
                    , p_program_update_date             IN DATE     DEFAULT NULL
                    , p_wh_update_date                  IN DATE     DEFAULT NULL);
                    

END xx_cdh_ebl_conv_doc_dtl_pkg;
/

SHOW ERRORS;