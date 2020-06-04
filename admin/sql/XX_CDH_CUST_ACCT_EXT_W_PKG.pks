create or replace package XX_CDH_CUST_ACCT_EXT_W_PKG AUTHID CURRENT_USER
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_CDH_CUST_ACCT_EXT_W_PKG                                              |
-- | Description: This package is the Wrapper for the Package XX_CDH_CUST_ACCT_EXT_PKG	  |
-- |											                                          |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version     Date            Author               Remarks                              |
-- |=======   ===========   ==================    ========================================|
-- |DRAFT 1A  17-MAR-2010      Mangala		   Initial draft version                      |
-- |1.1       20-Nov-2018    Reddy Sekhar      Code changes for Req NAIT-61952 and 66520  |
-- |1.2       27-MAY-2020    Divyansh           Added logic for JIRA NAIT-129167          |
-- |                                                                                      |
-- |======================================================================================|
-- | Subversion Info:                                                                     |
-- | $HeadURL: file:///app/svnrepos/od/crm/trunk/xxcrm/admin/sql/XX_CDH_CUST_ACCT_EXT_W_PKG.pks $                                                                          |
-- | $Rev: 291512 $                                                                       |
-- | $Date: 2018-11-21 03:38:19 -0500 (Wed, 21 Nov 2018) $                                |
-- |                                                                                      |
-- +======================================================================================+
AS

-- +==================================================================================+
-- | Name             : INSERT_ROW                                                    |
-- | Description      : This procedure shall insert data into XX_CDH_CUST_ACCT_EXT_B  |
-- |                    and XX_CDH_CUST_ACCT_EXT_TL tables.                           |
-- |										      |
-- +=================================================================================+

procedure INSERT_ROW (
  x_rowid             IN OUT NOCOPY VARCHAR2 ,
  p_extension_id      IN NUMBER,
  p_cust_account_id   IN NUMBER,
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
  p_last_update_login IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
  p_bc_pod_flag       IN VARCHAR2 DEFAULT NULL --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520
  ,p_fee_option          IN              VARCHAR2 DEFAULT NULL --code added for 1.2
  );

-- +==============================================================================+
-- | Name             : LOCK_ROW                                                  |
-- | Description      : This procedure shall lock rows into XX_CDH_CUST_ACCT_EXT_B|
-- |                    and XX_CDH_CUST_ACCT_EXT_TL tables.                       |
-- |                                                                              |
-- |                                                                              |
-- +==============================================================================+

procedure LOCK_ROW (
  p_extension_id       IN NUMBER,
  p_cust_account_id    IN NUMBER,
  p_attr_group_id      IN NUMBER,
  p_c_ext_attr1        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr2        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr3        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr4        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr5        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr6        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr7        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr8        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr9        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr10       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr11       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr12       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr13       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr14       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr15       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr16       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr17       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr18       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr19       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr20       IN VARCHAR2 DEFAULT NULL,
  p_n_ext_attr1        IN NUMBER DEFAULT NULL,
  p_n_ext_attr2        IN NUMBER DEFAULT NULL,
  p_n_ext_attr3        IN NUMBER DEFAULT NULL,
  p_n_ext_attr4        IN NUMBER DEFAULT NULL,
  p_n_ext_attr5        IN NUMBER DEFAULT NULL,
  p_n_ext_attr6        IN NUMBER DEFAULT NULL,
  p_n_ext_attr7        IN NUMBER DEFAULT NULL,
  p_n_ext_attr8        IN NUMBER DEFAULT NULL,
  p_n_ext_attr9        IN NUMBER DEFAULT NULL,
  p_n_ext_attr10       IN NUMBER DEFAULT NULL,
  p_n_ext_attr11       IN NUMBER DEFAULT NULL,
  p_n_ext_attr12       IN NUMBER DEFAULT NULL,
  p_n_ext_attr13       IN NUMBER DEFAULT NULL,
  p_n_ext_attr14       IN NUMBER DEFAULT NULL,
  p_n_ext_attr15       IN NUMBER DEFAULT NULL,
  p_n_ext_attr16       IN NUMBER DEFAULT NULL,
  p_n_ext_attr17       IN NUMBER DEFAULT NULL,
  p_n_ext_attr18       IN NUMBER DEFAULT NULL,
  p_n_ext_attr19       IN NUMBER DEFAULT NULL,
  p_n_ext_attr20       IN NUMBER DEFAULT NULL,
  p_d_ext_attr1        IN DATE DEFAULT NULL,
  p_d_ext_attr2        IN DATE DEFAULT NULL,
  p_d_ext_attr3        IN DATE DEFAULT NULL,
  p_d_ext_attr4        IN DATE DEFAULT NULL,
  p_d_ext_attr5        IN DATE DEFAULT NULL,
  p_d_ext_attr6        IN DATE DEFAULT NULL,
  p_d_ext_attr7        IN DATE DEFAULT NULL,
  p_d_ext_attr8        IN DATE DEFAULT NULL,
  p_d_ext_attr9        IN DATE DEFAULT NULL,
  p_d_ext_attr10       IN DATE DEFAULT NULL,
  p_tl_ext_attr1       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr2       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr3       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr4       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr5       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr6       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr7       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr8       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr9       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr10      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr11      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr12      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr13      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr14      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr15      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr16      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr17      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr18      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr19      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr20      IN VARCHAR2 DEFAULT NULL,
  p_bc_pod_flag        IN VARCHAR2 DEFAULT NULL --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520
  ,p_fee_option          IN              VARCHAR2 DEFAULT NULL --code added for 1.2
  );

-- +==============================================================================+
-- | Name             : UPDATE_ROW                                                |
-- | Description      :This procedure shall update data intoXX_CDH_CUST_ACCT_EXT_B|
-- |                    and XX_CDH_CUST_ACCT_EXT_TL tables.                       |
-- |                                                                              |
-- +==============================================================================+

procedure UPDATE_ROW (
  p_extension_id       IN NUMBER ,
  p_cust_account_id    IN NUMBER,
  p_attr_group_id      IN NUMBER,
  p_c_ext_attr1        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr2        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr3        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr4        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr5        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr6        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr7        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr8        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr9        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr10       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr11       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr12       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr13       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr14       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr15       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr16       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr17       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr18       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr19       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr20       IN VARCHAR2 DEFAULT NULL,
  p_n_ext_attr1        IN NUMBER DEFAULT NULL,
  p_n_ext_attr2        IN NUMBER DEFAULT NULL,
  p_n_ext_attr3        IN NUMBER DEFAULT NULL,
  p_n_ext_attr4        IN NUMBER DEFAULT NULL,
  p_n_ext_attr5        IN NUMBER DEFAULT NULL,
  p_n_ext_attr6        IN NUMBER DEFAULT NULL,
  p_n_ext_attr7        IN NUMBER DEFAULT NULL,
  p_n_ext_attr8        IN NUMBER DEFAULT NULL,
  p_n_ext_attr9        IN NUMBER DEFAULT NULL,
  p_n_ext_attr10       IN NUMBER DEFAULT NULL,
  p_n_ext_attr11       IN NUMBER DEFAULT NULL,
  p_n_ext_attr12       IN NUMBER DEFAULT NULL,
  p_n_ext_attr13       IN NUMBER DEFAULT NULL,
  p_n_ext_attr14       IN NUMBER DEFAULT NULL,
  p_n_ext_attr15       IN NUMBER DEFAULT NULL,
  p_n_ext_attr16       IN NUMBER DEFAULT NULL,
  p_n_ext_attr17       IN NUMBER DEFAULT NULL,
  p_n_ext_attr18       IN NUMBER DEFAULT NULL,
  p_n_ext_attr19       IN NUMBER DEFAULT NULL,
  p_n_ext_attr20       IN NUMBER DEFAULT NULL,
  p_d_ext_attr1        IN DATE DEFAULT NULL,
  p_d_ext_attr2        IN DATE DEFAULT NULL,
  p_d_ext_attr3        IN DATE DEFAULT NULL,
  p_d_ext_attr4        IN DATE DEFAULT NULL,
  p_d_ext_attr5        IN DATE DEFAULT NULL,
  p_d_ext_attr6        IN DATE DEFAULT NULL,
  p_d_ext_attr7        IN DATE DEFAULT NULL,
  p_d_ext_attr8        IN DATE DEFAULT NULL,
  p_d_ext_attr9        IN DATE DEFAULT NULL,
  p_d_ext_attr10       IN DATE DEFAULT NULL,
  p_tl_ext_attr1       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr2       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr3       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr4       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr5       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr6       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr7       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr8       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr9       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr10      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr11      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr12      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr13      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr14      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr15      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr16      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr17      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr18      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr19      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr20      IN VARCHAR2 DEFAULT NULL,
  p_last_update_date   IN DATE DEFAULT SYSDATE,
  p_last_updated_by    IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
  p_last_update_login  IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
  p_bc_pod_flag        IN VARCHAR2 DEFAULT NULL --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520
  ,p_fee_option        IN              VARCHAR2 DEFAULT NULL --code added for 1.2
  );

-- +==============================================================================+
-- | Name             : DELETE_ROW                                                |
-- | Description      : This procedure shall delete data in XX_CDH_CUST_ACCT_EXT_B|
-- |                    XX_CDH_CUST_ACCT_EXT_TL table for the given extension id. |
-- |                                                                              |
-- +==============================================================================+

procedure DELETE_ROW (
  p_extension_id     IN NUMBER);

-- +==============================================================================+
-- | Name             : ADD_LANGUAGE                                              |
-- | Description      : This procedure shall insert and update data  in           |
-- |                    XX_CDH_CUST_ACCT_EXT_TL table.                            |
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
  p_extension_id       IN NUMBER,
  p_cust_account_id    IN NUMBER,
  p_attr_group_id      IN NUMBER,
  p_c_ext_attr1        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr2        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr3        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr4        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr5        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr6        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr7        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr8        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr9        IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr10       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr11       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr12       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr13       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr14       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr15       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr16       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr17       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr18       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr19       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr20       IN VARCHAR2 DEFAULT NULL,
  p_n_ext_attr1        IN NUMBER DEFAULT NULL,
  p_n_ext_attr2        IN NUMBER DEFAULT NULL,
  p_n_ext_attr3        IN NUMBER DEFAULT NULL,
  p_n_ext_attr4        IN NUMBER DEFAULT NULL,
  p_n_ext_attr5        IN NUMBER DEFAULT NULL,
  p_n_ext_attr6        IN NUMBER DEFAULT NULL,
  p_n_ext_attr7        IN NUMBER DEFAULT NULL,
  p_n_ext_attr8        IN NUMBER DEFAULT NULL,
  p_n_ext_attr9        IN NUMBER DEFAULT NULL,
  p_n_ext_attr10       IN NUMBER DEFAULT NULL,
  p_n_ext_attr11       IN NUMBER DEFAULT NULL,
  p_n_ext_attr12       IN NUMBER DEFAULT NULL,
  p_n_ext_attr13       IN NUMBER DEFAULT NULL,
  p_n_ext_attr14       IN NUMBER DEFAULT NULL,
  p_n_ext_attr15       IN NUMBER DEFAULT NULL,
  p_n_ext_attr16       IN NUMBER DEFAULT NULL,
  p_n_ext_attr17       IN NUMBER DEFAULT NULL,
  p_n_ext_attr18       IN NUMBER DEFAULT NULL,
  p_n_ext_attr19       IN NUMBER DEFAULT NULL,
  p_n_ext_attr20       IN NUMBER DEFAULT NULL,
  p_d_ext_attr1        IN DATE DEFAULT NULL,
  p_d_ext_attr2        IN DATE DEFAULT NULL,
  p_d_ext_attr3        IN DATE DEFAULT NULL,
  p_d_ext_attr4        IN DATE DEFAULT NULL,
  p_d_ext_attr5        IN DATE DEFAULT NULL,
  p_d_ext_attr6        IN DATE DEFAULT NULL,
  p_d_ext_attr7        IN DATE DEFAULT NULL,
  p_d_ext_attr8        IN DATE DEFAULT NULL,
  p_d_ext_attr9        IN DATE DEFAULT NULL,
  p_d_ext_attr10       IN DATE DEFAULT NULL,
  p_tl_ext_attr1       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr2       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr3       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr4       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr5       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr6       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr7       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr8       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr9       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr10      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr11      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr12      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr13      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr14      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr15      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr16      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr17      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr18      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr19      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr20      IN VARCHAR2 DEFAULT NULL,
  p_owner              IN VARCHAR2 DEFAULT NULL
  );

-- +==============================================================================+
-- | Name             : TRANSLATE_ROW                                             |
-- | Description      : This procedure is not being implemented.                  |
-- |                                                                              |
-- +==============================================================================+

procedure TRANSLATE_ROW (
  p_extension_id       IN NUMBER ,
  p_cust_account_id    IN NUMBER,
  p_attr_group_id      IN NUMBER,
  p_tl_ext_attr1       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr2       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr3       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr4       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr5       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr6       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr7       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr8       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr9       IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr10      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr11      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr12      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr13      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr14      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr15      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr16      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr17      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr18      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr19      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr20      IN VARCHAR2 DEFAULT NULL,
  p_owner              IN VARCHAR2 DEFAULT NULL
  );

-- +==============================================================================+
-- | Name             : COMPLETE_CUST_DOC                                         |
-- | Description      : This procedure is to validate if new Pay Doc Exceptions   |
-- |                    are included to the Cust Doc Id . If so the older Pay Doc |
-- |                    will be end dated                     .                   |
-- |                                                                              |
-- +==============================================================================+
procedure COMPLETE_CUST_DOC(p_doc_id IN NUMBER
                           ,p_cust_acct_id IN NUMBER
                           ,p_payment_term IN OUT VARCHAR2
                           ,p_doc_type     IN VARCHAR2
                           ,p_direct_flag  IN VARCHAR2
                           ,p_req_st_date  IN DATE
                           ,p_combo_type   IN VARCHAR2
                           ,p_update_flag  IN VARCHAR2
                           ,x_process_flag OUT NUMBER
                           ,x_cust_doc_id  OUT NUMBER
                           ,x_cust_doc_id1 OUT NUMBER);

-- +==============================================================================+
-- | Name             : VALIDATE_CUST_DOC                                           |
-- | Description      : This procedure is to validate the Pay Doc Exceptions      |
-- |                                                                              |
-- |                                                          .                   |
-- |                                                                              |
-- +==============================================================================+

PROCEDURE VALIDATE_CUST_DOC(
    p_cust_account_id IN NUMBER,
    x_vld_pay_doc_cnt OUT NUMBER,
    x_vld_pay_doc_id1 OUT NUMBER,
    x_vld_pay_doc_id2 OUT NUMBER,
    x_combo_type OUT VARCHAR2,
    x_cons_flag OUT VARCHAR2,
    x_error_msg OUT VARCHAR2);

-- +==============================================================================+
-- | Name             : VALIDATE_CUST_DOC                                         |
-- | Description      : This procedure is to validate the Pay Doc Exceptions      |
-- |                                                                              |
-- |                                                          .                   |
-- |                                                                              |
-- +==============================================================================+
FUNCTION GET_PAY_DOC_VALID_DATE(p_cust_acc_id NUMBER
                               ,p_attr_grp_id NUMBER
                               ,p_combo_type  VARCHAR2) RETURN DATE;

END XX_CDH_CUST_ACCT_EXT_W_PKG;