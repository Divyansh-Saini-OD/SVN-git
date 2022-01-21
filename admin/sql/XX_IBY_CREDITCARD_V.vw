-- +==============================================================================+
-- |                                  Office Depot                                |
-- |                                                                              |
-- +==============================================================================+
-- | Script Name: XX_IBY_CREDITCARD_V.vw                                          |
-- | View Name  : XX_IBY_CREDITCARD_V                                             |
-- | RICE #     : E3084 - EBS_Database_Roles                                      |
-- | Description: View created to hide senstive data in table                     |
-- |                IBY_CREDITCARD_V                                              |
-- |                                                                              |
-- |                  Columns excluded: ccnumber                                  |
-- |                                    cc_number_hash1                           |
-- |                                    cc_number_hash2                           |
-- |                                    masked_cc_number                          |
-- |                                    attribute4                                |
-- |                                    attribute5                                |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version  Date         Author                 Comments                         |
-- |=======  ===========  =====================  =================================|
-- |  1.0    16-MAR-2014  R.Aldridge             Initial version                  |
-- |  1.1    04-JAN-2017  Avinash B		 R12.2 GSCC Changes               |
-- |                                                                              |
-- +==============================================================================+
CREATE OR REPLACE FORCE VIEW XX_IBY_CREDITCARD_V
AS
SELECT instrid
      ,expirydate
      ,accttypeid
      ,addressid
      ,instrname
      ,description
      ,chname
      ,finame
      ,last_update_date
      ,last_updated_by
      ,creation_date
      ,created_by
      ,last_update_login
      ,object_version_number
      ,subtype
      ,security_group_id
      ,encrypted
      ,card_issuer_code
      ,cc_issuer_range_id
      ,cc_number_length
      ,card_mask_setting
      ,card_unmask_length
      ,cc_num_sec_segment_id
      ,salt_version
      ,card_owner_id
      ,billing_addr_postal_code
      ,bill_addr_territory_code
      ,instrument_type
      ,purchasecard_flag
      ,purchasecard_subtype
      ,active_flag
      ,single_use_flag
      ,information_only_flag
      ,card_purpose
      ,inactive_date
      ,attribute_category
      ,attribute1
      ,attribute2
      ,attribute3
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
      ,attribute16
      ,attribute17
      ,attribute18
      ,attribute19
      ,attribute20
      ,attribute21
      ,attribute22
      ,attribute23
      ,attribute24
      ,attribute25
      ,attribute26
      ,attribute27
      ,attribute28
      ,attribute29
      ,attribute30
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
      ,upgrade_addressid
      ,sec_subkey_id
      ,expiry_sec_segment_id
      ,chname_sec_segment_id
      ,expired_flag
      ,chname_mask_setting
      ,chname_unmask_length
      ,invalid_flag
      ,invalidation_reason
 FROM iby_creditcard;
 