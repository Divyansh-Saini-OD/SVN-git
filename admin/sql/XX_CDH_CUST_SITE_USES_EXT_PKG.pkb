CREATE OR REPLACE package body XX_CDH_CUST_SITE_USES_EXT_PKG 
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_CDH_CUST_SITE_USES_EXT_PKG                                           |
-- | Description: This package body provides table handlers for XX_CDH_SITE_USES_EXT_B and    |
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
) is
  cursor C is select ROWID from XX_CDH_SITE_USES_EXT_B
    where EXTENSION_ID = X_EXTENSION_ID
    ;
begin
  insert into XX_CDH_SITE_USES_EXT_B (
    EXTENSION_ID,
    SITE_USE_ID,
    ATTR_GROUP_ID,
    C_EXT_ATTR1,
    C_EXT_ATTR2,
    C_EXT_ATTR3,
    C_EXT_ATTR4,
    C_EXT_ATTR5,
    C_EXT_ATTR6,
    C_EXT_ATTR7,
    C_EXT_ATTR8,
    C_EXT_ATTR9,
    C_EXT_ATTR10,
    C_EXT_ATTR11,
    C_EXT_ATTR12,
    C_EXT_ATTR13,
    C_EXT_ATTR14,
    C_EXT_ATTR15,
    C_EXT_ATTR16,
    C_EXT_ATTR17,
    C_EXT_ATTR18,
    C_EXT_ATTR19,
    C_EXT_ATTR20,
    N_EXT_ATTR1,
    N_EXT_ATTR2,
    N_EXT_ATTR3,
    N_EXT_ATTR4,
    N_EXT_ATTR5,
    N_EXT_ATTR6,
    N_EXT_ATTR7,
    N_EXT_ATTR8,
    N_EXT_ATTR9,
    N_EXT_ATTR10,
    N_EXT_ATTR11,
    N_EXT_ATTR12,
    N_EXT_ATTR13,
    N_EXT_ATTR14,
    N_EXT_ATTR15,
    N_EXT_ATTR16,
    N_EXT_ATTR17,
    N_EXT_ATTR18,
    N_EXT_ATTR19,
    N_EXT_ATTR20,
    D_EXT_ATTR1,
    D_EXT_ATTR2,
    D_EXT_ATTR3,
    D_EXT_ATTR4,
    D_EXT_ATTR5,
    D_EXT_ATTR6,
    D_EXT_ATTR7,
    D_EXT_ATTR8,
    D_EXT_ATTR9,
    D_EXT_ATTR10,
    CREATION_DATE,
    CREATED_BY,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_LOGIN
  ) values (
    X_EXTENSION_ID,
    X_SITE_USE_ID,
    X_ATTR_GROUP_ID,
    X_C_EXT_ATTR1,
    X_C_EXT_ATTR2,
    X_C_EXT_ATTR3,
    X_C_EXT_ATTR4,
    X_C_EXT_ATTR5,
    X_C_EXT_ATTR6,
    X_C_EXT_ATTR7,
    X_C_EXT_ATTR8,
    X_C_EXT_ATTR9,
    X_C_EXT_ATTR10,
    X_C_EXT_ATTR11,
    X_C_EXT_ATTR12,
    X_C_EXT_ATTR13,
    X_C_EXT_ATTR14,
    X_C_EXT_ATTR15,
    X_C_EXT_ATTR16,
    X_C_EXT_ATTR17,
    X_C_EXT_ATTR18,
    X_C_EXT_ATTR19,
    X_C_EXT_ATTR20,
    X_N_EXT_ATTR1,
    X_N_EXT_ATTR2,
    X_N_EXT_ATTR3,
    X_N_EXT_ATTR4,
    X_N_EXT_ATTR5,
    X_N_EXT_ATTR6,
    X_N_EXT_ATTR7,
    X_N_EXT_ATTR8,
    X_N_EXT_ATTR9,
    X_N_EXT_ATTR10,
    X_N_EXT_ATTR11,
    X_N_EXT_ATTR12,
    X_N_EXT_ATTR13,
    X_N_EXT_ATTR14,
    X_N_EXT_ATTR15,
    X_N_EXT_ATTR16,
    X_N_EXT_ATTR17,
    X_N_EXT_ATTR18,
    X_N_EXT_ATTR19,
    X_N_EXT_ATTR20,
    X_D_EXT_ATTR1,
    X_D_EXT_ATTR2,
    X_D_EXT_ATTR3,
    X_D_EXT_ATTR4,
    X_D_EXT_ATTR5,
    X_D_EXT_ATTR6,
    X_D_EXT_ATTR7,
    X_D_EXT_ATTR8,
    X_D_EXT_ATTR9,
    X_D_EXT_ATTR10,
    X_CREATION_DATE,
    X_CREATED_BY,
    X_LAST_UPDATE_DATE,
    X_LAST_UPDATED_BY,
    X_LAST_UPDATE_LOGIN
  );

  insert into XX_CDH_SITE_USES_EXT_TL (
    TL_EXT_ATTR8,
    TL_EXT_ATTR9,
    TL_EXT_ATTR10,
    TL_EXT_ATTR11,
    TL_EXT_ATTR12,
    TL_EXT_ATTR13,
    TL_EXT_ATTR14,
    TL_EXT_ATTR15,
    TL_EXT_ATTR16,
    TL_EXT_ATTR17,
    TL_EXT_ATTR18,
    TL_EXT_ATTR19,
    TL_EXT_ATTR20,
    EXTENSION_ID,
    SITE_USE_ID,
    ATTR_GROUP_ID,
    CREATED_BY,
    CREATION_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_DATE,
    LAST_UPDATE_LOGIN,
    TL_EXT_ATTR1,
    TL_EXT_ATTR2,
    TL_EXT_ATTR3,
    TL_EXT_ATTR4,
    TL_EXT_ATTR5,
    TL_EXT_ATTR6,
    TL_EXT_ATTR7,
    LANGUAGE,
    SOURCE_LANG
  ) select
    X_TL_EXT_ATTR8,
    X_TL_EXT_ATTR9,
    X_TL_EXT_ATTR10,
    X_TL_EXT_ATTR11,
    X_TL_EXT_ATTR12,
    X_TL_EXT_ATTR13,
    X_TL_EXT_ATTR14,
    X_TL_EXT_ATTR15,
    X_TL_EXT_ATTR16,
    X_TL_EXT_ATTR17,
    X_TL_EXT_ATTR18,
    X_TL_EXT_ATTR19,
    X_TL_EXT_ATTR20,
    X_EXTENSION_ID,
    X_SITE_USE_ID,
    X_ATTR_GROUP_ID,
    X_CREATED_BY,
    X_CREATION_DATE,
    X_LAST_UPDATED_BY,
    X_LAST_UPDATE_DATE,
    X_LAST_UPDATE_LOGIN,
    X_TL_EXT_ATTR1,
    X_TL_EXT_ATTR2,
    X_TL_EXT_ATTR3,
    X_TL_EXT_ATTR4,
    X_TL_EXT_ATTR5,
    X_TL_EXT_ATTR6,
    X_TL_EXT_ATTR7,
    L.LANGUAGE_CODE,
    userenv('LANG')
  from FND_LANGUAGES L
  where L.INSTALLED_FLAG in ('I', 'B')
  and not exists
    (select NULL
    from XX_CDH_SITE_USES_EXT_TL T
    where T.EXTENSION_ID = X_EXTENSION_ID
    and T.LANGUAGE = L.LANGUAGE_CODE);

  open c;
  fetch c into X_ROWID;
  if (c%notfound) then
    close c;
    raise no_data_found;
  end if;
  close c;

end INSERT_ROW;

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
) is
  cursor c is select
      SITE_USE_ID,
      ATTR_GROUP_ID,
      C_EXT_ATTR1,
      C_EXT_ATTR2,
      C_EXT_ATTR3,
      C_EXT_ATTR4,
      C_EXT_ATTR5,
      C_EXT_ATTR6,
      C_EXT_ATTR7,
      C_EXT_ATTR8,
      C_EXT_ATTR9,
      C_EXT_ATTR10,
      C_EXT_ATTR11,
      C_EXT_ATTR12,
      C_EXT_ATTR13,
      C_EXT_ATTR14,
      C_EXT_ATTR15,
      C_EXT_ATTR16,
      C_EXT_ATTR17,
      C_EXT_ATTR18,
      C_EXT_ATTR19,
      C_EXT_ATTR20,
      N_EXT_ATTR1,
      N_EXT_ATTR2,
      N_EXT_ATTR3,
      N_EXT_ATTR4,
      N_EXT_ATTR5,
      N_EXT_ATTR6,
      N_EXT_ATTR7,
      N_EXT_ATTR8,
      N_EXT_ATTR9,
      N_EXT_ATTR10,
      N_EXT_ATTR11,
      N_EXT_ATTR12,
      N_EXT_ATTR13,
      N_EXT_ATTR14,
      N_EXT_ATTR15,
      N_EXT_ATTR16,
      N_EXT_ATTR17,
      N_EXT_ATTR18,
      N_EXT_ATTR19,
      N_EXT_ATTR20,
      D_EXT_ATTR1,
      D_EXT_ATTR2,
      D_EXT_ATTR3,
      D_EXT_ATTR4,
      D_EXT_ATTR5,
      D_EXT_ATTR6,
      D_EXT_ATTR7,
      D_EXT_ATTR8,
      D_EXT_ATTR9,
      D_EXT_ATTR10
    from XX_CDH_SITE_USES_EXT_B
    where EXTENSION_ID = X_EXTENSION_ID
    for update of EXTENSION_ID nowait;
  recinfo c%rowtype;

  cursor c1 is select
      TL_EXT_ATTR1,
      TL_EXT_ATTR2,
      TL_EXT_ATTR3,
      TL_EXT_ATTR4,
      TL_EXT_ATTR5,
      TL_EXT_ATTR6,
      TL_EXT_ATTR7,
      TL_EXT_ATTR8,
      TL_EXT_ATTR9,
      TL_EXT_ATTR10,
      TL_EXT_ATTR11,
      TL_EXT_ATTR12,
      TL_EXT_ATTR13,
      TL_EXT_ATTR14,
      TL_EXT_ATTR15,
      TL_EXT_ATTR16,
      TL_EXT_ATTR17,
      TL_EXT_ATTR18,
      TL_EXT_ATTR19,
      TL_EXT_ATTR20,
      decode(LANGUAGE, userenv('LANG'), 'Y', 'N') BASELANG
    from XX_CDH_SITE_USES_EXT_TL
    where EXTENSION_ID = X_EXTENSION_ID
    and userenv('LANG') in (LANGUAGE, SOURCE_LANG)
    for update of EXTENSION_ID nowait;
begin
  open c;
  fetch c into recinfo;
  if (c%notfound) then
    close c;
    fnd_message.set_name('FND', 'FORM_RECORD_DELETED');
    app_exception.raise_exception;
  end if;
  close c;
  if (    (recinfo.SITE_USE_ID = X_SITE_USE_ID)
      AND (recinfo.ATTR_GROUP_ID = X_ATTR_GROUP_ID)
      AND ((recinfo.C_EXT_ATTR1 = X_C_EXT_ATTR1)
           OR ((recinfo.C_EXT_ATTR1 is null) AND (X_C_EXT_ATTR1 is null)))
      AND ((recinfo.C_EXT_ATTR2 = X_C_EXT_ATTR2)
           OR ((recinfo.C_EXT_ATTR2 is null) AND (X_C_EXT_ATTR2 is null)))
      AND ((recinfo.C_EXT_ATTR3 = X_C_EXT_ATTR3)
           OR ((recinfo.C_EXT_ATTR3 is null) AND (X_C_EXT_ATTR3 is null)))
      AND ((recinfo.C_EXT_ATTR4 = X_C_EXT_ATTR4)
           OR ((recinfo.C_EXT_ATTR4 is null) AND (X_C_EXT_ATTR4 is null)))
      AND ((recinfo.C_EXT_ATTR5 = X_C_EXT_ATTR5)
           OR ((recinfo.C_EXT_ATTR5 is null) AND (X_C_EXT_ATTR5 is null)))
      AND ((recinfo.C_EXT_ATTR6 = X_C_EXT_ATTR6)
           OR ((recinfo.C_EXT_ATTR6 is null) AND (X_C_EXT_ATTR6 is null)))
      AND ((recinfo.C_EXT_ATTR7 = X_C_EXT_ATTR7)
           OR ((recinfo.C_EXT_ATTR7 is null) AND (X_C_EXT_ATTR7 is null)))
      AND ((recinfo.C_EXT_ATTR8 = X_C_EXT_ATTR8)
           OR ((recinfo.C_EXT_ATTR8 is null) AND (X_C_EXT_ATTR8 is null)))
      AND ((recinfo.C_EXT_ATTR9 = X_C_EXT_ATTR9)
           OR ((recinfo.C_EXT_ATTR9 is null) AND (X_C_EXT_ATTR9 is null)))
      AND ((recinfo.C_EXT_ATTR10 = X_C_EXT_ATTR10)
           OR ((recinfo.C_EXT_ATTR10 is null) AND (X_C_EXT_ATTR10 is null)))
      AND ((recinfo.C_EXT_ATTR11 = X_C_EXT_ATTR11)
           OR ((recinfo.C_EXT_ATTR11 is null) AND (X_C_EXT_ATTR11 is null)))
      AND ((recinfo.C_EXT_ATTR12 = X_C_EXT_ATTR12)
           OR ((recinfo.C_EXT_ATTR12 is null) AND (X_C_EXT_ATTR12 is null)))
      AND ((recinfo.C_EXT_ATTR13 = X_C_EXT_ATTR13)
           OR ((recinfo.C_EXT_ATTR13 is null) AND (X_C_EXT_ATTR13 is null)))
      AND ((recinfo.C_EXT_ATTR14 = X_C_EXT_ATTR14)
           OR ((recinfo.C_EXT_ATTR14 is null) AND (X_C_EXT_ATTR14 is null)))
      AND ((recinfo.C_EXT_ATTR15 = X_C_EXT_ATTR15)
           OR ((recinfo.C_EXT_ATTR15 is null) AND (X_C_EXT_ATTR15 is null)))
      AND ((recinfo.C_EXT_ATTR16 = X_C_EXT_ATTR16)
           OR ((recinfo.C_EXT_ATTR16 is null) AND (X_C_EXT_ATTR16 is null)))
      AND ((recinfo.C_EXT_ATTR17 = X_C_EXT_ATTR17)
           OR ((recinfo.C_EXT_ATTR17 is null) AND (X_C_EXT_ATTR17 is null)))
      AND ((recinfo.C_EXT_ATTR18 = X_C_EXT_ATTR18)
           OR ((recinfo.C_EXT_ATTR18 is null) AND (X_C_EXT_ATTR18 is null)))
      AND ((recinfo.C_EXT_ATTR19 = X_C_EXT_ATTR19)
           OR ((recinfo.C_EXT_ATTR19 is null) AND (X_C_EXT_ATTR19 is null)))
      AND ((recinfo.C_EXT_ATTR20 = X_C_EXT_ATTR20)
           OR ((recinfo.C_EXT_ATTR20 is null) AND (X_C_EXT_ATTR20 is null)))
      AND ((recinfo.N_EXT_ATTR1 = X_N_EXT_ATTR1)
           OR ((recinfo.N_EXT_ATTR1 is null) AND (X_N_EXT_ATTR1 is null)))
      AND ((recinfo.N_EXT_ATTR2 = X_N_EXT_ATTR2)
           OR ((recinfo.N_EXT_ATTR2 is null) AND (X_N_EXT_ATTR2 is null)))
      AND ((recinfo.N_EXT_ATTR3 = X_N_EXT_ATTR3)
           OR ((recinfo.N_EXT_ATTR3 is null) AND (X_N_EXT_ATTR3 is null)))
      AND ((recinfo.N_EXT_ATTR4 = X_N_EXT_ATTR4)
           OR ((recinfo.N_EXT_ATTR4 is null) AND (X_N_EXT_ATTR4 is null)))
      AND ((recinfo.N_EXT_ATTR5 = X_N_EXT_ATTR5)
           OR ((recinfo.N_EXT_ATTR5 is null) AND (X_N_EXT_ATTR5 is null)))
      AND ((recinfo.N_EXT_ATTR6 = X_N_EXT_ATTR6)
           OR ((recinfo.N_EXT_ATTR6 is null) AND (X_N_EXT_ATTR6 is null)))
      AND ((recinfo.N_EXT_ATTR7 = X_N_EXT_ATTR7)
           OR ((recinfo.N_EXT_ATTR7 is null) AND (X_N_EXT_ATTR7 is null)))
      AND ((recinfo.N_EXT_ATTR8 = X_N_EXT_ATTR8)
           OR ((recinfo.N_EXT_ATTR8 is null) AND (X_N_EXT_ATTR8 is null)))
      AND ((recinfo.N_EXT_ATTR9 = X_N_EXT_ATTR9)
           OR ((recinfo.N_EXT_ATTR9 is null) AND (X_N_EXT_ATTR9 is null)))
      AND ((recinfo.N_EXT_ATTR10 = X_N_EXT_ATTR10)
           OR ((recinfo.N_EXT_ATTR10 is null) AND (X_N_EXT_ATTR10 is null)))
      AND ((recinfo.N_EXT_ATTR11 = X_N_EXT_ATTR11)
           OR ((recinfo.N_EXT_ATTR11 is null) AND (X_N_EXT_ATTR11 is null)))
      AND ((recinfo.N_EXT_ATTR12 = X_N_EXT_ATTR12)
           OR ((recinfo.N_EXT_ATTR12 is null) AND (X_N_EXT_ATTR12 is null)))
      AND ((recinfo.N_EXT_ATTR13 = X_N_EXT_ATTR13)
           OR ((recinfo.N_EXT_ATTR13 is null) AND (X_N_EXT_ATTR13 is null)))
      AND ((recinfo.N_EXT_ATTR14 = X_N_EXT_ATTR14)
           OR ((recinfo.N_EXT_ATTR14 is null) AND (X_N_EXT_ATTR14 is null)))
      AND ((recinfo.N_EXT_ATTR15 = X_N_EXT_ATTR15)
           OR ((recinfo.N_EXT_ATTR15 is null) AND (X_N_EXT_ATTR15 is null)))
      AND ((recinfo.N_EXT_ATTR16 = X_N_EXT_ATTR16)
           OR ((recinfo.N_EXT_ATTR16 is null) AND (X_N_EXT_ATTR16 is null)))
      AND ((recinfo.N_EXT_ATTR17 = X_N_EXT_ATTR17)
           OR ((recinfo.N_EXT_ATTR17 is null) AND (X_N_EXT_ATTR17 is null)))
      AND ((recinfo.N_EXT_ATTR18 = X_N_EXT_ATTR18)
           OR ((recinfo.N_EXT_ATTR18 is null) AND (X_N_EXT_ATTR18 is null)))
      AND ((recinfo.N_EXT_ATTR19 = X_N_EXT_ATTR19)
           OR ((recinfo.N_EXT_ATTR19 is null) AND (X_N_EXT_ATTR19 is null)))
      AND ((recinfo.N_EXT_ATTR20 = X_N_EXT_ATTR20)
           OR ((recinfo.N_EXT_ATTR20 is null) AND (X_N_EXT_ATTR20 is null)))
      AND ((recinfo.D_EXT_ATTR1 = X_D_EXT_ATTR1)
           OR ((recinfo.D_EXT_ATTR1 is null) AND (X_D_EXT_ATTR1 is null)))
      AND ((recinfo.D_EXT_ATTR2 = X_D_EXT_ATTR2)
           OR ((recinfo.D_EXT_ATTR2 is null) AND (X_D_EXT_ATTR2 is null)))
      AND ((recinfo.D_EXT_ATTR3 = X_D_EXT_ATTR3)
           OR ((recinfo.D_EXT_ATTR3 is null) AND (X_D_EXT_ATTR3 is null)))
      AND ((recinfo.D_EXT_ATTR4 = X_D_EXT_ATTR4)
           OR ((recinfo.D_EXT_ATTR4 is null) AND (X_D_EXT_ATTR4 is null)))
      AND ((recinfo.D_EXT_ATTR5 = X_D_EXT_ATTR5)
           OR ((recinfo.D_EXT_ATTR5 is null) AND (X_D_EXT_ATTR5 is null)))
      AND ((recinfo.D_EXT_ATTR6 = X_D_EXT_ATTR6)
           OR ((recinfo.D_EXT_ATTR6 is null) AND (X_D_EXT_ATTR6 is null)))
      AND ((recinfo.D_EXT_ATTR7 = X_D_EXT_ATTR7)
           OR ((recinfo.D_EXT_ATTR7 is null) AND (X_D_EXT_ATTR7 is null)))
      AND ((recinfo.D_EXT_ATTR8 = X_D_EXT_ATTR8)
           OR ((recinfo.D_EXT_ATTR8 is null) AND (X_D_EXT_ATTR8 is null)))
      AND ((recinfo.D_EXT_ATTR9 = X_D_EXT_ATTR9)
           OR ((recinfo.D_EXT_ATTR9 is null) AND (X_D_EXT_ATTR9 is null)))
      AND ((recinfo.D_EXT_ATTR10 = X_D_EXT_ATTR10)
           OR ((recinfo.D_EXT_ATTR10 is null) AND (X_D_EXT_ATTR10 is null)))
  ) then
    null;
  else
    fnd_message.set_name('FND', 'FORM_RECORD_CHANGED');
    app_exception.raise_exception;
  end if;

  for tlinfo in c1 loop
    if (tlinfo.BASELANG = 'Y') then
      if (    ((tlinfo.TL_EXT_ATTR1 = X_TL_EXT_ATTR1)
               OR ((tlinfo.TL_EXT_ATTR1 is null) AND (X_TL_EXT_ATTR1 is null)))
          AND ((tlinfo.TL_EXT_ATTR2 = X_TL_EXT_ATTR2)
               OR ((tlinfo.TL_EXT_ATTR2 is null) AND (X_TL_EXT_ATTR2 is null)))
          AND ((tlinfo.TL_EXT_ATTR3 = X_TL_EXT_ATTR3)
               OR ((tlinfo.TL_EXT_ATTR3 is null) AND (X_TL_EXT_ATTR3 is null)))
          AND ((tlinfo.TL_EXT_ATTR4 = X_TL_EXT_ATTR4)
               OR ((tlinfo.TL_EXT_ATTR4 is null) AND (X_TL_EXT_ATTR4 is null)))
          AND ((tlinfo.TL_EXT_ATTR5 = X_TL_EXT_ATTR5)
               OR ((tlinfo.TL_EXT_ATTR5 is null) AND (X_TL_EXT_ATTR5 is null)))
          AND ((tlinfo.TL_EXT_ATTR6 = X_TL_EXT_ATTR6)
               OR ((tlinfo.TL_EXT_ATTR6 is null) AND (X_TL_EXT_ATTR6 is null)))
          AND ((tlinfo.TL_EXT_ATTR7 = X_TL_EXT_ATTR7)
               OR ((tlinfo.TL_EXT_ATTR7 is null) AND (X_TL_EXT_ATTR7 is null)))
          AND ((tlinfo.TL_EXT_ATTR8 = X_TL_EXT_ATTR8)
               OR ((tlinfo.TL_EXT_ATTR8 is null) AND (X_TL_EXT_ATTR8 is null)))
          AND ((tlinfo.TL_EXT_ATTR9 = X_TL_EXT_ATTR9)
               OR ((tlinfo.TL_EXT_ATTR9 is null) AND (X_TL_EXT_ATTR9 is null)))
          AND ((tlinfo.TL_EXT_ATTR10 = X_TL_EXT_ATTR10)
               OR ((tlinfo.TL_EXT_ATTR10 is null) AND (X_TL_EXT_ATTR10 is null)))
          AND ((tlinfo.TL_EXT_ATTR11 = X_TL_EXT_ATTR11)
               OR ((tlinfo.TL_EXT_ATTR11 is null) AND (X_TL_EXT_ATTR11 is null)))
          AND ((tlinfo.TL_EXT_ATTR12 = X_TL_EXT_ATTR12)
               OR ((tlinfo.TL_EXT_ATTR12 is null) AND (X_TL_EXT_ATTR12 is null)))
          AND ((tlinfo.TL_EXT_ATTR13 = X_TL_EXT_ATTR13)
               OR ((tlinfo.TL_EXT_ATTR13 is null) AND (X_TL_EXT_ATTR13 is null)))
          AND ((tlinfo.TL_EXT_ATTR14 = X_TL_EXT_ATTR14)
               OR ((tlinfo.TL_EXT_ATTR14 is null) AND (X_TL_EXT_ATTR14 is null)))
          AND ((tlinfo.TL_EXT_ATTR15 = X_TL_EXT_ATTR15)
               OR ((tlinfo.TL_EXT_ATTR15 is null) AND (X_TL_EXT_ATTR15 is null)))
          AND ((tlinfo.TL_EXT_ATTR16 = X_TL_EXT_ATTR16)
               OR ((tlinfo.TL_EXT_ATTR16 is null) AND (X_TL_EXT_ATTR16 is null)))
          AND ((tlinfo.TL_EXT_ATTR17 = X_TL_EXT_ATTR17)
               OR ((tlinfo.TL_EXT_ATTR17 is null) AND (X_TL_EXT_ATTR17 is null)))
          AND ((tlinfo.TL_EXT_ATTR18 = X_TL_EXT_ATTR18)
               OR ((tlinfo.TL_EXT_ATTR18 is null) AND (X_TL_EXT_ATTR18 is null)))
          AND ((tlinfo.TL_EXT_ATTR19 = X_TL_EXT_ATTR19)
               OR ((tlinfo.TL_EXT_ATTR19 is null) AND (X_TL_EXT_ATTR19 is null)))
          AND ((tlinfo.TL_EXT_ATTR20 = X_TL_EXT_ATTR20)
               OR ((tlinfo.TL_EXT_ATTR20 is null) AND (X_TL_EXT_ATTR20 is null)))
      ) then
        null;
      else
        fnd_message.set_name('FND', 'FORM_RECORD_CHANGED');
        app_exception.raise_exception;
      end if;
    end if;
  end loop;
  return;
end LOCK_ROW;

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
) is
begin
  update XX_CDH_SITE_USES_EXT_B set
    SITE_USE_ID = X_SITE_USE_ID,
    ATTR_GROUP_ID = X_ATTR_GROUP_ID,
    C_EXT_ATTR1 = X_C_EXT_ATTR1,
    C_EXT_ATTR2 = X_C_EXT_ATTR2,
    C_EXT_ATTR3 = X_C_EXT_ATTR3,
    C_EXT_ATTR4 = X_C_EXT_ATTR4,
    C_EXT_ATTR5 = X_C_EXT_ATTR5,
    C_EXT_ATTR6 = X_C_EXT_ATTR6,
    C_EXT_ATTR7 = X_C_EXT_ATTR7,
    C_EXT_ATTR8 = X_C_EXT_ATTR8,
    C_EXT_ATTR9 = X_C_EXT_ATTR9,
    C_EXT_ATTR10 = X_C_EXT_ATTR10,
    C_EXT_ATTR11 = X_C_EXT_ATTR11,
    C_EXT_ATTR12 = X_C_EXT_ATTR12,
    C_EXT_ATTR13 = X_C_EXT_ATTR13,
    C_EXT_ATTR14 = X_C_EXT_ATTR14,
    C_EXT_ATTR15 = X_C_EXT_ATTR15,
    C_EXT_ATTR16 = X_C_EXT_ATTR16,
    C_EXT_ATTR17 = X_C_EXT_ATTR17,
    C_EXT_ATTR18 = X_C_EXT_ATTR18,
    C_EXT_ATTR19 = X_C_EXT_ATTR19,
    C_EXT_ATTR20 = X_C_EXT_ATTR20,
    N_EXT_ATTR1 = X_N_EXT_ATTR1,
    N_EXT_ATTR2 = X_N_EXT_ATTR2,
    N_EXT_ATTR3 = X_N_EXT_ATTR3,
    N_EXT_ATTR4 = X_N_EXT_ATTR4,
    N_EXT_ATTR5 = X_N_EXT_ATTR5,
    N_EXT_ATTR6 = X_N_EXT_ATTR6,
    N_EXT_ATTR7 = X_N_EXT_ATTR7,
    N_EXT_ATTR8 = X_N_EXT_ATTR8,
    N_EXT_ATTR9 = X_N_EXT_ATTR9,
    N_EXT_ATTR10 = X_N_EXT_ATTR10,
    N_EXT_ATTR11 = X_N_EXT_ATTR11,
    N_EXT_ATTR12 = X_N_EXT_ATTR12,
    N_EXT_ATTR13 = X_N_EXT_ATTR13,
    N_EXT_ATTR14 = X_N_EXT_ATTR14,
    N_EXT_ATTR15 = X_N_EXT_ATTR15,
    N_EXT_ATTR16 = X_N_EXT_ATTR16,
    N_EXT_ATTR17 = X_N_EXT_ATTR17,
    N_EXT_ATTR18 = X_N_EXT_ATTR18,
    N_EXT_ATTR19 = X_N_EXT_ATTR19,
    N_EXT_ATTR20 = X_N_EXT_ATTR20,
    D_EXT_ATTR1 = X_D_EXT_ATTR1,
    D_EXT_ATTR2 = X_D_EXT_ATTR2,
    D_EXT_ATTR3 = X_D_EXT_ATTR3,
    D_EXT_ATTR4 = X_D_EXT_ATTR4,
    D_EXT_ATTR5 = X_D_EXT_ATTR5,
    D_EXT_ATTR6 = X_D_EXT_ATTR6,
    D_EXT_ATTR7 = X_D_EXT_ATTR7,
    D_EXT_ATTR8 = X_D_EXT_ATTR8,
    D_EXT_ATTR9 = X_D_EXT_ATTR9,
    D_EXT_ATTR10 = X_D_EXT_ATTR10,
    LAST_UPDATE_DATE = X_LAST_UPDATE_DATE,
    LAST_UPDATED_BY = X_LAST_UPDATED_BY,
    LAST_UPDATE_LOGIN = X_LAST_UPDATE_LOGIN
  where EXTENSION_ID = X_EXTENSION_ID;

  if (sql%notfound) then
    raise no_data_found;
  end if;

  update XX_CDH_SITE_USES_EXT_TL set
    TL_EXT_ATTR1 = X_TL_EXT_ATTR1,
    TL_EXT_ATTR2 = X_TL_EXT_ATTR2,
    TL_EXT_ATTR3 = X_TL_EXT_ATTR3,
    TL_EXT_ATTR4 = X_TL_EXT_ATTR4,
    TL_EXT_ATTR5 = X_TL_EXT_ATTR5,
    TL_EXT_ATTR6 = X_TL_EXT_ATTR6,
    TL_EXT_ATTR7 = X_TL_EXT_ATTR7,
    TL_EXT_ATTR8 = X_TL_EXT_ATTR8,
    TL_EXT_ATTR9 = X_TL_EXT_ATTR9,
    TL_EXT_ATTR10 = X_TL_EXT_ATTR10,
    TL_EXT_ATTR11 = X_TL_EXT_ATTR11,
    TL_EXT_ATTR12 = X_TL_EXT_ATTR12,
    TL_EXT_ATTR13 = X_TL_EXT_ATTR13,
    TL_EXT_ATTR14 = X_TL_EXT_ATTR14,
    TL_EXT_ATTR15 = X_TL_EXT_ATTR15,
    TL_EXT_ATTR16 = X_TL_EXT_ATTR16,
    TL_EXT_ATTR17 = X_TL_EXT_ATTR17,
    TL_EXT_ATTR18 = X_TL_EXT_ATTR18,
    TL_EXT_ATTR19 = X_TL_EXT_ATTR19,
    TL_EXT_ATTR20 = X_TL_EXT_ATTR20,
    LAST_UPDATE_DATE = X_LAST_UPDATE_DATE,
    LAST_UPDATED_BY = X_LAST_UPDATED_BY,
    LAST_UPDATE_LOGIN = X_LAST_UPDATE_LOGIN,
    SOURCE_LANG = userenv('LANG')
  where EXTENSION_ID = X_EXTENSION_ID
  and userenv('LANG') in (LANGUAGE, SOURCE_LANG);

  if (sql%notfound) then
    raise no_data_found;
  end if;
end UPDATE_ROW;

-- +==============================================================================+
-- | Name             : DELETE_ROW                                                |
-- | Description      : This procedure shall delete data  in XX_CDH_SITE_USES_EXT_B   |
-- |                    XX_CDH_SITE_USES_EXT_TL table for the given extension id.     |
-- |                                                                              |
-- +==============================================================================+

procedure DELETE_ROW (
  X_EXTENSION_ID IN NUMBER) is
begin
  delete from XX_CDH_SITE_USES_EXT_TL
  where EXTENSION_ID = X_EXTENSION_ID;

  if (sql%notfound) then
    raise no_data_found;
  end if;

  delete from XX_CDH_SITE_USES_EXT_B
  where EXTENSION_ID = X_EXTENSION_ID;

  if (sql%notfound) then
    raise no_data_found;
  end if;
end DELETE_ROW;

-- +==============================================================================+
-- | Name             : ADD_LANGUAGE                                              |
-- | Description      : This procedure shall insert and update data  in           |
-- |                    XX_CDH_SITE_USES_EXT_TL table.                                |
-- |                                                                              |
-- +==============================================================================+

procedure ADD_LANGUAGE
is
begin
  delete from XX_CDH_SITE_USES_EXT_TL T
  where not exists
    (select NULL
    from XX_CDH_SITE_USES_EXT_B B
    where B.EXTENSION_ID = T.EXTENSION_ID
    );

  update XX_CDH_SITE_USES_EXT_TL T set (
      TL_EXT_ATTR1,
      TL_EXT_ATTR2,
      TL_EXT_ATTR3,
      TL_EXT_ATTR4,
      TL_EXT_ATTR5,
      TL_EXT_ATTR6,
      TL_EXT_ATTR7,
      TL_EXT_ATTR8,
      TL_EXT_ATTR9,
      TL_EXT_ATTR10,
      TL_EXT_ATTR11,
      TL_EXT_ATTR12,
      TL_EXT_ATTR13,
      TL_EXT_ATTR14,
      TL_EXT_ATTR15,
      TL_EXT_ATTR16,
      TL_EXT_ATTR17,
      TL_EXT_ATTR18,
      TL_EXT_ATTR19,
      TL_EXT_ATTR20
    ) = (select
      B.TL_EXT_ATTR1,
      B.TL_EXT_ATTR2,
      B.TL_EXT_ATTR3,
      B.TL_EXT_ATTR4,
      B.TL_EXT_ATTR5,
      B.TL_EXT_ATTR6,
      B.TL_EXT_ATTR7,
      B.TL_EXT_ATTR8,
      B.TL_EXT_ATTR9,
      B.TL_EXT_ATTR10,
      B.TL_EXT_ATTR11,
      B.TL_EXT_ATTR12,
      B.TL_EXT_ATTR13,
      B.TL_EXT_ATTR14,
      B.TL_EXT_ATTR15,
      B.TL_EXT_ATTR16,
      B.TL_EXT_ATTR17,
      B.TL_EXT_ATTR18,
      B.TL_EXT_ATTR19,
      B.TL_EXT_ATTR20
    from XX_CDH_SITE_USES_EXT_TL B
    where B.EXTENSION_ID = T.EXTENSION_ID
    and B.LANGUAGE = T.SOURCE_LANG)
  where (
      T.EXTENSION_ID,
      T.LANGUAGE
  ) in (select
      SUBT.EXTENSION_ID,
      SUBT.LANGUAGE
    from XX_CDH_SITE_USES_EXT_TL SUBB, XX_CDH_SITE_USES_EXT_TL SUBT
    where SUBB.EXTENSION_ID = SUBT.EXTENSION_ID
    and SUBB.LANGUAGE = SUBT.SOURCE_LANG
    and (SUBB.TL_EXT_ATTR1 <> SUBT.TL_EXT_ATTR1
      or (SUBB.TL_EXT_ATTR1 is null and SUBT.TL_EXT_ATTR1 is not null)
      or (SUBB.TL_EXT_ATTR1 is not null and SUBT.TL_EXT_ATTR1 is null)
      or SUBB.TL_EXT_ATTR2 <> SUBT.TL_EXT_ATTR2
      or (SUBB.TL_EXT_ATTR2 is null and SUBT.TL_EXT_ATTR2 is not null)
      or (SUBB.TL_EXT_ATTR2 is not null and SUBT.TL_EXT_ATTR2 is null)
      or SUBB.TL_EXT_ATTR3 <> SUBT.TL_EXT_ATTR3
      or (SUBB.TL_EXT_ATTR3 is null and SUBT.TL_EXT_ATTR3 is not null)
      or (SUBB.TL_EXT_ATTR3 is not null and SUBT.TL_EXT_ATTR3 is null)
      or SUBB.TL_EXT_ATTR4 <> SUBT.TL_EXT_ATTR4
      or (SUBB.TL_EXT_ATTR4 is null and SUBT.TL_EXT_ATTR4 is not null)
      or (SUBB.TL_EXT_ATTR4 is not null and SUBT.TL_EXT_ATTR4 is null)
      or SUBB.TL_EXT_ATTR5 <> SUBT.TL_EXT_ATTR5
      or (SUBB.TL_EXT_ATTR5 is null and SUBT.TL_EXT_ATTR5 is not null)
      or (SUBB.TL_EXT_ATTR5 is not null and SUBT.TL_EXT_ATTR5 is null)
      or SUBB.TL_EXT_ATTR6 <> SUBT.TL_EXT_ATTR6
      or (SUBB.TL_EXT_ATTR6 is null and SUBT.TL_EXT_ATTR6 is not null)
      or (SUBB.TL_EXT_ATTR6 is not null and SUBT.TL_EXT_ATTR6 is null)
      or SUBB.TL_EXT_ATTR7 <> SUBT.TL_EXT_ATTR7
      or (SUBB.TL_EXT_ATTR7 is null and SUBT.TL_EXT_ATTR7 is not null)
      or (SUBB.TL_EXT_ATTR7 is not null and SUBT.TL_EXT_ATTR7 is null)
      or SUBB.TL_EXT_ATTR8 <> SUBT.TL_EXT_ATTR8
      or (SUBB.TL_EXT_ATTR8 is null and SUBT.TL_EXT_ATTR8 is not null)
      or (SUBB.TL_EXT_ATTR8 is not null and SUBT.TL_EXT_ATTR8 is null)
      or SUBB.TL_EXT_ATTR9 <> SUBT.TL_EXT_ATTR9
      or (SUBB.TL_EXT_ATTR9 is null and SUBT.TL_EXT_ATTR9 is not null)
      or (SUBB.TL_EXT_ATTR9 is not null and SUBT.TL_EXT_ATTR9 is null)
      or SUBB.TL_EXT_ATTR10 <> SUBT.TL_EXT_ATTR10
      or (SUBB.TL_EXT_ATTR10 is null and SUBT.TL_EXT_ATTR10 is not null)
      or (SUBB.TL_EXT_ATTR10 is not null and SUBT.TL_EXT_ATTR10 is null)
      or SUBB.TL_EXT_ATTR11 <> SUBT.TL_EXT_ATTR11
      or (SUBB.TL_EXT_ATTR11 is null and SUBT.TL_EXT_ATTR11 is not null)
      or (SUBB.TL_EXT_ATTR11 is not null and SUBT.TL_EXT_ATTR11 is null)
      or SUBB.TL_EXT_ATTR12 <> SUBT.TL_EXT_ATTR12
      or (SUBB.TL_EXT_ATTR12 is null and SUBT.TL_EXT_ATTR12 is not null)
      or (SUBB.TL_EXT_ATTR12 is not null and SUBT.TL_EXT_ATTR12 is null)
      or SUBB.TL_EXT_ATTR13 <> SUBT.TL_EXT_ATTR13
      or (SUBB.TL_EXT_ATTR13 is null and SUBT.TL_EXT_ATTR13 is not null)
      or (SUBB.TL_EXT_ATTR13 is not null and SUBT.TL_EXT_ATTR13 is null)
      or SUBB.TL_EXT_ATTR14 <> SUBT.TL_EXT_ATTR14
      or (SUBB.TL_EXT_ATTR14 is null and SUBT.TL_EXT_ATTR14 is not null)
      or (SUBB.TL_EXT_ATTR14 is not null and SUBT.TL_EXT_ATTR14 is null)
      or SUBB.TL_EXT_ATTR15 <> SUBT.TL_EXT_ATTR15
      or (SUBB.TL_EXT_ATTR15 is null and SUBT.TL_EXT_ATTR15 is not null)
      or (SUBB.TL_EXT_ATTR15 is not null and SUBT.TL_EXT_ATTR15 is null)
      or SUBB.TL_EXT_ATTR16 <> SUBT.TL_EXT_ATTR16
      or (SUBB.TL_EXT_ATTR16 is null and SUBT.TL_EXT_ATTR16 is not null)
      or (SUBB.TL_EXT_ATTR16 is not null and SUBT.TL_EXT_ATTR16 is null)
      or SUBB.TL_EXT_ATTR17 <> SUBT.TL_EXT_ATTR17
      or (SUBB.TL_EXT_ATTR17 is null and SUBT.TL_EXT_ATTR17 is not null)
      or (SUBB.TL_EXT_ATTR17 is not null and SUBT.TL_EXT_ATTR17 is null)
      or SUBB.TL_EXT_ATTR18 <> SUBT.TL_EXT_ATTR18
      or (SUBB.TL_EXT_ATTR18 is null and SUBT.TL_EXT_ATTR18 is not null)
      or (SUBB.TL_EXT_ATTR18 is not null and SUBT.TL_EXT_ATTR18 is null)
      or SUBB.TL_EXT_ATTR19 <> SUBT.TL_EXT_ATTR19
      or (SUBB.TL_EXT_ATTR19 is null and SUBT.TL_EXT_ATTR19 is not null)
      or (SUBB.TL_EXT_ATTR19 is not null and SUBT.TL_EXT_ATTR19 is null)
      or SUBB.TL_EXT_ATTR20 <> SUBT.TL_EXT_ATTR20
      or (SUBB.TL_EXT_ATTR20 is null and SUBT.TL_EXT_ATTR20 is not null)
      or (SUBB.TL_EXT_ATTR20 is not null and SUBT.TL_EXT_ATTR20 is null)
  ));

  insert into XX_CDH_SITE_USES_EXT_TL (
    TL_EXT_ATTR8,
    TL_EXT_ATTR9,
    TL_EXT_ATTR10,
    TL_EXT_ATTR11,
    TL_EXT_ATTR12,
    TL_EXT_ATTR13,
    TL_EXT_ATTR14,
    TL_EXT_ATTR15,
    TL_EXT_ATTR16,
    TL_EXT_ATTR17,
    TL_EXT_ATTR18,
    TL_EXT_ATTR19,
    TL_EXT_ATTR20,
    EXTENSION_ID,
    SITE_USE_ID,
    ATTR_GROUP_ID,
    CREATED_BY,
    CREATION_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_DATE,
    LAST_UPDATE_LOGIN,
    TL_EXT_ATTR1,
    TL_EXT_ATTR2,
    TL_EXT_ATTR3,
    TL_EXT_ATTR4,
    TL_EXT_ATTR5,
    TL_EXT_ATTR6,
    TL_EXT_ATTR7,
    LANGUAGE,
    SOURCE_LANG
  ) select /*+ ORDERED */
    B.TL_EXT_ATTR8,
    B.TL_EXT_ATTR9,
    B.TL_EXT_ATTR10,
    B.TL_EXT_ATTR11,
    B.TL_EXT_ATTR12,
    B.TL_EXT_ATTR13,
    B.TL_EXT_ATTR14,
    B.TL_EXT_ATTR15,
    B.TL_EXT_ATTR16,
    B.TL_EXT_ATTR17,
    B.TL_EXT_ATTR18,
    B.TL_EXT_ATTR19,
    B.TL_EXT_ATTR20,
    B.EXTENSION_ID,
    B.SITE_USE_ID,
    B.ATTR_GROUP_ID,
    B.CREATED_BY,
    B.CREATION_DATE,
    B.LAST_UPDATED_BY,
    B.LAST_UPDATE_DATE,
    B.LAST_UPDATE_LOGIN,
    B.TL_EXT_ATTR1,
    B.TL_EXT_ATTR2,
    B.TL_EXT_ATTR3,
    B.TL_EXT_ATTR4,
    B.TL_EXT_ATTR5,
    B.TL_EXT_ATTR6,
    B.TL_EXT_ATTR7,
    L.LANGUAGE_CODE,
    B.SOURCE_LANG
  from XX_CDH_SITE_USES_EXT_TL B, FND_LANGUAGES L
  where L.INSTALLED_FLAG in ('I', 'B')
  and B.LANGUAGE = userenv('LANG')
  and not exists
    (select NULL
    from XX_CDH_SITE_USES_EXT_TL T
    where T.EXTENSION_ID = B.EXTENSION_ID
    and T.LANGUAGE = L.LANGUAGE_CODE);
end ADD_LANGUAGE;


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
  X_OWNER in VARCHAR2)
IS
BEGIN
  null;
end LOAD_ROW;

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
  X_OWNER in VARCHAR2)
IS
BEGIN
  null;
end TRANSLATE_ROW;


end XX_CDH_CUST_SITE_USES_EXT_PKG;
/
show errors;

exit;