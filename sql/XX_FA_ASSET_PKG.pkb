create or replace PACKAGE BODY XX_FA_ASSET_PKG
AS
   -- +===================================================================================+
   -- |              Office Depot - Project Merge                                         |
   -- |                                                                                   |
   -- +===================================================================================+
   -- | Name :       FA Mass Additions Conversion  Program                                |
   -- | Description :To convert the active assets for both the SAP data and the PWC data  |
   -- |              from custom staging tables to Oracle Productin tables                |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version       Date              Author              Remarks                        |
   -- |=======       ==========    =============        =======================           |
   -- |  1.0         06-JUN-2007   Sayeed Ahamed        Applied Build Standards           |
   -- |  2.0         06-JUN-2014   Mark Schmit          Modified for Merge Project        |
   -- |  3.0         16-Feb-2015   Paddy Sanjeevi       Modified procedure definitions    |
   -- |  4.0         4-Mar-2015    Mark Schmit          Added Comments to include defect #|
   -- |              Removed E12 error in VALIDATE_DATA as per Defect #624                |
   -- |              Revised code from CR1304 to include recalc of CC_ID as per defect #627             |
   -- |              Revised the date for the NEW/USED calc from ASSERPR14 rule per defect #644         |
   -- |              Revised procedures to be called individually from Conc Managers by                 |
   -- |                      including error code returns from CCR as per Defect #730                   |
   -- |              Removed loop in LOAD_TAX dealing with DEPRN_FLAG load as per Defect #731           |
   -- |              Revised PWC logic to take a newly passed value to calc life as per Defect #732/747 |
   -- |              Revised code to loop by asset within a loop by book as er defect #787|
   -- |  4.1         25-Mar-2015    Mark Schmit          DPIS date math for defect #976   |
   -- |  4.2         31-Mar-2015    Mark Schmit          Multiple rows returned from tax book validate for defect ??? |
   -- +===================================================================================+
   -- +===================================================================================+
   -- | Name        :GET_DEFAULTS                                                         |
   -- | Description :Populate default values in XX_FA_MASS_ADDITIONS_STG and              |
   -- |              XX_FA_TAX_INTERFACE_STG                                              |
   -- | Parameters:  p_batch_id, p_validate_flag                                          |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE GET_DEFAULTS (p_validate_flag IN VARCHAR2)
   AS
      lc_login_id   VARCHAR2 (25) := fnd_global.login_id;
      lc_user_id    VARCHAR2 (25) := fnd_global.user_id;
   BEGIN
      IF p_validate_flag = 'S'
      THEN
         BEGIN
            UPDATE XX_FA_MASS_ADDITIONS_STG                  -- RULE ASSETPR01
               SET ACCOUNTING_DATE = SYSDATE,
                   ASSET_NUMBER = LTRIM (asset_number, '0'),
                   ASSET_TYPE = 'CAPITALIZED',
                   BOOK_TYPE_CODE = gb_corp_book_name,
                   CLASS = LTRIM (class, '0'),
                   CONTEXT = SYSDATE,
                   COMPANY_CODE = LTRIM (company_code, '0'),
                   CONV_ACTION = 'CONV',                     -- RULE ASSETPR02
                   COST_CENTER = LTRIM (cost_center, '0'),
                   CREATED_BY = lc_user_id,
                   CREATION_DATE = SYSDATE,
                   DEPRECIATE_FLAG = 'YES',
                   DEPRN_METHOD_CODE = 'STL',
                   FEEDER_SYSTEM_NAME = 'SAP',
                   LAST_UPDATE_DATE = SYSDATE,
                   LAST_UPDATED_BY = lc_user_id,
                   LAST_UPDATE_LOGIN = lc_login_id,
                   POSTING_STATUS = 'POST',
                   PROCESS_FLAG = 1,
                   PRORATE_CONVENTION_CODE = 'MID MONTH',
                   QUEUE_NAME = 'POST',
                   SOURCE_SYSTEM_CODE = 'U1SAP',             -- RULE ASSETPR02
                   SOURCE_SYSTEM_REF = 'ODN SAP Conversion'  -- RULE ASSETPR02
             WHERE process_flag IS NULL;

            COMMIT;

            UPDATE xx_fa_mass_additions_stg                  -- RULE ASSETPR02
               SET mass_addition_id = xx_fa_mass_additions_stg_s.NEXTVAL
             WHERE process_flag = 1;

            UPDATE xx_fa_mass_additions_stg                  -- RULE ASSETPR02
               SET control_id = mass_addition_id
             WHERE process_flag = 1;

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'GET_DEFAULTS',
                  p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                  p_staging_column_name    => '',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => 'No default values loaded for XX_FA_MASS_ADDITIONS_STG table',
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE xx_fa_mass_additions_stg
                  SET process_flag = 3, error_message = 'E4';
         END;
      ELSIF p_validate_flag = 'P'
      THEN
         BEGIN
            UPDATE XX_FA_TAX_INTERFACE_STG                   -- RULE ASSETPR01
               SET CALC_DEPRECIATE_FLAG = 'Y',
                   CALC_YTD_DEPRN = 0,
                   CREATED_BY = lc_user_id,
                   CREATION_DATE = SYSDATE,
                   LAST_UPDATE_DATE = SYSDATE,
                   LAST_UPDATED_BY = lc_user_id,
                   LAST_UPDATE_LOGIN = lc_login_id,
                   PROCESS_FLAG = 1,
                   SOURCE_SYSTEM_CODE = 'U1SAP',             -- RULE ASSETPR02
                   SOURCE_SYSTEM_REF = 'ODN SAP Conversion'; -- RULE ASSETPR02

            COMMIT;

            UPDATE XX_FA_TAX_INTERFACE_STG                   -- RULE ASSETPR02
               SET tax_interface_id = xx_fa_tax_interface_stg_s.NEXTVAL;

            UPDATE XX_FA_TAX_INTERFACE_STG                   -- RULE ASSETPR02
               SET control_id = tax_interface_id;

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'GET_DEFAULTS',
                  p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                  p_staging_column_name    => '',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => 'No default values loaded for XX_FA_TAX_INTERFACE_STG table',
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE xx_fa_tax_interface_stg
                  SET process_flag = 3, error_message = 'E5';
         END;
      END IF;
   END GET_DEFAULTS;

   -- +===================================================================================+
   -- | Name        :MASTER                                                               |
   -- | Description :It creates the batches of FA Mass additions transactions             |
   -- |              from the custom staging table XX_FA_MASS_ADDITIONS_STG               |
   -- |              and calls the needed CHILD procedure for each batch.                 |
   -- | Parameters:  x_err_buf, x_ret_code, p_process_name,                               |
   -- |              p_validate_flag, p_reset_status_flag                                 |
   -- |                                                                                   |
   -- | Returns   :  Error Buffer, Return Code                                            |
   -- +===================================================================================+
   PROCEDURE MASTER (x_errbuf              OUT NOCOPY VARCHAR2,
                     x_retcode             OUT NOCOPY VARCHAR2,
                     p_validate_flag    IN            VARCHAR2,
                     p_corp_book        IN            VARCHAR2,
                     p_fed_book         IN            VARCHAR2,
                     p_state_book       IN            VARCHAR2,
                     p_fed_ace_book     IN            VARCHAR2,
                     p_fed_amt_book     IN            VARCHAR2,
                     p_state_amt_book   IN            VARCHAR2)
   IS
      ln_batch_id              NUMBER := 0;
      ln_par_conc_request_id   fnd_concurrent_requests.request_id%TYPE;
      ln_conversion_id         xx_com_conversions_conv.conversion_id%TYPE;
      lc_source_system_code    xx_com_conversions_conv.system_code%TYPE;
      lc_error_message         VARCHAR2 (100);
   BEGIN
      ln_par_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID ();
      -- Set the names of the tax books passed into the MASTER procedure
      gb_corp_book_name := p_corp_book;
      gb_fed_book_name := p_fed_book;
      gb_state_book_name := p_state_book;
      gb_fed_ace_book_name := p_fed_ace_book;
      gb_fed_amt_book_name := p_fed_amt_book;
      gb_state_amt_book_name := p_state_amt_book;
      --For parameter printing
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parameters');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Validate Flag: ' || p_validate_flag);
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');

      --Generating the BATCH_ID from the Sequence
      SELECT xx_fa_mass_additions_batch_s.NEXTVAL
        INTO ln_batch_id
        FROM SYS.DUAL;

      --  DBMS_OUTPUT.put_line ('Start MASTER');
      IF p_validate_flag = 'S'
      THEN
         -- Set Batch ID
         UPDATE xx_fa_mass_additions_stg
            SET batch_id = ln_batch_id;
      ELSIF p_validate_flag = 'P'
      THEN
         -- Set Batch ID
         UPDATE xx_fa_tax_interface_stg
            SET batch_id = ln_batch_id;
      END IF;

      COMMIT;
      CHILD (p_validate_flag => p_validate_flag);
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_message := 'Unable to set BATCH_ID in MASTER';
         XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
            p_conversion_id          => ln_conversion_id,
            p_record_control_id      => '',
            p_source_system_code     => lc_source_system_code,
            p_package_name           => 'XX_FA_ASSET_PKG',
            p_procedure_name         => 'MASTER',
            p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
            p_staging_column_name    => '',
            p_staging_column_value   => '',
            p_source_system_ref      => '',
            p_batch_id               => '',
            p_exception_log          => lc_error_message,
            p_oracle_error_code      => SQLCODE,
            p_oracle_error_msg       => SQLERRM);

         UPDATE xx_fa_mass_additions_stg
            SET process_flag = 3, error_message = 'E1';

         COMMIT;
         FND_FILE.PUT_LINE (FND_FILE.LOG,
                            'Error in Master procedure :' || SQLERRM);
         x_errbuf := SUBSTR (SQLERRM, 1, 150);
         x_retcode := '2';
   END MASTER;

   -- +===================================================================================+
   -- | Name        :CHILD                                                                |
   -- | Description :To populate defaults and validate data for each batch                |
   -- | Parameters : p_process_name, p_validate_flag, p_reset_status_flag, p_batch_id     |
   -- |                                                                                   |
   -- | Returns    : None                                                                 |
   -- +===================================================================================+
   PROCEDURE CHILD (p_validate_flag IN VARCHAR2)
   AS
      ln_chi_conc_request_id   fnd_concurrent_requests.request_id%TYPE;
      lc_error_message         VARCHAR2 (100);
      ln_conversion_id         xx_com_conversions_conv.conversion_id%TYPE;
      lc_source_system_code    xx_com_conversions_conv.system_code%TYPE;
   BEGIN
      ln_chi_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID ();
      --Printing the Parameters
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parameters: ');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Validate Flag: ' || p_validate_flag);
      --      DBMS_OUTPUT.PUT_LINE ('Validate Flag: ' || p_validate_flag);
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');

      --   DBMS_OUTPUT.put_line ('Start CHILD');
      IF p_validate_flag = 'S'
      THEN
         VALIDATE_DATA (p_validate_flag => p_validate_flag);
      ELSIF p_validate_flag = 'P'
      THEN
         VALIDATE_DATA (p_validate_flag => p_validate_flag);
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_message :=
            'Unable to call VALIDATE_DATA procedure from CHILD';
         XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
            p_conversion_id          => ln_conversion_id,
            p_record_control_id      => '',
            p_source_system_code     => lc_source_system_code,
            p_package_name           => 'XX_FA_ASSET_PKG',
            p_procedure_name         => 'CHILD',
            p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
            p_staging_column_name    => '',
            p_staging_column_value   => '',
            p_source_system_ref      => '',
            p_batch_id               => '',
            p_exception_log          => lc_error_message,
            p_oracle_error_code      => SQLCODE,
            p_oracle_error_msg       => SQLERRM);

         UPDATE xx_fa_mass_additions_stg
            SET process_flag = 3, error_message = error_message || ' E2';

         COMMIT;
   END CHILD;

   -- +===================================================================================+
   -- | Name        :VALIDATE_DATA                                                        |
   -- | Description :It validates all the incoming data                                   |
   -- | Parameters:  p_process_name, p_validate_flag, p_reset_status_flag, p_batch_id     |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE VALIDATE_DATA (p_validate_flag IN VARCHAR2)
   AS
      --Cursor For Assigning Batch ID
      CURSOR c_record_type (p_system_code VARCHAR2)
      IS
           SELECT DISTINCT book_type_code
             FROM xx_fa_mass_additions_stg
            WHERE source_system_code = p_system_code                  -- U1SAP
         --  AND process_flag !=3
         GROUP BY book_type_code;

      --Cursor For Creating Asset Category
      CURSOR c_class_category
      IS
         SELECT DISTINCT class FROM xx_fa_mass_additions_stg;

      --WHERE process_flag != 3;
      --Cursor For Modifying Asset Category
      CURSOR c_new_class_category
      IS
         SELECT class, company_code
           FROM xx_fa_mass_additions_stg
          WHERE class = '1752' AND company_code LIKE '6%';

      -- WHERE     process_flag != 3;
      --Cursor For Checking Duplicate Records
      CURSOR c_dup_asset
      IS
         SELECT asset_number, company_code FROM xx_fa_mass_additions_stg;

      -- WHERE process_flag != 3;
      --Cursor For Checking DPIS
      CURSOR c_dpis
      IS
         SELECT asset_number, company_code, sap_date_placed_in_service
           FROM xx_fa_mass_additions_stg;

      --  WHERE process_flag != 3;
      lc_error_message         VARCHAR2 (1000);
      lc_source_system_code    xx_com_conversions_conv.system_code%TYPE;
      ln_conversion_id         xx_com_conversions_conv.conversion_id%TYPE;
      ln_par_conc_request_id   fnd_concurrent_requests.request_id%TYPE;
      l_category_id            fa_categories_b.category_id%TYPE;
      l_category_segments      VARCHAR2 (200);
      l_property_1245          fa_categories_b.property_1245_1250_code%TYPE;
      l_property_type          fa_categories_b.property_type_code%TYPE;
      l_seg1                   fa_categories_b.segment1%TYPE;
      l_seg2                   fa_categories_b.segment2%TYPE;
      l_seg3                   fa_categories_b.segment3%TYPE;
      l_trans_id               xx_fin_translatedefinition.translate_id%TYPE;
   BEGIN
      ln_par_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID ();
      --For parameter printing
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parameters');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Validate Flag: ' || p_validate_flag);
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');

      --   DBMS_OUTPUT.put_line ('Start VALIDATE');
      IF p_validate_flag = 'S'
      THEN
         -- Set Defaults
         GET_DEFAULTS (p_validate_flag => p_validate_flag);
         COMMIT;

         --Updating the  Batch_id,process flag
         UPDATE xx_fa_mass_additions_stg
            SET process_flag = 2
          WHERE process_flag != 3;
      ELSIF p_validate_flag = 'P'
      THEN
         -- Set Defaults
         GET_DEFAULTS (p_validate_flag => p_validate_flag);
         COMMIT;

         --Updating the  Batch_id,process flag
         UPDATE xx_fa_tax_interface_stg
            SET process_flag = 2
          WHERE process_flag != 3;
      END IF;

      COMMIT;

      IF p_validate_flag = 'S'
      THEN
         -- Check for bad data:
         BEGIN
            UPDATE XX_FA_MASS_ADDITIONS_STG
               SET cost_center = LPAD (cost_center, 4, '0')
             WHERE LENGTH (cost_center) < 4;

            COMMIT;

            UPDATE XX_FA_MASS_ADDITIONS_STG
               SET process_flag = 3, error_message = error_message || ' E6'
             WHERE cost_center IS NULL;

            COMMIT;

            -- Populate Defaults for system wide columns
            -- ASSET_CATEGORY_ID
            -- DEPRECIATE_FLAG
            -- PROPERTY_1245_1250_CODE
            -- PROPERTY_TYPE_CODE
            UPDATE XX_FA_MASS_ADDITIONS_STG                  -- RULE ASSETPR10
               SET depreciate_flag = 'NO',
                   --     DEPRN_METHOD_CODE = 'MANU',
                   calc_amortize_flag = NULL,
                   calc_amortize_nbv_flag = NULL,
                   calc_amortization_start_date = NULL
             WHERE     SAP_DEPRN_METHOD_CODE = 'MANU'
                   AND COST_CENTER = '2640'
                   AND COMPANY_CODE = '2100';

            COMMIT;

            --Ignore the 1415 and 4001 SAP Class records
            UPDATE xx_fa_mass_additions_stg                  -- RULE ASSETPR19
               SET process_flag = 3, error_message = error_message || ' E42'
             WHERE (class = '1415' OR CLASS LIKE '4%');

            COMMIT;

            -- Populate Attribute Defaults
            UPDATE XX_FA_MASS_ADDITIONS_STG
               SET attribute6 =                              -- RULE ASSETPR9A
                         TRIM (company_code)
                      || '-'
                      || TRIM (class)
                      || '-'
                      || TRIM (asset_number)
                      || '-'
                      || TRIM (cost_center),
                   attribute10 =
                      TRIM (asset_number) || '-' || TRIM (company_code); -- RULE ASSETPR9B

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'Unable to calculate mass defaults in VALIDATE_DATA - MASS ADDITIONS';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => ln_conversion_id,
                  p_record_control_id      => '',
                  p_source_system_code     => lc_source_system_code,
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                  p_staging_column_name    => '',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE xx_fa_mass_additions_stg
                  SET process_flag = 3,
                      error_message = error_message || ' E41';
         END;

         BEGIN
            UPDATE XX_FA_MASS_ADDITIONS_STG
               SET net_book_value =
                      TO_NUMBER (REPLACE (raw_net_book_value, CHR (13)));

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'NET_BOOK_VALUE does not translate to a valid NUMBER';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => ln_conversion_id,
                  p_record_control_id      => '',
                  p_source_system_code     => lc_source_system_code,
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                  p_staging_column_name    => 'NET_BOOK_VALUE',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE xx_fa_mass_additions_stg
                  SET process_flag = 3,
                      error_message = error_message || ' E47';
         END;

         BEGIN
            SELECT translate_id
              INTO l_trans_id
              FROM xx_fin_translatedefinition
             WHERE translation_name = 'XXFA_CLASS_CATEGORY';

            FOR lcu_class IN c_class_category
            LOOP
               BEGIN                                         -- RULE ASSETPR03
                  SELECT target_value1, target_value2, target_value3
                    INTO l_seg1, l_seg2, l_seg3
                    FROM xx_fin_translatevalues
                   WHERE     source_value1 = lcu_class.class
                         AND translate_id = l_trans_id;

                  -- Update asset_category_id
                  SELECT category_id,
                         property_1245_1250_code,
                         property_type_code,
                         segment1 || '.' || segment2 || '.' || segment3
                    INTO l_category_id,
                         l_property_1245,
                         l_property_type,
                         l_category_segments
                    FROM FA_CATEGORIES_B
                   WHERE     segment1 = l_seg1
                         AND segment2 = l_seg2
                         AND segment3 = l_seg3;

                  IF l_seg1 = 'LAND' AND l_seg2 = 'LAND' AND l_seg3 = 'NONE'
                  THEN                                       -- RULE ASSETPR08
                                                             -- RULE ASSETPR10
                     UPDATE XX_FA_MASS_ADDITIONS_STG
                        SET asset_category_id = l_category_id,
                            depreciate_flag = 'NO',
                            property_1245_1250_code = l_property_1245,
                            property_type_code = l_property_type,
                            calc_asset_category_segments = l_category_segments
                      WHERE class = lcu_class.class;
                  ELSE
                     UPDATE XX_FA_MASS_ADDITIONS_STG
                        SET asset_category_id = l_category_id,
                            property_1245_1250_code = l_property_1245,
                            property_type_code = l_property_type,
                            calc_asset_category_segments = l_category_segments
                      WHERE class = lcu_class.class;
                  END IF;

                  COMMIT;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_error_message :=
                        'Unable to set Class/Category in VALIDATE_DATA';
                     XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                        p_conversion_id          => '',
                        p_record_control_id      => '',
                        p_source_system_code     => '',
                        p_package_name           => 'XX_FA_ASSET_PKG',
                        p_procedure_name         => 'MASTER',
                        p_staging_table_name     => 'XX_FIN_TRANSLATEVALUES',
                        p_staging_column_name    => 'TRANSLATE_ID',
                        p_staging_column_value   => 'XXFA_CLASS_CATEGORY',
                        p_source_system_ref      => '',
                        p_batch_id               => '',
                        p_exception_log          => lc_error_message,
                        p_oracle_error_code      => SQLCODE,
                        p_oracle_error_msg       => SQLERRM);

                     UPDATE XX_FA_MASS_ADDITIONS_STG
                        SET asset_category_id = NULL,
                            process_flag = 3,
                            error_message = error_message || ' E7'
                      WHERE class = lcu_class.class;
               END;
            END LOOP;

            BEGIN
               SELECT category_id,
                      property_1245_1250_code,
                      property_type_code,
                      segment1 || '.' || segment2 || '.' || segment3
                 INTO l_category_id,
                      l_property_1245,
                      l_property_type,
                      l_category_segments
                 FROM FA_CATEGORIES_B
                WHERE     segment1 = 'SOFTWARE'
                      AND segment2 = 'SWINT 03'
                      AND segment3 = 'NONE';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lc_error_message :=
                     'Unable to look up class/category for SOFTWARE.SWINT 03.NONE';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => '',
                     p_record_control_id      => '',
                     p_source_system_code     => '',
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'VALIDATE_DATA',
                     p_staging_table_name     => 'XX_FIN_TRANSLATEVALUES',
                     p_staging_column_name    => 'CATEGORY_ID',
                     p_staging_column_value   => 'XXFA_CLASS_CATEGORY',
                     p_source_system_ref      => '',
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);

                  UPDATE XX_FA_MASS_ADDITIONS_STG
                     SET asset_category_id = NULL,
                         process_flag = 3,
                         error_message = error_message || ' E8';
            END;

            FOR lcu_class IN c_new_class_category            -- RULE ASSETPR03
            LOOP
               BEGIN
                  UPDATE XX_FA_MASS_ADDITIONS_STG
                     SET asset_category_id = l_category_id,
                         property_1245_1250_code = l_property_1245,
                         property_type_code = l_property_type,
                         calc_asset_category_segments = l_category_segments
                   WHERE     class = lcu_class.class
                         AND company_code = lcu_class.company_code;

                  COMMIT;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_error_message :=
                        'Unable to update asset category segments for specified Class in VALIDATE_DATA';
                     XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                        p_conversion_id          => '',
                        p_record_control_id      => '',
                        p_source_system_code     => '',
                        p_package_name           => 'XX_FA_ASSET_PKG',
                        p_procedure_name         => 'VALIDATE_DATA',
                        p_staging_table_name     => 'XX_FIN_TRANSLATEVALUES',
                        p_staging_column_name    => 'TRANSLATE_ID',
                        p_staging_column_value   => 'XXFA_CLASS_CATEGORY',
                        p_source_system_ref      => '',
                        p_batch_id               => '',
                        p_exception_log          => lc_error_message,
                        p_oracle_error_code      => SQLCODE,
                        p_oracle_error_msg       => SQLERRM);

                     UPDATE XX_FA_MASS_ADDITIONS_STG
                        SET asset_category_id = NULL,
                            process_flag = 3,
                            error_message = error_message || ' E9'
                      WHERE     class = lcu_class.class
                            AND company_code = lcu_class.company_code;
               END;
            END LOOP;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lc_error_message :=
                  'XXFA_CLASS_CATEGORY lookup not defined in VALIDATE_DATA';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FIN_TRANSLATEDEFINITION',
                  p_staging_column_name    => 'TRANSLATE_ID',
                  p_staging_column_value   => 'XXFA_CLASS_CATEGORY',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE XX_FA_MASS_ADDITIONS_STG
                  SET asset_category_id = NULL,
                      process_flag = 3,
                      error_message = error_message || ' E10';
         END;

         BEGIN
            UPDATE xx_fa_mass_additions_stg                  -- RULE ASSETPR16
               SET process_flag = 3, error_message = error_message || ' E11'
             WHERE company_code || asset_number IN (  SELECT    company_code
                                                             || asset_number
                                                        FROM xx_fa_mass_additions_stg
                                                      HAVING COUNT (
                                                                   company_code
                                                                || asset_number) >
                                                                1
                                                    GROUP BY    company_code
                                                             || asset_number);

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'Duplicate records found in XX_FA_MASS_ADDITIONS_STG table';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                  p_staging_column_name    => 'ASSET_ID',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);
         END;

         BEGIN
            FOR lcu_dpis IN c_dpis
            LOOP
               BEGIN                             -- RULE ASSETPR18
                  UPDATE XX_FA_MASS_ADDITIONS_STG
                     SET date_placed_in_service = TO_DATE (sap_date_placed_in_service, 'RRRRMMDD')
                   WHERE     asset_number = lcu_dpis.asset_number
                         AND company_code = lcu_dpis.company_code;
                  COMMIT;
                  UPDATE XX_FA_MASS_ADDITIONS_STG -- ADDED 25-Mar-2015 from defect 976
                     SET date_placed_in_service = TO_DATE ('06-NOV-2013', 'DD-MON-RRRR')
                   WHERE nvl(date_placed_in_service, '01-NOV-2013') < '06-NOV-2013';
                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_error_message :=
                        'Raw data for DPIS cannot be translated into an Oracle DATE';
                     XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                        p_conversion_id          => '',
                        p_record_control_id      => '',
                        p_source_system_code     => '',
                        p_package_name           => 'XX_FA_ASSET_PKG',
                        p_procedure_name         => 'VALIDATE_DATA',
                        p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                        p_staging_column_name    => 'SAP_DATE_PLACED_INTO_SERVICE',
                        p_staging_column_value   => '',
                        p_source_system_ref      => '',
                        p_batch_id               => '',
                        p_exception_log          => lc_error_message,
                        p_oracle_error_code      => SQLCODE,
                        p_oracle_error_msg       => SQLERRM);

                     UPDATE XX_FA_MASS_ADDITIONS_STG
                        SET process_flag = 3,
                            error_message = error_message || 'E13'
                      WHERE     asset_number = lcu_dpis.asset_number
                            AND company_code = lcu_dpis.company_code;
               END;
            END LOOP;
         END;

         COMMIT;
         TRANSLATE_DATA (p_validate_flag => p_validate_flag);
      ELSIF p_validate_flag = 'P'
      THEN
         BEGIN                                               -- RULE ASSETPR01
            UPDATE XX_FA_TAX_INTERFACE_STG
               SET process_flag = 3, error_message = error_message || ' E14'
             WHERE pwc_asset_nbr IS NULL;

            UPDATE XX_FA_TAX_INTERFACE_STG
               SET process_flag = 3, error_message = error_message || ' E15'
             WHERE pwc_book_desc IS NULL;

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'Duplicate records found in XX_FA_TAX_INTERFACE_STG table';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                  p_staging_column_name    => 'PWC_ASSET_NBR',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);
         END;

         BEGIN                                               -- RULE ASSETPR25
            UPDATE XX_FA_TAX_INTERFACE_STG
               SET calc_book_type_code = gb_fed_book_name
             WHERE book = 'BK1';

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'BK1 records not updated with book_type_code';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                  p_staging_column_name    => 'PWC_BOOK_TYPE_CODE',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE XX_FA_TAX_INTERFACE_STG
                  SET process_flag = 3,
                      error_message = error_message || ' E16'
                WHERE book = 'BK1';
         END;

         BEGIN                                               -- RULE ASSETPR25
            UPDATE XX_FA_TAX_INTERFACE_STG
               SET calc_book_type_code = gb_fed_ace_book_name
             WHERE book = 'BK2';

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'BK2 records not updated with book_type_code';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                  p_staging_column_name    => 'PWC_BOOK_TYPE_CODE',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE XX_FA_TAX_INTERFACE_STG
                  SET process_flag = 3,
                      error_message = error_message || ' E17'
                WHERE book = 'BK2';
         END;

         BEGIN                                               -- RULE ASSETPR25
            UPDATE XX_FA_TAX_INTERFACE_STG
               SET calc_book_type_code = gb_state_book_name
             WHERE book = 'BK3';

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'BK3 records not updated with book_type_code';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                  p_staging_column_name    => 'PWC_BOOK_TYPE_CODE',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE XX_FA_TAX_INTERFACE_STG
                  SET process_flag = 3,
                      error_message = error_message || ' E18'
                WHERE book = 'BK3';
         END;

         BEGIN                                               -- RULE ASSETPR25
            UPDATE XX_FA_TAX_INTERFACE_STG
               SET calc_book_type_code = gb_fed_amt_book_name
             WHERE book = 'BK4';

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'BK4 records not updated with book_type_code';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                  p_staging_column_name    => 'PWC_BOOK_TYPE_CODE',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE XX_FA_TAX_INTERFACE_STG
                  SET process_flag = 3,
                      error_message = error_message || ' E19'
                WHERE book = 'BK4';
         END;

         BEGIN                                               -- RULE ASSETPR25
            UPDATE XX_FA_TAX_INTERFACE_STG
               SET calc_book_type_code = gb_state_amt_book_name
             WHERE book = 'BK5';

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'BK5 records not updated with book_type_code';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                  p_staging_column_name    => 'PWC_BOOK_TYPE_CODE',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE XX_FA_TAX_INTERFACE_STG
                  SET process_flag = 3,
                      error_message = error_message || ' E20'
                WHERE book = 'BK5';
         END;

         BEGIN                                               -- RULE ASSETPR26
            UPDATE XX_FA_TAX_INTERFACE_STG
               SET calc_depreciate_flag = 'N'
             WHERE pwc_asset_class_desc = 'Non-Depreciable Land';
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'Unable to set calc_depreciate_flag in VALIDATE_DATA';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => '',
                  p_record_control_id      => '',
                  p_source_system_code     => '',
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'VALIDATE_DATA',
                  p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                  p_staging_column_name    => 'CALC_DEPRECIATE_FLAG',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE XX_FA_TAX_INTERFACE_STG
                  SET process_flag = 3,
                      error_message = error_message || ' E21'
                WHERE pwc_asset_class_desc = 'Non-Depreciable Land';
         END;

         COMMIT;
         TRANSLATE_DATA (p_validate_flag => p_validate_flag);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_message := 'Unable to execute VALIDATE_DATA procedure';
         XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
            p_conversion_id          => ln_conversion_id,
            p_record_control_id      => '',
            p_source_system_code     => lc_source_system_code,
            p_package_name           => 'XX_FA_ASSET_PKG',
            p_procedure_name         => 'VALIDATE_DATA',
            p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
            p_staging_column_name    => '',
            p_staging_column_value   => '',
            p_source_system_ref      => '',
            p_batch_id               => '',
            p_exception_log          => lc_error_message,
            p_oracle_error_code      => SQLCODE,
            p_oracle_error_msg       => SQLERRM);

         UPDATE xx_fa_mass_additions_stg
            SET process_flag = 3, error_message = error_message || ' E3';
   END VALIDATE_DATA;

   -- +===================================================================================+
   -- | Name        :TRANSLATE_DATA                                                       |
   -- | Description :To perform needed translations on the incoming data                  |
   -- | Parameters:  p_process_name, p_validate_flag, p_reset_status_flag, p_batch_id     |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE TRANSLATE_DATA (p_validate_flag IN VARCHAR2)
   AS
      CURSOR c_proc_rec
      IS
         SELECT * FROM xx_fa_mass_additions_stg;

      --WHERE process_flag != '3';
      CURSOR c_proc_tax_book_rec
      IS
         SELECT DISTINCT book FROM xx_fa_tax_interface_stg;

      CURSOR c_proc_tax_rec
      IS
         SELECT *
           FROM xx_fa_tax_interface_stg
          WHERE book = ln_book_loop;

      --  WHERE process_flag != '3';

      lc_error_message             VARCHAR2 (1000);
      lc_source_system_code        xx_com_conversions_conv.system_code%TYPE;
      lc_pwc_val                   VARCHAR2 (1);
      lc_sap_val                   VARCHAR2 (1);
      ln_amortize_flag             fa_mass_additions.amortize_flag%TYPE;
      ln_amortize_nbv_flag         fa_mass_additions.amortize_nbv_flag%TYPE;
      ln_amortization_start_date   fa_mass_additions.amortization_start_date%TYPE;
      ln_attribute7                fa_mass_additions.payables_cost%TYPE;
      ln_attribute8                fa_mass_additions.attribute8%TYPE;
      ln_calc_asset_id             xx_fa_tax_interface_stg.calc_asset_id%TYPE;
      ln_calc_asset_number         xx_fa_tax_interface_stg.calc_asset_number%TYPE;
      ln_calc_dpis                 xx_fa_tax_interface_stg.calc_dpis%TYPE;
      ln_calc_deprn_method_code    xx_fa_tax_interface_stg.calc_deprn_method_code%TYPE;
      ln_calc_prorate_cc           xx_fa_tax_interface_stg.calc_prorate_cc%TYPE;
      ln_calc_life                 xx_fa_tax_interface_stg.calc_life%TYPE;
      ln_category_id               xx_fa_mass_additions_stg.asset_category_id%TYPE;
      ln_conversion_id             xx_com_conversions_conv.conversion_id%TYPE;
      ln_cost                      fa_mass_additions.fixed_assets_cost%TYPE;
      ln_count                     NUMBER := 1;
      ln_seg1                  VARCHAR2 (4);
      ln_seg2                  VARCHAR2 (5);
      ln_seg3                  VARCHAR2 (8);
      ln_seg4                  VARCHAR2 (6);
      ln_seg5                  VARCHAR2 (4);
      ln_seg6                  VARCHAR2 (2);
      ln_seg7                  VARCHAR2 (6);
      lnp_seg1                  VARCHAR2 (4);
      lnp_seg2                  VARCHAR2 (5);
      lnp_seg3                  VARCHAR2 (8);
      lnp_seg4                  VARCHAR2 (6);
      lnp_seg5                  VARCHAR2 (4);
      lnp_seg6                  VARCHAR2 (2);
      lnp_seg7                  VARCHAR2 (6);
      ln_exp_seg1                  VARCHAR2 (4);
      ln_exp_seg2                  VARCHAR2 (5);
      ln_exp_seg3                  FA_CATEGORY_BOOKS.DEPRN_EXPENSE_ACCT%TYPE;
      ln_exp_seg4                  VARCHAR2 (6);
      ln_exp_seg5                  VARCHAR2 (4);
      ln_exp_seg6                  VARCHAR2 (2);
      ln_exp_seg7                  VARCHAR2 (6);
      ln_new_used                  VARCHAR2 (4);
      ln_pay_seg1                  VARCHAR2 (4);
      ln_pay_seg2                  VARCHAR2 (5);
      ln_pay_seg3                  FA_CATEGORY_BOOKS.DEPRN_EXPENSE_ACCT%TYPE;
      ln_pay_seg4                  VARCHAR2 (6);
      ln_pay_seg5                  VARCHAR2 (4);
      ln_pay_seg6                  VARCHAR2 (2);
      ln_pay_seg7                  VARCHAR2 (6);
      ln_segment_1                 VARCHAR2 (4);
      ln_segment_2                 VARCHAR2 (5);
      ln_segment_3                 FA_CATEGORY_BOOKS.DEPRN_EXPENSE_ACCT%TYPE;
      ln_segment_4                 VARCHAR2 (6);
      ln_segment_5                 VARCHAR2 (4);
      ln_segment_6                 VARCHAR2 (2);
      ln_segment_7                 VARCHAR2 (6);
      lnp_segment_1                VARCHAR2 (4);
      lnp_segment_2                VARCHAR2 (5);
      lnp_segment_3                FA_CATEGORY_BOOKS.DEPRN_EXPENSE_ACCT%TYPE;
      lnp_segment_4                VARCHAR2 (6);
      lnp_segment_5                VARCHAR2 (4);
      lnp_segment_6                VARCHAR2 (2);
      lnp_segment_7                VARCHAR2 (6);
      ln_life_in_months            fa_mass_additions.life_in_months%TYPE;
      ln_location_seg1             VARCHAR2 (2);
      ln_location_seg2             VARCHAR2 (4);
      ln_location_seg3             VARCHAR2 (80);
      ln_location_seg4             VARCHAR2 (80);
      ln_location_seg5             VARCHAR2 (6);
      ln_location_seg6             VARCHAR2 (10);
      ln_exp_ccid                  gl_code_combinations.code_combination_id%TYPE;
      ln_exp_segments              VARCHAR2 (50);
      ln_fixed_assets_units        fa_mass_additions.fixed_assets_units%TYPE;
      ln_location_id               xx_fa_mass_additions_stg.calc_location_id%TYPE;
      ln_location_segments         xx_fa_mass_additions_stg.calc_location_segments%TYPE;
      ln_pay_ccid                  gl_code_combinations.code_combination_id%TYPE;
      ln_pay_segments              VARCHAR2 (50);
      ln_process_flag              xx_fa_mass_additions_stg.process_flag%TYPE;
      ln_segment5                  xx_fin_translatevalues.target_value5%TYPE;
      ln_serial_number             fa_mass_additions.serial_number%TYPE;
      ln_trans_id                  NUMBER;
      ln_error_message             VARCHAR2 (2000);
   BEGIN
      --Printing the Parameters
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parameters: ');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         'Validate Only Flag: ' || p_validate_flag);
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');

      --      DBMS_OUTPUT.PUT_LINE ('Step A: ');
      --    DBMS_OUTPUT.put_line ('Start TRANSLATE');
      IF p_validate_flag = 'S'
      THEN
         FOR lcu_process_records IN c_proc_rec
         LOOP
            --Initialization for each transactions
            ln_error_message := NULL;

            BEGIN
               SELECT COUNT (*)
                 INTO ln_count
                 FROM XX_FA_TAX_INTERFACE_STG
                WHERE     lcu_process_records.attribute10 = pwc_asset_nbr
                      AND book = 'BK1';

               --       DBMS_OUTPUT.PUT_LINE ('Step B: ' || ln_count || ' ' || lcu_process_records.attribute10 );
               IF ln_count = 0
               THEN
                  lc_pwc_val := 'N';
               ELSE
                  lc_pwc_val := 'Y';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_error_message :=
                     'Unable to update asset_in_pwc flag in TRANSLATE_DATA';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => lcu_process_records.control_id,
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                     p_staging_column_name    => 'ASSET_IN_PWC',
                     p_staging_column_value   => lcu_process_records.asset_number,
                     p_source_system_ref      => lcu_process_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E22';

                  UPDATE xx_fa_mass_additions_stg
                     SET process_flag = 3,
                         error_message = error_message || ' E22'
                   WHERE attribute10 = lcu_process_records.attribute10;
            END;

            -- Translating Correct Fixed Asset Cost
            -- Correction on 3-Feb in SIT .. fixed assets cost is not to be calculated any more
            -- But keep the new_used logis as this is the only IF..THEN that uses the NOV 13 date
            ln_cost := lcu_process_records.fixed_assets_cost;

            BEGIN                                            -- RULE ASSETPR14
               IF TO_DATE (lcu_process_records.date_placed_in_service,
                           'DD-MON-RR') <= TO_DATE ('06-NOV-13', 'DD-MON-RR')
               THEN
                  ln_new_used := 'USED';
               ELSE
                  ln_new_used := 'NEW';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_error_message :=
                     'Unable to set new_used in VALIDATE_DATA';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => lcu_process_records.control_id,
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                     p_staging_column_name    => 'DATE_PLACED_IN_SERVICE',
                     p_staging_column_value   => lcu_process_records.asset_number,
                     p_source_system_ref      => lcu_process_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E51';

                  UPDATE xx_fa_mass_additions_stg
                     SET process_flag = 3,
                         error_message = error_message || ' E51'
                   WHERE     company_code = lcu_process_records.company_code
                         AND asset_number = lcu_process_records.asset_number;
            END;

            -- Validating Location Id
            BEGIN
               ln_segment_1 := NULL;
               ln_segment_2 := NULL;
               ln_segment_3 := NULL;
               ln_segment_4 := NULL;
               ln_segment_5 := NULL;
               ln_segment_6 := NULL;
               ln_location_id := NULL;
               ln_location_seg1 := NULL;
               ln_location_seg2 := NULL;
               ln_location_seg3 := NULL;
               ln_location_seg4 := NULL;
               ln_location_seg5 := NULL;
               ln_location_seg6 := NULL;
               ln_location_segments := NULL;

               SELECT target_value1
                 INTO ln_segment5
                 FROM xx_fin_translatevalues TDTL,
                      xx_fin_translatedefinition THDR
                WHERE     THDR.translate_id = TDTL.translate_id
                      AND THDR.translation_name = 'XXFA_SAP_EXP_LOCATIONS'
                      AND TDTL.source_value1 =
                             lcu_process_records.company_code
                      AND TDTL.source_value2 =
                             lcu_process_records.cost_center;

               SELECT LOCATION_ID,
                      segment1,
                      segment2,
                      segment3,
                      segment4,
                      segment5,
                      segment6,
                         segment1
                      || '|'
                      || segment2
                      || '|'
                      || segment3
                      || '|'
                      || segment4
                      || '|'
                      || segment5
                      || '|'
                      || segment6
                 INTO ln_location_id,
                      ln_location_seg1,
                      ln_location_seg2,
                      ln_location_seg3,
                      ln_location_seg4,
                      ln_location_seg5,
                      ln_location_seg6,
                      ln_location_segments
                 FROM FA_LOCATIONS
                WHERE     segment5 = ln_segment5
                      AND enabled_flag = 'Y'
                      AND end_date_active IS NULL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_error_message :=
                     'Unable to derive location segments or ID in TRANSLATE_DATA';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => lcu_process_records.control_id,
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                     p_staging_column_name    => 'CALC_LOCATION_ID',
                     p_staging_column_value   => lcu_process_records.location_id,
                     p_source_system_ref      => lcu_process_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E25';

                  UPDATE xx_fa_mass_additions_stg
                     SET process_flag = 3,
                         error_message = error_message || ' E25'
                   WHERE     company_code = lcu_process_records.company_code
                         AND asset_number = lcu_process_records.asset_number;
            END;

            -- Translating Expense Code Combination            -- RULE ASSETPR06
            BEGIN
               ln_segment_1 := NULL;
               ln_segment_2 := NULL;
               ln_segment_3 := NULL;
               ln_segment_4 := NULL;
               ln_segment_5 := NULL;
               ln_segment_6 := NULL;
               ln_segment_7 := NULL;
               ln_exp_ccid := NULL;
               ln_exp_seg1 := NULL;
               ln_exp_seg2 := NULL;
               ln_exp_seg3 := NULL;
               ln_exp_seg4 := NULL;
               ln_exp_seg5 := NULL;
               ln_exp_seg6 := NULL;
               ln_exp_seg7 := NULL;
               ln_exp_segments := NULL;

               SELECT asset_category_id
                 INTO ln_category_id -- Save this for the Payables inquiry below
                 FROM xx_fa_mass_additions_stg
                WHERE     company_code = lcu_process_records.company_code
                      AND asset_number = lcu_process_records.asset_number;

               SELECT DEPRN_EXPENSE_ACCT                           -- Segment3
                 INTO ln_segment_3
                 FROM FA_CATEGORY_BOOKS
                WHERE     category_id = ln_category_id
                      AND book_type_code = gb_corp_book_name;

               ln_segment_5 := '0000';
               ln_segment_7 := '000000';

               SELECT target_value2,
                      target_value3,
                      target_value4,
                      target_value5
                 INTO ln_segment_1,
                      ln_segment_2,
                      ln_segment_4,
                      ln_segment_6
                 FROM xx_fin_translatevalues TDTL,
                      xx_fin_translatedefinition THDR
                WHERE     THDR.translate_id = TDTL.translate_id
                      AND THDR.translation_name = 'XXFA_SAP_EXP_LOCATIONS'
                      AND TDTL.source_value1 =
                             lcu_process_records.company_code
                      AND TDTL.source_value2 =
                             lcu_process_records.cost_center;
               ln_seg1 := ln_segment_1;
               ln_seg2 := ln_segment_2;
               ln_seg3 := ln_segment_3;
               ln_seg4 := ln_segment_4;
               ln_seg5 := ln_segment_5;
               ln_seg6 := ln_segment_6;
               ln_seg7 := ln_segment_7;
               SELECT gcc.code_combination_id,
                      gcc.segment1,
                      gcc.segment2,
                      gcc.segment3,
                      gcc.segment4,
                      gcc.segment5,
                      gcc.segment6,
                      gcc.segment7,
                         gcc.segment1
                      || '|'
                      || gcc.segment2
                      || '|'
                      || gcc.segment3
                      || '|'
                      || gcc.segment4
                      || '|'
                      || gcc.segment5
                      || '|'
                      || gcc.segment6
                      || '|'
                      || gcc.segment7
                 INTO ln_exp_ccid,
                      ln_exp_seg1,
                      ln_exp_seg2,
                      ln_exp_seg3,
                      ln_exp_seg4,
                      ln_exp_seg5,
                      ln_exp_seg6,
                      ln_exp_seg7,
                      ln_exp_segments
                 FROM gl_code_combinations gcc, gl_sets_of_books sob
                WHERE     gcc.chart_of_accounts_id = sob.chart_of_accounts_id
                      AND sob.short_name = 'US_USD_P'
                      AND gcc.segment1 = ln_segment_1
                      AND gcc.segment2 = ln_segment_2
                      AND gcc.segment3 = ln_segment_3
                      AND gcc.segment4 = ln_segment_4
                      AND gcc.segment5 = ln_segment_5
                      AND gcc.segment6 = ln_segment_6
                      AND gcc.segment7 = ln_segment_7
                      AND gcc.enabled_flag = 'Y';

               --ADD LOB RECALC HERE for CR1308
               IF ln_exp_seg6 = '10'
               THEN
                  IF lcu_process_records.class LIKE '17%'
                  THEN
                     ln_exp_seg2 := '43002';
                  ELSIF lcu_process_records.class LIKE '27%'
                  THEN
                     ln_exp_seg2 := '45001';
                  END IF;
                  ln_seg1 := ln_exp_seg1;
                  ln_seg2 := ln_exp_seg2;
                  ln_seg3 := ln_exp_seg3;
                  ln_seg4 := ln_exp_seg4;
                  ln_seg5 := ln_exp_seg5;
                  ln_seg6 := ln_exp_seg6;
                  ln_seg7 := ln_exp_seg7;
                  SELECT gcc.code_combination_id,
                      gcc.segment1
                      || '|'
                      || gcc.segment2
                      || '|'
                      || gcc.segment3
                      || '|'
                      || gcc.segment4
                      || '|'
                      || gcc.segment5
                      || '|'
                      || gcc.segment6
                      || '|'
                      || gcc.segment7
                 INTO ln_exp_ccid, ln_exp_segments
                 FROM gl_code_combinations gcc, gl_sets_of_books sob
                WHERE     gcc.chart_of_accounts_id = sob.chart_of_accounts_id
                      AND sob.short_name = 'US_USD_P'
                      AND gcc.segment1 = ln_exp_seg1
                      AND gcc.segment2 = ln_exp_seg2
                      AND gcc.segment3 = ln_exp_seg3
                      AND gcc.segment4 = ln_exp_seg4
                      AND gcc.segment5 = ln_exp_seg5
                      AND gcc.segment6 = ln_exp_seg6
                      AND gcc.segment7 = ln_exp_seg7
                      AND gcc.enabled_flag = 'Y';

               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_exp_ccid := NULL;
                  ln_exp_segments := NULL;
                  lc_error_message :=
                     'Unable to derive expense code combination ID in TRANSLATE_DATA';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => lcu_process_records.control_id,
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                     p_staging_column_name    => 'EXPENSE_CODE_COMBINATION_ID',
                     p_staging_column_value   => lcu_process_records.location_code,
                     p_source_system_ref      => lcu_process_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E23';

                  UPDATE xx_fa_mass_additions_stg
                     SET process_flag = 3,
                         error_message =
                               error_message
                            || ' E23 ('
                            || lcu_process_records.asset_number
                            || ' ' ||
                               ln_seg1 || '-' ||
                               ln_seg2 || '-' ||
                               ln_seg3 || '-' ||
                               ln_seg4 || '-' ||
                               ln_seg5 || '-' ||
                               ln_seg6 || '-' ||
                               ln_seg7
                            || ') '
                   WHERE     company_code = lcu_process_records.company_code
                         AND asset_number = lcu_process_records.asset_number;
            END;

            -- Translating Payables Code Combination           -- RULE ASSETPR05
            BEGIN
               lnp_segment_1 := NULL;
               lnp_segment_2 := NULL;
               lnp_segment_3 := NULL;
               lnp_segment_4 := NULL;
               lnp_segment_5 := NULL;
               lnp_segment_6 := NULL;
               lnp_segment_7 := NULL;

               SELECT ASSET_CLEARING_ACCT                          -- Segment3
                 INTO lnp_segment_3
                 FROM FA_CATEGORY_BOOKS
                WHERE     category_id = ln_category_id
                      AND book_type_code = gb_corp_book_name;

               lnp_segment_2 := '00000';
               lnp_segment_5 := '0000';
               lnp_segment_6 := '90';
               lnp_segment_7 := '000000';

               SELECT target_value2                          --, target_value5
                 INTO lnp_segment_1                           --, ln_segment_6
                 FROM xx_fin_translatevalues TDTL,
                      xx_fin_translatedefinition THDR
                WHERE     THDR.translate_id = TDTL.translate_id
                      AND THDR.translation_name = 'XXFA_SAP_EXP_LOCATIONS'
                      AND TDTL.source_value1 =
                             lcu_process_records.company_code
                      AND TDTL.source_value2 =
                             lcu_process_records.cost_center;

               IF lnp_segment_1 = '5010'
               THEN
                  lnp_segment_4 := '010067';
               ELSIF lnp_segment_1 = '5020'
               THEN
                  lnp_segment_4 := '010068';
               ELSIF lnp_segment_1 = '5030'
               THEN
                  lnp_segment_4 := '010069';
               ELSIF lnp_segment_1 = '5040'
               THEN
                  lnp_segment_4 := '010070';
               ELSIF lnp_segment_1 = '5050'
               THEN
                  lnp_segment_4 := '010071';
               ELSIF lnp_segment_1 = '5060'
               THEN
                  lnp_segment_4 := '010072';
               END IF;
               lnp_seg1 := lnp_segment_1;
               lnp_seg2 := lnp_segment_2;
               lnp_seg3 := lnp_segment_3;
               lnp_seg4 := lnp_segment_4;
               lnp_seg5 := lnp_segment_5;
               lnp_seg6 := lnp_segment_6;
               lnp_seg7 := lnp_segment_7;
               SELECT gcc.code_combination_id,
                      gcc.segment1,
                      gcc.segment2,
                      gcc.segment3,
                      gcc.segment4,
                      gcc.segment5,
                      gcc.segment6,
                      gcc.segment7,
                         gcc.segment1
                      || '|'
                      || gcc.segment2
                      || '|'
                      || gcc.segment3
                      || '|'
                      || gcc.segment4
                      || '|'
                      || gcc.segment5
                      || '|'
                      || gcc.segment6
                      || '|'
                      || gcc.segment7
                 INTO ln_pay_ccid,
                      ln_pay_seg1,
                      ln_pay_seg2,
                      ln_pay_seg3,
                      ln_pay_seg4,
                      ln_pay_seg5,
                      ln_pay_seg6,
                      ln_pay_seg7,
                      ln_pay_segments
                 FROM gl_code_combinations gcc, gl_sets_of_books sob
                WHERE     gcc.chart_of_accounts_id = sob.chart_of_accounts_id
                      AND sob.short_name = 'US_USD_P'
                      AND gcc.segment1 = lnp_segment_1
                      AND gcc.segment2 = lnp_segment_2
                      AND gcc.segment3 = lnp_segment_3
                      AND gcc.segment4 = lnp_segment_4
                      AND gcc.segment5 = lnp_segment_5
                      AND gcc.segment6 = lnp_segment_6
                      AND gcc.segment7 = lnp_segment_7
                      AND gcc.enabled_flag = 'Y';
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_pay_ccid := NULL;
                  ln_pay_segments := NULL;
                  lc_error_message :=
                     'Unable to derive payables code combination ID in TRANSLATE_DATA';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => lcu_process_records.control_id,
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                     p_staging_column_name    => 'PAYABLES_CODE_COMBINATION_ID',
                     p_staging_column_value   => lcu_process_records.location_code,
                     p_source_system_ref      => lcu_process_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E24';

                  UPDATE xx_fa_mass_additions_stg
                     SET process_flag = 3,
                         error_message =
                               error_message
                            || ' E24 ('
                            || lcu_process_records.asset_number
                            || ' ' ||
                               lnp_seg1 || '-' ||
                               lnp_seg2 || '-' ||
                               lnp_seg3 || '-' ||
                               lnp_seg4 || '-' ||
                               lnp_seg5 || '-' ||
                               lnp_seg6 || '-' ||
                               lnp_seg7
                            || ') '
                   WHERE     company_code = lcu_process_records.company_code
                         AND asset_number = lcu_process_records.asset_number;
            END;

            BEGIN
               --Changing the serial_number to include the inventory-number if needed
               --     DBMS_OUTPUT.PUT_LINE (
               --     'Step D: ' || lcu_process_records.serial_number);
               ln_serial_number := lcu_process_records.serial_number;

               IF lcu_process_records.inventory_number IS NOT NULL -- RULE ASSETPR12
               THEN
                  ln_serial_number :=
                     SUBSTR (
                           lcu_process_records.inventory_number
                        || '|'
                        || lcu_process_records.serial_number,
                        1,
                        35);
               END IF;

               --Changing amortization flags as needed for the deprn_type_code
               -- On 15 Dec 2014 it was determined by the business that ZSL9
               -- are to be treated as all other non-amoritized assets.  So this
               -- next code is not needed but going to stay in place if the
               -- business changes their mind once we get to SIT ...
               --  IF lcu_process_records.sap_deprn_method_code = 'ZSL9' -- RULE ASSETPR13
               --  THEN
               --     ln_amortize_flag := 'YES';
               --     ln_amortize_nbv_flag := 'YES';
               --
               --     SELECT MAX (calendar_period_open_date)
               --       INTO ln_amortization_start_date
               --       FROM fa_deprn_periods
               --      WHERE     book_type_code = gb_corp_book_name
               --            AND period_close_date IS NULL;
               --  ELSE
               ln_amortize_flag := NULL;
               ln_amortize_nbv_flag := NULL;
               ln_amortization_start_date := NULL;

               --  END IF;
               -- Changing the fixed_assets_units to 1 if it is less than or equal to zero.
               -- Changing the life_in_months to 1 if it is less than or equal to zero.
               --     DBMS_OUTPUT.PUT_LINE ('Step E');              -- RULE ASSETPR15
               IF lcu_process_records.fixed_assets_units <= 0
               THEN
                  ln_fixed_assets_units := 1;
               ELSE
                  ln_fixed_assets_units :=
                     ROUND (lcu_process_records.fixed_assets_units);
               END IF;

               IF lcu_process_records.life_in_months <= 0
               THEN
                  ln_life_in_months := 1;
               ELSE
                  ln_life_in_months :=
                     ROUND (lcu_process_records.life_in_months);
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_error_message :=
                     'Serial Number and FA Units not updated in XX_FA_MASS_ADDITIONS_STG table';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => '',
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                     p_staging_column_name    => '',
                     p_staging_column_value   => '',
                     p_source_system_ref      => lcu_process_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E26';

                  UPDATE xx_fa_mass_additions_stg
                     SET process_flag = 3,
                         error_message = error_message || ' E26'
                   WHERE     company_code = lcu_process_records.company_code
                         AND asset_number = lcu_process_records.asset_number;
            END;

            --  DBMS_OUTPUT.PUT_LINE ('Step F');                 -- RULE ASSETPR15
            -- Attribute7 Calculation
            BEGIN
               ln_attribute7 := NULL;                        -- RULE ASSETPR20

               IF TO_DATE (lcu_process_records.date_placed_in_service,
                           'DD-MON-RR') <= TO_DATE ('27-DEC-14', 'DD-MON-RR')
               THEN
                  SELECT PWC_INITIAL_TAX_COST
                    INTO ln_attribute7
                    FROM XX_FA_TAX_INTERFACE_STG
                   WHERE     pwc_asset_nbr = lcu_process_records.attribute10
                         AND book = 'BK1';
               --    DBMS_OUTPUT.PUT_LINE ('Step F LT ' || ln_attribute7);                 -- RULE ASSETPR15
               ELSE
                  ln_attribute7 := lcu_process_records.fixed_assets_cost;
               --   DBMS_OUTPUT.PUT_LINE ('Step F GT' || ln_attribute7);                 -- RULE ASSETPR15
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  ln_attribute7 := lcu_process_records.fixed_assets_cost;
               WHEN OTHERS
               THEN
                  lc_error_message :=
                     'Attribute7 unable to be derived for XX_FA_MASS_ADDITIONS_STG ';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => lcu_process_records.control_id,
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                     p_staging_column_name    => 'DATE_PLACED_IN_SERVICE',
                     p_staging_column_value   => lcu_process_records.asset_number,
                     p_source_system_ref      => lcu_process_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E43';

                  UPDATE xx_fa_mass_additions_stg
                     SET process_flag = 3,
                         error_message = error_message || ' E43 '
                   WHERE     company_code = lcu_process_records.company_code
                         AND asset_number = lcu_process_records.asset_number;
            END;

            --  DBMS_OUTPUT.PUT_LINE ('Step G1 ' || to_date(lcu_process_records.date_placed_in_service, 'DD-MON-RR'));                 -- RULE ASSETPR15
            -- Attribute8 Calculation
            BEGIN
               ln_attribute8 := NULL;                        -- RULE ASSETPR21

               IF TO_DATE (lcu_process_records.date_placed_in_service,
                           'DD-MON-RR') <= TO_DATE ('27-DEC-14', 'DD-MON-RR')
               THEN
                  SELECT TO_DATE (pwc_in_service_date, 'MM/DD/RRRR')
                    INTO ln_attribute8
                    FROM XX_FA_TAX_INTERFACE_STG
                   WHERE     pwc_asset_nbr = lcu_process_records.attribute10
                         AND book = 'BK1';
               --     DBMS_OUTPUT.PUT_LINE ('Step G2 ' || ln_attribute8);                 -- RULE ASSETPR15
               ELSE
                  ln_attribute8 := lcu_process_records.date_placed_in_service;
               -- DBMS_OUTPUT.PUT_LINE ('Step G3 ' || ln_attribute8);            -- RULE ASSETPR15
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  ln_attribute8 := lcu_process_records.date_placed_in_service;
               WHEN OTHERS
               THEN
                  lc_error_message :=
                     'Attribute8 unable to be derived for XX_FA_MASS_ADDITIONS_STG';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => lcu_process_records.control_id,
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                     p_staging_column_name    => 'DATE_PLACED_IN_SERVICE',
                     p_staging_column_value   => lcu_process_records.asset_number,
                     p_source_system_ref      => lcu_process_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E44';

                  UPDATE xx_fa_mass_additions_stg
                     SET process_flag = 3,
                         error_message = error_message || ' E44'
                   WHERE     company_code = lcu_process_records.company_code
                         AND asset_number = lcu_process_records.asset_number;
            END;

            BEGIN
               IF LENGTH (ln_error_message) > 0
               THEN
                  ln_process_flag := 3;
               ELSE
                  ln_process_flag := 4;
               END IF;

               UPDATE xx_fa_mass_additions_stg
                  SET calc_amortization_start_date =
                         ln_amortization_start_date,         -- RULE ASSETPR13
                      calc_amortize_flag = ln_amortize_flag, -- RULE ASSETPR13
                      calc_amortize_nbv_flag = ln_amortize_nbv_flag, -- RULE ASSETPR13
                      payables_cost = ln_attribute7,         -- RULE ASSETPR20
                      attribute7 = TO_CHAR (ln_attribute7),  -- RULE ASSETPR20
                      attribute8 = ln_attribute8,            -- RULE ASSETPR21
                      expense_code_combination_id = ln_exp_ccid, -- RULE ASSETPR06
                      calc_exp_cc_segments = ln_exp_segments, -- RULE ASSETPR06
                      calc_fixed_assets_cost = ln_cost,      -- RULE ASSETPR14
                      calc_fixed_assets_units = ln_fixed_assets_units, -- RULE ASSETPR15
                      calc_location_id = ln_location_id,     -- RULE ASSETPR07
                      calc_location_segments = ln_location_segments,
                      calc_life_in_months = ln_life_in_months, -- RULE ASSETPR11
                      payables_code_combination_id = ln_pay_ccid, -- RULE ASSETPR05
                      calc_pay_cc_segments = ln_pay_segments, -- RULE ASSETPR06
                      calc_serial_number = ln_serial_number, -- RULE ASSETPR12
                      asset_in_pwc = lc_pwc_val,             -- RULE ASSETPR22
                      attribute14 = sap_vendor_name,
                      attribute15 = sap_invoice_number,
                      process_flag = ln_process_flag,
                      exp_account_seg = ln_exp_seg3,
                      exp_company_seg = ln_exp_seg1,
                      exp_cost_seg = ln_exp_seg2,
                      exp_future_seg = ln_exp_seg7,
                      exp_intercpo_seg = ln_exp_seg5,
                      exp_lob_seg = ln_exp_seg6,
                      exp_location_seg = ln_exp_seg4,
                      pay_account_seg = ln_pay_seg3,
                      pay_company_seg = ln_pay_seg1,
                      pay_cost_seg = ln_pay_seg2,
                      pay_future_seg = ln_pay_seg7,
                      pay_intercpo_seg = ln_pay_seg5,
                      pay_lob_seg = ln_pay_seg6,
                      pay_location_seg = ln_pay_seg4,
                      calc_location_seg1 = ln_location_seg1,
                      calc_location_seg2 = ln_location_seg2,
                      calc_location_seg3 = ln_location_seg3,
                      calc_location_seg4 = ln_location_seg4,
                      calc_location_seg5 = ln_location_seg5,
                      calc_location_seg6 = ln_location_seg6,
                      new_used = ln_new_used                               --,
                --    error_message = ln_error_message
                WHERE     company_code = lcu_process_records.company_code
                      AND asset_number = lcu_process_records.asset_number;

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  --     DBMS_OUTPUT.PUT_LINE ('VALIDATE ERROR: ' || SQLERRM); -- RULE ASSETPR15
                  lc_error_message :=
                     'Derived values not updated to XX_FA_MASS_ADDITIONS_STG';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => '',
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                     p_staging_column_name    => '',
                     p_staging_column_value   => '',
                     p_source_system_ref      => lcu_process_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);

                  UPDATE xx_fa_mass_additions_stg
                     SET process_flag = 3,
                         error_message = error_message || ' E28'
                   WHERE     company_code = lcu_process_records.company_code
                         AND asset_number = lcu_process_records.asset_number;
            END;
         END LOOP;

         COMMIT;
      ELSIF p_validate_flag = 'P'
      THEN
         ln_error_message := NULL;

         BEGIN
            SELECT NVL (translate_id, 999)
              INTO ln_trans_id
              FROM xx_fin_translatedefinition
             WHERE translation_name = 'XXFA_PWC_DEPRN';
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'Lookup Values for XXFA_PWC_DEPRN  not set up';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => ln_conversion_id,
                  p_record_control_id      => '',
                  p_source_system_code     => lc_source_system_code,
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'TRANSLATE_DATA',
                  p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                  p_staging_column_name    => '',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);
               ln_error_message := ln_error_message || ' E27';

               UPDATE xx_fa_tax_interface_stg
                  SET process_flag = 3,
                      error_message = error_message || ' E27';
         END;

         ln_book_loop := 'BK1';

         FOR lcu_process_tax_records IN c_proc_tax_rec
         LOOP
            --Initialization for each transactions
            ln_error_message := NULL;
            ln_count := 0;

            -- Translating ASSET_IN_SAP flag                -- RULE ASSETPR23
            BEGIN
               SELECT COUNT (*)
                 INTO ln_count
                 FROM XX_FA_MASS_ADDITIONS_STG
                WHERE attribute10 = lcu_process_tax_records.pwc_asset_nbr;

               IF ln_count = 0
               THEN
                  lc_sap_val := 'N';
               ELSE
                  lc_sap_val := 'Y';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_error_message :=
                     'Unable to update asset_in_sap flag in TRANSLATE_DATA';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => ln_conversion_id,
                     p_record_control_id      => lcu_process_tax_records.control_id,
                     p_source_system_code     => lc_source_system_code,
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                     p_staging_column_name    => 'ASSET_IN_SAP',
                     p_staging_column_value   => lcu_process_tax_records.pwc_asset_nbr,
                     p_source_system_ref      => lcu_process_tax_records.source_system_ref,
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E29';

                  UPDATE xx_fa_tax_interface_stg
                     SET process_flag = 3,
                         error_message = error_message || ' E29'
                   WHERE pwc_asset_nbr =
                            lcu_process_tax_records.pwc_asset_nbr;
            END;

            IF lcu_process_tax_records.pwc_in_service_date IS NOT NULL
            THEN
               BEGIN                                         -- RULE ASSETPR24
                  SELECT TO_DATE (
                            lcu_process_tax_records.pwc_in_service_date,
                            'MM/DD/RRRR')
                    INTO ln_calc_dpis
                    FROM DUAL;
               --  DBMS_OUTPUT.put_line (
               --         'DPIS ' || lcu_process_tax_records.pwc_in_service_date ||
               --       ' New ' || ln_calc_dpis );

               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_error_message :=
                        'Unable to calc DPIS within XX_FA_TAX_INTERFACE_STG';
                     XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                        p_conversion_id          => '',
                        p_record_control_id      => '',
                        p_source_system_code     => '',
                        p_package_name           => 'XX_FA_ASSET_PKG',
                        p_procedure_name         => 'TRANSLATE_DATA',
                        p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                        p_staging_column_name    => 'PWC_IN_SERVICE_DATE',
                        p_staging_column_value   => '',
                        p_source_system_ref      => '',
                        p_batch_id               => '',
                        p_exception_log          => lc_error_message,
                        p_oracle_error_code      => SQLCODE,
                        p_oracle_error_msg       => SQLERRM);
                     ln_error_message := ln_error_message || ' E45';

                     UPDATE xx_fa_tax_interface_stg
                        SET process_flag = 3,
                            error_message = error_message || ' E45'
                      WHERE pwc_in_service_date =
                               lcu_process_tax_records.pwc_in_service_date;
               END;
            END IF;

            BEGIN                                            -- RULE ASSETPR27
               ln_calc_asset_number := NULL;
               ln_calc_asset_id := NULL;

               --                DBMS_OUTPUT.put_line (
               --              'Get New Asset Number ' || lcu_process_tax_records.pwc_asset_nbr);
              SELECT asset_number, asset_id
                 INTO ln_calc_asset_number, ln_calc_asset_id
                 FROM FA_ADDITIONS_B
                WHERE attribute10 = lcu_process_tax_records.pwc_asset_nbr
                  and  creation_date = (select max(creation_date)  FROM fa.FA_ADDITIONS_B
                WHERE attribute10 = lcu_process_tax_records.pwc_asset_nbr) ; --- MWS   Defect ???
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_error_message :=
                     'Asset Number not in FA_ADDITIONS_B for tax table update';
                  XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                     p_conversion_id          => '',
                     p_record_control_id      => '',
                     p_source_system_code     => '',
                     p_package_name           => 'XX_FA_ASSET_PKG',
                     p_procedure_name         => 'TRANSLATE_DATA',
                     p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                     p_staging_column_name    => 'PWC_IN_SERVICE_DATE',
                     p_staging_column_value   => '',
                     p_source_system_ref      => '',
                     p_batch_id               => '',
                     p_exception_log          => lc_error_message,
                     p_oracle_error_code      => SQLCODE,
                     p_oracle_error_msg       => SQLERRM);
                  ln_error_message := ln_error_message || ' E30';

                  UPDATE xx_fa_tax_interface_stg
                     SET process_flag = 3,
                         error_message = error_message || ' E30'
                   WHERE pwc_asset_nbr =
                            lcu_process_tax_records.pwc_asset_nbr;
            END;

            IF LENGTH (ln_error_message) > 0
            THEN
               ln_process_flag := 3;
            ELSE
               ln_process_flag := 4;
            END IF;

            UPDATE xx_fa_tax_interface_stg
               SET asset_in_sap = lc_sap_val,                -- RULE ASSETPR23
                   calc_dpis = ln_calc_dpis,                 -- RULE ASSETPR24
                   process_flag = ln_process_flag,
                   calc_asset_id = ln_calc_asset_id,
                   calc_asset_number = ln_calc_asset_number  -- RULE ASSETPR27
             WHERE pwc_asset_nbr = lcu_process_tax_records.pwc_asset_nbr;

            COMMIT;
         END LOOP;

         FOR lcu_process_tax_book_records IN c_proc_tax_book_rec
         LOOP
            ln_book_loop := lcu_process_tax_book_records.book;

            --     DBMS_OUTPUT.put_line (
            --    'Tax Book Loop ' || ln_book_loop);
            FOR lcu_process_tax_records IN c_proc_tax_rec
            LOOP
               ln_calc_deprn_method_code := NULL;
               ln_calc_life := NULL;
               ln_calc_prorate_cc := NULL;
               ln_error_message := NULL;

               BEGIN                                         -- RULE ASSETPR28
                  -- Update Life and Deprn values
                  --      IF lcu_process_tax_records.pwc_life = 31.5
                  --      THEN
                  --         ln_pwc_life_char := '31.50';
                  --      ELSE
                  --         ln_pwc_life_char :=
                  --            TO_CHAR (lcu_process_tax_records.pwc_life) || '.00';
                  --      END IF;
                  SELECT target_value1, target_value2, target_value3
                    INTO ln_calc_deprn_method_code,
                         ln_calc_life,
                         ln_calc_prorate_cc
                    FROM xx_fin_translatevalues
                   WHERE     source_value1 = lcu_process_tax_records.pwc_rate
                         AND source_value2 =
                                TO_CHAR (lcu_process_tax_records.pwc_life)
                         AND UPPER (source_value3) =
                                UPPER (
                                   lcu_process_tax_records.pwc_description)
                         AND translate_id = ln_trans_id;
               --               DBMS_OUTPUT.put_line (
               --                 'Individual Loop '
               --          || lcu_process_tax_records.pwc_asset_nbr
               --      || ' Book '
               --    || lcu_process_tax_book_records.book
               --  || ' Value '
               -- || ln_calc_deprn_method_code);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_error_message :=
                        'PWC Life and Deprn Values not updated in XX_FA_TAX_INTERFACE_STG table';
                     XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                        p_conversion_id          => '',
                        p_record_control_id      => '',
                        p_source_system_code     => '',
                        p_package_name           => 'XX_FA_ASSET_PKG',
                        p_procedure_name         => 'TRANSLATE_DATA',
                        p_staging_table_name     => 'XX_FIN_TRANSLATEVALUES',
                        p_staging_column_name    => 'TRANSLATE_ID',
                        p_staging_column_value   => 'PWC_RATE',
                        p_source_system_ref      => '',
                        p_batch_id               => '',
                        p_exception_log          => lc_error_message,
                        p_oracle_error_code      => SQLCODE,
                        p_oracle_error_msg       => SQLERRM);
                     ln_error_message := ln_error_message || ' E31';

                     UPDATE xx_fa_tax_interface_stg
                        SET process_flag = 3,
                            error_message = error_message || ' E31'
                      WHERE     pwc_asset_nbr =
                                   lcu_process_tax_records.pwc_asset_nbr
                            AND book = lcu_process_tax_book_records.book;
               END;

               BEGIN
                  --
                  -- Update xx_fa_mass_additions with derived values
                  --
                  --       DBMS_OUTPUT.PUT_LINE ('Step 17');
                  IF LENGTH (ln_error_message) > 0
                  THEN
                     ln_process_flag := 3;
                  ELSE
                     ln_process_flag := 4;
                  END IF;

                  UPDATE xx_fa_tax_interface_stg
                     SET calc_comp_code =
                            SUBSTR (
                               lcu_process_tax_records.pwc_asset_nbr,
                                 INSTR (
                                    lcu_process_tax_records.pwc_asset_nbr,
                                    '-')
                               + 1,
                               4),
                         calc_deprn_method_code = ln_calc_deprn_method_code, -- RULE ASSSETPR28
                         calc_life = ln_calc_life,           -- RULE ASSETPR18
                         calc_prorate_cc = ln_calc_prorate_cc, -- RULE ASSETPR18
                         calc_deprn_reserve = ROUND (pwc_accum_deprn, 2),
                         process_flag = ln_process_flag
                   WHERE     pwc_asset_nbr =
                                lcu_process_tax_records.pwc_asset_nbr
                         AND book = lcu_process_tax_book_records.book;

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_error_message :=
                        'Derived values not updated to XX_FA_TAX_INTERFACE_STG table';
                     XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                        p_conversion_id          => ln_conversion_id,
                        p_record_control_id      => '',
                        p_source_system_code     => lc_source_system_code,
                        p_package_name           => 'XX_FA_ASSET_PKG',
                        p_procedure_name         => 'TRANSLATE_DATA',
                        p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                        p_staging_column_name    => '',
                        p_staging_column_value   => '',
                        p_source_system_ref      => lcu_process_tax_records.source_system_ref,
                        p_batch_id               => '',
                        p_exception_log          => lc_error_message,
                        p_oracle_error_code      => SQLCODE,
                        p_oracle_error_msg       => SQLERRM);

                     UPDATE xx_fa_tax_interface_stg
                        SET process_flag = 3,
                            error_message = error_message || ' E32'
                      WHERE     pwc_asset_nbr =
                                   lcu_process_tax_records.pwc_asset_nbr
                            AND book = lcu_process_tax_book_records.book;
               END;
            END LOOP;

            COMMIT;
         END LOOP;

         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_message := 'Unable to execute TRANSLATE_DATA procedure';
         XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
            p_conversion_id          => ln_conversion_id,
            p_record_control_id      => '',
            p_source_system_code     => lc_source_system_code,
            p_package_name           => 'XX_FA_ASSET_PKG',
            p_procedure_name         => 'TRANSLATE_DATA',
            p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
            p_staging_column_name    => '',
            p_staging_column_value   => '',
            p_source_system_ref      => '',
            p_batch_id               => '',
            p_exception_log          => lc_error_message,
            p_oracle_error_code      => SQLCODE,
            p_oracle_error_msg       => SQLERRM);
   END TRANSLATE_DATA;

   -- +===================================================================================+
   -- | Name        :LOAD_MA                                                              |
   -- | Description :When requested by the business it loads data to the seeded Oracle    |
   -- |              FA Mass Additions Staging Table                                      |
   -- | Parameters:  p_process_name, p_batch_id                                           |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE LOAD_MA (x_errbuf       OUT NOCOPY VARCHAR2,
                      x_retcode      OUT NOCOPY VARCHAR2)    -- Added by Paddy
   IS
      --Cursor to get the transaction of the Particular batch
      CURSOR c_proc_rec
      IS
         SELECT *
           FROM xx_fa_mass_additions_stg
          WHERE process_flag = 4;

      lc_error_message        VARCHAR2 (100);
      lc_source_system_code   xx_com_conversions_conv.system_code%TYPE;
      ln_conversion_id        xx_com_conversions_conv.conversion_id%TYPE;
   BEGIN
      --Printing the Parameters
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parameters: ');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'None');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');

      FOR lcu_process_records IN c_proc_rec
      LOOP
         --Initialization for each transactions
         lc_error_message := NULL;

         BEGIN
            --Inserting Into Table FA_MASS_ADDITIONS
            INSERT INTO fa_mass_additions (accounting_date,              -- OK
                                           amortize_flag,                -- OK
                                           amortize_nbv_flag,            -- OK
                                           amortization_start_date,      -- OK
                                           asset_category_id,            -- OK
                                           --asset_key_ccid,
                                           asset_number,                 -- OK
                                           asset_type,                   -- OK
                                           attribute6,                   -- OK
                                           attribute7,                   -- OK
                                           attribute8,                   -- OK
                                           attribute10,                  -- OK
                                           --attribute11,
                                           attribute12,                  -- OK
                                           attribute14,                  -- OK
                                           attribute15,                  -- OK
                                           book_type_code,               -- OK
                                           context,                      -- OK
                                           --conversion_date,
                                           --create_batch_date,
                                           created_by,                   -- OK
                                           creation_date,                -- OK
                                           date_placed_in_service,       -- OK
                                           depreciate_flag,              -- OK
                                           deprn_method_code,            -- OK
                                           deprn_reserve,                -- OK
                                           description,                  -- OK
                                           expense_code_combination_id,  -- OK
                                           feeder_system_name,           -- OK
                                           fixed_assets_cost,            -- OK
                                           fixed_assets_units,           -- OK
                                           --group_asset_id,
                                           --in_use_flag,
                                           --invoice_date,
                                           --invoice_id,
                                           --invoice_number,
                                           last_update_date,             -- OK
                                           last_update_login,            -- OK
                                           last_updated_by,              -- OK
                                           --lease_id,
                                           --lessor_id,
                                           location_id,                  -- OK
                                           life_in_months,               -- OK
                                           mass_addition_id,             -- OK
                                           --manufacturer_name,
                                           --model_number,
                                           new_used,
                                           --original_deprn_start_date,
                                           --owned_leased,
                                           --parent_asset_id,
                                           payables_code_combination_id, -- OK
                                           payables_cost,                -- OK
                                           payables_units,               -- OK
                                           --po_number,
                                           --po_vendor_id,
                                           posting_status,               -- OK
                                           property_1245_1250_code,      -- OK
                                           property_type_code,           -- OK
                                           prorate_convention_code,      -- OK
                                           queue_name,                   -- OK
                                           serial_number,                -- OK
                                           --tag_number,
                                           ytd_deprn)
                 VALUES (lcu_process_records.accounting_date,
                         lcu_process_records.calc_amortize_flag,
                         lcu_process_records.calc_amortize_nbv_flag,
                         lcu_process_records.calc_amortization_start_date,
                         lcu_process_records.asset_category_id,
                         --lcu_process_records.asset_key_ccid,
                         NULL,             --lcu_process_records.asset_number,
                         lcu_process_records.asset_type,
                         lcu_process_records.attribute6,
                         lcu_process_records.attribute7,
                         lcu_process_records.attribute8,
                         lcu_process_records.attribute10,
                         --lcu_process_records.attribute11,
                         lcu_process_records.attribute12,
                         lcu_process_records.attribute14,
                         lcu_process_records.attribute15,
                         lcu_process_records.book_type_code,
                         lcu_process_records.context,
                         --lcu_process_records.conversion_date,
                         --lcu_process_records.create_batch_date,
                         lcu_process_records.created_by,
                         lcu_process_records.creation_date,
                         lcu_process_records.date_placed_in_service,
                         lcu_process_records.depreciate_flag,
                         lcu_process_records.deprn_method_code,
                         ABS (lcu_process_records.deprn_reserve), -- ASSETPR31
                         lcu_process_records.description,
                         lcu_process_records.expense_code_combination_id,
                         lcu_process_records.feeder_system_name,
                         lcu_process_records.calc_fixed_assets_cost,
                         lcu_process_records.calc_fixed_assets_units,
                         --lcu_process_records.group_asset_id,
                         --lcu_process_records.in_use_flag,
                         --lcu_process_records.invoice_date,
                         --lcu_process_records.invoice_id,
                         --lcu_process_records.invoice_number,
                         lcu_process_records.last_update_date,
                         lcu_process_records.last_update_login,
                         lcu_process_records.last_updated_by,
                         --lcu_process_records.lease_id,
                         --lcu_process_records.lessor_id,
                         lcu_process_records.calc_location_id,
                         lcu_process_records.calc_life_in_months,
                         lcu_process_records.mass_addition_id,
                         --lcu_process_records.manufacturer_name,
                         --lcu_process_records.model_number,
                         lcu_process_records.new_used,
                         --lcu_process_records.original_deprn_start_date,
                         --lcu_process_records.owned_leased,
                         --lcu_process_records.parent_asset_id,
                         lcu_process_records.payables_code_combination_id,
                         lcu_process_records.payables_cost,
                         lcu_process_records.calc_fixed_assets_units,
                         --lcu_process_records.po_number,
                         --lcu_process_records.po_vendor_id,
                         lcu_process_records.posting_status,
                         lcu_process_records.property_1245_1250_code,
                         lcu_process_records.property_type_code,
                         lcu_process_records.prorate_convention_code,
                         lcu_process_records.queue_name,
                         lcu_process_records.calc_serial_number,
                         --lcu_process_records.tag_number,
                         ABS (lcu_process_records.ytd_deprn));    -- ASSETPR31
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'Unable to load FA_MASS_ADDITIONS from XX_FA_MASS_ADDITIONS_STG';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => ln_conversion_id,
                  p_record_control_id      => '',
                  p_source_system_code     => lc_source_system_code,
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'LOAD_MA',
                  p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                  p_staging_column_name    => '',
                  p_staging_column_value   => '',
                  p_source_system_ref      => lcu_process_records.source_system_ref,
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE xx_fa_mass_additions_stg
                  SET process_flag = 3,
                      error_message = error_message || ' E34'
                WHERE attribute10 = lcu_process_records.attribute10;
         END;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         --  DBMS_OUTPUT.put_line ('Start MASTER '||  SQLCODE || ' ' || SQLERRM);
         lc_error_message := 'Unable to execute LOAD_MA procedure';
         XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
            p_conversion_id          => ln_conversion_id,
            p_record_control_id      => '',
            p_source_system_code     => lc_source_system_code,
            p_package_name           => 'XX_FA_ASSET_PKG',
            p_procedure_name         => 'LOAD_MA',
            p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
            p_staging_column_name    => '',
            p_staging_column_value   => '',
            p_source_system_ref      => '',
            p_batch_id               => '',
            p_exception_log          => lc_error_message,
            p_oracle_error_code      => SQLCODE,
            p_oracle_error_msg       => SQLERRM);
         FND_FILE.PUT_LINE (FND_FILE.LOG,
                            'Error in Load_ma procedure :' || SQLERRM);
         x_errbuf := SUBSTR (SQLERRM, 1, 150);
         x_retcode := '2';
   END LOAD_MA;

   -- +===================================================================================+
   -- | Name        :FA_CLOSEOUT                                                          |
   -- | Description :Verify that the conversion record is in the Production tables        |
   -- | Parameters : p_batch_id                                                           |
   -- |                                                                                   |
   -- | Returns    : None                                                                 |
   -- +===================================================================================+
   PROCEDURE FA_CLOSEOUT (x_errbuf       OUT NOCOPY VARCHAR2,
                          x_retcode      OUT NOCOPY VARCHAR2) -- Added by Paddy
   IS
      --Cursor to get the transaction of the Particular batch
      CURSOR c_proc_rec
      IS
         SELECT *
           FROM xx_fa_mass_additions_stg
          WHERE process_flag = 4;

      lc_error_message        VARCHAR2 (100);
      lc_source_system_code   xx_com_conversions_conv.system_code%TYPE;
      ln_conversion_id        xx_com_conversions_conv.conversion_id%TYPE;
      ln_count                NUMBER;
      ln_process_flag         xx_fa_mass_additions_stg.process_flag%TYPE;
   BEGIN
      --Printing the Parameters
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parameters: ');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'None');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');

      FOR lcu_process_records IN c_proc_rec
      LOOP
         BEGIN
            SELECT COUNT (*)
              INTO ln_count
              FROM FA_ADDITIONS_B
             WHERE attribute10 = lcu_process_records.attribute10;

            IF ln_count > 0
            THEN
               ln_process_flag := 7;
            ELSE
               ln_process_flag := 6;
            END IF;

            UPDATE xx_fa_mass_additions_stg
               SET process_flag = ln_process_flag
             WHERE attribute10 = lcu_process_records.attribute10;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'Unable to update record to process_flag of 7 in FA_CLOSEOUT';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => ln_conversion_id,
                  p_record_control_id      => '',
                  p_source_system_code     => lc_source_system_code,
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'FA_CLOSEOUT',
                  p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
                  p_staging_column_name    => '',
                  p_staging_column_value   => '',
                  p_source_system_ref      => '',
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE xx_fa_mass_additions_stg
                  SET process_flag = 3,
                      error_message = error_message || ' E36'
                WHERE attribute10 = lcu_process_records.attribute10;
         END;
      END LOOP;

      COMMIT;                                                -- Added by Paddy
   EXCEPTION
      WHEN OTHERS
      THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG,
                            'Error in fa_closeout procedure :' || SQLERRM);
         x_errbuf := SUBSTR (SQLERRM, 1, 150);
         x_retcode := '2';
   END FA_CLOSEOUT;

   -- +===================================================================================+
   -- | Name        :LOAD_TAX                                                             |
   -- | Description :When requested by the business it loads data to the seeded Oracle    |
   -- |              FA Tax Interface Staging Table                                       |
   -- | Parameters:  p_process_name, p_batch_id, p_book_type_code, p_depr_flag_only       |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE LOAD_TAX (x_errbuf              OUT NOCOPY VARCHAR2,
                       x_retcode             OUT NOCOPY VARCHAR2,
                       p_book_type_code   IN            VARCHAR2) -- Added by Paddy
   IS
      --Cursor to get the transaction of the Particular batch
      CURSOR c_proc_rec
      IS
         SELECT *
           FROM xx_fa_tax_interface_stg
          WHERE process_flag = 4 AND calc_book_type_code = p_book_type_code;

      lc_error_message        VARCHAR2 (100);
      lc_source_system_code   xx_com_conversions_conv.system_code%TYPE;
      ln_conversion_id        xx_com_conversions_conv.conversion_id%TYPE;
      ln_count                NUMBER;
      ln_error_number         VARCHAR2(3);

   BEGIN
      --Printing the Parameters
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parameters: ');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         'Book Type Code : ' || p_book_type_code);
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         '---------------------------------------');

      FOR lcu_process_records IN c_proc_rec
      LOOP
         --Initialization for each transactions
         lc_error_message := NULL;

         BEGIN

         SELECT count(*)
           INTO ln_count
                 FROM FA_BOOKS
                WHERE asset_id = lcu_process_records.CALC_ASSET_NUMBER
                and book_type_code = p_book_type_code;

            IF ln_count > 0 THEN
            --Inserting Into Table FA_MASS_ADDITIONS
            INSERT INTO fa_tax_interface (ASSET_ID,
                                          ASSET_NUMBER,                  -- OK
                                          BOOK_TYPE_CODE,                -- OK
                                          CREATED_BY,                    -- OK
                                          CREATION_DATE,                 -- OK
                                          --   DEPRECIATE_FLAG,               -- OK
                                          LAST_UPDATE_DATE,              -- OK
                                          LAST_UPDATE_LOGIN,             -- OK
                                          LAST_UPDATED_BY,               -- OK
                                          POSTING_STATUS,
                                          COST,                          -- OK
                                          DATE_PLACED_IN_SERVICE,        -- OK
                                          DEPRN_METHOD_CODE,             -- OK
                                          DEPRN_RESERVE,                 -- OK
                                          LIFE_IN_MONTHS,                -- OK
                                          PRORATE_CONVENTION_CODE,       -- OK
                                          YTD_DEPRN)
                 VALUES (lcu_process_records.CALC_ASSET_NUMBER,           --OK
                         lcu_process_records.CALC_ASSET_NUMBER,           --OK
                         lcu_process_records.CALC_BOOK_TYPE_CODE,         --OK
                         lcu_process_records.CREATED_BY,                 -- OK
                         lcu_process_records.CREATION_DATE,              -- OK
                         --  lcu_process_records.CALC_DEPRECIATE_FLAG,        --OK
                         lcu_process_records.LAST_UPDATE_DATE,            --OK
                         lcu_process_records.LAST_UPDATE_LOGIN,           --OK
                         lcu_process_records.LAST_UPDATED_BY,             --OK
                         'POST',
                         lcu_process_records.PWC_INITIAL_TAX_COST,       -- OK
                         lcu_process_records.CALC_DPIS,                 -- OK,
                         lcu_process_records.CALC_DEPRN_METHOD_CODE,      --OK
                         lcu_process_records.CALC_DEPRN_RESERVE,          --OK
                         lcu_process_records.CALC_LIFE,                  -- OK
                         lcu_process_records.CALC_PRORATE_CC,            -- OK
                         lcu_process_records.CALC_YTD_DEPRN);

            ELSE

              IF p_book_type_code = gb_fed_book_name       THEN ln_error_number := 'E52'; ELSIF
                 p_book_type_code = gb_state_book_name     THEN ln_error_number := 'E53'; ELSIF
                 p_book_type_code = gb_fed_ace_book_name   THEN ln_error_number := 'E54'; ELSIF
                 p_book_type_code = gb_fed_amt_book_name   THEN ln_error_number := 'E55'; ELSIF
                 p_book_type_code = gb_state_amt_book_name THEN ln_error_number := 'E56'; END IF;

               UPDATE xx_fa_tax_interface_stg
                  SET process_flag = 3,
                      error_message = error_message || ' ' || ln_error_number
                WHERE CALC_ASSET_NUMBER =
                         lcu_process_records.CALC_ASSET_NUMBER;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_message :=
                  'Unable to load FA_TAX_INTERFACE from XX_FA_TAX_INTERFACE_STG (Y)';
               XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
                  p_conversion_id          => ln_conversion_id,
                  p_record_control_id      => '',
                  p_source_system_code     => lc_source_system_code,
                  p_package_name           => 'XX_FA_ASSET_PKG',
                  p_procedure_name         => 'LOAD_TAX',
                  p_staging_table_name     => 'XX_FA_TAX_INTERFACE_STG',
                  p_staging_column_name    => '',
                  p_staging_column_value   => '',
                  p_source_system_ref      => lcu_process_records.source_system_ref,
                  p_batch_id               => '',
                  p_exception_log          => lc_error_message,
                  p_oracle_error_code      => SQLCODE,
                  p_oracle_error_msg       => SQLERRM);

               UPDATE xx_fa_tax_interface_stg
                  SET process_flag = 3,
                      error_message = error_message || ' E38'
                WHERE CALC_ASSET_NUMBER =
                         lcu_process_records.CALC_ASSET_NUMBER;
         END;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_message := 'Unable to execute LOAD_TAX ';
         XX_COM_CONV_ELEMENTS_PKG.LOG_EXCEPTIONS_PROC (
            p_conversion_id          => ln_conversion_id,
            p_record_control_id      => '',
            p_source_system_code     => lc_source_system_code,
            p_package_name           => 'XX_FA_ASSET_PKG',
            p_procedure_name         => 'LOAD_MA',
            p_staging_table_name     => 'XX_FA_MASS_ADDITIONS_STG',
            p_staging_column_name    => '',
            p_staging_column_value   => '',
            p_source_system_ref      => '',
            p_batch_id               => '',
            p_exception_log          => lc_error_message,
            p_oracle_error_code      => SQLCODE,
            p_oracle_error_msg       => SQLERRM);

         UPDATE xx_fa_tax_interface_stg
            SET process_flag = 3, error_message = error_message || ' E40';

         COMMIT;
         FND_FILE.PUT_LINE (FND_FILE.LOG,
                            'Error in Load_tax procedure :' || SQLERRM);
         x_errbuf := SUBSTR (SQLERRM, 1, 150);
         x_retcode := '2';
   END LOAD_TAX;
END XX_FA_ASSET_PKG;
/
