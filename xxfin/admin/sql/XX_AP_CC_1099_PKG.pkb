SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_AP_CC_1099_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AP_CC_1099_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name :  1099 From CreditCard                                        |
-- | Description : To create one invoice and one credit memo for each    |
-- |              of those vendors that Office Depot pays through 3rd    |
-- |              party credit card companies, inorder to report 1099    |
-- |              activity on the vendors.                               |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       13-APR-2007  Anusha Ramanujam,     Initial version         |
-- |                       Wipro Technologies                            |
-- |1.1       04-FEB-2007  Sandeep Pandhare      Defect 4123             |
-- |1.2       10-JUN-2013  Darshini Gangadhar    Modified for R12 Upgrade| 
-- |                                             Retrofit                |
-- +=====================================================================+

    lc_error_loc          VARCHAR2(2000) := NULL;
    lc_err_msg            VARCHAR2(250);


-- +=======================================================================+
-- | Name : GET_REQUEST_ID                                                 |
-- | Description : To populate the request_id of the SQL Loader concurrent |
-- |               Program, 'OD: AP CC1099 Import Program' in the Staging  |
-- |               table                                                   |
-- |                                                                       |
-- | Returns : ln_req_id (request id of the loader program)                |
-- +=======================================================================+
   FUNCTION GET_REQUEST_ID
   RETURN NUMBER
   IS

   ln_req_id   NUMBER;

   BEGIN

      lc_error_loc := 'Getting the Request ID of ''OD: AP CC1099 Import Program''';

      SELECT MAX (request_id)
      INTO ln_req_id
      FROM fnd_concurrent_requests
      WHERE concurrent_program_id = (
                    SELECT concurrent_program_id
                    FROM fnd_concurrent_programs
                    WHERE concurrent_program_name = 'XXAPCC1099IMPT');-- short name of the loader program
      RETURN ln_req_id;

   EXCEPTION
      WHEN OTHERS THEN
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => 'XXAPCC1099IMPT'
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc 
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
              );

      RETURN -1;

   END GET_REQUEST_ID;


-- +=======================================================================+
-- | Name : XX_AP_VERIFY_SETUPS                                            |
-- | Description : To verify whether the Setups required for the extension |
-- |               are in place                                            |
-- | Parameters : p_lkp_type_ven,p_lkp_code_ven,p_lkp_type_pay,            |
-- |              p_lkp_code_sup_pay,p_lkp_code_site_pay,p_lkp_type_sou,   |
-- |              p_lkp_code_sou,x_valid                                   |
-- |                                                                       |
-- | Returns : x_valid ('Y' or 'N' based on verification success/failure)  |
-- +=======================================================================+
   PROCEDURE XX_AP_VERIFY_SETUPS(
                                 p_lkp_type_ven      IN  VARCHAR2
                                ,p_lkp_code_ven      IN  VARCHAR2
                                ,p_lkp_type_pay      IN  VARCHAR2
                                ,p_lkp_code_sup_pay  IN  VARCHAR2
                                ,p_lkp_code_site_pay IN  VARCHAR2
                                ,p_lkp_type_sou      IN  VARCHAR2
                                ,p_lkp_code_sou      IN  VARCHAR2
                                ,p_lkp_type_acc      IN  VARCHAR2
                                ,p_lkp_code_acc      IN  VARCHAR2
                                ,x_valid             OUT VARCHAR2 )
   IS
   ln_count          NUMBER;


   BEGIN
      x_valid := 'Y';

    --To verify if the Vendor Type Lookup Code is set up for the extension
      BEGIN

         lc_error_loc := 'Verifying Setup for Vendor Type Lookup Code';

         SELECT COUNT(1)
         INTO ln_count
         FROM po_lookup_codes
         WHERE lookup_type = p_lkp_type_ven
         AND lookup_code = p_lkp_code_ven;

         IF (ln_count = 0) THEN
             x_valid := 'N';
             FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0002_VDR_TYPE');
             lc_err_msg := FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);
         END IF;

      EXCEPTION
         WHEN OTHERS THEN
              x_valid := 'N';
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => gc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
                 ,p_object_id               => p_lkp_code_ven
              );

      END;

    --To verify if the Pay Group Lookup Code for Supplier is set up
      BEGIN

         lc_error_loc := 'Verifying Setup for Supplier Pay Group Lookup Code';

         SELECT COUNT(1)
         INTO ln_count
         FROM po_lookup_codes
         WHERE lookup_type = p_lkp_type_pay
         AND lookup_code = p_lkp_code_sup_pay
         AND inactive_date IS NULL;

         IF (ln_count = 0) THEN 
             x_valid := 'N';
             FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0003_SUP_PAY');
             lc_err_msg := FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);
         END IF;

      EXCEPTION
          WHEN OTHERS THEN
              x_valid := 'N';
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => gc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
                 ,p_object_id               => p_lkp_code_sup_pay
              );

      END;

    --To verify if the Pay Group Lookup Code for site is set up for the extension
      BEGIN

         lc_error_loc := 'Verifying Setup for Site Pay Group Lookup Code';

         SELECT COUNT(1)
         INTO ln_count
         FROM po_lookup_codes
         WHERE lookup_type = p_lkp_type_pay
         AND lookup_code = p_lkp_code_site_pay;

         IF (ln_count = 0) THEN
             x_valid := 'N';
             FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0004_SITE_PAY');
             lc_err_msg := FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);
         END IF;

      EXCEPTION
         WHEN OTHERS THEN
              x_valid := 'N';
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => gc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
                 ,p_object_id               => p_lkp_code_site_pay
              );

      END;

    --To verify  if the Invoice Source is set up for the extension
      BEGIN

         lc_error_loc := 'Verifying Setup for Invoice Source';

         SELECT COUNT(1)
         INTO ln_count 
         FROM ap_lookup_codes
         WHERE lookup_type = p_lkp_type_sou
         AND lookup_code = p_lkp_code_sou;

         IF (ln_count = 0) THEN
             x_valid := 'N';
             FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0005_INV_SOU');
             lc_err_msg := FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);
         END IF;

      EXCEPTION
         WHEN OTHERS THEN
              x_valid := 'N';
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => gc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
                 ,p_object_id               => p_lkp_code_sou
              );

      END;

    --To verify if the Invoice Account is set up for the extension
      BEGIN

         lc_error_loc := 'Verifying Setup for Invoice Account';

         SELECT COUNT(1)
         INTO   ln_count
         FROM   ap_lookup_codes
         WHERE  lookup_type = p_lkp_type_acc
         AND    lookup_code = p_lkp_code_acc;

         IF (ln_count = 0) THEN
             x_valid := 'N';
             FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0007_ACCT_LKP');
             lc_err_msg := FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);
         END IF;

      EXCEPTION
         WHEN OTHERS THEN
              x_valid := 'N';
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => gc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
                 ,p_object_id               => p_lkp_code_acc
              );

      END;


   EXCEPTION
       WHEN OTHERS THEN
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0006_SETUP');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg||': '||SQLERRM);

   END XX_AP_VERIFY_SETUPS;


-- +=======================================================================+
-- | Name : XX_AP_INSERT_VENDOR                                            |
-- | Description : To insert the validated records into the Supplier       |
-- |               Interface table AP_SUPPLIERS_INT                        |
-- | Parameters  : p_vendor_name, p_tax_id, p_lkp_code_ven,                |
-- |               p_lkp_code_sup_pay, p_type_1099                         |
-- +=======================================================================+
   PROCEDURE XX_AP_INSERT_VENDOR(
                                 p_vendor_name      IN  VARCHAR2
                                ,p_tax_id           IN  NUMBER
                                ,p_lkp_code_ven     IN  VARCHAR2
                                ,p_lkp_code_sup_pay IN  VARCHAR2
                                ,p_type_1099        IN  VARCHAR2 
                                ,p_lkp_code_org     IN  VARCHAR2 )--Bug 2059
   IS

   ln_vndr_intfc_id      NUMBER;

   BEGIN

      lc_error_loc := 'Inserting Vendor into ap_suppliers_int table';

      SELECT ap_suppliers_int_s.NEXTVAL
      INTO ln_vndr_intfc_id
      FROM SYS.DUAL;

      INSERT INTO ap_suppliers_int
                         (vendor_interface_id
                         ,vendor_name
                         ,creation_date
                         ,vendor_type_lookup_code
                         ,pay_group_lookup_code
                         ,num_1099
                         ,type_1099
                         ,state_reportable_flag
                         ,federal_reportable_flag
                         ,organization_type_lookup_code --Bug 2059
						 )
                    VALUES
                        (ln_vndr_intfc_id
                        ,p_vendor_name
                        ,SYSDATE
                        ,p_lkp_code_ven
                        ,p_lkp_code_sup_pay
                        ,p_tax_id
                        ,p_type_1099
                        ,'Y'
                        ,'Y'
                        ,p_lkp_code_org
						);
   EXCEPTION
       WHEN OTHERS THEN
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => gc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
               );

   END XX_AP_INSERT_VENDOR;


-- +=======================================================================+
-- | Name : XX_AP_INSERT_VENDOR_SITE                                       |
-- | Description: To insert the validated records into the Supplier Site   |
-- |              Interface table AP_SUPPLIER_SITES_INT                    |
-- | Parameters : p_vndr_intfc_id, p_vendor_id,p_vendor_site,              |
-- |              p_address_line1,p_address_line2,p_city,p_state,p_postal, |
-- |              p_lkp_code_site_pay                                      |
-- +=======================================================================+
   PROCEDURE XX_AP_INSERT_VENDOR_SITE(
                                      p_vndr_intfc_id      IN NUMBER   DEFAULT NULL
                                     ,p_vendor_id          IN VARCHAR2 DEFAULT NULL
                                     ,p_vendor_site        IN VARCHAR2
                                     ,p_address_line1      IN VARCHAR2 DEFAULT NULL
                                     ,p_address_line2      IN VARCHAR2 DEFAULT NULL
                                     ,p_city               IN VARCHAR2 DEFAULT NULL
                                     ,p_state              IN VARCHAR2 DEFAULT NULL
                                     ,p_postal             IN VARCHAR2 DEFAULT NULL 
                                     ,p_lkp_code_site_pay  IN VARCHAR2 )
   IS
   lc_ou_name      VARCHAR2(50);
   lc_country      VARCHAR2(50);  --Added by Darshini for R12 Upgrade Retrofit

   BEGIN

      --Added by Darshini for R12 Upgrade Retrofit
      SELECT country 
	  INTO   lc_country
	  FROM   xle_fp_ou_ledger_v
      WHERE  operating_unit_id = FND_PROFILE.VALUE('ORG_ID');
	  -- end of addition
	  
      lc_error_loc := 'Inserting Vendor Site into ap_supplier_sites_int table';

      SELECT name
      INTO   lc_ou_name
      FROM   hr_operating_units
      WHERE  organization_id = FND_PROFILE.VALUE('ORG_ID');

      INSERT INTO ap_supplier_sites_int
                          (vendor_interface_id
                          ,vendor_site_code
                          ,vendor_id
                          ,creation_date
                          ,pay_site_flag
                          ,address_line1
                          ,address_line2
                          ,city
                          ,state
                          ,zip
                          ,terms_name
                          ,terms_date_basis
                          ,pay_group_lookup_code
                          ,pay_date_basis_lookup_code
                          ,payment_priority
                          ,payment_method_lookup_code
                          ,attribute8
                          ,match_option
                          ,operating_unit_name
                          ,tax_reporting_site_flag --Bug 2059
						  ,org_id  --Added by Darshini for R12 Upgrade Retrofit
						  ,country --Added by Darshini for R12 Upgrade Retrofit
                          )
                     VALUES
                         (p_vndr_intfc_id
                         ,p_vendor_site
                         ,p_vendor_id
                         ,SYSDATE
                         ,'Y'
                         ,p_address_line1
                         ,p_address_line2
                         ,p_city
                         ,p_state
                         ,p_postal
                         ,'00'
                         ,'Invoice'
                         ,p_lkp_code_site_pay
                         ,'DISCOUNT'
                         ,1
                         ,'CLEARING'
                         ,'EX'    -- Defect 4123
                         ,'P'
                         ,lc_ou_name
                         ,'Y'
						 ,FND_PROFILE.VALUE('ORG_ID') --Added by Darshini for R12 Upgrade Retrofit
						 ,lc_country --Added by Darshini for R12 Upgrade Retrofit
                         );
   EXCEPTION
       WHEN OTHERS THEN
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => gc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
              );

   END XX_AP_INSERT_VENDOR_SITE;


-- +=======================================================================+
-- | Name : XX_AP_INSERT_INVOICE                                           |
-- | Description: To insert a new invoice header and one corresponding     |
-- |              invoice line into the Invoice Interface tables           |
-- |              AP_INVOICES_INTERFACE and AP_INVOICE_LINES_INTERFACE     |
-- |              respectively.                                            |
-- | Parameters : p_invoice_type,p_vendor_name,p_withholding_amount        |
-- |              ,p_group_id,p_vendor_site,p_description,p_lkp_code_sou   |
-- +=======================================================================+
   PROCEDURE XX_AP_INSERT_INVOICE(
                                 p_invoice_type       IN  VARCHAR2
                                ,p_vendor_name        IN  VARCHAR2
                                ,p_withholding_amount IN  NUMBER
                                ,p_group_id           IN  VARCHAR2
                                ,p_vendor_site        IN  VARCHAR2
                                ,p_description        IN  VARCHAR2
                                ,p_lkp_code_sou       IN  VARCHAR2 )
   IS
   ln_invoice_id       NUMBER;
   ln_invoice_num      NUMBER;
   lc_invoice_number   VARCHAR2(100);

   BEGIN

      lc_error_loc := 'Getting sequence values for invoice_id and invoice_number';

      SELECT ap_invoices_interface_s.NEXTVAL
      INTO ln_invoice_id
      FROM SYS.DUAL;

      SELECT xx_ap_cc_1099_invoice_s.NEXTVAL
      INTO ln_invoice_num
      FROM SYS.DUAL;

      lc_invoice_number := '1099'||ln_invoice_num;


      lc_error_loc := 'Inserting Invoice for the vendor';

      INSERT INTO ap_invoices_interface
                              (invoice_id
                              ,invoice_type_lookup_code
                              ,vendor_name
                              ,vendor_site_code
                              ,description
                              ,invoice_date
                              ,invoice_num
                              ,invoice_amount
                              ,source
                              ,group_id
                              ,org_id
                              ,creation_date    -- defect 4123
                              ,last_update_date -- defect 4123
							  )
                        VALUES
                              (ln_invoice_id
                              ,p_invoice_type
                              ,p_vendor_name
                              ,p_vendor_site
                              ,p_description
                              ,SYSDATE
                              ,lc_invoice_number
                              ,p_withholding_amount
                              ,p_lkp_code_sou
                              ,p_group_id
                              ,FND_PROFILE.VALUE('ORG_ID')
                              ,sysdate
                              ,sysdate
							 );

      INSERT INTO ap_invoice_lines_interface
                              (invoice_id
                              ,line_number
                              ,line_type_lookup_code
                              ,amount
                              ,dist_code_concatenated
                              ,creation_date
                              )
                        VALUES
                              (ln_invoice_id
                              ,1
                              ,'ITEM'
                              ,p_withholding_amount
                              ,gc_inv_account
                              ,SYSDATE
                              );


   EXCEPTION
       WHEN OTHERS THEN
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => gc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
              );

   END XX_AP_INSERT_INVOICE;


-- +=======================================================================+
-- | Name : XX_AP_WAIT_FOR_REQUEST                                         |
-- | Description : To wait till the completion of a submitted concurrent   |
-- |              program. It calls the function "fnd_concurrent.          |
-- |              wait_for_request"                                        |
-- | Parameters  : p_conc_request_id, x_prog_status                        |
-- | Returns     : x_prog_status ('E' if program completes in 'Error')     |
-- +=======================================================================+
   PROCEDURE XX_AP_WAIT_FOR_REQUEST(
                                    p_conc_request_id IN  NUMBER
                                   ,x_prog_status     OUT VARCHAR2 )
   IS
   lb_req_status        BOOLEAN;
   lc_phase             VARCHAR2(50);
   lc_status            VARCHAR2(50);
   lc_devphase          VARCHAR2(50);
   lc_devstatus         VARCHAR2(50);
   lc_message           VARCHAR2(50);

   BEGIN

      lc_error_loc := 'getting the status of the request submitted';

      lb_req_status := fnd_concurrent.wait_for_request (
                                              p_conc_request_id
                                             ,'10'
                                             ,''
                                             ,lc_phase
                                             ,lc_status
                                             ,lc_devphase
                                             ,lc_devstatus
                                             ,lc_message );

      FND_FILE.PUT_LINE(fnd_file.log, 'Phase and Status = '||lc_phase||' '||lc_status);
      FND_FILE.PUT_LINE(fnd_file.log, '         Message = '||lc_message);

      IF (lc_phase = 'Completed') THEN

          IF (lc_status = 'Normal') THEN

              FND_FILE.PUT_LINE(fnd_file.log,'Request completed with Normal status');
              FND_FILE.PUT_LINE(fnd_file.log,'');

          ELSIF (lc_status = 'Error') THEN

              FND_FILE.PUT_LINE(fnd_file.log,'Request completed in ERROR!!');
              x_prog_status := 'E';

          ELSIF (lc_status = 'Warning') THEN

              FND_FILE.PUT_LINE(fnd_file.log,'Request completed with WARNING');
              FND_FILE.PUT_LINE(fnd_file.log,'Check the log file of the concurrent program');

          END IF;

      ELSIF (lc_phase = 'Inactive') THEN

              FND_FILE.PUT_LINE(fnd_file.log,'Request in INACTIVE status after submission');
              FND_FILE.PUT_LINE(fnd_file.log,'Check Oracle Applications for detail information.');

      END IF;

   EXCEPTION
       WHEN OTHERS THEN
              FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
              FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
              FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => gc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || lc_error_loc
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => '1099 CreditCard'
              );

   END XX_AP_WAIT_FOR_REQUEST;


-- +=======================================================================+
-- | Name : XX_AP_UPDATE_VENDOR                                            |
-- | Description: To update the vendors with appropriate value of the      |
-- |              Income Tax Type Code before(NULL) and after('MISC7') the |
-- |              creation of invoice of type 'CREDIT'                     |
-- | Parameters : p_vendor_id, p_type_1099, x_status                       |
-- | Returns    : x_status('Y' or 'N' based on updation success/failure)   |
-- +=======================================================================+
   PROCEDURE XX_AP_UPDATE_VENDOR(
                                 p_vendor_id             IN NUMBER
                                ,p_type_1099             IN VARCHAR2
                                ,x_status                OUT NOCOPY VARCHAR2 )
   IS
-- variables for the arguments to update_row
   -- Commented and added by Darshini for R12 Upgrade Retrofit
   /*lc_rowid                         VARCHAR2(255);
   lc_vendor_name                   po_vendors.vendor_name%TYPE;
   lc_segment1                      po_vendors.segment1%TYPE;
   lc_summary_flag                  po_vendors.summary_flag%TYPE;
   lc_enabled_flag                  po_vendors.enabled_flag%TYPE;
   ln_employee_id                   po_vendors.employee_id%TYPE;
   ln_validation_number             po_vendors.validation_number%TYPE;
   lc_vendor_type_lookup_code       po_vendors.vendor_type_lookup_code%TYPE;
   lc_customer_num                  po_vendors.customer_num%TYPE;
   lc_one_time_flag                 po_vendors.one_time_flag%TYPE;
   ln_parent_vendor_id              NUMBER;
   ln_min_order_amount              NUMBER;
   ln_ship_to_location_id           NUMBER;
   ln_bill_to_location_id           NUMBER;
   lc_ship_via_lookup_code          po_vendors.ship_via_lookup_code%TYPE;
   lc_freight_terms_lookup_code     po_vendors.freight_terms_lookup_code%TYPE;
   lc_fob_lookup_code               po_vendors.fob_lookup_code%TYPE;
   ln_terms_id                      NUMBER;
   ln_set_of_books_id               NUMBER;
   lc_always_take_disc_flag         po_vendors.always_take_disc_flag%TYPE;
   lc_pay_date_basis_lookup_code    po_vendors.pay_date_basis_lookup_code%TYPE;
   lc_pay_group_lookup_code         po_vendors.pay_group_lookup_code%TYPE;
   ln_payment_priority              NUMBER;
   lc_invoice_currency_code         po_vendors.invoice_currency_code%TYPE;
   lc_payment_currency_code         po_vendors.payment_currency_code%TYPE;
   ln_invoice_amount_limit          NUMBER;
   lc_hold_all_payments_flag        po_vendors.hold_all_payments_flag%TYPE;
   lc_hold_future_payments_flag     po_vendors.hold_future_payments_flag%TYPE;
   lc_hold_reason                   po_vendors.hold_reason%TYPE;
   ln_distribution_set_id           NUMBER;
   ln_accts_pay_ccid                NUMBER;
   ln_future_dated_payment_ccid     NUMBER;
   ln_prepay_ccid                   NUMBER;
   lc_num_1099                      po_vendors.num_1099%TYPE;
   lc_type_1099                     po_vendors.type_1099%TYPE;
   lc_withhldng_stat_lookup_code    po_vendors.withholding_status_lookup_code%TYPE;
   ld_withholding_start_date        DATE;
   lc_org_type_lookup_code          po_vendors.organization_type_lookup_code%TYPE;
   lc_vat_code                      po_vendors.vat_code%TYPE;
   ld_start_date_active             DATE;
   ld_end_date_active               DATE;
   ln_qty_rcv_tolerance             NUMBER;
   lc_minority_group_lookup_code    po_vendors.minority_group_lookup_code%TYPE;
   lc_payment_method_lookup_code    po_vendors.payment_method_lookup_code%TYPE;
   lc_bank_account_name             po_vendors.bank_account_name%TYPE;
   lc_bank_account_num              po_vendors.bank_account_num%TYPE;
   lc_bank_num                      po_vendors.bank_num%TYPE;
   lc_bank_account_type             po_vendors.bank_account_type%TYPE;
   lc_women_owned_flag              po_vendors.women_owned_flag%TYPE;
   lc_small_business_flag           po_vendors.small_business_flag%TYPE;
   lc_standard_industry_class       po_vendors.standard_industry_class%TYPE;
   lc_attribute_category            po_vendors.attribute_category%TYPE;
   lc_attribute1                    VARCHAR2(255);
   lc_attribute2                    VARCHAR2(255);
   lc_attribute3                    VARCHAR2(255);
   lc_attribute4                    VARCHAR2(255);
   lc_attribute5                    VARCHAR2(255);
   lc_hold_flag                     VARCHAR2(255);
   lc_purchasing_hold_reason        po_vendors.purchasing_hold_reason%TYPE;
   ln_hold_by                       NUMBER;
   ld_hold_date                     DATE;
   lc_terms_date_basis              po_vendors.terms_date_basis%TYPE;
   ln_price_tolerance               po_vendors.price_tolerance%TYPE;
   lc_attribute10                   VARCHAR2(255);
   lc_attribute11                   VARCHAR2(255);
   lc_attribute12                   VARCHAR2(255);
   lc_attribute13                   VARCHAR2(255);
   lc_attribute14                   VARCHAR2(255);
   lc_attribute15                   VARCHAR2(255);
   lc_attribute6                    VARCHAR2(255);
   lc_attribute7                    VARCHAR2(255);
   lc_attribute8                    VARCHAR2(255);
   lc_attribute9                    VARCHAR2(255);
   ln_days_early_receipt_allowed    NUMBER;
   ln_days_late_receipt_allowed     NUMBER;
   lc_enforce_ship_to_loc_code      po_vendors.enforce_ship_to_location_code%TYPE;
   lc_exclusive_payment_flag        po_vendors.exclusive_payment_flag%TYPE;
   lc_federal_reportable_flag       po_vendors.federal_reportable_flag%TYPE;
   lc_hold_unmatchd_invoices_flag   po_vendors.hold_unmatched_invoices_flag%TYPE;
   lc_match_option                  po_vendors.match_option%TYPE;
   lc_create_debit_memo_flag        po_vendors.create_debit_memo_flag%TYPE;
   lc_inspection_required_flag      po_vendors.inspection_required_flag%TYPE;
   lc_receipt_required_flag         po_vendors.receipt_required_flag%TYPE;
   ln_receiving_routing_id          NUMBER;
   lc_state_reportable_flag         po_vendors.state_reportable_flag%TYPE;
   ld_tax_verification_date         DATE;
   lc_auto_calc_interest_flag       po_vendors.auto_calculate_interest_flag%TYPE;
   lc_name_control                  po_vendors.name_control%TYPE;
   lc_allow_subst_receipts_flag     po_vendors.allow_substitute_receipts_flag%TYPE;
   lc_allow_unord_receipts_flag     po_vendors.allow_unordered_receipts_flag%TYPE;
   lc_receipt_days_exception_code   po_vendors.receipt_days_exception_code%TYPE;
   lc_qty_rcv_exception_code        po_vendors.qty_rcv_exception_code%TYPE;
      lc_offset_tax_flag            po_vendors.offset_tax_flag%TYPE;
   lc_exclude_freight_from_disc     po_vendors.exclude_freight_from_discount%TYPE;
   lc_vat_registration_num          po_vendors.vat_registration_num%TYPE;
   lc_tax_reporting_name            po_vendors.tax_reporting_name%TYPE;
   ln_awt_group_id                  NUMBER;
   lc_check_digits                  po_vendors.check_digits%TYPE;
   lc_bank_number                   po_vendors.bank_number%TYPE;
   lc_allow_awt_flag                po_vendors.allow_awt_flag%TYPE;
   lc_bank_branch_type              po_vendors.bank_branch_type%TYPE;
   lc_edi_payment_method            po_vendors.edi_payment_method%TYPE;
   lc_edi_payment_format            po_vendors.edi_payment_format%TYPE;
   lc_edi_remittance_method         po_vendors.edi_remittance_method%TYPE;
   lc_edi_remittance_instruction    po_vendors.edi_remittance_instruction%TYPE;
   lc_edi_transaction_handling      po_vendors.edi_transaction_handling%TYPE;
   lc_auto_tax_calc_flag            po_vendors.auto_tax_calc_flag%TYPE;
   lc_auto_tax_calc_override        po_vendors.auto_tax_calc_override%TYPE;
   lc_amount_includes_tax_flag      po_vendors.amount_includes_tax_flag%TYPE;
   lc_ap_tax_rounding_rule          po_vendors.ap_tax_rounding_rule%TYPE;
   lc_vendor_name_alt               po_vendors.vendor_name_alt%TYPE;
   lc_global_attribute_category     po_vendors.global_attribute_category%TYPE;
   lc_global_attribute1             VARCHAR2(255);
   lc_global_attribute2             VARCHAR2(255);
   lc_global_attribute3             VARCHAR2(255);
   lc_global_attribute4             VARCHAR2(255);
   lc_global_attribute5             VARCHAR2(255);
   lc_global_attribute6             VARCHAR2(255);
   lc_global_attribute7             VARCHAR2(255);
   lc_global_attribute8             VARCHAR2(255);
   lc_global_attribute9             VARCHAR2(255);
   lc_global_attribute10            VARCHAR2(255);
   lc_global_attribute11            VARCHAR2(255);
   lc_global_attribute12            VARCHAR2(255);
   lc_global_attribute13            VARCHAR2(255);
   lc_global_attribute14            VARCHAR2(255);
   lc_global_attribute15            VARCHAR2(255);
   lc_global_attribute16            VARCHAR2(255);
   lc_global_attribute17            VARCHAR2(255);
   lc_global_attribute18            VARCHAR2(255);
   lc_global_attribute19            VARCHAR2(255);
   lc_global_attribute20            VARCHAR2(255);
   lc_bank_charge_bearer            po_vendors.bank_charge_bearer%TYPE;*/
   lc_rowid                         VARCHAR2(255);
   lc_vendor_name                   ap_suppliers.vendor_name%TYPE;
   lc_segment1                      ap_suppliers.segment1%TYPE;
   lc_summary_flag                  ap_suppliers.summary_flag%TYPE;
   lc_enabled_flag                  ap_suppliers.enabled_flag%TYPE;
   ln_employee_id                   ap_suppliers.employee_id%TYPE;
   ln_validation_number             ap_suppliers.validation_number%TYPE;
   lc_vendor_type_lookup_code       ap_suppliers.vendor_type_lookup_code%TYPE;
   lc_customer_num                  ap_suppliers.customer_num%TYPE;
   lc_one_time_flag                 ap_suppliers.one_time_flag%TYPE;
   ln_parent_vendor_id              NUMBER;
   ln_min_order_amount              NUMBER;
   ln_ship_to_location_id           NUMBER;
   ln_bill_to_location_id           NUMBER;
   lc_ship_via_lookup_code          ap_suppliers.ship_via_lookup_code%TYPE;
   lc_freight_terms_lookup_code     ap_suppliers.freight_terms_lookup_code%TYPE;
   lc_fob_lookup_code               ap_suppliers.fob_lookup_code%TYPE;
   ln_terms_id                      NUMBER;
   ln_set_of_books_id               NUMBER;
   lc_always_take_disc_flag         ap_suppliers.always_take_disc_flag%TYPE;
   lc_pay_date_basis_lookup_code    ap_suppliers.pay_date_basis_lookup_code%TYPE;
   lc_pay_group_lookup_code         ap_suppliers.pay_group_lookup_code%TYPE;
   ln_payment_priority              NUMBER;
   lc_invoice_currency_code         ap_suppliers.invoice_currency_code%TYPE;
   lc_payment_currency_code         ap_suppliers.payment_currency_code%TYPE;
   ln_invoice_amount_limit          NUMBER;
   lc_hold_all_payments_flag        ap_suppliers.hold_all_payments_flag%TYPE;
   lc_hold_future_payments_flag     ap_suppliers.hold_future_payments_flag%TYPE;
   lc_hold_reason                   ap_suppliers.hold_reason%TYPE;
   ln_distribution_set_id           NUMBER;
   ln_accts_pay_ccid                NUMBER;
   ln_future_dated_payment_ccid     NUMBER;
   ln_prepay_ccid                   NUMBER;
   lc_num_1099                      ap_suppliers.num_1099%TYPE;
   lc_type_1099                     ap_suppliers.type_1099%TYPE;
   lc_withhldng_stat_lookup_code    ap_suppliers.withholding_status_lookup_code%TYPE;
   ld_withholding_start_date        DATE;
   lc_org_type_lookup_code          ap_suppliers.organization_type_lookup_code%TYPE;
   lc_vat_code                      ap_suppliers.vat_code%TYPE;
   ld_start_date_active             DATE;
   ld_end_date_active               DATE;
   ln_qty_rcv_tolerance             NUMBER;
   lc_minority_group_lookup_code    ap_suppliers.minority_group_lookup_code%TYPE;
   lc_payment_method_lookup_code    ap_suppliers.payment_method_lookup_code%TYPE;
   lc_bank_account_name             ap_suppliers.bank_account_name%TYPE;
   lc_bank_account_num              ap_suppliers.bank_account_num%TYPE;
   lc_bank_num                      ap_suppliers.bank_num%TYPE;
   lc_bank_account_type             ap_suppliers.bank_account_type%TYPE;
   lc_women_owned_flag              ap_suppliers.women_owned_flag%TYPE;
   lc_small_business_flag           ap_suppliers.small_business_flag%TYPE;
   lc_standard_industry_class       ap_suppliers.standard_industry_class%TYPE;
   lc_attribute_category            ap_suppliers.attribute_category%TYPE;
   lc_attribute1                    VARCHAR2(255);
   lc_attribute2                    VARCHAR2(255);
   lc_attribute3                    VARCHAR2(255);
   lc_attribute4                    VARCHAR2(255);
   lc_attribute5                    VARCHAR2(255);
   lc_hold_flag                     VARCHAR2(255);
   lc_purchasing_hold_reason        ap_suppliers.purchasing_hold_reason%TYPE;
   ln_hold_by                       NUMBER;
   ld_hold_date                     DATE;
   lc_terms_date_basis              ap_suppliers.terms_date_basis%TYPE;
   ln_price_tolerance               ap_suppliers.price_tolerance%TYPE;
   lc_attribute10                   VARCHAR2(255);
   lc_attribute11                   VARCHAR2(255);
   lc_attribute12                   VARCHAR2(255);
   lc_attribute13                   VARCHAR2(255);
   lc_attribute14                   VARCHAR2(255);
   lc_attribute15                   VARCHAR2(255);
   lc_attribute6                    VARCHAR2(255);
   lc_attribute7                    VARCHAR2(255);
   lc_attribute8                    VARCHAR2(255);
   lc_attribute9                    VARCHAR2(255);
   ln_days_early_receipt_allowed    NUMBER;
   ln_days_late_receipt_allowed     NUMBER;
   lc_enforce_ship_to_loc_code      ap_suppliers.enforce_ship_to_location_code%TYPE;
   lc_exclusive_payment_flag        ap_suppliers.exclusive_payment_flag%TYPE;
   lc_federal_reportable_flag       ap_suppliers.federal_reportable_flag%TYPE;
   lc_hold_unmatchd_invoices_flag   ap_suppliers.hold_unmatched_invoices_flag%TYPE;
   lc_match_option                  ap_suppliers.match_option%TYPE;
   lc_create_debit_memo_flag        ap_suppliers.create_debit_memo_flag%TYPE;
   lc_inspection_required_flag      ap_suppliers.inspection_required_flag%TYPE;
   lc_receipt_required_flag         ap_suppliers.receipt_required_flag%TYPE;
   ln_receiving_routing_id          NUMBER;
   lc_state_reportable_flag         ap_suppliers.state_reportable_flag%TYPE;
   ld_tax_verification_date         DATE;
   lc_auto_calc_interest_flag       ap_suppliers.auto_calculate_interest_flag%TYPE;
   lc_name_control                  ap_suppliers.name_control%TYPE;
   lc_allow_subst_receipts_flag     ap_suppliers.allow_substitute_receipts_flag%TYPE;
   lc_allow_unord_receipts_flag     ap_suppliers.allow_unordered_receipts_flag%TYPE;
   lc_receipt_days_exception_code   ap_suppliers.receipt_days_exception_code%TYPE;
   lc_qty_rcv_exception_code        ap_suppliers.qty_rcv_exception_code%TYPE;
      lc_offset_tax_flag            ap_suppliers.offset_tax_flag%TYPE;
   lc_exclude_freight_from_disc     ap_suppliers.exclude_freight_from_discount%TYPE;
   lc_vat_registration_num          ap_suppliers.vat_registration_num%TYPE;
   lc_tax_reporting_name            ap_suppliers.tax_reporting_name%TYPE;
   ln_awt_group_id                  NUMBER;
   lc_check_digits                  ap_suppliers.check_digits%TYPE;
   lc_bank_number                   ap_suppliers.bank_number%TYPE;
   lc_allow_awt_flag                ap_suppliers.allow_awt_flag%TYPE;
   lc_bank_branch_type              ap_suppliers.bank_branch_type%TYPE;
   lc_edi_payment_method            ap_suppliers.edi_payment_method%TYPE;
   lc_edi_payment_format            ap_suppliers.edi_payment_format%TYPE;
   lc_edi_remittance_method         ap_suppliers.edi_remittance_method%TYPE;
   lc_edi_remittance_instruction    ap_suppliers.edi_remittance_instruction%TYPE;
   lc_edi_transaction_handling      ap_suppliers.edi_transaction_handling%TYPE;
   lc_auto_tax_calc_flag            ap_suppliers.auto_tax_calc_flag%TYPE;
   lc_auto_tax_calc_override        ap_suppliers.auto_tax_calc_override%TYPE;
   lc_amount_includes_tax_flag      ap_suppliers.amount_includes_tax_flag%TYPE;
   lc_ap_tax_rounding_rule          ap_suppliers.ap_tax_rounding_rule%TYPE;
   lc_vendor_name_alt               ap_suppliers.vendor_name_alt%TYPE;
   lc_global_attribute_category     ap_suppliers.global_attribute_category%TYPE;
   lc_global_attribute1             VARCHAR2(255);
   lc_global_attribute2             VARCHAR2(255);
   lc_global_attribute3             VARCHAR2(255);
   lc_global_attribute4             VARCHAR2(255);
   lc_global_attribute5             VARCHAR2(255);
   lc_global_attribute6             VARCHAR2(255);
   lc_global_attribute7             VARCHAR2(255);
   lc_global_attribute8             VARCHAR2(255);
   lc_global_attribute9             VARCHAR2(255);
   lc_global_attribute10            VARCHAR2(255);
   lc_global_attribute11            VARCHAR2(255);
   lc_global_attribute12            VARCHAR2(255);
   lc_global_attribute13            VARCHAR2(255);
   lc_global_attribute14            VARCHAR2(255);
   lc_global_attribute15            VARCHAR2(255);
   lc_global_attribute16            VARCHAR2(255);
   lc_global_attribute17            VARCHAR2(255);
   lc_global_attribute18            VARCHAR2(255);
   lc_global_attribute19            VARCHAR2(255);
   lc_global_attribute20            VARCHAR2(255);
   lc_bank_charge_bearer            ap_suppliers.bank_charge_bearer%TYPE;
   ln_pay_awt_group_id              NUMBER;
   -- end of addition

   BEGIN

   -- Select all the values needed to be passed to update_row from PO_VENDORS
      SELECT rowid, segment1, vendor_name, summary_flag, enabled_flag
            ,employee_id, validation_number, vendor_type_lookup_code
            ,customer_num, one_time_flag, parent_vendor_id, min_order_amount
            ,ship_to_location_id, bill_to_location_id, ship_via_lookup_code, freight_terms_lookup_code
            ,fob_lookup_code, terms_id, set_of_books_id, always_take_disc_flag
            ,pay_date_basis_lookup_code, pay_group_lookup_code, payment_priority, invoice_currency_code
            ,payment_currency_code, invoice_amount_limit, hold_all_payments_flag, hold_future_payments_flag
            ,hold_reason, distribution_set_id, accts_pay_code_combination_id, future_dated_payment_ccid
            ,prepay_code_combination_id, 
			--  commented and added by Darshini for R12 Upgrade Retrofit
			--num_1099,
            NVL(num_1099,individual_1099), 
            -- end of addition			
			type_1099, withholding_status_lookup_code
            ,withholding_start_date, organization_type_lookup_code, vat_code, start_date_active
            ,end_date_active, qty_rcv_tolerance, minority_group_lookup_code, payment_method_lookup_code
            ,bank_account_name, bank_account_num, bank_num, bank_account_type
            ,women_owned_flag,small_business_flag
            ,standard_industry_class, attribute_category
            ,attribute1, attribute2, attribute3, attribute4
            ,attribute5, hold_flag, purchasing_hold_reason, hold_by
            ,hold_date, terms_date_basis, price_tolerance, attribute10
            ,attribute11, attribute12, attribute13, attribute14
            ,attribute15, attribute6, attribute7, attribute8
            ,attribute9, days_early_receipt_allowed, days_late_receipt_allowed, enforce_ship_to_location_code
            ,exclusive_payment_flag, federal_reportable_flag, hold_unmatched_invoices_flag, match_option
            ,create_debit_memo_flag, inspection_required_flag, receipt_required_flag, receiving_routing_id
            ,state_reportable_flag, tax_verification_date, auto_calculate_interest_flag, name_control
            ,allow_substitute_receipts_flag, allow_unordered_receipts_flag, receipt_days_exception_code, qty_rcv_exception_code
            ,offset_tax_flag, exclude_freight_from_discount, vat_registration_num, tax_reporting_name
            ,awt_group_id
			-- Added by Darshini for R12 Upgrade Retrofit
			,pay_awt_group_id 
		    -- end of addition
			,check_digits, bank_number, allow_awt_flag
            ,bank_branch_type, edi_payment_method, edi_payment_format, edi_remittance_method
            ,edi_remittance_instruction, edi_transaction_handling, auto_tax_calc_flag, auto_tax_calc_override
            ,amount_includes_tax_flag, ap_tax_rounding_rule, vendor_name_alt, global_attribute_category
            ,global_attribute1, global_attribute2, global_attribute3, global_attribute4
            ,global_attribute5, global_attribute6, global_attribute7, global_attribute8
            ,global_attribute9, global_attribute10, global_attribute11, global_attribute12
            ,global_attribute13, global_attribute14, global_attribute15, global_attribute16
            ,global_attribute17, global_attribute18, global_attribute19, global_attribute20
            ,bank_charge_bearer
      INTO   lc_rowid, lc_segment1, lc_vendor_name, lc_summary_flag, lc_enabled_flag
            ,ln_employee_id, ln_validation_number, lc_vendor_type_lookup_code
            ,lc_customer_num, lc_one_time_flag, ln_parent_vendor_id, ln_min_order_amount
            ,ln_ship_to_location_id, ln_bill_to_location_id, lc_ship_via_lookup_code
            ,lc_freight_terms_lookup_code
            ,lc_fob_lookup_code, ln_terms_id, ln_set_of_books_id, lc_always_take_disc_flag
            ,lc_pay_date_basis_lookup_code, lc_pay_group_lookup_code, ln_payment_priority
            ,lc_invoice_currency_code
            ,lc_payment_currency_code, ln_invoice_amount_limit, lc_hold_all_payments_flag
            ,lc_hold_future_payments_flag
            ,lc_hold_reason, ln_distribution_set_id, ln_accts_pay_ccid, ln_future_dated_payment_ccid
            ,ln_prepay_ccid, lc_num_1099, lc_type_1099,lc_withhldng_stat_lookup_code
            ,ld_withholding_start_date, lc_org_type_lookup_code, lc_vat_code, ld_start_date_active
            ,ld_end_date_active, ln_qty_rcv_tolerance, lc_minority_group_lookup_code
            ,lc_payment_method_lookup_code
            ,lc_bank_account_name, lc_bank_account_num, lc_bank_num, lc_bank_account_type
            ,lc_women_owned_flag,lc_small_business_flag
            ,lc_standard_industry_class, lc_attribute_category
            ,lc_attribute1, lc_attribute2, lc_attribute3, lc_attribute4
            ,lc_attribute5, lc_hold_flag, lc_purchasing_hold_reason, ln_hold_by
            ,ld_hold_date, lc_terms_date_basis, ln_price_tolerance, lc_attribute10
            ,lc_attribute11, lc_attribute12, lc_attribute13, lc_attribute14
            ,lc_attribute15, lc_attribute6, lc_attribute7, lc_attribute8
            ,lc_attribute9, ln_days_early_receipt_allowed, ln_days_late_receipt_allowed
            ,lc_enforce_ship_to_loc_code
            ,lc_exclusive_payment_flag, lc_federal_reportable_flag, lc_hold_unmatchd_invoices_flag
            ,lc_match_option
            ,lc_create_debit_memo_flag, lc_inspection_required_flag, lc_receipt_required_flag
            ,ln_receiving_routing_id
            ,lc_state_reportable_flag, ld_tax_verification_date, lc_auto_calc_interest_flag
            ,lc_name_control
            ,lc_allow_subst_receipts_flag, lc_allow_unord_receipts_flag, lc_receipt_days_exception_code
            ,lc_qty_rcv_exception_code
            ,lc_offset_tax_flag, lc_exclude_freight_from_disc, lc_vat_registration_num
            ,lc_tax_reporting_name
            ,ln_awt_group_id 
			 --Added by Darshini for R12 Upgrade Retrofit
			,ln_pay_awt_group_id
			-- end of addition
			,lc_check_digits, lc_bank_number, lc_allow_awt_flag
            ,lc_bank_branch_type, lc_edi_payment_method, lc_edi_payment_format, lc_edi_remittance_method
            ,lc_edi_remittance_instruction, lc_edi_transaction_handling, lc_auto_tax_calc_flag
            ,lc_auto_tax_calc_override
            ,lc_amount_includes_tax_flag, lc_ap_tax_rounding_rule, lc_vendor_name_alt
            ,lc_global_attribute_category
            ,lc_global_attribute1, lc_global_attribute2, lc_global_attribute3, lc_global_attribute4
            ,lc_global_attribute5, lc_global_attribute6, lc_global_attribute7, lc_global_attribute8
            ,lc_global_attribute9, lc_global_attribute10, lc_global_attribute11, lc_global_attribute12
            ,lc_global_attribute13, lc_global_attribute14, lc_global_attribute15, lc_global_attribute16
            ,lc_global_attribute17, lc_global_attribute18, lc_global_attribute19, lc_global_attribute20
            ,lc_bank_charge_bearer
      -- commented and added by Darshini for R12 Upgrade Retrofit
      --FROM po_vendors
      FROM ap_suppliers
	  -- end of addition
	  WHERE vendor_id = p_vendor_id;
      --Commented and added by Darshini for R12 Upgrade Retrofit
      /*AP_VENDORS_PKG.UPDATE_ROW(
         x_rowid                             =>  lc_rowid,
         x_vendor_id                         =>  p_vendor_id,
         x_last_update_date                  =>  SYSDATE,
         x_last_updated_by                   =>  FND_GLOBAL.USER_ID,
         x_vendor_name                       =>  lc_vendor_name,
         x_segment1                          =>  lc_segment1,
         x_summary_flag                      =>  lc_summary_flag,
         x_enabled_flag                      =>  lc_enabled_flag,
         x_last_update_login                 =>  FND_GLOBAL.LOGIN_ID,
         x_employee_id                       =>  ln_employee_id,
         x_validation_number                 =>  ln_validation_number,
         x_vendor_type_lookup_code           =>  lc_vendor_type_lookup_code,
         x_customer_num                      =>  lc_customer_num,
         x_one_time_flag                     =>  lc_one_time_flag,
         x_parent_vendor_id                  =>  ln_parent_vendor_id,
         x_min_order_amount                  =>  ln_min_order_amount,
         x_ship_to_location_id               =>  ln_ship_to_location_id,
         x_bill_to_location_id               =>  ln_bill_to_location_id,
         x_ship_via_lookup_code              =>  lc_ship_via_lookup_code,
         x_freight_terms_lookup_code         =>  lc_freight_terms_lookup_code,
         x_fob_lookup_code                   =>  lc_fob_lookup_code,
         x_terms_id                          =>  ln_terms_id,
         x_set_of_books_id                   =>  ln_set_of_books_id,
         x_always_take_disc_flag             =>  lc_always_take_disc_flag,
         x_pay_date_basis_lookup_code        =>  lc_pay_date_basis_lookup_code,
         x_pay_group_lookup_code             =>  lc_pay_group_lookup_code,
         x_payment_priority                  =>  ln_payment_priority,
         x_invoice_currency_code             =>  lc_invoice_currency_code,
         x_payment_currency_code             =>  lc_payment_currency_code,
         x_invoice_amount_limit              =>  ln_invoice_amount_limit,
         x_hold_all_payments_flag            =>  lc_hold_all_payments_flag,
         x_hold_future_payments_flag         =>  lc_hold_future_payments_flag,
         x_hold_reason                       =>  lc_hold_reason,
         x_distribution_set_id               =>  ln_distribution_set_id,
         x_accts_pay_ccid                    =>  ln_accts_pay_ccid,
         x_future_dated_payment_ccid         =>  ln_future_dated_payment_ccid,
         x_prepay_ccid                       =>  ln_prepay_ccid,
         x_num_1099                          =>  lc_num_1099,
         x_type_1099                         =>  p_type_1099,
         x_withholding_stat_lookup_code      =>  lc_withhldng_stat_lookup_code,
         x_withholding_start_date            =>  ld_withholding_start_date,
         x_org_type_lookup_code              =>  lc_org_type_lookup_code,
         x_vat_code                          =>  lc_vat_code,
         x_start_date_active                 =>  ld_start_date_active,
         x_end_date_active                   =>  ld_end_date_active,
         x_qty_rcv_tolerance                 =>  ln_qty_rcv_tolerance,
         x_minority_group_lookup_code        =>  lc_minority_group_lookup_code,
         x_payment_method_lookup_code        =>  lc_payment_method_lookup_code,
         x_bank_account_name                 =>  lc_bank_account_name,
         x_bank_account_num                  =>  lc_bank_account_num,
         x_bank_num                          =>  lc_bank_num,
         x_bank_account_type                 =>  lc_bank_account_type,
         x_women_owned_flag                  =>  lc_women_owned_flag,
         x_small_business_flag               =>  lc_small_business_flag,
         x_standard_industry_class           =>  lc_standard_industry_class,
         x_attribute_category                =>  lc_attribute_category,
         x_attribute1                        =>  lc_attribute1,
         x_attribute2                        =>  lc_attribute2,
         x_attribute3                        =>  lc_attribute3,
         x_attribute4                        =>  lc_attribute4,
         x_attribute5                        =>  lc_attribute5,
         x_hold_flag                         =>  lc_hold_flag,
         x_purchasing_hold_reason            =>  lc_purchasing_hold_reason,
         x_hold_by                           =>  ln_hold_by,
         x_hold_date                         =>  ld_hold_date,
         x_terms_date_basis                  =>  lc_terms_date_basis,
         x_price_tolerance                   =>  ln_price_tolerance,
         x_attribute10                       =>  lc_attribute10,
         x_attribute11                       =>  lc_attribute11,
         x_attribute12                       =>  lc_attribute12,
         x_attribute13                       =>  lc_attribute13,
         x_attribute14                       =>  lc_attribute14,
         x_attribute15                       =>  lc_attribute15,
         x_attribute6                        =>  lc_attribute6,
         x_attribute7                        =>  lc_attribute7,
         x_attribute8                        =>  lc_attribute8,
         x_attribute9                        =>  lc_attribute9,
         x_days_early_receipt_allowed        =>  ln_days_early_receipt_allowed,
         x_days_late_receipt_allowed         =>  ln_days_late_receipt_allowed,
         x_enforce_ship_to_loc_code          =>  lc_enforce_ship_to_loc_code,
         x_exclusive_payment_flag            =>  lc_exclusive_payment_flag,
         x_federal_reportable_flag           =>  lc_federal_reportable_flag,
         x_hold_unmatched_invoices_flag      =>  lc_hold_unmatchd_invoices_flag,
         x_match_option                      =>  lc_match_option,
         x_create_debit_memo_flag            =>  lc_create_debit_memo_flag,
         x_inspection_required_flag          =>  lc_inspection_required_flag,
         x_receipt_required_flag             =>  lc_receipt_required_flag,
         x_receiving_routing_id              =>  ln_receiving_routing_id,
         x_state_reportable_flag             =>  lc_state_reportable_flag,
         x_tax_verification_date             =>  ld_tax_verification_date,
         x_auto_calculate_interest_flag      =>  lc_auto_calc_interest_flag,
         x_name_control                      =>  lc_name_control,
         x_allow_subst_receipts_flag         =>  lc_allow_subst_receipts_flag,
         x_allow_unord_receipts_flag         =>  lc_allow_unord_receipts_flag,
         x_receipt_days_exception_code       =>  lc_receipt_days_exception_code,
         x_qty_rcv_exception_code            =>  lc_qty_rcv_exception_code,
         x_offset_tax_flag                   =>  lc_offset_tax_flag,
         x_exclude_freight_from_disc         =>  lc_exclude_freight_from_disc,
         x_vat_registration_num              =>  lc_vat_registration_num,
         x_tax_reporting_name                =>  lc_tax_reporting_name,
         x_awt_group_id                      =>  ln_awt_group_id,
         x_check_digits                      =>  lc_check_digits,
         x_bank_number                       =>  lc_bank_number,
         x_allow_awt_flag                    =>  lc_allow_awt_flag,
         x_bank_branch_type                  =>  lc_bank_branch_type,
         x_edi_payment_method                =>  lc_edi_payment_method,
         x_edi_payment_format                =>  lc_edi_payment_format,
         x_edi_remittance_method             =>  lc_edi_remittance_method,
         x_edi_remittance_instruction        =>  lc_edi_remittance_instruction,
         x_edi_transaction_handling          =>  lc_edi_transaction_handling,
         x_auto_tax_calc_flag                =>  lc_auto_tax_calc_flag,
         x_auto_tax_calc_override            =>  lc_auto_tax_calc_override,
         x_amount_includes_tax_flag          =>  lc_amount_includes_tax_flag,
         x_ap_tax_rounding_rule              =>  lc_ap_tax_rounding_rule,
         x_vendor_name_alt                   =>  lc_vendor_name_alt,
         x_global_attribute_category         =>  lc_global_attribute_category,
         x_global_attribute1                 =>  lc_global_attribute1,
         x_global_attribute2                 =>  lc_global_attribute2,
         x_global_attribute3                 =>  lc_global_attribute3,
         x_global_attribute4                 =>  lc_global_attribute4,
         x_global_attribute5                 =>  lc_global_attribute5,
         x_global_attribute6                 =>  lc_global_attribute6,
         x_global_attribute7                 =>  lc_global_attribute7,
         x_global_attribute8                 =>  lc_global_attribute8,
         x_global_attribute9                 =>  lc_global_attribute9,
         x_global_attribute10                =>  lc_global_attribute10,
         x_global_attribute11                =>  lc_global_attribute11,
         x_global_attribute12                =>  lc_global_attribute12,
         x_global_attribute13                =>  lc_global_attribute13,
         x_global_attribute14                =>  lc_global_attribute14,
         x_global_attribute15                =>  lc_global_attribute15,
         x_global_attribute16                =>  lc_global_attribute16,
         x_global_attribute17                =>  lc_global_attribute17,
         x_global_attribute18                =>  lc_global_attribute18,
         x_global_attribute19                =>  lc_global_attribute19,
         x_global_attribute20                =>  lc_global_attribute20,
         x_bank_charge_bearer                =>  lc_bank_charge_bearer,
         x_calling_sequence                  =>  NULL);*/
		 
		 AP_VENDORS_PKG.UPDATE_ROW(
		 x_rowid                             =>  lc_rowid,
         x_vendor_id                         =>  p_vendor_id,
         x_last_update_date                  =>  SYSDATE,
         x_last_updated_by                   =>  FND_GLOBAL.USER_ID,
         x_vendor_name                       =>  lc_vendor_name,
         x_segment1                          =>  lc_segment1,
         x_summary_flag                      =>  lc_summary_flag,
         x_enabled_flag                      =>  lc_enabled_flag,
         x_last_update_login                 =>  FND_GLOBAL.LOGIN_ID,
         x_employee_id                       =>  ln_employee_id,
         x_validation_number                 =>  ln_validation_number,
         x_vendor_type_lookup_code           =>  lc_vendor_type_lookup_code,
         x_customer_num                      =>  lc_customer_num,
         x_one_time_flag                     =>  lc_one_time_flag,
         x_parent_vendor_id                  =>  ln_parent_vendor_id,
         x_min_order_amount                  =>  ln_min_order_amount,
         x_terms_id                          =>  ln_terms_id,
         x_set_of_books_id                   =>  ln_set_of_books_id,
         x_always_take_disc_flag             =>  lc_always_take_disc_flag,
         x_pay_date_basis_lookup_code        =>  lc_pay_date_basis_lookup_code,
         x_pay_group_lookup_code             =>  lc_pay_group_lookup_code,
         x_payment_priority                  =>  ln_payment_priority,
         x_invoice_currency_code             =>  lc_invoice_currency_code,
         x_payment_currency_code             =>  lc_payment_currency_code,
         x_invoice_amount_limit              =>  ln_invoice_amount_limit,
         x_hold_all_payments_flag            =>  lc_hold_all_payments_flag,
         x_hold_future_payments_flag         =>  lc_hold_future_payments_flag,
         x_hold_reason                       =>  lc_hold_reason,
         x_num_1099                          =>  lc_num_1099,
         x_type_1099                         =>  p_type_1099,
         x_withholding_stat_lookup_code      =>  lc_withhldng_stat_lookup_code,
         x_withholding_start_date            =>  ld_withholding_start_date,
         x_org_type_lookup_code              =>  lc_org_type_lookup_code,
         x_start_date_active                 =>  ld_start_date_active,
         x_end_date_active                   =>  ld_end_date_active,
         x_qty_rcv_tolerance                 =>  ln_qty_rcv_tolerance,
         x_minority_group_lookup_code        =>  lc_minority_group_lookup_code,
         x_bank_account_name                 =>  lc_bank_account_name,
         x_bank_account_num                  =>  lc_bank_account_num,
         x_bank_num                          =>  lc_bank_num,
         x_bank_account_type                 =>  lc_bank_account_type,
         x_women_owned_flag                  =>  lc_women_owned_flag,
         x_small_business_flag               =>  lc_small_business_flag,
         x_standard_industry_class           =>  lc_standard_industry_class,
         x_attribute_category                =>  lc_attribute_category,
         x_attribute1                        =>  lc_attribute1,
         x_attribute2                        =>  lc_attribute2,
         x_attribute3                        =>  lc_attribute3,
         x_attribute4                        =>  lc_attribute4,
         x_attribute5                        =>  lc_attribute5,
         x_hold_flag                         =>  lc_hold_flag,
         x_purchasing_hold_reason            =>  lc_purchasing_hold_reason,
         x_hold_by                           =>  ln_hold_by,
         x_hold_date                         =>  ld_hold_date,
         x_terms_date_basis                  =>  lc_terms_date_basis,
         x_price_tolerance                   =>  ln_price_tolerance,
         x_attribute10                       =>  lc_attribute10,
         x_attribute11                       =>  lc_attribute11,
         x_attribute12                       =>  lc_attribute12,
         x_attribute13                       =>  lc_attribute13,
         x_attribute14                       =>  lc_attribute14,
         x_attribute15                       =>  lc_attribute15,
         x_attribute6                        =>  lc_attribute6,
         x_attribute7                        =>  lc_attribute7,
         x_attribute8                        =>  lc_attribute8,
         x_attribute9                        =>  lc_attribute9,
         x_days_early_receipt_allowed        =>  ln_days_early_receipt_allowed,
         x_days_late_receipt_allowed         =>  ln_days_late_receipt_allowed,
         x_enforce_ship_to_loc_code          =>  lc_enforce_ship_to_loc_code,
         x_federal_reportable_flag           =>  lc_federal_reportable_flag,
         x_hold_unmatched_invoices_flag      =>  lc_hold_unmatchd_invoices_flag,
         x_match_option                      =>  lc_match_option,
         x_create_debit_memo_flag            =>  lc_create_debit_memo_flag,
         x_inspection_required_flag          =>  lc_inspection_required_flag,
         x_receipt_required_flag             =>  lc_receipt_required_flag,
         x_receiving_routing_id              =>  ln_receiving_routing_id,
         x_state_reportable_flag             =>  lc_state_reportable_flag,
         x_tax_verification_date             =>  ld_tax_verification_date,
         x_auto_calculate_interest_flag      =>  lc_auto_calc_interest_flag,
         x_name_control                      =>  lc_name_control,
         x_allow_subst_receipts_flag         =>  lc_allow_subst_receipts_flag,
         x_allow_unord_receipts_flag         =>  lc_allow_unord_receipts_flag,
         x_receipt_days_exception_code       =>  lc_receipt_days_exception_code,
         x_qty_rcv_exception_code            =>  lc_qty_rcv_exception_code,
         x_exclude_freight_from_disc         =>  lc_exclude_freight_from_disc,
         x_vat_registration_num              =>  lc_vat_registration_num,
         x_tax_reporting_name                =>  lc_tax_reporting_name,
         x_awt_group_id                      =>  ln_awt_group_id,
		 x_pay_awt_group_id                  =>  ln_pay_awt_group_id,
         x_check_digits                      =>  lc_check_digits,
         x_bank_number                       =>  lc_bank_number,
         x_allow_awt_flag                    =>  lc_allow_awt_flag,
         x_bank_branch_type                  =>  lc_bank_branch_type,
         x_vendor_name_alt                   =>  lc_vendor_name_alt,
         x_global_attribute_category         =>  lc_global_attribute_category,
         x_global_attribute1                 =>  lc_global_attribute1,
         x_global_attribute2                 =>  lc_global_attribute2,
         x_global_attribute3                 =>  lc_global_attribute3,
         x_global_attribute4                 =>  lc_global_attribute4,
         x_global_attribute5                 =>  lc_global_attribute5,
         x_global_attribute6                 =>  lc_global_attribute6,
         x_global_attribute7                 =>  lc_global_attribute7,
         x_global_attribute8                 =>  lc_global_attribute8,
         x_global_attribute9                 =>  lc_global_attribute9,
         x_global_attribute10                =>  lc_global_attribute10,
         x_global_attribute11                =>  lc_global_attribute11,
         x_global_attribute12                =>  lc_global_attribute12,
         x_global_attribute13                =>  lc_global_attribute13,
         x_global_attribute14                =>  lc_global_attribute14,
         x_global_attribute15                =>  lc_global_attribute15,
         x_global_attribute16                =>  lc_global_attribute16,
         x_global_attribute17                =>  lc_global_attribute17,
         x_global_attribute18                =>  lc_global_attribute18,
         x_global_attribute19                =>  lc_global_attribute19,
         x_global_attribute20                =>  lc_global_attribute20,
         x_bank_charge_bearer                =>  lc_bank_charge_bearer,
		 x_ni_number                         =>  NULL,
         x_calling_sequence                  =>  NULL);
    -- end of addition
   -- Set the updation status to 'Y' after the updation of the vendor
      x_status := 'Y';


   EXCEPTION
      WHEN OTHERS THEN
         x_status := 'N';
         FND_FILE.PUT_LINE(fnd_file.log,'Vendor Updation Status: '||x_status);
         FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
         FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
         FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
         lc_err_msg := FND_MESSAGE.GET;
         FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

         XX_COM_ERROR_LOG_PUB.LOG_ERROR (
             p_program_type            => 'CONCURRENT PROGRAM'
            ,p_program_name            => gc_concurrent_program_name
            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
            ,p_module_name             => 'AP'
            ,p_error_location          => 'Error at ' || lc_error_loc
            ,p_error_message_count     => 1
            ,p_error_message_code      => 'E'
            ,p_error_message           => lc_err_msg
            ,p_error_message_severity  => 'Major'
            ,p_notify_flag             => 'N'
            ,p_object_type             => '1099 CreditCard'
         );

   END XX_AP_UPDATE_VENDOR;


-- +==========================================================================+
-- | Name : PROCESS                                                           |
-- | Description : To validate the data in the staging table                  |
-- |            xx_ap_creditcard_1099_stg and then load them into the base    |
-- |            tables through the standard interface tables. It calls the    |
-- |            custom insert procedures to insert into the interface tables  |
-- |            and then submits the "Supplier Open Interface Import", the    |
-- |            "Supplier Sites Open Interface Import" and the "Payables Open |
-- |            Interface Import" programs to import the data into the        |
-- |            corresponding base tables.                                    |
-- |                                                                          |
-- | Parameters : x_error_buff, x_ret_code, p_file_name, p_batch_size,        |
-- |            p_user_id, p_login_id, p_reprocess_flag, p_vendor_site        |
-- |            p_description, p_lkp_code_sup_pay, p_type_1099,               |
-- |            p_lkp_type_ven, p_lkp_code_ven, p_lkp_type_pay,               |
-- |            p_lkp_code_site_pay, p_lkp_type_sou, p_lkp_code_sou           |
-- |                                                                          |
-- | Returns :    x_error_buff, x_ret_code                                    |
-- +==========================================================================+
   PROCEDURE PROCESS(
                     x_error_buff        OUT VARCHAR2
                    ,x_ret_code          OUT NUMBER
                    ,p_file_name         IN  VARCHAR2
                    ,p_batch_size        IN  NUMBER
                    ,p_user_id           IN  NUMBER
                    ,p_login_id          IN  NUMBER
                    ,p_reprocess_flag    IN  VARCHAR2
                    ,p_vendor_site       IN  VARCHAR2
                    ,p_description       IN  VARCHAR2 
                    ,p_lkp_code_sup_pay  IN  VARCHAR2
                    ,p_type_1099         IN  VARCHAR2
                    ,p_lkp_type_ven      IN  VARCHAR2
                    ,p_lkp_code_ven      IN  VARCHAR2
                    ,p_lkp_type_pay      IN  VARCHAR2
                    ,p_lkp_code_site_pay IN  VARCHAR2
                    ,p_lkp_type_sou      IN  VARCHAR2
                    ,p_lkp_code_sou      IN  VARCHAR2
                    ,p_lkp_type_acc      IN  VARCHAR2
                    ,p_lkp_code_acc      IN  VARCHAR2 
                    ,p_lkp_code_org      IN  VARCHAR2)

   IS
      ln_batch_id              NUMBER;
      ln_number                NUMBER;
      ln_vnd_count             NUMBER;
      ln_site_count            NUMBER;
      ln_vndr_intfc_id         NUMBER;
      ln_inv_amount            NUMBER;
      lc_valid                 VARCHAR2(1) := 'Y';
      lc_prog_status           VARCHAR2(1);
      lc_status                VARCHAR2(1);
      lc_path                  VARCHAR2(200);
      lc_format                VARCHAR2(25);
      lc_batch_name            VARCHAR2(50);
      lc_vnd_flag              VARCHAR2(1) := 'N';
      lc_vnd_site_flag         VARCHAR2(1) := 'N';
      lc_inv_flag              VARCHAR2(1) := 'N';
      lc_language_code         VARCHAR2(10);
      lc_error_code            VARCHAR2(240);
      EX_SETUP_VAL             EXCEPTION;
      EX_WAIT_REQ              EXCEPTION;
	  -- Commented and added by Darshini for R12 Upgrade Retrofit
      /*ln_vendor_id             po_vendors.vendor_id%TYPE;
      lc_type_1099             po_vendors.type_1099%TYPE;*/
	  ln_vendor_id             ap_suppliers.vendor_id%TYPE;
      lc_type_1099             ap_suppliers.type_1099%TYPE;
	  -- end of addition
      lc_dir_path              dba_directories.directory_path%TYPE;
      ln_conc_request_id       fnd_concurrent_requests.request_id%TYPE;

      TYPE c_ref IS REF CURSOR;
      c_ref_csr_type          c_ref;

      lc_cursor_query         VARCHAR2(1000)
            := 'SELECT  rowid '
                   ||' ,file_name'
                   ||' ,batch_id'
                   ||' ,vendor_name'
                   ||' ,withholding_amount'
                   ||' ,tax_id'
                   ||' ,address_Line1'
                   ||' ,address_Line2'
                   ||' ,city'
                   ||' ,state'
                   ||' ,postal'
                   ||' ,status'
                   ||' ,type_1099'
                   ||' ,request_id'
            ||' FROM xx_ap_creditcard_1099_stg xac WHERE ';

      lc_where_clause         VARCHAR2(100);

      TYPE c_rec_type IS RECORD(
      lc_rowid              VARCHAR2(255)
     ,file_name             xx_ap_creditcard_1099_stg.file_name%TYPE
     ,batch_id              xx_ap_creditcard_1099_stg.batch_id%TYPE
     ,vendor_name           xx_ap_creditcard_1099_stg.vendor_name%TYPE
     ,withholding_amount    xx_ap_creditcard_1099_stg.withholding_amount%TYPE
     ,tax_id                xx_ap_creditcard_1099_stg.tax_id%TYPE
     ,address_Line1         xx_ap_creditcard_1099_stg.address_Line1%TYPE
     ,address_Line2         xx_ap_creditcard_1099_stg.address_Line2%TYPE
     ,city                  xx_ap_creditcard_1099_stg.city%TYPE
     ,state                 xx_ap_creditcard_1099_stg.state%TYPE
     ,postal                xx_ap_creditcard_1099_stg.postal%TYPE
     ,status                xx_ap_creditcard_1099_stg.status%TYPE
     ,type_1099             xx_ap_creditcard_1099_stg.type_1099%TYPE
     ,request_id            xx_ap_creditcard_1099_stg.request_id%TYPE
      );

      lr_c_rec_type         c_rec_type;

      CURSOR c_success(p_group_id IN VARCHAR2)
      IS
      SELECT  vendor_name
             ,invoice_num
             ,invoice_type_lookup_code
             ,invoice_amount
      FROM  ap_invoices_interface
      WHERE group_id = p_group_id
      AND   request_id IN(gn_request3_id, gn_request4_id)
      AND   UPPER(status) = 'PROCESSED'
      AND   UPPER(source) = p_lkp_code_sou
      ORDER BY invoice_num;

      CURSOR c_inv_reject(p_group_id IN VARCHAR2)
      IS
      SELECT  AII.vendor_name
             ,AII.invoice_num
             ,AII.invoice_type_lookup_code
             ,AII.invoice_date
             ,AII.invoice_amount
             ,ALC.displayed_field
      FROM  ap_invoices_interface AII
           ,ap_lookup_codes ALC
           ,ap_interface_rejections AIR
      WHERE group_id = p_group_id
      AND   AIR.parent_id = AII.invoice_id
      AND   AIR.reject_lookup_code = ALC.lookup_code
      AND   request_id IN(gn_request3_id, gn_request4_id)
      AND   ALC.lookup_type = 'REJECT CODE'
      AND   UPPER(status) = 'REJECTED'
      AND   UPPER(source) = p_lkp_code_sou
      ORDER BY invoice_num;


   BEGIN

   -- Printing the Parameters
      lc_error_loc := 'Printing the Parameters of the program';

      FND_FILE.PUT_LINE(fnd_file.log,'Parameters');
      FND_FILE.PUT_LINE(fnd_file.log,'----------');
      FND_FILE.PUT_LINE(fnd_file.log,'File Name:           '||p_file_name);
      FND_FILE.PUT_LINE(fnd_file.log,'Reprocess Only Flag: '||p_reprocess_flag);
      FND_FILE.PUT_LINE(fnd_file.log,'vendor lkp type:     '||p_lkp_type_ven);
      FND_FILE.PUT_LINE(fnd_file.log,'vendor lkp code:     '||p_lkp_code_ven);
      FND_FILE.PUT_LINE(fnd_file.log,'pay lkp type:        '||p_lkp_type_pay);
      FND_FILE.PUT_LINE(fnd_file.log,'Sup pay grp code:    '||p_lkp_code_sup_pay);
      FND_FILE.PUT_LINE(fnd_file.log,'Site pay grp code:   '||p_lkp_code_site_pay);
      FND_FILE.PUT_LINE(fnd_file.log,'Inv source lkp type: '||p_lkp_type_sou);
      FND_FILE.PUT_LINE(fnd_file.log,'Inv source:          '||p_lkp_code_sou);
      FND_FILE.PUT_LINE(fnd_file.log,'vendor site code:    '||p_vendor_site);
      FND_FILE.PUT_LINE(fnd_file.log,'type_1099:           '||p_type_1099);
      FND_FILE.PUT_LINE(fnd_file.log,'Inv description:     '||p_description);
      FND_FILE.PUT_LINE(fnd_file.log,'Inv Acct lkp type:   '||p_lkp_type_acc);
      FND_FILE.PUT_LINE(fnd_file.log,'Inv Acct lkp code:   '||p_lkp_code_acc);
      FND_FILE.PUT_LINE(fnd_file.log,'Orgn lkp code:       '||p_lkp_code_org);
      FND_FILE.PUT_LINE(fnd_file.log,'');

    --Get the Concurrent Program Name 
      lc_error_loc   := 'Get the Concurrent Program Name';

      SELECT FCPT.user_concurrent_program_name
      INTO   gc_concurrent_program_name
      FROM   fnd_concurrent_programs_tl FCPT
      WHERE  FCPT.concurrent_program_id = fnd_global.conc_program_id
      AND    FCPT.language = 'US';


   -- To verify whether the Setups required for the extension are in place
      lc_error_loc := 'Verifying the setups for the extension';

      XX_AP_VERIFY_SETUPS(
                          p_lkp_type_ven
                         ,p_lkp_code_ven
                         ,p_lkp_type_pay
                         ,p_lkp_code_sup_pay
                         ,p_lkp_code_site_pay
                         ,p_lkp_type_sou
                         ,p_lkp_code_sou
                         ,p_lkp_type_acc
                         ,p_lkp_code_acc
                         ,lc_valid
                          );

   -- If any of the setups are not done then the raise the exception
        IF (lc_valid = 'N') THEN

          RAISE EX_SETUP_VAL;

        END IF;

      FND_FILE.PUT_LINE(fnd_file.log, 'Setups Verification Successful..');
      FND_FILE.PUT_LINE(fnd_file.log, '');

   -- Get the invoice account value to populate the dist_code_concatenated column
      SELECT displayed_field
      INTO   gc_inv_account
      FROM   ap_lookup_codes
      WHERE  lookup_type = p_lkp_type_acc
      AND    lookup_code = p_lkp_code_acc;

   -- Get the batch_id from the Sequence xx_ap_cc_1099_batch_stg_s
      SELECT XX_AP_CC_1099_Batch_STG_S.NEXTVAL 
      INTO ln_batch_id 
      FROM SYS.DUAL;


      IF (p_reprocess_flag = 'N') THEN

      -- Constructing the full path for the data file
         BEGIN

            SELECT directory_path
            INTO   lc_dir_path
            FROM   dba_directories
            WHERE  directory_name = 'XXFIN_INBOUND';

            lc_path := lc_dir_path||'/'||p_file_name;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0009_PATH_SETUP');
               lc_err_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

            WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0010_DIR_PATH');
               lc_err_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg||': '||SQLERRM);

         END;

      -- Submit the OD: AP CC1099 Import Program 
         lc_error_loc := 'Submitting the OD: AP CC1099 Import Program';

         FND_FILE.PUT_LINE(fnd_file.log, 'Submitting the OD: AP CC1099 Import Program..');

         ln_conc_request_id := fnd_request.submit_request(
                                            'XXFIN'
                                           ,'XXAPCC1099IMPT'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,lc_path 
                                          );

         FND_FILE.PUT_LINE(fnd_file.log,'OD: AP CC1099 Import Program submitted successfully..');
         FND_FILE.PUT_LINE(fnd_file.log,'Concurrent Program Request id: '||ln_conc_request_id);
         COMMIT;

         FND_FILE.PUT_LINE(fnd_file.log,'Wait till the completion of "OD: AP CC1099 Import Program"..');

         XX_AP_WAIT_FOR_REQUEST(ln_conc_request_id,lc_prog_status);

            IF (lc_prog_status = 'E') THEN

              RAISE EX_WAIT_REQ;

            END IF;

      -- Update the staging table with the batch_id and File_Name
         UPDATE xx_ap_creditcard_1099_stg
         SET batch_id  = ln_batch_id
            ,file_name = p_file_name
            ,type_1099 = p_type_1099
         WHERE request_id = ln_conc_request_id;

      -- Opening the cursor for p_reprocess_flag = 'N'
         lc_where_clause := ' batch_id = :batch_id ';

         OPEN c_ref_csr_type FOR lc_cursor_query ||' '||lc_where_clause
         USING ln_batch_id;


      ELSIF (p_reprocess_flag = 'Y') THEN

      -- Update the staging table with a NEW batch_id for all records whose status = 'R'
         UPDATE xx_ap_creditcard_1099_stg
         SET batch_id = ln_batch_id
            ,status = 'R'
         WHERE status = 'E'
         AND   file_name = p_file_name;

      -- Opening the cursor for p_reprocess_flag = 'Y'
         lc_where_clause := ' status = ''R'' and batch_id = :batch_id ';

         OPEN c_ref_csr_type FOR lc_cursor_query ||' '||lc_where_clause
         USING ln_batch_id;

      END IF;


    --Printing the records Rejected in the staging table 
      lc_error_loc   := 'Printing the Records that got Rejected in the staging table';

      FND_FILE.PUT_LINE(fnd_file.output,'                             OD: AP CreditCard AMEX 1099 Program                    ');
      FND_FILE.PUT_LINE(fnd_file.output,'                             -----------------------------------                    ');
      FND_FILE.PUT_LINE(fnd_file.output,'');
      FND_FILE.PUT_LINE(fnd_file.output,'*******************************Records Rejected in Staging table***************************');
      FND_FILE.PUT_LINE(fnd_file.output,'');
      FND_FILE.PUT_LINE(fnd_file.output,RPAD('Vendor Name',40,' ')
                                      ||RPAD('Withholding Amount',30,' ')
                                      ||'Validation Error');

      FND_FILE.PUT_LINE(fnd_file.output,RPAD('-----------',40,' ')
                                      ||RPAD('------------------',30,' ')
                                      ||'----------------');


      LOOP

         FETCH c_ref_csr_type INTO lr_c_rec_type;
         EXIT WHEN c_ref_csr_type%NOTFOUND;

       --Resetting the flags/variables
         lc_valid := 'Y';
         lc_error_code := NULL;

      -------------------
      -- Data Validations
      -------------------
      -- NOT NULL Validation for Vendor name
         lc_error_loc := 'Validating vendor name';

         IF (lr_c_rec_type.vendor_name IS NULL) THEN

             lc_valid := 'N';

             FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0011_VDR_NUL');
             lc_err_msg := FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(fnd_file.output,RPAD(NVL(lr_c_rec_type.vendor_name,' '),40,' ')
                                             ||RPAD(NVL(lr_c_rec_type.withholding_amount,' '),30,' ')
                                             ||lc_err_msg);

             XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'AP'
                ,p_error_location          => 'Error at ' || lc_error_loc
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => '1099 CreditCard'
             );

             lc_error_code := lc_err_msg;

         END IF;

      -- Validation for Invoice Withholding Amount
         BEGIN

            lc_error_loc := 'Validating Withholding Amount';

            ln_number := TO_NUMBER(lr_c_rec_type.withholding_amount);

            IF (lr_c_rec_type.withholding_amount IS NULL) THEN

               lc_valid := 'N';

               FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0012_AMT_NUL');
               lc_err_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(fnd_file.output,RPAD(NVL(lr_c_rec_type.vendor_name,' '),40,' ')
                                               ||RPAD(NVL(lr_c_rec_type.withholding_amount,' '),30,' ')
                                               ||lc_err_msg);

               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                  ,p_module_name             => 'AP'
                  ,p_error_location          => 'Error at ' || lc_error_loc
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => '1099 CreditCard'
                  ,p_object_id               => lr_c_rec_type.vendor_name
                );

               lc_error_code := lc_error_code||' ; '||lc_err_msg;

            ELSIF (lr_c_rec_type.withholding_amount = 0) THEN

               lc_valid := 'N';

               FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0013_AMT_ZERO');
               lc_err_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(fnd_file.output,RPAD(NVL(lr_c_rec_type.vendor_name,' '),40,' ')
                                               ||RPAD(NVL(lr_c_rec_type.withholding_amount,' '),30,' ')
                                               ||lc_err_msg);

               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                  ,p_module_name             => 'AP'
                  ,p_error_location          => 'Error at ' || lc_error_loc
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => '1099 CreditCard'
                  ,p_object_id               => lr_c_rec_type.vendor_name
               );

               lc_error_code := lc_error_code||' ; '||lc_err_msg;

            END IF;

         EXCEPTION
             WHEN VALUE_ERROR THEN

                 lc_valid := 'N';

                 FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0014_AMT_INVAL');
                 lc_err_msg := FND_MESSAGE.GET;
                 FND_FILE.PUT_LINE(fnd_file.output,RPAD(NVL(lr_c_rec_type.vendor_name,' '),40, ' ')
                                                 ||RPAD(NVL(lr_c_rec_type.withholding_amount,' '),30, ' ')
                                                 ||lc_err_msg);

                 XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                    ,p_module_name             => 'AP'
                    ,p_error_location          => 'Error at ' || lc_error_loc
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => '1099 CreditCard'
                    ,p_object_id               => lr_c_rec_type.vendor_name
                 );

                 lc_error_code := lc_error_code||' ; '||lc_err_msg;

         END;

      -- To validate taxpayer id
         lc_error_loc := 'Validating taxpayer id in flat file';

         SELECT USERENV ('LANG')
         INTO lc_language_code
         FROM DUAL;

         IF (lr_c_rec_type.tax_id IS NOT NULL) THEN
            -- commented and added by Darshini for R12 Upgrade Retrofit
            --IF (AP_PO_VENDORS_APIS_PKG.IS_TAXPAYER_ID_VALID(lr_c_rec_type.tax_id,lc_language_code) = 'N') THEN
            IF (AP_VENDOR_PUB_PKG.IS_TAXPAYER_ID_VALID(lr_c_rec_type.tax_id,lc_language_code) = 'N') THEN
			-- end of addition
               lc_valid := 'N';

               FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0015_TAXID_INVAL');
               lc_err_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(fnd_file.output,RPAD(NVL(lr_c_rec_type.vendor_name,' '),40, ' ')
                                               ||RPAD(NVL(lr_c_rec_type.withholding_amount,' '),30, ' ')
                                               ||lc_err_msg);

               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                  ,p_module_name             => 'AP'
                  ,p_error_location          => 'Error at ' || lc_error_loc
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => '1099 CreditCard'
                  ,p_object_id               => lr_c_rec_type.vendor_name
               );

               lc_error_code := lc_error_code||' ; '||lc_err_msg;

            END IF;

         ELSE

               lc_valid := 'N';

               FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0016_TAXID_NUL');
               lc_err_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(fnd_file.output,RPAD(NVL(lr_c_rec_type.vendor_name,' '),40, ' ')
                                               ||RPAD(NVL(lr_c_rec_type.withholding_amount,' '),30, ' ')
                                               ||lc_err_msg);

               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                  ,p_module_name             => 'AP'
                  ,p_error_location          => 'Error at ' || lc_error_loc
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => '1099 CreditCard'
                  ,p_object_id               => lr_c_rec_type.vendor_name
               );

               lc_error_code := lc_error_code||' ; '||lc_err_msg;

         END IF;

      -- Validation for Addressline1 information
         lc_error_loc := 'Validating Addressline1';

         IF (lr_c_rec_type.address_line1 IS NULL) THEN

             lc_valid := 'N';

             FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0017_ADDR_NUL');
             lc_err_msg := FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(fnd_file.output,RPAD(NVL(lr_c_rec_type.vendor_name,' '),40,' ')
                                             ||RPAD(NVL(lr_c_rec_type.withholding_amount,' '),30,' ')
                                             ||lc_err_msg);

             XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'AP'
                ,p_error_location          => 'Error at ' || lc_error_loc
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => '1099 CreditCard'
             );

             lc_error_code := lc_error_code||' ; '||lc_err_msg;

         END IF;

      -- To verify if there is any vendor duplication in the same batch
         BEGIN

            lc_error_loc   := 'Checking for vendor duplication in the batch';

            SELECT COUNT(1)
            INTO  ln_vnd_count
            FROM  xx_ap_creditcard_1099_stg
            WHERE vendor_name= lr_c_rec_type.vendor_name
            AND   batch_id = ln_batch_id ;

            IF (ln_vnd_count > 1 ) THEN

                lc_valid := 'N';

                FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0018_DUP_VDR');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(fnd_file.output,RPAD(NVL(lr_c_rec_type.vendor_name,' '),40,' ')
                                                ||RPAD(NVL(lr_c_rec_type.withholding_amount,' '),30,' ')
                                                ||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                    p_program_type            => 'CONCURRENT PROGRAM'
                   ,p_program_name            => gc_concurrent_program_name
                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                   ,p_module_name             => 'AP'
                   ,p_error_location          => 'Error at ' || lc_error_loc
                   ,p_error_message_count     => 1
                   ,p_error_message_code      => 'E'
                   ,p_error_message           => lc_err_msg
                   ,p_error_message_severity  => 'Major'
                   ,p_notify_flag             => 'N'
                   ,p_object_type             => '1099 CreditCard'
                   ,p_object_id               => lr_c_rec_type.vendor_name
                );

                lc_error_code := lc_error_code||' ; '||lc_err_msg;

            END IF;

         EXCEPTION
            WHEN OTHERS THEN
                FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
                FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                    p_program_type            => 'CONCURRENT PROGRAM'
                   ,p_program_name            => gc_concurrent_program_name
                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                   ,p_module_name             => 'AP'
                   ,p_error_location          => 'Error at ' || lc_error_loc
                   ,p_error_message_count     => 1
                   ,p_error_message_code      => 'E'
                   ,p_error_message           => lc_err_msg
                   ,p_error_message_severity  => 'Major'
                   ,p_notify_flag             => 'N'
                   ,p_object_type             => '1099 CreditCard'
                   ,p_object_id               => lr_c_rec_type.vendor_name
                 );

         END;


      -- Proceeding further ONLY for the records that PASSED the validation
         IF (lc_valid = 'Y') THEN

         -- To Check if the given supplier already exists
            BEGIN

               lc_error_loc   := 'Fetching the vendor count to check if he already exists';

               SELECT COUNT(1)
               INTO ln_vnd_count
			   -- commented and added by Darshini for R12 Upgrade Retrofit
               --FROM po_vendors
               FROM ap_suppliers
			   -- end of addition
			   WHERE vendor_name = TRIM(lr_c_rec_type.vendor_name);

            EXCEPTION
               WHEN OTHERS THEN
                    FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
                    FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                    FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                        p_program_type            => 'CONCURRENT PROGRAM'
                       ,p_program_name            => gc_concurrent_program_name
                       ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                       ,p_module_name             => 'AP'
                       ,p_error_location          => 'Error at ' || lc_error_loc
                       ,p_error_message_count     => 1
                       ,p_error_message_code      => 'E'
                       ,p_error_message           => lc_err_msg
                       ,p_error_message_severity  => 'Major'
                       ,p_notify_flag             => 'N'
                       ,p_object_type             => '1099 CreditCard'
                     );

            END;

         -- To Check if the site already exists for the given supplier
            BEGIN

               lc_error_loc   := 'Fetching the site count to check if it already exists for the supplier';

               SELECT COUNT(assa.vendor_site_code)
               INTO ln_site_count
			   -- commented and added by Darshini for R12 Upgrade Retrofit
               /*FROM po_vendor_sites_all PVS
                  , po_vendors PV*/
			   FROM ap_supplier_sites_all assa,
			        ap_suppliers aps
			   -- end of addition
               WHERE assa.vendor_id = aps.vendor_id
               AND vendor_site_code= p_vendor_site
               AND vendor_name = TRIM(lr_c_rec_type.vendor_name);

            EXCEPTION
               WHEN OTHERS THEN
                    FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
                    FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                    FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                        p_program_type            => 'CONCURRENT PROGRAM'
                       ,p_program_name            => gc_concurrent_program_name
                       ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                       ,p_module_name             => 'AP'
                       ,p_error_location          => 'Error at ' || lc_error_loc
                       ,p_error_message_count     => 1
                       ,p_error_message_code      => 'E'
                       ,p_error_message           => lc_err_msg
                       ,p_error_message_severity  => 'Major'
                       ,p_notify_flag             => 'N'
                       ,p_object_type             => '1099 CreditCard'
                    );

            END;


         -- If both supplier and site are new then insert new supplier, site and then create the invoices
            IF ( ln_vnd_count = 0
                AND ln_site_count = 0 ) THEN

               lc_vnd_flag := 'Y';
               lc_inv_flag := 'Y';

               FND_FILE.PUT_LINE(fnd_file.log, 'Both vendor and site are new for: '||lr_c_rec_type.vendor_name);
               FND_FILE.PUT_LINE(fnd_file.log, '  Inserting new vendor..');

               lc_error_loc := 'Inserting a new Vendor into AP_SUPPLIERS_INT table';

               XX_AP_INSERT_VENDOR(
                                   lr_c_rec_type.vendor_name
                                  ,lr_c_rec_type.tax_id
                                  ,p_lkp_code_ven
                                  ,p_lkp_code_sup_pay
                                  ,p_type_1099
                                  ,p_lkp_code_org
                                   );

             --To fetch the same vendor_interface_id of the vendor
               SELECT ap_suppliers_int_s.CURRVAL
               INTO ln_vndr_intfc_id
               FROM SYS.DUAL;

               FND_FILE.PUT_LINE(fnd_file.log, '  Inserting new vendor Site..');

               lc_error_loc := 'Inserting Site for the new vendor';

               XX_AP_INSERT_VENDOR_SITE(
                                        ln_vndr_intfc_id
                                       ,NULL
                                       ,p_vendor_site
                                       ,lr_c_rec_type.address_line1
                                       ,lr_c_rec_type.address_line2
                                       ,lr_c_rec_type.city
                                       ,lr_c_rec_type.state
                                       ,lr_c_rec_type.postal
                                       ,p_lkp_code_site_pay
                                       );

               FND_FILE.PUT_LINE(fnd_file.log, '  Inserting STANDARD Invoice for the vendor..');

               lc_error_loc := 'Inserting an Invoice for the new vendor..';

               XX_AP_INSERT_INVOICE(
                                    'STANDARD'
                                   ,lr_c_rec_type.vendor_name
                                   ,lr_c_rec_type.withholding_amount
                                   ,ln_batch_id
                                   ,p_vendor_site
                                   ,p_description
                                   ,p_lkp_code_sou
                                   );

            END IF;


         -- If the Vendor already exists, then first verify the classification and Type_1099
            IF ( ln_vnd_count > 0 ) THEN

            -- Fetch the original Vendor Type and Income tax Type for each supplier
               BEGIN

                  FND_FILE.PUT_LINE(fnd_file.log,'Fetching the original Income tax Type and vendor id..');

                  lc_error_loc := 'Fetching the original Income tax Type and vendor id values';

                  SELECT type_1099, vendor_id
                  INTO lc_type_1099, ln_vendor_id
				  -- commented and added by Darshini for R12 Upgrade Retrofit
                  --FROM po_vendors
				  FROM ap_suppliers
				  -- end of addition
                  WHERE vendor_name = TRIM(lr_c_rec_type.vendor_name);

                  FND_FILE.PUT_LINE(fnd_file.log,'inc tax type: '||lc_type_1099);
                  FND_FILE.PUT_LINE(fnd_file.log,'vendor id: '||ln_vendor_id);

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0019_NO_VDR');
                     lc_err_msg := FND_MESSAGE.GET;
                     FND_FILE.PUT_LINE(fnd_file.log,lc_err_msg);

               END;

            -- Store the Income tax Type and Vendor Type in the staging table
               lc_error_loc := 'Storing the original Type_1099 in the staging table';

               UPDATE xx_ap_creditcard_1099_stg
               SET type_1099 = lc_type_1099
               WHERE rowid = lr_c_rec_type.lc_rowid
               AND batch_id = ln_batch_id;

            -- Update the Vendor with 1099 Vendor Type and Income Tax Type
               IF ( lc_type_1099 <> p_type_1099 
                   OR lc_type_1099 IS NULL ) THEN

                 FND_FILE.PUT_LINE(fnd_file.log,'Updating Income Tax Type before invoice creation');

                 lc_error_loc := 'Updating Income Tax Type before invoice creation';

                 XX_AP_UPDATE_VENDOR(
                                     ln_vendor_id
                                    ,p_type_1099
                                    ,lc_status
                                     );

               END IF;

            END IF;

         -- If supplier exits but site doesnot exist, add the site relevant information and create the invoice
            IF ( ln_vnd_count > 0 
                AND ln_site_count = 0 ) THEN

               lc_vnd_site_flag := 'Y';
               lc_inv_flag      := 'Y';

               FND_FILE.PUT_LINE(fnd_file.log, 'Vendor '||lr_c_rec_type.vendor_name||' exists already,site to be added..');
               FND_FILE.PUT_LINE(fnd_file.log, '  Inserting new Vendor Site into AP_SUPPLIER_SITES_INT..');

               lc_error_loc := 'Inserting a Site for the existing vendor ';

               XX_AP_INSERT_VENDOR_SITE(
                                        NULL
                                       ,ln_vendor_id
                                       ,p_vendor_site
                                       ,lr_c_rec_type.address_line1
                                       ,lr_c_rec_type.address_line2
                                       ,lr_c_rec_type.city
                                       ,lr_c_rec_type.state
                                       ,lr_c_rec_type.postal
                                       ,p_lkp_code_site_pay
                                       );

               FND_FILE.PUT_LINE(fnd_file.log, '  Inserting a STANDARD Invoice for the vendor..');

               lc_error_loc := 'Inserting an Invoice for the existing vendor';

               XX_AP_INSERT_INVOICE(
                                    'STANDARD'
                                   ,lr_c_rec_type.vendor_name
                                   ,lr_c_rec_type.withholding_amount
                                   ,ln_batch_id
                                   ,p_vendor_site
                                   ,p_description
                                   ,p_lkp_code_sou
                                   );

            END IF;


         -- If supplier and site already exist, directly go and create invoice
            IF (ln_vnd_count > 0 
                AND ln_site_count > 0 ) THEN 

               lc_inv_flag := 'Y';

               FND_FILE.PUT_LINE(fnd_file.log,'Both Vendor and Site exist already so directly creating invoice for '||lr_c_rec_type.vendor_name);

               lc_error_loc := 'Directly inserting an invoice for the existing vendor';

               XX_AP_INSERT_INVOICE(
                                    'STANDARD'
                                   ,lr_c_rec_type.vendor_name
                                   ,lr_c_rec_type.withholding_amount
                                   ,ln_batch_id
                                   ,p_vendor_site
                                   ,p_description
                                   ,p_lkp_code_sou
                                   );

            END IF;


         -- Update the status as per the validation results
            lc_error_loc := 'Updating the status column in staging table..';

            UPDATE xx_ap_creditcard_1099_stg
            SET status            = 'P'
               ,error_description = lc_error_code
               ,last_updated_by   = FND_GLOBAL.USER_ID
               ,last_update_date  = SYSDATE
               ,last_update_login = FND_GLOBAL.LOGIN_ID
               ,created_by        = FND_GLOBAL.USER_ID
            WHERE rowid = lr_c_rec_type.lc_rowid
            AND batch_id = ln_batch_id;

         ELSE

            UPDATE xx_ap_creditcard_1099_stg
            SET status            = 'E'
               ,error_description = 'Custom Err Msg: '||lc_error_code
               ,last_updated_by   = FND_GLOBAL.USER_ID
               ,last_update_date  = SYSDATE
               ,last_update_login = FND_GLOBAL.LOGIN_ID
               ,created_by        = FND_GLOBAL.USER_ID
            WHERE rowid = lr_c_rec_type.lc_rowid
            AND batch_id = ln_batch_id;

         END IF;

      END LOOP;

      CLOSE c_ref_csr_type;


      IF (lc_vnd_flag = 'Y') THEN

     -- Submit the "Supplier Open Interface Import" program using FND_REQUEST.SUBMIT_REQUEST.
         FND_FILE.PUT_LINE(fnd_file.log, '');
         FND_FILE.PUT_LINE(fnd_file.log, 'Submitting the Supplier Open Interface Import program.. ');

         lc_error_loc := 'Submitting the Supplier Open Interface Import program';

         ln_conc_request_id := fnd_request.submit_request(
                                            'SQLAP'
                                           ,'APXSUIMP'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'NEW'
                                           ,p_batch_size
                                           ,'N'
                                           ,'N'
                                           ,'N'
                                 );

         FND_FILE.PUT_LINE(fnd_file.log,'Concurrent program submitted successfully');
         FND_FILE.PUT_LINE(fnd_file.log,'Supplier Open Interface Import program Request id: '||ln_conc_request_id);
         COMMIT;

         FND_FILE.PUT_LINE(fnd_file.log, 'Wait till the completion of Supplier Open Interface Import program..');

         XX_AP_WAIT_FOR_REQUEST(
                               ln_conc_request_id
                              ,lc_prog_status
                               );

            IF (lc_prog_status = 'E') THEN

               RAISE EX_WAIT_REQ;

            END IF;

      END IF;


      IF (lc_vnd_flag = 'Y' 
          OR lc_vnd_site_flag = 'Y' ) THEN

      -- Submit the "Supplier Sites Open Interface Import" program using  FND_REQUEST.SUBMIT_REQUEST.
         FND_FILE.PUT_LINE(fnd_file.log, '');
         FND_FILE.PUT_LINE(fnd_file.log, 'Submitting the Supplier Sites Open Interface Import program.. ');

         lc_error_loc := 'Submitting the Supplier Sites Open Interface Import program';

         ln_conc_request_id := fnd_request.submit_request(
                                            'SQLAP'
                                           ,'APXSSIMP'
                                           ,''
                                           ,''
                                           ,FALSE
										   ,FND_PROFILE.VALUE('ORG_ID') -- Added by Darshini for R12 Upgrade Retrofit
                                           ,'NEW'
                                           ,p_batch_size
                                           ,'N'
                                           ,'N'
                                           ,'N'
                                         );

         FND_FILE.PUT_LINE(fnd_file.log,'Concurrent program submitted successfully');
         FND_FILE.PUT_LINE(fnd_file.log,'Supplier Sites Open Interface Import program Request id: '
                                                   ||ln_conc_request_id);
         COMMIT;

         FND_FILE.PUT_LINE(fnd_file.log,'Wait till the completion of Supplier Sites Open Interface Import program .. ');

         XX_AP_WAIT_FOR_REQUEST(
                               ln_conc_request_id
                              ,lc_prog_status
                               );

            IF (lc_prog_status = 'E') THEN

               RAISE EX_WAIT_REQ;

            END IF;

      END IF;


      IF (lc_inv_flag = 'Y') THEN

      -- Submit the "Payables Open Interface Import" program using FND_REQUEST.SUBMIT_REQUEST.
         FND_FILE.PUT_LINE(fnd_file.log, '');
         FND_FILE.PUT_LINE(fnd_file.log, 'Submitting the Payables Open Interface Import program for STANDARD Invoice');

         lc_error_loc := 'Submitting the Payables Open Interface Import program for STANDARD Invoice';

         lc_format := TO_CHAR(SYSDATE,'MONDDYYYY');
         lc_batch_name := '1099_'||lc_format;

         ln_conc_request_id := fnd_request.submit_request( 
                                            'SQLAP'
                                           ,'APXIIMPT'
                                           ,''
                                           ,''
                                           ,FALSE
										   ,FND_PROFILE.VALUE('ORG_ID') -- Added by Darshini for R12 Upgrade Retrofit
                                           ,p_lkp_code_sou
                                           ,ln_batch_id
                                           ,lc_batch_name
                                           ,''
                                           ,''
                                           ,''
                                           ,'N'
                                           ,'N'
                                           ,'N'
                                           ,'N'
                                           ,p_batch_size
                                           ,p_user_id
                                           ,p_login_id 
                                         );

         FND_FILE.PUT_LINE(fnd_file.log,'Concurrent program submitted successfully');
         FND_FILE.PUT_LINE(fnd_file.log,'Payables Open Interface Import program Request id: '
                                                   ||ln_conc_request_id);
         COMMIT;

         gn_request3_id := ln_conc_request_id;

         FND_FILE.PUT_LINE(fnd_file.log,'Wait till the completion of Payables Open Interface Import program - STANDARD.. ');

         XX_AP_WAIT_FOR_REQUEST(
                               ln_conc_request_id
                              ,lc_prog_status
                               );

            IF (lc_prog_status = 'E') THEN

               RAISE EX_WAIT_REQ;

            END IF;

      END IF;


    --Opening the cursor for Updating the vendors
      lc_where_clause := 'status = ''P'' AND  batch_id = :batch_id';

      OPEN c_ref_csr_type FOR lc_cursor_query ||' '||lc_where_clause
      USING ln_batch_id;

      LOOP

         FETCH c_ref_csr_type INTO lr_c_rec_type;
         EXIT WHEN c_ref_csr_type%NOTFOUND;

      -- Updating all the vendors with NULL value for the 'Income tax Type Code'.
         BEGIN

            FND_FILE.PUT_LINE (fnd_file.log,'Getting vendor id to update vendor..');

            SELECT vendor_id
            INTO ln_vendor_id
			-- commented and added by Darshini for R12 Upgrade Retrofit
            --FROM po_vendors
			FROM ap_suppliers
			-- end of addition
            WHERE vendor_name = TRIM(lr_c_rec_type.vendor_name);

         EXCEPTION
             WHEN NO_DATA_FOUND THEN
                FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0019_NO_VDR');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(fnd_file.log,lc_err_msg);

         END;

         FND_FILE.PUT_LINE (fnd_file.log,'Updating the vendor'||' '||lr_c_rec_type.vendor_name||' '||'with Type_1099=NULL..');

         lc_error_loc := 'Updating the vendor with Type_1099=NULL before credit memo creation';

         XX_AP_UPDATE_VENDOR(
                             ln_vendor_id
                            ,NULL
                            ,lc_status
                             );

         lc_error_loc := 'Checking Vendor Updation Status';

         IF (lc_status='Y') THEN

            FND_FILE.PUT_LINE (fnd_file.log,'Vendor successfully updated..');

         -- For each supplier, insert one invoice of type 'CREDIT' with the Income Tax Type Code as NULL 
            lc_error_loc := 'Inserting a CreditMemo Invoice for the vendor ';

            FND_FILE.PUT_LINE (fnd_file.log,'Inserting a CREDIT type invoice for the vendor..');

            ln_inv_amount := '-'||lr_c_rec_type.Withholding_Amount;

            XX_AP_INSERT_INVOICE(
                                  'CREDIT'
                                 ,lr_c_rec_type.vendor_name
                                 ,ln_inv_amount
                                 ,ln_batch_id
                                 ,p_vendor_site
                                 ,p_description
                                 ,p_lkp_code_sou
                                 );

         END IF;

      END LOOP;

      CLOSE c_ref_csr_type;


      IF (lc_inv_flag = 'Y'
           AND lc_status = 'Y') THEN

      -- Submit the "Payables Open Interface Import" program using FND_REQUEST.SUBMIT_REQUEST.
         FND_FILE.PUT_LINE (fnd_file.log,'');
         FND_FILE.PUT_LINE(fnd_file.log,'Submiting the Payables Open Interface Import program for CREDIT type Invoice');

         lc_error_loc := 'Submitting the Payables Open Interface Import program for CREDIT MEMO';

         ln_conc_request_id := fnd_request.submit_request(
                                            'SQLAP'
                                           ,'APXIIMPT'
                                           ,''
                                           ,''
                                           ,FALSE
										   ,FND_PROFILE.VALUE('ORG_ID') -- Added by Darshini for R12 Upgrade Retrofit
                                           ,p_lkp_code_sou
                                           ,ln_batch_id
                                           ,lc_batch_name
                                           ,''
                                           ,''
                                           ,''
                                           ,'N'
                                           ,'N'
                                           ,'N'
                                           ,'N'
                                           ,p_batch_size
                                           ,p_user_id
                                           ,p_login_id 
                                         );

         FND_FILE.PUT_LINE (fnd_file.log,'Concurrent program submitted successfully');
         FND_FILE.PUT_LINE (fnd_file.log,'Payables Open Interface Import program Request id: '
                                                         ||ln_conc_request_id);
         COMMIT;

         gn_request4_id := ln_conc_request_id;

         FND_FILE.PUT_LINE (fnd_file.log,'Wait till the completion of Payables Open Interface Import program - CREDIT MEMO.. ');

         XX_AP_WAIT_FOR_REQUEST(ln_conc_request_id
                               ,lc_prog_status
                               );

            IF (lc_prog_status = 'E') THEN

                RAISE EX_WAIT_REQ;

            END IF;

      END IF;


    --Opening the cursor for Reupdating the vendors
      lc_where_clause := 'status = ''P'' AND batch_id = :batch_id';

      OPEN c_ref_csr_type FOR lc_cursor_query ||' '||lc_where_clause
      USING ln_batch_id;

   -- Reupdate all the suppliers with the actual value for the 'Income Tax Type Code'.
      LOOP

         FETCH c_ref_csr_type INTO lr_c_rec_type;
         EXIT WHEN c_ref_csr_type%NOTFOUND;

         BEGIN

            FND_FILE.PUT_LINE (fnd_file.log,'Getting the vendor id to Re-update the vendor');

            SELECT vendor_id
            INTO   ln_vendor_id
			-- commented and added by Darshini for R12 Upgrade Retrofit
            --FROM   po_vendors
			FROM ap_suppliers
			-- end of addition
            WHERE  vendor_name = TRIM(lr_c_rec_type.vendor_name);

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0019_NO_VDR');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(fnd_file.log,lc_err_msg);

         END;

         BEGIN
            FND_FILE.PUT_LINE (fnd_file.log,'Getting the stored value to Re-update the vendor');

            lc_error_loc := 'Getting the stored value of Type_1099 to Re-update the vendor';

            SELECT type_1099
            INTO lc_type_1099
            FROM xx_ap_creditcard_1099_stg
            WHERE vendor_name = TRIM(lr_c_rec_type.vendor_name)
            AND batch_id = ln_batch_id;

         EXCEPTION
            WHEN OTHERS THEN
                FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERR');
                FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                    p_program_type            => 'CONCURRENT PROGRAM'
                   ,p_program_name            => gc_concurrent_program_name
                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                   ,p_module_name             => 'AP'
                   ,p_error_location          => 'Error at ' || lc_error_loc
                   ,p_error_message_count     => 1
                   ,p_error_message_code      => 'E'
                   ,p_error_message           => lc_err_msg
                   ,p_error_message_severity  => 'Major'
                   ,p_notify_flag             => 'N'
                   ,p_object_type             => '1099 CreditCard'
                   ,p_object_id               => lc_type_1099
                );

         END;

         FND_FILE.PUT_LINE(fnd_file.log,'  The original Income Tax Type: '||lc_type_1099);

         FND_FILE.PUT_LINE(fnd_file.log,'Re-updating the vendor'||' '||lr_c_rec_type.vendor_name||' '||'with actual values..');

         lc_error_loc := 'Re-updating the Vendors with the original value of Type_1099';

         XX_AP_UPDATE_VENDOR(
                             ln_vendor_id
                            ,lc_type_1099
                            ,lc_status
                             );

         lc_error_loc := 'Checking Vendor Reupdation Status';

         IF (lc_status='Y') THEN

            FND_FILE.PUT_LINE(fnd_file.log,'Vendor successfully re-updated');
            FND_FILE.PUT_LINE(fnd_file.log,'');

         END IF;

      END LOOP;

      CLOSE c_ref_csr_type;


    --Printing the Successfully processed invoices
      lc_error_loc   := 'Printing the Successfully processed records';

      FND_FILE.PUT_LINE(fnd_file.output,'');
      FND_FILE.PUT_LINE(fnd_file.output,'');
      FND_FILE.PUT_LINE(fnd_file.output,'**************************************Imported Invoices**************************************');
      FND_FILE.PUT_LINE(fnd_file.output,'');
      FND_FILE.PUT_LINE(fnd_file.output,RPAD('Supplier Name',40, ' ')
                                      ||RPAD('Invoice Number',20, ' ')
                                      ||RPAD('Invoice Type',20, ' ')
                                      ||RPAD('Invoice Amount',20, ' '));
      FND_FILE.PUT_LINE(fnd_file.output,RPAD('-------------',40, ' ')
                                      ||RPAD('--------------',20, ' ')
                                      ||RPAD('------------',20, ' ')
                                      ||RPAD('--------------',20, ' '));

    --Opening the cursor for Successfully processed records 
      lc_error_loc   := 'Opening the cursor for Successfully processed records';

      FOR lcu_c_success IN c_success(ln_batch_id)
      LOOP

          FND_FILE.PUT_LINE(fnd_file.output,RPAD(lcu_c_success.vendor_name,40, ' ')
                                          ||RPAD(lcu_c_success.invoice_num,20, ' ')
                                          ||RPAD(lcu_c_success.invoice_type_lookup_code,20, ' ')
                                          ||RPAD(lcu_c_success.invoice_amount,20, ' '));

      END LOOP;

      FND_FILE.PUT_LINE(fnd_file.output,'');


    --Printing the Rejected invoices
      lc_error_loc   := 'Printing The Rejected Records';

      FND_FILE.PUT_LINE(fnd_file.output,'');
      FND_FILE.PUT_LINE(fnd_file.output,'**************************************Rejected Invoices**************************************');
      FND_FILE.PUT_LINE(fnd_file.output,'');
      FND_FILE.PUT_LINE(fnd_file.output,RPAD('Supplier Name',40, ' ')
                                      ||RPAD('Invoice Number',20, ' ')
                                      ||RPAD('Invoice Type',20, ' ')
                                      ||RPAD('Invoice Amount',20, ' ')
                                      ||'Rejection Reason');
      FND_FILE.PUT_LINE(fnd_file.output,RPAD('-------------',40, ' ')
                                      ||RPAD('--------------',20, ' ')
                                      ||RPAD('------------',20, ' ')
                                      ||RPAD('--------------',20, ' ')
                                      ||'----------------');

    --Opening the cursor for the Rejected records 
      lc_error_loc   := 'Opening the cursor for the Rejected records';

      FOR lcu_c_inv_reject IN c_inv_reject(ln_batch_id)
      LOOP

          FND_FILE.PUT_LINE(fnd_file.output,RPAD(lcu_c_inv_reject.vendor_name,40, ' ')
                                          ||RPAD(lcu_c_inv_reject.invoice_num,20, ' ')
                                          ||RPAD(lcu_c_inv_reject.invoice_type_lookup_code,20, ' ')
                                          ||RPAD(lcu_c_inv_reject.invoice_amount,20, ' ')
                                          ||lcu_c_inv_reject.displayed_field);

        --Updating the status in the staging table if invoice creation fails
          UPDATE xx_ap_creditcard_1099_stg
          SET status            = 'E'
             ,error_description = 'Standard Err Msg: '||lcu_c_inv_reject.displayed_field
             ,last_updated_by   = FND_GLOBAL.USER_ID
             ,last_update_date  = SYSDATE
             ,last_update_login = FND_GLOBAL.LOGIN_ID
             ,created_by        = FND_GLOBAL.USER_ID
          WHERE vendor_name = lcu_c_inv_reject.vendor_name
          AND batch_id = ln_batch_id;

      END LOOP;


   EXCEPTION
          WHEN EX_SETUP_VAL THEN
                FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0020_SETUP_FAIL');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(fnd_file.log,lc_err_msg);
                x_ret_code := 2;

          WHEN EX_WAIT_REQ THEN
                FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0021_CON_ERR');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(fnd_file.log,lc_err_msg);
                x_ret_code := 2;

          WHEN OTHERS THEN
                FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0022_PRO_ERR');
                FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(fnd_file.log, lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                    p_program_type            => 'CONCURRENT PROGRAM'
                   ,p_program_name            => gc_concurrent_program_name
                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                   ,p_module_name             => 'AP'
                   ,p_error_location          => 'Error at ' || lc_error_loc
                   ,p_error_message_count     => 1
                   ,p_error_message_code      => 'E'
                   ,p_error_message           => lc_err_msg
                   ,p_error_message_severity  => 'Major'
                   ,p_notify_flag             => 'N'
                   ,p_object_type             => '1099 CreditCard'
                );

                x_ret_code := 2;

   END PROCESS;

END XX_AP_CC_1099_PKG;
/
SHOW ERROR