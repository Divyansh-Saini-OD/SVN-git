-- +==============================================================================+
-- |                                  Office Depot                                |
-- |                                                                              |
-- +==============================================================================+
-- | Script Name: XX_IBY_CREDITCARD_H_V.vw                                        |
-- | View Name  : XX_IBY_CREDITCARD_H_V                                           |
-- | RICE #     : E3084 - EBS_Database_Roles                                      |
-- | Description: View created to hide senstive data in table                     |
-- |                IBY_CREDITCARD_H                                              |
-- |                                                                              |
-- |                  Columns excluded: masked_cc_number                          |
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
CREATE OR REPLACE FORCE VIEW XX_IBY_CREDITCARD_H_V
AS
SELECT card_history_change_id
      ,instrid
      ,expirydate
      ,addressid
      ,description
      ,chname
      ,finame
      ,security_group_id
      ,encrypted
      ,card_owner_id
      ,instrument_type
      ,purchasecard_flag
      ,purchasecard_subtype
      ,card_issuer_code
      ,single_use_flag
      ,information_only_flag
      ,card_purpose
      ,active_flag
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
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,object_version_number
      ,effective_start_date
      ,effective_end_date
      ,expiry_sec_segment_id
      ,chname_sec_segment_id
 FROM iby_creditcard_h;
 