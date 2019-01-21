SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_EBL_CONV_DOC_DTL_PKG

  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XX_CDH_EBL_CONV_DOC_DTL_PKG                                 |
  -- | Description :                                                             |
  -- | This package provides table handlers for the table                        |
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
                    , p_wh_update_date                  IN DATE     DEFAULT NULL)
IS

BEGIN

  INSERT
  INTO xx_cdh_ebl_conv_doc_dtl( ebl_conv_doc_id
                              , new_cust_doc_id
                              , new_doc_status
                              , batch_id
                              , cust_account_id
                              , account_number
                              , aops_number
                              , old_cust_doc_id
                              , old_frequency
                              , old_report_day
                              , billdocs_mbs_doc_id
                              , billdocs_pay_doc_ind
                              , billdocs_delivery_method
                              , billdocs_direct_flag
                              , billdocs_doc_type
                              , billdocs_combo_type
                              , billdocs_payment_term
                              , billdocs_term_id
                              , billdocs_is_parent
                              , billdocs_send_to_parent
                              , billdocs_parent_doc_id
                              , billdocs_mail_to_attention
                              , billdoc_status
                              , billdocs_record_status
                              , billdocs_req_start_date
                              , ebill_transmission_type
                              , ebill_associate
                              , file_processing_method
                              , file_name_ext
                              , max_file_size
                              , max_transmission_size
                              , zip_required
                              , zipping_utility
                              , zip_file_name_ext
                              , od_field_contact
                              , od_field_contact_phone
                              , od_field_contact_email
                              , client_tech_contact
                              , client_tech_contact_phone
                              , client_tech_contact_email
                              , field_selection
                              , file_name_seq_reset
                              , file_next_seq_number
                              , file_seq_reset_date
                              , file_name_max_seq_number
                              , email_subject
                              , email_std_message
                              , email_custom_message
                              , email_std_disclaimer
                              , email_signature
                              , email_logo_required
                              , email_logo_file_name
                              , ftp_direction
                              , ftp_transfer_type
                              , ftp_destination_site
                              , ftp_destination_folder
                              , ftp_user_name
                              , ftp_password
                              , ftp_pickup_server
                              , ftp_pickup_folder
                              , ftp_cust_contact_name
                              , ftp_cust_contact_email
                              , ftp_cust_contact_phone
                              , ftp_notify_customer
                              , ftp_cc_emails
                              , ftp_email_sub
                              , ftp_email_content
                              , ftp_send_zero_byte_file
                              , ftp_zero_byte_file_text
                              , ftp_zero_byte_notification_txt
                              , cd_file_location
                              , cd_send_to_address
                              , comments
                              , attribute1
                              , attribute2
                              , attribute3
                              , attribute4
                              , attribute5
                              , attribute6
                              , attribute7
                              , attribute8
                              , attribute9
                              , attribute10
                              , attribute11
                              , attribute12
                              , attribute13
                              , attribute14
                              , attribute15
                              , attribute16
                              , attribute17
                              , attribute18
                              , attribute19
                              , attribute20
                              , last_update_date
                              , last_updated_by
                              , creation_date
                              , created_by
                              , last_update_login
                              , request_id
                              , program_application_id
                              , program_id
                              , program_update_date
                              , wh_update_date )
            VALUES    ( p_ebl_conv_doc_id
                      , p_new_cust_doc_id
                      , p_new_doc_status
                      , p_batch_id
                      , p_cust_account_id
                      , p_account_number
                      , p_aops_number
                      , p_old_cust_doc_id
                      , p_old_frequency
                      , p_old_report_day
                      , p_billdocs_mbs_doc_id
                      , p_billdocs_pay_doc_ind
                      , p_billdocs_delivery_method
                      , p_billdocs_direct_flag
                      , p_billdocs_doc_type
                      , p_billdocs_combo_type
                      , p_billdocs_payment_term
                      , p_billdocs_term_id
                      , p_billdocs_is_parent
                      , p_billdocs_send_to_parent
                      , p_billdocs_parent_doc_id
                      , p_billdocs_mail_to_attention
                      , p_billdoc_status
                      , p_billdocs_record_status
                      , p_billdocs_req_start_date
                      , p_ebill_transmission_type
                      , p_ebill_associate
                      , p_file_processing_method
                      , p_file_name_ext
                      , p_max_file_size
                      , p_max_transmission_size
                      , p_zip_required
                      , p_zipping_utility
                      , p_zip_file_name_ext
                      , p_od_field_contact
                      , p_od_field_contact_phone
                      , p_od_field_contact_email
                      , p_client_tech_contact
                      , p_client_tech_contact_phone
                      , p_client_tech_contact_email
                      , p_field_selection
                      , p_file_name_seq_reset
                      , p_file_next_seq_number
                      , p_file_seq_reset_date
                      , p_file_name_max_seq_number
                      , p_email_subject
                      , p_email_std_message
                      , p_email_custom_message
                      , p_email_std_disclaimer
                      , p_email_signature
                      , p_email_logo_required
                      , p_email_logo_file_name
                      , p_ftp_direction
                      , p_ftp_transfer_type
                      , p_ftp_destination_site
                      , p_ftp_destination_folder
                      , p_ftp_user_name
                      , p_ftp_password
                      , p_ftp_pickup_server
                      , p_ftp_pickup_folder
                      , p_ftp_cust_contact_name
                      , p_ftp_cust_contact_email
                      , p_ftp_cust_contact_phone
                      , p_ftp_notify_customer
                      , p_ftp_cc_emails
                      , p_ftp_email_sub
                      , p_ftp_email_content
                      , p_ftp_send_zero_byte_file
                      , p_ftp_zero_byte_file_text
                      , p_ftp_zero_byte_notification
                      , p_cd_file_location
                      , p_cd_send_to_address
                      , p_comments
                      , p_attribute1
                      , p_attribute2
                      , p_attribute3
                      , p_attribute4
                      , p_attribute5
                      , p_attribute6
                      , p_attribute7
                      , p_attribute8
                      , p_attribute9
                      , p_attribute10
                      , p_attribute11
                      , p_attribute12
                      , p_attribute13
                      , p_attribute14
                      , p_attribute15
                      , p_attribute16
                      , p_attribute17
                      , p_attribute18
                      , p_attribute19
                      , p_attribute20
                      , p_last_update_date
                      , p_last_updated_by
                      , p_creation_date
                      , p_created_by
                      , p_last_update_login
                      , p_request_id
                      , p_program_application_id
                      , p_program_id
                      , p_program_update_date
                      , p_wh_update_date );
                      
  x_status := 'S';

EXCEPTION

   WHEN OTHERS THEN
    
    x_status := 'E';
    x_error_message := 'Insert into xx_cdh_ebl_conv_doc_dtl failed.' || ' SQLCODE - ' || SQLCODE || ' SQLERRM - '  || INITCAP(SQLERRM);

END insert_row;

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
                    , p_wh_update_date                  IN DATE     DEFAULT NULL)
IS
BEGIN

  UPDATE xx_cdh_ebl_conv_doc_dtl
  SET   new_cust_doc_id                =   p_new_cust_doc_id
      , new_doc_status                 =   p_new_doc_status
      , batch_id                       =   p_batch_id
      , cust_account_id                =   p_cust_account_id
      , account_number                 =   p_account_number
      , aops_number                    =   p_aops_number
      , old_cust_doc_id                =   p_old_cust_doc_id
      , old_frequency                  =   p_old_frequency
      , old_report_day                 =   p_old_report_day
      , billdocs_mbs_doc_id            =   p_billdocs_mbs_doc_id
      , billdocs_pay_doc_ind           =   p_billdocs_pay_doc_ind
      , billdocs_delivery_method       =   p_billdocs_delivery_method
      , billdocs_direct_flag           =   p_billdocs_direct_flag
      , billdocs_doc_type              =   p_billdocs_doc_type
      , billdocs_combo_type            =   p_billdocs_combo_type
      , billdocs_payment_term          =   p_billdocs_payment_term
      , billdocs_term_id               =   p_billdocs_term_id
      , billdocs_is_parent             =   p_billdocs_is_parent
      , billdocs_send_to_parent        =   p_billdocs_send_to_parent
      , billdocs_parent_doc_id         =   p_billdocs_parent_doc_id
      , billdocs_mail_to_attention     =   p_billdocs_mail_to_attention
      , billdoc_status                 =   p_billdoc_status
      , billdocs_record_status         =   p_billdocs_record_status
      , billdocs_req_start_date        =   p_billdocs_req_start_date
      , ebill_transmission_type        =   p_ebill_transmission_type
      , ebill_associate                =   p_ebill_associate
      , file_processing_method         =   p_file_processing_method
      , file_name_ext                  =   p_file_name_ext
      , max_file_size                  =   p_max_file_size
      , max_transmission_size          =   p_max_transmission_size
      , zip_required                   =   p_zip_required
      , zipping_utility                =   p_zipping_utility
      , zip_file_name_ext              =   p_zip_file_name_ext
      , od_field_contact               =   p_od_field_contact
      , od_field_contact_phone         =   p_od_field_contact_phone
      , od_field_contact_email         =   p_od_field_contact_email
      , client_tech_contact            =   p_client_tech_contact
      , client_tech_contact_phone      =   p_client_tech_contact_phone
      , client_tech_contact_email      =   p_client_tech_contact_email
      , field_selection                =   p_field_selection
      , file_name_seq_reset            =   p_file_name_seq_reset
      , file_next_seq_number           =   p_file_next_seq_number
      , file_seq_reset_date            =   p_file_seq_reset_date
      , file_name_max_seq_number       =   p_file_name_max_seq_number
      , email_subject                  =   p_email_subject
      , email_std_message              =   p_email_std_message
      , email_custom_message           =   p_email_custom_message
      , email_std_disclaimer           =   p_email_std_disclaimer
      , email_signature                =   p_email_signature
      , email_logo_required            =   p_email_logo_required
      , email_logo_file_name           =   p_email_logo_file_name
      , ftp_direction                  =   p_ftp_direction
      , ftp_transfer_type              =   p_ftp_transfer_type
      , ftp_destination_site           =   p_ftp_destination_site
      , ftp_destination_folder         =   p_ftp_destination_folder
      , ftp_user_name                  =   p_ftp_user_name
      , ftp_password                   =   p_ftp_password
      , ftp_pickup_server              =   p_ftp_pickup_server
      , ftp_pickup_folder              =   p_ftp_pickup_folder
      , ftp_cust_contact_name          =   p_ftp_cust_contact_name
      , ftp_cust_contact_email         =   p_ftp_cust_contact_email
      , ftp_cust_contact_phone         =   p_ftp_cust_contact_phone
      , ftp_notify_customer            =   p_ftp_notify_customer
      , ftp_cc_emails                  =   p_ftp_cc_emails
      , ftp_email_sub                  =   p_ftp_email_sub
      , ftp_email_content              =   p_ftp_email_content
      , ftp_send_zero_byte_file        =   p_ftp_send_zero_byte_file
      , ftp_zero_byte_file_text        =   p_ftp_zero_byte_file_text
      , ftp_zero_byte_notification_txt =   p_ftp_zero_byte_notification
      , cd_file_location               =   p_cd_file_location
      , cd_send_to_address             =   p_cd_send_to_address
      , comments                       =   p_comments
      , attribute1                     =   p_attribute1
      , attribute2                     =   p_attribute2
      , attribute3                     =   p_attribute3
      , attribute4                     =   p_attribute4
      , attribute5                     =   p_attribute5
      , attribute6                     =   p_attribute6
      , attribute7                     =   p_attribute7
      , attribute8                     =   p_attribute8
      , attribute9                     =   p_attribute9
      , attribute10                    =   p_attribute10
      , attribute11                    =   p_attribute11
      , attribute12                    =   p_attribute12
      , attribute13                    =   p_attribute13
      , attribute14                    =   p_attribute14
      , attribute15                    =   p_attribute15
      , attribute16                    =   p_attribute16
      , attribute17                    =   p_attribute17
      , attribute18                    =   p_attribute18
      , attribute19                    =   p_attribute19
      , attribute20                    =   p_attribute20
      , last_update_date               =   p_last_update_date
      , last_updated_by                =   p_last_updated_by
      , creation_date                  =   p_creation_date
      , created_by                     =   p_created_by
      , last_update_login              =   p_last_update_login
      , request_id                     =   p_request_id
      , program_application_id         =   p_program_application_id
      , program_id                     =   p_program_id
      , program_update_date            =   p_program_update_date
      , wh_update_date                 =   p_wh_update_date
  WHERE ebl_conv_doc_id        = p_ebl_conv_doc_id;

  x_status := 'S';

EXCEPTION

   WHEN OTHERS THEN
    
    x_status := 'E';
    x_error_message := 'Update into xx_cdh_ebl_conv_doc_dtl failed.' || ' SQLCODE - ' || SQLCODE || ' SQLERRM - '  || INITCAP(SQLERRM);

END update_row;

END xx_cdh_ebl_conv_doc_dtl_pkg;
/

SHOW ERRORS;