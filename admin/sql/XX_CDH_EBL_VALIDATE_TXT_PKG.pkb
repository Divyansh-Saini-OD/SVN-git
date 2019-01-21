SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;

WHENEVER SQLERROR CONTINUE;

WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE BODY xx_cdh_ebl_validate_txt_pkg
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_VALIDATE_TXT_PKG                                 |
-- | Description :                                                             |
-- | This package body will validate before inserting data into tables.        |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      27-May-2016 Sridevi K     I2186 - For MOD 4B R4                   |
-- +===========================================================================+
AS
   gc_insert_fun_status           VARCHAR2 (4000) := '';
   gc_return_status               VARCHAR2 (4000) := '';
   gc_error_code                  VARCHAR2 (20)   := '';
   gc_error_message               VARCHAR2 (4000) := '';
   gc_validation_status           VARCHAR2 (5)    := 'TRUE';
   gc_doc_process_date   CONSTANT DATE            := SYSDATE;
   gex_error_table_error          EXCEPTION;

   FUNCTION validate_ebl_file_name_txt (
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
        FROM (SELECT 
                     val.source_value1  Field_ID,
                     val.source_value2  Field_Name,
                     val.target_value5  Use_In_File_Name
              FROM   XX_FIN_TRANSLATEDEFINITION def,
                     XX_FIN_TRANSLATEVALUES val
              where  def.translate_id     = val.translate_id
              and    def.translation_name = 'XX_CDH_EBL_TXT_HDR_FIELDS'
              and    val.enabled_flag     = 'Y'
             ) vfin 
       WHERE field_id = p_field_id AND use_in_file_name = 'Y';

      gc_error_code := 'XXOD_EBL_019';

      IF ln_field_count = 0
      THEN
         gc_error_message := '';
         gc_insert_fun_status :=
            xx_cdh_ebl_validate_pkg.insert_ebl_error (p_cust_doc_id,
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
        FROM (SELECT 
                     val.source_value1  Field_ID,
                     val.source_value2  Field_Name
              FROM   XX_FIN_TRANSLATEDEFINITION def,
                     XX_FIN_TRANSLATEVALUES val
              where  def.translate_id     = val.translate_id
              and    def.translation_name = 'XX_CDH_EBL_TXT_HDR_FIELDS'
              and    val.enabled_flag     = 'Y'
             ) vfin       
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
            xx_cdh_ebl_validate_pkg.insert_ebl_error (p_cust_doc_id,
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
            xx_cdh_ebl_validate_pkg.insert_ebl_error (p_cust_doc_id,
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
            xx_cdh_ebl_validate_pkg.insert_ebl_error (p_cust_doc_id,
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
   END validate_ebl_file_name_txt;

   
   -- +===========================================================================+
  -- |                                                                           |
  -- | NAME        : VALIDATE_EBL_TEMPL_DTL                                      |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION WILL BE USED TO VALIDATE DATE BEFORE INSERTING INTO         |
  -- | XX_CDH_EBL_TEMPL_DTL TABLE AND ALSO VALIDATE DATE BEFORE CHANGING         |
  -- | THE DOCUMENT STATUS FROM "IN PROCESS" TO "TESTING" (OR) FROM "TESTING"    |
  -- | TO "COMPLETE".                                                            |
  -- |                                                                           |
  -- |                                                                           |
  -- | PARAMETERS  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | RETURNS     :                                                             |
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

      IF lc_delivery_method = 'eTXT'
      THEN
         gc_error_code := 'SELECT5';

----------------------------------------------------------------------------
-- To make sure only Constant Value is picked. for Example Constant1 will be Constant.
----------------------------------------------------------------------------
         SELECT SUBSTR (val.source_value2, 0, 8) field_name
           INTO ln_field_name
           FROM xx_fin_translatedefinition def,
                xx_fin_translatevalues val
          WHERE def.translate_id = val.translate_id
            AND def.translation_name = 'XX_CDH_EBL_TXT_DET_FIELDS'
            AND val.enabled_flag = 'Y'
            AND val.source_value8 = 'Y'
            AND val.source_value1 IS NOT NULL
            AND val.source_value2 IS NOT NULL
            AND val.source_value1 = p_field_id;

        /*
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
         ELS
		 */
		 IF ln_field_name = 'Sequence'
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
               xx_cdh_ebl_validate_pkg.insert_ebl_error
                                   (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
                                   );
            gc_return_status := 'FALSE';
            gc_validation_status := 'TRUE';

            IF gc_insert_fun_status = 'FALSE'
            THEN
               RAISE gex_error_table_error;
            END IF;
         END IF;

         /*
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
         ELS
		 */
		 IF ln_field_name = 'Sequence'
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
               xx_cdh_ebl_validate_pkg.insert_ebl_error
                                   (p_cust_doc_id,
                                    gc_doc_process_date  -- p_doc_process_date
                                                       ,
                                    gc_error_code              -- p_error_code
                                                 ,
                                    gc_error_message           -- p_error_desc
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
--Commenting out
/*
         IF p_label IS NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               xx_cdh_ebl_validate_pkg.insert_ebl_error
                                   (p_cust_doc_id,
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
*/
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
               xx_cdh_ebl_validate_pkg.insert_ebl_error
                                   (p_cust_doc_id,
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
-- ERROR_CODE = 'XXOD_EBL_033'
-- ERROR_MESSAGE = ''
-- To make sure that File Creation Type = 'FIXED', alignment or PaddingChar can not be null.
--
----------------------------------------------------------------------------
       /*  gc_error_code := 'XXOD_EBL_033';

         IF     lc_ebill_file_creation_type = 'FIXED'
            AND (p_alignment IS NULL OR p_padding_char IS NULL)
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               xx_cdh_ebl_validate_pkg.insert_ebl_error
                                   (p_cust_doc_id,
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
*/
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
               xx_cdh_ebl_validate_pkg.insert_ebl_error
                                   (p_cust_doc_id,
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
-- ERROR_CODE = 'XXOD_EBL_034'
-- ERROR_MESSAGE = ''
-- To make sure that if Alignment is not null then PaddingChar can not be null.
--
----------------------------------------------------------------------------
        /*
         gc_error_code := 'XXOD_EBL_034';

         IF p_alignment IS NOT NULL AND p_padding_char IS NULL
         THEN
            gc_error_message := '';
            gc_insert_fun_status :=
               xx_cdh_ebl_validate_pkg.insert_ebl_error
                                   (p_cust_doc_id,
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
         */
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
            xx_cdh_ebl_validate_pkg.insert_ebl_error
                                   (p_cust_doc_id,
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
            xx_cdh_ebl_validate_pkg.insert_ebl_error
                                    (p_cust_doc_id,
                                     gc_doc_process_date -- p_doc_process_date
                                                        ,
                                     gc_error_code             -- p_error_code
                                                  ,
                                     gc_error_message          -- p_error_desc
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
      xx_cdh_ebl_validate_pkg.delete_ebl_error (p_cust_doc_id);
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
               xx_cdh_ebl_validate_pkg.insert_ebl_error
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
                  xx_cdh_ebl_validate_pkg.insert_ebl_error
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
                  xx_cdh_ebl_validate_pkg.insert_ebl_error
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

            /*   SELECT COUNT (1)
                 INTO lc_rec_count
                 FROM XX_CDH_EBL_TEMPL_HDR_TXT
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

*/
               IF gc_validation_status = 'FALSE'
               THEN
                  gc_insert_fun_status :=
                     xx_cdh_ebl_validate_pkg.insert_ebl_error
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
                    FROM XX_CDH_EBL_TEMPL_DTL_TXT
                   WHERE cust_doc_id = p_cust_doc_id AND attribute1 = 'Y';
               ELSE
                  SELECT COUNT (1)
                    INTO lc_rec_count
                    FROM XX_CDH_EBL_TEMPL_DTL_TXT
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
                     xx_cdh_ebl_validate_pkg.insert_ebl_error
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
                  xx_cdh_ebl_validate_pkg.validate_ebl_main
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
                  xx_cdh_ebl_validate_pkg.validate_ebl_transmission
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
                  xx_cdh_ebl_validate_pkg.insert_ebl_error
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

            gc_error_code := 'LOOP4';

            FOR lcu_get_ebill_contact IN (SELECT *
                                            FROM xx_cdh_ebl_contacts
                                           WHERE cust_doc_id = p_cust_doc_id)
            LOOP
               gc_insert_fun_status :=
                  xx_cdh_ebl_validate_pkg.validate_ebl_contacts
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
                  AND field_id =
                         (SELECT val.source_value1
                            FROM xx_fin_translatedefinition def,
                                 xx_fin_translatevalues val
                           WHERE def.translate_id = val.translate_id
                             AND def.translation_name =
                                                   'XX_CDH_EBL_TXT_DET_FIELDS'
                             AND val.enabled_flag = 'Y'
                             AND val.source_value8 = 'Y'
                             AND val.source_value1 IS NOT NULL
                             AND val.source_value2 IS NOT NULL
                             AND val.source_value2 = 'Sequence');

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
                     xx_cdh_ebl_validate_pkg.insert_ebl_error
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
                  validate_ebl_file_name_txt
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
/*
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
-- End of eBill Conf Header Details.*/
----------------------------------------------------------------------------
-- Starting eBill Conf Details.
----------------------------------------------------------------------------
            gc_error_code := 'LOOP7';

           /* FOR lcu_get_ebill_conf_dtl IN (SELECT *
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
            */
         -- End of eBill Conf Details.
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
                        xx_cdh_ebl_validate_pkg.insert_ebl_error
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

                /*
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
                        xx_cdh_ebl_validate_pkg.insert_ebl_error
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
 */
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
                     xx_cdh_ebl_validate_pkg.insert_ebl_error
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
            xx_cdh_ebl_validate_pkg.insert_ebl_error
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
   END validate_final;
END xx_cdh_ebl_validate_txt_pkg;

/

SHOW ERROR;
