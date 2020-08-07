CREATE OR REPLACE PROCEDURE xx_po_employee_vendor_proc (p_person_id IN NUMBER,
                                                        x_vendor_id IN OUT NUMBER,
                                                        x_vendor_site_id IN OUT NUMBER) AS
  /**********************************************************************************
   NAME:       xx_po_employee_vendor_proc
   PURPOSE:    This procedure creates employe vendors and banks when they do not
               already exist.

   REVISIONS:
  -- Version Date        Author                               Description
  -- ------- ----------- ----------------------               ---------------------
  -- 1.0     26-JUL-2007 Greg Dill, Providge Consulting, LLC. Created base version.
  -- 1.1     09-OCT-2007 Greg Dill, Providge Consulting, LLC. Added org processing.
  -- 1.2     15-OCT-2007 Greg Dill, Providge Consulting, LLC. Changed org processing to use xx_fin_country_defaults_pkg.
  -- 1.3     22-OCT-2007 Greg Dill, Providge Consulting, LLC. Changes for Defect ID 2488.
  -- 1.4     20-NOV-2007 Sandeep Pandhare                     Changes for Defect ID 2564.
  -- 1.5     11-DEC-2007 Greg Dill, Providge Consulting, LLC. Changes for Defect ID 2564.
  -- 1.6     21-FEB-2008 Sandeep Pandhare                     Changes for Defect ID 4824.
  -- 1.7     05-MAY-2008 Greg Dill, Providge Consulting, LLC. Changes for Defect ID 6627.
  --                                                          Added p_initialize and calls to it.
  -- 1.8      23-SEP-2008   Sandeep Pandhare        Defect 11307 - Added log statements for Extensity 11307 |
  -- 1.9      16-OCT-2008   Sandeep Pandhare        Defect 11998 - Modify Bank Account check criteria, removed log statements |
  -- 1.10     21-OCT-2008   Sandeep Pandhare        Defect 12044 - Set Terms to DUE IMMEDIATE |
  -- 1.11     28-OCT-2008   Sandeep Pandhare        Defect 11998 - Payment Method |
  -- 1.12     28-OCT-2008   Sandeep Pandhare        Defect 12216 - Bank Branch Name prefix 'FED DIRECTORY-'.  |
  -- 1.13    03-JUL-2009  Peter Marco               Defect 437   -  Employee "Supplier site ID" in
  --                                                             the supplier file is not maching with the
  --                                                             "Supplier match id"
  -- 1.14      07-JUN-2013     Darshini Gangadhar     Modified for R12 Upgrade Retrofit                                |
  -- 1.15      17-NOV-2015     Harvinder Rakhra       Retrofit R12.2                                                   |
  -- 1.16      07-SEP-2016     Avinash Baddam         R12.2 Retrofit after the patch                                   | 
 **********************************************************************************/

  /* Define constants */
  c_no     CONSTANT VARCHAR2(1) := 'N';
  c_org_id CONSTANT NUMBER := fnd_profile.value('ORG_ID');
  c_when   CONSTANT DATE := SYSDATE;
  c_who    CONSTANT fnd_user.user_id%TYPE := fnd_load_util.owner_id('INTERFACE');
  c_yes    CONSTANT VARCHAR2(1) := 'Y';

  /* Define variables for initialization */
  v_accts_pay_ccid                    NUMBER;
  v_address_style                     VARCHAR2(255);
  v_allow_awt_flag                    VARCHAR2(255);
  v_allow_sub_receipts_flag           VARCHAR2(255);
  v_allow_unord_receipts_flag         VARCHAR2(255);
  v_always_take_disc_flag             VARCHAR2(1);
  v_amount_includes_tax_flag          VARCHAR2(255);
  v_amount_includes_tax_override      VARCHAR2(255);
  v_ap_inst_flag                      VARCHAR2(255);
  v_ap_tax_rounding_rule              VARCHAR2(255);
  v_auto_tax_calc_flag                VARCHAR2(255);
  v_auto_tax_calc_override            VARCHAR2(255);
  v_bank_charge_bearer                VARCHAR2(255);
  v_base_currency_code                VARCHAR2(255);
  v_bill_to_location_code             VARCHAR2(255);
  v_bill_to_location_id               NUMBER;
  v_chart_of_accounts_id              NUMBER;
  v_days_early_receipt_allowed        NUMBER;
  v_days_late_receipt_allowed         NUMBER;
  v_default_awt_group_id              NUMBER;
  v_default_awt_group_name            VARCHAR2(255);
  v_default_country_code              VARCHAR2(255);
  v_default_country_disp              VARCHAR2(255);
  v_distribution_set_id               NUMBER;
  v_enforce_ship_to_loc_code          VARCHAR2(255);
  v_enforce_ship_to_loc_disp          VARCHAR2(255);
  v_exclusive_payment                 VARCHAR2(255);
  v_fin_match_option                  VARCHAR2(255);
  v_fin_require_matching              VARCHAR2(255);
  v_fob_lookup_code                   VARCHAR2(255);
  v_fob_lookup_disp                   VARCHAR2(255);
  v_freight_terms_lookup_code         VARCHAR2(255);
  v_freight_terms_lookup_disp         VARCHAR2(255);
  v_future_dated_payment_ccid         NUMBER;
  v_home_country_code                 VARCHAR2(255);
  v_inspection_required_flag          VARCHAR2(255);
  v_inventory_organization_id         NUMBER;
  v_invoice_currency_code             VARCHAR2(255);
  v_manual_vendor_num_type            VARCHAR2(255);
  v_org_id                            NUMBER;
  v_pay_date_basis_disp               VARCHAR2(255);
  v_pay_date_basis_lookup_code        VARCHAR2(255);
  v_payment_currency_code             VARCHAR2(255);
  v_payment_method_disp               VARCHAR2(255);
  v_payment_method_lookup_code        VARCHAR2(255);
  v_po_create_dm_flag                 VARCHAR2(255);
  v_po_inst_flag                      VARCHAR2(255);
  v_prepay_code_combination_id        NUMBER;
  v_qty_rcv_exception_code            VARCHAR2(255);
  v_qty_rcv_exception_disp            VARCHAR2(255);
  v_qty_rcv_tolerance                 NUMBER;
  v_receipt_days_exception_code       VARCHAR2(255);
  v_receipt_days_exception_disp       VARCHAR2(255);
  v_receipt_required_flag             VARCHAR2(255);
  v_receiving_routing_id              NUMBER;
  v_receiving_routing_name            VARCHAR2(255);
  v_rfq_only_site_flag                VARCHAR2(255);
  v_set_of_books_id                   NUMBER;
  v_ship_to_location_code             VARCHAR2(255);
  v_ship_to_location_id               NUMBER;
  v_ship_via_disp                     VARCHAR2(255);
  v_ship_via_lookup_code              VARCHAR2(255);
  v_short_name                        VARCHAR2(255);
  v_sys_auto_calc_int_flag            VARCHAR2(255);
  v_sys_require_matching              VARCHAR2(255);
  v_sysdate                           DATE;
  v_terms_date_basis                  VARCHAR2(255);
  v_terms_date_basis_disp             VARCHAR2(255);
  v_terms_disp                        VARCHAR2(255);
  v_terms_id                          NUMBER;
  v_terms_id_default                  NUMBER;    -- Defect 12044
  v_use_bank_charge_flag              VARCHAR2(255);
  v_user_defined_vendor_num_code      VARCHAR2(255);
  v_vat_code                          VARCHAR2(255);
  v_vendor_auto_int_default           VARCHAR2(255);
  v_vendor_pay_group_disp             VARCHAR2(255);
  v_vendor_pay_group_lookup_code      VARCHAR2(255);
  v_create_awt_dists_type             VARCHAR2(255); --Added by Darshini(v1.14) for R12 Upgrade Retrofit

  /* Define variables */
  v_address1                   ap_supplier_sites_int.address_line1%TYPE;
  v_address2                   ap_supplier_sites_int.address_line2%TYPE;
  v_address3                   ap_supplier_sites_int.address_line3%TYPE;
  v_bank_account_id            ap_bank_accounts.bank_account_id%TYPE;
  v_bank_account_num           xx_hr_employee_banks.bank_account_num%TYPE;
  v_bank_branch_id             ap_bank_branches.bank_branch_id%TYPE;
  v_bank_branch_name           xx_hr_employee_banks.bank_branch_name%TYPE;
  v_bank_name                  xx_hr_employee_banks.bank_name%TYPE;
  v_bank_num                   xx_hr_employee_banks.bank_num%TYPE;
  v_city                       ap_supplier_sites_int.city%TYPE;
  v_country                    ap_supplier_sites_int.country%TYPE;
  v_email_address              ap_supplier_sites_int.email_address%TYPE;
  v_employee_number            per_all_people_f.employee_number%TYPE;
  v_exclusive_payment_flag     ap_supplier_sites_int.exclusive_payment_flag%TYPE;
  v_full_name                  per_all_people_f.full_name%TYPE;
  v_num_1099                   per_all_people_f.national_identifier%TYPE;
  v_org_switch                 hr_operating_units.organization_id%TYPE;
  v_pay_group_lookup_code      ap_supplier_sites_int.pay_group_lookup_code%TYPE;
  v_rowid                      ROWID;
  v_state                      ap_supplier_sites_int.state%TYPE;
  v_vendor_name                po_vendors.vendor_name%TYPE;
  v_vendor_number              po_vendors.segment1%TYPE;
  v_vendor_site_code           ap_supplier_sites_int.vendor_site_code%TYPE;
  v_zip                        ap_supplier_sites_int.zip%TYPE;
  l_ext_bank_acct_rec          iby_ext_bankacct_pub.extbankacct_rec_type;
-- defect 2564
  v_bank_account_name          VARCHAR2(255);
  
  -- Added by Darshini(v1.14) for R12 Upgrade Retrofit
  v_bank_id                    iby_ext_bank_accounts.bank_id%TYPE;
  l_msg_count                   NUMBER := NULL;
  l_msg_data                    VARCHAR2 (3000) := NULL;
  l_error_message               VARCHAR2 (2000);
  l_return_status               VARCHAR2 (100);
  lr_extbank_recbranch_rec      iby_ext_bankacct_pub.extbankbranch_rec_type;
  lr_result_rec                 iby_fndcpt_common_pub.result_rec_type;
  -- end of addition

/* Define procedure to check if the employee vendor already exists */
PROCEDURE p_vendor_check IS
  /* Define vendor cursor */
  CURSOR vend_cur IS
    SELECT aps.vendor_id,
           assa.vendor_site_id
    -- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
	--FROM po_vendor_sites_all pvsa,
         --po_vendors pv
	FROM  ap_suppliers aps,
	      ap_supplier_sites_all assa
    -- end of addition
    WHERE aps.employee_id = p_person_id
    AND   assa.vendor_id = aps.vendor_id
    AND   assa.pay_site_flag = c_yes
    AND   (assa.inactive_date IS NULL OR assa.inactive_date >= c_when);

BEGIN
  /* Only open the vendor cursor if it is not already open */
  IF NOT vend_cur%ISOPEN THEN
    OPEN vend_cur;
  END IF;

  /* Populate variables using cursor fetch */
  FETCH vend_cur INTO x_vendor_id,
                      x_vendor_site_id;

  CLOSE vend_cur;

EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in xx_po_employee_vendor_proc.p_vendor_check '||SQLERRM);
END p_vendor_check;

/* Define procedure to create the employee bank, if bank details exist */
PROCEDURE p_create_bank IS
  /* Define bank details cursor */
  CURSOR bdet_cur IS
    SELECT papf.employee_number,
           papf.full_name,
           xheb.bank_num,
           upper(xheb.bank_name),  -- defect 2564
           xheb.bank_account_num,
           'FED DIRECTORY-'||xheb.bank_num,     -- Defect 12216 'ACH-'||xheb.bank_num,
           upper(first_name||' '||last_name)||' - ' || papf.employee_number  --defect 2564
    FROM   xx_hr_employee_banks xheb,
           per_all_people_f papf
    WHERE  papf.person_id = p_person_id
	-- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
    --AND    xheb.legacy_employee_id = papf.employee_number
	AND    to_char(xheb.legacy_employee_id) = papf.employee_number
	-- end of addition
    AND    trunc(sysdate) between papf.effective_start_date and papf.effective_end_date; -- Added per defect 437

  /* Define bank account cursor */
  CURSOR bacc_cur IS
  -- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
    /*SELECT bank_account_id
    FROM ap_bank_accounts_all
    WHERE bank_branch_id = v_bank_branch_id
    AND   bank_account_num = v_bank_account_num;*/
	SELECT ext_bank_account_id
    FROM  iby_ext_bank_accounts
    WHERE branch_id = v_bank_branch_id
    AND   bank_account_num = v_bank_account_num;
 -- end of sddition
BEGIN
  /* Only open the bank details cursor if it is not already open */
  IF NOT bdet_cur%ISOPEN THEN
    OPEN bdet_cur;
  END IF;

  /* Populate variables using cursor fetch */
  FETCH bdet_cur INTO v_employee_number,
                      v_full_name,
                      v_bank_num,
                      v_bank_name,
                      v_bank_account_num,
                      v_bank_branch_name,
                      v_bank_account_name;   -- defect 2564

  CLOSE bdet_cur;
  
  	  -- added by Darshini(v1.14) for R12 Upgrade Retrofit
	  SELECT bank_party_id
      INTO v_bank_id
      FROM iby_ext_bank_branches_v
      WHERE branch_number = v_bank_num
      AND bank_branch_name = v_bank_branch_name ;
	  --end of addition
  
  /* If bank details are available, create the bank branch and bank account if they do not already exist */
  IF v_bank_num IS NOT NULL AND v_bank_account_num IS NOT NULL THEN
    BEGIN
      /* Does the bank branch already exist? */
	   -- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
      /*SELECT bank_branch_id
      INTO v_bank_branch_id
      FROM ap_bank_branches
      WHERE bank_num = v_bank_num
      AND bank_branch_name = v_bank_branch_name ;  -- Defect 12216
--      AND   bank_branch_type = 'ABA';  Defect 11998*/
      SELECT branch_party_id
      INTO v_bank_branch_id
      FROM iby_ext_bank_branches_v
      WHERE branch_number = v_bank_num
      AND bank_branch_name = v_bank_branch_name ;
     -- end of addition

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        /* The bank branch does not already exist, create it */
/*        fnd_file.put_line(fnd_file.log,'xx_po_employee_vendor_proc: Insert Bank Branch = '
                          || v_bank_name || ' '
                          || v_bank_branch_name || ' '
                          || v_bank_num || ' '
                          || v_bank_name || ' '
                          || v_bank_branch_id || ' '
                          );          */
        -- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
        /*arp_bank_pkg.insert_bank_branch(p_bank_name => v_bank_name,
                                        p_bank_branch_name => v_bank_branch_name,
                                        p_bank_number => v_bank_num,
                                        p_bank_num => v_bank_num,
                                        p_bank_branch_type => 'ABA',
                                        p_institution_type => 'BANK',
                                        p_end_date  => NULL,
                                        p_eft_user_number => NULL,
                                        p_eft_swift_code => NULL,
                                        p_edi_id_number => NULL,
                                        p_ece_tp_location_code => NULL,
                                        p_description => v_bank_name||' - '||v_bank_num,
                                        p_bank_branch_id => v_bank_branch_id);*/
		
								   
			lr_extbank_recbranch_rec.bank_party_id := v_bank_id;
			lr_extbank_recbranch_rec.branch_name   := v_bank_branch_name;
		    lr_extbank_recbranch_rec.branch_type   := 'ABA';
			lr_extbank_recbranch_rec.description   := v_bank_name||' - '||v_bank_num;
			
            iby_ext_bankacct_pub.create_ext_bank_branch
                                  (p_api_version           => 1.0
                                  ,p_init_msg_list         => fnd_api.g_true
                                  ,p_ext_bank_branch_rec   => lr_extbank_recbranch_rec
                                  ,x_branch_id             => v_bank_branch_id
                                  ,x_return_status         => l_return_status
                                  ,x_msg_count             => l_msg_count
                                  ,x_msg_data              => l_msg_data
                                  ,x_response              => lr_result_rec
                                  );
                            	   
        -- end of addition
    END;

    /* Only open the bank account cursor if it is not already open */
    IF NOT bacc_cur%ISOPEN THEN
      OPEN bacc_cur;
    END IF;

    /* Populate variables using cursor fetch */
    FETCH bacc_cur INTO v_bank_account_id;

    CLOSE bacc_cur;
	
    /* If the bank account does not already exist, create it */
    IF v_bank_account_id IS NULL THEN
      /* Create the bank account */
/*        fnd_file.put_line(fnd_file.log,'xx_po_employee_vendor_proc: Insert Bank Account = '
                          || v_bank_account_name || ' '
                          || v_bank_account_num || ' '
                          || v_bank_account_id || ' '
                          || v_bank_branch_id || ' '
                          );       */
       -- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
      /*arp_bank_pkg.insert_bank_account(p_bank_account_name => v_bank_account_name,  -- defect 2564
                                       p_bank_account_num => v_bank_account_num,
                                       p_bank_branch_id => v_bank_branch_id,
                                       p_currency_code => 'USD',
                                       p_inactive_date => NULL,
                                       p_bank_account_type => 'SUPPLIER',
                                       p_bank_account_id => v_bank_account_id);

      -- Unfortunately arp_bank_pkg creates the bank account as CUSTOMER, we need it to be SUPPLIER 
      UPDATE ap_bank_accounts_all
      SET account_type = 'SUPPLIER'
      ,bank_account_type = 'SUPPLIER'  -- defect 2564
      ,bank_account_name_alt = v_employee_number  -- defect 2564
      ,description = v_bank_name || ' - ' || v_bank_branch_name  -- defect 2564
      WHERE bank_account_id = v_bank_account_id;*/

	  
	  l_ext_bank_acct_rec.bank_account_name := v_bank_account_name;
	  l_ext_bank_acct_rec.bank_account_num := v_bank_account_num;
	  l_ext_bank_acct_rec.bank_id := v_bank_id;
	  l_ext_bank_acct_rec.branch_id := v_bank_branch_id;
	  l_ext_bank_acct_rec.country_code := 'US';
	  l_ext_bank_acct_rec.currency := 'USD';
	  

	  IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT
                             (p_api_version            => 1.0,
                              p_init_msg_list          => fnd_api.g_true,
                              p_ext_bank_acct_rec      => l_ext_bank_acct_rec,
                              p_association_level      => 'S',
                              p_supplier_site_id       => NULL,
                              p_party_site_id          => NULL,
                              p_org_id                 => NULL,
                              p_org_type               => NULL,
                              x_acct_id                => v_bank_account_id,
							  x_return_status          => l_return_status,
							  x_msg_count              => l_msg_count,
							  x_msg_data               => l_msg_data,
                              x_response               => lr_result_rec);
	 				 
	  UPDATE iby_ext_bank_accounts
      SET bank_account_type = 'SUPPLIER'  -- defect 2564
      ,bank_account_name_alt = v_employee_number  -- defect 2564
      ,description = v_bank_name || ' - ' || v_bank_branch_name  -- defect 2564
      WHERE ext_bank_account_id = v_bank_account_id;
 -- end of addition
    END IF;
  END IF;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in xx_po_employee_vendor_proc.p_create_bank '||SQLERRM);
END p_create_bank;

/* Define procedure to initialize the default vendor values */
PROCEDURE p_initialize IS
BEGIN
  /* Initialize the required default values */
  -- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
  /*ap_apxvdmvd_pkg.initialize(x_user_defined_vendor_num_code => v_user_defined_vendor_num_code,
                             x_manual_vendor_num_type       => v_manual_vendor_num_type,
                             x_rfq_only_site_flag           => v_rfq_only_site_flag,
                             x_ship_to_location_id          => v_ship_to_location_id,
                             x_ship_to_location_code        => v_ship_to_location_code,
                             x_bill_to_location_id          => v_bill_to_location_id,
                             x_bill_to_location_code        => v_bill_to_location_code,
                             x_fob_lookup_code              => v_fob_lookup_code,
                             x_freight_terms_lookup_code    => v_freight_terms_lookup_code,
                             x_terms_id                     => v_terms_id_default,  -- v_terms_id,  -- Defect 12044
                             x_terms_disp                   => v_terms_disp,
                             x_always_take_disc_flag        => v_always_take_disc_flag,
                             x_invoice_currency_code        => v_invoice_currency_code,
                             x_org_id                       => v_org_id,
                             x_set_of_books_id              => v_set_of_books_id,
                             x_short_name                   => v_short_name,
                             x_payment_currency_code        => v_payment_currency_code,
                             x_accts_pay_ccid               => v_accts_pay_ccid,
                             x_future_dated_payment_ccid    => v_future_dated_payment_ccid,
                             x_prepay_code_combination_id   => v_prepay_code_combination_id,
                             x_vendor_pay_group_lookup_code => v_vendor_pay_group_lookup_code,
                             x_sys_auto_calc_int_flag       => v_sys_auto_calc_int_flag,
                             x_terms_date_basis             => v_terms_date_basis,
                             x_terms_date_basis_disp        => v_terms_date_basis_disp,
                             x_chart_of_accounts_id         => v_chart_of_accounts_id,
                             x_fob_lookup_disp              => v_fob_lookup_disp,
                             x_freight_terms_lookup_disp    => v_freight_terms_lookup_disp,
                             x_vendor_pay_group_disp        => v_vendor_pay_group_disp,
                             x_fin_require_matching         => v_fin_require_matching,
                             x_sys_require_matching         => v_sys_require_matching,
                             x_fin_match_option             => v_fin_match_option,
                             x_po_create_dm_flag            => v_po_create_dm_flag,
                             x_exclusive_payment            => v_exclusive_payment,
                             x_vendor_auto_int_default      => v_vendor_auto_int_default,
                             x_inventory_organization_id    => v_inventory_organization_id,
                             x_ship_via_lookup_code         => v_ship_via_lookup_code,
                             x_ship_via_disp                => v_ship_via_disp,
                             x_sysdate                      => v_sysdate,
                             x_enforce_ship_to_loc_code     => v_enforce_ship_to_loc_code,
                             x_receiving_routing_id         => v_receiving_routing_id,
                             x_qty_rcv_tolerance            => v_qty_rcv_tolerance,
                             x_qty_rcv_exception_code       => v_qty_rcv_exception_code,
                             x_days_early_receipt_allowed   => v_days_early_receipt_allowed,
                             x_days_late_receipt_allowed    => v_days_late_receipt_allowed,
                             x_allow_sub_receipts_flag      => v_allow_sub_receipts_flag,
                             x_allow_unord_receipts_flag    => v_allow_unord_receipts_flag,
                             x_receipt_days_exception_code  => v_receipt_days_exception_code,
                             x_enforce_ship_to_loc_disp     => v_enforce_ship_to_loc_disp,
                             x_qty_rcv_exception_disp       => v_qty_rcv_exception_disp,
                             x_receipt_days_exception_disp  => v_receipt_days_exception_disp,
                             x_receipt_required_flag        => v_receipt_required_flag,
                             x_inspection_required_flag     => v_inspection_required_flag,
                             x_payment_method_lookup_code   => v_payment_method_lookup_code,
                             x_payment_method_disp          => v_payment_method_disp,
                             x_pay_date_basis_lookup_code   => v_pay_date_basis_lookup_code,
                             x_pay_date_basis_disp          => v_pay_date_basis_disp,
                             x_receiving_routing_name       => v_receiving_routing_name,
                             x_ap_inst_flag                 => v_ap_inst_flag,
                             x_po_inst_flag                 => v_po_inst_flag,
                             x_home_country_code            => v_home_country_code,
                             x_default_country_code         => v_default_country_code,
                             x_default_country_disp         => v_default_country_disp,
                             x_default_awt_group_id         => v_default_awt_group_id,
                             x_default_awt_group_name       => v_default_awt_group_name,
                             x_allow_awt_flag               => v_allow_awt_flag,
                             x_base_currency_code           => v_base_currency_code,
                             x_address_style                => v_address_style,
                             x_auto_tax_calc_flag           => v_auto_tax_calc_flag,
                             x_auto_tax_calc_override       => v_auto_tax_calc_override,
                             x_amount_includes_tax_flag     => v_amount_includes_tax_flag,
                             x_amount_includes_tax_override => v_amount_includes_tax_override,
                             x_ap_tax_rounding_rule         => v_ap_tax_rounding_rule,
                             x_vat_code                     => v_vat_code,
                             x_use_bank_charge_flag         => v_use_bank_charge_flag,
                             x_bank_charge_bearer           => v_bank_charge_bearer,
							 x_employee_id                  => v_employee_number,
                             x_calling_sequence             => NULL);*/
							 
    ap_apxvdmvd_pkg.initialize(
        x_user_defined_vendor_num_code	 => v_user_defined_vendor_num_code,
	    x_manual_vendor_num_type	     => v_manual_vendor_num_type,
	    x_rfq_only_site_flag		     => v_rfq_only_site_flag,
	    x_ship_to_location_id		     => v_ship_to_location_id,
	    x_ship_to_location_code		     => v_ship_to_location_code,
	    x_bill_to_location_id		     => v_bill_to_location_id,
	    x_bill_to_location_code		     => v_bill_to_location_code,
	    x_fob_lookup_code 			     => v_fob_lookup_code,
	    x_freight_terms_lookup_code		 => v_freight_terms_lookup_code,
	    x_terms_id				         => v_terms_id_default,  -- v_terms_id,  -- Defect 12044
	    x_terms_disp			         => v_terms_disp,
	    x_always_take_disc_flag	         => v_always_take_disc_flag,
	    x_invoice_currency_code	         => v_invoice_currency_code,
        x_org_id			             => v_org_id,
	    x_set_of_books_id		         => v_set_of_books_id,
        x_short_name		             => v_short_name,
	    x_payment_currency_code	         => v_payment_currency_code,
	    x_accts_pay_ccid		         => v_accts_pay_ccid,
	    x_future_dated_payment_ccid		 => v_future_dated_payment_ccid,
	    x_prepay_code_combination_id	 => v_prepay_code_combination_id,
	    x_vendor_pay_group_lookup_code	 => v_vendor_pay_group_lookup_code,
	    x_sys_auto_calc_int_flag		 => v_sys_auto_calc_int_flag,
	    x_terms_date_basis			     => v_terms_date_basis,
	    x_terms_date_basis_disp		     => v_terms_date_basis_disp,
	    x_chart_of_accounts_id		     => v_chart_of_accounts_id,
	    x_fob_lookup_disp			     => v_fob_lookup_disp,
	    x_freight_terms_lookup_disp	     => v_freight_terms_lookup_disp,
	    x_vendor_pay_group_disp		     => v_vendor_pay_group_disp,
	    x_fin_require_matching		     => v_fin_require_matching,
	    x_sys_require_matching		     => v_sys_require_matching,
	    x_fin_match_option			     => v_fin_match_option,
	    x_po_create_dm_flag			     => v_po_create_dm_flag,
	    x_exclusive_payment			     => v_exclusive_payment,
	    x_vendor_auto_int_default	     => v_vendor_auto_int_default,
	    x_inventory_organization_id	     => v_inventory_organization_id,
	    x_ship_via_lookup_code		     => v_ship_via_lookup_code,
	    x_ship_via_disp			         => v_ship_via_disp,
	    x_sysdate				         => v_sysdate,
	    x_enforce_ship_to_loc_code		 => v_enforce_ship_to_loc_code,
	    x_receiving_routing_id		     => v_receiving_routing_id,
	    x_qty_rcv_tolerance			     => v_qty_rcv_tolerance,
	    x_qty_rcv_exception_code		 => v_qty_rcv_exception_code,
	    x_days_early_receipt_allowed	 => v_days_early_receipt_allowed,
	    x_days_late_receipt_allowed		 => v_days_late_receipt_allowed,
	    x_allow_sub_receipts_flag		 => v_allow_sub_receipts_flag,
	    x_allow_unord_receipts_flag		 => v_allow_unord_receipts_flag,
	    x_receipt_days_exception_code	 => v_receipt_days_exception_code,
	    x_enforce_ship_to_loc_disp		 => v_enforce_ship_to_loc_disp,
	    x_qty_rcv_exception_disp		 => v_qty_rcv_exception_disp,
	    x_receipt_days_exception_disp	 => v_receipt_days_exception_disp,
	    x_receipt_required_flag		     => v_receipt_required_flag,
	    x_inspection_required_flag		 => v_inspection_required_flag,
	    x_payment_method_lookup_code	 => v_payment_method_lookup_code,
        x_payment_method_disp		     => v_payment_method_disp,
	    x_pay_date_basis_lookup_code	 => v_pay_date_basis_lookup_code,
	    x_pay_date_basis_disp		     => v_pay_date_basis_disp,
	    x_receiving_routing_name		 => v_receiving_routing_name,
	    x_AP_inst_flag			         => v_ap_inst_flag,
	    x_PO_inst_flag			         => v_po_inst_flag,
   	    x_home_country_code 	         => v_home_country_code,
	    x_default_country_code 	         => v_default_country_code,
	    x_default_country_disp 	         => v_default_country_disp,
	    x_default_awt_group_id	         => v_default_awt_group_id,
	    x_default_awt_group_name         => v_default_awt_group_name,
	    x_allow_awt_flag			     => v_allow_awt_flag,
    	x_create_awt_dists_type          => v_create_awt_dists_type,
	    x_base_currency_code		     => v_base_currency_code,
	    x_address_style			         => v_address_style,
	    x_use_bank_charge_flag           => v_use_bank_charge_flag,
        x_bank_charge_bearer             => v_bank_charge_bearer,
        x_employee_id                    => v_employee_number,
	    X_calling_sequence		         => NULL);
  -- end of addition
EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in xx_po_employee_vendor_proc.p_initialize '||SQLERRM);
END p_initialize;

/* Define procedure to insert the vendors into the API tables */
PROCEDURE p_insert_vendors IS
  /* Define vendor cursor */
  CURSOR vend_cur IS
    SELECT UPPER(first_name||' '||last_name),
           email_address,
           employee_number,
           national_identifier
    FROM per_all_people_f
    WHERE person_id = p_person_id
    AND  trunc(sysdate) between effective_start_date and effective_end_date; -- Added per defect 437;

  /* Define vendor address cursor */
  CURSOR vadd_cur IS
    SELECT address_line1,
           address_line2,
           address_line3,
           town_or_city,
           region_2,
           postal_code,
           country
    FROM per_addresses
    WHERE person_id = p_person_id
    AND   primary_flag = c_yes;

BEGIN
  /* Only open the vendor cursor if it is not already open */
  IF NOT vend_cur%ISOPEN THEN
    OPEN vend_cur;
  END IF;


    /* Terms are always immediate for employee vendors */
    -- Defect 12044 moved outside loop
    BEGIN
      SELECT term_id
      INTO v_terms_id
      FROM ap_terms_tl
      WHERE name = '00';

    EXCEPTION
      /* If no result was returned, use the value returned from financials_system_parameters */
      WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Error in xx_po_employee_vendor_proc: get TERMS_ID for DUE_IMMEDIATE '||SQLERRM);
    END;



  LOOP
    /* Populate variables using cursor fetch */
    FETCH vend_cur INTO v_vendor_name,
                        v_email_address,
                        v_employee_number,
                        v_num_1099;

    /* Keep fetching until no more records are found */
    EXIT WHEN NOT vend_cur%FOUND;

    /* Initialize the required default values */
    p_initialize;

   -- commented by Darshini(v1.14) for R12 Upgrade Retrofit
   /* Set the payment method if there is a bank involved */
   /* IF v_bank_account_id IS NULL THEN
      NULL;
    ELSE
      v_payment_method_lookup_code := 'EFT';
    END IF;

    /* Defect 4824 Set the Payment Group based on Payment Method 
    IF v_payment_method_lookup_code = 'EFT' THEN
      v_vendor_pay_group_lookup_code := 'US_OD_ACH';
      v_pay_group_lookup_code := 'US_OD_ACH';
    END IF;
    IF v_payment_method_lookup_code = 'CHECK' THEN
      v_vendor_pay_group_lookup_code := 'US_OD_EXP_NON_DISC';
      v_pay_group_lookup_code := 'US_OD_EXP_NON_DISC';
    END IF;*/




    Begin
    /* Create the employee vendor */
    fnd_file.put_line(fnd_file.log,'xx_po_employee_vendor_proc.create vendor  '|| v_vendor_name || ' ' || v_terms_id);
	-- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
    /*ap_vendors_pkg.insert_row(x_rowid                        => v_rowid,
                              x_vendor_id                    => x_vendor_id,
                              x_last_update_date             => c_when,
                              x_last_updated_by              => c_who,
                              x_vendor_name                  => v_vendor_name,
                              x_segment1                     => v_vendor_number,
                              x_summary_flag                 => c_no,
                              x_enabled_flag                 => c_yes,
                              x_last_update_login            => NULL,
                              x_creation_date                => c_when,
                              x_created_by                   => c_who,
                              x_employee_id                  => p_person_id,
                              x_validation_number            => NULL,
                              x_vendor_type_lookup_code      => 'EMPLOYEE',
                              x_customer_num                 => NULL,
                              x_one_time_flag                => c_no,
                              x_parent_vendor_id             => NULL,
                              x_min_order_amount             => NULL,
                              x_ship_to_location_id          => v_ship_to_location_id,
                              x_bill_to_location_id          => v_bill_to_location_id,
                              x_ship_via_lookup_code         => v_ship_via_lookup_code,
                              x_freight_terms_lookup_code    => v_freight_terms_lookup_code,
                              x_fob_lookup_code              => v_fob_lookup_code,
                              x_terms_id                     => v_terms_id,
                              x_set_of_books_id              => v_set_of_books_id,
                              x_always_take_disc_flag        => v_always_take_disc_flag,
                              x_pay_date_basis_lookup_code   => v_pay_date_basis_lookup_code,
                              x_pay_group_lookup_code        => v_vendor_pay_group_lookup_code,
                              x_payment_priority             => 99,
                              x_invoice_currency_code        => v_invoice_currency_code,
                              x_payment_currency_code        => v_payment_currency_code,
                              x_invoice_amount_limit         => NULL,
                              x_hold_all_payments_flag       => c_no,
                              x_hold_future_payments_flag    => c_no,
                              x_hold_reason                  => NULL,
                              x_distribution_set_id          => NULL,
                              x_accts_pay_ccid               => NULL,  -- always multiorg
                              x_future_dated_payment_ccid    => NULL,
                              x_prepay_ccid                  => NULL,  -- always multiorg
                              x_num_1099                     => v_num_1099, -- should validate
                              x_type_1099                    => NULL,
                              x_withholding_stat_lookup_code => NULL,
                              x_withholding_start_date       => NULL,
                              x_org_type_lookup_code         => NULL,
                              --x_vat_code                     => v_vat_code,
                              x_start_date_active            => c_when,
                              x_end_date_active              => NULL,
                              x_qty_rcv_tolerance            => v_qty_rcv_tolerance,
                              x_minority_group_lookup_code   => NULL,--p_minority_group_lookup_code,
                              --x_payment_method_lookup_code   => v_payment_method_lookup_code,
                              x_bank_account_name            => NULL,
                              x_bank_account_num             => NULL,
                              x_bank_num                     => NULL,
                              x_bank_account_type            => NULL,
                              x_women_owned_flag             => c_no,
                              x_small_business_flag          => c_no,
                              x_standard_industry_class      => NULL,
                              x_attribute_category           => NULL,
                              x_attribute1                   => NULL,
                              x_attribute2                   => NULL,
                              x_attribute3                   => NULL,
                              x_attribute4                   => NULL,
                              x_attribute5                   => NULL,
                              x_hold_flag                    => c_no,
                              x_purchasing_hold_reason       => NULL,
                              x_hold_by                      => NULL,
                              x_hold_date                    => NULL,
                              x_terms_date_basis             => v_terms_date_basis,
                              x_price_tolerance              => NULL,
                              x_attribute10                  => NULL,
                              x_attribute11                  => NULL,
                              x_attribute12                  => NULL,
                              x_attribute13                  => NULL,
                              x_attribute14                  => NULL,
                              x_attribute15                  => NULL,
                              x_attribute6                   => NULL,
                              x_attribute7                   => NULL,
                              x_attribute8                   => NULL,
                              x_attribute9                   => NULL,
                              x_days_early_receipt_allowed   => v_days_early_receipt_allowed,
                              x_days_late_receipt_allowed    => v_days_late_receipt_allowed,
                              x_enforce_ship_to_loc_code     => v_enforce_ship_to_loc_code,
                              --x_exclusive_payment_flag       => v_exclusive_payment,
                              x_federal_reportable_flag      => c_no,
                              x_hold_unmatched_invoices_flag => NULL,
                              x_match_option                 => v_fin_match_option,
                              x_create_debit_memo_flag       => v_po_create_dm_flag,
                              x_inspection_required_flag     => v_inspection_required_flag,
                              x_receipt_required_flag        => v_receipt_required_flag,
                              x_receiving_routing_id         => v_receiving_routing_id,
                              x_state_reportable_flag        => NULL,
                              x_tax_verification_date        => NULL,
                              x_auto_calculate_interest_flag => v_sys_auto_calc_int_flag,
                              x_name_control                 => NULL,
                              x_allow_subst_receipts_flag    => v_allow_sub_receipts_flag,
                              x_allow_unord_receipts_flag    => v_allow_unord_receipts_flag,
                              x_receipt_days_exception_code  => v_receipt_days_exception_code,
                              x_qty_rcv_exception_code       => v_qty_rcv_exception_code,
                              --x_offset_tax_flag              => NULL,
                              x_exclude_freight_from_disc    => c_no,
                              x_vat_registration_num         => v_num_1099,
                              x_tax_reporting_name           => NULL,
                              x_awt_group_id                 => NULL,
                              x_check_digits                 => NULL,
                              x_bank_number                  => NULL,
                              x_allow_awt_flag               => v_allow_awt_flag,
                              x_bank_branch_type             => NULL,
                              x_edi_payment_method           => NULL,
                              x_edi_payment_format           => NULL,
                              x_edi_remittance_method        => NULL,
                              x_edi_remittance_instruction   => NULL,
                              x_edi_transaction_handling     => NULL,
                              x_auto_tax_calc_flag           => v_auto_tax_calc_flag,
                              x_auto_tax_calc_override       => v_auto_tax_calc_override,
                              x_amount_includes_tax_flag     => v_amount_includes_tax_flag,
                              x_ap_tax_rounding_rule         => v_ap_tax_rounding_rule,
                              x_vendor_name_alt              => NULL,
                              x_global_attribute_category    => NULL,
                              x_global_attribute1            => NULL,
                              x_global_attribute2            => NULL,
                              x_global_attribute3            => NULL,
                              x_global_attribute4            => NULL,
                              x_global_attribute5            => NULL,
                              x_global_attribute6            => NULL,
                              x_global_attribute7            => NULL,
                              x_global_attribute8            => NULL,
                              x_global_attribute9            => NULL,
                              x_global_attribute10           => NULL,
                              x_global_attribute11           => NULL,
                              x_global_attribute12           => NULL,
                              x_global_attribute13           => NULL,
                              x_global_attribute14           => NULL,
                              x_global_attribute15           => NULL,
                              x_global_attribute16           => NULL,
                              x_global_attribute17           => NULL,
                              x_global_attribute18           => NULL,
                              x_global_attribute19           => NULL,
                              x_global_attribute20           => NULL,
                              x_bank_charge_bearer           => NULL,
							  X_NI_Number                    => NULL,
                              x_calling_sequence             => NULL);*/
    
	 ap_vendors_pkg.insert_row(
	    x_Rowid				               => v_rowid,
		x_Vendor_Id			               => x_vendor_id,
		x_Last_Update_Date	               => c_when,
		x_Last_Updated_By	               => c_who,
		x_Vendor_Name		               => v_vendor_name,
		x_Segment1	                       => v_vendor_number,
		x_Summary_Flag		               => c_no,
		x_Enabled_Flag		               => c_yes,
		x_Last_Update_Login	               => NULL,
		x_Creation_Date		               => c_when,
		x_Created_By		               => c_who,
		x_Employee_Id		               => p_person_id,
		x_Validation_Number	               => NULL,
		x_Vendor_Type_Lookup_Code		   => 'EMPLOYEE',
		x_Customer_Num				       => NULL,
		x_One_Time_Flag				       => c_no,
		x_Parent_Vendor_Id			       => NULL,
		x_Min_Order_Amount			       => NULL,
		x_Terms_Id				           => v_terms_id,
		x_Set_Of_Books_Id		           => v_set_of_books_id,
		x_Always_Take_Disc_Flag	           => v_always_take_disc_flag,
		x_Pay_Date_Basis_Lookup_Code       => v_pay_date_basis_lookup_code,
		x_Pay_Group_Lookup_Code		       => v_vendor_pay_group_lookup_code,
		x_Payment_Priority			       => 99,
		x_Invoice_Currency_Code		       => v_invoice_currency_code,
		x_Payment_Currency_Code		       => v_payment_currency_code,
		x_Invoice_Amount_Limit		       => NULL,
		x_Hold_All_Payments_Flag	       => c_no,
		x_Hold_Future_Payments_Flag	       => c_no,
		x_Hold_Reason			           => NULL,
		x_Num_1099				           => v_num_1099, -- should validate
		x_Type_1099				           => NULL,
		x_withholding_stat_Lookup_Code	   => NULL,
		x_Withholding_Start_Date		   => NULL,
		x_Org_Type_Lookup_Code			   => NULL,
		x_Start_Date_Active			       => c_when,
		x_End_Date_Active			       => NULL,
		x_Qty_Rcv_Tolerance			       => v_qty_rcv_tolerance,
		x_Minority_Group_Lookup_Code		=> NULL,--p_minority_group_lookup_code,
		x_Bank_Account_Name			        => NULL,
		x_Bank_Account_Num			        => NULL,
		x_Bank_Num				            => NULL,
		x_Bank_Account_Type			        => NULL,
		x_Women_Owned_Flag			        => c_no,
		x_Small_Business_Flag		        => c_no,
		x_Standard_Industry_Class	        => NULL,
		x_Attribute_Category		        => NULL,
		x_Attribute1				        => NULL,
		x_Attribute2				        => NULL,
		x_Attribute3				        => NULL,
		x_Attribute4				        => NULL,
		x_Attribute5				        => NULL,
		x_Hold_Flag				            => c_no,
		x_Purchasing_Hold_Reason	        => NULL,
		x_Hold_By				            => NULL,
		x_Hold_Date				            => NULL,
		x_Terms_Date_Basis			        => v_terms_date_basis,
		x_Price_Tolerance			        => NULL,
		x_Attribute10				        => NULL,
		x_Attribute11				        => NULL,
		x_Attribute12				        => NULL,
		x_Attribute13				        => NULL,
		x_Attribute14				        => NULL,
		x_Attribute15				        => NULL,
		x_Attribute6				        => NULL,
		x_Attribute7				        => NULL,
		x_Attribute8				        => NULL,
		x_Attribute9				        => NULL,
		x_Days_Early_Receipt_Allowed        => v_days_early_receipt_allowed,
		x_Days_Late_Receipt_Allowed		    => v_days_late_receipt_allowed,
		x_Enforce_Ship_To_Loc_Code		    => v_enforce_ship_to_loc_code,
		x_Federal_Reportable_Flag		    => c_no,
		x_Hold_Unmatched_Invoices_Flag	    => NULL,
		x_match_option				        => v_fin_match_option,
		x_create_debit_memo_flag		    => v_po_create_dm_flag,
		x_Inspection_Required_Flag		    => v_inspection_required_flag,
		x_Receipt_Required_Flag			    => v_receipt_required_flag,
		x_Receiving_Routing_Id			    => v_receiving_routing_id,
		x_State_Reportable_Flag			    => NULL,
		x_Tax_Verification_Date			    => NULL,
		x_Auto_Calculate_Interest_Flag	    => v_sys_auto_calc_int_flag,
		x_Name_Control				        => NULL,
		x_Allow_Subst_Receipts_Flag		    => v_allow_sub_receipts_flag,
		x_Allow_Unord_Receipts_Flag		    => v_allow_unord_receipts_flag,
		x_Receipt_Days_Exception_Code	    => v_receipt_days_exception_code,
		x_Qty_Rcv_Exception_Code		    => v_qty_rcv_exception_code,
		x_Exclude_Freight_From_Disc		    => c_no,
		x_Vat_Registration_Num			    => v_num_1099,
		x_Tax_Reporting_Name		        => NULL,
		x_Awt_Group_Id				        => NULL,
        x_Pay_Awt_Group_Id                  => NULL,
		x_Check_Digits				        => NULL,
		x_Bank_Number				        => NULL,
		x_Allow_Awt_Flag			        => v_allow_awt_flag,
		x_Bank_Branch_Type			        => NULL,
		x_Vendor_Name_Alt			        => NULL,
        X_global_attribute_category         => NULL,
        X_global_attribute1                 => NULL,
        X_global_attribute2                 => NULL,
        X_global_attribute3                 => NULL,
        X_global_attribute4                 => NULL,
        X_global_attribute5                 => NULL,
        X_global_attribute6                 => NULL,
        X_global_attribute7                 => NULL,
        X_global_attribute8                 => NULL,
        X_global_attribute9                 => NULL,
        X_global_attribute10                => NULL,
        X_global_attribute11                => NULL,
        X_global_attribute12                => NULL,
        X_global_attribute13                => NULL,
        X_global_attribute14                => NULL,
        X_global_attribute15                => NULL,
        X_global_attribute16                => NULL,
        X_global_attribute17                => NULL,
        X_global_attribute18                => NULL,
        X_global_attribute19                => NULL,
        X_global_attribute20                => NULL,
        X_Bank_Charge_Bearer	            => NULL,
		X_NI_Number				            => NULL,
		X_calling_sequence		            => NULL);
	-- end of addition;
	EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Error in xx_po_employee_vendor_proc.ap_vendors_pkg.insert_row '||SQLERRM);
    End;
--fnd_file.put_line(fnd_file.log,'Debug0: '||v_legacy_vendor_id);
    /* Only open the vendor address cursor if it is not already open */
    IF NOT vadd_cur%ISOPEN THEN
      OPEN vadd_cur;
    END IF;

    LOOP
      /* Populate variables using cursor fetch */
      FETCH vadd_cur INTO v_address1,
                          v_address2,
                          v_address3,
                          v_city,
                          v_state,
                          v_zip,
                          v_country;

      /* Keep fetching until no more records are found */
      EXIT WHEN NOT vadd_cur%FOUND;

      /* Get the org_id for the employee's country */
      IF v_country IN ('CA','US') THEN
        v_org_switch := xx_fin_country_defaults_pkg.f_org_id(v_country);

        /* Set the org context based on the employee's country */
        IF (v_org_switch != -1 AND v_org_switch != c_org_id) THEN
          fnd_client_info.set_org_context(v_org_switch);
--          fnd_file.put_line(fnd_file.log,'xx_po_employee_vendor_proc CALLING P_INITIALIZE(BEFORE) for '|| v_vendor_name || ' ' || v_vendor_site_code || ' '  || v_terms_id );

          /* The org change so re-initialize the required default values */
          p_initialize;

--          fnd_file.put_line(fnd_file.log,'xx_po_employee_vendor_proc CALLING P_INITIALIZE(AFTER) for '|| v_vendor_name || ' ' || v_vendor_site_code || ' '  || v_terms_id );
        END IF;
      ELSE
        NULL;
      END IF;

    /* Defect 11998 */
    /* Set the payment method if there is a bank involved */
    /*IF v_bank_account_id IS NULL THEN
      NULL;
    ELSE
      v_payment_method_lookup_code := 'EFT';
    END IF;
    -- commented by Darshini(v1.14) for R12 Upgrade Retrofit
    /* Defect 4824 Set the Payment Group based on Payment Method 
    IF v_payment_method_lookup_code = 'EFT' THEN
      v_vendor_pay_group_lookup_code := 'US_OD_ACH';
      v_pay_group_lookup_code := 'US_OD_ACH';
    END IF;
    IF v_payment_method_lookup_code = 'CHECK' THEN
      v_vendor_pay_group_lookup_code := 'US_OD_EXP_NON_DISC';
      v_pay_group_lookup_code := 'US_OD_EXP_NON_DISC';
    END IF;*/




      /* Build the site code */
      v_vendor_site_code := 'E'||v_employee_number;

      /* Insert the vendor address into ap_supplier_sites_int */
      Begin
     --insert the vendor site. Use AP_PO_VENDORS_APIS1.INSERT_NEW_VENDOR_SITE or ap_vendor_sites_pkg.insert_row
      fnd_file.put_line(fnd_file.log,'xx_po_employee_vendor_proc.create vendor site for '|| v_vendor_name || ' ' || v_vendor_site_code || ' '  || v_terms_id );
	  -- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
      /*ap_vendor_sites_pkg.insert_row(x_rowid                        =>  v_rowid,
                                     x_vendor_site_id               =>  x_vendor_site_id,
                                     x_last_update_date             =>  c_when,
                                     x_last_updated_by              =>  c_who,
                                     x_vendor_id                    =>  x_vendor_id,
                                     x_vendor_site_code             =>  v_vendor_site_code,
                                     x_last_update_login            =>  NULL,
                                     x_creation_date                =>  c_when,
                                     x_created_by                   =>  c_who,
                                     x_purchasing_site_flag         =>  c_no,
                                     x_rfq_only_site_flag           =>  v_rfq_only_site_flag,
                                     x_pay_site_flag                =>  c_yes,
                                     x_attention_ar_flag            =>  c_no,
                                     x_address_line1                =>  v_address1,
                                     x_address_line2                =>  v_address2,
                                     x_address_line3                =>  v_address3,
                                     x_city                         =>  v_city,
                                     x_state                        =>  v_state,
                                     x_zip                          =>  v_zip,
                                     x_province                     =>  NULL,
                                     x_country                      =>  v_country,
                                     x_area_code                    =>  NULL,
                                     x_phone                        =>  NULL,
                                     x_customer_num                 =>  NULL,
                                     x_ship_to_location_id          =>  v_ship_to_location_id,
                                     x_bill_to_location_id          =>  v_bill_to_location_id,
                                     x_ship_via_lookup_code         =>  v_ship_via_lookup_code,
                                     x_freight_terms_lookup_code    =>  v_freight_terms_lookup_code,
                                     x_fob_lookup_code              =>  v_fob_lookup_code,
                                     x_inactive_date                =>  NULL,
                                     x_fax                          =>  NULL,
                                     x_fax_area_code                =>  NULL,
                                     x_telex                        =>  NULL,
                                     --x_payment_method_lookup_code   =>  v_payment_method_lookup_code,
                                     x_bank_account_name            =>  v_bank_account_name,    -- defect 2564
                                     x_bank_account_num             =>  v_bank_account_num,
                                     x_bank_num                     =>  v_bank_num,
                                     x_bank_account_type            =>  NULL,
                                     x_terms_date_basis             =>  v_terms_date_basis,
                                     x_current_catalog_num          =>  NULL,
                                     --x_vat_code                     =>  NULL,--v_vat_code_def,
                                     x_distribution_set_id          =>  v_distribution_set_id,
                                     x_accts_pay_ccid               =>  v_accts_pay_ccid,
                                     x_future_dated_payment_ccid    =>  v_future_dated_payment_ccid,
                                     x_prepay_code_combination_id   =>  v_prepay_code_combination_id,
                                     x_pay_group_lookup_code        =>  v_pay_group_lookup_code,
                                     x_payment_priority             =>  99,--v_payment_priority,
                                     x_terms_id                     =>  v_terms_id,
                                     x_invoice_amount_limit         =>  NULL,--v_invoice_amount_limit,
                                     x_pay_date_basis_lookup_code   =>  v_pay_date_basis_lookup_code,
                                     x_always_take_disc_flag        =>  v_always_take_disc_flag,
                                     x_invoice_currency_code        =>  v_invoice_currency_code,
                                     x_payment_currency_code        =>  v_payment_currency_code,
                                     x_hold_all_payments_flag       =>  NULL,--v_hold_all_payments_flag,
                                     x_hold_future_payments_flag    =>  NULL,--v_hold_future_payments_flag,
                                     x_hold_reason                  =>  NULL,--v_hold_reason,
                                     x_hold_unmatched_invoices_flag =>  NULL,--v_hold_unmatched_invoices_flag,
                                     x_match_option                 =>  v_fin_match_option,
                                     x_create_debit_memo_flag       =>  c_no,
                                     --x_exclusive_payment_flag       =>  v_exclusive_payment_flag,
                                     x_tax_reporting_site_flag      =>  c_no,
                                     x_attribute_category           =>  NULL,
                                     x_attribute1                   =>  NULL,
                                     x_attribute2                   =>  NULL,
                                     x_attribute3                   =>  NULL,
                                     x_attribute4                   =>  NULL,
                                     x_attribute5                   =>  NULL,
                                     x_attribute6                   =>  NULL,
                                     x_attribute7                   =>  NULL,
                                     x_attribute8                   =>  'EX',
                                     x_attribute9                   =>  NULL,
                                     x_attribute10                  =>  NULL,
                                     x_attribute11                  =>  NULL,
                                     x_attribute12                  =>  NULL,
                                     x_attribute13                  =>  NULL,
                                     x_attribute14                  =>  NULL,
                                     x_attribute15                  =>  NULL,
                                     x_validation_number            =>  0,
                                     x_exclude_freight_from_disc    =>  NULL,--v_exclude_freight_from_disc,
                                     x_vat_registration_num         =>  NULL,--v_vat_registration_num,
                                     --x_offset_tax_flag              =>  NULL,--v_offset_tax_flag,
                                     x_check_digits                 =>  NULL,
                                     x_bank_number                  =>  v_bank_num,
                                     x_address_line4                =>  NULL,
                                     x_county                       =>  NULL,
                                     x_address_style                =>  NULL,
                                     x_language                     =>  NULL,
                                     x_allow_awt_flag               =>  v_allow_awt_flag,
                                     x_awt_group_id                 =>  NULL,--v_awt_group_id,
                                     x_pay_on_code                  =>  NULL,
                                     x_default_pay_site_id          =>  NULL,
                                     x_pay_on_receipt_summary_code  =>  NULL,--v_pay_on_rec_summary_code,
                                     x_bank_branch_type             =>  NULL,--v_bank_branch_type,
                                     x_edi_id_number                =>  NULL,
                                     x_edi_payment_method           =>  NULL,--v_edi_payment_method,
                                     x_edi_payment_format           =>  NULL,--v_edi_payment_format,
                                     x_edi_remittance_method        =>  NULL,--v_edi_remittance_method,
                                     x_edi_remittance_instruction   =>  NULL,--v_edi_remittance_instruction,
                                     x_edi_transaction_handling     =>  NULL,--v_edi_transaction_handling,
                                     x_auto_tax_calc_flag           =>  NULL,--v_tax_calc_flag_def,
                                     x_auto_tax_calc_override       =>  NULL,--v_tax_calc_override_def,
                                     x_amount_includes_tax_flag     =>  NULL,--v_amt_inc_tax_flag_def,
                                     x_ap_tax_rounding_rule         =>  NULL,--v_ap_tax_rounding_rule,
                                     x_vendor_site_code_alt         =>  NULL,
                                     x_address_lines_alt            =>  NULL,
                                     x_global_attribute_category    =>  NULL,
                                     x_global_attribute1            =>  NULL,
                                     x_global_attribute2            =>  NULL,
                                     x_global_attribute3            =>  NULL,
                                     x_global_attribute4            =>  NULL,
                                     x_global_attribute5            =>  NULL,
                                     x_global_attribute6            =>  NULL,
                                     x_global_attribute7            =>  NULL,
                                     x_global_attribute8            =>  NULL,
                                     x_global_attribute9            =>  NULL,
                                     x_global_attribute10           =>  NULL,
                                     x_global_attribute11           =>  NULL,
                                     x_global_attribute12           =>  NULL,
                                     x_global_attribute13           =>  NULL,
                                     x_global_attribute14           =>  NULL,
                                     x_global_attribute15           =>  NULL,
                                     x_global_attribute16           =>  NULL,
                                     x_global_attribute17           =>  NULL,
                                     x_global_attribute18           =>  NULL,
                                     x_global_attribute19           =>  NULL,
                                     x_global_attribute20           =>  NULL,
                                     x_bank_charge_bearer           =>  v_bank_charge_bearer,
                                     x_ece_tp_location_code         =>  NULL,
                                     x_pcard_site_flag              =>  c_no,
                                     x_country_of_origin_code       =>  NULL,--v_default_country,
                                     x_calling_sequence             =>  NULL,
                                     x_shipping_location_id         =>  NULL,
                                     x_supplier_notif_method        =>  NULL,
                                     x_email_address                =>  v_email_address,
                                     --x_remittance_email             =>  NULL,
                                     x_primary_pay_site_flag        =>  NULL,
                                     --x_shipping_control             =>  NULL,
                                     --x_duns_number                  =>  NULL,
                                     x_org_id                 =>  NULL);--v_tolerance_id);*/
	ap_vendor_sites_pkg.insert_row
                       (X_Rowid                            =>  v_rowid,
                       X_Vendor_Site_Id                   =>  x_vendor_site_id,                    
                       X_Last_Update_Date                 =>  c_when,                    
                       X_Last_Updated_By                  =>  c_who,                    
                       X_Vendor_Id                        =>  x_vendor_id,                    
                       X_Vendor_Site_Code                 =>  v_vendor_site_code,                    
                       X_Last_Update_Login                =>  NULL,                    
                       X_Creation_Date                    =>  c_when,                    
                       X_Created_By                       =>  c_who,                    
                       X_Purchasing_Site_Flag             =>  c_no,                    
                       X_Rfq_Only_Site_Flag               =>  v_rfq_only_site_flag,                    
                       X_Pay_Site_Flag                    =>  c_yes,                    
                       X_Attention_Ar_Flag                =>  c_no,                    
                       X_Address_Line1                    =>  v_address1,                    
                       X_Address_Line2                    =>  v_address2,                    
                       X_Address_Line3                    =>  v_address3,                    
                       X_City                             =>  v_city,                    
                       X_State                            =>  v_state,                    
                       X_Zip                              =>  v_zip,                    
                       X_Province                         =>  NULL,                    
                       X_Country                          =>  v_country,
                       X_Area_Code                        =>  NULL,
                       X_Phone                            =>  NULL,
                       X_Customer_Num                     =>  NULL,
                       X_Ship_To_Location_Id              =>  v_ship_to_location_id,
                       X_Bill_To_Location_Id              =>  v_bill_to_location_id,
                       X_Ship_Via_Lookup_Code             =>  v_ship_via_lookup_code,
                       X_Freight_Terms_Lookup_Code        =>  v_freight_terms_lookup_code,
                       X_Fob_Lookup_Code                  =>  v_fob_lookup_code,
                       X_Inactive_Date                    =>  NULL,
                       X_Fax                              =>  NULL,
                       X_Fax_Area_Code                    =>  NULL,
                       X_Telex                            =>  NULL,
                       X_Bank_Account_Name                =>  v_bank_account_name,    -- defect 2564
                       X_Bank_Account_Num                 =>  v_bank_account_num,
                       X_Bank_Num                         =>  v_bank_num,
                       X_Bank_Account_Type                =>  NULL,
                       X_Terms_Date_Basis                 =>  v_terms_date_basis,
                       X_Current_Catalog_Num              =>  NULL,
                       X_Distribution_Set_Id              =>  v_distribution_set_id,
                       X_Accts_Pay_CCID		              =>  v_accts_pay_ccid,
                       X_Future_Dated_Payment_CCID	      =>  v_future_dated_payment_ccid,
                       X_Prepay_Code_Combination_Id       =>  v_prepay_code_combination_id,
                       X_Pay_Group_Lookup_Code            =>  v_pay_group_lookup_code,
                       X_Payment_Priority                 =>  99,--v_payment_priority,
                       X_Terms_Id                         =>  v_terms_id,
                       X_Invoice_Amount_Limit             =>  NULL,--v_invoice_amount_limit,
                       X_Pay_Date_Basis_Lookup_Code       =>  v_pay_date_basis_lookup_code,
                       X_Always_Take_Disc_Flag            =>  v_always_take_disc_flag,
                       X_Invoice_Currency_Code            =>  v_invoice_currency_code,
                       X_Payment_Currency_Code            =>  v_payment_currency_code,
                       X_Hold_All_Payments_Flag           =>  NULL,--v_hold_all_payments_flag,
                       X_Hold_Future_Payments_Flag        =>  NULL,--v_hold_future_payments_flag,
                       X_Hold_Reason                      =>  NULL,--v_hold_reason,
                       X_Hold_Unmatched_Invoices_Flag     =>  NULL,--v_hold_unmatched_invoices_flag,
                       X_Match_Option			          =>  v_fin_match_option,
		               X_Create_Debit_Memo_Flag	          =>  c_no,
                       X_Tax_Reporting_Site_Flag          =>  c_no,
                       X_Attribute_Category               =>  NULL,
                       X_Attribute1                       =>  NULL,
                       X_Attribute2                       =>  NULL,
                       X_Attribute3                       =>  NULL,
                       X_Attribute4                       =>  NULL,
                       X_Attribute5                       =>  NULL,
                       X_Attribute6                       =>  NULL,
                       X_Attribute7                       =>  NULL,
                       X_Attribute8                       =>  'EX',
                       X_Attribute9                       =>  NULL,
                       X_Attribute10                      =>  NULL,
                       X_Attribute11                      =>  NULL,
                       X_Attribute12                      =>  NULL,
                       X_Attribute13                      =>  NULL,
                       X_Attribute14                      =>  NULL,
                       X_Attribute15                      =>  NULL,
                       X_Validation_Number                =>  0,
                       X_Exclude_Freight_From_Disc        =>  NULL,--v_exclude_freight_from_disc,
                       X_Vat_Registration_Num             =>  NULL,--v_vat_registration_num,
                       X_Check_Digits                     =>  NULL,
                       X_Bank_Number                      =>  v_bank_num,
                       X_Address_Line4                    =>  NULL,
                       X_County                           =>  NULL,
                       X_Address_Style                    =>  NULL,
                       X_Language                         =>  NULL,
                       X_Allow_Awt_Flag                   =>  v_allow_awt_flag,
                       X_Awt_Group_Id                     =>  NULL,--v_awt_group_id,
                       X_Pay_Awt_Group_Id                 =>  NULL,
		               X_pay_on_code			          =>  NULL,
		               X_default_pay_site_id	          =>  NULL,
		               X_pay_on_receipt_summary_code	  =>  NULL,--v_pay_on_rec_summary_code,
		               X_Bank_Branch_Type		          =>  NULL,--v_bank_branch_type,
		               X_EDI_ID_Number                    =>  NULL,
        		       X_Vendor_Site_Code_Alt		      =>  NULL,
		               X_Address_Lines_Alt		          =>  NULL,
                       X_global_attribute_category        =>  NULL,
                       X_global_attribute1                =>  NULL,
                       X_global_attribute2                =>  NULL,
                       X_global_attribute3                =>  NULL,
                       X_global_attribute4                =>  NULL,
                       X_global_attribute5                =>  NULL,
                       X_global_attribute6                =>  NULL,
                       X_global_attribute7                =>  NULL,
                       X_global_attribute8                =>  NULL,
                       X_global_attribute9                =>  NULL,
                       X_global_attribute10               =>  NULL,
                       X_global_attribute11               =>  NULL,
                       X_global_attribute12               =>  NULL,
                       X_global_attribute13               =>  NULL,
                       X_global_attribute14               =>  NULL,
                       X_global_attribute15               =>  NULL,
                       X_global_attribute16               =>  NULL,
                       X_global_attribute17               =>  NULL,
                       X_global_attribute18               =>  NULL,
                       X_global_attribute19               =>  NULL,
                       X_global_attribute20               =>  NULL,
		               X_Bank_Charge_Bearer	  	          =>  v_bank_charge_bearer,
                       X_Ece_Tp_Location_Code             =>  NULL,
		               X_Pcard_Site_Flag		          =>  c_no,
		               X_Country_of_Origin_Code           =>  NULL,--v_default_country,
		               X_calling_sequence	              =>  NULL,
		               X_Shipping_Location_id	          =>  NULL,
		               X_Supplier_Notif_Method            =>  NULL,
                       X_Email_Address                    =>  v_email_address,
                       X_Primary_pay_site_flag            =>  NULL,
		      	       X_Org_ID				              =>  NULL,
		      	       X_Ack_Lead_time            =>  NULL); --AB V1.16
    -- end of addition
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Error in xx_po_employee_vendor_proc.ap_vendor_sites_pkg.insert_row '||SQLERRM);
    End;

    END LOOP;
    CLOSE vadd_cur;

  END LOOP;
  CLOSE vend_cur;

  /* Insert the bank account uses into ap_bank_account_uses_all */
  /*IF v_bank_account_id IS NOT NULL THEN
    Begin
--    fnd_file.put_line(fnd_file.log,'xx_po_employee_vendor_proc.create bank account for site '|| x_vendor_site_id );
  -- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
    INSERT INTO ap_bank_account_uses_all (bank_account_uses_id,
                                          last_update_date,
                                          last_updated_by,
                                          creation_date,
                                          created_by,
                                          vendor_id,
                                          vendor_site_id,
                                          external_bank_account_id,
                                          start_date,
                                          primary_flag)
    VALUES (ap_bank_account_uses_s.nextval, --bank_account_uses_id,
            c_when,                         --last_update_date
            c_who,                          --last_updated_by
            c_when,                         --creation_date
            c_who,                          --created_by
            x_vendor_id,                    --vendor_id
            x_vendor_site_id,               --vendor_site_id,
            v_bank_account_id,              --external_bank_account_id
            TRUNC(c_when),                  --start_date
            c_yes);                         --primary_flag
	
	
	EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Error in xx_po_employee_vendor_proc Insert ap_bank_account_uses_all '||SQLERRM);
    End;
  END IF;

  COMMIT;*/

  /* Switch the org context back */
  fnd_client_info.set_org_context(c_org_id);

EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in xx_po_employee_vendor_proc.p_insert_vendors '||SQLERRM);
END p_insert_vendors;

/* Start the main program */
BEGIN
--  fnd_file.put_line(fnd_file.output,' ');
--  fnd_file.put_line(fnd_file.output,'''OD: PO Employee Vendor'' start time is '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
--  fnd_file.put_line(fnd_file.output,' ');

  /* Check if the employee vendor already exists */
  p_vendor_check;

  IF x_vendor_id IS NULL THEN

    fnd_file.put_line(fnd_file.log,'***** xx_po_employee_vendor_proc: Creating Bank and Vendor for person_id= ' || p_person_id);
	-- commented and added by Darshini(v1.14) for R12 Upgrade Retrofit
    /* Create the employee bank, if bank details exist */
    --p_create_bank;

    /* Create the employee vendor and employee vendor site.  If bank details exist create the bank account use */
   -- p_insert_vendors;
   
    /* Create the employee vendor and employee vendor site.  If bank details exist create the bank account use */
    p_insert_vendors;
	
	/* Create the employee bank, if bank details exist */
    p_create_bank;
	
	
  END IF;
  
  	IF v_bank_account_id IS NULL THEN
      NULL;
    ELSE
      v_payment_method_lookup_code := 'EFT';
    END IF;

    /* Defect 4824 Set the Payment Group based on Payment Method */
    IF v_payment_method_lookup_code = 'EFT' THEN
      v_vendor_pay_group_lookup_code := 'US_OD_ACH';
      v_pay_group_lookup_code := 'US_OD_ACH';
    END IF;
    IF v_payment_method_lookup_code = 'CHECK' THEN
      v_vendor_pay_group_lookup_code := 'US_OD_EXP_NON_DISC';
      v_pay_group_lookup_code := 'US_OD_EXP_NON_DISC';
    END IF;
	
	UPDATE ap_suppliers
	set pay_group_lookup_code = v_vendor_pay_group_lookup_code
	where vendor_id = x_vendor_id;
	
	UPDATE ap_supplier_sites_all
	set pay_group_lookup_code = v_pay_group_lookup_code
	where vendor_id = x_vendor_id
	and vendor_site_id = x_vendor_site_id;
	
	COMMIT;
   	-- end of addition(1.14)

--  fnd_file.put_line(fnd_file.output,'''OD: PO Employee Vendor'' end time is '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
--  fnd_file.put_line(fnd_file.output,' ');

EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in xx_po_employee_vendor_proc.main '||SQLERRM);
END xx_po_employee_vendor_proc;
/