SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE BODY xx_ce_bank_webadi_pkg
IS
  -- +=====================================================================================================+
  -- |                              Office Depot                                                           |
  -- +=====================================================================================================+
  -- | Name        :  XX_CE_BANK_WEBADI_PKG                                                                 |
  -- |                                                                                                     |
  -- | Description :  Package Body to upload new Bank Accounts under existing banks and branches           |
  -- | Rice ID     :                                                                                       |
  -- |Change Record:                                                                                       |
  -- |===============                                                                                      |
  -- |Version   Date         Author           Remarks                                                      |
  -- |=======   ==========   =============    ======================                                       |
  -- | 1.0      24-Nov-2017  Jitendra Atale    Initial Version                                             |
  -- | 1.1      22-Jun-2018  Jitendra Atale    Added Dynamic code combination creation API                 |
  -- +=====================================================================================================+
   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
  g_proc                    VARCHAR2(80)  := NULL;
  g_debug                   VARCHAR2(1)   := 'N';
  gc_success                VARCHAR2(100) := 'SUCCESS';
  gc_failure                VARCHAR2(100) := 'FAILURE';
  lv_init_msg_list          VARCHAR2 (200);
  lv_bank_id                NUMBER :=0;
  lv_branch_id              NUMBER :=0;
  lv_bank_account_name      VARCHAR2(200);
  lv_bank_account_num       NUMBER;
  lv_currency               VARCHAR2(20);
  lv_return_status          VARCHAR2 (200);
  lv_branch_return_status   VARCHAR2 (200);
  lv_account_return_status  VARCHAR2 (200);
  lv_account_return_status1 VARCHAR2 (200);
  lv_msg_count              NUMBER;
  lv_msg_data               VARCHAR2 (200);
  lv_branch_msg_count       NUMBER;
  lv_branch_msg_data        VARCHAR2 (200);
  lv_acc_msg_count          NUMBER;
  lv_acc_msg_data           VARCHAR2 (200);
  lv_acc_msg_count1         NUMBER;
  lv_acc_msg_data1          VARCHAR2 (200);
  lv_end_date               DATE;
  lv_cash_ccid              NUMBER :=0;
  lv_cash_clearing_ccid     NUMBER :=0;
  lv_bank_charges_ccid      NUMBER :=0;
  lv_bank_error_ccid        NUMBER :=0;
  lv_chart_of_accounts_id   NUMBER :=0;
  -- +===================================================================+
  -- | Name  : write_output                                               |
  -- | Description     : procedure to generate Concurrrent Program output |
  -- | Parameters      : p_request_id, p_user_id                         |
  -- +===================================================================+
PROCEDURE write_output(
    p_request_id NUMBER,
    p_user_id    NUMBER)
AS
  CURSOR detail
  IS
    SELECT rpad(DECODE(country_code,403,'CA','US'),10,' ') country_code,
      rpad(bank_name, 20, ' ') bank_name,
      rpad(bank_number, 20, ' ') bank_number,
      rpad(branch_name,20, ' ') branch_name,
      rpad(branch_number,20,' ') branch_number,
      rpad(branch_type, 15, ' ') branch_type,
      rpad(bank_account_type,15, ' ') account_type,
      rpad(agency_location_code,15, ' ') agency_code,
      rpad(bank_account_num,15, ' ') bank_account_num,
      rpad(currency,10, ' ') currency,
      rpad(DECODE(process_flag,'E','Error','S','Success',' '),15, ' ') process_flag,
      rpad(error_msg,500, ' ') error_msg
    FROM xx_ce_bank_stg
    WHERE request_id=p_request_id
    AND created_by  =p_user_id;
  CURSOR hdr
  IS
    SELECT rpad('Country',10,' ') country,
      rpad('Bank name', 20, ' ') bank_name,
      rpad('Bank number', 20, ' ') bank_number,
      rpad('Branch name',20, ' ') branch_name,
      rpad('Branch number',20,' ') branch_number,
      rpad('Branch type', 15, ' ') branch_type,
      rpad('Account type',15, ' ') account_type,
      rpad('Agency code',15, ' ') agency_code,
      rpad('Account num',15, ' ') bank_account_num,
      rpad('Currency',10, ' ') currency,
      rpad('Process flag',15, ' ') process_flag,
      rpad('Error_msg',500, ' ') error_msg
    FROM dual;
  l_user_name VARCHAR2(150);
BEGIN
  BEGIN
    SELECT user_name INTO l_user_name FROM fnd_user WHERE user_id=p_user_id;
  EXCEPTION
  WHEN OTHERS THEN
    l_user_name :=NULL;
  END;
  fnd_file.put_line(fnd_file.output,lpad(' OFFICE DEPOT, INC ',120,' '));
  fnd_file.put_line(fnd_file.output,lpad(' OD Bank Creation WebADI Upload Report ',100,' '));
  fnd_file.put_line(fnd_file.output,'Run Date: '|| TO_CHAR(SYSDATE,'MM/DD/YYYY'));
  fnd_file.put_line(fnd_file.output,'Submitted By: '|| l_user_name);
  fnd_file.put_line(fnd_file.output,lpad('-',400,'-'));
  FOR i IN hdr
  LOOP
    fnd_file.put_line(fnd_file.output,i.country||' '||i.bank_name||' '||i.bank_number||' '||i.branch_name||' '||i.branch_number||' '||i.branch_type||' '||i.Account_type||' '||i.agency_code||' '||i.bank_account_num||' '||i.currency||' '||i.process_flag||' '||i.error_msg);
  END LOOP;
  fnd_file.put_line(fnd_file.output,lpad('-',400,'-'));
  FOR j IN detail
  LOOP
    fnd_file.put_line(fnd_file.output,j.country_code||' '||j.bank_name||' '||j.bank_number||' '||j.branch_name||' '||j.branch_number||' '||j.branch_type||' '||j.account_type||' '||j.agency_code||' '||j.bank_account_num||' '|| j.currency||' '||j.process_flag||' ' ||j.error_msg);
  END LOOP;
  fnd_file.put_line(fnd_file.output,lpad('-',400,'-'));
END write_output;
-- +===================================================================+
-- | Name  : log_debug_msg                                              |
-- | Description     : procedure that will meaningful log messages      |
-- | Parameters      :  p_debug_msg IN                                    |
-- +===================================================================+
PROCEDURE log_debug_msg(
    p_debug_msg IN VARCHAR2 )
IS
  ln_login fnd_user.last_update_login%TYPE := fnd_global.login_id;
  ln_user_id fnd_user.user_id%TYPE         := fnd_global.user_id;
  lc_user_name fnd_user.user_name%TYPE     := fnd_global.user_name;
BEGIN
  IF (g_debug = 'Y') THEN
    xx_com_error_log_pub.log_error ( p_return_code => fnd_api.g_ret_sts_success ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'LOG' ,p_attribute15 => 'XX_CE_BANK_WEBADI_PKG' ,p_attribute16 => g_proc ,p_program_id => 0 ,p_module_name => 'CE' ,p_error_message => p_debug_msg ,p_error_message_severity => 'LOG' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
    fnd_file.put_line(fnd_file.LOG, p_debug_msg);
  END IF;
END log_debug_msg;
PROCEDURE log_error(
    p_error_msg IN VARCHAR2 )
IS
  ln_login fnd_user.last_update_login%TYPE := fnd_global.login_id;
  ln_user_id fnd_user.user_id%TYPE         := fnd_global.user_id;
  lc_user_name fnd_user.user_name%TYPE     := fnd_global.user_name;
BEGIN
  xx_com_error_log_pub.log_error ( p_return_code => fnd_api.g_ret_sts_success ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'ERROR' ,p_attribute15 => 'XX_CE_BANK_WEBADI_PKG' ,p_attribute16 => g_proc ,p_program_id => 0 ,p_module_name => 'CE' ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
  fnd_file.put_line(fnd_file.LOG, p_error_msg);
END log_error;
-- +===================================================================+
-- | Name  : CREATE_BANK_ACCT                                           |
-- | Description     : procedure that will insert bank through API      |
-- | Parameters      :  p_bank_id IN                                    |
-- |                    p_branch_id IN                                  |
-- |                    lv_branch_return_status           OUT           |
-- |                    lv_branch_id            OUT                     |
-- +===================================================================+
PROCEDURE create_bank_acct(
    p_acc_bank_id      IN NUMBER,
    p_acc_bank_branch  IN NUMBER,
    p_user_id          IN NUMBER,
    p_bank_account_num IN VARCHAR2,
    lv_acct_id OUT NUMBER,
    lv_account_return_status OUT VARCHAR2)
AS
  lv_acct_rec ce_bank_pub.bankacct_rec_type;
  lv_org_id            NUMBER :=0;
  lv_acct_use_id       NUMBER :=0;
  lv_acct_id_cnt       NUMBER :=0;
  lv_org_type          VARCHAR2(5);
  lv_accowner_org_id   NUMBER :=0;
  lv_accowner_party_id NUMBER :=0;
  lv_account_owner     VARCHAR2(50);
  CURSOR c2
  IS
    SELECT ROWID,
      stg.*
    FROM xx_ce_bank_stg stg
    WHERE process_flag  ='N'
    AND bank_id         = p_acc_bank_id
    AND bank_branch_id  =p_acc_bank_branch
    AND bank_account_num=p_bank_account_num
    AND created_by      =p_user_id;
BEGIN
  g_proc :='CREATE_BANK_ACCT';
  SELECT gsob.chart_of_accounts_id
  INTO lv_chart_of_accounts_id
  FROM gl_sets_of_books gsob
  WHERE gsob.set_of_books_id = fnd_profile.value ('GL_SET_OF_BKS_ID');
  FOR r2 IN c2
  LOOP
    lv_account_return_status           := NULL;
    lv_org_id                          := r2.country_code;
    lv_init_msg_list                   := fnd_api.g_true;
    lv_acct_rec.branch_id              := r2.bank_branch_id;
    lv_acct_rec.bank_id                := r2.bank_id;
    lv_acct_rec.account_classification := 'INTERNAL';
    lv_acct_rec.acct_type              := r2.bank_account_type;
    lv_acct_rec.agency_location_code   := r2.agency_location_code;
    lv_acct_rec.bank_account_name      := r2.bank_name||' - '||SUBSTR(lpad(r2.agency_location_code,8,0),3,8);
    IF r2.bank_account_name_alt         = 'OD Store' THEN
      lv_acct_rec.alternate_acct_name  := r2.bank_account_name_alt||' - '||SUBSTR(lpad(r2.agency_location_code,8,0),3,8);
    ELSE
      lv_acct_rec.alternate_acct_name := r2.bank_account_name_alt;
    END IF;
    --log_debug_msg(' agency_location_code '||lv_acct_rec.agency_location_code||' '||' bank_account_name '||' '||lv_acct_rec.bank_account_name|| ' alternate_acct_name '||lv_acct_rec.alternate_acct_name);
    lv_acct_rec.bank_account_num := r2.bank_account_num;
    lv_acct_rec.currency         := r2.currency;
    lv_acct_rec.description      := lv_acct_rec.bank_account_name ||' '||r2.bank_account_type;
    SELECT default_legal_context_id
    INTO lv_accowner_org_id
    FROM hr_operating_units
    WHERE organization_id             =lv_org_id;
    lv_acct_rec.account_owner_org_id := lv_accowner_org_id;
    SELECT NAME
    INTO lv_account_owner
    FROM hr_organization_units
    WHERE organization_id=lv_accowner_org_id;
    SELECT party_id
    INTO lv_accowner_party_id
    FROM hz_parties
    WHERE party_name = lv_account_owner;
    --log_debug_msg(' lv_account_owner '||lv_account_owner||' lv_accowner_org_id '||lv_accowner_org_id||' '||' lv_accowner_party_id '||lv_accowner_party_id);
    -- Fetching code combination id for Cash Account.
    -- New code combination will be created if CCID not exist
    IF r2.cash_ccid   IS NOT NULL THEN
      lv_cash_ccid    := fnd_flex_ext.get_ccid ('SQLGL', 'GL#', lv_chart_of_accounts_id, TO_CHAR (sysdate, 'YYYY/MM/DD HH24:MI:SS'), r2.cash_ccid );
      IF lv_cash_ccid  = 0 THEN
        gv_err_msg    := gv_err_msg || ' Cash Account '|| fnd_message.get;
        gv_error_code := 'E';
      END IF;
    END IF;
    IF r2.cash_clearing_ccid  IS NOT NULL THEN
      lv_cash_clearing_ccid   := fnd_flex_ext.get_ccid ('SQLGL', 'GL#', lv_chart_of_accounts_id, TO_CHAR (sysdate, 'YYYY/MM/DD HH24:MI:SS'), r2.cash_clearing_ccid );
      IF lv_cash_clearing_ccid = 0 THEN
        gv_err_msg            := gv_err_msg || ' Cash Clearing Account '|| fnd_message.get;
        gv_error_code         := 'E';
      END IF;
    END IF;
    IF r2.bank_charges_ccid  IS NOT NULL THEN
      lv_bank_charges_ccid   := fnd_flex_ext.get_ccid ('SQLGL', 'GL#', lv_chart_of_accounts_id, TO_CHAR (sysdate, 'YYYY/MM/DD HH24:MI:SS'), r2.bank_charges_ccid );
      IF lv_bank_charges_ccid = 0 THEN
        gv_err_msg           := gv_err_msg || ' Bank Charges Account '|| fnd_message.get;
        gv_error_code        := 'E';
      END IF;
    END IF;
    IF r2.bank_error_ccid  IS NOT NULL THEN
      lv_bank_error_ccid   := fnd_flex_ext.get_ccid ('SQLGL', 'GL#', lv_chart_of_accounts_id, TO_CHAR (sysdate, 'YYYY/MM/DD HH24:MI:SS'), r2.bank_error_ccid );
      IF lv_bank_error_ccid = 0 THEN
        gv_err_msg         := gv_err_msg || ' Bank Error Account '|| fnd_message.get;
        gv_error_code      := 'E';
      END IF;
    END IF;
    lv_acct_rec.account_owner_party_id      := lv_accowner_party_id;
    lv_acct_rec.multi_currency_allowed_flag := 'Y';
    lv_acct_rec.payment_multi_currency_flag := 'Y';
    lv_acct_rec.receipt_multi_currency_flag := 'Y';
    lv_acct_rec.zero_amount_allowed         := 'N';
    lv_acct_rec.pooled_flag                 := 'N';
    lv_acct_rec.ap_use_allowed_flag         := 'Y';
    lv_acct_rec.ar_use_allowed_flag         := 'Y';
    lv_acct_rec.xtr_use_allowed_flag        := 'N';
    lv_acct_rec.pay_use_allowed_flag        := 'N';
    lv_acct_rec.asset_code_combination_id   := lv_cash_ccid;
    lv_acct_rec.cash_clearing_ccid          := lv_cash_clearing_ccid;
    lv_acct_rec.bank_charges_ccid           := lv_bank_charges_ccid;
    lv_acct_rec.bank_errors_ccid            := lv_bank_error_ccid;
    lv_acct_rec.start_date                  := SYSDATE;
    lv_acct_rec.end_date                    := NULL;
    IF gv_error_code                         = 'S' THEN
      ce_bank_pub.create_bank_acct (p_init_msg_list => lv_init_msg_list, p_acct_rec => lv_acct_rec, x_acct_id => lv_acct_id, x_return_status => lv_account_return_status, x_msg_count => lv_acc_msg_count, x_msg_data => lv_acc_msg_data );
      log_debug_msg( SQL%rowcount ||' Row(s) inserted in XX_CE_BANK_WEBADI_PKG.CREATE_BANK_ACCT '||lv_account_return_status||' '||lv_acc_msg_data ||' '||lv_acct_id);
      COMMIT;
      lv_account_return_status   := gc_success;
      IF lv_account_return_status = gc_success THEN
        UPDATE xx_ce_bank_stg
        SET bank_account_id          = lv_acct_id,
          account_owner_org_id       =lv_accowner_org_id,
          account_owner_party_id     =lv_accowner_party_id,
          account_classification     ='INTERNAL',
          multi_currency_allowed_flag='Y',
          ap_use_enable_flag         ='Y',
          ar_use_enable_flag         ='Y',
          xtr_use_enable_flag        ='N',
          pay_use_enable_flag        ='N',
          bank_account_name_alt      =lv_acct_rec.alternate_acct_name,
          BANK_ACCOUNT_OWNER         =lv_accowner_org_id
        WHERE ROWID                  = r2.ROWID;
        COMMIT;
      ELSE
        gv_err_msg    := gv_err_msg || ' ' || r2.bank_account_num ||' ' || lv_acc_msg_data;
        gv_error_code := 'E';
      END IF;
    END IF;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  gv_error_code            := 'E';
  Lv_Account_Return_Status := Gc_Failure;
  gv_err_msg               := gv_err_msg || ' ' || lv_acc_msg_data;
  log_error('Error in CREATE ACCOUNT API '||SUBSTR(sqlerrm,1,100));
END create_bank_acct;
-- +===================================================================+
-- | Name  : CREATE_BANK_ACCT_USE                                       |
-- | Description     : procedure that will insert bank through API      |
-- | Parameters      :  p_bank_id IN                                    |
-- |                    p_branch_id IN
-- |                    p_acct_id IN                                    |
-- |                    lv_branch_return_status           OUT           |
-- |                    lv_branch_id            OUT                     |
-- +===================================================================+
PROCEDURE create_bank_acct_use(
    p_bank_id            IN NUMBER,
    p_bank_branch        IN NUMBER,
    p_acct_id            IN NUMBER,
    p_user_id            IN NUMBER,
    p_cash_ccid          IN NUMBER,
    p_cash_clearing_ccid IN NUMBER,
    p_bank_charges_ccid  IN NUMBER,
    p_bank_error_ccid    IN NUMBER,
    lv_account_return_status1 OUT VARCHAR2)
AS
  lv_use_rec ce_bank_pub.bankacct_use_rec_type;
  lv_org_id               NUMBER;
  lv_acct_id              NUMBER;
  lv_acct_use_id          NUMBER;
  lv_acct_use_id_cnt      NUMBER :=0;
  lv_org_type             VARCHAR2(5);
  lv_chart_of_accounts_id NUMBER :=0;
  CURSOR c3
  IS
    SELECT ROWID,
      stg.*
    FROM xx_ce_bank_stg stg
    WHERE bank_id      = p_bank_id
    AND bank_branch_id =p_bank_branch
    AND bank_account_id=p_acct_id
    AND process_flag   ='N'
    AND created_by     =p_user_id;
BEGIN
  g_proc :='CREATE_BANK_ACCT_USE';
  FOR r3 IN c3
  LOOP
    lv_org_id                            := r3.country_code;
    lv_account_return_status1            := NULL;
    lv_init_msg_list                     := fnd_api.g_true;
    lv_org_type                          := 'OU';
    lv_use_rec.ap_use_enable_flag        := 'Y';
    lv_use_rec.ar_use_enable_flag        := 'Y';
    lv_use_rec.xtr_use_enable_flag       := 'N';
    lv_use_rec.pay_use_enable_flag       := 'N';
    lv_use_rec.org_id                    := lv_org_id;
    lv_use_rec.org_type                  := lv_org_type;
    lv_use_rec.asset_code_combination_id := p_cash_ccid;
    lv_use_rec.ap_asset_ccid             := p_cash_ccid;
    lv_use_rec.cash_clearing_ccid        := p_cash_clearing_ccid;
    lv_use_rec.bank_charges_ccid         := p_bank_charges_ccid;
    lv_use_rec.bank_errors_ccid          := p_bank_error_ccid;
    lv_use_rec.bank_account_id           := p_acct_id;
    lv_use_rec.authorized_flag           := 'Y';
    lv_use_rec.default_account_flag      := 'N';
    lv_use_rec.ap_default_settlement_flag:= 'N';
    IF gv_error_code                      = 'S' THEN
      ce_bank_pub.create_bank_acct_use (p_init_msg_list => lv_init_msg_list, p_acct_use_rec => lv_use_rec, x_acct_use_id => lv_acct_use_id, x_return_status => lv_account_return_status1, x_msg_count => lv_acc_msg_count1, x_msg_data => lv_acc_msg_data1 );
      log_debug_msg( lv_acct_use_id_cnt||' Row(s) inserted in XX_CE_BANK_WEBADI_PKG.create_bank_acct_use ' ||lv_acct_use_id||' ' ||lv_account_return_status1||' '||lv_acc_msg_data1);
      COMMIT;
      lv_account_return_status1 := gc_success;
    ELSE
      lv_account_return_status1 := gc_failure;
    END IF;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  lv_account_return_status1 := gc_failure;
  gv_error_code             := 'E';
  gv_err_msg                := gv_err_msg || ' ' || lv_acc_msg_data1;
  log_error('Error in CREATE ACCOUNT USE API '||SUBSTR(sqlerrm,1,100));
END create_bank_acct_use;
-- +===================================================================+
-- | Name  : fetch_data                                                |
-- | Description     : The fetch_data procedure will fetch data from   |
-- |                   WEBADI to bank staging table              |
-- |                                                                   |
-- | Parameters      :                                                 |
-- +===================================================================+
PROCEDURE fetch_data(
    p_country_code                IN NUMBER,
    p_bank_name                   IN VARCHAR2,
    p_bank_number                 IN VARCHAR2,
    p_alternate_bank_name         IN VARCHAR2,
    p_short_bank_name             IN VARCHAR2,
    p_description                 IN VARCHAR2,
    p_branch_name                 IN VARCHAR2,
    p_branch_number               IN VARCHAR2,
    p_branch_type                 IN VARCHAR2,
    p_alternate_branch_name       IN VARCHAR2,
    p_branch_description          IN VARCHAR2,
    p_rfc_identifier              IN VARCHAR2,
    p_bank_account_name           IN VARCHAR2,
    p_bank_account_type           IN VARCHAR2,
    p_agency_location_code        IN VARCHAR2,
    p_bank_account_name_alt       IN VARCHAR2,
    p_bank_account_num            IN VARCHAR2,
    p_bank_account_owner          IN NUMBER,
    p_account_owner_org_id        IN NUMBER,
    p_account_owner_party_id      IN NUMBER,
    p_account_classification      IN VARCHAR2,
    p_multi_currency_allowed_flag IN VARCHAR2,
    p_ap_use_enable_flag          IN VARCHAR2,
    p_ar_use_enable_flag          IN VARCHAR2,
    p_xtr_use_enable_flag         IN VARCHAR2,
    p_pay_use_enable_flag         IN VARCHAR2,
    p_currency                    IN VARCHAR2,
    p_cash_ccid                   IN VARCHAR2,
    p_cash_clearing_ccid          IN VARCHAR2,
    p_bank_charges_ccid           IN VARCHAR2,
    p_bank_error_ccid             IN VARCHAR2 )
IS
BEGIN
  g_proc :='FETCH_DATA';
  INSERT
  INTO xx_ce_bank_stg
    (
      country_code,
      bank_name,
      bank_number,
      alt_bank_name,
      short_bank_name,
      bank_description,
      branch_name,
      branch_number,
      branch_type,
      alt_branch_name,
      branch_description,
      rfc_identifier,
      bank_account_name,
      bank_account_type,
      agency_location_code,
      bank_account_name_alt,
      bank_account_num,
      bank_account_owner,
      account_owner_org_id,
      account_owner_party_id,
      account_classification,
      multi_currency_allowed_flag,
      ap_use_enable_flag,
      ar_use_enable_flag,
      xtr_use_enable_flag,
      pay_use_enable_flag,
      currency,
      cash_ccid,
      cash_clearing_ccid,
      bank_charges_ccid,
      bank_error_ccid,
      process_flag,
      creation_date,
      created_by,
      last_update_date,
      last_updated_by,
      last_update_login
    )
    VALUES
    (
      p_country_code,
      p_bank_name,
      p_bank_number,
      p_alternate_bank_name,
      p_short_bank_name,
      p_description,
      p_branch_name,
      p_branch_number,
      p_branch_type,
      p_alternate_branch_name,
      p_branch_description,
      p_rfc_identifier,
      p_bank_account_name,
      p_bank_account_type,
      p_agency_location_code,
      p_bank_account_name_alt,
      p_bank_account_num,
      p_bank_account_owner,
      p_account_owner_org_id,
      p_account_owner_party_id,
      p_account_classification,
      p_multi_currency_allowed_flag,
      p_ap_use_enable_flag,
      p_ar_use_enable_flag,
      p_xtr_use_enable_flag,
      p_pay_use_enable_flag,
      p_currency,
      p_cash_ccid,
      p_cash_clearing_ccid,
      p_bank_charges_ccid,
      p_bank_error_ccid,
      'N',
      SYSDATE,
      fnd_global.user_id,
      SYSDATE,
      fnd_global.user_id,
      fnd_global.login_id
    );
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  log_error('Error Inserting Data into XX_CE_BANK_STG '||SUBSTR(sqlerrm,1,50));
  raise_application_error (-20343, 'Error inserting the data..'||sqlerrm);
END fetch_data ;
-- +===================================================================+
-- | Name  : extract                                                   |
-- | Description     : The extract procedure is the main               |
-- |                   procedure that will extract all the unprocessed |
-- |                   records from xx_ce_bank_staging              |
-- | Parameters      : x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- +===================================================================+
PROCEDURE EXTRACT
  (
    x_errbuf OUT nocopy  VARCHAR2,
    x_retcode OUT nocopy NUMBER
  )
IS
  --------------------------------
  -- Local Variable Declaration --
  --------------------------------
  lc_err_flag VARCHAR2(1);
  --  ln_user_id fnd_user.user_id%TYPE;
  lc_user_name fnd_user.user_name%TYPE;
  lc_debug_flag              VARCHAR2(1) := NULL;
  lc_upd_bank_ret_status     VARCHAR2(20);
  lc_upd_branch_ret_status   VARCHAR2(20);
  lc_upd_account_ret_status  VARCHAR2(20);
  lc_upd_account_ret_status1 VARCHAR2(20);
  ln_count                   NUMBER;
  ln_count_stg               NUMBER;
  lc_branch_id               NUMBER;
  lc_acct_id                 NUMBER;
  lvc_acct_id                NUMBER;
  lc_acct_use_id             NUMBER;
  lv_country_code            VARCHAR2(2);
  lc_bank_account_name       VARCHAR2(100);
  lv_Bank_number             VARCHAR2(100);
  lv_branch_number           VARCHAR2(100);
  lv_branch_name             VARCHAR2(100);
  lv_ref_identifier          VARCHAR2(10);
  lv_branch_description      VARCHAR2(200);
  lv_brach_type              VARCHAR2(10);
  lc_cash_ccid               NUMBER :=0;
  lc_cash_clearing_ccid      NUMBER :=0;
  lc_bank_charges_ccid       NUMBER :=0;
  lc_bank_error_ccid         NUMBER :=0;
  CURSOR c1 (p_user_id NUMBER)
  IS
    SELECT ROWID,
      stg.*
    FROM xx_ce_bank_stg stg
    WHERE process_flag = 'N'
    AND created_by     =p_user_id;
BEGIN
  g_proc        :='EXTRACT';
  gn_user_id    := fnd_global.user_id;
  gn_request_id := fnd_global.conc_request_id;
  gv_err_msg    := NULL;
  gv_error_code := 'S';
  SELECT user_name INTO lc_user_name FROM fnd_user WHERE user_id = gn_user_id;
  log_debug_msg('User Name :'|| lc_user_name);
  fnd_file.put_line(fnd_file.log, 'User id       :'|| gn_user_id);
  FOR r1 IN c1 (gn_user_id)
  LOOP
    x_retcode                 :=0;
    lv_bank_id                :=0;
    lc_branch_id              :=0;
    lc_upd_bank_ret_status    := NULL;
    lc_upd_branch_ret_status  := NULL;
    lc_upd_account_ret_status := NULL;
    lc_user_name              := NULL;
    ln_count                  := NULL;
    ln_count_stg              := NULL;
    lv_country_code           := NULL;
    lv_Bank_number            := NULL;
    lc_debug_flag             := 'Y';
    log_debug_msg ('Debug Flag :'||lc_debug_flag);
    IF (lc_debug_flag = 'Y') THEN
      g_debug        := 'Y';
    ELSE
      g_debug := 'N';
    END IF;
    log_debug_msg('Getting the user name ..');
    fnd_file.put_line(fnd_file.LOG ,SQL%rowcount||'  Before insert Bank '||r1.bank_id);
    BEGIN
      lv_init_msg_list := fnd_api.g_true;
      BEGIN
        SELECT DISTINCT xftv.target_value1
        INTO lv_Bank_number
        FROM xx_fin_translatedefinition xftd ,
          xx_fin_translatevalues xftv
        WHERE xftd.translate_id   = xftv.translate_id
        AND xftv.source_value1    =r1.bank_name
        AND xftd.translation_name = 'XX_CE_BANK_GL_STRING'
        AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
        AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
        AND xftv.enabled_flag = 'Y'
        AND xftd.enabled_flag = 'Y';
        SELECT NVL(bank_party_id,0)
        INTO lv_bank_id
        FROM ce_banks_v
        WHERE bank_number=lv_Bank_number;
      EXCEPTION
      WHEN OTHERS THEN
        lv_bank_id :=0;
      END;
      IF r1.country_code = 403 THEN
        lv_country_code := 'CA';
      ELSE
        lv_country_code := 'US';
      END IF;
      IF lv_bank_id > 0 THEN
        UPDATE xx_ce_bank_stg
        SET bank_id  = lv_bank_id,
          bank_number=lv_Bank_number
        WHERE 1      =1
        AND ROWID    =r1.ROWID;
        COMMIT;
        log_debug_msg( SQL%rowcount ||lv_bank_id||'   '||r1.bank_name|| ' Bank is already present in system');
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      gv_error_code := 'E';
      gv_err_msg    := gv_err_msg || ' ' ||lv_Bank_number ||' Internal Bank is not available in System '||' '||sqlerrm;
      fnd_file.put_line(fnd_file.LOG,' Internal Bank is not available in System '||sqlerrm);
      x_retcode := 2;
    END;
    BEGIN
      BEGIN
        SELECT NVL(branch_party_id,0),
          branch_number,
          bank_branch_name,
          bank_branch_type,
          description
        INTO lc_branch_id,
          lv_branch_number,
          lv_branch_name,
          lv_brach_type,
          lv_branch_description
        FROM ce_bank_branches_v
        WHERE bank_party_id  = lv_bank_id
        AND bank_branch_name =r1.branch_name;
        fnd_file.put_line(fnd_file.LOG ,SQL%rowcount||'  Before Branch API '||lv_bank_id ||' ' ||lc_branch_id );
      EXCEPTION
      WHEN OTHERS THEN
        gv_error_code := 'E';
        gv_err_msg    := gv_err_msg || ' ' ||' Internal Bank branch is not available for bank '|| lv_bank_number ||' '|| sqlerrm;
        fnd_file.put_line(fnd_file.LOG,' Internal Bank branch is not available for bank '|| lv_bank_number ||' '||sqlerrm);
        x_retcode := 2;
      END;
      IF lc_branch_id > 0 THEN
        UPDATE xx_ce_bank_stg
        SET bank_branch_id  = lc_branch_id,
          branch_number     = lv_branch_number,
          branch_type       = lv_brach_type,
          BRANCH_DESCRIPTION=lv_branch_description
        WHERE ROWID         =r1.ROWID;
        fnd_file.put_line(fnd_file.LOG ,SQL%rowcount||'  Updated existing branch id '||lv_bank_id ||' ' ||lc_branch_id );
        COMMIT;
      END IF;
      IF lc_branch_id > 0 THEN
        BEGIN
          fnd_file.put_line(fnd_file.LOG ,' Checking acct if exist for Bank Account Num:' ||r1.bank_account_num);
          SELECT NVL(bank_account_id,0),
            bank_branch_id,
            bank_account_name
          INTO lc_acct_id,
            lc_branch_id,
            lc_bank_account_name
          FROM ce_bank_accounts
          WHERE bank_id        = lv_bank_id
          AND bank_branch_id   = lc_branch_id
          AND bank_account_num = NVL(r1.bank_account_num,bank_account_num);
          gv_err_msg          := gv_err_msg || ' ' || r1.bank_account_num || ' already exists ';
          gv_error_code       := 'E';
          fnd_file.put_line(fnd_file.log ,' lc_acct_id is already exists ' ||lc_acct_id||' '||gv_error_code );
        EXCEPTION
        WHEN OTHERS THEN
          lc_acct_id:=0;
          --fnd_file.put_line(fnd_file.LOG ,' Checking in Exception for Acct Id: ' ||lc_acct_id);
        END;
        IF lc_acct_id > 0 THEN
          SELECT NVL(bank_acct_use_id,0)
          INTO lc_acct_use_id
          FROM ce_bank_acct_uses_all
          WHERE bank_account_id = lc_acct_id;
          UPDATE xx_ce_bank_stg
          SET bank_account_id = lc_acct_id,
            bank_account_name = lc_bank_account_name,
            bank_acct_use_id  = lc_acct_use_id
          WHERE ROWID         =r1.ROWID;
          COMMIT;
          IF lc_acct_use_id = 0 THEN
            create_bank_acct_use( p_bank_id => lv_bank_id, p_bank_branch => lc_branch_id, p_acct_id => lc_acct_id, p_user_id => gn_user_id, p_cash_ccid => lv_cash_ccid, p_cash_clearing_ccid => lv_cash_clearing_ccid, p_bank_charges_ccid => lv_bank_charges_ccid, p_bank_error_ccid => lv_bank_error_ccid, lv_account_return_status1 => lc_upd_account_ret_status1);
            IF lc_upd_account_ret_status1 = gc_success THEN
              gv_error_code              := 'S';
              SELECT NVL(bank_acct_use_id,0)
              INTO lc_acct_use_id
              FROM ce_bank_acct_uses_all
              WHERE bank_account_id = lc_acct_id;
              UPDATE xx_ce_bank_stg
              SET bank_acct_use_id= lc_acct_use_id
              WHERE ROWID         =r1.ROWID;
              fnd_file.put_line(fnd_file.LOG ,SQL%rowcount||'  Account Use id created when account id is already present');
              COMMIT;
            END IF;
          END IF;
        elsif lc_acct_id = 0 THEN
          create_bank_acct(p_acc_bank_id => lv_bank_id, p_acc_bank_branch => lc_branch_id, p_bank_account_num => r1.bank_account_num, p_user_id => gn_user_id, lv_acct_id => lvc_acct_id, lv_account_return_status => lc_upd_account_ret_status);
          IF lc_upd_account_ret_status = gc_success THEN
            SELECT NVL(bank_account_id,0),
              bank_branch_id,
              bank_account_name,
              asset_code_combination_id,
              cash_clearing_ccid,
              bank_charges_ccid,
              bank_errors_ccid
            INTO lc_acct_id,
              lc_branch_id,
              lc_bank_account_name,
              lc_cash_ccid,
              lc_cash_clearing_ccid,
              lc_bank_charges_ccid,
              lc_bank_error_ccid
            FROM ce_bank_accounts
            WHERE bank_id       = lv_bank_id
            AND bank_branch_id  = lc_branch_id
            AND bank_account_id = lvc_acct_id;
            UPDATE xx_ce_bank_stg SET bank_account_id = lc_acct_id WHERE rowid=r1.rowid;
            COMMIT;
            IF lc_cash_ccid  =0 OR lc_cash_clearing_ccid =0 OR lc_bank_charges_ccid =0 OR lc_bank_error_ccid =0 THEN
              gv_error_code := 'E';
              gv_err_msg    := gv_err_msg ||' '||'  Bank Acct id is Created without any of GL String ';
              fnd_file.put_line(fnd_file.LOG ,SQL%rowcount||'  Bank Acct id is Created without any of GL String ');
            ELSE
              gv_error_code := 'S';
              fnd_file.put_line(fnd_file.log ,sql%rowcount||'  Bank Acct id is updated in the Staging table XX_CE_BANK_STG');
              create_bank_acct_use( p_bank_id => lv_bank_id, p_bank_branch => lc_branch_id, p_acct_id => lc_acct_id, p_user_id => gn_user_id, p_cash_ccid => lv_cash_ccid, p_cash_clearing_ccid => lv_cash_clearing_ccid, p_bank_charges_ccid => lv_bank_charges_ccid, p_bank_error_ccid => lv_bank_error_ccid, lv_account_return_status1 => lc_upd_account_ret_status1);
              IF lc_upd_account_ret_status1 = gc_success THEN
                gv_error_code              := 'S';
                SELECT NVL(bank_acct_use_id,0)
                INTO lc_acct_use_id
                FROM ce_bank_acct_uses_all
                WHERE bank_account_id = lc_acct_id;
                UPDATE xx_ce_bank_stg
                SET bank_acct_use_id= lc_acct_use_id
                WHERE ROWID         =r1.ROWID;
                fnd_file.put_line(fnd_file.LOG ,SQL%rowcount||'  Account Use id created when account id is NEW');
                COMMIT;
				DELETE FROM xx_ce_bank_stg WHERE creation_date <= sysdate -90;
                fnd_file.put_line(fnd_file.log ,sql%rowcount||'  records Deleted in the table xx_ce_bank_stg more than 90 days '); 
           COMMIT;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'Internal Branch or Account creation - Process Ended in Error....'||sqlerrm);
      gv_error_code := 'E';
      gv_err_msg    := gv_err_msg || ' ' ||sqlerrm ;
    END;
    IF gv_error_code = 'E' THEN
      x_retcode     := 1;
    ELSE
      x_retcode  := 0;
      gv_err_msg :=NULL;
    END IF;
    UPDATE xx_ce_bank_stg
    SET process_flag = gv_error_code,
      request_id     =gn_request_id,
      error_msg      = gv_err_msg
    WHERE ROWID      =r1.ROWID;
  END LOOP;
  write_output (gn_request_id,gn_user_id);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.LOG,'Overall Bank creation - Process Ended in Error....'||sqlerrm);
  gv_error_code := 'E';
  gv_err_msg    := gv_err_msg || ' ' ||sqlerrm ;
  x_retcode     := 2;
END EXTRACT;
END xx_ce_bank_webadi_pkg;
/
SHOW ERROR;