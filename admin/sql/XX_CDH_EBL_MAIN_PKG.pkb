SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;

WHENEVER SQLERROR CONTINUE;

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_CDH_EBL_MAIN_PKG

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
  -- |1.0      31-MAR-2016 Havish K       MOD4B Rel 4 Changes                    |
  -- |2.0      25-MAR-2017 Bhagwan G      Changed for Defects#38962 and 2302     |
  -- |3.0      29-May-2018 Reddy Sekhar K Changed for Defect# NAIT-27146         |
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
    p_wh_update_date            IN DATE DEFAULT NULL,
	p_delimiter_char            IN VARCHAR2 DEFAULT NULL, -- Added for MOD4B Rel 4 Changes
	p_file_creation_type        IN VARCHAR2 DEFAULT NULL, -- Added for MOD4B Rel 4 Changes
    p_summary_bill              IN VARCHAR2 DEFAULT NULL,
    p_nondt_qty                 IN NUMBER DEFAULT NULL,
    p_parent_doc_id             IN NUMBER DEFAULT NULL --Added by Reddy Sekhar K for the defect # NAIT-27146 on 29-May-2018	
  )
IS


BEGIN 
  INSERT
  INTO xx_cdh_ebl_main
    (
      cust_doc_id ,
      cust_account_id ,
      ebill_transmission_type ,
      ebill_associate ,
      file_processing_method ,
      file_name_ext,
      max_file_size ,
      max_transmission_size ,
      zip_required ,
      zipping_utility ,
      zip_file_name_ext ,
      od_field_contact ,
      od_field_contact_email ,
      od_field_contact_phone ,
      client_tech_contact ,
      client_tech_contact_email ,
      client_tech_contact_phone ,
      file_name_seq_reset ,
      file_next_seq_number ,
      file_seq_reset_date ,
      file_name_max_seq_number ,
      attribute1 ,
      attribute2 ,
      attribute3 ,
      attribute4 ,
      attribute5 ,
      attribute6 ,
      attribute7 ,
      attribute8 ,
      attribute9 ,
      attribute10 ,
      attribute11 ,
      attribute12 ,
      attribute13 ,
      attribute14 ,
      attribute15 ,
      attribute16 ,
      attribute17 ,
      attribute18 ,
      attribute19 ,
      attribute20 ,
      last_update_date ,
      last_updated_by ,
      creation_date ,
      created_by ,
      last_update_login ,
      request_id ,
      program_application_id ,
      program_id ,
      program_update_date ,
      wh_update_date,
	  delimiter_char,  -- Added for MOD4B Rel 4 Changes
	  file_creation_type,  -- Added for MOD4B Rel 4 Changes
      summary_bill,
      nondt_quantity,
	  parent_doc_id --Added by Reddy Sekhar K for the defect # NAIT-27146 on 29-May-2018
    )
    VALUES
    (
      p_cust_doc_id ,
      p_cust_account_id ,
      nvl(p_ebill_transmission_type,'EMAIL') ,
      p_ebill_associate ,
      p_file_processing_method ,
      p_file_name_ext,
      p_max_file_size ,
      p_max_transmission_size ,
      nvl(p_zip_required, 'N') ,
      p_zipping_utility ,
      p_zip_file_name_ext ,
      p_od_field_contact ,
      p_od_field_contact_email ,
      p_od_field_contact_phone ,
      p_client_tech_contact ,
      p_client_tech_contact_email ,
      p_client_tech_contact_phone ,
      p_file_name_seq_reset ,
      p_file_next_seq_number ,
      p_file_seq_reset_date ,
      p_file_name_max_seq_number ,
      p_attribute1 ,
      p_attribute2 ,
      p_attribute3 ,
      p_attribute4 ,
      p_attribute5 ,
      p_attribute6 ,
      p_attribute7 ,
      p_attribute8 ,
      p_attribute9 ,
      p_attribute10 ,
      p_attribute11 ,
      p_attribute12 ,
      p_attribute13 ,
      p_attribute14 ,
      p_attribute15 ,
      p_attribute16 ,
      p_attribute17 ,
      p_attribute18 ,
      p_attribute19 ,
      p_attribute20 ,
      p_last_update_date ,
      p_last_updated_by ,
      SYSDATE ,
      p_created_by ,
      p_last_update_login ,
      NULL ,
      NULL ,
      NULL ,
      NULL ,
      NULL ,
	  p_delimiter_char,  -- Added for MOD4B Rel 4 Changes
	  p_file_creation_type,  -- Added for MOD4B Rel 4 Changes
      p_summary_bill,
      p_nondt_qty,
      p_parent_doc_id	--Added by Reddy Sekhar K for the defect # NAIT-27146 on 29-May-2018 	  
    );

END insert_row;

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

PROCEDURE update_row
  (
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
    p_wh_update_date            IN DATE DEFAULT NULL ,
	p_delimiter_char            IN VARCHAR2 DEFAULT NULL,  -- Added for MOD4B Rel 4 Changes
	p_file_creation_type        IN VARCHAR2 DEFAULT NULL,   -- Added for MOD4B Rel 4 Changes
    p_summary_bill              IN VARCHAR2 DEFAULT NULL,
    p_nondt_qty                 IN NUMBER DEFAULT NULL,
	p_parent_doc_id             IN NUMBER DEFAULT NULL  --Added by Reddy Sekhar K for the defect # NAIT-27146 on 29-May-2018
  )
IS
BEGIN

  UPDATE xx_cdh_ebl_main
  SET ebill_transmission_type = p_ebill_transmission_type ,
    ebill_associate           = p_ebill_associate ,
    file_processing_method    = p_file_processing_method ,
    file_name_ext             = p_file_name_ext ,
    max_file_size             = p_max_file_size ,
    max_transmission_size     = p_max_transmission_size ,
    zip_required              = p_zip_required ,
    zipping_utility           = p_zipping_utility ,
    zip_file_name_ext         = p_zip_file_name_ext ,
    od_field_contact          = p_od_field_contact ,
    od_field_contact_email    =p_od_field_contact_email ,
    od_field_contact_phone    =p_od_field_contact_phone ,
    client_tech_contact       = p_client_tech_contact ,
    client_tech_contact_email = p_client_tech_contact_email ,
    client_tech_contact_phone = p_client_tech_contact_phone ,
    file_name_seq_reset       = p_file_name_seq_reset ,
    file_next_seq_number      =p_file_next_seq_number ,
    file_seq_reset_date       =p_file_seq_reset_date ,
    file_name_max_seq_number  =p_file_name_max_seq_number ,
    attribute1                =p_attribute1 ,
    attribute2                =p_attribute2 ,
    attribute3                =p_attribute3 ,
    attribute4                =p_attribute4 ,
    attribute5                =p_attribute5 ,
    attribute6                =p_attribute6 ,
    attribute7                =p_attribute7 ,
    attribute8                =p_attribute8 ,
    attribute9                =p_attribute9 ,
    attribute10               =p_attribute10 ,
    attribute11               =p_attribute11 ,
    attribute12               =p_attribute12 ,
    attribute13               =p_attribute13 ,
    attribute14               =p_attribute14 ,
    attribute15               =p_attribute15 ,
    attribute16               =p_attribute16 ,
    attribute17               =p_attribute17 ,
    attribute18               =p_attribute18 ,
    attribute19               =p_attribute19 ,
    attribute20               =p_attribute20 ,
    last_update_date          = p_last_update_date ,
    last_updated_by           =p_last_updated_by ,
    last_update_login         = p_last_update_login ,
    request_id                = p_request_id ,
    program_application_id    =p_program_application_id ,
    program_id                = p_program_id ,
    program_update_date       = p_program_update_date ,
    wh_update_date            =p_wh_update_date,
	delimiter_char            = p_delimiter_char,  -- Added for MOD4B Rel 4 Changes
	file_creation_type        = p_file_creation_type,  -- Added for MOD4B Rel 4 Changes
    summary_bill              = p_summary_bill,
    nondt_quantity            = p_nondt_qty,
	parent_doc_id             = p_parent_doc_id	--Added by Reddy Sekhar K for the defect # NAIT-27146 on 29-May-2018 
  WHERE cust_doc_id           = p_cust_doc_id;
  IF (sql%notfound) THEN
    RAISE no_data_found;
  END IF;

EXCEPTION
   WHEN OTHERS THEN
      raise ;

END update_row;

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
    p_cust_doc_id IN NUMBER )
IS
BEGIN
  DELETE FROM xx_cdh_ebl_main WHERE cust_doc_id = p_cust_doc_id ;

  IF (sql%notfound) THEN
    RAISE no_data_found;
  END IF;

EXCEPTION
   WHEN OTHERS THEN
      raise ;

END delete_row;

-- +==========================================================================+
-- |                                                                           |
-- | Name        : LOCK_ROW                                                    |
-- |                                                                           |
-- | Description :                                                             |
-- |  This procedure shall lock rows into  the table XX_CDH_EBL_MAIN.          |
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
,p_wh_update_date            IN DATE )
IS
BEGIN
*/

-- +===========================================================================+
-- |                                                                           |
-- | Name        : UPD_FILE_NAMING_SEQ_DTLS                                    |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall UPDATE file naming sequence details into the         |
-- |  table XX_CDH_EBL_MAIN.                                                   |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- +===========================================================================+
-- | Stub                                                                      |
-- |---------------------------------------------------------------------------|
-- |                                                                           |
-- |DECLARE
-- |
-- |  lc_insert_fun_status       VARCHAR2(4000);
-- |BEGIN
-- |
-- |             XX_CDH_EBL_MAIN_PKG.upd_file_naming_seq_dtls(
-- |                445371         -- p_cust_doc_id
-- |              , 5              -- p_file_next_seq_number
-- |              , trunc(sysdate) -- p_file_seq_reset_date
-- |              , lc_insert_fun_status -- x_error_message
-- |            );
-- |
-- |   DBMS_OUTPUT.PUT_LINE ('Return Status: ' || lc_insert_fun_status);
-- |   DBMS_OUTPUT.PUT_LINE ('No Errors');
-- |
-- |EXCEPTION
-- |   WHEN OTHERS THEN
-- |      DBMS_OUTPUT.PUT_LINE ('SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000));
-- |
-- |END;
-- |
-- |select file_next_seq_number, file_seq_reset_date, eblm.* from XX_CDH_EBL_MAIN eblm
-- |WHERE  CUST_DOC_ID = :document_id;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE upd_file_naming_seq_dtls(
    p_cust_doc_id          IN NUMBER,
    p_file_next_seq_number IN NUMBER,
    p_file_seq_reset_date  IN DATE,
    x_error_message        OUT VARCHAR2 )
IS

BEGIN

  UPDATE xx_cdh_ebl_main
  SET file_next_seq_number = p_file_next_seq_number ,
    file_seq_reset_date    = NVL(p_file_seq_reset_date, file_seq_reset_date)
  WHERE cust_doc_id        = p_cust_doc_id;

  IF (sql%notfound) THEN
    RAISE no_data_found;
  END IF;

  x_error_message := 'UPDATED';

EXCEPTION

   WHEN NO_DATA_FOUND THEN
      x_error_message := 'ERROR - Invalid Customer Document Id, please verify it and update the record again.';

   WHEN OTHERS THEN
      x_error_message := 'ERROR - Exception occurred in XX_CDH_EBL_MAIN_PKG.UPD_FILE_NAMING_SEQ_DTLS. ' ||' SQLCODE - ' || SQLCODE || ', SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000);
END upd_file_naming_seq_dtls;

END XX_CDH_EBL_MAIN_PKG ;
/
SHOW ERRORS;