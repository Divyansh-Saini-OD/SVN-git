SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 

CREATE OR REPLACE PACKAGE XX_CDH_EBL_FILE_NAME_DTL_PKG AUTHID CURRENT_USER

  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XX_CDH_EBL_FILE_NAME_DTL_PKG                                |
  -- | Description :                                                             |
  -- | This package provides table handlers for the table			 |
  -- | XX_CDH_EBL_FILE_NAME_DTL.						 |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author        Remarks				 |
  -- |======== =========== ============= ========================================|
  -- |DRAFT 1A 25-FEB-2010 Mangala       Initial draft version                   |
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
  -- | This procedure inserts data into the table  XX_CDH_EBL_FILE_NAME_DTL.     |
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
    p_ebl_file_name_id       IN NUMBER,
    p_cust_doc_id            IN NUMBER ,
    p_file_name_order_seq    IN NUMBER ,
    p_field_id               IN NUMBER ,
    p_constant_value         IN VARCHAR2,
    p_default_if_null        IN VARCHAR2,
    p_comments               IN VARCHAR2,
    p_attribute1             IN VARCHAR2 DEFAULT NULL,
    p_attribute2             IN VARCHAR2 DEFAULT NULL,
    p_attribute3             IN VARCHAR2 DEFAULT NULL,
    p_attribute4             IN VARCHAR2 DEFAULT NULL,
    p_attribute5             IN VARCHAR2 DEFAULT NULL,
    p_attribute6             IN VARCHAR2 DEFAULT NULL,
    p_attribute7             IN VARCHAR2 DEFAULT NULL,
    p_attribute8             IN VARCHAR2 DEFAULT NULL,
    p_attribute9             IN VARCHAR2 DEFAULT NULL,
    p_attribute10            IN VARCHAR2 DEFAULT NULL,
    p_attribute11            IN VARCHAR2 DEFAULT NULL,
    p_attribute12            IN VARCHAR2 DEFAULT NULL,
    p_attribute13            IN VARCHAR2 DEFAULT NULL,
    p_attribute14            IN VARCHAR2 DEFAULT NULL,
    p_attribute15            IN VARCHAR2 DEFAULT NULL,
    p_attribute16            IN VARCHAR2 DEFAULT NULL,
    p_attribute17            IN VARCHAR2 DEFAULT NULL,
    p_attribute18            IN VARCHAR2 DEFAULT NULL,
    p_attribute19            IN VARCHAR2 DEFAULT NULL,
    p_attribute20            IN VARCHAR2 DEFAULT NULL,
    p_last_update_date       IN DATE DEFAULT SYSDATE,
    p_last_updated_by        IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_creation_date          IN DATE DEFAULT SYSDATE,
    p_created_by             IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_last_update_login      IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_request_id             IN NUMBER DEFAULT NULL ,
    p_program_application_id IN NUMBER DEFAULT NULL ,
    p_program_id             IN NUMBER DEFAULT NULL ,
    p_program_update_date    IN DATE DEFAULT NULL ,
    p_wh_update_date         IN DATE DEFAULT NULL );
    
  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : UPDATE_ROW                                                  |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | This procedure shall update data into the table XX_CDH_EBL_FILE_NAME_DTL. |
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
    p_ebl_file_name_id       IN NUMBER,
    p_cust_doc_id            IN NUMBER ,
    p_file_name_order_seq    IN NUMBER ,
    p_field_id               IN NUMBER ,
    p_constant_value         IN VARCHAR2,
    p_default_if_null        IN VARCHAR2,
    p_comments               IN VARCHAR2,
    p_attribute1             IN VARCHAR2 DEFAULT NULL,
    p_attribute2             IN VARCHAR2 DEFAULT NULL,
    p_attribute3             IN VARCHAR2 DEFAULT NULL,
    p_attribute4             IN VARCHAR2 DEFAULT NULL,
    p_attribute5             IN VARCHAR2 DEFAULT NULL,
    p_attribute6             IN VARCHAR2 DEFAULT NULL,
    p_attribute7             IN VARCHAR2 DEFAULT NULL,
    p_attribute8             IN VARCHAR2 DEFAULT NULL,
    p_attribute9             IN VARCHAR2 DEFAULT NULL,
    p_attribute10            IN VARCHAR2 DEFAULT NULL,
    p_attribute11            IN VARCHAR2 DEFAULT NULL,
    p_attribute12            IN VARCHAR2 DEFAULT NULL,
    p_attribute13            IN VARCHAR2 DEFAULT NULL,
    p_attribute14            IN VARCHAR2 DEFAULT NULL,
    p_attribute15            IN VARCHAR2 DEFAULT NULL,
    p_attribute16            IN VARCHAR2 DEFAULT NULL,
    p_attribute17            IN VARCHAR2 DEFAULT NULL,
    p_attribute18            IN VARCHAR2 DEFAULT NULL,
    p_attribute19            IN VARCHAR2 DEFAULT NULL,
    p_attribute20            IN VARCHAR2 DEFAULT NULL,
    p_last_update_date       IN DATE DEFAULT SYSDATE,
    p_last_updated_by        IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_last_update_login      IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_request_id             IN NUMBER DEFAULT NULL ,
    p_program_application_id IN NUMBER DEFAULT NULL,
    p_program_id             IN NUMBER DEFAULT NULL,
    p_program_update_date    IN DATE DEFAULT NULL,
    p_wh_update_date         IN DATE DEFAULT NULL );

  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : DELETE_ROW                                                  |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | This procedure shall delete data  in XX_CDH_EBL_FILE_NAME_DTL.		 |
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
    p_ebl_file_name_id IN NUMBER,
    p_cust_doc_id      IN NUMBER );

  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : LOCK_ROW                                                    |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | This procedure shall lock rows into  the table XX_CDH_EBL_FILE_NAME_DTL.	 |
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
  p_ebl_file_name_id       IN NUMBER,
  p_cust_doc_id            IN NUMBER ,
  p_file_name_order_seq    IN NUMBER ,
  p_field_id               IN NUMBER ,
  p_constant_value         IN VARCHAR2,
  p_default_if_null        IN VARCHAR2,
  p_comments               IN VARCHAR2,
  p_attribute1             IN VARCHAR2,
  p_attribute2             IN VARCHAR2,
  p_attribute3             IN VARCHAR2,
  p_attribute4             IN VARCHAR2,
  p_attribute5             IN VARCHAR2,
  p_attribute6             IN VARCHAR2,
  p_attribute7             IN VARCHAR2,
  p_attribute8             IN VARCHAR2,
  p_attribute9             IN VARCHAR2,
  p_attribute10            IN VARCHAR2,
  p_attribute11            IN VARCHAR2,
  p_attribute12            IN VARCHAR2,
  p_attribute13            IN VARCHAR2,
  p_attribute14            IN VARCHAR2,
  p_attribute15            IN VARCHAR2,
  p_attribute16            IN VARCHAR2,
  p_attribute17            IN VARCHAR2,
  p_attribute18            IN VARCHAR2,
  p_attribute19            IN VARCHAR2,
  p_attribute20            IN VARCHAR2,
  p_last_update_date       IN DATE ,
  p_last_updated_by        IN NUMBER,
  p_creation_date          IN DATE ,
  p_created_by             IN NUMBER ,
  p_last_update_login      IN NUMBER ,
  p_request_id             IN NUMBER ,
  p_program_application_id IN NUMBER ,
  p_program_id             IN NUMBER ,
  p_program_update_date    IN DATE ,
  p_wh_update_date         IN DATE ); 
  */

END XX_CDH_EBL_FILE_NAME_DTL_PKG ;
/

SHOW ERRORS;
