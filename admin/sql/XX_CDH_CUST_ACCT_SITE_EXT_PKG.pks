SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE package XX_CDH_CUST_ACCT_SITE_EXT_PKG AUTHID CURRENT_USER
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_CDH_CUST_ACCT_SITE_EXT_PKG                                           |
-- | Description: This package provides table handlers for XX_CDH_ACCT_SITE_EXT_B and     |
-- |              and XX_CDH_ACCT_SITE_EXT_TL tables.                                     |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version     Date            Author               Remarks                              |
-- |=======   ===========   ==================    ========================================|
-- |DRAFT 1A  09-MAY-2007   Sathya Prabha Rani      Initial draft version                 |
-- |======================================================================================|                         
-- | Subversion Info:                                                                     |
-- | $HeadURL$                                                                          |
-- | $Rev$                                                                              |
-- | $Date$                                                                             |
-- |                                                                                      |
-- +======================================================================================+
AS

-- +==================================================================================+
-- | Name             : INSERT_ROW                                                    |
-- | Description      : This procedure shall insert data into XX_CDH_ACCT_SITE_EXT_B  |
-- |                    and XX_CDH_ACCT_SITE_EXT_TL tables.                           |
-- |                                                                                  |
-- +==================================================================================+

procedure INSERT_ROW (
  X_ROWID             IN OUT NOCOPY VARCHAR2,
  X_EXTENSION_ID      IN NUMBER,
  X_CUST_ACCT_SITE_ID IN NUMBER,
  X_ATTR_GROUP_ID     IN NUMBER,
  X_C_EXT_ATTR1       IN VARCHAR2,
  X_C_EXT_ATTR2       IN VARCHAR2,
  X_C_EXT_ATTR3       IN VARCHAR2,
  X_C_EXT_ATTR4       IN VARCHAR2,
  X_C_EXT_ATTR5       IN VARCHAR2,
  X_C_EXT_ATTR6       IN VARCHAR2,
  X_C_EXT_ATTR7       IN VARCHAR2,
  X_C_EXT_ATTR8       IN VARCHAR2,
  X_C_EXT_ATTR9       IN VARCHAR2,
  X_C_EXT_ATTR10      IN VARCHAR2,
  X_C_EXT_ATTR11      IN VARCHAR2,
  X_C_EXT_ATTR12      IN VARCHAR2,
  X_C_EXT_ATTR13      IN VARCHAR2,
  X_C_EXT_ATTR14      IN VARCHAR2,
  X_C_EXT_ATTR15      IN VARCHAR2,
  X_C_EXT_ATTR16      IN VARCHAR2,
  X_C_EXT_ATTR17      IN VARCHAR2,
  X_C_EXT_ATTR18      IN VARCHAR2,
  X_C_EXT_ATTR19      IN VARCHAR2,
  X_C_EXT_ATTR20      IN VARCHAR2,
  X_N_EXT_ATTR1       IN NUMBER,
  X_N_EXT_ATTR2       IN NUMBER,
  X_N_EXT_ATTR3       IN NUMBER,
  X_N_EXT_ATTR4       IN NUMBER,
  X_N_EXT_ATTR5       IN NUMBER,
  X_N_EXT_ATTR6       IN NUMBER,
  X_N_EXT_ATTR7       IN NUMBER,
  X_N_EXT_ATTR8       IN NUMBER,
  X_N_EXT_ATTR9       IN NUMBER,
  X_N_EXT_ATTR10      IN NUMBER,
  X_N_EXT_ATTR11      IN NUMBER,
  X_N_EXT_ATTR12      IN NUMBER,
  X_N_EXT_ATTR13      IN NUMBER,
  X_N_EXT_ATTR14      IN NUMBER,
  X_N_EXT_ATTR15      IN NUMBER,
  X_N_EXT_ATTR16      IN NUMBER,
  X_N_EXT_ATTR17      IN NUMBER,
  X_N_EXT_ATTR18      IN NUMBER,
  X_N_EXT_ATTR19      IN NUMBER,
  X_N_EXT_ATTR20      IN NUMBER,
  X_D_EXT_ATTR1       IN DATE,
  X_D_EXT_ATTR2       IN DATE,
  X_D_EXT_ATTR3       IN DATE,
  X_D_EXT_ATTR4       IN DATE,
  X_D_EXT_ATTR5       IN DATE,
  X_D_EXT_ATTR6       IN DATE,
  X_D_EXT_ATTR7       IN DATE,
  X_D_EXT_ATTR8       IN DATE,
  X_D_EXT_ATTR9       IN DATE,
  X_D_EXT_ATTR10      IN DATE,
  X_TL_EXT_ATTR1      IN VARCHAR2,
  X_TL_EXT_ATTR2      IN VARCHAR2,
  X_TL_EXT_ATTR3      IN VARCHAR2,
  X_TL_EXT_ATTR4      IN VARCHAR2,
  X_TL_EXT_ATTR5      IN VARCHAR2,
  X_TL_EXT_ATTR6      IN VARCHAR2,
  X_TL_EXT_ATTR7      IN VARCHAR2,
  X_TL_EXT_ATTR8      IN VARCHAR2,
  X_TL_EXT_ATTR9      IN VARCHAR2,
  X_TL_EXT_ATTR10     IN VARCHAR2,
  X_TL_EXT_ATTR11     IN VARCHAR2,
  X_TL_EXT_ATTR12     IN VARCHAR2,
  X_TL_EXT_ATTR13     IN VARCHAR2,
  X_TL_EXT_ATTR14     IN VARCHAR2,
  X_TL_EXT_ATTR15     IN VARCHAR2,
  X_TL_EXT_ATTR16     IN VARCHAR2,
  X_TL_EXT_ATTR17     IN VARCHAR2,
  X_TL_EXT_ATTR18     IN VARCHAR2,
  X_TL_EXT_ATTR19     IN VARCHAR2,
  X_TL_EXT_ATTR20     IN VARCHAR2,
  X_CREATION_DATE     IN DATE,
  X_CREATED_BY        IN NUMBER,
  X_LAST_UPDATE_DATE  IN DATE,
  X_LAST_UPDATED_BY   IN NUMBER,
  X_LAST_UPDATE_LOGIN IN NUMBER
);

-- +==============================================================================+
-- | Name             : LOCK_ROW                                                  |
-- | Description      : This procedure shall lock rows into XX_CDH_ACCT_SITE_EXT_B    |
-- |                    and XX_CDH_ACCT_SITE_EXT_TL tables.                           |
-- |                                                                              |
-- |                                                                              |
-- +==============================================================================+

procedure LOCK_ROW (
  X_EXTENSION_ID       IN NUMBER,
  X_CUST_ACCT_SITE_ID  IN NUMBER,
  X_ATTR_GROUP_ID      IN NUMBER,
  X_C_EXT_ATTR1        IN VARCHAR2,
  X_C_EXT_ATTR2        IN VARCHAR2,
  X_C_EXT_ATTR3        IN VARCHAR2,
  X_C_EXT_ATTR4        IN VARCHAR2,
  X_C_EXT_ATTR5        IN VARCHAR2,
  X_C_EXT_ATTR6        IN VARCHAR2,
  X_C_EXT_ATTR7        IN VARCHAR2,
  X_C_EXT_ATTR8        IN VARCHAR2,
  X_C_EXT_ATTR9        IN VARCHAR2,
  X_C_EXT_ATTR10       IN VARCHAR2,
  X_C_EXT_ATTR11       IN VARCHAR2,
  X_C_EXT_ATTR12       IN VARCHAR2,
  X_C_EXT_ATTR13       IN VARCHAR2,
  X_C_EXT_ATTR14       IN VARCHAR2,
  X_C_EXT_ATTR15       IN VARCHAR2,
  X_C_EXT_ATTR16       IN VARCHAR2,
  X_C_EXT_ATTR17       IN VARCHAR2,
  X_C_EXT_ATTR18       IN VARCHAR2,
  X_C_EXT_ATTR19       IN VARCHAR2,
  X_C_EXT_ATTR20       IN VARCHAR2,
  X_N_EXT_ATTR1        IN NUMBER,
  X_N_EXT_ATTR2        IN NUMBER,
  X_N_EXT_ATTR3        IN NUMBER,
  X_N_EXT_ATTR4        IN NUMBER,
  X_N_EXT_ATTR5        IN NUMBER,
  X_N_EXT_ATTR6        IN NUMBER,
  X_N_EXT_ATTR7        IN NUMBER,
  X_N_EXT_ATTR8        IN NUMBER,
  X_N_EXT_ATTR9        IN NUMBER,
  X_N_EXT_ATTR10       IN NUMBER,
  X_N_EXT_ATTR11       IN NUMBER,
  X_N_EXT_ATTR12       IN NUMBER,
  X_N_EXT_ATTR13       IN NUMBER,
  X_N_EXT_ATTR14       IN NUMBER,
  X_N_EXT_ATTR15       IN NUMBER,
  X_N_EXT_ATTR16       IN NUMBER,
  X_N_EXT_ATTR17       IN NUMBER,
  X_N_EXT_ATTR18       IN NUMBER,
  X_N_EXT_ATTR19       IN NUMBER,
  X_N_EXT_ATTR20       IN NUMBER,
  X_D_EXT_ATTR1        IN DATE,
  X_D_EXT_ATTR2        IN DATE,
  X_D_EXT_ATTR3        IN DATE,
  X_D_EXT_ATTR4        IN DATE,
  X_D_EXT_ATTR5        IN DATE,
  X_D_EXT_ATTR6        IN DATE,
  X_D_EXT_ATTR7        IN DATE,
  X_D_EXT_ATTR8        IN DATE,
  X_D_EXT_ATTR9        IN DATE,
  X_D_EXT_ATTR10       IN DATE,
  X_TL_EXT_ATTR1       IN VARCHAR2,
  X_TL_EXT_ATTR2       IN VARCHAR2,
  X_TL_EXT_ATTR3       IN VARCHAR2,
  X_TL_EXT_ATTR4       IN VARCHAR2,
  X_TL_EXT_ATTR5       IN VARCHAR2,
  X_TL_EXT_ATTR6       IN VARCHAR2,
  X_TL_EXT_ATTR7       IN VARCHAR2,
  X_TL_EXT_ATTR8       IN VARCHAR2,
  X_TL_EXT_ATTR9       IN VARCHAR2,
  X_TL_EXT_ATTR10      IN VARCHAR2,
  X_TL_EXT_ATTR11      IN VARCHAR2,
  X_TL_EXT_ATTR12      IN VARCHAR2,
  X_TL_EXT_ATTR13      IN VARCHAR2,
  X_TL_EXT_ATTR14      IN VARCHAR2,
  X_TL_EXT_ATTR15      IN VARCHAR2,
  X_TL_EXT_ATTR16      IN VARCHAR2,
  X_TL_EXT_ATTR17      IN VARCHAR2,
  X_TL_EXT_ATTR18      IN VARCHAR2,
  X_TL_EXT_ATTR19      IN VARCHAR2,
  X_TL_EXT_ATTR20      IN VARCHAR2
  );

-- +==============================================================================+
-- | Name             : UPDATE_ROW                                                |
-- | Description      : This procedure shall update data into XX_CDH_ACCT_SITE_EXT_B  |
-- |                    and XX_CDH_ACCT_SITE_EXT_TL tables.                           |
-- |                                                                              |
-- +==============================================================================+

procedure UPDATE_ROW (
  X_EXTENSION_ID       IN NUMBER,
  X_CUST_ACCT_SITE_ID  IN NUMBER,
  X_ATTR_GROUP_ID      IN NUMBER,
  X_C_EXT_ATTR1        IN VARCHAR2,
  X_C_EXT_ATTR2        IN VARCHAR2,
  X_C_EXT_ATTR3        IN VARCHAR2,
  X_C_EXT_ATTR4        IN VARCHAR2,
  X_C_EXT_ATTR5        IN VARCHAR2,
  X_C_EXT_ATTR6        IN VARCHAR2,
  X_C_EXT_ATTR7        IN VARCHAR2,
  X_C_EXT_ATTR8        IN VARCHAR2,
  X_C_EXT_ATTR9        IN VARCHAR2,
  X_C_EXT_ATTR10       IN VARCHAR2,
  X_C_EXT_ATTR11       IN VARCHAR2,
  X_C_EXT_ATTR12       IN VARCHAR2,
  X_C_EXT_ATTR13       IN VARCHAR2,
  X_C_EXT_ATTR14       IN VARCHAR2,
  X_C_EXT_ATTR15       IN VARCHAR2,
  X_C_EXT_ATTR16       IN VARCHAR2,
  X_C_EXT_ATTR17       IN VARCHAR2,
  X_C_EXT_ATTR18       IN VARCHAR2,
  X_C_EXT_ATTR19       IN VARCHAR2,
  X_C_EXT_ATTR20       IN VARCHAR2,
  X_N_EXT_ATTR1        IN NUMBER,
  X_N_EXT_ATTR2        IN NUMBER,
  X_N_EXT_ATTR3        IN NUMBER,
  X_N_EXT_ATTR4        IN NUMBER,
  X_N_EXT_ATTR5        IN NUMBER,
  X_N_EXT_ATTR6        IN NUMBER,
  X_N_EXT_ATTR7        IN NUMBER,
  X_N_EXT_ATTR8        IN NUMBER,
  X_N_EXT_ATTR9        IN NUMBER,
  X_N_EXT_ATTR10       IN NUMBER,
  X_N_EXT_ATTR11       IN NUMBER,
  X_N_EXT_ATTR12       IN NUMBER,
  X_N_EXT_ATTR13       IN NUMBER,
  X_N_EXT_ATTR14       IN NUMBER,
  X_N_EXT_ATTR15       IN NUMBER,
  X_N_EXT_ATTR16       IN NUMBER,
  X_N_EXT_ATTR17       IN NUMBER,
  X_N_EXT_ATTR18       IN NUMBER,
  X_N_EXT_ATTR19       IN NUMBER,
  X_N_EXT_ATTR20       IN NUMBER,
  X_D_EXT_ATTR1        IN DATE,
  X_D_EXT_ATTR2        IN DATE,
  X_D_EXT_ATTR3        IN DATE,
  X_D_EXT_ATTR4        IN DATE,
  X_D_EXT_ATTR5        IN DATE,
  X_D_EXT_ATTR6        IN DATE,
  X_D_EXT_ATTR7        IN DATE,
  X_D_EXT_ATTR8        IN DATE,
  X_D_EXT_ATTR9        IN DATE,
  X_D_EXT_ATTR10       IN DATE,
  X_TL_EXT_ATTR1       IN VARCHAR2,
  X_TL_EXT_ATTR2       IN VARCHAR2,
  X_TL_EXT_ATTR3       IN VARCHAR2,
  X_TL_EXT_ATTR4       IN VARCHAR2,
  X_TL_EXT_ATTR5       IN VARCHAR2,
  X_TL_EXT_ATTR6       IN VARCHAR2,
  X_TL_EXT_ATTR7       IN VARCHAR2,
  X_TL_EXT_ATTR8       IN VARCHAR2,
  X_TL_EXT_ATTR9       IN VARCHAR2,
  X_TL_EXT_ATTR10      IN VARCHAR2,
  X_TL_EXT_ATTR11      IN VARCHAR2,
  X_TL_EXT_ATTR12      IN VARCHAR2,
  X_TL_EXT_ATTR13      IN VARCHAR2,
  X_TL_EXT_ATTR14      IN VARCHAR2,
  X_TL_EXT_ATTR15      IN VARCHAR2,
  X_TL_EXT_ATTR16      IN VARCHAR2,
  X_TL_EXT_ATTR17      IN VARCHAR2,
  X_TL_EXT_ATTR18      IN VARCHAR2,
  X_TL_EXT_ATTR19      IN VARCHAR2,
  X_TL_EXT_ATTR20      IN VARCHAR2,
  X_LAST_UPDATE_DATE   IN DATE,
  X_LAST_UPDATED_BY    IN NUMBER,
  X_LAST_UPDATE_LOGIN  IN NUMBER
  );

-- +==============================================================================+
-- | Name             : DELETE_ROW                                                |
-- | Description      : This procedure shall delete data  in XX_CDH_ACCT_SITE_EXT_B   |
-- |                    XX_CDH_ACCT_SITE_EXT_TL table for the given extension id.     |
-- |                                                                              |
-- +==============================================================================+

procedure DELETE_ROW (
  X_EXTENSION_ID     IN NUMBER);

-- +==============================================================================+
-- | Name             : ADD_LANGUAGE                                              |
-- | Description      : This procedure shall insert and update data  in           |
-- |                    XX_CDH_ACCT_SITE_EXT_TL table.                                |
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
  X_EXTENSION_ID       IN NUMBER,
  X_CUST_ACCT_SITE_ID  IN NUMBER,
  X_ATTR_GROUP_ID      IN NUMBER,
  X_C_EXT_ATTR1        IN VARCHAR2,
  X_C_EXT_ATTR2        IN VARCHAR2,
  X_C_EXT_ATTR3        IN VARCHAR2,
  X_C_EXT_ATTR4        IN VARCHAR2,
  X_C_EXT_ATTR5        IN VARCHAR2,
  X_C_EXT_ATTR6        IN VARCHAR2,
  X_C_EXT_ATTR7        IN VARCHAR2,
  X_C_EXT_ATTR8        IN VARCHAR2,
  X_C_EXT_ATTR9        IN VARCHAR2,
  X_C_EXT_ATTR10       IN VARCHAR2,
  X_C_EXT_ATTR11       IN VARCHAR2,
  X_C_EXT_ATTR12       IN VARCHAR2,
  X_C_EXT_ATTR13       IN VARCHAR2,
  X_C_EXT_ATTR14       IN VARCHAR2,
  X_C_EXT_ATTR15       IN VARCHAR2,
  X_C_EXT_ATTR16       IN VARCHAR2,
  X_C_EXT_ATTR17       IN VARCHAR2,
  X_C_EXT_ATTR18       IN VARCHAR2,
  X_C_EXT_ATTR19       IN VARCHAR2,
  X_C_EXT_ATTR20       IN VARCHAR2,
  X_N_EXT_ATTR1        IN NUMBER,
  X_N_EXT_ATTR2        IN NUMBER,
  X_N_EXT_ATTR3        IN NUMBER,
  X_N_EXT_ATTR4        IN NUMBER,
  X_N_EXT_ATTR5        IN NUMBER,
  X_N_EXT_ATTR6        IN NUMBER,
  X_N_EXT_ATTR7        IN NUMBER,
  X_N_EXT_ATTR8        IN NUMBER,
  X_N_EXT_ATTR9        IN NUMBER,
  X_N_EXT_ATTR10       IN NUMBER,
  X_N_EXT_ATTR11       IN NUMBER,
  X_N_EXT_ATTR12       IN NUMBER,
  X_N_EXT_ATTR13       IN NUMBER,
  X_N_EXT_ATTR14       IN NUMBER,
  X_N_EXT_ATTR15       IN NUMBER,
  X_N_EXT_ATTR16       IN NUMBER,
  X_N_EXT_ATTR17       IN NUMBER,
  X_N_EXT_ATTR18       IN NUMBER,
  X_N_EXT_ATTR19       IN NUMBER,
  X_N_EXT_ATTR20       IN NUMBER,
  X_D_EXT_ATTR1        IN DATE,
  X_D_EXT_ATTR2        IN DATE,
  X_D_EXT_ATTR3        IN DATE,
  X_D_EXT_ATTR4        IN DATE,
  X_D_EXT_ATTR5        IN DATE,
  X_D_EXT_ATTR6        IN DATE,
  X_D_EXT_ATTR7        IN DATE,
  X_D_EXT_ATTR8        IN DATE,
  X_D_EXT_ATTR9        IN DATE,
  X_D_EXT_ATTR10       IN DATE,
  X_TL_EXT_ATTR1       IN VARCHAR2,
  X_TL_EXT_ATTR2       IN VARCHAR2,
  X_TL_EXT_ATTR3       IN VARCHAR2,
  X_TL_EXT_ATTR4       IN VARCHAR2,
  X_TL_EXT_ATTR5       IN VARCHAR2,
  X_TL_EXT_ATTR6       IN VARCHAR2,
  X_TL_EXT_ATTR7       IN VARCHAR2,
  X_TL_EXT_ATTR8       IN VARCHAR2,
  X_TL_EXT_ATTR9       IN VARCHAR2,
  X_TL_EXT_ATTR10      IN VARCHAR2,
  X_TL_EXT_ATTR11      IN VARCHAR2,
  X_TL_EXT_ATTR12      IN VARCHAR2,
  X_TL_EXT_ATTR13      IN VARCHAR2,
  X_TL_EXT_ATTR14      IN VARCHAR2,
  X_TL_EXT_ATTR15      IN VARCHAR2,
  X_TL_EXT_ATTR16      IN VARCHAR2,
  X_TL_EXT_ATTR17      IN VARCHAR2,
  X_TL_EXT_ATTR18      IN VARCHAR2,
  X_TL_EXT_ATTR19      IN VARCHAR2,
  X_TL_EXT_ATTR20      IN VARCHAR2,
  X_OWNER              IN VARCHAR2
  );

-- +==============================================================================+
-- | Name             : TRANSLATE_ROW                                             |
-- | Description      : This procedure is not being implemented.                  |
-- |                                                                              |
-- +==============================================================================+

procedure TRANSLATE_ROW (
  X_EXTENSION_ID       IN NUMBER,
  X_CUST_ACCT_SITE_ID  IN NUMBER,
  X_ATTR_GROUP_ID      IN NUMBER,
  X_TL_EXT_ATTR1       IN VARCHAR2,
  X_TL_EXT_ATTR2       IN VARCHAR2,
  X_TL_EXT_ATTR3       IN VARCHAR2,
  X_TL_EXT_ATTR4       IN VARCHAR2,
  X_TL_EXT_ATTR5       IN VARCHAR2,
  X_TL_EXT_ATTR6       IN VARCHAR2,
  X_TL_EXT_ATTR7       IN VARCHAR2,
  X_TL_EXT_ATTR8       IN VARCHAR2,
  X_TL_EXT_ATTR9       IN VARCHAR2,
  X_TL_EXT_ATTR10      IN VARCHAR2,
  X_TL_EXT_ATTR11      IN VARCHAR2,
  X_TL_EXT_ATTR12      IN VARCHAR2,
  X_TL_EXT_ATTR13      IN VARCHAR2,
  X_TL_EXT_ATTR14      IN VARCHAR2,
  X_TL_EXT_ATTR15      IN VARCHAR2,
  X_TL_EXT_ATTR16      IN VARCHAR2,
  X_TL_EXT_ATTR17      IN VARCHAR2,
  X_TL_EXT_ATTR18      IN VARCHAR2,
  X_TL_EXT_ATTR19      IN VARCHAR2,
  X_TL_EXT_ATTR20      IN VARCHAR2,
  X_OWNER              IN VARCHAR2
  );

END XX_CDH_CUST_ACCT_SITE_EXT_PKG;
/
SHOW ERRORS;
