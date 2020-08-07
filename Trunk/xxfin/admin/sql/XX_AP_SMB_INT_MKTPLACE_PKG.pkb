SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE BODY XX_AP_SMB_INT_MKTPLACE_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project                                                                    |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_SMB_INT_MKTPLACE_PKG                                                       |
  -- |  RICE ID   :                                                                               |
  -- |  Description:                                                                              |
  -- |                                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author              Remarks                                       |
  -- | =========   ===========  =============       ==============================================|
  -- | 1.0         10/08/2018   Arun D'Souza        Initial Version-    SMB Internal Marketplace  |
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Name  : Log Exception                                                                     |
  -- |  Description: The log_exception procedure logs all exceptions                              |
  -- =============================================================================================|
  gc_debug VARCHAR2(2);
  gn_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_user_id fnd_concurrent_requests.requested_by%TYPE;
  gn_login_id NUMBER;
  --  gn_bad_rec_flag       NUMBER :=0;
  --  gn_count              NUMBER :=0;
  ln_conc_request_id NUMBER;
PROCEDURE log_exception(
    p_program_name   IN VARCHAR2 ,
    p_error_location IN VARCHAR2 ,
    p_error_msg      IN VARCHAR2)
IS
  ln_login   NUMBER := FND_GLOBAL.LOGIN_ID;
  ln_user_id NUMBER := FND_GLOBAL.USER_ID;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error( p_return_code => FND_API.G_RET_STS_ERROR ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'Custom Messages' ,p_program_name => p_program_name ,p_attribute15 => p_program_name ,p_program_id => NULL ,p_module_name => 'AP' ,p_error_location => p_error_location ,p_error_message_code => NULL ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error while writing to the log ...'|| SQLERRM);
END log_exception;
/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_Message := p_message;
    fnd_file.put_line (fnd_file.log, lc_Message);
    IF ( fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      dbms_output.put_line (lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_debug_msg;
/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  lc_message := p_message;
  fnd_file.put_line (fnd_file.output, lc_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    dbms_output.put_line (lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_out_msg;
-- +============================================================================================+
-- |  Name  : parse_smb_file                                                                   |
-- |  Description: Procedure to parse string and load them into the file                        |
-- =============================================================================================|
PROCEDURE parse_and_load_smb_file(
    p_string IN VARCHAR2 ,
    p_inserted_cnt OUT NUMBER,
    p_error_msg OUT VARCHAR2 ,
    p_errcode OUT VARCHAR2 )
IS
  l_string VARCHAR2(32767) := REPLACE(p_string,'"','');
  --  l_string VARCHAR2(32767) := '2004;Fake Store;Fake;Fake Last;Fake First;102, Fake Street;Fake Pakoda;;33333;Fake City;USA;;fakestoreemail@fake.com;true;;;2018-09-28 20:55:10.4918;2018-09-21 06:00:02.888004;2018-09-28 20:55:10.4918;230189;;;;;;;;1347;44;130.7;0;564;13.5;54.6;0;0;0;76.1;0;737.4;;;0;0;0;0;USD;ABA;test;test;;;;;;12345678901234;56008849';
  --  l_string        VARCHAR2(32767) :=   replace('"2002;""HP Store"";""Hewlett Packet"";""Kirsten"";""Dust"";""6503 N Military Til"";""2501"";"""";""33486"";""Boca Raton"";""USA"";""Florida"";""kdust@hp.com"";""true"";""TMK1306572"";"""";""2018-10-16 22:36:02.208882"";""2018-07-09 20:57:52.243"";""2018-10-16 22:36:02.208882"";""230190"";"""";"""";"""";"""";"""";"""";"""";""4213.99"";""32.99"";""424.70"";""0.00"";""10.00"";""0.00"";""1.00"";""0.00"";""35.00"";""0.00"";""458.70"";""0.00"";""3778.28"";"""";""TMK1306572"";""0.00"";""0.00"";""0.00"";""0.00"";""USD"";""ABA"";""Test"";""Teste"";"""";"""";"""";"""";"""";""12345678901234"";""056008849"";"""""','"','');
  l_pos_start        NUMBER (5);
  l_pos_end          NUMBER (5);
  l_invoice_dt_yy    VARCHAR2(2);
  l_invoice_dt_mm    VARCHAR2(2);
  l_invoice_dt_dd    VARCHAR2(2);
  l_sys_dt_yy        VARCHAR2(2);
  l_sys_dt_mm        VARCHAR2(2);
  l_sys_dt_dd        VARCHAR2(2);
  l_dt_created_trunc VARCHAR2(50);
  lc_field_name      VARCHAR2(100);
  lc_code_locn       VARCHAR2(100);
  l_record_exists    BOOLEAN;
  lc_exist_ind       VARCHAR2(1);
  ld_semicolon_cnt   NUMBER := 0;
  l_smb_stg_record xx_ap_smb_int_mkt_stg%ROWTYPE;
  lc_error_mesg VARCHAR2(250);
  DATA_ERROR    EXCEPTION;
  ------- SMB Payment Voucher Record Layout ----------------------------------------------------
  l_shop_id VARCHAR2(1000); -- Supplier Site Ref# DFF
  -- Invoice HDR Description is l_start_time || l_end_time
  l_shop_name                    VARCHAR2(1000);
  l_shop_corporate_name          VARCHAR2(1000);
  l_shop_address_lastname        VARCHAR2(1000);
  l_shop_address_firstname       VARCHAR2(1000);
  l_shop_address_street1         VARCHAR2(1000);
  l_shop_address_street2         VARCHAR2(1000);
  l_shop_address_complementary   VARCHAR2(1000);
  l_shop_address_zip_code        VARCHAR2(1000);
  l_shop_address_city            VARCHAR2(1000);
  l_shop_address_country         VARCHAR2(1000);
  l_shop_address_state           VARCHAR2(1000);
  l_shop_email                   VARCHAR2(1000);
  l_shop_is_professional         VARCHAR2(1000);
  l_shop_siret                   VARCHAR2(1000);
  l_shop_vat_number              VARCHAR2(1000);
  l_date_created                 VARCHAR2(1000);
  l_start_time                   VARCHAR2(1000);
  l_end_time                     VARCHAR2(1000);
  l_invoice_number               VARCHAR2(1000);
  l_billing_info_owner           VARCHAR2(1000);
  l_billing_info_bank_name       VARCHAR2(1000);
  l_billing_info_bank_street     VARCHAR2(1000);
  l_billing_info_bank_zip        VARCHAR2(1000);
  l_billing_info_bank_city       VARCHAR2(1000);
  l_billing_info_bic             VARCHAR2(1000);
  l_billing_info_iban            VARCHAR2(1000);
  l_order_amount                 VARCHAR2(1000);
  l_order_shipping_amount        VARCHAR2(1000);
  l_order_commission_amount      VARCHAR2(1000);
  l_order_commission_amount_vat  VARCHAR2(1000);
  l_refund_amount                VARCHAR2(1000);
  l_refund_shipping_amount       VARCHAR2(1000);
  l_refund_commission_amount     VARCHAR2(1000);
  l_refund_commission_amount_vat VARCHAR2(1000);
  l_subscription_amount          VARCHAR2(1000);
  l_subscription_amount_vat      VARCHAR2(1000);
  l_total_charged_amount         VARCHAR2(1000);
  l_total_charged_amount_vat     VARCHAR2(1000);
  l_transfer_amount              VARCHAR2(1000);
  l_shop_operator_internal_id    VARCHAR2(1000);
  l_shop_identification_number   VARCHAR2(1000); -- Vendor Site Code also Mirakl System Business Regn No
  l_total_manual_invoice_amount  VARCHAR2(1000);
  l_tot_manual_invoice_amt_vat   VARCHAR2(1000);
  l_total_manual_credit_amount   VARCHAR2(1000);
  l_tot_manual_credit_amt_vat    VARCHAR2(1000);
  l_currency_iso_code            VARCHAR2(1000);
  l_payment_info_type            VARCHAR2(1000);
  l_payment_info_owner           VARCHAR2(1000);
  l_payment_info_bank_name       VARCHAR2(1000);
  l_payment_info_bank_city       VARCHAR2(1000);
  l_payment_info_bank_zip        VARCHAR2(1000);
  l_payment_info_bank_street     VARCHAR2(1000);
  l_payinfo_ibantype_iban        VARCHAR2(1000);
  l_payment_info_ibantype_bic    VARCHAR2(1000);
  l_payinfo_abatype_bank_acct_no VARCHAR2(1000);
  l_payinfo_abatype_routing_no   VARCHAR2(1000);
  l_payment_info_abatype_bic     VARCHAR2(1000);
PROCEDURE get_next_pos
AS
BEGIN
  l_pos_start := NVL (l_pos_end, 1);
  l_pos_end   := INSTR (l_string, ';', l_pos_start + 1, 1);
END;
BEGIN
  lc_code_locn := 'INIT';
  l_pos_start  := NULL;
  l_pos_end    := NULL;
  get_next_pos;
  lc_code_locn := 'PARSE';
  l_string     := l_string || ';';
  l_shop_id    := SUBSTR (l_string, l_pos_start, l_pos_end - (l_pos_start));
  l_shop_id    := UPPER (ltrim(rtrim(l_shop_id)));
  IF l_shop_id  = 'SHOP-ID' THEN
    --     gn_bad_rec_flag := 1;
    p_error_msg := 'Skipping the Column Header record. Line with String - ' || TRIM(l_string);
    print_debug_msg (p_error_msg,FALSE);
    RETURN;
  END IF;
  SELECT REGEXP_COUNT(l_string, ';') INTO ld_semicolon_cnt FROM dual;
  IF NVL(ld_semicolon_cnt,0) != 58 THEN
    lc_error_mesg            := 'Invalid number of columns in data record - expecting 58 columns and data file contains ' || TO_CHAR(ld_semicolon_cnt) || ' columns!';
    raise DATA_ERROR;
  END IF;
  print_debug_msg ('Shop ID : ' || l_shop_id,FALSE);
  -- l_smb_stg_record.shop_id := UPPER (l_shop_id);
  get_next_pos;
  l_shop_name := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_name := UPPER (ltrim(rtrim(l_shop_name)));
  -- l_smb_stg_record.shop_name := UPPER (ltrim(rtrim(l_shop_name)));
  print_debug_msg ('Shop Name : ' || l_shop_name,FALSE);
  get_next_pos;
  l_shop_corporate_name := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_corporate_name := UPPER (ltrim(rtrim(l_shop_corporate_name)));
  -- l_smb_stg_record.shop_corporate_name := UPPER (ltrim(rtrim(l_shop_corporate_name)));
  print_debug_msg ('l_shop_corporate_name : ' || l_shop_corporate_name);
  get_next_pos;
  l_shop_address_lastname := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_address_lastname := UPPER (ltrim(rtrim(l_shop_address_lastname)));
  -- l_smb_stg_record.shop_address_lastname := UPPER (ltrim(rtrim(l_shop_address_lastname)));
  print_debug_msg('l_shop_address_lastname : ' || l_shop_address_lastname);
  get_next_pos;
  l_shop_address_firstname := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_address_firstname := UPPER (ltrim(rtrim(l_shop_address_firstname)));
  -- l_smb_stg_record.shop_address_firstname := UPPER (ltrim(rtrim(l_shop_address_firstname)));
  print_debug_msg('l_shop_address_firstname : ' || l_shop_address_firstname);
  get_next_pos;
  l_shop_address_street1 := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_address_street1 := UPPER (ltrim(rtrim(l_shop_address_street1)));
  -- l_smb_stg_record.shop_address_street1 := UPPER (ltrim(rtrim(l_shop_address_street1)));
  print_debug_msg ('l_shop_address_street1 : ' || l_shop_address_street1);
  get_next_pos;
  l_shop_address_street2 := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_address_street2 := UPPER (ltrim(rtrim(l_shop_address_street2)));
  -- l_smb_stg_record.shop_address_street2 := UPPER (ltrim(rtrim(l_shop_address_street2)));
  print_debug_msg('l_shop_address_street2 : ' || l_shop_address_street2);
  get_next_pos;
  l_shop_address_complementary := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_address_complementary := UPPER (ltrim(rtrim(l_shop_address_complementary)));
  -- l_smb_stg_record.shop_address_complementary := UPPER (ltrim(rtrim(l_shop_address_complementary)));
  print_debug_msg('l_shop_address_complementary : ' || l_shop_address_complementary);
  get_next_pos;
  l_shop_address_zip_code := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_address_zip_code := UPPER (ltrim(rtrim(l_shop_address_zip_code)));
  -- l_smb_stg_record.shop_address_zip_code := UPPER (ltrim(rtrim(l_shop_address_zip_code)));
  print_debug_msg('l_shop_address_zip_code : ' || l_shop_address_zip_code);
  get_next_pos;
  l_shop_address_city := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_address_city := UPPER (ltrim(rtrim(l_shop_address_city)));
  -- l_smb_stg_record.shop_address_city := UPPER (ltrim(rtrim(l_shop_address_city)));
  print_debug_msg('l_shop_address_city : ' || l_shop_address_city);
  get_next_pos;
  l_shop_address_country := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_address_country := UPPER (ltrim(rtrim(l_shop_address_country)));
  -- l_smb_stg_record.shop_address_country := UPPER (ltrim(rtrim(l_shop_address_country)));
  print_debug_msg('l_shop_address_country : ' || l_shop_address_country);
  get_next_pos;
  l_shop_address_state := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_address_state := UPPER (ltrim(rtrim(l_shop_address_state)));
  -- l_smb_stg_record.shop_address_state := UPPER (ltrim(rtrim(l_shop_address_state)));
  print_debug_msg('l_shop_address_state : ' || l_shop_address_state);
  get_next_pos;
  l_shop_email := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_email := UPPER (ltrim(rtrim(l_shop_email)));
  -- l_smb_stg_record.shop_email := UPPER (ltrim(rtrim(l_shop_email)));
  print_debug_msg('l_shop_email : ' || l_shop_email);
  get_next_pos;
  l_shop_is_professional := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_is_professional := UPPER (ltrim(rtrim(l_shop_is_professional)));
  -- l_smb_stg_record.shop_is_professional := UPPER (ltrim(rtrim(l_shop_is_professional)));
  print_debug_msg('l_shop_is_professional : ' || l_shop_is_professional);
  get_next_pos;
  l_shop_siret := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_siret := UPPER (ltrim(rtrim(l_shop_siret)));
  -- l_smb_stg_record.shop_siret := UPPER (ltrim(rtrim(l_shop_siret)));
  print_debug_msg('l_shop_siret : ' || l_shop_siret);
  get_next_pos;
  l_shop_vat_number := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_vat_number := UPPER (ltrim(rtrim(l_shop_vat_number)));
  -- l_smb_stg_record.shop_vat_number := UPPER (ltrim(rtrim(l_shop_vat_number)));
  print_debug_msg('l_shop_vat_number : ' || l_shop_vat_number);
  get_next_pos;
  l_date_created := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_date_created := UPPER (ltrim(rtrim(l_date_created)));
  -- l_smb_stg_record.date_created := UPPER (ltrim(rtrim(l_date_created)));
  print_debug_msg('l_date_created : ' || l_date_created);
  get_next_pos;
  l_start_time := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_start_time := UPPER (ltrim(rtrim(l_start_time)));
  -- l_smb_stg_record.start_time := UPPER (ltrim(rtrim(l_start_time)));
  print_debug_msg('l_start_time : ' || l_start_time);
  get_next_pos;
  l_end_time := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_end_time := UPPER (ltrim(rtrim(l_end_time)));
  print_debug_msg('l_end_time : ' || l_end_time);
  -- l_smb_stg_record.end_time := UPPER (ltrim(rtrim(l_end_time)));
  get_next_pos;
  l_invoice_number := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_invoice_number := UPPER (ltrim(rtrim(l_invoice_number)));
  -- l_smb_stg_record.invoice_number := UPPER (ltrim(rtrim(l_invoice_number)));
  print_debug_msg('l_invoice_number : ' || l_invoice_number);
  get_next_pos;
  l_billing_info_owner := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_billing_info_owner := UPPER (ltrim(rtrim(l_billing_info_owner)));
  -- l_smb_stg_record.billing_info_owner := UPPER (ltrim(rtrim(l_billing_info_owner)));
  print_debug_msg('l_billing_info_owner : ' || l_billing_info_owner);
  get_next_pos;
  l_billing_info_bank_name := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_billing_info_bank_name := UPPER (ltrim(rtrim(l_billing_info_bank_name)));
  -- l_smb_stg_record.billing_info_bank_name := UPPER (ltrim(rtrim(l_billing_info_bank_name)));
  print_debug_msg('l_billing_info_bank_name : ' || l_billing_info_bank_name);
  get_next_pos;
  l_billing_info_bank_street := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_billing_info_bank_street := UPPER (ltrim(rtrim(l_billing_info_bank_street)));
  -- l_smb_stg_record.billing_info_bank_street := UPPER (ltrim(rtrim(l_billing_info_bank_street)));
  print_debug_msg('l_billing_info_bank_street : ' || l_billing_info_bank_street);
  get_next_pos;
  l_billing_info_bank_zip := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_billing_info_bank_zip := UPPER (ltrim(rtrim(l_billing_info_bank_zip)));
  -- l_smb_stg_record.billing_info_bank_zip := UPPER (ltrim(rtrim(l_billing_info_bank_zip)));
  print_debug_msg('l_billing_info_bank_zip : ' || l_billing_info_bank_zip);
  get_next_pos;
  l_billing_info_bank_city := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_billing_info_bank_city := UPPER (ltrim(rtrim(l_billing_info_bank_city)));
  -- l_smb_stg_record.billing_info_bank_city := UPPER (ltrim(rtrim(l_billing_info_bank_city)));
  print_debug_msg('l_billing_info_bank_city : ' || l_billing_info_bank_city);
  get_next_pos;
  l_billing_info_bic := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_billing_info_bic := UPPER (ltrim(rtrim(l_billing_info_bic)));
  -- l_smb_stg_record.billing_info_bic := UPPER (ltrim(rtrim(l_billing_info_bic)));
  print_debug_msg('l_billing_info_bic : ' || l_billing_info_bic);
  get_next_pos;
  l_billing_info_iban := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_billing_info_iban := UPPER (ltrim(rtrim(l_billing_info_iban)));
  -- l_smb_stg_record.billing_info_iban := UPPER (ltrim(rtrim(l_billing_info_iban)));
  print_debug_msg('l_billing_info_iban : ' || l_billing_info_iban);
  get_next_pos;
  l_order_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_order_amount := UPPER (ltrim(rtrim(l_order_amount)));
  -- l_smb_stg_record.order_amount := UPPER (ltrim(rtrim(l_order_amount)));
  print_debug_msg('l_order_amount : ' || l_order_amount);
  get_next_pos;
  l_order_shipping_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_order_shipping_amount := UPPER (ltrim(rtrim(l_order_shipping_amount)));
  -- l_smb_stg_record.order_shipping_amount := UPPER (ltrim(rtrim(l_order_shipping_amount)));
  print_debug_msg('l_order_shipping_amount : ' || l_order_shipping_amount);
  get_next_pos;
  l_order_commission_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_order_commission_amount := UPPER (ltrim(rtrim(l_order_commission_amount)));
  -- l_smb_stg_record.order_commission_amount := UPPER (ltrim(rtrim(l_order_commission_amount)));
  print_debug_msg('l_order_commission_amount : ' || l_order_commission_amount);
  get_next_pos;
  l_order_commission_amount_vat := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_order_commission_amount_vat := UPPER (ltrim(rtrim(l_order_commission_amount_vat)));
  -- l_smb_stg_record.order_commission_amount_vat := UPPER (ltrim(rtrim(l_order_commission_amount_vat)));
  print_debug_msg('l_order_commission_amount_vat : ' || l_order_commission_amount_vat);
  get_next_pos;
  l_refund_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_refund_amount := UPPER (ltrim(rtrim(l_refund_amount)));
  -- l_smb_stg_record.refund_amount := UPPER (ltrim(rtrim(l_refund_amount)));
  print_debug_msg('l_refund_amount : ' || l_refund_amount);
  get_next_pos;
  l_refund_shipping_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_refund_shipping_amount := UPPER (ltrim(rtrim(l_refund_shipping_amount)));
  -- l_smb_stg_record.refund_shipping_amount := UPPER (ltrim(rtrim(l_refund_shipping_amount)));
  print_debug_msg('l_refund_shipping_amount : ' || l_refund_shipping_amount);
  get_next_pos;
  l_refund_commission_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_refund_commission_amount := UPPER (ltrim(rtrim(l_refund_commission_amount)));
  -- l_smb_stg_record.refund_commission_amount := UPPER (ltrim(rtrim(l_refund_commission_amount)));
  print_debug_msg('l_refund_commission_amount : ' || l_refund_commission_amount);
  get_next_pos;
  l_refund_commission_amount_vat := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_refund_commission_amount_vat := UPPER (ltrim(rtrim(l_refund_commission_amount_vat)));
  -- l_smb_stg_record.refund_commission_amount_vat := UPPER (ltrim(rtrim(l_refund_commission_amount_vat)));
  print_debug_msg ('l_refund_commission_amount_vat : ' || l_refund_commission_amount_vat);
  get_next_pos;
  l_subscription_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_subscription_amount := UPPER (ltrim(rtrim(l_subscription_amount)));
  -- l_smb_stg_record.subscription_amount := UPPER (ltrim(rtrim(l_subscription_amount)));
  print_debug_msg ('l_subscription_amount : ' || l_subscription_amount);
  get_next_pos;
  l_subscription_amount_vat := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_subscription_amount_vat := UPPER (ltrim(rtrim(l_subscription_amount_vat)));
  -- l_smb_stg_record.subscription_amount_vat := UPPER (ltrim(rtrim(l_subscription_amount_vat)));
  print_debug_msg ('l_subscription_amount_vat : ' || l_subscription_amount_vat);
  get_next_pos;
  l_total_charged_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_total_charged_amount := UPPER (ltrim(rtrim(l_total_charged_amount)));
  -- l_smb_stg_record.total_charged_amount := UPPER (ltrim(rtrim(l_total_charged_amount)));
  print_debug_msg ('l_total_charged_amount : ' || l_total_charged_amount);
  get_next_pos;
  l_total_charged_amount_vat := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_total_charged_amount_vat := UPPER (ltrim(rtrim(l_total_charged_amount_vat)));
  -- l_smb_stg_record. total_charged_amount_vat := UPPER (ltrim(rtrim(l_total_charged_amount_vat)));
  print_debug_msg ('l_total_charged_amount_vat : ' || l_total_charged_amount_vat);
  get_next_pos;
  l_transfer_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_transfer_amount := UPPER (ltrim(rtrim(l_transfer_amount)));
  -- l_smb_stg_record.transfer_amount := UPPER (ltrim(rtrim(l_transfer_amount)));
  print_debug_msg ('l_transfer_amount : ' || l_transfer_amount);
  get_next_pos;
  l_shop_operator_internal_id := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_operator_internal_id := UPPER (ltrim(rtrim(l_shop_operator_internal_id)));
  -- l_smb_stg_record.shop_operator_internal_id := UPPER (ltrim(rtrim(l_shop_operator_internal_id)));
  print_debug_msg ('l_shop_operator_internal_id : ' || l_shop_operator_internal_id);
  get_next_pos;
  l_shop_identification_number := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_shop_identification_number := UPPER (ltrim(rtrim(l_shop_identification_number)));
  -- l_smb_stg_record.shop_identification_number := UPPER (ltrim(rtrim(l_shop_identification_number)));
  print_debug_msg ('l_shop_identification_number : ' || l_shop_identification_number);
  get_next_pos;
  l_total_manual_invoice_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_total_manual_invoice_amount := UPPER (ltrim(rtrim(l_total_manual_invoice_amount)));
  -- l_smb_stg_record.total_manual_invoice_amount := UPPER (ltrim(rtrim(l_total_manual_invoice_amount)));
  print_debug_msg ('l_total_manual_invoice_amount : ' || l_total_manual_invoice_amount);
  get_next_pos;
  l_tot_manual_invoice_amt_vat := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_tot_manual_invoice_amt_vat := UPPER (ltrim(rtrim(l_tot_manual_invoice_amt_vat )));
  -- l_smb_stg_record.tot_manual_invoice_amt_vat := UPPER (ltrim(rtrim(l_tot_manual_invoice_amt_vat )));
  print_debug_msg ('l_tot_manual_invoice_amt_vat   : ' || l_tot_manual_invoice_amt_vat );
  get_next_pos;
  l_total_manual_credit_amount := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_total_manual_credit_amount := UPPER (ltrim(rtrim(l_total_manual_credit_amount)));
  -- l_smb_stg_record.total_manual_credit_amount := UPPER (ltrim(rtrim(l_total_manual_credit_amount)));
  print_debug_msg ('l_total_manual_credit_amount : ' || l_total_manual_credit_amount);
  get_next_pos;
  l_tot_manual_credit_amt_vat := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_tot_manual_credit_amt_vat := UPPER (ltrim(rtrim(l_tot_manual_credit_amt_vat )));
  -- l_smb_stg_record.tot_manual_credit_amt_vat := UPPER (ltrim(rtrim(l_tot_manual_credit_amt_vat )));
  print_debug_msg ('l_tot_manual_credit_amt_vat   : ' || l_tot_manual_credit_amt_vat );
  get_next_pos;
  l_currency_iso_code := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_currency_iso_code := UPPER (ltrim(rtrim(l_currency_iso_code)));
  -- l_smb_stg_record.currency_iso_code := UPPER (ltrim(rtrim(l_currency_iso_code)));
  print_debug_msg ('l_currency_iso_code : ' || l_currency_iso_code);
  get_next_pos;
  l_payment_info_type := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payment_info_type := UPPER (ltrim(rtrim(l_payment_info_type)));
  -- l_smb_stg_record.payment_info_type := UPPER (ltrim(rtrim(l_payment_info_type)));
  print_debug_msg ('l_payment_info_type : ' || l_payment_info_type);
  get_next_pos;
  l_payment_info_owner := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payment_info_owner := UPPER (ltrim(rtrim(l_payment_info_owner)));
  -- l_smb_stg_record.payment_info_owner := UPPER (ltrim(rtrim(l_payment_info_owner)));
  print_debug_msg ('l_payment_info_owner : ' || l_payment_info_owner);
  get_next_pos;
  l_payment_info_bank_name := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payment_info_bank_name := UPPER (ltrim(rtrim(l_payment_info_bank_name)));
  print_debug_msg ('l_payment_info_bank_name : ' || l_payment_info_bank_name);
  -- l_smb_stg_record.payment_info_bank_name := UPPER (ltrim(rtrim(l_payment_info_bank_name)));
  get_next_pos;
  l_payment_info_bank_city := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payment_info_bank_city := UPPER (ltrim(rtrim(l_payment_info_bank_city)));
  -- l_smb_stg_record.payment_info_bank_city := UPPER (ltrim(rtrim(l_payment_info_bank_city)));
  print_debug_msg ('l_payment_info_bank_city : ' || l_payment_info_bank_city);
  get_next_pos;
  l_payment_info_bank_zip := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payment_info_bank_zip := UPPER (ltrim(rtrim(l_payment_info_bank_zip)));
  -- l_smb_stg_record.payment_info_bank_zip := UPPER (ltrim(rtrim(l_payment_info_bank_zip)));
  print_debug_msg ('l_payment_info_bank_zip : ' || l_payment_info_bank_zip);
  get_next_pos;
  l_payment_info_bank_street := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payment_info_bank_street := UPPER (ltrim(rtrim(l_payment_info_bank_street)));
  -- l_smb_stg_record.payment_info_bank_street := UPPER (ltrim(rtrim(l_payment_info_bank_street)));
  print_debug_msg ('l_payment_info_bank_street : ' || l_payment_info_bank_street);
  get_next_pos;
  l_payinfo_ibantype_iban := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payinfo_ibantype_iban := UPPER (ltrim(rtrim(l_payinfo_ibantype_iban)));
  -- l_smb_stg_record.payinfo_ibantype_iban := UPPER (ltrim(rtrim(l_payinfo_ibantype_iban)));
  print_debug_msg ('l_payinfo_ibantype_iban : ' || l_payinfo_ibantype_iban);
  get_next_pos;
  l_payment_info_ibantype_bic := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payment_info_ibantype_bic := UPPER (ltrim(rtrim(l_payment_info_ibantype_bic)));
  -- l_smb_stg_record.payment_info_ibantype_bic := UPPER (ltrim(rtrim(l_payment_info_ibantype_bic)));
  print_debug_msg ('l_payment_info_ibantype_bic : ' || l_payment_info_ibantype_bic);
  get_next_pos;
  l_payinfo_abatype_bank_acct_no := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payinfo_abatype_bank_acct_no := UPPER (ltrim(rtrim(l_payinfo_abatype_bank_acct_no )));
  -- l_smb_stg_record.payinfo_abatype_bank_acct_no := UPPER (ltrim(rtrim(l_payinfo_abatype_bank_acct_no )));
  print_debug_msg ('l_payinfo_abatype_bank_acct_no   : ' || l_payinfo_abatype_bank_acct_no );
  get_next_pos;
  l_payinfo_abatype_routing_no := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payinfo_abatype_routing_no := UPPER (ltrim(rtrim(l_payinfo_abatype_routing_no )));
  -- l_smb_stg_record.payinfo_abatype_routing_no := UPPER (ltrim(rtrim(l_payinfo_abatype_routing_no )));
  print_debug_msg ('l_payinfo_abatype_routing_no   : ' || l_payinfo_abatype_routing_no );
  get_next_pos;
  l_payment_info_abatype_bic := SUBSTR (l_string, l_pos_start + 1, l_pos_end - (l_pos_start + 1));
  l_payment_info_abatype_bic := UPPER (ltrim(rtrim(l_payment_info_abatype_bic)));
  -- l_smb_stg_record.payment_info_abatype_bic := UPPER (ltrim(rtrim(l_payment_info_abatype_bic)));
  print_debug_msg ('l_payment_info_abatype_bic : ' || l_payment_info_abatype_bic);
  lc_code_locn := 'POPULATE_PRE_STAGE_REC';
  -- Populating Pre Staging table record with parsed fields and tracking field name for error handling
  BEGIN
    lc_field_name                                 := 'SHOP-ID';
    l_smb_stg_record.shop_id                      := UPPER (l_shop_id);
    lc_field_name                                 := 'SHOP_NAME';
    l_smb_stg_record.shop_name                    := UPPER (ltrim(rtrim(l_shop_name)));
    lc_field_name                                 := 'SHOP_CORPORATE_NAME';
    l_smb_stg_record.shop_corporate_name          := UPPER (ltrim(rtrim(l_shop_corporate_name)));
    lc_field_name                                 := 'SHOP_ADDRESS_LASTNAME';
    l_smb_stg_record.shop_address_lastname        := UPPER (ltrim(rtrim(l_shop_address_lastname)));
    lc_field_name                                 := 'SHOP_ADDRESS_FIRSTNAME';
    l_smb_stg_record.shop_address_firstname       := UPPER (ltrim(rtrim(l_shop_address_firstname)));
    lc_field_name                                 := 'SHOP_ADDRESS_STREET1';
    l_smb_stg_record.shop_address_street1         := UPPER (ltrim(rtrim(l_shop_address_street1)));
    lc_field_name                                 := 'SHOP_ADDRESS_STREET2';
    l_smb_stg_record.shop_address_street2         := UPPER (ltrim(rtrim(l_shop_address_street2)));
    lc_field_name                                 := 'SHOP_ADDRESS_COMPLEMENTARY';
    l_smb_stg_record.shop_address_complementary   := UPPER (ltrim(rtrim(l_shop_address_complementary)));
    lc_field_name                                 := 'SHOP_ADDRESS_ZIP_CODE';
    l_smb_stg_record.shop_address_zip_code        := UPPER (ltrim(rtrim(l_shop_address_zip_code)));
    lc_field_name                                 := 'SHOP_ADDRESS_CITY';
    l_smb_stg_record.shop_address_city            := UPPER (ltrim(rtrim(l_shop_address_city)));
    lc_field_name                                 := 'SHOP_ADDRESS_COUNTRY';
    l_smb_stg_record.shop_address_country         := UPPER (ltrim(rtrim(l_shop_address_country)));
    lc_field_name                                 := 'SHOP_ADDRESS_STATE';
    l_smb_stg_record.shop_address_state           := UPPER (ltrim(rtrim(l_shop_address_state)));
    lc_field_name                                 := 'SHOP_EMAIL';
    l_smb_stg_record.shop_email                   := UPPER (ltrim(rtrim(l_shop_email)));
    lc_field_name                                 := 'SHOP_IS_PROFESSIONAL';
    l_smb_stg_record.shop_is_professional         := UPPER (ltrim(rtrim(l_shop_is_professional)));
    lc_field_name                                 := 'SHOP_SIRET';
    l_smb_stg_record.shop_siret                   := UPPER (ltrim(rtrim(l_shop_siret)));
    lc_field_name                                 := 'SHOP_VAT_NUMBER';
    l_smb_stg_record.shop_vat_number              := UPPER (ltrim(rtrim(l_shop_vat_number)));
    lc_field_name                                 := 'DATE_CREATED';
    l_smb_stg_record.date_created                 := UPPER (ltrim(rtrim(l_date_created)));
    lc_field_name                                 := 'START_TIME';
    l_smb_stg_record.start_time                   := UPPER (ltrim(rtrim(l_start_time)));
    lc_field_name                                 := 'END_TIME';
    l_smb_stg_record.end_time                     := UPPER (ltrim(rtrim(l_end_time)));
    lc_field_name                                 := 'INVOICE_NUMBER';
    l_smb_stg_record.invoice_number               := UPPER (ltrim(rtrim(l_invoice_number)));
    lc_field_name                                 := 'BILLING_INFO_OWNER';
    l_smb_stg_record.billing_info_owner           := UPPER (ltrim(rtrim(l_billing_info_owner)));
    lc_field_name                                 := 'BILLING_INFO_BANK_NAME';
    l_smb_stg_record.billing_info_bank_name       := UPPER (ltrim(rtrim(l_billing_info_bank_name)));
    lc_field_name                                 := 'BILLING_INFO_BANK_STREET';
    l_smb_stg_record.billing_info_bank_street     := UPPER (ltrim(rtrim(l_billing_info_bank_street)));
    lc_field_name                                 := 'BILLING_INFO_BANK_ZIP';
    l_smb_stg_record.billing_info_bank_zip        := UPPER (ltrim(rtrim(l_billing_info_bank_zip)));
    lc_field_name                                 := 'BILLING_INFO_BANK_CITY';
    l_smb_stg_record.billing_info_bank_city       := UPPER (ltrim(rtrim(l_billing_info_bank_city)));
    lc_field_name                                 := 'BILLING_INFO_BIC';
    l_smb_stg_record.billing_info_bic             := UPPER (ltrim(rtrim(l_billing_info_bic)));
    lc_field_name                                 := 'BILLING_INFO_IBAN';
    l_smb_stg_record.billing_info_iban            := UPPER (ltrim(rtrim(l_billing_info_iban)));
    lc_field_name                                 := 'ORDER_AMOUNT';
    l_smb_stg_record.order_amount                 := UPPER (ltrim(rtrim(l_order_amount)));
    lc_field_name                                 := 'ORDER_SHIPPING_AMOUNT';
    l_smb_stg_record.order_shipping_amount        := UPPER (ltrim(rtrim(l_order_shipping_amount)));
    lc_field_name                                 := 'ORDER_COMMISSION_AMOUNT';
    l_smb_stg_record.order_commission_amount      := UPPER (ltrim(rtrim(l_order_commission_amount)));
    lc_field_name                                 := 'ORDER_COMMISSION_AMOUNT_VAT';
    l_smb_stg_record.order_commission_amount_vat  := UPPER (ltrim(rtrim(l_order_commission_amount_vat)));
    lc_field_name                                 := 'REFUND_AMOUNT';
    l_smb_stg_record.refund_amount                := UPPER (ltrim(rtrim(l_refund_amount)));
    lc_field_name                                 := 'REFUND_SHIPPING_AMOUNT';
    l_smb_stg_record.refund_shipping_amount       := UPPER (ltrim(rtrim(l_refund_shipping_amount)));
    lc_field_name                                 := 'REFUND_COMMISSION_AMOUNT';
    l_smb_stg_record.refund_commission_amount     := UPPER (ltrim(rtrim(l_refund_commission_amount)));
    lc_field_name                                 := 'REFUND_COMMISSION_AMOUNT_VAT';
    l_smb_stg_record.refund_commission_amount_vat := UPPER (ltrim(rtrim(l_refund_commission_amount_vat)));
    lc_field_name                                 := 'SUBSCRIPTION_AMOUNT';
    l_smb_stg_record.subscription_amount          := UPPER (ltrim(rtrim(l_subscription_amount)));
    lc_field_name                                 := 'SUBSCRIPTION_AMOUNT_VAT';
    l_smb_stg_record.subscription_amount_vat      := UPPER (ltrim(rtrim(l_subscription_amount_vat)));
    lc_field_name                                 := 'TOTAL_CHARGED_AMOUNT';
    l_smb_stg_record.total_charged_amount         := UPPER (ltrim(rtrim(l_total_charged_amount)));
    lc_field_name                                 := 'TOTAL_CHARGED_AMOUNT_VAT';
    l_smb_stg_record. total_charged_amount_vat    := UPPER (ltrim(rtrim(l_total_charged_amount_vat)));
    lc_field_name                                 := 'TRANSFER_AMOUNT';
    l_smb_stg_record.transfer_amount              := UPPER (ltrim(rtrim(l_transfer_amount)));
    lc_field_name                                 := 'SHOP_OPERATOR_INTERNAL_ID';
    l_smb_stg_record.shop_operator_internal_id    := UPPER (ltrim(rtrim(l_shop_operator_internal_id)));
    lc_field_name                                 := 'SHOP_IDENTIFICATION_NUMBER';
    l_smb_stg_record.shop_identification_number   := UPPER (ltrim(rtrim(l_shop_identification_number)));
    lc_field_name                                 := 'TOTAL_MANUAL_INVOICE_AMOUNT';
    l_smb_stg_record.total_manual_invoice_amount  := UPPER (ltrim(rtrim(l_total_manual_invoice_amount)));
    lc_field_name                                 := 'TOT_MANUAL_INVOICE_AMT_VAT';
    l_smb_stg_record.tot_manual_invoice_amt_vat   := UPPER (ltrim(rtrim(l_tot_manual_invoice_amt_vat )));
    lc_field_name                                 := 'TOTAL_MANUAL_CREDIT_AMOUNT';
    l_smb_stg_record.total_manual_credit_amount   := UPPER (ltrim(rtrim(l_total_manual_credit_amount)));
    lc_field_name                                 := 'TOT_MANUAL_CREDIT_AMT_VAT';
    l_smb_stg_record.tot_manual_credit_amt_vat    := UPPER (ltrim(rtrim(l_tot_manual_credit_amt_vat )));
    lc_field_name                                 := 'CURRENCY_ISO_CODE';
    l_smb_stg_record.currency_iso_code            := UPPER (ltrim(rtrim(l_currency_iso_code)));
    lc_field_name                                 := 'PAYMENT_INFO_TYPE';
    l_smb_stg_record.payment_info_type            := UPPER (ltrim(rtrim(l_payment_info_type)));
    lc_field_name                                 := 'PAYMENT_INFO_OWNER';
    l_smb_stg_record.payment_info_owner           := UPPER (ltrim(rtrim(l_payment_info_owner)));
    lc_field_name                                 := 'PAYMENT_INFO_BANK_NAME';
    l_smb_stg_record.payment_info_bank_name       := UPPER (ltrim(rtrim(l_payment_info_bank_name)));
    lc_field_name                                 := 'PAYMENT_INFO_BANK_CITY';
    l_smb_stg_record.payment_info_bank_city       := UPPER (ltrim(rtrim(l_payment_info_bank_city)));
    lc_field_name                                 := 'PAYMENT_INFO_BANK_ZIP';
    l_smb_stg_record.payment_info_bank_zip        := UPPER (ltrim(rtrim(l_payment_info_bank_zip)));
    lc_field_name                                 := 'PAYMENT_INFO_BANK_STREET';
    l_smb_stg_record.payment_info_bank_street     := UPPER (ltrim(rtrim(l_payment_info_bank_street)));
    lc_field_name                                 := 'PAYINFO_IBANTYPE_IBAN';
    l_smb_stg_record.payinfo_ibantype_iban        := UPPER (ltrim(rtrim(l_payinfo_ibantype_iban)));
    lc_field_name                                 := 'PAYMENT_INFO_IBANTYPE_BIC';
    l_smb_stg_record.payment_info_ibantype_bic    := UPPER (ltrim(rtrim(l_payment_info_ibantype_bic)));
    lc_field_name                                 := 'PAYINFO_ABATYPE_BANK_ACCT_NO';
    l_smb_stg_record.payinfo_abatype_bank_acct_no := UPPER (ltrim(rtrim(l_payinfo_abatype_bank_acct_no )));
    lc_field_name                                 := 'PAYINFO_ABATYPE_ROUTING_NO';
    l_smb_stg_record.payinfo_abatype_routing_no   := UPPER (ltrim(rtrim(l_payinfo_abatype_routing_no )));
    lc_field_name                                 := 'PAYMENT_INFO_ABATYPE_BIC';
    l_smb_stg_record.payment_info_abatype_bic     := UPPER (ltrim(rtrim(l_payment_info_abatype_bic)));
    --  lc_field_name := 'REQUEST_ID';
    --   l_smb_stg_record.request_id    := gn_request_id; -- request_id
    lc_field_name                      := 'CREATION_DATE';
    l_smb_stg_record.creation_date     := sysdate;
    lc_field_name                      := 'CREATED_BY';
    l_smb_stg_record.created_by        := gn_user_id;
    lc_field_name                      := 'LAST_UPDATE_LOGIN';
    l_smb_stg_record.last_update_login := gn_login_id; -- last_update_login
    lc_field_name                      := 'RECORD_STATUS';
    l_smb_stg_record.record_status     := 'N'; -- last_update_login
  EXCEPTION
  WHEN OTHERS THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_SMB_INT_MKTPLACE_PKG.parse_and_load_smb_file -'||SUBSTR(sqlerrm,1,150);
    print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
    print_debug_msg ('--------------------------ERROR DEBUGGING LOG-----------------------------------------',TRUE);
    print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
    print_debug_msg ('Populate Stg Record:' || p_error_msg,TRUE);
    print_debug_msg ('Error in Field Value:' || lc_field_name,TRUE);
    print_debug_msg ('Record:' || l_string,TRUE);
    print_debug_msg ('Shop ID : ' || l_shop_id,TRUE);
    print_debug_msg('Invoice number : ' || l_invoice_number,TRUE);
    print_debug_msg ('Shop Name : ' || l_shop_name,TRUE);
    print_debug_msg('Error Code Section : ' || lc_code_locn,TRUE);
    RETURN;
  END;
  SELECT xx_ap_smb_int_mkt_stg_s.nextval
  INTO l_smb_stg_record.load_id
  FROM DUAL;
  BEGIN
    INSERT INTO XX_AP_SMB_INT_MKT_STG VALUES l_smb_stg_record;
    p_inserted_cnt := 1;
  EXCEPTION
  WHEN OTHERS THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_SMB_INT_MKTPLACE_PKG.parse_and_load_smb_file -'||SUBSTR(sqlerrm,1,150);
    print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
    print_debug_msg ('--------------------------ERROR DEBUGGING LOG-----------------------------------------',TRUE);
    print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
    print_debug_msg ('Insert Pre Stg:' || p_error_msg,TRUE);
    print_debug_msg ('Record:' || l_string,TRUE);
    print_debug_msg ('Shop ID : ' || l_shop_id,TRUE);
    print_debug_msg('Invoice number : ' || l_invoice_number,TRUE);
    print_debug_msg ('Shop Name : ' || l_shop_name,TRUE);
    print_debug_msg('Error Code Section : ' || lc_code_locn,TRUE);
    RETURN;
  END;
  print_debug_msg ('Parse_smb_file : Inserted Pre-Stg Record! ',FALSE);
  -- END IF;
  lc_code_locn := 'END';
EXCEPTION
WHEN DATA_ERROR THEN
  p_errcode   := '2';
  p_error_msg := 'Error in XX_AP_SMB_INT_MKTPLACE_PKG.parse_and_load_smb_file -'|| lc_error_mesg;
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('--------------------------ERROR DEBUGGING LOG-----------------------------------------',TRUE);
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('Main Others: ' || p_error_msg,TRUE);
  print_debug_msg ('Record:' || l_string,TRUE);
  print_debug_msg ('Shop ID : ' || l_shop_id,TRUE);
  print_debug_msg('Invoice number : ' || l_invoice_number,TRUE);
  print_debug_msg ('Shop Name : ' || l_shop_name,TRUE);
  print_debug_msg('Error Code Section : ' || lc_code_locn,TRUE);
WHEN OTHERS THEN
  p_errcode   := '2';
  p_error_msg := 'Error in XX_AP_SMB_INT_MKTPLACE_PKG.parse_and_load_smb_file -'||SUBSTR(SQLERRM,1,150);
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('--------------------------ERROR DEBUGGING LOG-----------------------------------------',TRUE);
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('Main Others: ' || p_error_msg,TRUE);
  print_debug_msg ('Record:' || l_string,TRUE);
  print_debug_msg ('Shop ID : ' || l_shop_id,TRUE);
  print_debug_msg('Invoice number : ' || l_invoice_number,TRUE);
  print_debug_msg ('Shop Name : ' || l_shop_name,TRUE);
  print_debug_msg('Error Code Section : ' || lc_code_locn,TRUE);
END parse_and_load_smb_file;
-- +====================================================================================================+
-- |  Name  : get_translation_accounts                                                                  |
-- |  Description: This procedure gets the accounting flexfield segments from the translation defn      |
-- |  Lookup tables to get the proper account based on the Internal Marketplace Seller Invoice Line Type|
-- =====================================================================================================|
PROCEDURE get_translation_account_segs
  (
    p_line_source IN VARCHAR2,
    p_ret_code OUT NUMBER ,
    p_company OUT VARCHAR2,
    p_cost_center OUT VARCHAR2,
    p_natural_account OUT VARCHAR2,
    p_location OUT VARCHAR2,
    p_lob OUT VARCHAR2,
    p_inter_company OUT VARCHAR2,
    p_future OUT VARCHAR2
  )
AS
  lc_dflt_company VARCHAR2
  (
    30
  )
  ;
  lc_dflt_cost_center     VARCHAR2(30);
  lc_dflt_natural_account VARCHAR2(30);
  lc_dflt_inter_company   VARCHAR2(30);
  lc_dflt_location        VARCHAR2(30);
  lc_dflt_lob             VARCHAR2(30);
  lc_dflt_future          VARCHAR2(30);
BEGIN
  lc_dflt_company         := '1001';
  lc_dflt_cost_center     := '00000';
  lc_dflt_natural_account := '22003000';
  lc_dflt_location        := '010000';
  lc_dflt_inter_company   := '0000';
  lc_dflt_lob             := '10';
  lc_dflt_future          := '000000';
  BEGIN
    SELECT target_value1,
      target_value2,
      target_value3,
      target_value4,
      target_value5,
      target_value6,
      target_value7
    INTO p_company,
      p_cost_center,
      p_natural_account,
      p_location,
      p_inter_company,
      p_lob,
      p_future
    FROM xx_fin_translatevalues
    WHERE translate_id IN
      (SELECT translate_id
      FROM xx_fin_translatedefinition
      WHERE translation_name = 'OD_AP_INT_MKT_ACCT_MAP'
      AND enabled_flag       = 'Y'
      )
    AND source_value1  = p_line_source;
    p_company         := NVL(p_company,lc_dflt_company);
    p_cost_center     := NVL(p_cost_center,lc_dflt_cost_center);
    p_natural_account := NVL(p_natural_account,lc_dflt_natural_account);
    p_location        := NVL(p_location,lc_dflt_location);
    p_lob             := NVL(p_lob,lc_dflt_lob);
    p_inter_company   := NVL(p_inter_company,lc_dflt_inter_company);
    p_future          := NVL(p_future,lc_dflt_future);
    p_ret_code        := 0;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_ret_code        := 1;
    p_company         := NULL;
    p_cost_center     := NULL;
    p_natural_account := NULL;
    p_location        := NULL;
    p_lob             := NULL;
    p_company         := NVL(p_company,lc_dflt_company);
    p_cost_center     := NVL(p_cost_center,lc_dflt_cost_center);
    p_natural_account := NVL(p_natural_account,lc_dflt_natural_account);
    p_location        := NVL(p_location,lc_dflt_location);
    p_lob             := NVL(p_lob,lc_dflt_lob);
    p_inter_company   := NVL(p_inter_company,lc_dflt_inter_company);
    p_future          := NVL(p_future,lc_dflt_future);
  END;
EXCEPTION
WHEN OTHERS THEN
  p_ret_code        := 1;
  p_company         := NULL;
  p_cost_center     := NULL;
  p_natural_account := NULL;
  p_location        := NULL;
  p_lob             := NULL;
  p_company         := NVL(p_company,lc_dflt_company);
  p_cost_center     := NVL(p_cost_center,lc_dflt_cost_center);
  p_natural_account := NVL(p_natural_account,lc_dflt_natural_account);
  p_location        := NVL(p_location,lc_dflt_location);
  p_lob             := NVL(p_lob,lc_dflt_lob);
  p_inter_company   := NVL(p_inter_company,lc_dflt_inter_company);
  p_future          := NVL(p_future,lc_dflt_future);
END get_translation_account_segs;
-- +====================================================================================================+
-- |  Name  : load_data_to_staging_smb                                                                  |
-- |  Description: This procedure reads data from the SMB pre-staging and inserts into  staging tables  |
-- | Hdr Staging xx_ap_inv_interface_stg and Lines Staging xx_ap_inv_lines_interface_stg                |
-- =====================================================================================================|
PROCEDURE load_data_to_staging_smb(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_source    IN VARCHAR2 ,
    p_debug     IN VARCHAR2 ,
    p_from_date IN VARCHAR2 ,
    p_to_date   IN VARCHAR2 )
AS
  lc_error_mesg       VARCHAR2(500);
  lc_error_loc        VARCHAR2(100) := 'XX_AP_SMB_INT_MKTPLACE_PKG.load_data_to_staging_smb';
  lc_code_locn        VARCHAR2(100);
  ld_dt_created_trunc VARCHAR2(30);
  data_exception      EXCEPTION;
  record_error        EXCEPTION;
  l_record_exists     BOOLEAN;
  lc_exist_ind        VARCHAR2(1);
  ld_vendor_id ap_suppliers.vendor_id%TYPE;
  ld_vendor_site_id ap_supplier_sites_all.vendor_site_id%TYPE;
  lc_pay_group_code ap_supplier_sites_all.pay_group_lookup_code%TYPE;
  ln_term_id ap_terms_tl.term_id%TYPE;
  lc_term_name ap_terms_tl.name%TYPE;
  lc_pay_method_code iby_ext_party_pmt_mthds.payment_method_code%TYPE;
  stg_hdr_rec xx_ap_inv_interface_stg%ROWTYPE;
  stg_line_rec xx_ap_inv_lines_interface_stg%ROWTYPE;
  stg_hdr_rec_null xx_ap_inv_interface_stg%ROWTYPE;
  stg_line_rec_null xx_ap_inv_lines_interface_stg%ROWTYPE;
  ln_line_no NUMBER := 0;
  lc_currency_code ap_supplier_sites_all.invoice_currency_code%TYPE;
  ld_org_id ap_supplier_sites_all.org_id%TYPE;
  ld_record_err_count NUMBER := 0;
  lc_company          VARCHAR2(30);
  lc_cost_center      VARCHAR2(30);
  lc_natural_account  VARCHAR2(30);
  lc_inter_company    VARCHAR2(30);
  lc_location         VARCHAR2(30);
  lc_lob              VARCHAR2(30);
  lc_future           VARCHAR2(30);
  --  lc_description          VARCHAR2(100);
  lc_gl_string         VARCHAR2(200);
  lc_err_mesg          VARCHAR2(250);
  ld_inserted_hdr_cnt  NUMBER := 0;
  ld_inserted_line_cnt NUMBER := 0;
  ld_retcode           NUMBER := 0;
  lc_vendor_site_code_alt ap_supplier_sites_all.vendor_site_code_alt%TYPE;
  ld_load_id xx_ap_smb_int_mkt_stg.load_id%TYPE;
  lc_shop_id xx_ap_smb_int_mkt_stg.shop_id%TYPE;
  lc_shop_name xx_ap_smb_int_mkt_stg.shop_name%TYPE;
  lc_invoice_number xx_ap_smb_int_mkt_stg.invoice_number%TYPE;
  lc_shop_id_number xx_ap_smb_int_mkt_stg.shop_identification_number%TYPE;
  -- Cursor to select all the header information
  CURSOR smb_cur
  IS
    SELECT *
    FROM XX_AP_SMB_INT_MKT_STG
    WHERE record_status = 'N'
    ORDER BY load_id FOR UPDATE OF record_status;
BEGIN
  IF NVL(p_source,'No_Source') != 'OD_US_INT_MARKETPLACE' THEN
    lc_error_mesg              := 'INVALID SOURCE SPECIFIED. SOURCE should be : OD_US_INT_MARKETPLACE ';
    RAISE DATA_EXCEPTION;
  END IF;
  FOR smb_rec IN smb_cur
  LOOP
    BEGIN
      lc_code_locn                                        := 'INIT';
      ld_load_id                                          := smb_rec.load_id;
      lc_shop_id                                          := smb_rec.shop_id;
      lc_shop_name                                        := smb_rec.shop_name;
      lc_invoice_number                                   := smb_rec.invoice_number;
      lc_shop_id_number                                   := smb_rec.shop_identification_number;
      IF ltrim(rtrim(smb_rec.shop_identification_number)) IS NULL THEN
        lc_error_mesg                                     := 'ERROR : SHOP IDENTIFICATION NUMBER IS NULL';
        RAISE RECORD_ERROR;
      END IF;
      -------------------- Duplicate Invoice Check -----------------------
      lc_code_locn    := 'CHECK_FOR_DUPLICATES';
      l_record_exists := FALSE;
      BEGIN
        SELECT 'X'
        INTO lc_exist_ind
        FROM xx_ap_smb_int_mkt_stg
        WHERE invoice_number           = smb_rec.invoice_number
        AND shop_identification_number = smb_rec.shop_identification_number
        AND NVL(record_status,'N')    IN ('N','Y')
        AND load_id                    < smb_rec.load_id
        AND rownum                     < 2;
        l_record_exists               := TRUE;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_record_exists := FALSE;
      END;
      IF l_record_exists = TRUE THEN
        lc_error_mesg   := 'Invoice Number ' || smb_rec.invoice_number || ' is Duplicate !';
        RAISE RECORD_ERROR;
      END IF;
      --------- End Duplicate Check
      stg_hdr_rec := stg_hdr_rec_null;
      SELECT ap_invoices_interface_s.nextval INTO stg_hdr_rec.invoice_id FROM dual;
      IF ltrim(rtrim(smb_rec.invoice_number)) IS NULL THEN
        lc_error_mesg                         := 'ERROR : INVOICE NUMBER IS NULL';
        RAISE RECORD_ERROR;
      END IF;
      stg_hdr_rec.invoice_num              := smb_rec.invoice_number;
      stg_hdr_rec.invoice_type_lookup_code := 'STANDARD';
      ld_dt_created_trunc                  := SUBSTR(ltrim(rtrim(smb_rec.date_created)),1,instr(ltrim(rtrim(smb_rec.date_created)),'.')-1 );
      BEGIN
        stg_hdr_rec.invoice_date := to_date(ld_dt_created_trunc,'yyyy-mm-dd hh24:mi:ss');
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'ERROR : INVOICE DATE FORMAT ERROR :' || stg_hdr_rec.invoice_date ;
        RAISE RECORD_ERROR;
      END;
      stg_hdr_rec.po_number      := NULL;
      stg_hdr_rec.invoice_amount := smb_rec.transfer_amount;
      lc_code_locn               := 'VENDOR_SITE_FETCH';
      BEGIN
        SELECT d.vendor_id,
          c.vendor_site_id,
          c.pay_group_lookup_code,
          c.terms_id,
          t.name,
          c.org_id,
          c.invoice_currency_code,
          c.vendor_site_code_alt
        INTO ld_vendor_id,
          ld_vendor_site_id,
          lc_pay_group_code,
          ln_term_id,
          lc_term_name,
          ld_org_id,
          lc_currency_code,
          lc_vendor_site_code_alt
        FROM ap_supplier_sites_all c,
          ap_suppliers d,
          ap_terms_tl t
        WHERE c.vendor_site_code = smb_rec.shop_identification_number --LTRIM(p_vendor,'0')
          --  c.vendor_site_code_alt = '4072894'  -- smb_rec.shop_identification_number  --LTRIM(p_vendor,'0')
        AND d.vendor_id        = c.vendor_id
        AND ((c.inactive_date IS NULL)
        OR (c.inactive_date    > SYSDATE))
        AND c.terms_id         = t.term_id (+);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lc_error_mesg := 'ERROR : VENDOR SITE CODE - SHOP ID NUMBER NOT FOUND IN VENDOR SITES TABLE :' || smb_rec.shop_identification_number;
        RAISE RECORD_ERROR;
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: FETCHING VENDOR SITE :' || SQLERRM;
        RAISE RECORD_ERROR;
      END;
      stg_hdr_rec.org_id                := ld_org_id;
      stg_hdr_rec.vendor_id             := ld_vendor_id;
      stg_hdr_rec.vendor_num            := NULL;
      stg_hdr_rec.vendor_name           := NULL;
      stg_hdr_rec.vendor_site_id        := ld_vendor_site_id;
      stg_hdr_rec.vendor_site_code      := NULL;
      stg_hdr_rec.terms_id              := ln_term_id;
      stg_hdr_rec.terms_name            := lc_term_name;
      stg_hdr_rec.description           := smb_rec.start_time || '  ' || smb_rec.end_time;
      stg_hdr_rec.creation_date         := sysdate;
      stg_hdr_rec.created_by            := gn_user_id;
      stg_hdr_rec.last_update_login     := gn_login_id;
      stg_hdr_rec.attribute7            := p_source;
      stg_hdr_rec.attribute10           := lc_vendor_site_code_alt; --  smb_rec.shop_identification_number;  --   vendor_site_code
      stg_hdr_rec.invoice_currency_code := NVL(lc_currency_code,smb_rec.currency_iso_code);
      IF NVL(smb_rec.transfer_amount,0) >= 0 THEN
        stg_hdr_rec.global_attribute20  := '+'; --gross_amt_sign
      ELSE
        stg_hdr_rec.global_attribute20 := '-';
      END IF;
      stg_hdr_rec.status     := NULL;
      stg_hdr_rec.source     := p_source;
      stg_hdr_rec.group_id   := NULL;
      stg_hdr_rec.request_id := gn_request_id;
      lc_code_locn           := 'PAY_METHOD_FETCH';
      BEGIN
        SELECT a.payment_method_code
        INTO lc_pay_method_code
        FROM iby_ext_party_pmt_mthds a,
          iby_external_payees_all b,
          ap_supplier_sites_all c,
          ap_suppliers d
        WHERE d.vendor_id      = ld_vendor_id
        AND c.vendor_site_id   = ld_vendor_site_id
        AND d.vendor_id        = c.vendor_id
        AND c.vendor_site_id   = b.supplier_site_id
        AND a.ext_pmt_party_id = b.ext_payee_id
        AND a.primary_flag     = 'Y'
          --  AND c.pay_site_flag                   = 'Y'
        AND ((c.inactive_date IS NULL)
        OR (c.inactive_date    > SYSDATE))
        AND ROWNUM             < 2;
      EXCEPTION
      WHEN OTHERS THEN
        lc_pay_method_code := 'EFT';
        print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
        print_debug_msg ('--------------------------RECORD WARNING LOG-----------------------------------------',TRUE);
        print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
        print_debug_msg ('PAY METHOD Others: ' || SQLERRM,TRUE);
        print_debug_msg ('PAY METHOD Others: PAYMENT METHOD NOT FOUND, DEFAULTING EFT',TRUE);
        print_debug_msg ('Load Id:' || ld_load_id,TRUE);
        print_debug_msg ('Shop ID : ' || lc_shop_id,TRUE);
        print_debug_msg('Shop Name : ' || lc_shop_name,TRUE);
        print_debug_msg ('Invoice Number : ' || lc_invoice_number,TRUE);
        print_debug_msg ('Shop ID Number : ' || lc_shop_id_number,TRUE);
        print_debug_msg('Error Code Section : ' || lc_code_locn,TRUE);
        print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
      END;
      stg_hdr_rec.payment_method_lookup_code := lc_pay_method_code;
      stg_hdr_rec.pay_group_lookup_code      := lc_pay_group_code;
      stg_hdr_rec.terms_date                 := NULL;
      stg_line_rec                           := stg_line_rec_null;
      stg_line_rec.invoice_id                := stg_hdr_rec.invoice_id;
      SELECT ap_invoice_lines_interface_s.nextval
      INTO stg_line_rec.invoice_line_id
      FROM dual;
      lc_code_locn                       := 'ORDER_AMOUNT_LINE';
      ln_line_no                         := 1;
      stg_line_rec.line_number           := ln_line_no;
      stg_line_rec.line_type_lookup_code := 'MISCELLANEOUS';
      stg_line_rec.amount                := NVL(smb_rec.order_amount,0);
      stg_line_rec.description           := 'ORDER AMOUNT';
      stg_line_rec.po_line_number        := NULL;
      stg_line_rec.inventory_item_id     := NULL;
      stg_line_rec.item_description      := NULL;
      stg_line_rec.quantity_invoiced     := NULL;
      stg_line_rec.unit_price            := NULL;
      --     stg_line_rec.attribute10 := lc_vendor_site_code_alt; --'4072894';
      ld_retcode := 0;
      get_translation_account_segs( 'ORDER_AMT', ld_retcode, lc_company, lc_cost_center, lc_natural_account, lc_location, lc_lob, lc_inter_company, lc_future );
      IF ld_retcode != 0 THEN
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
        print_debug_msg('Translation account segments NOT Found for Invoice line ORDER_AMT !',TRUE);
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
      END IF;
      lc_gl_string                        := lc_company ||'.' || lc_cost_center ||'.' || lc_natural_account ||'.' || lc_location ||'.' || lc_inter_company ||'.' || lc_lob ||'.' || lc_future; --dist_code_concatenated
      stg_line_rec.dist_code_concatenated := lc_gl_string;
      stg_line_rec.created_by             := gn_user_id;
      stg_line_rec.creation_date          := sysdate;
      stg_line_rec.last_update_login      := gn_login_id;
      stg_line_rec.reason_code            := NULL;
      stg_line_rec.oracle_gl_company      := lc_company;
      stg_line_rec.oracle_gl_cost_center  := lc_cost_center;
      stg_line_rec.oracle_gl_account      := lc_natural_account;
      stg_line_rec.oracle_gl_location     := lc_location;
      stg_line_rec.oracle_gl_intercompany := lc_inter_company;
      stg_line_rec.oracle_gl_lob          := lc_lob;
      stg_line_rec.oracle_gl_future1      := lc_future;
      BEGIN
        INSERT INTO xx_ap_inv_interface_stg VALUES stg_hdr_rec;
        ld_inserted_hdr_cnt := NVL(ld_inserted_hdr_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING xx_ap_inv_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      BEGIN
        INSERT INTO xx_ap_inv_lines_interface_stg VALUES stg_line_rec;
        ld_inserted_line_cnt := NVL(ld_inserted_line_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING ORDER_AMT LINE xx_ap_inv_lines_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      -------------------------------------------------------------------------------------------------------------
      ---------------------------Code for Remaining Line Amounts --------------------------------------------------
      -------------------------------------------------------------------------------------------------------------
      ------------------------------------------------------------------------------------------------------------
      -- (2)   order_shipping_amount
      -------------------------------------------------------------------------------------------------------------
      lc_code_locn := 'ORDER_SHIPPING_AMOUNT';
      SELECT ap_invoice_lines_interface_s.nextval
      INTO stg_line_rec.invoice_line_id
      FROM dual;
      ln_line_no                         := NVL(ln_line_no,0) + 1;
      stg_line_rec.line_number           := ln_line_no;
      stg_line_rec.line_type_lookup_code := 'MISCELLANEOUS';
      stg_line_rec.amount                := NVL(smb_rec.order_shipping_amount,0);
      stg_line_rec.description           := 'ORDER SHIPPING AMOUNT';
      --      lc_natural_account := NULL;  same as Order Amount
      ld_retcode := 0;
      get_translation_account_segs( 'ORDER_SHIP_AMT', ld_retcode, lc_company, lc_cost_center, lc_natural_account, lc_location, lc_lob, lc_inter_company, lc_future );
      IF ld_retcode != 0 THEN
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
        print_debug_msg('Translation account segments NOT Found for Invoice line ORDER_SHIP_AMT !',TRUE);
        print_debug_msg('------------------------------------------------------------------------',TRUE);
      END IF;
      lc_gl_string                        := lc_company ||'.' || lc_cost_center ||'.' || lc_natural_account ||'.' || lc_location ||'.' || lc_inter_company ||'.' || lc_lob ||'.' || lc_future; --dist_code_concatenated
      stg_line_rec.dist_code_concatenated := lc_gl_string;
      stg_line_rec.oracle_gl_company      := lc_company;
      stg_line_rec.oracle_gl_cost_center  := lc_cost_center;
      stg_line_rec.oracle_gl_account      := lc_natural_account;
      stg_line_rec.oracle_gl_location     := lc_location;
      stg_line_rec.oracle_gl_intercompany := lc_inter_company;
      stg_line_rec.oracle_gl_lob          := lc_lob;
      stg_line_rec.oracle_gl_future1      := lc_future;
      BEGIN
        INSERT INTO xx_ap_inv_lines_interface_stg VALUES stg_line_rec;
        ld_inserted_line_cnt := NVL(ld_inserted_line_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING ORDER SHIPPING AMOUNT LINE xx_ap_inv_lines_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      -----------------------------------------------------------------------------------------------------------------------
      -- (3)   order_commission_amount      Negative Amount on Invoice
      -----------------------------------------------------------------------------------------------------------------------
      lc_code_locn := 'ORDER_COMMISSION_AMOUNT';
      SELECT ap_invoice_lines_interface_s.nextval
      INTO stg_line_rec.invoice_line_id
      FROM dual;
      ln_line_no                         := NVL(ln_line_no,0) + 1;
      stg_line_rec.line_number           := ln_line_no;
      stg_line_rec.line_type_lookup_code := 'MISCELLANEOUS';
      stg_line_rec.amount                := -1 * NVL(smb_rec.order_commission_amount,0);
      stg_line_rec.description           := 'ORDER COMMISSION AMOUNT';
      ld_retcode                         := 0;
      get_translation_account_segs( 'ORDER_COMIS_AMT', ld_retcode, lc_company, lc_cost_center, lc_natural_account, lc_location, lc_lob, lc_inter_company, lc_future );
      IF ld_retcode != 0 THEN
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
        print_debug_msg('Translation account segments NOT Found for Invoice line ORDER_COMIS_AMT !',TRUE);
        print_debug_msg('------------------------------------------------------------------------',TRUE);
      END IF;
      lc_gl_string                        := lc_company ||'.' || lc_cost_center ||'.' || lc_natural_account ||'.' || lc_location ||'.' || lc_inter_company ||'.' || lc_lob ||'.' || lc_future; --dist_code_concatenated
      stg_line_rec.dist_code_concatenated := lc_gl_string;
      stg_line_rec.oracle_gl_company      := lc_company;
      stg_line_rec.oracle_gl_cost_center  := lc_cost_center;
      stg_line_rec.oracle_gl_account      := lc_natural_account;
      stg_line_rec.oracle_gl_location     := lc_location;
      stg_line_rec.oracle_gl_intercompany := lc_inter_company;
      stg_line_rec.oracle_gl_lob          := lc_lob;
      stg_line_rec.oracle_gl_future1      := lc_future;
      BEGIN
        INSERT INTO xx_ap_inv_lines_interface_stg VALUES stg_line_rec;
        ld_inserted_line_cnt := NVL(ld_inserted_line_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING ORDER COMMISSION AMOUNT LINE xx_ap_inv_lines_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      --------------------------------------------------------------------------------------------------------------------
      -- (4)   refund_amount                Negative Amount
      ---------------------------------------------------------------------------------------------------------------------
      lc_code_locn := 'REFUND_AMOUNT';
      SELECT ap_invoice_lines_interface_s.nextval
      INTO stg_line_rec.invoice_line_id
      FROM dual;
      ln_line_no                         := NVL(ln_line_no,0) + 1;
      stg_line_rec.line_number           := ln_line_no;
      stg_line_rec.line_type_lookup_code := 'MISCELLANEOUS';
      stg_line_rec.amount                := -1 * NVL(smb_rec.refund_amount,0);
      stg_line_rec.description           := 'ORDER REFUND AMOUNT';
      ld_retcode                         := 0;
      get_translation_account_segs( 'ORD_REFUND_AMT', ld_retcode, lc_company, lc_cost_center, lc_natural_account, lc_location, lc_lob, lc_inter_company, lc_future );
      IF ld_retcode != 0 THEN
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
        print_debug_msg('Translation account segments NOT Found for Invoice line ORD_REFUND_AMT !',TRUE);
        print_debug_msg('------------------------------------------------------------------------',TRUE);
      END IF;
      lc_gl_string                        := lc_company ||'.' || lc_cost_center ||'.' || lc_natural_account ||'.' || lc_location ||'.' || lc_inter_company ||'.' || lc_lob ||'.' || lc_future; --dist_code_concatenated
      stg_line_rec.dist_code_concatenated := lc_gl_string;
      stg_line_rec.oracle_gl_company      := lc_company;
      stg_line_rec.oracle_gl_cost_center  := lc_cost_center;
      stg_line_rec.oracle_gl_account      := lc_natural_account;
      stg_line_rec.oracle_gl_location     := lc_location;
      stg_line_rec.oracle_gl_intercompany := lc_inter_company;
      stg_line_rec.oracle_gl_lob          := lc_lob;
      stg_line_rec.oracle_gl_future1      := lc_future;
      BEGIN
        INSERT INTO xx_ap_inv_lines_interface_stg VALUES stg_line_rec;
        ld_inserted_line_cnt := NVL(ld_inserted_line_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING ORDER COMMISSION AMOUNT LINE xx_ap_inv_lines_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      ---------------------------------------------------------------------------------------------------------------------
      -- (5)   refund_shipping_amount       Negative Amount
      ----------------------------------------------------------------------------------------------------------------------
      lc_code_locn := 'REFUND_SHIPPING_AMOUNT';
      SELECT ap_invoice_lines_interface_s.nextval
      INTO stg_line_rec.invoice_line_id
      FROM dual;
      ln_line_no                         := NVL(ln_line_no,0) + 1;
      stg_line_rec.line_number           := ln_line_no;
      stg_line_rec.line_type_lookup_code := 'MISCELLANEOUS';
      stg_line_rec.amount                := -1 * NVL(smb_rec.refund_shipping_amount,0);
      stg_line_rec.description           := 'REFUND SHIPPING AMOUNT';
      ld_retcode                         := 0;
      get_translation_account_segs( 'ORD_REFUND_SHIP_AMT', ld_retcode, lc_company, lc_cost_center, lc_natural_account, lc_location, lc_lob, lc_inter_company, lc_future );
      IF ld_retcode != 0 THEN
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
        print_debug_msg('Translation account segments NOT Found for Invoice line ORD_REFUND_SHIP_AMT !',TRUE);
        print_debug_msg('------------------------------------------------------------------------',TRUE);
      END IF;
      lc_gl_string                        := lc_company ||'.' || lc_cost_center ||'.' || lc_natural_account ||'.' || lc_location ||'.' || lc_inter_company ||'.' || lc_lob ||'.' || lc_future; --dist_code_concatenated
      stg_line_rec.dist_code_concatenated := lc_gl_string;
      stg_line_rec.oracle_gl_company      := lc_company;
      stg_line_rec.oracle_gl_cost_center  := lc_cost_center;
      stg_line_rec.oracle_gl_account      := lc_natural_account;
      stg_line_rec.oracle_gl_location     := lc_location;
      stg_line_rec.oracle_gl_intercompany := lc_inter_company;
      stg_line_rec.oracle_gl_lob          := lc_lob;
      stg_line_rec.oracle_gl_future1      := lc_future;
      BEGIN
        INSERT INTO xx_ap_inv_lines_interface_stg VALUES stg_line_rec;
        ld_inserted_line_cnt := NVL(ld_inserted_line_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING REFUND_SHIPPING_AMOUNT LINE xx_ap_inv_lines_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      ---------------------------------------------------------------------------------------------------------------------------
      -- (6)   refund_commission_amount     Positive amount
      ---------------------------------------------------------------------------------------------------------------------------
      lc_code_locn := 'REFUND_COMMISSION_AMOUNT';
      SELECT ap_invoice_lines_interface_s.nextval
      INTO stg_line_rec.invoice_line_id
      FROM dual;
      ln_line_no                         := NVL(ln_line_no,0) + 1;
      stg_line_rec.line_number           := ln_line_no;
      stg_line_rec.line_type_lookup_code := 'MISCELLANEOUS';
      stg_line_rec.amount                := NVL(smb_rec.refund_commission_amount,0);
      stg_line_rec.description           := 'REFUND COMMISSION AMOUNT';
      ld_retcode                         := 0;
      get_translation_account_segs( 'ORD_REFUND_COMIS_AMT', ld_retcode, lc_company, lc_cost_center, lc_natural_account, lc_location, lc_lob, lc_inter_company, lc_future );
      IF ld_retcode != 0 THEN
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
        print_debug_msg('Translation account segments NOT Found for Invoice line ORD_REFUND_COMIS_AMT !',TRUE);
        print_debug_msg('------------------------------------------------------------------------',TRUE);
      END IF;
      lc_gl_string                        := lc_company ||'.' || lc_cost_center ||'.' || lc_natural_account ||'.' || lc_location ||'.' || lc_inter_company ||'.' || lc_lob ||'.' || lc_future; --dist_code_concatenated
      stg_line_rec.dist_code_concatenated := lc_gl_string;
      stg_line_rec.oracle_gl_company      := lc_company;
      stg_line_rec.oracle_gl_cost_center  := lc_cost_center;
      stg_line_rec.oracle_gl_account      := lc_natural_account;
      stg_line_rec.oracle_gl_location     := lc_location;
      stg_line_rec.oracle_gl_intercompany := lc_inter_company;
      stg_line_rec.oracle_gl_lob          := lc_lob;
      stg_line_rec.oracle_gl_future1      := lc_future;
      BEGIN
        INSERT INTO xx_ap_inv_lines_interface_stg VALUES stg_line_rec;
        ld_inserted_line_cnt := NVL(ld_inserted_line_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING REFUND COMMISSION AMT LINE xx_ap_inv_lines_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      -----------------------------------------------------------------------------------------------------------------------
      -- (7)   subscription_amount          Negative Amount
      -----------------------------------------------------------------------------------------------------------------------
      lc_code_locn := 'SUBSCRIPTION_AMOUNT';
      SELECT ap_invoice_lines_interface_s.nextval
      INTO stg_line_rec.invoice_line_id
      FROM dual;
      ln_line_no                         := NVL(ln_line_no,0) + 1;
      stg_line_rec.line_number           := ln_line_no;
      stg_line_rec.line_type_lookup_code := 'MISCELLANEOUS';
      stg_line_rec.amount                := -1 * NVL(smb_rec.subscription_amount,0);
      stg_line_rec.description           := 'SUBSCRIPTION AMOUNT';
      ld_retcode                         := 0;
      get_translation_account_segs( 'SUBSCRIPTION_AMT', ld_retcode, lc_company, lc_cost_center, lc_natural_account, lc_location, lc_lob, lc_inter_company, lc_future );
      IF ld_retcode != 0 THEN
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
        print_debug_msg('Translation account segments NOT Found for Invoice line SUBSCRIPTION_AMT !',TRUE);
        print_debug_msg('------------------------------------------------------------------------',TRUE);
      END IF;
      lc_gl_string                        := lc_company ||'.' || lc_cost_center ||'.' || lc_natural_account ||'.' || lc_location ||'.' || lc_inter_company ||'.' || lc_lob ||'.' || lc_future; --dist_code_concatenated
      stg_line_rec.dist_code_concatenated := lc_gl_string;
      stg_line_rec.oracle_gl_company      := lc_company;
      stg_line_rec.oracle_gl_cost_center  := lc_cost_center;
      stg_line_rec.oracle_gl_account      := lc_natural_account;
      stg_line_rec.oracle_gl_location     := lc_location;
      stg_line_rec.oracle_gl_intercompany := lc_inter_company;
      stg_line_rec.oracle_gl_lob          := lc_lob;
      stg_line_rec.oracle_gl_future1      := lc_future;
      BEGIN
        INSERT INTO xx_ap_inv_lines_interface_stg VALUES stg_line_rec;
        ld_inserted_line_cnt := NVL(ld_inserted_line_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING SUBSCRIPTION_AMT LINE xx_ap_inv_lines_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      --------------------------------------------------------------------------------------------------------------------
      -- (8)   total_manual_invoice_amount  Negative Amount per preUAT Defect
      ---------------------------------------------------------------------------------------------------------------------
      lc_code_locn := 'TOT_MANUAL_INVOICE_AMT';
      SELECT ap_invoice_lines_interface_s.nextval
      INTO stg_line_rec.invoice_line_id
      FROM dual;
      ln_line_no                         := NVL(ln_line_no,0) + 1;
      stg_line_rec.line_number           := ln_line_no;
      stg_line_rec.line_type_lookup_code := 'MISCELLANEOUS';
      stg_line_rec.amount                := -1 * NVL(smb_rec.total_manual_invoice_amount,0);
      stg_line_rec.description           := 'TOTAL MANUAL INVOICE AMOUNT';
      ld_retcode                         := 0;
      get_translation_account_segs( 'TOT_MANUAL_INV_AMT', ld_retcode, lc_company, lc_cost_center, lc_natural_account, lc_location, lc_lob, lc_inter_company, lc_future );
      IF ld_retcode != 0 THEN
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
        print_debug_msg('Translation account segments NOT Found for Invoice line TOT_MANUAL_INV_AMT !',TRUE);
        print_debug_msg('------------------------------------------------------------------------',TRUE);
      END IF;
      lc_gl_string                        := lc_company ||'.' || lc_cost_center ||'.' || lc_natural_account ||'.' || lc_location ||'.' || lc_inter_company ||'.' || lc_lob ||'.' || lc_future; --dist_code_concatenated
      stg_line_rec.dist_code_concatenated := lc_gl_string;
      stg_line_rec.oracle_gl_company      := lc_company;
      stg_line_rec.oracle_gl_cost_center  := lc_cost_center;
      stg_line_rec.oracle_gl_account      := lc_natural_account;
      stg_line_rec.oracle_gl_location     := lc_location;
      stg_line_rec.oracle_gl_intercompany := lc_inter_company;
      stg_line_rec.oracle_gl_lob          := lc_lob;
      stg_line_rec.oracle_gl_future1      := lc_future;
      BEGIN
        INSERT INTO xx_ap_inv_lines_interface_stg VALUES stg_line_rec;
        ld_inserted_line_cnt := NVL(ld_inserted_line_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING TOT_MANUAL_INVOICE_AMT LINE xx_ap_inv_lines_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      --------------------------------------------------------------------------------------------------------------------
      -- (9)   total_manual_credit_amount  Positive amount - per preUAT defect
      ---------------------------------------------------------------------------------------------------------------------
      lc_code_locn := 'TOT_MANUAL_CREDIT_AMT';
      SELECT ap_invoice_lines_interface_s.nextval
      INTO stg_line_rec.invoice_line_id
      FROM dual;
      ln_line_no                         := NVL(ln_line_no,0) + 1;
      stg_line_rec.line_number           := ln_line_no;
      stg_line_rec.line_type_lookup_code := 'MISCELLANEOUS';
      stg_line_rec.amount                :=  NVL(smb_rec.total_manual_credit_amount,0);
      stg_line_rec.description           := 'TOTAL MANUAL CREDIT AMOUNT';
      ld_retcode                         := 0;
      get_translation_account_segs( 'TOT_MANUAL_CR_AMT', ld_retcode, lc_company, lc_cost_center, lc_natural_account, lc_location, lc_lob, lc_inter_company, lc_future );
      IF ld_retcode != 0 THEN
        print_debug_msg('------------------- WARNING --------------------------------------------',TRUE);
        print_debug_msg('Translation account segments NOT Found for Invoice line TOT_MANUAL_CR_AMT !',TRUE);
        print_debug_msg('------------------------------------------------------------------------',TRUE);
      END IF;
      lc_gl_string                        := lc_company ||'.' || lc_cost_center ||'.' || lc_natural_account ||'.' || lc_location ||'.' || lc_inter_company ||'.' || lc_lob ||'.' || lc_future; --dist_code_concatenated
      stg_line_rec.dist_code_concatenated := lc_gl_string;
      stg_line_rec.oracle_gl_company      := lc_company;
      stg_line_rec.oracle_gl_cost_center  := lc_cost_center;
      stg_line_rec.oracle_gl_account      := lc_natural_account;
      stg_line_rec.oracle_gl_location     := lc_location;
      stg_line_rec.oracle_gl_intercompany := lc_inter_company;
      stg_line_rec.oracle_gl_lob          := lc_lob;
      stg_line_rec.oracle_gl_future1      := lc_future;
      BEGIN
        INSERT INTO xx_ap_inv_lines_interface_stg VALUES stg_line_rec;
        ld_inserted_line_cnt := NVL(ld_inserted_line_cnt,0) + 1;
        --     p_inserted_cnt := l_inserted_cnt;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_mesg := 'OTHERS ERROR: INSERTING TOT_MANUAL_CREDIT_AMT LINE xx_ap_inv_lines_interface_stg :' || SQLERRM;
        RAISE DATA_EXCEPTION;
      END;
      UPDATE XX_AP_SMB_INT_MKT_STG SET record_status = 'Y' WHERE CURRENT OF smb_cur;
    EXCEPTION
    WHEN RECORD_ERROR THEN
      UPDATE XX_AP_SMB_INT_MKT_STG
      SET record_status = 'E',
        error_message   = SUBSTR(lc_error_mesg,1,500)
      WHERE CURRENT OF smb_cur;
      print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
      print_debug_msg ('--------------------------RECORD LOAD ERROR LOG---------------------------------------',TRUE);
      print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
      print_debug_msg ('Data_Exception : ' || p_errbuf,TRUE);
      print_debug_msg ('Load Id:' || ld_load_id,TRUE);
      print_debug_msg ('Shop ID : ' || lc_shop_id,TRUE);
      print_debug_msg('Shop Name : ' || lc_shop_name,TRUE);
      print_debug_msg ('Invoice Number : ' || lc_invoice_number,TRUE);
      print_debug_msg ('Shop ID Number : ' || lc_shop_id_number,TRUE);
      print_debug_msg('Error Code Section : ' || lc_code_locn,TRUE);
      print_debug_msg('Error Message : ' || lc_error_mesg,TRUE);
      print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
      ld_record_err_count := NVL(ld_record_err_count,0) + 1;
    END;
  END LOOP; -- staging table smb_cur loop
  print_debug_msg('Program Insert XX Staging Completed Sucessfully !',TRUE);
  print_debug_msg( TO_CHAR(ld_inserted_hdr_cnt) || ' XX SMB Internal Marketplace Staging Header Records Created !',TRUE);
  print_debug_msg(TO_CHAR(ld_inserted_line_cnt) || ' XX SMB Internal Marketplace Staging Line Records Created !',TRUE);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Program XX_AP_SMB_INT_MKTPLACE_PKG.LOAD_DATA_TO_STAGING_SMB Completed Sucessfully !');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,TO_CHAR(ld_inserted_hdr_cnt) || ' XX Staging Invoice Header Records Created !');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,TO_CHAR(ld_inserted_line_cnt) || ' XX Staging Invoice Line Records Created !');
  COMMIT;
  IF ld_record_err_count = 0 THEN
    p_retcode           := 0;
  ELSE
    p_retcode := 1;
    p_errbuf  := 'Warning : ' || TO_CHAR(ld_record_err_count) || ' Invoice Records had Errors !';
  END IF;
EXCEPTION
WHEN data_exception THEN
  ROLLBACK;
  p_retcode := '2';
  p_errbuf  := 'Error in XX_AP_SMB_INT_MKTPLACE_PKG.load_data_to_staging_smb -'|| lc_error_mesg;
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('--------------------------ERROR DEBUGGING LOG-----------------------------------------',TRUE);
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('Data_Exception : ' || p_errbuf,TRUE);
  print_debug_msg ('Load Id:' || ld_load_id,TRUE);
  print_debug_msg ('Shop ID : ' || lc_shop_id,TRUE);
  print_debug_msg('Shop Name : ' || lc_shop_name,TRUE);
  print_debug_msg ('Invoice Number : ' || lc_invoice_number,TRUE);
  print_debug_msg ('Shop ID Number : ' || lc_shop_id_number,TRUE);
  print_debug_msg('Error Code Section : ' || lc_code_locn,TRUE);
  print_debug_msg('Error Message : ' || lc_error_mesg,TRUE);
  log_exception ('XX_AP_SMB_INT_MKTPLACE_PKG.load_data_to_staging_smb', lc_error_loc, p_errbuf);
WHEN OTHERS THEN
  ROLLBACK;
  p_retcode := '2';
  p_errbuf  := 'Error in XX_AP_SMB_INT_MKTPLACE_PKG.load_data_to_staging_smb -'||SUBSTR(SQLERRM,1,150);
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('--------------------------ERROR DEBUGGING LOG-----------------------------------------',TRUE);
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('Main Others: ' || p_errbuf,TRUE);
  print_debug_msg ('Load Id:' || ld_load_id,TRUE);
  print_debug_msg ('Shop ID : ' || lc_shop_id,TRUE);
  print_debug_msg('Shop Name : ' || lc_shop_name,TRUE);
  print_debug_msg ('Invoice Number : ' || lc_invoice_number,TRUE);
  print_debug_msg ('Shop ID Number : ' || lc_shop_id_number,TRUE);
  print_debug_msg('Error Code Section : ' || lc_code_locn,TRUE);
  print_debug_msg('Error Message : ' || lc_error_mesg,TRUE);
  log_exception ('XX_AP_SMB_INT_MKTPLACE_PKG.load_data_to_staging_smb', lc_error_loc, p_errbuf);
END load_data_to_staging_smb;
-- +============================================================================================+
-- |  Name  : load_prestaging                                                                  |
-- |  Description: This procedure reads data from the file and inserts into prestaging tables   |
-- =============================================================================================|
PROCEDURE load_prestaging(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_filepath  IN VARCHAR2 ,
    p_source    IN VARCHAR2 ,
    p_file_name IN VARCHAR2 ,
    p_debug     IN VARCHAR2)
AS
  CURSOR get_dir_path (cp_filepath IN VARCHAR2)
  IS
    SELECT directory_path FROM all_directories WHERE directory_name = cp_filepath;
  l_filehandle UTL_FILE.FILE_TYPE;
  lc_filedir         VARCHAR2(30) := p_filepath;
  lc_filename        VARCHAR2(200):= p_file_name;
  lc_source          VARCHAR2(40) := p_source;
  lc_dirpath         VARCHAR2(500);
  lc_archive_dirpath VARCHAR2(500);
  lb_file_exist      BOOLEAN;
  ln_size            NUMBER;
  ln_block_size      NUMBER;
  lc_newline         VARCHAR2(20000); -- Input line
  ln_max_linesize BINARY_INTEGER := 32767;
  ln_rec_cnt                   NUMBER              := 0;
  l_ret_count                  NUMBER              := 0;
  lc_error_msg                 VARCHAR2(32000)     := NULL;
  lc_error_loc                 VARCHAR2(2000)      := 'XX_AP_SMB_INT_MKTPLACE_PKG.LOAD_PRESTAGING';
  lc_errcode                   VARCHAR2(3)         := NULL;
  lc_rec_type                  VARCHAR2(30)        := NULL;
  ln_count_hdr                 NUMBER              := 0;
  ln_count_lin                 NUMBER              := 0;
  ln_count_err                 NUMBER              := 0;
  ln_count_tot                 NUMBER              := 0;
  ln_conc_file_copy_request_id NUMBER;
  lc_dest_file_name            VARCHAR2(200);
  nofile                       EXCEPTION;
  --  bad_file_exception           EXCEPTION; --3.9 Change
  data_exception     EXCEPTION;
  ld_from_date       DATE;
  ld_to_date         DATE;
  ln_invoice_id      NUMBER;
  ln_sequence_number NUMBER := 0;
  lc_vendor_site     VARCHAR2(30);
  lc_description     VARCHAR2(30);
  lc_location        VARCHAR2(30);
  lc_lob             VARCHAR2(30);
  lc_oracle_account  VARCHAR2(30);
  lc_company         VARCHAR2(30);
  lc_acct_detail     VARCHAR2(30);
  lc_cost_center     VARCHAR2(30);
  lc_inter_company   VARCHAR2(30);
  lc_future          VARCHAR2(30);
  l_nfields          NUMBER;
  lc_drp_details     VARCHAR2(32767);
  lc_temp_email      VARCHAR2(100);
  conn utl_smtp.connection;
  lc_instance_name VARCHAR2(30);
  ln_job_id        NUMBER;
  lb_complete      BOOLEAN;
  lc_phase         VARCHAR2(100);
  lc_status        VARCHAR2(100);
  lc_dev_phase     VARCHAR2(100);
  lc_dev_status    VARCHAR2(100);
  lc_message       VARCHAR2(100);
  lc_email_from    VARCHAR2(100);
  lc_email_to      VARCHAR2(100);
  lc_email_cc      VARCHAR2(100);
  lc_email_subject VARCHAR2(100);
  lc_email_body    VARCHAR2(100);
  lc_email_sub     VARCHAR2(200) := 'Alert - Trade EDI File Carriage Return Issue';
  ln_log           VARCHAR2(32767);
BEGIN
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;
  -- To get the instance Name
  SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV','INSTANCE_NAME')),1,8)
  INTO lc_instance_name
  FROM dual;
  -- **********************************
  -- For Source: SMB MARKETPLACE MIRAKL
  -- **********************************
  IF p_source = 'OD_US_INT_MARKETPLACE' THEN
    print_debug_msg ('Start reading the data from File:'||p_file_name||' Path:'||p_filepath||' for Source: '||p_source,TRUE);
    -- To check whether the file exists or not
    UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
    IF NOT lb_file_exist THEN
      RAISE nofile;
    END IF;
    l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',ln_max_linesize);
    print_debug_msg ('File open successfull',TRUE);
    ln_log       := ln_log || 'INVOICE NUMBER       VENDOR NUMBER          PO NUMBER                            LINE NUMBER                         ERROR MESSAGE '|| chr(10);
    ln_log       := ln_log || '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------' || CHR(10);
    ln_count_hdr := 0;
    ln_count_lin := 0;
    LOOP
      BEGIN
        lc_rec_type := NULL;
        UTL_FILE.GET_LINE(l_filehandle,lc_newline);
        IF lc_newline IS NULL THEN
          EXIT;
        END IF;
        print_debug_msg ('Processing Line:'||lc_newline,FALSE);
        l_ret_count  := 0;
        lc_errcode   := '0';
        lc_error_msg := NULL;
        PARSE_AND_LOAD_SMB_FILE(lc_newline,l_ret_count,lc_error_msg,lc_errcode);
        ln_count_hdr := NVL(ln_count_hdr,0) + NVL(l_ret_count,0);
        --        gn_count     := gn_count            +1;
        IF lc_errcode = '2' THEN
          raise data_exception;
        END IF;
        ln_count_tot := ln_count_tot + 1;
      EXCEPTION
      WHEN no_data_found THEN
        print_debug_msg ('No Data Found - Exit',FALSE);
        EXIT;
      END;
    END LOOP;
    UTL_FILE.FCLOSE(l_filehandle);
    COMMIT;
    
  ELSE

  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('----------------------INVALID SOURCE- SHOULD BE OD_US_INT_MARKETPLACE-----------------',TRUE);
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);

  
  END IF; -- if Main p_source Branches
  /*print_debug_msg(to_char(ln_count_tot)||' records successfully loaded into the Header Table',FALSE); */
  print_debug_msg('================================================ ',TRUE);
  print_debug_msg('No. of records loaded in the Prestaging table:'||TO_CHAR(ln_count_hdr),TRUE);
  --  print_debug_msg('No. of line records loaded in the Prestaging table :'||TO_CHAR(ln_count_lin),TRUE);
  print_debug_msg('================================================ ',TRUE);
  print_out_msg('================================================ ');
  print_out_msg('No. of header records loaded in the Prestaging table:'||TO_CHAR(ln_count_hdr));
 -- print_out_msg('No. of line records loaded in the Prestaging table :'||TO_CHAR(ln_count_lin));
  print_out_msg(' ');
  dbms_lock.sleep(5);
  /*   Commented out as File Archiving and Move creating separate ESP job to archive SMB payment voucher
  IF lb_file_exist THEN
  lc_phase      := NULL;
  lc_status     := NULL;
  lc_dev_phase  := NULL;
  lc_dev_status := NULL;
  lc_message    := NULL;
  OPEN get_dir_path(p_filepath);
  FETCH get_dir_path INTO lc_dirpath;
  CLOSE get_dir_path;
  OPEN get_dir_path(p_filepath || '_ARC');
  FETCH get_dir_path INTO lc_archive_dirpath;
  CLOSE get_dir_path;
  print_debug_msg('Calling the Common File Copy to copy the source file to Archive Folder',TRUE);
  lc_dest_file_name  := lc_archive_dirpath || '/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)||'_' || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';
  ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN', 'XXCOMFILCOPY', '', '',
  FALSE, lc_dirpath||'/'||lc_filename, --Source File Name
  lc_dest_file_name,                                                                                                               --Dest File Name
  '', '', 'N'                                                                                                                      --Deleting the Source File
  );
  IF ln_conc_file_copy_request_id > 0 THEN
  COMMIT;
  print_debug_msg('While Waiting Import Standard Purchase Order Request to Finish');
  -- wait for request to finish
  lb_complete :=fnd_concurrent.wait_for_request ( request_id => ln_conc_file_copy_request_id,
  interval => 10, max_wait => 0, phase => lc_phase, status => lc_status,
  dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message );
  print_debug_msg('Status :'||lc_status);
  print_debug_msg('dev_phase :'||lc_dev_phase);
  print_debug_msg('dev_status :'||lc_dev_status);
  print_debug_msg('message :'||lc_message);
  END IF;
  print_debug_msg('Calling the Common File Copy to move the Inbound file to Archive folder',TRUE);
  lc_dest_file_name            := NULL;
  ln_conc_file_copy_request_id := NULL;
  lc_dest_file_name            := '$XXFIN_ARCHIVE/inbound/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)
  ||'_' || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';
  ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN', 'XXCOMFILCOPY', '', '', FALSE,
  lc_dirpath||'/'||lc_filename, --Source File Name
  lc_dest_file_name,                                                                                                               --Dest File Name
  '', '', 'Y'                                                                                                                      --Deleting the Source File
  );
  END IF;
  */
  COMMIT;
  -------------------------- Main Pre Staging Exception Handler ----------------------
EXCEPTION
WHEN nofile THEN
 print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('----------------------DATA FILE NOT FOUND TO LOAD-------------------------------------',TRUE);
  print_debug_msg ('--------------------------------------------------------------------------------------',TRUE);
  print_debug_msg ('ERROR - File does not exist in specified directory!',TRUE);
  p_retcode := 2;
  p_errbuf  := 'Data File not Found!';
WHEN data_exception THEN
  ROLLBACK;
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg('Error at line:'||lc_newline,TRUE);
  p_errbuf  := lc_error_msg;
  p_retcode := lc_errcode;
WHEN UTL_FILE.INVALID_OPERATION THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('XX_AP_SMB_INT_MTKPLACE_PKG.load_prestaging ERROR - Invalid Operation',TRUE);
  p_retcode:=2;
WHEN UTL_FILE.INVALID_FILEHANDLE THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('XX_AP_SMB_INT_MTKPLACE_PKG.load_prestaging ERROR - Invalid File Handle',TRUE);
  p_retcode := 2;
WHEN UTL_FILE.READ_ERROR THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('XX_AP_SMB_INT_MTKPLACE_PKG.load_prestaging ERROR - Read Error',TRUE);
  p_retcode := 2;
WHEN UTL_FILE.INVALID_PATH THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('XX_AP_SMB_INT_MTKPLACE_PKG.load_prestaging ERROR - Invalid Path',TRUE);
  p_retcode := 2;
WHEN UTL_FILE.INVALID_MODE THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('XX_AP_SMB_INT_MTKPLACE_PKG.load_prestaging ERROR - Invalid Mode',TRUE);
  p_retcode := 2;
WHEN UTL_FILE.INTERNAL_ERROR THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('XX_AP_SMB_INT_MTKPLACE_PKG.load_prestaging ERROR - Internal Error',TRUE);
  p_retcode := 2;
WHEN OTHERS THEN
  ROLLBACK;
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('XX_AP_SMB_INT_MTKPLACE_PKG.load_prestaging ERROR - '||SUBSTR(sqlerrm,1,250),TRUE);
  p_retcode := 2;
END load_prestaging;
END XX_AP_SMB_INT_MKTPLACE_PKG;
/

SHOW ERRORS;