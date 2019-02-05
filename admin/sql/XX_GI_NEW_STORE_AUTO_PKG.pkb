CREATE OR REPLACE PACKAGE BODY xx_gi_new_store_auto_pkg
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_GI_NEW_STORE_AUTO_PKG                                          |
-- |                                                                                |
-- | Description:                                                                   |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 18-JUL-2007 Sarah Maria Justina     Initial draft version              |
-- |1.0      15-OCT-2007 Archibald Antony P.	 Update update_stg_data_err_details |
-- |                                             into an autonomous transaction     |
-- |1.1      18-OCT-2007 P.Suresh                Corrected the sequence name.       |
-- |1.2      25-OCT-2007 Archibald Antony P.     Changed the logic for generating   |
-- |					                   org code and added code to avoid   |
-- |                                             duplication                        |
-- |1.3      08-NOV-2007 Rama Dwibhashyam       Added get_io_ccid function to get   |
-- |                                            Inter org receivable and payable    |
-- |                                            accounts seg4 same as seg1          |
-- |1.4      12-DEC-2007 Archibald Antony P.    Did changes for workflow procedure  |
-- |1.5      31-MAR-2008 Ganesh B Nadakudhiti   Changed generate org code function  |
-- |								to generate org codes from custom   |
-- |								table.					|
-- |1.6      18-APR-2008 Ganesh B Nadakudhiti   Modified code to match location name|
-- |								to six digits of HR Location        |
-- |1.7	 14-May-2008 Ganesh B Nadakudhiti   Capturing the HR Location is staging|
--								table to use it back for HR Loc/Org |
--								assignment.					|
-- |1.8  11-Jun-2013 Srinivas Sivalanka   modified code for retrofit(R12 upgrade)   |
--                                        GL_SET_OF_BOOKS table replaced with       |
--                                        gl_ledgers.                               |
-- |1.9  11-Oct-2013 Veronica Mairembam   E0351A - Modified for R12 Upgrade Retrofit|
-- |1.10 19-Oct-2015 Madhu Bolli          Remove schema for 12.2 retrofit |
-- +================================================================================+
--**************************
--Declaring Global variables
--**************************
   gc_debug_flag                      VARCHAR2 (1);
   g_prog_application        CONSTANT VARCHAR2 (30)   := 'INV';
   g_prog_executable         CONSTANT VARCHAR2 (30)
                                           := 'XX_GI_COPY_ORG_MASTER';
   g_child_prog_executable   CONSTANT VARCHAR2 (30)
                                            := 'XX_GI_COPY_ORG_CHILD';
   g_module_name             CONSTANT VARCHAR2 (50)   := 'INV';
   g_prog_type               CONSTANT VARCHAR2 (50)
                                              := 'CONCURRENT PROGRAM';
   g_notify                  CONSTANT VARCHAR2 (1)    := 'Y';
   g_major                   CONSTANT VARCHAR2 (15)   := 'MAJOR';
   g_minor                   CONSTANT VARCHAR2 (15)   := 'MINOR';
   g_user_id                 CONSTANT VARCHAR2 (60)
                                             := fnd_global.user_id
                                                                  ();
   gc_invalid_acc_details             VARCHAR2 (4000) := '';
   ex_item_val_org_invalid            EXCEPTION;
   ex_model_org_id_not_found          EXCEPTION;
   ex_no_mtl_data_found               EXCEPTION;
   ex_no_rcv_data_found               EXCEPTION;
   ex_inv_org_incorrect               EXCEPTION;
   ex_inv_acc_str_not_found           EXCEPTION;
   ex_ccid_creation_err               EXCEPTION;
   ex_inv_invalid_account             EXCEPTION;
   ex_inv_reqd_field_null             EXCEPTION;
   ex_no_data_in_stg                  EXCEPTION;
   ex_no_data_in_mtl                  EXCEPTION;
   ex_no_data_in_rcv                  EXCEPTION;
   ex_invalid_wf_role                 EXCEPTION;
   ex_model_org_code_null             EXCEPTION;
   ex_invalid_grp_size                EXCEPTION;
   ex_rms_pop_data_invalid            EXCEPTION;
   ex_submit_child                    EXCEPTION;
   ex_org_for_loc_exists              EXCEPTION;

-- +========================================================================+
-- | Name        :  LOG_ERROR                                               |
-- |                                                                        |
-- | Description :  This wrapper procedure calls the custom common error api|
-- |                 with relevant parameters.                              |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_prog_name IN VARCHAR2                                 |
-- |                p_exception IN VARCHAR2                                 |
-- |                p_message   IN VARCHAR2                                 |
-- |                p_code      IN NUMBER                                   |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE log_error (
      p_prog_name   IN   VARCHAR2
     ,p_exception   IN   VARCHAR2
     ,p_message     IN   VARCHAR2
     ,p_code        IN   NUMBER
   )
   IS
-- ---------
-- Constants
-- ---------
      lc_severity   VARCHAR2 (15) := NULL;
   BEGIN
      IF p_code = -1
      THEN
         lc_severity := g_major;
      ELSIF p_code = 1
      THEN
         lc_severity := g_minor;
      END IF;

      xx_com_error_log_pub.log_error
                             (p_program_type                => g_prog_type
                             ,p_program_name                => p_prog_name
                             ,p_module_name                 => g_module_name
                             ,p_error_location              => p_exception
                             ,p_error_message_code          => p_code
                             ,p_error_message               => p_message
                             ,p_error_message_severity      => lc_severity
                             ,p_notify_flag                 => g_notify
                             );
   END log_error;

-- +========================================================================+
-- | Name        :  UPDATE_STG_DATA_ERR_DETAILS                             |
-- |                                                                        |
-- | Description :  This procedure updates the staging table                |
-- |                 with relevant error parameters.                        |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_message IN VARCHAR2                                   |
-- |                p_code  IN NUMBER                                       |
-- |                p_control_id  N NUMBER                                  |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE update_stg_data_err_details (
      p_message      IN   VARCHAR2
     ,p_code         IN   NUMBER
     ,p_control_id   IN   NUMBER
   )
   IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_inv_org_loc_def_stg
         SET update_date = SYSDATE
            ,updated_by = g_user_id
		,ERROR_CODE = SUBSTR (p_code, 1, 20)
            ,error_message = SUBSTR (p_message, 1, 200)
       WHERE control_id = p_control_id;
   commit;
   END update_stg_data_err_details;

-- +====================================================================+
 -- | Name        :  DISPLAY_LOG
 -- | Description :  This procedure is invoked to print in the log file
 -- | Parameters  :  p_message IN VARCHAR2
 -- |                p_optional IN NUMBER
 -- +====================================================================+
   PROCEDURE display_log (p_message IN VARCHAR2, p_optional IN NUMBER)
   IS
   BEGIN
      IF (p_optional = 1)
      THEN
         IF NVL (gc_debug_flag, 'N') = 'Y'
         THEN
            fnd_file.put_line (fnd_file.LOG, p_message);
         END IF;           -- Check for NVL (gc_debug_flag, 'N') = 'Y'
      ELSIF (p_optional = 0)
      THEN
         fnd_file.put_line (fnd_file.LOG, p_message);
      END IF;                              -- Check for p_optional = 1
   END display_log;

-- +====================================================================+
-- | Name        :  DISPLAY_OUT
-- | Description :  This procedure is invoked to print in the Output
-- |                file
-- | Parameters  :  p_message IN VARCHAR2
-- +====================================================================+
   PROCEDURE display_out (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_message);
   END display_out;

-- +====================================================================+
-- | Name        :  VALIDATE_CCID
-- | Description :  This procedure is invoked to validate the CCID
-- | Parameters  :  l_ccid IN NUMBER
-- +====================================================================+
   FUNCTION validate_ccid (p_ccid IN NUMBER)
      RETURN NUMBER
   IS
      does_ccid_exist   NUMBER := 0;
   BEGIN
      display_log ('-- In validate_ccid() CCID: ' || p_ccid, 1);

      SELECT COUNT (1)
        INTO does_ccid_exist
        FROM gl_code_combinations
       WHERE enabled_flag = 'Y'
         AND NVL (end_date_active, SYSDATE) >= SYSDATE
         AND code_combination_id = p_ccid;

      display_log ('-- Finished Validating CCID : ' || p_ccid, 1);
      RETURN does_ccid_exist;
   END validate_ccid;

/*====================================================================+
| Name        :  GENERATE_ORG_CODE                                    |
| Description :  This procedure is invoked to generate org code       |
| Parameters  :  NA                                                   |
+====================================================================*/
FUNCTION generate_org_code
RETURN VARCHAR2 IS

CURSOR csr_get_orgcode IS
SELECT org_code
  FROM xx_inv_org_codes
 WHERE process_flag = 'N'
ORDER BY sno ;

v_org_code    VARCHAR2(10);
v_return_code NUMBER ;

BEGIN
 --
 -- Get the unused org code from the org codes table
 --
 FOR i IN csr_get_orgcode LOOP
   --
   -- Check if the org code is already in use
   --
   v_return_code := check_org_code(i.org_code);
   IF v_return_code <> 0 THEN
    -- Org Code is already used, so update it as used
    update_org_codes(i.org_code);
    --
   ELSE
    --
    v_org_code := i.org_code;
    update_org_codes(i.org_code);
    EXIT;
    --
   END IF;
 END LOOP;
 IF v_org_code IS NULL THEN
  -- No valid org codes exist
  RETURN('?');
 ELSE
  RETURN(v_org_code);
 END IF;
END generate_org_code;
-- +====================================================================+
-- | Name        :  GENERATE_XML
-- | Description :  This procedure is invoked to generate the xml code
-- | Parameters  :  p_control_id IN NUMBER
-- +====================================================================+
FUNCTION generate_xml (p_control_id IN NUMBER)
RETURN CLOB IS
 --
 CURSOR lcu_get_xml_data IS
 SELECT LPAD(location_number_sw,6,0)||':'||org_name_sw AS NAME
       ,org_code                                       AS organizationcode
       ,ebs_location_code                              AS locationcode
   FROM xx_inv_org_loc_def_stg
  WHERE control_id = p_control_id;
 --
 lclob_result       CLOB;
 lc_name            VARCHAR2 (240);
 lc_org_code        VARCHAR2 (3);
 lc_location_code   VARCHAR2 (240);
 lc_xml_string      VARCHAR2 (4000);
 --
BEGIN
 --
 display_log ('-- In  generate_xml()', 1);
 --
  OPEN lcu_get_xml_data;
 FETCH lcu_get_xml_data INTO lc_name,lc_org_code,lc_location_code ;
 CLOSE lcu_get_xml_data;
 --
 lc_xml_string :=   '<Root><InventoryOrganization><Name>'
                 || lc_name
                 || '</Name><OrganizationCode>'
                 || lc_org_code
                 || '</OrganizationCode><LocationCode>'
                 || lc_location_code
                 || '</LocationCode></InventoryOrganization></Root>';
 --
 lclob_result := TO_CLOB (lc_xml_string);
 --
 display_log (' -- Finished Generating Interface XML : '|| lc_xml_string,1);
 --
 RETURN lclob_result;
 --
END generate_xml;

   -- +====================================================================+
   -- | Name        :  GET_IO_CCID
   -- | Description :  This procedure is invoked to generate the ccid
   -- | Parameters  :
   -- |                   p_account_id        IN       NUMBER,
   -- |                   p_location_number   IN       NUMBER,
   -- |                   x_errbuf            OUT      VARCHAR2,
   -- |                   x_retcode           OUT      VARCHAR2,
   -- |                   x_segments          OUT      VARCHAR2
   -- +====================================================================+
      FUNCTION get_io_ccid (
         p_account_id        IN       NUMBER
        ,p_location_number   IN       NUMBER
        ,x_errbuf            OUT      VARCHAR2
        ,x_retcode           OUT      VARCHAR2
        ,x_segments          OUT      VARCHAR2
      )
         RETURN NUMBER
      IS
         ln_adj_ccid           NUMBER;
         lc_segment1           VARCHAR2 (30);
         lc_segment2           VARCHAR2 (30);
         lc_segment3           VARCHAR2 (30);
         lc_segment4           VARCHAR2 (30);
         lc_segment5           VARCHAR2 (30);
         lc_segment6           VARCHAR2 (30);
         lc_segment7           VARCHAR2 (30);
         lc_conc_segments      VARCHAR2 (100);
         lc_structure_number   VARCHAR2 (100);
         lc_err_msg            VARCHAR2 (4000);
      BEGIN
         display_log ('-- In get_ccid() for Account ID : '
                      || p_account_id
                     ,1
                     );

         SELECT gcc.segment2
               ,gcc.segment3
               ,gcc.segment6
               ,gcc.segment7
           INTO lc_segment2
               ,lc_segment3
               ,lc_segment6
               ,lc_segment7
           FROM gl_code_combinations gcc
          WHERE gcc.code_combination_id = p_account_id;

         BEGIN
            display_log
               (   '-- Getting location and company segments for location Number : '
                || p_location_number
               ,1
               );

            SELECT TRIM (ffv.flex_value) location_segment
                  ,TRIM (ffv.attribute1) company_segment
                  ,TRIM (ffv.attribute1) inter_comp_segment
              INTO lc_segment4
                  ,lc_segment1
                  ,lc_segment5
              FROM fnd_flex_value_sets ffvs
                  ,fnd_flex_values ffv
             WHERE ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
               AND ffvs.flex_value_set_id = ffv.flex_value_set_id
               AND LPAD (p_location_number, 6, 0) = ffv.flex_value;

            display_log ('-- Company Segment : ' || lc_segment1, 1);
            display_log ('-- Location Segment : ' || lc_segment4, 1);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RAISE ex_inv_org_incorrect;
         END;

         IF lc_segment1 IS NULL
         THEN
            RAISE ex_inv_org_incorrect;
         END IF;

         BEGIN
            display_log
                    ('-- Obtaining Structure Number for  OD_GLOBAL_COA'
                    ,1
                    );

            SELECT id_flex_num
              INTO lc_structure_number
              FROM fnd_id_flex_structures
             WHERE application_id = 101
               AND id_flex_code = 'GL#'
               AND id_flex_structure_code = 'OD_GLOBAL_COA';

            display_log ('-- Stucture Number : ' || lc_structure_number
                        ,1
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE ex_inv_acc_str_not_found;
         END;

         IF lc_structure_number IS NULL
         THEN
            RAISE ex_inv_acc_str_not_found;
         END IF;

         lc_conc_segments :=
               lc_segment1
            || '.'
            || lc_segment2
            || '.'
            || lc_segment3
            || '.'
            || lc_segment4
            || '.'
            || lc_segment5
            || '.'
            || lc_segment6
            || '.'
            || lc_segment7;
         x_segments := lc_conc_segments;
         display_log ('-- Concatenated segments : ' || lc_conc_segments
                     ,1
                     );
         ln_adj_ccid :=
            fnd_flex_ext.get_ccid
                               (application_short_name      => 'SQLGL'
                               ,key_flex_code               => 'GL#'
                               ,structure_number            => lc_structure_number
                               ,validation_date             => NULL
                               ,concatenated_segments       => lc_conc_segments
                               );

         BEGIN
            IF ln_adj_ccid <= 0
            THEN
               lc_err_msg := fnd_flex_ext.GET_MESSAGE;
               RAISE ex_ccid_creation_err;
            END IF;
         END;

         display_log ('-- CCID: ' || ln_adj_ccid, 1);
         RETURN (ln_adj_ccid);
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE ex_ccid_creation_err;
   END get_io_ccid;

-- +====================================================================+
-- | Name        :  GET_CCID
-- | Description :  This procedure is invoked to generate the ccid
-- | Parameters  :
-- |                   p_account_id        IN       NUMBER,
-- |                   p_location_number   IN       NUMBER,
-- |                   x_errbuf            OUT      VARCHAR2,
-- |                   x_retcode           OUT      VARCHAR2,
-- |                   x_segments          OUT      VARCHAR2
-- +====================================================================+
   FUNCTION get_ccid  (
      p_account_id        IN       NUMBER
     ,p_location_number   IN       NUMBER
     ,x_errbuf            OUT      VARCHAR2
     ,x_retcode           OUT      VARCHAR2
     ,x_segments          OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      ln_adj_ccid           NUMBER;
      lc_segment1           VARCHAR2 (30);
      lc_segment2           VARCHAR2 (30);
      lc_segment3           VARCHAR2 (30);
      lc_segment4           VARCHAR2 (30);
      lc_segment5           VARCHAR2 (30);
      lc_segment6           VARCHAR2 (30);
      lc_segment7           VARCHAR2 (30);
      lc_conc_segments      VARCHAR2 (100);
      lc_structure_number   VARCHAR2 (100);
      lc_err_msg            VARCHAR2 (4000);
   BEGIN
      display_log ('-- In get_ccid() for Account ID : '
                   || p_account_id
                  ,1
                  );

      SELECT gcc.segment2
            ,gcc.segment3
            ,gcc.segment5
            ,gcc.segment6
            ,gcc.segment7
        INTO lc_segment2
            ,lc_segment3
            ,lc_segment5
            ,lc_segment6
            ,lc_segment7
        FROM gl_code_combinations gcc
       WHERE gcc.code_combination_id = p_account_id;

      BEGIN
         display_log
            (   '-- Getting location and company segments for location Number : '
             || p_location_number
            ,1
            );

         SELECT TRIM (ffv.flex_value) location_segment
               ,TRIM (ffv.attribute1) company_segment
           INTO lc_segment4
               ,lc_segment1
           FROM fnd_flex_value_sets ffvs
               ,fnd_flex_values ffv
          WHERE ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
            AND ffvs.flex_value_set_id = ffv.flex_value_set_id
            AND LPAD (p_location_number, 6, 0) = ffv.flex_value;

         display_log ('-- Company Segment : ' || lc_segment1, 1);
         display_log ('-- Location Segment : ' || lc_segment4, 1);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RAISE ex_inv_org_incorrect;
      END;

      IF lc_segment1 IS NULL
      THEN
         RAISE ex_inv_org_incorrect;
      END IF;

      BEGIN
         display_log
                 ('-- Obtaining Structure Number for  OD_GLOBAL_COA'
                 ,1
                 );

         SELECT id_flex_num
           INTO lc_structure_number
           FROM fnd_id_flex_structures
          WHERE application_id = 101
            AND id_flex_code = 'GL#'
            AND id_flex_structure_code = 'OD_GLOBAL_COA';

         display_log ('-- Stucture Number : ' || lc_structure_number
                     ,1
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE ex_inv_acc_str_not_found;
      END;

      IF lc_structure_number IS NULL
      THEN
         RAISE ex_inv_acc_str_not_found;
      END IF;

      lc_conc_segments :=
            lc_segment1
         || '.'
         || lc_segment2
         || '.'
         || lc_segment3
         || '.'
         || lc_segment4
         || '.'
         || lc_segment5
         || '.'
         || lc_segment6
         || '.'
         || lc_segment7;
      x_segments := lc_conc_segments;
      display_log ('-- Concatenated segments : ' || lc_conc_segments
                  ,1
                  );
      ln_adj_ccid :=
         fnd_flex_ext.get_ccid
                            (application_short_name      => 'SQLGL'
                            ,key_flex_code               => 'GL#'
                            ,structure_number            => lc_structure_number
                            ,validation_date             => NULL
                            ,concatenated_segments       => lc_conc_segments
                            );

      BEGIN
         IF ln_adj_ccid <= 0
         THEN
            lc_err_msg := fnd_flex_ext.GET_MESSAGE;
            RAISE ex_ccid_creation_err;
         END IF;
      END;

      display_log ('-- CCID: ' || ln_adj_ccid, 1);
      RETURN (ln_adj_ccid);
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE ex_ccid_creation_err;
   END get_ccid;

-- +====================================================================+
-- | Name        :  GET_ACCOUNT_ID
-- | Description :  This procedure is invoked to validate accounts
-- | Parameters  :  p_control_id   IN       NUMBER,
-- |              x_errbuf       OUT      VARCHAR2,
-- |              x_retcode      OUT      VARCHAR2
-- +====================================================================+

   FUNCTION get_account_id (p_conc_segments VARCHAR2)
      RETURN NUMBER
   IS
      lc_conc_segments   VARCHAR2 (100);
      ln_account_id      NUMBER;
   BEGIN
      lc_conc_segments := p_conc_segments;

      SELECT code_combination_id
        INTO ln_account_id
        FROM gl_code_combinations gcc
       WHERE segment1 =
                SUBSTR (lc_conc_segments
                       ,1
                       , INSTR (lc_conc_segments, '.', 1, 1) - 1
                       )
         AND segment2 =
                SUBSTR (lc_conc_segments
                       , INSTR (lc_conc_segments, '.', 1, 1) + 1
                       ,   INSTR (lc_conc_segments, '.', 1, 2)
                         - (INSTR (lc_conc_segments, '.', 1, 1) + 1)
                       )
         AND segment3 =
                SUBSTR (lc_conc_segments
                       , INSTR (lc_conc_segments, '.', 1, 2) + 1
                       ,   INSTR (lc_conc_segments, '.', 1, 3)
                         - (INSTR (lc_conc_segments, '.', 1, 2) + 1)
                       )
         AND segment4 =
                SUBSTR (lc_conc_segments
                       , INSTR (lc_conc_segments, '.', 1, 3) + 1
                       ,   INSTR (lc_conc_segments, '.', 1, 4)
                         - (INSTR (lc_conc_segments, '.', 1, 3) + 1)
                       )
         AND segment5 =
                SUBSTR (lc_conc_segments
                       , INSTR (lc_conc_segments, '.', 1, 4) + 1
                       ,   INSTR (lc_conc_segments, '.', 1, 5)
                         - (INSTR (lc_conc_segments, '.', 1, 4) + 1)
                       )
         AND segment6 =
                SUBSTR (lc_conc_segments
                       , INSTR (lc_conc_segments, '.', 1, 5) + 1
                       ,   INSTR (lc_conc_segments, '.', 1, 6)
                         - (INSTR (lc_conc_segments, '.', 1, 5) + 1)
                       )
         AND segment7 =
                SUBSTR (lc_conc_segments
                       , INSTR (lc_conc_segments, '.', 1, 6) + 1
                       );


      RETURN ln_account_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ln_account_id := 0;
      RETURN ln_account_id;
      WHEN OTHERS
      THEN
         ln_account_id := 0;
        RETURN ln_account_id;
   END;


-- +====================================================================+
-- | Name        :  VALIDATE_ACCOUNTS
-- | Description :  This procedure is invoked to validate accounts
-- | Parameters  :  p_control_id   IN       NUMBER,
-- |              x_errbuf       OUT      VARCHAR2,
-- |              x_retcode      OUT      VARCHAR2
-- +====================================================================+
   PROCEDURE validate_accounts (
      p_control_id   IN       NUMBER
     ,x_errbuf       OUT      VARCHAR2
     ,x_retcode      OUT      VARCHAR2
   )
   IS
      CURSOR lcu_get_stg_accounts
      IS
         SELECT material_account
               ,material_overhead_account
               ,matl_ovhd_absorption_acct
               ,resource_account
               ,purchase_price_var_account
               ,ap_accrual_account
               ,overhead_account
               ,outside_processing_account
               ,intransit_inv_account
               ,interorg_receivables_account
               ,interorg_price_var_account
               ,interorg_payables_account
               ,cost_of_sales_account
               ,encumbrance_account
               ,project_cost_account
               ,interorg_transfer_cr_account
               ,receiving_account_id
               ,clearing_account_id
               ,retroprice_adj_account_id
               ,sales_account
               ,expense_account
               ,average_cost_var_account
               ,invoice_price_var_account
               ,rcv_exists
           FROM xx_inv_org_loc_def_stg
          WHERE control_id = p_control_id;

      CURSOR lcu_get_stg_reqd_defaults
      IS
         SELECT org_name_sw
               ,org_type_ebs
               ,org_type
               ,od_type_cd_sw
               ,org_code
               ,location_number_sw
               ,location_name
               ,sob
               ,legal_entity
               ,operating_unit
               ,country_id_sw
               ,district_sw
               ,open_date_sw
               ,close_date_sw
               ,sob_name
           FROM xx_inv_org_loc_def_stg
          WHERE control_id = p_control_id;

      get_accounts_rec_type      lcu_get_stg_accounts%ROWTYPE;
      get_reqd_fields_rec_type   lcu_get_stg_reqd_defaults%ROWTYPE;
      ln_is_invalid_account      NUMBER                           := 0;
      ln_is_reqd_field_null      NUMBER                           := 0;
   BEGIN
      BEGIN
         display_log ('--In validate_accounts()', 1);
         display_log ('--Control ID:' || p_control_id, 1);
         gc_invalid_acc_details := '';

         OPEN lcu_get_stg_accounts;

         FETCH lcu_get_stg_accounts
          INTO get_accounts_rec_type;

         display_log ('-- Validating MTL Accounts: ', 1);

         IF (validate_ccid (get_accounts_rec_type.material_account) =
                                                                     0
            )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.material_account
               || ',';
         ELSIF (validate_ccid
                      (get_accounts_rec_type.material_overhead_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.material_overhead_account
               || ',';
         ELSIF (validate_ccid (get_accounts_rec_type.resource_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.resource_account
               || ',';
         ELSIF (validate_ccid
                     (get_accounts_rec_type.purchase_price_var_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.purchase_price_var_account
               || ',';
         ELSIF (validate_ccid
                             (get_accounts_rec_type.ap_accrual_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.ap_accrual_account
               || ',';
         ELSIF (validate_ccid (get_accounts_rec_type.overhead_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.overhead_account
               || ',';
         ELSIF (validate_ccid
                     (get_accounts_rec_type.outside_processing_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.outside_processing_account
               || ',';
         ELSIF (validate_ccid
                          (get_accounts_rec_type.intransit_inv_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.intransit_inv_account
               || ',';
         ELSIF (validate_ccid
                   (get_accounts_rec_type.interorg_receivables_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.interorg_receivables_account
               || ',';
         ELSIF (validate_ccid
                     (get_accounts_rec_type.interorg_price_var_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.interorg_price_var_account
               || ',';
         ELSIF (validate_ccid
                      (get_accounts_rec_type.interorg_payables_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.interorg_payables_account
               || ',';
         ELSIF (validate_ccid
                          (get_accounts_rec_type.cost_of_sales_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.cost_of_sales_account
               || ',';
         ELSIF (validate_ccid
                   (get_accounts_rec_type.interorg_transfer_cr_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.interorg_transfer_cr_account
               || ',';
         ELSIF (validate_ccid (get_accounts_rec_type.sales_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.sales_account
               || ',';
         ELSIF (validate_ccid (get_accounts_rec_type.expense_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.expense_account
               || ',';
         ELSIF (validate_ccid
                       (get_accounts_rec_type.average_cost_var_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.average_cost_var_account
               || ',';
         ELSIF (validate_ccid
                      (get_accounts_rec_type.invoice_price_var_account) =
                                                                     0
               )
         THEN
            ln_is_invalid_account := 1;
            gc_invalid_acc_details :=
                  gc_invalid_acc_details
               || get_accounts_rec_type.invoice_price_var_account
               || ',';
         END IF;

         display_log ('-- Finished Validating MTL Accounts: ', 1);

         IF (get_accounts_rec_type.rcv_exists = 1)
         THEN
            BEGIN
               display_log ('--Validating RCV Accounts: ', 1);

               IF (validate_ccid
                           (get_accounts_rec_type.receiving_account_id) =
                                                                     0
                  )
               THEN
                  ln_is_invalid_account := 1;
                  gc_invalid_acc_details :=
                        gc_invalid_acc_details
                     || get_accounts_rec_type.receiving_account_id
                     || ',';
               ELSIF (validate_ccid
                            (get_accounts_rec_type.clearing_account_id) =
                                                                     0
                     )
               THEN
                  ln_is_invalid_account := 1;
                  gc_invalid_acc_details :=
                        gc_invalid_acc_details
                     || get_accounts_rec_type.clearing_account_id
                     || ',';
               ELSIF (validate_ccid
                         (get_accounts_rec_type.retroprice_adj_account_id
                         ) = 0
                     )
               THEN
                  ln_is_invalid_account := 1;
                  gc_invalid_acc_details :=
                        gc_invalid_acc_details
                     || get_accounts_rec_type.retroprice_adj_account_id
                     || ',';
               END IF;

               display_log ('--Finished Validating RCV Accounts: ', 1);
            END;
         END IF;      --Check for get_accounts_rec_type.rcv_exists = 1

         CLOSE lcu_get_stg_accounts;

         IF (ln_is_invalid_account = 1)
         THEN
            gc_invalid_acc_details :=
               SUBSTR (gc_invalid_acc_details
                      ,1
                      , LENGTH (gc_invalid_acc_details) - 1
                      );
            RAISE ex_inv_invalid_account;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RAISE ex_no_data_in_stg;
      END;

      BEGIN
         OPEN lcu_get_stg_reqd_defaults;

         FETCH lcu_get_stg_reqd_defaults
          INTO get_reqd_fields_rec_type;

         display_log ('--Checking for Required Fields: ', 1);

         IF (   get_reqd_fields_rec_type.org_name_sw IS NULL
             OR TRIM (get_reqd_fields_rec_type.org_name_sw) = ''
            )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.org_type_ebs IS NULL
                OR TRIM (get_reqd_fields_rec_type.org_type_ebs) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.org_type IS NULL
                OR TRIM (get_reqd_fields_rec_type.org_type) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.od_type_cd_sw IS NULL
                OR TRIM (get_reqd_fields_rec_type.od_type_cd_sw) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.org_code IS NULL
                OR TRIM (get_reqd_fields_rec_type.org_code) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (get_reqd_fields_rec_type.location_number_sw IS NULL)
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.location_name IS NULL
                OR TRIM (get_reqd_fields_rec_type.location_name) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.sob IS NULL
                OR TRIM (get_reqd_fields_rec_type.sob) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.legal_entity IS NULL
                OR TRIM (get_reqd_fields_rec_type.legal_entity) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.operating_unit IS NULL
                OR TRIM (get_reqd_fields_rec_type.operating_unit) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.country_id_sw IS NULL
                OR TRIM (get_reqd_fields_rec_type.country_id_sw) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (get_reqd_fields_rec_type.district_sw IS NULL)
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.open_date_sw IS NULL
                OR TRIM (get_reqd_fields_rec_type.open_date_sw) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         ELSIF (   get_reqd_fields_rec_type.sob_name IS NULL
                OR TRIM (get_reqd_fields_rec_type.sob_name) = ''
               )
         THEN
            ln_is_reqd_field_null := 1;
         END IF;

         CLOSE lcu_get_stg_reqd_defaults;

         IF (ln_is_reqd_field_null = 1)
         THEN
            RAISE ex_inv_reqd_field_null;
         END IF;

         display_log ('--Finished Checking for Required Fields: ', 1);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RAISE ex_no_data_in_stg;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END validate_accounts;

-- +====================================================================+
-- | Name        :  GET_LOCATION_DETAILS
-- | Description :  This procedure is called by the Workflow XXGISTR
-- | Parameters  :  p_incoming_doc   IN       VARCHAR2,
-- |              display_type     IN       VARCHAR2,
-- |              document         IN OUT   CLOB,
-- |              document_type    IN OUT   VARCHAR2
-- +====================================================================+
   PROCEDURE get_location_details (
      p_incoming_doc   IN       VARCHAR2
     ,display_type     IN       VARCHAR2
     ,document         IN OUT   CLOB
     ,document_type    IN OUT   VARCHAR2
   )
   IS
      lclob_document   CLOB := NULL;


   Cursor c_get_location_details
   IS
       SELECT location_number_sw,
              org_code ,
              location_name
         FROM xx_inv_org_loc_def_stg
        WHERE request_id = p_incoming_doc
          AND ready_to_process_flag = 'Y';

   BEGIN
      display_log ('--In Get_Location_Details()', 1);
      document_type := 'text/plain';
      lclob_document :=
                       lclob_document || RPAD ('LOCATION_NUMBER', 30);
      lclob_document := lclob_document || RPAD ('LOCATION_NAME', 30);
      lclob_document :=
                   lclob_document || RPAD ('ORG_CODE', 10)
                   || CHR (10);
      FOR lc_get_loc_details IN c_get_location_details
      LOOP
        lclob_document := lclob_document || RPAD (lc_get_loc_details.location_number_sw, 30);
        lclob_document := lclob_document || RPAD (lc_get_loc_details.location_name, 30);
        lclob_document := lclob_document || RPAD (lc_get_loc_details.org_code, 10) || CHR (10);

      END LOOP;

--      document := lclob_document || p_incoming_doc;
      document := lclob_document;
      display_log ('--Finished Preparing Workflow Message Body: ', 1);
   END get_location_details;

--
/*+============================================================================+
| Name        :  UPDATE_STG_ORG_DATA                                           |
| Description :  This procedure will be called by Conc Program                 |
|               OD: GI Populate Copy Org Staging table Program                 |
| Parameters  :  x_errbuf       OUT      VARCHAR2,                             |
|              x_retcode      OUT      VARCHAR2,                               |
|              p_debug_flag   IN       VARCHAR2                                +
+=============================================================================*/
PROCEDURE update_stg_org_data (x_errbuf               OUT  VARCHAR2
                              ,x_retcode              OUT  VARCHAR2
                              ,p_debug_flag           IN   VARCHAR2
                              ,p_records_to_process   IN   VARCHAR2
                              )
IS
--
 ln_control_id                 XX_INV_ORG_LOC_DEF_STG.control_id%TYPE;
 lc_org_type                   XX_INV_ORG_LOC_DEF_STG.org_type%TYPE;
 ln_total_rows                 NUMBER;
 ln_num_batches                NUMBER;
 lc_org_type_ebs               XX_INV_ORG_LOC_DEF_STG.org_type_ebs%TYPE;
 ln_location_number            XX_INV_ORG_LOC_DEF_STG.location_number_sw%TYPE;
 lc_model_org_code             VARCHAR2 (3);
 lc_model_org_name             XX_INV_ORG_LOC_DEF_STG.model_organization_name%TYPE;
 ln_model_org_id               XX_INV_ORG_LOC_DEF_STG.model_org_id%TYPE;
 lc_primary_cost_method        XX_INV_ORG_LOC_DEF_STG.primary_cost_method%TYPE;
 ln_cost_organization_id       XX_INV_ORG_LOC_DEF_STG.cost_organization_id%TYPE;
 ln_default_material_cost_id   XX_INV_ORG_LOC_DEF_STG.default_material_cost_id%TYPE;
 lc_calendar_code              XX_INV_ORG_LOC_DEF_STG.calendar_code%TYPE;
 lc_user_receipt_num_code      XX_INV_ORG_LOC_DEF_STG.user_defined_receipt_num_code%TYPE;
 lc_manual_receipt_num_type    XX_INV_ORG_LOC_DEF_STG.manual_receipt_num_type%TYPE;
 lc_next_receipt_num           XX_INV_ORG_LOC_DEF_STG.next_receipt_num%TYPE;
 lt_accounts_tbl_type          xx_inv_accounts_tbl_type;
 lc_group_code                 XX_INV_ORG_LOC_DEF_STG.group_code%TYPE;
 lc_item_val_org               VARCHAR2 (240);
 lc_country_code               XX_INV_ORG_LOC_DEF_STG.country_id_sw%TYPE;
 ln_item_val_org_id            NUMBER;
 ln_sob_id                     NUMBER;
 ln_legal_entity_id            NUMBER;
 ln_operating_unit_id          NUMBER;
 lc_sob                        XX_INV_ORG_LOC_DEF_STG.sob%TYPE;
 lc_sob_name                   XX_INV_ORG_LOC_DEF_STG.sob_name%TYPE;
 lc_legal_entity               XX_INV_ORG_LOC_DEF_STG.legal_entity%TYPE;
 lc_operating_unit             XX_INV_ORG_LOC_DEF_STG.operating_unit%TYPE;
 lc_org_code                   XX_INV_ORG_LOC_DEF_STG.org_code%TYPE;
 ln_batch_size                 NUMBER;
 ln_start_num                  NUMBER;
 ln_end_num                    NUMBER;
 ln_does_role_exist            NUMBER;
 lc_location_name              XX_INV_ORG_LOC_DEF_STG.location_name%TYPE;
 lc_current_time               VARCHAR2 (100);
 lclob_document                CLOB                                     := NULL;
 lc_request_id                 VARCHAR2(240)                            := NULL;
 lc_message_data               VARCHAR2 (4000);
 ln_message_code               NUMBER;
 ln_does_rcv_exist             XX_INV_ORG_LOC_DEF_STG.rcv_exists%TYPE   := 0;
 ln_val_hrs                    NUMBER;
 lc_val_team                   VARCHAR2 (100);
 lc_val_start_time             VARCHAR2 (100);
 ln_conc_request_id            NUMBER;
 lc_errmsg                     VARCHAR2 (4000);
 ln_is_data_processed          NUMBER                                   := 0;
 lt_control_id_type            xx_control_tbl_type;
 ln_control_id_index           NUMBER                                   := 0;
 ln_total_records              NUMBER                                   := 0;
 ln_errored_records            NUMBER                                   := 0;
 ln_processed_records          NUMBER                                   := 0;
 lc_org_name                   VARCHAR2 (300);
 ln_org_already_exists         NUMBER;
 ln_duplicate_records          NUMBER                                   :=0;
 ln_dup_retcode             NUMBER                                      :=0;
--
--
 CURSOR lcu_stg_org_types (p_batch_sz NUMBER) IS
 SELECT DISTINCT stg.org_type||
                 stg.od_type_cd_sw||
                 stg.od_sub_type_cd_sw AS         org_type_ebs
                ,COUNT (*) AS                     rec_to_be_processed
                ,CEIL (COUNT (*) / p_batch_sz) AS num_batches
   FROM  xx_inv_org_loc_def_stg stg
        ,hr_locations hl
        ,fnd_flex_value_sets ffvs
        ,fnd_flex_values ffv
  WHERE stg.rms_attribute_created_flag = 'Y'
    AND stg.process_action = 'CREATE'
    AND (stg.org_created_flag IS NULL OR stg.org_created_flag = 'N')
    AND stg.ready_to_process_flag           = 'N'
    AND LPAD (stg.location_number_sw, 6, 0) = SUBSTR(hl.location_code,1,6)
    AND stg.country_id_sw                 = hl.country
    AND hl.inventory_organization_id IS NULL
    AND ffvs.flex_value_set_name            ='OD_GL_GLOBAL_LOCATION'
    AND ffvs.flex_value_set_id              = ffv.flex_value_set_id
    AND LPAD (stg.location_number_sw, 6, 0) = ffv.flex_value
 GROUP BY stg.org_type|| stg.od_type_cd_sw|| stg.od_sub_type_cd_sw;


-- Picks up data from Staging table that are also in EBIZ(duplicate records)
 CURSOR lcu_dup_data IS
 SELECT stg.control_id
       ,stg.location_number_sw AS location_number
       ,stg.org_name_sw        AS org_name
   FROM xx_inv_org_loc_def_stg stg
  WHERE stg.rms_attribute_created_flag = 'Y'
    AND stg.process_action = 'CREATE'
    AND (stg.org_created_flag IS NULL OR stg.org_created_flag = 'N')
    AND stg.ready_to_process_flag = 'N'
    AND LPAD (stg.location_number_sw, 6, 0)
                        || ':'
                        || stg.org_name_sw IN (SELECT NAME
                                                 FROM hr_all_organization_units);
 -- Cursor to check duplicate records
 CURSOR csr_check_dup_locations IS
 SELECT control_id,
        LPAD(location_number_sw,6,0) location_number,
        country_id_sw
   FROM xx_inv_org_loc_def_stg stg
  WHERE rms_attribute_created_flag = 'Y'
    AND process_action = 'CREATE'
    AND (stg.org_created_flag IS NULL OR stg.org_created_flag = 'N')
    AND ready_to_process_flag           = 'N' ;
 --
 v_org_count 	NUMBER :=0;
 v_hr_loc_code  VARCHAR2(60) ;
 v_hr_loc_id    NUMBER ;
 v_err_mesg     VARCHAR2(200);
--
-- Picks up data from Staging table that needs to be processed. Only those rows which have a valid location record in
-- HR_LOCATIONS must be picked up.
 CURSOR lcu_stg_data (
         p_org_type    VARCHAR2
        ,p_start_num   NUMBER
        ,p_end_num     NUMBER
        ,p_batch_size  NUMBER
      ) IS
 SELECT *
   FROM (SELECT ROWNUM AS row_num
               ,stg.control_id
               ,stg.org_type||stg.od_type_cd_sw||stg.od_sub_type_cd_sw AS org_type_ebs
               ,stg.location_number_sw AS location_number
               ,country_id_sw AS country_code
               ,stg.location_name AS location_name
               ,stg.org_name_sw AS org_name
           FROM xx_inv_org_loc_def_stg stg
               ,hr_locations hl
               ,fnd_flex_value_sets ffvs
               ,fnd_flex_values ffv
          WHERE stg.rms_attribute_created_flag          = 'Y'
            AND stg.process_action                      = 'CREATE'
            AND (stg.org_created_flag IS NULL
                 OR stg.org_created_flag = 'N')
            AND stg.ready_to_process_flag               = 'N'
            AND LPAD (stg.location_number_sw, 6, 0) = SUBSTR(hl.location_code,1,6)
            AND stg.country_id_sw                 = hl.country
            AND LPAD (stg.location_number_sw, 6, 0)
                ||':'|| stg.org_name_sw NOT IN (SELECT NAME
                                                  FROM hr_all_organization_units)
            AND hl.inventory_organization_id IS NULL
            AND ffvs.flex_value_set_name                = 'OD_GL_GLOBAL_LOCATION'
            AND ffvs.flex_value_set_id                  = ffv.flex_value_set_id
            AND LPAD (stg.location_number_sw, 6, 0)     = ffv.flex_value
            AND stg.org_type||stg.od_type_cd_sw
                ||stg.od_sub_type_cd_sw                 = p_org_type
            AND stg.group_code IS NULL
		AND stg.error_message IS NULL) f
  WHERE 1=1
    AND f.row_num < p_batch_size +1
    ;--BETWEEN p_start_num AND p_end_num;

-- To get Model Org Code from Lookup for that particular org_type
 CURSOR lcu_get_model_org_code (p_org_type VARCHAR2) IS
 SELECT attribute6
   FROM fnd_lookup_values
  WHERE lookup_type                     = 'ORG_TYPE'
    AND enabled_flag                    = 'Y'
    AND NVL (end_date_active, SYSDATE) >= SYSDATE
    AND lookup_code                     = p_org_type;

-- To get Model Org ID and Model Org Name
 CURSOR lcu_get_model_org_id (p_org_code VARCHAR2) IS
 SELECT b.NAME
       ,a.organization_id
   FROM mtl_parameters               a,
        hr_all_organization_units_vl b
  WHERE a.organization_id = b.organization_id
    AND a.organization_id != a.master_organization_id
    AND a.organization_code = p_org_code;

--To get defaults from the Model Org
 CURSOR lcu_get_mtl_model_org_defaults (p_org_id NUMBER) IS
 SELECT primary_cost_method
               ,cost_organization_id
               ,default_material_cost_id
               ,calendar_code
           FROM mtl_parameters
          WHERE organization_id = p_org_id;

--To get other receiving parameters for the Model Org
 CURSOR lcu_get_rcv_model_org_defaults (p_org_id NUMBER) IS
 SELECT user_defined_receipt_num_code
       ,manual_receipt_num_type
       ,next_receipt_num
   FROM rcv_parameters
  WHERE organization_id = p_org_id;
--
BEGIN
 --
 -- Update batch_code to null for all orgs that are stuck or failed.
 --
 UPDATE xx_inv_org_loc_def_stg
    SET error_code		      = NULL ,
        error_message		  = NULL
  WHERE ready_to_process_flag = 'N'
    AND error_message IS NOT NULL;
 --
 -- Reset the process_flag in Org Codes table
 --
 UPDATE xx_inv_org_codes
    SET process_flag='N';
 COMMIT;
 --
 -- Loop through all stg table to update the org codes and delete records from MTL COPY ORG INTERFACE
 --

 display_log ('--In update_stg_org_data() ', 1);
 gc_debug_flag := p_debug_flag;
 --
 display_log ('--In update_stg_org_data() ', 1);
 display_out(RPAD('Office Depot',100) || 'Date:' || SYSDATE);
 display_out(LPAD('OD Populate Copy Organization staging table',70)|| LPAD ('Page:1', 36));
 display_out('');
 display_out('');
 display_out('===================================================================');
 display_out('====================== Duplicate Records ============================');
 display_out('===================================================================');
 display_out(RPAD ('CONTROL_ID', 15)|| RPAD ('LOCATION #', 15)|| RPAD ('ORGANIZATION NAME', 100));
 display_out ('');
 --
 -- To fetch duplicate records and update the ready to process flag to 'E'
 --
 display_log ('--Updating Duplicate Records ', 1);
 FOR l_dup_data_rec IN lcu_dup_data
 LOOP
  --
  UPDATE xx_inv_org_loc_def_stg
     SET ready_to_process_flag ='E'
   WHERE control_id = l_dup_data_rec.control_id;
  --
  ln_message_code := -1;
  fnd_message.set_name ('XXPTP','XXPTP_ORG_FOR_LOC_EXISTS');
  fnd_message.set_token ('LOC_NUM',l_dup_data_rec.location_number);
  lc_message_data := fnd_message.get;
  --
  log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
           ,p_exception      => 'ORG_FOR_LOC_EXISTS'
           ,p_message        => lc_message_data
           ,p_code           => ln_message_code
           );
  --
  lc_errmsg := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;

  UPDATE xx_inv_org_loc_def_stg
     SET update_date   = SYSDATE
        ,updated_by    = g_user_id
        ,error_code    = SUBSTR (ln_message_code, 1, 20)
        ,error_message = SUBSTR (lc_message_data, 1, 200)
   WHERE control_id    = l_dup_data_rec.control_id;

  ln_dup_retcode := 1;
  --
  display_out(RPAD(l_dup_data_rec.control_id,15)||RPAD(l_dup_data_rec.location_number,15)
              || RPAD (l_dup_data_rec.org_name, 100));

  ln_duplicate_records := ln_duplicate_records + 1;
  --
 END LOOP;
  --
 COMMIT;
 --
 -- Update records as error if country code is null
 --
 display_log ('--Checking for Null values for country id ', 1);
 UPDATE xx_inv_org_loc_def_stg
    SET ready_to_process_flag = 'E' ,
        error_message		= 'Country Id Column Cannot be Null'
  WHERE country_id_sw IS NULL
    AND rms_attribute_created_flag = 'Y'
    AND process_action = 'CREATE'
    AND ready_to_process_flag = 'N' ;
 --
 -- Update duplicate locations as error
 --
 --
 display_log ('--Checking Duplicate Locations ', 1);
 FOR i IN csr_check_dup_locations
 LOOP
  --
  v_hr_loc_code    := NULL;
  v_hr_loc_id      := NULL;
  v_err_mesg       := NULL;
  --
  BEGIN
   --
   SELECT location_code,location_id
     INTO v_hr_loc_code,v_hr_loc_id
     FROM hr_locations
    WHERE SUBSTR(location_code,1,6) = i.location_number
      AND country                   = i.country_id_sw ;
   --
   UPDATE xx_inv_org_loc_def_stg
      SET ebs_location_code = v_hr_loc_code,
          ebs_location_id   = v_hr_loc_id
    WHERE control_id  = i.control_id;
   --
  EXCEPTION
   --
   WHEN TOO_MANY_ROWS THEN
    UPDATE xx_inv_org_loc_def_stg
       SET ready_to_process_flag = 'E',
           error_message         = 'More than 1 Loc/country Combination exist',
           update_date           = SYSDATE  ,
           updated_by            = g_user_id
     WHERE CONTROL_ID            = i.control_id ;
   --
   WHEN NO_DATA_FOUND THEN
    UPDATE xx_inv_org_loc_def_stg
       SET ready_to_process_flag = 'E',
           error_message         = 'Loc/country Combination does not exist',
           update_date           = SYSDATE  ,
           updated_by            = g_user_id
     WHERE CONTROL_ID            = i.control_id ;
   --
   WHEN OTHERS THEN
    v_err_mesg := SUBSTR('When Others getting Loc/country, SQL Error'||SQLERRM,1,190);
    display_log (v_err_mesg, 1);
    UPDATE xx_inv_org_loc_def_stg
       SET ready_to_process_flag = 'E',
           error_message         = v_err_mesg,
           update_date           = SYSDATE  ,
           updated_by            = g_user_id
     WHERE CONTROL_ID            = i.control_id ;
   --
  END;
  --
  COMMIT;
  --
 END LOOP;
--
 display_out('');
 display_out('');
 display_out('===================================================================');
 display_out('====================== Successful Records ============================');
 display_out('===================================================================');
 display_out('Info about additional data written to XX_INV_ORG_LOC_DEF_STAGE table:');
 display_out(   RPAD ('CONTROL_ID', 15)
             || RPAD ('ORG_TYPE_EBS', 20)
             || RPAD ('ORG_CODE', 10)
             || RPAD ('SOB', 10)
             || RPAD ('LEGAL_ENTITY', 15)
             || RPAD ('OPERATING_UNIT', 20)
             || RPAD ('MODEL_ORGANIZATION_NAME', 50)
             || RPAD ('GROUP_CODE', 15)
             || RPAD ('PRIMARY_COST_METHOD', 25)
             || RPAD ('COST_ORGANIZATION_ID', 25)
             || RPAD ('DEFAULT_MATERIAL_COST_ID', 30)
             || RPAD ('CALENDAR_CODE', 15)
             || RPAD ('MATERIAL_ACCOUNT', 30)
             || RPAD ('MATERIAL_OVERHEAD_ACCOUNT', 30)
             || RPAD ('MATL_OVHD_ABSORPTION_ACCT', 30)
             || RPAD ('RESOURCE_ACCOUNT', 30)
             || RPAD ('PURCHASE_PRICE_VAR_ACCOUNT', 30)
             || RPAD ('AP_ACCRUAL_ACCOUNT', 30)
             || RPAD ('OVERHEAD_ACCOUNT', 30)
             || RPAD ('OUTSIDE_PROCESSING_ACCOUNT', 30)
             || RPAD ('INTRANSIT_INV_ACCOUNT', 30)
             || RPAD ('INTERORG_RECEIVABLES_ACCOUNT', 30)
             || RPAD ('INTERORG_PRICE_VAR_ACCOUNT', 30)
             || RPAD ('INTERORG_PAYABLES_ACCOUNT', 30)
             || RPAD ('COST_OF_SALES_ACCOUNT', 30)
             || RPAD ('ENCUMBRANCE_ACCOUNT', 30)
             || RPAD ('PROJECT_COST_ACCOUNT', 30)
             || RPAD ('INTERORG_TRANSFER_CR_ACCOUNT', 30)
             || RPAD ('RECEIVING_ACCOUNT_ID', 30)
             || RPAD ('USER_DEFINED_RECEIPT_NUM_CODE', 30)
             || RPAD ('MANUAL_RECEIPT_NUM_TYPE', 30)
             || RPAD ('CLEARING_ACCOUNT_ID', 30)
             || RPAD ('RETROPRICE_ADJ_ACCOUNT_ID', 30)
             || RPAD ('SALES_ACCOUNT', 30)
             || RPAD ('EXPENSE_ACCOUNT', 30)
             || RPAD ('AVERAGE_COST_VAR_ACCOUNT', 30)
             || RPAD ('INVOICE_PRICE_VAR_ACCOUNT', 30)
             || RPAD ('READY_TO_PROCESS_FLAG', 30)
            );
 display_out ('');
 --
 --
 BEGIN
  display_log('--Reading profile value: XX_GI_GRP_BATCH_SIZE',1);
  --
  SELECT fnd_profile.VALUE ('XX_GI_GRP_BATCH_SIZE')
    INTO ln_batch_size
    FROM DUAL;
  --
  IF (ln_batch_size IS NULL OR ln_batch_size <= 0) THEN
   RAISE ex_invalid_grp_size;
  END IF;
  --
  display_log ('--Profile value: ' || ln_batch_size, 1);
 EXCEPTION
  WHEN ex_invalid_grp_size THEN
   --
   ln_message_code := -1;
   fnd_message.set_name ('XXPTP', 'XXPTP_GRP_BAT_SIZE_NULL');
   lc_message_data := fnd_message.get;
   --
   log_error(p_prog_name  => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
            ,p_exception  => 'INVALID_GRP_SIZE_EX'
            ,p_message    => lc_message_data
            ,p_code       => ln_message_code
            );
   --
   x_retcode := 2;
   x_errbuf  := 'Procedure: UPDATE_STG_ORG_DATA: ' || lc_message_data;
   display_out ('No Data Processed.' || x_errbuf);
   display_log ('--Error: ' || x_errbuf, 0);
   RAISE;
  --
  WHEN OTHERS THEN
   --
   ln_message_code := -1;
   fnd_message.set_name ('XXPTP', 'XXPTP_GRP_BAT_SIZE_NULL');
   lc_message_data := fnd_message.get;
   --
   log_error(p_prog_name  => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
            ,p_exception  => 'UNEXPECTED'
            ,p_message    => lc_message_data
            ,p_code       => ln_message_code
            );
   --
   x_retcode := 2;
   x_errbuf  := 'Procedure: UPDATE_STG_ORG_DATA: ' || lc_message_data;
   display_out ('No Data Processed.' || x_errbuf);
   display_log ('--Error: ' || x_errbuf, 0);
   RAISE;
   --
 END;
 --
 -- Will loop for diff organization types
 --
 display_log ('--Processing data for each ORG_TYPE ', 1);
 --
 FOR l_stg_org_type_rec IN lcu_stg_org_types (ln_batch_size)
 LOOP
  --
  lc_org_type       := l_stg_org_type_rec.org_type_ebs        ;
  ln_total_rows     := l_stg_org_type_rec.rec_to_be_processed ;
  ln_num_batches    := l_stg_org_type_rec.num_batches         ;
  ln_total_records  := ln_total_records + ln_total_rows       ;
  --
  display_log('--ORG_TYPE: ' || lc_org_type, 1);
  display_log('--Number of Records(Without Duplicates): ' || ln_total_rows, 1);
  display_log('--Number of Batches: ' || ln_num_batches, 1);
  --
  -- The following for, will loop for diff batches for an organization
  display_log ('--Processing data for each Batch ', 1);
  FOR i IN 1 .. ln_num_batches
  LOOP
   -- Not required comment out
   --
   -- ln_start_num := (i - 1) * ln_batch_size + 1;
   -- ln_end_num   := ln_batch_size * i          ;
   --
   -- display_log ('--Batch Start Number: ' || ln_start_num, 1);
   -- display_log ('--Batch End Number: ' || ln_end_num, 1);
    display_log ('--ORG_TYPE: ' || lc_org_type, 1);
    --
    SELECT 'GRP'|| xx_gi_group_code_s.NEXTVAL
      INTO lc_group_code
      FROM DUAL;

    display_log('--Starting Processing for for the Batch(Group Code):'|| lc_group_code,1);

    --The following for, will loop for each and every record in the staging table

    FOR l_stg_data_rec IN lcu_stg_data(lc_org_type
                                      ,ln_start_num
                                      ,ln_end_num
 		                          ,ln_batch_size
                                      )
    LOOP
     --
     ln_control_id      := l_stg_data_rec.control_id     ;
     lc_org_type_ebs    := l_stg_data_rec.org_type_ebs   ;
     ln_location_number := l_stg_data_rec.location_number;
     lc_country_code    := l_stg_data_rec.country_code   ;
     lc_location_name   := l_stg_data_rec.location_name  ;
     lc_org_name        := l_stg_data_rec.org_name       ;
     --
     BEGIN
      --
      display_log('===================================================================',1);
      display_log('-- Processing for Control ID : '|| ln_control_id,1);
      --
      -- If Country code or org type is null throw exception
      IF ( (lc_country_code IS NULL OR TRIM (lc_country_code) = '') OR
           (ln_location_number IS NULL)                             OR
           (lc_org_type_ebs IS NULL OR TRIM (lc_org_type_ebs) = '')
         ) THEN
       RAISE ex_rms_pop_data_invalid;
      END IF;
      --
      SELECT COUNT (1)
        INTO ln_org_already_exists
        FROM hr_all_organization_units
       WHERE attribute1 = TO_CHAR(ln_location_number);
      --
      IF (ln_org_already_exists > 0) THEN
       RAISE ex_org_for_loc_exists;
      END IF;
      --
      --Get Item Validation Org to fetch the SOB,Legal Entity and Operating Unit details
      lc_item_val_org := 'OD_ITEM_VALIDATION_' || TRIM (lc_country_code);
      --
      display_log('--Obtained Item Validation Org: '|| lc_item_val_org,1);
      --
      BEGIN
       SELECT organization_id
         INTO ln_item_val_org_id
         FROM hr_all_organization_units haou
        WHERE haou.TYPE = 'VAL'
          AND TRIM (NAME) = TRIM (lc_item_val_org);

       SELECT org_information1 AS sob
             ,org_information2 AS legal_entity
             ,org_information3 AS operating_unit
         INTO ln_sob_id
             ,ln_legal_entity_id
             ,ln_operating_unit_id
         FROM hr_organization_information_v
        WHERE org_information_context ='Accounting Information'
          AND organization_id = ln_item_val_org_id;

       SELECT NAME
         INTO lc_operating_unit
         FROM hr_all_organization_units
        WHERE organization_id = ln_operating_unit_id;

       SELECT short_name
             ,NAME
         INTO lc_sob
             ,lc_sob_name
         FROM gl_ledgers          -- gl_sets_of_books  Commented by sivalanka for R12 upgrade 
        WHERE ledger_id=ln_sob_id;  --set_of_books_id = ln_sob_id; Commented by sivalanka for R12 upgrade 

       SELECT NAME
         INTO lc_legal_entity
        -- FROM hr_legal_entities -- Commented by Veronica for R12 Upgrade Retrofit

        FROM xle_entity_profiles -- Added by Veronica for R12 Upgrade Retrofit
       -- WHERE organization_id = ln_legal_entity_id; -- Commented by Veronica for R12 Upgrade Retrofit

       WHERE legal_entity_id = ln_legal_entity_id; -- Added by Veronica for R12 Upgrade Retrofit
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         RAISE ex_item_val_org_invalid;
      END;
      --
      display_log('--Obtained SOB, Operating Unit and Legal Entity Details: ',1);
      --
      -- ORG_CODE generation .

      lc_org_code := generate_org_code ();
      --
      IF lc_org_code = '?' THEN
       --
       display_log('No Valid Org codes',0);
       display_out('No Valid Org codes');
       --
       RAISE_APPLICATION_ERROR(-21000,'No valid Org Codes, Please populate table with org codes');
      END IF;
     --
      lc_model_org_code := NULL;
      --
      BEGIN
       --
       OPEN  lcu_get_model_org_code (lc_org_type_ebs);
       FETCH lcu_get_model_org_code INTO lc_model_org_code;
       CLOSE lcu_get_model_org_code;
       --
       IF (lc_model_org_code IS NULL OR TRIM (lc_model_org_code) = '') THEN
        RAISE ex_model_org_code_null;
       END IF;
       --
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
        RAISE ex_model_org_code_null;
      END;
      --
      display_log ('--Obtained Model Org Code:'|| lc_model_org_code,1);
      --
      BEGIN
       --
        OPEN lcu_get_model_org_id (lc_model_org_code);
       FETCH lcu_get_model_org_id INTO lc_model_org_name,ln_model_org_id;
       CLOSE lcu_get_model_org_id;
       --
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
        RAISE ex_model_org_id_not_found;
      END;
      --
      display_log('--Obtained Model Org ID:'|| ln_model_org_id,1);
      --
      BEGIN
       --
        OPEN lcu_get_mtl_model_org_defaults(ln_model_org_id);
       FETCH lcu_get_mtl_model_org_defaults
        INTO lc_primary_cost_method
            ,ln_cost_organization_id
            ,ln_default_material_cost_id
            ,lc_calendar_code;
       CLOSE lcu_get_mtl_model_org_defaults;
       --
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
        RAISE ex_no_mtl_data_found;
      END;
      --
      display_log('--Obtained Model Org MTL Defaults:',1);
      --
      SELECT COUNT(1)
        INTO ln_does_rcv_exist
        FROM rcv_parameters
       WHERE organization_id = ln_model_org_id;
      --
      IF (ln_does_rcv_exist = 1) THEN
       --
       BEGIN
        --
        display_log('--Does Model Org have RCV Options: Yes',1);
        --
         OPEN lcu_get_rcv_model_org_defaults(ln_model_org_id);
        FETCH lcu_get_rcv_model_org_defaults
         INTO lc_user_receipt_num_code
             ,lc_manual_receipt_num_type
             ,lc_next_receipt_num;
        CLOSE lcu_get_rcv_model_org_defaults;
        --
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
        RAISE ex_no_rcv_data_found;
       END;
       --
       display_log('--Obtained Model Org RCV Defaults:',1);
       --
      END IF;
      --
      get_accounts(p_model_org_id        => ln_model_org_id
                  ,p_location_number     => ln_location_number
                  ,p_does_rcv_exist      => ln_does_rcv_exist
                  ,x_accounts_tbl_type   => lt_accounts_tbl_type
                  ,x_errbuf              => x_errbuf
                  ,x_retcode             => x_retcode
                  );
      --
      display_log('--Updating staging table XX_INV_ORG_LOC_DEF_STG',1);
      --
      UPDATE xx_inv_org_loc_def_stg
         SET model_organization_name        = lc_model_org_name
            ,group_code                     = lc_group_code
            ,primary_cost_method            = lc_primary_cost_method
            ,cost_organization_id           = ln_cost_organization_id
            ,default_material_cost_id       = ln_default_material_cost_id
            ,calendar_code                  = lc_calendar_code
            ,material_account               = lt_accounts_tbl_type(0).material_account
            ,material_overhead_account      = lt_accounts_tbl_type(0).material_overhead_account
            ,matl_ovhd_absorption_acct      = lt_accounts_tbl_type(0).matl_ovhd_absorption_acct
            ,resource_account               = lt_accounts_tbl_type(0).resource_account
            ,purchase_price_var_account     = lt_accounts_tbl_type(0).purchase_price_var_account
            ,ap_accrual_account             = lt_accounts_tbl_type(0).ap_accrual_account
            ,overhead_account               = lt_accounts_tbl_type(0).overhead_account
            ,outside_processing_account     = lt_accounts_tbl_type(0).outside_processing_account
            ,intransit_inv_account          = lt_accounts_tbl_type(0).intransit_inv_account
            ,interorg_receivables_account   = lt_accounts_tbl_type(0).interorg_receivables_account
            ,interorg_price_var_account     = lt_accounts_tbl_type(0).interorg_price_var_account
            ,interorg_payables_account      = lt_accounts_tbl_type(0).interorg_payables_account
            ,cost_of_sales_account          = lt_accounts_tbl_type(0).cost_of_sales_account
            ,encumbrance_account            = lt_accounts_tbl_type(0).encumbrance_account
            ,project_cost_account           = lt_accounts_tbl_type(0).project_cost_account
            ,interorg_transfer_cr_account   = lt_accounts_tbl_type(0).interorg_transfer_cr_account
            ,receiving_account_id           = lt_accounts_tbl_type(0).receiving_account_id
            ,user_defined_receipt_num_code  = lc_user_receipt_num_code
            ,manual_receipt_num_type        = lc_manual_receipt_num_type
            ,next_receipt_num               = lc_next_receipt_num
            ,clearing_account_id            = lt_accounts_tbl_type(0).clearing_account_id
            ,retroprice_adj_account_id      = lt_accounts_tbl_type(0).retroprice_adj_account_id
            ,sales_account                  = lt_accounts_tbl_type(0).sales_account
            ,expense_account                = lt_accounts_tbl_type(0).expense_account
            ,average_cost_var_account       = lt_accounts_tbl_type(0).avg_cost_var_account
            ,invoice_price_var_account      = lt_accounts_tbl_type(0).invoice_price_var_account
            ,org_type_ebs                   = lc_org_type_ebs
            ,sob                            = lc_sob
            ,legal_entity                   = lc_legal_entity
            ,operating_unit                 = lc_operating_unit
            ,org_code                       = lc_org_code
            ,sob_name                       = lc_sob_name
            ,rcv_exists                     = ln_does_rcv_exist
            ,material_acc_code              = lt_accounts_tbl_type(0).material_acc_cd
            ,material_overhead_acc_code     = lt_accounts_tbl_type(0).material_overhead_ac_cd
            ,matl_ovhd_abs_acct_code        = lt_accounts_tbl_type(0).matl_ovhd_abs_acc_cd
            ,resource_acc_code              = lt_accounts_tbl_type(0).resource_acc_cd
            ,pur_price_var_acc_code         = lt_accounts_tbl_type(0).pur_price_var_acc_cd
            ,ap_accrual_acc_code            = lt_accounts_tbl_type(0).ap_accrual_acc_cd
            ,overhead_acc_code              = lt_accounts_tbl_type(0).overhead_acc_cd
            ,outside_proc_acc_code          = lt_accounts_tbl_type(0).outside_processing_acc_cd
            ,intransit_inv_acc_code         = lt_accounts_tbl_type(0).intransit_inv_acc_cd
            ,interorg_rec_acc_code          = lt_accounts_tbl_type(0).interorg_rec_acc_cd
            ,interorg_price_var_acc_code    = lt_accounts_tbl_type(0).interorg_price_var_acc_cd
            ,interorg_payables_acc_code     = lt_accounts_tbl_type(0).interorg_payables_acc_cd
            ,cost_of_sales_acc_code         = lt_accounts_tbl_type(0).cost_of_sales_acc_cd
            ,encumbrance_acc_code           = lt_accounts_tbl_type(0).encumbrance_acc_cd
            ,project_cost_acc_code          = lt_accounts_tbl_type(0).project_cost_acc_cd
            ,interorg_trans_cr_acc_code     = lt_accounts_tbl_type(0).interorg_trnfr_cr_acc_cd
            ,receiving_acc_code             = lt_accounts_tbl_type(0).receiving_acc_cd
            ,clearing_acc_code              = lt_accounts_tbl_type(0).clearing_acc_cd
            ,retroprice_adj_acc_code        = lt_accounts_tbl_type(0).retropr_adj_acc_cd
            ,sales_acc_code                 = lt_accounts_tbl_type(0).sales_acc_cd
            ,expense_acc_code               = lt_accounts_tbl_type(0).expense_acc_cd
            ,avg_cost_var_acc_code          = lt_accounts_tbl_type(0).avg_cost_var_acc_cd
            ,invoice_price_var_acc_code     = lt_accounts_tbl_type(0).invoice_price_var_acc_cd
            ,model_org_id                   = ln_model_org_id
            ,transferred_to_mcoi            = 'N'
            ,update_date                    = SYSDATE
            ,updated_by                     = g_user_id
            ,request_id                     = fnd_global.conc_request_id
       WHERE control_id                     = ln_control_id;
      --
      validate_accounts(p_control_id  => ln_control_id
                       ,x_errbuf      => x_errbuf
                       ,x_retcode     => x_retcode
                       );
      --
      display_log
                     ('--Setting READY_TO_PROCESS_FLAG to Y in staging table XX_INV_ORG_LOC_DEF_STG'
                     ,1
                     );

                  UPDATE xx_inv_org_loc_def_stg
                     SET --ready_to_process_flag = 'Y'
                         update_date = SYSDATE
                        ,updated_by = g_user_id
                   WHERE control_id = ln_control_id;

      display_out(  RPAD(ln_control_id, 15)
                  ||RPAD(lc_org_type_ebs, 20)
                  ||RPAD(lc_org_code, 10)
                  ||RPAD(lc_sob, 10)
                  ||RPAD(lc_legal_entity, 15)
                  ||RPAD(lc_operating_unit, 20)
                  ||RPAD(lc_model_org_name, 50)
                  ||RPAD(lc_group_code, 15)
                  ||RPAD(NVL(lc_primary_cost_method, '-'), 25)
                  ||RPAD(NVL(TO_CHAR (ln_cost_organization_id),'-'),25)
                  ||RPAD(NVL(TO_CHAR (ln_default_material_cost_id),'-'),30)
                  ||RPAD(lc_calendar_code, 15)
                  ||RPAD(lt_accounts_tbl_type (0).material_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).material_overhead_account,30)
                  ||RPAD(NVL(TO_CHAR(lt_accounts_tbl_type (0).matl_ovhd_absorption_acct),'-'),30)
                  ||RPAD(lt_accounts_tbl_type (0).resource_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).purchase_price_var_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).ap_accrual_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).overhead_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).outside_processing_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).intransit_inv_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).interorg_receivables_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).interorg_price_var_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).interorg_payables_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).cost_of_sales_account,30)
                  ||RPAD(NVL(TO_CHAR(lt_accounts_tbl_type (0).encumbrance_account),'-'),30)
                  ||RPAD(NVL(TO_CHAR(lt_accounts_tbl_type (0).project_cost_account),'-'),30)
                  ||RPAD(lt_accounts_tbl_type (0).interorg_transfer_cr_account,30)
                  ||RPAD(NVL(TO_CHAR(lt_accounts_tbl_type (0).receiving_account_id),'-'),30)
                  ||RPAD(lc_user_receipt_num_code,30)
                  ||RPAD (lc_manual_receipt_num_type, 30)
                  ||RPAD(NVL(TO_CHAR(lt_accounts_tbl_type (0).clearing_account_id),'-'),30)
                  ||RPAD(NVL(TO_CHAR(lt_accounts_tbl_type (0).retroprice_adj_account_id),'-'),30)
                  ||RPAD (lt_accounts_tbl_type (0).sales_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).expense_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).avg_cost_var_account,30)
                  ||RPAD(lt_accounts_tbl_type (0).invoice_price_var_account,30)
                  ||RPAD ('Y', 30)
                 );
      --
      lclob_document := lclob_document || RPAD (ln_location_number, 30);
      lclob_document := lclob_document || RPAD (lc_location_name, 30);
      lclob_document := lclob_document || RPAD (lc_org_code, 10)|| CHR (10);
      --
      display_log ('--Committing Data', 1);
      --
      COMMIT;
      ln_is_data_processed := 1;
     EXCEPTION
      WHEN ex_rms_pop_data_invalid THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP','XXPTP_RMS_DATA_INVALID');
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
                ,p_exception      => 'RMS_POP_DATA_INVALID'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg :='Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       display_log('--Error:'|| lc_errmsg, 0);

       update_stg_data_err_details(p_message     => lc_message_data
                                  ,p_code        => ln_message_code
                                  ,p_control_id  => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;

       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw :=ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message := lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;

      WHEN ex_org_for_loc_exists THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP','XXPTP_ORG_FOR_LOC_EXISTS');
       fnd_message.set_token ('LOC_NUM',ln_location_number);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
                ,p_exception      => 'ORG_FOR_LOC_EXISTS'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg :='Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       display_log('--Error:' || lc_errmsg, 0);
       update_stg_data_err_details(p_message     => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf  := 'Procedure: UPDATE_STG_ORG_DATA: ';
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message := lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;

      WHEN ex_item_val_org_invalid THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP','XXPTP_VAL_ORG_INVALID');
       fnd_message.set_token ('ITEM_VAL_ORG',lc_item_val_org);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
                ,p_exception      => 'NO_DATA_FOUND'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       display_log ('--Error:' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id :=ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw :=ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_model_org_code_null THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name('XXPTP','XXPTP_MODEL_ORG_NOT_SETUP');
       fnd_message.set_token ('ORG_TYPE_EBS',lc_org_type_ebs);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
                ,p_exception      => 'XX_MODEL_ORG_CODE_NULL'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       display_log ('--Error:' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf  := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message := lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_model_org_id_not_found THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP','XXPTP_MODEL_ORG_ID_NULL');
       fnd_message.set_token ('ORG_CODE',lc_model_org_code);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
                ,p_exception      => 'NO_DATA_FOUND'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       display_log ('--Error:' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_no_mtl_data_found THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name('XXPTP','XXPTP_MODEL_ORG_MTL_NOT_FOUND');
       fnd_message.set_token ('ORG_ID', ln_model_org_id);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
                ,p_exception      => 'NO_DATA_FOUND'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg :='Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       display_log ('--Error:' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_no_rcv_data_found THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name('XXPTP','XXPTP_MODEL_ORG_RCV_NOT_FOUND');
       fnd_message.set_token ('ORG_ID', ln_model_org_id);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
                ,p_exception      => 'NO_DATA_FOUND'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                 );
       lc_errmsg :='Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       display_log ('--Error:' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_inv_org_incorrect THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP','XXPTP_INCORRECT_ORG');
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.GET_CCID'
                ,p_exception      => 'XX_INV_ORG_INCORRECT'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg :='Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       display_log ('--Error:' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_inv_acc_str_not_found THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name('XXPTP','XXPTP_ACC_STRUCT_NOT_FOUND');
       fnd_message.set_token ('COA', 'OD_GLOBAL_COA');
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.GET_CCID'
                ,p_exception      => 'XX_INV_ACC_STR_NOT_FOUND'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg :='Procedure: GET_CCID: ' || lc_message_data;
       display_log ('-- Error: ' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_ccid_creation_err THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP', 'XXPTP_CCID_GEN');
       fnd_message.set_token ('SQL_ERR', SQLERRM);
       lc_message_data := fnd_flex_ext.GET_MESSAGE;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.GET_CCID'
                ,p_exception      => 'XX_CCID_CREATION_ERR'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg := 'Procedure: GET_CCID: ' || lc_message_data;
       display_log ('-- Error: ' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_inv_invalid_account THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP','XXPTP_INV_ACC_INVALID');
       fnd_message.set_token ('CONTROL_ID',ln_control_id);
       fnd_message.set_token ('ACC_DETAILS',gc_invalid_acc_details);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.VALIDATE_ACCOUNTS'
                ,p_exception      => 'EX_INV_INVALID_ACCOUNT'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg := 'Procedure: VALIDATE_ACCOUNTS: ' || lc_message_data;
       display_log ('-- Error: ' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_inv_reqd_field_null THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP','XXPTP_REQD_FIELDS_NULL');
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.VALIDATE_ACCOUNTS'
                ,p_exception      => 'EX_INV_REQD_FIELD_NULL'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg :='Procedure: VALIDATE_ACCOUNTS: '|| lc_message_data;
       display_log ('-- Error: ' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_no_data_in_stg THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP','XXPTP_NO_STG_DATA_FOUND');
       fnd_message.set_token ('CONTROL_ID',ln_control_id);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.VALIDATE_ACCOUNTS'
                ,p_exception      => 'NO_DATA_IN_STG'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg :='Procedure: VALIDATE_ACCOUNTS: '|| lc_message_data;
       display_log ('-- Error: ' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_no_data_in_mtl THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name('XXPTP','XXPTP_MODEL_ORG_MTL_NOT_FOUND');
       fnd_message.set_token ('ORG_ID', ln_model_org_id);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.GET_ACCOUNTS'
                ,p_exception      => 'NO_DATA_IN_MTL'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg := 'Procedure: GET_ACCOUNTS: ' || lc_message_data;
       display_log ('-- Error: ' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN ex_no_data_in_rcv THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name('XXPTP','XXPTP_MODEL_ORG_RCV_NOT_FOUND');
       fnd_message.set_token ('ORG_ID', ln_model_org_id);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.GET_ACCOUNTS'
                ,p_exception      => 'NO_DATA_IN_RCV'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg := 'Procedure: GET_ACCOUNTS: ' || lc_message_data;
       display_log ('-- Error: ' || lc_errmsg, 0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;
      WHEN OTHERS THEN
       ROLLBACK;
       ln_message_code := -1;
       fnd_message.set_name ('XXPTP','XXPTP_UNEXPECTED_ERR');
       fnd_message.set_token ('SQL_ERR', SQLERRM);
       lc_message_data := fnd_message.get;
       log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
                ,p_exception      => 'UNEXPECTED'
                ,p_message        => lc_message_data
                ,p_code           => ln_message_code
                );
       lc_errmsg :='Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       display_log ('--Unexpected Error: ' || lc_errmsg,0);
       update_stg_data_err_details(p_message         => lc_message_data
                                  ,p_code            => ln_message_code
                                  ,p_control_id      => ln_control_id
                                  );
       x_retcode := 1;
       x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
       lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
       lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
       lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)
                                                            || ':'
                                                            || lc_org_name;
       lt_control_id_type (ln_control_id_index).error_message :=lc_message_data;
       ln_control_id_index := ln_control_id_index + 1;

     END;

     display_log('-------End of Processing for Control ID:'|| ln_control_id,1 );
     display_log('===================================================================',1);
    END LOOP;

    display_log('--Finished Processing for for the Batch(Group Code): '|| lc_group_code,1);
   END LOOP;

   display_log('--Finished Processing data for ORG_TYPE:'|| lc_org_type,1);
 END LOOP;

 UPDATE xx_inv_org_loc_def_stg
    SET ready_to_process_flag = 'Y'
  WHERE request_id  = fnd_global.conc_request_id
    AND org_code IS NOT NULL;

 COMMIT;

 display_out ('');

 IF (ln_control_id_index > 0) THEN
  BEGIN
   display_out('===================================================================');
   display_out('====================== Errored Records ============================');
   display_out('===================================================================');
   display_out(  RPAD ('CONTROL_ID', 15)
               ||RPAD ('LOCATION_NUMBER', 30)
               || RPAD ('ORGANIZATION_NAME', 100)
               || RPAD ('ERROR MESSAGE',100)
              );
   FOR i IN lt_control_id_type.FIRST .. lt_control_id_type.LAST
   LOOP
    display_out(  RPAD (lt_control_id_type (i).control_id, 15)
                ||RPAD (lt_control_id_type (i).location_number_sw,30 )
                ||RPAD (lt_control_id_type (i).org_name, 100)
                ||RPAD (substr(lt_control_id_type (i).error_message,1,100), 100)
               );
   END LOOP;
  END;
 END IF;

 -- Adding duplicate records
 ln_total_records := ln_total_records + ln_duplicate_records;
 ln_errored_records := ln_control_id_index + ln_duplicate_records;
 ln_processed_records := ln_total_records - ln_errored_records;
 display_out ('');
 display_out ('Total Records:' || ln_total_records);
 display_out ('Errored Records:' || ln_errored_records);
 display_out ('Successful Records:' || ln_processed_records);
 display_out ('');
 display_out(LPAD('*** End of Report - < OD Populate Copy Organization staging table > ***' ,98));
 display_log('--Submitting the OD: GI Master ORg Program and Initiating Workflow',1);
 BEGIN
  ln_val_hrs :=fnd_profile.VALUE ('XX_GI_ORG_DATA_VAL_PERIOD');
  display_log(   '--Obtained Profile Value XX_GI_ORG_DATA_VAL_PERIOD:'|| ln_val_hrs,1);
  lc_val_team := fnd_profile.VALUE ('XX_GI_ORG_DATA_VAL_TEAM');
  display_log('--Obtained Profile Value XX_GI_ORG_DATA_VAL_TEAM:'|| lc_val_team,1);
  lc_val_start_time :=TO_CHAR ((SYSDATE + (ln_val_hrs / 24)),'DD-MON-YYYY HH:MI:SS');
  lc_current_time := TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS');
  display_log ('--Current time :' || lc_current_time, 1);
  display_log('--Start time for Concurrent Program OD: GI Copy Org Master Program:'|| lc_val_start_time,1);

  SELECT COUNT (1)
    INTO ln_does_role_exist
    FROM wf_roles
   WHERE NAME = lc_val_team;

  IF (ln_is_data_processed = 1) THEN
    IF (ln_does_role_exist = 0) THEN
     RAISE ex_invalid_wf_role;
    ELSE
     BEGIN
      display_log('--Is Profile Value XX_GI_ORG_DATA_VAL_TEAM a valid workflow role:Yes',1 );
      lc_request_id := fnd_global.conc_request_id;
      wf_engine.createprocess (itemtype      => 'XXGISTR'
                               ,itemkey       => lc_current_time
                               ,process       => 'NOTIF_PROCESS'
                                          );
      wf_engine.setitemattrtext(itemtype      => 'XXGISTR'
                               ,itemkey       => lc_current_time
                               ,aname         => 'LOCATION_DETAIL'
                              ,avalue        =>    'PLSQLCLOB:XX_GI_NEW_STORE_AUTO_PKG.GET_LOCATION_DETAILS/'
                                       || lc_request_id
                               );
      wf_engine.setitemattrtext(itemtype      => 'XXGISTR'
                               ,itemkey       => lc_current_time
                               ,aname         => 'VALIDATION_TEAM_ID'
                               ,avalue        => lc_val_team
                               );
      wf_engine.startprocess (itemtype      => 'XXGISTR'
                             ,itemkey       => lc_current_time
                             );
     END;
    END IF;
  END IF;
  -- Testing for Org
  ln_conc_request_id :=fnd_request.submit_request
                                   (application      => g_prog_application
                                   ,program          => g_prog_executable
                                   ,sub_request      => FALSE
                                   ,start_time       => lc_val_start_time
                                   ,argument1        => 'Y'
                                   ,argument2        => p_records_to_process
                                   );

  IF (ln_conc_request_id = 0) THEN
   display_log (   'Unable to submit the conc program'|| g_prog_executable,1);
   RAISE ex_submit_child;
  ELSE
   display_log (   'Submitted the conc program'|| g_prog_executable,1);
   display_log ('Concurrent Request ID:'|| ln_conc_request_id,1 );
  END IF;

  display_log ('--Committing Data....', 1);
  COMMIT;

  IF ln_dup_retcode = 1 THEN
   x_retcode := 1;
  END IF;
 EXCEPTION
  WHEN ex_submit_child  THEN
   ROLLBACK;
   ln_message_code := -1;
   fnd_message.set_name ('XXPTP','XXPTP_CONC_PRG_SUBMIT_FAILED');
   fnd_message.set_token ('PRG_NAME', g_prog_executable);
   fnd_message.set_token ('SQL_ERR', SQLERRM);
   lc_message_data := fnd_message.get;
   log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
            ,p_exception      => 'EX_SUBMIT_CHILD'    --IN VARCHAR2
            ,p_message        => lc_message_data      --IN VARCHAR2
            ,p_code           => ln_message_code        --IN NUMBER
            );
   x_retcode := 2;
   x_errbuf :='Procedure: UPDATE_STG_ORG_DATA: ' || lc_message_data;
   display_log ('--Error:' || x_errbuf, 0);
   RAISE;
  WHEN ex_invalid_wf_role THEN
   ROLLBACK;
   ln_message_code := -1;
   fnd_message.set_name ('XXPTP', 'XXPTP_WF_ROLE_INVALID');
   fnd_message.set_token ('WF_ROLE', lc_val_team);
   lc_message_data := fnd_message.get;
   log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_STG_ORG_DATA'
            ,p_exception      => 'INVALID_WF_ROLE_EX' --IN VARCHAR2
            ,p_message        => lc_message_data      --IN VARCHAR2
            ,p_code           => ln_message_code        --IN NUMBER
            );
   x_retcode := 2;
   x_errbuf :='Procedure: UPDATE_STG_ORG_DATA: ' || lc_message_data;
   display_log ('--Error:' || x_errbuf, 0);
   RAISE;
  WHEN OTHERS THEN
   ROLLBACK;
   ln_message_code := -1;
   fnd_message.set_name ('XXPTP', 'XXPTP_UNEXPECTED_ERR');
   fnd_message.set_token ('SQL_ERR', SQLERRM);
   lc_message_data := fnd_message.get;
   log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.UPDATE_ORG_STG_DATA'
            ,p_exception      => 'UNEXPECTED'         --IN VARCHAR2
            ,p_message        => lc_message_data      --IN VARCHAR2
            ,p_code           => ln_message_code        --IN NUMBER
            );
   x_retcode := 2;
   x_errbuf :='Procedure: UPDATE_STG_ORG_DATA: ' || lc_message_data;
   display_log ('--Unexpected Error: ' || x_errbuf, 0);
   RAISE;
 END;
 display_log('--Finished Submitting the OD: GI Master ORg Program and Initiating Workflow',1 );

END update_stg_org_data;
--

-- +====================================================================================+
-- | Name        :  GET_ACCOUNTS
-- | Description :  This procedure builds the accounts for each record in staging table
-- | Parameters  :  p_model_org_id        IN              NUMBER,
-- |              p_location_number     IN              NUMBER,
-- |              p_does_rcv_exist      IN              NUMBER,
-- |              x_accounts_tbl_type   OUT NOCOPY      xx_inv_accounts_tbl_type,
-- |              x_errbuf              OUT             VARCHAR2,
-- |              x_retcode             OUT             VARCHAR2
-- +====================================================================================+
   PROCEDURE get_accounts (
      p_model_org_id        IN              NUMBER
     ,p_location_number     IN              NUMBER
     ,p_does_rcv_exist      IN              NUMBER
     ,x_accounts_tbl_type   OUT NOCOPY      xx_inv_accounts_tbl_type
     ,x_errbuf              OUT             VARCHAR2
     ,x_retcode             OUT             VARCHAR2
   )
   IS
--to get the MTL and RCV accounts for the Model Org
      CURSOR lcu_get_mtl_accounts (p_org_id NUMBER)
      IS
         SELECT material_account
               ,material_overhead_account
               ,matl_ovhd_absorption_acct
               ,resource_account
               ,purchase_price_var_account
               ,ap_accrual_account
               ,overhead_account
               ,outside_processing_account
               ,intransit_inv_account
               ,interorg_receivables_account
               ,interorg_price_var_account
               ,interorg_payables_account
               ,cost_of_sales_account
               ,encumbrance_account
               ,project_cost_account
               ,interorg_transfer_cr_account
               ,sales_account
               ,expense_account
               ,average_cost_var_account
               ,invoice_price_var_account
           FROM mtl_parameters m
          WHERE m.organization_id = p_org_id;

      CURSOR lcu_get_rcv_accounts (p_org_id NUMBER)
      IS
         SELECT receiving_account_id
               ,clearing_account_id
               ,retroprice_adj_account_id
           FROM rcv_parameters r
          WHERE r.organization_id = p_org_id;

      ln_temp_account_id    NUMBER;
      ln_temp_ccid          NUMBER;
      lr_get_accounts_rec   lcu_get_mtl_accounts%ROWTYPE;
      lr_get_rcv_acc_rec    lcu_get_rcv_accounts%ROWTYPE;
      lc_acc_segments       VARCHAR2 (2000);
   BEGIN
      display_log ('--In get_accounts()', 1);

      BEGIN
         display_log (   '--Getting MTL Accounts for Model Org ID:'
                      || p_model_org_id
                     ,1
                     );

         OPEN lcu_get_mtl_accounts (p_model_org_id);

         FETCH lcu_get_mtl_accounts
          INTO lr_get_accounts_rec;

         ln_temp_account_id := lr_get_accounts_rec.material_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).material_account := ln_temp_ccid;
         x_accounts_tbl_type (0).material_acc_cd := lc_acc_segments;
         ln_temp_account_id :=
                         lr_get_accounts_rec.material_overhead_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).material_overhead_account :=
                                                          ln_temp_ccid;
         x_accounts_tbl_type (0).material_overhead_ac_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id := lr_get_accounts_rec.resource_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).resource_account := ln_temp_ccid;
         x_accounts_tbl_type (0).resource_acc_cd := lc_acc_segments;
         ln_temp_account_id :=
                        lr_get_accounts_rec.purchase_price_var_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).purchase_price_var_account :=
                                                          ln_temp_ccid;
         x_accounts_tbl_type (0).pur_price_var_acc_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id := lr_get_accounts_rec.ap_accrual_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).ap_accrual_account := ln_temp_ccid;
         x_accounts_tbl_type (0).ap_accrual_acc_cd := lc_acc_segments;
         ln_temp_account_id := lr_get_accounts_rec.overhead_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).overhead_account := ln_temp_ccid;
         x_accounts_tbl_type (0).overhead_acc_cd := lc_acc_segments;
         ln_temp_account_id :=
                        lr_get_accounts_rec.outside_processing_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).outside_processing_account :=
                                                          ln_temp_ccid;
         x_accounts_tbl_type (0).outside_processing_acc_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id :=
                             lr_get_accounts_rec.intransit_inv_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).intransit_inv_account := ln_temp_ccid;
         x_accounts_tbl_type (0).intransit_inv_acc_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id :=
                      lr_get_accounts_rec.interorg_receivables_account;
         ln_temp_ccid :=
            get_io_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).interorg_receivables_account :=
                                                          ln_temp_ccid;
         x_accounts_tbl_type (0).interorg_rec_acc_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id :=
                        lr_get_accounts_rec.interorg_price_var_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).interorg_price_var_account :=
                                                          ln_temp_ccid;
         x_accounts_tbl_type (0).interorg_price_var_acc_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id :=
                         lr_get_accounts_rec.interorg_payables_account;
         ln_temp_ccid :=
            get_io_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).interorg_payables_account :=
                                                          ln_temp_ccid;
         x_accounts_tbl_type (0).interorg_payables_acc_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id :=
                             lr_get_accounts_rec.cost_of_sales_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).cost_of_sales_account := ln_temp_ccid;
         x_accounts_tbl_type (0).cost_of_sales_acc_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id :=
                      lr_get_accounts_rec.interorg_transfer_cr_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).interorg_transfer_cr_account :=
                                                          ln_temp_ccid;
         x_accounts_tbl_type (0).interorg_trnfr_cr_acc_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id := lr_get_accounts_rec.sales_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).sales_account := ln_temp_ccid;
         x_accounts_tbl_type (0).sales_acc_cd := lc_acc_segments;
         ln_temp_account_id := lr_get_accounts_rec.expense_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).expense_account := ln_temp_ccid;
         x_accounts_tbl_type (0).expense_acc_cd := lc_acc_segments;
         ln_temp_account_id :=
                          lr_get_accounts_rec.average_cost_var_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).avg_cost_var_account := ln_temp_ccid;
         x_accounts_tbl_type (0).avg_cost_var_acc_cd :=
                                                       lc_acc_segments;
         ln_temp_account_id :=
                         lr_get_accounts_rec.invoice_price_var_account;
         ln_temp_ccid :=
            get_ccid (ln_temp_account_id
                     ,p_location_number
                     ,x_errbuf
                     ,x_retcode
                     ,lc_acc_segments
                     );
         x_accounts_tbl_type (0).invoice_price_var_account :=
                                                          ln_temp_ccid;
         x_accounts_tbl_type (0).invoice_price_var_acc_cd :=
                                                       lc_acc_segments;

         CLOSE lcu_get_mtl_accounts;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RAISE ex_no_data_in_mtl;
      END;

      display_log
              (   '--Finished Getting MTL Accounts for Model Org ID:'
               || p_model_org_id
              ,1
              );

      IF (p_does_rcv_exist = 1)
      THEN
         display_log ('--Do RCV Accounts exist for Model Org ID:Y'
                     ,1);

         BEGIN
            display_log
                      (   '--Getting RCV Accounts for Model Org ID:'
                       || p_model_org_id
                      ,1
                      );

            OPEN lcu_get_rcv_accounts (p_model_org_id);

            FETCH lcu_get_rcv_accounts
             INTO lr_get_rcv_acc_rec;

            ln_temp_account_id :=
                               lr_get_rcv_acc_rec.receiving_account_id;
            ln_temp_ccid :=
               get_ccid (ln_temp_account_id
                        ,p_location_number
                        ,x_errbuf
                        ,x_retcode
                        ,lc_acc_segments
                        );
            x_accounts_tbl_type (0).receiving_account_id :=
                                                          ln_temp_ccid;
            x_accounts_tbl_type (0).receiving_acc_cd :=
                                                       lc_acc_segments;
            ln_temp_account_id :=
                                lr_get_rcv_acc_rec.clearing_account_id;
            ln_temp_ccid :=
               get_ccid (ln_temp_account_id
                        ,p_location_number
                        ,x_errbuf
                        ,x_retcode
                        ,lc_acc_segments
                        );
            x_accounts_tbl_type (0).clearing_account_id :=
                                                          ln_temp_ccid;
            x_accounts_tbl_type (0).clearing_acc_cd := lc_acc_segments;
            ln_temp_account_id :=
                          lr_get_rcv_acc_rec.retroprice_adj_account_id;
            ln_temp_ccid :=
               get_ccid (ln_temp_account_id
                        ,p_location_number
                        ,x_errbuf
                        ,x_retcode
                        ,lc_acc_segments
                        );
            x_accounts_tbl_type (0).retroprice_adj_account_id :=
                                                          ln_temp_ccid;
            x_accounts_tbl_type (0).retropr_adj_acc_cd :=
                                                       lc_acc_segments;

            CLOSE lcu_get_rcv_accounts;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RAISE ex_no_data_in_rcv;
         END;

         display_log
              (   '--Finished Getting RCV Accounts for Model Org ID:'
               || p_model_org_id
              ,1
              );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END get_accounts;

--
/*+===========================================================================+
| Name         :   COPYSTG_ORG_DATA                                           |
| Description  :   This procedure is called by conc program                   |
|                  OD: GI Copy Inventory Org Master Program                   |
| Parameters   :   x_errbuf       OUT      VARCHAR2,                          |
|                  x_retcode      OUT      VARCHAR2,                          |
|                  p_debug_flag   IN       VARCHAR2                           |
+============================================================================*/
PROCEDURE copy_stg_org_data (x_errbuf               OUT      VARCHAR2
                            ,x_retcode              OUT      VARCHAR2
                            ,p_debug_flag           IN       VARCHAR2
                            ,p_records_to_process   IN       VARCHAR2
                            )
IS
 --
 ln_control_id           xx_inv_org_loc_def_stg.control_id%TYPE                 ;
 lc_group_code           xx_inv_org_loc_def_stg.group_code%TYPE                 ;
 lc_org_code             xx_inv_org_loc_def_stg.org_code%TYPE                   ;
 ln_does_rcv_exist       xx_inv_org_loc_def_stg.rcv_exists%TYPE     := 0        ;
 ln_model_org_id         xx_inv_org_loc_def_stg.model_org_id%TYPE               ;
 ln_conc_request_id      NUMBER                                                 ;
 ln_org_id               NUMBER                                                 ;
 lc_message_data         VARCHAR2 (4000)                                        ;
 ln_message_code         NUMBER                                                 ;
 ln_location_id          NUMBER                                                 ;
 ln_obj_version_num      NUMBER                                                 ;
 ln_maxwait              NUMBER                                     := 0        ;
 lb_request_status       BOOLEAN                                                ;
 lc_phase                VARCHAR2 (100)                             := NULL     ;
 lc_status               VARCHAR2 (100)                             := NULL     ;
 lc_dev_phase            VARCHAR2 (100)                             := NULL     ;
 lc_dev_status           VARCHAR2 (100)                             := NULL     ;
 lc_message              VARCHAR2 (100)                             := NULL     ;
 lt_conc_req_tbl         xx_conc_requests_tbl_type                              ;
 lclob_xml               CLOB                                                   ;
 ex_submit_child         EXCEPTION                                              ;
 lc_errmsg               VARCHAR2 (4000)                                        ;
 ln_conc_req_index       NUMBER                                      := 0       ;
 ln_operating_unit_id    NUMBER                                                 ;
 lt_control_id_type      xx_control_tbl_type                                    ;
 ln_control_id_index     NUMBER                                      := 0       ;
 lc_org_name             VARCHAR2 (300)                                         ;
 ln_location_number      NUMBER                                                 ;
 lc_invalid_rec_exists   VARCHAR2 (1)                                 := 'N'    ;
 ln_total_records        NUMBER                                       := 0      ;
 ln_errored_records      NUMBER                                       := 0      ;
 ln_processed_records    NUMBER                                       := 0      ;
 ln_org_already_exists   NUMBER                                       := 0      ;

-- Picks up data from Staging table that needs to be processed.
 CURSOR lcu_stg_data IS
 SELECT stg.control_id
               ,stg.group_code
               ,stg.org_code
               ,stg.rcv_exists
               ,stg.location_number_sw
               ,stg.district_sw
               ,stg.open_date_sw
               ,stg.close_date_sw
               ,stg.country_id_sw
               ,stg.org_type
               ,stg.org_name_sw
   FROM xx_inv_org_loc_def_stg stg
  WHERE stg.ready_to_process_flag = 'Y'
    AND stg.organization_id IS NULL
    AND NVL (stg.transferred_to_mcoi, 'N') = 'N';

  CURSOR lcu_get_groups IS
  SELECT DISTINCT stg.group_code
                 ,stg.model_org_id
    FROM xx_inv_org_loc_def_stg stg
        ,mtl_copy_org_interface mcoi
   WHERE stg.ready_to_process_flag = 'Y'
     AND stg.transferred_to_mcoi = 'Y'
     AND mcoi.group_code = stg.group_code
     AND mcoi.organization_code = stg.org_code
     AND stg.organization_id IS NULL
     AND LPAD (stg.location_number_sw,6,0)||':'||stg.org_name_sw NOT IN (SELECT NAME
                                                                           FROM hr_all_organization_units)
     AND DECODE (p_records_to_process,'ERR', 'JAVA_ERR'
                                     ,'NEW', DECODE(NVL(stg.ERROR_CODE,'S'),'0', 'S'
                                                                           ,'-1', 'S'
                                                                           ,'S', 'S'
                                                    )
                                    ,'ALL', DECODE (NVL (stg.ERROR_CODE,'S'),'0', 'S'
                                                                            ,'-1', 'S'
                                                                            ,'S', 'S'
                                                        ,stg.ERROR_CODE
                                                   )
                ) = DECODE (NVL(stg.ERROR_CODE,'S'),'0', 'S'
                                                   ,'-1', 'S'
                                                   ,'S', 'S'
                                   ,stg.ERROR_CODE
                                   );

  CURSOR lcu_get_org_cr_data IS
  SELECT stg.control_id
        ,stg.group_code
        ,stg.org_code
        ,stg.rcv_exists
        ,stg.location_number_sw
        ,stg.district_sw
        ,stg.open_date_sw
        ,stg.close_date_sw
        ,stg.country_id_sw
        ,stg.org_type
        ,stg.org_name_sw
        ,stg.ebs_location_code
   FROM xx_inv_org_loc_def_stg stg
       ,mtl_copy_org_interface mcoi
   WHERE stg.ready_to_process_flag = 'Y'
     AND stg.organization_id IS NULL
     AND stg.transferred_to_mcoi = 'Y'
     AND mcoi.group_code = stg.group_code
     AND mcoi.organization_code = stg.org_code
     AND LPAD (stg.location_number_sw, 6, 0)
                        || ':'
                        || stg.org_name_sw IN (SELECT NAME
                                                   FROM hr_all_organization_units);

      CURSOR lcu_get_java_err_data (p_group_code VARCHAR2)
      IS
      SELECT stg.control_id
               ,stg.location_number_sw
               , LPAD (location_number_sw, 6, 0) || ':' || org_name_sw
                                                          AS org_name
           FROM xx_inv_org_loc_def_stg stg
               ,mtl_copy_org_interface mcoi
          WHERE stg.ready_to_process_flag = 'Y'
            AND stg.organization_id IS NULL
            AND stg.transferred_to_mcoi = 'Y'
            AND mcoi.group_code = stg.group_code
            AND mcoi.group_code = p_group_code
            AND mcoi.organization_code = stg.org_code
            AND nvl(mcoi.status,'R') <>  'S'
            AND LPAD (stg.location_number_sw, 6, 0)
                        || ':'
                        || stg.org_name_sw NOT IN (SELECT NAME
                                                   FROM hr_all_organization_units);


      CURSOR lcu_err_group_codes (p_group_code VARCHAR2)
      IS
         SELECT control_id
               ,location_number_sw
               , LPAD (location_number_sw, 6, 0) || ':' || org_name_sw
                                                          AS org_name
           FROM xx_inv_org_loc_def_stg
          WHERE group_code = p_group_code;

      CURSOR lcu_check_valid_grp_records
      IS
         SELECT stg.group_code
               ,stg.model_org_id
               ,stg.org_code
               ,stg.location_number_sw
               , LPAD (location_number_sw, 6, 0) || ':' || org_name_sw
                                                          AS org_name
           FROM xx_inv_org_loc_def_stg stg
               ,mtl_copy_org_interface mcoi
          WHERE stg.ready_to_process_flag = 'Y'
            AND stg.transferred_to_mcoi = 'Y'
            AND mcoi.group_code = stg.group_code
            AND mcoi.organization_code = stg.org_code
            AND stg.organization_id IS NULL
            AND LPAD (stg.location_number_sw, 6, 0)
                        || ':'
                        || stg.org_name_sw IN (SELECT NAME
                                                   FROM hr_all_organization_units)
            AND DECODE (p_records_to_process
                       ,'ERR', 'JAVA_ERR'
                       ,'NEW', DECODE (NVL (stg.ERROR_CODE, 'S')
                                      ,'0', 'S'
                                      ,'-1', 'S'
                                      ,'S', 'S'
                                      )
                       ,'ALL', DECODE (NVL (stg.ERROR_CODE, 'S')
                                      ,'0', 'S'
                                      ,'-1', 'S'
                                      ,'S', 'S'
                                      ,stg.ERROR_CODE
                                      )
                       ) =
                   DECODE (NVL (stg.ERROR_CODE, 'S')
                          ,'0', 'S'
                          ,'-1', 'S'
                          ,'S', 'S'
                          ,stg.ERROR_CODE
                          );

      CURSOR lcu_get_tot_records (p_records_to_process VARCHAR2)
      IS
         SELECT COUNT (f.control_id)
           FROM (SELECT DISTINCT control_id
                            FROM xx_inv_org_loc_def_stg stg
                                ,mtl_copy_org_interface mcoi
                           WHERE stg.ready_to_process_flag = 'Y'
                             AND stg.transferred_to_mcoi = 'Y'
                             AND mcoi.group_code = stg.group_code
                             AND mcoi.organization_code = stg.org_code
                             AND stg.organization_id IS NULL
                             AND DECODE
                                       (p_records_to_process
                                       ,'ERR', 'JAVA_ERR'
                                       ,'NEW', DECODE
                                                (NVL (stg.ERROR_CODE
                                                     ,'S'
                                                     )
                                                ,'0', 'S'
                                                ,'-1', 'S'
                                                ,'S', 'S'
                                                )
                                       ,'ALL', DECODE
                                                (NVL (stg.ERROR_CODE
                                                     ,'S'
                                                     )
                                                ,'0', 'S'
                                                ,'-1', 'S'
                                                ,'S', 'S'
                                                ,stg.ERROR_CODE
                                                )
                                       ) =
                                    DECODE (NVL (stg.ERROR_CODE, 'S')
                                           ,'0', 'S'
                                           ,'-1', 'S'
                                           ,'S', 'S'
                                           ,stg.ERROR_CODE
                                           )
                 UNION
                 SELECT DISTINCT stg.control_id
                            FROM xx_inv_org_loc_def_stg stg
                           WHERE stg.ready_to_process_flag IN ('Y')
                             AND stg.organization_id IS NULL
                             AND NVL (stg.transferred_to_mcoi, 'N') =
                                                                   'N') f;
BEGIN
 --
 display_log ('--In copy_stg_org_data()', 1);
 gc_debug_flag := p_debug_flag;
 display_out (RPAD ('Office Depot', 100) || 'Date:' || SYSDATE);
 display_out (LPAD ('OD Copy Organization Program', 70)|| LPAD ('Page:1', 36));
 display_out ('');
 display_out('Information about inventory organizations created:');
 display_out ('');
 display_out ('');
 --
 BEGIN
  --
   OPEN lcu_get_tot_records (p_records_to_process);
  FETCH lcu_get_tot_records INTO ln_total_records;
  CLOSE lcu_get_tot_records;
  --
  FOR l_stg_data_rec IN lcu_stg_data LOOP
   --
   BEGIN
    --
    ln_control_id       := l_stg_data_rec.control_id;
    lc_group_code       := l_stg_data_rec.group_code;
    lc_org_code         := l_stg_data_rec.org_code;
    ln_does_rcv_exist   := l_stg_data_rec.rcv_exists;
    lc_org_name         := l_stg_data_rec.org_name_sw;
    ln_location_number  := l_stg_data_rec.location_number_sw;
    --
    SELECT COUNT (1)
      INTO ln_org_already_exists
      FROM hr_all_organization_units
     WHERE attribute1 = TO_CHAR(ln_location_number);
    --
    IF (ln_org_already_exists > 0) THEN
     RAISE ex_org_for_loc_exists;
    END IF;
    --
    display_log ('--Validating for Control ID:'|| ln_control_id,1);
    validate_accounts (p_control_id      => ln_control_id
                      ,x_errbuf          => x_errbuf
                      ,x_retcode         => x_retcode
                      );
    --
    lclob_xml := generate_xml(p_control_id => ln_control_id);
    --
    display_log ('--Inserting data into Interface Table:',1);
    --
    INSERT INTO mtl_copy_org_interface(group_code
                                      ,xml
                                      ,organization_code
                                      ,last_update_date
                                      ,creation_date
                                      ,created_by
                                      ,last_updated_by
                                      ,last_update_login
                                      )
                              VALUES  (lc_group_code
                                      ,lclob_xml
                                      ,lc_org_code
                                      ,SYSDATE
                                      ,SYSDATE
                                      ,g_user_id
                                      ,g_user_id
                                      ,g_user_id
                                      );
    --
    display_log('--Updating TRANSFERRED_TO_MCOI to Y in Staging Table:',1);
    --
    UPDATE xx_inv_org_loc_def_stg stg
       SET transferred_to_mcoi = 'Y'
          ,update_date = SYSDATE
          ,updated_by = g_user_id
     WHERE control_id = ln_control_id;
    --
    display_log ('--Committing Data', 1);
    COMMIT;
    --
   EXCEPTION
    --
    WHEN ex_org_for_loc_exists THEN
     ROLLBACK;
     ln_message_code := -1;
     fnd_message.set_name ('XXPTP','XXPTP_ORG_FOR_LOC_EXISTS');
     fnd_message.set_token ('LOC_NUM',ln_location_number);
     lc_message_data := fnd_message.get;
     log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.VALIDATE_ACCOUNTS'
              ,p_exception      => 'ORG_FOR_LOC_EXISTS'
              ,p_message        => lc_message_data
              ,p_code           => ln_message_code
              );
     lc_errmsg := 'Procedure: VALIDATE_ACCOUNTS: '|| lc_message_data;
     display_log('--Error:' || lc_errmsg, 0);
     update_stg_data_err_details(p_message     => lc_message_data
                                ,p_code        => ln_message_code
                                ,p_control_id  => ln_control_id
                                );
     x_retcode := 1;
     x_errbuf := 'Procedure: VALIDATE_ACCOUNTS: '|| lc_message_data;
     lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
     lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
     lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)|| ':'|| lc_org_name;
     lt_control_id_type (ln_control_id_index).error_message := lc_message_data;
     ln_control_id_index := ln_control_id_index + 1;
    --
    WHEN ex_inv_invalid_account THEN
     ROLLBACK;
     ln_message_code := -1;
     fnd_message.set_name ('XXPTP','XXPTP_INV_ACC_INVALID');
     fnd_message.set_token ('CONTROL_ID', ln_control_id);
     fnd_message.set_token ('ACC_DETAILS',gc_invalid_acc_details);
     lc_message_data := fnd_message.get;
     log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.VALIDATE_ACCOUNTS'
              ,p_exception      => 'EX_INV_INVALID_ACCOUNT'
              ,p_message        => lc_message_data
              ,p_code           => ln_message_code
              );
     lc_errmsg := 'Procedure: VALIDATE_ACCOUNTS: '|| lc_message_data;
     display_log('--Error:' || lc_errmsg, 0);
     update_stg_data_err_details(p_message     => lc_message_data
                                ,p_code        => ln_message_code
                                ,p_control_id  => ln_control_id
                                );
     x_retcode := 1;
     x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
     lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
     lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
     lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)|| ':'|| lc_org_name;
     lt_control_id_type (ln_control_id_index).error_message := lc_message_data;
     ln_control_id_index := ln_control_id_index + 1;
    --
    WHEN ex_inv_reqd_field_null THEN
     ROLLBACK;
     ln_message_code := -1;
     fnd_message.set_name ('XXPTP','XXPTP_REQD_FIELDS_NULL');
     lc_message_data := fnd_message.get;
     log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.VALIDATE_ACCOUNTS'
              ,p_exception      => 'EX_INV_REQD_FIELD_NULL'
              ,p_message        => lc_message_data
              ,p_code           => ln_message_code
              );
     lc_errmsg := 'Procedure: VALIDATE_ACCOUNTS: '|| lc_message_data;
     display_log ('--Error: ' || lc_errmsg, 0);
     update_stg_data_err_details(p_message     => lc_message_data
                                ,p_code        => ln_message_code
                                ,p_control_id  => ln_control_id
                                );
     x_retcode := 1;
     x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
     lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
     lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
     lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)|| ':'|| lc_org_name;
     lt_control_id_type (ln_control_id_index).error_message := lc_message_data;
     ln_control_id_index := ln_control_id_index + 1;
    --
    WHEN ex_no_data_in_stg THEN
     ROLLBACK;
     ln_message_code := -1;
     fnd_message.set_name ('XXPTP','XXPTP_NO_STG_DATA_FOUND');
     fnd_message.set_token ('CONTROL_ID', ln_control_id);
     lc_message_data := fnd_message.get;
     log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.VALIDATE_ACCOUNTS'
              ,p_exception      => 'NO_DATA_IN_STG'
              ,p_message        => lc_message_data
              ,p_code           => ln_message_code
              );
     lc_errmsg := 'Procedure: VALIDATE_ACCOUNTS: '|| lc_message_data;
     display_log ('--Error: ' || lc_errmsg, 0);
     update_stg_data_err_details(p_message     => lc_message_data
                                ,p_code        => ln_message_code
                                ,p_control_id  => ln_control_id
                                );
     x_retcode := 1;
     x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
     lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
     lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
     lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)|| ':'|| lc_org_name;
     lt_control_id_type (ln_control_id_index).error_message := lc_message_data;
     ln_control_id_index := ln_control_id_index + 1;
    --
    WHEN OTHERS THEN
     ROLLBACK;
     ln_message_code := -1;
     fnd_message.set_name ('XXPTP','XXPTP_UNEXPECTED_ERR');
     fnd_message.set_token ('SQL_ERR', SQLERRM);
     lc_message_data := fnd_message.get;
     log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.COPY_ORG_STG_DATA'
              ,p_exception      => 'UNEXPECTED'
              ,p_message        => lc_message_data
              ,p_code           => ln_message_code
              );
     lc_errmsg := 'Procedure: COPY_STG_ORG_DATA: '|| lc_message_data;
     display_log ('--Unexpected Error: ' || lc_errmsg, 0);
     update_stg_data_err_details(p_message     => lc_message_data
                                ,p_code        => ln_message_code
                                ,p_control_id  => ln_control_id
                                );
     x_retcode := 1;
     x_errbuf := 'Procedure: UPDATE_STG_ORG_DATA: '|| lc_message_data;
     lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
     lt_control_id_type (ln_control_id_index).location_number_sw := ln_location_number;
     lt_control_id_type (ln_control_id_index).org_name := LPAD (ln_location_number, 6, 0)|| ':'|| lc_org_name;
     lt_control_id_type (ln_control_id_index).error_message := lc_message_data;
     ln_control_id_index := ln_control_id_index + 1;
   END;
  END LOOP;
  --
  display_log('--Calling Java Concurrent Program: OD: GI Copy Org Child Program for each distinct Group Code',1);
  display_out('===================================================================');
  display_out('-------Records for which the Organization is already created-------');
  display_out('===================================================================');
  display_out(RPAD ('ORG_CODE', 10)|| RPAD ('LOCATION_NUMBER', 30)|| RPAD ('ORGANIZATION_NAME', 100));
  --
  FOR l_invalid_grp_rec IN lcu_check_valid_grp_records
  LOOP
   BEGIN
    display_out(RPAD (l_invalid_grp_rec.org_code, 10)||
                RPAD (l_invalid_grp_rec.location_number_sw,30)||
                RPAD (l_invalid_grp_rec.org_name, 100)
               );
    lc_invalid_rec_exists := 'Y';
   END;
  END LOOP;

  IF (lc_invalid_rec_exists = 'N') THEN
   BEGIN
    display_out('-----------No records found-------------------------');
   END;
  END IF;

  FOR l_get_groups_rec IN lcu_get_groups
  LOOP
   BEGIN
    lc_group_code := l_get_groups_rec.group_code;
    ln_model_org_id := l_get_groups_rec.model_org_id;
    display_log ('--Group Code:' || lc_group_code, 1);
    ln_conc_request_id := FND_REQUEST.submit_request(application   => g_prog_application
                                                    ,program       => g_child_prog_executable
                                                    ,sub_request   => FALSE
                                                    ,argument1     => ln_model_org_id
                                                    ,argument2     => lc_group_code
                                                    ,argument3     => 'N'
                                                    ,argument4     => 'N'
                                                    ,argument5     => 'N'
                                                    ,argument6     => 'N'
                                                    ,argument7     => 'N'
                                                    ,argument8     => 'N'
                                                    );
    COMMIT;

    IF (ln_conc_request_id = 0) THEN
      ROLLBACK;
      display_log('Unable to submit the child conc program '|| g_child_prog_executable,1);
      ln_message_code := -1;
      fnd_message.set_name ('XXPTP','XXPTP_CONC_PRG_SUBMIT_FAILED');
      fnd_message.set_token ('PRG_NAME',g_prog_executable);
      fnd_message.set_token ('SQL_ERR', SQLERRM);
      lc_message_data := fnd_message.get;
      log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.COPY_STG_ORG_DATA'
               ,p_exception      => 'EX_SUBMIT_CHILD'
               ,p_message        => lc_message_data
               ,p_code           => ln_message_code
               );
      x_retcode := 2;
      x_errbuf :='Procedure: COPY_STG_ORG_DATA: '|| lc_message_data;
      display_log ('--Error:' || x_errbuf, 0);
    ELSE
      lt_conc_req_tbl (ln_conc_req_index).conc_request_id := ln_conc_request_id;
      lt_conc_req_tbl (ln_conc_req_index).group_code      := lc_group_code;
      display_log('Submitted the child conc program '||g_child_prog_executable,1);
      display_log('Concurrent Request ID: '|| ln_conc_request_id,1);
    END IF;
    ln_conc_req_index := ln_conc_req_index + 1;
   END;
  END LOOP;

  display_log('--Waited for the all the child processes to complete',1);
  IF (ln_conc_req_index > 0) THEN
   FOR i IN 0 .. (ln_conc_req_index - 1)
   LOOP
    ln_conc_request_id := lt_conc_req_tbl (i).conc_request_id;
    lb_request_status  := FND_CONCURRENT.wait_for_request(request_id  => ln_conc_request_id
                                                         ,interval    => 10
                                                         ,max_wait    => ln_maxwait
                                                         ,phase       => lc_phase
                                                         ,status      => lc_status
                                                         ,dev_phase   => lc_dev_phase
                                                         ,dev_status  => lc_dev_status
                                                         ,message     => lc_message
                                                         );
    IF (lc_dev_status = 'ERROR'      OR
        lc_dev_status = 'TERMINATED' OR
        lc_dev_status = 'CANCELLED'
       )    THEN
     x_retcode := 1;
     x_errbuf  := 'Procedure: UPDATE_STG_ORG_DATA: ' || lc_message;
     --
     FOR grp_code_rec IN lcu_err_group_codes(lt_conc_req_tbl (i).group_code)
     LOOP
      --
      lt_control_id_type(ln_control_id_index).control_id         := grp_code_rec.control_id        ;
      lt_control_id_type(ln_control_id_index).location_number_sw := grp_code_rec.location_number_sw ;
      lt_control_id_type(ln_control_id_index).org_name           := grp_code_rec.org_name          ;
      lt_control_id_type(ln_control_id_index).error_message      := 'Java Error'                           ;
      ln_control_id_index                                       := ln_control_id_index + 1         ;
      --
      UPDATE xx_inv_org_loc_def_stg
         SET error_code = '-1'
            ,error_message = 'Java Error'
       WHERE control_id = grp_code_rec.control_id;
     END LOOP;
     --
    ELSE
     --
     FOR java_grp_code_rec IN lcu_get_java_err_data(lt_conc_req_tbl (i).group_code)
     LOOP
      lt_control_id_type(ln_control_id_index).control_id        := java_grp_code_rec.control_id         ;
      lt_control_id_type(ln_control_id_index).location_number_sw := java_grp_code_rec.location_number_sw ;
      lt_control_id_type(ln_control_id_index).org_name          := java_grp_code_rec.org_name           ;
      lt_control_id_type(ln_control_id_index).error_message     := 'Java Unhandled Exception'           ;
      ln_control_id_index                                       := ln_control_id_index + 1              ;
      --
      UPDATE xx_inv_org_loc_def_stg
         SET error_code = '-1'
            ,error_message = 'Java Unhandled Exception'
       WHERE control_id = java_grp_code_rec.control_id;
     END LOOP;
     --
    END IF;
    --
   END LOOP;
   --
  END IF;
  --
  display_log('--Processing Staging table Records that have passed ORG CREATION via Java CP',1);
  display_out ('');
  display_out('===================================================================');
  display_out('=======================Successful Records===========================');
  display_out('===================================================================');
  display_out(  RPAD ('ORGANIZATION_ID', 20)
              ||RPAD ('ORG_CODE', 10)
              ||RPAD ('LOCATION_NUMBER', 30)
              ||RPAD ('ORGANIZATION_NAME', 100)
             );
  display_out ('');
  --
  FOR l_stg_data_rec IN lcu_get_org_cr_data
  LOOP
   --
   BEGIN
    --
    ln_control_id := l_stg_data_rec.control_id;
    lc_org_code := l_stg_data_rec.org_code;
    display_log ('--Control ID:' || ln_control_id, 1);
    display_log ('--Org Code:' || lc_org_code, 1);
    --
    SELECT organization_id
          ,operating_unit
      INTO ln_org_id
          ,ln_operating_unit_id
      FROM org_organization_definitions
     WHERE organization_code = lc_org_code;
    --
    display_log ('--Org ID:' || ln_org_id, 1);
    --
    UPDATE hr_all_organization_units
       SET attribute1 = l_stg_data_rec.location_number_sw
          ,attribute2 = l_stg_data_rec.district_sw
          ,attribute3 = l_stg_data_rec.open_date_sw
          ,attribute4 = l_stg_data_rec.close_date_sw
          ,attribute5 = l_stg_data_rec.country_id_sw
          ,last_updated_by = g_user_id
          ,last_update_date = SYSDATE
     WHERE organization_id = ln_org_id;
    --
    COMMIT;
    display_log ('--Updating KFF inside DFF link', 1);

    UPDATE mtl_parameters
       SET attribute_category = DECODE (UPPER (l_stg_data_rec.org_type),'STORE', 'Store Attribute'
                                                                       ,'WH'   , 'WH Attributes'
                                       )
          ,attribute6 = ( SELECT MAX (combination_id)
                            FROM xx_inv_org_loc_rms_attribute
                           WHERE location_number_sw = l_stg_data_rec.location_number_sw)
          ,last_updated_by = g_user_id
          ,last_update_date = SYSDATE
     WHERE organization_id = ln_org_id;
     --
     COMMIT;
     SELECT location_id
           ,object_version_number
       INTO ln_location_id
           ,ln_obj_version_num
       FROM hr_locations_all
      WHERE location_code =  l_stg_data_rec.ebs_location_code ;
        --location_code =LPAD(l_stg_data_rec.location_number_sw,6,0)||':'||l_stg_data_rec.org_name_sw;
     --
     display_log('--Linking Location to the newly created ORG using HR_LOCATION_API.update_location',1);
     --
     hr_location_api.update_location(p_effective_date                 => SYSDATE
                                    ,p_location_id                    => ln_location_id
                                    ,p_inventory_organization_id      => ln_org_id
                                    ,p_object_version_number          => ln_obj_version_num
                                    ,p_operating_unit_id              => ln_operating_unit_id
                                    );
     --
     UPDATE xx_inv_org_loc_def_stg stg
        SET organization_id = ln_org_id
           ,org_created_flag = 'Y'
           ,updated_by = g_user_id
           ,update_date = SYSDATE
           ,error_code = NULL
           ,error_message = NULL
      WHERE control_id = ln_control_id;
     --
     display_log('--Committing Data', 1);
     display_out(  RPAD(ln_org_id, 20)
                 ||RPAD(lc_org_code, 10)
                 ||RPAD(l_stg_data_rec.location_number_sw,30)
                 ||LPAD(l_stg_data_rec.location_number_sw,6,0)
                 ||':'
                 ||RPAD(l_stg_data_rec.org_name_sw, 100)
                );
     COMMIT;
     --
   EXCEPTION
    --
    WHEN OTHERS THEN
     ROLLBACK;
     ln_message_code := -1;
     fnd_message.set_name ('XXPTP','XXPTP_UNEXPECTED_ERR');
     fnd_message.set_token ('SQL_ERR', SQLERRM);
     lc_message_data := fnd_message.get;
     log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.COPY_ORG_STG_DATA'
              ,p_exception      => 'UNEXPECTED'
              ,p_message        => lc_message_data
              ,p_code           => ln_message_code
              );
     lc_errmsg := 'Procedure: COPY_STG_ORG_DATA: '|| lc_message_data;
     display_log ('--Unexpected Error: ' || lc_errmsg, 0);
     update_stg_data_err_details(p_message         => lc_message_data
                                ,p_code            => ln_message_code
                                ,p_control_id      => ln_control_id
                                );
     x_retcode := 1;
     x_errbuf  :='Procedure: UPDATE_STG_ORG_DATA: ' || lc_message;
     lt_control_id_type (ln_control_id_index).control_id := ln_control_id;
     lt_control_id_type (ln_control_id_index).location_number_sw := l_stg_data_rec.location_number_sw;
     lt_control_id_type (ln_control_id_index).org_name :=  LPAD (l_stg_data_rec.location_number_sw, 6, 0)
                                                           || ':'|| l_stg_data_rec.org_name_sw;
     lt_control_id_type (ln_control_id_index).error_message := lc_message_data;
     ln_control_id_index := ln_control_id_index + 1;
   END;
  END LOOP;
 END;

 display_out ('');

 IF (ln_control_id_index > 0) THEN
  BEGIN
   display_out('===================================================================');
   display_out('====================== Errored Records ============================');
   display_out('===================================================================');
   display_out(  RPAD ('CONTROL_ID', 15)
               ||RPAD ('LOCATION_NUMBER', 30)
               ||RPAD ('ORGANIZATION_NAME', 100)
              );

   FOR i IN lt_control_id_type.FIRST .. lt_control_id_type.LAST
   LOOP
    display_out(  RPAD (lt_control_id_type (i).control_id, 15)
                ||RPAD (lt_control_id_type (i).location_number_sw,30)
                ||RPAD (lt_control_id_type (i).org_name, 100)
                ||RPAD (lt_control_id_type (i).error_message, 240)
               );
   END LOOP;
  END;
 END IF;

 ln_errored_records := ln_control_id_index;
 ln_processed_records := ln_total_records - ln_errored_records;
 display_out ('');
 display_out ('Total Records:' || ln_total_records);
 display_out ('Errored Records:' || ln_errored_records);
 display_out ('Successful Records:' || ln_processed_records);
 display_out ('');
 display_out(LPAD('*** End of Report - < OD Copy Organization Program > ***',98));
EXCEPTION
 WHEN OTHERS THEN
  ln_message_code := -1;
  fnd_message.set_name ('XXPTP', 'XXPTP_UNEXPECTED_ERR');
  fnd_message.set_token ('SQL_ERR', SQLERRM);
  lc_message_data := fnd_message.get;
  log_error(p_prog_name      => 'XX_GI_NEW_STORE_AUTO_PKG.COPY_STG_ORG_DATA'
           ,p_exception      => 'UNEXPECTED'
           ,p_message        => lc_message_data
           ,p_code           => ln_message_code
           );
   x_retcode := 2;
   x_errbuf  := 'Procedure: COPY_STG_ORG_DATA: ' || lc_message_data;
   display_log ('--Unexpected Error: ' || x_errbuf, 0);
   RAISE;
END copy_stg_org_data;
--

   PROCEDURE get_ccid_wrapper (
      p_inv_sixaccts_tbl_type IN OUT xx_inv_sixaccts_tbl_type,
      p_location_number IN NUMBER
      )
   IS
      lc_errbuf        VARCHAR2 (4000);
      lc_retcode       VARCHAR2 (10);
      ln_account_id   NUMBER;
      ln_temp_ccid    NUMBER;
   BEGIN

      IF p_inv_sixaccts_tbl_type.COUNT > 0
      THEN

         FOR i IN p_inv_sixaccts_tbl_type.FIRST .. p_inv_sixaccts_tbl_type.LAST
         LOOP
            -- Using account segments finding out the account ID
            ln_account_id :=
                 get_account_id (p_inv_sixaccts_tbl_type (i).material_account);

            -- Extracting the accouting segments with the new location number
            ln_temp_ccid :=
               get_ccid (ln_account_id
                        ,p_location_number
                        ,lc_errbuf
                        ,lc_retcode
                        ,p_inv_sixaccts_tbl_type (i).material_account
                        );

            ln_account_id :=
               get_account_id
                          (p_inv_sixaccts_tbl_type (i).material_overhead_account
                          );

            ln_temp_ccid :=
               get_ccid (ln_account_id
                        ,p_location_number
                        ,lc_errbuf
                        ,lc_retcode
                        ,p_inv_sixaccts_tbl_type (i).material_overhead_account
                        );
            ln_account_id :=
                  get_account_id (p_inv_sixaccts_tbl_type (i).resource_account);

            ln_temp_ccid :=
               get_ccid (ln_account_id
                        ,p_location_number
                        ,lc_errbuf
                        ,lc_retcode
                        ,p_inv_sixaccts_tbl_type (i).resource_account
                        );
            ln_account_id :=
                  get_account_id (p_inv_sixaccts_tbl_type (i).overhead_account);

            ln_temp_ccid :=
               get_ccid (ln_account_id
                        ,p_location_number
                        ,lc_errbuf
                        ,lc_retcode
                        ,p_inv_sixaccts_tbl_type (i).overhead_account
                        );
            ln_account_id :=
               get_account_id
                         (p_inv_sixaccts_tbl_type (i).outside_processing_account
                         );

            ln_temp_ccid :=
               get_ccid (ln_account_id
                        ,p_location_number
                        ,lc_errbuf
                        ,lc_retcode
                        ,p_inv_sixaccts_tbl_type (i).outside_processing_account
                        );
            ln_account_id :=
                   get_account_id (p_inv_sixaccts_tbl_type (i).expense_account);

            ln_temp_ccid :=
               get_ccid (ln_account_id
                        ,p_location_number
                        ,lc_errbuf
                        ,lc_retcode
                        ,p_inv_sixaccts_tbl_type (i).expense_account
                        );
         END LOOP;
      END IF;
   END get_ccid_wrapper;

--------------------------------------------------------------------------------------------
-- Function to check if org code is in use
--------------------------------------------------------------------------------------------
FUNCTION check_org_code(p_org_code IN VARCHAR2)
RETURN NUMBER IS

CURSOR csr_checkorg IS
SELECT 1
  FROM mtl_parameters
 WHERE organization_code = p_org_code
UNION ALL
SELECT 1
  FROM mtl_copy_org_interface
 WHERE organization_code = p_org_code
UNION ALL
SELECT 1
  FROM xx_inv_org_loc_def_stg
 WHERE org_code = p_org_code;
--
v_org_exists NUMBER := 0;
--
BEGIN
--
 OPEN csr_checkorg;
FETCH csr_checkorg INTO v_org_exists;
CLOSE csr_checkorg;
--
RETURN(v_org_exists);
END check_org_code;
--------------------------------------------------------------------------------------------
-- Procedure to update the org code as used in the org codes table
--------------------------------------------------------------------------------------------
PROCEDURE update_org_codes(p_org_code IN VARCHAR2) IS
BEGIN
 UPDATE xx_inv_org_codes
    SET process_flag = 'Y'
  WHERE org_code = p_org_code;
END update_org_codes;


END xx_gi_new_store_auto_pkg;
/
