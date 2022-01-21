-- +==============================================================================+
-- |                                  Office Depot                                |
-- |                                                                              |
-- +==============================================================================+
-- | Script Name: XX_IBY_EXT_BANK_ACCOUNTS_V.vw                                   |
-- | View Name  : XX_IBY_EXT_BANK_ACCOUNTS_V                                      |
-- | RICE #     : E3084 - EBS_Database_Roles                                      |
-- | Description: View created to hide senstive data in table                     |
-- |                IBY_EXT_BANK_ACCOUNTS                                         |
-- |                                                                              |
-- |                  Columns excluded: bank_account_num                          |
-- |                                    bank_account_num_hash1                    |
-- |                                    bank_account_num_hash2                    |
-- |                                    bank_account_num_electronic               |
-- |                                    bank_account_name                         |
-- |                                    masked_bank_account_num                   |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version  Date         Author                 Comments                         |
-- |=======  ===========  =====================  =================================|
-- |  1.0    16-MAR-2014  R.Aldridge             Initial version                  |
-- |  1.1    04-JAN-2017  Avinash B		 R12.2 GSCC Changes               |
-- |                                                                              |
-- +==============================================================================+
CREATE OR REPLACE FORCE VIEW XX_IBY_EXT_BANK_ACCOUNTS_V
AS
SELECT ext_bank_account_id
      ,country_code
      ,branch_id
      ,bank_id
      ,ba_mask_setting
      ,ba_unmask_length
      ,currency_code
      ,iban
      ,iban_hash1
      ,iban_hash2
      ,salt_version
      ,masked_iban
      ,check_digits
      ,bank_account_type
      ,account_classification
      ,account_suffix
      ,agency_location_code
      ,payment_factor_flag
      ,foreign_payment_use_flag
      ,exchange_rate_agreement_num
      ,exchange_rate_agreement_type
      ,exchange_rate
      ,hedging_contract_reference
      ,secondary_account_reference
      ,ba_num_sec_segment_id
      ,encrypted
      ,iban_sec_segment_id
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
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
      ,start_date
      ,end_date
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,object_version_number
      ,bank_account_name_alt
      ,short_acct_name
      ,description
      ,ba_num_elec_sec_segment_id
      ,contact_name
      ,contact_phone
      ,contact_fax
      ,contact_email
 FROM iby_ext_bank_accounts;
