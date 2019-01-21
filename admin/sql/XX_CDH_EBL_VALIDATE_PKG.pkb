SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;

WHENEVER SQLERROR CONTINUE;

WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_cdh_ebl_validate_pkg
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_VALIDATE_PKG                                     |
-- | Description :                                                             |
-- | This package will validate entire data before inserting data into tables. |
-- | And also all the validation functions are exceuted one final time before  |
-- | changing the document status, to make sure that the date is Valid.        |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 25-FEB-2010 Srini Ch      Initial draft version                   |
-- |1.1      23-Oct-2013 Deepak V      I2186 - Changes done for R12 Upgrade retrofit.|
-- |2.0      22-OCT-2015 Manikant Kasu  Removed schema alias as part of GSCC   |
-- |                                    R12.2.2 Retrofit                       |
-- |3.0      8-Jan-2016 Sridevi K      I2186 - For MOD 4B R3                   |
-- |3.1      27-Jan-2016 Sridevi K     I2186 - For MOD 4B R3 -Defect2009       |
-- +===========================================================================+
AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_EBL_MAIN                                           |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function will be used to validate date before inserting into         |
-- | XX_CDH_EBL_MAIN table and also validate date before changing              |
-- | the document status from "IN PROCESS" to "TESTING" (or) from "TESTING"    |
-- | to "COMPLETE".                                                            |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |         lc_insert_fun_status :=
-- |             XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_MAIN(
-- |                p_cust_doc_id
-- |              , p_cust_account_id
-- |              , lcu_get_eBill_main.ebill_transmission_type
-- |              , lcu_get_eBill_main.ebill_associate
-- |              , lcu_get_eBill_main.file_processing_method
-- |              , lcu_get_eBill_main.max_file_size
-- |              , lcu_get_eBill_main.max_transmission_size
-- |              , lcu_get_eBill_main.zip_required
-- |              , lcu_get_eBill_main.zipping_utility
-- |              , lcu_get_eBill_main.zip_file_name_ext
-- |              , lcu_get_eBill_main.od_field_contact
-- |              , lcu_get_eBill_main.od_field_contact_email
-- |              , lcu_get_eBill_main.od_field_contact_phone
-- |              , lcu_get_eBill_main.client_tech_contact
-- |              , lcu_get_eBill_main.client_tech_contact_email
-- |              , lcu_get_eBill_main.client_tech_contact_phone
-- |              , Null -- lcu_get_eBill_main.attribute1
-- |              , Null -- lcu_get_eBill_main.attribute2
-- |              , Null -- lcu_get_eBill_main.attribute3
-- |              , Null -- lcu_get_eBill_main.attribute4
-- |              , Null -- lcu_get_eBill_main.attribute5
-- |              , Null -- lcu_get_eBill_main.attribute6
-- |              , Null -- lcu_get_eBill_main.attribute7
-- |              , Null -- lcu_get_eBill_main.attribute8
-- |              , Null -- lcu_get_eBill_main.attribute9
-- |              , Null -- lcu_get_eBill_main.attribute10
-- |              , Null -- lcu_get_eBill_main.attribute11
-- |              , Null -- lcu_get_eBill_main.attribute12
-- |              , Null -- lcu_get_eBill_main.attribute13
-- |              , Null -- lcu_get_eBill_main.attribute14
-- |              , Null -- lcu_get_eBill_main.attribute15
-- |              , Null -- lcu_get_eBill_main.attribute16
-- |              , Null -- lcu_get_eBill_main.attribute17
-- |              , Null -- lcu_get_eBill_main.attribute18
-- |              , Null -- lcu_get_eBill_main.attribute19
-- |              , Null -- lcu_get_eBill_main.attribute20
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
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = :document_id;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   gc_insert_fun_status           VARCHAR2 (4000) := '';
   gc_return_status               VARCHAR2 (4000) := '';
   gc_error_code                  VARCHAR2 (20)   := '';
   gc_error_message               VARCHAR2 (4000) := '';
   gc_validation_status           VARCHAR2 (5)    := 'TRUE';
   gc_doc_process_date   CONSTANT DATE            := SYSDATE;
   gex_error_table_error          EXCEPTION;

----------------------------------------------------------------------------
-- Private PROCEDURES and FUNCTIONS.
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Public PROCEDURES and FUNCTIONS.
----------------------------------------------------------------------------
   FUNCTION validate_ebl_main (
      p_cust_doc_id                 IN   NUMBER,
      p_cust_account_id             IN   NUMBER,
      p_ebill_transmission_type     IN   VARCHAR2,
      p_ebill_associate             IN   VARCHAR2,
      p_file_processing_method      IN   VARCHAR2,
      p_file_name_ext               IN   VARCHAR2,
      p_max_file_size               IN   NUMBER,
      p_max_transmission_size       IN   NUMBER,
      p_zip_required                IN   VARCHAR2,
      p_zipping_utility             IN   VARCHAR2,
      p_zip_file_name_ext           IN   VARCHAR2,
      p_od_field_contact            IN   VARCHAR2,
      p_od_field_contact_email      IN   VARCHAR2,
      p_od_field_contact_phone      IN   VARCHAR2,
      p_client_tech_contact         IN   VARCHAR2,
      p_client_tech_contact_email   IN   VARCHAR2,
      p_client_tech_contact_phone   IN   VARCHAR2,
      p_file_name_seq_reset         IN   VARCHAR2,
      p_file_next_seq_number        IN   NUMBER,
      p_file_seq_reset_date         IN   DATE,
      p_file_name_max_seq_number    IN   NUMBER,
      p_attribute1                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute2                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute3                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute4                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute5                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute6                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute7                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute8                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute9                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute10                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute11                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute12                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute13                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute14                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute15                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute16                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute17                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute18                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute19                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute20                 IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      lc_delivery_method   VARCHAR2 (150);
      lc_is_parent         VARCHAR2 (3);
      lc_direct_flag       VARCHAR2 (3);
   BEGIN
----------------------------------------------------------------------------
-- Begining of VALIDATE_EBL_MAIN package body.
----------------------------------------------------------------------------
      gc_return_status := 'TRUE';
----------------------------------------------------------------------------
-- To get the Delivery Method for a given document.
----------------------------------------------------------------------------
      gc_error_code := 'SELECT1';

      SELECT c_ext_attr3, CASE n_ext_attr17
                WHEN 1
                   THEN 'Yes'
                ELSE 'No'
             END,
             c_ext_attr7 direct_flag
        INTO lc_delivery_method, lc_is_parent,
             lc_direct_flag
        FROM xx_cdh_cust_acct_ext_b
       WHERE cust_account_id = p_cust_account_id
         AND n_ext_attr2 = p_cust_doc_id
         AND attr_group_id =
                (SELECT attr_group_id
                   FROM ego_attr_groups_v
                  WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
                    AND attr_group_name = 'BILLDOCS');                  -- 166

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_038'
-- ERROR_MESSAGE = ''
--
----------------------------------------------------------------------------
      gc_error_code := 'XXOD_EBL_038';

      IF     lc_delivery_method = 'ePDF'
         AND lc_is_parent = 'Yes'
         AND p_file_processing_method <> '03'
      THEN
         gc_error_message := '';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_002' and 'XXOD_EBL_003'
-- ERROR_MESSAGE = ''
-- ERROR_MESSAGE = ''
--
----------------------------------------------------------------------------
      IF lc_delivery_method = 'ePDF' AND p_file_processing_method IS NULL
      THEN
         gc_error_code := 'XXOD_EBL_002';
         gc_error_message := '';
         gc_validation_status := 'FALSE';
      ELSIF     lc_delivery_method IN ('eXLS', 'eTXT')
            AND p_file_processing_method IS NOT NULL
      THEN
         gc_error_code := 'XXOD_EBL_003';
         gc_error_message := '';
         gc_validation_status := 'FALSE';
      END IF;

      IF gc_validation_status = 'FALSE'
      THEN
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';
         gc_validation_status := 'TRUE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_004' and 'XXOD_EBL_005'
-- ERROR_MESSAGE = ''
-- ERROR_MESSAGE = ''
--
----------------------------------------------------------------------------
      IF p_zip_required = 'Y' AND p_zip_file_name_ext IS NULL
      THEN
         gc_error_code := 'XXOD_EBL_004';
         gc_error_message := '';
         gc_validation_status := 'FALSE';
      ELSIF p_zip_required = 'N' AND p_zip_file_name_ext IS NOT NULL
      THEN
         gc_error_code := 'XXOD_EBL_005';
         gc_error_message := '';
         gc_validation_status := 'FALSE';
      END IF;

      IF gc_validation_status = 'FALSE'
      THEN
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';
         gc_validation_status := 'TRUE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_080'.
-- ERROR_MESSAGE = ''
-- Compression Utility column should be null for Indirect Document.
--
----------------------------------------------------------------------------
      gc_error_code := 'XXOD_EBL_080';

      IF lc_direct_flag = 'N' AND p_zip_required = 'Y'
      THEN
         gc_error_message := '';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

      RETURN gc_return_status;
----------------------------------------------------------------------------
-- VALIDATE_EBL_MAIN - Exception Block starts.
----------------------------------------------------------------------------
   EXCEPTION
      WHEN gex_error_table_error
      THEN
         gc_error_message :=
               'Customer Document Id: '
            || p_cust_doc_id
            || ' and Exception occurred in VALIDATE_EBL_MAIN.';
         gc_return_status :=
               'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
            || gc_error_message
            || ' - '
            || gc_error_code
            || ' - '
            || fnd_message.get_string ('XXCRM', gc_error_code);
         RETURN gc_return_status;
      WHEN OTHERS
      THEN
-------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_001'
-- ERROR_MESSAGE = ''
--
-------------------------------------------------------------------------
         gc_error_message :=
               'Exception occurred in VALIDATE_EBL_MAIN. While processing/validating '
            || gc_error_code
            || '. SQLCODE - '
            || SQLCODE
            || ' SQLERRM - '
            || SUBSTR (SQLERRM, 1, 3000);
         gc_error_code := 'XXOD_EBL_001';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );

         IF gc_insert_fun_status = 'FALSE'
         THEN
            gc_return_status :=
                  'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
               || gc_error_code
               || ' - '
               || gc_error_message
               || ' - '
               || fnd_message.get_string ('XXCRM', gc_error_code);
         ELSE
            gc_return_status := 'FALSE - EBL-001';
         END IF;

         gc_error_message := '';
         RETURN gc_return_status;
   END validate_ebl_main;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_EBL_TRANSMISSION                                   |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function will be used to validate date before inserting into         |
-- | XX_CDH_EBL_TRANSMISSION_DTL table and also validate date before changing  |
-- | the document status from "IN PROCESS" to "TESTING" (or) from "TESTING"    |
-- | to "COMPLETE".                                                            |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |         lc_insert_fun_status :=
-- |             XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_TRANSMISSION (
-- |                p_cust_doc_id
-- |              , lcu_get_eBill_trans.email_subject
-- |              , lcu_get_eBill_trans.email_std_message
-- |              , lcu_get_eBill_trans.email_custom_message
-- |              , lcu_get_eBill_trans.email_std_disclaimer
-- |              , lcu_get_eBill_trans.email_signature
-- |              , lcu_get_eBill_trans.email_logo_required
-- |              , lcu_get_eBill_trans.email_logo_file_name
-- |              , lcu_get_eBill_trans.ftp_direction
-- |              , lcu_get_eBill_trans.ftp_transfer_type
-- |              , lcu_get_eBill_trans.ftp_destination_site
-- |              , lcu_get_eBill_trans.ftp_destination_folder
-- |              , lcu_get_eBill_trans.ftp_user_name
-- |              , lcu_get_eBill_trans.ftp_password
-- |              , lcu_get_eBill_trans.ftp_pickup_server
-- |              , lcu_get_eBill_trans.ftp_pickup_folder
-- |              , lcu_get_eBill_trans.ftp_cust_contact_name
-- |              , lcu_get_eBill_trans.ftp_cust_contact_email
-- |              , lcu_get_eBill_trans.ftp_cust_contact_phone
-- |              , lcu_get_eBill_trans.ftp_notify_customer
-- |              , lcu_get_eBill_trans.ftp_cc_emails
-- |              , lcu_get_eBill_trans.ftp_email_sub
-- |              , lcu_get_eBill_trans.ftp_email_content
-- |              , lcu_get_eBill_trans.ftp_send_zero_byte_file
-- |              , lcu_get_eBill_trans.ftp_zero_byte_file_text
-- |              , lcu_get_eBill_trans.FTP_ZERO_BYTE_NOTIFICATION_TXT
-- |              , lcu_get_eBill_trans.cd_file_location
-- |              , lcu_get_eBill_trans.cd_send_to_address
-- |              , lcu_get_eBill_trans.comments
-- |              , NULL -- lcu_get_eBill_trans.attribute1
-- |              , NULL -- lcu_get_eBill_trans.attribute2
-- |              , NULL -- lcu_get_eBill_trans.attribute3
-- |              , NULL -- lcu_get_eBill_trans.attribute4
-- |              , NULL -- lcu_get_eBill_trans.attribute5
-- |              , NULL -- lcu_get_eBill_trans.attribute6
-- |              , NULL -- lcu_get_eBill_trans.attribute7
-- |              , NULL -- lcu_get_eBill_trans.attribute8
-- |              , NULL -- lcu_get_eBill_trans.attribute9
-- |              , NULL -- lcu_get_eBill_trans.attribute10
-- |              , NULL -- lcu_get_eBill_trans.attribute11
-- |              , NULL -- lcu_get_eBill_trans.attribute12
-- |              , NULL -- lcu_get_eBill_trans.attribute13
-- |              , NULL -- lcu_get_eBill_trans.attribute14
-- |              , NULL -- lcu_get_eBill_trans.attribute15
-- |              , NULL -- lcu_get_eBill_trans.attribute16
-- |              , NULL -- lcu_get_eBill_trans.attribute17
-- |              , NULL -- lcu_get_eBill_trans.attribute18
-- |              , NULL -- lcu_get_eBill_trans.attribute19
-- |              , NULL -- lcu_get_eBill_trans.attribute20
-- |            );
-- |
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
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = :document_id;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   FUNCTION validate_ebl_transmission (
      p_cust_doc_id               IN   NUMBER,
      p_transmission_type         IN   VARCHAR2,
      p_email_subject             IN   VARCHAR2,
      p_email_std_message         IN   VARCHAR2,
      p_email_custom_message      IN   VARCHAR2,
      p_email_std_disclaimer      IN   VARCHAR2,
      p_email_signature           IN   VARCHAR2,
      p_email_logo_required       IN   VARCHAR2,
      p_email_logo_file_name      IN   VARCHAR2,
      p_ftp_direction             IN   VARCHAR2,
      p_ftp_transfer_type         IN   VARCHAR2,
      p_ftp_destination_site      IN   VARCHAR2,
      p_ftp_destination_folder    IN   VARCHAR2,
      p_ftp_user_name             IN   VARCHAR2,
      p_ftp_password              IN   VARCHAR2,
      p_ftp_pickup_server         IN   VARCHAR2,
      p_ftp_pickup_folder         IN   VARCHAR2,
      p_ftp_cust_contact_name     IN   VARCHAR2,
      p_ftp_cust_contact_email    IN   VARCHAR2,
      p_ftp_cust_contact_phone    IN   VARCHAR2,
      p_ftp_notify_customer       IN   VARCHAR2,
      p_ftp_cc_emails             IN   VARCHAR2,
      p_ftp_email_sub             IN   VARCHAR2,
      p_ftp_email_content         IN   VARCHAR2,
      p_ftp_send_zero_byte_file   IN   VARCHAR2,
      p_ftp_zero_byte_file_text   IN   VARCHAR2,
      p_ftp_zero_byte_notif_txt   IN   VARCHAR2,
      p_cd_file_location          IN   VARCHAR2,
      p_cd_send_to_address        IN   VARCHAR2,
      p_comments                  IN   VARCHAR2,
      p_attribute1                IN   VARCHAR2 DEFAULT NULL,
      p_attribute2                IN   VARCHAR2 DEFAULT NULL,
      p_attribute3                IN   VARCHAR2 DEFAULT NULL,
      p_attribute4                IN   VARCHAR2 DEFAULT NULL,
      p_attribute5                IN   VARCHAR2 DEFAULT NULL,
      p_attribute6                IN   VARCHAR2 DEFAULT NULL,
      p_attribute7                IN   VARCHAR2 DEFAULT NULL,
      p_attribute8                IN   VARCHAR2 DEFAULT NULL,
      p_attribute9                IN   VARCHAR2 DEFAULT NULL,
      p_attribute10               IN   VARCHAR2 DEFAULT NULL,
      p_attribute11               IN   VARCHAR2 DEFAULT NULL,
      p_attribute12               IN   VARCHAR2 DEFAULT NULL,
      p_attribute13               IN   VARCHAR2 DEFAULT NULL,
      p_attribute14               IN   VARCHAR2 DEFAULT NULL,
      p_attribute15               IN   VARCHAR2 DEFAULT NULL,
      p_attribute16               IN   VARCHAR2 DEFAULT NULL,
      p_attribute17               IN   VARCHAR2 DEFAULT NULL,
      p_attribute18               IN   VARCHAR2 DEFAULT NULL,
      p_attribute19               IN   VARCHAR2 DEFAULT NULL,
      p_attribute20               IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      lc_ebill_transmission_type   xx_cdh_ebl_main.ebill_transmission_type%TYPE;
   BEGIN
----------------------------------------------------------------------------
-- Begining of VALIDATE_EBL_TRANSMISSION package body.
----------------------------------------------------------------------------
      gc_return_status := 'TRUE';
      lc_ebill_transmission_type := p_transmission_type;

      IF lc_ebill_transmission_type = 'EMAIL'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_006'
-- ERROR_MESSAGE = ''
-- Validation when TRANS_TYPE = 'EMAIL'.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_006';

         IF p_email_subject IS NULL OR p_email_std_message IS NULL
         THEN
            --       OR p_email_custom_message IS NULL
            --       OR p_email_std_disclaimer IS NULL
            --       OR p_email_signature IS NULL THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      ELSIF lc_ebill_transmission_type = 'FTP'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_007'
-- ERROR_MESSAGE = ''
-- Validation when TRANS_TYPE = 'FTP'.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_007';

         IF p_ftp_direction IS NULL
         THEN
            --      OR p_ftp_destination_site IS NULL
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      ELSIF lc_ebill_transmission_type = 'CD'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_008'
-- ERROR_MESSAGE = ''
-- Validation when TRANS_TYPE = 'CD'.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_008';

         IF p_cd_send_to_address IS NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      END IF;

      IF gc_validation_status = 'FALSE'
      THEN
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';
         gc_validation_status := 'TRUE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

      IF lc_ebill_transmission_type = 'EMAIL'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_009'
-- ERROR_MESSAGE = ''
-- Validation when TRANS_TYPE = 'EMAIL'.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_009';

         IF    p_ftp_direction IS NOT NULL
            --     OR p_ftp_transfer_type IS NOT NULL
            --     OR p_ftp_destination_site IS NOT NULL
            --     OR p_ftp_destination_folder IS NOT NULL
            --     OR p_ftp_user_name IS NOT NULL
            --     OR p_ftp_password IS NOT NULL
            --     OR p_ftp_pickup_server IS NOT NULL
            --     OR p_ftp_pickup_folder IS NOT NULL
            OR p_ftp_cust_contact_name IS NOT NULL
            OR p_ftp_cust_contact_email IS NOT NULL
            OR p_ftp_cust_contact_phone IS NOT NULL
            OR p_ftp_notify_customer IS NOT NULL
            OR p_ftp_cc_emails IS NOT NULL
            OR p_ftp_email_sub IS NOT NULL
            OR p_ftp_email_content IS NOT NULL
            OR p_ftp_send_zero_byte_file IS NOT NULL
            OR p_ftp_zero_byte_file_text IS NOT NULL
            OR p_ftp_zero_byte_notif_txt IS NOT NULL
         --   OR p_cd_file_location IS NOT NULL
         --   OR p_cd_send_to_address IS NOT NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      ELSIF lc_ebill_transmission_type = 'FTP'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_010'
-- ERROR_MESSAGE = ''
-- Validation when TRANS_TYPE = 'FTP'.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_010';

         IF    p_email_subject IS NOT NULL
            OR p_email_std_message IS NOT NULL
            OR p_email_custom_message IS NOT NULL
            OR p_email_std_disclaimer IS NOT NULL
            OR p_email_signature IS NOT NULL
            OR p_cd_file_location IS NOT NULL
            OR p_cd_send_to_address IS NOT NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      ELSIF lc_ebill_transmission_type = 'CD'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_011'
-- ERROR_MESSAGE = ''
-- Validation when TRANS_TYPE = 'CD'.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_011';

         IF    p_email_subject IS NOT NULL
            OR p_email_std_message IS NOT NULL
            OR p_email_custom_message IS NOT NULL
            OR p_email_std_disclaimer IS NOT NULL
            OR p_email_signature IS NOT NULL
            OR p_ftp_direction IS NOT NULL
            OR p_ftp_transfer_type IS NOT NULL
            OR p_ftp_destination_site IS NOT NULL
            OR p_ftp_destination_folder IS NOT NULL
            OR p_ftp_user_name IS NOT NULL
            OR p_ftp_password IS NOT NULL
            OR p_ftp_pickup_server IS NOT NULL
            OR p_ftp_pickup_folder IS NOT NULL
            OR p_ftp_cust_contact_name IS NOT NULL
            OR p_ftp_cust_contact_email IS NOT NULL
            OR p_ftp_cust_contact_phone IS NOT NULL
            OR p_ftp_notify_customer IS NOT NULL
            OR p_ftp_cc_emails IS NOT NULL
            OR p_ftp_email_sub IS NOT NULL
            OR p_ftp_email_content IS NOT NULL
            OR p_ftp_send_zero_byte_file IS NOT NULL
            OR p_ftp_zero_byte_file_text IS NOT NULL
            OR p_ftp_zero_byte_notif_txt IS NOT NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      END IF;

      IF gc_validation_status = 'FALSE'
      THEN
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';
         gc_validation_status := 'TRUE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_012' and 'XXOD_EBL_013'
-- ERROR_MESSAGE = ''
-- ERROR_MESSAGE = ''
-- Validation when TRANS_TYPE = 'FTP' and Notify is "YES".
--
----------------------------------------------------------------------------
      IF p_ftp_notify_customer = 'Y' AND lc_ebill_transmission_type = 'FTP'
      THEN
         gc_error_code := 'XXOD_EBL_012';

         IF    p_ftp_cust_contact_name IS NULL
            OR p_ftp_cust_contact_email IS NULL
            OR p_ftp_email_sub IS NULL
            OR p_ftp_email_content IS NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      ELSIF p_ftp_notify_customer = 'N' AND lc_ebill_transmission_type = 'FTP'
      THEN
         gc_error_code := 'XXOD_EBL_013';

         IF    p_ftp_cust_contact_name IS NOT NULL
            OR p_ftp_cust_contact_email IS NOT NULL
            OR p_ftp_email_sub IS NOT NULL
            OR p_ftp_email_content IS NOT NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      END IF;

      IF gc_validation_status = 'FALSE'
      THEN
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';
         gc_validation_status := 'TRUE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_014' and 'XXOD_EBL_015'
-- ERROR_MESSAGE = ''
-- ERROR_MESSAGE = ''
-- Validation when TRANS_TYPE = 'FTP', and Send Zero Byte File is "Yes".
--
----------------------------------------------------------------------------
      IF p_ftp_send_zero_byte_file = 'Y'
         AND lc_ebill_transmission_type = 'FTP'
      THEN
         gc_error_code := 'XXOD_EBL_014';

         IF    p_ftp_zero_byte_file_text IS NULL
            OR p_ftp_zero_byte_notif_txt IS NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      ELSIF     p_ftp_send_zero_byte_file = 'N'
            AND lc_ebill_transmission_type = 'FTP'
      THEN
         gc_error_code := 'XXOD_EBL_015';

         IF    p_ftp_zero_byte_file_text IS NOT NULL
            OR p_ftp_zero_byte_notif_txt IS NOT NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      END IF;

      IF gc_validation_status = 'FALSE'
      THEN
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';
         gc_validation_status := 'TRUE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

      RETURN gc_return_status;
----------------------------------------------------------------------------
-- VALIDATE_EBL_TRANSMISSION - Exception Block starts.
----------------------------------------------------------------------------
   EXCEPTION
      WHEN gex_error_table_error
      THEN
         gc_error_message :=
               'Customer Document Id: '
            || p_cust_doc_id
            || ' and Exception occurred in VALIDATE_EBL_TRANSMISSION.';
         gc_return_status :=
               'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
            || gc_error_message
            || ' - '
            || gc_error_code
            || ' - '
            || fnd_message.get_string ('XXCRM', gc_error_code);
         RETURN gc_return_status;
      WHEN OTHERS
      THEN
-------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_001'
-- ERROR_MESSAGE = ''
--
-------------------------------------------------------------------------
         gc_error_message :=
               'Exception occurred in VALIDATE_EBL_TRANSMISSION. While processing/validating '
            || gc_error_code
            || '. SQLCODE - '
            || SQLCODE
            || ' SQLERRM - '
            || SUBSTR (SQLERRM, 1, 3000);
         gc_error_code := 'XXOD_EBL_001';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );

         IF gc_insert_fun_status = 'FALSE'
         THEN
            gc_return_status :=
                  'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
               || gc_error_code
               || ' - '
               || gc_error_message
               || ' - '
               || fnd_message.get_string ('XXCRM', gc_error_code);
         ELSE
            gc_return_status := 'FALSE - EBL-001';
         END IF;

         gc_error_message := '';
         RETURN gc_return_status;
   END validate_ebl_transmission;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_EBL_CONTACTS                                       |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function will be used to validate date before inserting into         |
-- | XX_CDH_EBL_CONTACTS table and also validate date before changing          |
-- | the document status from "IN PROCESS" to "TESTING" (or) from "TESTING"    |
-- | to "COMPLETE".                                                            |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |         lc_insert_fun_status :=
-- |             XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_CONTACTS(
-- |                 lcu_get_doc.C_EXT_ATTR2 -- p_pay_doc_indicator
-- |               , p_cust_account_id
-- |               , lc_ebill_transmission_type -- p_ebill_transmission_type
-- |               , p_cust_doc_id
-- |               , lcu_get_eBill_contact.org_contact_id
-- |               , lcu_get_eBill_contact.cust_acct_site_id
-- |               , NULL -- lcu_get_eBill_contact.attribute1
-- |               , NULL -- lcu_get_eBill_contact.attribute2
-- |               , NULL -- lcu_get_eBill_contact.attribute3
-- |               , NULL -- lcu_get_eBill_contact.attribute4
-- |               , NULL -- lcu_get_eBill_contact.attribute5
-- |               , NULL -- lcu_get_eBill_contact.attribute6
-- |               , NULL -- lcu_get_eBill_contact.attribute7
-- |               , NULL -- lcu_get_eBill_contact.attribute8
-- |               , NULL -- lcu_get_eBill_contact.attribute9
-- |               , NULL -- lcu_get_eBill_contact.attribute10
-- |               , NULL -- lcu_get_eBill_contact.attribute11
-- |               , NULL -- lcu_get_eBill_contact.attribute12
-- |               , NULL -- lcu_get_eBill_contact.attribute13
-- |               , NULL -- lcu_get_eBill_contact.attribute14
-- |               , NULL -- lcu_get_eBill_contact.attribute15
-- |               , NULL -- lcu_get_eBill_contact.attribute16
-- |               , NULL -- lcu_get_eBill_contact.attribute17
-- |               , NULL -- lcu_get_eBill_contact.attribute18
-- |               , NULL -- lcu_get_eBill_contact.attribute19
-- |               , NULL -- lcu_get_eBill_contact.attribute20
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
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = :document_id;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   FUNCTION validate_ebl_contacts (
      p_cust_account_id      IN   xx_cdh_ebl_main.cust_account_id%TYPE,
      p_transmission_type    IN   xx_cdh_ebl_main.ebill_transmission_type%TYPE,
      p_paydoc_ind           IN   VARCHAR2,
      p_ebl_doc_contact_id   IN   NUMBER,
      p_cust_doc_id          IN   NUMBER,
      p_org_contact_id       IN   NUMBER,
      p_cust_acct_site_id    IN   NUMBER,
      p_attribute1           IN   VARCHAR2 DEFAULT NULL,
      p_attribute2           IN   VARCHAR2 DEFAULT NULL,
      p_attribute3           IN   VARCHAR2 DEFAULT NULL,
      p_attribute4           IN   VARCHAR2 DEFAULT NULL,
      p_attribute5           IN   VARCHAR2 DEFAULT NULL,
      p_attribute6           IN   VARCHAR2 DEFAULT NULL,
      p_attribute7           IN   VARCHAR2 DEFAULT NULL,
      p_attribute8           IN   VARCHAR2 DEFAULT NULL,
      p_attribute9           IN   VARCHAR2 DEFAULT NULL,
      p_attribute10          IN   VARCHAR2 DEFAULT NULL,
      p_attribute11          IN   VARCHAR2 DEFAULT NULL,
      p_attribute12          IN   VARCHAR2 DEFAULT NULL,
      p_attribute13          IN   VARCHAR2 DEFAULT NULL,
      p_attribute14          IN   VARCHAR2 DEFAULT NULL,
      p_attribute15          IN   VARCHAR2 DEFAULT NULL,
      p_attribute16          IN   VARCHAR2 DEFAULT NULL,
      p_attribute17          IN   VARCHAR2 DEFAULT NULL,
      p_attribute18          IN   VARCHAR2 DEFAULT NULL,
      p_attribute19          IN   VARCHAR2 DEFAULT NULL,
      p_attribute20          IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      ln_contact_count             NUMBER;
      ln_cust_account_id           xx_cdh_ebl_main.cust_account_id%TYPE;
      lc_billdocs_paydoc_ind       VARCHAR2 (150);
      lc_ebill_transmission_type   xx_cdh_ebl_main.ebill_transmission_type%TYPE;
      lc_site_use_code             hz_cust_site_uses.site_use_code%TYPE;
      l_party_name                 hz_parties.party_name%TYPE;
   BEGIN
----------------------------------------------------------------------------
-- Begining of VALIDATE_EBL_CONTACTS package body.
----------------------------------------------------------------------------
      gc_return_status := 'TRUE';
      ln_cust_account_id := p_cust_account_id;
      lc_ebill_transmission_type := p_transmission_type;
      lc_billdocs_paydoc_ind := p_paydoc_ind;

      IF lc_ebill_transmission_type = 'EMAIL'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_016'
-- ERROR_MESSAGE = ''
-- Contact should have Email Id (OR) Not a valid contact.
--
----------------------------------------------------------------------------
         gc_error_code := 'SELECT3';

         SELECT COUNT (1)
           INTO ln_contact_count
           FROM hz_relationships hr,
                hz_contact_points hcp,
                hz_org_contacts hoc
          WHERE hr.relationship_code = 'CONTACT_OF'
            AND hcp.owner_table_name = 'HZ_PARTIES'
            AND hcp.owner_table_id = hr.party_id
            AND hcp.contact_point_type = 'EMAIL'
            AND hoc.party_relationship_id = hr.relationship_id
            AND hcp.primary_flag = 'Y'
            AND hoc.org_contact_id = p_org_contact_id
            AND hcp.contact_point_purpose = 'BILLING'
            AND hcp.email_address IS NOT NULL;

         gc_error_code := 'XXOD_EBL_016';

         BEGIN
            l_party_name := NULL;

            SELECT hp.party_name
              INTO l_party_name
              FROM hz_org_contacts hoc
                                      --,hz_party_relationships hr Commented for R12upgrade retrofit
            ,
                   hz_relationships hr       -- Added for R12 upgrade retrofit
                                      ,
                   hz_parties hp
             WHERE hoc.org_contact_id = p_org_contact_id
               --AND hoc.party_relationship_id = hr.party_relationship_id Commented for R12 upgrade retrofit
               AND hoc.party_relationship_id = hr.relationship_id
               -- Added for R12upgrade retrofit
               AND hr.subject_id = hp.party_id
               --AND hr.party_relationship_type = 'CONTACT_OF'; Commented for R12 upgrade retrofit
               AND hr.relationship_code = 'CONTACT_OF';
         -- Added for R12upgrade retrofit
         EXCEPTION
            WHEN OTHERS
            THEN
               l_party_name := NULL;
         END;

         IF ln_contact_count = 0
         THEN
            gc_error_message := l_party_name;
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_017'
-- ERROR_MESSAGE = ''
-- Validation on location depending on Pay Document or Info Document.
--
----------------------------------------------------------------------------
      IF lc_billdocs_paydoc_ind = 'Y'
      THEN
         lc_site_use_code := 'BILL_TO';
      ELSE
         lc_site_use_code := 'SHIP_TO';
      END IF;

      gc_error_code := 'SELECT4';

      SELECT COUNT (1)
        INTO ln_contact_count
        FROM hz_cust_acct_sites_all hcas, hz_cust_site_uses_all hcsu
       WHERE hcas.cust_acct_site_id = hcsu.cust_acct_site_id
         AND hcas.status = 'A'
         AND hcas.cust_acct_site_id = NVL (p_cust_acct_site_id, -99999)
         AND hcas.cust_account_id = ln_cust_account_id
         AND hcsu.site_use_code = lc_site_use_code;

      DBMS_OUTPUT.put_line ('ln_contact_count::::: ' || ln_contact_count);
      gc_error_code := 'XXOD_EBL_017';

      IF ln_contact_count = 0 AND p_cust_acct_site_id IS NOT NULL
      THEN
         gc_error_message := 'p_cust_acct_site_id: ' || p_cust_acct_site_id;
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

      /*
      ELSIF lc_billdocs_paydoc_ind = 'N' AND p_cust_acct_site_id IS NULL THEN
      GC_ERROR_CODE        := 'XXOD_EBL_018';
      GC_ERROR_MESSAGE     := '';
      GC_VALIDATION_STATUS := 'FALSE';
      END IF;
      IF GC_VALIDATION_STATUS = 'FALSE' THEN
      GC_INSERT_FUN_STATUS :=
      INSERT_EBL_ERROR(
      p_cust_doc_id
      , GC_DOC_PROCESS_DATE -- p_doc_process_date
      , GC_ERROR_CODE       -- p_error_code
      , GC_ERROR_MESSAGE    -- p_error_desc
      );
      GC_RETURN_STATUS     := 'FALSE';
      GC_VALIDATION_STATUS := 'TRUE';
      IF GC_INSERT_FUN_STATUS = 'FALSE' THEN
      RAISE GEX_ERROR_TABLE_ERROR;
      END IF;
      END IF;
      */
      RETURN gc_return_status;
----------------------------------------------------------------------------
-- VALIDATE_EBL_CONTACTS - Exception Block starts.
----------------------------------------------------------------------------
   EXCEPTION
      WHEN gex_error_table_error
      THEN
         gc_error_message :=
               'Customer Document Id: '
            || p_cust_doc_id
            || ' and Exception occurred in VALIDATE_EBL_CONTACTS';
         gc_return_status :=
               'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
            || gc_error_message
            || ' - '
            || gc_error_code
            || ' - '
            || fnd_message.get_string ('XXCRM', gc_error_code);
         RETURN gc_return_status;
      WHEN OTHERS
      THEN
-------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_001'
-- ERROR_MESSAGE = ''
--
-------------------------------------------------------------------------
         gc_error_message :=
               'Exception occurred in VALIDATE_EBL_CONTACTS. While processing/validating '
            || gc_error_code
            || '. SQLCODE - '
            || SQLCODE
            || ' SQLERRM - '
            || SUBSTR (SQLERRM, 1, 3000);
         gc_error_code := 'XXOD_EBL_001';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );

         IF gc_insert_fun_status = 'FALSE'
         THEN
            gc_return_status :=
                  'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
               || gc_error_code
               || ' - '
               || gc_error_message
               || ' - '
               || fnd_message.get_string ('XXCRM', gc_error_code);
         ELSE
            gc_return_status := 'FALSE - EBL-001';
         END IF;

         gc_error_message := '';
         RETURN gc_return_status;
   END validate_ebl_contacts;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_EBL_FILE_NAME                                      |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function will be used to validate date before inserting into         |
-- | XX_CDH_EBL_FILE_NAME_DTL table and also validate date before changing     |
-- | the document status from "IN PROCESS" to "TESTING" (or) from "TESTING"    |
-- | to "COMPLETE".                                                            |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |         lc_insert_fun_status :=
-- |             XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_FILE_NAME(
-- |                 lcu_get_eBill_file_details.ebl_file_name_id
-- |               , p_cust_doc_id
-- |               , lcu_get_eBill_file_details.file_name_order_seq
-- |               , lcu_get_eBill_file_details.field_id
-- |               , lcu_get_eBill_file_details.constant_value
-- |               , lcu_get_eBill_file_details.default_if_null
-- |               , lcu_get_eBill_file_details.comments
-- |               , lc_file_name_seq_reset
-- |               , lc_file_next_seq_number
-- |               , lc_file_seq_reset_date
-- |               , lc_file_name_max_seq_number
-- |               , NULL -- lcu_get_eBill_file_details.attribute1
-- |               , NULL -- lcu_get_eBill_file_details.attribute2
-- |               , NULL -- lcu_get_eBill_file_details.attribute3
-- |               , NULL -- lcu_get_eBill_file_details.attribute4
-- |               , NULL -- lcu_get_eBill_file_details.attribute5
-- |               , NULL -- lcu_get_eBill_file_details.attribute6
-- |               , NULL -- lcu_get_eBill_file_details.attribute7
-- |               , NULL -- lcu_get_eBill_file_details.attribute8
-- |               , NULL -- lcu_get_eBill_file_details.attribute9
-- |               , NULL -- lcu_get_eBill_file_details.attribute10
-- |               , NULL -- lcu_get_eBill_file_details.attribute11
-- |               , NULL -- lcu_get_eBill_file_details.attribute12
-- |               , NULL -- lcu_get_eBill_file_details.attribute13
-- |               , NULL -- lcu_get_eBill_file_details.attribute14
-- |               , NULL -- lcu_get_eBill_file_details.attribute15
-- |               , NULL -- lcu_get_eBill_file_details.attribute16
-- |               , NULL -- lcu_get_eBill_file_details.attribute17
-- |               , NULL -- lcu_get_eBill_file_details.attribute18
-- |               , NULL -- lcu_get_eBill_file_details.attribute19
-- |               , NULL -- lcu_get_eBill_file_details.attribute20
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
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = :document_id;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   FUNCTION validate_ebl_file_name (
      p_ebl_file_name_id           IN   NUMBER,
      p_cust_doc_id                IN   NUMBER,
      p_file_name_order_seq        IN   NUMBER,
      p_field_id                   IN   NUMBER,
      p_constant_value             IN   VARCHAR2,
      p_default_if_null            IN   VARCHAR2,
      p_comments                   IN   VARCHAR2,
      p_file_name_seq_reset        IN   VARCHAR2,
      p_file_next_seq_number       IN   NUMBER,
      p_file_seq_reset_date        IN   DATE,
      p_file_name_max_seq_number   IN   NUMBER,
      p_attribute1                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute2                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute3                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute4                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute5                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute6                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute7                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute8                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute9                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute10                IN   VARCHAR2 DEFAULT NULL,
      p_attribute11                IN   VARCHAR2 DEFAULT NULL,
      p_attribute12                IN   VARCHAR2 DEFAULT NULL,
      p_attribute13                IN   VARCHAR2 DEFAULT NULL,
      p_attribute14                IN   VARCHAR2 DEFAULT NULL,
      p_attribute15                IN   VARCHAR2 DEFAULT NULL,
      p_attribute16                IN   VARCHAR2 DEFAULT NULL,
      p_attribute17                IN   VARCHAR2 DEFAULT NULL,
      p_attribute18                IN   VARCHAR2 DEFAULT NULL,
      p_attribute19                IN   VARCHAR2 DEFAULT NULL,
      p_attribute20                IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      ln_field_count                NUMBER;
      ln_field_name                 xx_fin_translatevalues.source_value2%TYPE;
      lc_file_name_seq_reset        xx_cdh_ebl_main.file_name_seq_reset%TYPE;
      ln_file_next_seq_number       xx_cdh_ebl_main.file_next_seq_number%TYPE;
      ld_file_seq_reset_date        xx_cdh_ebl_main.file_seq_reset_date%TYPE;
      ln_file_name_max_seq_number   xx_cdh_ebl_main.file_name_max_seq_number%TYPE;
   BEGIN
----------------------------------------------------------------------------
-- Begining of VALIDATE_EBL_FILE_NAME package body.
----------------------------------------------------------------------------
      gc_return_status := 'TRUE';
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_019'
-- ERROR_MESSAGE = ''
-- Check for valid Field_id.
--
----------------------------------------------------------------------------
      gc_error_code := 'SELECT1';

      SELECT COUNT (1)
        INTO ln_field_count
        FROM xx_cdh_ebilling_fields_v vfin
       WHERE field_id = p_field_id AND use_in_file_name = 'Y';

      gc_error_code := 'XXOD_EBL_019';

      IF ln_field_count = 0
      THEN
         gc_error_message := '';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_020'
-- ERROR_MESSAGE = ''
-- Check for valid value for Constant.
--
----------------------------------------------------------------------------
      gc_error_code := 'SELECT2';

      SELECT field_name
        INTO ln_field_name
        FROM xx_cdh_ebilling_fields_v vfin
       WHERE field_id = p_field_id;

      IF ln_field_name = 'Constant'
      THEN
         gc_error_code := 'XXOD_EBL_020';

         IF p_constant_value IS NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      ELSIF ln_field_name = 'Sequence'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_021'
-- ERROR_MESSAGE = ''
-- Check for valid value for Sequence.
--
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- To get the File Sequence Details for a given Document.
----------------------------------------------------------------------------
         lc_file_name_seq_reset := p_file_name_seq_reset;
         ln_file_next_seq_number := p_file_next_seq_number;
         ld_file_seq_reset_date := p_file_seq_reset_date;
         ln_file_name_max_seq_number := p_file_name_max_seq_number;
         gc_error_code := 'XXOD_EBL_021';

         IF    lc_file_name_seq_reset IS NULL
            OR ln_file_next_seq_number IS NULL
            OR ld_file_seq_reset_date IS NULL
            OR ln_file_name_max_seq_number IS NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      END IF;

      IF gc_validation_status = 'FALSE'
      THEN
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';
         gc_validation_status := 'TRUE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_039'
-- ERROR_MESSAGE = ''
-- Constant can not have a value in "Default" Column.
--
----------------------------------------------------------------------------
      IF ln_field_name = 'Constant'
      THEN
         gc_error_code := 'XXOD_EBL_039';

         IF p_default_if_null IS NOT NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      ELSIF ln_field_name = 'Sequence'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_040'
-- ERROR_MESSAGE = ''
-- Check for Null value for Sequence.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_040';

         IF p_default_if_null IS NOT NULL OR p_constant_value IS NOT NULL
         THEN
            gc_error_message := '';
            gc_validation_status := 'FALSE';
         END IF;
      END IF;

      IF gc_validation_status = 'FALSE'
      THEN
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';
         gc_validation_status := 'TRUE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

      RETURN gc_return_status;
----------------------------------------------------------------------------
-- VALIDATE_EBL_FILE_NAME - Exception Block starts.
----------------------------------------------------------------------------
   EXCEPTION
      WHEN gex_error_table_error
      THEN
         gc_error_message :=
               'Customer Document Id: '
            || p_cust_doc_id
            || ' and Exception occurred in VALIDATE_EBL_FILE_NAME';
         gc_return_status :=
               'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
            || gc_error_message
            || ' - '
            || gc_error_code
            || ' - '
            || fnd_message.get_string ('XXCRM', gc_error_code);
         RETURN gc_return_status;
      WHEN OTHERS
      THEN
-------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_001'
-- ERROR_MESSAGE = ''
--
-------------------------------------------------------------------------
         gc_error_message :=
               'Exception occurred in VALIDATE_EBL_FILE_NAME. While processing/validating '
            || gc_error_code
            || '. SQLCODE - '
            || SQLCODE
            || ' SQLERRM - '
            || SUBSTR (SQLERRM, 1, 3000);
         gc_error_code := 'XXOD_EBL_001';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );

         IF gc_insert_fun_status = 'FALSE'
         THEN
            gc_return_status :=
                  'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
               || gc_error_code
               || ' - '
               || gc_error_message
               || ' - '
               || fnd_message.get_string ('XXCRM', gc_error_code);
         ELSE
            gc_return_status := 'FALSE - EBL-001';
         END IF;

         gc_error_message := '';
         RETURN gc_return_status;
   END validate_ebl_file_name;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_EBL_TEMPL_HEADER                                   |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function will be used to validate date before inserting into         |
-- | XX_CDH_EBL_TEMPL_HEADER table and also validate date before changing      |
-- | the document status from "IN PROCESS" to "TESTING" (or) from "TESTING"    |
-- | to "COMPLETE".                                                            |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |         lc_insert_fun_status :=
-- |             XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_TEMPL_HEADER(
-- |                lcu_get_doc.C_EXT_ATTR3  -- p_delivery_Method
-- |              , p_cust_doc_id
-- |              , lcu_get_eBill_conf_hdr.ebill_file_creation_type
-- |              , lcu_get_eBill_conf_hdr.delimiter_char
-- |              , lcu_get_eBill_conf_hdr.line_feed_style
-- |              , lcu_get_eBill_conf_hdr.include_header
-- |              , lcu_get_eBill_conf_hdr.logo_file_name
-- |              , lcu_get_eBill_conf_hdr.file_split_criteria
-- |              , lcu_get_eBill_conf_hdr.file_split_value
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute1
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute2
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute3
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute4
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute5
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute6
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute7
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute8
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute9
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute10
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute11
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute12
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute13
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute14
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute15
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute16
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute17
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute18
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute19
-- |              , NULL -- lcu_get_eBill_conf_hdr.attribute20
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
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = :document_id;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   FUNCTION validate_ebl_templ_header (
      p_cust_account_id            IN   NUMBER,
      p_cust_doc_id                IN   NUMBER,
      p_ebill_file_creation_type   IN   VARCHAR2,
      p_delimiter_char             IN   VARCHAR2,
      p_line_feed_style            IN   VARCHAR2,
      p_include_header             IN   VARCHAR2,
      p_logo_file_name             IN   VARCHAR2,
      p_file_split_criteria        IN   VARCHAR2,
      p_file_split_value           IN   NUMBER,
      p_attribute1                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute2                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute3                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute4                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute5                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute6                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute7                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute8                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute9                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute10                IN   VARCHAR2 DEFAULT NULL,
      p_attribute11                IN   VARCHAR2 DEFAULT NULL,
      p_attribute12                IN   VARCHAR2 DEFAULT NULL,
      p_attribute13                IN   VARCHAR2 DEFAULT NULL,
      p_attribute14                IN   VARCHAR2 DEFAULT NULL,
      p_attribute15                IN   VARCHAR2 DEFAULT NULL,
      p_attribute16                IN   VARCHAR2 DEFAULT NULL,
      p_attribute17                IN   VARCHAR2 DEFAULT NULL,
      p_attribute18                IN   VARCHAR2 DEFAULT NULL,
      p_attribute19                IN   VARCHAR2 DEFAULT NULL,
      p_attribute20                IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      lc_delivery_method   VARCHAR2 (150);
      lc_is_parent         NUMBER;
   BEGIN
----------------------------------------------------------------------------
-- Begining of VALIDATE_EBL_TEMPL_HEADER package body.
----------------------------------------------------------------------------
      gc_return_status := 'TRUE';
----------------------------------------------------------------------------
-- To get the Delivery Method for a given document.
----------------------------------------------------------------------------
      gc_error_code := 'SELECT1';

      SELECT c_ext_attr3, n_ext_attr17
        INTO lc_delivery_method, lc_is_parent
        FROM xx_cdh_cust_acct_ext_b
       WHERE cust_account_id = p_cust_account_id
         AND n_ext_attr2 = p_cust_doc_id
         AND attr_group_id =
                (SELECT attr_group_id
                   FROM ego_attr_groups_v
                  WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
                    AND attr_group_name = 'BILLDOCS');                  -- 166

      IF lc_delivery_method = 'eXLS'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_022'
-- ERROR_MESSAGE = ''
-- File Creation Type should be null for eXLS.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_022';

         IF    p_ebill_file_creation_type IS NOT NULL
            OR p_delimiter_char IS NOT NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;
      ELSIF lc_delivery_method = 'eTXT'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_023'
-- ERROR_MESSAGE = ''
-- File Creation Type can not be null for eTXT.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_023';

         IF p_ebill_file_creation_type IS NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_041'
-- ERROR_MESSAGE = ''
-- Delimiter Char can not be null when File Creation Type is DELIMITED.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_041';

         IF     p_ebill_file_creation_type = 'DELIMITED'
            AND p_delimiter_char IS NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_018'
-- ERROR_MESSAGE = ''
-- Delimiter Char should be null when File Creation Type is FIXED.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_018';

         IF     p_ebill_file_creation_type = 'FIXED'
            AND p_delimiter_char IS NOT NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_024'
-- ERROR_MESSAGE = ''
-- Include Header and Logo File Name should be No for eTXT.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_024';

         IF p_include_header = 'Y' OR p_logo_file_name IS NOT NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;
      ELSE
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_025'
-- ERROR_MESSAGE = ''
-- Not a Valid eBill Delivery Method.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_025';
         gc_error_message := '';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_042'
-- ERROR_MESSAGE = ''
-- For Parent Document Split Functionality is not available.
--
----------------------------------------------------------------------------
      gc_error_code := 'XXOD_EBL_042';

      IF     lc_is_parent = 1
         AND (   p_file_split_criteria IS NOT NULL
              OR p_file_split_value IS NOT NULL
             )
      THEN
         gc_error_message := '';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_043'
-- ERROR_MESSAGE = ''
-- File Split Value column can not have value.
--
----------------------------------------------------------------------------
      gc_error_code := 'XXOD_EBL_043';

      IF     p_file_split_criteria NOT IN ('INVAMT', 'INVAMTABS')
         AND p_file_split_value IS NOT NULL
      THEN
         gc_error_message := '';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_026'
-- ERROR_MESSAGE = ''
-- Validation for Split Criteria.
--
----------------------------------------------------------------------------
      gc_error_code := 'XXOD_EBL_026';

      IF     p_file_split_criteria IN ('INVAMT', 'INVAMTABS')
         AND p_file_split_value IS NULL
      THEN
         gc_error_message := '';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

      RETURN gc_return_status;
----------------------------------------------------------------------------
-- VALIDATE_EBL_TEMPL_HEADER - Exception Block starts.
----------------------------------------------------------------------------
   EXCEPTION
      WHEN gex_error_table_error
      THEN
         gc_error_message :=
               'Customer Document Id: '
            || p_cust_doc_id
            || ' and Exception occurred in VALIDATE_EBL_TEMPL_HEADER';
         gc_return_status :=
               'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
            || gc_error_message
            || ' - '
            || gc_error_code
            || ' - '
            || fnd_message.get_string ('XXCRM', gc_error_code);
         RETURN gc_return_status;
      WHEN OTHERS
      THEN
-------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_001'
-- ERROR_MESSAGE = ''
--
-------------------------------------------------------------------------
         gc_error_message :=
               'Exception occurred in VALIDATE_EBL_TEMPL_HEADER. While processing/validating '
            || gc_error_code
            || '. SQLCODE - '
            || SQLCODE
            || ' SQLERRM - '
            || SUBSTR (SQLERRM, 1, 3000);
         gc_error_code := 'XXOD_EBL_001';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );

         IF gc_insert_fun_status = 'FALSE'
         THEN
            gc_return_status :=
                  'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
               || gc_error_code
               || ' - '
               || gc_error_message
               || ' - '
               || fnd_message.get_string ('XXCRM', gc_error_code);
         ELSE
            gc_return_status := 'FALSE - EBL-001';
         END IF;

         gc_error_message := '';
         RETURN gc_return_status;
   END validate_ebl_templ_header;
   -- Moved for bottom to here for forward declaration on 08-JAN-2016
   PROCEDURE chkconcatorsplit (
      p_field_id     IN       NUMBER,
      p_cust_docid   IN       NUMBER,
      x_flag         OUT      VARCHAR2
   )
   IS
      CURSOR lcu_concatorsplit
      IS
         SELECT 'Y'
           FROM (SELECT xcecf.conc_field_label field_name,
                        CAST (xcecf.conc_field_id AS VARCHAR2 (240)) field_id,
                        xcetd.cust_doc_id
                   FROM xx_cdh_ebl_templ_dtl xcetd,
                        xx_cdh_ebl_concat_fields xcecf
                  WHERE xcetd.field_id = xcecf.conc_field_id
                    AND xcetd.cust_doc_id = xcecf.cust_doc_id
                    AND xcetd.attribute20 = 'Y'
                 UNION
                 SELECT xcetd.label field_name,
                        CAST (xcetd.field_id AS VARCHAR2 (240)) field_id,
                        xcetd.cust_doc_id
                   FROM xx_cdh_ebl_templ_dtl xcetd
                  WHERE base_field_id IS NOT NULL AND attribute20 = 'Y') qrslt
          WHERE cust_doc_id = p_cust_docid AND field_id = p_field_id;

      l_flag   VARCHAR2 (1) := 'N';
   BEGIN
      OPEN lcu_concatorsplit;

      FETCH lcu_concatorsplit
       INTO l_flag;

      CLOSE lcu_concatorsplit;

      x_flag := l_flag;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_flag := 'N';
   END chkconcatorsplit;
   
-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_EBL_TEMPL_DTL                                      |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function will be used to validate date before inserting into         |
-- | XX_CDH_EBL_TEMPL_DTL table and also validate date before changing         |
-- | the document status from "IN PROCESS" to "TESTING" (or) from "TESTING"    |
-- | to "COMPLETE".                                                            |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |         lc_insert_fun_status :=
-- |             XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_TEMPL_DTL (
-- |                 lcu_get_doc.C_EXT_ATTR3  -- p_delivery_Method
-- |               , lc_ebill_file_creation_type -- p_ebill_file_creation_type
-- |               , lcu_get_eBill_conf_dtl.ebl_templ_id
-- |               , lcu_get_eBill_conf_dtl.cust_doc_id
-- |               , lcu_get_eBill_conf_dtl.record_type
-- |               , lcu_get_eBill_conf_dtl.seq
-- |               , lcu_get_eBill_conf_dtl.field_id
-- |               , lcu_get_eBill_conf_dtl.label
-- |               , lcu_get_eBill_conf_dtl.start_pos
-- |               , lcu_get_eBill_conf_dtl.field_len
-- |               , lcu_get_eBill_conf_dtl.data_format
-- |               , lcu_get_eBill_conf_dtl.string_fun
-- |               , lcu_get_eBill_conf_dtl.sort_order
-- |               , lcu_get_eBill_conf_dtl.sort_type
-- |               , lcu_get_eBill_conf_dtl.mandatory
-- |               , lcu_get_eBill_conf_dtl.seq_start_val
-- |               , lcu_get_eBill_conf_dtl.seq_inc_val
-- |               , lcu_get_eBill_conf_dtl.seq_reset
-- |               , lcu_get_eBill_conf_dtl.constant_value
-- |               , lcu_get_eBill_conf_dtl.alignment
-- |               , lcu_get_eBill_conf_dtl.padding_char
-- |               , lcu_get_eBill_conf_dtl.default_if_null
-- |               , lcu_get_eBill_conf_dtl.comments
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute1
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute2
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute3
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute4
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute5
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute6
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute7
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute8
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute9
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute10
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute11
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute12
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute13
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute14
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute15
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute16
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute17
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute18
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute19
-- |               , NULL -- lcu_get_eBill_conf_dtl.attribute20
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
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = :document_id;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   FUNCTION validate_ebl_templ_dtl (
      p_cust_account_id            IN   NUMBER,
      p_ebill_file_creation_type   IN   xx_cdh_ebl_templ_header.ebill_file_creation_type%TYPE,
      p_ebl_templ_id               IN   NUMBER,
      p_cust_doc_id                IN   NUMBER,
      p_record_type                IN   VARCHAR2,
      p_seq                        IN   NUMBER,
      p_field_id                   IN   NUMBER,
      p_label                      IN   VARCHAR2,
      p_start_pos                  IN   NUMBER
                                              -- Need to Remove from the screen.
   ,
      p_field_len                  IN   NUMBER,
      p_data_format                IN   VARCHAR2,
      p_string_fun                 IN   VARCHAR2,
      p_sort_order                 IN   NUMBER,
      p_sort_type                  IN   VARCHAR2,
      p_mandatory                  IN   VARCHAR2,
      p_seq_start_val              IN   NUMBER,
      p_seq_inc_val                IN   NUMBER,
      p_seq_reset_field            IN   NUMBER,
      p_constant_value             IN   VARCHAR2,
      p_alignment                  IN   VARCHAR2,
      p_padding_char               IN   VARCHAR2,
      p_default_if_null            IN   VARCHAR2,
      p_comments                   IN   VARCHAR2,
      p_attribute1                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute2                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute3                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute4                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute5                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute6                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute7                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute8                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute9                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute10                IN   VARCHAR2 DEFAULT NULL,
      p_attribute11                IN   VARCHAR2 DEFAULT NULL,
      p_attribute12                IN   VARCHAR2 DEFAULT NULL,
      p_attribute13                IN   VARCHAR2 DEFAULT NULL,
      p_attribute14                IN   VARCHAR2 DEFAULT NULL,
      p_attribute15                IN   VARCHAR2 DEFAULT NULL,
      p_attribute16                IN   VARCHAR2 DEFAULT NULL,
      p_attribute17                IN   VARCHAR2 DEFAULT NULL,
      p_attribute18                IN   VARCHAR2 DEFAULT NULL,
      p_attribute19                IN   VARCHAR2 DEFAULT NULL,
      p_attribute20                IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      lc_delivery_method            VARCHAR2 (150);
      ln_field_count                NUMBER;
      ln_field_name                 xx_fin_translatevalues.source_value2%TYPE;
      lc_ebill_file_creation_type   xx_cdh_ebl_templ_header.ebill_file_creation_type%TYPE;
      lc_flag                       VARCHAR2 (1);
   BEGIN
----------------------------------------------------------------------------
-- Begining of VALIDATE_EBL_TEMPL_DTL package body.
----------------------------------------------------------------------------
      gc_return_status := 'TRUE';
      lc_ebill_file_creation_type := p_ebill_file_creation_type;
----------------------------------------------------------------------------
-- To get the Delivery Method for a given document.
----------------------------------------------------------------------------
      gc_error_code := 'SELECT1';

      SELECT c_ext_attr3
        INTO lc_delivery_method
        FROM xx_cdh_cust_acct_ext_b
       WHERE cust_account_id = p_cust_account_id
         AND n_ext_attr2 = p_cust_doc_id
         AND attr_group_id =
                (SELECT attr_group_id
                   FROM ego_attr_groups_v
                  WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
                    AND attr_group_name = 'BILLDOCS');                  -- 166

      IF lc_delivery_method = 'eXLS'
      THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_027'
-- ERROR_MESSAGE = ''
-- To make sure that all the fields are for eXLS.
--
----------------------------------------------------------------------------
/*
gc_error_code := 'SELECT3';
SELECT COUNT(1)
INTO ln_field_count
FROM xx_cdh_ebilling_fields_v vfin
WHERE field_id = p_field_id
AND include_in_standard = 'Y';
gc_error_code := 'XXOD_EBL_027';
IF ln_field_count = 0
THEN
gc_error_message := '';
gc_insert_fun_status := insert_ebl_error(p_cust_doc_id,
gc_doc_process_date -- p_doc_process_date
,
gc_error_code -- p_error_code
,
gc_error_message -- p_error_desc
);
gc_return_status := 'FALSE';
IF gc_insert_fun_status = 'FALSE'
THEN
RAISE gex_error_table_error;
END IF;
END IF;
*/
--Code Unit Included by Vasan, 01/Jul/2010
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_083'
-- ERROR_MESSAGE = ''
-- To make sure that the Sort Type is given for only valid fields in eXLS.
--
----------------------------------------------------------------------------
/*
--Code Commented by Vasan on 05-Jan, for Defect
SELECT substr(Field_Name, 0 , 8) Field_Name
INTO   ln_field_name
FROM   XX_CDH_EBILLING_FIELDS_V vfin
WHERE  field_id = p_field_id;
GC_ERROR_CODE := 'XXOD_EBL_083';
IF p_attribute1 = 'Y'
AND ln_field_name = 'Constant'
AND nvl(p_constant_value,'NULL') = 'NULL'
THEN
GC_ERROR_MESSAGE     := '';
GC_INSERT_FUN_STATUS :=
INSERT_EBL_ERROR(
p_cust_doc_id
, GC_DOC_PROCESS_DATE -- p_doc_process_date
, GC_ERROR_CODE       -- p_error_code
, GC_ERROR_MESSAGE    -- p_error_desc
);
GC_RETURN_STATUS     := 'FALSE';
IF GC_INSERT_FUN_STATUS = 'FALSE' THEN
RAISE GEX_ERROR_TABLE_ERROR;
END IF;
END IF;
*/
--Code Unit Included by Vasan, 01/Jul/2010
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_028'
-- ERROR_MESSAGE = ''
-- To make sure that the Sort Order is given for only valid fields for eXLS.
--
----------------------------------------------------------------------------
         IF p_sort_order IS NOT NULL
         THEN
            gc_error_code := 'SELECT4';
            lc_flag := 'N';
            chkconcatorsplit (p_field_id        => p_field_id,
                              p_cust_docid      => p_cust_doc_id,
                              x_flag            => lc_flag
                             );

            IF (lc_flag = 'N')
            THEN
               SELECT COUNT (1)
                 INTO ln_field_count
                 FROM xx_cdh_ebilling_fields_v vfin
                WHERE field_id = p_field_id AND sortable = 'Y';
            END IF;

            gc_error_code := 'XXOD_EBL_028';

            IF ln_field_count = 0
            THEN
               gc_error_message := '';
               gc_insert_fun_status :=
                  insert_ebl_error (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
               gc_return_status := 'FALSE';

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  RAISE gex_error_table_error;
               END IF;
            
            END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_029'
-- ERROR_MESSAGE = ''
-- To make sure that the Sort Type is given for only valid fields in eXLS.
--
----------------------------------------------------------------------------
            gc_error_code := 'XXOD_EBL_029';

            IF p_sort_type IS NULL
            THEN
               gc_error_message := '';
               gc_insert_fun_status :=
                  insert_ebl_error (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
               gc_return_status := 'FALSE';

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  RAISE gex_error_table_error;
               END IF;
            END IF;
        ELSE /* Sort order null */
        
            gc_error_code := 'XXOD_EBL_084';

            IF p_sort_type IS NOT NULL
            THEN
               gc_error_message := '';
               gc_insert_fun_status :=
                  insert_ebl_error (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
               gc_return_status := 'FALSE';

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  RAISE gex_error_table_error;
               END IF;
            END IF;
         END IF;
         
         
      ELSIF lc_delivery_method = 'eTXT'
      THEN
         gc_error_code := 'SELECT5';

----------------------------------------------------------------------------
-- To make sure only Constant Value is picked. for Example Constant1 will be Constant.
----------------------------------------------------------------------------
         SELECT SUBSTR (field_name, 0, 8) field_name
           INTO ln_field_name
           FROM xx_cdh_ebilling_fields_v vfin
          WHERE field_id = p_field_id;

         IF ln_field_name = 'Constant'
         THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_030'
-- ERROR_MESSAGE = ''
-- To make sure that Constant Value is given when the field is Constant.
--
----------------------------------------------------------------------------
            gc_error_code := 'XXOD_EBL_030';

            IF p_constant_value IS NULL
            THEN
               gc_error_message := '';
               gc_validation_status := 'FALSE';
            END IF;
         ELSIF ln_field_name = 'Sequence'
         THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_031'
-- ERROR_MESSAGE = ''
-- To make sure that Sequence related Value is given when the field is Sequence.
--
----------------------------------------------------------------------------
            gc_error_code := 'XXOD_EBL_031';

            IF p_seq_start_val IS NULL OR p_seq_inc_val IS NULL
            THEN
               --             OR p_seq_reset_field IS NULL THEN
               gc_error_message := '';
               gc_validation_status := 'FALSE';
            END IF;
         END IF;

         IF gc_validation_status = 'FALSE'
         THEN
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';
            gc_validation_status := 'TRUE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

         IF ln_field_name = 'Constant'
         THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_047'
-- ERROR_MESSAGE = ''
-- When Constant Field is selected then all the Sequence column values should be Null and also Default column value should be null.
--
----------------------------------------------------------------------------
            gc_error_code := 'XXOD_EBL_047';

            IF    p_default_if_null IS NOT NULL
               OR p_seq_start_val IS NOT NULL
               OR p_seq_inc_val IS NOT NULL
               OR p_seq_reset_field IS NOT NULL
            THEN
               gc_error_message := '';
               gc_validation_status := 'FALSE';
            END IF;
         ELSIF ln_field_name = 'Sequence'
         THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_048'
-- ERROR_MESSAGE = ''
-- When Sequence Field is selected then Constant column values should be Null and also Default column value should be null.
--
----------------------------------------------------------------------------
            gc_error_code := 'XXOD_EBL_048';

            IF p_default_if_null IS NOT NULL OR p_constant_value IS NOT NULL
            THEN
               gc_error_message := '';
               gc_validation_status := 'FALSE';
            END IF;
         END IF;

         IF gc_validation_status = 'FALSE'
         THEN
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';
            gc_validation_status := 'TRUE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_044'
-- ERROR_MESSAGE = ''
-- Label can not be null.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_044';

         IF p_label IS NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_032'
-- ERROR_MESSAGE = ''
-- To make sure that Default If Null Column Value is given when Mandatory field = 'Yes'.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_032';

         IF p_mandatory = 'Y' AND p_default_if_null IS NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_033'
-- ERROR_MESSAGE = ''
-- To make sure that File Creation Type = 'FIXED', alignment or PaddingChar can not be null.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_033';

         IF     lc_ebill_file_creation_type = 'FIXED'
            AND (p_alignment IS NULL OR p_padding_char IS NULL)
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_049'
-- ERROR_MESSAGE = ''
-- Both Alignment or Padding Char columns should be null when File Creation Type <> 'FIXED'.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_049';

         IF     lc_ebill_file_creation_type <> 'FIXED'
            AND (p_alignment IS NOT NULL OR p_padding_char IS NOT NULL)
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_034'
-- ERROR_MESSAGE = ''
-- To make sure that if Alignment is not null then PaddingChar can not be null.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_034';

         IF p_alignment IS NOT NULL AND p_padding_char IS NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;
      ELSE
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_025'
-- ERROR_MESSAGE = ''
-- Not a Valid eBill Delivery Method.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_025';
         gc_error_message := '';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

      RETURN gc_return_status;
----------------------------------------------------------------------------
-- VALIDATE_EBL_TEMPL_DTL - Exception Block starts.
----------------------------------------------------------------------------
   EXCEPTION
      WHEN gex_error_table_error
      THEN
         gc_error_message :=
               'Customer Document Id: '
            || p_cust_doc_id
            || ' and Exception occurred in VALIDATE_EBL_TEMPL_DTL';
         gc_return_status :=
               'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
            || gc_error_message
            || ' - '
            || gc_error_code
            || ' - '
            || fnd_message.get_string ('XXCRM', gc_error_code);
         RETURN gc_return_status;
      WHEN OTHERS
      THEN
-------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_001'
-- ERROR_MESSAGE = ''
--
-------------------------------------------------------------------------
         gc_error_message :=
               'Exception occurred in VALIDATE_EBL_TEMPL_DTL. While processing/validating '
            || gc_error_code
            || '. SQLCODE - '
            || SQLCODE
            || ' SQLERRM - '
            || SUBSTR (SQLERRM, 1, 3000);
         gc_error_code := 'XXOD_EBL_001';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );

         IF gc_insert_fun_status = 'FALSE'
         THEN
            gc_return_status :=
                  'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
               || gc_error_code
               || ' - '
               || gc_error_message
               || ' - '
               || fnd_message.get_string ('XXCRM', gc_error_code);
         ELSE
            gc_return_status := 'FALSE - EBL-001';
         END IF;

         gc_error_message := '';
         RETURN gc_return_status;
   END validate_ebl_templ_dtl;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_EBL_STD_AGGR_DTL                                   |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function will be used to validate date before inserting into         |
-- | XX_CDH_EBL_STD_AGGR_DTL table and also validate date before changing      |
-- | the document status from "IN PROCESS" to "TESTING" (or) from "TESTING"    |
-- | to "COMPLETE". This validation package is not called for eTXT.            |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |         lc_insert_fun_status :=
-- |             XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_STD_AGGR_DTL (
-- |                 lcu_get_eBill_sub_tot.ebl_aggr_id
-- |               , lcu_get_eBill_sub_tot.cust_doc_id
-- |               , lcu_get_eBill_sub_tot.aggr_fun
-- |               , lcu_get_eBill_sub_tot.aggr_field_id
-- |               , lcu_get_eBill_sub_tot.change_field_id
-- |               , lcu_get_eBill_sub_tot.label_on_file
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute1
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute2
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute3
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute4
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute5
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute6
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute7
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute8
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute9
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute10
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute11
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute12
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute13
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute14
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute15
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute16
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute17
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute18
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute19
-- |               , NULL -- lcu_get_eBill_sub_tot.attribute20
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
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = :document_id;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   FUNCTION validate_ebl_std_aggr_dtl (
      p_ebl_aggr_id       IN   NUMBER,
      p_cust_doc_id       IN   NUMBER,
      p_aggr_fun          IN   VARCHAR2,
      p_aggr_field_id     IN   NUMBER,
      p_change_field_id   IN   NUMBER,
      p_label_on_file     IN   VARCHAR2,
      p_attribute1        IN   VARCHAR2 DEFAULT NULL,
      p_attribute2        IN   VARCHAR2 DEFAULT NULL,
      p_attribute3        IN   VARCHAR2 DEFAULT NULL,
      p_attribute4        IN   VARCHAR2 DEFAULT NULL,
      p_attribute5        IN   VARCHAR2 DEFAULT NULL,
      p_attribute6        IN   VARCHAR2 DEFAULT NULL,
      p_attribute7        IN   VARCHAR2 DEFAULT NULL,
      p_attribute8        IN   VARCHAR2 DEFAULT NULL,
      p_attribute9        IN   VARCHAR2 DEFAULT NULL,
      p_attribute10       IN   VARCHAR2 DEFAULT NULL,
      p_attribute11       IN   VARCHAR2 DEFAULT NULL,
      p_attribute12       IN   VARCHAR2 DEFAULT NULL,
      p_attribute13       IN   VARCHAR2 DEFAULT NULL,
      p_attribute14       IN   VARCHAR2 DEFAULT NULL,
      p_attribute15       IN   VARCHAR2 DEFAULT NULL,
      p_attribute16       IN   VARCHAR2 DEFAULT NULL,
      p_attribute17       IN   VARCHAR2 DEFAULT NULL,
      p_attribute18       IN   VARCHAR2 DEFAULT NULL,
      p_attribute19       IN   VARCHAR2 DEFAULT NULL,
      p_attribute20       IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      ln_field_count      NUMBER;
      lc_aggrfield_flag   VARCHAR2 (1);
      lc_chgfield_flag    VARCHAR2 (1);
   BEGIN
----------------------------------------------------------------------------
-- Begining of VALIDATE_EBL_STD_AGGR_DTL package body.
----------------------------------------------------------------------------
      gc_return_status := 'TRUE';
      lc_aggrfield_flag := 'N';
      lc_chgfield_flag := 'N';
      chkconcatorsplit (p_field_id        => p_aggr_field_id,
                        p_cust_docid      => p_cust_doc_id,
                        x_flag            => lc_aggrfield_flag
                       );
      chkconcatorsplit (p_field_id        => p_change_field_id,
                        p_cust_docid      => p_cust_doc_id,
                        x_flag            => lc_chgfield_flag
                       );
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_045'
-- ERROR_MESSAGE = ''
-- Aggregate Field Name and/or Change Field Name can not be Null.
--
----------------------------------------------------------------------------
      gc_error_code := 'XXOD_EBL_045';

      IF p_aggr_field_id IS NULL OR p_change_field_id IS NULL
      THEN
         gc_error_message := '';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );
         gc_return_status := 'FALSE';

         IF gc_insert_fun_status = 'FALSE'
         THEN
            RAISE gex_error_table_error;
         END IF;
      END IF;

      IF lc_aggrfield_flag = 'N'
      THEN
         IF p_aggr_fun = 'COUNT'
         THEN
            gc_error_code := 'SELECT1';

            SELECT COUNT (1)
              INTO ln_field_count
              FROM xx_cdh_ebilling_fields_v vfin
             WHERE aggegatable = 'Y'
               AND include_in_standard = 'Y'
               AND vfin.field_id = p_aggr_field_id
               AND EXISTS (
                      SELECT 1
                        FROM xx_cdh_ebl_templ_dtl ebl_temp
                       WHERE ebl_temp.cust_doc_id = p_cust_doc_id
                         AND ebl_temp.field_id = vfin.field_id
                         AND ebl_temp.attribute1 = 'Y');

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_035'
-- ERROR_MESSAGE = ''
-- To make sure that valid aggr field is saved when aggr_fun = 'COUNT'.
--
----------------------------------------------------------------------------
            gc_error_code := 'XXOD_EBL_035';

            IF ln_field_count = 0
            THEN
               gc_error_message := '';
               gc_validation_status := 'FALSE';
            END IF;
         ELSIF p_aggr_fun = 'SUM'
         THEN
            gc_error_code := 'SELECT2';

            SELECT COUNT (1)
              INTO ln_field_count
              FROM xx_cdh_ebilling_fields_v vfin
             WHERE aggegatable = 'Y'
               AND include_in_standard = 'Y'
               AND vfin.field_id = p_aggr_field_id
               AND data_type = 'NUMERIC'
               AND EXISTS (
                      SELECT 1
                        FROM xx_cdh_ebl_templ_dtl ebl_temp
                       WHERE ebl_temp.cust_doc_id = p_cust_doc_id
                         AND ebl_temp.field_id = vfin.field_id
                         AND ebl_temp.attribute1 = 'Y');

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_036'
-- ERROR_MESSAGE = ''
-- To make sure that valid aggr field is saved when aggr_fun = 'SUM'.
--
----------------------------------------------------------------------------
            gc_error_code := 'XXOD_EBL_036';

            IF ln_field_count = 0
            THEN
               gc_error_message := '';
               gc_validation_status := 'FALSE';
            END IF;
         ELSE
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_037'
-- ERROR_MESSAGE = ''
-- Invalid aggr_fun.
--
----------------------------------------------------------------------------
            gc_error_code := 'XXOD_EBL_037';

            IF ln_field_count = 0
            THEN
               gc_error_message := '';
               gc_validation_status := 'FALSE';
            END IF;
         END IF;

         IF gc_validation_status = 'FALSE'
         THEN
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';
            gc_validation_status := 'TRUE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;
      END IF;

      IF lc_chgfield_flag = 'N'
      THEN
         gc_error_code := 'SELECT3';

         SELECT COUNT (1)
           INTO ln_field_count
           FROM xx_cdh_ebilling_fields_v vfin
          WHERE include_in_standard = 'Y'
            AND vfin.field_id = p_change_field_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_cdh_ebl_templ_dtl ebl_temp
                    WHERE ebl_temp.cust_doc_id = p_cust_doc_id
                      AND ebl_temp.field_id = vfin.field_id
                      AND ebl_temp.attribute1 = 'Y');

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_046'
-- ERROR_MESSAGE = ''
-- To make sure that valid Change field is saved.
--
----------------------------------------------------------------------------
         gc_error_code := 'XXOD_EBL_046';

         IF ln_field_count = 0
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            gc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;
      END IF;

      RETURN gc_return_status;
----------------------------------------------------------------------------
-- VALIDATE_EBL_STD_AGGR_DTL - Exception Block starts.
----------------------------------------------------------------------------
   EXCEPTION
      WHEN gex_error_table_error
      THEN
         gc_error_message :=
               'Customer Document Id: '
            || p_cust_doc_id
            || ' and Exception occurred in VALIDATE_EBL_STD_AGGR_DTL';
         gc_return_status :=
               'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
            || gc_error_message
            || ' - '
            || gc_error_code
            || ' - '
            || fnd_message.get_string ('XXCRM', gc_error_code);
         RETURN gc_return_status;
      WHEN OTHERS
      THEN
-------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_001'
-- ERROR_MESSAGE = ''
--
-------------------------------------------------------------------------
         gc_error_message :=
               'Exception occurred in VALIDATE_EBL_STD_AGGR_DTL. While processing/validating '
            || gc_error_code
            || '. SQLCODE - '
            || SQLCODE
            || ' SQLERRM - '
            || SUBSTR (SQLERRM, 1, 3000);
         gc_error_code := 'XXOD_EBL_001';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );

         IF gc_insert_fun_status = 'FALSE'
         THEN
            gc_return_status :=
                  'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
               || gc_error_code
               || ' - '
               || gc_error_message
               || ' - '
               || fnd_message.get_string ('XXCRM', gc_error_code);
         ELSE
            gc_return_status := 'FALSE - EBL-001';
         END IF;

         gc_error_message := '';
         RETURN gc_return_status;
   END validate_ebl_std_aggr_dtl;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_FINAL                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function will be used to validate date before chaning the status     |
-- | from "IN PROCESS" to "TESTING" (or) from "TESTING" to "COMPLETE".         |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- | -- 0 Records in Error table.
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = p_cust_doc_id;
-- |
-- |select * from xx_cdh_ebl_error
-- |where cust_doc_id = 10954555;
-- |
-- |update XX_CDH_CUST_ACCT_EXT_B set
-- |C_EXT_ATTR16 = 'IN_PROCESS'
-- |where N_EXT_ATTR2 = 10954555
-- |and   CUST_ACCOUNT_ID = 7666
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |         lc_insert_fun_status :=
-- |             XX_CDH_EBL_VALIDATE_PKG.VALIDATE_FINAL (
-- |                p_cust_doc_id
-- |              , p_cust_account_id
-- |              , p_change_status
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
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = :document_id;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   FUNCTION validate_final (
      p_cust_doc_id       IN   NUMBER,
      p_cust_account_id   IN   NUMBER,
      p_change_status     IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      lc_ebill_transmission_type    xx_cdh_ebl_main.ebill_transmission_type%TYPE;
      lc_file_name_seq_reset        xx_cdh_ebl_main.file_name_seq_reset%TYPE;
      ld_file_seq_reset_date        xx_cdh_ebl_main.file_seq_reset_date%TYPE;
      ln_file_next_seq_number       xx_cdh_ebl_main.file_next_seq_number%TYPE;
      ln_file_name_max_seq_number   xx_cdh_ebl_main.file_name_max_seq_number%TYPE;
      lc_ebill_file_creation_type   xx_cdh_ebl_templ_header.ebill_file_creation_type%TYPE;
      lc_paydoc_payment_term        VARCHAR2 (100);
      lc_return_status              VARCHAR2 (4000);
      lc_rec_count                  NUMBER;
      le_other_proc_error           EXCEPTION;
   BEGIN
      DBMS_OUTPUT.put_line ('Start Program');
----------------------------------------------------------------------------
-- Begining of VALIDATE_FINAL package body.
----------------------------------------------------------------------------
      lc_return_status := 'TRUE';
----------------------------------------------------------------------------
-- Delete all the Error records from the Error Table.
----------------------------------------------------------------------------
      DBMS_OUTPUT.put_line ('Before Delete');
      delete_ebl_error (p_cust_doc_id);
----------------------------------------------------------------------------
-- Starting Document Loop.
----------------------------------------------------------------------------
      DBMS_OUTPUT.put_line ('First Loop');
      gc_error_code := 'LOOP1';

      FOR lcu_get_doc IN (SELECT *
                            FROM xx_cdh_cust_acct_ext_b
                           WHERE cust_account_id = p_cust_account_id
                             AND n_ext_attr2 = p_cust_doc_id)
      -- Start of Customer Document Loop.
      LOOP
         IF lcu_get_doc.c_ext_attr3 NOT IN ('ePDF', 'eXLS', 'eTXT')
         THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_025'
-- ERROR_MESSAGE = ''
-- Invalid Delivery Method.
--
----------------------------------------------------------------------------
            gc_error_code := 'XXOD_EBL_025';
            gc_error_message := '';
            gc_insert_fun_status :=
               insert_ebl_error (p_cust_doc_id,
                                 gc_doc_process_date     -- p_doc_process_date
                                                    ,
                                 gc_error_code                 -- p_error_code
                                              ,
                                 gc_error_message              -- p_error_desc
                                );
            lc_return_status := 'FALSE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         ELSE
----------------------------------------------------------------------------
-- Starting eBill Main Loop.
----------------------------------------------------------------------------
            gc_error_code := 'SELECT0';

            SELECT COUNT (1)
              INTO lc_rec_count
              FROM xx_cdh_ebl_main
             WHERE cust_doc_id = p_cust_doc_id;

            IF lc_rec_count <> 1
            THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_050'
-- ERROR_MESSAGE = ''
-- Document should have eBill Main Details. So please save eBill Main Page details and then Click on Complete.
--
----------------------------------------------------------------------------
               gc_error_code := 'XXOD_EBL_050';
               gc_error_message := '';
               gc_insert_fun_status :=
                  insert_ebl_error (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
               lc_return_status := 'FALSE';

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  RAISE gex_error_table_error;
               END IF;
            END IF;

            gc_error_code := 'SELECT0.1';

            SELECT COUNT (1)
              INTO lc_rec_count
              FROM xx_cdh_ebl_file_name_dtl
             WHERE cust_doc_id = p_cust_doc_id;

            IF lc_rec_count = 0
            THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_051'
-- ERROR_MESSAGE = ''
-- Document should have File Naming Details. So please save File Naming Page details and then Click on Complete.
--
----------------------------------------------------------------------------
               gc_error_code := 'XXOD_EBL_051';
               gc_error_message := '';
               gc_insert_fun_status :=
                  insert_ebl_error (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
               lc_return_status := 'FALSE';

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  RAISE gex_error_table_error;
               END IF;
            END IF;

            gc_error_code := 'LOOP2';

            FOR lcu_get_ebill_main IN (SELECT *
                                         FROM xx_cdh_ebl_main
                                        WHERE cust_doc_id = p_cust_doc_id)
            -- Start of eBill Main Loop.
            LOOP
               lc_ebill_transmission_type :=
                                   lcu_get_ebill_main.ebill_transmission_type;
               lc_file_name_seq_reset :=
                                       lcu_get_ebill_main.file_name_seq_reset;
               ld_file_seq_reset_date :=
                                       lcu_get_ebill_main.file_seq_reset_date;
               ln_file_next_seq_number :=
                                      lcu_get_ebill_main.file_next_seq_number;
               ln_file_name_max_seq_number :=
                                  lcu_get_ebill_main.file_name_max_seq_number;
               gc_error_code := 'SELECT1';

               SELECT COUNT (1)
                 INTO lc_rec_count
                 FROM xx_cdh_ebl_templ_header
                WHERE cust_doc_id = p_cust_doc_id;

               IF lcu_get_doc.c_ext_attr3 = 'ePDF' AND lc_rec_count > 0
               THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_052'
-- ERROR_MESSAGE = ''
-- For ePDF Delivery Method temp header should not be defined.
--
----------------------------------------------------------------------------
                  gc_error_code := 'XXOD_EBL_052';
                  gc_error_message := '';
                  gc_validation_status := 'FALSE';
               ELSIF     lcu_get_doc.c_ext_attr3 IN ('eXLS', 'eTXT')
                     AND lc_rec_count = 0
               THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_053'
-- ERROR_MESSAGE = ''
-- For eXLS and eTXT Delivery Method temp header should be defined.
--
----------------------------------------------------------------------------
                  gc_error_code := 'XXOD_EBL_053';
                  gc_error_message := '';
                  gc_validation_status := 'FALSE';
               END IF;

               IF gc_validation_status = 'FALSE'
               THEN
                  gc_insert_fun_status :=
                     insert_ebl_error
                                   (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
                  lc_return_status := 'FALSE';
                  gc_validation_status := 'TRUE';

                  IF gc_insert_fun_status = 'FALSE'
                  THEN
                     RAISE gex_error_table_error;
                  END IF;
               END IF;

               gc_error_code := 'SELECT2';

               IF lcu_get_doc.c_ext_attr3 = 'eXLS'
               THEN
                  SELECT COUNT (1)
                    INTO lc_rec_count
                    FROM xx_cdh_ebl_templ_dtl
                   WHERE cust_doc_id = p_cust_doc_id AND attribute1 = 'Y';
               ELSE
                  SELECT COUNT (1)
                    INTO lc_rec_count
                    FROM xx_cdh_ebl_templ_dtl
                   WHERE cust_doc_id = p_cust_doc_id;
               END IF;

               IF lcu_get_doc.c_ext_attr3 = 'ePDF' AND lc_rec_count > 0
               THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_054'
-- ERROR_MESSAGE = ''
-- For ePDF Delivery Method temp details should not be defined.
--
----------------------------------------------------------------------------
                  gc_error_code := 'XXOD_EBL_054';
                  gc_error_message := '';
                  gc_validation_status := 'FALSE';
               ELSIF     lcu_get_doc.c_ext_attr3 IN ('eXLS', 'eTXT')
                     AND lc_rec_count = 0
               THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_055'
-- ERROR_MESSAGE = ''
-- For eXLS and eTXT Delivery Method temp details should be defined.
--
----------------------------------------------------------------------------
                  gc_error_code := 'XXOD_EBL_055';
                  gc_error_message := '';
                  gc_validation_status := 'FALSE';
               END IF;

               IF gc_validation_status = 'FALSE'
               THEN
                  gc_insert_fun_status :=
                     insert_ebl_error
                                   (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
                  lc_return_status := 'FALSE';
                  gc_validation_status := 'TRUE';

                  IF gc_insert_fun_status = 'FALSE'
                  THEN
                     RAISE gex_error_table_error;
                  END IF;
               END IF;

               gc_error_code := 'SELECT3';

               SELECT COUNT (1)
                 INTO lc_rec_count
                 FROM xx_cdh_ebl_std_aggr_dtl
                WHERE cust_doc_id = p_cust_doc_id;

               IF     lcu_get_doc.c_ext_attr3 IN ('ePDF', 'eTXT')
                  AND lc_rec_count > 0
               THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_056'
-- ERROR_MESSAGE = ''
-- For ePDF and eTXT Delivery Method Sub Total should not be defined.
--
----------------------------------------------------------------------------
                  gc_error_code := 'XXOD_EBL_056';
                  gc_error_message := '';
                  gc_validation_status := 'FALSE';
--      ELSIF lcu_get_doc.C_EXT_ATTR3 = 'eXLS'
--        AND lc_rec_count = 0 THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_057'
-- ERROR_MESSAGE = ''
-- For eXLS Delivery Method Sub Total should be defined.
--
----------------------------------------------------------------------------
--         GC_ERROR_CODE        := 'XXOD_EBL_057';
--         GC_ERROR_MESSAGE     := '';
--             GC_VALIDATION_STATUS := 'FALSE';
               END IF;

               IF gc_validation_status = 'FALSE'
               THEN
                  gc_insert_fun_status :=
                     insert_ebl_error
                                   (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
                  lc_return_status := 'FALSE';
                  gc_validation_status := 'TRUE';

                  IF gc_insert_fun_status = 'FALSE'
                  THEN
                     RAISE gex_error_table_error;
                  END IF;
               END IF;

               gc_insert_fun_status :=
                  validate_ebl_main
                                (p_cust_doc_id,
                                 p_cust_account_id,
                                 lcu_get_ebill_main.ebill_transmission_type,
                                 lcu_get_ebill_main.ebill_associate,
                                 lcu_get_ebill_main.file_processing_method,
                                 lcu_get_ebill_main.file_name_ext,
                                 lcu_get_ebill_main.max_file_size,
                                 lcu_get_ebill_main.max_transmission_size,
                                 lcu_get_ebill_main.zip_required,
                                 lcu_get_ebill_main.zipping_utility,
                                 lcu_get_ebill_main.zip_file_name_ext,
                                 lcu_get_ebill_main.od_field_contact,
                                 lcu_get_ebill_main.od_field_contact_email,
                                 lcu_get_ebill_main.od_field_contact_phone,
                                 lcu_get_ebill_main.client_tech_contact,
                                 lcu_get_ebill_main.client_tech_contact_email,
                                 lcu_get_ebill_main.client_tech_contact_phone,
                                 lcu_get_ebill_main.file_name_seq_reset,
                                 lcu_get_ebill_main.file_next_seq_number,
                                 lcu_get_ebill_main.file_seq_reset_date,
                                 lcu_get_ebill_main.file_name_max_seq_number,
                                 lcu_get_ebill_main.attribute1,
                                 lcu_get_ebill_main.attribute2,
                                 lcu_get_ebill_main.attribute3,
                                 lcu_get_ebill_main.attribute4,
                                 lcu_get_ebill_main.attribute5,
                                 lcu_get_ebill_main.attribute6,
                                 lcu_get_ebill_main.attribute7,
                                 lcu_get_ebill_main.attribute8,
                                 lcu_get_ebill_main.attribute9,
                                 lcu_get_ebill_main.attribute10,
                                 lcu_get_ebill_main.attribute11,
                                 lcu_get_ebill_main.attribute12,
                                 lcu_get_ebill_main.attribute13,
                                 lcu_get_ebill_main.attribute14,
                                 lcu_get_ebill_main.attribute15,
                                 lcu_get_ebill_main.attribute16,
                                 lcu_get_ebill_main.attribute17,
                                 lcu_get_ebill_main.attribute18,
                                 lcu_get_ebill_main.attribute19,
                                 lcu_get_ebill_main.attribute20
                                );

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  lc_return_status := gc_insert_fun_status;
               ELSIF gc_insert_fun_status <> 'TRUE'
               THEN
                  RAISE le_other_proc_error;
               END IF;
            END LOOP;

-- End of eBill Main Loop.
----------------------------------------------------------------------------
-- Starting eBill Transmission Details Loop.
----------------------------------------------------------------------------
            gc_error_code := 'LOOP3';

            FOR lcu_get_ebill_trans IN (SELECT *
                                          FROM xx_cdh_ebl_transmission_dtl
                                         WHERE cust_doc_id = p_cust_doc_id)
            LOOP
               gc_insert_fun_status :=
                  validate_ebl_transmission
                         (p_cust_doc_id,
                          lc_ebill_transmission_type    -- p_transmission_type
                                                    ,
                          lcu_get_ebill_trans.email_subject,
                          lcu_get_ebill_trans.email_std_message,
                          lcu_get_ebill_trans.email_custom_message,
                          lcu_get_ebill_trans.email_std_disclaimer,
                          lcu_get_ebill_trans.email_signature,
                          lcu_get_ebill_trans.email_logo_required,
                          lcu_get_ebill_trans.email_logo_file_name,
                          lcu_get_ebill_trans.ftp_direction,
                          lcu_get_ebill_trans.ftp_transfer_type,
                          lcu_get_ebill_trans.ftp_destination_site,
                          lcu_get_ebill_trans.ftp_destination_folder,
                          lcu_get_ebill_trans.ftp_user_name,
                          lcu_get_ebill_trans.ftp_password,
                          lcu_get_ebill_trans.ftp_pickup_server,
                          lcu_get_ebill_trans.ftp_pickup_folder,
                          lcu_get_ebill_trans.ftp_cust_contact_name,
                          lcu_get_ebill_trans.ftp_cust_contact_email,
                          lcu_get_ebill_trans.ftp_cust_contact_phone,
                          lcu_get_ebill_trans.ftp_notify_customer,
                          lcu_get_ebill_trans.ftp_cc_emails,
                          lcu_get_ebill_trans.ftp_email_sub,
                          lcu_get_ebill_trans.ftp_email_content,
                          lcu_get_ebill_trans.ftp_send_zero_byte_file,
                          lcu_get_ebill_trans.ftp_zero_byte_file_text,
                          lcu_get_ebill_trans.ftp_zero_byte_notification_txt,
                          lcu_get_ebill_trans.cd_file_location,
                          lcu_get_ebill_trans.cd_send_to_address,
                          lcu_get_ebill_trans.comments,
                          lcu_get_ebill_trans.attribute1,
                          lcu_get_ebill_trans.attribute2,
                          lcu_get_ebill_trans.attribute3,
                          lcu_get_ebill_trans.attribute4,
                          lcu_get_ebill_trans.attribute5,
                          lcu_get_ebill_trans.attribute6,
                          lcu_get_ebill_trans.attribute7,
                          lcu_get_ebill_trans.attribute8,
                          lcu_get_ebill_trans.attribute9,
                          lcu_get_ebill_trans.attribute10,
                          lcu_get_ebill_trans.attribute11,
                          lcu_get_ebill_trans.attribute12,
                          lcu_get_ebill_trans.attribute13,
                          lcu_get_ebill_trans.attribute14,
                          lcu_get_ebill_trans.attribute15,
                          lcu_get_ebill_trans.attribute16,
                          lcu_get_ebill_trans.attribute17,
                          lcu_get_ebill_trans.attribute18,
                          lcu_get_ebill_trans.attribute19,
                          lcu_get_ebill_trans.attribute20
                         );

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  lc_return_status := gc_insert_fun_status;
               ELSIF gc_insert_fun_status <> 'TRUE'
               THEN
                  RAISE le_other_proc_error;
               END IF;
            END LOOP;

-- End of eBill Transmission Details Loop.
----------------------------------------------------------------------------
-- Starting eBill Contacts Details Loop.
----------------------------------------------------------------------------
            gc_error_code := 'SELECT4';

            SELECT COUNT (1)
              INTO lc_rec_count
              FROM xx_cdh_ebl_contacts
             WHERE cust_doc_id = p_cust_doc_id;

            IF lc_rec_count > 0 AND lc_ebill_transmission_type <> 'EMAIL'
            THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_058'
-- ERROR_MESSAGE = ''
-- Contacts should be defined only if Transmission Type = 'EMAIL' else no Contacts.
--
----------------------------------------------------------------------------
               gc_error_code := 'XXOD_EBL_058';
               gc_error_message := '';
               gc_validation_status := 'FALSE';
            ELSIF lc_rec_count = 0 AND lc_ebill_transmission_type = 'EMAIL'
            THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_059'
-- ERROR_MESSAGE = ''
-- Contacts should be defined only if Transmission Type = 'EMAIL' else no Contacts.
--
----------------------------------------------------------------------------
               gc_error_code := 'XXOD_EBL_059';
               gc_error_message := '';
               gc_validation_status := 'FALSE';
            END IF;

            IF gc_validation_status = 'FALSE'
            THEN
               gc_insert_fun_status :=
                  insert_ebl_error (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
               lc_return_status := 'FALSE';
               gc_validation_status := 'TRUE';

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  RAISE gex_error_table_error;
               END IF;
            END IF;

            gc_error_code := 'LOOP4';

            FOR lcu_get_ebill_contact IN (SELECT *
                                            FROM xx_cdh_ebl_contacts
                                           WHERE cust_doc_id = p_cust_doc_id)
            LOOP
               gc_insert_fun_status :=
                  validate_ebl_contacts
                           (lcu_get_doc.cust_account_id   -- p_cust_account_id
                                                       ,
                            lc_ebill_transmission_type  -- p_transmission_type
                                                      ,
                            lcu_get_doc.c_ext_attr2            -- p_paydoc_ind
                                                   ,
                            lcu_get_ebill_contact.ebl_doc_contact_id,
                            p_cust_doc_id,
                            lcu_get_ebill_contact.org_contact_id,
                            lcu_get_ebill_contact.cust_acct_site_id,
                            lcu_get_ebill_contact.attribute1,
                            lcu_get_ebill_contact.attribute2,
                            lcu_get_ebill_contact.attribute3,
                            lcu_get_ebill_contact.attribute4,
                            lcu_get_ebill_contact.attribute5,
                            lcu_get_ebill_contact.attribute6,
                            lcu_get_ebill_contact.attribute7,
                            lcu_get_ebill_contact.attribute8,
                            lcu_get_ebill_contact.attribute9,
                            lcu_get_ebill_contact.attribute10,
                            lcu_get_ebill_contact.attribute11,
                            lcu_get_ebill_contact.attribute12,
                            lcu_get_ebill_contact.attribute13,
                            lcu_get_ebill_contact.attribute14,
                            lcu_get_ebill_contact.attribute15,
                            lcu_get_ebill_contact.attribute16,
                            lcu_get_ebill_contact.attribute17,
                            lcu_get_ebill_contact.attribute18,
                            lcu_get_ebill_contact.attribute19,
                            lcu_get_ebill_contact.attribute20
                           );

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  lc_return_status := gc_insert_fun_status;
               ELSIF gc_insert_fun_status <> 'TRUE'
               THEN
                  RAISE le_other_proc_error;
               END IF;
            END LOOP;

-- End of eBill Contacts Details Loop.
----------------------------------------------------------------------------
-- Starting eBill File Naming Details.
----------------------------------------------------------------------------
            gc_error_code := 'LOOP5';

            FOR lcu_get_ebill_file_details IN (SELECT *
                                                 FROM xx_cdh_ebl_file_name_dtl
                                                WHERE cust_doc_id =
                                                                 p_cust_doc_id)
            LOOP
               gc_error_code := 'SELECT5';

               SELECT COUNT (1)
                 INTO lc_rec_count
                 FROM xx_cdh_ebl_file_name_dtl
                WHERE cust_doc_id = p_cust_doc_id
                  AND field_id = (SELECT field_id
                                    FROM xx_cdh_ebilling_fields_v
                                   WHERE field_name = 'Sequence');

               IF lc_rec_count > 1
               THEN
----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_060'
-- ERROR_MESSAGE = ''
-- File_Naming table should contain only one Sequence number.
--
----------------------------------------------------------------------------
                  gc_error_code := 'XXOD_EBL_060';
                  gc_error_message := '';
                  gc_insert_fun_status :=
                     insert_ebl_error
                                   (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
                  lc_return_status := 'FALSE';

                  IF gc_insert_fun_status = 'FALSE'
                  THEN
                     RAISE gex_error_table_error;
                  END IF;
               END IF;

               gc_insert_fun_status :=
                  validate_ebl_file_name
                              (lcu_get_ebill_file_details.ebl_file_name_id,
                               p_cust_doc_id,
                               lcu_get_ebill_file_details.file_name_order_seq,
                               lcu_get_ebill_file_details.field_id,
                               lcu_get_ebill_file_details.constant_value,
                               lcu_get_ebill_file_details.default_if_null,
                               lcu_get_ebill_file_details.comments,
                               lc_file_name_seq_reset,
                               ln_file_next_seq_number,
                               ld_file_seq_reset_date,
                               ln_file_name_max_seq_number,
                               lcu_get_ebill_file_details.attribute1,
                               lcu_get_ebill_file_details.attribute2,
                               lcu_get_ebill_file_details.attribute3,
                               lcu_get_ebill_file_details.attribute4,
                               lcu_get_ebill_file_details.attribute5,
                               lcu_get_ebill_file_details.attribute6,
                               lcu_get_ebill_file_details.attribute7,
                               lcu_get_ebill_file_details.attribute8,
                               lcu_get_ebill_file_details.attribute9,
                               lcu_get_ebill_file_details.attribute10,
                               lcu_get_ebill_file_details.attribute11,
                               lcu_get_ebill_file_details.attribute12,
                               lcu_get_ebill_file_details.attribute13,
                               lcu_get_ebill_file_details.attribute14,
                               lcu_get_ebill_file_details.attribute15,
                               lcu_get_ebill_file_details.attribute16,
                               lcu_get_ebill_file_details.attribute17,
                               lcu_get_ebill_file_details.attribute18,
                               lcu_get_ebill_file_details.attribute19,
                               lcu_get_ebill_file_details.attribute20
                              );

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  lc_return_status := gc_insert_fun_status;
               ELSIF gc_insert_fun_status <> 'TRUE'
               THEN
                  RAISE le_other_proc_error;
               END IF;
            END LOOP;

-- End of eBill File Naming Details.
----------------------------------------------------------------------------
-- Starting eBill Conf Header Details.
----------------------------------------------------------------------------
            gc_error_code := 'LOOP6';

            FOR lcu_get_ebill_conf_hdr IN (SELECT *
                                             FROM xx_cdh_ebl_templ_header
                                            WHERE cust_doc_id = p_cust_doc_id)
            LOOP
               lc_ebill_file_creation_type :=
                              lcu_get_ebill_conf_hdr.ebill_file_creation_type;
               gc_insert_fun_status :=
                  validate_ebl_templ_header
                            (p_cust_account_id,
                             p_cust_doc_id,
                             lcu_get_ebill_conf_hdr.ebill_file_creation_type,
                             lcu_get_ebill_conf_hdr.delimiter_char,
                             lcu_get_ebill_conf_hdr.line_feed_style,
                             lcu_get_ebill_conf_hdr.include_header,
                             lcu_get_ebill_conf_hdr.logo_file_name,
                             lcu_get_ebill_conf_hdr.file_split_criteria,
                             lcu_get_ebill_conf_hdr.file_split_value,
                             lcu_get_ebill_conf_hdr.attribute1,
                             lcu_get_ebill_conf_hdr.attribute2,
                             lcu_get_ebill_conf_hdr.attribute3,
                             lcu_get_ebill_conf_hdr.attribute4,
                             lcu_get_ebill_conf_hdr.attribute5,
                             lcu_get_ebill_conf_hdr.attribute6,
                             lcu_get_ebill_conf_hdr.attribute7,
                             lcu_get_ebill_conf_hdr.attribute8,
                             lcu_get_ebill_conf_hdr.attribute9,
                             lcu_get_ebill_conf_hdr.attribute10,
                             lcu_get_ebill_conf_hdr.attribute11,
                             lcu_get_ebill_conf_hdr.attribute12,
                             lcu_get_ebill_conf_hdr.attribute13,
                             lcu_get_ebill_conf_hdr.attribute14,
                             lcu_get_ebill_conf_hdr.attribute15,
                             lcu_get_ebill_conf_hdr.attribute16,
                             lcu_get_ebill_conf_hdr.attribute17,
                             lcu_get_ebill_conf_hdr.attribute18,
                             lcu_get_ebill_conf_hdr.attribute19,
                             lcu_get_ebill_conf_hdr.attribute20
                            );

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  lc_return_status := gc_insert_fun_status;
               ELSIF gc_insert_fun_status <> 'TRUE'
               THEN
                  RAISE le_other_proc_error;
               END IF;
            END LOOP;

-- End of eBill Conf Header Details.
----------------------------------------------------------------------------
-- Starting eBill Conf Details.
----------------------------------------------------------------------------
            gc_error_code := 'LOOP7';

            FOR lcu_get_ebill_conf_dtl IN (SELECT *
                                             FROM xx_cdh_ebl_templ_dtl
                                            WHERE cust_doc_id = p_cust_doc_id)
            LOOP
               gc_insert_fun_status :=
                  validate_ebl_templ_dtl
                                     (p_cust_account_id,
                                      lc_ebill_file_creation_type
                                                                 -- p_ebill_file_creation_type
                  ,
                                      lcu_get_ebill_conf_dtl.ebl_templ_id,
                                      lcu_get_ebill_conf_dtl.cust_doc_id,
                                      lcu_get_ebill_conf_dtl.record_type,
                                      lcu_get_ebill_conf_dtl.seq,
                                      lcu_get_ebill_conf_dtl.field_id,
                                      lcu_get_ebill_conf_dtl.label,
                                      lcu_get_ebill_conf_dtl.start_pos,
                                      lcu_get_ebill_conf_dtl.field_len,
                                      lcu_get_ebill_conf_dtl.data_format,
                                      lcu_get_ebill_conf_dtl.string_fun,
                                      lcu_get_ebill_conf_dtl.sort_order,
                                      lcu_get_ebill_conf_dtl.sort_type,
                                      lcu_get_ebill_conf_dtl.mandatory,
                                      lcu_get_ebill_conf_dtl.seq_start_val,
                                      lcu_get_ebill_conf_dtl.seq_inc_val,
                                      lcu_get_ebill_conf_dtl.seq_reset_field,
                                      lcu_get_ebill_conf_dtl.constant_value,
                                      lcu_get_ebill_conf_dtl.alignment,
                                      lcu_get_ebill_conf_dtl.padding_char,
                                      lcu_get_ebill_conf_dtl.default_if_null,
                                      lcu_get_ebill_conf_dtl.comments,
                                      lcu_get_ebill_conf_dtl.attribute1,
                                      lcu_get_ebill_conf_dtl.attribute2,
                                      lcu_get_ebill_conf_dtl.attribute3,
                                      lcu_get_ebill_conf_dtl.attribute4,
                                      lcu_get_ebill_conf_dtl.attribute5,
                                      lcu_get_ebill_conf_dtl.attribute6,
                                      lcu_get_ebill_conf_dtl.attribute7,
                                      lcu_get_ebill_conf_dtl.attribute8,
                                      lcu_get_ebill_conf_dtl.attribute9,
                                      lcu_get_ebill_conf_dtl.attribute10,
                                      lcu_get_ebill_conf_dtl.attribute11,
                                      lcu_get_ebill_conf_dtl.attribute12,
                                      lcu_get_ebill_conf_dtl.attribute13,
                                      lcu_get_ebill_conf_dtl.attribute14,
                                      lcu_get_ebill_conf_dtl.attribute15,
                                      lcu_get_ebill_conf_dtl.attribute16,
                                      lcu_get_ebill_conf_dtl.attribute17,
                                      lcu_get_ebill_conf_dtl.attribute18,
                                      lcu_get_ebill_conf_dtl.attribute19,
                                      lcu_get_ebill_conf_dtl.attribute20
                                     );

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  lc_return_status := gc_insert_fun_status;
               ELSIF gc_insert_fun_status <> 'TRUE'
               THEN
                  RAISE le_other_proc_error;
               END IF;
            END LOOP;

-- End of eBill Conf Details.
----------------------------------------------------------------------------
-- Starting eBill Sub Total Details.
----------------------------------------------------------------------------
            gc_error_code := 'LOOP8';

            FOR lcu_get_ebill_sub_tot IN (SELECT *
                                            FROM xx_cdh_ebl_std_aggr_dtl
                                           WHERE cust_doc_id = p_cust_doc_id)
            LOOP
               gc_insert_fun_status :=
                  validate_ebl_std_aggr_dtl
                                      (lcu_get_ebill_sub_tot.ebl_aggr_id,
                                       lcu_get_ebill_sub_tot.cust_doc_id,
                                       lcu_get_ebill_sub_tot.aggr_fun,
                                       lcu_get_ebill_sub_tot.aggr_field_id,
                                       lcu_get_ebill_sub_tot.change_field_id,
                                       lcu_get_ebill_sub_tot.label_on_file,
                                       lcu_get_ebill_sub_tot.attribute1,
                                       lcu_get_ebill_sub_tot.attribute2,
                                       lcu_get_ebill_sub_tot.attribute3,
                                       lcu_get_ebill_sub_tot.attribute4,
                                       lcu_get_ebill_sub_tot.attribute5,
                                       lcu_get_ebill_sub_tot.attribute6,
                                       lcu_get_ebill_sub_tot.attribute7,
                                       lcu_get_ebill_sub_tot.attribute8,
                                       lcu_get_ebill_sub_tot.attribute9,
                                       lcu_get_ebill_sub_tot.attribute10,
                                       lcu_get_ebill_sub_tot.attribute11,
                                       lcu_get_ebill_sub_tot.attribute12,
                                       lcu_get_ebill_sub_tot.attribute13,
                                       lcu_get_ebill_sub_tot.attribute14,
                                       lcu_get_ebill_sub_tot.attribute15,
                                       lcu_get_ebill_sub_tot.attribute16,
                                       lcu_get_ebill_sub_tot.attribute17,
                                       lcu_get_ebill_sub_tot.attribute18,
                                       lcu_get_ebill_sub_tot.attribute19,
                                       lcu_get_ebill_sub_tot.attribute20
                                      );

               IF gc_insert_fun_status = 'FALSE'
               THEN
                  lc_return_status := gc_insert_fun_status;
               ELSIF gc_insert_fun_status <> 'TRUE'
               THEN
                  RAISE le_other_proc_error;
               END IF;
            END LOOP;
         -- End of eBill Sub Total Details.
         END IF;

         IF p_change_status = 'COMPLETE' AND lc_return_status = 'TRUE'
         THEN
            DECLARE
               x_process_flag          NUMBER;
               x_cust_doc_id           NUMBER;
               x_cust_doc_id1          NUMBER;
               lc_pay_term             VARCHAR2 (100);
               ld_doc_req_start_date   DATE;
               ld_doc_next_run_date    DATE;
            BEGIN
               lc_pay_term := lcu_get_doc.c_ext_attr14;
               ld_doc_req_start_date :=
                          GREATEST (lcu_get_doc.d_ext_attr9, TRUNC (SYSDATE));

               IF lcu_get_doc.c_ext_attr2 = 'Y'
               THEN
                  xx_cdh_cust_acct_ext_w_pkg.complete_cust_doc
                           (lcu_get_doc.n_ext_attr2               -- ln_doc_id
                                                   ,
                            lcu_get_doc.cust_account_id  -- ln_cust_account_id
                                                       ,
                            lc_pay_term                         -- lc_pay_term
                                       ,
                            lcu_get_doc.c_ext_attr1             -- lc_doc_type
                                                   ,
                            lcu_get_doc.c_ext_attr7             -- lc_dir_flag
                                                   ,
                            ld_doc_req_start_date                 -- ld_req_dt
                                                 ,
                            lcu_get_doc.c_ext_attr13               -- lc_combo
                                                    ,
                            'Y',
                            x_process_flag                      -- lx_prc_flag
                                          ,
                            x_cust_doc_id                      -- lx_cust_doc1
                                         ,
                            x_cust_doc_id1                     -- lx_cust_doc2
                           );

                  IF x_cust_doc_id1 < 0
                  THEN
                     gc_error_code := 'XXOD_EBL_082';
                     gc_insert_fun_status :=
                        insert_ebl_error
                                   (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
                     ROLLBACK;
                     lc_return_status := 'FALSE';

                     IF gc_insert_fun_status = 'FALSE'
                     THEN
                        RAISE gex_error_table_error;
                     END IF;
                  END IF;
               ELSE
----------------------------------------------------------------------------
-- To get the Billing Cycle Date.
----------------------------------------------------------------------------
                  ld_doc_next_run_date :=
                     xx_ar_inv_freq_pkg.compute_effective_date
                                                       (lc_pay_term,
                                                        ld_doc_req_start_date
                                                       );
                  ld_doc_next_run_date := ld_doc_next_run_date + 1;
----------------------------------------------------------------------------
-- To validate Pay Doc Validation.
----------------------------------------------------------------------------
                  gc_error_code := 'PAY_TERM';

                  SELECT ego.c_ext_attr14 payment_term,
                         n_ext_attr2 billdocs_cust_doc_id
                    INTO lc_paydoc_payment_term,
                         x_cust_doc_id
                    FROM xx_cdh_cust_acct_ext_b ego
                   WHERE ego.cust_account_id = lcu_get_doc.cust_account_id
                     AND TRUNC (ld_doc_next_run_date) BETWEEN d_ext_attr1
                                                          AND NVL
                                                                (d_ext_attr2,
                                                                 TRUNC
                                                                    (ld_doc_next_run_date
                                                                    )
                                                                )
                     AND c_ext_attr2 = 'Y'              -- BILLDOCS_PAYDOC_IND
                     AND ego.attr_group_id =
                            (SELECT attr_group_id
                               FROM ego_attr_groups_v
                              WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
                                AND attr_group_name = 'BILLDOCS')       -- 166
                     AND ROWNUM < 2;              -- To Handel COMBO Documents

----------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_061'
-- ERROR_MESSAGE = ''
-- Payment Term on Info Document should match with Payment Term on PayDocument.
--
----------------------------------------------------------------------------
                  gc_error_code := 'XXOD_EBL_061';

                  IF     lc_paydoc_payment_term <> lcu_get_doc.c_ext_attr14
                     AND SUBSTR (lc_paydoc_payment_term, 0, 2) <> 'DL'
                  THEN
                     gc_error_message :=
                           'Pay Doc:'
                        || x_cust_doc_id
                        || '. Pay Doc Term: '
                        || lc_paydoc_payment_term
                        || '. Info Doc Term: '
                        || lcu_get_doc.c_ext_attr14;
                     gc_insert_fun_status :=
                        insert_ebl_error
                                    (p_cust_doc_id,
                                     gc_doc_process_date -- p_doc_process_date
                                                        ,
                                     gc_error_code             -- p_error_code
                                                  ,
                                     gc_error_message          -- p_error_desc
                                    );
                     lc_return_status := 'FALSE';

                     IF gc_insert_fun_status = 'FALSE'
                     THEN
                        RAISE gex_error_table_error;
                     END IF;
                  END IF;

                  IF lc_return_status <> 'FALSE'
                  THEN
                     UPDATE xx_cdh_cust_acct_ext_b
                        SET c_ext_attr16 = 'COMPLETE',
                            d_ext_attr1 = TRUNC (ld_doc_next_run_date)
                      -- Start Date
                     WHERE  cust_account_id = lcu_get_doc.cust_account_id
                        AND n_ext_attr2 = lcu_get_doc.n_ext_attr2;
                  END IF;
               END IF;

               IF lcu_get_doc.c_ext_attr3 = 'eXLS'
               THEN
                  DELETE FROM xx_cdh_ebl_templ_dtl templ
                        WHERE templ.cust_doc_id = lcu_get_doc.n_ext_attr2
                          AND templ.attribute1 != 'Y';
               END IF;

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
-------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_001'
-- ERROR_MESSAGE = ''
--
-------------------------------------------------------------------------
                  gc_error_message :=
                        'Exception occurred in XX_CDH_CUST_ACCT_EXT_W_PKG.COMPLETE_CUST_DOC. '
                     || gc_error_code
                     || '. SQLCODE - '
                     || SQLCODE
                     || ' SQLERRM - '
                     || SUBSTR (SQLERRM, 1, 3000);
                  gc_error_code := 'XXOD_EBL_001';
                  gc_insert_fun_status :=
                     insert_ebl_error
                                    (p_cust_doc_id,
                                     gc_doc_process_date -- p_doc_process_date
                                                        ,
                                     gc_error_code             -- p_error_code
                                                  ,
                                     gc_error_message          -- p_error_desc
                                    );

                  IF gc_insert_fun_status = 'FALSE'
                  THEN
                     lc_return_status :=
                           'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
                        || gc_error_code
                        || ' - '
                        || gc_error_message
                        || ' - '
                        || fnd_message.get_string ('XXCRM', gc_error_code);
                  ELSE
                     lc_return_status := 'FALSE - EBL-001';
                  END IF;

                  gc_error_message := '';
                  RETURN lc_return_status;
            END;
         END IF;
      END LOOP;

      -- End of Customer Document Loop.
      RETURN lc_return_status;
----------------------------------------------------------------------------
-- VALIDATE_FINAL - Exception Block starts.
----------------------------------------------------------------------------
   EXCEPTION
      WHEN gex_error_table_error
      THEN
         gc_error_message :=
               'Customer Document Id: '
            || p_cust_doc_id
            || ' and Exception occurred in VALIDATE_FINAL';
         lc_return_status :=
               'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
            || gc_error_message
            || ' - '
            || gc_error_code
            || ' - '
            || fnd_message.get_string ('XXCRM', gc_error_code);
         RETURN lc_return_status;
      WHEN le_other_proc_error
      THEN
         IF gc_insert_fun_status = 'FALSE - EBL-001'
         THEN
            lc_return_status := 'FALSE - EBL-001';
         ELSE
            lc_return_status :=
                  'FALSE - Error in VALIDATE_FINAL procedure. - '
               || gc_insert_fun_status;
         END IF;

         RETURN lc_return_status;
      WHEN OTHERS
      THEN
-------------------------------------------------------------------------
--
-- ERROR_CODE = 'XXOD_EBL_001'
-- ERROR_MESSAGE = ''
--
-------------------------------------------------------------------------
         gc_error_message :=
               'Exception occurred in VALIDATE_FINAL. While processing/validating '
            || gc_error_code
            || '. SQLCODE - '
            || SQLCODE
            || ' SQLERRM - '
            || SUBSTR (SQLERRM, 1, 3000);
         gc_error_code := 'XXOD_EBL_001';
         gc_insert_fun_status :=
            insert_ebl_error (p_cust_doc_id,
                              gc_doc_process_date        -- p_doc_process_date
                                                 ,
                              gc_error_code                    -- p_error_code
                                           ,
                              gc_error_message                 -- p_error_desc
                             );

         IF gc_insert_fun_status = 'FALSE'
         THEN
            lc_return_status :=
                  'FALSE - Error while inserting into Error table. Error_Code and Error_Message - '
               || gc_error_code
               || ' - '
               || gc_error_message
               || ' - '
               || fnd_message.get_string ('XXCRM', gc_error_code);
         ELSE
            lc_return_status := 'FALSE - EBL-001';
         END IF;

         gc_error_message := '';
         RETURN lc_return_status;
   END validate_final;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : INSERT_EBL_ERROR                                            |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function is used to INSERT data into error table (XX_CDH_EBL_ERROR), |
-- | when validation program comes across an error.                            |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |         lc_insert_fun_status :=
-- |             XX_CDH_EBL_VALIDATE_PKG.INSERT_EBL_ERROR (
-- |                1234       -- p_cust_doc_id
-- |              , SYSDATE    -- p_doc_process_date
-- |              , 'XXOD_EBL_001'  -- p_error_code
-- |              , NULL       -- p_error_desc
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
-- |select * from XX_CDH_EBL_ERROR
-- |WHERE  CUST_DOC_ID = 1234; -- p_cust_doc_id
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   FUNCTION insert_ebl_error (
      p_cust_doc_id        IN   NUMBER,
      p_doc_process_date   IN   DATE,
      p_error_code         IN   VARCHAR2,
      p_error_desc         IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      l_error_message   VARCHAR2 (4000);
   BEGIN
----------------------------------------------------------------------------
-- Begining of INSERT_EBL_ERROR package body.
----------------------------------------------------------------------------
      gc_insert_fun_status := 'TRUE';
      l_error_message :=
         CASE
            WHEN p_error_desc IS NULL
               THEN fnd_message.get_string ('XXCRM', p_error_code)
            ELSE    p_error_desc
                 || ' - '
                 || fnd_message.get_string ('XXCRM', p_error_code)
         END;

      INSERT INTO xx_cdh_ebl_error
                  (cust_doc_id, doc_process_date, ERROR_CODE,
                   error_desc
                  )
           VALUES (p_cust_doc_id, p_doc_process_date, p_error_code,
                   l_error_message
                  );

      COMMIT;
      RETURN gc_insert_fun_status;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         gc_insert_fun_status := 'FALSE';
         RETURN gc_insert_fun_status;
   END insert_ebl_error;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : DELETE_EBL_ERROR                                            |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedue is used to DELETE data into error table (XX_CDH_EBL_ERROR). |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
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
-- |             XX_CDH_EBL_VALIDATE_PKG.DELETE_EBL_ERROR(
-- |                p_cust_doc_id
-- |            );
-- |
-- |   DBMS_OUTPUT.PUT_LINE ('All previously INSERTED records for Document: ' || p_cust_doc_id
-- |                      || ' are deteted from Error Table.');
-- |   DBMS_OUTPUT.PUT_LINE ('No Errors');
-- |
-- |EXCEPTION
-- |   WHEN OTHERS THEN
-- |      DBMS_OUTPUT.PUT_LINE ('SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000));
-- |
-- |END;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE delete_ebl_error (p_cust_doc_id IN NUMBER)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
----------------------------------------------------------------------------
-- Begining of DELETE_EBL_ERROR package body.
----------------------------------------------------------------------------
      DELETE FROM xx_cdh_ebl_error
            WHERE cust_doc_id = p_cust_doc_id;

      COMMIT;
   END delete_ebl_error;
   
END xx_cdh_ebl_validate_pkg;
/

SHOW ERROR;
