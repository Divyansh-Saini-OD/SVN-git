-- +==============================================================================+
-- |                                  Office Depot                                |
-- |                                                                              |
-- +==============================================================================+
-- | Script Name: XX_AP_BANK_ACCOUNTS_ALL_V.vw                                    |
-- | View Name  : apps.xx_ap_bank_accounts_all_v                                  |
-- | RICE #     : E3084 - EBS_Database_Roles                                      |
-- | Description: View created to hide senstive data in table.  Columns excluded: |
-- |                                                                              |
-- |               bank_account_num                                               |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version  Date         Author                 Comments                         |
-- |=======  ===========  =====================  =================================|
-- |  1.0    16-MAR-2014  R.Aldridge             Initial version                  |
-- |  1.1    30-DEC-2015  Harvinder Rakhra       R12.2 Retrofit                   |
-- |                                                                              |
-- +==============================================================================+
CREATE OR REPLACE FORCE VIEW XX_AP_BANK_ACCOUNTS_ALL_V
AS
SELECT bank_account_id
      ,bank_account_name
      ,last_update_date
      ,last_updated_by
      ,last_update_login
      ,creation_date
      ,created_by
      ,bank_branch_id
      ,set_of_books_id
      ,currency_code
      ,description
      ,contact_first_name
      ,contact_middle_name
      ,contact_last_name
      ,contact_prefix
      ,contact_title
      ,contact_area_code
      ,contact_phone
      ,max_check_amount
      ,min_check_amount
      ,one_signature_max_flag
      ,inactive_date
      ,avg_float_days
      ,asset_code_combination_id
      ,gain_code_combination_id
      ,loss_code_combination_id
      ,bank_account_type
      ,validation_number
      ,max_outlay
      ,multi_currency_flag
      ,account_type
      ,attribute_category
      ,attribute1
      ,attribute2
      ,attribute3
      ,attribute4
      ,attribute5
      ,attribute6
      ,attribute7
      ,attribute8
      ,attribute9
      ,attribute10
      ,attribute11
      ,attribute12
      ,attribute13
      ,attribute14
      ,attribute15
      ,pooled_flag
      ,zero_amounts_allowed
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
      ,receipt_multi_currency_flag
      ,check_digits
      ,org_id
      ,cash_clearing_ccid
      ,bank_charges_ccid
      ,bank_errors_ccid
      ,earned_ccid
      ,unearned_ccid
      ,on_account_ccid
      ,unapplied_ccid
      ,unidentified_ccid
      ,factor_ccid
      ,receipt_clearing_ccid
      ,remittance_ccid
      ,short_term_deposit_ccid
      ,global_attribute_category
      ,global_attribute1
      ,global_attribute2
      ,global_attribute3
      ,global_attribute4
      ,global_attribute5
      ,global_attribute6
      ,global_attribute7
      ,global_attribute8
      ,global_attribute9
      ,global_attribute10
      ,global_attribute11
      ,global_attribute12
      ,global_attribute13
      ,global_attribute14
      ,global_attribute15
      ,global_attribute16
      ,global_attribute17
      ,global_attribute18
      ,global_attribute19
      ,global_attribute20
      ,bank_account_name_alt
      ,account_holder_name
      ,account_holder_name_alt
      ,eft_requester_id
      ,eft_user_number
      ,payroll_bank_account_id
      ,future_dated_payment_ccid
      ,edisc_receivables_trx_id
      ,unedisc_receivables_trx_id
      ,br_remittance_ccid
      ,br_factor_ccid
      ,br_std_receivables_trx_id
      ,allow_multi_assignments_flag
      ,agency_location_code
      ,iban_number
  FROM ap_bank_accounts_all;
