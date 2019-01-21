SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_EBL_TRANS_DTL_PKG
  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XX_CDH_EBL_TRANS_DTL_PKG                                    |
  -- | Description :                                                             |
  -- | This package provides table handlers for the table                        |
  -- | XX_CDH_EBL_TRANSMISSION_DTL.                                              |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author        Remarks                                 |
  -- |======== =========== ============= ========================================|
  -- |DRAFT 1A 24-FEB-2010 Mangala       Initial draft version                   |
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
  -- | This procedure inserts data into the table XX_CDH_EBL_TRANSMISSION_DTL.   |
  -- |                                                                           |
  -- |                                                                           |
  -- | Parameters  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | Returns     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+
  
PROCEDURE insert_row(
    p_cust_doc_id              IN NUMBER ,
    p_email_subject            IN VARCHAR2 ,
    p_email_std_message        IN VARCHAR2 ,
    p_email_custom_message     IN VARCHAR2 ,
    p_email_std_disclaimer     IN VARCHAR2 ,
    p_email_signature          IN VARCHAR2 ,
    p_email_logo_required      IN VARCHAR2 ,
    p_email_logo_file_name     IN VARCHAR2 ,
    p_ftp_direction            IN VARCHAR2 ,
    p_ftp_transfer_type        IN VARCHAR2 ,
    p_ftp_destination_site     IN VARCHAR2 ,
    p_ftp_destination_folder   IN VARCHAR2 ,
    p_ftp_user_name            IN VARCHAR2 ,
    p_ftp_password             IN VARCHAR2 ,
    p_ftp_pickup_server        IN VARCHAR2 ,
    p_ftp_pickup_folder        IN VARCHAR2 ,
    p_ftp_cust_contact_name    IN VARCHAR2 ,
    p_ftp_cust_contact_email   IN VARCHAR2 ,
    p_ftp_cust_contact_phone   IN VARCHAR2 ,
    p_ftp_notify_customer      IN VARCHAR2 ,
    p_ftp_cc_emails            IN VARCHAR2 ,
    p_ftp_email_sub            IN VARCHAR2 ,
    p_ftp_email_content        IN VARCHAR2 ,
    p_ftp_send_zero_byte_file  IN VARCHAR2 ,
    p_ftp_zero_byte_file_text  IN VARCHAR2 ,
    p_ftp_zero_byte_notifi_txt IN VARCHAR2 ,
    p_cd_file_location         IN VARCHAR2 ,
    p_cd_send_to_address       IN VARCHAR2 ,
    p_comments                 IN VARCHAR2 ,
    p_attribute1               IN VARCHAR2 DEFAULT NULL,
    p_attribute2               IN VARCHAR2 DEFAULT NULL,
    p_attribute3               IN VARCHAR2 DEFAULT NULL,
    p_attribute4               IN VARCHAR2 DEFAULT NULL,
    p_attribute5               IN VARCHAR2 DEFAULT NULL,
    p_attribute6               IN VARCHAR2 DEFAULT NULL,
    p_attribute7               IN VARCHAR2 DEFAULT NULL,
    p_attribute8               IN VARCHAR2 DEFAULT NULL,
    p_attribute9               IN VARCHAR2 DEFAULT NULL,
    p_attribute10              IN VARCHAR2 DEFAULT NULL,
    p_attribute11              IN VARCHAR2 DEFAULT NULL,
    p_attribute12              IN VARCHAR2 DEFAULT NULL,
    p_attribute13              IN VARCHAR2 DEFAULT NULL,
    p_attribute14              IN VARCHAR2 DEFAULT NULL,
    p_attribute15              IN VARCHAR2 DEFAULT NULL,
    p_attribute16              IN VARCHAR2 DEFAULT NULL,
    p_attribute17              IN VARCHAR2 DEFAULT NULL,
    p_attribute18              IN VARCHAR2 DEFAULT NULL,
    p_attribute19              IN VARCHAR2 DEFAULT NULL,
    p_attribute20              IN VARCHAR2 DEFAULT NULL,
    p_last_update_date         IN DATE DEFAULT SYSDATE,
    p_last_updated_by          IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_creation_date            IN DATE DEFAULT SYSDATE ,
    p_created_by               IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_last_update_login        IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_request_id               IN NUMBER DEFAULT NULL ,
    p_program_application_id   IN NUMBER DEFAULT NULL,
    p_program_id               IN NUMBER DEFAULT NULL,
    p_program_update_date      IN DATE DEFAULT NULL,
    p_wh_update_date           IN DATE DEFAULT NULL)
    
IS

BEGIN

  INSERT
  INTO xx_cdh_ebl_transmission_dtl
    (
      cust_doc_id ,
      email_subject,
      email_std_message,
      email_custom_message,
      email_std_disclaimer,
      email_signature,
      email_logo_required,
      email_logo_file_name,
      ftp_direction,
      ftp_transfer_type,
      ftp_destination_site,
      ftp_destination_folder,
      ftp_user_name,
      ftp_password,
      ftp_pickup_server,
      ftp_pickup_folder,
      ftp_cust_contact_name,
      ftp_cust_contact_email,
      ftp_cust_contact_phone,
      ftp_notify_customer,
      ftp_cc_emails,
      ftp_email_sub,
      ftp_email_content,
      ftp_send_zero_byte_file,
      ftp_zero_byte_file_text,
      ftp_zero_byte_notification_txt,
      cd_file_location,
      cd_send_to_address,
      comments,
      attribute1,
      attribute2,
      attribute3,
      attribute4,
      attribute5,
      attribute6,
      attribute7,
      attribute8,
      attribute9,
      attribute10,
      attribute11,
      attribute12,
      attribute13,
      attribute14,
      attribute15,
      attribute16,
      attribute17,
      attribute18,
      attribute19,
      attribute20,
      last_update_date ,
      last_updated_by ,
      creation_date ,
      created_by ,
      last_update_login ,
      request_id,
      program_application_id,
      program_id,
      program_update_date,
      wh_update_date
    )
    VALUES
    (
      p_cust_doc_id ,
      p_email_subject,
      p_email_std_message,
      p_email_custom_message,
      p_email_std_disclaimer,
      p_email_signature,
      p_email_logo_required,
      p_email_logo_file_name,
      p_ftp_direction,
      p_ftp_transfer_type,
      p_ftp_destination_site,
      p_ftp_destination_folder,
      p_ftp_user_name,
      p_ftp_password,
      p_ftp_pickup_server,
      p_ftp_pickup_folder,
      p_ftp_cust_contact_name,
      p_ftp_cust_contact_email,
      p_ftp_cust_contact_phone,
      p_ftp_notify_customer,
      p_ftp_cc_emails,
      p_ftp_email_sub,
      p_ftp_email_content,
      p_ftp_send_zero_byte_file,
      p_ftp_zero_byte_file_text,
      p_ftp_zero_byte_notifi_txt,
      p_cd_file_location,
      p_cd_send_to_address,
      p_comments,
      p_attribute1,
      p_attribute2,
      p_attribute3,
      p_attribute4,
      p_attribute5,
      p_attribute6,
      p_attribute7,
      p_attribute8,
      p_attribute9,
      p_attribute10,
      p_attribute11,
      p_attribute12,
      p_attribute13,
      p_attribute14,
      p_attribute15,
      p_attribute16,
      p_attribute17,
      p_attribute18,
      p_attribute19,
      p_attribute20,
      p_last_update_date ,
      p_last_updated_by ,
      SYSDATE ,
      p_created_by ,
      p_last_update_login ,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL
    );

END insert_row;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : UPDATE_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall update data in the table XX_CDH_EBL_TRANSMISSION_DTL |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE update_row
  (
    p_cust_doc_id              IN NUMBER ,
    p_email_subject            IN VARCHAR2 ,
    p_email_std_message        IN VARCHAR2 ,
    p_email_custom_message     IN VARCHAR2 ,
    p_email_std_disclaimer     IN VARCHAR2 ,
    p_email_signature          IN VARCHAR2 ,
    p_email_logo_required      IN VARCHAR2 ,
    p_email_logo_file_name     IN VARCHAR2 ,
    p_ftp_direction            IN VARCHAR2 ,
    p_ftp_transfer_type        IN VARCHAR2 ,
    p_ftp_destination_site     IN VARCHAR2 ,
    p_ftp_destination_folder   IN VARCHAR2 ,
    p_ftp_user_name            IN VARCHAR2 ,
    p_ftp_password             IN VARCHAR2 ,
    p_ftp_pickup_server        IN VARCHAR2 ,
    p_ftp_pickup_folder        IN VARCHAR2 ,
    p_ftp_cust_contact_name    IN VARCHAR2 ,
    p_ftp_cust_contact_email   IN VARCHAR2 ,
    p_ftp_cust_contact_phone   IN VARCHAR2 ,
    p_ftp_notify_customer      IN VARCHAR2 ,
    p_ftp_cc_emails            IN VARCHAR2 ,
    p_ftp_email_sub            IN VARCHAR2 ,
    p_ftp_email_content        IN VARCHAR2 ,
    p_ftp_send_zero_byte_file  IN VARCHAR2 ,
    p_ftp_zero_byte_file_text  IN VARCHAR2 ,
    p_ftp_zero_byte_notifi_txt IN VARCHAR2 ,
    p_cd_file_location         IN VARCHAR2 ,
    p_cd_send_to_address       IN VARCHAR2 ,
    p_comments                 IN VARCHAR2 ,
    p_attribute1               IN VARCHAR2 DEFAULT NULL ,
    p_attribute2               IN VARCHAR2 DEFAULT NULL ,
    p_attribute3               IN VARCHAR2 DEFAULT NULL ,
    p_attribute4               IN VARCHAR2 DEFAULT NULL ,
    p_attribute5               IN VARCHAR2 DEFAULT NULL ,
    p_attribute6               IN VARCHAR2 DEFAULT NULL ,
    p_attribute7               IN VARCHAR2 DEFAULT NULL ,
    p_attribute8               IN VARCHAR2 DEFAULT NULL ,
    p_attribute9               IN VARCHAR2 DEFAULT NULL ,
    p_attribute10              IN VARCHAR2 DEFAULT NULL ,
    p_attribute11              IN VARCHAR2 DEFAULT NULL ,
    p_attribute12              IN VARCHAR2 DEFAULT NULL ,
    p_attribute13              IN VARCHAR2 DEFAULT NULL ,
    p_attribute14              IN VARCHAR2 DEFAULT NULL ,
    p_attribute15              IN VARCHAR2 DEFAULT NULL ,
    p_attribute16              IN VARCHAR2 DEFAULT NULL ,
    p_attribute17              IN VARCHAR2 DEFAULT NULL ,
    p_attribute18              IN VARCHAR2 DEFAULT NULL ,
    p_attribute19              IN VARCHAR2 DEFAULT NULL ,
    p_attribute20              IN VARCHAR2 DEFAULT NULL ,
    p_last_update_date         IN DATE DEFAULT SYSDATE,
    p_last_updated_by          IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_creation_date            IN DATE DEFAULT NULL ,
    p_created_by               IN NUMBER DEFAULT NULL,
    p_last_update_login        IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_request_id               IN NUMBER DEFAULT NULL ,
    p_program_application_id   IN NUMBER DEFAULT NULL ,
    p_program_id               IN NUMBER DEFAULT NULL ,
    p_program_update_date      IN DATE DEFAULT NULL ,
    p_wh_update_date           IN DATE DEFAULT NULL
  )
IS

BEGIN

  UPDATE xx_cdh_ebl_transmission_dtl
  SET email_subject               = p_email_subject,
    email_std_message             = p_email_std_message,
    email_custom_message          = p_email_custom_message,
    email_std_disclaimer          = p_email_std_disclaimer,
    email_signature               = p_email_signature,
    email_logo_required           = p_email_logo_required,
    email_logo_file_name          = p_email_logo_file_name,
    ftp_direction                 = p_ftp_direction,
    ftp_transfer_type             = p_ftp_transfer_type,
    ftp_destination_site          = p_ftp_destination_site ,
    ftp_destination_folder        = p_ftp_destination_folder,
    ftp_user_name                 = p_ftp_user_name,
    ftp_password                  = p_ftp_password,
    ftp_pickup_server             = p_ftp_pickup_server,
    ftp_pickup_folder             = p_ftp_pickup_folder,
    ftp_cust_contact_name         = p_ftp_cust_contact_name,
    ftp_cust_contact_email        = p_ftp_cust_contact_email,
    ftp_cust_contact_phone        = p_ftp_cust_contact_phone,
    ftp_notify_customer           = p_ftp_notify_customer,
    ftp_cc_emails                 = p_ftp_cc_emails,
    ftp_email_sub                 = p_ftp_email_sub,
    ftp_email_content             = p_ftp_email_content,
    ftp_send_zero_byte_file       = p_ftp_send_zero_byte_file,
    ftp_zero_byte_file_text       = p_ftp_zero_byte_file_text,
    ftp_zero_byte_notification_txt= p_ftp_zero_byte_notifi_txt,
    cd_file_location              = p_cd_file_location,
    cd_send_to_address            = p_cd_send_to_address,
    comments                      = p_comments,
    attribute1                    = p_attribute1,
    attribute2                    = p_attribute2,
    attribute3                    = p_attribute3,
    attribute4                    = p_attribute4,
    attribute5                    = p_attribute5,
    attribute6                    = p_attribute6,
    attribute7                    = p_attribute7,
    attribute8                    = p_attribute8,
    attribute9                    = p_attribute9,
    attribute10                   = p_attribute10,
    attribute11                   = p_attribute11,
    attribute12                   = p_attribute12,
    attribute13                   = p_attribute13,
    attribute14                   = p_attribute14,
    attribute15                   = p_attribute15,
    attribute16                   = p_attribute16,
    attribute17                   = p_attribute17,
    attribute18                   = p_attribute18,
    attribute19                   = p_attribute19,
    attribute20                   = p_attribute20,
    last_update_date              = p_last_update_date ,
    last_updated_by               = p_last_updated_by ,
    last_update_login             = p_last_update_login ,
    request_id                    = p_request_id,
    program_application_id        = p_program_application_id,
    program_id                    = p_program_id,
    program_update_date           = p_program_update_date,
    wh_update_date                = p_wh_update_date
  WHERE cust_doc_id               = p_cust_doc_id ;
  
  IF (sql%notfound) THEN
    RAISE no_data_found;
  END IF;

EXCEPTION
   WHEN no_data_found THEN
      raise ;
   WHEN OTHERS THEN
      raise ;
END update_row;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : DELETE_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- |This procedure shall delete data  in XX_CDH_EBL_TRANSMISSION_DTL           |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE delete_row(
    p_cust_doc_id IN NUMBER)
IS
BEGIN

  DELETE FROM xx_cdh_ebl_transmission_dtl WHERE cust_doc_id = p_cust_doc_id;
  
  IF (sql%notfound) THEN
    RAISE no_data_found;
  END IF;
  
EXCEPTION
   WHEN no_data_found THEN
      raise ;
      
   WHEN too_many_rows THEN
      raise ;
      
   WHEN OTHERS THEN
      raise ;
      
END delete_row;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : LOCK_ROW                                                    |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall lock rows into  the table XX_CDH_EBL_TRANSMISSION_DTL|
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

/*
PROCEDURE lock_row(
p_cust_doc_id     IN NUMBER ,
p_email_subject     IN VARCHAR2 ,
p_email_std_message    IN VARCHAR2 ,
p_email_custom_message    IN VARCHAR2 ,
p_email_std_disclaimer    IN VARCHAR2 ,
p_email_signature    IN VARCHAR2 ,
p_email_logo_required    IN VARCHAR2 ,
p_email_logo_file_name    IN VARCHAR2 ,
p_ftp_direction     IN VARCHAR2 ,
p_ftp_transfer_type    IN VARCHAR2 ,
p_ftp_destination_site    IN VARCHAR2 ,
p_ftp_destination_folder   IN VARCHAR2 ,
p_ftp_user_name     IN VARCHAR2 ,
p_ftp_password     IN VARCHAR2 ,
p_ftp_pickup_server    IN VARCHAR2 ,
p_ftp_pickup_folder    IN VARCHAR2 ,
p_ftp_cust_contact_name    IN VARCHAR2 ,
p_ftp_cust_contact_email   IN VARCHAR2 ,
p_ftp_cust_contact_phone   IN VARCHAR2 ,
p_ftp_notify_customer    IN VARCHAR2 ,
p_ftp_cc_emails     IN VARCHAR2 ,
p_ftp_email_sub     IN VARCHAR2 ,
p_ftp_email_content    IN VARCHAR2 ,
p_ftp_send_zero_byte_file  IN VARCHAR2 ,
p_ftp_zero_byte_file_text  IN VARCHAR2 ,
p_ftp_zero_byte_notifi_txt IN VARCHAR2 ,
p_cd_file_location    IN VARCHAR2 ,
p_cd_send_to_address    IN VARCHAR2 ,
p_comments     IN VARCHAR2 ,
p_attribute1     IN VARCHAR2 ,
p_attribute2     IN VARCHAR2 ,
p_attribute3     IN VARCHAR2 ,
p_attribute4     IN VARCHAR2 ,
p_attribute5     IN VARCHAR2 ,
p_attribute6     IN VARCHAR2 ,
p_attribute7     IN VARCHAR2 ,
p_attribute8     IN VARCHAR2 ,
p_attribute9     IN VARCHAR2 ,
p_attribute10     IN VARCHAR2 ,
p_attribute11     IN VARCHAR2 ,
p_attribute12     IN VARCHAR2 ,
p_attribute13     IN VARCHAR2 ,
p_attribute14     IN VARCHAR2 ,
p_attribute15     IN VARCHAR2 ,
p_attribute16     IN VARCHAR2 ,
p_attribute17     IN VARCHAR2 ,
p_attribute18     IN VARCHAR2 ,
p_attribute19     IN VARCHAR2 ,
p_attribute20     IN VARCHAR2 ,
p_last_update_date    IN DATE ,
p_last_updated_by    IN NUMBER ,
p_creation_date     IN DATE DEFAULT SYSDATE ,
p_created_by     IN NUMBER ,
p_last_update_login    IN NUMBER ,
p_request_id     IN NUMBER ,
p_program_application_id   IN NUMBER ,
p_program_id     IN NUMBER ,
p_program_update_date    IN DATE ,
p_wh_update_date    IN DATE ); */

END XX_CDH_EBL_TRANS_DTL_PKG ;
/

SHOW ERRORS;