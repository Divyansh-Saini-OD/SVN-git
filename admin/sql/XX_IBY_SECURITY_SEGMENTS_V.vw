-- +==============================================================================+
-- |                                  Office Depot                                |
-- |                                                                              |
-- +==============================================================================+
-- | Script Name: XX_IBY_SECURITY_SEGMENTS_V.vw                                   |
-- | View Name  : XX_IBY_SECURITY_SEGMENTS_V                                      |
-- | RICE #     : E3084 - EBS_Database_Roles                                      |
-- | Description: View created to hide senstive data in table                     |
-- |                IBY_SECURITY_SEGMENTS                                         |
-- |                                                                              |
-- |                  Columns excluded: segment_cipher_text                       |
-- |                                    cc_unmask_digits                          |
-- |                                    cc_number_hash1                           |
-- |                                    cc_number_hash2                           |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version  Date         Author                 Comments                         |
-- |=======  ===========  =====================  =================================|
-- |  1.0    16-MAR-2014  R.Aldridge             Initial version                  |
-- |  1.1    04-JAN-2017  Avinash B		 R12.2 GSCC Changes               |
-- |                                                                              |
-- +==============================================================================+
CREATE OR REPLACE FORCE VIEW XX_IBY_SECURITY_SEGMENTS_V
AS
SELECT sec_segment_id
      ,sec_subkey_id
      ,encoding_scheme
      ,cc_number_length
      ,cc_issuer_range_id
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,object_version_number
      ,salt_version
 FROM iby_security_segments;
 