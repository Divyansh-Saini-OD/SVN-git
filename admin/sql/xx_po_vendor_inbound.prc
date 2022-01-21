create or replace PROCEDURE xx_po_vendor_inbound_proc (errbuf OUT VARCHAR2,
                                                       retcode OUT VARCHAR2) AS
  /**********************************************************************************
   NAME:       xx_po_vendor_inbound
   PURPOSE:    This procedure loads the vendor data into the AP vendor API tables then
               submits the three required imports.

   REVISIONS:
  -- Version Date        Author                               Description
  -- ------- ----------- ----------------------               ---------------------
  -- 1.0     06-APR-2007 Greg Dill, Providge Consulting, LLC. Created base version.
  -- 1.1     13-JUL-2007 Greg Dill, Providge Consulting, LLC. Updates based on feedback from Link Test 1.
  -- 1.2     22-AUG-2007 Greg Dill, Providge Consulting, LLC. Updates based on new vendor site naming standards.
  -- 1.3     05-SEP-2007 Greg Dill, Providge Consulting, LLC. Updates based to KFF processing for Defect #1427.
  **********************************************************************************/

  /* Define constants */
  c_no   CONSTANT VARCHAR2(1) := 'N';
  c_when CONSTANT DATE := SYSDATE;
  c_who  CONSTANT fnd_user.user_id%TYPE := fnd_load_util.owner_id('CONVERSION');
  c_yes  CONSTANT VARCHAR2(1) := 'Y';

  /* Define variables */
  v_accts_pay_ccid             xx_ap_supplier_sites_stg.accts_pay_code_combination_id%TYPE;
  v_address_rowid              ROWID;
  v_address1                   xx_ap_supplier_sites_stg.address_line1%TYPE;
  v_address2                   xx_ap_supplier_sites_stg.address_line2%TYPE;
  v_address3                   xx_ap_supplier_sites_stg.address_line3%TYPE;
  v_address4                   xx_ap_supplier_sites_stg.address_line4%TYPE;
  v_area_code                  xx_ap_sup_site_contact_stg.area_code%TYPE;
  v_attribute7                 xx_ap_suppliers_stg.attribute7%TYPE;
  v_attribute8                 xx_ap_suppliers_stg.attribute8%TYPE;
  v_attribute9                 xx_ap_suppliers_stg.attribute9%TYPE;
  v_attribute10                xx_ap_suppliers_stg.attribute10%TYPE;
  v_attribute11                xx_ap_suppliers_stg.attribute11%TYPE;
  v_attribute12                xx_ap_suppliers_stg.attribute12%TYPE;
  v_bool                       BOOLEAN;
  v_ca_cons_ccid               xx_ap_supplier_sites_stg.accts_pay_code_combination_id%TYPE;
  v_ca_trade_ccid              xx_ap_supplier_sites_stg.accts_pay_code_combination_id%TYPE;
  v_child_legacy_vendor_id     xx_ap_suppliers_stg.legacy_vendor_id%TYPE;
  v_city                       xx_ap_supplier_sites_stg.city%TYPE;
  v_contact_rowid              ROWID;
  v_country                    xx_ap_supplier_sites_stg.country%TYPE;
  v_department                 xx_ap_sup_site_contact_stg.department%TYPE;
  v_dev_phase                  VARCHAR2(80);
  v_dev_status                 VARCHAR2(80);
  v_dummy                      xx_ap_supplier_sites_stg.terms_name%TYPE;
  v_duns_number                xx_ap_supplier_sites_stg.duns_number%TYPE;
  v_email_address              xx_ap_supplier_sites_stg.email_address%TYPE;
  v_error_message              VARCHAR2(2000);
  v_error_message_cont         VARCHAR2(2000);
  v_error_message_site         VARCHAR2(2000);
  v_error_message_vend         VARCHAR2(2000);
  v_exclusive_payment_flag     xx_ap_supplier_sites_stg.exclusive_payment_flag%TYPE;
  v_fax                        xx_ap_sup_site_contact_stg.fax%TYPE;
  v_fax_area_code              xx_ap_sup_site_contact_stg.fax_area_code%TYPE;
  v_federal_reportable_flag    xx_ap_suppliers_stg.federal_reportable_flag%TYPE;
  v_first_name                 xx_ap_sup_site_contact_stg.first_name%TYPE;
  v_hold_all_payments_flag     xx_ap_supplier_sites_stg.hold_all_payments_flag%TYPE;
  v_hold_reason                xx_ap_supplier_sites_stg.hold_reason%TYPE;
  v_id_flex_num1               fnd_id_flex_structures.id_flex_num%TYPE;
  v_id_flex_num2               fnd_id_flex_structures.id_flex_num%TYPE;
  v_id_flex_num3               fnd_id_flex_structures.id_flex_num%TYPE;
  v_id_flex_num4               fnd_id_flex_structures.id_flex_num%TYPE;
  v_last_name                  xx_ap_sup_site_contact_stg.last_name%TYPE;
  v_legacy_vendor_id           xx_ap_suppliers_stg.legacy_vendor_id%TYPE;
  v_message                    VARCHAR2(240);
  v_minority_group_lookup_code xx_ap_suppliers_stg.attribute7%TYPE;
  v_num_1099                   xx_ap_suppliers_stg.num_1099%TYPE;
  v_org_id                     xx_ap_supplier_sites_stg.org_id%TYPE;
  v_org_type_lookup_code       xx_ap_suppliers_stg.organization_type_lookup_code%TYPE;
  v_pay_group_lookup_code      xx_ap_supplier_sites_stg.pay_group_lookup_code%TYPE;
  v_pay_site_flag              xx_ap_supplier_sites_stg.pay_site_flag%TYPE;
  v_payment_currency_code      xx_ap_supplier_sites_stg.payment_currency_code%TYPE;
  v_payment_method_lookup_code xx_ap_suppliers_stg.payment_method_lookup_code%TYPE;
  v_phase                      VARCHAR2(80);
  v_phone                      xx_ap_sup_site_contact_stg.phone%TYPE;
  v_province                   xx_ap_supplier_sites_stg.province%TYPE;
  v_purchasing_site_flag       xx_ap_supplier_sites_stg.purchasing_site_flag%TYPE;
  v_request_id                 fnd_concurrent_requests.request_id%TYPE;
  v_secondary_vendor_site_code xx_ap_supplier_sites_stg.vendor_site_code%TYPE;
  v_segment1                   xx_po_vendor_sites_kff_stg.segment1%TYPE;
  v_segment2                   xx_po_vendor_sites_kff_stg.segment2%TYPE;
  v_segment3                   xx_po_vendor_sites_kff_stg.segment3%TYPE;
  v_segment4                   xx_po_vendor_sites_kff_stg.segment4%TYPE;
  v_segment5                   xx_po_vendor_sites_kff_stg.segment5%TYPE;
  v_segment6                   xx_po_vendor_sites_kff_stg.segment6%TYPE;
  v_segment7                   xx_po_vendor_sites_kff_stg.segment7%TYPE;
  v_segment8                   xx_po_vendor_sites_kff_stg.segment8%TYPE;
  v_segment9                   xx_po_vendor_sites_kff_stg.segment9%TYPE;
  v_segment10                  xx_po_vendor_sites_kff_stg.segment10%TYPE;
  v_segment11                  xx_po_vendor_sites_kff_stg.segment11%TYPE;
  v_segment12                  xx_po_vendor_sites_kff_stg.segment12%TYPE;
  v_segment13                  xx_po_vendor_sites_kff_stg.segment13%TYPE;
  v_segment14                  xx_po_vendor_sites_kff_stg.segment14%TYPE;
  v_segment15                  xx_po_vendor_sites_kff_stg.segment15%TYPE;
  v_segment16                  xx_po_vendor_sites_kff_stg.segment16%TYPE;
  v_segment17                  xx_po_vendor_sites_kff_stg.segment17%TYPE;
  v_segment18                  xx_po_vendor_sites_kff_stg.segment18%TYPE;
  v_segment19                  xx_po_vendor_sites_kff_stg.segment19%TYPE;
  v_segment20                  xx_po_vendor_sites_kff_stg.segment20%TYPE;
  v_segment21                  xx_po_vendor_sites_kff_stg.segment21%TYPE;
  v_segment22                  xx_po_vendor_sites_kff_stg.segment22%TYPE;
  v_segment23                  xx_po_vendor_sites_kff_stg.segment23%TYPE;
  v_segment24                  xx_po_vendor_sites_kff_stg.segment24%TYPE;
  v_segment25                  xx_po_vendor_sites_kff_stg.segment25%TYPE;
  v_segment26                  xx_po_vendor_sites_kff_stg.segment26%TYPE;
  v_segment27                  xx_po_vendor_sites_kff_stg.segment27%TYPE;
  v_segment28                  xx_po_vendor_sites_kff_stg.segment28%TYPE;
  v_segment29                  xx_po_vendor_sites_kff_stg.segment29%TYPE;
  v_segment30                  xx_po_vendor_sites_kff_stg.segment30%TYPE;
  v_segment31                  xx_po_vendor_sites_kff_stg.segment31%TYPE;
  v_segment32                  xx_po_vendor_sites_kff_stg.segment32%TYPE;
  v_segment33                  xx_po_vendor_sites_kff_stg.segment33%TYPE;
  v_segment34                  xx_po_vendor_sites_kff_stg.segment34%TYPE;
  v_segment35                  xx_po_vendor_sites_kff_stg.segment35%TYPE;
  v_segment36                  xx_po_vendor_sites_kff_stg.segment36%TYPE;
  v_segment37                  xx_po_vendor_sites_kff_stg.segment37%TYPE;
  v_segment38                  xx_po_vendor_sites_kff_stg.segment38%TYPE;
  v_segment39                  xx_po_vendor_sites_kff_stg.segment39%TYPE;
  v_segment40                  xx_po_vendor_sites_kff_stg.segment40%TYPE;
  v_segment41                  xx_po_vendor_sites_kff_stg.segment41%TYPE;
  v_segment42                  xx_po_vendor_sites_kff_stg.segment42%TYPE;
  v_segment43                  xx_po_vendor_sites_kff_stg.segment43%TYPE;
  v_segment44                  xx_po_vendor_sites_kff_stg.segment44%TYPE;
  v_segment45                  xx_po_vendor_sites_kff_stg.segment45%TYPE;
  v_segment46                  xx_po_vendor_sites_kff_stg.segment46%TYPE;
  v_segment47                  xx_po_vendor_sites_kff_stg.segment47%TYPE;
  v_segment48                  xx_po_vendor_sites_kff_stg.segment48%TYPE;
  v_segment49                  xx_po_vendor_sites_kff_stg.segment49%TYPE;
  v_segment50                  xx_po_vendor_sites_kff_stg.segment50%TYPE;
  v_segment51                  xx_po_vendor_sites_kff_stg.segment51%TYPE;
  v_segment52                  xx_po_vendor_sites_kff_stg.segment52%TYPE;
  v_segment53                  xx_po_vendor_sites_kff_stg.segment53%TYPE;
  v_segment54                  xx_po_vendor_sites_kff_stg.segment54%TYPE;
  v_segment55                  xx_po_vendor_sites_kff_stg.segment55%TYPE;
  v_segment56                  xx_po_vendor_sites_kff_stg.segment56%TYPE;
  v_segment57                  xx_po_vendor_sites_kff_stg.segment57%TYPE;
  v_segment58                  xx_po_vendor_sites_kff_stg.segment58%TYPE;
  v_segment59                  xx_po_vendor_sites_kff_stg.segment59%TYPE;
  v_segment60                  xx_po_vendor_sites_kff_stg.segment60%TYPE;
  v_seq_site                   NUMBER;
  v_set_completion_status_flag VARCHAR2(10) := 'S';
  v_set_completion_status_text VARCHAR2(240);
  v_settle_days                xx_ap_supplier_sites_stg.attribute10%TYPE;
  v_site_category              xx_ap_supplier_sites_stg.attribute8%TYPE;
  v_small_business_flag        xx_ap_suppliers_stg.small_business_flag%TYPE;
  v_state                      xx_ap_supplier_sites_stg.state%TYPE;
  v_state_reportable_flag      xx_ap_suppliers_stg.state_reportable_flag%TYPE;
  v_status                     VARCHAR2(80);
  v_tax_reporting_site_flag    xx_ap_supplier_sites_stg.tax_reporting_site_flag%TYPE;
  v_tax_verification_date      xx_ap_suppliers_stg.tax_verification_date%TYPE;
  v_terms_name                 xx_ap_supplier_sites_stg.terms_name%TYPE;
  v_translated_pay_group       xx_ap_supplier_sites_stg.pay_group_lookup_code%TYPE;
  v_translated_payment_method  xx_ap_suppliers_stg.payment_method_lookup_code%TYPE;
  v_translated_segment11       xx_po_vendor_sites_kff_stg.segment11%TYPE;
  v_translated_segment21       xx_po_vendor_sites_kff_stg.segment21%TYPE;
  v_translated_segment25       xx_po_vendor_sites_kff_stg.segment25%TYPE;
  v_translated_segment3        xx_po_vendor_sites_kff_stg.segment3%TYPE;
  v_translated_segment36       xx_po_vendor_sites_kff_stg.segment36%TYPE;
  v_translated_segment41       xx_po_vendor_sites_kff_stg.segment41%TYPE;
  v_translated_segment44       xx_po_vendor_sites_kff_stg.segment44%TYPE;
  v_translated_terms_name      xx_ap_supplier_sites_stg.terms_name%TYPE;
  v_type_1099                  xx_ap_suppliers_stg.type_1099%TYPE;
  v_us_cons_ccid               xx_ap_supplier_sites_stg.accts_pay_code_combination_id%TYPE;
  v_us_trade_ccid              xx_ap_supplier_sites_stg.accts_pay_code_combination_id%TYPE;
  v_vendor_count               NUMBER := 0;
  v_vendor_interface_id        xx_ap_suppliers_stg.vendor_interface_id%TYPE;
  v_vendor_name                xx_ps_vendor_merge.global_supplier_name%TYPE;
  v_vendor_rowid               ROWID;
  v_vendor_site_code           xx_ap_supplier_sites_stg.vendor_site_code%TYPE;
  v_vendor_site_code_prefix    xx_ap_supplier_sites_stg.vendor_site_code%TYPE;
  v_vendor_site_contact_count  NUMBER := 0;
  v_vendor_site_count          NUMBER := 0;
  v_vendor_type_lookup_code    xx_ap_suppliers_stg.vendor_type_lookup_code%TYPE;
  v_vs_kff_id                  xx_po_vendor_sites_kff.vs_kff_id%TYPE;
  v_women_owned_flag           xx_ap_suppliers_stg.women_owned_flag%TYPE;
  v_zip                        xx_ap_supplier_sites_stg.zip%TYPE;

/* Define procedure to lookup the exception GL accounts */
PROCEDURE p_get_gl_accounts IS
BEGIN
  --US Trade - 1001.00000.20101000.000000.0000.00.000000
  SELECT code_combination_id
  INTO v_us_trade_ccid
  FROM gl_code_combinations
  WHERE segment1 = '1001'
  AND   segment2 = '00000'
  AND   segment3 = '20101000'
  AND   segment4 = '000000'
  AND   segment5 = '0000'
  AND   segment6 = '00'
  AND   segment7 = '000000'
  AND   account_type = 'L'
  AND   enabled_flag = 'Y';

  --US Consignment - 1001.00000.12202000.000000.0000.00.000000
  BEGIN
    SELECT code_combination_id
    INTO v_us_cons_ccid
    FROM gl_code_combinations
    WHERE segment1 = '1001'
    AND   segment2 = '00000'
    AND   segment3 = '12202000'
    AND   segment4 = '000000'
    AND   segment5 = '0000'
    AND   segment6 = '00'
    AND   segment7 = '000000'
    AND   account_type = 'L'
    AND   enabled_flag = 'Y';

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_us_cons_ccid := v_us_trade_ccid;
  END;

  --CA Trade 1003.00000.20101000.000000.0000.00.000000
  SELECT code_combination_id
  INTO v_ca_trade_ccid
  FROM gl_code_combinations
  WHERE segment1 = '1003'
  AND   segment2 = '00000'
  AND   segment3 = '20101000'
  AND   segment4 = '000000'
  AND   segment5 = '0000'
  AND   segment6 = '00'
  AND   segment7 = '000000'
  AND   account_type = 'L'
  AND   enabled_flag = 'Y';

  --CA Consignment - 1003.00000.12202000.000000.0000.00.000000
  BEGIN
    SELECT code_combination_id
    INTO v_ca_cons_ccid
    FROM gl_code_combinations
    WHERE segment1 = '1003'
    AND   segment2 = '00000'
    AND   segment3 = '12202000'
    AND   segment4 = '000000'
    AND   segment5 = '0000'
    AND   segment6 = '00'
    AND   segment7 = '000000'
    AND   account_type = 'L'
    AND   enabled_flag = 'Y';

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_ca_cons_ccid := v_ca_trade_ccid;
  END;

EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in p_get_gl_accounts '||SQLERRM);
    v_set_completion_status_flag := 'ERROR';
    v_set_completion_status_text := 'Error in p_get_gl_accounts '||SQLERRM;
END p_get_gl_accounts;

/* Define procedure to insert the vendors into the API tables */
PROCEDURE p_insert_vendors IS

  /* Define vendor cursor */
  CURSOR vend_cur IS
    SELECT xass.ROWID,
           xass.legacy_vendor_id,
           xapvm.global_supplier_name||'-'||TO_CHAR(c_when,'YYMMDDHH24MISS'),
           xass.vendor_type_lookup_code,
           xass.num_1099,
           xass.type_1099,
           xass.organization_type_lookup_code,
           NVL(xass.payment_method_lookup_code,'CHK'),
           xass.women_owned_flag,
           xass.small_business_flag,
           xass.tax_verification_date,
           xass.attribute7,
           xass.attribute8,
           xass.attribute9,
           xass.attribute10
    FROM xx_ap_suppliers_stg xass,
         xx_ps_vendor_merge xapvm
    WHERE xass.legacy_vendor_id = xapvm.legacy_vendor_id
    AND   xapvm.global = 'Global'
    AND   xass.process_flag != 7;

  /* Define vendor minority code cursor */
  CURSOR vmin_cur IS
    SELECT vendor_site_code
    FROM xx_ap_supplier_sites_stg
    WHERE legacy_vendor_id = v_legacy_vendor_id
    AND   vendor_site_code IN ('AIF','AIM','APF','APM','BBF','BBM','CAF','CAM','HIF','HIM','NAF','NAM')
    AND   ROWNUM = 1;  --There is meant to be only one minority code per vendor but it's not always the case

  /* Define vendor address cursor */
  CURSOR vadd_cur IS
    SELECT xasss.rowid,
           xapvm2.legacy_vendor_id,
           xasss.vendor_site_code,
           xasss.purchasing_site_flag,
           xasss.pay_site_flag,
           xasss.address_line1,
           xasss.address_line2,
           xasss.address_line3,
           xasss.address_line4,
           xasss.city,
           xasss.state,
           xasss.zip,
           xasss.province,
           DECODE(xasss.country,'USA','US','CAN','CA',xasss.country),
           NVL(xasss.payment_method_lookup_code,'CHK'),
           xasss.pay_group_lookup_code,
           xasss.terms_name,
           xasss.payment_currency_code,
           xasss.hold_all_payments_flag,
           xasss.hold_reason,
           xasss.exclusive_payment_flag,
           xasss.tax_reporting_site_flag,
           xasss.attribute10,
           xasss.org_id,
           xasss.email_address,
           xasss.duns_number
    FROM xx_ps_vendor_merge xapvm,
         xx_ps_vendor_merge xapvm2,
         xx_ap_supplier_sites_stg xasss
    WHERE xapvm.legacy_vendor_id = v_legacy_vendor_id
    AND   xapvm.global_supplier_name = xapvm2.global_supplier_name
    AND   xasss.legacy_vendor_id = xapvm2.legacy_vendor_id
    AND   xasss.process_flag != 7
    AND   (xasss.vendor_site_code IN ('EXP','TRA')
       OR (xasss.vendor_site_code = 'ARC' AND xapvm.legacy_vendor_id LIKE 'A%'));

  /* Define secondary vendor site code cursor */
  CURSOR vsec_cur IS
    select vendor_site_code
    FROM xx_ap_supplier_sites_stg
    WHERE legacy_vendor_id = v_child_legacy_vendor_id
    AND   purchasing_site_flag = v_purchasing_site_flag
    AND   pay_site_flag = v_pay_site_flag
    AND   ((v_vendor_site_code = 'EXP' AND vendor_site_code IN ('IMP','RNT','STX','UTI'))
        OR (v_vendor_site_code = 'TRA' AND vendor_site_code IN ('CON','IMP')))
    AND   (address_line1 = v_address1 OR (address_line1 is null and v_address1 IS NULL))
    AND   (address_line2 = v_address2 OR (address_line2 is null and v_address2 IS NULL))
    AND   (address_line3 = v_address3 OR (address_line3 is null and v_address3 IS NULL))
    AND   (address_line4 = v_address4 OR (address_line4 is null and v_address4 IS NULL))
    AND   (city = v_city OR (city IS NULL AND v_city IS NULL))
    AND   (state = v_state OR (state IS NULL AND v_state IS NULL))
    AND   (zip = v_zip OR (zip IS NULL AND v_zip IS NULL))
    AND   (province = v_province OR (province IS NULL AND v_province IS NULL))
    AND   DECODE(country,'USA','US','CAN','CA',country) = v_country;

  /* Define vendor contact cursor */
  CURSOR vcon_cur IS
    SELECT ROWID,
           org_id,
           NVL(first_name,'first name'),
           NVL(last_name,'last name'),
           SUBSTR(phone,1,3),
           SUBSTR(REPLACE(phone,'/',NULL),4),
           department,
           email_address,
           SUBSTR(fax,1,3),
           SUBSTR(REPLACE(fax,'/',NULL),4)
    FROM xx_ap_sup_site_contact_stg
    WHERE legacy_vendor_id = v_child_legacy_vendor_id
    AND   process_flag != 7;

BEGIN

  begin
  	  	DBMS_STATS.GATHER_TABLE_STATS (
  	  	  ownname => 'XXCNV',
          tabname => 'XX_AP_SUPPLIERS_STG',
          estimate_percent => 100
          );
          end;
  begin
  	  	DBMS_STATS.GATHER_TABLE_STATS (
  	  	  ownname => 'XXCNV',
          tabname => 'XX_AP_SUPPLIER_SITES_STG',
          estimate_percent => 100
          );
          end;
  begin
  	  	DBMS_STATS.GATHER_TABLE_STATS (
  	  	  ownname => 'XXCNV',
          tabname => 'XX_AP_SUP_SITE_CONTACT_STG',
          estimate_percent => 100
          );
          end;

  /* Only open the vendor cursor if it is not already open */
  IF NOT vend_cur%ISOPEN THEN
    OPEN vend_cur;
  END IF;

  LOOP
    /* Reset the variables */
    v_error_message_vend := NULL;
    v_translated_payment_method := NULL;
    v_minority_group_lookup_code := NULL;

    /* Populate variables using cursor fetch */
    FETCH vend_cur INTO v_vendor_rowid,
                        v_legacy_vendor_id,
                        v_vendor_name,
                        v_vendor_type_lookup_code,
                        v_num_1099,
                        v_type_1099,
                        v_org_type_lookup_code,
                        v_payment_method_lookup_code,
                        v_women_owned_flag,
                        v_small_business_flag,
                        v_tax_verification_date,
                        v_attribute7,
                        v_attribute8,
                        v_attribute9,
                        v_attribute10;

    /* Keep fetching until no more records are found */
    EXIT WHEN NOT vend_cur%FOUND;

    /* Only open the vendor minority code cursor if it is not already open */
    IF NOT vmin_cur%ISOPEN THEN
      OPEN vmin_cur;
    END IF;

    /* Populate variables using cursor fetch */
    FETCH vmin_cur INTO v_minority_group_lookup_code;

    CLOSE vmin_cur;

    /* Translate the attributes */
    IF v_attribute7 = 'MBE' THEN
      v_attribute7 := 'Y';
    ELSE
      v_attribute7 := 'N';
    END IF;

    IF v_attribute8 = 'WBE' THEN
      v_attribute8 := 'Y';
    ELSE
      v_attribute8 := 'N';
    END IF;

    IF v_attribute9 = 'DVB' THEN
      v_attribute9 := 'Y';
    ELSE
      v_attribute9 := 'N';
    END IF;

    IF v_attribute10 = 'SBC' THEN
      v_attribute10 := 'Y';
    ELSE
      v_attribute10 := 'N';
    END IF;

    /* Translate the payment method */
    xx_fin_translate_pkg.xx_fin_translatevalue_proc (p_translation_name => 'AP_PAYMENT_METHOD',
                                                     p_source_value1 => v_payment_method_lookup_code,
                                                     x_target_value1 => v_translated_payment_method,
                                                     x_target_value2 => v_dummy,
                                                     x_target_value3 => v_dummy,
                                                     x_target_value4 => v_dummy,
                                                     x_target_value5 => v_dummy,
                                                     x_target_value6 => v_dummy,
                                                     x_target_value7 => v_dummy,
                                                     x_target_value8 => v_dummy,
                                                     x_target_value9 => v_dummy,
                                                     x_target_value10 => v_dummy,
                                                     x_target_value11 => v_dummy,
                                                     x_target_value12 => v_dummy,
                                                     x_target_value13 => v_dummy,
                                                     x_target_value14 => v_dummy,
                                                     x_target_value15 => v_dummy,
                                                     x_target_value16 => v_dummy,
                                                     x_target_value17 => v_dummy,
                                                     x_target_value18 => v_dummy,
                                                     x_target_value19 => v_dummy,
                                                     x_target_value20 => v_dummy,
                                                     x_error_message => v_error_message_vend);

    /* Only continue processing vendors without errors */
    IF v_error_message_vend IS NULL THEN
      /* Set the tax details */
      IF v_type_1099 IS NULL THEN
        v_state_reportable_flag := NULL;
        v_federal_reportable_flag := NULL;
      ELSE
        v_type_1099 := 'MISC'||to_number(v_type_1099);
        v_state_reportable_flag := 'Y';
        v_federal_reportable_flag := 'Y';
      END IF;

      /* Get the vendor_interface_id */
      SELECT ap_suppliers_int_s.NEXTVAL
      INTO v_vendor_interface_id
      FROM dual;

      /* Insert the vendor into ap_suppliers_int */
      INSERT INTO ap_suppliers_int (vendor_interface_id,
                                    last_update_date,
                                    last_updated_by,
                                    vendor_name,
                                    vendor_name_alt,
                                    segment1,
                                    summary_flag,
                                    enabled_flag,
                                    last_update_login,
                                    creation_date,
                                    created_by,
                                    employee_id,
                                    vendor_type_lookup_code,
                                    customer_num,
                                    one_time_flag,
                                    min_order_amount,
                                    ship_to_location_id,
                                    ship_to_location_code,
                                    bill_to_location_id,
                                    bill_to_location_code,
                                    ship_via_lookup_code,
                                    freight_terms_lookup_code,
                                    fob_lookup_code,
                                    terms_id,
                                    terms_name,
                                    set_of_books_id,
                                    always_take_disc_flag,
                                    pay_date_basis_lookup_code,
                                    pay_group_lookup_code,
                                    payment_priority,
                                    invoice_currency_code,
                                    payment_currency_code,
                                    invoice_amount_limit,
                                    hold_all_payments_flag,
                                    hold_future_payments_flag,
                                    hold_reason,
                                    distribution_set_id,
                                    distribution_set_name,
                                    accts_pay_code_combination_id,
                                    prepay_code_combination_id,
                                    num_1099,
                                    type_1099,
                                    organization_type_lookup_code,
                                    vat_code,
                                    start_date_active,
                                    end_date_active,
                                    minority_group_lookup_code,
                                    payment_method_lookup_code,
                                    women_owned_flag,
                                    small_business_flag,
                                    standard_industry_class,
                                    hold_flag,
                                    purchasing_hold_reason,
                                    hold_by,
                                    hold_date,
                                    terms_date_basis,
                                    inspection_required_flag,
                                    receipt_required_flag,
                                    qty_rcv_tolerance,
                                    qty_rcv_exception_code,
                                    enforce_ship_to_location_code,
                                    days_early_receipt_allowed,
                                    days_late_receipt_allowed,
                                    receipt_days_exception_code,
                                    receiving_routing_id,
                                    allow_substitute_receipts_flag,
                                    allow_unordered_receipts_flag,
                                    hold_unmatched_invoices_flag,
                                    exclusive_payment_flag,
                                    ap_tax_rounding_rule,
                                    auto_tax_calc_flag,
                                    auto_tax_calc_override,
                                    amount_includes_tax_flag,
                                    tax_verification_date,
                                    name_control,
                                    state_reportable_flag,
                                    federal_reportable_flag,
                                    attribute_category,
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
                                    request_id,
                                    program_application_id,
                                    program_id,
                                    program_update_date,
                                    vat_registration_num,
                                    auto_calculate_interest_flag,
                                    exclude_freight_from_discount,
                                    tax_reporting_name,
                                    allow_awt_flag,
                                    awt_group_id,
                                    awt_group_name,
                                    global_attribute1,
                                    global_attribute2,
                                    global_attribute3,
                                    global_attribute4,
                                    global_attribute5,
                                    global_attribute6,
                                    global_attribute7,
                                    global_attribute8,
                                    global_attribute9,
                                    global_attribute10,
                                    global_attribute11,
                                    global_attribute12,
                                    global_attribute13,
                                    global_attribute14,
                                    global_attribute15,
                                    global_attribute16,
                                    global_attribute17,
                                    global_attribute18,
                                    global_attribute19,
                                    global_attribute20,
                                    global_attribute_category,
                                    edi_transaction_handling,
                                    edi_payment_method,
                                    edi_payment_format,
                                    edi_remittance_method,
                                    edi_remittance_instruction,
                                    bank_charge_bearer,
                                    match_option,
                                    future_dated_payment_ccid,
                                    create_debit_memo_flag,
                                    offset_tax_flag,
                                    import_request_id,
                                    status,
                                    reject_code)
      VALUES (v_vendor_interface_id,        --vendor_interface_id
              c_when,                       --last_update_date
              c_who,                        --last_updated_by
              v_vendor_name,                --vendor_name
              NULL,                         --vendor_name_alt
              v_legacy_vendor_id,           --segment1
              NULL,                         --summary_flag
              NULL,                         --enabled_flag
              NULL,                         --last_update_login
              c_when,                       --creation_date
              c_who,                        --created_by
              NULL,                         --employee_id
              v_vendor_type_lookup_code,    --vendor_type_lookup_code
              NULL,                         --customer_num
              NULL,                         --one_time_flag
              NULL,                         --min_order_amount
              NULL,                         --ship_to_location_id
              NULL,                         --ship_to_location_code
              NULL,                         --bill_to_location_id
              NULL,                         --bill_to_location_code
              NULL,                         --ship_via_lookup_code
              NULL,                         --freight_terms_lookup_code
              NULL,                         --fob_lookup_code
              NULL,                         --terms_id
              NULL,                         --terms_name
              NULL,                         --set_of_books_id
              NULL,                         --always_take_disc_flag
              NULL,                         --pay_date_basis_lookup_code
              NULL,                         --pay_group_lookup_code
              NULL,                         --payment_priority
              NULL,                         --invoice_currency_code
              NULL,                         --payment_currency_code
              NULL,                         --invoice_amount_limit
              NULL,                         --hold_all_payments_flag
              NULL,                         --hold_future_payments_flag
              NULL,                         --hold_reason
              NULL,                         --distribution_set_id
              NULL,                         --distribution_set_name
              NULL,                         --accts_pay_code_combination_id
              NULL,                         --prepay_code_combination_id
              v_num_1099,                   --num_1099
              v_type_1099,                  --type_1099
              v_org_type_lookup_code,       --organization_type_lookup_code
              NULL,                         --vat_code
              '01-JAN-1950',                --start_date_active
              NULL,                         --end_date_active
              v_minority_group_lookup_code, --minority_group_lookup_code
              v_translated_payment_method,  --payment_method_lookup_code
              v_women_owned_flag,           --women_owned_flag
              v_small_business_flag,        --small_business_flag
              NULL,                         --standard_industry_class
              NULL,                         --hold_flag
              NULL,                         --purchasing_hold_reason
              NULL,                         --hold_by
              NULL,                         --hold_date
              NULL,                         --terms_date_basis
              NULL,                         --inspection_required_flag
              NULL,                         --receipt_required_flag
              NULL,                         --qty_rcv_tolerance
              NULL,                         --qty_rcv_exception_code
              NULL,                         --enforce_ship_to_location_code
              NULL,                         --days_early_receipt_allowed
              NULL,                         --days_late_receipt_allowed
              NULL,                         --receipt_days_exception_code
              NULL,                         --receiving_routing_id
              NULL,                         --allow_substitute_receipts_flag
              NULL,                         --allow_unordered_receipts_flag
              NULL,                         --hold_unmatched_invoices_flag
              NULL,                         --exclusive_payment_flag
              NULL,                         --ap_tax_rounding_rule
              NULL,                         --auto_tax_calc_flag
              NULL,                         --auto_tax_calc_override
              NULL,                         --amount_includes_tax_flag
              v_tax_verification_date,      --tax_verification_date
              NULL,                         --name_control
              v_state_reportable_flag,      --state_reportable_flag
              v_federal_reportable_flag,    --federal_reportable_flag
              NULL,                         --attribute_category
              NULL,                         --attribute1
              NULL,                         --attribute2
              NULL,                         --attribute3
              NULL,                         --attribute4
              NULL,                         --attribute5
              NULL,                         --attribute6
              v_attribute7,                 --attribute7
              v_attribute8,                 --attribute8
              v_attribute9,                 --attribute9
              v_attribute10,                --attribute10
              NULL,                         --attribute11
              NULL,                         --attribute12
              NULL,                         --attribute13
              NULL,                         --attribute14
              NULL,                         --attribute15
              NULL,                         --request_id
              NULL,                         --program_application_id
              NULL,                         --program_id
              NULL,                         --program_update_date
              NULL,                         --vat_registration_num
              NULL,                         --auto_calculate_interest_flag
              NULL,                         --exclude_freight_from_discount
              NULL,                         --tax_reporting_name
              NULL,                         --allow_awt_flag
              NULL,                         --awt_group_id
              NULL,                         --awt_group_name
              NULL,                         --global_attribute1
              NULL,                         --global_attribute2
              NULL,                         --global_attribute3
              NULL,                         --global_attribute4
              NULL,                         --global_attribute5
              NULL,                         --global_attribute6
              NULL,                         --global_attribute7
              NULL,                         --global_attribute8
              NULL,                         --global_attribute9
              NULL,                         --global_attribute10
              NULL,                         --global_attribute11
              NULL,                         --global_attribute12
              NULL,                         --global_attribute13
              NULL,                         --global_attribute14
              NULL,                         --global_attribute15
              NULL,                         --global_attribute16
              NULL,                         --global_attribute17
              NULL,                         --global_attribute18
              NULL,                         --global_attribute19
              NULL,                         --global_attribute20
              NULL,                         --global_attribute_category
              NULL,                         --edi_transaction_handling
              NULL,                         --edi_payment_method
              NULL,                         --edi_payment_format
              NULL,                         --edi_remittance_method
              NULL,                         --edi_remittance_instruction
              NULL,                         --bank_charge_bearer
              NULL,                         --match_option
              NULL,                         --future_dated_payment_ccid
              NULL,                         --create_debit_memo_flag
              NULL,                         --offset_tax_flag
              NULL,                         --import_request_id
              'NEW',                        --status
              NULL);                        --reject_code

      /* Increment the vendor count */
      v_vendor_count := v_vendor_count + 1;

      /* Set the site sequence */
      v_seq_site := 1;

--fnd_file.put_line(fnd_file.log,'Debug0: '||v_legacy_vendor_id);
      /* Only open the vendor address cursor if it is not already open */
      IF NOT vadd_cur%ISOPEN THEN
        OPEN vadd_cur;
      END IF;

      LOOP
        /* Reset the variables */
        v_error_message_site := NULL;
        v_translated_payment_method := NULL;
        v_translated_pay_group := NULL;
        v_translated_terms_name := NULL;
        v_site_category := NULL;

        /* Populate variables using cursor fetch */
        FETCH vadd_cur INTO v_address_rowid,
                            v_child_legacy_vendor_id,
                            v_vendor_site_code,
                            v_purchasing_site_flag,
                            v_pay_site_flag,
                            v_address1,
                            v_address2,
                            v_address3,
                            v_address4,
                            v_city,
                            v_state,
                            v_zip,
                            v_province,
                            v_country,
                            v_payment_method_lookup_code,
                            v_pay_group_lookup_code,
                            v_terms_name,
                            v_payment_currency_code,
                            v_hold_all_payments_flag,
                            v_hold_reason,
                            v_exclusive_payment_flag,
                            v_tax_reporting_site_flag,
                            v_settle_days,
                            v_org_id,
                            v_email_address,
                            v_duns_number;

        /* Keep fetching until no more records are found */
        EXIT WHEN NOT vadd_cur%FOUND OR v_error_message_vend IS NOT NULL;

        /* A supplier can have only one tax reporting site */
        IF v_tax_reporting_site_flag = 'Y' and v_seq_site > 1 THEN
          v_tax_reporting_site_flag := 'N';
        END IF;

        /* Translate the payment method */
        xx_fin_translate_pkg.xx_fin_translatevalue_proc (p_translation_name => 'AP_PAYMENT_METHOD',
                                                         p_source_value1 => v_payment_method_lookup_code,
                                                         x_target_value1 => v_translated_payment_method,
                                                         x_target_value2 => v_dummy,
                                                         x_target_value3 => v_dummy,
                                                         x_target_value4 => v_dummy,
                                                         x_target_value5 => v_dummy,
                                                         x_target_value6 => v_dummy,
                                                         x_target_value7 => v_dummy,
                                                         x_target_value8 => v_dummy,
                                                         x_target_value9 => v_dummy,
                                                         x_target_value10 => v_dummy,
                                                         x_target_value11 => v_dummy,
                                                         x_target_value12 => v_dummy,
                                                         x_target_value13 => v_dummy,
                                                         x_target_value14 => v_dummy,
                                                         x_target_value15 => v_dummy,
                                                         x_target_value16 => v_dummy,
                                                         x_target_value17 => v_dummy,
                                                         x_target_value18 => v_dummy,
                                                         x_target_value19 => v_dummy,
                                                         x_target_value20 => v_dummy,
                                                         x_error_message => v_error_message_site);

        /* Translate the payment group */
        IF v_error_message_site IS NULL THEN
          IF v_pay_group_lookup_code = 'EX' AND v_vendor_site_code = 'RNT' THEN
            v_translated_pay_group := 'US_OD_RENT';
          ELSE
            xx_fin_translate_pkg.xx_fin_translatevalue_proc (p_translation_name => 'AP_PAYMENT_GROUP_CODE',
                                                             p_source_value1 => v_pay_group_lookup_code,
                                                             p_source_value2 => v_payment_method_lookup_code,
                                                             x_target_value1 => v_translated_pay_group,
                                                             x_target_value2 => v_dummy,
                                                             x_target_value3 => v_dummy,
                                                             x_target_value4 => v_dummy,
                                                             x_target_value5 => v_dummy,
                                                             x_target_value6 => v_dummy,
                                                             x_target_value7 => v_dummy,
                                                             x_target_value8 => v_dummy,
                                                             x_target_value9 => v_dummy,
                                                             x_target_value10 => v_dummy,
                                                             x_target_value11 => v_dummy,
                                                             x_target_value12 => v_dummy,
                                                             x_target_value13 => v_dummy,
                                                             x_target_value14 => v_dummy,
                                                             x_target_value15 => v_dummy,
                                                             x_target_value16 => v_dummy,
                                                             x_target_value17 => v_dummy,
                                                             x_target_value18 => v_dummy,
                                                             x_target_value19 => v_dummy,
                                                             x_target_value20 => v_dummy,
                                                             x_error_message => v_error_message);

            /* Add this error message to the site error message */
            IF v_error_message_site IS NULL THEN
              v_error_message_site := v_error_message;
            ELSE
              v_error_message_site := SUBSTR(v_error_message_site||' '||v_error_message,1,2000);
            END IF;
          END IF;

          /* Translate the terms name */
          IF v_error_message_site IS NULL THEN
            xx_fin_translate_pkg.xx_fin_translatevalue_proc (p_translation_name => 'AP_PAYMENT_TERMS',
                                                             p_source_value1 => v_terms_name,
                                                             x_target_value1 => v_dummy,
                                                             x_target_value2 => v_translated_terms_name,
                                                             x_target_value3 => v_dummy,
                                                             x_target_value4 => v_dummy,
                                                             x_target_value5 => v_dummy,
                                                             x_target_value6 => v_dummy,
                                                             x_target_value7 => v_dummy,
                                                             x_target_value8 => v_dummy,
                                                             x_target_value9 => v_dummy,
                                                             x_target_value10 => v_dummy,
                                                             x_target_value11 => v_dummy,
                                                             x_target_value12 => v_dummy,
                                                             x_target_value13 => v_dummy,
                                                             x_target_value14 => v_dummy,
                                                             x_target_value15 => v_dummy,
                                                             x_target_value16 => v_dummy,
                                                             x_target_value17 => v_dummy,
                                                             x_target_value18 => v_dummy,
                                                             x_target_value19 => v_dummy,
                                                             x_target_value20 => v_dummy,
                                                             x_error_message => v_error_message);

            /* Add this error message to the site error message */
            IF v_error_message_site IS NULL THEN
              v_error_message_site := v_error_message;
            ELSE
              v_error_message_site := SUBSTR(v_error_message_site||' '||v_error_message,1,2000);
            END IF;

            /* Only open the secondary vendor site code cursor if it is not already open */
            IF NOT vsec_cur%ISOPEN THEN
              OPEN vsec_cur;
            END IF;

            /* Reset the variables */
            v_secondary_vendor_site_code := 'NA';

            /* Populate variables using cursor fetch */
            FETCH vsec_cur INTO v_secondary_vendor_site_code;

            CLOSE vsec_cur;

            /* Translate the terms name */
            IF v_error_message_site IS NULL THEN
--fnd_file.put_line(fnd_file.output,'v_vendor_site_code is '||v_vendor_site_code);
--fnd_file.put_line(fnd_file.output,'v_secondary_vendor_site_code is '||v_secondary_vendor_site_code);
              xx_fin_translate_pkg.xx_fin_translatevalue_proc (p_translation_name => 'AP_VENDOR_SITE_CATEGORY',
                                                               p_source_value1 => v_vendor_site_code,
                                                               p_source_value2 => v_secondary_vendor_site_code,
                                                               x_target_value1 => v_site_category,
                                                               x_target_value2 => v_vendor_site_code_prefix,
                                                               x_target_value3 => v_dummy,
                                                               x_target_value4 => v_dummy,
                                                               x_target_value5 => v_dummy,
                                                               x_target_value6 => v_dummy,
                                                               x_target_value7 => v_dummy,
                                                               x_target_value8 => v_dummy,
                                                               x_target_value9 => v_dummy,
                                                               x_target_value10 => v_dummy,
                                                               x_target_value11 => v_dummy,
                                                               x_target_value12 => v_dummy,
                                                               x_target_value13 => v_dummy,
                                                               x_target_value14 => v_dummy,
                                                               x_target_value15 => v_dummy,
                                                               x_target_value16 => v_dummy,
                                                               x_target_value17 => v_dummy,
                                                               x_target_value18 => v_dummy,
                                                               x_target_value19 => v_dummy,
                                                               x_target_value20 => v_dummy,
                                                               x_error_message => v_error_message);
--fnd_file.put_line(fnd_file.output,'v_site_category is '||v_site_category);

              /* Add this error message to the site error message */
              IF v_error_message_site IS NULL THEN
                v_error_message_site := v_error_message;
              ELSE
                v_error_message_site := SUBSTR(v_error_message_site||' '||v_error_message,1,2000);
              END IF;

            END IF;
          END IF;
        END IF;

        /* Insert the vendor address into ap_supplier_sites_int */
        IF v_error_message_site IS NULL THEN
          /* Set the override accts_pay_ccid, or NULL to use the default configuration */
          IF v_vendor_site_code = 'TRA' THEN
            IF v_country = 'US' THEN
              IF v_secondary_vendor_site_code = 'CON' THEN
                v_accts_pay_ccid := v_us_cons_ccid;
              ELSE
                v_accts_pay_ccid := v_us_trade_ccid;
              END IF;
            ELSIF v_country = 'CA' THEN
              IF v_secondary_vendor_site_code = 'CON' THEN
                v_accts_pay_ccid := v_ca_cons_ccid;
              ELSE
                v_accts_pay_ccid := v_ca_trade_ccid;
              END IF;
            ELSE
              v_accts_pay_ccid := NULL;
            END IF;
          ELSE
            v_accts_pay_ccid := NULL;
          END IF;

          /* Construct the vendor_site_category and vendor_site_code */
--          IF v_pay_site_flag = 'Y' AND v_purchasing_site_flag = 'Y' THEN
--            v_vendor_site_code := substr(v_site_category||'-PAYPUR'||v_seq_site,1,15);
--          ELSIF v_pay_site_flag = 'Y' THEN
--            v_vendor_site_code := v_site_category||'-PAY'||v_seq_site;
--          ELSIF v_purchasing_site_flag = 'Y' THEN
--            v_vendor_site_code := v_site_category||'-PUR'||v_seq_site;
--          ELSE
--            v_vendor_site_code := v_site_category||v_seq_site;
--          END IF;
          IF v_pay_site_flag = 'Y' AND v_purchasing_site_flag = 'Y' THEN
            v_vendor_site_code := v_vendor_site_code_prefix||v_child_legacy_vendor_id;
          ELSIF v_pay_site_flag = 'Y' THEN
            v_vendor_site_code := v_vendor_site_code_prefix||v_child_legacy_vendor_id||'PY';
          ELSIF v_purchasing_site_flag = 'Y' THEN
            v_vendor_site_code := v_vendor_site_code_prefix||v_child_legacy_vendor_id||'PR';
          ELSE
            v_vendor_site_code := v_vendor_site_code_prefix||v_child_legacy_vendor_id;
          END IF;

          INSERT INTO ap_supplier_sites_int (vendor_interface_id,
                                             last_update_date,
                                             last_updated_by,
                                             vendor_id,
                                             vendor_site_code,
                                             vendor_site_code_alt,
                                             last_update_login,
                                             creation_date,
                                             created_by,
                                             purchasing_site_flag,
                                             rfq_only_site_flag,
                                             pay_site_flag,
                                             attention_ar_flag,
                                             address_line1,
                                             address_lines_alt,
                                             address_line2,
                                             address_line3,
                                             city,
                                             state,
                                             zip,
                                             province,
                                             country,
                                             area_code,
                                             phone,
                                             customer_num,
                                             ship_to_location_id,
                                             ship_to_location_code,
                                             bill_to_location_id,
                                             bill_to_location_code,
                                             ship_via_lookup_code,
                                             freight_terms_lookup_code,
                                             fob_lookup_code,
                                             inactive_date,
                                             fax,
                                             fax_area_code,
                                             telex,
                                             payment_method_lookup_code,
                                             terms_date_basis,
                                             vat_code,
                                             distribution_set_id,
                                             distribution_set_name,
                                             accts_pay_code_combination_id,
                                             prepay_code_combination_id,
                                             pay_group_lookup_code,
                                             payment_priority,
                                             terms_id,
                                             terms_name,
                                             invoice_amount_limit,
                                             pay_date_basis_lookup_code,
                                             always_take_disc_flag,
                                             invoice_currency_code,
                                             payment_currency_code,
                                             hold_all_payments_flag,
                                             hold_future_payments_flag,
                                             hold_reason,
                                             hold_unmatched_invoices_flag,
                                             ap_tax_rounding_rule,
                                             auto_tax_calc_flag,
                                             auto_tax_calc_override,
                                             amount_includes_tax_flag,
                                             exclusive_payment_flag,
                                             tax_reporting_site_flag,
                                             attribute_category,
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
                                             request_id,
                                             program_application_id,
                                             program_id,
                                             program_update_date,
                                             exclude_freight_from_discount,
                                             vat_registration_num,
                                             org_id,
                                             operating_unit_name,
                                             address_line4,
                                             county,
                                             address_style,
                                             language,
                                             allow_awt_flag,
                                             awt_group_id,
                                             awt_group_name,
                                             global_attribute1,
                                             global_attribute2,
                                             global_attribute3,
                                             global_attribute4,
                                             global_attribute5,
                                             global_attribute6,
                                             global_attribute7,
                                             global_attribute8,
                                             global_attribute9,
                                             global_attribute10,
                                             global_attribute11,
                                             global_attribute12,
                                             global_attribute13,
                                             global_attribute14,
                                             global_attribute15,
                                             global_attribute16,
                                             global_attribute17,
                                             global_attribute18,
                                             global_attribute19,
                                             global_attribute20,
                                             global_attribute_category,
                                             edi_transaction_handling,
                                             edi_id_number,
                                             edi_payment_method,
                                             edi_payment_format,
                                             edi_remittance_method,
                                             bank_charge_bearer,
                                             edi_remittance_instruction,
                                             pay_on_code,
                                             default_pay_site_id,
                                             pay_on_receipt_summary_code,
                                             tp_header_id,
                                             ece_tp_location_code,
                                             pcard_site_flag,
                                             match_option,
                                             country_of_origin_code,
                                             future_dated_payment_ccid,
                                             create_debit_memo_flag,
                                             offset_tax_flag,
                                             supplier_notif_method,
                                             email_address,
                                             remittance_email,
                                             primary_pay_site_flag,
                                             import_request_id,
                                             status,
                                             reject_code,
                                             shipping_control,
                                             duns_number,
                                             tolerance_id,
                                             tolerance_name)
          VALUES (v_vendor_interface_id,       --vendor_interface_id
                  c_when,                      --last_update_date
                  c_who,                       --last_updated_by
                  NULL,                        --vendor_id
                  v_vendor_site_code,          --vendor_site_code
                  v_child_legacy_vendor_id,    --vendor_site_code_alt
                  NULL,                        --last_update_login
                  c_when,                      --creation_date
                  c_who,                       --created_by
                  v_purchasing_site_flag,      --purchasing_site_flag
                  NULL,                        --rfq_only_site_flag
                  v_pay_site_flag,             --pay_site_flag
                  NULL,                        --attention_ar_flag
                  v_address1,                  --address_line1
                  NULL,                        --address_lines_alt
                  v_address2,                  --address_line2
                  v_address3,                  --address_line3
                  v_city,                      --city
                  v_state,                     --state
                  v_zip,                       --zip
                  v_province,                  --province
                  v_country,                   --country
                  NULL,                        --area_code
                  NULL,                        --phone
                  NULL,                        --customer_num
                  NULL,                        --ship_to_location_id
                  NULL,                        --ship_to_location_code
                  NULL,                        --bill_to_location_id
                  NULL,                        --bill_to_location_code
                  NULL,                        --ship_via_lookup_code
                  NULL,                        --freight_terms_lookup_code
                  NULL,                        --fob_lookup_code
                  NULL,                        --inactive_date
                  NULL,                        --fax
                  NULL,                        --fax_area_code
                  NULL,                        --telex
                  v_translated_payment_method, --payment_method_lookup_code
                  NULL,                        --terms_date_basis
                  NULL,                        --vat_code
                  NULL,                        --distribution_set_id
                  NULL,                        --distribution_set_name
                  v_accts_pay_ccid,            --accts_pay_code_combination_id
                  NULL,                        --prepay_code_combination_id
                  v_translated_pay_group,      --pay_group_lookup_code
                  NULL,                        --payment_priority
                  NULL,                        --terms_id
                  v_translated_terms_name,     --terms_name
                  NULL,                        --invoice_amount_limit
                  NULL,                        --pay_date_basis_lookup_code
                  NULL,                        --always_take_disc_flag
                  v_payment_currency_code,     --invoice_currency_code
                  v_payment_currency_code,     --payment_currency_code
                  v_hold_all_payments_flag,    --hold_all_payments_flag
                  NULL,                        --hold_future_payments_flag
                  v_hold_reason,               --hold_reason
                  NULL,                        --hold_unmatched_invoices_flag
                  NULL,                        --ap_tax_rounding_rule
                  NULL,                        --auto_tax_calc_flag
                  NULL,                        --auto_tax_calc_override
                  NULL,                        --amount_includes_tax_flag
                  v_exclusive_payment_flag,    --exclusive_payment_flag
                  v_tax_reporting_site_flag,   --tax_reporting_site_flag
                  NULL,                        --attribute_category
                  NULL,                        --attribute1
                  NULL,                        --attribute2
                  NULL,                        --attribute3
                  NULL,                        --attribute4
                  NULL,                        --attribute5
                  NULL,                        --attribute6
                  NULL,                        --attribute7
                  v_site_category,             --attribute8
                  v_child_legacy_vendor_id,    --attribute9
                  NULL,                        --attribute10
                  NULL,                        --attribute11
                  NULL,                        --attribute12
                  NULL,                        --attribute13
                  NULL,                        --attribute14
                  NULL,                        --attribute15
                  NULL,                        --request_id
                  NULL,                        --program_application_id
                  NULL,                        --program_id
                  NULL,                        --program_update_date
                  NULL,                        --exclude_freight_from_discount
                  NULL,                        --vat_registration_num
                  v_org_id,                    --org_id
                  NULL,                        --operating_unit_name
                  v_address4,                  --address_line4
                  NULL,                        --county
                  NULL,                        --address_style
                  NULL,                        --language
                  NULL,                        --allow_awt_flag
                  NULL,                        --awt_group_id
                  NULL,                        --awt_group_name
                  NULL,                        --global_attribute1
                  NULL,                        --global_attribute2
                  NULL,                        --global_attribute3
                  NULL,                        --global_attribute4
                  NULL,                        --global_attribute5
                  NULL,                        --global_attribute6
                  NULL,                        --global_attribute7
                  NULL,                        --global_attribute8
                  NULL,                        --global_attribute9
                  NULL,                        --global_attribute10
                  NULL,                        --global_attribute11
                  NULL,                        --global_attribute12
                  NULL,                        --global_attribute13
                  NULL,                        --global_attribute14
                  NULL,                        --global_attribute15
                  NULL,                        --global_attribute16
                  NULL,                        --global_attribute17
                  NULL,                        --global_attribute18
                  NULL,                        --global_attribute19
                  NULL,                        --global_attribute20
                  NULL,                        --global_attribute_category
                  NULL,                        --edi_transaction_handling
                  NULL,                        --edi_id_number
                  NULL,                        --edi_payment_method
                  NULL,                        --edi_payment_format
                  NULL,                        --edi_remittance_method
                  NULL,                        --bank_charge_bearer
                  NULL,                        --edi_remittance_instruction
                  NULL,                        --pay_on_code
                  NULL,                        --default_pay_site_id
                  NULL,                        --pay_on_receipt_summary_code
                  NULL,                        --tp_header_id
                  NULL,                        --ece_tp_location_code
                  NULL,                        --pcard_site_flag
                  NULL,                        --match_option
                  NULL,                        --country_of_origin_code
                  NULL,                        --future_dated_payment_ccid
                  v_pay_site_flag,             --create_debit_memo_flag
                  NULL,                        --offset_tax_flag
                  NULL,                        --supplier_notif_method
                  v_email_address,             --email_address
                  NULL,                        --remittance_email
                  NULL,                        --primary_pay_site_flag
                  NULL,                        --import_request_id
                  'NEW',                       --status
                  NULL,                        --reject_code
                  NULL,                        --shipping_control
                  v_duns_number,               --duns_number
                  NULL,                        --tolerance_id
                  NULL);                       --tolerance_name

          /* Increment the vendor count and site sequence, set the contact sequence */
          v_vendor_site_count := v_vendor_site_count + 1;
          v_seq_site := v_seq_site + 1;

          /* Only open the vendor contacts cursor if it is not already open */
          IF NOT vcon_cur%ISOPEN THEN
            OPEN vcon_cur;
          END IF;

          LOOP
            /* Populate variables using cursor fetch */
            FETCH vcon_cur INTO v_contact_rowid,
                                v_org_id,
                                v_first_name,
                                v_last_name,
                                v_area_code,
                                v_phone,
                                v_department,
                                v_email_address,
                                v_fax_area_code,
                                v_fax;

            /* Keep fetching until no more records are found */
            EXIT WHEN NOT vcon_cur%FOUND;

            /* Insert the vendor address into ap_supplier_sites_int */
            INSERT INTO ap_sup_site_contact_int (last_update_date,
                                                 last_updated_by,
                                                 vendor_site_id,
                                                 vendor_site_code,
                                                 org_id,
                                                 operating_unit_name,
                                                 last_update_login,
                                                 creation_date,
                                                 created_by,
                                                 inactive_date,
                                                 first_name,
                                                 middle_name,
                                                 last_name,
                                                 prefix,
                                                 title,
                                                 mail_stop,
                                                 area_code,
                                                 phone,
                                                 program_application_id,
                                                 program_id,
                                                 program_update_date,
                                                 request_id,
                                                 contact_name_alt,
                                                 first_name_alt,
                                                 last_name_alt,
                                                 department,
                                                 import_request_id,
                                                 status,
                                                 reject_code,
                                                 email_address,
                                                 url,
                                                 alt_area_code,
                                                 alt_phone,
                                                 fax_area_code,
                                                 fax)
            VALUES (c_when,                   --last_update_date
                    c_who,                    --last_updated_by
                    NULL,                     --vendor_site_id
                    v_vendor_site_code,       --vendor_site_code
                    v_org_id,                 --org_id
                    NULL,                     --operating_unit_name
                    NULL,                     --last_update_login
                    c_when,                   --creation_date
                    c_who,                    --created_by
                    NULL,                     --inactive_date
                    v_first_name,             --first_name
                    NULL,                     --middle_name
                    v_last_name,              --last_name
                    NULL,                     --prefix
                    NULL,                     --title
                    NULL,                     --mail_stop
                    v_area_code,              --area_code
                    v_phone,                  --phone
                    NULL,                     --program_application_id
                    NULL,                     --program_id
                    NULL,                     --program_update_date
                    NULL,                     --request_id
                    v_child_legacy_vendor_id, --contact_name_alt
                    NULL,                     --first_name_alt
                    NULL,                     --last_name_alt
                    v_department,             --department
                    NULL,                     --import_request_id
                    'NEW',                    --status
                    NULL,                     --reject_code
                    v_email_address,          --email_address
                    NULL,                     --url
                    NULL,                     --alt_area_code
                    NULL,                     --alt_phone
                    v_fax_area_code,          --fax_area_code
                    v_fax);                   --fax)

            /* Increment the vendor site contact count */
            v_vendor_site_contact_count := v_vendor_site_contact_count + 1;

            /* Update the vendor address contact record to reflect that it has been processed */
            UPDATE xx_ap_sup_site_contact_stg
            SET process_flag = DECODE(NVL(v_error_message_cont,'~'),'~',7,4),
                reject_code = v_error_message_cont
            WHERE ROWID = v_contact_rowid;

      --dbms_output.put_line('vcon_cur inserted');
          END LOOP;
          CLOSE vcon_cur;

        ELSE
          /* Processing the error */
          fnd_file.put_line(fnd_file.output,'Site level translation error(s) occured: '||v_error_message_site);

          /* Set the vendor level error */
          v_error_message_vend := 'Error occured in site processing';
        END IF;

        /* Update the vendor address record to reflect that it has been processed */
        update xx_ap_supplier_sites_stg
        set process_flag = DECODE(NVL(v_error_message_site,'~'),'~',7,4),
            reject_code = v_error_message_site
        where rowid = v_address_rowid;

        /* If v_error_message_vend is not null here there was an error processing one or more lines, clean it all up */
        IF v_error_message_vend IS NOT NULL THEN
          /* Delete the contact strays */
          DELETE FROM ap_sup_site_contact_int assci
          WHERE contact_name_alt IN (SELECT assi.attribute9
                                     FROM ap_supplier_sites_int assi
                                     WHERE assi.vendor_interface_id = v_vendor_interface_id
                                     AND   assi.attribute9 = assci.contact_name_alt
                                     AND   assi.vendor_site_code = assci.vendor_site_code)
          AND   status = 'NEW'
          AND   vendor_site_id IS NULL;

          /* Decrement the vendor site contact count */
          v_vendor_site_contact_count := v_vendor_site_contact_count - SQL%ROWCOUNT;

          /* Reset the processed contacts */
          UPDATE xx_ap_sup_site_contact_stg
          SET process_flag = 1
          WHERE legacy_vendor_id = v_child_legacy_vendor_id
          AND   process_flag = 7;

          /* Delete the site strays */
          DELETE FROM ap_supplier_sites_int
          WHERE vendor_interface_id = v_vendor_interface_id;

          /* Decrement the vendor site count */
          v_vendor_site_count := v_vendor_site_count - SQL%ROWCOUNT;

          /* Reset the processed sites */
          UPDATE xx_ap_supplier_sites_stg
          SET process_flag = 1
          WHERE vendor_interface_id = v_vendor_interface_id
          AND   process_flag = 7;

          /* Delete the vendor strays */
          DELETE FROM ap_suppliers_int
          WHERE vendor_interface_id = v_vendor_interface_id;

          /* Decrement the vendor count */
          v_vendor_count := v_vendor_count - SQL%ROWCOUNT;

          /* Reset the processed sites */
          UPDATE xx_ap_supplier_sites_stg
          SET process_flag = 1
          WHERE vendor_interface_id = v_vendor_interface_id
          AND   process_flag = 7;
        END IF;

        /* Commit every 100 processed sites */
        IF MOD(v_vendor_site_count,100) = 0 THEN
          COMMIT;
        END IF;
      END LOOP;
      CLOSE vadd_cur;

    ELSE
      /* Processing the error */
      fnd_file.put_line(fnd_file.output,'Vendor level translation error(s) occured: '||v_error_message_vend);
    END IF;

    /* Update the vendor record to reflect that it has been processed successfully */
    UPDATE xx_ap_suppliers_stg
    SET process_flag = DECODE(NVL(v_error_message_vend,'~'),'~',7,4),
        reject_code = v_error_message_vend
    WHERE ROWID = v_vendor_rowid;

  END LOOP;
  CLOSE vend_cur;

  /* Commit the strays */
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in p_insert_vendors while processing '||v_legacy_vendor_id||', '||v_child_legacy_vendor_id||': '||SQLERRM);

    --Set the completion status variables
    v_set_completion_status_flag := 'ERROR';
    v_set_completion_status_text := 'Error in p_insert_vendors, see log file for details.';
END p_insert_vendors;

/* Define procedure to process the KFFs */
PROCEDURE p_process_kffs IS
  /* Define flex num cursor */
  CURSOR flex_cur IS
    SELECT fifs1.id_flex_num,
           fifs2.id_flex_num,
           fifs3.id_flex_num,
           fifs4.id_flex_num
    FROM fnd_id_flex_structures fifs4,
         fnd_id_flex_structures fifs3,
         fnd_id_flex_structures fifs2,
         fnd_id_flex_structures fifs1
    WHERE fifs1.id_flex_code = 'ODVS'
    AND   fifs1.enabled_flag = 'Y'
    AND   fifs1.id_flex_structure_code LIKE '%1'
    AND   fifs2.id_flex_code = fifs1.id_flex_code
    AND   fifs2.enabled_flag = fifs1.enabled_flag
    AND   fifs2.id_flex_structure_code LIKE '%2'
    AND   fifs3.id_flex_code = fifs2.id_flex_code
    AND   fifs3.enabled_flag = fifs2.enabled_flag
    AND   fifs3.id_flex_structure_code LIKE '%3'
    AND   fifs4.id_flex_code = fifs3.id_flex_code
    AND   fifs4.enabled_flag = fifs3.enabled_flag
    AND   fifs4.id_flex_structure_code LIKE '%4';

  /* Define KFF1 cursor */
  CURSOR kff1_cur IS
    SELECT xpvsfs.segment1,
           xpvsfs.segment2,
           xpvsfs.segment3,
           xpvsfs.segment4,
           xpvsfs.segment5,
           TRIM(xpvsfs.segment6),
           xpvsfs.segment7,
           xpvsfs.segment8,
           xpvsfs.segment9,
           xpvsfs.segment10,
           xasss.attribute10,
           xpvsfs.segment12,
           xpvsfs.segment13,
           xpvsfs.segment14,
           xpvsfs.segment15,
           xpvsfs.segment16,
           xpvsfs.segment17,
           xpvsfs.segment18,
           xpvsfs.segment19
    FROM xx_po_vendor_sites_kff_stg xpvsfs,
         xx_ap_supplier_sites_stg xasss
    WHERE xpvsfs.kff1_id IS NULL
--and xpvsfs.legacy_vendor_id = '0000003393'
    AND   xpvsfs.legacy_vendor_id = xasss.legacy_vendor_id (+)
    GROUP BY xpvsfs.segment1,
             xpvsfs.segment2,
             xpvsfs.segment3,
             xpvsfs.segment4,
             xpvsfs.segment5,
             xpvsfs.segment6,
             xpvsfs.segment7,
             xpvsfs.segment8,
             xpvsfs.segment9,
             xpvsfs.segment10,
             xasss.attribute10,
             xpvsfs.segment12,
             xpvsfs.segment13,
             xpvsfs.segment14,
             xpvsfs.segment15,
             xpvsfs.segment16,
             xpvsfs.segment17,
             xpvsfs.segment18,
             xpvsfs.segment19;

  /* Define KFF2 cursor */
  CURSOR kff2_cur IS
    SELECT segment20,
           segment21,
           segment22,
           segment23,
           segment24,
           segment25,
           segment26,
           segment27,
           segment28,
           segment29,
           segment30,
           segment31,
           segment32,
           segment33,
           segment34,
           segment35,
           segment36,
           segment37,
           segment38,
           segment39
    FROM xx_po_vendor_sites_kff_stg
    WHERE kff2_id IS NULL
--and legacy_vendor_id = '0000003393'
    GROUP BY segment20,
             segment21,
             segment22,
             segment23,
             segment24,
             segment25,
             segment26,
             segment27,
             segment28,
             segment29,
             segment30,
             segment31,
             segment32,
             segment33,
             segment34,
             segment35,
             segment36,
             segment37,
             segment38,
             segment39;

  /* Define KFF3 cursor */
  CURSOR kff3_cur IS
    SELECT segment40,
           segment41,
           segment42,
           segment43,
           segment44,
           segment45,
           segment46,
           segment47,
           segment48,
           segment49,
           segment50,
           segment51,
           segment52,
           segment53,
           segment54,
           segment55,
           segment56,
           segment57,
           segment58,
           segment59
    FROM xx_po_vendor_sites_kff_stg
    WHERE kff3_id IS NULL
--and legacy_vendor_id = '0000003393'
    GROUP BY segment40,
             segment41,
             segment42,
             segment43,
             segment44,
             segment45,
             segment46,
             segment47,
             segment48,
             segment49,
             segment50,
             segment51,
             segment52,
             segment53,
             segment54,
             segment55,
             segment56,
             segment57,
             segment58,
             segment59;

  /* Define KFF cursor */
  CURSOR kff_cur IS
    SELECT DISTINCT pvsa.attribute9,
           xpvsfs.kff1_id,
           xpvsfs.kff2_id,
           xpvsfs.kff3_id
    FROM xx_po_vendor_sites_kff_stg xpvsfs,
         po_vendor_sites_all pvsa
    WHERE (pvsa.attribute10 IS NULL
        OR pvsa.attribute11 IS NULL
        OR pvsa.attribute12 IS NULL)
--AND   pvsa.attribute9 = '0000003393' --IS NOT NULL
    AND   xpvsfs.legacy_vendor_id = pvsa.attribute9;

BEGIN
  /* Only open the flex num cursor if it is not already open */
  IF NOT flex_cur%ISOPEN THEN
    OPEN flex_cur;
  END IF;

  /* Populate variables using cursor fetch */
  FETCH flex_cur INTO v_id_flex_num1,
                      v_id_flex_num2,
                      v_id_flex_num3,
                      v_id_flex_num4;

  CLOSE flex_cur;

  /* There's no point continuing if the KFF hasn't been defined */
  IF v_id_flex_num1 IS NULL OR v_id_flex_num2 IS NULL OR v_id_flex_num3 IS NULL OR v_id_flex_num4 IS NULL THEN
      fnd_file.put_line(fnd_file.output,'Please define the ODVS KFF.');
      v_set_completion_status_flag := 'ERROR';
      v_set_completion_status_text := 'Error: Please define the ODVS KFF';
  ELSE
    /* Only open the KFF1 cursor if it is not already open */
    IF NOT kff1_cur%ISOPEN THEN
      OPEN kff1_cur;
    END IF;

    LOOP
      /* Populate variables using cursor fetch */
      FETCH kff1_cur INTO v_segment1,
                          v_segment2,
                          v_segment3,
                          v_segment4,
                          v_segment5,
                          v_segment6,
                          v_segment7,
                          v_segment8,
                          v_segment9,
                          v_segment10,
                          v_segment11,
                          v_segment12,
                          v_segment13,
                          v_segment14,
                          v_segment15,
                          v_segment16,
                          v_segment17,
                          v_segment18,
                          v_segment19;

      /* Keep fetching until no more records are found */
      EXIT WHEN NOT kff1_cur%FOUND;

      /* Translate the segment3 */
      IF v_segment3 = 'NEXT' THEN
        v_translated_segment3 := 'NEXT DAY';
      ELSIF v_segment3 = 'NDD' THEN
        v_translated_segment3 := 'NEXT VALID DELIVERY DAY';
      ELSE
        v_translated_segment3 := v_segment3;
      END IF;

      /* Translate the terms name - segment11 */
      xx_fin_translate_pkg.xx_fin_translatevalue_proc (p_translation_name => 'AP_EFT_SETTLE_DAYS',
                                                       p_source_value1 => v_segment11,
                                                       x_target_value1 => v_translated_segment11,
                                                       x_target_value2 => v_dummy,
                                                       x_target_value3 => v_dummy,
                                                       x_target_value4 => v_dummy,
                                                       x_target_value5 => v_dummy,
                                                       x_target_value6 => v_dummy,
                                                       x_target_value7 => v_dummy,
                                                       x_target_value8 => v_dummy,
                                                       x_target_value9 => v_dummy,
                                                       x_target_value10 => v_dummy,
                                                       x_target_value11 => v_dummy,
                                                       x_target_value12 => v_dummy,
                                                       x_target_value13 => v_dummy,
                                                       x_target_value14 => v_dummy,
                                                       x_target_value15 => v_dummy,
                                                       x_target_value16 => v_dummy,
                                                       x_target_value17 => v_dummy,
                                                       x_target_value18 => v_dummy,
                                                       x_target_value19 => v_dummy,
                                                       x_target_value20 => v_dummy,
                                                       x_error_message => v_error_message);

      /* If there was no value returned, use the original */
      IF v_error_message IS NULL THEN
        NULL;
      ELSE
        v_translated_segment11 := v_segment11;
        v_error_message := NULL;
      END IF;

      /* If the combination does not already exist, create it */
      BEGIN
        /* Check if the combination already exists */
        select vs_kff_id
        INTO v_vs_kff_id
        from xx_po_vendor_sites_kff
        WHERE (segment1 = v_segment1 OR (segment1 IS NULL AND v_segment1 IS NULL))
        AND   (segment2 = v_segment2 OR (segment2 IS NULL AND v_segment2 IS NULL))
        AND   (segment3 = v_translated_segment3 OR (segment3 IS NULL AND v_translated_segment3 IS NULL))
        AND   (segment4 = v_segment4 OR (segment4 IS NULL AND v_segment4 IS NULL))
        AND   (segment5 = v_segment5 OR (segment5 IS NULL AND v_segment5 IS NULL))
        AND   (segment6 = v_segment6 OR (segment6 IS NULL AND v_segment6 IS NULL))
        AND   (segment7 = v_segment7 OR (segment7 IS NULL AND v_segment7 IS NULL))
        AND   (segment8 = v_segment8 OR (segment8 IS NULL AND v_segment8 IS NULL))
        AND   (segment9 = v_segment9 OR (segment9 IS NULL AND v_segment9 IS NULL))
        AND   (segment10 = v_segment10 OR (segment10 IS NULL AND v_segment10 IS NULL))
        AND   (segment11 = v_translated_segment11 OR (segment11 IS NULL AND v_translated_segment11 IS NULL))
        AND   (segment12 = v_segment12 OR (segment12 IS NULL AND v_segment12 IS NULL))
        AND   (segment13 = v_segment13 OR (segment13 IS NULL AND v_segment13 IS NULL))
        AND   (segment14 = v_segment14 OR (segment14 IS NULL AND v_segment14 IS NULL))
        AND   (segment15 = v_segment15 OR (segment15 IS NULL AND v_segment15 IS NULL))
        AND   (segment16 = v_segment16 OR (segment16 IS NULL AND v_segment16 IS NULL))
        AND   (segment17 = v_segment17 OR (segment17 IS NULL AND v_segment17 IS NULL))
        AND   (segment18 = v_segment18 OR (segment18 IS NULL AND v_segment18 IS NULL))
        AND   (segment19 = v_segment19 OR (segment19 IS NULL AND v_segment19 IS NULL));

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          /* Get the KFF ID */
          SELECT xx_po_vendor_sites_kff_s.NEXTVAL
          INTO v_vs_kff_id
          FROM dual;

          /* Insert the KFF1 data */
          INSERT INTO xx_po_vendor_sites_kff (vs_kff_id,
                                              structure_id,
                                              enabled_flag,
                                              summary_flag,
                                              start_date_active,
                                              end_date_active,
                                              last_update_date,
                                              last_updated_by,
                                              segment1,
                                              segment2,
                                              segment3,
                                              segment4,
                                              segment5,
                                              segment6,
                                              segment7,
                                              segment8,
                                              segment9,
                                              segment10,
                                              segment11,
                                              segment12,
                                              segment13,
                                              segment14,
                                              segment15,
                                              segment16,
                                              segment17,
                                              segment18,
                                              segment19)
          VALUES (v_vs_kff_id,            --vs_kff_id
                  v_id_flex_num1,         --structure_id
                  c_yes,                  --enabled_flag
                  c_no,                   --summary_flag
                  NULL,                   --start_date_active
                  NULL,                   --end_date_active
                  c_when,                 --last_update_date
                  c_who,                  --last_updated_by
                  v_segment1,             --segment1
                  v_segment2,             --segment2
                  v_translated_segment3,  --segment3
                  v_segment4,             --segment4
                  v_segment5,             --segment5
                  v_segment6,             --segment6
                  v_segment7,             --segment7
                  v_segment8,             --segment8
                  v_segment9,             --segment9
                  v_segment10,            --segment10
                  v_translated_segment11, --segment11
                  v_segment12,            --segment12
                  v_segment13,            --segment13
                  v_segment14,            --segment14
                  v_segment15,            --segment15
                  v_segment16,            --segment16
                  v_segment17,            --segment17
                  v_segment18,            --segment18
                  v_segment19);           --segment19
      END;

      /* Update the KFF staging table */
      UPDATE xx_po_vendor_sites_kff_stg
      SET kff1_id = v_vs_kff_id
      WHERE (segment1 = v_segment1 OR (segment1 IS NULL AND v_segment1 IS NULL))
      AND   (segment2 = v_segment2 OR (segment2 IS NULL AND v_segment2 IS NULL))
      AND   (segment3 = v_segment3 OR (segment3 IS NULL AND v_segment3 IS NULL))
      AND   (segment4 = v_segment4 OR (segment4 IS NULL AND v_segment4 IS NULL))
      AND   (segment5 = v_segment5 OR (segment5 IS NULL AND v_segment5 IS NULL))
      AND   (segment6 = v_segment6 OR (segment6 IS NULL AND v_segment6 IS NULL))
      AND   (segment7 = v_segment7 OR (segment7 IS NULL AND v_segment7 IS NULL))
      AND   (segment8 = v_segment8 OR (segment8 IS NULL AND v_segment8 IS NULL))
      AND   (segment9 = v_segment9 OR (segment9 IS NULL AND v_segment9 IS NULL))
      AND   (segment10 = v_segment10 OR (segment10 IS NULL AND v_segment10 IS NULL))
      AND   (segment11 = v_segment11 OR (segment11 IS NULL AND v_segment11 IS NULL))
      AND   (segment12 = v_segment12 OR (segment12 IS NULL AND v_segment12 IS NULL))
      AND   (segment13 = v_segment13 OR (segment13 IS NULL AND v_segment13 IS NULL))
      AND   (segment14 = v_segment14 OR (segment14 IS NULL AND v_segment14 IS NULL))
      AND   (segment15 = v_segment15 OR (segment15 IS NULL AND v_segment15 IS NULL))
      AND   (segment16 = v_segment16 OR (segment16 IS NULL AND v_segment16 IS NULL))
      AND   (segment17 = v_segment17 OR (segment17 IS NULL AND v_segment17 IS NULL))
      AND   (segment18 = v_segment18 OR (segment18 IS NULL AND v_segment18 IS NULL))
      AND   (segment19 = v_segment19 OR (segment19 IS NULL AND v_segment19 IS NULL));

    END LOOP;
    CLOSE kff1_cur;

    /* Commit the kff1_cur work */
    COMMIT;

    /* Only open the KFF2 cursor if it is not already open */
    IF NOT kff2_cur%ISOPEN THEN
      OPEN kff2_cur;
    END IF;

    LOOP
      /* Populate variables using cursor fetch */
      FETCH kff2_cur INTO v_segment20,
                          v_segment21,
                          v_segment22,
                          v_segment23,
                          v_segment24,
                          v_segment25,
                          v_segment26,
                          v_segment27,
                          v_segment28,
                          v_segment29,
                          v_segment30,
                          v_segment31,
                          v_segment32,
                          v_segment33,
                          v_segment34,
                          v_segment35,
                          v_segment36,
                          v_segment37,
                          v_segment38,
                          v_segment39;

      /* Keep fetching until no more records are found */
      EXIT WHEN NOT kff2_cur%FOUND;

      /* Translate the terms names */
      xx_fin_translate_pkg.xx_fin_translatevalue_proc (p_translation_name => 'AP_PAYMENT_TERMS',
                                                       p_source_value1 => NULL,
                                                       p_source_value2 => v_segment21,
                                                       x_target_value1 => v_dummy,
                                                       x_target_value2 => v_translated_segment21,
                                                       x_target_value3 => v_dummy,
                                                       x_target_value4 => v_dummy,
                                                       x_target_value5 => v_dummy,
                                                       x_target_value6 => v_dummy,
                                                       x_target_value7 => v_dummy,
                                                       x_target_value8 => v_dummy,
                                                       x_target_value9 => v_dummy,
                                                       x_target_value10 => v_dummy,
                                                       x_target_value11 => v_dummy,
                                                       x_target_value12 => v_dummy,
                                                       x_target_value13 => v_dummy,
                                                       x_target_value14 => v_dummy,
                                                       x_target_value15 => v_dummy,
                                                       x_target_value16 => v_dummy,
                                                       x_target_value17 => v_dummy,
                                                       x_target_value18 => v_dummy,
                                                       x_target_value19 => v_dummy,
                                                       x_target_value20 => v_dummy,
                                                       x_error_message => v_error_message);

      /* If there was no value returned, use the original */
      IF v_error_message IS NULL THEN
        /* Lookup the terms id */
        BEGIN
          SELECT term_id
          INTO v_translated_segment21
          FROM ap_terms_tl
          WHERE NAME = v_translated_segment21;

        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      ELSE
        v_translated_segment21 := v_segment21;
        v_error_message := NULL;
      END IF;

      xx_fin_translate_pkg.xx_fin_translatevalue_proc (p_translation_name => 'AP_PAYMENT_TERMS',
                                                       p_source_value1 => NULL,
                                                       p_source_value2 => v_segment25,
                                                       x_target_value1 => v_dummy,
                                                       x_target_value2 => v_translated_segment25,
                                                       x_target_value3 => v_dummy,
                                                       x_target_value4 => v_dummy,
                                                       x_target_value5 => v_dummy,
                                                       x_target_value6 => v_dummy,
                                                       x_target_value7 => v_dummy,
                                                       x_target_value8 => v_dummy,
                                                       x_target_value9 => v_dummy,
                                                       x_target_value10 => v_dummy,
                                                       x_target_value11 => v_dummy,
                                                       x_target_value12 => v_dummy,
                                                       x_target_value13 => v_dummy,
                                                       x_target_value14 => v_dummy,
                                                       x_target_value15 => v_dummy,
                                                       x_target_value16 => v_dummy,
                                                       x_target_value17 => v_dummy,
                                                       x_target_value18 => v_dummy,
                                                       x_target_value19 => v_dummy,
                                                       x_target_value20 => v_dummy,
                                                       x_error_message => v_error_message);

      /* If there was no value returned, use the original */
      IF v_error_message IS NULL THEN
        /* Lookup the terms id */
        BEGIN
          SELECT term_id
          INTO v_translated_segment25
          FROM ap_terms_tl
          WHERE name = v_translated_segment25;

        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      ELSE
        v_translated_segment25 := v_segment25;
        v_error_message := NULL;
      END IF;

      /* Translate the segment36 */
      IF v_segment36 = 'D' THEN
        v_translated_segment36 := 'DAILY';
      ELSIF v_segment36 = 'M' THEN
        v_translated_segment36 := 'MONTHLY';
      ELSIF v_segment36 = 'W' THEN
        v_translated_segment36 := 'WEEKLY';
      ELSE
        v_translated_segment36 := v_segment36;
      END IF;

      /* If the combination does not already exist, create it */
      BEGIN
        /* Check if the combination already exists */
        select vs_kff_id
        INTO v_vs_kff_id
        from xx_po_vendor_sites_kff
        WHERE (segment20 = v_segment20 OR (segment20 IS NULL AND v_segment20 IS NULL))
        AND   (segment21 = v_translated_segment21 OR (segment21 IS NULL AND v_translated_segment21 IS NULL))
        AND   (segment22 = v_segment22 OR (segment22 IS NULL AND v_segment22 IS NULL))
        AND   (segment23 = v_segment23 OR (segment23 IS NULL AND v_segment23 IS NULL))
        AND   (segment24 = v_segment24 OR (segment24 IS NULL AND v_segment24 IS NULL))
        AND   (segment25 = v_translated_segment25 OR (segment25 IS NULL AND v_translated_segment25 IS NULL))
        AND   (segment26 = v_segment26 OR (segment26 IS NULL AND v_segment26 IS NULL))
        AND   (segment27 = v_segment27 OR (segment27 IS NULL AND v_segment27 IS NULL))
        AND   (segment28 = v_segment28 OR (segment28 IS NULL AND v_segment28 IS NULL))
        AND   (segment29 = v_segment29 OR (segment29 IS NULL AND v_segment29 IS NULL))
        AND   (segment30 = v_segment30 OR (segment30 IS NULL AND v_segment30 IS NULL))
        AND   (segment31 = v_segment31 OR (segment31 IS NULL AND v_segment31 IS NULL))
        AND   (segment32 = v_segment32 OR (segment32 IS NULL AND v_segment32 IS NULL))
        AND   (segment33 = v_segment33 OR (segment33 IS NULL AND v_segment33 IS NULL))
        AND   (segment34 = v_segment34 OR (segment34 IS NULL AND v_segment34 IS NULL))
        AND   (segment35 = v_segment35 OR (segment35 IS NULL AND v_segment35 IS NULL))
        AND   (segment36 = v_translated_segment36 OR (segment36 IS NULL AND v_translated_segment36 IS NULL))
        AND   (segment37 = v_segment37 OR (segment37 IS NULL AND v_segment37 IS NULL))
        AND   (segment38 = v_segment38 OR (segment38 IS NULL AND v_segment38 IS NULL))
        AND   (segment39 = v_segment39 OR (segment39 IS NULL AND v_segment39 IS NULL));

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          /* Get the KFF ID */
          SELECT xx_po_vendor_sites_kff_s.NEXTVAL
          INTO v_vs_kff_id
          FROM dual;

          /* Insert the KFF2 data */
          INSERT INTO xx_po_vendor_sites_kff (vs_kff_id,
                                              structure_id,
                                              enabled_flag,
                                              summary_flag,
                                              start_date_active,
                                              end_date_active,
                                              last_update_date,
                                              last_updated_by,
                                              segment20,
                                              segment21,
                                              segment22,
                                              segment23,
                                              segment24,
                                              segment25,
                                              segment26,
                                              segment27,
                                              segment28,
                                              segment29,
                                              segment30,
                                              segment31,
                                              segment32,
                                              segment33,
                                              segment34,
                                              segment35,
                                              segment36,
                                              segment37,
                                              segment38,
                                              segment39)
          VALUES (v_vs_kff_id,            --vs_kff_id
                  v_id_flex_num2,         --structure_id
                  c_yes,                  --enabled_flag
                  c_no,                   --summary_flag
                  NULL,                   --start_date_active
                  NULL,                   --end_date_active
                  c_when,                 --last_update_date
                  c_who,                  --last_updated_by
                  v_segment20,            --segment20
                  v_translated_segment21, --segment21
                  v_segment22,            --segment22
                  v_segment23,            --segment23
                  v_segment24,            --segment24
                  v_translated_segment25, --segment25
                  v_segment26,            --segment26
                  v_segment27,            --segment27
                  v_segment28,            --segment28
                  v_segment29,            --segment29
                  v_segment30,            --segment30
                  v_segment31,            --segment31
                  v_segment32,            --segment32
                  v_segment33,            --segment33
                  v_segment34,            --segment34
                  v_segment35,            --segment35
                  v_translated_segment36, --segment36
                  v_segment37,            --segment37
                  v_segment38,            --segment38
                  v_segment39);           --segment39
      END;

      /* Update the KFF staging table */
      UPDATE xx_po_vendor_sites_kff_stg
      SET kff2_id = v_vs_kff_id
      WHERE (segment20 = v_segment20 OR (segment20 IS NULL AND v_segment20 IS NULL))
      AND   (segment21 = v_segment21 OR (segment21 IS NULL AND v_segment21 IS NULL))
      AND   (segment22 = v_segment22 OR (segment22 IS NULL AND v_segment22 IS NULL))
      AND   (segment23 = v_segment23 OR (segment23 IS NULL AND v_segment23 IS NULL))
      AND   (segment24 = v_segment24 OR (segment24 IS NULL AND v_segment24 IS NULL))
      AND   (segment25 = v_segment25 OR (segment25 IS NULL AND v_segment25 IS NULL))
      AND   (segment26 = v_segment26 OR (segment26 IS NULL AND v_segment26 IS NULL))
      AND   (segment27 = v_segment27 OR (segment27 IS NULL AND v_segment27 IS NULL))
      AND   (segment28 = v_segment28 OR (segment28 IS NULL AND v_segment28 IS NULL))
      AND   (segment29 = v_segment29 OR (segment29 IS NULL AND v_segment29 IS NULL))
      AND   (segment30 = v_segment30 OR (segment30 IS NULL AND v_segment30 IS NULL))
      AND   (segment31 = v_segment31 OR (segment31 IS NULL AND v_segment31 IS NULL))
      AND   (segment32 = v_segment32 OR (segment32 IS NULL AND v_segment32 IS NULL))
      AND   (segment33 = v_segment33 OR (segment33 IS NULL AND v_segment33 IS NULL))
      AND   (segment34 = v_segment34 OR (segment34 IS NULL AND v_segment34 IS NULL))
      AND   (segment35 = v_segment35 OR (segment35 IS NULL AND v_segment35 IS NULL))
      AND   (segment36 = v_segment36 OR (segment36 IS NULL AND v_segment36 IS NULL))
      AND   (segment37 = v_segment37 OR (segment37 IS NULL AND v_segment37 IS NULL))
      AND   (segment38 = v_segment38 OR (segment38 IS NULL AND v_segment38 IS NULL))
      AND   (segment39 = v_segment39 OR (segment39 IS NULL AND v_segment39 IS NULL));

    END LOOP;
    CLOSE kff2_cur;

    /* Commit the kff2_cur work */
    COMMIT;

    /* Only open the KFF3 cursor if it is not already open */
    IF NOT kff3_cur%ISOPEN THEN
      OPEN kff3_cur;
    END IF;

    LOOP
      /* Populate variables using cursor fetch */
      FETCH kff3_cur INTO v_segment40,
                          v_segment41,
                          v_segment42,
                          v_segment43,
                          v_segment44,
                          v_segment45,
                          v_segment46,
                          v_segment47,
                          v_segment48,
                          v_segment49,
                          v_segment50,
                          v_segment51,
                          v_segment52,
                          v_segment53,
                          v_segment54,
                          v_segment55,
                          v_segment56,
                          v_segment57,
                          v_segment58,
                          v_segment59;

      /* Keep fetching until no more records are found */
      EXIT WHEN NOT kff3_cur%FOUND;

      /* Translate the segment41 */
      IF v_segment41 = 'CC' THEN
        v_translated_segment41 := 'COLLECT';
      ELSIF v_segment41 = 'NN' THEN
        v_translated_segment41 := 'NEITHER';
      ELSIF v_segment41 = 'PP' THEN
        v_translated_segment41 := 'PREPAID';
      ELSE
        v_translated_segment41 := v_segment41;
      END IF;

      /* Translate the segment44 */
      IF v_segment44 = 'M' THEN
        v_translated_segment44 := 'MONTHLY';
      ELSIF v_segment44 = 'Q' THEN
        v_translated_segment44 := 'QUARTERLY';
      ELSIF v_segment44 = 'W' THEN
        v_translated_segment44 := 'WEEKLY';
      ELSE
        v_translated_segment44 := v_segment44;
      END IF;

      /* If the combination does not already exist, create it */
      BEGIN
        /* Check if the combination already exists */
        select vs_kff_id
        INTO v_vs_kff_id
        from xx_po_vendor_sites_kff
        WHERE (segment40 = v_segment40 OR (segment40 IS NULL AND v_segment40 IS NULL))
        AND   (segment41 = v_translated_segment41 OR (segment41 IS NULL AND v_translated_segment41 IS NULL))
        AND   (segment42 = v_segment42 OR (segment42 IS NULL AND v_segment42 IS NULL))
        AND   (segment43 = v_segment43 OR (segment43 IS NULL AND v_segment43 IS NULL))
        AND   (segment44 = v_translated_segment44 OR (segment44 IS NULL AND v_translated_segment44 IS NULL))
        AND   (segment45 = v_segment45 OR (segment45 IS NULL AND v_segment45 IS NULL))
        AND   (segment46 = v_segment46 OR (segment46 IS NULL AND v_segment46 IS NULL))
        AND   (segment47 = v_segment47 OR (segment47 IS NULL AND v_segment47 IS NULL))
        AND   (segment48 = v_segment48 OR (segment48 IS NULL AND v_segment48 IS NULL))
        AND   (segment49 = v_segment49 OR (segment49 IS NULL AND v_segment49 IS NULL))
        AND   (segment50 = v_segment50 OR (segment50 IS NULL AND v_segment50 IS NULL))
        AND   (segment51 = v_segment51 OR (segment51 IS NULL AND v_segment51 IS NULL))
        AND   (segment52 = v_segment52 OR (segment52 IS NULL AND v_segment52 IS NULL))
        AND   (segment53 = v_segment53 OR (segment53 IS NULL AND v_segment53 IS NULL))
        AND   (segment54 = v_segment54 OR (segment54 IS NULL AND v_segment54 IS NULL))
        AND   (segment55 = v_segment55 OR (segment55 IS NULL AND v_segment55 IS NULL))
        AND   (segment56 = v_segment56 OR (segment56 IS NULL AND v_segment56 IS NULL))
        AND   (segment57 = v_segment57 OR (segment57 IS NULL AND v_segment57 IS NULL))
        AND   (segment58 = v_segment58 OR (segment58 IS NULL AND v_segment58 IS NULL))
        AND   (segment59 = v_segment59 OR (segment59 IS NULL AND v_segment59 IS NULL));

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          /* Get the KFF ID */
          SELECT xx_po_vendor_sites_kff_s.NEXTVAL
          INTO v_vs_kff_id
          FROM dual;

          /* Insert the KFF3 data */
          INSERT INTO xx_po_vendor_sites_kff (vs_kff_id,
                                              structure_id,
                                              enabled_flag,
                                              summary_flag,
                                              start_date_active,
                                              end_date_active,
                                              last_update_date,
                                              last_updated_by,
                                              segment40,
                                              segment41,
                                              segment42,
                                              segment43,
                                              segment44,
                                              segment45,
                                              segment46,
                                              segment47,
                                              segment48,
                                              segment49,
                                              segment50,
                                              segment51,
                                              segment52,
                                              segment53,
                                              segment54,
                                              segment55,
                                              segment56,
                                              segment57,
                                              segment58,
                                              segment59)
          VALUES (v_vs_kff_id,            --vs_kff_id
                  v_id_flex_num3,         --structure_id
                  c_yes,                  --enabled_flag
                  c_no,                   --summary_flag
                  NULL,                   --start_date_active
                  NULL,                   --end_date_active
                  c_when,                 --last_update_date
                  c_who,                  --last_updated_by
                  v_segment40,            --segment40
                  v_translated_segment41, --segment41
                  v_segment42,            --segment42
                  v_segment43,            --segment43
                  v_translated_segment44, --segment44
                  v_segment45,            --segment45
                  v_segment46,            --segment46
                  v_segment47,            --segment47
                  v_segment48,            --segment48
                  v_segment49,            --segment49
                  v_segment50,            --segment50
                  v_segment51,            --segment51
                  v_segment52,            --segment52
                  v_segment53,            --segment53
                  v_segment54,            --segment54
                  v_segment55,            --segment55
                  v_segment56,            --segment56
                  v_segment57,            --segment57
                  v_segment58,            --segment58
                  v_segment59);           --segment59
      END;

      /* Update the KFF staging table */
      UPDATE xx_po_vendor_sites_kff_stg
      SET kff3_id = v_vs_kff_id
      WHERE (segment40 = v_segment40 OR (segment40 IS NULL AND v_segment40 IS NULL))
      AND   (segment41 = v_segment41 OR (segment41 IS NULL AND v_segment41 IS NULL))
      AND   (segment42 = v_segment42 OR (segment42 IS NULL AND v_segment42 IS NULL))
      AND   (segment43 = v_segment43 OR (segment43 IS NULL AND v_segment43 IS NULL))
      AND   (segment44 = v_segment44 OR (segment44 IS NULL AND v_segment44 IS NULL))
      AND   (segment45 = v_segment45 OR (segment45 IS NULL AND v_segment45 IS NULL))
      AND   (segment46 = v_segment46 OR (segment46 IS NULL AND v_segment46 IS NULL))
      AND   (segment47 = v_segment47 OR (segment47 IS NULL AND v_segment47 IS NULL))
      AND   (segment48 = v_segment48 OR (segment48 IS NULL AND v_segment48 IS NULL))
      AND   (segment49 = v_segment49 OR (segment49 IS NULL AND v_segment49 IS NULL))
      AND   (segment50 = v_segment50 OR (segment50 IS NULL AND v_segment50 IS NULL))
      AND   (segment51 = v_segment51 OR (segment51 IS NULL AND v_segment51 IS NULL))
      AND   (segment52 = v_segment52 OR (segment52 IS NULL AND v_segment52 IS NULL))
      AND   (segment53 = v_segment53 OR (segment53 IS NULL AND v_segment53 IS NULL))
      AND   (segment54 = v_segment54 OR (segment54 IS NULL AND v_segment54 IS NULL))
      AND   (segment55 = v_segment55 OR (segment55 IS NULL AND v_segment55 IS NULL))
      AND   (segment56 = v_segment56 OR (segment56 IS NULL AND v_segment56 IS NULL))
      AND   (segment57 = v_segment57 OR (segment57 IS NULL AND v_segment57 IS NULL))
      AND   (segment58 = v_segment58 OR (segment58 IS NULL AND v_segment58 IS NULL))
      AND   (segment59 = v_segment59 OR (segment59 IS NULL AND v_segment59 IS NULL));

    END LOOP;
    CLOSE kff3_cur;

    /* Commit the kff3_cur work */
    COMMIT;

    /* Only open the KFF cursor if it is not already open */
    IF NOT kff_cur%ISOPEN THEN
      OPEN kff_cur;
    END IF;

    LOOP
      /* Populate variables using cursor fetch */
      FETCH kff_cur INTO v_legacy_vendor_id,
                         v_attribute10,
                         v_attribute11,
                         v_attribute12;

      /* Keep fetching until no more records are found */
      EXIT WHEN NOT kff_cur%FOUND;

      /* Update po_vendor_sites_all attributes for the current legacy_vendor_id */
      UPDATE po_vendor_sites_all
      SET attribute10 = NVL(attribute10,v_attribute10),
          attribute11 = NVL(attribute11,v_attribute11),
          attribute12 = NVL(attribute12,v_attribute12)
      WHERE attribute9 = v_legacy_vendor_id;

    END LOOP;
    CLOSE kff_cur;
  END IF;

  /* Commit the strays */
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in p_process_kffs '||SQLERRM);
    v_set_completion_status_flag := 'ERROR';
    v_set_completion_status_text := 'Error in p_process_kffs '||SQLERRM;
END p_process_kffs;

/* Start the main program */
BEGIN
  fnd_file.put_line(fnd_file.output,'''OD: PO Vendor Inbound'' start time is '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
  fnd_file.put_line(fnd_file.output,' ');

  /* Get the exception GL accounts */
  p_get_gl_accounts;

  IF v_us_trade_ccid IS NULL OR v_ca_trade_ccid IS NULL THEN
    IF v_us_trade_ccid IS NULL THEN
      fnd_file.put_line(fnd_file.output,'Trade liability account combinations must be defined for US.');
      fnd_file.put_line(fnd_file.output,' ');
    END IF;

    IF v_ca_trade_ccid IS NULL THEN
      fnd_file.put_line(fnd_file.output,'Trade liability account combinations must be defined for CA.');
      fnd_file.put_line(fnd_file.output,' ');
    END IF;

  ELSE
    /* Load the vendors */
    p_insert_vendors;

    fnd_file.put_line(fnd_file.output,' ');
    fnd_file.put_line(fnd_file.output,'Successfully processed vendor count is '||v_vendor_count);
    fnd_file.put_line(fnd_file.output,'Successfully processed vendor site count is '||v_vendor_site_count);
    fnd_file.put_line(fnd_file.output,'Successfully processed vendor contact count is '||v_vendor_site_contact_count);
    fnd_file.put_line(fnd_file.output,' ');

    fnd_file.put_line(fnd_file.output,'Post processing time is '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    fnd_file.put_line(fnd_file.output,' ');

    /* Submit the Vendor, Vendor Site, and Vendor Site Contact imports if vendors were processed */
    IF v_vendor_count > 0 THEN
      fnd_file.put_line(fnd_file.output,'Starting Imports...');
      fnd_file.put_line(fnd_file.output,' ');

      /* Submit the 'Supplier Open Interface Import' process */
      v_request_id := Fnd_Request.submit_request ('SQLAP',    --application
                                                  'APXSUIMP', --program
                                                  NULL,       --description
                                                  NULL,       --start_time
                                                  FALSE,      --sub_request
                                                  'ALL',      --argument1
                                                  '1000',     --argument2
                                                  c_no,       --argument3
                                                  c_no,       --argument4
                                                  c_no,       --argument5
                                                  CHR(0));    --argument6

      /* Start the request */
      COMMIT;

      /* Check that the request submission was OK */
      IF v_request_id = 0 THEN
        fnd_file.put_line(fnd_file.log,'Error submitting request for ''Supplier Open Interface Import''.');
        fnd_file.put_line(fnd_file.output,' ');
      ELSE

        fnd_file.put_line(fnd_file.output,'Started ''Supplier Open Interface Import'' at '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        fnd_file.put_line(fnd_file.output,' ');

        /* Wait for the import request to complete */
        v_bool := fnd_concurrent.wait_for_request(v_request_id, --request_id
                                                  10,           --interval
                                                  360000,       --max_wait
                                                  v_phase,      --phase
                                                  v_status,     --status
                                                  v_dev_phase,  --dev_phase
                                                  v_dev_status, --dev_status
                                                  v_message );  --message

        /* Submit the 'Supplier Sites Open Interface Import' process */
        v_request_id := Fnd_Request.submit_request ('SQLAP',    --application
                                                    'APXSSIMP', --program,
                                                    NULL,       --description,
                                                    NULL,       --start_time,
                                                    FALSE,      --sub_request
                                                    'ALL',      --argument1
                                                    '1000',     --argument2
                                                    c_no,       --argument3
                                                    c_no,       --argument4
                                                    c_no,       --argument5
                                                    CHR(0));    --argument6

        /* Start the request */
        COMMIT;

        /* Check that the request submission was OK */
        IF v_request_id = 0 THEN
          fnd_file.put_line(fnd_file.log,'Error submitting request for ''Supplier Sites Open Interface Import''.');
          fnd_file.put_line(fnd_file.output,' ');
        ELSE

          fnd_file.put_line(fnd_file.output,'Started ''Supplier Sites Open Interface Import'' at '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
          fnd_file.put_line(fnd_file.output,' ');

          /* Wait for the import request to complete */
          v_bool := fnd_concurrent.wait_for_request(v_request_id, --request_id
                                                    10,           --interval
                                                    360000,       --max_wait
                                                    v_phase,      --phase
                                                    v_status,     --status
                                                    v_dev_phase,  --dev_phase
                                                    v_dev_status, --dev_status
                                                    v_message );  --message

          /* Update the site contacts vendor_site_id */
          UPDATE ap_sup_site_contact_int assci
          SET vendor_site_id = (SELECT MAX(pvsa.vendor_site_id)
                                FROM po_vendor_sites_all pvsa
                                WHERE pvsa.attribute9 = assci.contact_name_alt
                                AND   pvsa.vendor_site_code = assci.vendor_site_code)
          WHERE status != 'PROCESSED'
          AND   vendor_site_id IS NULL;

          COMMIT;

          /* Submit the 'Supplier Site Contacts Open Interface Import' process */
          v_request_id := Fnd_Request.submit_request ('SQLAP',    --application
                                                      'APXSCIMP', --program,
                                                      NULL,       --description,
                                                      NULL,       --start_time,
                                                      FALSE,      --sub_request
                                                      'ALL',      --argument1
                                                      '1000',     --argument2
                                                      c_no,       --argument3
                                                      c_no,       --argument4
                                                      c_no,       --argument5
                                                      CHR(0));    --argument6

          /* Start the request */
          COMMIT;

          /* Check that the request submission was OK */
          IF v_request_id = 0 THEN
            fnd_file.put_line(fnd_file.log,'Error submitting request for ''Supplier Site Contacts Open Interface Import''.');
            fnd_file.put_line(fnd_file.output,' ');
          ELSE
            fnd_file.put_line(fnd_file.output,'Started ''Supplier Site Contacts Open Interface Import'' at '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
            fnd_file.put_line(fnd_file.output,' ');
          END IF;
        END IF;
      END IF;

    fnd_file.put_line(fnd_file.output,'Imports completed!');
    fnd_file.put_line(fnd_file.output,' ');
    END IF;
  END IF;

  fnd_file.put_line(fnd_file.output,'Processing KFFs...');
  fnd_file.put_line(fnd_file.output,' ');

  /* Process the KFFs */
  p_process_kffs;

  fnd_file.put_line(fnd_file.output,'KFFs processed!');
  fnd_file.put_line(fnd_file.output,' ');

  /* Set the completion status*/
  IF v_set_completion_status_flag != 'S' THEN
    v_bool := fnd_concurrent.set_completion_status(v_set_completion_status_flag,v_set_completion_status_text);
  END IF;

  fnd_file.put_line(fnd_file.output,'''OD: PO Vendor Inbound'' end time is '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));

EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in main: '||SQLERRM);
    v_bool := fnd_concurrent.set_completion_status('ERROR','Error in main, see log file for details. '||SQLERRM);
END xx_po_vendor_inbound_proc;
/