SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_CDH_CUST_ACCT_SITE_EXTW_PKG AUTHID CURRENT_USER
  -- +======================================================================================+
  -- |                  Office Depot - Project Simplify                                     |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
  -- +======================================================================================|
  -- | Name       : XX_CDH_CUST_ACCT_SITE_EXTW_PKG                                          |
  -- | Description: This package is the Wrapper for  XX_CDH_CUST_ACCT_SITE_EXT_PKG          |
  -- |                                                                                      |
  -- |                                                                                      |
  -- |Change Record:                                                                        |
  -- |===============                                                                       |
  -- |Version     Date            Author               Remarks                              |
  -- |=======   ===========   =================     ========================================|
  -- |DRAFT 1A  17-MAR-2010   Mangala                   Initial draft version               |
  -- |                                                                                      |
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
PROCEDURE INSERT_ROW(
    x_rowid IN OUT NOCOPY VARCHAR2,
    x_return_status OUT VARCHAR2,
    p_extension_id      IN NUMBER,
    p_cust_acct_site_id IN NUMBER,
    p_attr_group_id     IN NUMBER,
    p_c_ext_attr1       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr2       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr3       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr4       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr5       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr6       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr7       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr8       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr9       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr10      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr11      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr12      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr13      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr14      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr15      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr16      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr17      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr18      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr19      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr20      IN VARCHAR2 DEFAULT NULL,
    p_n_ext_attr1       IN NUMBER DEFAULT NULL,
    p_n_ext_attr2       IN NUMBER DEFAULT NULL,
    p_n_ext_attr3       IN NUMBER DEFAULT NULL,
    p_n_ext_attr4       IN NUMBER DEFAULT NULL,
    p_n_ext_attr5       IN NUMBER DEFAULT NULL,
    p_n_ext_attr6       IN NUMBER DEFAULT NULL,
    p_n_ext_attr7       IN NUMBER DEFAULT NULL,
    p_n_ext_attr8       IN NUMBER DEFAULT NULL,
    p_n_ext_attr9       IN NUMBER DEFAULT NULL,
    p_n_ext_attr10      IN NUMBER DEFAULT NULL,
    p_n_ext_attr11      IN NUMBER DEFAULT NULL,
    p_n_ext_attr12      IN NUMBER DEFAULT NULL,
    p_n_ext_attr13      IN NUMBER DEFAULT NULL,
    p_n_ext_attr14      IN NUMBER DEFAULT NULL,
    p_n_ext_attr15      IN NUMBER DEFAULT NULL,
    p_n_ext_attr16      IN NUMBER DEFAULT NULL,
    p_n_ext_attr17      IN NUMBER DEFAULT NULL,
    p_n_ext_attr18      IN NUMBER DEFAULT NULL,
    p_n_ext_attr19      IN NUMBER DEFAULT NULL,
    p_n_ext_attr20      IN NUMBER DEFAULT NULL,
    p_d_ext_attr1       IN DATE DEFAULT NULL,
    p_d_ext_attr2       IN DATE DEFAULT NULL,
    p_d_ext_attr3       IN DATE DEFAULT NULL,
    p_d_ext_attr4       IN DATE DEFAULT NULL,
    p_d_ext_attr5       IN DATE DEFAULT NULL,
    p_d_ext_attr6       IN DATE DEFAULT NULL,
    p_d_ext_attr7       IN DATE DEFAULT NULL,
    p_d_ext_attr8       IN DATE DEFAULT NULL,
    p_d_ext_attr9       IN DATE DEFAULT NULL,
    p_d_ext_attr10      IN DATE DEFAULT NULL,
    p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL,
    p_creation_date     IN DATE DEFAULT SYSDATE,
    p_created_by        IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_last_update_date  IN DATE DEFAULT SYSDATE,
    p_last_updated_by   IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_last_update_login IN NUMBER DEFAULT FND_GLOBAL.USER_ID );
  -- +==============================================================================+
  -- | Name             : LOCK_ROW                                                  |
  -- | Description      : This procedure shall lock rows into XX_CDH_ACCT_SITE_EXT_B    |
  -- |                    and XX_CDH_ACCT_SITE_EXT_TL tables.                           |
  -- |                                                                              |
  -- |                                                                              |
  -- +==============================================================================+
PROCEDURE LOCK_ROW(
    p_extension_id      IN NUMBER,
    p_cust_acct_site_ID IN NUMBER,
    p_attr_group_id     IN NUMBER,
    p_c_ext_attr1       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr2       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr3       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr4       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr5       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr6       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr7       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr8       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr9       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr10      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr11      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr12      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr13      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr14      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr15      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr16      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr17      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr18      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr19      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr20      IN VARCHAR2 DEFAULT NULL,
    p_n_ext_attr1       IN NUMBER DEFAULT NULL,
    p_n_ext_attr2       IN NUMBER DEFAULT NULL,
    p_n_ext_attr3       IN NUMBER DEFAULT NULL,
    p_n_ext_attr4       IN NUMBER DEFAULT NULL,
    p_n_ext_attr5       IN NUMBER DEFAULT NULL,
    p_n_ext_attr6       IN NUMBER DEFAULT NULL,
    p_n_ext_attr7       IN NUMBER DEFAULT NULL,
    p_n_ext_attr8       IN NUMBER DEFAULT NULL,
    p_n_ext_attr9       IN NUMBER DEFAULT NULL,
    p_n_ext_attr10      IN NUMBER DEFAULT NULL,
    p_n_ext_attr11      IN NUMBER DEFAULT NULL,
    p_n_ext_attr12      IN NUMBER DEFAULT NULL,
    p_n_ext_attr13      IN NUMBER DEFAULT NULL,
    p_n_ext_attr14      IN NUMBER DEFAULT NULL,
    p_n_ext_attr15      IN NUMBER DEFAULT NULL,
    p_n_ext_attr16      IN NUMBER DEFAULT NULL,
    p_n_ext_attr17      IN NUMBER DEFAULT NULL,
    p_n_ext_attr18      IN NUMBER DEFAULT NULL,
    p_n_ext_attr19      IN NUMBER DEFAULT NULL,
    p_n_ext_attr20      IN NUMBER DEFAULT NULL,
    p_d_ext_attr1       IN DATE DEFAULT NULL,
    p_d_ext_attr2       IN DATE DEFAULT NULL,
    p_d_ext_attr3       IN DATE DEFAULT NULL,
    p_d_ext_attr4       IN DATE DEFAULT NULL,
    p_d_ext_attr5       IN DATE DEFAULT NULL,
    p_d_ext_attr6       IN DATE DEFAULT NULL,
    p_d_ext_attr7       IN DATE DEFAULT NULL,
    p_d_ext_attr8       IN DATE DEFAULT NULL,
    p_d_ext_attr9       IN DATE DEFAULT NULL,
    p_d_ext_attr10      IN DATE DEFAULT NULL,
    p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL );
  -- +==============================================================================+
  -- | Name             : UPDATE_ROW                                                |
  -- | Description      : This procedure shall update data into XX_CDH_ACCT_SITE_EXT_B  |
  -- |                    and XX_CDH_ACCT_SITE_EXT_TL tables.                           |
  -- |                                                                              |
  -- +==============================================================================+
PROCEDURE UPDATE_ROW(
    x_return_status OUT VARCHAR2,
    p_extension_id      IN NUMBER,
    p_cust_acct_site_id IN NUMBER,
    p_attr_group_id     IN NUMBER,
    p_c_ext_attr1       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr2       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr3       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr4       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr5       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr6       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr7       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr8       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr9       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr10      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr11      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr12      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr13      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr14      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr15      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr16      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr17      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr18      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr19      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr20      IN VARCHAR2 DEFAULT NULL,
    p_n_ext_attr1       IN NUMBER DEFAULT NULL,
    p_n_ext_attr2       IN NUMBER DEFAULT NULL,
    p_n_ext_attr3       IN NUMBER DEFAULT NULL,
    p_n_ext_attr4       IN NUMBER DEFAULT NULL,
    p_n_ext_attr5       IN NUMBER DEFAULT NULL,
    p_n_ext_attr6       IN NUMBER DEFAULT NULL,
    p_n_ext_attr7       IN NUMBER DEFAULT NULL,
    p_n_ext_attr8       IN NUMBER DEFAULT NULL,
    p_n_ext_attr9       IN NUMBER DEFAULT NULL,
    p_n_ext_attr10      IN NUMBER DEFAULT NULL,
    p_n_ext_attr11      IN NUMBER DEFAULT NULL,
    p_n_ext_attr12      IN NUMBER DEFAULT NULL,
    p_n_ext_attr13      IN NUMBER DEFAULT NULL,
    p_n_ext_attr14      IN NUMBER DEFAULT NULL,
    p_n_ext_attr15      IN NUMBER DEFAULT NULL,
    p_n_ext_attr16      IN NUMBER DEFAULT NULL,
    p_n_ext_attr17      IN NUMBER DEFAULT NULL,
    p_n_ext_attr18      IN NUMBER DEFAULT NULL,
    p_n_ext_attr19      IN NUMBER DEFAULT NULL,
    p_n_ext_attr20      IN NUMBER DEFAULT NULL,
    p_d_ext_attr1       IN DATE DEFAULT NULL,
    p_d_ext_attr2       IN DATE DEFAULT NULL,
    p_d_ext_attr3       IN DATE DEFAULT NULL,
    p_d_ext_attr4       IN DATE DEFAULT NULL,
    p_d_ext_attr5       IN DATE DEFAULT NULL,
    p_d_ext_attr6       IN DATE DEFAULT NULL,
    p_d_ext_attr7       IN DATE DEFAULT NULL,
    p_d_ext_attr8       IN DATE DEFAULT NULL,
    p_d_ext_attr9       IN DATE DEFAULT NULL,
    p_d_ext_attr10      IN DATE DEFAULT NULL,
    p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL,
    p_last_update_date  IN DATE DEFAULT SYSDATE,
    p_last_updated_by   IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
    p_last_update_login IN NUMBER DEFAULT FND_GLOBAL.USER_ID );
  -- +==============================================================================+
  -- | Name             : DELETE_ROW                                                |
  -- | Description      : This procedure shall delete data  in XX_CDH_ACCT_SITE_EXT_B   |
  -- |                    XX_CDH_ACCT_SITE_EXT_TL table for the given extension id.     |
  -- |                                                                              |
  -- +==============================================================================+
PROCEDURE DELETE_ROW(
    p_extension_id IN NUMBER);
  -- +==============================================================================+
  -- | Name             : ADD_LANGUAGE                                              |
  -- | Description      : This procedure shall insert and update data  in           |
  -- |                    XX_CDH_ACCT_SITE_EXT_TL table.                                |
  -- |                                                                              |
  -- +==============================================================================+
PROCEDURE ADD_LANGUAGE ;
  -- +==============================================================================+
  -- | Name             : LOAD_ROW                                                  |
  -- | Description      : This procedure does not being implemented.                |
  -- |                                                                              |
  -- |                                                                              |
  -- +==============================================================================+
PROCEDURE LOAD_ROW(
    p_extension_id      IN NUMBER,
    p_cust_acct_site_ID IN NUMBER,
    p_attr_group_id     IN NUMBER,
    p_c_ext_attr1       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr2       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr3       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr4       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr5       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr6       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr7       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr8       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr9       IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr10      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr11      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr12      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr13      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr14      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr15      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr16      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr17      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr18      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr19      IN VARCHAR2 DEFAULT NULL,
    p_c_ext_attr20      IN VARCHAR2 DEFAULT NULL,
    p_n_ext_attr1       IN NUMBER DEFAULT NULL,
    p_n_ext_attr2       IN NUMBER DEFAULT NULL,
    p_n_ext_attr3       IN NUMBER DEFAULT NULL,
    p_n_ext_attr4       IN NUMBER DEFAULT NULL,
    p_n_ext_attr5       IN NUMBER DEFAULT NULL,
    p_n_ext_attr6       IN NUMBER DEFAULT NULL,
    p_n_ext_attr7       IN NUMBER DEFAULT NULL,
    p_n_ext_attr8       IN NUMBER DEFAULT NULL,
    p_n_ext_attr9       IN NUMBER DEFAULT NULL,
    p_n_ext_attr10      IN NUMBER DEFAULT NULL,
    p_n_ext_attr11      IN NUMBER DEFAULT NULL,
    p_n_ext_attr12      IN NUMBER DEFAULT NULL,
    p_n_ext_attr13      IN NUMBER DEFAULT NULL,
    p_n_ext_attr14      IN NUMBER DEFAULT NULL,
    p_n_ext_attr15      IN NUMBER DEFAULT NULL,
    p_n_ext_attr16      IN NUMBER DEFAULT NULL,
    p_n_ext_attr17      IN NUMBER DEFAULT NULL,
    p_n_ext_attr18      IN NUMBER DEFAULT NULL,
    p_n_ext_attr19      IN NUMBER DEFAULT NULL,
    p_n_ext_attr20      IN NUMBER DEFAULT NULL,
    p_d_ext_attr1       IN DATE DEFAULT NULL,
    p_d_ext_attr2       IN DATE DEFAULT NULL,
    p_d_ext_attr3       IN DATE DEFAULT NULL,
    p_d_ext_attr4       IN DATE DEFAULT NULL,
    p_d_ext_attr5       IN DATE DEFAULT NULL,
    p_d_ext_attr6       IN DATE DEFAULT NULL,
    p_d_ext_attr7       IN DATE DEFAULT NULL,
    p_d_ext_attr8       IN DATE DEFAULT NULL,
    p_d_ext_attr9       IN DATE DEFAULT NULL,
    p_d_ext_attr10      IN DATE DEFAULT NULL,
    p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL,
    p_owner             IN VARCHAR2 DEFAULT NULL );
  -- +==============================================================================+
  -- | Name             : TRANSLATE_ROW                                             |
  -- | Description      : This procedure is not being implemented.                  |
  -- |                                                                              |
  -- +==============================================================================+
PROCEDURE TRANSLATE_ROW(
    p_extension_id      IN NUMBER,
    p_cust_acct_site_id IN NUMBER,
    p_attr_group_id     IN NUMBER,
    p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
    p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL,
    p_owner             IN VARCHAR2 DEFAULT NULL );
  -- +==========================================================================================+
  -- | Name             : VALIDATE_DUPLICATE_ROW                                                |
  -- | Description      : This procedure is to do the validation while the user tries creating  |
  -- |                    more than one Exception for a particular Cust Doc Id .                |
  -- |                                                                                          |
  -- +==========================================================================================+
PROCEDURE VALIDATE_DUPLICATE_ROW(
    x_ret_status OUT VARCHAR2,
    p_cust_doc_id IN NUMBER,
    p_from_site   IN NUMBER);
END XX_CDH_CUST_ACCT_SITE_EXTW_PKG;
/
SHOW ERRORS;