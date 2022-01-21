SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE xx_ce_bank_webadi_pkg
IS
  -- +=====================================================================================================+
  -- |                              Office Depot                                                           |
  -- +=====================================================================================================+
  -- | Name        :  XX_CE_BANK_WEBADI_PKG                                                                 |
  -- |                                                                                                     |
  -- | Description :  Package Spec to upload new Bank Accounts under existing banks and branches           |
  -- | Rice ID     :                                                                                       |
  -- |Change Record:                                                                                       |
  -- |===============                                                                                      |
  -- |Version   Date         Author           Remarks                                                      |
  -- |=======   ==========   =============    ======================                                       |
  -- | 1.0      24-Nov-2017  Jitendra Atale    Initial Version                                              |
  -- | 1.1      22-Jun-2018  Jitendra Atale    Added Dynamic code combination creation API                 |
  -- +=====================================================================================================+
  -- +===================================================================+
  -- | Name  : fetch_data                                                |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to xx_ce_bank_staging table              |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- +===================================================================+
  gn_user_id    NUMBER;
  gn_request_id NUMBER;
  gv_err_msg    VARCHAR2(1000);
  gv_error_code VARCHAR2(1) :='N';
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
      p_bank_error_ccid             IN VARCHAR2 );
  -- +===================================================================+
  -- | Name  : extract                                                   |
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records from XX_AP_MERCH_CONT_STG               |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- +===================================================================+
  PROCEDURE extract(
      x_errbuf OUT nocopy  VARCHAR2,
      x_retcode OUT nocopy NUMBER);
END xx_ce_bank_webadi_pkg;
/

SHOW ERROR;