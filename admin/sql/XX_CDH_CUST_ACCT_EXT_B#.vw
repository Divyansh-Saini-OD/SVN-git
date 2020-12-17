-- +========================================================================+
-- |                  Office Depot                                          |
-- +========================================================================+
-- | Name        : XX_CDH_CUST_ACCT_EXT_B#.vw                               |
-- | Description : Added new field in the existing XX_CDH_CUST_ACCT_EXT_B#  |
-- |               table   fee_option                                       |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date        Author           Remarks                          |
-- |=======  ===========  =============    =================================|
-- |1.0      20-Oct-2020  Divyansh Saini    Initial Version                 |
-- +========================================================================+
CREATE OR REPLACE VIEW xxcrm.XX_CDH_CUST_ACCT_EXT_B#
AS
  SELECT EXTENSION_ID EXTENSION_ID,
    CUST_ACCOUNT_ID CUST_ACCOUNT_ID,
    ATTR_GROUP_ID ATTR_GROUP_ID,
    CREATED_BY CREATED_BY,
    CREATION_DATE CREATION_DATE,
    LAST_UPDATED_BY LAST_UPDATED_BY,
    LAST_UPDATE_DATE LAST_UPDATE_DATE,
    LAST_UPDATE_LOGIN LAST_UPDATE_LOGIN,
    C_EXT_ATTR1 C_EXT_ATTR1,
    C_EXT_ATTR2 C_EXT_ATTR2,
    C_EXT_ATTR3 C_EXT_ATTR3,
    C_EXT_ATTR4 C_EXT_ATTR4,
    C_EXT_ATTR5 C_EXT_ATTR5,
    C_EXT_ATTR6 C_EXT_ATTR6,
    C_EXT_ATTR7 C_EXT_ATTR7,
    C_EXT_ATTR8 C_EXT_ATTR8,
    C_EXT_ATTR9 C_EXT_ATTR9,
    C_EXT_ATTR10 C_EXT_ATTR10,
    C_EXT_ATTR11 C_EXT_ATTR11,
    C_EXT_ATTR12 C_EXT_ATTR12,
    C_EXT_ATTR13 C_EXT_ATTR13,
    C_EXT_ATTR14 C_EXT_ATTR14,
    C_EXT_ATTR15 C_EXT_ATTR15,
    C_EXT_ATTR16 C_EXT_ATTR16,
    C_EXT_ATTR17 C_EXT_ATTR17,
    C_EXT_ATTR18 C_EXT_ATTR18,
    C_EXT_ATTR19 C_EXT_ATTR19,
    C_EXT_ATTR20 C_EXT_ATTR20,
    N_EXT_ATTR1 N_EXT_ATTR1,
    N_EXT_ATTR2 N_EXT_ATTR2,
    N_EXT_ATTR3 N_EXT_ATTR3,
    N_EXT_ATTR4 N_EXT_ATTR4,
    N_EXT_ATTR5 N_EXT_ATTR5,
    N_EXT_ATTR6 N_EXT_ATTR6,
    N_EXT_ATTR7 N_EXT_ATTR7,
    N_EXT_ATTR8 N_EXT_ATTR8,
    N_EXT_ATTR9 N_EXT_ATTR9,
    N_EXT_ATTR10 N_EXT_ATTR10,
    N_EXT_ATTR11 N_EXT_ATTR11,
    N_EXT_ATTR12 N_EXT_ATTR12,
    N_EXT_ATTR13 N_EXT_ATTR13,
    N_EXT_ATTR14 N_EXT_ATTR14,
    N_EXT_ATTR15 N_EXT_ATTR15,
    N_EXT_ATTR16 N_EXT_ATTR16,
    N_EXT_ATTR17 N_EXT_ATTR17,
    N_EXT_ATTR18 N_EXT_ATTR18,
    N_EXT_ATTR19 N_EXT_ATTR19,
    N_EXT_ATTR20 N_EXT_ATTR20,
    D_EXT_ATTR1 D_EXT_ATTR1,
    D_EXT_ATTR2 D_EXT_ATTR2,
    D_EXT_ATTR3 D_EXT_ATTR3,
    D_EXT_ATTR4 D_EXT_ATTR4,
    D_EXT_ATTR5 D_EXT_ATTR5,
    D_EXT_ATTR6 D_EXT_ATTR6,
    D_EXT_ATTR7 D_EXT_ATTR7,
    D_EXT_ATTR8 D_EXT_ATTR8,
    D_EXT_ATTR9 D_EXT_ATTR9,
    D_EXT_ATTR10 D_EXT_ATTR10,
    BC_POD_FLAG BC_POD_FLAG ,
    fee_option
  FROM "XXCRM"."XX_CDH_CUST_ACCT_EXT_B";