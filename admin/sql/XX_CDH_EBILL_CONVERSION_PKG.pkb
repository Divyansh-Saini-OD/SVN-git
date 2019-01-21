PROMPT Creating Package Body XX_CDH_EBILL_CONVERSION_PKG
PROMPT Program exits if the creation is not successful

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_CDH_EBILL_CONVERSION_PKG
AS
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name        : XX_CDH_EBILL_CONVERSION_PKG                                |
-- |                                                                          |
-- | Description : This Package is used to update the customer account id     |
-- |               and customer doc id in the summary table and it also       |
-- |               inserts the records in tables for :                        |
-- |                  1)Ebilling Customer Document.                           |
-- |                  2)Ebilling Contacts.                                    |
-- |                  3)Ebilling File Name Parameter.                         |
-- |               It also inserts the Mail to Attention in EGO table.        |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date            Author         Remarks                          |
-- |=======   ==========    =============    =================================|
-- |1.0       29-MAR-10     Navin Agarwal    Initial version                  |
-- |1.1       16-Jul-10     Srini            Add clearing_days while updating |
-- |                                         Document Summary table.          |
-- |1.2       09-AUG-10     Param            Added lpad for ORG_ID and        |
-- |                                         attribute2  for getting the      |
-- |                                         cust acc ID for defect # 7167    |
-- |1.3       22-OCT-15     Manikant Kasu    Removed schema alias as part of  |
-- |                                         GSCC R12.2.2 Retrofit            |
-- |                                                                          |
-- +==========================================================================+

   PROCEDURE XX_EBILL_CONVERSION_MASTER(
                      x_error_buff              OUT      VARCHAR2
                     ,x_ret_code                OUT      NUMBER
                     ,p_cust_doc_sum_id         IN       NUMBER
                     ,p_file_name_parmt_sum_id  IN       NUMBER
                     ,p_contacts_sum_id         IN       NUMBER
                     ,p_Activate_Bulk_Batch     IN       NUMBER
                                       )
   IS
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name        : XX_EBILL_CONVERSION_MASTER                                 |
-- |                                                                          |
-- | Description : This procedure is used to call the other three             |
-- |               procedures, which will do the required conversion.         |
-- |                                                                          |
-- |                                                                          |
-- | Program Name: OD: CDH eBill Customer Document Conversion.                |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date            Author              Remarks                     |
-- |=======   ==========    =============        =============================|
-- |1.0       29-MAR-10      Navin Agarwal       Initial version              |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

      lc_error_message            VARCHAR2(4000)   DEFAULT NULL;
      lc_ret_code                 VARCHAR2(100);

   BEGIN
      x_ret_code := 0;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'***********************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Running eBill Conversion for  Cust Document Procedure Having Summary Id: '||p_cust_doc_sum_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Running eBill Conversion for  File Naming Parameters Procedure Having Summary Id: '||p_file_name_parmt_sum_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Running eBill Conversion for  Contact Procedure Having Summary Id: '||p_contacts_sum_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Bulk Batch: '||p_Activate_Bulk_Batch);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'***********************************************************************************************');

-- ----------------------------------------------------------------------------
--  Calling a procedure to import Document date from file to XX_CDH_EBL tables.
-- ----------------------------------------------------------------------------

      IF p_cust_doc_sum_id IS NOT NULL THEN
      
         lc_error_message := 'EBILL CUST DOCUMENT PROCEDURE';

         -- Calling Ebilling Customer Document Procedure.
         xx_ebill_cust_doc_prc(p_cust_doc_sum_id
                              ,p_file_name_parmt_sum_id
                              ,p_contacts_sum_id
                              ,lc_ret_code);

         IF lc_ret_code <> 0 THEN
            x_ret_code := lc_ret_code;
            x_error_buff := 'See log file for more details ...';
         END IF;

      ELSE

         lc_ret_code := 0;
      END IF;

      IF lc_ret_code <> 2 THEN

-- ----------------------------------------------------------------------------
--  Calling a procedure to import File Naming date from file to XX_CDH_EBL tables.
-- ----------------------------------------------------------------------------

         IF p_file_name_parmt_sum_id IS NOT NULL THEN

            lc_error_message := 'EBILL FILE NAME PARAMETER';

           -- Calling Ebilling File Name Parameter Procedure.
            xx_ebill_file_name_parmt_prc(
                          p_file_name_parmt_sum_id
                         ,lc_ret_code);

         END IF; 
         
         IF lc_ret_code <> 0 THEN
            x_ret_code := lc_ret_code;
            x_error_buff := 'See log file for more details ...';
         END IF;

-- ----------------------------------------------------------------------------
-- Calling a procedure to import Contact date for a Document from file to XX_CDH_EBL tables.
-- And also the same procedure will call Conversion programs to import contacts 
-- into Oracle STD tables.
-- ----------------------------------------------------------------------------

         IF p_contacts_sum_id IS NOT NULL THEN

            lc_error_message := 'EBILL CONTACTS PROCEDURE';

           -- Calling Ebilling Contacts Procedure.
            xx_ebill_contacts_prc(
                           p_contacts_sum_id
                          ,p_Activate_Bulk_Batch
                          ,lc_ret_code);

         END IF;

         IF lc_ret_code <> 0 THEN
            x_ret_code := lc_ret_code;
            x_error_buff := 'See log file for more details ...';
         END IF;


      ELSE
         x_error_buff := 'Error while processing data. See log file for more details ...';
         x_ret_code := lc_ret_code;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while processing eBill Conversion data for Cust Document Procedure.');
      END IF;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'***********************************************************************************************');

   EXCEPTION
      WHEN OTHERS THEN
         lc_error_message := 'Error - Unhandled exception package XX_CDH_EBILL_CONVERSION_PKG.XX_EBILL_CONVERSION_MASTER.'
                           ||' while calling procedure :' || lc_error_message 
                           ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

         x_ret_code   := 2;
         x_error_buff := 'See log file for more details ...';

   END XX_EBILL_CONVERSION_MASTER;


   PROCEDURE XX_EBILL_CUST_DOC_PRC(
                        p_cust_doc_sum_id         IN       NUMBER
                       ,p_file_name_parmt_sum_id  IN       NUMBER
                       ,p_contacts_sum_id         IN       NUMBER
                       ,x_ret_code                IN OUT   NUMBER
                                  )
   IS
   
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name        : XX_EBILL_CUST_DOC_PRC                                      |
-- |                                                                          |
-- | Description : This procedure is used to update the customer              |
-- |               accountid and customer doc id in the summary               |
-- |               table and is also inserts the records in three             |
-- |               corresponding table for ebilling customer document.        |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date            Author              Remarks                     |
-- |=======   ==========    =============        =============================|
-- |1.0       29-MAR-10      Navin Agarwal       Initial version              |
-- |1.1       09-AUG-10      Param               Added lpad for ORG_ID for    |
-- |                                             getting the cust acc ID for  |
-- |                                             defect # 7167                |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+
      
      CURSOR lcu_summary_table
      IS
      SELECT *
        FROM xxod_hz_summary 
       WHERE summary_id = p_cust_doc_sum_id    -- 767677
         AND insert_update_flag = 0;
         
      ln_counter                  NUMBER         DEFAULT 0;
      ln_cust_acc_id              NUMBER;
      ln_cust_doc_id              NUMBER;
      ln_extension_id             NUMBER;
      ln_attr_group_id            NUMBER;
      ln_term_id                  NUMBER;
      ln_orig_system_reference    VARCHAR2(20);
      lc_payment_term             VARCHAR2(150);
      lc_x_rowid                  VARCHAR2(50);
      lc_error_message            VARCHAR2(4000) DEFAULT NULL;
      summary_table_rec_type      xxod_hz_summary%ROWTYPE;


   BEGIN
   
      FND_FILE.PUT_LINE(FND_FILE.LOG,'***********************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,' --------  Begin of XX_EBILL_CUST_DOC_PRC --------  ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' --------  Begin of XX_EBILL_CUST_DOC_PRC --------  ');
      x_ret_code := 0;
   
      OPEN lcu_summary_table;
      LOOP
         FETCH lcu_summary_table
         INTO summary_table_rec_type; 

         EXIT WHEN lcu_summary_table%NOTFOUND;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- >Processing data for AOPS# ' || summary_table_rec_type.org_id);

         BEGIN


-- ----------------------------------------------------------------------------
-- To get the Cust_Account_ID and APOS number.
-- ----------------------------------------------------------------------------
            lc_error_message := 'HZ_CUST_ACCOUNTS (Null Cust_Account_id)';
            SELECT cust_account_id,orig_system_reference                  -- TO_CHAR(summary_table_rec_type.org_id)||'-00001-A0';
               INTO ln_cust_acc_id,ln_orig_system_reference
               FROM HZ_CUST_ACCOUNTS 
               WHERE orig_system_reference = to_char(lpad((summary_table_rec_type.org_id),8,0))||'-00001-A0';  -- Added for Defect # 7167

            SELECT xx_cdh_cust_doc_id_s.NEXTVAL, ego_extfwk_s.NEXTVAL
               INTO ln_cust_doc_id, ln_extension_id
               FROM DUAL;

            lc_error_message := 'EGO_ATTR_GROUPS_V (Null attr_group_id)';
            SELECT attr_group_id
               INTO ln_attr_group_id
               FROM ego_attr_groups_v
               WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
               AND attr_group_name   = 'BILLDOCS';

            IF summary_table_rec_type.edi_payment_format IS NULL THEN

-- ----------------------------------------------------------------------------
-- To get the payment Term from existing ELEC document when its NULL in the file.
-- ----------------------------------------------------------------------------
               lc_error_message := 'XX_CDH_CUST_ACCT_EXT_B (Null Payment Term) - Cust_Acc_Id: ' || ln_cust_acc_id;
               SELECT BILLDOCS_PAYMENT_TERM
               INTO lc_payment_term 
               FROM (
                  SELECT c_ext_attr14 BILLDOCS_PAYMENT_TERM                        -- BILLDOCS_PAYMENT_TERM
                     FROM   xx_cdh_cust_acct_ext_b
                     WHERE  attr_group_id   = ln_attr_group_id
                     AND    cust_account_id = ln_cust_acc_id
                     AND    c_ext_attr2     = summary_table_rec_type.primary_flag  -- BILLDOCS_PAYDOC_IND
                     AND    c_ext_attr16    = 'COMPLETE'                           -- BILLDOCS_STATUS
                     AND    C_EXT_ATTR3     = 'ELEC'                               -- BILLDOCS_DELIVERY_METH
                     ORDER BY d_ext_attr1 DESC)                                    -- BILLDOCS_EFF_FROM_DATE
                  WHERE ROWNUM = 1;
            ELSE
               lc_payment_term := summary_table_rec_type.edi_payment_format;
            END IF;

-- ----------------------------------------------------------------------------
-- To get the Term_Id from given Payment Term.
-- ----------------------------------------------------------------------------
            lc_error_message := 'RA_TERMS - (Null Term Id) - || Payment Term: ' || lc_payment_term;
            SELECT term_id
              INTO ln_term_id
              FROM ra_terms
              WHERE name = lc_payment_term;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for Document Conversion Summary.
-- ----------------------------------------------------------------------------
            UPDATE xxod_hz_summary
               SET eft_printing_program_id = ln_cust_acc_id                   -- CUSTOMER_ACCOUNT_ID
                  ,eft_transmission_program_id = ln_cust_doc_id               -- CUSTOMER_DOCUMENT_ID
                  ,edi_payment_format = lc_payment_term                       -- PAYMENT_TERM
                  ,orig_system_reference = ln_orig_system_reference           -- ORIG_SYSTEM_REFERENCE
               WHERE org_id   = summary_table_rec_type.org_id                 -- AOPS CUSTOMER #
               AND   clearing_days = summary_table_rec_type.clearing_days     -- EBILL_DOCUMENT_ID -- Added for 1.1
               AND summary_id = p_cust_doc_sum_id;                            -- SUMMARY_ID 767677;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for Contact Conversion Summary.
-- ----------------------------------------------------------------------------
            UPDATE xxod_hz_summary
               SET eft_printing_program_id = ln_cust_acc_id                   -- CUSTOMER_ACCOUNT_ID
                  ,eft_transmission_program_id = ln_cust_doc_id               -- CUSTOMER_DOCUMENT_ID
                  ,orig_system_reference = ln_orig_system_reference           -- ORIG_SYSTEM_REFERENCE
               WHERE clearing_days = summary_table_rec_type.clearing_days     -- EBILL_DOCUMENT_ID
               AND summary_id      = p_contacts_sum_id;                       -- SUMMARY_ID 767678;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for File Naming Conversion Summary.
-- ----------------------------------------------------------------------------
            UPDATE xxod_hz_summary
               SET eft_printing_program_id = ln_cust_acc_id                   -- CUSTOMER_ACCOUNT_ID
                  ,eft_transmission_program_id = ln_cust_doc_id               -- CUSTOMER_DOCUMENT_ID
                  ,orig_system_reference = ln_orig_system_reference           -- ORIG_SYSTEM_REFERENCE
               WHERE clearing_days = summary_table_rec_type.clearing_days     -- EBILL_DOCUMENT_ID
               AND summary_id = p_file_name_parmt_sum_id;                     -- SUMMARY_ID 767679;

-- ----------------------------------------------------------------------------
-- Calling API to Insert Document data into EGO table.
-- ----------------------------------------------------------------------------
            lc_error_message := 'XX_CDH_CUST_ACCT_EXT_W_PKG.INSERT_ROW';
            XX_CDH_CUST_ACCT_EXT_W_PKG.insert_row(
                   x_rowid             => lc_x_rowid
                  ,p_n_ext_attr1       => summary_table_rec_type.obj_id                     -- MBS_Document_Id
                  ,p_c_ext_attr1       => summary_table_rec_type.type_of_financial_report   -- Invoice Type
                  ,p_c_ext_attr7       => summary_table_rec_type.branch_flag                -- Billdocs_Direct_Flag
                  ,p_c_ext_attr2       => summary_table_rec_type.primary_flag               -- Pay Doc Indicator
                  ,p_c_ext_attr3       => summary_table_rec_type.edi_remittance_method      -- Delivery Method
                  ,p_c_ext_attr14      => lc_payment_term                                   -- Payment Term
                  ,p_cust_account_id   => ln_cust_acc_id                                    -- Oracle_Cust_Account_Id
                  ,p_n_ext_attr2       => ln_cust_doc_id                                    -- New_Oracle_Cust_Doc_Id (Using Sequence)
                  ,p_extension_id      => ln_extension_id                                   -- Using Sequence
                  ,p_attr_group_id     => ln_attr_group_id                                  -- 166
                  ,p_n_ext_attr18      => ln_term_id                                        -- Billdocs_Term_ID
                  ,p_c_ext_attr16      => 'IN_PROCESS'                                      -- Billdocs_Status
                  ,p_n_ext_attr19      => 0                                                 -- Billdoc_Process_Flag
                  ,p_n_ext_attr17      => 0                                                 -- Is_Parent
                  ,p_n_ext_attr16      => 0                                                 -- Send_To_Parent
                  ,p_n_ext_attr15      => NULL                                              -- Parent_Doc_ID
                  ,p_c_ext_attr15      => NULL                                              -- Billdocs_Mail_Attention
                  ,p_d_ext_attr9       => TRUNC(SYSDATE)
                  ,p_creation_date     => SYSDATE
                  ,p_created_by        => FND_GLOBAL.USER_ID
                  ,p_last_update_date  => SYSDATE
                  ,p_last_updated_by   => FND_GLOBAL.USER_ID
                  ,p_last_update_login => FND_GLOBAL.USER_ID
                  );

-- ----------------------------------------------------------------------------
-- Calling API to Insert Document main data into Custom table (XX_CDH_EBL_MAIN).
-- ----------------------------------------------------------------------------
            lc_error_message := 'XX_CDH_EBL_MAIN_PKG.INSERT_ROW';
            XX_CDH_EBL_MAIN_PKG.insert_row(
                   p_cust_doc_id               => ln_cust_doc_id                                      -- New_Oracle_Cust_Doc_Id (Using Sequence)
                  ,p_cust_account_id           => ln_cust_acc_id                                      -- Oracle_Cust_Account_Id
                  ,p_file_processing_method    => LPAD(summary_table_rec_type.document_reference,2,0) -- File Processing Method
                  ,p_ebill_transmission_type   => summary_table_rec_type.edi_payment_method           -- Transmission Method
                  ,p_ebill_associate           => summary_table_rec_type.collector_name               -- eBill Associate
                  ,p_od_field_contact          => summary_table_rec_type.contact_orig_system          -- OD Field Contact
                  ,p_od_field_contact_email    => summary_table_rec_type.line_of_business             -- OD Field Contact Email Address
                  ,p_od_field_contact_phone    => summary_table_rec_type.phone_number                 -- OD Field Contact Telephone
                  ,p_client_tech_contact       => summary_table_rec_type.party_site_name              -- Customer Tech Contact Name
                  ,p_client_tech_contact_email => summary_table_rec_type.email_address                -- Customer Tech Contact Email
                  ,p_client_tech_contact_phone => summary_table_rec_type.contact_number               -- Customer Tech Contact Tel
                  ,p_file_name_ext             => 'PDF'
                  ,p_max_file_size             => '10'
                  ,p_max_transmission_size     => '10'
                  ,p_zip_required              => 'N'
                  ,p_zipping_utility           => NULL
                  ,p_zip_file_name_ext         => NULL
                  ,p_file_name_seq_reset       => NULL
                  ,p_file_next_seq_number      => NULL
                  ,p_file_seq_reset_date       => NULL
                  ,p_file_name_max_seq_number  => NULL
                  ,p_last_update_date          => SYSDATE
                  ,p_last_updated_by           => FND_GLOBAL.USER_ID
                  ,p_creation_date             => SYSDATE
                  ,p_created_by                => FND_GLOBAL.USER_ID
                  ,p_last_update_login         => FND_GLOBAL.USER_ID
                  );

-- ----------------------------------------------------------------------------
-- Calling API to Insert Document Transmission data into Custom table (XX_CDH_EBL_TRANSMISSION_DTL).
-- ----------------------------------------------------------------------------
            lc_error_message := 'XX_CDH_EBL_TRANS_DTL_PKG.INSERT_ROW';
            XX_CDH_EBL_TRANS_DTL_PKG.insert_row(
                   p_cust_doc_id              => ln_cust_doc_id                                    -- New_Oracle_Cust_Doc_Id (Using Sequence)
                  ,p_email_subject            => summary_table_rec_type.email_format               -- EMAIL_Subject
                  ,p_email_std_message        => summary_table_rec_type.mission_statement          -- EMAIL_Std_Message
                  ,p_email_custom_message     => summary_table_rec_type.description                -- EMAIL_Custom_Message
                  ,p_email_signature          => summary_table_rec_type.interface_entity_name      -- EMAIL_Signature
                  ,p_email_std_disclaimer     => summary_table_rec_type.spcl_evnt_txt              -- EMAIL_Std Disclaimer
                  ,p_email_logo_required      => summary_table_rec_type.jgzz_fiscal_code           -- EMAIL_Require Logo
                  ,p_email_logo_file_name     => summary_table_rec_type.party_type                 -- EMAIL_Logo Type
                  ,p_ftp_cust_contact_name    => NULL
                  ,p_ftp_cust_contact_email   => NULL
                  ,p_ftp_cust_contact_phone   => NULL
                  ,p_ftp_direction            => NULL
                  ,p_ftp_transfer_type        => NULL
                  ,p_ftp_destination_site     => NULL
                  ,p_ftp_destination_folder   => NULL
                  ,p_ftp_user_name            => NULL
                  ,p_ftp_password             => NULL
                  ,p_ftp_pickup_server        => NULL
                  ,p_ftp_pickup_folder        => NULL
                  ,p_ftp_notify_customer      => NULL
                  ,p_ftp_cc_emails            => NULL
                  ,p_ftp_email_sub            => NULL
                  ,p_ftp_email_content        => NULL
                  ,p_ftp_send_zero_byte_file  => NULL
                  ,p_ftp_zero_byte_file_text  => NULL
                  ,p_ftp_zero_byte_notifi_txt => NULL
                  ,p_cd_file_location         => NULL
                  ,p_cd_send_to_address       => NULL
                  ,p_comments                 => summary_table_rec_type.rel_comments               -- Comments
                  ,p_last_update_date         => SYSDATE
                  ,p_last_updated_by          => FND_GLOBAL.USER_ID
                  ,p_creation_date            => SYSDATE
                  ,p_created_by               => FND_GLOBAL.USER_ID
                  ,p_last_update_login        => FND_GLOBAL.USER_ID
                  );
                  
            ln_counter := ln_counter + 1;
            lc_error_message := 'SUCCESSFULLY PROCESSED';

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Processed (2).
-- ----------------------------------------------------------------------------
            UPDATE xxod_hz_summary
               SET error_text = lc_error_message
                  ,insert_update_flag = 2
               WHERE summary_id = p_cust_doc_sum_id
               AND   clearing_days = summary_table_rec_type.clearing_days     -- EBILL_DOCUMENT_ID  -- Added for 1.1
               AND org_id       = summary_table_rec_type.org_id;

            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'PROCESSED SUCCESSFULLY FOR  AOPS# : '||lpad((summary_table_rec_type.org_id),8,0) -- Added for Defect# 7167
                             ||'  CUST_DOC_ID: '||ln_cust_doc_id||'  CUST_ACC_ID: '||ln_cust_acc_id);

            COMMIT;

         EXCEPTION

            WHEN NO_DATA_FOUND THEN

               lc_error_message := 'Error - No Data Found while getting data from: '||lc_error_message||' table.'
                                ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

               ROLLBACK;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for Document Conversion record status to Error (1).
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text = lc_error_message
                     ,insert_update_flag = 1
                  WHERE summary_id = p_cust_doc_sum_id
                  AND   clearing_days = summary_table_rec_type.clearing_days     -- EBILL_DOCUMENT_ID  -- Added for 1.1
                  AND org_id       = summary_table_rec_type.org_id;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for Document Contact Conversion record status 
-- to Error (1), when parent record fails.
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text = 'Parent Program errored out. '||lc_error_message
                     ,insert_update_flag = 1
                  WHERE summary_id  = p_contacts_sum_id
                  AND clearing_days = summary_table_rec_type.clearing_days;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for Document File Naming Conversion record status 
-- to Error (1), when parent record fails.
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text = 'Parent Program errored out. '||lc_error_message
                     ,insert_update_flag = 1
                  WHERE summary_id  = p_file_name_parmt_sum_id
                  AND clearing_days = summary_table_rec_type.clearing_days;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'CONTACTS procedure and FILE NAME PARAMETER procedure will not process for EBILL_DOC_ID : '
                                              ||summary_table_rec_type.clearing_days);

               x_ret_code := 1;
               COMMIT;

            WHEN OTHERS THEN

               lc_error_message := 'Error - Unhandled exception : package XX_CDH_EBILL_CONVERSION_PKG.XX_EBILL_CUST_DOC_PRC. Table/Package ' 
                                || lc_error_message 
                                ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

               ROLLBACK;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for Document Conversion record status to Error (1).
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text         = lc_error_message
                     ,insert_update_flag = 1
                  WHERE summary_id = p_cust_doc_sum_id
                  AND   clearing_days = summary_table_rec_type.clearing_days     -- EBILL_DOCUMENT_ID  -- Added for 1.1
                  AND org_id       = summary_table_rec_type.org_id;
                  
-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for Document Contact Conversion record status 
-- to Error (1), when parent record fails.
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text         = 'Parent Program errored out'||lc_error_message
                     ,insert_update_flag = 1
                  WHERE summary_id  = p_contacts_sum_id
                  AND clearing_days = summary_table_rec_type.clearing_days;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for Document File Naming Conversion record status 
-- to Error (1), when parent record fails.
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text         = 'Parent Program errored out'||lc_error_message
                     ,insert_update_flag = 1
                  WHERE summary_id  = p_file_name_parmt_sum_id
                  AND clearing_days = summary_table_rec_type.clearing_days;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'CONTACTS procedure and FILE NAME PARAMETER procedure will not process for EBILL_DOC_ID : '
                                              ||summary_table_rec_type.clearing_days);

               x_ret_code := 1;
               COMMIT;
         END;
         
         END LOOP;
         CLOSE lcu_summary_table;
         
         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- >NUMBER OF RECORDS PROCESSED SUCCESSFULLY : '||ln_counter);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-- >NUMBER OF RECORDS PROCESSED SUCCESSFULLY : '||ln_counter);
         
         COMMIT;
         
   EXCEPTION

      WHEN OTHERS THEN

         lc_error_message := 'Error - Unhandled exception in package XX_CDH_EBILL_CONVERSION_PKG.XX_EBILL_CUST_DOC_PRC '
                                ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED IN EBILL CUST DOCUMENT');
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

               ROLLBACK;
               
-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table for Document Conversion record status to Error (1).
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text = 'Look into logfile for more details.. ' || lc_error_message
                     ,insert_update_flag = 1
                  WHERE summary_id = p_cust_doc_sum_id
                  AND insert_update_flag = 0;

               x_ret_code := 2;

               COMMIT;

   END XX_EBILL_CUST_DOC_PRC;
   

   PROCEDURE XX_EBILL_FILE_NAME_PARMT_PRC(
                         p_file_name_parmt_sum_id  IN       NUMBER
                        ,x_ret_code                IN OUT   NUMBER
                                         )
   IS
   
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name        : XX_EBILL_FILE_NAME_PARMT_PRC                               |
-- |                                                                          |
-- | Description : This procedure is used to insert the records in            |
-- |               corresponding table for ebilling file name parameter.      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date            Author              Remarks                     |
-- |=======   ==========    =============        =============================|
-- |1.0       29-MAR-10      Navin Agarwal       Initial version              |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

      CURSOR lcu_summary_table
      IS
      SELECT *
         FROM xxod_hz_summary
         WHERE summary_id = p_file_name_parmt_sum_id     -- 767679;
         AND insert_update_flag = 0;
         
      ln_counter                  NUMBER                   DEFAULT 0;
      ln_process_flag             NUMBER                   DEFAULT 0;
      ln_ebl_file_name_id         NUMBER;
      lc_error_message            VARCHAR2(4000)           DEFAULT NULL;
      summary_table_rec_type      xxod_hz_summary%ROWTYPE;
      ln_field_count              NUMBER;

   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'***********************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,' --------  Begin of XX_EBILL_FILE_NAME_PARMT_PRC --------  ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' --------  Begin of XX_EBILL_FILE_NAME_PARMT_PRC --------  ');

      OPEN lcu_summary_table;
      LOOP

         FETCH lcu_summary_table
         INTO summary_table_rec_type; 
         EXIT WHEN lcu_summary_table%NOTFOUND;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- >Processing data for E-bill doc_id ' || summary_table_rec_type.clearing_days);
         lc_error_message := '';

         BEGIN

-- ----------------------------------------------------------------------------
-- To check the Field, if its not a valid field Id then through an Error.
-- ----------------------------------------------------------------------------
            SELECT COUNT(1)
            INTO   ln_field_count
            FROM   XX_CDH_EBILLING_FIELDS_V vfin
            WHERE  field_id = summary_table_rec_type.customer_profile_class_name
            AND    NVL(use_in_file_name, 'N') = 'Y';

-- ----------------------------------------------------------------------------
-- To check the Field count and Cust Document Id.
-- ----------------------------------------------------------------------------
            IF summary_table_rec_type.eft_transmission_program_id IS NOT NULL
               AND ln_field_count > 0 THEN
               
               SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
                  INTO ln_ebl_file_name_id
                  FROM DUAL;

-- ----------------------------------------------------------------------------
-- Calling API to Insert Document Transmission data into Custom table (XX_CDH_EBL_FILE_NAME_DTL).
-- ----------------------------------------------------------------------------
               lc_error_message := 'XX_CDH_EBL_FILE_NAME_DTL_PKG.INSERT_ROW';
               XX_CDH_EBL_FILE_NAME_DTL_PKG.insert_row(
                      p_ebl_file_name_id     => ln_ebl_file_name_id                                -- Using Sequence
                     ,p_cust_doc_id          => summary_table_rec_type.eft_transmission_program_id -- New_Oracle_Cust_Doc_Id
                     ,p_file_name_order_seq  => summary_table_rec_type.worker_id                   -- Sequence_Number
                     ,p_field_id             => summary_table_rec_type.customer_profile_class_name -- Data Element Name
                     ,p_constant_value       => summary_table_rec_type.cons_bill_level             -- Constant Value
                     ,p_default_if_null      => 'NULL'
                     ,p_comments             => summary_table_rec_type.rel_comments                -- Comments
                     ,p_last_update_date     => SYSDATE
                     ,p_last_updated_by      => FND_GLOBAL.USER_ID
                     ,p_creation_date        => SYSDATE
                     ,p_created_by           => FND_GLOBAL.USER_ID
                     ,p_last_update_login    => FND_GLOBAL.USER_ID
                                        );
                                        
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'PROCESSED SUCCESSFULLY FOR  EBILL_DOCUMENT_ID : '||summary_table_rec_type.clearing_days
                                                ||'  CUST_DOC_ID: '||summary_table_rec_type.eft_transmission_program_id
                                                ||'  CUST_ACC_ID: '||summary_table_rec_type.eft_printing_program_id);
               lc_error_message := 'SUCCESSFULLY PROCESSED';
               ln_process_flag := 2;
               ln_counter := ln_counter +1;
               
            ELSE
               
               lc_error_message := 'Cust_Doc_Id is Null/Invalid Field Code';
               ln_process_flag := 1;
               x_ret_code := 1;
               
            END IF;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Processed (2) / Error (1).
-- ----------------------------------------------------------------------------
            UPDATE xxod_hz_summary
               SET error_text = lc_error_message
                  ,insert_update_flag = ln_process_flag
               WHERE summary_id = p_file_name_parmt_sum_id
               AND clearing_days = summary_table_rec_type.clearing_days;
            
            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
            COMMIT;

         EXCEPTION

            WHEN OTHERS THEN

               lc_error_message := 'Error - Unhandled exception in package XX_CDH_EBILL_CONVERSION_PKG.XX_EBILL_FILE_NAME_PARMT_PRC: Table/Package ' 
                                || lc_error_message 
                                ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED INSIDE EBILL FILE NAME PARAMETER');
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
               
               ROLLBACK;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1).
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text = lc_error_message
                     ,insert_update_flag = 1
                  WHERE summary_id = p_file_name_parmt_sum_id
                  AND clearing_days = summary_table_rec_type.clearing_days;
               
               x_ret_code := 1;
               COMMIT;
               
         END;
         
         END LOOP;
         CLOSE lcu_summary_table;
         
         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- >NUMBER OF RECORDS PROCESSED SUCCESSFULLY : '||ln_counter);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-- >NUMBER OF RECORDS PROCESSED SUCCESSFULLY : '||ln_counter);
   
   EXCEPTION

      WHEN OTHERS THEN

         lc_error_message := 'Error - Unhandled exception in package XX_CDH_EBILL_CONVERSION_PKG.XX_EBILL_FILE_NAME_PARMT_PRC.'
                          ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED IN EBILL FILE NAME PARAMETER');
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

         ROLLBACK;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1).
-- ----------------------------------------------------------------------------
         UPDATE xxod_hz_summary
            SET error_text = 'Look into logfile for more details. ' || lc_error_message
               ,insert_update_flag = 1
            WHERE summary_id = p_file_name_parmt_sum_id
            AND insert_update_flag = 0;

         x_ret_code := 2;
         COMMIT;

   END XX_EBILL_FILE_NAME_PARMT_PRC;
   

   PROCEDURE XX_EBILL_CONTACTS_PRC(
                       p_contacts_sum_id         IN       NUMBER
                      ,p_activate_bulk_batch     IN       NUMBER
                      ,x_ret_code                IN OUT   NUMBER
                                  )
   IS
   
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name        : XX_EBILL_CONTACTS_PRC                                      |
-- |                                                                          |
-- | Description : This procedure is used to create contacts for a given      |
-- |               customer document in ebilling contacts table and also      |
-- |               create contacts in Oracle STD tables.                      |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date            Author              Remarks                     |
-- |=======   ==========    =============        =============================|
-- |1.0       29-MAR-10      Navin Agarwal       Initial version              |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

      ln_counter                   NUMBER  DEFAULT 0;
      ln_ebl_doc_contact_id        NUMBER;
      ln_org_contact_id            NUMBER;
      ln_cust_account_id           NUMBER;
      lc_error_message             VARCHAR2(4000)                     DEFAULT NULL;
      summary_table_rec_type       xxod_hz_summary%ROWTYPE;
      
      CURSOR lcu_summary_table
      IS
      SELECT *
         FROM xxod_hz_summary
         WHERE summary_id = p_contacts_sum_id     -- 767678;
         AND insert_update_flag = 0
         AND    CONS_INV_FLAG = 2;
         
   BEGIN
   
      FND_FILE.PUT_LINE(FND_FILE.LOG,'***********************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,' --------  Begin of XX_EBILL_CONTACTS_PRC --------  ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' --------  Begin of XX_EBILL_CONTACTS_PRC --------  ');

-- ----------------------------------------------------------------------------
-- Calling Procedure to Create Contact Details in STD tables.
-- ----------------------------------------------------------------------------
      XX_STD_CONTACTS_CONVERSION (
             p_contacts_sum_id
            ,p_Activate_Bulk_Batch
            ,x_ret_code
                                  );
      
    IF x_ret_code <> '2' THEN -- XX_STD_CONTACTS_CONVERSION return status <> 2.
      
      OPEN lcu_summary_table;
      LOOP
         FETCH lcu_summary_table
         INTO summary_table_rec_type; 
         EXIT WHEN lcu_summary_table%NOTFOUND;
         
         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- >Processing data for E-bill doc_id ' || summary_table_rec_type.clearing_days);
         BEGIN

-- ----------------------------------------------------------------------------
-- Get Org_Contact_Id from Oracle STD tables for given record.
-- ----------------------------------------------------------------------------
            lc_error_message := 'HZ_ORG_CONTACTS';
            SELECT org_contact_id 
            INTO   ln_org_contact_id
            FROM   hz_org_contacts HOC
	    WHERE  ORIG_SYSTEM_REFERENCE = summary_table_rec_type.contact_orig_system_reference
            AND    status = 'A';


            SELECT xx_cdh_ebl_doc_contact_id_s.NEXTVAL
               INTO ln_ebl_doc_contact_id
               FROM DUAL;
               
            SELECT CUST_ACCOUNT_ID
            INTO   ln_cust_account_id
            FROM   XX_CDH_EBL_MAIN eblm
            WHERE  eblm.CUST_DOC_ID = summary_table_rec_type.eft_transmission_program_id;

-- ----------------------------------------------------------------------------
-- Calling API to Insert Document Contact data into Custom table (XX_CDH_EBL_CONTACTS).
-- ----------------------------------------------------------------------------
            lc_error_message := 'XX_CDH_EBL_CONTACTS_PKG.INSERT_ROW';
            XX_CDH_EBL_CONTACTS_PKG.insert_row(
                                    p_ebl_doc_contact_id => ln_ebl_doc_contact_id                                -- Using Sequence
                                   ,p_cust_doc_id        => summary_table_rec_type.eft_transmission_program_id   -- New_Oracle_Cust_Doc_Id
                                   ,p_org_contact_id     => ln_org_contact_id                                    -- Using Sequence
                                   ,p_cust_acct_site_id  => NULL
                                   ,p_attribute1         => ln_cust_account_id
                                   ,p_last_update_date   => SYSDATE
                                   ,p_last_updated_by    => FND_GLOBAL.USER_ID
                                   ,p_creation_date      => SYSDATE
                                   ,p_created_by         => FND_GLOBAL.USER_ID
                                   ,p_last_update_login  => FND_GLOBAL.USER_ID
                                   );
                                   
            ln_counter := ln_counter +1;
            lc_error_message := 'SUCCESSFULLY PROCESSED';

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Processed (2).
-- ----------------------------------------------------------------------------
            UPDATE xxod_hz_summary
               SET error_text = lc_error_message
                  ,insert_update_flag = 2
                  ,PARTY_ID = ln_org_contact_id
               WHERE summary_id                = p_contacts_sum_id
               AND   clearing_days             = summary_table_rec_type.clearing_days
               AND   person_previous_last_name = summary_table_rec_type.person_previous_last_name
               AND   email_address             = summary_table_rec_type.email_address;

            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'PROCESSED SUCCESSFULLY FOR  EBILL_DOCUMENT_ID : '||summary_table_rec_type.clearing_days
                             ||'  CUST_DOC_ID: '||summary_table_rec_type.eft_transmission_program_id
                             ||'  CUST_ACC_ID: '||summary_table_rec_type.eft_printing_program_id);
            COMMIT;
         EXCEPTION

            WHEN NO_DATA_FOUND THEN

               lc_error_message := 'Error - No Data Found while getting data from: ' || lc_error_message||' table. No org_contact_id.'
                                ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED INSIDE EBILL CONTACTS');
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'NO CUST ACC ID FOR THIS EBILL DOC ID : '||summary_table_rec_type.clearing_days);

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1).
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text = lc_error_message
                     ,insert_update_flag = 1
                     ,cons_inv_flag = 1
                  WHERE summary_id = p_contacts_sum_id
                  AND   clearing_days = summary_table_rec_type.clearing_days
                  AND   person_previous_last_name = summary_table_rec_type.person_previous_last_name
                  AND   email_address             = summary_table_rec_type.email_address;

               x_ret_code := 1;
               COMMIT;

            WHEN OTHERS THEN

               lc_error_message := 'Error - Unhandled exception in package XX_CDH_EBILL_CONVERSION_PKG.XX_EBILL_CONTACTS_PRC: Table/Package ' 
                                || lc_error_message 
                                ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED INSIDE EBILL CONTACTS');
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1).
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text = lc_error_message
                     ,insert_update_flag = 1
                  WHERE summary_id = p_contacts_sum_id
                  AND   clearing_days = summary_table_rec_type.clearing_days
                  AND   person_previous_last_name = summary_table_rec_type.person_previous_last_name
                  AND   email_address             = summary_table_rec_type.email_address;

               x_ret_code := 1;
               COMMIT;
         END;
         END LOOP;
         CLOSE lcu_summary_table;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- >NUMBER OF RECORDS PROCESSED SUCCESSFULLY : '||ln_counter);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-- >NUMBER OF RECORDS PROCESSED SUCCESSFULLY : '||ln_counter);
         COMMIT;
         
       ELSE -- XX_STD_CONTACTS_CONVERSION return status <> 2.
       
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_STD_CONTACTS_CONVERSION returned with ERROR.');
       END IF; -- XX_STD_CONTACTS_CONVERSION return status <> 2.
       
   EXCEPTION

      WHEN OTHERS THEN

         lc_error_message := 'Error - Unhandled exception in package XX_CDH_EBILL_CONVERSION_PKG.XX_EBILL_CONTACTS_PRC'
                          ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED IN EBILL CONTACTS');
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

         ROLLBACK;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1).
-- ----------------------------------------------------------------------------
         UPDATE xxod_hz_summary
            SET error_text = 'Look into logfile for more details. ' || lc_error_message
               ,insert_update_flag = 1
            WHERE summary_id = p_contacts_sum_id
            AND   insert_update_flag = 0
            AND   cons_inv_flag = 2;

         x_ret_code := 2;
         COMMIT;

   END XX_EBILL_CONTACTS_PRC;
   

   PROCEDURE XX_STD_CONTACTS_CONVERSION(
                                  p_contacts_sum_id         IN       NUMBER
                                 ,p_Activate_Bulk_Batch     IN       NUMBER
                                 ,x_ret_code             IN OUT      NUMBER
                                  )
   IS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name        : XX_EBILL_FILE_NAME_PARMT_PRC                               |
-- |                                                                          |
-- | Description : This procedure is used to insert the records in            |
-- |               corresponding table for ebilling contacts.                 |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date            Author              Remarks                     |
-- |=======   ==========    =============        =============================|
-- |1.0       29-MAR-10      Navin Agarwal       Initial version              |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

      CURSOR lcu_summary_table
      IS
      SELECT rownum row_count, xhzs.*
         FROM xxod_hz_summary xhzs
         WHERE summary_id = p_contacts_sum_id
         and    CONS_INV_FLAG = 0;
--          AND insert_update_flag = 0
--          AND CONTACT_ORIG_SYSTEM_REFERENCE IS NOT NULL;


      lb_wait                           BOOLEAN;

      ln_counter                        NUMBER                  DEFAULT 0;
      ln_batch_id                       NUMBER;
      ln_contacts_sum_id                NUMBER;
      ln_batch_count                    NUMBER;
      ln_request_id                     fnd_concurrent_requests.request_id%TYPE
                                        := fnd_global.conc_request_id();
      ln_conc_request_id                fnd_concurrent_requests.request_id%TYPE;

      lc_error_message                  VARCHAR2(4000)          DEFAULT NULL;
      lc_new_orig_system_reference      VARCHAR2(240);
      lv_phase                          VARCHAR2(2000);
      lv_status                         VARCHAR2(2000);
      lv_dev_phase                      VARCHAR2(2000);
      lv_dev_status                     VARCHAR2(2000);
      lv_message                        VARCHAR2(2000);


      lr_summary_table_rec              lcu_summary_table%ROWTYPE;
      
      lex_cust_exception                EXCEPTION;
      le_exception                      EXCEPTION;
      
   
   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'***********************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,' --------  Begin of XX_STD_CONTACTS_CONVERSION --------  ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' --------  Begin of XX_STD_CONTACTS_CONVERSION --------  ');

      ln_batch_id                  := p_activate_bulk_batch; 
      lc_error_message := 'SELECT1';

      FND_FILE.PUT_LINE(FND_FILE.LOG,' Active Bulk Batch id: '|| ln_batch_id);

-- ----------------------------------------------------------------------------
-- To make sure that the Batch_Id is active.
-- ----------------------------------------------------------------------------
      SELECT COUNT(1)
      INTO   ln_batch_count
      FROM   HZ_IMP_BATCH_SUMMARY bs
      WHERE  batch_id = nvl(ln_batch_id, -10000129)
      AND    batch_status = 'ACTIVE';

      IF ln_batch_count = 0 or ln_batch_id IS NULL THEN

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Active Batch: ' || p_activate_bulk_batch);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STD Contact Conversion program is Canceled. ');
         lc_error_message := 'Invalid Activate Batch... Please Create and Activate the batch and run the program again.';
         RAISE lex_cust_exception;
      END IF;


      lc_error_message := 'Loop lcu_summary_table.';
      OPEN lcu_summary_table;
      LOOP
         FETCH lcu_summary_table
         INTO lr_summary_table_rec; 

         EXIT WHEN lcu_summary_table%NOTFOUND;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- > Inserting data into INT tables. Orig System Reference: ' 
            || lr_summary_table_rec.orig_system_reference || '. Contact Last Name: '|| lr_summary_table_rec.person_previous_last_name
            || '. Email Address: ' || lr_summary_table_rec.email_address);
            
         BEGIN

-- ----------------------------------------------------------------------------
-- To make sure that the required date is available.
-- ----------------------------------------------------------------------------
            lc_error_message := 'No Error';
            IF lr_summary_table_rec.orig_system_reference IS NULL THEN
               lc_error_message := 'ORIG_SYSTEM_REFERENCE is Null, Some Issue with MAIN Conversion Procedure.';
            END IF;
            
            IF lr_summary_table_rec.person_previous_last_name IS NULL THEN
               lc_error_message := 'Last Name on the File can not be null (PERSON_PREVIOUS_LAST_NAME).';
            END IF;

            IF lr_summary_table_rec.email_address IS NULL THEN
               lc_error_message := 'Email Address on the File can not be null (EMAIL_ADDRESS).';
            END IF;

            -- FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_error_message: ' || lc_error_message);
            IF lc_error_message = 'No Error' THEN
               lc_new_orig_system_reference := 'EBL_CONV' || to_char(sysdate, 'YYYYMMDDHH24MISS') 
                                                          || lpad(lr_summary_table_rec.row_count,6, 0);

-- ----------------------------------------------------------------------------
-- Inserting data into required INTERFACE table.
-- ----------------------------------------------------------------------------

               lc_error_message := 'Insert into HZ_IMP_PARTIES_INT.';
               INSERT INTO HZ_IMP_PARTIES_INT (
	             BATCH_ID                      -- NUMBER
	            ,PARTY_ORIG_SYSTEM             -- VARCHAR2
	            ,PARTY_ORIG_SYSTEM_REFERENCE   -- VARCHAR2
	            ,PARTY_TYPE                    -- VARCHAR2
	            ,ATTRIBUTE4                    -- VARCHAR2
	            ,ATTRIBUTE13                   -- VARCHAR2
	            ,ATTRIBUTE20                   -- VARCHAR2
	            ,PERSON_LAST_NAME              -- VARCHAR2
	            ,PERSON_FIRST_NAME             -- VARCHAR2
	            ,CREATED_BY_MODULE             -- VARCHAR2
	       ) VALUES (
	             ln_batch_id
	            ,'A0'
	            ,lc_new_orig_system_reference 
	            ,'PERSON'
	            ,'REGULAR'
	            ,'CUSTOMER'
	            ,NULL-- '221042'
	            ,lr_summary_table_rec.person_previous_last_name-- LNAME
	            ,lr_summary_table_rec.collector_name-- FNAME
	            ,'XXCONV'
	       );
	       
	       lc_error_message := 'Insert into XXOD_HZ_IMP_CONTACTS_INT.';
	       INSERT INTO XXOD_HZ_IMP_CONTACTS_INT 
	       (
	             ATTRIBUTE19                   -- VARCHAR2
	            ,BATCH_ID                      -- NUMBER
	            ,CONTACT_ORIG_SYSTEM           -- VARCHAR2
	            ,CONTACT_ORIG_SYSTEM_REFERENCE -- VARCHAR2
	            ,CREATED_BY_MODULE             -- VARCHAR2
	            ,OBJ_ORIG_SYSTEM               -- VARCHAR2
	            ,OBJ_ORIG_SYSTEM_REFERENCE     -- VARCHAR2
	            ,RELATIONSHIP_CODE             -- VARCHAR2
	            ,RELATIONSHIP_TYPE             -- VARCHAR2
	            ,START_DATE                    -- DATE
	            ,SUB_ORIG_SYSTEM               -- VARCHAR2
	            ,SUB_ORIG_SYSTEM_REFERENCE     -- VARCHAR2
	       ) VALUES (
	             0
	            ,ln_batch_id
	            ,'A0'
	            ,lc_new_orig_system_reference
	            ,'XXCONV'
	            ,'A0'
	            , lr_summary_table_rec.orig_system_reference-- hzc.Orig_System_Reference
	            ,'CONTACT_OF'
	            ,'CONTACT'
	            ,TRUNC(SYSDATE)
	            ,'A0'
	            ,lc_new_orig_system_reference 
	       );
	       
	       lc_error_message := 'Insert into XXOD_HZ_IMP_ACCT_CONTACTS_INT.';
	       INSERT INTO XXOD_HZ_IMP_ACCT_CONTACTS_INT 
	       (
	             BATCH_ID                      -- NUMBER
	            ,CREATED_BY_MODULE             -- VARCHAR2
	            ,PARTY_ORIG_SYSTEM             -- VARCHAR2
	            ,PARTY_ORIG_SYSTEM_REFERENCE   -- VARCHAR2
	            ,ACCOUNT_ORIG_SYSTEM           -- VARCHAR2
	            ,ACCOUNT_ORIG_SYSTEM_REFERENCE -- VARCHAR2
	            ,CONTACT_ORIG_SYSTEM           -- VARCHAR2
	            ,CONTACT_ORIG_SYSTEM_REFERENCE -- VARCHAR2
	            ,ROLE_TYPE                     -- VARCHAR2
	            ,PRIMARY_FLAG                  -- VARCHAR2
	       ) VALUES (
	             ln_batch_id
	            ,'XXCONV'
	            ,'A0'
	            ,lc_new_orig_system_reference 
	            ,'A0'
	            ,lr_summary_table_rec.orig_system_reference-- hzc.Orig_System_Reference
	            ,'A0'
	            ,lc_new_orig_system_reference -- CONTACT_ORIG_SYSTEM_REFERENCE
              ,'CONTACT'
	            ,'N'
	       );
	       
	       lc_error_message := 'Insert into XXOD_HZ_IMP_CONTACTROLES_INT.';
	       INSERT INTO XXOD_HZ_IMP_CONTACTROLES_INT 
	       (
	             BATCH_ID                      -- NUMBER
	            ,CONTACT_ORIG_SYSTEM           -- VARCHAR2
	            ,CONTACT_ORIG_SYSTEM_REFERENCE -- VARCHAR2
	            ,CREATED_BY_MODULE             -- VARCHAR2
	            ,ROLE_TYPE                     -- VARCHAR2
	            ,SUB_ORIG_SYSTEM               -- VARCHAR2
	            ,SUB_ORIG_SYSTEM_REFERENCE     -- VARCHAR2
	       ) VALUES (
	             ln_batch_id
	            ,'A0'
	            ,lc_new_orig_system_reference 
	            ,'XXCONV'
	            ,'BILLING'-- 'FIRST_CONTACT'
	            ,'A0'
	            ,lc_new_orig_system_reference 
	       );
	       
	       lc_error_message := 'Insert into XXOD_HZ_IMP_ACCT_CNTROLES_INT.';
	       INSERT INTO XXOD_HZ_IMP_ACCT_CNTROLES_INT 
	       (
	             BATCH_ID                      -- NUMBER
	            ,CREATED_BY_MODULE             -- VARCHAR2
	            ,PARTY_ORIG_SYSTEM             -- VARCHAR2
	            ,PARTY_ORIG_SYSTEM_REFERENCE   -- VARCHAR2
	            ,ACCOUNT_ORIG_SYSTEM           -- VARCHAR2
	            ,ACCOUNT_ORIG_SYSTEM_REFERENCE -- VARCHAR2
	            ,CONTACT_ORIG_SYSTEM           -- VARCHAR2
	            ,CONTACT_ORIG_SYSTEM_REFERENCE -- VARCHAR2
	            ,RESPONSIBILITY_TYPE           -- VARCHAR2
	            ,PRIMARY_FLAG                  -- VARCHAR2
	       ) VALUES (
	             ln_batch_id
	            ,'XXCONV'
	            ,'A0'
	            ,lc_new_orig_system_reference 
	            ,'A0'
	            , lr_summary_table_rec.orig_system_reference-- hzc.Orig_System_Reference
	            ,'A0'
	            ,lc_new_orig_system_reference 
	            ,'BILLING'-- 'FIRST_CONTACT'
	            ,'N'
	       );
	       
	       IF lr_summary_table_rec.EMAIL_ADDRESS IS NOT NULL THEN

                  lc_error_message := 'Insert into XXOD_HZ_IMP_CONTACTPTS_INT.';
	          INSERT INTO XXOD_HZ_IMP_CONTACTPTS_INT 
	          (
	             ATTRIBUTE19                   -- VARCHAR2
	            ,ATTRIBUTE20                   -- VARCHAR2
	            ,BATCH_ID                      -- NUMBER
	            ,CONTACT_POINT_PURPOSE         -- VARCHAR2
	            ,CONTACT_POINT_TYPE            -- VARCHAR2
	            ,CP_ORIG_SYSTEM                -- VARCHAR2
	            ,CP_ORIG_SYSTEM_REFERENCE      -- VARCHAR2
	            ,CREATED_BY_MODULE             -- VARCHAR2
	            ,EMAIL_ADDRESS                 -- VARCHAR2
	            ,EMAIL_FORMAT                  -- VARCHAR2
	            ,PARTY_ORIG_SYSTEM             -- VARCHAR2
	            ,PARTY_ORIG_SYSTEM_REFERENCE   -- VARCHAR2
	            ,PRIMARY_FLAG                  -- VARCHAR2
	            ,REL_FLAG                      -- VARCHAR2
	          ) VALUES (
	             0
	            ,lr_summary_table_rec.orig_system_reference-- hzc.Orig_System_Reference
	            ,ln_batch_id
	            ,'BILLING'-- 'BUSINESS'
	            ,'EMAIL'
	            ,'A0'
	            ,'E' || lc_new_orig_system_reference
	             -- CP_ORIG_SYSTEM_REFERENCE-- Example: E00000001996260 and P00000002043964
	            ,'XXCONV'
	            ,lr_summary_table_rec.EMAIL_ADDRESS-- EMAIL_ADDRESS-- IF EMAIL.
	            ,'MAILTEXT'     -- IF EMAIL.
	            ,'A0'
	            ,lc_new_orig_system_reference 
	            ,'N' -- PRIMARY_FLAG-- IF EMAIL then 'Y'.
	            ,'Y'
	          );
	       
	       END IF;
	       
	       IF lr_summary_table_rec.PHONE_NUMBER IS NOT NULL THEN

                  lc_error_message := 'Insert into XXOD_HZ_IMP_CONTACTPTS_INT.';
	          INSERT INTO XXOD_HZ_IMP_CONTACTPTS_INT 
	          (
	             ATTRIBUTE19                   -- VARCHAR2
	            ,ATTRIBUTE20                   -- VARCHAR2
	            ,BATCH_ID                      -- NUMBER
	            ,CONTACT_POINT_PURPOSE         -- VARCHAR2
	            ,CONTACT_POINT_TYPE            -- VARCHAR2
	            ,CP_ORIG_SYSTEM                -- VARCHAR2
	            ,CP_ORIG_SYSTEM_REFERENCE      -- VARCHAR2
	            ,CREATED_BY_MODULE             -- VARCHAR2
	            ,PARTY_ORIG_SYSTEM             -- VARCHAR2
	            ,PARTY_ORIG_SYSTEM_REFERENCE   -- VARCHAR2
	            -- Phone related columns.
	            ,PHONE_COUNTRY_CODE            -- VARCHAR2
	            ,PHONE_LINE_TYPE               -- VARCHAR2
	            ,PHONE_NUMBER                  -- VARCHAR2
	            ,PRIMARY_FLAG                  -- VARCHAR2
	            ,RAW_PHONE_NUMBER              -- VARCHAR2
	            ,REL_FLAG                      -- VARCHAR2
	          ) VALUES (
	             0
	            ,lr_summary_table_rec.orig_system_reference-- hzc.Orig_System_Reference
	            ,ln_batch_id
	            ,'BILLING'-- Old Value: 'BUSINESS'
	            ,'PHONE'
	            ,'A0'
	            ,'P' || lc_new_orig_system_reference
	           -- CP_ORIG_SYSTEM_REFERENCE-- Example: E00000001996260 and P00000002043964
	            ,'XXCONV'
	            ,'A0'
	            ,lc_new_orig_system_reference 
	            ,'1'-- IF PHONE.
	            ,'GEN'-- IF PHONE.
	            , NULL-- PHONE_NUMBER-- Difference between below column and this column.
	            ,'N' -- PRIMARY_FLAG-- IF PHONE Then "N". 
	            ,lr_summary_table_rec.PHONE_NUMBER-- RAW_PHONE_NUMBER -- IF PHONE.-- Phone Number
	            ,'Y'
	          );
               END IF;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record STD Contact Conversion status to Processed (2).
-- ----------------------------------------------------------------------------
	          lc_error_message := 'Update XXOD_HZ_SUMMARY table.';
	          UPDATE xxod_hz_summary set
	             ERROR_TEXT          = 'SUCCESSFULLY PROCESSED'
	            ,CONTACT_ORIG_SYSTEM_REFERENCE = lc_new_orig_system_reference
	            ,CONS_INV_FLAG                 = 2
                  WHERE summary_id                = p_contacts_sum_id    -- 767677
                  AND   CONS_INV_FLAG             = 0
                  and   PERSON_PREVIOUS_LAST_NAME = lr_summary_table_rec.PERSON_PREVIOUS_LAST_NAME
                  and   EMAIL_ADDRESS             = lr_summary_table_rec.EMAIL_ADDRESS;
               
               COMMIT;
               ln_counter := ln_counter + 1;
               lc_error_message := '';
               
            ELSE-- ORIG_SYSTEM_REFERENCE IS NOT NULL

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record STD Contact Conversion status to Error (1).
-- ----------------------------------------------------------------------------
	          UPDATE xxod_hz_summary set
	              ERROR_TEXT          = lc_error_message
	             ,CONS_INV_FLAG       = 1
                  WHERE summary_id                = p_contacts_sum_id    -- 767677
                  AND   CONS_INV_FLAG             = 0
                  and   PERSON_PREVIOUS_LAST_NAME = lr_summary_table_rec.PERSON_PREVIOUS_LAST_NAME
                  and   EMAIL_ADDRESS             = lr_summary_table_rec.EMAIL_ADDRESS;

                  x_ret_code := 1;
                  
            END IF;-- ORIG_SYSTEM_REFERENCE IS NOT NULL
            COMMIT;
            
         EXCEPTION
            
            WHEN OTHERS THEN

               lc_error_message := 'Error - Unhandled exception in package XX_CDH_EBILL_CONVERSION_PKG.XX_STD_CONTACTS_CONVERSION: While - ' 
                                || lc_error_message 
                                ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);

               FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED INSIDE EBILL CONTACTS');
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

               ROLLBACK;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record STD Contact Conversion status to Error (1).
-- ----------------------------------------------------------------------------
	          UPDATE xxod_hz_summary set
	              ERROR_TEXT          = lc_error_message
	             ,CONS_INV_FLAG       = 1
                  WHERE summary_id                = p_contacts_sum_id    -- 767677
                  AND   insert_update_flag        = 0
                  and   PERSON_PREVIOUS_LAST_NAME = lr_summary_table_rec.PERSON_PREVIOUS_LAST_NAME
                  and   EMAIL_ADDRESS             = lr_summary_table_rec.EMAIL_ADDRESS;

               x_ret_code := 1;
               COMMIT;

         END;
         
         END LOOP;
         CLOSE lcu_summary_table;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of records Inserted into Interface tables: ' || ln_counter);
         FND_FILE.PUT_LINE(FND_FILE.LOG,' Active Bulk Batch id: '|| ln_batch_id);
         
         IF trim(ln_batch_id ) IS NOT NULL and ln_counter > 0 THEN -- int_count > 0
         
-- ----------------------------------------------------------------------------
--  Submitting Program -- > OD: CDH Load Oracle INT to STG Process
--  Parameters:
--       Apps Batch_Id

--  ---------------------------------------------------------------------------

               fnd_file.put_line (fnd_file.log, 'Submiting Request for Program - OD: CDH OWB Load from Oracle CV to STG');
               ln_conc_request_id := FND_REQUEST.submit_request 
	                               (   application => 'XXCNV',
	                                   program     => 'XX_CDH_CONV_LOAD_INT_STG_PKG',
	                                   argument1   => ln_batch_id
	                               );
               COMMIT;
               
	       IF ln_conc_request_id = 0 THEN
	       
	          fnd_file.put_line (fnd_file.log, 'Child Request failed to submit: ' || fnd_message.get);
	          RAISE le_exception;
	       ELSE
	       
	          fnd_file.put_line (fnd_file.log, ' ');
	          fnd_file.put_line (fnd_file.log, 'Submitted Child Request : '|| TO_CHAR( ln_conc_request_id ));
	          fnd_file.put_line (fnd_file.log, 'Batch_id                : '|| ln_batch_id);
               END IF;


               lb_wait := FND_CONCURRENT.wait_for_request 
                       (   request_id      => ln_conc_request_id,
                           interval        => 10,
                           phase           => lv_phase,
                           status          => lv_status,
                           dev_phase       => lv_dev_phase,
                           dev_status      => lv_dev_status,
                           message         => lv_message
                       );


               SELECT COUNT(1) 
               INTO   ln_batch_count
               FROM   XXOD_HZ_IMP_ACCT_CONTACT_STG
               WHERE  batch_id = ln_batch_id;

IF ln_batch_count > 0 THEN -- stg_count > 0
-- ----------------------------------------------------------------------------
--  Submitting Program -- > OD: CDH Customer Conversion Master Program
--  Parameters:
--       Batch_Id From
--       Batch_Id to
--       Submit Bulk Load?                         - Yes
--       Create Cust Account?                      - Yes
--       Create Contact?                           - Yes
--       Create Customer Profile?                  - Yes
--       Create Bank and Payments?                 - Yes
--       Create Extended Attributes?               - Yes
--       Import Run Option                         - COMPLETE -- > Run Preimport and Import
--       Run Batch De-Duplication                  - No
--       Batch De-Duplication Rule                 - Null
--       Action to Take on Duplicates              - Null
--       Run Address Validation                    - No
--       Run Registry De-Duplication               - No
--       Registry De-Duplication Rule              - Null
--       Generate Fuzzy Key During Post Processing - No
-- ----------------------------------------------------------------------------

               fnd_file.put_line (fnd_file.log, 'Submiting Request for Program - OD: CDH Customer Conversion Master Program');
               ln_conc_request_id := FND_REQUEST.submit_request 
	                               (   application => 'XXCNV',
	                                   program     => 'XX_CDH_CUST_CONV_MASTER',
	                                   description => ln_request_id||'-',-- UI job display
	                                   start_time  => NULL,
	                                  -- sub_request => TRUE,
	                                   argument1   => ln_batch_id,
	                                   argument2   => ln_batch_id,
	                                   argument3   => 'Y',
	                                   argument4   => 'Y',
	                                   argument5   => 'Y',
	                                   argument6   => 'Y',
	                                   argument7   => 'Y',
	                                   argument8   => 'Y',
	                                   argument9   => 'COMPLETE',-- 'Run Preimport and Import',
	                                   argument10  => 'N',
	                                   argument11  => Null,
	                                   argument12  => Null,
	                                   argument13  => 'N',
	                                   argument14  => 'N',
	                                   argument15  => Null,
	                                   argument16  => 'N'
	                               );
               COMMIT;
               
	       IF ln_conc_request_id = 0 THEN
	       
	          fnd_file.put_line (fnd_file.log, 'Child Request failed to submit: ' || fnd_message.get);
	          RAISE le_exception;
	       ELSE
	       
	          fnd_file.put_line (fnd_file.log, ' ');
	          fnd_file.put_line (fnd_file.log, 'Submitted Child Request : '|| TO_CHAR( ln_conc_request_id ));
	          fnd_file.put_line (fnd_file.log, 'Batch_id                : '|| ln_batch_id);
               END IF;

               lb_wait := FND_CONCURRENT.wait_for_request 
                       (   request_id      => ln_conc_request_id,
                           interval        => 10,
                           phase           => lv_phase,
                           status          => lv_status,
                           dev_phase       => lv_dev_phase,
                           dev_status      => lv_dev_status,
                           message         => lv_message
                       );
                       
-- ----------------------------------------------------------------------------
--  Submitting Program -- > OD: CDH Contact Role Responsibility Conversion Program
--  Parameters:
--       Batch_Id
--       Process Role Responsibility? - Yes
-- ----------------------------------------------------------------------------

               fnd_file.put_line (fnd_file.log, 'Submiting Request for Program - OD: CDH Contact Role Responsibility Conversion Program');
               ln_conc_request_id := FND_REQUEST.submit_request 
	                               (   application => 'XXCNV',
	                                   program     => 'XX_CDH_CONTACT_ROLE_RESP',
	                                   description => ln_request_id||'-',-- UI job display
	                                   start_time  => NULL,
	                                  -- sub_request => TRUE,
	                                   argument1   => ln_batch_id,
	                                   argument2   => 'Y'
	                               );
               COMMIT;

	       IF ln_conc_request_id = 0 THEN
	       
	          fnd_file.put_line (fnd_file.log, 'Child Request failed to submit: ' || fnd_message.get);
	          RAISE le_exception;
	       ELSE
	       
	          fnd_file.put_line (fnd_file.log, ' ');
	          fnd_file.put_line (fnd_file.log, 'Submitted Child Request : '|| TO_CHAR( ln_conc_request_id ));
	          fnd_file.put_line (fnd_file.log, 'Batch_id                : '|| ln_batch_id);
               END IF;


               lb_wait := FND_CONCURRENT.wait_for_request 
                       (   request_id      => ln_conc_request_id,
                           interval        => 10,
                           phase           => lv_phase,
                           status          => lv_status,
                           dev_phase       => lv_dev_phase,
                           dev_status      => lv_dev_status,
                           message         => lv_message
                       );
ELSE

   lc_error_message := 'Error - Zero records are imported into STAGING tables, so not submitting Master Conversion programs.';
   fnd_file.put_line (fnd_file.log, lc_error_message);
   x_ret_code := 2;

END IF;  -- STG_COUNT > 0
      ELSE

         lc_error_message := 'Error - Zero records inserted into INTERFACE tables for given Batch_Id: ' || ln_batch_id;
         x_ret_code := 2;
         fnd_file.put_line (fnd_file.log, lc_error_message);
      END IF;  -- int_count > 0
      
      IF x_ret_code = 2 THEN

         UPDATE xxod_hz_summary
            SET error_text = lc_error_message
               ,CONS_INV_FLAG = 1
            WHERE summary_id = p_contacts_sum_id
            AND CONS_INV_FLAG = 0;
      END IF;
      COMMIT;
      
   EXCEPTION

      WHEN lex_cust_exception then

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1), when Batch_id is not Active/Null.
-- ----------------------------------------------------------------------------
         UPDATE xxod_hz_summary
            SET error_text = lc_error_message || 'Batch_id is not active. Update INSERT_UPDATE_FLAG to zero and reprocess again.'
               ,CONS_INV_FLAG = 1
            WHERE summary_id = p_contacts_sum_id
            AND CONS_INV_FLAG = 0;

         x_ret_code := 2;
         COMMIT;

      WHEN le_exception THEN

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1), when Conversion Programs are not Submitted.
-- ----------------------------------------------------------------------------
         UPDATE xxod_hz_summary
            SET error_text = lc_error_message || 'Exception while running Conversion programs. Update INSERT_UPDATE_FLAG to zero and reprocess again.'
               ,CONS_INV_FLAG = 1
            WHERE summary_id = p_contacts_sum_id
            AND CONS_INV_FLAG = 0;

         x_ret_code := 2;
         COMMIT;
      
      WHEN OTHERS THEN

         lc_error_message := 'Error - Unhandled exception in package XX_CDH_EBILL_CONVERSION_PKG.XX_STD_CONTACTS_CONVERSION'
                          ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);

         FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED IN EBILL CONTACTS');
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

         ROLLBACK;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1), Unhandled exception.
-- ----------------------------------------------------------------------------
         UPDATE xxod_hz_summary
            SET error_text = 'Look into logfile for more details. ' || lc_error_message
               ,CONS_INV_FLAG = 1
            WHERE summary_id = p_contacts_sum_id
            AND CONS_INV_FLAG = 0;

         x_ret_code := 2;
         COMMIT;

   END XX_STD_CONTACTS_CONVERSION;



   PROCEDURE XX_MAIL_PAY_ATTN_PRC(
                                 x_error_buff              OUT      VARCHAR2
                                ,x_ret_code                OUT      NUMBER
                                ,p_mail_attn_sum_id        IN       NUMBER
                                 )
   IS
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name        : XX_MAIL_PAY_ATTN_PRC                                       |
-- |                                                                          |
-- | Description : This procedure is used to insert the records in            |
-- |               corresponding table for Mail Pay Attention.                |
-- |                                                                          |
-- |                                                                          |
-- | Program Name: OD: CDH Mail To Attention Conversion.                      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date            Author              Remarks                     |
-- |=======   ==========    =============        =============================|
-- |1.0 B     12-Apr-10      Navin Agarwal       Draft                        |
-- |1.1       09-AUG-10      Param               Added lpad for attribute2 in |
-- |                                             getting the cust acc ID for  |
-- |                                             defect # 7167                |
-- |                                                                          |
-- +==========================================================================+

      ln_counter                   NUMBER  DEFAULT 0;
      ln_temp_count                NUMBER  DEFAULT 0;
      ln_process_flag              NUMBER  DEFAULT 0;
      ln_cust_acc_id               NUMBER;
      lc_error_message             VARCHAR2(4000)                     DEFAULT NULL;
      summary_table_rec_type       xxod_hz_summary%ROWTYPE;

      CURSOR lcu_summary_table
      IS
      SELECT *
         FROM xxod_hz_summary
         WHERE summary_id = p_mail_attn_sum_id     -- 767676;
         AND insert_update_flag = 0;

   BEGIN

      x_ret_code := 0;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'***********************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Running eBill Conversion for  Mail Pay Attention Having Summary Id: '||p_mail_attn_sum_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'***********************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,' --------  Begin of XX_MAIL_PAY_ATTN_PRC --------  ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' --------  Begin of XX_MAIL_PAY_ATTN_PRC --------  ');

      OPEN lcu_summary_table;
      LOOP

         FETCH lcu_summary_table
         INTO summary_table_rec_type; 
         EXIT WHEN lcu_summary_table%NOTFOUND;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- >Processing data for AOPS# ' || summary_table_rec_type.attribute2);

         BEGIN
            ln_cust_acc_id := NULL;
            lc_error_message := 'HZ_CUST_ACCOUNTS (Null Cust_Account_id)';


-- ----------------------------------------------------------------------------
-- Get the Cust_Account_ID for the Given AOPS Number.
-- ----------------------------------------------------------------------------
            SELECT cust_account_id
               INTO ln_cust_acc_id
               FROM HZ_CUST_ACCOUNTS 
               WHERE orig_system_reference = to_char(lpad((summary_table_rec_type.attribute2),8,0))||'-00001-A0'; -- Added for Defect # 7167

-- ----------------------------------------------------------------------------
-- Update EGO table with MAIL TO ATTENTION value.
-- ----------------------------------------------------------------------------
            UPDATE xx_cdh_cust_acct_ext_b
               SET c_ext_attr15 = summary_table_rec_type.consolidated_ind     -- BILLDOCS_MAIL_ATTENTION
               WHERE cust_account_id = ln_cust_acc_id                         -- CUST_ACCOUNT_ID
               AND n_ext_attr2 = summary_table_rec_type.account_status;       -- BILLDOCS_CUST_DOC_ID
            
            ln_temp_count := SQL%ROWCOUNT;
            
            IF ln_temp_count = 0 THEN
            
               lc_error_message := 'Error - No records found in EGO Table,for CUST_ACC_ID: '||ln_cust_acc_id
                                 ||' and CUST_DOC_ID: '||summary_table_rec_type.account_status;
               ln_process_flag := 1;
            ELSIF ln_temp_count > 1 THEN
            
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'PROCESSED SUCCESSFULLY FOR  AOPS# : '||summary_table_rec_type.attribute2);
               lc_error_message := 'Multiple ('||ln_temp_count||')records found in EGO Table,for CUST_ACC_ID: '||ln_cust_acc_id
                                 ||' and CUST_DOC_ID: '||summary_table_rec_type.account_status;
               ln_process_flag := 2;
               ln_counter := ln_counter + 1;
            ELSE
            
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'PROCESSED SUCCESSFULLY FOR  AOPS# : '||summary_table_rec_type.attribute2);
               lc_error_message := 'SUCCESSFULLY PROCESSED';
               ln_process_flag := 2;
               ln_counter := ln_counter + 1;
            END IF;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Process (2) / Error (1).
-- ----------------------------------------------------------------------------
            UPDATE xxod_hz_summary
               SET error_text = lc_error_message
                  ,insert_update_flag = ln_process_flag
                  ,eft_printing_program_id = ln_cust_acc_id        -- CUSTOMER_ACCOUNT_ID
               WHERE attribute2 = summary_table_rec_type.attribute2
               AND summary_id   = p_mail_attn_sum_id;
            
            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
            COMMIT;

         EXCEPTION

            WHEN NO_DATA_FOUND THEN

               lc_error_message := 'Error - No Data Found while getting data from: ' || lc_error_message||' table.'
                                ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED INSIDE MAIL PAY ATTENTION');
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'NO CUST ACC ID FOR THIS AOPS# : '||summary_table_rec_type.attribute2);

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1), when there is no date for a given AOPS#.
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text = lc_error_message
                     ,insert_update_flag = 1
                     ,eft_printing_program_id = ln_cust_acc_id        -- CUSTOMER_ACCOUNT_ID
                  WHERE summary_id = p_mail_attn_sum_id
                  AND attribute2 = summary_table_rec_type.attribute2;
               x_ret_code := 1;
               COMMIT;

            WHEN OTHERS THEN
               lc_error_message := 'Error - Unhandled exception in package XX_CDH_EBILL_CONVERSION_PKG.XX_MAIL_PAY_ATTN_PRC: Table/Package ' 
                                || lc_error_message 
                                ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED INSIDE MAIL PAY ATTENTION');
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1), Unhandled exception.
-- ----------------------------------------------------------------------------
               UPDATE xxod_hz_summary
                  SET error_text = lc_error_message
                     ,insert_update_flag = 1
                     ,eft_printing_program_id = ln_cust_acc_id        -- CUSTOMER_ACCOUNT_ID
                  WHERE summary_id = p_mail_attn_sum_id
                  AND attribute2 = summary_table_rec_type.attribute2;

               x_ret_code := 1;
               COMMIT;
         END;
         END LOOP;
         CLOSE lcu_summary_table;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'-- >NUMBER OF RECORDS PROCESSED SUCCESSFULLY : '||ln_counter);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-- >NUMBER OF RECORDS PROCESSED SUCCESSFULLY : '||ln_counter);
         COMMIT;

   EXCEPTION

      WHEN OTHERS THEN
         lc_error_message := 'Error - Unhandled exception in package XX_CDH_EBILL_CONVERSION_PKG.XX_MAIL_PAY_ATTN_PRC'
                          ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SUBSTR(SQLERRM, 1, 3000);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION OCCURED IN MAIL PAY ATTENTION');
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

         ROLLBACK;

-- ----------------------------------------------------------------------------
-- Update XXOD_HZ_SUMMARY table record status to Error (1), Unhandled exception.
-- ----------------------------------------------------------------------------
         UPDATE xxod_hz_summary
            SET error_text = 'Look into logfile for more details. ' || lc_error_message
               ,insert_update_flag = 1
            WHERE summary_id = p_mail_attn_sum_id
            AND insert_update_flag = 0;

        x_ret_code := 2;
        COMMIT;

   END XX_MAIL_PAY_ATTN_PRC;
   
END XX_CDH_EBILL_CONVERSION_PKG;
/

SHOW ERRORS;