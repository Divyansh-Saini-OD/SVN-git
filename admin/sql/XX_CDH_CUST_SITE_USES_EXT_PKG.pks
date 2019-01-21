CREATE OR REPLACE package XX_CDH_CUST_SITE_USES_EXT_PKG 
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_CDH_CUST_SITE_USES_EXT_PKG                                           |
-- | Description: This package provides table handlers for XX_CDH_SITE_USES_EXT_B and         |
-- |              and XX_CDH_SITE_USES_EXT_TL tables.                                         | 
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date         Author           Remarks                                       |
-- |=======   ===========  =============    ==============================================|
-- |DRAFT 1A  21-MAR-2007  Prem Kumar B     Initial draft version                         |
-- +======================================================================================+
AS

-- +==============================================================================+
-- | Name             : INSERT_ROW                                                |
-- | Description      : This procedure shall insert data into XX_CDH_SITE_USES_EXT_B  |
-- |                    and XX_CDH_SITE_USES_EXT_TL tables.                           |
-- |                                                                              |
-- +==============================================================================+

procedure INSERT_ROW (
  X_ROWID in out nocopy VARCHAR2,
  X_EXTENSION_ID IN NUMBER,
  X_SITE_USE_ID IN NUMBER,
  X_ATTR_GROUP_ID IN NUMBER,
  X_C_EXT_ATTR1 IN VARCHAR2,
  X_C_EXT_ATTR2 IN VARCHAR2,
  X_C_EXT_ATTR3 IN VARCHAR2,
  X_C_EXT_ATTR4 IN VARCHAR2,
  X_C_EXT_ATTR5 IN VARCHAR2,
  X_C_EXT_ATTR6 IN VARCHAR2,
  X_C_EXT_ATTR7 IN VARCHAR2,
  X_C_EXT_ATTR8 IN VARCHAR2,
  X_C_EXT_ATTR9 IN VARCHAR2,
  X_C_EXT_ATTR10 IN VARCHAR2,
  X_C_EXT_ATTR11 IN VARCHAR2,
  X_C_EXT_ATTR12 IN VARCHAR2,
  X_C_EXT_ATTR13 IN VARCHAR2,
  X_C_EXT_ATTR14 IN VARCHAR2,
  X_C_EXT_ATTR15 IN VARCHAR2,
  X_C_EXT_ATTR16 IN VARCHAR2,
  X_C_EXT_ATTR17 IN VARCHAR2,
  X_C_EXT_ATTR18 IN VARCHAR2,
  X_C_EXT_ATTR19 IN VARCHAR2,
  X_C_EXT_ATTR20 IN VARCHAR2,
  X_N_EXT_ATTR1 IN NUMBER,
  X_N_EXT_ATTR2 IN NUMBER,
  X_N_EXT_ATTR3 IN NUMBER,
  X_N_EXT_ATTR4 IN NUMBER,
  X_N_EXT_ATTR5 IN NUMBER,
  X_N_EXT_ATTR6 IN NUMBER,
  X_N_EXT_ATTR7 IN NUMBER,
  X_N_EXT_ATTR8 IN NUMBER,
  X_N_EXT_ATTR9 IN NUMBER,
  X_N_EXT_ATTR10 IN NUMBER,
  X_N_EXT_ATTR11 IN NUMBER,
  X_N_EXT_ATTR12 IN NUMBER,
  X_N_EXT_ATTR13 IN NUMBER,
  X_N_EXT_ATTR14 IN NUMBER,
  X_N_EXT_ATTR15 IN NUMBER,
  X_N_EXT_ATTR16 IN NUMBER,
  X_N_EXT_ATTR17 IN NUMBER,
  X_N_EXT_ATTR18 IN NUMBER,
  X_N_EXT_ATTR19 IN NUMBER,
  X_N_EXT_ATTR20 IN NUMBER,
  X_D_EXT_ATTR1 IN DATE,
  X_D_EXT_ATTR2 IN DATE,
  X_D_EXT_ATTR3 IN DATE,
  X_D_EXT_ATTR4 IN DATE,
  X_D_EXT_ATTR5 IN DATE,
  X_D_EXT_ATTR6 IN DATE,
  X_D_EXT_ATTR7 IN DATE,
  X_D_EXT_ATTR8 IN DATE,
  X_D_EXT_ATTR9 IN DATE,
  X_D_EXT_ATTR10 IN DATE,
  X_TL_EXT_ATTR1 IN VARCHAR2,
  X_TL_EXT_ATTR2 IN VARCHAR2,
  X_TL_EXT_ATTR3 IN VARCHAR2,
  X_TL_EXT_ATTR4 IN VARCHAR2,
  X_TL_EXT_ATTR5 IN VARCHAR2,
  X_TL_EXT_ATTR6 IN VARCHAR2,
  X_TL_EXT_ATTR7 IN VARCHAR2,
  X_TL_EXT_ATTR8 IN VARCHAR2,
  X_TL_EXT_ATTR9 IN VARCHAR2,
  X_TL_EXT_ATTR10 IN VARCHAR2,
  X_TL_EXT_ATTR11 IN VARCHAR2,
  X_TL_EXT_ATTR12 IN VARCHAR2,
  X_TL_EXT_ATTR13 IN VARCHAR2,
  X_TL_EXT_ATTR14 IN VARCHAR2,
  X_TL_EXT_ATTR15 IN VARCHAR2,
  X_TL_EXT_ATTR16 IN VARCHAR2,
  X_TL_EXT_ATTR17 IN VARCHAR2,
  X_TL_EXT_ATTR18 IN VARCHAR2,
  X_TL_EXT_ATTR19 IN VARCHAR2,
  X_TL_EXT_ATTR20 IN VARCHAR2,
  X_CREATION_DATE in DATE,
  X_CREATED_BY in NUMBER,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
);

-- +==============================================================================+
-- | Name             : LOCK_ROW                                                  |
-- | Description      : This procedure shall lock rows into XX_CDH_SITE_USES_EXT_B    |
-- |                    and XX_CDH_SITE_USES_EXT_TL tables.                           |
-- |                                                                              |
-- |                                                                              |
-- +==============================================================================+

procedure LOCK_ROW (
  X_EXTENSION_ID IN NUMBER,
  X_SITE_USE_ID IN NUMBER,
  X_ATTR_GROUP_ID IN NUMBER,
  X_C_EXT_ATTR1 IN VARCHAR2,
  X_C_EXT_ATTR2 IN VARCHAR2,
  X_C_EXT_ATTR3 IN VARCHAR2,
  X_C_EXT_ATTR4 IN VARCHAR2,
  X_C_EXT_ATTR5 IN VARCHAR2,
  X_C_EXT_ATTR6 IN VARCHAR2,
  X_C_EXT_ATTR7 IN VARCHAR2,
  X_C_EXT_ATTR8 IN VARCHAR2,
  X_C_EXT_ATTR9 IN VARCHAR2,
  X_C_EXT_ATTR10 IN VARCHAR2,
  X_C_EXT_ATTR11 IN VARCHAR2,
  X_C_EXT_ATTR12 IN VARCHAR2,
  X_C_EXT_ATTR13 IN VARCHAR2,
  X_C_EXT_ATTR14 IN VARCHAR2,
  X_C_EXT_ATTR15 IN VARCHAR2,
  X_C_EXT_ATTR16 IN VARCHAR2,
  X_C_EXT_ATTR17 IN VARCHAR2,
  X_C_EXT_ATTR18 IN VARCHAR2,
  X_C_EXT_ATTR19 IN VARCHAR2,
  X_C_EXT_ATTR20 IN VARCHAR2,
  X_N_EXT_ATTR1 IN NUMBER,
  X_N_EXT_ATTR2 IN NUMBER,
  X_N_EXT_ATTR3 IN NUMBER,
  X_N_EXT_ATTR4 IN NUMBER,
  X_N_EXT_ATTR5 IN NUMBER,
  X_N_EXT_ATTR6 IN NUMBER,
  X_N_EXT_ATTR7 IN NUMBER,
  X_N_EXT_ATTR8 IN NUMBER,
  X_N_EXT_ATTR9 IN NUMBER,
  X_N_EXT_ATTR10 IN NUMBER,
  X_N_EXT_ATTR11 IN NUMBER,
  X_N_EXT_ATTR12 IN NUMBER,
  X_N_EXT_ATTR13 IN NUMBER,
  X_N_EXT_ATTR14 IN NUMBER,
  X_N_EXT_ATTR15 IN NUMBER,
  X_N_EXT_ATTR16 IN NUMBER,
  X_N_EXT_ATTR17 IN NUMBER,
  X_N_EXT_ATTR18 IN NUMBER,
  X_N_EXT_ATTR19 IN NUMBER,
  X_N_EXT_ATTR20 IN NUMBER,
  X_D_EXT_ATTR1 IN DATE,
  X_D_EXT_ATTR2 IN DATE,
  X_D_EXT_ATTR3 IN DATE,
  X_D_EXT_ATTR4 IN DATE,
  X_D_EXT_ATTR5 IN DATE,
  X_D_EXT_ATTR6 IN DATE,
  X_D_EXT_ATTR7 IN DATE,
  X_D_EXT_ATTR8 IN DATE,
  X_D_EXT_ATTR9 IN DATE,
  X_D_EXT_ATTR10 IN DATE,
  X_TL_EXT_ATTR1 IN VARCHAR2,
  X_TL_EXT_ATTR2 IN VARCHAR2,
  X_TL_EXT_ATTR3 IN VARCHAR2,
  X_TL_EXT_ATTR4 IN VARCHAR2,
  X_TL_EXT_ATTR5 IN VARCHAR2,
  X_TL_EXT_ATTR6 IN VARCHAR2,
  X_TL_EXT_ATTR7 IN VARCHAR2,
  X_TL_EXT_ATTR8 IN VARCHAR2,
  X_TL_EXT_ATTR9 IN VARCHAR2,
  X_TL_EXT_ATTR10 IN VARCHAR2,
  X_TL_EXT_ATTR11 IN VARCHAR2,
  X_TL_EXT_ATTR12 IN VARCHAR2,
  X_TL_EXT_ATTR13 IN VARCHAR2,
  X_TL_EXT_ATTR14 IN VARCHAR2,
  X_TL_EXT_ATTR15 IN VARCHAR2,
  X_TL_EXT_ATTR16 IN VARCHAR2,
  X_TL_EXT_ATTR17 IN VARCHAR2,
  X_TL_EXT_ATTR18 IN VARCHAR2,
  X_TL_EXT_ATTR19 IN VARCHAR2,
  X_TL_EXT_ATTR20 IN VARCHAR2
);

-- +==============================================================================+
-- | Name             : UPDATE_ROW                                                |
-- | Description      : This procedure shall update data into XX_CDH_SITE_USES_EXT_B  |
-- |                    and XX_CDH_SITE_USES_EXT_TL tables.                           |
-- |                                                                              |
-- +==============================================================================+

procedure UPDATE_ROW (
  X_EXTENSION_ID IN NUMBER,
  X_SITE_USE_ID IN NUMBER,
  X_ATTR_GROUP_ID IN NUMBER,
  X_C_EXT_ATTR1 IN VARCHAR2,
  X_C_EXT_ATTR2 IN VARCHAR2,
  X_C_EXT_ATTR3 IN VARCHAR2,
  X_C_EXT_ATTR4 IN VARCHAR2,
  X_C_EXT_ATTR5 IN VARCHAR2,
  X_C_EXT_ATTR6 IN VARCHAR2,
  X_C_EXT_ATTR7 IN VARCHAR2,
  X_C_EXT_ATTR8 IN VARCHAR2,
  X_C_EXT_ATTR9 IN VARCHAR2,
  X_C_EXT_ATTR10 IN VARCHAR2,
  X_C_EXT_ATTR11 IN VARCHAR2,
  X_C_EXT_ATTR12 IN VARCHAR2,
  X_C_EXT_ATTR13 IN VARCHAR2,
  X_C_EXT_ATTR14 IN VARCHAR2,
  X_C_EXT_ATTR15 IN VARCHAR2,
  X_C_EXT_ATTR16 IN VARCHAR2,
  X_C_EXT_ATTR17 IN VARCHAR2,
  X_C_EXT_ATTR18 IN VARCHAR2,
  X_C_EXT_ATTR19 IN VARCHAR2,
  X_C_EXT_ATTR20 IN VARCHAR2,
  X_N_EXT_ATTR1 IN NUMBER,
  X_N_EXT_ATTR2 IN NUMBER,
  X_N_EXT_ATTR3 IN NUMBER,
  X_N_EXT_ATTR4 IN NUMBER,
  X_N_EXT_ATTR5 IN NUMBER,
  X_N_EXT_ATTR6 IN NUMBER,
  X_N_EXT_ATTR7 IN NUMBER,
  X_N_EXT_ATTR8 IN NUMBER,
  X_N_EXT_ATTR9 IN NUMBER,
  X_N_EXT_ATTR10 IN NUMBER,
  X_N_EXT_ATTR11 IN NUMBER,
  X_N_EXT_ATTR12 IN NUMBER,
  X_N_EXT_ATTR13 IN NUMBER,
  X_N_EXT_ATTR14 IN NUMBER,
  X_N_EXT_ATTR15 IN NUMBER,
  X_N_EXT_ATTR16 IN NUMBER,
  X_N_EXT_ATTR17 IN NUMBER,
  X_N_EXT_ATTR18 IN NUMBER,
  X_N_EXT_ATTR19 IN NUMBER,
  X_N_EXT_ATTR20 IN NUMBER,
  X_D_EXT_ATTR1 IN DATE,
  X_D_EXT_ATTR2 IN DATE,
  X_D_EXT_ATTR3 IN DATE,
  X_D_EXT_ATTR4 IN DATE,
  X_D_EXT_ATTR5 IN DATE,
  X_D_EXT_ATTR6 IN DATE,
  X_D_EXT_ATTR7 IN DATE,
  X_D_EXT_ATTR8 IN DATE,
  X_D_EXT_ATTR9 IN DATE,
  X_D_EXT_ATTR10 IN DATE,
  X_TL_EXT_ATTR1 IN VARCHAR2,
  X_TL_EXT_ATTR2 IN VARCHAR2,
  X_TL_EXT_ATTR3 IN VARCHAR2,
  X_TL_EXT_ATTR4 IN VARCHAR2,
  X_TL_EXT_ATTR5 IN VARCHAR2,
  X_TL_EXT_ATTR6 IN VARCHAR2,
  X_TL_EXT_ATTR7 IN VARCHAR2,
  X_TL_EXT_ATTR8 IN VARCHAR2,
  X_TL_EXT_ATTR9 IN VARCHAR2,
  X_TL_EXT_ATTR10 IN VARCHAR2,
  X_TL_EXT_ATTR11 IN VARCHAR2,
  X_TL_EXT_ATTR12 IN VARCHAR2,
  X_TL_EXT_ATTR13 IN VARCHAR2,
  X_TL_EXT_ATTR14 IN VARCHAR2,
  X_TL_EXT_ATTR15 IN VARCHAR2,
  X_TL_EXT_ATTR16 IN VARCHAR2,
  X_TL_EXT_ATTR17 IN VARCHAR2,
  X_TL_EXT_ATTR18 IN VARCHAR2,
  X_TL_EXT_ATTR19 IN VARCHAR2,
  X_TL_EXT_ATTR20 IN VARCHAR2,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
);

-- +==============================================================================+
-- | Name             : DELETE_ROW                                                |
-- | Description      : This procedure shall delete data  in XX_CDH_SITE_USES_EXT_B   |
-- |                    XX_CDH_SITE_USES_EXT_TL table for the given extension id.     |
-- |                                                                              |
-- +==============================================================================+

procedure DELETE_ROW (
  X_EXTENSION_ID IN NUMBER);
  
-- +==============================================================================+
-- | Name             : ADD_LANGUAGE                                              |
-- | Description      : This procedure shall insert and update data  in           |
-- |                    XX_CDH_SITE_USES_EXT_TL table.                                |
-- |                                                                              |
-- +==============================================================================+

procedure ADD_LANGUAGE ;


-- +==============================================================================+
-- | Name             : LOAD_ROW                                                  |
-- | Description      : This procedure does not being implemented.                |
-- |                                                                              |
-- |                                                                              |
-- +==============================================================================+

procedure LOAD_ROW(
  X_EXTENSION_ID IN NUMBER,
  X_SITE_USE_ID IN NUMBER,
  X_ATTR_GROUP_ID IN NUMBER,
  X_C_EXT_ATTR1 IN VARCHAR2,
  X_C_EXT_ATTR2 IN VARCHAR2,
  X_C_EXT_ATTR3 IN VARCHAR2,
  X_C_EXT_ATTR4 IN VARCHAR2,
  X_C_EXT_ATTR5 IN VARCHAR2,
  X_C_EXT_ATTR6 IN VARCHAR2,
  X_C_EXT_ATTR7 IN VARCHAR2,
  X_C_EXT_ATTR8 IN VARCHAR2,
  X_C_EXT_ATTR9 IN VARCHAR2,
  X_C_EXT_ATTR10 IN VARCHAR2,
  X_C_EXT_ATTR11 IN VARCHAR2,
  X_C_EXT_ATTR12 IN VARCHAR2,
  X_C_EXT_ATTR13 IN VARCHAR2,
  X_C_EXT_ATTR14 IN VARCHAR2,
  X_C_EXT_ATTR15 IN VARCHAR2,
  X_C_EXT_ATTR16 IN VARCHAR2,
  X_C_EXT_ATTR17 IN VARCHAR2,
  X_C_EXT_ATTR18 IN VARCHAR2,
  X_C_EXT_ATTR19 IN VARCHAR2,
  X_C_EXT_ATTR20 IN VARCHAR2,
  X_N_EXT_ATTR1 IN NUMBER,
  X_N_EXT_ATTR2 IN NUMBER,
  X_N_EXT_ATTR3 IN NUMBER,
  X_N_EXT_ATTR4 IN NUMBER,
  X_N_EXT_ATTR5 IN NUMBER,
  X_N_EXT_ATTR6 IN NUMBER,
  X_N_EXT_ATTR7 IN NUMBER,
  X_N_EXT_ATTR8 IN NUMBER,
  X_N_EXT_ATTR9 IN NUMBER,
  X_N_EXT_ATTR10 IN NUMBER,
  X_N_EXT_ATTR11 IN NUMBER,
  X_N_EXT_ATTR12 IN NUMBER,
  X_N_EXT_ATTR13 IN NUMBER,
  X_N_EXT_ATTR14 IN NUMBER,
  X_N_EXT_ATTR15 IN NUMBER,
  X_N_EXT_ATTR16 IN NUMBER,
  X_N_EXT_ATTR17 IN NUMBER,
  X_N_EXT_ATTR18 IN NUMBER,
  X_N_EXT_ATTR19 IN NUMBER,
  X_N_EXT_ATTR20 IN NUMBER,
  X_D_EXT_ATTR1 IN DATE,
  X_D_EXT_ATTR2 IN DATE,
  X_D_EXT_ATTR3 IN DATE,
  X_D_EXT_ATTR4 IN DATE,
  X_D_EXT_ATTR5 IN DATE,
  X_D_EXT_ATTR6 IN DATE,
  X_D_EXT_ATTR7 IN DATE,
  X_D_EXT_ATTR8 IN DATE,
  X_D_EXT_ATTR9 IN DATE,
  X_D_EXT_ATTR10 IN DATE,
  X_TL_EXT_ATTR1 IN VARCHAR2,
  X_TL_EXT_ATTR2 IN VARCHAR2,
  X_TL_EXT_ATTR3 IN VARCHAR2,
  X_TL_EXT_ATTR4 IN VARCHAR2,
  X_TL_EXT_ATTR5 IN VARCHAR2,
  X_TL_EXT_ATTR6 IN VARCHAR2,
  X_TL_EXT_ATTR7 IN VARCHAR2,
  X_TL_EXT_ATTR8 IN VARCHAR2,
  X_TL_EXT_ATTR9 IN VARCHAR2,
  X_TL_EXT_ATTR10 IN VARCHAR2,
  X_TL_EXT_ATTR11 IN VARCHAR2,
  X_TL_EXT_ATTR12 IN VARCHAR2,
  X_TL_EXT_ATTR13 IN VARCHAR2,
  X_TL_EXT_ATTR14 IN VARCHAR2,
  X_TL_EXT_ATTR15 IN VARCHAR2,
  X_TL_EXT_ATTR16 IN VARCHAR2,
  X_TL_EXT_ATTR17 IN VARCHAR2,
  X_TL_EXT_ATTR18 IN VARCHAR2,
  X_TL_EXT_ATTR19 IN VARCHAR2,
  X_TL_EXT_ATTR20 IN VARCHAR2,
  X_OWNER in VARCHAR2);

-- +==============================================================================+
-- | Name             : TRANSLATE_ROW                                             |
-- | Description      : This procedure does not being implemented.                |
-- |                                                                              |
-- +==============================================================================+

procedure TRANSLATE_ROW (
  X_EXTENSION_ID IN NUMBER,
  X_SITE_USE_ID IN NUMBER,
  X_ATTR_GROUP_ID IN NUMBER,
  X_TL_EXT_ATTR1 IN VARCHAR2,
  X_TL_EXT_ATTR2 IN VARCHAR2,
  X_TL_EXT_ATTR3 IN VARCHAR2,
  X_TL_EXT_ATTR4 IN VARCHAR2,
  X_TL_EXT_ATTR5 IN VARCHAR2,
  X_TL_EXT_ATTR6 IN VARCHAR2,
  X_TL_EXT_ATTR7 IN VARCHAR2,
  X_TL_EXT_ATTR8 IN VARCHAR2,
  X_TL_EXT_ATTR9 IN VARCHAR2,
  X_TL_EXT_ATTR10 IN VARCHAR2,
  X_TL_EXT_ATTR11 IN VARCHAR2,
  X_TL_EXT_ATTR12 IN VARCHAR2,
  X_TL_EXT_ATTR13 IN VARCHAR2,
  X_TL_EXT_ATTR14 IN VARCHAR2,
  X_TL_EXT_ATTR15 IN VARCHAR2,
  X_TL_EXT_ATTR16 IN VARCHAR2,
  X_TL_EXT_ATTR17 IN VARCHAR2,
  X_TL_EXT_ATTR18 IN VARCHAR2,
  X_TL_EXT_ATTR19 IN VARCHAR2,
  X_TL_EXT_ATTR20 IN VARCHAR2,
  X_OWNER in VARCHAR2);

end XX_CDH_CUST_SITE_USES_EXT_PKG;
/

exit;