SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_EBL_MAIN_PKG AUTHID CURRENT_USER

  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XX_CDH_EBL_MAIN_PKG                                         |
  -- | Description :                                                             |
  -- | This package provides table handlers for the table XX_CDH_EBL_MAIN.       |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author        Remarks                                 |
  -- |======== =========== ============= ========================================|
  -- |DRAFT 1A 24-FEB-2010 Mangala        Initial draft version                  |
  -- |1.0      31-MAR-2016 Havish K       Modified for MOD4B Rel 4 Changes       |
  -- |2.0      25-MAR-2017 Bhagwan G      Changed for Defects#38962 and 2302     |  
  -- |3.0      29-May-2018 Reddy Sekhar K Modified for Defect# NAIT-27146        |
  -- |                                                                           |
  -- +===========================================================================+

AS

  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : INSERT_ROW                                                  |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | This procedure inserts data into the table  XX_CDH_EBL_MAIN.              |
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
    p_cust_doc_id               IN NUMBER ,
    p_cust_account_id           IN NUMBER ,
    p_ebill_transmission_type   IN VARCHAR2 ,
    p_ebill_associate           IN VARCHAR2 ,
    p_file_processing_method    IN VARCHAR2 ,
    p_file_name_ext             IN VARCHAR2,
    p_max_file_size             IN NUMBER ,
    p_max_transmission_size     IN NUMBER ,
    p_zip_required              IN VARCHAR2 ,
    p_zipping_utility           IN VARCHAR2 ,
    p_zip_file_name_ext         IN VARCHAR2 ,
    p_od_field_contact          IN VARCHAR2 ,
    p_od_field_contact_email    IN VARCHAR2 ,
    p_od_field_contact_phone    IN VARCHAR2 ,
    p_client_tech_contact       IN VARCHAR2 ,
    p_client_tech_contact_email IN VARCHAR2 ,
    p_client_tech_contact_phone IN VARCHAR2 ,
    p_file_name_seq_reset       IN VARCHAR2 ,
    p_file_next_seq_number      IN NUMBER ,
    p_file_seq_reset_date       IN DATE ,
    p_file_name_max_seq_number  IN NUMBER ,
    p_attribute1                IN VARCHAR2 DEFAULT NULL ,
    p_attribute2                IN VARCHAR2 DEFAULT NULL ,
    p_attribute3                IN VARCHAR2 DEFAULT NULL ,
    p_attribute4                IN VARCHAR2 DEFAULT NULL ,
    p_attribute5                IN VARCHAR2 DEFAULT NULL ,
    p_attribute6                IN VARCHAR2 DEFAULT NULL ,
    p_attribute7                IN VARCHAR2 DEFAULT NULL ,
    p_attribute8                IN VARCHAR2 DEFAULT NULL ,
    p_attribute9                IN VARCHAR2 DEFAULT NULL ,
    p_attribute10               IN VARCHAR2 DEFAULT NULL ,
    p_attribute11               IN VARCHAR2 DEFAULT NULL ,
    p_attribute12               IN VARCHAR2 DEFAULT NULL ,
    p_attribute13               IN VARCHAR2 DEFAULT NULL ,
    p_attribute14               IN VARCHAR2 DEFAULT NULL ,
    p_attribute15               IN VARCHAR2 DEFAULT NULL ,
    p_attribute16               IN VARCHAR2 DEFAULT NULL ,
    p_attribute17               IN VARCHAR2 DEFAULT NULL ,
    p_attribute18               IN VARCHAR2 DEFAULT NULL ,
    p_attribute19               IN VARCHAR2 DEFAULT NULL ,
    p_attribute20               IN VARCHAR2 DEFAULT NULL ,
    p_last_update_date          IN DATE DEFAULT SYSDATE ,
    p_last_updated_by           IN NUMBER DEFAULT FND_GLOBAL.USER_ID ,
    p_creation_date             IN DATE DEFAULT SYSDATE ,
    p_created_by                IN NUMBER DEFAULT FND_GLOBAL.USER_ID ,
    p_last_update_login         IN NUMBER DEFAULT FND_GLOBAL.USER_ID ,
    p_request_id                IN NUMBER DEFAULT NULL ,
    p_program_application_id    IN NUMBER DEFAULT NULL ,
    p_program_id                IN NUMBER DEFAULT NULL ,
    p_program_update_date       IN DATE DEFAULT NULL ,
    p_wh_update_date            IN DATE DEFAULT NULL ,
	p_delimiter_char            IN VARCHAR2 DEFAULT NULL,-- Added for MOD4B Rel 4 Changes
	p_file_creation_type        IN VARCHAR2 DEFAULT NULL, -- Added for MOD4B Rel 4 Changes
    p_summary_bill              IN VARCHAR2 DEFAULT NULL,
    p_nondt_qty                 IN NUMBER DEFAULT NULL ,
    p_parent_doc_id             IN NUMBER DEFAULT NULL --Added by Reddy Sekhar K for the defect # NAIT-27146 on 29-May-2018
   );

  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : UPDATE_ROW                                                  |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | This procedure shall update data into the table XX_CDH_EBL_MAIN           |
  -- |                                                                           |
  -- |                                                                           |
  -- | Parameters  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | Returns     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

PROCEDURE update_row(
    p_cust_doc_id               IN NUMBER ,
    p_cust_account_id           IN NUMBER ,
    p_ebill_transmission_type   IN VARCHAR2 ,
    p_ebill_associate           IN VARCHAR2 ,
    p_file_processing_method    IN VARCHAR2 ,
    p_file_name_ext             IN VARCHAR2,
    p_max_file_size             IN NUMBER ,
    p_max_transmission_size     IN NUMBER ,
    p_zip_required              IN VARCHAR2 ,
    p_zipping_utility           IN VARCHAR2 ,
    p_zip_file_name_ext         IN VARCHAR2 ,
    p_od_field_contact          IN VARCHAR2 ,
    p_od_field_contact_email    IN VARCHAR2 ,
    p_od_field_contact_phone    IN VARCHAR2 ,
    p_client_tech_contact       IN VARCHAR2 ,
    p_client_tech_contact_email IN VARCHAR2 ,
    p_client_tech_contact_phone IN VARCHAR2 ,
    p_file_name_seq_reset       IN VARCHAR2 ,
    p_file_next_seq_number      IN NUMBER ,
    p_file_seq_reset_date       IN DATE ,
    p_file_name_max_seq_number  IN NUMBER ,
    p_attribute1                IN VARCHAR2 DEFAULT NULL ,
    p_attribute2                IN VARCHAR2 DEFAULT NULL ,
    p_attribute3                IN VARCHAR2 DEFAULT NULL ,
    p_attribute4                IN VARCHAR2 DEFAULT NULL ,
    p_attribute5                IN VARCHAR2 DEFAULT NULL ,
    p_attribute6                IN VARCHAR2 DEFAULT NULL ,
    p_attribute7                IN VARCHAR2 DEFAULT NULL ,
    p_attribute8                IN VARCHAR2 DEFAULT NULL ,
    p_attribute9                IN VARCHAR2 DEFAULT NULL ,
    p_attribute10               IN VARCHAR2 DEFAULT NULL ,
    p_attribute11               IN VARCHAR2 DEFAULT NULL ,
    p_attribute12               IN VARCHAR2 DEFAULT NULL ,
    p_attribute13               IN VARCHAR2 DEFAULT NULL ,
    p_attribute14               IN VARCHAR2 DEFAULT NULL ,
    p_attribute15               IN VARCHAR2 DEFAULT NULL ,
    p_attribute16               IN VARCHAR2 DEFAULT NULL ,
    p_attribute17               IN VARCHAR2 DEFAULT NULL ,
    p_attribute18               IN VARCHAR2 DEFAULT NULL ,
    p_attribute19               IN VARCHAR2 DEFAULT NULL ,
    p_attribute20               IN VARCHAR2 DEFAULT NULL ,
    p_last_update_date          IN DATE DEFAULT SYSDATE ,
    p_last_updated_by           IN NUMBER DEFAULT FND_GLOBAL.USER_ID ,
    p_creation_date             IN DATE DEFAULT NULL ,
    p_created_by                IN NUMBER DEFAULT NULL ,
    p_last_update_login         IN NUMBER DEFAULT FND_GLOBAL.USER_ID ,
    p_request_id                IN NUMBER DEFAULT NULL ,
    p_program_application_id    IN NUMBER DEFAULT NULL ,
    p_program_id                IN NUMBER DEFAULT NULL ,
    p_program_update_date       IN DATE DEFAULT NULL ,
    p_wh_update_date            IN DATE DEFAULT NULL,
	p_delimiter_char            IN VARCHAR2 DEFAULT NULL,-- Added for MOD4B Rel 4 Changes
	p_file_creation_type        IN VARCHAR2 DEFAULT NULL, -- Added for MOD4B Rel 4 Changes
    p_summary_bill              IN VARCHAR2 DEFAULT NULL,
    p_nondt_qty                 IN NUMBER DEFAULT NULL,
    p_parent_doc_id             IN NUMBER DEFAULT NULL --Added by Reddy Sekhar K for the defect # NAIT-27146 on 29-May-2018  
   );

  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : DELETE_ROW                                                  |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | This procedure shall delete data  in XX_CDH_EBL_MAIN                      |
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
    p_cust_doc_id IN NUMBER );

  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : LOCK_ROW                                                    |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | 	This procedure shall lock rows into  the table XX_CDH_EBL_MAIN.          |
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
  p_cust_doc_id               IN NUMBER
  ,p_cust_account_id           IN NUMBER
  ,p_ebill_transmission_type   IN VARCHAR2
  ,p_ebill_associate           IN VARCHAR2
  ,p_file_processing_method    IN VARCHAR2
  ,p_file_name_ext             IN VARCHAR2
  ,p_max_file_size             IN NUMBER
  ,p_max_transmission_size     IN NUMBER
  ,p_zip_required              IN VARCHAR2
  ,p_zipping_utility           IN VARCHAR2
  ,p_zip_file_name_ext         IN VARCHAR2
  ,p_od_field_contact          IN VARCHAR2
  ,p_od_field_contact_email    IN VARCHAR2
  ,p_od_field_contact_phone    IN VARCHAR2
  ,p_client_tech_contact       IN VARCHAR2
  ,p_client_tech_contact_email IN VARCHAR2
  ,p_client_tech_contact_phone IN VARCHAR2
  ,p_file_name_seq_reset       IN VARCHAR2
  ,p_file_next_seq_number      IN NUMBER
  ,p_file_seq_reset_date       IN DATE
  ,p_file_name_max_seq_number  IN NUMBER
  ,p_attribute1                IN VARCHAR2
  ,p_attribute2                IN VARCHAR2
  ,p_attribute3                IN VARCHAR2
  ,p_attribute4                IN VARCHAR2
  ,p_attribute5                IN VARCHAR2
  ,p_attribute6                IN VARCHAR2
  ,p_attribute7                IN VARCHAR2
  ,p_attribute8                IN VARCHAR2
  ,p_attribute9                IN VARCHAR2
  ,p_attribute10               IN VARCHAR2
  ,p_attribute11               IN VARCHAR2
  ,p_attribute12               IN VARCHAR2
  ,p_attribute13               IN VARCHAR2
  ,p_attribute14               IN VARCHAR2
  ,p_attribute15               IN VARCHAR2
  ,p_attribute16               IN VARCHAR2
  ,p_attribute17               IN VARCHAR2
  ,p_attribute18               IN VARCHAR2
  ,p_attribute19               IN VARCHAR2
  ,p_attribute20               IN VARCHAR2
  ,p_last_update_date          IN DATE
  ,p_last_updated_by           IN NUMBER
  ,p_creation_date             IN DATE
  ,p_created_by                IN NUMBER
  ,p_last_update_login         IN NUMBER
  ,p_request_id                IN NUMBER
  ,p_program_application_id    IN NUMBER
  ,p_program_id                IN NUMBER
  ,p_program_update_date       IN DATE
  ,p_wh_update_date            IN DATE );
  */


  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : UPD_FILE_NAMING_SEQ_DTLS                                    |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | 	This procedure shall UPDATE file naming sequence details into the        |
  -- |  table XX_CDH_EBL_MAIN.                                                   |
  -- |                                                                           |
  -- |                                                                           |
  -- | Parameters  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | Returns     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

PROCEDURE upd_file_naming_seq_dtls (
    p_cust_doc_id          IN  NUMBER,
    p_file_next_seq_number IN  NUMBER,
    p_file_seq_reset_date  IN  DATE,
    x_error_message        OUT VARCHAR2
    );

END XX_CDH_EBL_MAIN_PKG ;
/
SHOW ERRORS;